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

func ANNMNBot() {
	bot.AnnouncementMNTelegram()
	bot.AnnouncementMNDiscord()
}

func ANNMNOtherChannel() {
	bot.AnnMNOtherChannelTelegram()
	bot.AnnouncementMNOtherDiscord()
}

func GiftBot() {
	bot.GiftTelegramBot()
	bot.GiftDiscordBot()
}

func GiftBotOtherChannel() {
	bot.GiftOtherChannelsTelegram()
	bot.GiftAnotherDiscordBot()
}
