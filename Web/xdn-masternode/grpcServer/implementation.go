package grpcServer

import (
	"context"
	"fmt"
	"io"
	"strconv"
	"strings"
	"xdn-masternode/coind"
	"xdn-masternode/database"
	"xdn-masternode/fn"
	"xdn-masternode/grpcModels"
	"xdn-masternode/models"
	"xdn-masternode/utils"
)

type Server struct {
	grpcModels.UnimplementedTransactionServiceServer
	grpcModels.UnimplementedRegisterMasternodeServiceServer
}

func (s *Server) SubmitTX(_ context.Context, in *grpcModels.SubmitRequest) (*grpcModels.Response, error) {
	utils.ReportMessage(fmt.Sprintf("TX %s", in.TxId))
	return &grpcModels.Response{Code: 200}, nil
}

func (s *Server) RegisterTX(_ context.Context, in *grpcModels.RegisterRequest) (*grpcModels.RegisterResponse, error) {
	utils.ReportMessage(fmt.Sprintf("TX %s", in.Token))
	return &grpcModels.RegisterResponse{Code: 200, Encrypt: ""}, nil
}

func (s *Server) StartMasternode(_ context.Context, in *grpcModels.StartMasternodeRequest) (*grpcModels.StartMasternodeResponse, error) {
	utils.ReportMessage(fmt.Sprintf("Start MN %d", in.NodeID))
	nodeID := int(in.NodeID)
	go fn.StartMasternode(nodeID)
	return &grpcModels.StartMasternodeResponse{Code: 200}, nil
}

func (s *Server) StartNonMasternode(_ context.Context, in *grpcModels.StartNonMasternodeRequest) (*grpcModels.StartNonMasternodeResponse, error) {
	utils.ReportMessage(fmt.Sprintf("Start MN %d", in.NodeID))
	nodeID := int(in.NodeID)
	key := in.WalletKey
	go fn.StartRemoteMasternode(nodeID, key)
	return &grpcModels.StartNonMasternodeResponse{Code: 200}, nil
}

func (s *Server) Withdraw(_ context.Context, wdmn *grpcModels.WithdrawRequest) (*grpcModels.WithdrawResponse, error) {
	if len(wdmn.Deposit) == 0 || wdmn.Amount == 0 || wdmn.NodeID == 0 {
		return &grpcModels.WithdrawResponse{Code: 400}, nil
	}
	go fn.WithDraw(wdmn)
	return &grpcModels.WithdrawResponse{Code: 200}, nil
}

func (s *Server) CheckMasternode(_ context.Context, request *grpcModels.CheckMasternodeRequest) (*grpcModels.CheckMasternodeResponse, error) {
	dm, errDm := database.GetDaemon(int(request.NodeID))
	if errDm != nil {
		return &grpcModels.CheckMasternodeResponse{Code: 400}, nil
	}

	call, err := coind.WrapDaemon(*dm, 5, "getinfo")
	if err != nil {
		return &grpcModels.CheckMasternodeResponse{Code: 400}, nil
	}

	if string(call) == "null" || len(string(call)) == 0 {
		return &grpcModels.CheckMasternodeResponse{Code: 400}, nil
	}

	if dm.CoinID == 0 || dm.CoinID == 40 {
		blkReqXDN, errNet := utils.GETAny("https://xdn-explorer.com/api/getblockcount")
		if errNet != nil {
			return &grpcModels.CheckMasternodeResponse{Code: 400}, nil
		}
		bodyXDN, _ := io.ReadAll(blkReqXDN.Body)
		blockhashXDN, _ := strconv.Atoi(string(bodyXDN))

		defer func(Body io.ReadCloser) {
			err := Body.Close()
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
		}(blkReqXDN.Body)

		blk, errBlock := coind.WrapDaemon(*dm, 1, "getblockcount")
		bnm, errBlock := strconv.Atoi(strings.Trim(string(blk), "\""))
		if errBlock != nil {
			utils.WrapErrorLog(errBlock.Error())
			go fn.Snap(dm.Folder, dm.CoinID)
			return &grpcModels.CheckMasternodeResponse{Code: 200}, nil
		}

		if !(blockhashXDN < (bnm + 10)) || !(blockhashXDN > (bnm - 10)) {
			utils.ReportMessage(fmt.Sprintf("SHIT BLOCK COUNT: Have %d, should have %d", bnm, blockhashXDN))
			go fn.Snap(dm.Folder, dm.CoinID)
			return &grpcModels.CheckMasternodeResponse{Code: 200}, nil
		}
		return &grpcModels.CheckMasternodeResponse{Code: 200}, nil
	} else {
		return &grpcModels.CheckMasternodeResponse{Code: 200}, nil
	}
}

func (s *Server) RestartMasternode(_ context.Context, wdmn *grpcModels.RestartMasternodeRequest) (*grpcModels.RestartMasternodeResponse, error) {
	if wdmn.NodeID == 0 {
		return &grpcModels.RestartMasternodeResponse{Code: 400}, nil
	}
	go fn.RestartMasternode(int(wdmn.NodeID))
	return &grpcModels.RestartMasternodeResponse{Code: 200}, nil
}

func (s *Server) MasternodeStatus(_ context.Context, wdmn *grpcModels.MasternodeStatusRequest) (*grpcModels.MasternodeStatusResponse, error) {
	//if wdmn.NodeID == 0 {
	//	return &grpcModels.MasternodeStatusResponse{Code: 400}, nil
	//}
	//go fn.MasternodeStatus(int(wdmn.NodeID))
	//return &grpcModels.MasternodeStatusResponse{Code: 200}, nil
	return &grpcModels.MasternodeStatusResponse{Code: 200, Status: 100}, nil
}

func (s *Server) AddMasternode(_ context.Context, in *grpcModels.AddMasternodeRequest) (*grpcModels.AddMasternodeResponse, error) {
	err := fn.AddMN(models.AddMNConfig{
		CoinFolder:       in.CoinFolder,
		PortPrefix:       int(in.PortPrefix),
		MasternodePort:   int(in.MasternodePort),
		BlockchainFolder: in.BlockchainFolder,
		ConfigFile:       in.ConfigName,
		DaemonName:       in.DaemonName,
		CliName:          in.CliName,
		CoinID:           int(in.CoinID),
	})
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return &grpcModels.AddMasternodeResponse{Code: 400, Message: err.Error()}, nil
	}
	return &grpcModels.AddMasternodeResponse{Code: 200, Message: "OK"}, nil
}
