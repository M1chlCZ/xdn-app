package grpcModels

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log"
	"time"
	"xdn-voting/coind"
	"xdn-voting/database"
	"xdn-voting/models"
	"xdn-voting/utils"
)

type Server struct {
	UnimplementedTransactionServiceServer
	UnimplementedRegisterServiceServer
	UnimplementedRegisterMasternodeServiceServer
}

func (s *Server) SubmitTX(_ context.Context, txDaemon *SubmitRequest) (*Response, error) {
	utils.ReportMessage(fmt.Sprintf("TX %s", txDaemon.TxId))
	var id int64
	var errUpdate error
	if txDaemon.Generated == true {
		amountMain := txDaemon.Amount + txDaemon.Fee
		amount := amountMain * 0.75
		amountFee := amountMain - amount
		id, errUpdate = database.InsertSQl("INSERT INTO masternode_tx(tx_id, idCoin, idNode, amount, mn_tx) VALUES(?, ?, ?, ?, ?)", txDaemon.TxId, txDaemon.IdCoin, txDaemon.NodeId, amount, txDaemon.Generated)
		if errUpdate != nil {
			utils.WrapErrorLog(errUpdate.Error())
			return &Response{Code: 400}, errUpdate
		}
		_, _ = database.InsertSQl("INSERT INTO mn_tx_fees(tx_id, idCoin, idNode, amount, mn_tx) VALUES(?, ?, ?, ?, ?)", txDaemon.TxId, txDaemon.IdCoin, txDaemon.NodeId, amountFee, txDaemon.Generated)
	} else {
		amount := txDaemon.Amount + txDaemon.Fee
		id, errUpdate = database.InsertSQl("INSERT INTO masternode_tx(tx_id, idCoin, idNode, amount, mn_tx) VALUES(?, ?, ?, ?, ?)", txDaemon.TxId, txDaemon.IdCoin, txDaemon.NodeId, amount, txDaemon.Generated)
		if errUpdate != nil {
			utils.WrapErrorLog(errUpdate.Error())
			return &Response{Code: 400}, errUpdate
		}
	}

	if txDaemon.Generated == true {
		s, errDB := database.ReadSql("SELECT * FROM masternode_tx WHERE id = ?", id)
		if errDB != nil {
			utils.WrapErrorLog(errDB.Error())
			return &Response{Code: 400}, errUpdate
		}
		var txRes models.WalletMNTX
		for s.Next() {
			if err := s.StructScan(&txRes); err != nil {
				utils.WrapErrorLog(err.Error())
				return &Response{Code: 400}, errUpdate
			}

			readUsers, errDB := database.ReadSql("SELECT idUser, session FROM users_mn WHERE active = 1 AND idCoin = ? AND idNode = ?", txRes.IdCoin, txRes.IdNode)
			if errDB != nil {
				utils.WrapErrorLog(errDB.Error())
				return &Response{Code: 400}, errUpdate
			}
			type ReadUsers struct {
				IdUser  sql.NullInt64 `db:"idUser"`
				Session sql.NullInt64 `db:"session"`
			}

			for readUsers.Next() {
				var ru ReadUsers
				if err := readUsers.StructScan(&ru); err != nil {
					utils.WrapErrorLog(errDB.Error())
					return &Response{Code: 400}, errUpdate
				}
				idUser := ru.IdUser.Int64
				session := ru.Session.Int64

				dt := time.Now().UTC().Format("2006-01-02 15:04:05")
				_, errUpdate := database.InsertSQl("INSERT INTO payouts_masternode(idUser, idCoin, idNode, tx_id, session, amount, datetime) VALUES (?, ?, ?, ?, ?, ?, ?)", idUser, txRes.IdCoin, txRes.IdNode, txRes.TXID, session, txRes.Amount, dt)
				if errUpdate != nil {
					utils.WrapErrorLog(errUpdate.Error())
					return &Response{Code: 400}, errUpdate
				}
				_, errUpdate = database.InsertSQl("UPDATE masternode_tx SET idUser = ? WHERE id = ?", ru.IdUser, id)
				user, _ := database.ReadValue[string]("SELECT nickname FROM users WHERE id = ?", idUser)
				utils.ReportMessage(fmt.Sprintf("-{ MN TX from node id: %d added, coin id: %s amount: %f | user: %s (uid: %d)}-", txDaemon.NodeId, txDaemon.IdCoin, txRes.Amount, user, ru.IdUser.Int64))
			}
			_ = readUsers.Close()
			_, errUpdate = database.InsertSQl("UPDATE masternode_tx SET processed = 1 WHERE id = ?", id)
			if errUpdate != nil {
				utils.WrapErrorLog(errUpdate.Error())
				return &Response{Code: 400}, errUpdate
			}

		}

		_ = s.Close()
	}
	return &Response{Code: 200}, nil
}

func (s *Server) Register(_ context.Context, request *RegisterRequest) (*RegisterResponse, error) {
	encryptKey := utils.GenerateSecureToken(8)

	_, errInsert := database.InsertSQl("INSERT INTO mn_server(token, url, encryptKey) VALUES(?, ?, ?)", request.Token, request.Url, encryptKey)

	if errInsert != nil {
		utils.WrapErrorLog(errInsert.Error())
		return &RegisterResponse{Code: 400, Encrypt: "FUCK OFF"}, errInsert
	}
	utils.ReportMessage(fmt.Sprintf("NODE %s", request.Url))
	return &RegisterResponse{Code: 200, Encrypt: encryptKey}, nil
}

func (s *Server) RegisterMasternode(_ context.Context, request *RegisterMasternodeRequest) (*RegisterMasternodeResponse, error) {
	lastID, errInsertToken := database.InsertSQl("INSERT INTO mn_clients(wallet_usr, wallet_pass, wallet_port, node_ip, coin_id, address, folder, conf, ip, priv_key) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", request.WalletUSR, request.WalletPass, request.WalletPort, request.NodeIP, request.CoinID, request.Address, request.Folder, request.Conf, request.NodeIP, request.PrivKey)
	if errInsertToken != nil {
		utils.WrapErrorLog(errInsertToken.Error())
		return &RegisterMasternodeResponse{Code: 400, NodeID: 0}, errInsertToken
	}
	utils.ReportMessage(fmt.Sprintf("New MN registered %d", lastID))
	return &RegisterMasternodeResponse{Code: 200, NodeID: uint32(lastID)}, nil
}

func (s *Server) GetPrivateKey(_ context.Context, request *GetPrivateKeyRequest) (*GetPrivateKeyResponse, error) {
	keyDB, err := database.ReadValue[string]("SELECT priv_key FROM mn_clients WHERE id = ?", request.NodeID)
	if err != nil {
		log.Printf("err: %v\n", err)
		log.Println(err)
		return &GetPrivateKeyResponse{Code: 400, PrivKey: ""}, err
	}
	return &GetPrivateKeyResponse{Code: 200, PrivKey: keyDB}, nil
}

func (s *Server) WithdrawConfirm(_ context.Context, txDaemon *WithdrawConfirmRequest) (*WithdrawConfirmResponse, error) {
	if txDaemon.Type == 1 {
		utils.ReportMessage(fmt.Sprintf("! Full Withdraw: Updating DB | Node id: %d !", txDaemon.NodeID))
		userid, _ := database.ReadValue[int64]("SELECT idUser FROM users_mn WHERE idNode = ? AND active = 1", txDaemon.NodeID)
		coinid, _ := database.ReadValue[int64]("SELECT idCoin FROM users_mn WHERE idNode = ? AND active = 1", txDaemon.NodeID)
		depAddr, _ := database.ReadValue[string]("SELECT addr FROM deposit_addr WHERE idUser = ? AND idCoin = ?", userid, coinid) //todo check if this is correct
		amnt, _ := database.ReadValue[float64]("SELECT IFNULL(SUM(amount), 0) as amount FROM payouts_masternode WHERE idNode = ? AND credited = 0", txDaemon.NodeID)
		collateral, _ := database.ReadValue[int]("SELECT collateral FROM mn_info WHERE idCoin = ?", coinid)

		_, errUpdate := database.InsertSQl("UPDATE mn_clients SET locked = 0, active = 0 WHERE id = ?", txDaemon.NodeID)
		_, errUpdate = database.InsertSQl("UPDATE mn_clients SET last_seen = NULL, active_time = NULL WHERE id = ?", txDaemon.NodeID)
		_, errUpdate = database.InsertSQl("UPDATE users_mn SET active = 0 WHERE idNode = ? AND id <> 0", txDaemon.NodeID)

		amountToSend := amnt - (txDaemon.Amount - float64(collateral))
		if amountToSend <= 0.0 {
			return &WithdrawConfirmResponse{
				Code: 400,
			}, errors.New("amount need to be more than 0")
		}
		utils.ReportMessage(fmt.Sprintf("! Remaining amount to send: %f !", amountToSend))
		server, err := database.ReadValue[string]("SELECT addr FROM servers_stake WHERE id = 1")
		if err != nil {
			return &WithdrawConfirmResponse{
				Code: 400,
			}, err
		}
		tx, err := coind.SendCoins(depAddr, server, amountToSend, true)
		if err != nil {
			return &WithdrawConfirmResponse{
				Code: 400,
			}, err
		}
		utils.ReportMessage(fmt.Sprintf("! Full Withdraw: TX %s !", tx))

		_, errUpdate = database.InsertSQl("UPDATE payouts_masternode SET credited = 1 WHERE idNode = ? AND idCoin = ? AND id <> 0", txDaemon.NodeID, coinid)
		if errUpdate != nil {
			return &WithdrawConfirmResponse{
				Code: 400,
			}, errUpdate
		}
	} else {
		for _, tx := range txDaemon.TxArr {
			//utils.ReportMessage(tx)
			_, errUpdate := database.InsertSQl("UPDATE payouts_masternode SET transferred = 1 WHERE tx_id = ? AND id <> 0", tx)
			if errUpdate != nil {
				utils.WrapErrorLog(errUpdate.Error())
				continue
			}
		}
	}

	return &WithdrawConfirmResponse{Code: 200}, nil
}

func (s *Server) MasternodeActive(_ context.Context, request *MasternodeActiveRequest) (*MasternodeActiveResponse, error) {
	type ActiveMN struct {
		ID     int64 `json:"id"`
		Active int   `json:"active"`
	}

	returnListArr, err := database.ReadArrayStruct[ActiveMN]("SELECT id, active FROM mn_clients WHERE node_ip = ?", request.Url)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return &MasternodeActiveResponse{Mn: nil}, err
	}
	active := make([]*MasternodeActiveResponse_Mn, 0)
	for _, mn := range returnListArr {
		active = append(active, &MasternodeActiveResponse_Mn{Id: uint32(mn.ID), Active: uint32(mn.Active)})
	}
	return &MasternodeActiveResponse{Mn: active}, nil
}

func (s *Server) LastSeen(_ context.Context, request *LastSeenRequest) (*LastSeenResponse, error) {
	for _, ls := range request.Items {
		_, errDB := database.InsertSQl("UPDATE mn_clients SET last_seen = ?, active_time = ? WHERE id = ?", ls.LastSeen, ls.ActiveTime, ls.Id)
		if errDB != nil {
			utils.ReportMessage(errDB.Error())
		}
	}
	return &LastSeenResponse{Code: 200}, nil
}
