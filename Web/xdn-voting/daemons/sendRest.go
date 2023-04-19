package daemons

import (
	"fmt"
	"strconv"
	"strings"
	"time"
	"xdn-voting/coind"
	"xdn-voting/database"
	"xdn-voting/utils"
)

var queve utils.Queue
var serverAddr string

func InitQueue() {
	queve = utils.Init()
	serverAddr, _ = database.ReadValue[string]("SELECT addr FROM servers_stake WHERE id = 1")
}

func FailedRequest(id int, addr string, amount float64) {
	m := make(map[string]interface{})
	m[fmt.Sprintf("%d:%s", id, addr)] = amount
	queve.Enqueue(m)
}

func SendRestDaemon() {
	for {
		m := queve.Dequeue()
		if m != nil {
			for k, v := range *m {
				sendCoins(k, v.(float64))
			}
		} else {
			time.Sleep(60 * time.Second)
		}
	}
}

func sendCoins(addrID string, amountSend float64) {
	addr := strings.Split(addrID, ":")[1]
	idStr := strings.Split(addrID, ":")[0]
	id, _ := strconv.Atoi(idStr)

	split := 2000000.0
	if amountSend > split {
		splitArr := make([]float64, 0)
		amount := amountSend
		tries := 0
		for {
			splitAmount := amount - split
			if splitAmount > split {
				splitArr = append(splitArr, split)
				amount = splitAmount
			} else {
				splitArr = append(splitArr, splitAmount)
				break
			}
		}
		for _, amnt := range splitArr {
			_, err := coind.SendCoins(addr, serverAddr, amnt, true)
			if err != nil {
				time.Sleep(10 * time.Second)
				utils.ReportMessage("Error sending coins to user, waiting")
				tries++
				continue
			}
			_, errDB := database.InsertSQl("UPDATE with_req SET sentAmount = sentAmount + ? WHERE id = ?", amnt, id)
			if errDB != nil {
				utils.WrapErrorLog(err.Error())
				return
			}
		}
	} else {
		tx, err := coind.SendCoins(addr, serverAddr, amountSend, true)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return
		}
		utils.ReportMessage("/// Sent " + tx + " to " + addr + " ///")
	}
}
