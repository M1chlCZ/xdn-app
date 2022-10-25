package daemons

import (
	"time"
	"xdn-voting/database"
	"xdn-voting/models"
	"xdn-voting/utils"
	"xdn-voting/web3"
)

func SaveTokenTX() {
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
