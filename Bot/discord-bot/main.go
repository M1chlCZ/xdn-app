package main

import (
	"database/sql"
	"discord-bot/misc"
	"encoding/json"
	_ "encoding/json"
	"fmt"
	"github.com/M1chlCZ/go-utils"
	"github.com/M1chlCZ/go-utils/coind"
	"github.com/M1chlCZ/go-utils/database"
	"github.com/bwmarrin/discordgo"
	"gopkg.in/errgo.v2/errors"
	"math/rand"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"
)

var (
	config *configStruct
)

const (
	MainChannelID = "469466166642081792"
)

func main() {
	utils.InitConfig("discord.log")
	database.New()
	StartDiscord()
}

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

func ReadConfigDiscord() error {
	utils.ReportMessage("Reading config file...")
	file, err := os.ReadFile("./config.json")

	if err != nil {
		utils.WrapErrorLog(err.Error())
		return err
	}
	err = json.Unmarshal(file, &config)

	if err != nil {
		utils.ReportMessage(err.Error())
		return err
	}

	return nil

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

func messageHandler(s *discordgo.Session, mes *discordgo.MessageCreate) {

	go func(m *discordgo.MessageCreate) {
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
				_, err = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipErrorEmbed("Tip unsuccessful", err.Error())})
				return
			}

			_, err = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipEmbed(discord["author"], discord["tipped"], discord["amount"], m.Author.AvatarURL("128"), m.Author.Username)})
			if err != nil {
				utils.WrapErrorLog(err.Error())
				return
			}
		} else if command == "rain" {
			discord, err, res := rainDiscord(m)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, err = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipErrorEmbed("Rain unsuccessful", err.Error())})
				return
			}
			mm, _ := s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{RainEmbed(discord)})
			create, d, err := finishRainDiscord(res, mm)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, _ = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipErrorEmbed("Rain unsuccessful", err.Error())})
				return
			}
			_, err = s.ChannelMessageEditEmbeds(d.ChannelID, d.ID, []*discordgo.MessageEmbed{RainFinishEmbed(create, m.Author.AvatarURL("128"), m.Author.Username)})
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, _ = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipErrorEmbed("Rain unsuccessful", err.Error())})
				return
			}
		} else {
			_, _ = s.ChannelMessageSend(m.ChannelID, "Unknown command")
		}
	}(mes)
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
	already2 := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users_bot WHERE token = ?", token)
	if already2.Valid {
		return errors.New("Already used same token for another social network")
	}

	idUser := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users WHERE tokenSocials = ?", token)
	if !idUser.Valid {
		misc.RegenerateTokenSocial(idUser.Int64)
		return errors.New("Invalid token")
	}

	_, err := database.InsertSQl("INSERT INTO users_bot (idUser, idSocial, token, typeBot, dName) VALUES (?, ?, ?, ?, ?)", idUser.Int64, from.Author.ID, token, 2, from.Author.Username)
	//_, err = database.InsertSQl("UPDATE users_bot SET dName = CONVERT(BINARY(CONVERT(? USING latin1)) USING utf8mb4) WHERE idSocial = ? ", from.Author.Username, from.Author.ID)
	if err != nil {
		return err
	}
	misc.RegenerateTokenSocial(idUser.Int64)
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
	misc.RegenerateTokenSocial(idUser.Int64)
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
	tx, err := coind.SendCoins(misc.DaemonWallet, addrTo.String, addrFrom.String, amnt, false)
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

func rainDiscord(from *discordgo.MessageCreate) (string, error, misc.RainReturnStruct) {
	if from.Author.Bot {
		return "", errors.New("Bots are not allowed"), misc.RainReturnStruct{}
	}
	str1 := strings.ReplaceAll(from.Message.Content, "@", "")
	str2 := from.Message.Content
	if (len(str2) - len(str1)) > 1 {
		return "", errors.New("Only one parameter is allowed"), misc.RainReturnStruct{}
	}
	if len(from.Mentions) > 1 {
		return "nil", errors.New("You can't rain on specific users, that's what tips are for"), misc.RainReturnStruct{}
	}

	//eg: 100XDN
	reg := regexp.MustCompile("\\s[0-9]+")
	am := reg.FindAllString(from.Message.Content, -1)
	if len(am) == 0 {
		return "", errors.New("Missing amount to tip"), misc.RainReturnStruct{}
	}
	if len(am) > 1 {
		return "", errors.New("You can specify only one amount to tip"), misc.RainReturnStruct{}
	}
	amount, err := strconv.ParseFloat(strings.TrimSpace(am[len(am)-1]), 32)
	if err != nil {
		return "", errors.New("Invalid amount to tip"), misc.RainReturnStruct{}
	}

	usrFrom := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE binary idSocial= ? AND typeBot = ?", from.Author.ID, 2)
	if !usrFrom.Valid {
		return "", errors.New("You are not registered in the bot db"), misc.RainReturnStruct{}
	}
	utils.ReportMessage(fmt.Sprintf("--- Rain from %s ---", from.Author.Username))
	ban := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users_bot WHERE idSocial = ? AND typeBot = ? AND ban = ?", from.Author.ID, 1, 1)
	if ban.Valid {
		return "", errors.New("You are banned from raining on Telegram"), misc.RainReturnStruct{}
	}
	usersTo, err := database.ReadArray[misc.UsrStruct](`SELECT a.addr as addr, b.idSocial as name FROM users  as a
												INNER JOIN users_bot  as b 
												ON a.id = b.idUser
												WHERE b.typeBot = 2 AND ban = 0`)
	if len(usersTo) == 0 {
		return "", errors.New("Can't find any users to tip"), misc.RainReturnStruct{}
	}
	usersToTip := make([]misc.UsrStruct, 0)
	numOfUsers := 0

	//eg: @100 people
	re := regexp.MustCompile("\\B@[0-9]+[^a-zA-Z]?$")
	m := re.FindAllString(from.Message.Content, -1)
	if len(m) != 0 {
		if len(m) > 1 {
			return "", errors.New("You can specify only one number of people to tip"), misc.RainReturnStruct{}
		}
		numOfUsers, err = strconv.Atoi(strings.ReplaceAll(m[0], "@", ""))
		if err != nil {
			return "", errors.New("Invalid number of people to tip"), misc.RainReturnStruct{}
		}

		if len(usersTo) < numOfUsers {
			return "", errors.New("Too many users to tip"), misc.RainReturnStruct{}
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
		return "", errors.New("Error getting user address #1"), misc.RainReturnStruct{}
	}

	_, _ = database.InsertSQl("UPDATE users_bot SET numberRained = numberRained+1 WHERE idUser = ?", usrFrom.Int64) //update number of rains

	addrTo := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM servers_stake WHERE 1")
	if !addrTo.Valid {
		return "", errors.New("Problem sending coins to rain service"), misc.RainReturnStruct{}
	}

	tx, err := coind.SendCoins(misc.DaemonWallet, addrTo.String, addrFrom.String, amount, false)
	if err != nil {
		return "", err, misc.RainReturnStruct{}
	}
	_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip Bot Rain", tx, "send")

	return fmt.Sprintf("Raining %.2f XDN on %d users", amount, numOfUsers), nil, misc.RainReturnStruct{
		UsrList:  usersToTip,
		Amount:   amount,
		AddrFrom: addrTo.String,
		Username: from.Author.ID,
		AddrSend: addrFrom.String,
	}

}
func finishRainDiscord(data misc.RainReturnStruct, m *discordgo.Message) (string, *discordgo.Message, error) {
	amountToUser := data.Amount / float64(len(data.UsrList))
	d := map[string]string{
		"fn": "sendTransaction",
	}
	finalUsrs := make([]misc.UsrStruct, 0)
	for _, v := range data.UsrList {
		tx, err := coind.SendCoins(misc.DaemonStakeWallet, v.Addr, data.AddrFrom, amountToUser, true)
		if err != nil {
			continue

		}
		finalUsrs = append(finalUsrs, v)
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip Bot Rain by: "+m.Author.Username+" on Discord", tx, "receive")
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
	for i, v := range finalUsrs {
		userString += "<@" + v.Name + ">"
		if i != 0 {
			userString += " "
		}
	}
	//create final message
	mes := fmt.Sprintf("User <@%s> rained on %s %s XDN each", data.Username, userString, strconv.FormatFloat(amountToUser, 'f', 2, 32))

	return mes, m, nil
}

func RainEmbed(message string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		Type:        "",
		Title:       "Rain in progress",
		Description: message,
		Timestamp:   timeString,
		Color:       0x00ff00,
		Footer:      nil,
		Image:       nil,
		Thumbnail:   nil,
		Video:       nil,
		Provider:    nil,
		Fields:      nil,
	}
	return &genericEmbed
}

func RainFinishEmbed(message, avatar, username string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		Type:        "",
		Title:       "Rain successfull",
		Description: message,
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

func TipErrorEmbed(error, title string) *discordgo.MessageEmbed {
	timeString := time.Now().Format(time.RFC3339)
	genericEmbed := discordgo.MessageEmbed{
		Type:        "",
		Title:       title,
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
