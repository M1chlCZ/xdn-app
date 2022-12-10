package daemons

import (
	"fmt"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"xdn-voting/database"
	"xdn-voting/grpcModels"
	"xdn-voting/utils"
)

func ScoopMasternode() {

	type NodeID struct {
		IdNode int64 `db:"idNode"`
	}
	clients, _ := database.ReadArrayStruct[NodeID]("SELECT id as idNode FROM mn_clients WHERE active = 1 GROUP BY idNode")
	if len(clients) > 0 {
		utils.ReportMessage("Scooping Masternodes...")
	}
	for _, node := range clients {
		ur, errCrypt := database.ReadValue[string]("SELECT node_ip FROM mn_clients WHERE id = ?", node.IdNode)
		coinID, errCrypt := database.ReadValue[string]("SELECT coin_id FROM mn_clients WHERE id = ?", node.IdNode)
		//tk, errCrypt := database.ReadValue[string]("SELECT token FROM mn_server WHERE url = ?", ur)
		//en, errCrypt := database.ReadValue[string]("SELECT encryptKey FROM mn_server WHERE url = ?", ur)
		if errCrypt != nil {
			utils.WrapErrorLog(errCrypt.Error())
			continue
		}

		addr, errCrypt := database.ReadValue[string]("SELECT addr FROM servers_stake WHERE idCoin = ?", coinID)
		if errCrypt != nil {
			utils.ReportMessage("3")
			utils.WrapErrorLog(errCrypt.Error())
			continue
		}
		tx := &grpcModels.WithdrawRequest{
			NodeID:  uint32(node.IdNode),
			Deposit: addr,
			Amount:  1.0,
			Type:    0,
		}
		creds, err := grpcModels.LoadTLSCredentials()
		if err != nil {
			utils.WrapErrorLog("cannot load TLS credentials: " + err.Error())
			return
		}
		grpcCon, err := grpc.Dial(fmt.Sprintf("%s:6810", ur), grpc.WithTransportCredentials(creds))
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		c := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
		resp, err := c.Withdraw(context.Background(), tx)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		if resp.Code == 200 {
			//utils.ReportMessage(fmt.Sprintf("Withdraw from node %s", ur))
		} else {
			utils.ReportMessage(fmt.Sprintf("Somethings wrong on node %s", ur))
		}
		_ = grpcCon.Close()
	}

	//utils.ReportMessage("Masternode fees")
}
