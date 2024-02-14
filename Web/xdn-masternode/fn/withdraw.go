package fn

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
	"time"
	"xdn-masternode/coind"
	"xdn-masternode/database"
	"xdn-masternode/grpcClient"
	"xdn-masternode/grpcModels"
	"xdn-masternode/models"
	"xdn-masternode/utils"
)

func WithDraw(wdmn *grpcModels.WithdrawRequest) {
	daemon, _ := database.GetDaemon(int(wdmn.NodeID))
	folder := daemon.Folder
	conf := daemon.Conf

	if wdmn.Type == 1 {
		pathConf := utils.GetHomeDir() + "/." + folder + "/" + conf
		pathMn := utils.GetHomeDir() + "/." + folder + "/masternode.conf"

		_, errScript := exec.Command("bash", "-c", fmt.Sprintf("systemctl --user stop %s.service", folder)).Output()
		utils.ReportMessage("Daemon stopped")
		_, errScript = exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "masternode=", pathConf)).Output()
		_, errScript = exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "masternodeprivkey=", pathConf)).Output()
		_, errScript = exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "MN", pathMn)).Output()
		utils.ReportMessage("Configs edited")
		time.Sleep(5 * time.Second)
		_, errScript = exec.Command("bash", "-c", fmt.Sprintf("systemctl --user start %s.service", folder)).Output()
		if errScript != nil {
			utils.ReportMessage(errScript.Error())
			utils.WrapErrorLog("Config edit error")
			return
		}
		utils.ReportMessage("Daemon started")

		time.Sleep(30 * time.Second)
	}

	amount := 0.0
	res, err := coind.WrapDaemon(*daemon, 9, "listunspent")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	var ing []models.ListUnspent
	var firstParam []models.RawTxArray
	errJson := json.Unmarshal(res, &ing)
	if errJson != nil {
		utils.WrapErrorLog(errJson.Error())
		return
	}
	txArray := make([]string, 0)
	for _, unspent := range ing {
		if unspent.Spendable == true {
			if wdmn.Type == 0 && unspent.Amount > 1000 {
				continue
			}
			unspentArray := models.RawTxArray{
				Txid: unspent.Txid,
				Vout: unspent.Vout,
			}
			firstParam = append(firstParam, unspentArray)
			txArray = append(txArray, unspent.Txid)
			amount += unspent.Amount
		} else {
			utils.ReportMessage(fmt.Sprintf("%f %s", unspent.Amount, unspent.Txid))
		}
	}
	if daemon.CoinID == 0 || daemon.CoinID == 40 {
		amount = amount - 0.001
	} else {
		fee, err := coind.WrapDaemon(*daemon, 10, "getinfo")
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		var fees models.GetInfo
		errJson = json.Unmarshal(fee, &fees)
		if errJson != nil {
			utils.WrapErrorLog(errJson.Error())
			return
		}
		utils.ReportMessage(fmt.Sprintf("Fee: %f", fees.Paytxfee))
		amount = amount - fees.Paytxfee
	}

	if amount <= 0 {
		return
	}

	var txid string
	if daemon.CoinID == 0 || daemon.CoinID == 40 {
		utils.ReportMessage("==========================================================")
		utils.ReportMessage(fmt.Sprintf("Amount: %f", amount))
		utils.ReportMessage(fmt.Sprintf("%v+1", firstParam))
		utils.ReportMessage(fmt.Sprintf("%s", ""))
		utils.ReportMessage("Creating raw transaction")
		secondParam := map[string]interface{}{
			wdmn.Deposit: amount,
		}

		//utils.ReportMessage(fmt.Sprintf("firstParam: %v secondParam %v", firstParam, secondParam))

		call, err := coind.WrapDaemon(*daemon, 5, "createrawtransaction", firstParam, secondParam)
		if err != nil {
			//go snapInactive(daemon.Folder, daemon.CoinID)
			utils.WrapErrorLog(fmt.Sprintf("createrawtransaction error, addr: %s", wdmn.Deposit))
			return
		}
		//utils.ReportMessage(fmt.Sprintf("createrawtransaction: %s", string(call)))

		hex := strings.Trim(string(call), "\"")

		call, err = coind.WrapDaemon(*daemon, 5, "signrawtransaction", hex)
		if err != nil {
			utils.WrapErrorLog(fmt.Sprintf("signrawtransaction error, addr: %s", wdmn.Deposit))
			return
		}
		//utils.ReportMessage(fmt.Sprintf("signrawtransaction: %s", string(call)))

		var sign models.SignRawTransaction
		errJson = json.Unmarshal(call, &sign)
		if errJson != nil {
			utils.ReportMessage(errJson.Error())
			return
		}

		call, err = coind.WrapDaemon(*daemon, 5, "sendrawtransaction", sign.Hex)
		if err != nil {
			utils.WrapErrorLog(fmt.Sprintf("sendrawtransaction error, addr: %s", wdmn.Deposit))
			return
		}
		txid = strings.Trim(string(call), "\"")
		utils.ReportMessage(fmt.Sprintf("Send raw transaction: %s", txid))
		utils.ReportMessage("==========================================================")
	} else {
		time.Sleep(time.Second * 5)
		utils.ReportMessage(fmt.Sprintf("Amount: %v", amount))
		kunTX, er := coind.WrapDaemon(*daemon, 10, "sendtoaddress", wdmn.Deposit, amount)
		if er != nil {
			//go snapInactive(folder, daemon.CoinID)
			utils.WrapErrorLog("Sent to addr failed")
			return
		}
		txid = strings.Trim(string(kunTX), "\"")
		utils.ReportMessage(fmt.Sprintf("Send transaction: %s", txid))
		utils.ReportMessage("==========================================================")
	}

	utils.ReportMessage("Contacting server...")

	tx := &grpcModels.WithdrawConfirmRequest{
		NodeID: uint32(daemon.NodeID),
		TxID:   txid,
		TxArr:  txArray,
		Type:   wdmn.Type,
		Amount: amount,
	}
	confirm, err := grpcClient.WithdrawConfirm(tx)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	if confirm.Code != 200 {
		utils.WrapErrorLog("Withdraw confirm failed")
	} else {
		utils.ReportMessage("Success")
	}
	return
}
