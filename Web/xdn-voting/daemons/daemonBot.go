package daemons

import "xdn-voting/bot"

func RunBotAnn() {
	bot.AnnouncementTelegram()
	bot.AnnouncementDiscord()
}

func RunBotAnnOtherChannel() {
	bot.AnnOtherChannelTelegram()
}

func AnnNFTBot() {
	bot.AnnNFTTelegram()
	bot.AnnouncementNFTDiscord()
}

func GiftBot() {
	bot.GiftTelegramBot()
	bot.GiftDiscordBot()
}

func GiftBotOtherChannel() {
	bot.GiftOtherChannelsTelegram()
}
