package main

import (
	"encoding/json"
	"fmt"
	"github.com/gofiber/fiber/v2"
	_ "github.com/gofiber/fiber/v2/utils"
	"github.com/jmoiron/sqlx"
	"log"
	"net/http"
	"sort"
	"strconv"
	"xdn-voting/database"
	"xdn-voting/errs"
	"xdn-voting/models"
	"xdn-voting/utils"
)

func main() {
	db, errDB := sqlx.Open("mysql", utils.GetENV("DB_CONN"))
	if errDB != nil {
		log.Fatal(errDB)
	}
	database.New(db)
	utils.NewJWT()
	app := fiber.New(fiber.Config{AppName: "XDN DAO", StrictRouting: true})

	app.Post("dao/v1/login", login)
	app.Get("dao/v1/contest/get", utils.Authorized(getCurrentContest))

	err := app.Listen(":6800")
	if err != nil {
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
	resp, err := utils.POSTReq("http://194.60.201.213:3000/verify", map[string]string{"token": payload.Token})
	if err != nil {
		return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
	}
	if resp.StatusCode != http.StatusOK {
		return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
	}
	utils.ReportMessage(fmt.Sprintf("%s", resp.Body))
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
		"success": true,
		"error":   "",
		"token":   token,
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

	contestEntries, err := database.ReadArrayStruct[models.ContestEntry](
		`SELECT id, name, IFNULL(amount, 0) as amount, IFNULL(userAmount, 0) as userAmount
    	 FROM (SELECT id, name, b.amount, c.amount as userAmount FROM voting_entries a
    	 LEFT JOIN  (SELECT idEntry, IFNULL(SUM(amount), 0) as amount FROM votes b GROUP BY idEntry) b ON a.id = b.idEntry
    	 LEFT JOIN (SELECT idEntry, IFNULL(SUM(amount), 0) as amount FROM votes c WHERE idUser = ? GROUP BY idEntry) c ON a.id = c.idEntry
		 WHERE a.idContest = ? ORDER BY id) d`, userID, contest.Id)
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
