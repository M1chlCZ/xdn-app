package daemons

import (
	"github.com/jasonlvhit/gocron"
	"xdn-voting/utils"
)

func InitCron() {
	go func() {
		err := gocron.Every(1).Day().At("08:00").Do(RunBotAnn)
		err = gocron.Every(1).Day().At("00:00").Do(AnnNFTBot)
		err = gocron.Every(1).Day().At("08:00").Do(AnnNFTBot)
		err = gocron.Every(1).Day().At("16:00").Do(AnnNFTBot)
		err = gocron.Every(5).Hours().Do(GiftBot)
		//err = gocron.Every(1).Day().At("16:00").Do(RunBotAnn)
		err = gocron.Every(1).Day().At("20:00").Do(RunBotAnn)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		utils.ReportMessage("< - Cron service for Bot Ann started - >")
		<-gocron.Start()
	}()
}
