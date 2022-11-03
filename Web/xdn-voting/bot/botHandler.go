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
		if update.Message == nil {
			continue
		}

		msg := tgbotapi.NewMessage(update.Message.Chat.ID, "")

		switch update.Message.Command() {
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
			msg.Text = "I'm ok."
		case "register":
			err := register(update.Message.CommandArguments(), update.Message.From)
			if err != nil {
				msg.Text = "Error: " + err.Error()
			} else {
				msg.Text = "Registered successfully!"
			}
		default:
			//msg.Text = "Invalid command"
			continue
		}

		if _, err := bot.Send(msg); err != nil {
			panic(err)
		}
	}

}

func isRegistered(chatID int64) error {
	//update.FromChat().ID
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
	utils.ReportMessage("Registered user " + from.UserName + " with token " + token)
	return nil
}

func tip(username string, from *tgbotapi.Message) (string, error) {
	re := regexp.MustCompile("\\B@\\w+")
	reg := regexp.MustCompile("[0-9]+")
	amount := reg.FindAllString(from.Text, -1)
	m := re.FindSubmatch([]byte(from.Text))
	usr := ""
	for _, match := range m {
		s := string(match)
		utils.ReportMessage(fmt.Sprintf("Match - %s:", strings.Trim(s, "\n")))
		usr = strings.Trim(s, "\n") + " "
	}
	if usr == "" {
		return "", errors.New("No user to tip")
	}
	ut := strings.Trim(usr, "@")
	usrFrom := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ?", username)
	if !usrFrom.Valid {
		return "", errors.New("Not registered")
	}
	usrTo := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ?", ut)
	if !usrTo.Valid {
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
	utils.ReportMessage(fmt.Sprintf("From: %s, To: %s, Amount: %s", addrFrom.String, addrTo.String, amount[len(amount)-1]))
	amnt, err := strconv.ParseFloat(amount[len(amount)-1], 32)
	if err != nil {
		return "", errors.New("Invalid amount")
	}
	_, err = coind.SendCoins(addrTo.String, addrFrom.String, amnt, false)
	if err != nil {
		return "", err
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
	}(addrFrom.String, addrTo.String, amount[len(amount)-1])

	return fmt.Sprintf("User @%s tipped @%s %sXDN", username, ut, amount[len(amount)-1]), nil
	//return nil
}
