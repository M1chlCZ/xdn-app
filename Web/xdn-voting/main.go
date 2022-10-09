package main

import (
	"encoding/json"
	"fmt"
	"github.com/gofiber/fiber/v2"
	_ "github.com/gofiber/fiber/v2/utils"
	"gopkg.in/guregu/null.v4"
	"log"
	"net/http"
	"sort"
	"strconv"
	"xdn-voting/database"
	"xdn-voting/errs"
	"xdn-voting/models"
	"xdn-voting/utils"
	"xdn-voting/web3"
)

func main() {
	database.New()
	utils.NewJWT()
	web3.New()
	number, errr := web3.GetBalance("0x426cdD94138DD82737D40057f949588b3957DAb7")
	if errr != nil {
		log.Println(errr)
	}
	utils.ReportMessage(fmt.Sprintf("Addr: %v ", float64(number.Int64())/1000000000000000000))
	app := fiber.New(fiber.Config{AppName: "XDN DAO", StrictRouting: true})
	utils.ReportMessage("Rest API v" + utils.VERSION + " - XDN DAO API | SERVER")
	app.Post("dao/v1/login", login)
	app.Get("dao/v1/ping", utils.Authorized(ping))
	app.Get("dao/v1/contest/get", utils.Authorized(getCurrentContest))
	app.Post("dao/v1/contest/create", utils.Authorized(createContest))
	app.Post("dao/v1/contest/vote", utils.Authorized(castVote))
	app.Post("dao/v1/address/add", utils.Authorized(addAddress))

	err := app.Listen(":6800")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		log.Panic(err)
	}
}

func login(c *fiber.Ctx) error {
	payload := struct {
		Token string `json:"token"`
	}{}

	if err := c.BodyParser(&payload); err != nil {
		return err
	}
	resp, err := utils.POSTReq("http://localhost:3000/verify", map[string]string{"token": payload.Token})
	if err != nil {
		return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
	}
	if resp.StatusCode != http.StatusOK {
		return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
	}
	decGet := json.NewDecoder(resp.Body)
	decGet.DisallowUnknownFields()

	var userMe models.Auth
	errJson := decGet.Decode(&userMe)
	errorJson, errorMessage := errs.ValidateJson(errJson)
	if errorJson == true {
		return utils.ReportError(c, errorMessage, http.StatusBadRequest)

	}
	token, errToken := utils.CreateKeyToken(uint64(userMe.Id))
	if errToken != nil {
		log.Printf("err: %v\n", errToken)
		return utils.ReportError(c, errToken.Error(), http.StatusInternalServerError)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"token":      token,
	})
}

func getCurrentContest(c *fiber.Ctx) error {
	userID, err := strconv.Atoi(c.Get("User_id"))
	if err != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}

	contest, err := database.ReadStruct[models.Contest]("SELECT * FROM voting_contest WHERE finished = 0")
	if err != nil {
		return utils.ReportError(c, "No contest", http.StatusConflict)
	}
	if contest == (models.Contest{}) {
		return utils.ReportError(c, "No contest", http.StatusConflict)
	}

	contestEntries, err := database.ReadArrayStruct[models.ContestEntry](
		`SELECT id, name, IFNULL(amount, 0) as amount, IFNULL(userAmount, 0) as userAmount, d.addr as address
	FROM (SELECT a.id, name, b.amount, c.amount as userAmount, d.addr FROM voting_entries a
    LEFT JOIN  (SELECT idEntry, IFNULL(SUM(amount), 0) as amount FROM votes b GROUP BY idEntry) b ON a.id = b.idEntry
    LEFT JOIN (SELECT idEntry, IFNULL(SUM(amount), 0) as amount FROM votes c WHERE idUser = ? GROUP BY idEntry) c ON a.id = c.idEntry
    LEFT JOIN (SELECT id, addr FROM voting_addr) d ON a.idAddr = d.id
      WHERE a.idContest = ?) d;`, userID, contest.Id)
	if err != nil {
		return utils.ReportError(c, "No entries", http.StatusConflict)
	}
	sort.Slice(contestEntries, func(i, j int) bool {
		return contestEntries[i].Amount > contestEntries[j].Amount
	})
	res := &models.ContestResponse{
		Id:            contest.Id,
		Name:          contest.Name,
		AmountToReach: contest.AmountToReach,
		DateEnding:    contest.DateEnding,
		Entries:       contestEntries,
	}
	return c.Status(fiber.StatusOK).JSON(res)
}

func createContest(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type req struct {
		Name          string     `json:"name"`
		AmountToReach null.Float `json:"amountToReach"`
		DateEnding    null.Time  `json:"dateEnding"` //Format: 2020-09-10T00:00:00.000Z
		Entries       []string   `json:"entries"`
		IDCreator     int        `json:"idCreator"`
	}
	var payload req
	if err := c.BodyParser(&payload); err != nil {
		return err
	}

	//check for already existing active contest
	activeContest := database.ReadValueEmpty[null.Int]("SELECT id FROM voting_contest WHERE finished = 0 LIMIT 1")

	if activeContest.Valid {
		return utils.ReportError(c, "There is already an active contest", http.StatusConflict)
	}
	type addr struct {
		ID      int    `db:"id"`
		Address string `db:"addr"`
	}
	//get voting addresses
	votingAddresses, errDB := database.ReadArrayStruct[addr]("SELECT * FROM voting_addr")
	if errDB != nil {
		return utils.ReportError(c, errDB.Error(), http.StatusInternalServerError)
	}
	addrCount := len(votingAddresses)

	//validation of the fields
	if payload.Name == "" {
		return utils.ReportError(c, "Contest name is required", http.StatusBadRequest)
	}
	if payload.AmountToReach.Valid && payload.DateEnding.Valid {
		return utils.ReportError(c, "AmountToReach and DateEnding cannot be used at the same time", http.StatusBadRequest)
	}
	if !payload.AmountToReach.Valid && !payload.DateEnding.Valid {
		return utils.ReportError(c, "AmountToReach or DateEnding required", http.StatusBadRequest)
	}
	if len(payload.Entries) == 0 {
		return utils.ReportError(c, "Contest Voting Entries required", http.StatusBadRequest)
	}
	if len(payload.Entries) > addrCount {
		return utils.ReportError(c, "Too many entries (not enough voting addresses)", http.StatusBadRequest)
	}

	//all good
	var contestID int64
	var err error

	if payload.AmountToReach.Valid {
		contestID, err = database.InsertSQl("INSERT INTO voting_contest (name, amountToReach, idCreator) VALUES (?, ?, ?)", payload.Name, payload.AmountToReach.Float64, userID)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
	}

	if payload.DateEnding.Valid {
		contestID, err = database.InsertSQl("INSERT INTO voting_contest (name, dateEnding, idCreator) VALUES (?, ?, ?)", payload.Name, payload.DateEnding.Time, userID)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
	}

	for i, entry := range payload.Entries {
		addrID := votingAddresses[i].ID
		_, _ = database.InsertSQl("INSERT INTO voting_entries (idContest, name, idAddr) VALUES (?, ?, ?)", contestID, entry, addrID)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
	})
}

func castVote(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type req struct {
		IDEntry int     `json:"idEntry"`
		Amount  float64 `json:"amount"`
	}
	var payload req
	if err := c.BodyParser(&payload); err != nil {
		return err
	}

	//validation of the fields
	if payload.IDEntry == 0 {
		return utils.ReportError(c, "Entry ID is required", http.StatusBadRequest)
	}
	if payload.Amount == 0 {
		return utils.ReportError(c, "Amount is required", http.StatusBadRequest)
	}
	_, err := database.InsertSQl("INSERT INTO votes (idUser, idEntry, amount) VALUES (?, ?, ?)", userID, payload.IDEntry, payload.Amount)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
	})
}

func addAddress(c *fiber.Ctx) error {
	type req struct {
		Address string `json:"address"`
	}
	var payload req
	if err := c.BodyParser(&payload); err != nil {
		return err
	}

	//validation of the fields
	if len(payload.Address) == 0 {
		return utils.ReportError(c, "Address is required", http.StatusBadRequest)
	}
	if !utils.Erc20verify(payload.Address) {
		return utils.ReportError(c, "Invalid Address", http.StatusBadRequest)
	}

	_, err := database.InsertSQl("INSERT INTO voting_addr (addr) VALUES (?)", payload.Address)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
	})
}

func ping(c *fiber.Ctx) error {
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"message":    "pong",
	})
}
