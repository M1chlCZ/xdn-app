package grpc

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
	"xdn-voting/coind"
	"xdn-voting/database"
	"xdn-voting/grpcModels"
	"xdn-voting/models"
	"xdn-voting/utils"
)

type Server struct {
	grpcModels.UnimplementedTransactionServiceServer
	grpcModels.UnimplementedRegisterServiceServer
	grpcModels.UnimplementedRegisterMasternodeServiceServer
}

func (s *Server) SubmitTX(_ context.Context, txDaemon *grpcModels.SubmitRequest) (*grpcModels.Response, error) {
	var id int64
	var errUpdate error
	idCoin := 0
	if txDaemon.IdCoin == 40 {
		idCoin = int(txDaemon.IdCoin)
	}
	if txDaemon.Generated == true {
		amountMain := txDaemon.Amount + txDaemon.Fee
		amount := amountMain * 1.0
		amountFee := amountMain - amount
		id, errUpdate = database.InsertSQl("INSERT INTO masternode_tx(tx_id, idCoin, idNode, amount, mn_tx) VALUES(?, ?, ?, ?, ?)", txDaemon.TxId, idCoin, txDaemon.NodeId, amount, txDaemon.Generated)
		if errUpdate != nil {
			utils.WrapErrorLog(errUpdate.Error())
			return &grpcModels.Response{Code: 400}, errUpdate
		}
		_, _ = database.InsertSQl("INSERT INTO mn_tx_fees(tx_id, idCoin, idNode, amount, mn_tx) VALUES(?, ?, ?, ?, ?)", txDaemon.TxId, idCoin, txDaemon.NodeId, amountFee, txDaemon.Generated)
	} else {
		amount := txDaemon.Amount + txDaemon.Fee
		id, errUpdate = database.InsertSQl("INSERT INTO masternode_tx(tx_id, idCoin, idNode, amount, mn_tx) VALUES(?, ?, ?, ?, ?)", txDaemon.TxId, idCoin, txDaemon.NodeId, amount, txDaemon.Generated)
		if errUpdate != nil {
			utils.WrapErrorLog(errUpdate.Error())
			return &grpcModels.Response{Code: 400}, errUpdate
		}
	}

	if txDaemon.Generated == true {
		s, errDB := database.ReadSql("SELECT * FROM masternode_tx WHERE id = ?", id)
		if errDB != nil {
			utils.WrapErrorLog(errDB.Error())
			return &grpcModels.Response{Code: 400}, errUpdate
		}
		var txRes models.WalletMNTX
		for s.Next() {
			if err := s.StructScan(&txRes); err != nil {
				utils.WrapErrorLog(err.Error())
				return &grpcModels.Response{Code: 400}, errUpdate
			}

			readUsers, errDB := database.ReadSql("SELECT idUser, session, custodial, autostake FROM users_mn WHERE active = 1 AND idCoin = ? AND idNode = ?", idCoin, txRes.IdNode)
			if errDB != nil {
				utils.WrapErrorLog(errDB.Error())
				return &grpcModels.Response{Code: 400}, errUpdate
			}
			type ReadUsers struct {
				IdUser    sql.NullInt64 `db:"idUser"`
				Session   sql.NullInt64 `db:"session"`
				Custodial int64         `db:"custodial"`
				AutoStake bool          `db:"autostake"`
			}
			for readUsers.Next() {
				var ru ReadUsers
				if err := readUsers.StructScan(&ru); err != nil {
					utils.WrapErrorLog(errDB.Error())
					return &grpcModels.Response{Code: 400}, errUpdate
				}
				idUser := ru.IdUser.Int64
				session := ru.Session.Int64
				custodial := ru.Custodial

				if custodial == 0 {
					utils.ReportMessage(fmt.Sprintf("NON-CUSTODIAL | uid: %d node: %d", idUser, txDaemon.NodeId))
					continue
				}

				if idUser != 0 {
					dt := time.Now().UTC().Format("2006-01-02 15:04:05")
					if ru.AutoStake == true {
						_, errUpdate = database.InsertSQl("INSERT INTO payouts_masternode(idUser, idCoin, idNode, tx_id, session, amount, datetime, credited) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", idUser, idCoin, txRes.IdNode, txRes.TXID, session, txRes.Amount, dt, 1)
						if errUpdate != nil {
							utils.WrapErrorLog(errUpdate.Error())
							return &grpcModels.Response{Code: 400}, errUpdate
						}

						_, _ = database.InsertSQl("UPDATE users_stake SET amount = amount + ? WHERE idUser = ?", txRes.Amount, idUser)
						utils.ReportMessage(fmt.Sprintf("-{ Autostake share added to user %d }-", idUser))
						_, errUpdate = database.InsertSQl("UPDATE masternode_tx SET idUser = ? WHERE id = ?", ru.IdUser, id)
						continue
					}
					_, errUpdate := database.InsertSQl("INSERT INTO payouts_masternode(idUser, idCoin, idNode, tx_id, session, amount, datetime) VALUES (?, ?, ?, ?, ?, ?, ?)", idUser, idCoin, txRes.IdNode, txRes.TXID, session, txRes.Amount, dt)
					if errUpdate != nil {
						utils.WrapErrorLog(errUpdate.Error())
						return &grpcModels.Response{Code: 400}, errUpdate
					}
					_, errUpdate = database.InsertSQl("UPDATE masternode_tx SET idUser = ? WHERE id = ?", ru.IdUser, id)
					user, _ := database.ReadValue[string]("SELECT nickname FROM users WHERE id = ?", idUser)
					utils.ReportMessage(fmt.Sprintf("-{ MN TX from node id: %d added, coin id: %d amount: %f | user: %s (uid: %d)}-", txDaemon.NodeId, idCoin, txRes.Amount, user, ru.IdUser.Int64))
				} else {
					dt := time.Now().UTC().Format("2006-01-02 15:04:05")
					_, errUpdate := database.InsertSQl("INSERT INTO treasury(txid, amount, datetime) VALUES (?, ?, ?)", txRes.TXID, txRes.Amount, dt)
					_, errUpdate = database.InsertSQl("INSERT INTO payouts_masternode(idUser, idCoin, idNode, tx_id, session, amount, datetime) VALUES (?, ?, ?, ?, ?, ?, ?)", idUser, idCoin, txRes.IdNode, txRes.TXID, session, txRes.Amount, dt)
					if errUpdate != nil {
						utils.WrapErrorLog(errUpdate.Error())
						return &grpcModels.Response{Code: 400}, errUpdate
					}
					_, errUpdate = database.InsertSQl("UPDATE masternode_tx SET idUser = ? WHERE id = ?", ru.IdUser, id)
					utils.ReportMessage(fmt.Sprintf("-{ MN TX from node id: %d added to treasury }-", txDaemon.NodeId))
				}
				_ = readUsers.Close()
				_, errUpdate = database.InsertSQl("UPDATE masternode_tx SET processed = 1 WHERE id = ?", id)
				if errUpdate != nil {
					utils.WrapErrorLog(errUpdate.Error())
					return &grpcModels.Response{Code: 400}, errUpdate
				}
			}

		}

		_ = s.Close()
	}
	return &grpcModels.Response{Code: 200}, nil
}

func (s *Server) Register(_ context.Context, request *grpcModels.RegisterRequest) (*grpcModels.RegisterResponse, error) {
	encryptKey := utils.GenerateSecureToken(8)

	_, errInsert := database.InsertSQl("INSERT INTO mn_server(token, url, encryptKey) VALUES(?, ?, ?)", request.Token, request.Url, encryptKey)

	if errInsert != nil {
		utils.WrapErrorLog(errInsert.Error())
		return &grpcModels.RegisterResponse{Code: 400, Encrypt: "FUCK OFF"}, errInsert
	}
	utils.ReportMessage(fmt.Sprintf("NODE %s", request.Url))
	return &grpcModels.RegisterResponse{Code: 200, Encrypt: encryptKey}, nil
}

func (s *Server) RegisterMasternode(_ context.Context, request *grpcModels.RegisterMasternodeRequest) (*grpcModels.RegisterMasternodeResponse, error) {
	lastID, errInsertToken := database.InsertSQl("INSERT INTO mn_clients(wallet_usr, wallet_pass, wallet_port, node_ip, coin_id, address, folder, conf, ip, priv_key) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", request.WalletUSR, request.WalletPass, request.WalletPort, request.NodeIP, request.CoinID, request.Address, request.Folder, request.Conf, request.Ip, request.PrivKey)
	if errInsertToken != nil {
		utils.WrapErrorLog(errInsertToken.Error())
		return &grpcModels.RegisterMasternodeResponse{Code: 400, NodeID: 0}, errInsertToken
	}
	utils.ReportMessage(fmt.Sprintf("New MN registered %d", lastID))
	return &grpcModels.RegisterMasternodeResponse{Code: 200, NodeID: uint32(lastID)}, nil
}

func (s *Server) GetPrivateKey(_ context.Context, request *grpcModels.GetPrivateKeyRequest) (*grpcModels.GetPrivateKeyResponse, error) {
	keyDB, err := database.ReadValue[string]("SELECT priv_key FROM mn_clients WHERE id = ?", request.NodeID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return &grpcModels.GetPrivateKeyResponse{Code: 400, PrivKey: ""}, err
	}
	return &grpcModels.GetPrivateKeyResponse{Code: 200, PrivKey: keyDB}, nil
}

func (s *Server) WithdrawConfirm(_ context.Context, txDaemon *grpcModels.WithdrawConfirmRequest) (*grpcModels.WithdrawConfirmResponse, error) {
	if txDaemon.Type == 1 {
		utils.ReportMessage(fmt.Sprintf("! Full Withdraw: Updating DB | Node id: %d !", txDaemon.NodeID))
		userid, _ := database.ReadValue[int64]("SELECT idUser FROM users_mn WHERE idNode = ? AND active = 1", txDaemon.NodeID)
		coinid, _ := database.ReadValue[int64]("SELECT idCoin FROM users_mn WHERE idNode = ? AND active = 1", txDaemon.NodeID)
		depAddr, _ := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userid) //todo check if this is correct
		amnt, _ := database.ReadValue[float64]("SELECT IFNULL(SUM(amount), 0) as amount FROM payouts_masternode WHERE idNode = ? AND credited = 0", txDaemon.NodeID)
		collateral, _ := database.ReadValue[int]("SELECT collateral FROM mn_info WHERE idCoin = ?", coinid)

		_, errUpdate := database.InsertSQl("UPDATE mn_clients SET locked = 0, active = 0 WHERE id = ?", txDaemon.NodeID)
		_, errUpdate = database.InsertSQl("UPDATE mn_clients SET last_seen = NULL, active_time = NULL WHERE id = ?", txDaemon.NodeID)
		_, errUpdate = database.InsertSQl("UPDATE users_mn SET active = 0 WHERE idNode = ? AND id <> 0", txDaemon.NodeID)
		_, errUpdate = database.InsertSQl("UPDATE mn_clients SET custodial = 0 WHERE id = ? AND id <> 0", txDaemon.NodeID)

		amountToSend := amnt - (txDaemon.Amount - float64(collateral))
		if amountToSend <= 0.0 {
			return &grpcModels.WithdrawConfirmResponse{
				Code: 400,
			}, errors.New("amount need to be more than 0")
		}
		utils.ReportMessage(fmt.Sprintf("! Remaining amount to send: %f !", amountToSend))
		server, err := database.ReadValue[string]("SELECT addr FROM servers_stake WHERE id = 1")
		if err != nil {
			return &grpcModels.WithdrawConfirmResponse{
				Code: 400,
			}, err
		}
		tx, err := coind.SendCoins(depAddr, server, amountToSend, true)
		if err != nil {
			return &grpcModels.WithdrawConfirmResponse{
				Code: 400,
			}, err
		}
		utils.ReportMessage(fmt.Sprintf("! Full Withdraw: TX %s !", tx))

		_, errUpdate = database.InsertSQl("UPDATE payouts_masternode SET credited = 1 WHERE idNode = ? AND idCoin = ? AND id <> 0", txDaemon.NodeID, coinid)
		if errUpdate != nil {
			return &grpcModels.WithdrawConfirmResponse{
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

	return &grpcModels.WithdrawConfirmResponse{Code: 200}, nil
}

func (s *Server) MasternodeActive(_ context.Context, request *grpcModels.MasternodeActiveRequest) (*grpcModels.MasternodeActiveResponse, error) {
	type ActiveMN struct {
		ID        int64  `json:"id" db:"id"`
		Active    int    `json:"active" db:"active"`
		Custodial int    `json:"custodial" db:"custodial"`
		Address   string `json:"address" db:"address"`
	}

	returnListArr, err := database.ReadArrayStruct[ActiveMN]("SELECT id, active, custodial, address FROM mn_clients WHERE node_ip = ?", request.Url)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return &grpcModels.MasternodeActiveResponse{Mn: nil}, err
	}
	active := make([]*grpcModels.MasternodeActiveResponse_Mn, 0)
	for _, mn := range returnListArr {
		active = append(active, &grpcModels.MasternodeActiveResponse_Mn{Id: uint32(mn.ID), Active: uint32(mn.Active), Custodial: uint32(mn.Custodial), Address: mn.Address})
	}
	return &grpcModels.MasternodeActiveResponse{Mn: active}, nil
}

func (s *Server) LastSeen(_ context.Context, request *grpcModels.LastSeenRequest) (*grpcModels.LastSeenResponse, error) {
	for _, ls := range request.Items {
		_, errDB := database.InsertSQl("UPDATE mn_clients SET last_seen = ?, active_time = ? WHERE id = ?", ls.LastSeen, ls.ActiveTime, ls.Id)
		if errDB != nil {
			utils.ReportMessage(errDB.Error())
		}
	}
	return &grpcModels.LastSeenResponse{Code: 200}, nil
}

func (s *Server) Ping(_ context.Context, request *grpcModels.PingRequest) (*grpcModels.PingResponse, error) {
	utils.ReportMessage(fmt.Sprintf("! Ping from %d !", request.NodeID))
	return &grpcModels.PingResponse{Code: 200}, nil
}

func (s *Server) RemoveMasternode(_ context.Context, request *grpcModels.RemoveMasternodeRequest) (*grpcModels.RemoveMasternodeResponse, error) {
	active := database.ReadValueEmpty[bool]("SELECT active FROM mn_clients WHERE id = ?", request.NodeID)
	if active == true {
		return &grpcModels.RemoveMasternodeResponse{Code: 400}, errors.New("masternode is active")
	}
	locked := database.ReadValueEmpty[bool]("SELECT locked FROM mn_clients WHERE id = ?", request.NodeID)
	if locked == true {
		return &grpcModels.RemoveMasternodeResponse{Code: 400}, errors.New("masternode is active")
	}

	_, err := database.InsertSQl("DELETE FROM mn_clients WHERE id = ?", request.NodeID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return &grpcModels.RemoveMasternodeResponse{Code: 400}, err
	}
	return &grpcModels.RemoveMasternodeResponse{Code: 200}, nil
}

func (s *Server) MasternodeStarted(_ context.Context, request *grpcModels.MasternodeStartedRequest) (*grpcModels.MasternodeStartedResponse, error) {
	isError, err := database.ReadValue[bool]("SELECT error FROM mn_clients WHERE id = ?", request.NodeID)
	if err != nil {
		return &grpcModels.MasternodeStartedResponse{Code: 400}, err
	}
	if isError == true {
		go func() {
			utils.ReportMessage(fmt.Sprintf("! Masternode %d restart !", request.NodeID))
			userID := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_mn WHERE idNode = ? AND active = 1", request.NodeID)
			if !userID.Valid {
				utils.WrapErrorLog(fmt.Sprintf("! Masternode %d restart error can'f find user!", request.NodeID))
				return
			}
			type Token struct {
				Token string `json:"token"`
			}
			tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", userID.Int64)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}

			if len(tk) > 0 {
				for _, v := range tk {
					utils.SendMessage(v.Token, fmt.Sprintf("Node %d ", request.NodeID), fmt.Sprintf("MN has been restarted successfully"), map[string]string{})
				}
			}
		}()
		_, err = database.InsertSQl("UPDATE mn_clients SET active = 1 WHERE id = ?", request.NodeID)
		_, err = database.InsertSQl("UPDATE mn_clients SET error = 0 WHERE id = ?", request.NodeID)
	} else {
		_, err = database.InsertSQl("UPDATE mn_clients SET active = 1 WHERE id = ?", request.NodeID)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return &grpcModels.MasternodeStartedResponse{Code: 400}, err
		}
	}
	return &grpcModels.MasternodeStartedResponse{Code: 200}, nil
}

func (s *Server) MasternodeError(_ context.Context, request *grpcModels.MasternodeErrorRequest) (*grpcModels.MasternodeErrorResponse, error) {
	_, _ = database.InsertSQl("UPDATE mn_clients SET error = 1 WHERE id = ?", request.NodeID)

	utils.WrapErrorLog(fmt.Sprintf("! Masternode %d error: %s !", request.NodeID, request.Error))

	go func() {
		utils.ReportMessage(fmt.Sprintf("! Masternode %d error !", request.NodeID))
		userID := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_mn WHERE idNode = ? AND active = 1", request.NodeID)
		if !userID.Valid {
			utils.WrapErrorLog(fmt.Sprintf("! Masternode %d error can'f find user!", request.NodeID))
			return
		}
		type Token struct {
			Token string `json:"token"`
		}
		tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", userID.Int64)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}

		if len(tk) > 0 {
			for _, v := range tk {
				utils.SendMessage(v.Token, fmt.Sprintf("Node %d ", request.NodeID), fmt.Sprintf("MN stopped, please restart it in masternode console"), map[string]string{})
			}
		}
	}()
	return &grpcModels.MasternodeErrorResponse{Code: 200}, nil
}
