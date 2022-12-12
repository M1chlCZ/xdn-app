package grpc

import (
	"crypto/tls"
	"fmt"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
	"log"
	"net"
	"xdn-voting/grpcModels"
	"xdn-voting/utils"
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
	}

	s := Server{}
	grpcServer := grpc.NewServer(grpc.Creds(tlsCredentials))
	grpcModels.RegisterTransactionServiceServer(grpcServer, &s)
	grpcModels.RegisterRegisterServiceServer(grpcServer, &s)
	grpcModels.RegisterRegisterMasternodeServiceServer(grpcServer, &s)
	if err := grpcServer.Serve(lis); err != nil {
		utils.WrapErrorLog(err.Error())
	}
}
func NewAppServer() {
	utils.ReportMessage("APP gRPC Online on port 6805!")
	lisApp, errApp := net.Listen("tcp", fmt.Sprintf(":%d", 6805))
	if errApp != nil {
		utils.WrapErrorLog(errApp.Error())
	}

	sApp := ServerApp{}
	grpcServerApp := grpc.NewServer(grpc.Creds(insecure.NewCredentials()), grpc.UnaryInterceptor(serverInterceptor))
	grpcModels.RegisterAppServiceServer(grpcServerApp, &sApp)
	if err := grpcServerApp.Serve(lisApp); err != nil {
		utils.WrapErrorLog(err.Error())
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
