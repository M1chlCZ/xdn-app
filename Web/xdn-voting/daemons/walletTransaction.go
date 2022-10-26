package daemons

import (
	"encoding/json"
	"xdn-voting/coind"
	"xdn-voting/database"
	"xdn-voting/models"
	"xdn-voting/utils"
)

func SaveTransactions() {
	//utils.ReportMessage("Saving transactions")
	tx, err := coind.WrapDaemon(utils.DaemonWallet, 5, "listtransactions", "*", 100)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	var list models.ListTransactions
	err = json.Unmarshal(tx, &list)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	for _, txinfo := range list {
		//account := txinfo.Account
		if txinfo.Amount < 0 && txinfo.Category == "receive" {
			continue
		}
		address := txinfo.Address
		var empty models.Transaction
		txPrev := database.ReadStructEmpty[models.Transaction]("SELECT * FROM transaction WHERE txid = ?", txinfo.Txid)
		if txPrev != empty {
			if txPrev.Txid == txinfo.Txid {
				if txPrev.Address == address {
					_, err = database.InsertSQl("UPDATE transaction SET confirmation = ? WHERE txid = ?", txinfo.Confirmations, txinfo.Txid)
					if err != nil {
						utils.ReportMessage(err.Error())
					}
					continue
				}
			}
		}
		//stake wallet
		if address == "dW8VEXurvxeJ1dMer6JoR6RSb3u3MnmMQW" {
			continue
		}
		_, err = database.InsertSQl("INSERT INTO transaction(txid, account, amount, confirmation, address, category) VALUES (?, ?, ?, ?, ?, ?)", txinfo.Txid, txinfo.Account, txinfo.Amount, txinfo.Confirmations, txinfo.Address, "receive")
		if err != nil {
			//utils.ReportMessage(err.Error())
			_, err = database.InsertSQl("UPDATE transaction SET confirmation = ? WHERE txid = ?", txinfo.Confirmations, txinfo.Txid)
			if err != nil {
				utils.ReportMessage(err.Error())
			}
		}
	}
}

func SaveAllTransactions() {
	tx, err := coind.WrapDaemon(utils.DaemonWallet, 5, "listtransactions", "*", 99999999)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	var list models.ListTransactions
	err = json.Unmarshal(tx, &list)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	for _, txinfo := range list {
		//account := txinfo.Account

		if txinfo.Amount < 0 && txinfo.Category == "receive" {
			continue
		}

		address := txinfo.Address
		var empty models.Transaction
		txPrev := database.ReadStructEmpty[models.Transaction]("SELECT * FROM transaction WHERE txid = ?", txinfo.Txid)
		if txPrev != empty {
			if txPrev.Txid == txinfo.Txid {
				if txPrev.Address == address {
					_, err = database.InsertSQl("UPDATE transaction SET confirmation = ? WHERE txid = ?", txinfo.Confirmations, txinfo.Txid)
					if err != nil {
						utils.ReportMessage(err.Error())
					}
					continue
				}
			}
		}
		//stake wallet
		if address == "dW8VEXurvxeJ1dMer6JoR6RSb3u3MnmMQW" {
			continue
		}
		_, err = database.InsertSQl("INSERT INTO transaction(txid, account, amount, confirmation, address, category) VALUES (?, ?, ?, ?, ?, ?)", txinfo.Txid, txinfo.Account, txinfo.Amount, txinfo.Confirmations, txinfo.Address, "receive")
		if err != nil {
			//utils.ReportMessage(err.Error())
			_, err = database.InsertSQl("UPDATE transaction SET confirmation = ? WHERE txid = ?", txinfo.Confirmations, txinfo.Txid)
			if err != nil {
				utils.ReportMessage(err.Error())
			}
		}
	}
}
