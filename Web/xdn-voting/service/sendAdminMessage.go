package service

import (
	"fmt"
	"xdn-voting/database"
	"xdn-voting/models"
	"xdn-voting/utils"
)

func SendAdminsReq(idReq int64) {
	d := map[string]string{
		"func": "req",
		"fr":   fmt.Sprintf("%d", idReq),
	}
	req, err := database.ReadStruct[models.WithReq]("SELECT a.*, b.username FROM with_req as a, users as b WHERE a.id = ? AND a.idUser = b.id", idReq)
	admins, err := database.ReadArrayStruct[models.User]("SELECT * FROM users WHERE admin = 1")
	if err != nil {
		utils.ReportMessage(err.Error())
		return
	}
	for _, data := range admins {
		if data.Admin == 0 {
			continue
		}
		type Token struct {
			Token string `json:"token"`
		}
		tk, err := database.ReadArray[Token]("SELECT token FROM devices WHERE idUser = ?", data.Id)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}

		if len(tk) > 0 {
			for _, v := range tk {
				utils.SendMessage(v.Token, fmt.Sprintf("New Withdraw Request"), fmt.Sprintf("%s  %f", req.Username, float32(req.Amount)), d)
			}
		}

	}
}
