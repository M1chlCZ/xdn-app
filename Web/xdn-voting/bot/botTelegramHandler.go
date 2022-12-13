package bot

import (
	"database/sql"
	"fmt"
	"github.com/bwmarrin/discordgo"
	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
	"gopkg.in/errgo.v2/errors"
	"hash/maphash"
	"math/rand"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"
	"xdn-voting/coind"
	"xdn-voting/database"
	"xdn-voting/models"
	"xdn-voting/utils"
)

const (
	MainChannel = -1001238019497
	TestChannel = -1001873293473
)

var (
	bot           *tgbotapi.BotAPI
	statusMessage = []string{"I'm okay, you?", "All is good", "Yep...still okay", "Living the expensive life currently, you?", "I'm fine, how are you?", "I'm good, thanks!", "I'm fine"}
)

func StartTelegramBot() {
	var err error
	bot, err = tgbotapi.NewBotAPI(os.Getenv("TELEGRAM"))
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
					Running = true
					utils.ReportMessage(fmt.Sprintf("Message from %d", update.Message.Chat.ID))
					msg.Text = statusMessage[rand.Intn(len(statusMessage))]
					if _, err := bot.Send(msg); err != nil {
						utils.WrapErrorLog(err.Error())
					}
					Running = false
					return
				//case "test":
				//	Running = true
				//	utils.ReportMessage(fmt.Sprintf("Message from %d", update.Message.Chat.ID))
				//	msg.Text = statusMessage[rand.Intn(len(statusMessage))]
				//
				//	rand.Seed(time.Now().UnixNano())
				//	randNum := rand.Intn(len(PictureThunder))
				//
				//	url := fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d", randNum)
				//	utils.ReportMessage(url)
				//	photo := tgbotapi.NewPhoto(update.Message.Chat.ID, tgbotapi.FileURL(url))
				//	photo.Caption = "Test \n\nFUCK\n https://discord\\.gg/MHQqDeWd"
				//	if _, err := bot.Send(photo); err != nil {
				//		utils.WrapErrorLog(err.Error())
				//	}
				//	Running = false
				//	return
				case "help":
					Running = true
					post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 99")
					if err != nil {
						utils.WrapErrorLog(err.Error())
						return
					}
					msg.ParseMode = tgbotapi.ModeMarkdown
					msg.Text = post.Message
					if _, err := bot.Send(msg); err != nil {
						utils.WrapErrorLog(err.Error())
					}
					Running = false
					return
				case "ask":
					Running = true
					tx, err := ask(update.Message)
					if err != nil {
						msg.Text = "Error: " + err.Error()
					} else {
						msg.Text = tx
					}
					if _, err := bot.Send(msg); err != nil {
						utils.WrapErrorLog(err.Error())
					}
					Running = false
					return
				case "tip":
					Running = true
					tx, err := tip(update.Message.From.UserName, update.Message)
					if err != nil {
						msg.Text = "Error: " + err.Error()
					} else {
						msg.Text = tx
					}
					if _, err := bot.Send(msg); err != nil {
						utils.WrapErrorLog(err.Error())
					}
					Running = false
					return
				case "rain":
					Running = true
					tx, errr, data := rain(update.Message.From.UserName, update.Message)
					if errr != nil {
						msg.Text = "Error: " + errr.Error()
						_, _ = bot.Send(msg)
						Running = false
						return
					}
					msg.Text = tx
					mmm, err := bot.Send(msg)
					if err != nil {
						m := tgbotapi.NewMessage(update.Message.Chat.ID, "Error: "+err.Error())
						_, _ = bot.Send(m)
						utils.WrapErrorLog(err.Error())
						Running = false
						return
					}

					if data.Amount == 0 {
						Running = false
						return
					}

					chatID := mmm.Chat.ID
					messageID := mmm.MessageID
					txd, err := finishRain(data)
					if err != nil {
						m := tgbotapi.NewMessage(chatID, "Error: "+err.Error())
						_, _ = bot.Send(m)
						utils.WrapErrorLog(err.Error())
						Running = false
						return
					}
					if chatID != MainChannel {
						dl := tgbotapi.NewDeleteMessage(chatID, messageID)
						if _, err := bot.Send(dl); err != nil {
							utils.WrapErrorLog(err.Error())
						}
						randNum := utils.RandNum(len(PictureRain))

						url := fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=0", randNum)
						utils.ReportMessage(url)
						photo := tgbotapi.NewPhoto(chatID, tgbotapi.FileURL(url))
						utils.ReportMessage(txd)
						photo.Caption = "\n Join our OFFICIAL Telegram channel, lot of cool stuff there!\n" +
							"\n       https://t.me/XDNDN \n\n" + txd
						if len(photo.Caption) > 1024 {
							photo.Caption = photo.Caption[:1024]
						}
						if _, err := bot.Send(photo); err != nil {
							utils.WrapErrorLog(err.Error())
						}
					} else {
						dl := tgbotapi.NewDeleteMessage(chatID, messageID)
						if _, err := bot.Send(dl); err != nil {
							utils.WrapErrorLog(err.Error())
						}
						randNum := utils.RandNum(len(PictureRain))

						url := fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=0", randNum)
						utils.ReportMessage(url)
						photo := tgbotapi.NewPhoto(chatID, tgbotapi.FileURL(url))
						utils.ReportMessage(txd)
						photo.Caption = "\nJoin us on our new Discord Server!\n" +
							"\n     https://discord.gg/HD9vpTcMez \n\n" + txd
						if len(photo.Caption) > 1024 {
							photo.Caption = photo.Caption[:1024]
						}
						if _, err := bot.Send(photo); err != nil {
							utils.WrapErrorLog(err.Error())
						}
					}
					Running = false
					return
				case "thunder":
					Running = true
					utils.ReportMessage(fmt.Sprintf("Thunder %s", update.Message.From.UserName))
					tx, errr, data := thunderTelegram(update.Message.From.UserName, update.Message)
					if errr != nil {
						msg.Text = "Error: " + errr.Error()
						_, _ = bot.Send(msg)
						Running = false
						return
					}
					msg.Text = tx
					mmm, err := bot.Send(msg)
					if err != nil {
						m := tgbotapi.NewMessage(update.Message.Chat.ID, "Error: "+err.Error())
						_, _ = bot.Send(m)
						utils.WrapErrorLog(err.Error())
						Running = false
						return
					}
					if data.Amount == 0 {
						Running = false
						return
					}
					chatID := mmm.Chat.ID
					messageID := mmm.MessageID
					txd, err := finishThunder(data)
					if err != nil {
						m := tgbotapi.NewMessage(chatID, "Error: "+err.Error())
						_, _ = bot.Send(m)
						utils.WrapErrorLog(err.Error())
						Running = false
						return
					}
					if chatID != MainChannel {
						dl := tgbotapi.NewDeleteMessage(chatID, messageID)
						if _, err := bot.Send(dl); err != nil {
							utils.WrapErrorLog(err.Error())
						}
						randNum := utils.RandNum(len(PictureThunder))

						url := fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=1", randNum)
						utils.ReportMessage(url)
						photo := tgbotapi.NewPhoto(chatID, tgbotapi.FileURL(url))
						utils.ReportMessage(txd)
						photo.Caption = "\n Join our OFFICIAL Telegram channel, lot of cool stuff there!\n" +
							"\n       https://t.me/XDNDN \n\n" + txd
						if len(photo.Caption) > 1024 {
							photo.Caption = photo.Caption[:1024]
						}
						if _, err := bot.Send(photo); err != nil {
							utils.WrapErrorLog(err.Error())
						}
					} else {
						dl := tgbotapi.NewDeleteMessage(chatID, messageID)
						if _, err := bot.Send(dl); err != nil {
							utils.WrapErrorLog(err.Error())
						}
						randNum := utils.RandNum(len(PictureThunder))

						url := fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=1", randNum)
						utils.ReportMessage(url)
						photo := tgbotapi.NewPhoto(chatID, tgbotapi.FileURL(url))
						utils.ReportMessage(txd)
						photo.Caption = "\nJoin us on our new Discord Server!\n" +
							"\n     https://discord.gg/HD9vpTcMez \n\n" + txd
						if len(photo.Caption) > 1024 {
							photo.Caption = photo.Caption[:1024]
						}
						if _, err := bot.Send(photo); err != nil {
							utils.WrapErrorLog(err.Error())
						}
					}
					Running = false
					return
				case "register":
					Running = true
					err := register(update.Message.CommandArguments(), update.Message.From)
					if err != nil {
						msg.Text = "Error: " + err.Error()
					} else {
						msg.Text = "Registered successfully!"
					}
					if _, err := bot.Send(msg); err != nil {
						utils.WrapErrorLog(err.Error())
					}
					Running = false
					return
				case "unlink":
					Running = true
					err := unlink(update.Message.From)
					if err != nil {
						msg.Text = "Error: " + err.Error()
					} else {
						msg.Text = "Unliked successfully!"
					}
					if _, err := bot.Send(msg); err != nil {
						utils.WrapErrorLog(err.Error())
					}
					Running = false
					return
				default:
					Running = false
					return
				}
			}(&update)
		} else if update.CallbackQuery != nil {
			utils.ReportMessage("CallbackQuery")
			callback := tgbotapi.NewCallback(update.CallbackQuery.ID, update.CallbackQuery.Data)
			_, err := bot.Request(callback)
			if err != nil {
				utils.ReportMessage(err.Error())
			}
			if err == nil {
				if strings.Contains(update.CallbackQuery.Data, "likeAnn") || strings.Contains(update.CallbackQuery.Data, "dislikeAnn") {
					Running = true
					dataSplit := strings.Split(update.CallbackQuery.Data, ":")
					idPostage, _ := strconv.Atoi(dataSplit[1])
					idPost := database.ReadValueEmpty[int64]("SELECT idPost FROM bot_post_activity WHERE idMessage = ?", update.CallbackQuery.Message.MessageID)
					likeActivity, err := database.ReadStruct[ActivityBot]("SELECT activity, COUNT(*) as count FROM users_activity WHERE idMessage = ? AND idChannel = ? AND idPost = ? AND activity = 1 GROUP BY activity", update.CallbackQuery.Message.MessageID, update.CallbackQuery.Message.Chat.ID, idPostage)
					dislikeActivity, err := database.ReadStruct[ActivityBot]("SELECT activity, COUNT(*) as count FROM users_activity WHERE idMessage = ? AND idChannel = ? AND idPost = ? AND activity = 0 GROUP BY activity", update.CallbackQuery.Message.MessageID, update.CallbackQuery.Message.Chat.ID, idPostage)
					idU := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ?", update.CallbackQuery.From.UserName)
					idUser := 0
					likes := 0
					dislikes := 0
					userActivity := 0
					if idU.Valid {
						idUser = int(idU.Int64)
						userActivity = database.ReadValueEmpty[int]("SELECT activity FROM users_activity WHERE idUser = ? AND idPost = ? AND idMessage = ? AND idChannel = ?", idUser, idPostage, update.CallbackQuery.Message.MessageID, update.CallbackQuery.Message.Chat.ID)
						if userActivity == 0 {
							if err != nil {
								utils.WrapErrorLog(err.Error())
								Running = false
								return
							}
							if likeActivity.Count > 0 {
								likes = likeActivity.Count
							}
							if dislikeActivity.Count > 0 {
								dislikes = dislikeActivity.Count
							}
							if dataSplit[0] == "likeAnn" {
								likes++
								if likes == 50 {
									_, err := TipUser(update.CallbackQuery.From.UserName)
									if err != nil {
										utils.WrapErrorLog(err.Error())
									}
								}
								_, _ = database.InsertSQl("INSERT INTO users_activity (idUser, idMessage, idUserSocial, activity, idChannel, idPost) VALUES (?,?,?,?,?,?)", idUser, update.CallbackQuery.Message.MessageID, update.CallbackQuery.From.ID, 1, update.CallbackQuery.Message.Chat.ID, idPostage)
							} else if dataSplit[0] == "dislikeAnn" {
								dislikes++
								_, _ = database.InsertSQl("INSERT INTO users_activity (idUser, idMessage, idUserSocial, activity, idChannel, idPost) VALUES (?,?,?,?,?,?)", idUser, update.CallbackQuery.Message.MessageID, update.CallbackQuery.From.ID, 0, update.CallbackQuery.Message.Chat.ID, idPostage)
							}
							var rows []tgbotapi.InlineKeyboardButton
							rows = append(rows, tgbotapi.NewInlineKeyboardButtonData(fmt.Sprintf("👍🏻 %d", likes), fmt.Sprintf("likeAnn:%d", idPost)))
							//rows = append(rows, tgbotapi.NewInlineKeyboardButtonData(fmt.Sprintf("👎🏻 %d", dislikes), fmt.Sprintf("dislikeAnn:%d", idPost)))
							m := tgbotapi.NewEditMessageReplyMarkup(update.CallbackQuery.Message.Chat.ID, update.CallbackQuery.Message.MessageID, tgbotapi.NewInlineKeyboardMarkup(rows))
							_, err = bot.Send(m)
							if err != nil {
								utils.ReportMessage(err.Error())
							}
							Running = false
						} else {
							utils.WrapErrorLog(fmt.Sprintf("User %d already voted", idUser))
							Running = false
							// user already voted
						}
					} else {
						utils.WrapErrorLog("User not found")
						Running = false
					}

				}
				if strings.Contains(update.CallbackQuery.Data, "giftBot") {
					idU := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ?", update.CallbackQuery.From.UserName)
					if !idU.Valid {
						utils.ReportMessage("User not found")
						Running = false
						continue
					}
					luckyNumber := database.ReadValueEmpty[sql.NullInt64]("SELECT luckyNumber FROM gift_bot_numbers WHERE idMessage =? AND idChannel = ?", update.CallbackQuery.Message.MessageID, update.CallbackQuery.Message.Chat.ID)
					if !luckyNumber.Valid {
						utils.ReportMessage("Lucky number not found")
						Running = false
						continue
					}
					userVoted := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_activity WHERE idMessage = ? AND idChannel = ? AND idUserSocial = ?", update.CallbackQuery.Message.MessageID, update.CallbackQuery.Message.Chat.ID, update.CallbackQuery.From.ID)
					if userVoted.Valid {
						msg := tgbotapi.NewMessage(update.CallbackQuery.From.ID, "Already participated, good luck next time!")
						_, err := bot.Send(msg)
						if err != nil {
							utils.ReportMessage(err.Error())
						}
						utils.ReportMessage("Already participated")
						Running = false
						continue
					}
					_, _ = database.InsertSQl("INSERT INTO users_activity (idUser, idMessage, idUserSocial, activity, idChannel, idPost) VALUES (?,?,?,?,?,?)", idU, update.CallbackQuery.Message.MessageID, update.CallbackQuery.From.ID, 1, update.CallbackQuery.Message.Chat.ID, 2)

					countUsers := database.ReadValueEmpty[int64]("SELECT IFNULL(COUNT(*), 0) FROM users_activity WHERE idMessage = ? AND idChannel = ?", update.CallbackQuery.Message.MessageID, update.CallbackQuery.Message.Chat.ID)
					if countUsers != luckyNumber.Int64 {
						Running = false
						continue
					} else {
						addressTo := database.ReadValueEmpty[string]("SELECT addr FROM users WHERE id = ?", idU)
						addressFrom := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM servers_stake WHERE 1")
						if !addressFrom.Valid {
							utils.WrapErrorLog("Address from not found")
							Running = false
							continue
						}
						dl := tgbotapi.NewDeleteMessage(update.CallbackQuery.Message.Chat.ID, update.CallbackQuery.Message.MessageID)
						_, err = bot.Send(dl)
						if err != nil {
							utils.ReportMessage(err.Error())
						}
						url := fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", "win")
						msg := tgbotapi.NewPhoto(update.CallbackQuery.Message.Chat.ID, tgbotapi.FileURL(url))
						msg.Caption = fmt.Sprintf("Congratulations @%s, you won 100 XDN!", update.CallbackQuery.From.UserName)
						if _, err = bot.Send(msg); err != nil {
							utils.WrapErrorLog(err.Error())
							Running = false
							continue
						}
						_, err := coind.SendCoins(addressTo, addressFrom.String, 100.0, true)
						if err != nil {
							utils.WrapErrorLog(err.Error())
							Running = false
							continue
						}
						d := map[string]string{
							"fn": "sendTransaction",
						}
						type Token struct {
							Token string `json:"token"`
						}
						tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", idU)
						if err != nil {
							utils.WrapErrorLog(err.Error())
						}
						if len(tk) > 0 {
							for _, v := range tk {
								utils.SendMessage(v.Token, "🎁 from Gift Bot", fmt.Sprintf("%s XDN", strconv.FormatFloat(100.0, 'f', 2, 32)), d)
							}
						}
						Running = false
						continue
					}
				}
			}
			Running = false
		}
	}

}

func register(token string, from *tgbotapi.User) error {
	if from.IsBot {
		return errors.New("Bots are not allowed")
	}
	if from.UserName == "" {
		return errors.New("UserID is required")
	}

	already := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users_bot WHERE idSocial = ?", from.UserName)
	if already.Valid {
		return errors.New("Already registered")
	}

	idUser := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users WHERE tokenSocials = ?", token)
	if !idUser.Valid {
		RegenerateTokenSocial(idUser.Int64)
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
		return errors.New("UserID is required")
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

	r := regexp.MustCompile(`(?i)help`)
	if r.MatchString(from.Text) {
		return "Tip some user XDN\n\nUsage: /tip @<username> <amount>", nil
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
	_, err = database.InsertSQl("INSERT INTO uses_bot_activity (idUser, amount, type, idSocial, idChannel) VALUES (?, ?, ?, ?, ?)", usrFrom.Int64, amnt, 2, 0, from.Chat.ID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
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
	mes := fmt.Sprintf("User @%s tipped @%s%sXDN", username, ut, amount[len(amount)-1])
	utils.ReportMessage(fmt.Sprintf("User @%s tipped @%s%s XDN on Telegram", username, ut, amount[len(amount)-1]))
	return mes, nil
	//return nil
}

func rain(username string, from *tgbotapi.Message) (string, error, RainReturnStruct) {
	if from.From.IsBot {
		return "", errors.New("Bots are not allowed"), RainReturnStruct{}
	}
	r := regexp.MustCompile(`(?i)help`)
	if r.MatchString(from.Text) {
		return "Splash some coins on users on this social media\n\nUsage: /rain <amount> @<numOfUsers>\n\nParameter numOfUsers is optional, when not specified it will rain on all users registered on this social media", nil, RainReturnStruct{}
	}
	str1 := strings.ReplaceAll(from.Text, "@", "")
	str2 := from.Text
	if (len(str2) - len(str1)) > 1 {
		return "", errors.New("Only one parameter is allowed"), RainReturnStruct{}
	}

	//eg: 100XDN
	reg := regexp.MustCompile("\\s[0-9.]+")
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
		r := rand.New(rand.NewSource(int64(new(maphash.Hash).Sum64())))
		r.Shuffle(len(usersTo), func(i, j int) { usersTo[i], usersTo[j] = usersTo[j], usersTo[i] })
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
	_, err = database.InsertSQl("INSERT INTO uses_bot_activity (idUser, amount, type, idSocial, idChannel) VALUES (?, ?, ?, ?, ?)", usrFrom.Int64, amount, 0, 0, from.Chat.ID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	return fmt.Sprintf("Raining %.2f XDN on %d users", amount, numOfUsers), nil, RainReturnStruct{
		UsrList:  usersToTip,
		Amount:   amount,
		AddrFrom: addrTo.String,
		UserID:   username,
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
		_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip Bot Rain by: "+data.UserID, tx, "receive")
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
	mes := fmt.Sprintf("User @%s rained on %s %s XDN each", data.UserID, userString, strconv.FormatFloat(amountToUser, 'f', 2, 32))

	return mes, nil
}

func thunderTelegram(username string, from *tgbotapi.Message) (string, error, ThunderReturnStruct) {
	if from.From.IsBot {
		return "", errors.New("Bots are not allowed"), ThunderReturnStruct{}
	}
	r := regexp.MustCompile(`(?i)help`)
	if r.MatchString(from.Text) {
		return "Thunder is like rain, however it's not limited to one social media, it will rain on Telegram as well as Discord \n\nUsage: /thunder <amount> @<numOfUsers>\n\nParameter numOfUsers is optional, when not specified it will rain on all users registered on all social media", nil, ThunderReturnStruct{}
	}
	str1 := strings.ReplaceAll(from.Text, "@", "")
	str2 := from.Text
	if (len(str2) - len(str1)) > 1 {
		return "", errors.New("Only one parameter is allowed"), ThunderReturnStruct{}
	}

	//eg: 100XDN
	reg := regexp.MustCompile("\\s[0-9.]+")
	am := reg.FindAllString(from.Text, -1)
	if len(am) == 0 {
		return "", errors.New("Missing amount to tip"), ThunderReturnStruct{}
	}
	amount, err := strconv.ParseFloat(strings.TrimSpace(am[0]), 32)
	if err != nil {
		return "", errors.New("Invalid amount to tip"), ThunderReturnStruct{}
	}

	usrFrom := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE binary idSocial= ? AND typeBot = ?", username, 1)
	if !usrFrom.Valid {
		return "", errors.New("You are not registered in the bot db"), ThunderReturnStruct{}
	}
	utils.ReportMessage(fmt.Sprintf("--- Thunder from %s ---", username))

	//join userTelegram with userDiscord

	telegramFinalSlice := make([]UsrStruct, 0)
	discordFinalSlice := make([]UsrStruct, 0)

	numOfUsers := 0

	addrTo := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM servers_stake WHERE 1")
	if !addrTo.Valid {
		return "", errors.New("Problem sending coins to rain service"), ThunderReturnStruct{}
	}
	addrFrom := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM users WHERE id = ?", usrFrom.Int64)
	if !addrFrom.Valid {
		return "", errors.New("Error getting user address #1"), ThunderReturnStruct{}
	}

	//eg: @100 people
	re := regexp.MustCompile("\\B@[0-9]+[^a-zA-Z]?$")
	m := re.FindAllString(from.Text, -1)
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
		var usersToTip []UsrStructThunder
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

	_, _ = database.InsertSQl("UPDATE users_bot SET numberRained = numberRained + 1 WHERE idUser  = ?", usrFrom.Int64) //update number of rains
	utils.ReportMessage(fmt.Sprintf("Sending coins to rain service %s", username))
	tx, err := coind.SendCoins(addrTo.String, addrFrom.String, amount, false)
	if err != nil {
		return "", err, ThunderReturnStruct{}
	}
	_, _ = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Tip Bot Rain", tx, "send")

	_, err = database.InsertSQl("INSERT INTO uses_bot_activity (idUser, amount, type, idSocial, idChannel) VALUES (?, ?, ?, ?, ?)", usrFrom.Int64, amount, 1, 0, from.Chat.ID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	return fmt.Sprintf("Raining thunder of %.2f XDN on %d users", amount, numOfUsers), nil, ThunderReturnStruct{
		UsrListTelegram: telegramFinalSlice,
		UsrListDiscord:  discordFinalSlice,
		Amount:          amount,
		AddrFrom:        addrTo.String,
		Username:        username,
		AddrSend:        addrFrom.String,
	}
}

func finishThunder(data ThunderReturnStruct) (string, error) {
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

	if len(data.UsrListDiscord) != 0 {
		idUser := database.ReadValueEmpty[int64]("SELECT idUser FROM users_bot WHERE binary idSocial = ?", data.Username)
		discordUserID := database.ReadValueEmpty[string]("SELECT idSocial FROM users_bot WHERE idUser = ? AND typeBot = 2", idUser)
		discordUserName := database.ReadValueEmpty[string]("SELECT dname FROM users_bot WHERE id = ? AND typeBot = 2", idUser)
		utils.ReportMessage(fmt.Sprintf("Discord username: %s", discordUserID))

		a, b, c := finishRainDiscord(RainReturnStruct{
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
			showThunderMessage(a, b)
		}
	}
	t := strings.ReplaceAll(telegramResponse, "rained", "brought Thunder")
	return t, telegramError
}

func AnnouncementTelegram() {
	LoadPictures()
	lastPost, err := database.ReadStruct[ActivityBotStruct]("SELECT * FROM bot_post_activity WHERE idPost IN (SELECT id FROM bot_post WHERE category = 0) AND idChannel < 0 ORDER BY id DESC LIMIT 1")
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	if lastPost.Id != 0 {
		dl := tgbotapi.NewDeleteMessage(lastPost.IdChannel, int(lastPost.IdMessage))
		_, err := bot.Send(dl)
		if err != nil {
			utils.ReportMessage(err.Error())
		}
	}

	post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 0 ORDER BY RAND() LIMIT 1")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	postID := post.PostID
	url := fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=3", 1)
	utils.ReportMessage(fmt.Sprintf("Announcement url: %s", url))
	msg := tgbotapi.NewPhoto(MainChannel, tgbotapi.FileURL(url))
	var rows []tgbotapi.InlineKeyboardButton
	rows = append(rows, tgbotapi.NewInlineKeyboardButtonData("👍🏻", fmt.Sprintf("likeAnn:%d", postID)))
	//rows = append(rows, tgbotapi.NewInlineKeyboardButtonData("👎🏻", fmt.Sprintf("dislikeAnn:%d", postID)))
	msg.ReplyMarkup = tgbotapi.NewInlineKeyboardMarkup(rows)
	msg.ParseMode = tgbotapi.ModeMarkdown

	msg.Caption = post.Message
	mess, err := bot.Send(msg)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}

	_, err = database.InsertSQl("INSERT INTO bot_post_activity (idPost, idMessage, idChannel) VALUES (?,?,?)", post.PostID, mess.MessageID, mess.Chat.ID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
}

func AnnNFTTelegram() {
	LoadPictures()
	lastPost, err := database.ReadStruct[ActivityBotStruct]("SELECT * FROM bot_post_activity WHERE idPost IN (SELECT id FROM bot_post WHERE category = 1) AND idChannel < 0 ORDER BY id DESC LIMIT 1")
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	if lastPost.Id != 0 {
		dl := tgbotapi.NewDeleteMessage(lastPost.IdChannel, int(lastPost.IdMessage))
		_, err := bot.Send(dl)
		if err != nil {
			utils.ReportMessage(err.Error())
		}
	}

	post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 1 ORDER BY RAND() LIMIT 1")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	url := ""
	if post.Picture.Valid {
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", post.Picture.String)
	} else {
		randNum := utils.RandNum(len(PictureNFT))
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=2", randNum)
	}

	postID := post.PostID
	utils.ReportMessage(fmt.Sprintf("NFT url: %s", url))
	msg := tgbotapi.NewPhoto(MainChannel, tgbotapi.FileURL(url))
	var rows []tgbotapi.InlineKeyboardButton
	rows = append(rows, tgbotapi.NewInlineKeyboardButtonData("👍🏻", fmt.Sprintf("likeAnn:%d", postID)))
	//rows = append(rows, tgbotapi.NewInlineKeyboardButtonData("👎🏻", fmt.Sprintf("dislikeAnn:%d", postID)))
	msg.ReplyMarkup = tgbotapi.NewInlineKeyboardMarkup(rows)
	msg.ParseMode = tgbotapi.ModeMarkdown

	msg.Caption = post.Message
	mess, err := bot.Send(msg)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	_, err = database.InsertSQl("INSERT INTO bot_post_activity (idPost, idMessage, idChannel) VALUES (?,?,?)", post.PostID, mess.MessageID, mess.Chat.ID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
}

func GiftTelegramBot() {
	LoadPictures()
	lastPost, err := database.ReadStruct[ActivityBotStruct]("SELECT * FROM bot_post_activity WHERE idPost IN (SELECT id FROM bot_post WHERE category = 2) AND idChannel < 0 ORDER BY id DESC LIMIT 1")
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	if lastPost.Id != 0 {
		dl := tgbotapi.NewDeleteMessage(lastPost.IdChannel, int(lastPost.IdMessage))
		_, err := bot.Send(dl)
		if err != nil {
			utils.ReportMessage(err.Error())
		}
	}

	post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 2 ORDER BY RAND() LIMIT 1")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	url := ""
	if post.Picture.Valid {
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", post.Picture.String)
	} else {
		randNum := utils.RandNum(len(PictureNFT))
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=2", randNum)
	}

	utils.ReportMessage(fmt.Sprintf("GIFT url: %s", url))
	msg := tgbotapi.NewPhoto(MainChannel, tgbotapi.FileURL(url))
	var rows []tgbotapi.InlineKeyboardButton
	rows = append(rows, tgbotapi.NewInlineKeyboardButtonData("🎁", "giftBot"))
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
	msg.ReplyMarkup = tgbotapi.NewInlineKeyboardMarkup(rows)
	msg.ParseMode = tgbotapi.ModeMarkdown
	utils.ReportMessage(fmt.Sprintf("Lucky number: %d, Post Message: %s", luckyNumber, post.Message))
	msg.Caption = message
	mess, err := bot.Send(msg)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	_, err = database.InsertSQl("INSERT INTO gift_bot_numbers (idMessage, luckyNumber, idChannel) VALUES (?,?,?)", mess.MessageID, luckyNumber, mess.Chat.ID)
	_, err = database.InsertSQl("INSERT INTO bot_post_activity (idPost, idMessage, idChannel) VALUES (?,?,?)", post.PostID, mess.MessageID, mess.Chat.ID)
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
}

func showDiscordTelegramThunder(message string) {
	randNum := utils.RandNum(len(PictureThunder))

	url := fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=1", randNum)
	utils.ReportMessage(url)
	photo := tgbotapi.NewPhoto(MainChannel, tgbotapi.FileURL(url))
	utils.ReportMessage(message)
	photo.Caption = "\n Join our OFFICIAL Telegram channel, lot of cool stuff there!\n" +
		"\n       https://t.me/XDNDN \n\n" + message
	if len(photo.Caption) > 1024 {
		photo.Caption = photo.Caption[:1024]
	}
	if _, err := bot.Send(photo); err != nil {
		utils.WrapErrorLog(err.Error())
	}
}

func ask(from *tgbotapi.Message) (string, error) {
	if from.From.IsBot {
		return "", errors.New("Bots are not allowed")
	}
	if from.From.UserName == "" {
		return "", errors.New("You need to set a username")
	}
	str := strings.ReplaceAll(from.Text, "/ask ", "")
	userID := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE idSocial = ?", from.From.UserName)
	if userID.Valid {
		_, _ = database.InsertSQl("INSERT INTO ask_team (idUser, username, question) VALUES (?,?,?)", userID.Int64, from.From.UserName, str)
	} else {
		_, _ = database.InsertSQl("INSERT INTO ask_team (username, question) VALUES (?,?)", from.From.UserName, str)
	}
	utils.ReportMessage(fmt.Sprintf("New question from %s: %s", from.From.UserName, str))
	return "Thank you, your question has been sent to the team", nil

}

func AnnOtherChannelTelegram() {
	LoadPictures()

	post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 0 ORDER BY RAND() LIMIT 1")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	channels, err := database.ReadArrayStruct[models.Channel]("SELECT idChannel FROM uses_bot_activity WHERE idChannel < 0 AND idChannel !=? AND idChannel !=? GROUP BY idChannel", TestChannel, MainChannel)
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
		postID := post.PostID
		url := fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=3", 1)
		utils.ReportMessage(fmt.Sprintf("Announcement url: %s", url))
		msg := tgbotapi.NewPhoto(channel.IdChannel, tgbotapi.FileURL(url))
		var rows []tgbotapi.InlineKeyboardButton
		rows = append(rows, tgbotapi.NewInlineKeyboardButtonData("👍🏻", fmt.Sprintf("likeAnn:%d", postID)))
		//rows = append(rows, tgbotapi.NewInlineKeyboardButtonData("👎🏻", fmt.Sprintf("dislikeAnn:%d", postID)))
		msg.ReplyMarkup = tgbotapi.NewInlineKeyboardMarkup(rows)
		msg.ParseMode = tgbotapi.ModeMarkdown

		msg.Caption = "*This is one per day post on non-XDN channels using XDN-bot, only important announcement* \n ! Rewards work on other channels as well !\n\n" + post.Message
		mess, err := bot.Send(msg)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}

		_, err = database.InsertSQl("INSERT INTO bot_post_activity (idPost, idMessage, idChannel) VALUES (?,?,?)", post.PostID, mess.MessageID, mess.Chat.ID)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
	}
}

func GiftOtherChannelsTelegram() {
	LoadPictures()
	post, err := database.ReadStruct[Post]("SELECT * FROM bot_post WHERE category = 2 ORDER BY RAND() LIMIT 1")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	url := ""
	if post.Picture.Valid {
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file?file=%s", post.Picture.String)
	} else {
		randNum := utils.RandNum(len(PictureNFT))
		url = fmt.Sprintf("https://dex.digitalnote.org/api/api/v1/file/gram?file=%d&type=2", randNum)
	}
	channels, err := database.ReadArrayStruct[models.Channel]("SELECT idChannel FROM uses_bot_activity WHERE idChannel < 0 AND idChannel !=? AND idChannel !=? GROUP BY idChannel", TestChannel, MainChannel)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	for _, channel := range channels {
		lastPost, err := database.ReadStruct[ActivityBotStruct]("SELECT * FROM bot_post_activity WHERE idPost IN (SELECT id FROM bot_post WHERE category = 2) AND idChannel = ? ORDER BY id DESC LIMIT 1", channel.IdChannel)
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
		utils.ReportMessage(fmt.Sprintf("GIFT url: %s", url))
		msg := tgbotapi.NewPhoto(channel.IdChannel, tgbotapi.FileURL(url))
		var rows []tgbotapi.InlineKeyboardButton
		rows = append(rows, tgbotapi.NewInlineKeyboardButtonData("🎁", "giftBot"))
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
		msg.ReplyMarkup = tgbotapi.NewInlineKeyboardMarkup(rows)
		msg.ParseMode = tgbotapi.ModeMarkdown
		utils.ReportMessage(fmt.Sprintf("Lucky number: %d, Post Message: %s", luckyNumber, post.Message))
		msg.Caption = message
		mess, err := bot.Send(msg)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		_, err = database.InsertSQl("INSERT INTO gift_bot_numbers (idMessage, luckyNumber, idChannel) VALUES (?,?,?)", mess.MessageID, luckyNumber, mess.Chat.ID)
		_, err = database.InsertSQl("INSERT INTO bot_post_activity (idPost, idMessage, idChannel) VALUES (?,?,?)", post.PostID, mess.MessageID, mess.Chat.ID)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
	}
}

func TipUser(username string) (string, error) {
	usrTo := database.ReadValueEmpty[sql.NullInt64]("SELECT idUser FROM users_bot WHERE binary idSocial = ? AND typeBot = ?", username, 1)
	if !usrTo.Valid {
		return "", errors.New("Mentioned user not registered in the bot db")
	}
	addrFrom := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM servers_stake WHERE 1")
	if !addrFrom.Valid {
		return "", errors.New("Error getting user address #1")
	}
	addrTo := database.ReadValueEmpty[sql.NullString]("SELECT addr FROM users WHERE id = ?", usrTo.Int64)
	if !addrTo.Valid {
		return "", errors.New("Error getting user address #2")
	}
	utils.ReportMessage(fmt.Sprintf("From: %s, To: %s, Amount: %s", addrFrom.String, addrTo.String, 100))
	amnt := 100.0

	_, err := coind.SendCoins(addrTo.String, addrFrom.String, amnt, false)
	if err != nil {
		return "", errors.New("Error sending coins from " + username)
	}
	_, err = bot.Send(tgbotapi.NewMessage(MainChannel, fmt.Sprintf("User %s won %f XDN", username, amnt)))
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	_, err = database.InsertSQl("UPDATE transaction SET contactName = ? WHERE (txid = ? AND category = ? AND id > 0) LIMIT 1", "Winning announcement contest, tx", "send")
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	go func(addrTo string, addrSend string, amount string) {
		d := map[string]string{
			"fn": "sendTransaction",
		}
		userTo := database.ReadValueEmpty[sql.NullInt64]("SELECT id FROM users WHERE addr = ?", addrTo)
		if userTo.Valid {
			type Token struct {
				Token string `json:"token"`
			}
			tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", userTo.Int64)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}

			if len(tk) > 0 {
				for _, v := range tk {
					utils.SendMessage(v.Token, fmt.Sprintf("Won the ann competition from %s", "XDN Bot"), fmt.Sprintf("%s XDN", amount), d)
				}
			}

		}
	}(addrTo.String, addrFrom.String, "100.0")
	return fmt.Sprintf("You won %f XDN", amnt), nil
}
