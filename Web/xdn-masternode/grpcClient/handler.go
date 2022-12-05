package grpcClient

import (
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"log"
	"time"
	"xdn-masternode/grpcModels"
)

func CallSubmitTX(tx *grpcModels.SubmitRequest) (*grpcModels.Response, error) {
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %s", err)
	}
	defer grpcCon.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	c := grpcModels.NewTransactionServiceClient(grpcCon)
	return c.SubmitTX(ctx, tx)
}

func CallRegisterRequest(tx *grpcModels.RegisterRequest) (*grpcModels.RegisterResponse, error) {
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %s", err)
	}
	defer grpcCon.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	c := grpcModels.NewRegisterServiceClient(grpcCon)
	return c.Register(ctx, tx)
}

func CallRegisterMN(tx *grpcModels.RegisterMasternodeRequest) (*grpcModels.RegisterMasternodeResponse, error) {
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %s", err)
	}
	defer grpcCon.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	c := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
	return c.RegisterMasternode(ctx, tx)
}

func CallGetPrivateKey(tx *grpcModels.GetPrivateKeyRequest) (*grpcModels.GetPrivateKeyResponse, error) {
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %s", err)
	}
	defer grpcCon.Close()
	c := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return c.GetPrivateKey(ctx, tx)
}

func WithdrawConfirm(tx *grpcModels.WithdrawConfirmRequest) (*grpcModels.WithdrawConfirmResponse, error) {
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %s", err)
	}
	defer grpcCon.Close()
	c := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return c.WithdrawConfirm(ctx, tx)
}

func MasternodeActive(tx *grpcModels.MasternodeActiveRequest) (*grpcModels.MasternodeActiveResponse, error) {
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %s", err)
	}
	defer grpcCon.Close()
	c := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return c.MasternodeActive(ctx, tx)
}

func LastSeen(tx *grpcModels.LastSeenRequest) (*grpcModels.LastSeenResponse, error) {
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %s", err)
	}
	defer grpcCon.Close()
	c := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return c.LastSeen(ctx, tx)
}
