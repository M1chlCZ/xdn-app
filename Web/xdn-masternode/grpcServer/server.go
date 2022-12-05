package grpcServer

import (
	"fmt"
	"google.golang.org/grpc"
	"net"
	"xdn-masternode/grpcModels"
	"xdn-masternode/utils"
)

func NewServer() {
	utils.ReportMessage("gRPC Online on port 6810!")

	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", 6810))
	if err != nil {
		utils.WrapErrorLog(err.Error())
		//log.Fatalf("failed to listen: %v", err)
	}

	s := Server{}
	grpcServer := grpc.NewServer()
	grpcModels.RegisterRegisterMasternodeServiceServer(grpcServer, &s)
	if err := grpcServer.Serve(lis); err != nil {
		utils.WrapErrorLog(err.Error())
		//log.Fatalf("failed to serve: %s", err)
	}
}
