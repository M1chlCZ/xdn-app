package daemons

import "xdn-voting/bot"

func RunBotAnn() {
	bot.AnnouncementTelegram()
	bot.AnnouncementDiscord()
}
