package daemons

import (
	"github.com/jasonlvhit/gocron"
	"xdn-voting/utils"
)

func InitCron() {
	go func() {
		//main channel
		err := gocron.Every(1).Day().At("02:10").Do(ANNMNBot)
		err = gocron.Every(1).Day().At("04:00").Do(RunBotAnn)
		err = gocron.Every(1).Day().At("08:00").Do(AnnNFTBot)
		err = gocron.Every(1).Day().At("12:00").Do(ANNMNBot)
		err = gocron.Every(1).Day().At("09:00").Do(GiftBot)
		err = gocron.Every(1).Day().At("13:00").Do(GiftBot)
		err = gocron.Every(1).Day().At("16:00").Do(ANNMNBot)
		err = gocron.Every(1).Day().At("17:00").Do(GiftBot)
		err = gocron.Every(1).Day().At("21:00").Do(GiftBot)
		err = gocron.Every(1).Day().At("23:00").Do(GiftBot)
		err = gocron.Every(1).Day().At("01:00").Do(GiftBot)
		err = gocron.Every(1).Day().At("05:00").Do(GiftBot)
		err = gocron.Every(1).Day().At("23:00").Do(ANNMNBot)
		err = gocron.Every(1).Day().At("20:00").Do(RunBotAnn)
		//other channel
		err = gocron.Every(1).Day().At("22:00").Do(ANNMNOtherChanne)
		err = gocron.Every(1).Day().At("14:00").Do(GiftBotOtherChannel)
		err = gocron.Every(1).Day().At("16:00").Do(GiftBotOtherChannel)
		err = gocron.Every(1).Day().At("20:00").Do(RunBotAnnOtherChannel)
		err = gocron.Every(1).Day().At("22:00").Do(GiftBotOtherChannel)
		err = gocron.Every(1).Day().At("04:00").Do(AnnNFTBotOtherChannel)
		err = gocron.Every(1).Day().At("08:00").Do(ANNMNOtherChanne)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		utils.ReportMessage("< - Cron service for Bot Ann started - >")
		<-gocron.Start()
	}()
}
