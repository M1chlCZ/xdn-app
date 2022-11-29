package daemons

import "xdn-voting/bot"

func RunBotAnn() {
	bot.AnnouncementTelegram()
	bot.AnnouncementDiscord()
}

func AnnNFTBot() {
	bot.AnnNFTTelegram()
	bot.AnnouncementNFTDiscord()
}

func GiftBot() {
	bot.GiftTelegramBot()
}
