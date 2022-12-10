package grpcClient

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"log"
	"os"
	"time"
	"xdn-masternode/grpcModels"
)


func loadTLSCredentials() (credentials.TransportCredentials, error) {
	// Load certificate of the CA who signed server's certificate
	pemServerCA, err := os.ReadFile("./.cert/ca-cert.pem")
	if err != nil {
		return nil, err
	}

	certPool := x509.NewCertPool()
	if !certPool.AppendCertsFromPEM(pemServerCA) {
		return nil, fmt.Errorf("failed to add server CA's certificate")
	}

	// Create the credentials and return it
	config := &tls.Config{
		RootCAs:      certPool,
	}

	return credentials.NewTLS(config), nil
}

func CallSubmitTX(tx *grpcModels.SubmitRequest) (*grpcModels.Response, error) {
	tlsCredentials, err := loadTLSCredentials()
	if err != nil {
		log.Fatal("cannot load TLS credentials: ", err)
	}
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(tlsCredentials))
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
	tlsCredentials, err := loadTLSCredentials()
	if err != nil {
		log.Fatal("cannot load TLS credentials: ", err)
	}
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(tlsCredentials))
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
	tlsCredentials, err := loadTLSCredentials()
	if err != nil {
		log.Fatal("cannot load TLS credentials: ", err)
	}
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(tlsCredentials))
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
	tlsCredentials, err := loadTLSCredentials()
	if err != nil {
		log.Fatal("cannot load TLS credentials: ", err)
	}
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(tlsCredentials))
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
	tlsCredentials, err := loadTLSCredentials()
	if err != nil {
		log.Fatal("cannot load TLS credentials: ", err)
	}
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(tlsCredentials))
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
	tlsCredentials, err := loadTLSCredentials()
	if err != nil {
		log.Fatal("cannot load TLS credentials: ", err)
	}
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(tlsCredentials))
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
	tlsCredentials, err := loadTLSCredentials()
	if err != nil {
		log.Fatal("cannot load TLS credentials: ", err)
	}
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(tlsCredentials))
	if err != nil {
		log.Fatalf("did not connect: %s", err)
	}
	defer grpcCon.Close()
	c := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return c.LastSeen(ctx, tx)
}

func Ping(tx *grpcModels.PingRequest) (*grpcModels.PingResponse, error) {
	tlsCredentials, err := loadTLSCredentials()
	if err != nil {
		log.Fatal("cannot load TLS credentials: ", err)
	}
	grpcCon, err := grpc.Dial("194.60.201.213:6810", grpc.WithTransportCredentials(tlsCredentials))
	if err != nil {
		log.Fatalf("did not connect: %s", err)
	}
	defer grpcCon.Close()
	c := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return c.Ping(ctx, tx)
}
