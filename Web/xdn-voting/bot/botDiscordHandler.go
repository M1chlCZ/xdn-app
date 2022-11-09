package bot

import (
	"database/sql"
	"fmt"
	"gopkg.in/errgo.v2/errors"
	"regexp"
	"strconv"
	"strings"
	"time"
	"xdn-voting/coind"
	"xdn-voting/database"
	"xdn-voting/utils"

	"github.com/bwmarrin/discordgo"
)

var (
	config *configStruct
)

type configStruct struct {
	Token     string `json:"Token"`
	BotPrefix string `json:"BotPrefix"`
}

var botID string
var _ *discordgo.Session

func StartDiscord() {
	err := ReadConfigDiscord()

	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	Setup()
	<-make(chan struct{})
	return
}

func Setup() {
	goBot, err := discordgo.New("Bot " + config.Token)

	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	u, err := goBot.User("@me")

	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	goBot.Identify.Intents = discordgo.IntentMessageContent | discordgo.IntentGuilds | discordgo.IntentsGuildPresences | discordgo.IntentGuildMessages | discordgo.IntentGuildMembers | discordgo.IntentGuildMessageReactions | discordgo.IntentDirectMessages | discordgo.IntentDirectMessageReactions

	botID = u.ID

	goBot.AddHandler(messageHandler)
	err = goBot.Open()

	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	utils.ReportMessage(fmt.Sprintf("Bot is running as %s Prefix: %s", u.Username, config.BotPrefix))
}

func messageHandler(s *discordgo.Session, m *discordgo.MessageCreate) {
	if m.Author.ID == botID {
		return
	}

	re := regexp.MustCompile("\\B\\$\\w+")
	comArray := re.FindAllString(m.Content, 1)
	if len(comArray) == 0 {
		return
	}
	command := strings.Replace(comArray[0], "$", "", 1)

	if command == "ping" {
		_, _ = s.ChannelMessageSend(m.ChannelID, "pong")
	} else if command == "connect" {
		content := strings.ReplaceAll(m.Message.Content, config.BotPrefix+"connect", "")
		utils.ReportMessage(fmt.Sprintf("Registering user %s", content))
		err := registerDiscord(strings.TrimSpace(content), m)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			_, err = s.ChannelMessageSend(m.ChannelID, err.Error())
			return
		}
		_, err = s.ChannelMessageSend(m.ChannelID, "Successfully registered...")
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
	} else if command == "unlink" {
		content := strings.ReplaceAll(m.Message.Content, config.BotPrefix+"unlink", "")
		utils.ReportMessage(fmt.Sprintf("Unlinking user %s", content))
		err := deregisterDiscord(m)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			_, err = s.ChannelMessageSend(m.ChannelID, "Unlink failed...")
			return
		}

		_, err = s.ChannelMessageSend(m.ChannelID, "Successfully unliked...")
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}

		//s.ChannelMessageEditEmbed(asd.ChannelID, asd.ID, "Unlink successful...")
	} else if command == "tip" {

		discord, err := tipDiscord(m)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			_, err = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipErrorEmbed(err.Error())})
			return
		}
		_, err = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipEmbed(discord["author"], discord["tipped"], discord["amount"], m.Author.AvatarURL("128"), m.Author.Username)})
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
	} else {
		_, _ = s.ChannelMessageSend(m.ChannelID, "Unknown command")
	}
}

func registerDiscord(token string, from *discordgo.MessageCreate) error {
	//check if user is bot
	if from.Author.Bot {
		return errors.New("Bot can't register")
	}
	if from.Author.Username == "" {
		return errors.New("Username is required")
	}

	already := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users_bot WHERE idSocial = ? AND typeBot = ?", from.Author.ID, 2)
	if already.Valid {
		return errors.New("Already registered")
	}

	idUser := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users WHERE tokenSocials = ?", token)
	if !idUser.Valid {
		RegenerateTokenSocial(idUser.Int64)
		return errors.New("Invalid token")
	}

	_, err := database.InsertSQl("INSERT INTO users_bot (idUser, idSocial, token, typeBot, dName) VALUES (?, ?, ?, ?, ?)", idUser.Int64, from.Author.ID, token, 2, from.Author.Username)
	if err != nil {
		return err
	}
	RegenerateTokenSocial(idUser.Int64)
	utils.ReportMessage(fmt.Sprintf("Registered user %s (uid: %d) to Discord bot", from.Author.Username, idUser.Int64))
	return nil
}

func deregisterDiscord(from *discordgo.MessageCreate) error {
	if from.Author.Bot {
		return errors.New("Bot can't register")
	}
	if from.Author.Username == "" {
		return errors.New("Username is required")
	}

	already := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users_bot WHERE idSocial = ?", from.Author.ID)
	if !already.Valid {
		return errors.New("Not seeing you in the database")
	}

	idUser := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ?", from.Author.ID)
	if !idUser.Valid {
		return errors.New("Not seeing you in the database")
	}

	_, err := database.InsertSQl("DELETE FROM users_bot WHERE id = ?", already.Int64)
	if err != nil {
		return errors.New("Error #5")
	}
	RegenerateTokenSocial(idUser.Int64)
	utils.ReportMessage(fmt.Sprintf("Unlinked user %s (uid: %d) from Discord", from.Author.Username, idUser.Int64))
	return nil
}

func tipDiscord(from *discordgo.MessageCreate) (map[string]string, error) {
	//check if user is bot
	if from.Author.Bot {
		return nil, errors.New("Bot can't tip")
	}
	if from.Author.Username == "" {
		return nil, errors.New("Username is required")
	}
	if len(from.Mentions) == 0 {
		return nil, errors.New("No user mentioned in tip command")
	}
	if len(from.Mentions) > 1 {
		return nil, errors.New("You can tip only one user")
	}

	author := from.Author.ID
	tippedUser := from.Mentions[0].ID
	reg := regexp.MustCompile("\\s[0-9]+")
	amount := reg.FindAllString(from.Message.Content, -1)

	utils.ReportMessage(fmt.Sprintf("Tipping user %s %s XDN on Discord", from.Mentions[0].Username, strings.TrimSpace(amount[len(amount)-1])))

	usrFrom := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial= ? AND typeBot = ?", author, 2)
	if !usrFrom.Valid {
		return nil, errors.New("You are not registered in the bot db")
	}
	usrTo := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ? AND typeBot = ?", strings.TrimSpace(tippedUser), 2)
	if !usrTo.Valid {
		return nil, errors.New("Mentioned user is not registered in the Discord bot db")
	}
	contactTO := database.ReadValueEmpty[sql.NullString]("SELECT name FROM addressbook WHERE idUser = ? AND addr = (SELECT addr FROM users WHERE id = (SELECT idUser FROM users_bot WHERE idSocial = ? ))", usrFrom, tippedUser)
	addrFrom := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM users WHERE id = ?", usrFrom.Int64)
	if !addrFrom.Valid {
		return nil, errors.New("Error getting user from address #1")
	}
	addrTo := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM users WHERE id = ?", usrTo.Int64)
	if !addrTo.Valid {
		return nil, errors.New("Error getting user to address #2")
	}
	utils.ReportMessage(fmt.Sprintf("From: %s, To: %s, Amount: %s", addrFrom.String, addrTo.String, strings.TrimSpace(amount[len(amount)-1])))
	amnt, err := strconv.ParseFloat(strings.TrimSpace(amount[len(amount)-1]), 32)
	if err != nil {
		return nil, errors.New("Invalid amount")
	}
	tx, err := coind.SendCoins(addrTo.String, addrFrom.String, amnt, false)
	if err != nil {
		return nil, err
	}
	if contactTO.Valid {
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip to: "+contactTO.String, tx, "send")
	} else {
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip to: "+strings.TrimSpace(tippedUser), tx, "send")
	}
	_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tipped by: "+author, tx, "receive")
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
	returnMap := map[string]string{
		"author": author,
		"tipped": tippedUser,
		"amount": amount[len(amount)-1],
	}
	utils.ReportMessage(fmt.Sprintf("User @%s tipped @%s%s XDN on Discord", from.Author.Username, from.Mentions[0].Username, amount[len(amount)-1]))
	return returnMap, nil
}

func TipEmbed(userFrom, userTo, amount, avatar, username string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		Type:        "",
		Title:       "Tip successful",
		Description: fmt.Sprintf("User <@%s> tipped <@%s> %s XDN", userFrom, userTo, amount),
		Timestamp:   timeString,
		Color:       0x00ff00,
		Footer:      nil,
		Image:       nil,
		Thumbnail:   nil,
		Video:       nil,
		Provider:    nil,
		Author: &discordgo.MessageEmbedAuthor{
			Name:    username,
			URL:     "",
			IconURL: avatar,
		},
		Fields: nil,
	}
	return &genericEmbed
}

func TipErrorEmbed(error string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		Type:        "",
		Title:       "Tip unsuccessful",
		Description: error,
		Timestamp:   timeString,
		Color:       0xEB0000,
		Footer:      nil,
		Image:       nil,
		Thumbnail:   nil,
		Video:       nil,
		Provider:    nil,
		Author: &discordgo.MessageEmbedAuthor{
			Name:    "XDN Tip Bot",
			URL:     "",
			IconURL: "https://cdn.discordapp.com/avatars/1038623597746458644/b4aa43e5d422bcc3b72e49d067d87f73.webp?size=160",
		},
		Fields: nil,
	}
	return &genericEmbed
}
