package main

import (
	"encoding/json"
	"fmt"
	"github.com/gofiber/fiber/v2"
	_ "github.com/gofiber/fiber/v2/utils"
	"github.com/jmoiron/sqlx"
	"gopkg.in/guregu/null.v4"
	"log"
	"net/http"
	"sort"
	"strconv"
	"xdn-voting/coind"
	"xdn-voting/database"
	"xdn-voting/errs"
	"xdn-voting/models"
	"xdn-voting/utils"
)

func main() {
	database.New()
	utils.NewJWT()
	//web3.New()
	//number, errr := web3.GetBalance("0x426cdD94138DD82737D40057f949588b3957DAb7")
	//if errr != nil {
	//	log.Println(errr)
	//}
	//utils.ReportMessage(fmt.Sprintf("Addr: %v ", float64(number.Int64())/1000000000000000000))
	app := fiber.New(fiber.Config{AppName: "XDN DAO API", StrictRouting: true})
	utils.ReportMessage("Rest API v" + utils.VERSION + " - XDN DAO API | SERVER")
	// ================== DAO ==================
	app.Post("dao/v1/login", login)
	app.Get("dao/v1/ping", utils.Authorized(ping))
	app.Get("dao/v1/contest/get", utils.Authorized(getCurrentContest))
	app.Get("dao/v1/contest/check", utils.Authorized(checkContest))
	app.Post("dao/v1/contest/create", utils.Authorized(createContest))
	app.Post("dao/v1/contest/vote", utils.Authorized(castVote))
	app.Post("dao/v1/address/add", utils.Authorized(addAddress))
	app.Post("dao/v1/user/address/add", utils.Authorized(addUserAddress))

	// ================== API ==================
	app.Post("api/v1/staking/graph", utils.Authorized(getStakeGraph))
	app.Get("api/v1/user/balance", utils.Authorized(getBalance))

	err := app.Listen(":6800")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		log.Panic(err)
	}
}

func getBalance(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	acc, _ := database.ReadValue[string]("SELECT username FROM users WHERE id = ?", userID)
	addr, _ := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	immature, _ := database.ReadValue[float64]("SELECT IFNULL(SUM(amount),0) as immature FROM transaction WHERE account = ? AND confirmation < 5 AND category = 'receive'", acc)
	daemon := utils.GetDaemon()
	balance, err := coind.WrapDaemon(*daemon, 5, "listunspent", 1, 9999999, []string{addr})
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	var ing []models.ListUnspent
	spendable := 0.0
	errJson := json.Unmarshal(balance, &ing)
	if errJson != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	for _, v := range ing {
		if v.Spendable == true {
			spendable += v.Amount
		}
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"balance":    0,
		"immature":   float32(immature),
		"spendable":  float32(spendable),
	})
}

func checkContest(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}

	// TODO CHANGE!!!
	if userID != 1 && userID != 4 {
		return utils.ReportError(c, "No contest", http.StatusConflict)
	}

	contest, err := database.ReadStruct[models.Contest]("SELECT * FROM voting_contest WHERE finished = 0")
	if err != nil {
		return utils.ReportError(c, "No contest", http.StatusConflict)
	}
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	var empty models.Contest
	if contest == empty {
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			"hasError":   false,
			utils.STATUS: utils.OK,
			"message":    "No contest",
		})
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
	})
}

func addUserAddress(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type req struct {
		Address string `json:"address"`
	}
	var payload req
	if err := c.BodyParser(&payload); err != nil {
		return err
	}

	//validation of the fields
	if payload.Address == "" {
		return utils.ReportError(c, "Address is required", http.StatusBadRequest)
	}
	_, err := database.InsertSQl("INSERT INTO users_addr (idUser, addr) VALUES (?, ?)", userID, payload.Address)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	utils.ReportMessage(fmt.Sprint("User ", userID, " added address ", payload.Address))

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
	})
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
	// TODO CHANGE!!!
	if userID != 1 && userID != 4 {
		return utils.ReportError(c, "No contest", http.StatusConflict)
	}

	contest, err := database.ReadStruct[models.Contest]("SELECT * FROM voting_contest WHERE finished = 0")
	if err != nil {
		return utils.ReportError(c, "No contest", http.StatusConflict)
	}
	if contest == (models.Contest{}) {
		return utils.ReportError(c, "No contest", http.StatusConflict)
	}

	contestEntries, err := database.ReadArrayStruct[models.ContestEntry](
		`SELECT id, name, IFNULL(amount, 0) as amount, IFNULL(userAmount, 0) as userAmount, d.addr as address, IFNULL(goal,0) as goal
	FROM (SELECT a.id, name, b.amount, c.amount as userAmount, d.addr, goal FROM voting_entries a
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
		Goals         []int      `json:"goals"`
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
	if len(payload.Entries) != len(payload.Goals) {
		return utils.ReportError(c, "Goals and Entries should have the same length", http.StatusBadRequest)
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
		_, err := database.InsertSQl("INSERT INTO voting_entries (idContest, name, idAddr, goal) VALUES (?, ?, ?, ?)", contestID, entry, addrID, payload.Goals[i])
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
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
	utils.ReportMessage(fmt.Sprint("User ", userID, " voted ", payload.Amount, " for entry ", payload.IDEntry))

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

func getStakeGraph(c *fiber.Ctx) error {
	userID, _ := strconv.Atoi(c.Get("User_id"))
	var stakeReq models.GetStakeStruct
	if err := c.BodyParser(&stakeReq); err != nil {
		return err
	}

	var s *sqlx.Rows
	var errDB error
	var sqlQuery string
	createdFormat := "2006-01-02 15:04:05"
	timez := stakeReq.Datetime.Format(createdFormat)
	year, month, _ := stakeReq.Datetime.Date()

	if stakeReq.Type == 0 {
		sqlQuery = `SELECT date(datetime) as day, Hour(datetime) AS hour, sum(amount) AS amount FROM  payouts_stake WHERE datetime BETWEEN ? AND date_add(?, INTERVAL 24 HOUR) AND idUser = ? AND credited = 0 GROUP BY hour, day ORDER BY hour`
		//sqlDebugQuery := fmt.Sprintf(`SELECT date(datetime) as day, Hour(datetime) AS hour, sum(amount) AS amount FROM  payouts_stake2 WHERE datetime BETWEEN %s AND date_add(%s, INTERVAL 24 HOUR) AND idCoin = %d AND idUser = %s AND credited = 0 GROUP BY hour, day "+
		//	"ORDER BY hour", timez, timez, stakeReq.IdCoin, userID)
		//utils.ReportMessage(sqlDebugQuery)
		s, errDB = database.ReadSql(sqlQuery, timez, timez, userID)
	} else if stakeReq.Type == 1 {
		sqlQuery = "SELECT date(datetime) as day, sum(amount) AS amount FROM  payouts_stake WHERE datetime BETWEEN  date_sub(?, INTERVAL 1 WEEK) AND ? AND idUser = ? GROUP BY day"
		s, errDB = database.ReadSql(sqlQuery, timez, timez, userID)
	} else if stakeReq.Type == 2 {
		sqlQuery = "SELECT DATE(datetime) as day, SUM(`amount`) AS amount FROM payouts_stake WHERE idUser =? AND YEAR(date(datetime))=? AND MONTH(date(datetime))=? GROUP BY DATE(datetime)"
		s, errDB = database.ReadSql(sqlQuery, userID, year, month)
	} else if stakeReq.Type == 3 {
		sqlQuery = "SELECT ANY_VALUE(DATE_FORMAT(datetime,'%Y-%m')) AS day, SUM(`amount`) AS amount FROM payouts_stake WHERE idUser = ? AND YEAR(date(datetime))= ? GROUP BY MONTH (date(datetime))"
		s, errDB = database.ReadSql(sqlQuery, userID, year)
	}

	if errDB != nil {
		return utils.ReportError(c, errDB.Error(), http.StatusInternalServerError)
	}

	var returnArr interface{}
	if stakeReq.Type == 0 {
		returnArr = database.ParseArrayStruct[models.StakeDailyGraph](s)
	} else {
		returnArr = database.ParseArrayStruct[models.StakeWeeklyGraph](s)
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"stakes":     returnArr,
	})
}
