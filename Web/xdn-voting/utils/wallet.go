package utils

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"xdn-voting/coind"
	"xdn-voting/database"
	"xdn-voting/models"
)

//var daemonWallet models.Daemon
//var daemonStakeWallet models.Daemon

func init() {

}

func sendCoin(addressReceive string, addressSend string, amount float64, stakeWallet bool) error {
	var wallet models.Daemon
	if stakeWallet {
		wallet = daemonStakeWallet
	} else {
		wallet = daemonWallet
	}
	wrapDaemon, err := coind.WrapDaemon(wallet, 5, "listunspent")
	if err != nil {
		ReportMessage(err.Error())
		return err
	}

	var ing []models.ListUnspent
	errJson := json.Unmarshal(wrapDaemon, &ing)
	if errJson != nil {
		WrapErrorLog(fmt.Sprintf("%v, addr: %s", errJson.Error(), addressReceive))
		return errJson
	}
	ReportMessage(fmt.Sprintf("Sending %f to %s from %s", amount, addressReceive, addressSend))
	totalCoins := 0.0
	myUnspent := make([]models.ListUnspent, 0)
	for _, unspent := range ing {
		if unspent.Address == addressSend {
			if unspent.Spendable == true {
				ReportMessage(fmt.Sprintf("Found unspent input: %f", unspent.Amount))
				totalCoins += unspent.Amount
				myUnspent = append(myUnspent, unspent)
			}
		}
	}

	inputs := make([]models.ListUnspent, 0)
	inputsAmount := 0.0
	for _, spent := range myUnspent {
		inputsAmount += spent.Amount
		inputs = append(inputs, spent)
		if inputsAmount > amount {
			break
		}
	}

	inputsCount := len(inputs)
	fee := 0.0001 * float64(inputsCount)
	txBack := inputsAmount - fee - amount

	if totalCoins <= (amount + fee) {
		WrapErrorLog(fmt.Sprintf("not enough coins, addr: %s", addressReceive))
		return errors.New("not enough coins")
	}

	var firstParam []models.RawTxArray
	for _, input := range inputs {
		fparam := models.RawTxArray{
			Txid: input.Txid,
			Vout: input.Vout,
		}
		firstParam = append(firstParam, fparam)
	}

	secondParam := map[string]interface{}{
		addressReceive: amount,
		addressSend:    txBack}

	ReportMessage(fmt.Sprintf("firstParam: %v secondParam %v", firstParam, secondParam))

	call, err := coind.WrapDaemon(wallet, 1, "createrawtransaction", firstParam, secondParam)
	if err != nil {
		WrapErrorLog(fmt.Sprintf("createrawtransaction error, addr: %s", addressReceive))
		return errors.New("createrawtransaction error")
	}
	ReportMessage(fmt.Sprintf("createrawtransaction: %s", string(call)))

	hex := strings.Trim(string(call), "\"")

	call, err = coind.WrapDaemon(wallet, 1, "signrawtransaction", hex)
	if err != nil {
		WrapErrorLog(fmt.Sprintf("signrawtransaction error, addr: %s", addressReceive))
		return errors.New("signrawtransaction error")
	}
	ReportMessage(fmt.Sprintf("signrawtransaction: %s", string(call)))

	var sign models.SignRawTransaction
	errJson = json.Unmarshal(call, &sign)
	if errJson != nil {
		ReportMessage(errJson.Error())
		return errJson
	}

	call, err = coind.WrapDaemon(wallet, 1, "sendrawtransaction", sign.Hex)
	if err != nil {
		WrapErrorLog(fmt.Sprintf("sendrawtransaction error, addr: %s", addressReceive))
		return errors.New("sendrawtransaction error")
	}
	ReportMessage(fmt.Sprintf("sendrawtransaction: %s", string(call)))

	tx := strings.Trim(string(call), "\"")
	userSend, _ := database.ReadValue[sql.NullString]("SELECT username FROM users WHERE addr = ?", addressSend)
	userReceive, _ := database.ReadValue[sql.NullString]("SELECT username FROM users WHERE addr = ?", addressReceive)
	_, errInsert := database.InsertSQl("INSERT INTO transaction(txid, account, amount, confirmation, address, category) VALUES (?, ?, ?, ?, ?, ?)", tx, userSend.String, amount*-1, 0, addressSend, "send")
	if errInsert != nil {
		WrapErrorLog(fmt.Sprintf("insert transaction error, addr: %s error %s", addressReceive, errInsert.Error()))
		return errInsert
	}
	if userReceive.Valid {
		_, errInsert2 := database.InsertSQl("INSERT INTO transaction(txid, account, amount, confirmation, address, category) VALUES (?, ?, ?, ?, ?, ?)", tx, userReceive.String, amount, 0, addressReceive, "receive")
		if errInsert2 != nil {
			WrapErrorLog(fmt.Sprintf("insert transaction error, addr: %s error: %s", addressReceive, errInsert2.Error()))
			return errInsert
		}
	}
	return nil
}
