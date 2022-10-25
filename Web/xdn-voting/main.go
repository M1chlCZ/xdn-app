package main

import (
	"crypto/tls"
	"database/sql"
	"encoding/json"
	"fmt"
	"github.com/dgryski/dgoogauth"
	"github.com/gofiber/fiber/v2"
	_ "github.com/gofiber/fiber/v2/utils"
	"github.com/jmoiron/sqlx"
	"gopkg.in/guregu/null.v4"
	"log"
	"net/http"
	"os"
	"sort"
	"strconv"
	"time"
	"xdn-voting/coind"
	"xdn-voting/database"
	"xdn-voting/errs"
	"xdn-voting/models"
	"xdn-voting/utils"
	"xdn-voting/web3"
)

var debugTime = false

func main() {
	database.New()
	utils.NewJWT()
	web3.New()

	//debug time
	debugTime = false

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
	app.Post("api/v1/login", loginAPI)
	app.Post("api/v1/register", registerAPI)
	app.Post("api/v1/staking/graph", utils.Authorized(getStakeGraph))
	app.Post("api/v1/staking/set", utils.Authorized(setStake))
	app.Post("api/v1/staking/unset", utils.Authorized(unstake))
	app.Get("api/v1/staking/info", utils.Authorized(getStakeInfo))
	app.Post("api/v1/avatar/upload", utils.Authorized(uploadAvatar))
	app.Post("api/v1/avatar", utils.Authorized(getAvatar))
	app.Post("api/v1/avatar/version", utils.Authorized(getAvatarVersion))
	app.Get("api/v1/user/balance", utils.Authorized(getBalance))
	app.Get("api/v1/user/transactions", utils.Authorized(getTransactions))
	app.Get("api/v1/user/addressbook", utils.Authorized(getAddressBook))
	app.Post("api/v1/user/addressbook/save", utils.Authorized(saveToAddressBook))
	app.Get("api/v1/user/token/wxdn", utils.Authorized(getTokenBalance))
	app.Post("api/v1/user/token/tx", utils.Authorized(getTokenTX))
	app.Get("/", func(c *fiber.Ctx) error {
		return c.Status(fiber.StatusBadGateway).JSON(&fiber.Map{
			utils.ERROR:  true,
			utils.STATUS: utils.ERROR,
		})
	})

	utils.ScheduleFunc(saveTokenTX, time.Minute*10)

	// Create tls certificate
	cer, err := tls.LoadX509KeyPair("dex.crt", "dex.key")
	if err != nil {
		log.Fatal(err)
	}

	config := &tls.Config{Certificates: []tls.Certificate{cer}}

	// Create custom listener
	ln, err := tls.Listen("tcp", ":6800", config)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		panic(err)
	}

	// Start server with https/ssl enabled on http://localhost:443
	log.Fatal(app.Listener(ln))
}

func registerAPI(c *fiber.Ctx) error {
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
	})
}

func loginAPI(c *fiber.Ctx) error {
	var req models.UserLogin
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if req.Username == "" || req.Password == "" {
		return utils.ReportError(c, "Missing username or password", http.StatusBadRequest)
	}
	password := utils.HashPass(req.Password)
	user, err := database.ReadStruct[models.User]("SELECT * FROM users WHERE username = ? OR email= ?", req.Username, req.Username)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	if user.Username == "" {
		return utils.ReportError(c, "User not found", http.StatusNotFound)
	}
	if user.Password != password {
		return utils.ReportError(c, "Wrong password", http.StatusUnauthorized)
	}

	if user.TwoActive == 1 {
		if req.TwoFactor == 0 {
			return utils.ReportError(c, "Two factor is required", http.StatusConflict)
		}
		twoRes := dgoogauth.ComputeCode(*user.TwoKey, req.TwoFactor)
		if twoRes != -1 {
			return utils.ReportError(c, "Two factor is invalid", http.StatusUnauthorized)
		}
	}
	token, errToken := utils.CreateKeyToken(uint64(user.Id))
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

func getBalance(c *fiber.Ctx) error {
	name := "XDN balance request"
	start := time.Now()
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	acc, _ := database.ReadValue[string]("SELECT username FROM users WHERE id = ?", userID)
	addr, _ := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	immature, _ := database.ReadValue[float64]("SELECT IFNULL(SUM(amount),0) as immature FROM transaction WHERE account = ? AND confirmation < 3 AND category = 'receive'", acc)
	daemon := utils.GetDaemon()
	unspent, err := coind.WrapDaemon(*daemon, 5, "listunspent", 1, 9999999, []string{addr})
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	bal, err := database.ReadValue[float64](`SELECT SUM(amount) as amount FROM transaction WHERE account = ?`, acc)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	var ing []models.ListUnspent
	spendable := 0.0
	errJson := json.Unmarshal(unspent, &ing)
	if errJson != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	for _, v := range ing {
		if v.Spendable == true {
			spendable += v.Amount
		}
	}
	pending := bal - spendable
	elapsed := time.Since(start)
	if debugTime {
		utils.ReportMessage(fmt.Sprintf("%s took %s", name, elapsed))
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"balance":    fmt.Sprintf("%.2f", float32(pending)),
		"immature":   float32(immature),
		"spendable":  float32(spendable),
	})
}

func getTransactions(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	acc, _ := database.ReadValue[string]("SELECT username FROM users WHERE id = ?", userID)
	transactions, _ := database.ReadArrayStruct[models.Transaction]("SELECT * FROM transaction WHERE account = ?", acc)
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"data":       transactions,
	})
}

func checkContest(c *fiber.Ctx) error {

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
	utils.ReportMessage(fmt.Sprint("===== User ", userID, " voted ", payload.Amount, " for entry ", payload.IDEntry, " ====="))

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
	name := "Ping"
	start := time.Now()
	elapsed := time.Since(start)
	if debugTime {
		utils.ReportMessage(fmt.Sprintf("%s took %s", name, elapsed))
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"message":    "pong",
	})
}

func setStake(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	type req struct {
		Amount float64 `json:"amount"`
	}
	var r req
	err := c.BodyParser(&r)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	user, err := database.ReadStruct[models.StakeUsers]("SELECT * FROM users_stake WHERE idUser = ? AND active = ?", userID, 1)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	server, err := database.ReadValue[string]("SELECT addr FROM servers_stake WHERE id = 1")
	userAddr, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	if user.Active != 0 {
		utils.ReportMessage("UPDATING STAKE")
		balance := r.Amount + user.Amount
		tx, err := coind.SendCoins(server, userAddr, r.Amount, false)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusConflict)
		}
		_, _ = database.InsertSQl("UPDATE users_stake SET amount = ? WHERE idUser = ? AND active = ?", balance, userID, 1)
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Staking", tx, "send")
		time.Sleep(time.Second * 1)
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			"hasError":   false,
			utils.STATUS: utils.OK,
		})
	} else {
		utils.ReportMessage("INSERTING STAKE")
		smax, err := database.ReadValue[float64]("SELECT IFNULL(MAX(session), 0) as smax FROM users_stake WHERE idUser = ?", userID)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
		tx, err := coind.SendCoins(server, userAddr, r.Amount, false)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusConflict)
		}
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Staking", tx, "send")
		if smax == 0 {
			_, _ = database.InsertSQl("INSERT INTO users_stake (idUser, amount, active, session) VALUES (?, ?, ?, ?)", userID, r.Amount, 1, 1)
		} else {
			_, _ = database.InsertSQl("INSERT INTO users_stake (idUser, amount, active, session) VALUES (?, ?, ?, ?)", userID, r.Amount, 1, smax+1)
		}
		time.Sleep(time.Second * 1)
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			"hasError":   false,
			utils.STATUS: utils.OK,
		})
	}
}

func unstake(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	type req struct {
		Type int `json:"type"`
	}
	var r req
	err := c.BodyParser(&r)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	user, err := database.ReadStruct[models.StakeUsers]("SELECT * FROM users_stake WHERE idUser = ? AND active = ?", userID, 1)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	amountToSend := 0.0
	userStake, err := database.ReadValue[float64]("SELECT IFNULL(amount, 0) FROM users_stake WHERE idUser = ? AND active = ?", userID, 1)
	payouts, err := database.ReadValue[float64]("SELECT IFNULL(SUM(amount),0) FROM payouts_stake WHERE idUser = ? AND credited = 0 AND session = ?", userID, user.Session)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	if r.Type == 1 {
		amountToSend += payouts
	} else {
		dateChanged := user.DateStart.Time.UTC().UnixMilli()
		dateNow := time.Now().UnixMilli()
		dateDiff := dateNow - dateChanged
		if dateDiff > 86400000 {
			amountToSend += userStake
			amountToSend += payouts
		} else {
			return utils.ReportError(c, "You can only unstake after 24 hours", http.StatusConflict)
		}
	}
	utils.ReportMessage(fmt.Sprintf("Amount to send: %f, user to send %d", amountToSend, user.IdUser))
	server, err := database.ReadValue[string]("SELECT addr FROM servers_stake WHERE id = 1")
	userAddr, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	if user.Active != 0 {
		utils.ReportMessage("UNSTAKING")
		tx, err := coind.SendCoins(userAddr, server, amountToSend, true)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusConflict)
		}
		if r.Type == 1 {
			_, _ = database.InsertSQl("UPDATE payouts_stake SET credited = ? WHERE idUser = ? AND session = ? AND id <> 0", 1, userID, user.Session)
		} else {
			_, _ = database.InsertSQl("UPDATE payouts_stake SET credited = ? WHERE idUser = ? AND session = ? AND id <> 0", 1, userID, user.Session)
			_, _ = database.InsertSQl("UPDATE users_stake SET active = ? WHERE idUser = ?", 0, userID)
		}
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE txid = ? AND category = ? AND id <> 0 LIMIT 1", "Staking withdrawal", tx, "receive")
		time.Sleep(time.Second * 1)
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			"hasError":   false,
			utils.STATUS: utils.OK,
		})
	} else {
		return utils.ReportError(c, "You don't have any active stake", http.StatusConflict)
	}
}
func getStakeInfo(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	var emptyStruct models.CheckStakeDBStruct
	refDB := database.ReadStructEmpty[models.CheckStakeDBStruct]("SELECT amount, session FROM users_stake WHERE idUser = ? AND active = 1", userID)

	count := 0
	if refDB != emptyStruct {
		count = 1
	}

	rql, errSelect := database.ReadValue[sql.NullFloat64]("SELECT COALESCE(SUM(amount), 0) as amount FROM payouts_stake WHERE idUser = ? AND session = ? AND credited = 0 ", userID, refDB.Session)
	if errSelect != nil {
		return utils.ReportError(c, errSelect.Error(), http.StatusInternalServerError)

	}
	stakesAmount := utils.InlineIF(rql.Valid, rql.Float64, 0.0)

	totalCoins, _ := database.ReadValue[float64]("SELECT COALESCE(SUM(amount), 0) as amount FROM transaction_stake WHERE datetime >= now() - INTERVAL 1 DAY")
	inPoolTotal, _ := database.ReadValue[float64]("SELECT COALESCE(SUM(amount), 0) as amount FROM users_stake WHERE active = 1")

	percentage := refDB.Amount / inPoolTotal
	estimated := totalCoins * percentage

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.STATUS:   utils.OK,
		"hasError":     false,
		"amount":       refDB.Amount,
		"active":       count,
		"stakesAmount": stakesAmount,
		"contribution": percentage * 100,
		"estimated":    estimated,
		"poolAmount":   inPoolTotal,
	})
}

func getStakeGraph(c *fiber.Ctx) error {
	name := "Get stake graph request"
	start := time.Now()
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
	elapsed := time.Since(start)
	if debugTime {
		utils.ReportMessage(fmt.Sprintf("%s took %s", name, elapsed))
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"stakes":     returnArr,
	})
}

func getTokenBalance(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if debugTime {
		utils.ReportMessage(fmt.Sprint("===== Get Token Balance for user ", userID, " ====="))
	}
	name := "Token balance request"
	start := time.Now()

	//make database call below in goroutine
	acc, err := database.ReadArrayStruct[models.UsersTokenAddr]("SELECT * FROM users_addr WHERE idUser = ? AND addr IS NOT NULL", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	elapsed := time.Since(start)
	if debugTime {
		utils.ReportMessage(fmt.Sprintf("%s took %s", "DB Query", elapsed))
	}
	blc := 0.0
	for _, v := range acc {
		if string(v.Addr) == "" {
			//return utils.ReportError(c, "No address", http.StatusBadRequest)
			continue
		}
		balance, err := web3.GetContractBalance(string(v.Addr))
		if err != nil {
			//return utils.ReportError(c, err.Error(), http.StatusBadRequest)
			continue
		}
		blc += balance
	}
	elapsed = time.Since(start)
	if debugTime {
		utils.ReportMessage(fmt.Sprintf("%s took %s", name, elapsed))
		utils.ReportMessage(fmt.Sprint("=====////====="))
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"balance":    blc,
	})
}

func getTokenTX(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	var txReq models.GetTokenTxReq
	if err := c.BodyParser(&txReq); err != nil {
		return err
	}

	db, err := database.ReadArrayStruct[models.TokenTX]("SELECT * FROM bsc_tx WHERE idUser = ? AND timestampTX > ? AND tokenSymbol = 'WXDN' ORDER BY timestampTX DESC", userID, txReq.Timestamp)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	addr, err := database.ReadArrayStruct[models.UsersTokenAddr]("SELECT addr FROM users_addr WHERE idUser = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	blc := 0.0
	asdf := ""
	if len(addr) > 0 {
		for _, v := range addr {
			address := string(v.Addr)
			if len(address) == 0 {
				continue
			}

			balance, err := web3.GetContractBalance(address)
			if err != nil {
				return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
			}
			blc += balance
			asdf = address
		}
	} else {
		return utils.ReportError(c, "No user addresses in the db", http.StatusConflict)
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"addr":       asdf,
		"bal":        blc,
		"tx":         db,
	})
}

func saveTokenTX() {
	users, err := database.ReadArrayStruct[models.UsersTokenAddr]("SELECT * FROM users_addr WHERE 1")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	for _, u := range users {
		userID := u.IdUser
		//utils.ReportMessage(fmt.Sprintf("Saving token tx, user %d", userID))
		tx, err := web3.GetTokenTx(string(u.Addr))
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}

		if len(tx.Result) != 0 {
			for _, res := range tx.Result {
				_, err := database.InsertSQl(`INSERT INTO bsc_tx (hash, blocknumber, timestampTX, blockhash, fromAddr, toAddr, contractAddr, contractDecimal, amount, tokenName, tokenSymbol, gas, gasPrice, gasUsed, confirmations, idUser) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
			ON DUPLICATE KEY UPDATE confirmations = ?`, res.Hash, res.BlockNumber, res.TimeStamp, res.BlockHash, res.From, res.To, res.ContractAddress, res.TokenDecimal, res.Value, res.TokenName, res.TokenSymbol, res.Gas, res.GasPrice, res.GasUsed, res.Confirmations, userID, res.Confirmations)
				if err != nil {
					utils.WrapErrorLog(err.Error())
					break
				}
			}
		}
		time.Sleep(time.Millisecond * 200)
	}
	//utils.ReportMessage("Saved token tx")
}

func getAvatarVersion(c *fiber.Ctx) error {
	type Req struct {
		Address string `json:"address"`
	}
	var r Req
	err := c.BodyParser(&r)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if r.Address == "" {
		return utils.ReportError(c, "Address is empty", http.StatusBadRequest)
	}
	avatarVersion, err := database.ReadValue[int64]("SELECT av FROM users WHERE addr = ?", r.Address)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"version":    avatarVersion,
	})
}

func getAvatar(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown user", http.StatusBadRequest)
	}
	type Req struct {
		ID      int64  `json:"id"`
		Address string `json:"address"`
	}
	var r Req
	err := c.BodyParser(&r)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}

	if len(r.Address) == 0 {
		//by id
		id := 0
		if r.ID != 0 {
			id = int(r.ID)
		} else {
			id = userID
		}
		avatar, err := database.ReadValue[sql.NullString]("SELECT avatar FROM users WHERE id = ?", id)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
		if avatar.Valid {
			av, err := os.ReadFile(fmt.Sprintf(utils.GetHomeDir() + "/api/avatars/" + avatar.String + ".xdf"))
			if err != nil {
				return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
			}
			return c.Status(fiber.StatusOK).JSON(&fiber.Map{
				"hasError":   false,
				utils.STATUS: utils.OK,
				"avatar":     string(av),
			})
		} else {
			return c.Status(fiber.StatusBadRequest).JSON(&fiber.Map{
				"hasError":   true,
				utils.STATUS: utils.FAIL,
			})
		}
	} else {
		//by address
		avatar, err := database.ReadValue[sql.NullString]("SELECT avatar FROM users WHERE addr = ?", r.Address)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
		if avatar.Valid {
			av, err := os.ReadFile(fmt.Sprintf(utils.GetHomeDir() + "/api/avatars/" + avatar.String + ".xdf"))
			if err != nil {
				return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
			}
			return c.Status(fiber.StatusOK).JSON(&fiber.Map{
				"hasError":   false,
				utils.STATUS: utils.OK,
				"avatar":     string(av),
			})
		} else {
			return c.Status(fiber.StatusBadRequest).JSON(&fiber.Map{
				"hasError":   true,
				utils.STATUS: utils.FAIL,
			})
		}
	}
}

func uploadAvatar(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown user", http.StatusBadRequest)
	}
	type Req struct {
		File string `json:"file"`
	}
	var r Req
	err := c.BodyParser(&r)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	avatar, err := database.ReadValue[sql.NullString]("SELECT avatar FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	if avatar.Valid {
		//already has avatar
		err = os.WriteFile(fmt.Sprintf(utils.GetHomeDir()+"/api/avatars/"+avatar.String+".xdf"), []byte(r.File), 0644)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
		_, _ = database.InsertSQl("UPDATE users SET av = av + 1 WHERE id = ?", userID)
	} else {
		//don't have avatar
		filename := utils.GenerateSecureToken(10)
		err = os.WriteFile(fmt.Sprintf(utils.GetHomeDir()+"/api/avatars/"+filename+".xdf"), []byte(r.File), 0644)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
		_, _ = database.InsertSQl("UPDATE users SET avatar = ? WHERE id = ?", filename, userID)
		_, _ = database.InsertSQl("UPDATE users SET av = av + 1 WHERE id = ?", userID)
	}
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})

}

func saveToAddressBook(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type Req struct {
		Id   int    `json:"id"`
		Name string `json:"name"`
		Addr string `json:"addr"`
	}
	var req Req
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, "Invalid request", http.StatusBadRequest)
	}
	value, err := database.ReadValue[int64]("SELECT COUNT(id) FROM addressbook WHERE idUser = ? AND addr = ?", userID, req.Addr)
	if err != nil {
		return utils.ReportError(c, "Invalid request", http.StatusBadRequest)
	}
	if value == 0 {
		_, err = database.InsertSQl("INSERT INTO addressbook (idUser, name, addr) VALUES (?,?,?)", userID, req.Name, req.Addr)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
	}
	arrayStruct, err := database.ReadArrayStruct[Req]("SELECT id, name, addr FROM addressbook  WHERE idUser = ? ORDER BY id DESC", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"data":       arrayStruct,
	})
}

func getAddressBook(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type AddressBook struct {
		Id   int    `json:"id"`
		Name string `json:"name"`
		Addr string `json:"addr"`
	}
	arrayStruct, err := database.ReadArrayStruct[AddressBook]("SELECT id, name, addr FROM addressbook  WHERE idUser = ? ORDER BY id DESC", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"data":       arrayStruct,
	})
}
