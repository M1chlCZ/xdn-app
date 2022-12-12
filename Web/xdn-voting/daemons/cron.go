package daemons

import (
	"github.com/jasonlvhit/gocron"
	"xdn-voting/utils"
)

func InitCron() {
	go func() {
		err := gocron.Every(1).Day().At("04:00").Do(RunBotAnn)
		err = gocron.Every(1).Day().At("08:00").Do(AnnNFTBot)
		err = gocron.Every(1).Day().At("12:00").Do(RunBotAnn)
		err = gocron.Every(1).Day().At("09:00").Do(GiftBot)
		err = gocron.Every(1).Day().At("13:00").Do(GiftBot)
		err = gocron.Every(1).Day().At("17:00").Do(GiftBot)
		err = gocron.Every(1).Day().At("21:00").Do(GiftBot)
		err = gocron.Every(1).Day().At("01:00").Do(GiftBot)
		err = gocron.Every(1).Day().At("05:00").Do(GiftBot)
		err = gocron.Every(1).Day().At("20:00").Do(RunBotAnn)
		err = gocron.Every(1).Day().At("00:00").Do(RunBotAnn)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		utils.ReportMessage("< - Cron service for Bot Ann started - >")
		<-gocron.Start()
	}()
}
