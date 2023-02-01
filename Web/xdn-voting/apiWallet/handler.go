package apiWallet

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"github.com/gofiber/fiber/v2"
	"net/http"
	"os/exec"
	"strings"
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

func RepairWallet() {
	_, err := coind.WrapDaemon(utils.DaemonStakeWallet, 1, "repairwallet")
	if err != nil {
		utils.ReportMessage(err.Error())
	}
	active, _ := exec.Command("bash", "-c", fmt.Sprintf("systemctl --user is-active %s", utils.DaemonStakeWallet.Folder)).Output()
	if strings.TrimSpace(string(active)) != "active" {
		_, _ = exec.Command("bash", "-c", fmt.Sprintf("systemctl --user restart staking.service")).Output()
	}
	utils.ReportMessage("Wallet Repaired unlocked")
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
		//utils.ReportMessage("Transaction is stake")
		_, err = database.InsertSQl("INSERT INTO transaction_stake_wallet(txid, amount) VALUES (?, ?)", txID.Txid, 100)
		_, err = database.InsertSQl("INSERT INTO transaction_stake(txid, amount) VALUES (?, ?)", txID.Txid, 90)
		if err != nil {
			//utils.ReportMessage(err.Error())
			return utils.ReportErrorSilent(c, err.Error(), http.StatusBadRequest)
		}
		_, err = database.InsertSQl("INSERT INTO treasury(txid, amount) VALUES (?, ?)", txID.Txid, 10)
		if err != nil {
			//utils.ReportMessage(err.Error())
			return utils.ReportErrorSilent(c, err.Error(), http.StatusBadRequest)
		}
		utils.ReportMessage(fmt.Sprintf("Stake transaction added %s", txID.Txid))
		total, err := database.ReadValue[float64]("SELECT IFNULL(SUM(amount), 0) as amount FROM users_stake WHERE active = 1")
		if err != nil {
			return utils.ReportErrorSilent(c, err.Error(), http.StatusBadRequest)
		}
		type Stake struct {
			IDuser    int64   `db:"idUser" json:"idUser"`
			Amount    float64 `db:"amount" json:"amount"`
			Session   int64   `db:"session" json:"session"`
			Autostake bool    `db:"autostake" json:"autostake"`
		}
		users, err := database.ReadArrayStruct[Stake]("SELECT idUser, amount, session, autostake FROM users_stake WHERE active = 1")
		lastHour, _ := database.ReadArrayStruct[models.PayoutStake]("SELECT * FROM payouts_stake WHERE DATE_FORMAT(datetime, '%Y-%m-%d %H') = DATE_FORMAT(NOW(), '%Y-%m-%d %H') AND credited = 0")
		for _, user := range users {
			useric := false
			percentage := user.Amount / total
			credit := 100 * percentage

			dt := time.Now().UTC().Format("2006-01-02 15:04:05")
			if len(lastHour) == 0 {
				if user.Autostake == true {
					_, errUpdate := database.InsertSQl("INSERT INTO payouts_stake(idUser, txid, session, amount, credited) VALUES (?, ?, ?, ?, ?)", user.IDuser, txID.Txid, user.Session, credit, 1)
					_, errUpdate = database.InsertSQl("UPDATE users_stake SET amount = amount + ? WHERE idUser = ? AND active = 1", credit, user.IDuser)
					if errUpdate != nil {
						return utils.ReportError(c, errUpdate.Error(), http.StatusInternalServerError)
					}
				} else {
					_, errUpdate := database.InsertSQl("INSERT INTO payouts_stake(idUser, txid, session, amount) VALUES (?, ?, ?, ?)", user.IDuser, txID.Txid, user.Session, credit)
					if errUpdate != nil {
						return utils.ReportError(c, errUpdate.Error(), http.StatusInternalServerError)
					}
				}
			} else {
			loopic:
				for _, v := range lastHour {
					if int64(v.IdUser) == user.IDuser {
						if user.Autostake == true {
							_, errUpdate := database.InsertSQl("UPDATE payouts_stake SET amount = amount + ?, datetime = ? WHERE id = ?", credit, dt, v.Id)
							_, errUpdate = database.InsertSQl("UPDATE users_stake SET amount = amount + ? WHERE idUser = ? AND active = 1", credit, user.IDuser)
							if errUpdate != nil {
								return utils.ReportError(c, errUpdate.Error(), http.StatusInternalServerError)
							}
							useric = true
							break loopic
						} else {
							_, errUpdate := database.InsertSQl("UPDATE payouts_stake SET amount = amount + ?, datetime = ? WHERE id = ?", credit, dt, v.Id)
							if errUpdate != nil {
								return utils.ReportError(c, errUpdate.Error(), http.StatusInternalServerError)
							}
							useric = true
							break loopic
						}
					}
				}
				if useric == false {
					if user.Autostake == true {
						_, errUpdate := database.InsertSQl("INSERT INTO payouts_stake(idUser, txid, session, amount, credited) VALUES (?, ?, ?, ?, ?)", user.IDuser, txID.Txid, user.Session, credit, 1)
						_, errUpdate = database.InsertSQl("UPDATE users_stake SET amount = amount + ? WHERE idUser = ? AND active = 1", credit, user.IDuser)
						if errUpdate != nil {
							return utils.ReportError(c, errUpdate.Error(), http.StatusInternalServerError)
						}
					} else {
						_, errUpdate := database.InsertSQl("INSERT INTO payouts_stake(idUser, txid, session, amount) VALUES (?, ?, ?, ?)", user.IDuser, txID.Txid, user.Session, credit)
						if errUpdate != nil {
							return utils.ReportError(c, errUpdate.Error(), http.StatusInternalServerError)
						}
					}
				}
			}
		}
		_, _ = database.InsertSQl("UPDATE transaction_stake SET credited = 1 WHERE txid = ?", txID.Txid)
		utils.ReportMessage(fmt.Sprintf("Stake transaction credited %s", txID.Txid))

	} else {
		_, _ = database.InsertSQl("INSERT INTO transaction_stake_wallet(txid, amount) VALUES (?, ?)", txID.Txid, txID.Amount)
		//if err != nil {
		//	//utils.ReportMessage(err.Error())
		//return utils.ReportErrorSilent(c, err.Error(), http.StatusBadRequest)
		//}
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
		_, _ = database.InsertSQl("UPDATE transaction SET confirmation = ? WHERE txid = ?", txinfo.Confirmations, txinfo.Txid)
		return utils.ReportErrorSilent(c, err.Error(), http.StatusBadRequest)
	}

	go func() {
		d := map[string]string{
			"fn": "sendTransaction",
		}
		trans, err := database.ReadArrayStruct[models.Transaction]("SELECT * FROM transaction WHERE notified = 0")
		if err != nil {
			utils.ReportMessage(err.Error())
			return
		}
		for _, data := range trans {
			if data.Amount < 0 {
				continue
			}
			userTo := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users WHERE addr = ?", data.Address)
			if userTo.Valid {
				type Token struct {
					Token string `json:"token"`
				}
				tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", userTo.Int64)
				if err != nil {
					utils.WrapErrorLog(err.Error())
				}

				if len(tk) > 0 {
					for _, v := range tk {
						utils.SendMessage(v.Token, fmt.Sprintf("Incoming transaction: "), fmt.Sprintf("%3f XDN", data.Amount), d)
					}
				}

			}
			_, err = database.InsertSQl("UPDATE transaction SET notified = 1 WHERE txid = ?", data.Txid)
		}
	}()
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func CheckStakeBalance() error {
	//dbBalance := database.ReadValueEmpty[float64]("SELECT SUM(AMOUNT) FROM transaction_stake_wallet WHERE 1")
	//checkBalanceDaemon, err := coind.WrapDaemon(utils.DaemonStakeWallet, 1, "getinfo")
	//if err != nil {
	//	utils.WrapErrorLog(err.Error())
	//	active, _ := exec.Command("bash", "-c", fmt.Sprintf("systemctl --user is-active %s", utils.DaemonStakeWallet.Folder)).Output()
	//	if strings.TrimSpace(string(active)) != "active" {
	//		_, _ = exec.Command("bash", "-c", fmt.Sprintf("systemctl --user restart %s", utils.DaemonStakeWallet.Folder)).Output()
	//	}
	//}
	//var inf models.GetInfo
	//err = json.Unmarshal(checkBalanceDaemon, &inf)
	//if err != nil {
	//	utils.WrapErrorLog(err.Error())
	//	return err
	//}
	//blkReqXDN, errNet := utils.GETAny("https://xdn-explorer.com/ext/getbalance/daZCF2oVwvfVg3WWqqCFq8k9WLuKbmUc5N")
	//if errNet != nil {
	//	utils.WrapErrorLog(errNet.ErrorMessage() + " " + strconv.Itoa(errNet.StatusCode()))
	//	return errors.New(errNet.ErrorMessage() + " " + strconv.Itoa(errNet.StatusCode()))
	//}
	//
	//bodyXDN, _ := io.ReadAll(blkReqXDN.Body)
	//defer func(Body io.ReadCloser) {
	//	err := Body.Close()
	//	if err != nil {
	//		utils.WrapErrorLog(err.Error())
	//	}
	//}(blkReqXDN.Body)
	//balanceDaemon, err := strconv.ParseFloat(string(bodyXDN), 64)
	//if err != nil {
	//	utils.WrapErrorLog(err.Error())
	//	return err
	//}
	//
	//if !(balanceDaemon < (dbBalance + 1)) || !(balanceDaemon > (dbBalance - 1)) {
	//	lastTX := database.ReadValueEmpty[float64]("SELECT amount FROM transaction_stake_wallet ORDER BY id DESC LIMIT 1")
	//	utils.ReportMessage(fmt.Sprintf("Stake balance is not equal | Daemon:%f Database: %f lastTX: %f second try", balanceDaemon, dbBalance, lastTX))
	//	s := balanceDaemon + lastTX
	//	if !(s < (dbBalance + (lastTX * 0.1))) || !(s > (dbBalance - (lastTX * 0.1))) {
	//		utils.ReportMessage(fmt.Sprintf("Stake balance is not equal | Daemon:%f Database: %f lastTX: %f", balanceDaemon, dbBalance, lastTX))
	//		return errors.New("stake balance is not equal")
	//	} else {
	//		utils.ReportMessage(fmt.Sprintf("Stake balance is equal %f %f", balanceDaemon, dbBalance))
	//		return nil
	//	}
	//}
	//utils.ReportMessage(fmt.Sprintf("Stake balance is equal %f %f", balanceDaemon, dbBalance))
	return nil
}
