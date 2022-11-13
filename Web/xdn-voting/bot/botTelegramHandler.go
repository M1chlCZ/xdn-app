package bot

import (
	"database/sql"
	"fmt"
	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
	"gopkg.in/errgo.v2/errors"
	"math/rand"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"
	"xdn-voting/coind"
	"xdn-voting/database"
	"xdn-voting/utils"
)

const (
	MainChannel = -1001238019497
)

var statusMessage = []string{"I'm okay, you?", "All is good", "Yep...still okay", "Living the expensive life currently, you?", "I'm fine, how are you?", "I'm good, thanks!", "I'm fine"}

func StartTelegramBot() {
	bot, err := tgbotapi.NewBotAPI(os.Getenv("TELEGRAM"))
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}

	bot.Debug = true
	updateConfig := tgbotapi.NewUpdate(0)
	updateConfig.Timeout = 30
	updates := bot.GetUpdatesChan(updateConfig)

	for update := range updates {
		if update.Message != nil {
			go func(update *tgbotapi.Update) {
				msg := tgbotapi.NewMessage(update.Message.Chat.ID, "")
				switch update.Message.Command() {
				case "status":
					utils.ReportMessage(fmt.Sprintf("Message from %d", update.Message.Chat.ID))
					msg.Text = statusMessage[rand.Intn(len(statusMessage))]
					if _, err := bot.Send(msg); err != nil {
						utils.WrapErrorLog(err.Error())
					}
					return
				case "help":
					msg.Text = "I understand /register /unlink /status and /tip."
					if _, err := bot.Send(msg); err != nil {
						utils.WrapErrorLog(err.Error())
					}
					return
				case "tip":
					tx, err := tip(update.Message.From.UserName, update.Message)
					if err != nil {
						msg.Text = "Error: " + err.Error()
					} else {
						msg.Text = tx
					}
					if _, err := bot.Send(msg); err != nil {
						utils.WrapErrorLog(err.Error())
					}
					return
				case "rain":
					tx, errr, data := rain(update.Message.From.UserName, update.Message)
					if errr != nil {
						msg.Text = "Error: " + errr.Error()
						_, _ = bot.Send(msg)
						return
					}
					msg.Text = tx
					mmm, err := bot.Send(msg)
					if err != nil {
						m := tgbotapi.NewMessage(update.Message.Chat.ID, "Error: "+err.Error())
						_, _ = bot.Send(m)
						utils.WrapErrorLog(err.Error())
						return
					}
					chatID := mmm.Chat.ID
					messageID := mmm.MessageID
					txd, err := finishRain(data)
					if err != nil {
						m := tgbotapi.NewMessage(chatID, "Error: "+err.Error())
						_, _ = bot.Send(m)
						utils.WrapErrorLog(err.Error())
						return
					}
					ms := tgbotapi.NewEditMessageText(chatID, messageID, txd)
					if _, err := bot.Send(ms); err != nil {
						utils.WrapErrorLog(err.Error())
					}
					return
				case "register":
					err := register(update.Message.CommandArguments(), update.Message.From)
					if err != nil {
						msg.Text = "Error: " + err.Error()
					} else {
						msg.Text = "Registered successfully!"
					}
					if _, err := bot.Send(msg); err != nil {
						utils.WrapErrorLog(err.Error())
					}
					return
				case "unlink":
					err := unlink(update.Message.From)
					if err != nil {
						msg.Text = "Error: " + err.Error()
					} else {
						msg.Text = "Unliked successfully!"
					}
					if _, err := bot.Send(msg); err != nil {
						utils.WrapErrorLog(err.Error())
					}
					return
				default:
					return
				}
			}(&update)
		}
	}

}

func isRegistered(userID string) error {
	usrFrom := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ?", userID)
	if !usrFrom.Valid {
		return errors.New("Not registered")
	}
	return nil
}

func register(token string, from *tgbotapi.User) error {
	if from.IsBot {
		return errors.New("Bots are not allowed")
	}
	if from.UserName == "" {
		return errors.New("Username is required")
	}

	already := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users_bot WHERE idSocial = ?", from.UserName)
	if already.Valid {
		return errors.New("Already registered")
	}

	idUser := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users WHERE tokenSocials = ?", token)
	if !idUser.Valid {
		return errors.New("Invalid token")
	}

	_, _ = database.InsertSQl("INSERT INTO users_bot (idUser, idSocial, token, typeBot) VALUES (?, ?, ?,?)", idUser.Int64, from.UserName, token, 1)

	RegenerateTokenSocial(idUser.Int64)
	utils.ReportMessage(fmt.Sprintf("Registered user %s (uid: %d) to Telegram bot", from.UserName, idUser.Int64))
	return nil
}

func unlink(from *tgbotapi.User) error {
	if from.IsBot {
		return errors.New("Bots are not allowed")
	}
	if from.UserName == "" {
		return errors.New("Username is required")
	}

	already := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users_bot WHERE idSocial = ? AND typeBot = ?", from.UserName, 1)
	if !already.Valid {
		return errors.New("Not seeing you in the database")
	}

	idUser := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ?", from.UserName)
	if !idUser.Valid {
		return errors.New("Not seeing you in the database")
	}

	_, err := database.InsertSQl("DELETE FROM users_bot WHERE id = ?", already.Int64)
	if err != nil {
		return errors.New("Error #5")
	}
	RegenerateTokenSocial(idUser.Int64)
	utils.ReportMessage(fmt.Sprintf("Unlinked user %s (uid: %d) from Telegram", from.UserName, idUser.Int64))
	return nil

}

func tip(username string, from *tgbotapi.Message) (string, error) {
	if from.From.IsBot {
		return "", errors.New("Bots are not allowed")
	}
	str1 := strings.ReplaceAll(from.Text, "@", "")
	str2 := from.Text
	utils.ReportMessage(fmt.Sprintf("Tip from %s text %s", username, from.Text))
	if (len(str2) - len(str1)) > 1 {
		return "", errors.New("You can tip only one user per command")
	}
	re := regexp.MustCompile("\\B@[a-zA-z0-9]+")
	reg := regexp.MustCompile("\\s[0-9]+")
	m := re.FindSubmatch([]byte(from.Text))
	usr := ""
	if len(m) == 0 {
		return "", errors.New("Invalid username")
	}
	for _, match := range m {
		s := string(match)
		usr = strings.Trim(s, "\n") + " "
	}
	amount := reg.FindAllString(from.Text, -1)
	if usr == "" {
		return "", errors.New("No user to tip")
	}
	utils.ReportMessage(fmt.Sprintf("Tip %x", m))
	ut := strings.Trim(usr, "@")
	utils.ReportMessage(fmt.Sprintf("Tip from %s to %s amount %s", username, ut, amount))

	usrFrom := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE binary idSocial= ? AND typeBot = ?", username, 1)
	if !usrFrom.Valid {
		return "", errors.New("You are not registered in the bot db")
	}
	usrTo := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE binary idSocial = ? AND typeBot = ?", strings.TrimSpace(ut), 1)
	if !usrTo.Valid {
		return "", errors.New("Mentioned user not registered in the bot db")
	}
	contactTO := database.ReadValueEmpty[sql.NullString]("SELECT name FROM addressbook WHERE idUser = ? AND addr = (SELECT addr FROM users WHERE id = (SELECT idUser FROM users_bot WHERE idSocial = ? ))", usrFrom, ut)
	addrFrom := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM users WHERE id = ?", usrFrom.Int64)
	if !addrFrom.Valid {
		return "", errors.New("Error getting user address #1")
	}
	addrTo := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM users WHERE id = ?", usrTo.Int64)
	if !addrTo.Valid {
		return "", errors.New("Error getting user address #2")
	}
	utils.ReportMessage(fmt.Sprintf("From: %s, To: %s, Amount: %s", addrFrom.String, addrTo.String, strings.TrimSpace(amount[len(amount)-1])))
	amnt, err := strconv.ParseFloat(strings.TrimSpace(amount[len(amount)-1]), 32)
	if err != nil {
		return "", errors.New("Invalid amount")
	}
	tx, err := coind.SendCoins(addrTo.String, addrFrom.String, amnt, false)
	if err != nil {
		return "", errors.New("Error sending coins from " + username)
	}
	if contactTO.Valid {
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip to: "+contactTO.String, tx, "send")
	} else {
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip to: "+strings.TrimSpace(ut), tx, "send")
	}
	go func(addrTo string, addrSend string, amount string) {
		d := map[string]string{
			"fn": "sendTransaction",
		}
		userTo := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users WHERE addr = ?", addrTo)
		if userTo.Valid {
			nameFrom, err := database.ReadValue[sql.NullString]("SELECT name FROM addressbook WHERE idUser = ? AND addr = ?", userTo.Int64, addrSend)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
			usrTo := database.ReadValueEmpty[int64]("SELECT id FROM users WHERE addr = ?", addrTo)
			type Token struct {
				Token string `json:"token"`
			}
			tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", usrTo)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
			if nameFrom.Valid {
				if len(tk) > 0 {
					for _, v := range tk {
						utils.SendMessage(v.Token, fmt.Sprintf("Tip from %s", nameFrom.String), fmt.Sprintf("%s XDN", amount), d)
					}
				}
			} else {
				if len(tk) > 0 {
					for _, v := range tk {
						utils.SendMessage(v.Token, fmt.Sprintf("Tip from %s", addrSend), fmt.Sprintf("%s XDN", amount), d)
					}
				}
			}
		}
	}(addrTo.String, addrFrom.String, amount[len(amount)-1])
	mes := fmt.Sprintf("User @%s tipped @%s%s XDN", username, ut, amount[len(amount)-1])
	utils.ReportMessage(fmt.Sprintf("User @%s tipped @%s%s XDN on Telegram", username, ut, amount[len(amount)-1]))
	return mes, nil
	//return nil
}

func rain(username string, from *tgbotapi.Message) (string, error, RainReturnStruct) {
	if from.From.IsBot {
		return "", errors.New("Bots are not allowed"), RainReturnStruct{}
	}
	str1 := strings.ReplaceAll(from.Text, "@", "")
	str2 := from.Text
	if (len(str2) - len(str1)) > 1 {
		return "", errors.New("Only one parameter is allowed"), RainReturnStruct{}
	}

	//eg: 100XDN
	reg := regexp.MustCompile("\\s[0-9]+")
	am := reg.FindAllString(from.Text, -1)
	if len(am) == 0 {
		return "", errors.New("Missing amount to tip"), RainReturnStruct{}
	}
	if len(am) > 1 {
		return "", errors.New("You can specify only one amount to tip"), RainReturnStruct{}
	}
	amount, err := strconv.ParseFloat(strings.TrimSpace(am[len(am)-1]), 32)
	if err != nil {
		return "", errors.New("Invalid amount to tip"), RainReturnStruct{}
	}

	usrFrom := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE binary idSocial= ? AND typeBot = ?", username, 1)
	if !usrFrom.Valid {
		return "", errors.New("You are not registered in the bot db"), RainReturnStruct{}
	}
	utils.ReportMessage(fmt.Sprintf("--- Rain from %s ---", username))
	ban := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users_bot WHERE idSocial = ? AND typeBot = ? AND ban = ?", username, 1, 1)
	if ban.Valid {
		return "", errors.New("You are banned from raining on Telegram"), RainReturnStruct{}
	}
	usersTo, err := database.ReadArray[UsrStruct](`SELECT a.addr as addr, b.idSocial as name FROM users  as a
												INNER JOIN users_bot  as b 
												ON a.id = b.idUser
												WHERE b.typeBot = 1 AND ban = 0`)
	if len(usersTo) == 0 {
		return "", errors.New("Can't find any users to tip"), RainReturnStruct{}
	}
	usersToTip := make([]UsrStruct, 0)
	numOfUsers := 0

	//eg: @100 people
	re := regexp.MustCompile("\\B@[0-9]+[^a-zA-Z]?$")
	m := re.FindAllString(from.Text, -1)
	if len(m) != 0 {
		if len(m) > 1 {
			return "", errors.New("You can specify only one number of people to tip"), RainReturnStruct{}
		}
		numOfUsers, err = strconv.Atoi(strings.ReplaceAll(m[0], "@", ""))
		if err != nil {
			return "", errors.New("Invalid number of people to tip"), RainReturnStruct{}
		}

		if len(usersTo) < numOfUsers {
			return "", errors.New("Too many users to tip"), RainReturnStruct{}
		}
		//shuffle usrFrom
		rand.Seed(time.Now().UnixNano())
		rand.Shuffle(len(usersTo), func(i, j int) { usersTo[i], usersTo[j] = usersTo[j], usersTo[i] })
		//random select numOfUser from usrFrom
		for i := 0; i < numOfUsers; i++ {
			usersToTip = append(usersToTip, usersTo[i])
		}
	} else {
		usersToTip = usersTo
		numOfUsers = len(usersTo)
	}

	//send coins to stake wallet
	addrFrom := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM users WHERE id = ?", usrFrom.Int64)
	if !addrFrom.Valid {
		return "", errors.New("Error getting user address #1"), RainReturnStruct{}
	}

	_, _ = database.InsertSQl("UPDATE users_bot SET numberRained = numberRained + 1 WHERE idUser  = ?", usrFrom.Int64) //update number of rains

	addrTo := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM servers_stake WHERE 1")
	if !addrTo.Valid {
		return "", errors.New("Problem sending coins to rain service"), RainReturnStruct{}
	}

	tx, err := coind.SendCoins(addrTo.String, addrFrom.String, amount, false)
	if err != nil {
		return "", err, RainReturnStruct{}
	}
	_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip Bot Rain", tx, "send")

	return fmt.Sprintf("Raining %.2f XDN on %d users", amount, numOfUsers), nil, RainReturnStruct{
		UsrList:  usersToTip,
		Amount:   amount,
		AddrFrom: addrTo.String,
		Username: username,
		AddrSend: addrFrom.String,
	}

}
func finishRain(data RainReturnStruct) (string, error) {
	amountToUser := data.Amount / float64(len(data.UsrList))
	d := map[string]string{
		"fn": "sendTransaction",
	}
	finalUsrs := make([]UsrStruct, 0)
	for _, v := range data.UsrList {
		tx, err := coind.SendCoins(v.Addr, data.AddrFrom, amountToUser, true)
		if err != nil {
			continue
		}
		finalUsrs = append(finalUsrs, v)
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip Bot Rain by: "+data.Username, tx, "receive")
		utils.ReportMessage("Rain", fmt.Sprintf("Sent %f XDN to %s", amountToUser, v.Addr))
		userTo := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users WHERE addr = ?", v.Addr)
		if userTo.Valid {
			nameFrom := database.ReadValueEmpty[sql.NullString]("SELECT name FROM addressbook WHERE idUser = ? AND addr = ?", userTo.Int64, data.AddrSend)
			if nameFrom.Valid {
				usrTo := database.ReadValueEmpty[int64]("SELECT id FROM users WHERE addr = ?", v.Addr)
				type Token struct {
					Token string `json:"token"`
				}
				tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", usrTo)
				if err != nil {
					utils.WrapErrorLog(err.Error())
				}
				if len(tk) > 0 {
					for _, v := range tk {
						utils.SendMessage(v.Token, fmt.Sprintf("Caught rain by: %s", nameFrom.String), fmt.Sprintf("%s XDN", strconv.FormatFloat(amountToUser, 'f', 2, 32)), d)
					}
				}
				continue
			} else {
				usrTo := database.ReadValueEmpty[int64]("SELECT id FROM users WHERE addr = ?", v.Addr)
				type Token struct {
					Token string `json:"token"`
				}
				tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", usrTo)
				if err != nil {
					utils.WrapErrorLog(err.Error())
				}
				if len(tk) > 0 {
					for _, v := range tk {
						utils.SendMessage(v.Token, fmt.Sprintf("Caught rain by: %s", data.AddrSend), fmt.Sprintf("%s XDN", fmt.Sprintf("%s XDN", strconv.FormatFloat(amountToUser, 'f', 2, 32))), d)
					}
				}
			}
			continue
		} else {
			utils.ReportMessage(fmt.Sprintf("user invalid/////////////"))
		}

	}
	userString := ""
	for _, v := range finalUsrs {
		userString += "@" + v.Name + " "
	}
	//create final message
	mes := fmt.Sprintf("User @%s rained on %s %s XDN each", data.Username, userString, strconv.FormatFloat(amountToUser, 'f', 2, 32))

	return mes, nil
}
