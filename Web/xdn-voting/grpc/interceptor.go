package grpc

import (
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"strconv"
	"xdn-voting/utils"
)

// Authorization unary interceptor function to handle authorize per RPC call
func serverInterceptor(ctx context.Context,
	req interface{},
	info *grpc.UnaryServerInfo,
	handler grpc.UnaryHandler) (interface{}, error) {
	id := ""
	var err error
	//utils.ReportMessage(info.FullMethod)
	// Skip authorize when RefreshToken is requested
	if info.FullMethod != "/proto.AppService/RefreshToken" {
		if id, err = authorize(ctx); err != nil {
			return nil, err
		}
	}

	//interceptor
	md, ok := metadata.FromIncomingContext(ctx)
	if ok {
		md.Append("user_id", id)
	}
	newCtx := metadata.NewIncomingContext(ctx, md)
	return handler(newCtx, req)
}

// authorize function authorizes the token received from Metadata
func authorize(ctx context.Context) (string, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return "", status.Errorf(codes.InvalidArgument, "Retrieving metadata is failed")
	}

	authHeader, ok := md["authorization"]
	if !ok {
		return "", status.Errorf(codes.Unauthenticated, "Authorization token is not supplied")
	}

	token := authHeader[0]
	// validateToken function validates the token
	id, _, err := utils.ValidateKeyToken(token)

	if err != nil {
		return "", status.Errorf(codes.Unauthenticated, err.Error())
	}

	return strconv.Itoa(id), nil
}
