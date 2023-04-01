package grpc

import (
	"context"
	"fmt"
	"google.golang.org/grpc"
	"log"
	"time"
	"xdn-voting/grpcModels"
	"xdn-voting/utils"
)

func AddMasternode(tx *grpcModels.AddMasternodeRequest, url string) (*grpcModels.AddMasternodeResponse, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 360*time.Second)
	tlsCredentials, err := loadTLSCredentials()
	if err != nil {
		log.Fatal("cannot load TLS credentials: ", err)
	}
	grpcCon, err := grpc.DialContext(ctx, fmt.Sprintf("%s:6810", url), grpc.WithTransportCredentials(tlsCredentials))
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("did not connect: %s", err))
		cancel()
		return nil, err
	}
	defer func(grpcCon *grpc.ClientConn) {
		_ = grpcCon.Close()
	}(grpcCon)
	defer cancel()

	c := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
	return c.AddMasternode(ctx, tx)
}
