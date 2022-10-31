package main

import (
	"bufio"
	"crypto/tls"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"github.com/go-gomail/gomail"
	"github.com/gofiber/fiber/v2"
	_ "github.com/gofiber/fiber/v2/utils"
	"github.com/jmoiron/sqlx"
	"github.com/pquerna/otp/totp"
	"gopkg.in/guregu/null.v4"
	"io"
	"log"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"
	"xdn-voting/apiWallet"
	"xdn-voting/coind"
	"xdn-voting/daemons"
	"xdn-voting/database"
	"xdn-voting/errs"
	"xdn-voting/html"
	"xdn-voting/models"
	"xdn-voting/utils"
	"xdn-voting/web3"
)

var debugTime = false

func main() {
	database.New()
	utils.NewJWT()
	web3.New()

	//debug time
	debugTime = false

	// ============= Price Data  ===============
	go daemons.PriceData()

	// ============== API Wallet ===============
	go apiWallet.Handler()

	app := fiber.New(fiber.Config{AppName: "XDN DAO API", StrictRouting: true})
	utils.ReportMessage("Rest API v" + utils.VERSION + " - XDN DAO API | SERVER")
	// ================== DAO ==================
	app.Post("dao/v1/login", login)
	app.Get("dao/v1/ping", utils.Authorized(ping))
	app.Get("dao/v1/contest/get", utils.Authorized(getCurrentContest))
	app.Get("dao/v1/contest/check", utils.Authorized(checkContest))
	app.Post("dao/v1/contest/create", utils.Authorized(createContest))
	app.Post("dao/v1/contest/vote", utils.Authorized(castVote))
	app.Post("dao/v1/address/add", utils.Authorized(addAddress))
	app.Post("dao/v1/user/address/add", utils.Authorized(addUserAddress))

	// ================== API ==================
	app.Post("api/v1/login", loginAPI)
	app.Post("api/v1/register", registerAPI)
	app.Post("api/v1/login/refresh", refreshToken)
	app.Post("api/v1/login/forgot", forgotPassword)
	app.Post("api/v1/firebase", utils.Authorized(firebaseToken))
	app.Post("api/v1/password/change", utils.Authorized(changePassword))

	app.Get("api/v1/misc/privkey", utils.Authorized(getPrivKey))

	app.Post("api/v1/twofactor", utils.Authorized(twofactor))
	app.Post("api/v1/twofactor/activate", utils.Authorized(twofactorVerify))
	app.Get("api/v1/twofactor/check", utils.Authorized(twofactorCheck))
	app.Post("api/v1/twofactor/remove", utils.Authorized(twoFactorRemove))

	app.Post("api/v1/staking/graph", utils.Authorized(getStakeGraph))
	app.Post("api/v1/staking/set", utils.Authorized(setStake))
	app.Post("api/v1/staking/unset", utils.Authorized(unstake))
	app.Get("api/v1/staking/info", utils.Authorized(getStakeInfo))

	app.Get("api/v1/price/data", utils.Authorized(getPriceData))

	app.Post("api/v1/avatar/upload", utils.Authorized(uploadAvatar))
	app.Post("api/v1/avatar", utils.Authorized(getAvatar))
	app.Post("api/v1/avatar/version", utils.Authorized(getAvatarVersion))

	app.Get("api/v1/user/balance", utils.Authorized(getBalance))
	app.Get("api/v1/user/transactions", utils.Authorized(getTransactions))

	app.Post("api/v1/user/send/contact", utils.Authorized(sendContactTransaction))
	app.Post("api/v1/user/send", utils.Authorized(sendTransaction))

	app.Get("api/v1/user/xls", utils.Authorized(getTxXLS))

	app.Get("api/v1/user/messages/group", utils.Authorized(getMessageGroup))
	app.Post("api/v1/user/messages", utils.Authorized(getMessages))
	app.Post("api/v1/user/messages/likes", utils.Authorized(getMessagesLikes))
	app.Post("api/v1/user/messages/send", utils.Authorized(sendMessage))
	app.Post("api/v1/user/messages/read", utils.Authorized(readMessages))

	app.Get("api/v1/user/addressbook", utils.Authorized(getAddressBook))
	app.Post("api/v1/user/addressbook/save", utils.Authorized(saveToAddressBook))
	app.Post("api/v1/user/addressbook/delete", utils.Authorized(deleteFromAddressBook))
	app.Post("api/v1/user/addressbook/update", utils.Authorized(updateAddressBook))

	app.Post("api/v1/user/rename", utils.Authorized(renameUser))
	app.Post("api/v1/user/delete", utils.Authorized(deleteUser))

	app.Get("api/v1/user/token/wxdn", utils.Authorized(getTokenBalance))
	app.Post("api/v1/user/token/tx", utils.Authorized(getTokenTX))

	app.Get("api/v1/status", utils.Authorized(getStatus))

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
	daemons.DaemonStatus()
	utils.ScheduleFunc(daemons.SaveTokenTX, time.Minute*10)
	utils.ScheduleFunc(daemons.DaemonStatus, time.Minute*10)
	utils.ScheduleFunc(daemons.PriceData, time.Minute*5)

	// Create tls certificate
	cer, err := tls.LoadX509KeyPair("dex.crt", "dex.key")
	if err != nil {
		log.Fatal(err)
	}

	config := &tls.Config{Certificates: []tls.Certificate{cer}}

	// Create custom listener
	ln, err := tls.Listen("tcp", ":6800", config)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		panic(err)
	}

	// Start server with https/ssl enabled on http://localhost:443
	log.Fatal(app.Listener(ln))

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

	exist, err := database.ReadValue[sql.NullInt64]("SELECT id FROM devices WHERE token = ?", Req.Token)
	if err != nil {
		return utils.ReportError(c, err.Error(), fiber.StatusInternalServerError)
	}
	if !exist.Valid {
		_, _ = database.InsertSQl("INSERT INTO devices(idUser, token, device_type) VALUES (?, ?, ?)", userID, Req.Token, Req.Platform)
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
		d := map[string]interface{}{
			"func": "sendMessage",
			"from": addrFrom,
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
	readSql, err := database.ReadSql("SELECT * FROM transaction WHERE account = ? ORDER BY id DESC", usr)
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

	addrSend, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)

	tx, err := coind.SendCoins(data.Address, addrSend, data.Amount, false)
	if err != nil {
		return utils.ReportError(c, "Wallet problem, try again later", fiber.StatusConflict)
	}
	_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", data.Contact, tx, "send")

	go func(data dataReq, addrSend string) {
		d := map[string]interface{}{
			"func": "sendContactTransaction",
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

	addrSend, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)

	_, err = coind.SendCoins(data.Address, addrSend, data.Amount, false)
	if err != nil {
		return utils.ReportError(c, "Wallet problem, try again later", fiber.StatusConflict)
	}
	go func(data dataReq, addrSend string) {
		d := map[string]interface{}{
			"func": "sendTransaction",
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
	utils.ReportMessage("1")
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
	userExists, err := database.ReadValue[bool]("SELECT EXISTS(SELECT * FROM users WHERE username = ? OR email= ?)", req.Username, req.Password)
	if userExists {
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
	privKey := strings.Trim(string(pKey), "\"")
	_, _ = coind.WrapDaemon(utils.DaemonWallet, 2, "walletlock")
	_, err = database.InsertSQl("INSERT INTO users(username, password, email, addr, nickname, realname, UDID, privkey) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", req.Username, req.Password, req.Email, addr, req.Username, req.RealName, req.Udid, privKey)

	return c.Status(fiber.StatusCreated).JSON(&fiber.Map{
		"hasError":   false,
		utils.STATUS: utils.OK,
	})
}

func loginAPI(c *fiber.Ctx) error {
	var req models.UserLogin
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

func refreshToken(c *fiber.Ctx) error {
	var userAuth models.RefreshToken
	errJson := c.BodyParser(&userAuth)
	if errJson != nil {
		return utils.ReportError(c, errJson.Error(), http.StatusBadRequest)
	}

	readSql, errSelect := database.ReadStruct[models.RefreshTokenStruct]("SELECT * FROM refresh_token WHERE refreshToken = ?", userAuth.Token)
	if errSelect != nil {
		return utils.ReportErrorSilent(c, "Invalid refresh token", http.StatusUnauthorized)
	}

	if len(readSql.RefToken) != 0 && readSql.Used == 0 {
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
	name := "XDN balance request"
	start := time.Now()
	userID, er := strconv.Atoi(c.Get("User_id"))
	if er != nil {
		return utils.ReportError(c, "Unknown User", http.StatusBadRequest)
	}
	acc, _ := database.ReadValue[string]("SELECT username FROM users WHERE id = ?", userID)
	addr, _ := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	immature, _ := database.ReadValue[float64]("SELECT IFNULL(SUM(amount),0) as immature FROM transaction WHERE account = ? AND confirmation < 2 AND category = 'receive'", acc)
	daemon := utils.GetDaemon()
	unspent, err := coind.WrapDaemon(*daemon, 5, "listunspent", 1, 9999999, []string{addr})
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	bal, err := database.ReadValue[float64](`SELECT SUM(amount) as amount FROM transaction WHERE account = ?`, acc)
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
	pending := bal - spendable
	elapsed := time.Since(start)
	if debugTime {
		utils.ReportMessage(fmt.Sprintf("%s took %s", name, elapsed))
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"balance":    fmt.Sprintf("%.2f", float32(pending)),
		"immature":   float32(immature),
		"spendable":  float32(spendable),
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
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
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
		tx, err := coind.SendCoins(server, userAddr, r.Amount, false)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusConflict)
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
		tx, err := coind.SendCoins(server, userAddr, r.Amount, false)
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
	userID := c.Get("User_id")
	type req struct {
		Type int `json:"type"`
	}
	var r req
	err := c.BodyParser(&r)
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
	} else {
		dateChanged := user.DateStart.Time.UTC().UnixMilli()
		dateNow := time.Now().UnixMilli()
		dateDiff := dateNow - dateChanged
		if dateDiff > 86400000 {
			amountToSend += userStake
			amountToSend += payouts
		} else {
			return utils.ReportError(c, "You can only unstake after 24 hours", http.StatusConflict)
		}
	}
	utils.ReportMessage(fmt.Sprintf("Amount to send: %f, user to send %d", amountToSend, user.IdUser))
	server, err := database.ReadValue[string]("SELECT addr FROM servers_stake WHERE id = 1")
	userAddr, err := database.ReadValue[string]("SELECT addr FROM users WHERE id = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	if user.Active != 0 {
		utils.ReportMessage("UNSTAKING")
		tx, err := coind.SendCoins(userAddr, server, amountToSend, true)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusConflict)
		}
		if r.Type == 1 {
			_, _ = database.InsertSQl("UPDATE payouts_stake SET credited = ? WHERE idUser = ? AND session = ? AND id <> 0", 1, userID, user.Session)
		} else {
			_, _ = database.InsertSQl("UPDATE payouts_stake SET credited = ? WHERE idUser = ? AND session = ? AND id <> 0", 1, userID, user.Session)
			_, _ = database.InsertSQl("UPDATE users_stake SET active = ? WHERE idUser = ?", 0, userID)
		}
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE txid = ? AND category = ? AND id <> 0 LIMIT 1", "Staking withdrawal", tx, "receive")
		time.Sleep(time.Second * 1)
		return c.Status(fiber.StatusOK).JSON(&fiber.Map{
			"hasError":   false,
			utils.STATUS: utils.OK,
		})
	} else {
		return utils.ReportError(c, "You don't have any active stake", http.StatusConflict)
	}
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

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.STATUS:   utils.OK,
		"hasError":     false,
		"amount":       refDB.Amount.Float64,
		"active":       count,
		"stakesAmount": stakesAmount,
		"contribution": percentage * 100,
		"estimated":    estimated,
		"poolAmount":   inPoolTotal,
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

	//staking, err := database.ReadValue[sql.NullBool]("SELECT active FROM users_stakes WHERE idUser = ?", userID)
	//if err != nil {
	//	return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	//}
	//if !staking.Valid {
	//	return utils.ReportError(c, err.Error(), http.StatusBadRequest)
	//}

	if stakeReq.Type == 0 {
		sqlQuery = `SELECT date(datetime) as day, Hour(datetime) AS hour, sum(amount) AS amount FROM  payouts_stake WHERE datetime BETWEEN ? AND date_add(?, INTERVAL 24 HOUR) AND idUser = ? AND credited = 0 GROUP BY hour, day ORDER BY hour`
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
	if debugTime {
		utils.ReportMessage(fmt.Sprint("===== Get Token Balance for user ", userID, " ====="))
	}
	name := "Token balance request"
	start := time.Now()

	//make database call below in goroutine
	acc, err := database.ReadArrayStruct[models.UsersTokenAddr]("SELECT * FROM users_addr WHERE idUser = ? AND addr IS NOT NULL", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	elapsed := time.Since(start)
	if debugTime {
		utils.ReportMessage(fmt.Sprintf("%s took %s", "DB Query", elapsed))
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
	elapsed = time.Since(start)
	if debugTime {
		utils.ReportMessage(fmt.Sprintf("%s took %s", name, elapsed))
		utils.ReportMessage(fmt.Sprint("=====////====="))
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

	db, err := database.ReadArrayStruct[models.TokenTX]("SELECT * FROM bsc_tx WHERE idUser = ? AND timestampTX > ? AND tokenSymbol = 'WXDN' ORDER BY timestampTX DESC", userID, txReq.Timestamp)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}

	addr, err := database.ReadArrayStruct[models.UsersTokenAddr]("SELECT addr FROM users_addr WHERE idUser = ?", userID)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	blc := 0.0
	add := ""
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
			blc += balance
			add = address
		}
	} else {
		return utils.ReportError(c, "No user addresses in the db", http.StatusConflict)
	}

	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		utils.ERROR:  false,
		utils.STATUS: utils.OK,
		"addr":       add,
		"bal":        blc,
		"tx":         db,
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
