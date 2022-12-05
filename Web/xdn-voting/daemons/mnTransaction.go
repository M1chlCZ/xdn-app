package daemons

import (
	"database/sql"
	"fmt"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"xdn-voting/database"
	"xdn-voting/grpcModels"
	"xdn-voting/models"
	"xdn-voting/utils"
)

func MNTransaction() {
	go func() {
		_, errUpdate := database.InsertSQl("UPDATE mn_incoming_tx SET confirmations = confirmations + 1 WHERE processed = 0")
		if errUpdate != nil {
			utils.WrapErrorLog(errUpdate.Error())
			return
		}
		readSql, errSelect := database.ReadSql("SELECT a.id as wallet_id, b.id as incoming_id, b.idCoin, b.idUser, a.amount, b.idNode, a.tx_id FROM masternode_tx as a, mn_incoming_tx as b, mn_info as c WHERE a.amount = b.amount AND a.idCoin = b.idCoin AND a.idNode = b.idNode AND a.processed = 0 AND b.processed = 0 AND b.confirmations > c.confirmations AND a.idCoin = c.idCoin LIMIT 1")
		if errSelect != nil {
			utils.WrapErrorLog(errSelect.Error())
			return
		}
		countSel := 0
		countArray := make([]models.MnVerify, 0)
		for readSql.Next() == true {
			var verify models.MnVerify
			countSel++
			if err := readSql.StructScan(&verify); err != nil {
				utils.WrapErrorLog(err.Error())
				return
			} else {
				countArray = append(countArray, verify)
			}
		}
		_ = readSql.Close()
		if countSel != 0 {
			for _, verify := range countArray {

				idUser := verify.IdUser
				idCoin := verify.IdCoin
				incomingtxid := verify.IncomingTXID
				wallettxid := verify.WalletTXID
				idNode := verify.NodeID
				txID := verify.TXID
				amount := verify.Amount

				ur, errCrypt := database.ReadValue[string]("SELECT node_ip FROM mn_clients WHERE id = ?", idNode)
				//tk, errCrypt := database.ReadValue[string]("SELECT token FROM mn_server WHERE url = ?", ur)
				//en, errCrypt := database.ReadValue[string]("SELECT encryptKey FROM mn_server WHERE url = ?", ur)
				if errCrypt != nil {
					utils.WrapErrorLog(errCrypt.Error())
					return
					//return nil, "", errCrypt
				}

				var smax int64 = 0
				nodeSession, err := database.ReadValue[sql.NullInt64]("SELECT MAX(session) as smax FROM users_mn WHERE idNode = ?", idNode)
				if nodeSession.Valid {
					smax = nodeSession.Int64 + 1
				}
				tier := 0
				t, _ := database.ReadValue[sql.NullInt64]("SELECT id FROM mn_info WHERE collateral = ? AND idCoin = ?", int(amount), idCoin)
				if t.Valid {
					tier = int(t.Int64)
				}

				_, errUpdate := database.InsertSQl("INSERT INTO users_mn(idUser, idCoin, tier, idNode, session) VALUES (?, ?, ?, ?, ?)", idUser, idCoin, tier, idNode, smax)

				_, errUpdate = database.InsertSQl("UPDATE masternode_tx SET idUser = ? WHERE id = ?", idUser, wallettxid)
				_, errUpdate = database.InsertSQl("UPDATE masternode_tx SET processed = 1 WHERE id = ?", wallettxid)
				_, errUpdate = database.InsertSQl("UPDATE mn_incoming_tx SET processed = 1 WHERE id = ?", incomingtxid)
				_, errUpdate = database.InsertSQl("UPDATE mn_incoming_tx SET tx_id = ? WHERE id = ?", txID, incomingtxid)
				if errUpdate != nil {
					utils.WrapErrorLog(errUpdate.Error())
					return
				}
				user, _ := database.ReadValue[string]("SELECT username FROM users WHERE id = ?", idUser)
				utils.ReportMessage(fmt.Sprintf("Starting masternode for CoinID: %d & User: %s (id: %d) NODE id: %d", idCoin, user, idUser, idNode))

				_, errUpdate = database.InsertSQl("UPDATE mn_clients SET active = 1 WHERE id = ?", idNode)
				if errUpdate != nil {
					utils.WrapErrorLog(errUpdate.Error())
					return
				}

				grpcCon, err := grpc.Dial(fmt.Sprintf("%s:6810", ur), grpc.WithTransportCredentials(insecure.NewCredentials()))
				if err != nil {
					utils.WrapErrorLog(err.Error())
					return
				}
				c := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
				_, err = c.StartMasternode(context.Background(), &grpcModels.StartMasternodeRequest{
					NodeID: uint32(idNode),
				})
				if err != nil {
					utils.WrapErrorLog(err.Error())
					return
				}
				//TODO withdraw if problem
				//if resp.Code == 409 {
				//	var w models.WithdrawMNReq
				//	w.NodeId = idNode
				//	w.Amount = 10000
				//	w.Type = 1
				//	depositAddr, _ := database.ReadValue[string]("SELECT addr FROM deposit_addr WHERE idUser = ?", idUser)
				//	w.Deposit = depositAddr
				//
				//	payload, _ := json.Marshal(w)
				//	encryptPayload, err := encrypt.EncryptMessage(en, payload)
				//	if err != nil {
				//		utils.ReportMessage(fmt.Sprintf("err: %v\n", err))
				//		utils.ReportMessage(err.Error())
				//		return
				//	}
				//
				//	_, errClient := utils.ContactClient(ur, "/masternode/withdraw", tk, []byte(encryptPayload))
				//	if errClient != nil {
				//		utils.ReportMessage(fmt.Sprintf("err: %v\n", errClient))
				//		utils.ReportMessage(errClient.ErrorMessage())
				//		return
				//	}
				//
				//}
				_ = grpcCon.Close()
				utils.ReportMessage("Successfully started Masternode")
			}

		}
	}()

}
