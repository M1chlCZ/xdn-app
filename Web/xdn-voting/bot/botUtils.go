package bot

import (
	"encoding/json"
	"fmt"
	"os"
	"xdn-voting/database"
	"xdn-voting/utils"
)

var Running = false

var PictureThunder = []string{"thunder.png", "thunder2.png"}
var PictureRain = []string{"rain.png"}

func RegenerateTokenSocial(userID int64) {
	tk := utils.GenerateSocialsToken(32)
	_, err := database.InsertSQl("UPDATE users SET tokenSocials = ? WHERE id = ?", tk, userID)
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("Regenerate Token Error: %s", err.Error()))

	}
}

func ReadConfigDiscord() error {
	utils.ReportMessage("Reading config file...")
	file, err := os.ReadFile("./config.json")

	if err != nil {
		utils.WrapErrorLog(err.Error())
		return err
	}
	err = json.Unmarshal(file, &config)

	if err != nil {
		utils.ReportMessage(err.Error())
		return err
	}

	return nil

}

type UsrStruct struct {
	Addr string `db:"addr"`
	Name string `db:"name"`
}

type RainReturnStruct struct {
	UsrList  []UsrStruct
	Amount   float64
	AddrFrom string
	UserID   string
	AddrSend string
}

type ThunderReturnStruct struct {
	UsrListTelegram []UsrStruct
	UsrListDiscord  []UsrStruct
	Amount          float64
	AddrFrom        string
	Username        string
	AddrSend        string
}

type UsrStructThunder struct {
	Addr    string `db:"addr"`
	Name    string `db:"name"`
	TypeBot int    `db:"typeBot"`
}
