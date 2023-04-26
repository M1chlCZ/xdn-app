package daemons

import (
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
	"xdn-voting/coind"
	"xdn-voting/models"
	"xdn-voting/utils"
)

func StartGroupDaemon() {
	groupTX()
}

func groupTX() {
	utils.ReportMessage("Grouping TX")
	dm := utils.DaemonStakeWallet
	avoid := false
	address := "daZCF2oVwvfVg3WWqqCFq8k9WLuKbmUc5N"
	groupAmount := 200000.0
	utils.ReportMessage(fmt.Sprintf("GROUP ADDRESS %s", address))
	utils.ReportMessage(fmt.Sprintf("GROUP AMOUNT %f", groupAmount))

outerLoop:
	for {
		amount := 0.0
		numberOfInputs := 0
		finalInputs := make(models.ListUnspentArr, 0)
		res, err := coind.WrapDaemon(dm, 1, "listunspent")
		if err != nil {
			utils.WrapErrorLog(err.Error())
			time.Sleep(time.Second * 60)
			continue
		}
		var ing models.ListUnspentArr
		errJson := json.Unmarshal(res, &ing)
		if errJson != nil {
			utils.WrapErrorLog(errJson.Error())
			return
		}
		sort.Slice(ing, func(i, j int) bool {
			return ing[i].Amount < ing[j].Amount
		})
	innerLoop:
		for _, unspent := range ing {
			if avoid {
				if unspent.Address == address {
					utils.ReportMessage("Same address")
					continue
				}
			}
			if numberOfInputs == 50 || amount > groupAmount {
				break innerLoop
			}
			if unspent.Spendable && (unspent.Amount+amount) < groupAmount {
				finalInputs = append(finalInputs, unspent)
				amount += unspent.Amount
				numberOfInputs++
			}
		}
		if numberOfInputs <= 1 {
			break outerLoop
		}
		utils.ReportMessage(fmt.Sprintf("Amount %f, %d UTXO, deposit addr %s", amount, numberOfInputs, address))
		//tx := &grpcModels.WithdrawStakeCoinsRequest{
		//	IdCoin:        uint32(dm.CoinID),
		//	Address:       address,
		//	AddressDeamon: "",
		//	Amount:        float32(amount),
		//}
		//_, errSend := stakeFunc.WithStaking(tx)
		_, errSend := sendCoinsGroup(finalInputs, address, address, amount)
		if errSend != nil {
			utils.WrapErrorLog("No spendable outputs, waiting 360 seconds before trying again")
			time.Sleep(time.Second * 360)
		}
		time.Sleep(time.Second * 30)
	}

	utils.ReportMessage("GroupTX done")
	waitUntilReady()
}

func waitUntilReady() {
	utils.ReportMessage("Waiting 12 hour to get another UTXO to group")
	time.Sleep(time.Hour * 12)
	groupTX()
}

func sendCoinsGroup(finalUnspent models.ListUnspentArr, addressReceive, addressSend string, amountSend float64) (string, error) {
	var firstParam []models.RawTxArray
	for _, input := range finalUnspent {
		fparam := models.RawTxArray{
			Txid: input.Txid,
			Vout: input.Vout,
		}
		firstParam = append(firstParam, fparam)
	}

	type SecondParam struct {
		Address    string
		Amount     float64
		AdressSend string
		AmountSend float64
	}

	secondParam := map[string]interface{}{
		addressReceive: amountSend,
		addressSend:    amountSend}
	//secondParam := SecondParam{
	//	Address:    addressReceive,
	//	Amount:     amountSend,
	//	AdressSend: addressSend,
	//	AmountSend: 0.0,
	//}

	//{MDv5otvTX44hk5NZYvqo4mHgwjtRnjhkWC 1995.5139643 MDv5otvTX44hk5NZYvqo4mHgwjtRnjhkWC 0}

	wallet := utils.DaemonStakeWallet
	//utils.ReportMessage(fmt.Sprintf("firstParam: %v secondParam %v", firstParam, secondParam))
	if wallet.PassPhrase.Valid {
		_, _ = coind.WrapDaemon(wallet, 1, "walletpassphrase", wallet.PassPhrase.String, 100)
	}

	call, err := coind.WrapDaemon(wallet, 2, "createrawtransaction", firstParam, secondParam)
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("createrawtransaction error, addr: %s", addressReceive))
		return "", errors.New("createrawtransaction error")
	}
	//utils.ReportMessage(fmt.Sprintf("createrawtransaction: %s", string(call)))

	hex := strings.Trim(string(call), "\"")
	time.Sleep(1 * time.Second)
	call, err = coind.WrapDaemon(wallet, 2, "signrawtransaction", hex)
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("signrawtransaction error, addr: %s", addressReceive))
		return "", errors.New("signrawtransaction error")
	}
	//utils.ReportMessage(fmt.Sprintf("signrawtransaction: %s", string(call)))

	var sign models.SignRawTransaction
	errJson := json.Unmarshal(call, &sign)
	if errJson != nil {
		utils.ReportMessage(errJson.Error())
		return "", errJson
	}
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("signrawtransaction error, addr: %s", addressReceive))
		return "", errors.New("signrawtransaction error")
	}
	call, err = coind.WrapDaemon(wallet, 2, "sendrawtransaction", sign.Hex)
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("sendrawtransaction error, addr: %s", addressReceive))
		return "", errors.New("sendrawtransaction error")
	}
	utils.ReportMessage(fmt.Sprintf("sendrawtransaction: %s", string(call)))
	tx := strings.Trim(string(call), "\"")
	if wallet.PassPhrase.Valid {
		call, err = coind.WrapDaemon(wallet, 1, "walletlock")
		if err != nil {
			//utils.WrapErrorLog(fmt.Sprintf("walletlock error, addr: %s", addressReceive))
			//return "", errors.New("walletlock error")
		}
	}
	if wallet.PassPhrase.Valid {
		call, err = coind.WrapDaemon(wallet, 1, "walletpassphrase", wallet.PassPhrase.String, 999999999, true)
		if err != nil {
			//utils.WrapErrorLog(fmt.Sprintf("walletpassphrase error, addr: %s", addressReceive))
			//return "", errors.New("walletpassphrase error")
		}
	}
	if tx == "" {
		utils.WrapErrorLog(fmt.Sprintf("sendrawtransaction error, addr: %s", addressReceive))
		return "", errors.New("sendrawtransaction error")
	}
	return tx, nil
}
