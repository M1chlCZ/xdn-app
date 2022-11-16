package misc

import (
	"fmt"
	"github.com/M1chlCZ/go-utils"
	"github.com/M1chlCZ/go-utils/database"
)

func RegenerateTokenSocial(userID int64) {
	tk := utils.GenerateSocialsToken(32)
	_, err := database.InsertSQl("UPDATE users SET tokenSocials = ? WHERE id = ?", tk, userID)
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("Regenerate Token Error: %s", err.Error()))

	}
}

type UsrStruct struct {
	Addr string `db:"addr"`
	Name string `db:"name"`
}

type RainReturnStruct struct {
	UsrList  []UsrStruct
	Amount   float64
	AddrFrom string
	Username string
	AddrSend string
}
