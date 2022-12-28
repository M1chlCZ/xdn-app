package daemons

import "xdn-voting/bot"

func RunBotAnn() {
	bot.AnnouncementTelegram()
	bot.AnnouncementDiscord()
}

func RunBotAnnOtherChannel() {
	bot.AnnOtherChannelTelegram()
	bot.AnnouncementOtherDiscord()
}

func AnnNFTBot() {
	bot.AnnNFTTelegram()
	bot.AnnouncementNFTDiscord()
}

func AnnNFTBotOtherChannel() {
	bot.AnnouncementOtherNFTDiscord()
}

func GiftBot() {
	bot.GiftTelegramBot()
	bot.GiftDiscordBot()
}

func GiftBotOtherChannel() {
	bot.GiftOtherChannelsTelegram()
	bot.GiftAnotherDiscordBot()
}
