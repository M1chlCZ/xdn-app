package bot

import (
	"database/sql"
	"fmt"
	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
	"gopkg.in/errgo.v2/errors"
	"hash/maphash"
	"math/rand"
	"regexp"
	"strconv"
	"strings"
	"time"
	"xdn-voting/coind"
	"xdn-voting/database"
	"xdn-voting/models"
	"xdn-voting/utils"

	"github.com/bwmarrin/discordgo"
)

var (
	config *configStruct
)

const (
	MainChannelID = "469466166642081792"
	TestChannelID = "1033753700721754172"
	VIPChannelID  = "1033520774935498812"
)

type configStruct struct {
	Token     string `json:"Token"`
	BotPrefix string `json:"BotPrefix"`
}

var botID string
var goBot *discordgo.Session

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
	var err error
	goBot, err = discordgo.New("Bot " + config.Token)

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
	goBot.AddHandler(reactionAddHandler)
	goBot.AddHandler(reactionRemoveHandler)
	goBot.AddHandler(buttonHandler)
	err = goBot.Open()
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
}

func buttonHandler(s *discordgo.Session, i *discordgo.InteractionCreate) {
	switch i.Type {
	//case discordgo.InteractionApplicationCommand:
	//	if h, ok := commandsHandlers[i.ApplicationCommandData().Name]; ok {
	//		h(s, i)
	//	}
	case discordgo.InteractionMessageComponent:
		if h, ok := componentsHandlers[i.MessageComponentData().CustomID]; ok {
			h(s, i)
		}
	}
}

var (
	componentsHandlers = map[string]func(s *discordgo.Session, i *discordgo.InteractionCreate){
		"giftBot": giftBotHandler,
		"annBot":  annBotHandler,
	}
)

func reactionAddHandler(s *discordgo.Session, r *discordgo.MessageReactionAdd) {
	if strings.Contains(r.MessageReaction.Emoji.Name, "👍") {
		utils.ReportMessage("Added like")
	}
	if strings.Contains(r.MessageReaction.Emoji.Name, "👎") {
		utils.ReportMessage("Added dislike")
	}
}

func reactionRemoveHandler(s *discordgo.Session, r *discordgo.MessageReactionRemove) {
	if strings.Contains(r.MessageReaction.Emoji.Name, "👍") {
		utils.ReportMessage("Removed like")
	}
	if strings.Contains(r.MessageReaction.Emoji.Name, "👎") {
		utils.ReportMessage("Removed dislike")
	}
}

func messageHandler(s *discordgo.Session, mes *discordgo.MessageCreate) {
	go func(m *discordgo.MessageCreate) {
		if m.Author.ID == botID {
			return
		}
		re := regexp.MustCompile("^\\B\\$\\S*")
		comArray := re.FindAllString(m.Content, 1)
		if len(comArray) == 0 {
			return
		}
		command := strings.Replace(comArray[0], "$", "", 1)
		if command == "ping" {
			utils.ReportMessage(fmt.Sprintf("Pong! %s", m.ChannelID))
			_, _ = s.ChannelMessageSend(m.ChannelID, "pong")
		} else if command == "connect" {
			Running = true
			content := strings.ReplaceAll(m.Message.Content, config.BotPrefix+"connect", "")
			utils.ReportMessage(fmt.Sprintf("Registering user %s", content))
			err := registerDiscord(strings.TrimSpace(content), m)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, err = s.ChannelMessageSend(m.ChannelID, err.Error())
				Running = false
				return
			}
			_, err = s.ChannelMessageSend(m.ChannelID, "Successfully registered...")
			if err != nil {
				utils.WrapErrorLog(err.Error())
				Running = false
				return
			}
			Running = false
		} else if command == "unlink" {
			Running = true
			content := strings.ReplaceAll(m.Message.Content, config.BotPrefix+"unlink", "")
			utils.ReportMessage(fmt.Sprintf("Unlinking user %s", content))
			err := deregisterDiscord(m)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, err = s.ChannelMessageSend(m.ChannelID, "Unlink failed...")
				Running = false
				return
			}
			_, err = s.ChannelMessageSend(m.ChannelID, "Successfully unliked...")
			if err != nil {
				utils.WrapErrorLog(err.Error())
				Running = false
				return
			}
			Running = false
			//s.ChannelMessageEditEmbed(asd.ChannelID, asd.ID, "Unlink successful...")
		} else if command == "tip" {
			Running = true
			discord, err := tipDiscord(m)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, err = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipErrorEmbed("Tip unsuccessful", err.Error())})
				Running = false
				return
			}
			_, err = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipEmbed(discord["author"], discord["tipped"], discord["amount"], m.Author.AvatarURL("128"), m.Author.Username)})
			if err != nil {
				utils.WrapErrorLog(err.Error())
				Running = false
				return
			}
			Running = false
		} else if command == "grant" {
			Running = true
			discord, err := grantDiscord(m)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, err = s.ChannelMessageSend(m.ChannelID, err.Error())
				Running = false
				return
			}
			_, err = s.ChannelMessageSend(m.ChannelID, discord)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				Running = false
				return
			}
			Running = false
		} else if command == "deny" {
			Running = true
			discord, err := denyDiscord(m)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, err = s.ChannelMessageSend(m.ChannelID, err.Error())
				Running = false
				return
			}
			_, err = s.ChannelMessageSend(m.ChannelID, discord)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				Running = false
				return
			}
			Running = false
		} else if command == "ask" {
			Running = true
			discord, err := askDiscord(m)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, err = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipErrorEmbed("Question received unsuccessfully", err.Error())})
				Running = false
				return
			}
			_, err = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{AskEmbed(discord, "Question received successfully")})
			if err != nil {
				utils.WrapErrorLog(err.Error())
				Running = false
				return
			}
			Running = false
		} else if command == "rain" {
			Running = true
			discord, err, res := rainDiscord(m)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, err = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipErrorEmbed("Rain unsuccessful", err.Error())})
				Running = false
				return
			}
			mm, _ := s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{RainEmbed(discord)})
			create, d, err := finishRainDiscord(res, mm)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, _ = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipErrorEmbed("Rain unsuccessful", err.Error())})
				Running = false
				return
			}
			_, err = s.ChannelMessageEditEmbeds(d.ChannelID, d.ID, []*discordgo.MessageEmbed{RainFinishEmbed(create, m.Author.AvatarURL("128"), m.Author.Username)})
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, _ = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipErrorEmbed("Rain unsuccessful", err.Error())})
				Running = false
				return
			}
			Running = false
		} else if command == "thunder" {
			Running = true
			discord, err, res := thunderDiscord(m)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, err = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipErrorEmbed("Thunder unsuccessful", err.Error())})
				Running = false
				return
			}
			mm, _ := s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{ThunderEmbed(discord)})
			create, err := finishThunderDiscord(res)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, _ = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipErrorEmbed("Thunder unsuccessful", err.Error())})
				Running = false
				return
			}
			_, err = s.ChannelMessageEditEmbeds(mm.ChannelID, mm.ID, []*discordgo.MessageEmbed{ThunderFinishEmbed(create, m.Author.AvatarURL("128"), m.Author.Username)})
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_, _ = s.ChannelMessageSendEmbeds(m.ChannelID, []*discordgo.MessageEmbed{TipErrorEmbed("Thunder unsuccessful", err.Error())})
				Running = false
				return
			}
			Running = false
		} else {
			_, _ = s.ChannelMessageSend(m.ChannelID, "Unknown command")
			Running = false
		}
	}(mes)

}

func registerDiscord(token string, from *discordgo.MessageCreate) error {
	//check if user is bot
	if from.Author.Bot {
		return errors.New("Bot can't register")
	}
	if from.Author.Username == "" {
		return errors.New("UserID is required")
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
		RegenerateTokenSocial(idUser.Int64)
		return errors.New("Invalid token")
	}
	banned := database.ReadValueEmpty[int64]("SELECT banned FROM users WHERE id = ?", idUser)
	if banned == 1 {
		return errors.New("You are banned")
	}
	_, err := database.InsertSQl("INSERT INTO users_bot (idUser, idSocial, token, typeBot, dName) VALUES (?, ?, ?, ?, ?)", idUser.Int64, from.Author.ID, token, 2, from.Author.Username)
	//_, err = database.InsertSQl("UPDATE users_bot SET dName = CONVERT(BINARY(CONVERT(? USING latin1)) USING utf8mb4) WHERE idSocial = ? ", from.Author.UserID, from.Author.ID)
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
		return errors.New("UserID is required")
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
		return nil, errors.New("UserID is required")
	}
	if len(from.Mentions) == 0 {
		return nil, errors.New("No user mentioned in tip command")
	}
	if len(from.Mentions) > 1 {
		return nil, errors.New("You can tip only one user")
	}

	author := from.Author.ID
	tippedUser := from.Mentions[0].ID
	if author == tippedUser {
		return nil, errors.New("You can't tip yourself")
	}
	reg := regexp.MustCompile("\\s[0-9.]+")
	amount := reg.FindAllString(from.Message.Content, -1)

	utils.ReportMessage(fmt.Sprintf("Tipping user %s %s XDN on Discord in channel %s", from.Mentions[0].Username, strings.TrimSpace(amount[len(amount)-1]), from.ChannelID))

	usrFrom := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial= ? AND typeBot = ?", author, 2)
	if !usrFrom.Valid {
		return nil, errors.New("You are not registered in the bot db")
	}
	usrTo := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ? AND typeBot = ?", strings.TrimSpace(tippedUser), 2)
	if !usrTo.Valid {
		return nil, errors.New("Mentioned user is not registered in the Discord bot db")
	}
	banned := database.ReadValueEmpty[int64]("SELECT banned FROM users WHERE id = ?", usrFrom.Int64)
	if banned == 1 {
		return nil, errors.New("You are banned")
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
	_, err = database.InsertSQl("INSERT INTO uses_bot_activity (idUser, amount, type, idSocial, idChannel) VALUES (?, ?, ?, ?, ?)", usrFrom.Int64, amnt, 2, 1, from.ChannelID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}

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

func grantDiscord(from *discordgo.MessageCreate) (string, error) {
	//check if user is bot
	if from.Author.Bot {
		return "", errors.New("Bot can't tip")
	}
	if from.Author.Username == "" {
		return "", errors.New("UserID is required")
	}
	if len(from.Mentions) == 0 {
		return "", errors.New("No user mentioned in grand command")
	}
	if len(from.Mentions) > 1 {
		return "", errors.New("You can grant only one user")
	}

	author := from.Author.ID
	usrFrom := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial= ? AND typeBot = ?", author, 2)
	if !usrFrom.Valid {
		return "", errors.New("You are not registered in the bot db")
	}
	banned := database.ReadValueEmpty[int64]("SELECT banned FROM users WHERE id = ?", usrFrom.Int64)
	if banned == 1 {
		return "", errors.New("You are banned")
	}
	ustPermission := database.ReadValueEmpty[int64]("SELECT admin FROM users WHERE id = ?", usrFrom.Int64)
	if ustPermission == 0 {
		return "", errors.New("You don't have permission to grant other users access to MN service")
	}

	tippedUser := from.Mentions[0].ID
	textAfterTime := ""

	regLength := 0

	regdays := regexp.MustCompile(`\S+(?i)days`)
	days := regdays.FindAllString(from.Content, -1)
	if len(days) != 0 {
		s := strings.ReplaceAll(days[0], "days", "")
		regLength, _ = strconv.Atoi(s)
		textAfterTime = strings.ReplaceAll(from.Content, days[0], "")
	}

	regMonths := regexp.MustCompile(`\S+(?i)months`)
	months := regMonths.FindAllString(from.Content, -1)
	if len(months) != 0 {
		s := strings.ReplaceAll(months[0], "months", "")
		regLength, _ = strconv.Atoi(s)
		regLength = regLength * 30
		textAfterTime = strings.ReplaceAll(from.Content, months[0], "")
	}

	regYear := regexp.MustCompile(`\S+(?i)years`)
	years := regYear.FindAllString(from.Content, -1)
	if len(years) != 0 {
		s := strings.ReplaceAll(years[0], "years", "")
		regLength, _ = strconv.Atoi(s)
		regLength = regLength * 365
		utils.ReportMessage(years[0])
		textAfterTime = strings.ReplaceAll(from.Content, years[0], "")
	}

	if regLength == 0 {
		return "", errors.New("Invalid subscription period")
	}

	//calculate date for subscription in SQL format
	t := time.Now()
	t = t.AddDate(0, 0, regLength)
	date := t.Format("2006-01-02 15:04:05")
	utils.ReportMessage(strings.TrimSpace(textAfterTime))
	reg := regexp.MustCompile(`\S[a-zA-Z]+[^a-zA-Z]?$`)
	tier := reg.FindAllString(textAfterTime, -1)
	if len(tier) == 0 {
		return "", errors.New("You must specify tier")
	}
	if len(tier) > 1 {
		return "", errors.New("You can specify only one tier")
	}
	tierName := strings.TrimSpace(tier[0])
	if tierName != "bronze" && tierName != "silver" && tierName != "gold" && tierName != "smartnode" {
		return "", errors.New("Invalid tier name")
	}

	utils.ReportMessage(fmt.Sprintf("Granting access to user %s on Discord with tier %s for %d days", from.Mentions[0].Username, tierName, regLength))

	usrTo := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ? AND typeBot = ?", strings.TrimSpace(tippedUser), 2)
	if !usrTo.Valid {
		return "", errors.New("Mentioned user is not registered in the Discord bot db")
	}
	//check if user is in users_permission
	tierNum := 0
	numAddr := 0
	switch tierName {
	case "bronze":
		tierNum = 2
		numAddr = 2
	case "silver":
		tierNum = 5
		numAddr = 5
	case "gold":
		tierNum = 25
		numAddr = 1000
	case "smartnode":
		tierNum = 1
		numAddr = 50
	default:
		return "", errors.New("Invalid tier")
	}
	check := database.ReadValueEmpty[bool]("SELECT EXISTS( SELECT idUser FROM users_permission WHERE idUser = ?)", usrTo.Int64)
	if check == false {
		_, err := database.InsertSQl("INSERT INTO users_permission (idUser, mn, stealth, dateEnd) VALUES (?, ?, ?, ?)", usrTo.Int64, tierNum, numAddr, date)
		if tierName == "smartnode" {
			type nodes struct {
				IDNode int64 `db:"idNode"`
			}
			var empty nodes
			mnZero, err := database.ReadStruct[nodes]("SELECT idNode FROM users_mn WHERE idUser = ? AND active = 1 ORDER BY RAND() LIMIT 1", 0)
			if err != nil {
				return "", err
			}
			if mnZero == empty {
				return "", errors.New("No free smartnodes available")
			}
			futureTime := time.Now().AddDate(2, 0, 0).Format("2006-01-02 15:04:05")
			_, err = database.InsertSQl("UPDATE users_mn SET idUser = ? WHERE idNode = ?", usrTo.Int64, mnZero.IDNode)
			_, err = database.InsertSQl("UPDATE users_mn SET dateStart = ? WHERE idNode = ?", futureTime, mnZero.IDNode)
			if err != nil {
				return "", err
			}

		}

		if err != nil {
			return "", err
		}
		return fmt.Sprintf("User %s has been granted with access to MN service with %s tier for %d days", from.Mentions[0].Username, tierName, regLength), nil
	} else {
		if tierName == "smartnode" {
			_, _ = database.InsertSQl("UPDATE users_permission SET mn = mn + 1 WHERE idUser = ?", usrTo.Int64)
			_, _ = database.InsertSQl("UPDATE users_permission SET dateEnd = ? WHERE idUser = ?", date, usrTo.Int64)
			return fmt.Sprintf("User %s got added 1 Smartnode to their account for %d days", from.Mentions[0].Username, regLength), nil
		} else {
			_, _ = database.InsertSQl("UPDATE users_permission SET mn = ? WHERE idUser = ?", tierNum, usrTo.Int64)
			_, _ = database.InsertSQl("UPDATE users_permission SET stealth = ? WHERE idUser = ?", numAddr, usrTo.Int64)
			_, _ = database.InsertSQl("UPDATE users_permission SET dateEnd = ? WHERE idUser = ?", date, usrTo.Int64)
			return fmt.Sprintf("User %s got changed MN tier to %s for lenght of %d days", from.Mentions[0].Username, tierName, regLength), nil
		}

	}
}

func denyDiscord(from *discordgo.MessageCreate) (string, error) {
	//check if user is bot
	if from.Author.Bot {
		return "", errors.New("Bot can't tip")
	}
	if from.Author.Username == "" {
		return "", errors.New("UserID is required")
	}
	if len(from.Mentions) == 0 {
		return "", errors.New("No user mentioned in grand command")
	}
	if len(from.Mentions) > 1 {
		return "", errors.New("You can grant only one user")
	}

	author := from.Author.ID
	usrFrom := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial= ? AND typeBot = ?", author, 2)
	if !usrFrom.Valid {
		return "", errors.New("You are not registered in the bot db")
	}
	ustPermission := database.ReadValueEmpty[int64]("SELECT admin FROM users WHERE id = ?", usrFrom.Int64)
	if ustPermission == 0 {
		return "", errors.New("You don't have permission to deny other users access to MN service")
	}

	tippedUser := from.Mentions[0].ID

	utils.ReportMessage(fmt.Sprintf("Deniyng access to user %s on Discord", from.Mentions[0].Username))

	usrTo := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ? AND typeBot = ?", strings.TrimSpace(tippedUser), 2)
	if !usrTo.Valid {
		return "", errors.New("Mentioned user is not registered in the Discord bot db")
	}
	//check if user is in users_permission
	check := database.ReadValueEmpty[bool]("SELECT EXISTS( SELECT idUser FROM users_permission WHERE idUser = ?)", usrTo.Int64)
	if check == true {
		_, err := database.InsertSQl("DELETE FROM users_permission WHERE idUser = ?", usrTo.Int64)
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("User %s has been denied with access to MN service", from.Mentions[0].Username), nil
	} else {
		return fmt.Sprintf("User %s does not have privileges for MN service", from.Mentions[0].Username), nil
	}
}

func rainDiscord(from *discordgo.MessageCreate) (string, error, RainReturnStruct) {
	if from.Author.Bot {
		return "", errors.New("Bots are not allowed"), RainReturnStruct{}
	}
	str1 := strings.ReplaceAll(from.Message.Content, "@", "")
	str2 := from.Message.Content
	if (len(str2) - len(str1)) > 1 {
		return "", errors.New("Only one parameter is allowed"), RainReturnStruct{}
	}
	if len(from.Mentions) > 1 {
		return "nil", errors.New("You can't rain on specific users, that's what tips are for"), RainReturnStruct{}
	}

	//eg: 100XDN
	reg := regexp.MustCompile("\\s[0-9.]+")
	am := reg.FindAllString(from.Message.Content, -1)
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
	if amount < 0.0001 {
		return "", errors.New("Amount is too small"), RainReturnStruct{}
	}

	usrFrom := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE binary idSocial= ? AND typeBot = ?", from.Author.ID, 2)
	if !usrFrom.Valid {
		return "", errors.New("You are not registered in the bot db"), RainReturnStruct{}
	}
	banned := database.ReadValueEmpty[int64]("SELECT banned FROM users WHERE id = ?", usrFrom.Int64)
	if banned == 1 {
		return "", errors.New("You are banned"), RainReturnStruct{}
	}
	utils.ReportMessage(fmt.Sprintf("--- Rain from %s ---", from.Author.Username))
	ban := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users_bot WHERE idSocial = ? AND typeBot = ? AND ban = ?", from.Author.ID, 1, 1)
	if ban.Valid {
		return "", errors.New("You are banned from raining on Telegram"), RainReturnStruct{}
	}
	usersTo, err := database.ReadArray[UsrStruct](`SELECT a.addr as addr, b.idSocial as name FROM users  as a
												INNER JOIN users_bot  as b 
												ON a.id = b.idUser
												WHERE b.typeBot = 2 AND ban = 0`)
	if len(usersTo) == 0 {
		return "", errors.New("Can't find any users to tip"), RainReturnStruct{}
	}
	usersToTip := make([]UsrStruct, 0)
	numOfUsers := 0

	//eg: @100 people
	re := regexp.MustCompile("\\B@[0-9]+[^a-zA-Z]?$")
	m := re.FindAllString(from.Message.Content, -1)
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

	_, _ = database.InsertSQl("UPDATE users_bot SET numberRained = numberRained+1 WHERE idUser = ?", usrFrom.Int64) //update number of rains

	addrTo := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM servers_stake WHERE 1")
	if !addrTo.Valid {
		return "", errors.New("Problem sending coins to rain service"), RainReturnStruct{}
	}

	tx, err := coind.SendCoins(addrTo.String, addrFrom.String, amount, false)
	if err != nil {
		return "", err, RainReturnStruct{}
	}
	_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip Bot Rain", tx, "send")
	_, err = database.InsertSQl("INSERT INTO uses_bot_activity (idUser, amount, type, idSocial, idChannel) VALUES (?, ?, ?, ?, ?)", usrFrom.Int64, amount, 0, 1, from.ChannelID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}

	return fmt.Sprintf("Raining %.2f XDN on %d users", amount, numOfUsers), nil, RainReturnStruct{
		UsrList:  usersToTip,
		Amount:   amount,
		AddrFrom: addrTo.String,
		UserID:   from.Author.ID,
		AddrSend: addrFrom.String,
	}

}

func finishRainDiscord(data RainReturnStruct, m *discordgo.Message) (string, *discordgo.Message, error) {
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
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip Bot Rain by: "+m.Author.Username+" on Discord", tx, "receive")
		utils.ReportMessage(fmt.Sprintf("Rain, Sent %f XDN to %s", amountToUser, v.Addr))
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
	mes := fmt.Sprintf("User <@%s> rained on %s %s XDN each", data.UserID, userString, strconv.FormatFloat(amountToUser, 'f', 2, 32))

	return mes, m, nil
}

func showThunderMessage(message string, d *discordgo.Message) {
	user, err := goBot.User(d.Author.ID)
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("Get USER %s", err.Error()))
		return
	}
	_, err = goBot.ChannelMessageSendEmbeds(d.ChannelID, []*discordgo.MessageEmbed{ThunderFinishEmbed(message, user.AvatarURL("160"), user.Username)})
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
}

func thunderDiscord(from *discordgo.MessageCreate) (string, error, ThunderReturnStruct) {
	if from.Author.Bot {
		return "", errors.New("Bots are not allowed"), ThunderReturnStruct{}
	}
	str1 := strings.ReplaceAll(from.Message.Content, "@", "")
	str2 := from.Message.Content
	if (len(str2) - len(str1)) > 1 {
		return "", errors.New("Only one parameter is allowed"), ThunderReturnStruct{}
	}
	if len(from.Mentions) > 1 {
		return "nil", errors.New("You can't rain on specific users, that's what tips are for"), ThunderReturnStruct{}
	}

	//eg: 100XDN
	reg := regexp.MustCompile("\\s[0-9.]+")
	am := reg.FindAllString(from.Message.Content, -1)
	if len(am) == 0 {
		return "", errors.New("Missing amount to tip"), ThunderReturnStruct{}
	}
	if len(am) > 1 {
		return "", errors.New("You can specify only one amount to tip"), ThunderReturnStruct{}
	}
	amount, err := strconv.ParseFloat(strings.TrimSpace(am[len(am)-1]), 32)
	if err != nil {
		return "", errors.New("Invalid amount to tip"), ThunderReturnStruct{}
	}
	if amount < 0.0001 {
		return "", errors.New("Amount is too small"), ThunderReturnStruct{}
	}

	usrFrom := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial= ? AND typeBot = ?", from.Author.ID, 2)
	if !usrFrom.Valid {
		return "", errors.New("You are not registered in the bot db"), ThunderReturnStruct{}
	}
	banned := database.ReadValueEmpty[int64]("SELECT banned FROM users WHERE id = ?", usrFrom.Int64)
	if banned == 1 {
		return "", errors.New("You are banned"), ThunderReturnStruct{}
	}
	utils.ReportMessage(fmt.Sprintf("--- Rain from %s ---", from.Author.Username))
	ban := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users_bot WHERE idSocial = ? AND typeBot = ? AND ban = ?", from.Author.ID, 1, 1)
	if ban.Valid {
		return "", errors.New("You are banned from raining on Discord"), ThunderReturnStruct{}
	}
	usersTo, err := database.ReadArray[UsrStruct](`SELECT a.addr as addr, b.idSocial as name FROM users  as a
												INNER JOIN users_bot  as b 
												ON a.id = b.idUser
												WHERE b.typeBot = 2 AND ban = 0`)
	if len(usersTo) == 0 {
		return "", errors.New("Can't find any users to tip"), ThunderReturnStruct{}
	}
	usersToTip := make([]UsrStructThunder, 0)
	telegramFinalSlice := make([]UsrStruct, 0)
	discordFinalSlice := make([]UsrStruct, 0)
	numOfUsers := 0

	//eg: @100 people
	re := regexp.MustCompile("\\B@[0-9]+[^a-zA-Z]?$")
	m := re.FindAllString(from.Message.Content, -1)
	if len(m) != 0 {
		utils.ReportMessage("Thunder by number")
		if len(m) > 1 {
			return "", errors.New("You can specify only one number of people to tip"), ThunderReturnStruct{}
		}
		numOfUsers, err = strconv.Atoi(strings.ReplaceAll(m[0], "@", ""))
		if err != nil {
			return "", errors.New("Invalid number of people to tip"), ThunderReturnStruct{}
		}

		usrTL, err := database.ReadArray[UsrStructThunder](`SELECT ANY_VALUE(a.idSocial) as name, ANY_VALUE(a.typeBot) as typeBot, b.addr as addr from users_bot a, users b WHERE a.idUser = b.id 
		AND idUser IN  (SELECT idUser  FROM users_bot AS t1 JOIN (SELECT id FROM users_bot ORDER BY RAND()) as t2 ON t1.id=t2.id) 
		GROUP BY a.idUser
		`)
		if err != nil {
			return "", errors.New("Error getting users"), ThunderReturnStruct{}
		}

		if len(usrTL) < numOfUsers {
			return "", errors.New("Too many users to tip"), ThunderReturnStruct{}
		}

		//shuffle usrFrom
		r := rand.New(rand.NewSource(int64(new(maphash.Hash).Sum64())))
		r.Shuffle(len(usrTL), func(i, j int) { usrTL[i], usrTL[j] = usrTL[j], usrTL[i] })
		r2 := rand.New(rand.NewSource(int64(new(maphash.Hash).Sum64())))
		r2.Shuffle(len(usrTL), func(i, j int) { usrTL[i], usrTL[j] = usrTL[j], usrTL[i] })
		//random select numOfUser from usrFrom
		for i := 0; i < numOfUsers; i++ {
			usersToTip = append(usersToTip, usrTL[i])
		}

		for i := 0; i < numOfUsers; i++ {
			if usrTL[i].TypeBot == 1 {
				telegramFinalSlice = append(telegramFinalSlice, UsrStruct{
					Addr: usrTL[i].Addr,
					Name: usrTL[i].Name,
				})
			} else {
				discordFinalSlice = append(discordFinalSlice, UsrStruct{
					Addr: usrTL[i].Addr,
					Name: usrTL[i].Name,
				})
			}
		}
	} else {
		utils.ReportMessage("Thunder by all")

		usrTL, err := database.ReadArray[UsrStructThunder](`SELECT ANY_VALUE(a.idSocial) as name, ANY_VALUE(a.typeBot) as typeBot, b.addr as addr from users_bot a, users b WHERE a.idUser = b.id 
		AND idUser IN  (SELECT idUser  FROM users_bot AS t1 JOIN (SELECT id FROM users_bot ORDER BY RAND()) as t2 ON t1.id=t2.id) 
		GROUP BY a.idUser`)
		if err != nil {
			return "", errors.New("Error getting users"), ThunderReturnStruct{}
		}

		for i := 0; i < len(usrTL); i++ {
			if usrTL[i].TypeBot == 1 {
				telegramFinalSlice = append(telegramFinalSlice, UsrStruct{
					Addr: usrTL[i].Addr,
					Name: usrTL[i].Name,
				})
			} else {
				discordFinalSlice = append(discordFinalSlice, UsrStruct{
					Addr: usrTL[i].Addr,
					Name: usrTL[i].Name,
				})
			}
		}
		numOfUsers = len(usrTL)
	}

	//send coins to stake wallet
	addrFrom := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM users WHERE id = ?", usrFrom.Int64)
	if !addrFrom.Valid {
		return "", errors.New("Error getting user address #1"), ThunderReturnStruct{}
	}

	_, _ = database.InsertSQl("UPDATE users_bot SET numberRained = numberRained+1 WHERE idUser = ?", usrFrom.Int64) //update number of rains

	addrTo := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM servers_stake WHERE 1")
	if !addrTo.Valid {
		return "", errors.New("Problem sending coins to rain service"), ThunderReturnStruct{}
	}

	tx, err := coind.SendCoins(addrTo.String, addrFrom.String, amount, false)
	if err != nil {
		return "", err, ThunderReturnStruct{}
	}
	_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip Bot Rain", tx, "send")

	_, err = database.InsertSQl("INSERT INTO uses_bot_activity (idUser, amount, type, idSocial, idChannel) VALUES (?, ?, ?, ?, ?)", usrFrom.Int64, amount, 1, 1, from.ChannelID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	return fmt.Sprintf("Raining %.2f XDN on %d users", amount, numOfUsers), nil, ThunderReturnStruct{
		UsrListDiscord:  discordFinalSlice,
		UsrListTelegram: telegramFinalSlice,
		Amount:          amount,
		AddrFrom:        addrTo.String,
		Username:        from.Author.Username,
		AddrSend:        addrFrom.String,
	}
}

func finishThunderDiscord(data ThunderReturnStruct) (string, error) {
	numberOfUsers := len(data.UsrListTelegram) + len(data.UsrListDiscord)
	amountTelegram := (data.Amount / float64(numberOfUsers)) * float64(len(data.UsrListTelegram))
	amountDiscord := (data.Amount / float64(numberOfUsers)) * float64(len(data.UsrListDiscord))

	telegramResponse := ""
	var telegramError error
	if len(data.UsrListTelegram) != 0 {
		telegramResponse, telegramError = finishRain(RainReturnStruct{
			UsrList:  data.UsrListTelegram,
			Amount:   amountTelegram,
			AddrFrom: data.AddrFrom,
			UserID:   data.Username,
			AddrSend: data.AddrSend,
		})
	}
	discordMessage := ""
	if len(data.UsrListDiscord) != 0 {
		idUser := database.ReadValueEmpty[int64]("SELECT idUser FROM users_bot WHERE binary idSocial = ?", data.Username)
		discordUserID := database.ReadValueEmpty[string]("SELECT idSocial FROM users_bot WHERE idUser = ? AND typeBot = 2", idUser)
		discordUserName := database.ReadValueEmpty[string]("SELECT dname FROM users_bot WHERE id = ? AND typeBot = 2", idUser)
		utils.ReportMessage(fmt.Sprintf("Discord username: %s", discordUserID))

		a, _, c := finishRainDiscord(RainReturnStruct{
			UsrList:  data.UsrListDiscord,
			Amount:   amountDiscord,
			AddrFrom: data.AddrFrom,
			UserID:   discordUserID,
			AddrSend: data.AddrSend,
		}, &discordgo.Message{
			ID:        discordUserID,
			ChannelID: MainChannelID,
			Timestamp: time.Time{},
			Author:    &discordgo.User{Username: discordUserName, ID: discordUserID},
		})
		if c != nil {
			utils.WrapErrorLog(c.Error())
		} else {
			t := strings.ReplaceAll(telegramResponse, "rained", "brought Thunder")
			showDiscordTelegramThunder(t)
		}
		discordMessage = strings.ReplaceAll(a, "rained", "brought Thunder")
	}

	return discordMessage, telegramError
}

func AnnouncementDiscord() {
	LoadPictures()
	lastPost, err := database.ReadStruct[ActivityBotStruct]("SELECT * FROM bot_post_activity WHERE idPost IN (SELECT id FROM bot_post WHERE category = 0) AND idChannel = ? ORDER BY id DESC LIMIT 1", MainChannelID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	if lastPost.Id != 0 {
		err := goBot.ChannelMessageDelete(fmt.Sprintf("%d", lastPost.IdChannel), fmt.Sprintf("%d", lastPost.IdMessage))
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}

	}
	post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 0 ORDER BY RAND() LIMIT 1")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	messageBold := strings.ReplaceAll(post.Message, "*", "**")

	url := ""
	if post.Picture.Valid {
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", post.Picture.String)
	} else {
		randNum := utils.RandNum(len(PictureANN))
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=3", randNum)
	}
	buttons := []discordgo.MessageComponent{
		discordgo.ActionsRow{
			Components: []discordgo.MessageComponent{
				discordgo.Button{
					Emoji: discordgo.ComponentEmoji{
						Name: "👍🏻",
					},
					Label:    "Like",
					Style:    discordgo.SuccessButton,
					CustomID: "annBot",
				},
			},
		},
	}
	//
	messageSend := discordgo.MessageSend{
		Content:         "",
		Embeds:          []*discordgo.MessageEmbed{AnnEmbed("", messageBold, "XDN Announce Bot", url)},
		TTS:             false,
		Components:      buttons,
		Files:           nil,
		AllowedMentions: nil,
		Reference:       nil,
		File:            nil,
		Embed:           nil,
	}

	msg, err := goBot.ChannelMessageSendComplex(MainChannelID, &messageSend)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	//msg, err := goBot.ChannelMessageSendEmbeds(MainChannelID, []*discordgo.MessageEmbed{AnnEmbed("", messageBold, "XDN Announce Bot", url)})
	//if err != nil {
	//	utils.WrapErrorLog(err.Error())
	//	return
	//}
	////_, err = goBot.ChannelMessageSendEmbeds(MainChannelID, []*discordgo.MessageEmbed{AnnEmbed("", "If you want to be notified when we post a new announcement, please react with :white_check_mark: to this message.", "XDN Announce Bot", url)})
	//
	//go func(cID, mID string) {
	//	time.Sleep(2 * time.Second)
	//	err := goBot.MessageReactionAdd(cID, mID, "👍")
	//	if err != nil {
	//		utils.WrapErrorLog(err.Error())
	//	}
	//}(msg.ChannelID, msg.ID)

	channelID, ko := strconv.Atoi(msg.ChannelID)
	messageID, ko := strconv.Atoi(msg.ID)
	if ko != nil {
		utils.WrapErrorLog("Error converting string to int")
	} else {
		_, err = database.InsertSQl("INSERT INTO bot_post_activity (idPost, idMessage, idChannel) VALUES (?,?,?)", post.PostID, messageID, channelID)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
	}
}

func AnnouncementMNDiscord() {
	LoadPictures()
	lastPost, err := database.ReadStruct[ActivityBotStruct]("SELECT * FROM bot_post_activity WHERE idPost IN (SELECT id FROM bot_post WHERE category = 3) AND idChannel = ? ORDER BY id DESC LIMIT 1", MainChannelID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	if lastPost.Id != 0 {
		err := goBot.ChannelMessageDelete(fmt.Sprintf("%d", lastPost.IdChannel), fmt.Sprintf("%d", lastPost.IdMessage))
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}

	}
	post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 3 ORDER BY RAND() LIMIT 1")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	messageBold := strings.ReplaceAll(post.Message, "*", "**")

	url := ""
	if post.Picture.Valid {
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", post.Picture.String)
	} else {
		randNum := utils.RandNum(len(PictureANN))
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=3", randNum)
	}
	buttons := []discordgo.MessageComponent{
		discordgo.ActionsRow{
			Components: []discordgo.MessageComponent{
				discordgo.Button{
					Emoji: discordgo.ComponentEmoji{
						Name: "👍🏻",
					},
					Label:    "Like",
					Style:    discordgo.SuccessButton,
					CustomID: "annBot",
				},
			},
		},
	}
	//
	messageSend := discordgo.MessageSend{
		Content:         "",
		Embeds:          []*discordgo.MessageEmbed{AnnEmbed("", messageBold, "XDN Announce Bot", url)},
		TTS:             false,
		Components:      buttons,
		Files:           nil,
		AllowedMentions: nil,
		Reference:       nil,
		File:            nil,
		Embed:           nil,
	}

	msg, err := goBot.ChannelMessageSendComplex(MainChannelID, &messageSend)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	channelID, ko := strconv.Atoi(msg.ChannelID)
	messageID, ko := strconv.Atoi(msg.ID)
	if ko != nil {
		utils.WrapErrorLog("Error converting string to int")
	} else {
		_, err = database.InsertSQl("INSERT INTO bot_post_activity (idPost, idMessage, idChannel) VALUES (?,?,?)", post.PostID, messageID, channelID)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
	}
}

func AnnouncementOtherDiscord() {
	LoadPictures()
	channels, err := database.ReadArrayStruct[models.Channel]("SELECT idChannel FROM uses_bot_activity WHERE idChannel > 0 AND idChannel !=? AND idChannel !=? AND idChannel !=? GROUP BY idChannel", TestChannelID, MainChannelID, VIPChannelID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	for _, channel := range channels {
		lastPost, err := database.ReadStruct[ActivityBotStruct]("SELECT * FROM bot_post_activity WHERE idPost IN (SELECT id FROM bot_post WHERE category = 0) AND idChannel = ? ORDER BY id DESC LIMIT 1", channel.IdChannel)
		if err != nil {
			utils.WrapErrorLog(err.Error())

			if lastPost.Id != 0 {
				dl := tgbotapi.NewDeleteMessage(lastPost.IdChannel, int(lastPost.IdMessage))
				_, err := bot.Send(dl)
				if err != nil {
					utils.ReportMessage(err.Error())
				}
			}
		}
		post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 0 ORDER BY RAND() LIMIT 1")
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		messageBold := strings.ReplaceAll(post.Message, "*", "**")

		url := ""
		if post.Picture.Valid {
			url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", post.Picture.String)
		} else {
			randNum := utils.RandNum(len(PictureANN))
			url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=3", randNum)
		}
		buttons := []discordgo.MessageComponent{
			discordgo.ActionsRow{
				Components: []discordgo.MessageComponent{
					discordgo.Button{
						Emoji: discordgo.ComponentEmoji{
							Name: "👍🏻",
						},
						Label:    "Like",
						Style:    discordgo.SuccessButton,
						CustomID: "annBot",
					},
				},
			},
		}
		//
		messageSend := discordgo.MessageSend{
			Content:         "",
			Embeds:          []*discordgo.MessageEmbed{AnnEmbed("", messageBold, "XDN Announce Bot", url)},
			TTS:             false,
			Components:      buttons,
			Files:           nil,
			AllowedMentions: nil,
			Reference:       nil,
			File:            nil,
			Embed:           nil,
		}

		msg, err := goBot.ChannelMessageSendComplex(fmt.Sprintf("%d", channel.IdChannel), &messageSend)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}

		channelID, ko := strconv.Atoi(msg.ChannelID)
		messageID, ko := strconv.Atoi(msg.ID)
		if ko != nil {
			utils.WrapErrorLog("Error converting string to int")
		} else {
			_, err = database.InsertSQl("INSERT INTO bot_post_activity (idPost, idMessage, idChannel) VALUES (?,?,?)", post.PostID, messageID, channelID)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
		}
	}
}

func AnnouncementMNOtherDiscord() {
	LoadPictures()
	channels, err := database.ReadArrayStruct[models.Channel]("SELECT idChannel FROM uses_bot_activity WHERE idChannel > 0 AND idChannel !=? AND idChannel !=? AND idChannel !=? GROUP BY idChannel", TestChannelID, MainChannelID, VIPChannelID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	for _, channel := range channels {
		lastPost, err := database.ReadStruct[ActivityBotStruct]("SELECT * FROM bot_post_activity WHERE idPost IN (SELECT id FROM bot_post WHERE category = 3) AND idChannel = ? ORDER BY id DESC LIMIT 1", channel.IdChannel)
		if err != nil {
			utils.WrapErrorLog(err.Error())

			if lastPost.Id != 0 {
				dl := tgbotapi.NewDeleteMessage(lastPost.IdChannel, int(lastPost.IdMessage))
				_, err := bot.Send(dl)
				if err != nil {
					utils.ReportMessage(err.Error())
				}
			}
		}
		post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 3 ORDER BY RAND() LIMIT 1")
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		messageBold := strings.ReplaceAll(post.Message, "*", "**")

		url := ""
		if post.Picture.Valid {
			url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", post.Picture.String)
		} else {
			randNum := utils.RandNum(len(PictureANN))
			url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=3", randNum)
		}
		buttons := []discordgo.MessageComponent{
			discordgo.ActionsRow{
				Components: []discordgo.MessageComponent{
					discordgo.Button{
						Emoji: discordgo.ComponentEmoji{
							Name: "👍🏻",
						},
						Label:    "Like",
						Style:    discordgo.SuccessButton,
						CustomID: "annBot",
					},
				},
			},
		}
		//
		messageSend := discordgo.MessageSend{
			Content:         "",
			Embeds:          []*discordgo.MessageEmbed{AnnEmbed("", messageBold, "XDN Announce Bot", url)},
			TTS:             false,
			Components:      buttons,
			Files:           nil,
			AllowedMentions: nil,
			Reference:       nil,
			File:            nil,
			Embed:           nil,
		}

		msg, err := goBot.ChannelMessageSendComplex(fmt.Sprintf("%d", channel.IdChannel), &messageSend)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}

		channelID, ko := strconv.Atoi(msg.ChannelID)
		messageID, ko := strconv.Atoi(msg.ID)
		if ko != nil {
			utils.WrapErrorLog("Error converting string to int")
		} else {
			_, err = database.InsertSQl("INSERT INTO bot_post_activity (idPost, idMessage, idChannel) VALUES (?,?,?)", post.PostID, messageID, channelID)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
		}
	}
}

func AnnouncementNFTDiscord() {
	LoadPictures()
	lastPost, err := database.ReadStruct[ActivityBotStruct]("SELECT * FROM bot_post_activity WHERE idPost IN (SELECT id FROM bot_post WHERE category = 1) AND idChannel = ? ORDER BY id DESC LIMIT 1", MainChannelID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	if lastPost.Id != 0 {
		err := goBot.ChannelMessageDelete(fmt.Sprintf("%d", lastPost.IdChannel), fmt.Sprintf("%d", lastPost.IdMessage))
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}

	}
	post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 1 ORDER BY RAND() LIMIT 1")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	messageBold := strings.ReplaceAll(post.Message, "*", "**")

	url := ""
	if post.Picture.Valid {
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", post.Picture.String)
	} else {
		randNum := utils.RandNum(len(PictureNFT))
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=2", randNum)
	}

	msg, err := goBot.ChannelMessageSendEmbeds(MainChannelID, []*discordgo.MessageEmbed{AnnEmbed("", messageBold, "XDN Announce Bot", url)})
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	//_, err = goBot.ChannelMessageSendEmbeds(MainChannelID, []*discordgo.MessageEmbed{AnnEmbed("", "If you want to be notified when we post a new announcement, please react with :white_check_mark: to this message.", "XDN Announce Bot", url)})

	go func(cID, mID string) {
		time.Sleep(2 * time.Second)
		err := goBot.MessageReactionAdd(cID, mID, "👍")
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
	}(msg.ChannelID, msg.ID)

	channelID, ko := strconv.Atoi(msg.ChannelID)
	messageID, ko := strconv.Atoi(msg.ID)
	if ko != nil {
		utils.WrapErrorLog("Error converting string to int")
	} else {
		_, err = database.InsertSQl("INSERT INTO bot_post_activity (idPost, idMessage, idChannel) VALUES (?,?,?)", post.PostID, messageID, channelID)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
	}
}

func AnnouncementOtherNFTDiscord() {
	LoadPictures()
	channels, err := database.ReadArrayStruct[models.Channel]("SELECT idChannel FROM uses_bot_activity WHERE idChannel > 0 AND idChannel !=? AND idChannel !=? AND idChannel !=? GROUP BY idChannel", TestChannelID, MainChannelID, VIPChannelID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	for _, channel := range channels {
		lastPost, err := database.ReadStruct[ActivityBotStruct]("SELECT * FROM bot_post_activity WHERE idPost IN (SELECT id FROM bot_post WHERE category = 1) AND idChannel = ? ORDER BY id DESC LIMIT 1", channel.IdChannel)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		if lastPost.Id != 0 {
			err := goBot.ChannelMessageDelete(fmt.Sprintf("%d", lastPost.IdChannel), fmt.Sprintf("%d", lastPost.IdMessage))
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}

		}
		post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 1 ORDER BY RAND() LIMIT 1")
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		messageBold := strings.ReplaceAll(post.Message, "*", "**")

		url := ""
		if post.Picture.Valid {
			url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", post.Picture.String)
		} else {
			randNum := utils.RandNum(len(PictureNFT))
			url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=2", randNum)
		}

		msg, err := goBot.ChannelMessageSendEmbeds(fmt.Sprintf("%d", channel.IdChannel), []*discordgo.MessageEmbed{AnnEmbed("", messageBold, "XDN Announce Bot", url)})
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		//_, err = goBot.ChannelMessageSendEmbeds(MainChannelID, []*discordgo.MessageEmbed{AnnEmbed("", "If you want to be notified when we post a new announcement, please react with :white_check_mark: to this message.", "XDN Announce Bot", url)})

		go func(cID, mID string) {
			time.Sleep(2 * time.Second)
			err := goBot.MessageReactionAdd(cID, mID, "👍")
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
		}(msg.ChannelID, msg.ID)

		channelID, ko := strconv.Atoi(msg.ChannelID)
		messageID, ko := strconv.Atoi(msg.ID)
		if ko != nil {
			utils.WrapErrorLog("Error converting string to int")
		} else {
			_, err = database.InsertSQl("INSERT INTO bot_post_activity (idPost, idMessage, idChannel) VALUES (?,?,?)", post.PostID, messageID, channelID)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
		}
	}
}

func GiftDiscordBot() {
	LoadPictures()
	lastPost, err := database.ReadStruct[ActivityBotStruct]("SELECT * FROM bot_post_activity WHERE idPost IN (SELECT id FROM bot_post WHERE category = 2) AND idChannel = ? ORDER BY id DESC LIMIT 1", MainChannelID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	if lastPost.Id != 0 {
		err := goBot.ChannelMessageDelete(fmt.Sprintf("%d", lastPost.IdChannel), fmt.Sprintf("%d", lastPost.IdMessage))
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}

	}
	post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 2 ORDER BY RAND() LIMIT 1")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	usrTL := database.ReadValueEmpty[int64](`SELECT count(id) FROM users_bot WHERE typeBot = 1`)
	luckyNumber := utils.RandNum(int(usrTL / 2))
	text := ""
	if luckyNumber == 0 {
		luckyNumber++
	}
	if luckyNumber == 1 {
		text = "first"
	} else if luckyNumber == 2 {
		text = "second"
	} else if luckyNumber == 3 {
		text = "third"
	} else {
		text = strconv.FormatInt(luckyNumber, 10) + "th"
	}
	message := fmt.Sprintf(post.Message, text)
	messageBold := strings.ReplaceAll(message, "*", "**")

	url := ""
	if post.Picture.Valid {
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", post.Picture.String)
	} else {
		randNum := utils.RandNum(len(PictureNFT))
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=2", randNum)
	}

	buttons := []discordgo.MessageComponent{
		discordgo.ActionsRow{
			Components: []discordgo.MessageComponent{
				discordgo.Button{
					Emoji: discordgo.ComponentEmoji{
						Name: "🎁",
					},
					Label:    "Try your luck",
					Style:    discordgo.SuccessButton,
					CustomID: "giftBot",
				},
			},
		},
	}
	//
	messageSend := discordgo.MessageSend{
		Content:         "",
		Embeds:          []*discordgo.MessageEmbed{GiftEmbed(messageBold, url)},
		TTS:             false,
		Components:      buttons,
		Files:           nil,
		AllowedMentions: nil,
		Reference:       nil,
		File:            nil,
		Embed:           nil,
	}

	msg, err := goBot.ChannelMessageSendComplex(MainChannelID, &messageSend)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	channelID, ko := strconv.Atoi(msg.ChannelID)
	messageID, ko := strconv.Atoi(msg.ID)
	if ko != nil {
		utils.WrapErrorLog("Error converting string to int")
	} else {
		_, err = database.InsertSQl("INSERT INTO gift_bot_numbers (idMessage, luckyNumber, idChannel) VALUES (?,?,?)", messageID, luckyNumber, channelID)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		_, err = database.InsertSQl("INSERT INTO bot_post_activity (idPost, idMessage, idChannel) VALUES (?,?,?)", post.PostID, messageID, channelID)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
	}
}

func GiftAnotherDiscordBot() {
	LoadPictures()
	channels, err := database.ReadArrayStruct[models.Channel]("SELECT idChannel FROM uses_bot_activity WHERE idChannel > 0 AND idChannel !=? AND idChannel !=? AND idChannel !=? GROUP BY idChannel", TestChannelID, MainChannelID, VIPChannelID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	for _, channel := range channels {
		lastPost, err := database.ReadStruct[ActivityBotStruct]("SELECT * FROM bot_post_activity WHERE idPost IN (SELECT id FROM bot_post WHERE category = 2) AND idChannel = ? ORDER BY id DESC LIMIT 1", channel.IdChannel)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		if lastPost.Id != 0 {
			err := goBot.ChannelMessageDelete(fmt.Sprintf("%d", lastPost.IdChannel), fmt.Sprintf("%d", lastPost.IdMessage))
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}

		}
		post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 2 ORDER BY RAND() LIMIT 1")
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		usrTL := database.ReadValueEmpty[int64](`SELECT count(id) FROM users_bot WHERE typeBot = 1`)
		luckyNumber := utils.RandNum(int(usrTL / 2))
		text := ""
		if luckyNumber == 0 {
			luckyNumber++
		}
		if luckyNumber == 1 {
			text = "first"
		} else if luckyNumber == 2 {
			text = "second"
		} else if luckyNumber == 3 {
			text = "third"
		} else {
			text = strconv.FormatInt(int64(luckyNumber), 10) + "th"
		}
		message := fmt.Sprintf(post.Message, text)
		messageBold := strings.ReplaceAll(message, "*", "**")

		url := ""
		if post.Picture.Valid {
			url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", post.Picture.String)
		} else {
			randNum := utils.RandNum(len(PictureNFT))
			url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=2", randNum)
		}

		buttons := []discordgo.MessageComponent{
			discordgo.ActionsRow{
				Components: []discordgo.MessageComponent{
					discordgo.Button{
						Emoji: discordgo.ComponentEmoji{
							Name: "🎁",
						},
						Label:    "Try your luck",
						Style:    discordgo.SuccessButton,
						CustomID: "giftBot",
					},
				},
			},
		}
		//
		messageSend := discordgo.MessageSend{
			Content:         "",
			Embeds:          []*discordgo.MessageEmbed{GiftEmbed(messageBold, url)},
			TTS:             false,
			Components:      buttons,
			Files:           nil,
			AllowedMentions: nil,
			Reference:       nil,
			File:            nil,
			Embed:           nil,
		}

		msg, err := goBot.ChannelMessageSendComplex(fmt.Sprintf("%d", channel.IdChannel), &messageSend)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}

		channelID, ko := strconv.Atoi(msg.ChannelID)
		messageID, ko := strconv.Atoi(msg.ID)
		if ko != nil {
			utils.WrapErrorLog("Error converting string to int")
		} else {
			_, err = database.InsertSQl("INSERT INTO gift_bot_numbers (idMessage, luckyNumber, idChannel) VALUES (?,?,?)", messageID, luckyNumber, channelID)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
			_, err = database.InsertSQl("INSERT INTO bot_post_activity (idPost, idMessage, idChannel) VALUES (?,?,?)", post.PostID, messageID, channelID)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
		}
	}
}

func giftBotHandler(s *discordgo.Session, i *discordgo.InteractionCreate) {
	utils.ReportMessage(fmt.Sprintf("giftBotHandler %s, %s, %s", i.Message.ChannelID, i.Message.ID, i.Member.User.ID))
	idU := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ?", i.Member.User.ID)
	if !idU.Valid {
		err := s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
			Type: discordgo.InteractionResponseChannelMessageWithSource,
			Data: &discordgo.InteractionResponseData{
				Content: "Please link your XDN APP to Discord. Go to APP, tap on Settings, tap on Connect and then follow the instructions.",
				Flags:   discordgo.MessageFlagsEphemeral,
			},
		})
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		utils.ReportMessage("User not found")
		Running = false
		return
	}
	luckyNumber := database.ReadValueEmpty[sql.NullInt64]("SELECT luckyNumber FROM gift_bot_numbers WHERE idMessage =? AND idChannel = ?", i.Message.ID, i.Message.ChannelID)
	if !luckyNumber.Valid {
		utils.ReportMessage("Lucky number not found")
		Running = false
		return
	}
	userVoted := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_activity WHERE idMessage = ? AND idChannel = ? AND idUserSocial = ?", i.Message.ID, i.Message.ChannelID, i.Member.User.ID)
	if userVoted.Valid {
		utils.ReportMessage(fmt.Sprintf("User %d already voted", userVoted.Int64))
		err := s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
			Type: discordgo.InteractionResponseChannelMessageWithSource,
			Data: &discordgo.InteractionResponseData{
				Content: "Already participated, better luck next time.",
				Flags:   discordgo.MessageFlagsEphemeral,
			},
		})
		utils.ReportMessage("Already participated")
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		Running = false
		return
	}
	_, err := database.InsertSQl("INSERT INTO users_activity (idUser, idMessage, idUserSocial, activity, idChannel, idPost) VALUES (?,?,?,?,?,?)", idU.Int64, i.Message.ID, i.Member.User.ID, 1, i.Message.ChannelID, 5) //todo change idPost
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	countUsers := database.ReadValueEmpty[int64]("SELECT IFNULL(COUNT(*), 0) FROM users_activity WHERE idMessage = ? AND idChannel = ?", i.Message.ID, i.Message.ChannelID)
	if countUsers != luckyNumber.Int64 {
		err := s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
			Type: discordgo.InteractionResponseChannelMessageWithSource,
			Data: &discordgo.InteractionResponseData{
				Content: "Thank you for your participation, your number is not winning this one, better luck next time.",
				Flags:   discordgo.MessageFlagsEphemeral,
			},
		})
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		Running = false
		return
	} else {
		addressTo := database.ReadValueEmpty[string]("SELECT addr FROM users WHERE id = ?", idU.Int64)
		addressFrom := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM servers_stake WHERE 1")
		if !addressFrom.Valid {
			utils.WrapErrorLog("Address from not found")
			Running = false
			return
		}
		winningAmount := 100.0
		luck := false
		chance := utils.RandNum(100)
		if chance < 30 {
			winningAmount = 1000.0
			luck = true
		}
		wonPic := "win"
		if luck {
			wonPic = "bot_luck"
		}
		url := fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", wonPic)

		_, err := s.ChannelMessageSendEmbeds(i.ChannelID, []*discordgo.MessageEmbed{WinEmbed(fmt.Sprintf("%s", i.Member.User.ID), fmt.Sprintf("%d", winningAmount), i.Member.User.AvatarURL("128"), i.Member.User.Username, url)})
		if err != nil {
			utils.WrapErrorLog(err.Error())
			Running = false
			return
		}
		err = s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
			Type: discordgo.InteractionResponseChannelMessageWithSource,
			Data: &discordgo.InteractionResponseData{
				Content: "Your reward is on the way!.",
				Flags:   discordgo.MessageFlagsEphemeral,
			},
		})
		_, err = coind.SendCoins(addressTo, addressFrom.String, winningAmount, true)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			Running = false
			return
		}
		d := map[string]string{
			"fn": "sendTransaction",
		}
		type Token struct {
			Token string `json:"token"`
		}
		tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", idU.Int64)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		if len(tk) > 0 {
			for _, v := range tk {
				utils.SendMessage(v.Token, "🎁 from Gift Bot", fmt.Sprintf("%s XDN", strconv.FormatFloat(100.0, 'f', 2, 32)), d)
			}
		}
		err = goBot.ChannelMessageDelete(fmt.Sprintf("%s", i.Message.ChannelID), fmt.Sprintf("%s", i.Message.ID))
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		Running = false
	}
}

func annBotHandler(s *discordgo.Session, i *discordgo.InteractionCreate) {
	utils.ReportMessage(fmt.Sprintf("annBotHandler %s, %s, %s", i.Message.ChannelID, i.Message.ID, i.Member.User.ID))
	idU := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ?", i.Member.User.ID)
	if !idU.Valid {
		err := s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
			Type: discordgo.InteractionResponseChannelMessageWithSource,
			Data: &discordgo.InteractionResponseData{
				Content: "Please link your XDN APP to Discord. Go to APP, tap on Settings, tap on Connect and then follow the instructions.",
				Flags:   discordgo.MessageFlagsEphemeral,
			},
		})
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		utils.ReportMessage("User not found")
		Running = false
		return
	}
	userVoted := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_activity WHERE idMessage = ? AND idChannel = ? AND idUserSocial = ?", i.Message.ID, i.Message.ChannelID, i.Member.User.ID)
	if userVoted.Valid {
		utils.ReportMessage(fmt.Sprintf("User %d already voted", userVoted.Int64))
		err := s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
			Type: discordgo.InteractionResponseChannelMessageWithSource,
			Data: &discordgo.InteractionResponseData{
				Content: "Already participated",
				Flags:   discordgo.MessageFlagsEphemeral,
			},
		})
		utils.ReportMessage("Already participated")
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		Running = false
		return
	}
	_, err := database.InsertSQl("INSERT INTO users_activity (idUser, idMessage, idUserSocial, activity, idChannel, idPost) VALUES (?,?,?,?,?,?)", idU.Int64, i.Message.ID, i.Member.User.ID, 1, i.Message.ChannelID, 5) //todo change idPost
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	countUsers := database.ReadValueEmpty[int64]("SELECT IFNULL(COUNT(*), 0) FROM users_activity WHERE idMessage = ? AND idChannel = ?", i.Message.ID, i.Message.ChannelID)
	if countUsers == 50 {
		addressTo := database.ReadValueEmpty[string]("SELECT addr FROM users WHERE id = ?", idU.Int64)
		addressFrom := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM servers_stake WHERE 1")
		if !addressFrom.Valid {
			utils.WrapErrorLog("Address from not found")
			Running = false
			return
		}
		url := fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", "win")
		_, err := s.ChannelMessageSendEmbeds(i.ChannelID, []*discordgo.MessageEmbed{WinEmbed(fmt.Sprintf("%s", i.Member.User.ID), "100", i.Member.User.AvatarURL("128"), i.Member.User.Username, url)})
		if err != nil {
			utils.WrapErrorLog(err.Error())
			Running = false
			return
		}
		err = s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
			Type: discordgo.InteractionResponseChannelMessageWithSource,
			Data: &discordgo.InteractionResponseData{
				Content: "You have been 50th who liked the post, your reward is on the way!",
				Flags:   discordgo.MessageFlagsEphemeral,
			},
		})
		_, err = coind.SendCoins(addressTo, addressFrom.String, 100.0, true)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			Running = false
			return
		}
		d := map[string]string{
			"fn": "sendTransaction",
		}
		type Token struct {
			Token string `json:"token"`
		}
		tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", idU.Int64)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		if len(tk) > 0 {
			for _, v := range tk {
				utils.SendMessage(v.Token, "🎁 from Ann Bot", fmt.Sprintf("%s XDN", strconv.FormatFloat(100.0, 'f', 2, 32)), d)
			}
		}
		err = goBot.ChannelMessageDelete(fmt.Sprintf("%s", i.Message.ChannelID), fmt.Sprintf("%s", i.Message.ID))
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		Running = false
		return
	} else if countUsers == 75 {

	} else {
		err := s.InteractionRespond(i.Interaction, &discordgo.InteractionResponse{
			Type: discordgo.InteractionResponseChannelMessageWithSource,
			Data: &discordgo.InteractionResponseData{
				Content: "Thank you for your participation! ",
				Flags:   discordgo.MessageFlagsEphemeral,
			},
		})
		utils.ReportMessage("Already participated")
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		Running = false
		return
	}
}

func askDiscord(from *discordgo.MessageCreate) (string, error) {
	if from.Author.Bot {
		return "", errors.New("Bot can't tip")
	}
	if from.Author.Username == "" {
		return "", errors.New("UserID is required")
	}

	str := strings.ReplaceAll(from.Content, "$ask", "")
	userID := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ?", from.Author.ID)
	if userID.Valid {
		_, _ = database.InsertSQl("INSERT INTO ask_team (idUser, username, question) VALUES (?,?,?)", userID.Int64, from.Author.Username, str)
	} else {
		_, _ = database.InsertSQl("INSERT INTO ask_team (username, question) VALUES (?,?)", from.Author.Username, str)
	}
	utils.ReportMessage(fmt.Sprintf("New question from %s: %s", from.Author.Username, str))
	return "Thank you, XDN Team", nil

}
