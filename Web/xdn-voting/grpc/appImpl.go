package grpc

import (
	"database/sql"
	"fmt"
	"github.com/jmoiron/sqlx"
	"golang.org/x/net/context"
	"google.golang.org/grpc/metadata"
	"gopkg.in/errgo.v2/errors"
	"time"
	"xdn-voting/database"
	"xdn-voting/grpcModels"
	"xdn-voting/models"
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
		return &grpcModels.UserPermissionResponse{MnPermission: false, StealthPermission: false}, nil
	}
	uID := md.Get("user_id")
	userID := uID[0]
	admin := false
	mnPermission := false
	stealthPermission := false
	value := database.ReadValueEmpty[sql.NullInt64]("SELECT mn FROM users_permission WHERE idUser = ?", userID)
	if value.Valid {
		mnPermission = true
	}
	value2 := database.ReadValueEmpty[sql.NullInt64]("SELECT stealth FROM users_permission WHERE idUser = ?", userID)
	if value2.Valid {
		stealthPermission = true
	}

	value3 := database.ReadValueEmpty[bool]("SELECT admin FROM users WHERE id = ?", userID)
	if value3 {
		admin = true
	}

	return &grpcModels.UserPermissionResponse{MnPermission: mnPermission, StealthPermission: stealthPermission, Admin: admin}, nil
}

func (s *ServerApp) MasternodeGraph(ctx context.Context, request *grpcModels.MasternodeGraphRequest) (*grpcModels.MasternodeGraphResponse, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return nil, errors.New("no metadata")
	}
	uID := md.Get("user_id")
	userID := uID[0]

	//if userID == "1" {
	//	userID = "0"
	//}

	var rows *sqlx.Rows
	var errDB error
	var sqlQuery string
	createdFormat := "2006-01-02 15:04:05"
	timez := request.Datetime
	golangDateTime, err := time.Parse(createdFormat, timez)
	if err != nil {
		return nil, err
	}
	//golangDateTime.Format("2006-01-02 15:04:05")
	year, month, _ := golangDateTime.Date()

	if request.Type == 0 {
		sqlQuery = "SELECT date(datetime) as day, Hour(datetime) AS hour, sum(amount) AS amount FROM  payouts_masternode WHERE datetime BETWEEN ? AND date_sub(NOW(), INTERVAL 5 MINUTE) AND idCoin = ? AND idUser = ? GROUP BY hour, day " +
			"ORDER BY hour"
		//utils.ReportMessage(fmt.Sprintf("SELECT date(datetime) as day, Hour(datetime) AS hour, sum(amount) AS amount FROM  payouts_masternode WHERE datetime BETWEEN %s AND date_add(%s, INTERVAL 24 HOUR) AND idCoin = %d AND idUser = %s GROUP BY hour, day ORDER BY hour", timez, timez, stakeReq.IdCoin, userID))
		rows, errDB = database.ReadSql(sqlQuery, timez, request.IdCoin, userID)
	} else if request.Type == 1 {
		sqlQuery = "SELECT date(datetime) as day, sum(amount) AS amount FROM  payouts_masternode WHERE datetime BETWEEN  date_sub(?, INTERVAL 1 WEEK) AND ? AND idCoin = ? AND idUser = ? GROUP BY day"
		rows, errDB = database.ReadSql(sqlQuery, timez, timez, request.IdCoin, userID)
	} else if request.Type == 2 {
		sqlQuery = "SELECT DATE(datetime) as day, SUM(`amount`) AS amount FROM payouts_masternode WHERE idUser =? AND idCoin =? AND YEAR(date(datetime))=? AND MONTH(date(datetime))=? GROUP BY DATE(datetime)"
		rows, errDB = database.ReadSql(sqlQuery, userID, request.IdCoin, year, month)
	} else if request.Type == 3 {
		sqlQuery = "SELECT ANY_VALUE(DATE_FORMAT(datetime,'%Y-%m')) AS day, SUM(`amount`) AS amount FROM payouts_masternode WHERE idUser = ? AND idCoin = ? AND YEAR(date(datetime))= ? GROUP BY MONTH (date(datetime))"
		rows, errDB = database.ReadSql(sqlQuery, userID, request.IdCoin, year)
	}

	if errDB != nil {
		return nil, errDB
	}

	ra := database.ParseArrayStruct[models.StakeGetEntry](rows)
	returnArray := make([]*grpcModels.MasternodeGraphResponse_Rewards, 0)
	for _, v := range ra {
		returnArray = append(returnArray, &grpcModels.MasternodeGraphResponse_Rewards{
			Amount: v.Amount,
			Day:    v.Day,
			Hour:   uint32(v.Hours),
		})
	}
	return &grpcModels.MasternodeGraphResponse{
		HasError: false,
		Rewards:  returnArray,
		Status:   utils.OK,
	}, nil
}

func (s *ServerApp) StakeGraph(ctx context.Context, request *grpcModels.StakeGraphRequest) (*grpcModels.StakeGraphResponse, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return nil, errors.New("no metadata")
	}
	uID := md.Get("user_id")
	userID := uID[0]
	var rows *sqlx.Rows
	var errDB error
	var sqlQuery string
	createdFormat := "2006-01-02 15:04:05"
	timez := request.Datetime
	golangDateTime, err := time.Parse(createdFormat, timez)
	if err != nil {
		return nil, err
	}
	//golangDateTime.Format("2006-01-02 15:04:05")
	year, month, _ := golangDateTime.Date()

	if request.Type == 0 {
		sqlQuery = `SELECT date(datetime) as day, Hour(datetime) AS hour, sum(amount) AS amount FROM  payouts_stake WHERE datetime BETWEEN ? AND date_add(?, INTERVAL 24 HOUR) AND idUser = ? GROUP BY hour, day ORDER BY hour`
		rows, errDB = database.ReadSql(sqlQuery, timez, timez, userID)
	} else if request.Type == 1 {
		sqlQuery = "SELECT date(datetime) as day, sum(amount) AS amount FROM  payouts_stake WHERE datetime BETWEEN  date_sub(?, INTERVAL 1 WEEK) AND ? AND idUser = ? GROUP BY day"
		rows, errDB = database.ReadSql(sqlQuery, timez, timez, userID)
	} else if request.Type == 2 {
		sqlQuery = "SELECT DATE(datetime) as day, SUM(`amount`) AS amount FROM payouts_stake WHERE idUser =? AND YEAR(date(datetime))=? AND MONTH(date(datetime))=? GROUP BY DATE(datetime)"
		rows, errDB = database.ReadSql(sqlQuery, userID, year, month)
	} else if request.Type == 3 {
		sqlQuery = "SELECT ANY_VALUE(DATE_FORMAT(datetime,'%Y-%m')) AS day, SUM(`amount`) AS amount FROM payouts_stake WHERE idUser = ? AND YEAR(date(datetime))= ? GROUP BY MONTH (date(datetime))"
		rows, errDB = database.ReadSql(sqlQuery, userID, year)
	}

	if errDB != nil {
		return nil, errDB
	}

	ra := database.ParseArrayStruct[models.StakeGetEntry](rows)
	returnArray := make([]*grpcModels.StakeGraphResponse_Rewards, 0)
	for _, v := range ra {
		returnArray = append(returnArray, &grpcModels.StakeGraphResponse_Rewards{
			Amount: v.Amount,
			Day:    v.Day,
			Hour:   uint32(v.Hours),
		})
	}
	return &grpcModels.StakeGraphResponse{
		HasError: false,
		Rewards:  returnArray,
		Status:   utils.OK,
	}, nil
}

func (s *ServerApp) RefreshToken(_ context.Context, request *grpcModels.RefreshTokenRequest) (*grpcModels.RefreshTokenResponse, error) {
	//md, ok := metadata.FromIncomingContext(ctx)
	//if !ok {
	//	return nil, errors.New("no metadata")
	//}
	//uID := md.Get("user_id")

	readSql, errSelect := database.ReadStruct[models.RefreshTokenStruct]("SELECT * FROM refresh_token WHERE refreshToken = ?", request.Token)
	if errSelect != nil {
		utils.WrapErrorLog(fmt.Sprintf("err: %v\n", errSelect))
		return nil, errSelect
	}

	if len(readSql.RefToken) != 0 && readSql.Used == 0 {
		_, errUpdate := database.InsertSQl("UPDATE refresh_token SET used = 1 WHERE refreshToken = ?", request.Token)
		if errUpdate != nil {
			utils.WrapErrorLog(fmt.Sprintf("err: %v\n", errUpdate))
			return nil, errUpdate

		}
		token, errToken := utils.CreateKeyToken(uint64(readSql.IdUser))
		if errToken != nil {
			utils.WrapErrorLog(fmt.Sprintf("err: %v\n", errToken))
			return nil, errToken
		}

		rf := utils.GenerateSecureToken(32)
		_, errInsertToken := database.InsertSQl("INSERT INTO refresh_token(idUser, refreshToken) VALUES(?, ?)", readSql.IdUser, rf)
		if errInsertToken != nil {
			utils.WrapErrorLog(fmt.Sprintf("err: %v\n", errInsertToken))
			return nil, errInsertToken
		}

		_, errInsertToken = database.InsertSQl("DELETE FROM refresh_token WHERE used = 1")

		return &grpcModels.RefreshTokenResponse{
			Token:        token,
			RefreshToken: rf,
		}, nil

	} else {
		return nil, errors.New("Invalid refresh token")

	}

}
