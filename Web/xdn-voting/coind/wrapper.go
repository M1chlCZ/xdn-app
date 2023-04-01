package coind

import (
	"errors"
	"fmt"
	"sync"
	"time"
	"xdn-voting/models"
	"xdn-voting/utils"
)

func WrapDaemon(daemon models.Daemon, maxTries int, method string, params ...interface{}) ([]byte, error) {
	wg := new(sync.WaitGroup)
	c := make(chan []byte, 1)
	e := make(chan error, 1)
	var res []byte
	var err error
	go callDaemon(c, e, wg, &daemon, maxTries, method, params)
	wg.Wait()
	select {
	case data := <-c:
		res = data
	case er := <-e:
		utils.WrapErrorLog(er.Error())
		err = er
	}
	close(c)
	close(e)

	if err == nil {
		return res, nil
	} else {
		return nil, err
	}
}

func callDaemon(c chan []byte, e chan error, wg *sync.WaitGroup, daemon *models.Daemon, triesMax int, command string, params any) {
	wg.Add(1)
	defer wg.Done()
	var client *Coind
	var errClient error
	tries := 0
	for {
		if tries != 0 {
			utils.ReportMessage(fmt.Sprintf("Try %d of %d. CMD: %s Daemon: %s", tries, triesMax, command, daemon.Folder))
		}
		if tries >= triesMax {
			e <- errors.New("error getting RPC data")
			return
		}

		tries++
		if client == nil {
			client, errClient = New("127.0.0.1", daemon.WalletPort, daemon.WalletUser, daemon.WalletPass, false)
			if errClient != nil {
				utils.ReportMessage(errClient.Error())
				time.Sleep(15 * time.Second)
				continue
			}
		}
		p, er := client.Call(command, params)

		if er != nil {
			utils.ReportMessage("Daemon unreachable " + er.Error())
			time.Sleep(15 * time.Second)
			continue
		}
		if string(p) != "null" {
			if len(p) != 0 {
				if command == "getmasternodeoutputs" && string(p) == ("[]") {
					time.Sleep(15 * time.Second)
					continue
				}
				c <- p
				return
			}
		} else {
			if command == "walletpassphrase" || command == "walletlock" || command == "importkey" {
				c <- []byte("ok")
				return
			}
		}

		utils.ReportMessage("Error, trying again")
		time.Sleep(15 * time.Second)
	}
}
