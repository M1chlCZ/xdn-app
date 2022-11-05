package bot

import (
	"database/sql"
	"fmt"
	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
	"gopkg.in/errgo.v2/errors"
	"os"
	"regexp"
	"strconv"
	"strings"
	"xdn-voting/coind"
	"xdn-voting/database"
	"xdn-voting/utils"
)

var statusMessage = []string{"I'm okay, you?", "All is good", "Yep...still okay", "Living the expensive life currently, you?", "I'm fine, how are you?", "I'm good, thanks!", "I'm fine"}

func HandleBot() {
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
			msg := tgbotapi.NewMessage(update.Message.Chat.ID, "")

			switch update.Message.Command() {
			case "":
				continue
			case "help":
				msg.Text = "I understand /register /status and /tip."
			case "tip":
				tx, err := tip(update.Message.From.UserName, update.Message)
				if err != nil {
					msg.Text = "Error: " + err.Error()
				} else {
					msg.Text = tx
				}
			case "status":
				stMess := statusMessage[utils.RandInt(0, len(statusMessage)-1)]
				msg.Text = stMess
			case "register":
				err := register(update.Message.CommandArguments(), update.Message.From)
				if err != nil {
					msg.Text = "Error: " + err.Error()
				} else {
					msg.Text = "Registered successfully!"
				}
			default:
				msg.Text = "Invalid command"
			}

			if _, err := bot.Send(msg); err != nil {
				utils.WrapErrorLog(err.Error())
			}
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

	_, err := database.InsertSQl("INSERT INTO users_bot (idUser, idSocial, token) VALUES (?, ?, ?)", idUser.Int64, from.UserName, token)
	if err != nil {
		return errors.New("Error #3")
	}
	utils.ReportMessage(fmt.Sprintf("Registered user %s (uid: %d) ", from.UserName, idUser.Int64))
	return nil
}

func tip(username string, from *tgbotapi.Message) (string, error) {
	if from.From.IsBot {
		return "", errors.New("Bots are not allowed")
	}
	str1 := strings.ReplaceAll(from.Text, "@", "")
	str2 := from.Text
	if (len(str2) - len(str1)) > 1 {
		return "", errors.New("You can tip only one user per command")
	}
	re := regexp.MustCompile("\\B@\\w+")
	reg := regexp.MustCompile("\\s[0-9]+")
	m := re.FindSubmatch([]byte(from.Text))
	usr := ""
	for _, match := range m {
		s := string(match)
		utils.ReportMessage(fmt.Sprintf("Match - %s:", strings.Trim(s, "\n")))
		usr = strings.Trim(s, "\n") + " "
	}
	amount := reg.FindAllString(from.Text, -1)
	if usr == "" {
		return "", errors.New("No user to tip")
	}
	ut := strings.Trim(usr, "@")

	usrFrom := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE binary idSocial= ?", username)
	if !usrFrom.Valid {
		return "", errors.New("Not registered")
	}
	usrTo := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE binary idSocial = ?", strings.TrimSpace(ut))
	if !usrTo.Valid {
		return "", errors.New("User to tip not registered")
	}
	contactTO := database.ReadValueEmpty[sql.NullString]("SELECT name FROM addressbook WHERE idUser = ? AND addr = (SELECT addr FROM users WHERE id = (SELECT idUser FROM users_bot WHERE idSocial = ? ))", usrFrom, ut)
	if !contactTO.Valid {
		return "", errors.New("User to tip not registered")
	}
	addrFrom := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM users WHERE id = ?", usrFrom.Int64)
	if !addrFrom.Valid {
		return "", errors.New("Error getting user address")
	}
	addrTo := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM users WHERE id = ?", usrTo.Int64)
	if !addrTo.Valid {
		return "", errors.New("Error getting user address")
	}
	utils.ReportMessage(fmt.Sprintf("From: %s, To: %s, Amount: %s", addrFrom.String, addrTo.String, strings.TrimSpace(amount[len(amount)-1])))
	amnt, err := strconv.ParseFloat(strings.TrimSpace(amount[len(amount)-1]), 32)
	if err != nil {
		return "", errors.New("Invalid amount")
	}
	tx, err := coind.SendCoins(addrTo.String, addrFrom.String, amnt, false)
	if err != nil {
		return "", err
	}
	if contactTO.Valid {
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip to: "+contactTO.String, tx, "send")
	} else {
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip to: "+strings.TrimSpace(ut), tx, "send")
	}
	_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tipped by: "+username, tx, "receive")
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
	utils.ReportMessage(mes)
	return mes, nil
	//return nil
}
