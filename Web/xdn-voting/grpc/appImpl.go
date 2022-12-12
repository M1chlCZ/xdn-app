package grpc

import (
	"database/sql"
	"fmt"
	"golang.org/x/net/context"
	"google.golang.org/grpc/metadata"
	"xdn-voting/database"
	"xdn-voting/grpcModels"
	"xdn-voting/utils"
)

type ServerApp struct {
	grpcModels.UnimplementedAppServiceServer
}

func (s *ServerApp) AppPing(ctx context.Context, request *grpcModels.AppPingRequest) (*grpcModels.AppPingResponse, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return &grpcModels.AppPingResponse{Code: 400}, nil
	}
	usr := md.Get("user_id")
	utils.ReportMessage(fmt.Sprintf("AppPing %s", usr))
	utils.ReportMessage(fmt.Sprintf("! App Ping from %d !", request.Code))
	return &grpcModels.AppPingResponse{Code: 200}, nil
}

func (s *ServerApp) UserPermission(ctx context.Context, _ *grpcModels.UserPermissionRequest) (*grpcModels.UserPermissionResponse, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return &grpcModels.UserPermissionResponse{MnPermission: false}, nil
	}
	uID := md.Get("user_id")
	userID := uID[0]

	value := database.ReadValueEmpty[sql.NullBool]("SELECT mn FROM users_permission WHERE idUser = ?", userID)
	utils.ReportMessage(fmt.Sprintf("UserPermission %v", value))
	if value.Valid {
		return &grpcModels.UserPermissionResponse{MnPermission: value.Bool}, nil
	}
	return &grpcModels.UserPermissionResponse{MnPermission: false}, nil
}
