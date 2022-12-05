package grpcServer

import (
	"context"
	"fmt"
	"xdn-masternode/fn"
	"xdn-masternode/grpcModels"
	"xdn-masternode/utils"
)

type Server struct {
	grpcModels.UnimplementedTransactionServiceServer
	grpcModels.UnimplementedRegisterMasternodeServiceServer
}

func (s *Server) SubmitTX(ctx context.Context, in *grpcModels.SubmitRequest) (*grpcModels.Response, error) {
	utils.ReportMessage(fmt.Sprintf("TX %s", in.TxId))
	return &grpcModels.Response{Code: 200}, nil
}

func (s *Server) RegisterTX(ctx context.Context, in *grpcModels.RegisterRequest) (*grpcModels.RegisterResponse, error) {
	utils.ReportMessage(fmt.Sprintf("TX %s", in.Token))
	return &grpcModels.RegisterResponse{Code: 200, Encrypt: ""}, nil
}

func (s *Server) StartMasternode(ctx context.Context, in *grpcModels.StartMasternodeRequest) (*grpcModels.StartMasternodeResponse, error) {
	utils.ReportMessage(fmt.Sprintf("Start MN %d", in.NodeID))
	nodeID := int(in.NodeID)
	go fn.StartMasternode(nodeID)
	return &grpcModels.StartMasternodeResponse{Code: 200}, nil
}

func (s *Server) Withdraw(ctx context.Context, wdmn *grpcModels.WithdrawRequest) (*grpcModels.WithdrawResponse, error) {
	utils.ReportMessage(fmt.Sprintf("Withdraw %s", wdmn.Deposit))
	if len(wdmn.Deposit) == 0 || wdmn.Amount == 0 || wdmn.NodeID == 0 {
		return &grpcModels.WithdrawResponse{Code: 400}, nil
	}
	go fn.WithDraw(wdmn)
	return &grpcModels.WithdrawResponse{Code: 200}, nil
}
