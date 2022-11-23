package apiWallet

import (
	"encoding/json"
	"fmt"
	"github.com/gofiber/fiber/v2"
	"net/http"
	"time"
	"xdn-voting/coind"
	"xdn-voting/daemons"
	"xdn-voting/database"
	"xdn-voting/models"
	"xdn-voting/utils"
)

func Handler() {
	appWallet := fiber.New(fiber.Config{AppName: "XDN WALLET API", StrictRouting: true})

	unlockStakeWallet()
	utils.ScheduleFunc(daemons.SaveTransactions, time.Minute*1)
	utils.ScheduleFunc(daemons.SaveAllTransactions, time.Second*3700)

	appWallet.Post("api/v1/wallet/txsubmit", submitTransaction)
	appWallet.Post("api/v1/wallet/stake/txsubmit", submitStakeTransaction)
	err := appWallet.Listen("127.0.0.1:6600")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		panic(err)
	}
}

func unlockStakeWallet() {
	_, err := coind.WrapDaemon(utils.DaemonStakeWallet, 1, "walletpassphrase", utils.DaemonStakeWallet.PassPhrase.String, 99999999, true)
	if err != nil {
		utils.ReportMessage(err.Error())
	}
	utils.ReportMessage("Stake wallet unlocked")
}

func submitStakeTransaction(c *fiber.Ctx) error {
	txid := c.Get("txid")
	if txid == "" {
		return utils.ReportError(c, "No txid", http.StatusBadRequest)
	}
	tx, err := coind.WrapDaemon(utils.DaemonStakeWallet, 5, "gettransaction", txid)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	var txID models.GetTransaction
	err = json.Unmarshal(tx, &txID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}

	if txID.Generated == true {
		utils.ReportMessage("Transaction is stake")
		_, err = database.InsertSQl("INSERT INTO transaction_stake(txid, amount) VALUES (?, ?)", txID.Txid, 90)
		_, err = database.InsertSQl("INSERT INTO treasury(txid, amount) VALUES (?, ?)", txID.Txid, 10)
		if err != nil {
			utils.ReportMessage(err.Error())
			return utils.ReportErrorSilent(c, err.Error(), http.StatusBadRequest)
		}
		utils.ReportMessage(fmt.Sprintf("Stake transaction added %s", txID.Txid))
		total, err := database.ReadValue[float64]("SELECT IFNULL(SUM(amount), 0) as amount FROM users_stake WHERE active = 1")
		if err != nil {
			utils.ReportMessage(err.Error())
			return utils.ReportErrorSilent(c, err.Error(), http.StatusBadRequest)
		}
		type Stake struct {
			IDuser  int64   `db:"idUser" json:"idUser"`
			Amount  float64 `db:"amount" json:"amount"`
			Session int64   `db:"session" json:"session"`
		}
		users, err := database.ReadArrayStruct[Stake]("SELECT idUser, amount, session FROM users_stake WHERE active = 1")
		for _, user := range users {
			percentage := user.Amount / total
			credit := 100 * percentage
			_, err = database.InsertSQl("INSERT INTO payouts_stake(idUser, txid, session, amount) VALUES (?, ?, ?, ?)", user.IDuser, txID.Txid, user.Session, credit)
		}
		_, _ = database.InsertSQl("UPDATE transaction_stake SET credited = 1 WHERE txid = ?", txID.Txid)
		utils.ReportMessage(fmt.Sprintf("Stake transaction credited %s", txID.Txid))

	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func submitTransaction(c *fiber.Ctx) error {
	txid := c.Get("txid")
	if txid == "" {
		return utils.ReportError(c, "No txid", http.StatusBadRequest)
	}
	tx, err := coind.WrapDaemon(utils.DaemonWallet, 5, "gettransaction", txid)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	var txinfo models.GetTransaction
	err = json.Unmarshal(tx, &txinfo)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if txinfo.Amount < 0 {
		return utils.ReportErrorSilent(c, "Invalid amount", http.StatusBadRequest)
	}
	txPrev := database.ReadStructEmpty[models.Transaction]("SELECT * FROM transaction WHERE txid = ?", txid)

	account := ""
	address := ""
	for _, name := range txinfo.Details {
		if len(name.Account) > 0 {
			account = name.Account
			address = name.Address
			break
		}
	}
	if address == "dW8VEXurvxeJ1dMer6JoR6RSb3u3MnmMQW" {
		return utils.ReportErrorSilent(c, "Stake address", http.StatusBadRequest)
	}
	if txPrev.Txid == txid {
		if txPrev.Account == account && txPrev.Address == address {
			return c.Status(fiber.StatusOK).JSON(&fiber.Map{
				utils.ERROR:  false,
				utils.STATUS: utils.OK,
			})
		}
	}
	_, err = database.InsertSQl("INSERT INTO transaction(txid, account, amount, confirmation, address, category) VALUES (?, ?, ?, ?, ?, ?)", txid, account, txinfo.Amount, txinfo.Confirmations, address, "receive")
	if err != nil {
		//utils.ReportMessage(err.Error())
		_, err = database.InsertSQl("UPDATE transaction SET confirmation = ? WHERE txid = ?", txinfo.Confirmations, txinfo.Txid)
		if err != nil {
			utils.ReportMessage(err.Error())
		}
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}
