package main

import (
	"bufio"
	"context"
	"crypto/tls"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"github.com/bitly/go-simplejson"
	"github.com/go-gomail/gomail"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	_ "github.com/gofiber/fiber/v2/utils"
	"github.com/jmoiron/sqlx"
	"github.com/pquerna/otp/totp"
	gpc "google.golang.org/grpc"
	"gopkg.in/guregu/null.v4"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"sort"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
	"xdn-voting/apiWallet"
	"xdn-voting/auth"
	"xdn-voting/bot"
	"xdn-voting/coind"
	"xdn-voting/daemons"
	"xdn-voting/database"
	"xdn-voting/errs"
	"xdn-voting/grpc"
	"xdn-voting/grpcModels"
	"xdn-voting/html"
	"xdn-voting/models"
	"xdn-voting/service"
	"xdn-voting/utils"
	"xdn-voting/web3"
)

var debugTime = false

var wait = time.Second * 15

func main() {
	database.New()
	utils.NewJWT()
	web3.New()
	daemons.InitCron()
	//daemons.InitQueue()

	//debug time
	debugTime = false

	// ============= Price Data  ===============
	go daemons.PriceData()

	// ============= API Wallet ================
	go apiWallet.Handler()

	// ============ TELEGRAM BOT ===============
	go bot.StartTelegramBot()

	// ============= DISCORD BOT ===============
	go bot.StartDiscord()

	// ============= gRPC Service ==============
	go grpc.NewServer()
	go grpc.NewAppServer()

	app := fiber.New(fiber.Config{
		AppName:           "XDN DAO API",
		StrictRouting:     true,
		WriteTimeout:      time.Second * 35,
		ReadTimeout:       time.Second * 35,
		IdleTimeout:       time.Second * 65,
		EnablePrintRoutes: true,
	})
	app.Use(logger.New(logger.Config{
		Format: "[${ip}]:${port} ${status} - ${method} ${path}\n",
		Done: func(c *fiber.Ctx, logString []byte) {
			if c.Response().StatusCode() != 200 {
				utils.WrapErrorLog(string(logString))
			} else {
				utils.WrapErrorLog(string(logString))
			}
		},
	}))
	app.Use(cors.New())
	utils.ReportMessage("Rest API v" + utils.VERSION + " - XDN DAO API | SERVER")
	// ================== DAO ==================
	app.Post("dao/v1/login", login)
	app.Get("dao/v1/ping", auth.Authorized(ping))
	app.Get("dao/v1/contest/get", auth.Authorized(getCurrentContest))
	app.Get("dao/v1/contest/check", auth.Authorized(checkContest))
	app.Post("dao/v1/contest/create", auth.Authorized(createContest))
	app.Post("dao/v1/contest/vote", auth.Authorized(castVote))
	app.Post("dao/v1/address/add", auth.Authorized(addAddress))
	app.Post("dao/v1/user/address/add", auth.Authorized(addUserAddress))

	// ================= ADMIN =================
	app.Get("api/v1/request/withdraw", auth.Authorized(withDrawRequest))
	app.Post("api/v1/request/allow", auth.Authorized(allowRequest))
	app.Post("api/v1/request/unsure", auth.Authorized(unsureRequest))
	app.Post("api/v1/request/vote", auth.Authorized(voteRequest))
	app.Post("api/v1/request/deny", auth.Authorized(denyReq))
	app.Get("api/v1/request/list", auth.Authorized(getReqList))

	app.Post("api/v1/request/withdraw", auth.Authorized(getReqWithApp))

	// ================== API ==================
	app.Post("api/v1/login", loginAPI)
	app.Get("api/v1/login/qr", loginQRAPI)
	app.Post("api/v1/login/qr/auth", auth.Authorized(loginQRAuthAPI))
	app.Post("api/v1/login/qr/token", loginQRTokenAPI)
	app.Post("api/v1/register", registerAPI)
	app.Post("api/v1/login/refresh", refreshToken)
	app.Post("api/v1/login/forgot", forgotPassword)
	app.Post("api/v1/firebase", auth.Authorized(firebaseToken))
	app.Post("api/v1/password/change", auth.Authorized(changePassword))

	app.Get("api/v1/misc/privkey", auth.Authorized(getPrivKey))
	app.Post("api/v1/misc/bug/report", auth.Authorized(reportBug))
	app.Get("api/v1/misc/bug/user", auth.Authorized(getBugList))
	app.Get("api/v1/misc/bug/admin", auth.Authorized(getBugListAdmin))
	app.Post("api/v1/misc/bug/process", auth.Authorized(processBug))
	app.Get("api/v1/misc/admin/wallet", auth.Authorized(adminBalance))

	app.Post("api/v1/twofactor", auth.Authorized(twofactor))
	app.Post("api/v1/twofactor/activate", auth.Authorized(twofactorVerify))
	app.Get("api/v1/twofactor/check", auth.Authorized(twofactorCheck))
	app.Post("api/v1/twofactor/remove", auth.Authorized(twoFactorRemove))

	app.Post("api/v1/staking/graph", auth.Authorized(getStakeGraph))
	app.Post("api/v1/staking/set", auth.Authorized(setStake))
	app.Post("api/v1/staking/unset", auth.Authorized(unstake))
	app.Get("api/v1/staking/info", auth.Authorized(getStakeInfo))
	app.Post("api/v1/staking/auto", auth.Authorized(setAutoStake))

	app.Get("api/v1/masternode/info", auth.Authorized(getMNInfo))
	app.Post("api/v1/masternode/lock", auth.Authorized(lockMN))
	app.Post("api/v1/masternode/unlock", auth.Authorized(unlockMN))
	app.Post("api/v1/masternode/start", auth.Authorized(startMN))
	app.Post("api/v1/masternode/withdraw", auth.Authorized(withdrawMN))
	app.Post("api/v1/masternode/reward", auth.Authorized(rewardMN))
	app.Post("api/v1/masternode/auto", auth.Authorized(setAutoStakeMN))

	app.Post("api/v1/masternode/non/start", auth.Authorized(startNonMN))
	app.Get("api/v1/masternode/non/list", auth.Authorized(listNonMN))
	app.Post("api/v1/masternode/non/restart", auth.Authorized(restartNonMN))
	app.Post("api/v1/masternode/non/tx", auth.Authorized(txNonMn))
	app.Post("api/v1/masternode/non/config", auth.Authorized(nonMNConfig))
	app.Post("api/v1/masternode/add", auth.Authorized(addMasternodeAPI))

	app.Get("api/v1/price/data", auth.Authorized(getPriceData))

	app.Post("api/v1/avatar/upload", auth.Authorized(uploadAvatar))
	app.Post("api/v1/avatar", auth.Authorized(getAvatar))
	app.Post("api/v1/avatar/version", auth.Authorized(getAvatarVersion))

	app.Get("api/v1/user/balance", auth.Authorized(getBalance))
	app.Get("api/v1/user/transactions", auth.Authorized(getTransactions))

	app.Post("api/v1/user/send/contact", auth.Authorized(sendContactTransaction))
	app.Post("api/v1/user/send", auth.Authorized(sendTransaction))

	app.Get("api/v1/user/permissions", auth.Authorized(getPermissions))

	app.Get("api/v1/user/xls", auth.Authorized(getTxXLS))

	app.Get("api/v1/user/messages/group", auth.Authorized(getMessageGroup))
	app.Post("api/v1/user/messages", auth.Authorized(getMessages))
	app.Post("api/v1/user/messages/likes", auth.Authorized(getMessagesLikes))
	app.Post("api/v1/user/messages/send", auth.Authorized(sendMessage))
	app.Post("api/v1/user/messages/read", auth.Authorized(readMessages))

	app.Get("api/v1/user/addressbook", auth.Authorized(getAddressBook))
	app.Post("api/v1/user/addressbook/save", auth.Authorized(saveToAddressBook))
	app.Post("api/v1/user/addressbook/delete", auth.Authorized(deleteFromAddressBook))
	app.Post("api/v1/user/addressbook/update", auth.Authorized(updateAddressBook))

	app.Get("api/v1/user/bot/connect", auth.Authorized(getBotConnect))
	app.Post("api/v1/user/bot/unlink", auth.Authorized(unlinkBot))

	app.Post("api/v1/user/rename", auth.Authorized(renameUser))
	app.Post("api/v1/user/delete", auth.Authorized(deleteUser))

	app.Get("api/v1/user/token/addr", auth.Authorized(getTokenAddr))
	app.Get("api/v1/user/token/wxdn", auth.Authorized(getTokenBalance))
	app.Post("api/v1/user/token/tx", auth.Authorized(getTokenTX))

	app.Get("api/v1/user/stealth/balance", auth.Authorized(getStealthBalance))
	app.Get("api/v1/user/stealth/tx", auth.Authorized(getStealthTX))
	app.Get("api/v1/user/stealth/addr", auth.Authorized(getStealthAddr))
	app.Post("api/v1/user/stealth/send", auth.Authorized(sendStealthTX))

	app.Get("api/v1/status", auth.Authorized(getStatus))

	app.Get("api/v1/file/get", getFile)
	app.Get("api/v1/file/gram", getPictureBots)
	app.Get("api/v1/file", getPicture)
	app.Get("qt/release", getGithubRelease)

	app.Get("blockchain.zip", getBlockchain)

	app.Get("api/v1/ping", func(c *fiber.Ctx) error {
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			utils.ERROR:  true,
			utils.STATUS: utils.ERROR,
		})
	})

	app.Get("/", func(c *fiber.Ctx) error {
		return c.Status(fiber.StatusBadGateway).JSON(&fiber.Map{
			utils.ERROR:  true,
			utils.STATUS: utils.ERROR,
		})
	})
	go daemons.DaemonStatus()
	go daemons.MNStatistic()
	//go daemons.SendRestDaemon()
	utils.ScheduleFunc(daemons.SaveTokenTX, time.Minute*10)
	utils.ScheduleFunc(daemons.DaemonStatus, time.Minute*10)
	utils.ScheduleFunc(daemons.PriceData, time.Minute*5)
	utils.ScheduleFunc(daemons.MNTransaction, time.Minute*1)
	utils.ScheduleFunc(daemons.ScoopMasternode, time.Minute*30)
	utils.ScheduleFunc(daemons.MNStatistic, time.Hour*12)
	utils.ScheduleFunc(apiWallet.RepairWallet, time.Hour*3)
	go func() {
		time.Sleep(time.Second * 30)
		daemons.StartGroupDaemon()
	}()
	// Create tls certificate
	cer, err := tls.LoadX509KeyPair("dex.crt", "dex.key")
	if err != nil {
		log.Fatal(err)
	}

	config := &tls.Config{Certificates: []tls.Certificate{cer}}
	c := make(chan os.Signal, 1)
	signal.Notify(c, syscall.SIGTERM, syscall.SIGINT)

	// Create custom listener
	ln, err := tls.Listen("tcp", "127.0.0.1:6800", config)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		panic(err)
	}
	go func() {
		err := app.Listener(ln)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			//panic(err)
		}
		//utils.WrapErrorLog(error.Error(app.Listener(ln)))
	}()
	<-c

	for bot.Running == true {
		utils.ReportMessage("Waiting for bot to stop")
		time.Sleep(time.Second * 5)
	}

	_, cancel := context.WithTimeout(context.Background(), wait)
	utils.ReportMessage("/// = = Shutting down = = ///")
	defer cancel()
	_ = ln.Close()
	_ = app.Shutdown()
	os.Exit(0)

}

//func removeMasternodeAPI(c *fiber.Ctx) error {
//	type Request struct {
//		NodeID int64 `json:"nodeID"`
//		Force  bool  `json:"force"`
//	}
//	var req Request
//	err := c.BodyParser(&req)
//	if err != nil {
//		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
//	}
//	if req.NodeID == 0 {
//		return utils.ReportError(c, "Node id is missing", fiber.StatusBadRequest)
//	}
//
//	nodeIP, errCrypt := database.ReadValue[string]("SELECT node_ip FROM mn_clients WHERE id = ?", req.NodeID)
//	if errCrypt != nil {
//		utils.ReportMessage("1.0")
//		return utils.ReportError(c, errCrypt.Error(), http.StatusInternalServerError)
//	}
//
//	folder, errCrypt := database.ReadValue[string]("SELECT folder FROM mn_clients WHERE id = ?", req.NodeID)
//	if errCrypt != nil {
//		utils.ReportMessage("1.1")
//		return utils.ReportError(c, errCrypt.Error(), http.StatusInternalServerError)
//	}
//
//	check, err := database.ReadValue[bool]("SELECT active FROM mn_clients WHERE id = ?", req.NodeID)
//	if err != nil {
//		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
//	}
//
//	if check {
//		if req.Force {
//			userID, errUser := database.ReadValue[int64]("SELECT idUser FROM user_mn WHERE idNode = ?", req.NodeID)
//			if errUser != nil {
//				utils.ReportMessage("2")
//				return utils.ReportError(c, errUser.Error(), http.StatusInternalServerError)
//				//return nil, "", errUser
//			}
//
//			addr, errCrypt := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
//			if errCrypt != nil {
//				utils.ReportMessage("3")
//				return utils.ReportError(c, errCrypt.Error(), http.StatusInternalServerError)
//				//return nil, "", errCrypt
//			}
//			_, err = database.InsertSQl("INSERT INTO masternode_tombstone (id) VALUES (?)", req.NodeID)
//			if err != nil {
//				return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
//			}
//
//			tx := &grpcModels.WithdrawMasternodeRequest{
//				NodeID:  uint32(req.NodeID),
//				Address: addr,
//				Amount:  1.0,
//				Type:    1,
//			}
//
//			mn, err := grpcClient.WithdrawMasternode(tx, nodeIP)
//			if err != nil {
//				return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
//			}
//			if mn.Code != 200 {
//				return utils.ReportError(c, "Withdraw unsuccessful", http.StatusInternalServerError)
//			}
//
//			utils.ReportMessage(fmt.Sprintf(" |=> Forced withdrawal of MN id: %d by UserID: %d <=| ", req.NodeID, userID))
//			return nil
//		} else {
//			return utils.ReportError(c, "Masternode is active", fiber.StatusBadRequest)
//		}
//	} else {
//		m, err := grpcClient.PurgeMasternode(&grpcModels.PurgeMasternodeRequest{Folder: folder}, nodeIP)
//		if err != nil {
//			if m != nil {
//				return utils.ReportError(c, m.Message, fiber.StatusConflict)
//			} else {
//				return utils.ReportError(c, err.Error(), fiber.StatusConflict)
//			}
//		}
//	}
//
//	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
//		utils.ERROR:  false,
//		utils.STATUS: utils.OK,
//	})
//}

func addMasternodeAPI(c *fiber.Ctx) error {
	type Request struct {
		NodeIP string `json:"nodeIP"`
		CoinID int64  `json:"coinID"`
	}
	var req Request
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}
	if req.NodeIP == "" {
		return utils.ReportError(c, "Node IP is empty", fiber.StatusBadRequest)
	}
	if req.CoinID == 0 {
		return utils.ReportError(c, "Coin ID is empty", fiber.StatusBadRequest)
	}
	go func() {
		coinTempate, err := database.ReadStruct[models.MasternodeTemplate]("SELECT * FROM mn_template WHERE coinID = ?", req.CoinID)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}

		m, err := grpc.AddMasternode(&grpcModels.AddMasternodeRequest{
			CoinFolder:       coinTempate.CoinFolder,
			MasternodePort:   uint32(coinTempate.MasternodePort),
			BlockchainFolder: coinTempate.BlockchainFolder,
			ConfigName:       coinTempate.ConfigFile,
			DaemonName:       coinTempate.DaemonPath,
			CliName:          coinTempate.CliPath,
			CoinID:           uint32(coinTempate.CoinID),
			PortPrefix:       uint32(coinTempate.PortPrefix),
		}, req.NodeIP)

		if err != nil {
			if m != nil {
				utils.WrapErrorLog(m.Message)
				return
			} else {
				utils.WrapErrorLog(err.Error())
				return
			}
		}

	}()
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func adminBalance(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}
	adm := database.ReadValueEmpty[bool]("SELECT admin FROM users WHERE id = ?", userID)
	if adm == false {
		return utils.ReportError(c, "You are not admin", http.StatusBadRequest)
	}
	walletDaemon := utils.DaemonWallet
	walletStakeDaemon := utils.DaemonStakeWallet
	stakeWallet, err := coind.WrapDaemon(walletStakeDaemon, 1, "getbalance")
	if err != nil {
		return utils.ReportError(c, "stake wallet"+err.Error(), http.StatusBadRequest)
	}

	wallet, err := coind.WrapDaemon(walletDaemon, 1, "getbalance")
	if err != nil {
		return utils.ReportError(c, "wallet"+err.Error(), http.StatusBadRequest)
	}

	walletBalance, err := strconv.ParseFloat(string(wallet), 32)
	if err != nil {
		walletBalance = 0.0
	}
	stakeWalletBalance, err := strconv.ParseFloat(string(stakeWallet), 32)
	if err != nil {
		stakeWalletBalance = 0.0
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:   false,
		utils.STATUS:  utils.OK,
		"wallet":      walletBalance,
		"stakeWallet": stakeWalletBalance,
	})
}

func getPermissions(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}
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
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"admin":      admin,
		"mn":         mnPermission,
		"stealth":    stealthPermission,
	})
}

func nonMNConfig(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}
	type Req struct {
		ID int `json:"idNode"`
	}
	var req Req
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	mn, err := database.ReadStruct[models.MNNonCustodial]("SELECT a.*, b.ip FROM mn_non_custodial as a, mn_clients as b WHERE a.idNode = b.id and a.idNode = ?", req.ID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	str := fmt.Sprintf("MN%d [%s]:%d %s %s %d", mn.IdNode, mn.IP, 18092, mn.MnKey, mn.Txid, mn.Vout)
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"config":     str,
	})
}

func processBug(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}
	type Req struct {
		ID      int     `json:"id"`
		Comment *string `json:"comment"`
		Reward  float32 `json:"reward"`
	}
	var res Req
	err := c.BodyParser(&res)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	adm := database.ReadValueEmpty[bool]("SELECT admin FROM users WHERE id = ?", userID)
	if adm == false {
		return utils.ReportError(c, "You are not admin", http.StatusBadRequest)
	}
	_, err = database.InsertSQl("UPDATE bugs SET processed = 1, comment = ?, reward = ? WHERE id = ?", res.Comment, res.Reward, res.ID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func getBugListAdmin(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}
	adm := database.ReadValueEmpty[bool]("SELECT admin FROM users WHERE id = ?", userID)
	if adm == false {
		return utils.ReportError(c, "You are not admin", http.StatusBadRequest)
	}

	data, err := database.ReadArrayStruct[models.BugsAdmin]("SELECT a.*, b.addr, b.username FROM bugs as a, users as b WHERE a.idUser = b.id ORDER BY a.processed, a.id")
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"data":       data,
	})
}

func getBugList(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}
	data, err := database.ReadArrayStruct[models.Bugs]("SELECT * FROM bugs WHERE idUser = ? ORDER BY id DESC", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"data":       data,
	})
}

func setAutoStakeMN(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}
	var req struct {
		AutoStake bool `json:"autoStake"`
	}
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, "Invalid data", http.StatusBadRequest)
	}
	_, err = database.InsertSQl("UPDATE users_mn SET autostake = ? WHERE idUser = ? AND active = 1", req.AutoStake, userID)
	if err != nil {
		return utils.ReportError(c, "Error setting up auto-stake", http.StatusBadRequest)
	}
	if req.AutoStake == true {
		check := database.ReadValueEmpty[int]("SELECT COUNT(id) FROM users_stake WHERE idUser = ? AND active = 1", userID)
		if check != 0 {
			reward := database.ReadValueEmpty[float64]("SELECT IFNULL(SUM(amount), 0) FROM payouts_masternode WHERE idUser = ? AND credited = 0", userID)
			if reward > 0 {
				_, err = database.InsertSQl("UPDATE users_stake SET amount = amount + ? WHERE idUser = ? AND active = 1", reward, userID)
				if err != nil {
					return utils.ReportError(c, "Error #342", http.StatusBadRequest)
				}
				_, err = database.InsertSQl("UPDATE payouts_masternode SET credited = 1 WHERE idUser = ? ", userID)
				if err != nil {
					return utils.ReportError(c, "Error #984", http.StatusBadRequest)
				}
			}
		} else {
			smax, err := database.ReadValue[float64]("SELECT IFNULL(MAX(session), 0) as smax FROM users_stake WHERE idUser = ?", userID)
			if err != nil {
				return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
			}
			if smax == 0 {
				_, _ = database.InsertSQl("INSERT INTO users_stake (idUser, amount, active, session) VALUES (?, ?, ?, ?)", userID, 0.0, 1, 1)
			} else {
				_, _ = database.InsertSQl("INSERT INTO users_stake (idUser, amount, active, session) VALUES (?, ?, ?, ?)", userID, 0.0, 1, smax+1)
			}
			reward := database.ReadValueEmpty[float64]("SELECT IFNULL(SUM(amount), 0) FROM payouts_masternode WHERE idUser = ? AND credited = 0", userID)
			if reward > 0 {
				_, err = database.InsertSQl("UPDATE users_stake SET amount = amount + ? WHERE idUser = ? AND active = 1", reward, userID)
				if err != nil {
					return utils.ReportError(c, "Error", http.StatusBadRequest)
				}
				_, err = database.InsertSQl("UPDATE payouts_masternode SET credited = 1 WHERE idUser = ? ", userID)
			}
		}
	}
	utils.ReportMessage(fmt.Sprintf("= { User %s set auto stake to %t } =", userID, req.AutoStake))
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func setAutoStake(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}
	var req struct {
		AutoStake bool `json:"autoStake"`
	}
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, "Invalid data", http.StatusBadRequest)
	}

	_, err = database.InsertSQl("UPDATE users_stake SET autostake = ? WHERE idUser = ? AND active = 1", req.AutoStake, userID)
	if err != nil {
		return utils.ReportError(c, "Error", http.StatusBadRequest)
	}
	reward := database.ReadValueEmpty[float64]("SELECT IFNULL(SUM(amount), 0) FROM payouts_stake WHERE idUser = ? AND credited = 0 AND session = (SELECT MAX(session) FROM users_stake WHERE idUser = 1 AND active = 1)", userID)
	if reward > 0 {
		_, err = database.InsertSQl("UPDATE users_stake SET amount = amount + ? WHERE idUser = ? AND active = 1", reward, userID)
		if err != nil {
			return utils.ReportError(c, "Error", http.StatusBadRequest)
		}
		_, err = database.InsertSQl("UPDATE payouts_stake SET credited = 1 WHERE idUser = ? ", userID)
	}
	utils.ReportMessage(fmt.Sprintf("= { User %s set auto stake to %t } =", userID, req.AutoStake))
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func reportBug(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}
	var req struct {
		BugDesc     string `json:"bugDesc"`
		BugLocation string `json:"bugLocation"`
	}
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, "Invalid data", http.StatusBadRequest)
	}

	if req.BugDesc == "" || req.BugLocation == "" {
		return utils.ReportError(c, "Empty data", http.StatusBadRequest)
	}

	if len(req.BugDesc) < 10 || len(req.BugLocation) <= 5 {
		return utils.ReportError(c, "Submitted data is too short, write more", http.StatusBadRequest)
	}

	check := database.ReadValueEmpty[int64]("SELECT count(id) FROM bugs WHERE idUser = ? AND processed = 0", userID)
	if check <= 3 {
		_, err = database.InsertSQl("INSERT INTO bugs (idUser, bugDesc, bugLocation) VALUES (?, ?, ?)", userID, req.BugDesc, req.BugLocation)
		if err != nil {
			return utils.ReportError(c, "Error", http.StatusBadRequest)
		}
	} else {
		return utils.ReportError(c, "You can have up to 3 open bugs", http.StatusBadRequest)
	}
	utils.ReportMessage(fmt.Sprintf("= { New bug report from %s Desc: %s Location: %s } =", userID, req.BugDesc, req.BugLocation))
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func voteRequest(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}
	var req struct {
		ID int  `json:"id"`
		UP bool `json:"up"`
	}
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	adm := database.ReadValueEmpty[bool]("SELECT admin FROM users WHERE id = ?", userID)
	if adm == false {
		return utils.ReportError(c, "You are not admin", http.StatusBadRequest)
	}
	upvote := 0
	downvote := 0
	if req.UP == true {
		upvote = 1
	} else {
		downvote = 1
	}
	_, err = database.InsertSQl("INSERT INTO with_req_votes(idReq, idUser, upvote, downvote) VALUES (?,?,?,?)", req.ID, userID, upvote, downvote)
	if err != nil {
		return utils.ReportError(c, "Already voted", http.StatusConflict)
	}
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func unsureRequest(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}
	var req struct {
		ID int `json:"id"`
	}
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, "Invalid data", http.StatusBadRequest)
	}
	adm := database.ReadValueEmpty[bool]("SELECT admin FROM users WHERE id = ?", userID)
	if adm == false {
		return utils.ReportError(c, "You are not admin", http.StatusBadRequest)
	}
	_, err = database.InsertSQl("INSERT INTO with_req_voting(idReq, idUser) VALUES (?,?)", req.ID, userID)
	if err != nil {
		return utils.ReportError(c, "Can't start voting", http.StatusConflict)
	}
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func getReqList(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}

	requests, err := database.ReadArrayStruct[models.Withdrawals](`SELECT amount, datePosted, dateChanged, idUserAuth, username, send, auth, processed, idTx FROM with_req
																	LEFT JOIN users ON with_req.idUserAuth = users.id
																	WHERE idUser = ? ORDER BY datePosted DESC`, userID)
	if err != nil {
		return utils.ReportError(c, "Internal error", http.StatusInternalServerError)
	}
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"requests":   requests,
	})
}

func getReqWithApp(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}

	var req struct {
		ID string `json:"id"`
	}
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, "Invalid data", http.StatusBadRequest)
	}
	adm := database.ReadValueEmpty[bool]("SELECT admin FROM users WHERE id = ?", userID)
	if adm == false {
		return utils.ReportError(c, "You are not admin", http.StatusBadRequest)
	}
	request, err := database.ReadStruct[models.WithReqVote](`SELECT a.*, b.username, c.idUser as idUserVoting, IFNULL(d.upvote, 0) as upvote, IFNULL(d.downvote, 0) as downvote, IF(c.idUser = ?, true, false) as currentUser
FROM with_req as a
LEFT JOIN users as b ON a.idUser = b.id
LEFT JOIN with_req_voting as c ON a.id = c.idReq
LEFT JOIN (SELECT idReq, SUM(upvote) as upvote, SUM(downvote) as downvote FROM with_req_votes GROUP BY upvote, downvote, idReq) AS d on d.idReq = a.id
WHERE a.processed = 0 AND a.id = ?
ORDER BY a.datePosted`, userID, req.ID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if request.Processed == 1 {
		return utils.ReportError(c, "Request already processed", http.StatusConflict)
	}
	js, err := request.MarshalJSON()
	return c.Status(fiber.StatusOK).Send(js)
}

func allowRequest(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}
	//split := 2000000.0 // in case need to split transaction
	var req struct {
		ID int `json:"id"`
	}
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, "Invalid data", http.StatusBadRequest)
	}
	adm := database.ReadValueEmpty[bool]("SELECT admin FROM users WHERE id = ?", userID)
	if adm == false {
		return utils.ReportError(c, "You are not admin", http.StatusBadRequest)
	}
	request, err := database.ReadStruct[models.WithReq]("SELECT * FROM with_req WHERE id = ?", req.ID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if request.Processed == 1 {
		return utils.ReportError(c, "Request already processed", http.StatusBadRequest)
	}
	userAddr := database.ReadValueEmpty[string]("SELECT addr FROM users WHERE id = ?", request.IdUser)
	if userAddr == "" {
		return utils.ReportError(c, "User address not found", http.StatusBadRequest)
	}
	server, err := database.ReadValue[string]("SELECT addr FROM servers_stake WHERE id = 1")
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	txId := ""
	amountToSent := request.Amount - request.SentAmount
	split := 2000000.0
	if amountToSent > split {
		splitArr := make([]float64, 0)
		amount := amountToSent
		for {
			if amount > split {
				splitArr = append(splitArr, split)
				amount = amount - split
			} else {
				splitArr = append(splitArr, amount)
				break
			}
		}
		for _, amnt := range splitArr {
			tries := 0
			for {
				tx, err := coind.SendCoins(userAddr, server, amnt, true)
				if err != nil {
					tries++
					if tries > 3 {
						break
					}
					time.Sleep(10 * time.Second)
					utils.ReportMessage("Error sending coins to user, waiting")
					continue
				}
				txId = tx
				break
			}
			if txId == "" {
				return utils.ReportError(c, "Error sending coins to user", http.StatusConflict)
			}
			if err != nil {
				time.Sleep(10 * time.Second)
				utils.ReportMessage("Error sending coins to user, waiting")
				return utils.ReportError(c, err.Error(), http.StatusConflict)
			}
			_, errDB := database.InsertSQl("UPDATE with_req SET sentAmount = sentAmount + ? WHERE id = ?", amnt, request.Id)
			if errDB != nil {
				return utils.ReportError(c, err.Error(), http.StatusBadRequest)
			}
		}
	} else {
		tx, err := coind.SendCoins(userAddr, server, amountToSent, true)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusConflict)
		}
		_, errDB := database.InsertSQl("UPDATE with_req SET sentAmount = sentAmount + ? WHERE id = ?", amountToSent, request.Id)
		if errDB != nil {
			return utils.ReportError(c, err.Error(), http.StatusBadRequest)
		}
		txId = tx
	}
	//_, errDB := database.InsertSQl("UPDATE with_req SET sentAmount = sentAmount + ? WHERE id = ?", request.Amount, request.Id)
	//if errDB != nil {
	//    return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	//}
	_, err = database.InsertSQl("UPDATE with_req SET idUserAuth = ? WHERE id = ?", userID, request.Id)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	_, err = database.InsertSQl("UPDATE with_req SET processed = 1, auth = 1 WHERE id = ?", request.Id)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	_, err = database.InsertSQl("UPDATE with_req SET idTx = ? WHERE id = ?", txId, request.Id)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if request.WithdrawType == 0 {
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE txid = ? AND category = ? AND id <> 0 LIMIT 1", "Staking withdrawal", txId, "receive")
	} else if request.WithdrawType == 1 {
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE txid = ? AND category = ? AND id <> 0 LIMIT 1", "Masternode withdrawal", txId, "receive")
	} else {
		//_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE txid = ? AND category = ? AND id <> 0 LIMIT 1", "Masternode withdrawal", tx, "receive")
	}
	_, err = database.InsertSQl("UPDATE with_req SET send = 1 WHERE id = ?", request.Id)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func denyReq(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}

	var req struct {
		ID int `json:"id"`
	}
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, "Invalid data", http.StatusBadRequest)
	}
	utils.ReportMessage(fmt.Sprintf("Deny request %d", req.ID))
	adm := database.ReadValueEmpty[bool]("SELECT admin FROM users WHERE id = ?", userID)
	if adm == false {
		return utils.ReportError(c, "You are not admin", http.StatusBadRequest)
	}
	request, err := database.ReadStruct[models.WithReq]("SELECT * FROM with_req WHERE id = ?", req.ID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if request.Processed == 1 {
		return utils.ReportError(c, "Request already processed", http.StatusBadRequest)
	}
	_, err = database.InsertSQl("UPDATE with_req SET processed = 1, auth = 0 WHERE id = ?", request.Id)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	_, err = database.InsertSQl("UPDATE with_req SET idUserAuth = ? WHERE id = ?", userID, request.Id)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	go checkDeny()
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func checkDeny() {
	type BanStruct struct {
		IDUser int `db:"idUser"`
	}
	deniedUSR, err := database.ReadArrayStruct[BanStruct]("SELECT idUser FROM with_req GROUP BY idUser HAVING SUM(processed) >= SUM(auth) + 3")
	if err != nil {
		return
	}
	for _, v := range deniedUSR {
		_, err := database.InsertSQl("UPDATE users SET banned = 1 WHERE id = ?", v.IDUser)
		_, err = database.InsertSQl("UPDATE users_bot SET ban = 1 WHERE id= ?", v.IDUser)
		if err != nil {
			return
		}
	}
}

func withDrawRequest(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "Unauthorized", http.StatusBadRequest)
	}

	isAdmin, err := database.ReadValue[bool]("SELECT admin FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, "You are not admin", http.StatusBadRequest)
	}
	if isAdmin == false {
		return utils.ReportError(c, "You are not admin", http.StatusBadRequest)
	}

	request, err := database.ReadArrayStruct[models.WithReqVote](`SELECT a.*, b.username, c.idUser as idUserVoting, IFNULL(d.upvote, 0) as upvote, IFNULL(d.downvote, 0) as downvote, IF(c.idUser = ?, true, false) as currentUser FROM with_req as a
LEFT JOIN users as b ON a.idUser = b.id
LEFT JOIN with_req_voting as c ON a.id = c.idReq
LEFT JOIN (SELECT idReq, SUM(upvote) as upvote, SUM(downvote) as downvote FROM with_req_votes GROUP BY upvote, downvote, idReq) AS d on d.idReq = a.id
WHERE a.processed = 0 AND a.amount > 0.01
ORDER BY a.datePosted`, userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusConflict)
	}
	for i, _ := range request {
		request[i].Amount = request[i].Amount - request[i].SentAmount
	}
	if len(request) == 0 {
		return utils.ReportErrorSilent(c, "No requests available", http.StatusConflict)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"requests":   request,
	})
}

func txNonMn(c *fiber.Ctx) error {
	var Req struct {
		Tx string `json:"tx"`
	}

	err := c.BodyParser(&Req)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}

	addrCheck, errNet := utils.GETAny(fmt.Sprintf("https://xdn-explorer.com/ext/gettx/%s", Req.Tx))
	if errNet != nil {
		utils.WrapErrorLog(errNet.ErrorMessage() + " " + strconv.Itoa(errNet.StatusCode()))
		return utils.ReportError(c, errNet.ErrorMessage(), errNet.StatusCode())
	}

	bodyXDN, _ := io.ReadAll(addrCheck.Body)
	defer func(Body io.ReadCloser) {
		err := Body.Close()
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
	}(addrCheck.Body)

	var sum models.BlockTX
	err = json.Unmarshal(bodyXDN, &sum)
	if err != nil {
		return utils.ReportErrorSilent(c, err.Error(), http.StatusInternalServerError)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:     false,
		utils.STATUS:    utils.OK,
		"confirmations": sum.Confirmations,
	})

}

func restartNonMN(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(&fiber.Map{
			utils.ERROR:         true,
			utils.STATUS:        utils.ERROR,
			utils.ERROR_MESSAGE: "Unauthorized",
		})
	}

	var request models.MNUnlockStruct
	errJson := c.BodyParser(&request)
	if errJson != nil {
		return utils.ReportError(c, errJson.Error(), http.StatusBadRequest)
	}

	nodeExists := database.ReadValueEmpty[bool]("SELECT EXISTS (SELECT id FROM mn_clients WHERE id = ?)", request.IdNode)
	if !nodeExists {
		return utils.ReportError(c, "Node not found", http.StatusBadRequest)
	}

	belongToUser := database.ReadValueEmpty[bool]("SELECT EXISTS (SELECT id FROM users_mn WHERE idUser = ? AND idNode = ?)", userID, request.IdNode)
	if !belongToUser {
		return utils.ReportError(c, "You don't have access to this masternode", http.StatusBadRequest)
	}

	nodeIP := database.ReadValueEmpty[sql.NullString]("SELECT node_ip FROM mn_clients WHERE id = ?", request.IdNode)
	if !nodeIP.Valid {
		return utils.ReportError(c, "Node IP not found", http.StatusBadRequest)
	}

	creds, err := grpcModels.LoadTLSCredentials()
	if err != nil {
		return utils.ReportError(c, "cannot load TLS credentials: "+err.Error(), http.StatusInternalServerError)

	}
	grpcCon, err := gpc.Dial(fmt.Sprintf("%s:6810", nodeIP.String), gpc.WithTransportCredentials(creds))
	if err != nil {
		return utils.ReportError(c, "cannot connect to gRPC server: "+err.Error(), http.StatusInternalServerError)
	}
	tx := &grpcModels.RestartMasternodeRequest{
		NodeID: uint32(request.IdNode),
	}
	cc := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
	resp, err := cc.RestartMasternode(context.Background(), tx)
	if err != nil {
		_ = grpcCon.Close()
		return utils.ReportError(c, "cannot restart masternode: "+err.Error(), http.StatusInternalServerError)
	}
	_ = grpcCon.Close()
	if resp.Code == 200 {
		utils.ReportMessage(fmt.Sprintf("Masternode %d restarted", request.IdNode))
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			utils.ERROR:         false,
			utils.STATUS:        utils.OK,
			utils.ERROR_MESSAGE: "Masternode restarted",
		})
	} else {
		utils.ReportMessage(fmt.Sprintf("Somethings wrong on node %s while restarting node %d", nodeIP.String, request.IdNode))
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			utils.ERROR:         true,
			utils.STATUS:        utils.FAIL,
			utils.ERROR_MESSAGE: "Problem with node restart",
		})
	}
}

func listNonMN(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(&fiber.Map{
			utils.ERROR:         true,
			utils.STATUS:        utils.ERROR,
			utils.ERROR_MESSAGE: "Unauthorized",
		})
	}

	data, err := database.ReadArrayStruct[models.NonMNStruct]("SELECT a.id, a.ip, a.last_seen, a.active_time, a.active, a.error, a.address FROM mn_clients as a, users_mn as b WHERE a.custodial = 0 AND a.id = b.idNode AND b.idUser = ?", userID)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(&fiber.Map{
			utils.ERROR:         true,
			utils.STATUS:        utils.ERROR,
			utils.ERROR_MESSAGE: err.Error(),
		})
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"data":       data,
	})
}

func startNonMN(c *fiber.Ctx) error {
	userID := c.Get("User_id")

	var request models.SetNonMN
	errJson := c.BodyParser(&request)
	if errJson != nil {
		return utils.ReportError(c, errJson.Error(), http.StatusBadRequest)
	}

	admin := database.ReadValueEmpty[int64]("SELECT admin FROM users WHERE id = ?", userID)
	tier := database.ReadValueEmpty[int64]("SELECT mn FROM users_permission WHERE idUser = ?", userID)
	count := database.ReadValueEmpty[int64](`SELECT SUM(t1.count) as count FROM (SELECT COUNT(id) as count
                        FROM users_mn
                        WHERE idUser = ?
                          AND active = 1
                        UNION ALL
                        SELECT COUNT(id) as count
                        FROM mn_incoming_tx
                        WHERE idUser = ?
                          AND processed = 0) as t1`, userID, userID)
	utils.ReportMessage(fmt.Sprintf("User %s has %d MNs with tier %d (admin: %d)", userID, count, tier, admin))

	nodesCount := database.ReadValueEmpty[int64]("SELECT IFNULL(COUNT(id),0) FROM mn_clients WHERE locked = 0 AND active = 0")
	if nodesCount == 0 {
		return utils.ReportError(c, "No free nodes", http.StatusBadRequest)
	}

	if admin == 0 && count <= tier {
		return utils.ReportError(c, "You are not allowed to start more masternodes", http.StatusConflict)
	}

	check := database.ReadValueEmpty[sql.NullBool]("SELECT EXISTS (SELECT id FROM mn_non_custodial WHERE addr =?)", request.Address)
	if check.Valid && check.Bool {
		return utils.ReportError(c, "Address already in use, if needed please restart node with this address from main menu", http.StatusConflict)
	}

	addrCheck, errNet := utils.GETAny(fmt.Sprintf("https://xdn-explorer.com/ext/getaddress/%s", request.Address))
	if errNet != nil {
		utils.WrapErrorLog(errNet.ErrorMessage() + " " + strconv.Itoa(errNet.StatusCode()))
		return utils.ReportError(c, errNet.ErrorMessage(), errNet.StatusCode())
	}

	bodyXDN, _ := io.ReadAll(addrCheck.Body)
	defer func(Body io.ReadCloser) {
		err := Body.Close()
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
	}(addrCheck.Body)

	var sum models.MNAddressCheck
	var errAddr models.MNAddrProblem
	err := json.Unmarshal(bodyXDN, &sum)
	if err != nil {
		return utils.ReportErrorSilent(c, errAddr.Error, http.StatusInternalServerError)
	}

	err = json.Unmarshal(bodyXDN, &errAddr)
	if err != nil {
		return utils.ReportErrorSilent(c, err.Error(), http.StatusInternalServerError)
	}

	if errAddr.Error != "" {
		return utils.ReportErrorSilent(c, errAddr.Error, http.StatusConflict)
	}

	if sum.Balance != "2000000" {
		return utils.ReportError(c, "Address balance is not 2 mil XDN", http.StatusConflict)
	}

	if len(sum.LastTxs) == 0 {
		return utils.ReportError(c, "Address has no transactions", http.StatusConflict)
	}

	tx := sum.LastTxs[0].Addresses

	var ing models.MNTX
	p, _ := coind.WrapDaemon(utils.DaemonWallet, 5, "gettransaction", tx)
	err = json.Unmarshal(p, &ing)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	var vout int
	txid := ing.Txid
	for _, v := range ing.Vout {
		if v.Value == 2000000.0 {
			vout = v.N
			break
		}
	}

	s, err := coind.WrapDaemon(utils.DaemonWallet, 5, "masternode", "genkey")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	var empty models.MasternodeClient
	var idNode int64

	for {
		freeMN := database.ReadStructEmpty[models.MasternodeClient]("SELECT * FROM mn_clients WHERE coin_id = ? AND locked = 0 AND active = 0 LIMIT 1", request.CoinID)
		if freeMN == empty {
			return utils.ReportError(c, "No free MNs left for this coin", fiber.StatusConflict)
		} else {
			//token, _ := database.ReadValue[string]("SELECT token FROM mn_server WHERE url = ?", freeMN.NodeIP)
			utils.ReportMessage(fmt.Sprintf("NODE FREE: %d", freeMN.ID))
			creds, err := grpcModels.LoadTLSCredentials()
			if err != nil {
				utils.WrapErrorLog("cannot load TLS credentials: " + err.Error())
				return utils.ReportError(c, "cannot load TLS credentials: "+err.Error(), fiber.StatusInternalServerError)
			}
			grpcCon, err := gpc.Dial(fmt.Sprintf("%s:6810", freeMN.NodeIP), gpc.WithTransportCredentials(creds))
			if err != nil {
				utils.WrapErrorLog(err.Error())
				return utils.ReportError(c, err.Error(), fiber.StatusInternalServerError)
			}
			tx := &grpcModels.CheckMasternodeRequest{NodeID: uint32(freeMN.ID)}
			cc := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
			resp, err := cc.CheckMasternode(context.Background(), tx)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				return utils.ReportError(c, err.Error(), fiber.StatusInternalServerError)
			}

			if resp.Code != 200 {
				utils.ReportMessage(fmt.Sprintf("Somethings wrong on node %s", freeMN.NodeIP))

				_, _ = database.InsertSQl("UPDATE mn_clients SET locked = 1 WHERE id = ? ", freeMN.ID)
				//sendWarningMessage(68857, "Error Node", fmt.Sprintf("Error Node %d", freeMN.ID)) //TODO: Send message to admin
				continue
			}
			utils.ReportMessage(fmt.Sprintf("NODE OK: %d", freeMN.ID))
			_, errUpdate := database.InsertSQl("UPDATE mn_clients SET locked = 1 WHERE id = ? ", freeMN.ID)
			if errUpdate != nil {
				utils.WrapErrorLog(errUpdate.Error())
			}
			_ = grpcCon.Close()
			idNode = int64(freeMN.ID)
			break
		}
	}

	nodeIP := database.ReadValueEmpty[sql.NullString]("SELECT ip FROM mn_clients WHERE id = ?", idNode)

	if nodeIP.Valid == false {
		_, _ = database.InsertSQl("UPDATE mn_clients SET locked = 0 WHERE id = ? ", idNode)
		return utils.ReportError(c, "Node not found", http.StatusNotFound)
	}

	mnKey := strings.Trim(string(s), "\"")
	_, _ = database.InsertSQl("INSERT INTO mn_non_custodial (idUser, idCoin, addr, txid, vout, mnKey, idNode) VALUES (?, ?, ?, ?, ?, ?, ?)", userID, request.CoinID, request.Address, txid, vout, mnKey, idNode)
	str := fmt.Sprintf("MN%d [%s]:%d %s %s %d", idNode, nodeIP.String, 18092, mnKey, txid, vout)
	nIP := database.ReadValueEmpty[sql.NullString]("SELECT node_ip FROM mn_clients WHERE id = ?", idNode)
	if nodeIP.Valid == false {
		_, _ = database.InsertSQl("UPDATE mn_clients SET locked = 0 WHERE id = ? ", idNode)
		return utils.ReportError(c, "Node not found", http.StatusNotFound)
	}
	creds, err := grpcModels.LoadTLSCredentials()
	if err != nil {
		_, _ = database.InsertSQl("UPDATE mn_clients SET locked = 0 WHERE id = ? ", idNode)
		utils.WrapErrorLog("cannot load TLS credentials: " + err.Error())
		return utils.ReportError(c, "cannot load TLS credentials: "+err.Error(), fiber.StatusInternalServerError)
	}
	grpcCon, err := gpc.Dial(fmt.Sprintf("%s:6810", nIP.String), gpc.WithTransportCredentials(creds))
	if err != nil {
		_, _ = database.InsertSQl("UPDATE mn_clients SET locked = 0 WHERE id = ? ", idNode)
		utils.WrapErrorLog(err.Error())
		return utils.ReportError(c, err.Error(), fiber.StatusInternalServerError)
	}
	cc := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
	txGRPC := &grpcModels.StartNonMasternodeRequest{
		NodeID:    uint32(idNode),
		WalletKey: mnKey,
	}
	resp, err := cc.StartNonMasternode(context.Background(), txGRPC)
	if err != nil {
		_, _ = database.InsertSQl("UPDATE mn_clients SET locked = 0 WHERE id = ? ", idNode)
		utils.WrapErrorLog(err.Error())
		return utils.ReportError(c, err.Error(), fiber.StatusInternalServerError)
	}
	if resp.Code == 200 {
		var smax int64 = 0
		nodeSession := database.ReadValueEmpty[sql.NullInt64]("SELECT MAX(session) as smax FROM users_mn WHERE idNode = ?", idNode)
		if nodeSession.Valid {
			smax = nodeSession.Int64 + 1
		}
		_, _ = database.InsertSQl("INSERT INTO users_mn(idUser, idCoin, tier, idNode, session, custodial) VALUES (?, ?, ?, ?, ?,?)", userID, 0, 1, idNode, smax, 0)
		utils.ReportMessage(fmt.Sprintf("Start non-custodial wallet on node %s", nIP.String))
	} else {
		_, _ = database.InsertSQl("UPDATE mn_clients SET locked = 0 WHERE id = ? ", idNode)
		utils.ReportMessage(fmt.Sprintf("Somethings wrong on node %s", nIP.String))
	}
	_ = grpcCon.Close()
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"data":       str,
		"started":    false,
	})

}

func sendStealthTX(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if len(userID) == 0 {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type dataReq struct {
		StealthAddr string  `json:"stealth_addr"`
		Address     string  `json:"address"`
		Amount      float64 `json:"amount"`
	}
	var data dataReq
	if err := c.BodyParser(&data); err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}

	if data.Address == "" || data.Amount == 0 {
		return utils.ReportError(c, "All fields has to be populated", fiber.StatusBadRequest)
	}

	belongToUser := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM stealth_addr WHERE addr = ? AND idUser = ?", data.StealthAddr, userID)
	if !belongToUser.Valid {
		return utils.ReportError(c, "Stealth address does not belong to user", fiber.StatusBadRequest)
	}

	//addrSend, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)

	_, err := coind.SendCoins(data.Address, data.StealthAddr, data.Amount, false)
	if err != nil {
		return utils.ReportError(c, "Wallet problem, try again later", fiber.StatusConflict)
	}

	return c.JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func getStealthAddr(c *fiber.Ctx) error {
	// Get user
	userID := c.Get("User_id")
	user := database.ReadValueEmpty[sql.NullString]("SELECT username FROM users WHERE id = ?", userID)
	if user.Valid == false {
		return utils.ReportError(c, "User not found", fiber.StatusBadRequest)
	}

	admin := database.ReadValueEmpty[int64]("SELECT admin FROM users WHERE id = ?", userID)
	tier := database.ReadValueEmpty[int64]("SELECT stealth FROM users_permission WHERE idUser = ?", userID)
	count := database.ReadValueEmpty[int64]("SELECT IFNULL(COUNT(*),0) as count FROM stealth_addr WHERE idUser = ?", userID)

	if admin == 0 && tier <= count {
		return utils.ReportError(c, "You have reached the maximum number of stealth addresses with your plan", http.StatusConflict)
	}
	addrName := fmt.Sprintf("%s@%d", user.String, count+1)
	// Get stealth address
	address, err := coind.WrapDaemon(utils.DaemonWallet, 2, "getnewaddress", addrName)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusInternalServerError)
	}
	_, _ = database.InsertSQl("INSERT INTO stealth_addr (idUser, addr, addrName) VALUES (?,?, ?)", userID, strings.Trim(string(address), "\""), addrName)
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func getStealthTX(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	//var txReq models.GetTokenTxReq
	//if err := c.BodyParser(&txReq); err != nil {
	//	return err
	//}

	addr, err := database.ReadArrayStruct[models.Stealth]("SELECT * FROM stealth_addr WHERE idUser = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	type TX struct {
		Addr    string               `json:"addr"`
		Balance float64              `json:"bal"`
		TX      []models.Transaction `json:"tx"`
	}
	var txArr []TX
	if len(addr) > 0 {
		for _, v := range addr {
			address := v.Addr
			if len(address) == 0 {
				continue
			}

			unspent, err := coind.WrapDaemon(utils.DaemonWallet, 5, "listunspent", 1, 9999999, []string{v.Addr})
			if err != nil {
				return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
			}
			var ing []models.ListUnspent
			spendable := 0.0
			errJson := json.Unmarshal(unspent, &ing)
			if errJson != nil {
				return utils.ReportError(c, errJson.Error(), http.StatusInternalServerError)
			}
			for _, v := range ing {
				if v.Spendable == true {
					spendable += v.Amount
				}
			}

			//balance, err := web3.GetContractBalance(address)
			//if err != nil {
			//	return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
			//}

			db, err := database.ReadArrayStruct[models.Transaction]("SELECT * FROM transaction WHERE account = ?", v.AddrName)
			if err != nil {
				return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
			}
			txArr = append(txArr, TX{
				Addr:    address,
				Balance: spendable,
				TX:      db,
			})
		}
	} else {
		txArr = append(txArr, TX{
			Addr:    "",
			Balance: 0.0,
			TX:      []models.Transaction{},
		})
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			utils.ERROR:  false,
			utils.STATUS: utils.OK,
			"rest":       txArr,
		})
		//return utils.ReportError(c, "No user addresses in the db", http.StatusConflict)
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"rest":       txArr,
	})
}

func getTokenAddr(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(&fiber.Map{
			utils.ERROR:  true,
			utils.STATUS: utils.ERROR,
		})
	}
	type AddrStruct struct {
		Addr string `json:"addr" db:"addr"`
	}
	addr := database.ReadStructEmpty[AddrStruct]("SELECT addr FROM users WHERE id = ?", userID)
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"addr":       addr,
	})
}

func rewardMN(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	uid, _ := strconv.Atoi(userID)
	var mnInfoReq models.MNInfoStruct
	errDB := apiWallet.CheckStakeBalance()
	if errDB != nil {
		return utils.ReportError(c, "Withdrawing rewards on maintenance, stand by", http.StatusConflict)
	}
	amountToSend, _ := database.ReadValue[float64]("SELECT IFNULL(SUM(amount), 0) as amount FROM payouts_masternode WHERE idUser = ? AND credited = 0 AND idCoin = ?", userID, mnInfoReq.IdCoin)
	if amountToSend < 0.1 {
		return utils.ReportError(c, "Can't withdraw less than 0.1 XDN", fiber.StatusConflict)
	}
	exist, err := database.ReadValue[int]("SELECT COUNT(id) FROM requests WHERE idUser = ? AND masternode = 1 AND processed = 0", uid)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if exist > 0 {
		return utils.ReportError(c, "You have an active request", http.StatusBadRequest)
	}

	_, _ = database.InsertSQl("INSERT INTO requests (idUser, staking, masternode) VALUES (?, ?, ?)", userID, 0, 1)

	defer unrequestMasternode(uid)
	//server, err := database.ReadValue[string]("SELECT addr FROM servers_stake WHERE id = 1")
	userAddr, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	utils.ReportMessage(fmt.Sprintf("! - Reward withdrawal of %f sent to %s - !", amountToSend, userID))
	_, _ = database.InsertSQl("UPDATE payouts_masternode SET credited = ? WHERE idUser = ?", 1, userID)
	//_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE txid = ? AND category = ? AND id <> 0 LIMIT 1", "Masternode Reward", tx, "receive")
	//time.Sleep(time.Millisecond * 200)
	idd, err := database.InsertSQl("INSERT with_req (idUser, amount, address, withdrawType) VALUES (?, ?, ?, ?)", userID, amountToSend, userAddr, 1)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	go service.SendAdminsReq(idd)
	return utils.ReportError(c, "Your withdraw request is on review", http.StatusConflict)
	//tx, err := coind.SendCoins(userAddr, server, amountToSend, true)
	//if err != nil {
	//	return utils.ReportError(c, err.Error(), http.StatusConflict)
	//}
	//user, err := database.ReadStruct[models.MNUsers]("SELECT * FROM users_mn WHERE idUser = ? AND active = ?", userID, 1)
	//if err != nil {
	//	return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	//}
	//utils.ReportMessage(fmt.Sprintf("! - Reward withdrawal of %f sent to %s - !", amountToSend, userID))
	//_, _ = database.InsertSQl("UPDATE payouts_masternode SET credited = ? WHERE idUser = ?", 1, userID)
	//_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE txid = ? AND category = ? AND id <> 0 LIMIT 1", "Masternode Reward", tx, "receive")
	//time.Sleep(time.Millisecond * 200)
	//
	//j := simplejson.New()
	//j.Set(utils.STATUS, utils.OK)
	//j.Set("hasError", false)
	//j.Set("tx_id", tx)
	//payload, err := j.MarshalJSON()
	//return c.Status(fiber.StatusOK).Send(payload)
}

func withdrawMN(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	uid, err := strconv.Atoi(userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	var stakeReq models.MNWithStruct
	errJson := c.BodyParser(&stakeReq)
	if errJson != nil {
		return utils.ReportError(c, "JSON Request Body empty", http.StatusBadRequest)
	}

	exist, err := database.ReadValue[int]("SELECT COUNT(id) FROM requests WHERE idUser = ? AND masternode = 1 AND processed = 0", uid)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if exist > 0 {
		return utils.ReportError(c, "You have an active request", http.StatusBadRequest)
	}

	_, _ = database.InsertSQl("INSERT INTO requests (idUser, staking, masternode) VALUES (?, ?, ?)", userID, 0, 1)

	defer unrequestMasternode(uid)

	userNode, _ := database.ReadValue[int64]("SELECT COUNT(*) FROM users_mn WHERE idUser = ? AND idNode = ? AND active = 1", userID, stakeReq.IdNode)
	if userNode == 0 {
		return utils.ReportError(c, "Selected node does not belong to the user", http.StatusConflict)

	}

	dateStarted := database.ReadValueEmpty[sql.NullTime]("SELECT dateStart FROM users_mn WHERE idUser = ? AND idNode = ? AND active = 1", userID, stakeReq.IdNode)

	if dateStarted.Valid == false {
		return utils.ReportError(c, "Coins are still locked", http.StatusConflict)
	}

	dateChanged := dateStarted.Time.UTC().UnixMilli()
	dateNow := time.Now().UnixMilli()
	dateDiff := dateNow - dateChanged

	if dateDiff < 604800000 {
		return utils.ReportError(c, "Coins are locked", http.StatusConflict)
	}

	ur, errCrypt := database.ReadValue[string]("SELECT node_ip FROM mn_clients WHERE id = ?", stakeReq.IdNode)
	//coinID, errCrypt := database.ReadValue[string]("SELECT coin_id FROM mn_clients WHERE id = ?", stakeReq.IdNode)
	if errCrypt != nil {
		utils.ReportMessage("1")
		return utils.ReportError(c, errCrypt.Error(), http.StatusInternalServerError)

		//return nil, "", errCrypt
	}

	//var amount float64

	addr, errCrypt := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	if errCrypt != nil {
		utils.ReportMessage("3")
		return utils.ReportError(c, errCrypt.Error(), http.StatusInternalServerError)

	}
	str := &grpcModels.WithdrawRequest{}
	str.NodeID = uint32(stakeReq.IdNode)
	str.Amount = 1.0
	str.Deposit = addr
	str.Type = 1

	creds, err := grpcModels.LoadTLSCredentials()
	if err != nil {

	}

	grpcCon, err := gpc.Dial(fmt.Sprintf("%s:6810", ur), gpc.WithTransportCredentials(creds))
	if err != nil {
	}
	cs := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
	resp, err := cs.Withdraw(context.Background(), str)
	if err != nil {
		return utils.ReportError(c, "cannot dial x: "+err.Error(), http.StatusInternalServerError)
	}

	if resp.Code == 200 {
		utils.ReportMessage("Withdraw success")
	}

	utils.ReportMessage(fmt.Sprintf(" |=> Full Withdrawal of MN id: %d by UserID: %s <=| ", stakeReq.IdNode, userID))
	j := simplejson.New()
	j.Set(utils.STATUS, utils.OK)
	j.Set(utils.ERROR, false)
	return c.Status(fiber.StatusOK).JSON(j)
}

func unrequestMasternode(idUser int) {
	_, _ = database.InsertSQl("UPDATE requests SET processed = 1 WHERE idUser = ? AND masternode = 1 AND processed = 0 AND id <> 0 LIMIT 1", idUser)
}

func startMN(c *fiber.Ctx) error {
	userID := c.Get("User_id")

	var request models.SetMN
	errJson := c.BodyParser(&request)
	if errJson != nil {
		return utils.ReportError(c, errJson.Error(), http.StatusBadRequest)
	}

	admin := database.ReadValueEmpty[int64]("SELECT admin FROM users WHERE id = ?", userID)
	tier := database.ReadValueEmpty[int64]("SELECT mn FROM users_permission WHERE idUser = ?", userID)
	count := database.ReadValueEmpty[int64](`SELECT SUM(t1.count) as count FROM (SELECT COUNT(id) as count
                        FROM users_mn
                        WHERE idUser = ?
                          AND active = 1
                        UNION ALL
                        SELECT COUNT(id) as count
                        FROM mn_incoming_tx
                        WHERE idUser = ?
                          AND processed = 0) as t1`, userID, userID)
	utils.ReportMessage(fmt.Sprintf("User %s has %d MNs with tier %d (admin: %d)", userID, count, tier, admin))

	if admin == 0 && count <= tier {
		return utils.ReportError(c, "You are not allowed to start more masternodes", http.StatusConflict)
	}

	nodeAddr := database.ReadValueEmpty[sql.NullString]("SELECT address FROM mn_clients WHERE id = ?", request.NodeID)
	if !nodeAddr.Valid {
		return utils.ReportError(c, "Node not found", fiber.StatusBadRequest)
	}
	usedAddr := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM users WHERE id = ?", userID)
	if !usedAddr.Valid {
		return utils.ReportError(c, "User not found", fiber.StatusBadRequest)
	}
	tx, err := coind.SendCoins(nodeAddr.String, usedAddr.String, 2000000.01, false)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusConflict)
	}
	if len(tx) == 0 {
		return utils.ReportError(c, "TX id is missing", fiber.StatusBadRequest)
	}
	_, errInsert := database.InsertSQl("INSERT INTO mn_incoming_tx(idUser, idCoin, idNode, tx_id, amount) VALUES(?, ?, ?, ?,?)",
		userID, request.CoinID, request.NodeID, tx, 2000000)
	if errInsert != nil {
		return utils.ReportError(c, fmt.Sprintf("TX id already submitted %s", errInsert.Error()), fiber.StatusBadRequest)
	}
	_, errUpdate := database.InsertSQl("UPDATE mn_clients SET locked = 1 WHERE id = ?", request.NodeID)
	if errUpdate != nil {
		return utils.ReportError(c, errUpdate.Error(), fiber.StatusBadRequest)
	}
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})

}

func unlockMN(c *fiber.Ctx) error {
	var mnInfoReq models.MNUnlockStruct
	errJson := c.BodyParser(&mnInfoReq)
	if errJson != nil {
		return utils.ReportError(c, "JSON Request Body empty", http.StatusBadRequest)

	}

	type ActiveMN struct {
		ID     sql.NullInt64 `json:"id"`
		Active sql.NullInt64 `json:"active"`
	}

	freeMN, err := database.ReadStruct[ActiveMN]("SELECT id, active FROM mn_clients WHERE id = ?", mnInfoReq.IdNode)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)

	}

	if !freeMN.ID.Valid {
		return utils.ReportError(c, "Node was not found", http.StatusForbidden)

	} else if freeMN.Active.Int64 == 1 {
		return utils.ReportError(c, "Node is active!", http.StatusConflict)

	} else {
		_, errUpdate := database.InsertSQl("UPDATE mn_clients SET locked = 0 WHERE id = ? ", freeMN.ID.Int64)
		if errUpdate != nil {
			utils.WrapErrorLog(errUpdate.Error())
			return utils.ReportError(c, errUpdate.Error(), http.StatusConflict)

		}
	}

	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func lockMN(c *fiber.Ctx) error {
	//userID := c.Get("User_id")
	var mnInfoReq models.MNInfoStruct
	errJson := c.BodyParser(&mnInfoReq)
	if errJson != nil {
		return utils.ReportError(c, "JSON Request Body empty", fiber.StatusBadRequest)

	}
	var empty models.MasternodeClient
	var idNode int64

	for {
		freeMN := database.ReadStructEmpty[models.MasternodeClient]("SELECT * FROM mn_clients WHERE coin_id = ? AND locked = 0 AND active = 0 LIMIT 1", mnInfoReq.IdCoin)
		if freeMN == empty {
			return utils.ReportError(c, "No free MNs left for this coin", fiber.StatusConflict)
		} else {
			//token, _ := database.ReadValue[string]("SELECT token FROM mn_server WHERE url = ?", freeMN.NodeIP)
			utils.ReportMessage(fmt.Sprintf("NODE FREE: %d", freeMN.ID))
			creds, err := grpcModels.LoadTLSCredentials()
			if err != nil {
				utils.WrapErrorLog("cannot load TLS credentials: " + err.Error())
				return utils.ReportError(c, "cannot load TLS credentials: "+err.Error(), fiber.StatusInternalServerError)
			}
			grpcCon, err := gpc.Dial(fmt.Sprintf("%s:6810", freeMN.NodeIP), gpc.WithTransportCredentials(creds))
			if err != nil {
				utils.WrapErrorLog(err.Error())
				return utils.ReportError(c, err.Error(), fiber.StatusInternalServerError)
			}
			tx := &grpcModels.CheckMasternodeRequest{NodeID: uint32(freeMN.ID)}
			cc := grpcModels.NewRegisterMasternodeServiceClient(grpcCon)
			resp, err := cc.CheckMasternode(context.Background(), tx)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				return utils.ReportError(c, err.Error(), fiber.StatusInternalServerError)
			}

			if resp.Code != 200 {
				utils.ReportMessage(fmt.Sprintf("Somethings wrong on node %s", freeMN.NodeIP))

				_, _ = database.InsertSQl("UPDATE mn_clients SET locked = 1 WHERE id = ? ", freeMN.ID)
				//sendWarningMessage(68857, "Error Node", fmt.Sprintf("Error Node %d", freeMN.ID)) //TODO: Send message to admin
				continue
			}
			utils.ReportMessage(fmt.Sprintf("NODE OK: %d", freeMN.ID))
			_, errUpdate := database.InsertSQl("UPDATE mn_clients SET locked = 1 WHERE id = ? ", freeMN.ID)
			if errUpdate != nil {
				utils.WrapErrorLog(errUpdate.Error())
			}
			_ = grpcCon.Close()
			idNode = int64(freeMN.ID)
			break
		}
	}

	freeMasternodesQuery := "SELECT id, address FROM mn_clients WHERE id=?"
	type listMN struct {
		ID   int    `db:"id" json:"id"`
		Addr string `db:"address" json:"address"`
	}

	readStruct, err := database.ReadStruct[listMN](freeMasternodesQuery, idNode)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusInternalServerError)

	}

	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"node":       readStruct,
	})
}

func getGithubRelease(c *fiber.Ctx) error {
	formValue := c.FormValue("os", "win64")
	resp, err := http.Get("https://api.github.com/repos/DigitalNoteXDN/DigitalNote-2/releases/latest")
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
			utils.ERROR:  true,
			utils.STATUS: utils.ERROR,
		})
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
			utils.ERROR:  true,
			utils.STATUS: utils.ERROR,
		})
	}
	var result models.GitHubAssets
	err = json.Unmarshal(body, &result)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
			utils.ERROR:  true,
			utils.STATUS: utils.ERROR,
		})
	}
	for _, asset := range result.Assets {
		if strings.Contains(asset.Name, formValue) {
			//utils.ReportMessage(asset.BrowserDownloadURL)
			//utils.ReportMessage(asset.Name)
			return c.Redirect(asset.BrowserDownloadURL, fiber.StatusSeeOther)
		}
	}
	return c.Status(fiber.StatusNotFound).JSON(&fiber.Map{
		utils.ERROR:  true,
		utils.STATUS: utils.ERROR,
	})

}

func getMNInfo(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	avgPay, err := database.ReadValue[string]("SELECT SEC_TO_TIME(AVG(av)) as average FROM (SELECT TIMESTAMPDIFF(second, MIN(datetime), MAX(datetime)) / NULLIF(COUNT(*) - 1, 0) as av FROM payouts_masternode WHERE idCoin=? GROUP BY idNode) as b", 0)

	returnListArr, err := database.ReadArrayStruct[models.ListMN]("SELECT id, ip FROM mn_clients WHERE active = 0 AND coin_id = ? AND locked = 0", 0)

	returnArr, err := database.ReadArrayStruct[models.MNListInfo]("SELECT b.id, b.ip, a.dateStart, b.last_seen, b.active_time, a.custodial, b.address FROM users_mn as a, mn_clients as b WHERE a.idUser = ? AND a.idCoin = ? AND a.active = 1 AND a.idNode = b.id", userID, 0)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
			utils.ERROR:  true,
			utils.STATUS: utils.ERROR,
		})
	}
	//returnFinalArry := make([]listFinalMN, 0)
	//var wg sync.WaitGroup
	//wg.Add(len(returnArr))
	//for i := 0; i < len(returnArr); i++ {
	//	go func(i int) {
	//		id := returnArr[i].ID
	//		maxSession, _ := database.ReadValue[int]("SELECT MAX(session) FROM users_mn WHERE idNode = ?", id)
	//		sqlAveragePayrate := `SELECT IFNULL(SEC_TO_TIME(AVG(av)), 0) as average FROM (SELECT IFNULL(TIMESTAMPDIFF(second, MIN(datetime), MAX(datetime)) / NULLIF(COUNT(*) - 1, 0), 0) as av	FROM payouts_masternode WHERE idNode=? AND session=? GROUP BY idNode) as b`
	//		avp, _ := database.ReadValue[string](sqlAveragePayrate, id, maxSession)
	//		returnArr[i].AddAverage(avp)
	//		wg.Done()
	//	}(i)
	//}
	//go func() {
	//	wg.Wait()
	//}()

	var wg sync.WaitGroup
	wg.Add(len(returnArr))
	results := make(chan string, len(returnArr))
	for i := 0; i < len(returnArr); i++ {
		go func(i int) {
			id := returnArr[i].ID
			maxSession, _ := database.ReadValue[int]("SELECT MAX(session) FROM users_mn WHERE idNode = ?", id)
			sqlAveragePayrate := `SELECT IFNULL(SEC_TO_TIME(AVG(av)), 0) as average FROM (SELECT IFNULL(TIMESTAMPDIFF(second, MIN(datetime), MAX(datetime)) / NULLIF(COUNT(*) - 1, 0), 0) as av	FROM payouts_masternode WHERE idNode=? AND session=? GROUP BY idNode) as b`
			avp, _ := database.ReadValue[string](sqlAveragePayrate, id, maxSession)
			results <- avp
			wg.Done()
		}(i)
	}

	go func() {
		wg.Wait()
		close(results)
	}()
	i := 0
	for avp := range results {
		returnArr[i].AddAverage(avp)
		i++
	}

	returnArrr, err := database.ReadArrayStruct[models.MNList]("SELECT idNode, amount as amount, lastRewardDate, ip, address  FROM (SELECT a.idNode, SUM(a.amount) as amount, max(datetime) as lastRewardDate,  b.ip, b.address FROM payouts_masternode as a, mn_clients as b WHERE a.idCoin = ? AND a.idUser = ? AND a.idNode = b.id AND a.credited = 0  AND a.datetime < (NOW() - INTERVAL 5 MINUTE) GROUP BY a.idNode) as t1", 0, userID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
			utils.ERROR:  true,
			utils.STATUS: utils.ERROR,
		})
	}
	averageTimeToStart := ""
	for _, element := range daemons.GetMNStatistic() {
		if len(element[0]) != 0 {
			averageTimeToStart = element[0]
		}
	}

	pendingMNList, _ := database.ReadArrayStruct[models.PendingMN]("SELECT idNode FROM mn_incoming_tx WHERE idUser = ? AND idCoin = ? AND processed = 0", userID, 0)
	mnInfo, err := database.ReadValue[int]("SELECT collateral FROM mn_info WHERE idCoin = ?", 0)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	collateralAmount, _ := database.ReadArray[models.Collateral]("SELECT collateral FROM mn_info WHERE idCoin = ?", 0)
	numberOfNodes, _ := database.ReadValue[int]("SELECT COUNT(id) FROM mn_clients WHERE active = 1 AND coin_id = ?", 0)
	perWeek, _ := database.ReadValue[float32]("SELECT AVG(amount) as amount FROM (SELECT idNode, sum(amount) AS amount FROM payouts_masternode WHERE idCoin = ? AND datetime BETWEEN DATE_SUB(CURDATE(),INTERVAL 7 DAY) AND CURDATE() group by idNode)as t", 0)
	userNodeCount, _ := database.ReadValue[int64]("SELECT IFNULL(COUNT(id), 0) FROM users_mn WHERE idUser = ? AND idCoin = ? AND active = 1", userID, 0)
	averageReward := (perWeek / 7) * float32(userNodeCount)
	avgRewad := database.ReadValueEmpty[float32]("SELECT AVG(t1.count) as avg FROM (SELECT idNode, count(id) as count FROM masternode_tx WHERE amount > 0 AND date_created BETWEEN DATE_SUB(CURDATE(),INTERVAL 7 DAY) AND CURDATE() GROUP BY idNode) as t1")
	avgRewardCountDay := (avgRewad / 7) * float32(userNodeCount)
	rewardPerDay, _ := database.ReadValue[float64](`SELECT AVG(amount) FROM
														(SELECT DATE_FORMAT(datetime, '%Y-%m-%d') as theday, SUM(amount) as amount FROM payouts_masternode WHERE idCoin = ? GROUP BY idNode, DATE_FORMAT(datetime, '%Y-%m-%d')) as t1
														WHERE theday >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 7 DAY), '%Y-%m-%d')`, 0)
	roi := ((rewardPerDay * 365.2) / float64(mnInfo)) * 100
	colArr := make([]int64, 0)
	for _, element := range collateralAmount {
		colArr = append(colArr, element.Amount)
	}
	autoStake := database.ReadValueEmpty[bool]("SELECT autoStake FROM users_mn WHERE idUser = ? AND active = 1 LIMIT 1", userID)
	wg.Wait()

	resp := models.MNInfoResponse{
		Status:              utils.OK,
		Error:               false,
		ActiveNodes:         numberOfNodes,
		AveragePayTime:      avgPay,
		AverageRewardPerDay: averageReward,
		AverageTimeToStart:  averageTimeToStart,
		AveragePayForDay:    float32(rewardPerDay),
		ROI:                 float32(roi),
		FreeList:            returnListArr,
		MnList:              returnArr,
		PendingList:         pendingMNList,
		Collateral:          int64(mnInfo),
		CollateralTiers:     colArr,
		NodeRewards:         returnArrr,
		AutoStake:           autoStake,
		CountRewardDay:      avgRewardCountDay,
	}
	return c.Status(fiber.StatusOK).JSON(&resp)
}

func getBlockchain(c *fiber.Ctx) error {
	c.Response().Header.Add("Cache-Time", "30")
	return c.Status(fiber.StatusOK).SendFile("./blk.zip", true)
}

func getPicture(c *fiber.Ctx) error {
	formValue := c.FormValue("file", "nft.png")
	return c.Status(fiber.StatusOK).SendFile("./Files/" + formValue + ".png")
}

func getFile(c *fiber.Ctx) error {
	picture := []string{"thunder.png", "thunder2.jpg"}
	pic := picture[utils.RandNum(len(picture))]
	return c.Status(fiber.StatusOK).SendFile("./Files/" + pic)
}

func getPictureBots(c *fiber.Ctx) error {
	//get form data
	bot.LoadPictures()
	formValue := c.FormValue("file", "1")
	formValueType := c.FormValue("type", "1")
	//convert to int
	file, err := strconv.Atoi(formValue)
	tp, err := strconv.Atoi(formValueType)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(&fiber.Map{
			utils.ERROR:  true,
			utils.STATUS: utils.ERROR,
		})
	}

	if tp == 1 {
		if file > len(bot.PictureThunder) {
			file = len(bot.PictureThunder) - 1
		}
		pic := bot.PictureThunder[file]
		return c.Status(fiber.StatusOK).SendFile("./" + pic)
	} else if tp == 2 {
		if file > len(bot.PictureNFT) {
			file = len(bot.PictureNFT) - 1
		}
		pic := bot.PictureNFT[file]
		return c.Status(fiber.StatusOK).SendFile("./" + pic)
	} else if tp == 3 {
		if file > len(bot.PictureANN) {
			file = len(bot.PictureANN) - 1
		}
		pic := bot.PictureANN[file]
		return c.Status(fiber.StatusOK).SendFile("./" + pic)
	} else {
		if file > len(bot.PictureRain) {
			file = len(bot.PictureRain) - 1
		}
		pic := bot.PictureRain[file]
		return c.Status(fiber.StatusOK).SendFile("./" + pic)
	}
}

func getBotConnect(c *fiber.Ctx) error {
	userID, err := strconv.Atoi(c.Get("User_id"))
	if err != nil {
		return utils.ReportError(c, "User not found", fiber.StatusBadRequest)
	}

	time.Sleep(time.Millisecond * 10)
	bot.RegenerateTokenSocial(int64(userID))
	token := database.ReadValueEmpty[sql.NullString]("SELECT tokenSocials FROM users WHERE id = ?", userID)
	if !token.Valid || token.String == "" {
		return utils.ReportError(c, "Token not found", fiber.StatusBadRequest)
	}
	var response struct {
		TelegramUserName string `json:"telegram,omitempty"`
		DiscordUserName  string `json:"discord,omitempty"`
		Token            string `json:"token"`
	}
	tl := database.ReadValueEmpty[sql.NullString]("SELECT idSocial FROM users_bot WHERE idUser = ? AND typeBot = ?", userID, 1)
	if tl.Valid {
		response.TelegramUserName = tl.String
	}

	ds := database.ReadValueEmpty[sql.NullString]("SELECT dName FROM users_bot WHERE idUser = ? AND typeBot = ?", userID, 2)
	if ds.Valid {
		response.DiscordUserName = ds.String
	}
	response.Token = token.String

	payload, err := json.Marshal(response)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusInternalServerError)
	}
	return c.Status(fiber.StatusOK).Send(payload)

}

func unlinkBot(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	var request struct {
		Type int `json:"typeBot"`
	}
	err := c.BodyParser(&request)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}
	if userID == "" {
		return utils.ReportError(c, "User not found", fiber.StatusBadRequest)
	}
	_, err = database.InsertSQl("DELETE FROM users_bot WHERE idUser = ? and typeBot = ?", userID, request.Type)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusInternalServerError)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func deleteUser(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	user, err := database.ReadStruct[models.User]("SELECT * FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}
	_, _ = database.InsertSQl("DELETE FROM users_stake WHERE idUser = ?", userID)
	_, _ = database.InsertSQl("DELETE FROM devices WHERE idUser = ?", userID)
	_, _ = database.InsertSQl("DELETE FROM transaction WHERE account = ?", user.Username)
	_, _ = database.InsertSQl("DELETE FROM payouts_stake WHERE idUser = ?", userID)
	_, _ = database.InsertSQl("UPDATE addressbook SET name = ? WHERE addr = ?", "Deleted User", user.Addr)
	_, _ = database.InsertSQl("DELETE FROM users WHERE id = ?", userID)
	return c.JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})

}

func renameUser(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	var Req struct {
		NewName string `json:"name"`
	}
	err := c.BodyParser(&Req)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}
	if len(Req.NewName) < 3 {
		return utils.ReportError(c, "Name is too short", fiber.StatusBadRequest)
	}
	if len(Req.NewName) > 45 {
		return utils.ReportError(c, "Name is too long", fiber.StatusBadRequest)
	}
	_, _ = database.InsertSQl("UPDATE users SET nickname = ? WHERE id = ?", Req.NewName, userID)
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func getPrivKey(c *fiber.Ctx) error {
	userID := c.Get("User_id")

	addr, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}

	_, err = coind.WrapDaemon(utils.DaemonWallet, 2, "walletpassphrase", utils.DaemonWallet.PassPhrase.String, 100)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	time.Sleep(time.Millisecond * 100)
	pKey, err := coind.WrapDaemon(utils.DaemonWallet, 2, "dumpprivkey", addr)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	privKey := strings.Trim(string(pKey), "\"")
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"privkey":    privKey,
	})
}

func updateAddressBook(c *fiber.Ctx) error {
	var Req struct {
		IDContact int    `json:"id"`
		Name      string `json:"name"`
	}

	err := c.BodyParser(&Req)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}
	_, _ = database.InsertSQl("UPDATE addressbook SET name = ? WHERE id = ?", Req.Name, Req.IDContact)

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func readMessages(c *fiber.Ctx) error {
	var Req struct {
		Address      string `json:"addr"`
		UsersAddress string `json:"addrUsr"`
	}

	err := c.BodyParser(&Req)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}

	_, _ = database.InsertSQl("UPDATE messages SET messages.unread = 1 WHERE (receiveAddr = ? AND sentAddr = ? ) OR (receiveAddr = ? AND sentAddr = ?)", Req.Address, Req.UsersAddress, Req.UsersAddress, Req.Address)
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func firebaseToken(c *fiber.Ctx) error {
	userID := c.Get("User_id")

	var Req struct {
		Token    string `json:"token"`
		Platform string `json:"platform"`
	}

	err := c.BodyParser(&Req)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}

	exist := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM devices WHERE token = ?", Req.Token)
	if !exist.Valid {
		_, err := database.InsertSQl("INSERT INTO devices(idUser, token, device_type) VALUES (?, ?, ?)", userID, Req.Token, Req.Platform)
		if err != nil {
			return utils.ReportError(c, err.Error(), fiber.StatusInternalServerError)
		}
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func twoFactorRemove(c *fiber.Ctx) error {
	userID := c.Get("User_id")

	var Req struct {
		Token string `json:"token"`
	}

	err := c.BodyParser(&Req)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}

	twoKey, err := database.ReadValue[string]("SELECT twoKey FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusInternalServerError)
	}

	twoRes := totp.Validate(Req.Token, twoKey)
	if !twoRes {
		return utils.ReportError(c, "Invalid token", fiber.StatusConflict)
	}
	_, _ = database.InsertSQl("UPDATE users SET twoActive = 0 WHERE id = ?", userID)
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})

}

func sendMessage(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if len(userID) == 0 {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type dataReq struct {
		AddrTo  string `json:"addr"`
		Text    string `json:"text"`
		IDReply int    `json:"idReply"`
	}
	var data dataReq
	err := c.BodyParser(&data)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	addrFrom, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	_, err = database.InsertSQl("INSERT INTO messages (sentAddr, receiveAddr, text, direction, idReply) VALUES (?, ?, ?, ?, ?)", addrFrom, data.AddrTo, data.Text, "out", data.IDReply)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	go func(data dataReq, usedID string) {
		d := map[string]string{
			"func": "sendMessage",
			"fr":   addrFrom,
		}
		userTo := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users WHERE addr = ?", data.AddrTo)
		if userTo.Valid {
			nameFrom, err := database.ReadValue[sql.NullString]("SELECT name FROM addressbook WHERE idUser = ? AND addr = ?", userTo.Int64, addrFrom)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
			userTo := database.ReadValueEmpty[int64]("SELECT id FROM users WHERE addr = ?", data.AddrTo)
			type Token struct {
				Token string `json:"token"`
			}
			tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", userTo)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
			if nameFrom.Valid {
				if len(tk) > 0 {
					for _, v := range tk {
						utils.SendMessage(v.Token, fmt.Sprintf("Message from %s", nameFrom.String), data.Text, d)
					}
				}
			} else {
				if len(tk) > 0 {
					for _, v := range tk {
						utils.SendMessage(v.Token, fmt.Sprintf("Incoming message from %s", addrFrom), data.Text, d)
					}
				}
			}
		}
	}(data, userID)
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func getMessagesLikes(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if len(userID) == 0 {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}

	var req struct {
		MessageID int    `json:"id"`
		Addr      string `json:"addr"`
	}
	if err := c.BodyParser(&req); err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	exist := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM messages WHERE id = ? AND receiveAddr = ?", req.MessageID, req.Addr)
	//if err != nil {
	//	return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	//}
	if exist.Valid {
		m, err := database.ReadValue[int64]("SELECT likeSent as lk FROM messages WHERE id = ?", req.MessageID)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
		if m == 1 {
			_, _ = database.InsertSQl("UPDATE messages SET likeSent = 0 WHERE id = ?", req.MessageID)
		} else {
			_, _ = database.InsertSQl("UPDATE messages SET likeSent = 1 WHERE id = ?", req.MessageID)
		}
	} else {
		m, err := database.ReadValue[int64]("SELECT likeReceive as lk FROM messages WHERE id = ?", req.MessageID)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
		if m == 1 {
			_, _ = database.InsertSQl("UPDATE messages SET likeReceive = 0 WHERE id = ?", req.MessageID)
		} else {
			_, _ = database.InsertSQl("UPDATE messages SET likeReceive = 1 WHERE id = ?", req.MessageID)
		}
	}

	lk, err := database.ReadValue[int64]("SELECT (SUM(likeSent) + SUM(likeReceive)) as likes FROM messages WHERE id = ?", req.MessageID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"likes":      lk,
	})
}

func getMessages(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if len(userID) == 0 {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	var data struct {
		SendAddress string `json:"addr"`
		LastSync    string `json:"last_sync"`
	}
	err := c.BodyParser(&data)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	addrReceive, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	type Message struct {
		ID          int64     `json:"id" db:"id"`
		IdReply     int64     `json:"idReply" db:"idReply"`
		Likes       int64     `json:"likes" db:"likes"`
		LastChange  time.Time `json:"lastChange" db:"lastChange"`
		SentAddr    string    `json:"sentAddr" db:"sentAddr"`
		ReceiveAddr string    `json:"receiveAddr" db:"receiveAddr"`
		Unread      int       `json:"unread" db:"unread"`
		LastMessage string    `json:"lastMessage" db:"lastMessage"`
		Text        string    `json:"text" db:"text"`
	}
	messages, err := database.ReadArrayStruct[Message]("SELECT  id, idReply, likes, lastChange, sentAddr, receiveAddr, unread, lastMessage, text FROM (SELECT id, idReply, (SUM(likeSent) + SUM(likeReceive)) as likes, lastChange, sentAddr, receiveAddr, unread, receiveTime as lastMessage, text FROM messages WHERE receiveAddr = ? AND sentAddr = ? OR receiveAddr = ? AND sentAddr = ? GROUP BY id ORDER BY id) as a WHERE lastChange > ?", addrReceive, data.SendAddress, data.SendAddress, addrReceive, data.LastSync)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}

	type result = struct {
		ID          int64  `json:"id" db:"id"`
		IdReply     int64  `json:"idReply" db:"idReply"`
		Likes       int64  `json:"likes" db:"likes"`
		LastChange  int64  `json:"lastChange" db:"lastChange"`
		SentAddr    string `json:"sentAddr" db:"sentAddr"`
		ReceiveAddr string `json:"receiveAddr" db:"receiveAddr"`
		Unread      int    `json:"unread" db:"unread"`
		LastMessage string `json:"lastMessage" db:"lastMessage"`
		Text        string `json:"text" db:"text"`
	}

	res := make([]result, 0)
	for _, message := range messages {
		res = append(res, result{
			ID:          message.ID,
			IdReply:     message.IdReply,
			Likes:       message.Likes,
			LastChange:  message.LastChange.Unix(),
			SentAddr:    message.SentAddr,
			ReceiveAddr: message.ReceiveAddr,
			Unread:      message.Unread,
			LastMessage: message.LastMessage,
			Text:        message.Text,
		})
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"data":       res,
	})
}

func getMessageGroup(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if len(userID) == 0 {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	addr, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}

	type MessageGroup struct {
		ReceiveAddr string    `json:"receiveAddr" db:"receiveAddr"`
		SentAddr    string    `json:"sentAddr" db:"sentAddr"`
		Unread      int       `json:"unread" db:"unread"`
		LastMessage time.Time `json:"lastMessage" db:"lastMessage"`
		Text        string    `json:"text" db:"text"`
	}

	arrayStruct, err := database.ReadArrayStruct[MessageGroup](`SELECT finally.user as receiveAddr, finally.otherParticipant as sentAddr, finally.unread as unread, finally.lastMessage as lastMessage, finally.text as text FROM (SELECT myMessages.user, myMessages.otherParticipant, groupList.unread, groupList.lastMessage, myMessages.text FROM (SELECT  IF(sentAddr = ?, sentAddr, receiveAddr) as user, IF(receiveAddr = ?, sentAddr, receiveAddr) as otherParticipant, receiveTime,  messages.text,  messages.unread FROM  messages) myMessages INNER JOIN (SELECT otherParticipant, COUNT(IF(myMessages2.unread = 0, 1, NULL)) as unread, max(receiveTime) as lastMessage FROM (SELECT IF(receiveAddr = ?, sentAddr, receiveAddr) as otherParticipant, receiveTime,  messages.unread FROM  messages  WHERE sentAddr = ? or receiveAddr = ?) as myMessages2 GROUP BY otherParticipant) groupList ON myMessages.otherParticipant = groupList.otherParticipant AND myMessages.receiveTime = groupList.lastMessage) as finally`, addr, addr, addr, addr, addr)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}

	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"data":       arrayStruct,
	})
}

func twofactorCheck(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if len(userID) == 0 {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	two, err := database.ReadValue[bool]("SELECT twoActive FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"twoFactor":  two,
	})
}

func getTxXLS(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if len(userID) == 0 {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	usr, err := database.ReadValue[string]("SELECT username FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	readSql, err := database.ReadSql("SELECT txid, amount, confirmation, category, date FROM transaction WHERE account = ? ORDER BY id DESC", usr)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	err = utils.GenerateXLSXFromRows(readSql, usr+".xlsx")
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	open, err := os.Open("./" + usr + ".xlsx")
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	// Read entire file into byte slice.
	reader := bufio.NewReader(open)
	content, _ := io.ReadAll(reader)

	// Encode as base64.
	encoded := base64.StdEncoding.EncodeToString(content)

	// Remove file
	_ = os.Remove("./" + usr + ".xlsx")
	return c.JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"data":       encoded,
	})
}

func sendContactTransaction(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if len(userID) == 0 {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type dataReq struct {
		Address string  `json:"address"`
		Amount  float64 `json:"amount"`
		Contact string  `json:"contact"`
	}
	var data dataReq
	if err := c.BodyParser(&data); err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}

	if data.Address == "" || data.Amount == 0 || data.Contact == "" {
		return utils.ReportError(c, "All fields has to be populated", fiber.StatusBadRequest)
	}

	exist, err := database.ReadValue[int]("SELECT COUNT(id) FROM requests WHERE idUser = ? AND main = ? AND processed = 0", userID, 1)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if exist > 0 {
		return utils.ReportError(c, "You have an active request", http.StatusBadRequest)
	}
	defer unrequestMain(userID)

	addrSend, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)

	tx, err := coind.SendCoins(data.Address, addrSend, data.Amount, false)
	if err != nil {
		return utils.ReportError(c, "Wallet problem, try again later", fiber.StatusConflict)
	}
	_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", data.Contact, tx, "send")

	go func(data dataReq, addrSend string) {
		d := map[string]string{
			"fn": "sendTransaction",
		}
		userTo := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users WHERE addr = ?", data.Address)
		if userTo.Valid {
			nameFrom, err := database.ReadValue[sql.NullString]("SELECT name FROM addressbook WHERE idUser = ? AND addr = ?", userTo.Int64, addrSend)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
			userTo := database.ReadValueEmpty[int64]("SELECT id FROM users WHERE addr = ?", data.Address)
			type Token struct {
				Token string `json:"token"`
			}
			tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", userTo)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
			if nameFrom.Valid {
				if len(tk) > 0 {
					for _, v := range tk {
						utils.SendMessage(v.Token, fmt.Sprintf("Transaction from %s", nameFrom.String), fmt.Sprintf("%3f XDN", data.Amount), d)
					}
				}
			} else {
				if len(tk) > 0 {
					for _, v := range tk {
						utils.SendMessage(v.Token, fmt.Sprintf("Incoming transaction from %s", addrSend), fmt.Sprintf("%3f XDN", data.Amount), d)
					}
				}
			}
		}
	}(data, addrSend)
	return c.JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func unrequestMain(id string) {
	_, err := database.InsertSQl("UPDATE requests SET processed = 1 WHERE idUser = ? AND main = 1 AND processed = 0 AND id<> 0 LIMIT 1", id)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
}

func sendTransaction(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if len(userID) == 0 {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type dataReq struct {
		Address string  `json:"address"`
		Amount  float64 `json:"amount"`
	}
	var data dataReq
	if err := c.BodyParser(&data); err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}

	if data.Address == "" || data.Amount == 0 {
		return utils.ReportError(c, "All fields has to be populated", fiber.StatusBadRequest)
	}

	exist, err := database.ReadValue[int]("SELECT COUNT(id) FROM requests WHERE idUser = ? AND main = ? AND processed = 0", userID, 1)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if exist > 0 {
		return utils.ReportError(c, "You have an active request", http.StatusBadRequest)
	}
	defer unrequestMain(userID)

	addrSend, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)

	_, err = coind.SendCoins(data.Address, addrSend, data.Amount, false)
	if err != nil {
		return utils.ReportError(c, "Wallet problem, try again later", fiber.StatusConflict)
	}
	go func(data dataReq, addrSend string) {
		d := map[string]string{
			"fn": "sendTransaction",
		}
		userTo := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users WHERE addr = ?", data.Address)
		if userTo.Valid {
			nameFrom, err := database.ReadValue[sql.NullString]("SELECT name FROM addressbook WHERE idUser = ? AND addr = ?", userTo.Int64, addrSend)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
			userTo := database.ReadValueEmpty[int64]("SELECT id FROM users WHERE addr = ?", data.Address)
			type Token struct {
				Token string `json:"token"`
			}
			tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", userTo)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
			if nameFrom.Valid {
				if len(tk) > 0 {
					for _, v := range tk {
						utils.SendMessage(v.Token, fmt.Sprintf("Transaction from %s", nameFrom.String), fmt.Sprintf("%.3f XDN", data.Amount), d)
					}
				}
			} else {
				if len(tk) > 0 {
					for _, v := range tk {
						utils.SendMessage(v.Token, fmt.Sprintf("Incoming transaction from %s", addrSend), fmt.Sprintf("%3f XDN", data.Amount), d)
					}
				}
			}
		}
	}(data, addrSend)
	return c.JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func deleteFromAddressBook(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if len(userID) == 0 {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type req struct {
		Address string `json:"address"`
		Name    string `json:"name"`
	}
	var r req
	err := c.BodyParser(&r)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if len(r.Address) == 0 || len(r.Name) == 0 {
		return utils.ReportError(c, "Invalid data", http.StatusBadRequest)
	}
	_, _ = database.InsertSQl("DELETE FROM addressbook  WHERE idUser = ? AND name = ? AND addr = ?", userID, r.Name, r.Address)
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func getPriceData(c *fiber.Ctx) error {
	if daemons.PriceDat == nil {
		return utils.ReportError(c, "Price data not found", fiber.StatusNotFound)
	}
	return c.JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"data":       daemons.PriceDat,
	})
}

func changePassword(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if len(userID) == 0 {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	var req models.ChangePassword
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	hash := utils.HashPass(req.Pass)
	_, err = database.InsertSQl("UPDATE users SET password = ? WHERE id = ? ", hash, userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	return c.JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func forgotPassword(c *fiber.Ctx) error {
	var data models.ForgotPassword
	if err := c.BodyParser(&data); err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}
	utils.ReportMessage(data.Email)
	usr, err := database.ReadStruct[models.User]("SELECT * FROM users WHERE email = ?", data.Email)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}
	if usr.Id == 0 {
		return utils.ReportError(c, "User not found", fiber.StatusConflict)
	}
	passUser := utils.GenerateNewPassword(6)
	pass := utils.HashPass(passUser)
	_, _ = database.InsertSQl("UPDATE users SET password = ? WHERE id = ?", pass, usr.Id)

	m := gomail.NewMessage()
	m.SetHeader("From", "DigitalNote robot <no-reply@digitalnote.org>")
	m.SetHeader("To", usr.Email)
	m.SetHeader("Subject", "XDN Forgot Password")
	m.SetBody("text/html", html.GetEmail(passUser))

	d := gomail.NewDialer(utils.MailSettings.Host, 465, utils.MailSettings.Username, utils.MailSettings.Password)
	d.TLSConfig = &tls.Config{InsecureSkipVerify: true}

	if err := d.DialAndSend(m); err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusBadRequest)
	}
	utils.ReportMessage(fmt.Sprintf("Forgot email sent to user %s succes!", usr.Username))
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func twofactorVerify(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if len(userID) == 0 {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type Req struct {
		Code string `json:"code"`
	}
	var req Req
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}

	twoKey, err := database.ReadValue[string]("SELECT twoKey FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	utils.ReportMessage(fmt.Sprintf("Code: %s, twoKey: %s", req.Code, twoKey))
	good := totp.Validate(req.Code, twoKey)
	if !good {
		return utils.ReportError(c, "Invalid code", http.StatusForbidden)
	}
	_, _ = database.InsertSQl("UPDATE users SET twoActive = 1 WHERE id = ?", userID)
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func twofactor(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if len(userID) == 0 {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	check, err := database.ReadValue[bool]("SELECT twoActive FROM users WHERE id = ?", userID)
	name, err := database.ReadValue[string]("SELECT username FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	if check {
		return utils.ReportError(c, "Two factor already activated", http.StatusConflict)
	}
	code, err := totp.Generate(totp.GenerateOpts{
		Issuer:      "XDN APP",
		AccountName: name,
	})
	if err != nil {
		return utils.ReportError(c, "Code cannot be generated", http.StatusInternalServerError)
	}
	_, _ = database.InsertSQl("UPDATE users SET twoKey = ? WHERE id = ?", code.Secret(), userID)
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"code":       code.Secret(),
	})
}

func getStatus(c *fiber.Ctx) error {
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"data":       daemons.GetDaemonStatus(),
	})
}

func registerAPI(c *fiber.Ctx) error {
	var req models.RegisterUserStruct
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if req.Username == "" || req.Password == "" || req.Email == "" || req.RealName == "" || req.Udid == "" {
		return utils.ReportError(c, "Missing register details", http.StatusNotFound)
	}
	userExists := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users WHERE username = ? OR email= ?", req.Username, req.Password)
	if userExists.Valid {
		return utils.ReportError(c, "User already exists", http.StatusConflict)
	}
	address, err := coind.WrapDaemon(utils.DaemonWallet, 2, "getnewaddress", req.Username)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	addr := strings.Trim(string(address), "\"")
	_, err = coind.WrapDaemon(utils.DaemonWallet, 2, "walletpassphrase", utils.DaemonWallet.PassPhrase.String, 100)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	time.Sleep(time.Millisecond * 100)
	pKey, err := coind.WrapDaemon(utils.DaemonWallet, 2, "dumpprivkey", addr)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	if len(pKey) == 0 {
		return utils.ReportError(c, "Cannot get private key", http.StatusInternalServerError)
	}
	privKey := strings.Trim(string(pKey), "\"")
	_, _ = coind.WrapDaemon(utils.DaemonWallet, 2, "walletlock")
	tokSoc := utils.GenerateSocialsToken(32)
	for true {
		exist := database.ReadValueEmpty[sql.NullString]("SELECT tokenSocials FROM users WHERE token = ?", tokSoc)
		if !exist.Valid {
			break
		} else {
			tokSoc = utils.GenerateSocialsToken(32)
		}
	}
	hash := utils.HashPass(req.Password)
	_, err = database.InsertSQl("INSERT INTO users(username, password, email, addr, nickname, realname, UDID, privkey, tokenSocials) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", req.Username, hash, req.Email, addr, req.Username, req.RealName, req.Udid, privKey, tokSoc)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	utils.ReportMessage(fmt.Sprintf("/// User %s registered ///", req.Username))
	return c.Status(fiber.StatusCreated).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
	})
}

func loginAPI(c *fiber.Ctx) error {
	var req models.UserLogin
	remoteIP := c.Get("CF-Connecting-IP")
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if req.Username == "" || req.Password == "" {
		return utils.ReportError(c, "Missing username or password", http.StatusNotFound)
	}
	password := utils.HashPass(req.Password)
	user, err := database.ReadStruct[models.User]("SELECT * FROM users WHERE username = ? OR email= ?", req.Username, req.Username)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	if user.Username == "" {
		return utils.ReportError(c, "User not found", http.StatusNotFound)
	}
	if user.Password != password {
		return utils.ReportError(c, "Wrong password", http.StatusNotFound)
	}
	if user.Banned == 1 {
		return utils.ReportError(c, "User banned", http.StatusConflict)
	}
	if remoteIP == "" {
		remoteIP = c.IP()
	}
	utils.ReportMessage(fmt.Sprintf("/// Refresh token user %s -> login OK ///", remoteIP))
	service.GetLocationData(remoteIP, int64(user.Id))
	if user.TwoActive == 1 && user.TwoKey.Valid {
		if len(req.TwoFactor) == 0 {
			return utils.ReportError(c, "Two factor is required", http.StatusConflict)
		}
		twoRes := totp.Validate(req.TwoFactor, user.TwoKey.String)
		if twoRes != true {
			return utils.ReportError(c, "Two factor is invalid", http.StatusConflict)
		}
	}
	token, errToken := utils.CreateKeyToken(uint64(user.Id))
	if errToken != nil {
		log.Printf("err: %v\n", errToken)
		return utils.ReportError(c, errToken.Error(), http.StatusInternalServerError)
	}
	tokenDepr, errToken := utils.CreateToken(uint64(user.Id))
	if errToken != nil {
		log.Printf("err: %v\n", errToken)
		return utils.ReportError(c, errToken.Error(), http.StatusInternalServerError)
	}

	refToken := utils.GenerateSecureToken(32)
	_, errInsertToken := database.InsertSQl("INSERT INTO refresh_token(idUser, refreshToken) VALUES(?, ?)", user.Id, refToken)
	if errInsertToken != nil {
		return utils.ReportError(c, errInsertToken.Error(), http.StatusInternalServerError)
	}
	utils.ReportMessage(fmt.Sprintf("/// User %s logged in ///", user.Username))
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":      false,
		utils.STATUS:    utils.OK,
		"userid":        user.Id,
		"username":      user.Username,
		"nickname":      user.Nickname,
		"addr":          user.Addr,
		"admin":         user.Admin,
		"jwt":           tokenDepr,
		"token":         token,
		"refresh_token": refToken,
	})
}

func loginQRTokenAPI(c *fiber.Ctx) error {
	var QR struct {
		Token string `json:"token"`
	}
	err := c.BodyParser(&QR)
	if err != nil {
		return utils.ReportErrorSilent(c, "QR code not found", fiber.StatusBadRequest)
	}
	if QR.Token == "" {
		return utils.ReportErrorSilent(c, "QR code not found", fiber.StatusBadRequest)
	}
	tok := strings.Split(QR.Token, ";")
	idUser := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM qr_login WHERE token = ?", tok[1])
	if idUser.Valid == false {
		return utils.ReportErrorSilent(c, "user not found", fiber.StatusConflict)
	}
	admin := 0
	ad := database.ReadValueEmpty[sql.NullInt64]("SELECT admin FROM users WHERE id = ?", idUser.Int64)
	if ad.Valid == true {
		admin = int(ad.Int64)
	}
	token, errToken := utils.CreateKeyToken(uint64(idUser.Int64))
	if errToken != nil {
		log.Printf("err: %v\n", errToken)
		return utils.ReportErrorSilent(c, errToken.Error(), http.StatusInternalServerError)
	}

	refToken := utils.GenerateSecureToken(32)
	_, errInsertToken := database.InsertSQl("INSERT INTO refresh_token(idUser, refreshToken) VALUES(?, ?)", idUser.Int64, refToken)
	if errInsertToken != nil {
		return utils.ReportErrorSilent(c, errInsertToken.Error(), http.StatusInternalServerError)
	}
	utils.ReportMessage(fmt.Sprintf("/// QR login user %d -> login OK ///", idUser.Int64))
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":      false,
		utils.STATUS:    utils.OK,
		"token":         token,
		"refresh_token": refToken,
		"admin":         admin,
	})
}

func loginQRAuthAPI(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	if userID == "" {
		return utils.ReportError(c, "User not found", fiber.StatusBadRequest)
	}
	var QR struct {
		Token string `json:"token"`
	}
	err := c.BodyParser(&QR)
	if err != nil {
		return utils.ReportError(c, "QR code not found", fiber.StatusBadRequest)
	}
	if QR.Token == "" {
		return utils.ReportError(c, "QR code not found", fiber.StatusBadRequest)
	}
	_, err = database.InsertSQl("UPDATE qr_login SET idUser = ?, auth = 1 WHERE token = ?", userID, QR.Token)
	if err != nil {
		return utils.ReportError(c, "QR code not found", fiber.StatusBadRequest)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})
}

func loginQRAPI(c *fiber.Ctx) error {
	ip := c.Get("CF-Connecting-IP")
	tk := utils.GenerateSocialsToken(8)
	token := fmt.Sprintf("%s-%s", tk, utils.GenerateSecureToken(8))

	_, err := database.InsertSQl("INSERT INTO `qr_login` (`token`,`ip` ) VALUES (?, ?)", token, ip)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
			utils.ERROR:  true,
			utils.STATUS: utils.ERROR,
		})
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"token":      fmt.Sprintf("loginqr;%s", token),
	})
}

func refreshToken(c *fiber.Ctx) error {
	var userAuth models.RefreshToken
	remoteIP := c.Get("CF-Connecting-IP")
	errJson := c.BodyParser(&userAuth)
	if errJson != nil {
		return utils.ReportError(c, errJson.Error(), http.StatusBadRequest)
	}

	readSql, errSelect := database.ReadStruct[models.RefreshTokenStruct]("SELECT * FROM refresh_token WHERE refreshToken = ?", userAuth.Token)
	if errSelect != nil {
		return utils.ReportErrorSilent(c, "Invalid refresh token", http.StatusUnauthorized)
	}
	ban := database.ReadValueEmpty[bool]("SELECT banned FROM users WHERE id= ?", readSql.IdUser)
	if ban {
		return utils.ReportErrorSilent(c, "Banned user", http.StatusUnauthorized)
	}

	if len(readSql.RefToken) != 0 && readSql.Used == 0 {
		if remoteIP == "" {
			remoteIP = c.IP()
		}
		utils.ReportMessage(fmt.Sprintf("/// Refresh token user %s -> login OK ///", remoteIP))
		service.GetLocationData(remoteIP, readSql.IdUser)
		_, errUpdate := database.InsertSQl("UPDATE refresh_token SET used = 1 WHERE refreshToken = ?", userAuth.Token)
		if errUpdate != nil {
			return utils.ReportError(c, errUpdate.Error(), http.StatusInternalServerError)

		}
		token, errToken := utils.CreateKeyToken(uint64(readSql.IdUser))
		if errToken != nil {
			log.Printf("err: %v\n", errToken)
			return utils.ReportError(c, errToken.Error(), http.StatusInternalServerError)
		}

		rf := utils.GenerateSecureToken(32)
		_, errInsertToken := database.InsertSQl("INSERT INTO refresh_token(idUser, refreshToken) VALUES(?, ?)", readSql.IdUser, rf)
		if errInsertToken != nil {
			return utils.ReportError(c, errInsertToken.Error(), http.StatusInternalServerError)
		}

		_, errInsertToken = database.InsertSQl("DELETE FROM refresh_token WHERE used = 1")

		var dat models.DataRefreshToken
		dat.RefreshToken = rf
		dat.Token = token
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			"hasError":   false,
			utils.STATUS: utils.OK,
			"data":       dat,
		})

	} else {
		return utils.ReportErrorSilent(c, "Invalid refresh token", http.StatusUnauthorized)

	}
}

func getBalance(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	imm := 0.0
	bl := 0.0
	acc, _ := database.ReadValue[string]("SELECT username FROM users WHERE id = ?", userID)
	addr, _ := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	immature := database.ReadValueEmpty[sql.NullFloat64]("SELECT IFNULL(SUM(amount),0) as immature FROM transaction WHERE account = ? AND confirmation < 2 AND category = 'receive'", acc)
	bal := database.ReadValueEmpty[sql.NullFloat64](`SELECT SUM(amount) as amount FROM transaction WHERE account = ?`, acc)
	if immature.Valid {
		imm = immature.Float64
	}
	if imm < 0 {
		imm = 0
	}

	if bal.Valid {
		bl = bal.Float64
	}

	daemon := utils.GetDaemon()
	unspent, err := coind.WrapDaemon(*daemon, 5, "listunspent", 1, 9999999, []string{addr})
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	var ing []models.ListUnspent
	spendable := 0.0
	errJson := json.Unmarshal(unspent, &ing)
	if errJson != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	for _, v := range ing {
		if v.Spendable == true {
			spendable += v.Amount
		}
	}
	pending := bl - spendable
	if pending < 0 {
		pending = 0
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"balance":    fmt.Sprintf("%.2f", float32(pending)),
		"immature":   float32(imm),
		"spendable":  float32(spendable),
	})
}

func getStealthBalance(c *fiber.Ctx) error {
	var all []models.StealthBalance
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	addrAll, _ := database.ReadArrayStruct[models.Stealth]("SELECT * FROM stealth_addr WHERE idUser = ?", userID)
	//if err != nil {
	//	return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	//}
	if len(addrAll) == 0 {
		all = append(all, models.StealthBalance{
			Immature:  float32(0.0),
			Balance:   float32(0.0),
			Spendable: float32(0.0),
		})
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			utils.ERROR:  false,
			utils.STATUS: utils.OK,
			"balances":   all,
		})
	}

	for _, v := range addrAll {
		imm := 0.0
		bl := 0.0
		immature := database.ReadValueEmpty[sql.NullFloat64]("SELECT IFNULL(SUM(amount),0) as immature FROM transaction WHERE account = ? AND confirmation < 2 AND category = 'receive'", v.AddrName)
		bal := database.ReadValueEmpty[sql.NullFloat64](`SELECT SUM(amount) as amount FROM transaction WHERE account = ?`, v.AddrName)
		if immature.Valid {
			imm = immature.Float64
		}
		if bal.Valid {
			bl = bal.Float64
		}

		daemon := utils.GetDaemon()
		unspent, err := coind.WrapDaemon(*daemon, 5, "listunspent", 1, 9999999, []string{v.Addr})
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}

		var ing []models.ListUnspent
		spendable := 0.0
		errJson := json.Unmarshal(unspent, &ing)
		if errJson != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}

		for _, v := range ing {
			if v.Spendable == true {
				spendable += v.Amount
			}
		}
		pending := bl - spendable
		all = append(all, models.StealthBalance{
			Immature:  float32(pending),
			Balance:   float32(imm),
			Spendable: float32(spendable),
		})
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"balances":   all,
	})
}

func getTransactions(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	acc, _ := database.ReadValue[string]("SELECT username FROM users WHERE id = ?", userID)
	transactions, _ := database.ReadArrayStruct[models.Transaction]("SELECT * FROM transaction WHERE account = ?", acc)
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"data":       transactions,
	})
}

func checkContest(c *fiber.Ctx) error {

	contest, err := database.ReadStruct[models.Contest]("SELECT * FROM voting_contest WHERE finished = 0")
	if err != nil {
		return utils.ReportError(c, "No contest", http.StatusConflict)
	}
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	var empty models.Contest
	if contest == empty {
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			"hasError":   false,
			utils.STATUS: utils.OK,
			"message":    "No contest",
		})
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
	})
}

func addUserAddress(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type req struct {
		Address string `json:"address"`
	}
	var payload req
	if err := c.BodyParser(&payload); err != nil {
		return err
	}

	//validation of the fields
	if payload.Address == "" {
		return utils.ReportError(c, "Address is required", http.StatusBadRequest)
	}
	_, err := database.InsertSQl("INSERT INTO users_addr (idUser, addr) VALUES (?, ?)", userID, payload.Address)
	if err != nil {
		return utils.ReportErrorSilent(c, err.Error(), http.StatusInternalServerError)
	}
	utils.ReportMessage(fmt.Sprint("User ", userID, " added address ", payload.Address))

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
	})
}

func login(c *fiber.Ctx) error {
	payload := struct {
		Token string `json:"token"`
	}{}

	if err := c.BodyParser(&payload); err != nil {
		return err
	}
	resp, err := utils.POSTReq("http://localhost:3000/verify", map[string]string{"token": payload.Token})
	if err != nil {
		return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
	}
	if resp.StatusCode != http.StatusOK {
		return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
	}
	decGet := json.NewDecoder(resp.Body)
	decGet.DisallowUnknownFields()

	var userMe models.Auth
	errJson := decGet.Decode(&userMe)
	errorJson, errorMessage := errs.ValidateJson(errJson)
	if errorJson == true {
		return utils.ReportError(c, errorMessage, http.StatusBadRequest)

	}
	token, errToken := utils.CreateKeyToken(uint64(userMe.Id))
	if errToken != nil {
		log.Printf("err: %v\n", errToken)
		return utils.ReportError(c, errToken.Error(), http.StatusInternalServerError)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"token":      token,
	})
}

func getCurrentContest(c *fiber.Ctx) error {
	userID, err := strconv.Atoi(c.Get("User_id"))
	if err != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}

	contest, err := database.ReadStruct[models.Contest]("SELECT * FROM voting_contest WHERE finished = 0")
	if err != nil {
		return utils.ReportError(c, "No contest", http.StatusConflict)
	}
	if contest == (models.Contest{}) {
		return utils.ReportError(c, "No contest", http.StatusConflict)
	}

	contestEntries, err := database.ReadArrayStruct[models.ContestEntry](
		`SELECT id, name, IFNULL(amount, 0) as amount, IFNULL(userAmount, 0) as userAmount, d.addr as address, IFNULL(goal,0) as goal
	FROM (SELECT a.id, name, b.amount, c.amount as userAmount, d.addr, goal FROM voting_entries a
    LEFT JOIN  (SELECT idEntry, IFNULL(SUM(amount), 0) as amount FROM votes b GROUP BY idEntry) b ON a.id = b.idEntry
    LEFT JOIN (SELECT idEntry, IFNULL(SUM(amount), 0) as amount FROM votes c WHERE idUser = ? GROUP BY idEntry) c ON a.id = c.idEntry
    LEFT JOIN (SELECT id, addr FROM voting_addr) d ON a.idAddr = d.id
      WHERE a.idContest = ?) d;`, userID, contest.Id)
	if err != nil {
		return utils.ReportError(c, "No entries", http.StatusConflict)
	}
	sort.Slice(contestEntries, func(i, j int) bool {
		return contestEntries[i].Amount > contestEntries[j].Amount
	})
	res := &models.ContestResponse{
		Id:            contest.Id,
		Name:          contest.Name,
		AmountToReach: contest.AmountToReach,
		DateEnding:    contest.DateEnding,
		Entries:       contestEntries,
	}
	return c.Status(fiber.StatusOK).JSON(res)
}

func createContest(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type req struct {
		Name          string     `json:"name"`
		AmountToReach null.Float `json:"amountToReach"`
		DateEnding    null.Time  `json:"dateEnding"` //Format: 2020-09-10T00:00:00.000Z
		Entries       []string   `json:"entries"`
		Goals         []int      `json:"goals"`
	}
	var payload req
	if err := c.BodyParser(&payload); err != nil {
		return err
	}

	//check for already existing active contest
	activeContest := database.ReadValueEmpty[null.Int]("SELECT id FROM voting_contest WHERE finished = 0 LIMIT 1")

	if activeContest.Valid {
		return utils.ReportError(c, "There is already an active contest", http.StatusConflict)
	}
	type addr struct {
		ID      int    `db:"id"`
		Address string `db:"addr"`
	}
	//get voting addresses
	votingAddresses, errDB := database.ReadArrayStruct[addr]("SELECT * FROM voting_addr")
	if errDB != nil {
		return utils.ReportError(c, errDB.Error(), http.StatusInternalServerError)
	}
	addrCount := len(votingAddresses)

	//validation of the fields
	if payload.Name == "" {
		return utils.ReportError(c, "Contest name is required", http.StatusBadRequest)
	}
	if payload.AmountToReach.Valid && payload.DateEnding.Valid {
		return utils.ReportError(c, "AmountToReach and DateEnding cannot be used at the same time", http.StatusBadRequest)
	}
	if !payload.AmountToReach.Valid && !payload.DateEnding.Valid {
		return utils.ReportError(c, "AmountToReach or DateEnding required", http.StatusBadRequest)
	}
	if len(payload.Entries) == 0 {
		return utils.ReportError(c, "Contest Voting Entries required", http.StatusBadRequest)
	}
	if len(payload.Entries) > addrCount {
		return utils.ReportError(c, "Too many entries (not enough voting addresses)", http.StatusBadRequest)
	}
	if len(payload.Entries) != len(payload.Goals) {
		return utils.ReportError(c, "Goals and Entries should have the same length", http.StatusBadRequest)
	}

	//all good
	var contestID int64
	var err error

	if payload.AmountToReach.Valid {
		contestID, err = database.InsertSQl("INSERT INTO voting_contest (name, amountToReach, idCreator) VALUES (?, ?, ?)", payload.Name, payload.AmountToReach.Float64, userID)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
	}

	if payload.DateEnding.Valid {
		contestID, err = database.InsertSQl("INSERT INTO voting_contest (name, dateEnding, idCreator) VALUES (?, ?, ?)", payload.Name, payload.DateEnding.Time, userID)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
	}

	for i, entry := range payload.Entries {
		addrID := votingAddresses[i].ID
		_, err := database.InsertSQl("INSERT INTO voting_entries (idContest, name, idAddr, goal) VALUES (?, ?, ?, ?)", contestID, entry, addrID, payload.Goals[i])
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
	})
}

func castVote(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type req struct {
		IDEntry int     `json:"idEntry"`
		Amount  float64 `json:"amount"`
	}
	var payload req
	if err := c.BodyParser(&payload); err != nil {
		return err
	}

	//validation of the fields
	if payload.IDEntry == 0 {
		return utils.ReportError(c, "Entry ID is required", http.StatusBadRequest)
	}
	if payload.Amount == 0 {
		return utils.ReportError(c, "Amount is required", http.StatusBadRequest)
	}
	_, err := database.InsertSQl("INSERT INTO votes (idUser, idEntry, amount) VALUES (?, ?, ?)", userID, payload.IDEntry, payload.Amount)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	utils.ReportMessage(fmt.Sprint("===== User ", userID, " voted ", payload.Amount, " for entry ", payload.IDEntry, " ====="))

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
	})
}

func addAddress(c *fiber.Ctx) error {
	type req struct {
		Address string `json:"address"`
	}
	var payload req
	if err := c.BodyParser(&payload); err != nil {
		return err
	}

	//validation of the fields
	if len(payload.Address) == 0 {
		return utils.ReportError(c, "Address is required", http.StatusBadRequest)
	}
	if !utils.Erc20verify(payload.Address) {
		return utils.ReportError(c, "Invalid Address", http.StatusBadRequest)
	}

	_, err := database.InsertSQl("INSERT INTO voting_addr (addr) VALUES (?)", payload.Address)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
	})
}

func ping(c *fiber.Ctx) error {
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"message":    "pong",
	})
}

func setStake(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	type req struct {
		Amount float64 `json:"amount"`
	}
	var r req
	err := c.BodyParser(&r)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	errDB := apiWallet.CheckStakeBalance()
	if errDB != nil {
		return utils.ReportError(c, "Staking turned off temporarily", http.StatusConflict)
	}
	user, err := database.ReadStruct[models.StakeUsers]("SELECT * FROM users_stake WHERE idUser = ? AND active = ?", userID, 1)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	server, err := database.ReadValue[string]("SELECT addr FROM servers_stake WHERE id = 1")
	userAddr, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	balance := 0.0
	if user.Active != 0 {
		utils.ReportMessage("UPDATING STAKE")
		if user.Amount.Valid {
			balance = r.Amount + user.Amount.Float64
		} else {
			balance = r.Amount
		}
		tx, errWallet := coind.SendCoins(server, userAddr, r.Amount-0.01, false)
		if errWallet != nil {
			return utils.ReportError(c, errWallet.Error(), 400)
		}
		_, _ = database.InsertSQl("UPDATE users_stake SET amount = ? WHERE idUser = ? AND active = ?", balance, userID, 1)
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Staking", tx, "send")
		time.Sleep(time.Second * 1)
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			"hasError":   false,
			utils.STATUS: utils.OK,
		})
	} else {
		utils.ReportMessage("INSERTING STAKE")
		smax, err := database.ReadValue[float64]("SELECT IFNULL(MAX(session), 0) as smax FROM users_stake WHERE idUser = ?", userID)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
		tx, err := coind.SendCoins(server, userAddr, r.Amount-0.01, false)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusConflict)
		}
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Staking", tx, "send")
		if smax == 0 {
			_, _ = database.InsertSQl("INSERT INTO users_stake (idUser, amount, active, session) VALUES (?, ?, ?, ?)", userID, r.Amount, 1, 1)
		} else {
			_, _ = database.InsertSQl("INSERT INTO users_stake (idUser, amount, active, session) VALUES (?, ?, ?, ?)", userID, r.Amount, 1, smax+1)
		}
		time.Sleep(time.Second * 1)
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			"hasError":   false,
			utils.STATUS: utils.OK,
		})
	}
}

func unstake(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type req struct {
		Type   int     `json:"type"`
		Amount float64 `json:"amount"`
	}
	exist, err := database.ReadValue[int]("SELECT COUNT(id) FROM requests WHERE idUser = ? AND staking = ? AND processed = 0", userID, 1)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if exist > 0 {
		return utils.ReportError(c, "You have an active request", http.StatusBadRequest)
	}
	_, _ = database.InsertSQl("INSERT INTO requests (idUser, staking, masternode) VALUES (?, ?, ?)", userID, 1, 0)
	defer unrequestStaking(userID)
	errDB := apiWallet.CheckStakeBalance()
	if errDB != nil {
		return utils.ReportError(c, "Staking turned off temporarily", http.StatusConflict)
	}

	var r req
	err = c.BodyParser(&r)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	user, err := database.ReadStruct[models.StakeUsers]("SELECT * FROM users_stake WHERE idUser = ? AND active = ?", userID, 1)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	amountToSend := 0.0
	userStake, err := database.ReadValue[float64]("SELECT IFNULL(amount, 0) FROM users_stake WHERE idUser = ? AND active = ?", userID, 1)
	payouts, err := database.ReadValue[float64]("SELECT IFNULL(SUM(amount),0) FROM payouts_stake WHERE idUser = ? AND credited = 0 AND session = ?", userID, user.Session)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	if r.Type == 1 {
		amountToSend += payouts
	} else if r.Type == 2 {
		stakingAmount, _ := database.ReadValue[sql.NullFloat64]("SELECT amount FROM users_stake WHERE idUser = ? AND active = 1", userID)
		if stakingAmount.Valid {
			st := utils.ToFixed(stakingAmount.Float64, 8)
			if st > r.Amount {
				amountToSend = utils.ToFixed(r.Amount, 8)
			} else {
				return utils.ReportError(c, "Amount is bigger than user's staking amount", http.StatusConflict)

			}
		} else {
			return utils.ReportError(c, "Payout invalid", http.StatusForbidden)

		}
	} else if r.Type == 0 {
		dateChanged := user.DateStart.Time.UTC().UnixMilli()
		dateNow := time.Now().UnixMilli()
		dateDiff := dateNow - dateChanged
		if dateDiff > 86400000 {
			amountToSend += userStake
			amountToSend += payouts
		} else {
			return utils.ReportError(c, "You can only unstake after 24 hours", http.StatusConflict)
		}
	} else {
		return utils.ReportError(c, "Invalid type", http.StatusConflict)
	}
	utils.ReportMessage(fmt.Sprintf("Amount to send: %f, user to send %d", amountToSend, user.IdUser))
	//server, err := database.ReadValue[string]("SELECT addr FROM servers_stake WHERE id = 1")
	userAddr, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	if user.Active != 0 {

		if amountToSend < 0.1 {
			return utils.ReportError(c, "Amount is too small, withdraw at least 0.1 XDN", http.StatusConflict)
		}

		if r.Type == 1 {
			utils.ReportMessage("UNSTAKING")
			_, _ = database.InsertSQl("UPDATE payouts_stake SET credited = ? WHERE idUser = ? AND id <> 0", 1, userID)
			idd, _ := database.InsertSQl("INSERT with_req (idUser, amount, address) VALUES (?, ?, ?)", userID, amountToSend, userAddr)
			asdf, err := database.ReadValue[int](`	 SELECT count(auth)
														 FROM with_req
														 WHERE auth = 1 and idUser=?
														 GROUP BY idUser
														 HAVING MIN(send) = 1`, userID)
			if err != nil {
				go service.SendAdminsReq(idd)
				return utils.ReportError(c, "Your withdraw request is on review", http.StatusConflict)
			} else {
				if asdf > 15 {
					server, err := database.ReadValue[string]("SELECT addr FROM servers_stake WHERE id = 1")
					tx, err := coind.SendCoins(userAddr, server, amountToSend, true)
					if err != nil {
						return utils.ReportError(c, err.Error(), http.StatusConflict)
					}
					_, _ = database.InsertSQl("UPDATE with_req SET auth = 1, send = 1, idTx = ? WHERE id = ?", tx, idd)

				} else {
					go service.SendAdminsReq(idd)
					return utils.ReportError(c, "Your withdraw request is on review", http.StatusConflict)
				}
				return c.Status(fiber.StatusOK).JSON(fiber.Map{
					utils.ERROR:  false,
					utils.STATUS: utils.OK,
				})
			}

		} else if r.Type == 2 {
			return utils.ReportError(c, "Not implemented", http.StatusConflict)
		} else {
			utils.ReportMessage("UNSTAKING")
			_, _ = database.InsertSQl("UPDATE payouts_stake SET credited = ? WHERE idUser = ? AND id <> 0", 1, userID)
			_, _ = database.InsertSQl("UPDATE users_stake SET active = 0 WHERE idUser = ?", userID)
			idd, _ := database.InsertSQl("INSERT with_req (idUser, amount, address) VALUES (?, ?, ?)", userID, amountToSend, userAddr)
			asdf, err := database.ReadValue[int](`	 SELECT count(auth)
														 FROM with_req
														 WHERE auth = 1 and idUser = ?
														 GROUP BY idUser
														 HAVING MIN(send) = 1`, userID)
			if err != nil {
				go service.SendAdminsReq(idd)
				return utils.ReportError(c, "Your withdraw request is on review", http.StatusConflict)
			} else {
				if asdf > 15 {
					server, err := database.ReadValue[string]("SELECT addr FROM servers_stake WHERE id = 1")
					tx, err := coind.SendCoins(userAddr, server, amountToSend, true)
					if err != nil {
						return utils.ReportError(c, err.Error(), http.StatusConflict)
					}
					_, _ = database.InsertSQl("UPDATE with_req SET auth = 1, send = 1, idTx = ? WHERE id = ?", tx, idd)
				} else {
					go service.SendAdminsReq(idd)
					return utils.ReportError(c, "Your withdraw request is on review", http.StatusConflict)
				}
				return c.Status(fiber.StatusOK).JSON(fiber.Map{
					utils.ERROR:  false,
					utils.STATUS: utils.OK,
				})
			}
			//go service.SendAdminsReq(idd)
			//return utils.ReportError(c, "Your withdraw request is on review", http.StatusConflict)
		}
		//_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE txid = ? AND category = ? AND id <> 0 LIMIT 1", "Staking withdrawal", tx, "receive")
		//time.Sleep(time.Second * 1)
		//return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		//	"hasError":   false,
		//	utils.STATUS: utils.OK,
		//})
	} else {
		return utils.ReportError(c, "You don't have any active stake", http.StatusConflict)
	}
}

func unrequestStaking(idUser int) {
	_, _ = database.InsertSQl("UPDATE requests SET processed = 1 WHERE idUser = ? AND staking = 1 AND processed = 0 AND id <> 0 LIMIT 1", idUser)
}

func getStakeInfo(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	var emptyStruct models.CheckStakeDBStruct
	refDB := database.ReadStructEmpty[models.CheckStakeDBStruct]("SELECT amount, session FROM users_stake WHERE idUser = ? AND active = 1", userID)

	count := 0
	if refDB != emptyStruct {
		count = 1
	}

	rql, errSelect := database.ReadValue[sql.NullFloat64]("SELECT COALESCE(SUM(amount), 0) as amount FROM payouts_stake WHERE idUser = ? AND session = ? AND credited = 0 ", userID, refDB.Session)
	if errSelect != nil {
		return utils.ReportError(c, errSelect.Error(), http.StatusInternalServerError)

	}
	stakesAmount := utils.InlineIF(rql.Valid, rql.Float64, 0.0)

	totalCoins, _ := database.ReadValue[float64]("SELECT COALESCE(SUM(amount), 0) as amount FROM transaction_stake WHERE datetime >= now() - INTERVAL 1 DAY")
	inPoolTotal, _ := database.ReadValue[float64]("SELECT COALESCE(SUM(amount), 0) as amount FROM users_stake WHERE active = 1")

	percentage := refDB.Amount.Float64 / inPoolTotal
	estimated := totalCoins * percentage

	autoStake := database.ReadValueEmpty[bool]("SELECT autostake FROM users_stake WHERE idUser = ? AND active = 1", userID)

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.STATUS:   utils.OK,
		"hasError":     false,
		"amount":       refDB.Amount.Float64,
		"active":       count,
		"stakesAmount": stakesAmount,
		"contribution": percentage * 100,
		"estimated":    estimated,
		"poolAmount":   inPoolTotal,
		"autoStake":    autoStake,
	})
}

func getStakeGraph(c *fiber.Ctx) error {
	name := "Get stake graph request"
	start := time.Now()
	userID, _ := strconv.Atoi(c.Get("User_id"))
	var stakeReq models.GetStakeStruct
	if err := c.BodyParser(&stakeReq); err != nil {
		return err
	}

	var s *sqlx.Rows
	var errDB error
	var sqlQuery string
	createdFormat := "2006-01-02 15:04:05"
	timez := stakeReq.Datetime.Format(createdFormat)
	year, month, _ := stakeReq.Datetime.Date()

	if stakeReq.Type == 0 {
		sqlQuery = `SELECT date(datetime) as day, Hour(datetime) AS hour, sum(amount) AS amount FROM  payouts_stake WHERE datetime BETWEEN ? AND date_add(?, INTERVAL 24 HOUR) AND idUser = ? GROUP BY hour, day ORDER BY hour`
		s, errDB = database.ReadSql(sqlQuery, timez, timez, userID)
	} else if stakeReq.Type == 1 {
		sqlQuery = "SELECT date(datetime) as day, sum(amount) AS amount FROM  payouts_stake WHERE datetime BETWEEN  date_sub(?, INTERVAL 1 WEEK) AND ? AND idUser = ? GROUP BY day"
		s, errDB = database.ReadSql(sqlQuery, timez, timez, userID)
	} else if stakeReq.Type == 2 {
		sqlQuery = "SELECT DATE(datetime) as day, SUM(`amount`) AS amount FROM payouts_stake WHERE idUser =? AND YEAR(date(datetime))=? AND MONTH(date(datetime))=? GROUP BY DATE(datetime)"
		s, errDB = database.ReadSql(sqlQuery, userID, year, month)
	} else if stakeReq.Type == 3 {
		sqlQuery = "SELECT ANY_VALUE(DATE_FORMAT(datetime,'%Y-%m')) AS day, SUM(`amount`) AS amount FROM payouts_stake WHERE idUser = ? AND YEAR(date(datetime))= ? GROUP BY MONTH (date(datetime))"
		s, errDB = database.ReadSql(sqlQuery, userID, year)
	}

	if errDB != nil {
		return utils.ReportError(c, errDB.Error(), http.StatusInternalServerError)
	}

	var returnArr interface{}
	if stakeReq.Type == 0 {
		returnArr = database.ParseArrayStruct[models.StakeDailyGraph](s)
	} else {
		returnArr = database.ParseArrayStruct[models.StakeWeeklyGraph](s)
	}
	elapsed := time.Since(start)
	if debugTime {
		utils.ReportMessage(fmt.Sprintf("%s took %s", name, elapsed))
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"stakes":     returnArr,
	})
}

func getTokenBalance(c *fiber.Ctx) error {
	userID := c.Get("User_id")

	//make database call below in goroutine
	acc, err := database.ReadArrayStruct[models.UsersTokenAddr]("SELECT * FROM users_addr WHERE idUser = ? AND addr IS NOT NULL", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	blc := 0.0
	for _, v := range acc {
		if string(v.Addr) == "" {
			//return utils.ReportError(c, "No address", http.StatusBadRequest)
			continue
		}
		balance, err := web3.GetContractBalance(v.Addr)
		if err != nil {
			//return utils.ReportError(c, err.Error(), http.StatusBadRequest)
			continue
		}
		blc += balance
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"balance":    blc,
	})
}

func getTokenTX(c *fiber.Ctx) error {
	userID := c.Get("User_id")
	var txReq models.GetTokenTxReq
	if err := c.BodyParser(&txReq); err != nil {
		return err
	}

	addr, err := database.ReadArrayStruct[models.UsersTokenAddr]("SELECT * FROM users_addr WHERE idUser = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	type TX struct {
		Addr    string           `json:"addr"`
		Balance float64          `json:"bal"`
		TX      []models.TokenTX `json:"tx"`
	}
	var txArr []TX
	if len(addr) > 0 {
		for _, v := range addr {
			address := v.Addr
			if len(address) == 0 {
				continue
			}

			balance, err := web3.GetContractBalance(address)
			if err != nil {
				return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
			}

			db, err := database.ReadArrayStruct[models.TokenTX]("SELECT hash, timestampTX, fromAddr, toAddr, contractDecimal, amount, confirmations FROM bsc_tx WHERE timestampTX > ? AND tokenSymbol = 'WXDN' AND (toAddr = ? OR fromAddr = ?) ORDER BY timestampTX DESC", txReq.Timestamp, address, address)
			if err != nil {
				return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
			}
			txArr = append(txArr, TX{
				Addr:    address,
				Balance: balance,
				TX:      db,
			})
		}
	} else {
		return utils.ReportError(c, "No user addresses in the db", http.StatusConflict)
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"rest":       txArr,
	})
}

func getAvatarVersion(c *fiber.Ctx) error {
	type Req struct {
		Address string `json:"address"`
	}
	var r Req
	err := c.BodyParser(&r)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if r.Address == "" {
		return utils.ReportError(c, "Address is empty", http.StatusBadRequest)
	}
	avatarVersion, err := database.ReadValue[int64]("SELECT av FROM users WHERE addr = ?", r.Address)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"version":    avatarVersion,
	})
}

func getAvatar(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown user", http.StatusBadRequest)
	}
	type Req struct {
		ID      int64  `json:"id"`
		Address string `json:"address"`
	}
	var r Req
	err := c.BodyParser(&r)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}

	utils.ReportMessage(fmt.Sprintf("Get avatar, user %v", r))

	if len(r.Address) == 0 {
		//by id
		id := 0
		if r.ID != 0 {
			id = int(r.ID)
		} else {
			id = userID
		}
		avatar, err := database.ReadValue[sql.NullString]("SELECT avatar FROM users WHERE id = ?", id)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
		if avatar.Valid {
			av, err := os.ReadFile(fmt.Sprintf(utils.GetHomeDir() + "/api/avatars/" + avatar.String + ".xdf"))
			if err != nil {
				return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
			}
			return c.Status(fiber.StatusOK).JSON(&fiber.Map{
				"hasError":   false,
				utils.STATUS: utils.OK,
				"avatar":     string(av),
			})
		} else {
			return c.Status(fiber.StatusBadRequest).JSON(&fiber.Map{
				"hasError":   true,
				utils.STATUS: utils.FAIL,
			})
		}
	} else {
		//by address
		avatar, err := database.ReadValue[sql.NullString]("SELECT avatar FROM users WHERE addr = ?", r.Address)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
		if avatar.Valid {
			av, err := os.ReadFile(fmt.Sprintf(utils.GetHomeDir() + "/api/avatars/" + avatar.String + ".xdf"))
			if err != nil {
				return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
			}
			return c.Status(fiber.StatusOK).JSON(&fiber.Map{
				"hasError":   false,
				utils.STATUS: utils.OK,
				"avatar":     string(av),
			})
		} else {
			return c.Status(fiber.StatusBadRequest).JSON(&fiber.Map{
				"hasError":   false,
				utils.STATUS: utils.OK,
			})
		}
	}
}

func uploadAvatar(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown user", http.StatusBadRequest)
	}
	type Req struct {
		File string `json:"file"`
	}
	var r Req
	err := c.BodyParser(&r)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	avatar, err := database.ReadValue[sql.NullString]("SELECT avatar FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	if avatar.Valid {
		//already has avatar
		err = os.WriteFile(fmt.Sprintf(utils.GetHomeDir()+"/api/avatars/"+avatar.String+".xdf"), []byte(r.File), 0644)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
		_, _ = database.InsertSQl("UPDATE users SET av = av + 1 WHERE id = ?", userID)
	} else {
		//don't have avatar
		filename := utils.GenerateSecureToken(10)
		err = os.WriteFile(fmt.Sprintf(utils.GetHomeDir()+"/api/avatars/"+filename+".xdf"), []byte(r.File), 0644)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
		_, _ = database.InsertSQl("UPDATE users SET avatar = ? WHERE id = ?", filename, userID)
		_, _ = database.InsertSQl("UPDATE users SET av = av + 1 WHERE id = ?", userID)
	}
	return c.Status(http.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
	})

}

func saveToAddressBook(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type Req struct {
		Id   int    `json:"id"`
		Name string `json:"name"`
		Addr string `json:"addr"`
	}
	var req Req
	err := c.BodyParser(&req)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	value, err := database.ReadValue[int64]("SELECT COUNT(id) FROM addressbook WHERE idUser = ? AND addr = ?", userID, req.Addr)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	if value == 0 {
		_, err = database.InsertSQl("INSERT INTO addressbook (idUser, name, addr) VALUES (?,?,?)", userID, req.Name, req.Addr)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
		}
	}
	arrayStruct, err := database.ReadArrayStruct[Req]("SELECT id, name, addr FROM addressbook  WHERE idUser = ? ORDER BY id DESC", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"data":       arrayStruct,
	})
}

func getAddressBook(c *fiber.Ctx) error {
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	type AddressBook struct {
		Id   int    `json:"id"`
		Name string `json:"name"`
		Addr string `json:"addr"`
	}
	arrayStruct, err := database.ReadArrayStruct[AddressBook]("SELECT id, name, addr FROM addressbook  WHERE idUser = ? ORDER BY id DESC", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
		"data":       arrayStruct,
	})
}
