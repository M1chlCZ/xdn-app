package grpcServer

import (
	"crypto/tls"
	"fmt"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"log"
	"net"
	"xdn-masternode/grpcModels"
	"xdn-masternode/utils"
)

func NewServer() {
	utils.ReportMessage("gRPC Online on port 6810!")

	tlsCredentials, err := loadTLSCredentials()
	if err != nil {
		log.Fatal("cannot load TLS credentials: ", err)
	}

	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", 6810))
	if err != nil {
		utils.WrapErrorLog(err.Error())
		//log.Fatalf("failed to listen: %v", err)
	}

	s := Server{}
	grpcServer := grpc.NewServer(grpc.Creds(tlsCredentials))
	grpcModels.RegisterRegisterMasternodeServiceServer(grpcServer, &s)
	if err := grpcServer.Serve(lis); err != nil {
		utils.WrapErrorLog(err.Error())
		//log.Fatalf("failed to serve: %s", err)
	}
}

func loadTLSCredentials() (credentials.TransportCredentials, error) {
	// Load server's certificate and private key
	serverCert, err := tls.LoadX509KeyPair("./.cert/server-cert.pem", "./.cert/server-key.pem")
	if err != nil {
		utils.ReportMessage("Failed to load server's certificate and private key")
		return nil, err
	}

	// Create the credentials and return it
	config := &tls.Config{
		Certificates: []tls.Certificate{serverCert},
		ClientAuth:   tls.NoClientCert,
	}

	return credentials.NewTLS(config), nil
}
