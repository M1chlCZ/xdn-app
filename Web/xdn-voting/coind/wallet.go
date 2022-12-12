package coind

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
	"xdn-voting/database"
	"xdn-voting/models"
	"xdn-voting/utils"
)

func init() {

}

func SendCoins(addressReceive string, addressSend string, amount float64, stakeWallet bool) (string, error) {
	var wallet models.Daemon
	if stakeWallet {
		wallet = utils.DaemonStakeWallet
	} else {
		wallet = utils.DaemonWallet
	}
	wrapDaemon, err := WrapDaemon(wallet, 3, "listunspent")
	if err != nil {
		utils.ReportMessage(err.Error())
		return "", err
	}

	var ing []models.ListUnspent
	errJson := json.Unmarshal(wrapDaemon, &ing)
	if errJson != nil {
		utils.WrapErrorLog(fmt.Sprintf("%v, addr: %s", errJson.Error(), addressReceive))
		return "", errJson
	}
	utils.ReportMessage(fmt.Sprintf("Sending %f to %s from %s", amount, addressReceive, addressSend))
	totalCoins := 0.0
	myUnspent := make([]models.ListUnspent, 0)
	for _, unspent := range ing {
		if unspent.Address == addressSend {
			if unspent.Spendable == true {
				//utils.ReportMessage(fmt.Sprintf("Found unspent input: %f", unspent.Amount))
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
	fee := 0.01 * float64(inputsCount)
	amountSend := amount - fee
	txBack := inputsAmount - amountSend

	//g

	var firstParam []models.RawTxArray
	for _, input := range inputs {
		fparam := models.RawTxArray{
			Txid: input.Txid,
			Vout: input.Vout,
		}
		firstParam = append(firstParam, fparam)
	}

	secondParam := map[string]interface{}{
		addressReceive: amountSend,
		addressSend:    txBack}

	//utils.ReportMessage(fmt.Sprintf("firstParam: %v secondParam %v", firstParam, secondParam))
	if wallet.PassPhrase.Valid {
		_, _ = WrapDaemon(wallet, 1, "walletpassphrase", wallet.PassPhrase.String, 100)
	}

	call, err := WrapDaemon(wallet, 1, "createrawtransaction", firstParam, secondParam)
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("createrawtransaction error, addr: %s", addressReceive))
		return "", errors.New("createrawtransaction error")
	}
	//utils.ReportMessage(fmt.Sprintf("createrawtransaction: %s", string(call)))

	hex := strings.Trim(string(call), "\"")
	time.Sleep(1 * time.Second)
	call, err = WrapDaemon(wallet, 1, "signrawtransaction", hex)
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("signrawtransaction error, addr: %s", addressReceive))
		return "", errors.New("signrawtransaction error")
	}
	//utils.ReportMessage(fmt.Sprintf("signrawtransaction: %s", string(call)))

	var sign models.SignRawTransaction
	errJson = json.Unmarshal(call, &sign)
	if errJson != nil {
		utils.ReportMessage(errJson.Error())
		return "", errJson
	}
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("signrawtransaction error, addr: %s", addressReceive))
		return "", errors.New("signrawtransaction error")
	}
	call, err = WrapDaemon(wallet, 1, "sendrawtransaction", sign.Hex)
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("sendrawtransaction error, addr: %s", addressReceive))
		return "", errors.New("sendrawtransaction error")
	}
	utils.ReportMessage(fmt.Sprintf("sendrawtransaction: %s", string(call)))
	tx := strings.Trim(string(call), "\"")
	if wallet.PassPhrase.Valid {
		call, err = WrapDaemon(wallet, 1, "walletlock")
	}
	if tx == "" {
		utils.WrapErrorLog(fmt.Sprintf("sendrawtransaction error, addr: %s", addressReceive))
		return "", errors.New("sendrawtransaction error")
	}
	if !stakeWallet {
		userSend := database.ReadValueEmpty[sql.NullString]("SELECT username FROM users WHERE addr = ?", addressSend)
		if userSend.Valid {
			_, errInsert := database.InsertSQl("INSERT INTO transaction(txid, account, amount, confirmation, address, category) VALUES (?, ?, ?, ?, ?, ?)", tx, userSend.String, amount*-1, 0, addressSend, "send")
			if errInsert != nil {
				utils.WrapErrorLog(fmt.Sprintf("insert transaction error, addr: %s error %s", addressReceive, errInsert.Error()))
				//return "", errInsert
			}
		}
		if wallet.PassPhrase.Valid {
			_, _ = WrapDaemon(wallet, 1, "walletlock")
		}
	} else {
		go deferWalletLock(wallet)
	}
	userReceive := database.ReadValueEmpty[sql.NullString]("SELECT username FROM users WHERE addr = ?", addressReceive)
	if userReceive.Valid {
		_, errInsert2 := database.InsertSQl("INSERT INTO transaction(txid, account, amount, confirmation, address, category) VALUES (?, ?, ?, ?, ?, ?)", tx, userReceive.String, amount, 0, addressReceive, "receive")
		if errInsert2 != nil {
			utils.WrapErrorLog(fmt.Sprintf("insert transaction error, addr: %s error: %s", addressReceive, errInsert2.Error()))
			//return "", errInsert2
		}
	}
	return tx, nil
}

var sec = 0

func deferWalletLock(daemon models.Daemon) {
	if sec == 0 {
		go lockWalletStake(daemon)
	}
	sec = 5
}

func lockWalletStake(daemon models.Daemon) {
	for {
		time.Sleep(time.Second * 1)
		sec--
		utils.ReportMessage(fmt.Sprintf("sec remaining: %d", sec))
		if sec <= 0 {
			_, _ = WrapDaemon(daemon, 1, "walletpassphrase", daemon.PassPhrase.String, 99999999, true)
			utils.ReportMessage("LOCKED STAKE WALLET")
			break
		}
	}
}
