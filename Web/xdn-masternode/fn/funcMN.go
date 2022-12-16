package fn

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"
	"xdn-masternode/coind"
	"xdn-masternode/database"
	"xdn-masternode/grpcClient"
	"xdn-masternode/grpcModels"
	"xdn-masternode/models"
	"xdn-masternode/utils"
)

func StartMasternode(nodeID int) {
	daemon, err := database.GetDaemon(nodeID)
	pathConf := utils.GetHomeDir() + "/." + daemon.Folder + "/" + daemon.Conf
	pathMn := utils.GetHomeDir() + "/." + daemon.Folder + "/masternode.conf"
	_, errScript := exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "masternode=", pathConf)).Output()
	_, errScript = exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "masternodeprivkey=", pathConf)).Output()
	_, errScript = exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "MN", pathMn)).Output()
	_, _ = exec.Command("bash", "-c", fmt.Sprintf("rm $HOME/.%s/*.bak", daemon.Folder)).Output()

	utils.ReportMessage(fmt.Sprintf(" -| Setting up node id: %d |-", daemon.NodeID))

	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	folder := daemon.Folder
	conf := daemon.Conf
	ip := daemon.IP
	mnport := daemon.MnPort

	var txid string
	var vout int

	//if daemon.CoinID == 0 {
	type MasternodeOutputsXDN []struct {
		Txhash    string `json:"txhash"`
		Outputidx string `json:"outputidx"`
	}
	var ing MasternodeOutputsXDN
	mOut, err := coind.WrapDaemon(*daemon, 15, "masternode", "outputs")
	if err != nil {
		_, _ = exec.Command("bash", "-c", fmt.Sprintf("systemctl --user stop %s", daemon.Folder)).Output()
		_, _ = exec.Command("bash", "-c", fmt.Sprintf("rm $HOME/.%s/wallet.dat", daemon.Folder)).Output()
		_, _ = exec.Command("bash", "-c", fmt.Sprintf("systemctl --user start %s", daemon.Folder)).Output()
		time.Sleep(60 * time.Second)
		priv, err := privateKey(daemon.NodeID)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		utils.ReportMessage("Importing key...")
		_, err = coind.WrapDaemon(*daemon, 5, "importprivkey", priv)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		mOut, err = coind.WrapDaemon(*daemon, 15, "masternode", "outputs")
	}
	utils.ReportMessage(fmt.Sprintf("%v", string(mOut)))
	err = json.Unmarshal(mOut, &ing)
	if err != nil {
		utils.ReportMessage("Error getting outputs")
		go Snap(daemon.Folder, daemon.CoinID)
		return
	}
	if len(ing) != 0 {
		txid = ing[0].Txhash
		v, _ := strconv.Atoi(ing[0].Outputidx)
		vout = v
		//} else {
		//var ing models_json.MasternodeOutputs
		//mOut, err := coind.WrapDaemon(*daemon, 15, "getmasternodeoutputs")
		//if err != nil {
		//	_, _ = exec.Command("bash", "-c", fmt.Sprintf("systemctl --user stop %s", daemon.Folder)).Output()
		//	_, _ = exec.Command("bash", "-c", fmt.Sprintf("rm $HOME/.%s/wallet.dat", daemon.Folder)).Output()
		//	_, _ = exec.Command("bash", "-c", fmt.Sprintf("systemctl --user start %s", daemon.Folder)).Output()
		//	time.Sleep(60 * time.Second)
		//	priv, err := privateKey(daemon.NodeID)
		//	if err != nil {
		//		utils.WrapErrorLog(err.Error())
		//	}
		//	utils.ReportMessage("Importing key...")
		//	utils.ReportMessage(priv.Key)
		//	_, err = coind.WrapDaemon(*daemon, 5, "importprivkey", priv.Key)
		//	if err != nil {
		//		utils.WrapErrorLog(err.Error())
		//	}
		//	mOut, err = coind.WrapDaemon(*daemon, 15, "getmasternodeoutputs")
		//}
		//err = json.Unmarshal(mOut, &ing)
		//if err != nil {
		//	utils.ReportMessage("Error getting outputs")
		//	go Snap(daemon.Folder, daemon.CoinID)
		//	return
		//}
		//txid = ing[0].Txhash
		//vout = ing[0].Outputidx
		//}

		//REEdundancy
		if len(txid) == 0 {
			utils.ReportMessage("No masternode output")
			mOut, err := coind.WrapDaemon(*daemon, 15, "masternode", "outputs")
			if err != nil {
				go Snap(daemon.Folder, daemon.CoinID)
				return
			}
			err = json.Unmarshal(mOut, &ing)
			if err != nil {
				utils.ReportMessage("Error getting outputs")
				go Snap(daemon.Folder, daemon.CoinID)
				return
			}
			txid = ing[0].Txhash
			v, _ := strconv.Atoi(ing[0].Outputidx)
			vout = v
		}
	} else {
		utils.ReportMessage("! No masternode output !")
		mOut, err := coind.WrapDaemon(*daemon, 15, "masternode", "outputs")
		if err != nil {
			go Snap(daemon.Folder, daemon.CoinID)
			return
		}
		err = json.Unmarshal(mOut, &ing)
		if err != nil {
			utils.ReportMessage("Error getting outputs")
			go Snap(daemon.Folder, daemon.CoinID)
			return
		}
		txid = ing[0].Txhash
		v, _ := strconv.Atoi(ing[0].Outputidx)
		vout = v
	}

	p, _ := coind.WrapDaemon(*daemon, 5, "masternode", "genkey")

	mnKey := string(p)
	pathConf = utils.GetHomeDir() + "/." + folder + "/" + conf
	pathMn = utils.GetHomeDir() + "/." + folder + "/masternode.conf"
	regex := regexp.MustCompile(`-?\d[\d,]*[.]?[\d{2}]*`)
	subNum := regex.FindAllString(folder, -1)
	num := subNum[0]

	time.Sleep(10 * time.Second)

	_, errScript = exec.Command("bash", "-c", fmt.Sprintf("systemctl --user stop %s.service", folder)).Output()
	if errScript != nil {
		utils.ReportMessage(errScript.Error())
		return
	}
	utils.ReportMessage("Daemon stopped")

	//CLEAN UP
	_, _ = exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "masternode=", pathConf)).Output()
	_, _ = exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "masternodeprivkey=", pathConf)).Output()
	_, _ = exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "MN", pathMn)).Output()

	_, errScript = exec.Command("bash", "-c", fmt.Sprintf("echo \"masternode=1\" >> %s", pathConf)).Output()
	utils.ReportMessage(fmt.Sprintf("Editing %s", conf))
	_, errScript = exec.Command("bash", "-c", fmt.Sprintf("echo \"masternodeprivkey=%s\" >> %s", mnKey, pathConf)).Output()
	utils.ReportMessage("Editing masternode.conf")
	_, errScript = exec.Command("bash", "-c", fmt.Sprintf("echo \"MN%s [%s]:%d %s %s %d\" >> %s", num, ip, mnport, mnKey, txid, vout, pathMn)).Output()
	if errScript != nil {
		utils.ReportMessage(errScript.Error())
		return
	}

	time.Sleep(5 * time.Second)
	if daemon.CoinID == 2 {
		utils.ReportMessage("Starting daemon")
		_, errScript = exec.Command("bash", "-c", fmt.Sprintf("/home/m1chl/snap %s", folder)).Output()
		if errScript != nil {
			log.Println(errScript.Error())
			utils.ReportMessage(errScript.Error())
			return
		}
	} else {
		utils.ReportMessage("Starting daemon")
		_, errScript := exec.Command("bash", "-c", fmt.Sprintf("systemctl --user start %s.service", folder)).Output()
		if errScript != nil {
			log.Println(errScript.Error())
			utils.ReportMessage(errScript.Error())
			return
		}
	}
	time.Sleep(60 * time.Second)

	//XDN

	res, errMNstart := coind.WrapDaemon(*daemon, 30, "masternode", "start")
	utils.ReportMessage(fmt.Sprintf("%s", res))
	if errMNstart != nil {
		utils.WrapErrorLog(errMNstart.Error())
		return
	}
	utils.ReportMessage("< - Masternode Started - >")

	go func() {
		utils.ReportMessage("Starting goroutine restart service")
		time.Sleep(12 * time.Minute)
		//
		utils.ReportMessage("Restarting daemon: " + folder)
		_, errScript = exec.Command("bash", "-c", fmt.Sprintf("systemctl --user restart %s.service", folder)).Output()
		if errScript != nil {
			log.Println(errScript.Error())
			utils.ReportMessage(errScript.Error())
			return
		}
	}()

	utils.ReportMessage("-| Finished MN setup |-")
}

func Snap(folder string, coinID int) {
	utils.ReportMessage(fmt.Sprintf("Snapping active %s", folder))
	go func(folder string) {
		_, errScript := exec.Command("bash", "-c", fmt.Sprintf("$HOME/snap %s", folder)).Output()
		if errScript != nil {
			utils.ReportMessage(errScript.Error())
			return
		}
		time.Sleep(time.Second * 60)
		utils.ReportMessage(fmt.Sprintf("Snapped %s", folder))
		dm, _ := database.GetDaemonFolder(folder)
		corruptCheck(dm)
		pp, errr := coind.WrapDaemon(*dm, 1, "masternode", "start")
		if errr != nil {
			pathConf := utils.GetHomeDir() + "/." + folder + "/" + dm.Conf
			pathMn := utils.GetHomeDir() + "/." + folder + "/masternode.conf"
			_, _ = exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "masternode=", pathConf)).Output()
			_, _ = exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "masternodeprivkey=", pathConf)).Output()
			_, _ = exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "MN", pathMn)).Output()
			StartMasternode(dm.NodeID)
			return
		} else {
			utils.ReportMessage(string(pp))
			return
		}
	}(folder)
}

func corruptCheck(daemon *models.Daemon) {
	pathConf := utils.GetHomeDir() + "/." + daemon.Folder + "/" + daemon.Conf
	pathMn := utils.GetHomeDir() + "/." + daemon.Folder + "/masternode.conf"
	_, _ = exec.Command("bash", "-c", fmt.Sprintf("systemctl --user stop %s", daemon.Folder)).Output()
	_, _ = exec.Command("bash", "-c", fmt.Sprintf("rm $HOME/.%s/*.zip", daemon.Folder)).Output()
	_, _ = exec.Command("bash", "-c", fmt.Sprintf("rm $HOME/.%s/*.zip.1", daemon.Folder)).Output()
	fileExist, _ := exec.Command("bash", "-c", fmt.Sprintf("file=($HOME/.%s/*.bak); if [ -f \"$file\" ] || [ -d \"$file\" ]; then echo \"yes\" ; else echo \"no\" ; fi", daemon.Folder)).Output()
	if strings.TrimSpace(string(fileExist)) == "yes" {
		_, errScript := exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "masternode=", pathConf)).Output()
		_, errScript = exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "masternodeprivkey=", pathConf)).Output()
		_, errScript = exec.Command("bash", "-c", fmt.Sprintf("sed --in-place \"/%s/d\" \"%s\"", "MN", pathMn)).Output()
		_, err := exec.Command("bash", "-c", fmt.Sprintf("rm $HOME/.%s/*.bak", daemon.Folder)).Output()
		_, _ = exec.Command("bash", "-c", fmt.Sprintf("systemctl --user start %s", daemon.Folder)).Output()
		time.Sleep(60 * time.Second)
		if errScript != nil {
			utils.WrapErrorLog(err.Error())
		}
		priv, err := privateKey(daemon.NodeID)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
		utils.ReportMessage("Importing key...")
		utils.ReportMessage(priv)
		_, err = coind.WrapDaemon(*daemon, 5, "importprivkey", priv)
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
	}
}

func privateKey(nodeID int) (string, error) {
	tx := grpcModels.GetPrivateKeyRequest{
		NodeID: uint32(nodeID),
	}
	priv, err := grpcClient.CallGetPrivateKey(&tx)
	return priv.PrivKey, err
}

func ScanMasternodes() {
	utils.ReportMessage("-| Scanning for inactive MNs |-")
	daemonList, err := database.GetAllDaemons()
	if err != nil {
		utils.ReportMessage(err.Error())
		return
	}

	mnListServer, err := masternodeActive()
	if err != nil {
		utils.ReportMessage(err.Error())
		return
	}

	var daemonFinal = make([]models.Daemon, 0)
	var daemonFinalInactive = make([]models.Daemon, 0)
	for _, daemon := range *daemonList {
		for _, nodeInfo := range mnListServer.Mn {
			if int(nodeInfo.Id) == daemon.NodeID {
				if nodeInfo.Active == 1 {
					daemonFinal = append(daemonFinal, daemon)
				} else {
					daemonFinalInactive = append(daemonFinalInactive, daemon)
				}
			}
		}
	}
	lastSeen := make([]*grpcModels.LastSeenRequest_LastSeen, 0)

	blkReqXDN, errNet := utils.GETAny("https://xdn-explorer.com/api/getblockcount")
	if errNet != nil {
		utils.WrapErrorLog(errNet.ErrorMessage() + " " + strconv.Itoa(errNet.StatusCode()))
		return
	}
	bodyXDN, _ := io.ReadAll(blkReqXDN.Body)
	blockhashXDN, _ := strconv.Atoi(string(bodyXDN))

	defer func(Body io.ReadCloser) {
		err := Body.Close()
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
	}(blkReqXDN.Body)

	for _, daemon := range daemonFinal {
		_, _ = exec.Command("bash", "-c", fmt.Sprintf("rm $HOME/.%s/*.zip", daemon.Folder)).Output()
		_, _ = exec.Command("bash", "-c", fmt.Sprintf("rm $HOME/.%s/*.zip.1", daemon.Folder)).Output()
		//if daemon.CoinID == 0 {
		blk, errBlock := coind.WrapDaemon(daemon, 1, "getblockcount")
		bnm, errBlock := strconv.Atoi(strings.Trim(string(blk), "\""))
		if errBlock != nil {
			utils.WrapErrorLog(errBlock.Error())
			go Snap(daemon.Folder, daemon.CoinID)
			continue
		}

		if !(blockhashXDN < (bnm + 10)) || !(blockhashXDN > (bnm - 10)) {
			utils.ReportMessage(fmt.Sprintf("SHIT BLOCK COUNT: Have %d, should have %d", bnm, blockhashXDN))
			go Snap(daemon.Folder, daemon.CoinID)
			continue
		}
		bl, err := coind.WrapDaemon(daemon, 1, "getbalance")
		balance, err := strconv.ParseFloat(strings.Trim(string(bl), "\""), 64)
		if errBlock != nil {
			utils.WrapErrorLog(errBlock.Error())
			go Snap(daemon.Folder, daemon.CoinID)
			continue
		}
		if balance < 2000000.0 {
			utils.ReportMessage("Importing key...")
			priv, err := privateKey(daemon.NodeID)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				continue
			}
			utils.ReportMessage(priv)
			_, err = coind.WrapDaemon(daemon, 5, "importprivkey", priv)
			if err != nil {
				utils.WrapErrorLog(err.Error())
			}
		}

		var ing, check models.MasternodeStatusXDN
		p, err := coind.WrapDaemon(daemon, 3, "masternode", "status")
		if err != nil {
			utils.WrapErrorLog(err.Error())
			utils.ReportMessage(fmt.Sprintf("error status masternode %s, %d, %d", daemon.Folder, daemon.CoinID, daemon.NodeID))
			go Snap(daemon.Folder, daemon.CoinID)
			continue
		}
		errJson := json.Unmarshal(p, &ing)
		if errJson != nil {
			utils.WrapErrorLog(errJson.Error())
			utils.ReportMessage(fmt.Sprintf("Masternode status sucks, restarting %s", daemon.Folder))
			pp, errr := coind.WrapDaemon(daemon, 1, "masternode", "start")
			if errr != nil {
				utils.WrapErrorLog(errr.Error())
				utils.ReportMessage(fmt.Sprintf("error starting masternode %s, %d, %d", daemon.Folder, daemon.CoinID, daemon.NodeID))
				go Snap(daemon.Folder, daemon.CoinID)
				continue
			} else {
				utils.ReportMessage(string(pp))
				go func(dm models.Daemon) {
					utils.ReportMessage("Starting goroutine restart service")
					time.Sleep(12 * time.Minute)
					//
					utils.ReportMessage("Restarting daemon: " + dm.Folder)
					_, errScript := exec.Command("bash", "-c", fmt.Sprintf("systemctl --user restart %s.service", dm.Folder)).Output()
					if errScript != nil {
						utils.ReportMessage(errScript.Error())
						return
					}
				}(daemon)
				continue
			}
		}
		if ing.Status != 1 {
			utils.ReportMessage(fmt.Sprintf("Masternode status is not 1, restarting %s", daemon.Folder))
			s, errr := coind.WrapDaemon(daemon, 1, "masternode", "start")
			if errr != nil {
				utils.ReportMessage(fmt.Sprintf("error starting masternode %s, %d, %d", daemon.Folder, daemon.CoinID, daemon.NodeID))
				go Snap(daemon.Folder, daemon.CoinID)
				continue
			}
			if string(s) != "Masternode successfully started" {
				utils.ReportMessage(fmt.Sprintf("error starting masternode %s, %d, %d", daemon.Folder, daemon.CoinID, daemon.NodeID))
				go Snap(daemon.Folder, daemon.CoinID)
				continue
			}
		}

		if ing == check {
			utils.ReportMessage("Rescuing masternode")
			go Snap(daemon.Folder, daemon.CoinID)
			continue
		} else {
			bytes, err := coind.WrapDaemon(daemon, 1, "masternode", "list", "full")
			if err != nil {
				utils.WrapErrorLog(err.Error())
				go Snap(daemon.Folder, daemon.CoinID)
				continue
			}

			var mnList40 models.MasternodeList
			errJson = json.Unmarshal(bytes, &mnList40)
			if errJson != nil {
				utils.WrapErrorLog(errJson.Error())
				go Snap(daemon.Folder, daemon.CoinID)
				continue
			}

			for _, mnListNode := range mnList40 {
				if mnListNode.Addr == ing.Pubkey {
					m := &grpcModels.LastSeenRequest_LastSeen{
						Id:         uint32(daemon.NodeID),
						LastSeen:   uint32(mnListNode.Lastseen),
						ActiveTime: uint32(mnListNode.Activetime),
					}
					lastSeen = append(lastSeen, m)
					utils.ReportMessage(fmt.Sprintf("All OKAY @ %s!", daemon.Folder))
				}
			}
		}
		utils.ReportMessage(fmt.Sprintf("END CHECK @ %s!", daemon.Folder))
		continue
		//}

	}
	for _, daemon := range daemonFinalInactive {
		utils.ReportMessage(fmt.Sprintf("%s is inactive", daemon.Folder))

		_, _ = exec.Command("bash", "-c", fmt.Sprintf("rm $HOME/.%s/*.zip", daemon.Folder)).Output()
		_, _ = exec.Command("bash", "-c", fmt.Sprintf("rm $HOME/.%s/*.zip.1", daemon.Folder)).Output()

		fileExist, _ := exec.Command("bash", "-c", fmt.Sprintf("file=($HOME/.%s/*.bak); if [ -f \"$file\" ] || [ -d \"$file\" ]; then echo \"yes\" ; else echo \"no\" ; fi", daemon.Folder)).Output()
		if strings.TrimSpace(string(fileExist)) == "yes" {
			utils.ReportMessage("Restoring... bak file detected")
			_, errScript := exec.Command("bash", "-c", fmt.Sprintf("systemctl --user stop %s.service", daemon.Folder)).Output()
			_, errScript = exec.Command("bash", "-c", fmt.Sprintf("rm $HOME/.%s/*.bak", daemon.Folder)).Output()
			_, errScript = exec.Command("bash", "-c", fmt.Sprintf("rm $HOME/.%s/wallet.dat", daemon.Folder)).Output()
			_, errScript = exec.Command("bash", "-c", fmt.Sprintf("systemctl --user start %s.service", daemon.Folder)).Output()
			if errScript != nil {
				utils.WrapErrorLog(errScript.Error())
				continue
			}
			time.Sleep(time.Minute * 5)
			priv, err := privateKey(daemon.NodeID)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				continue
			}
			utils.ReportMessage("Importing key...")
			_, err = coind.WrapDaemon(daemon, 5, "importprivkey", priv)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				continue
			}
			go snapInactive(daemon.Folder, daemon.CoinID)
			continue
		}

		blk, errBlock := coind.WrapDaemon(daemon, 5, "getblockcount")
		if errBlock != nil || string(blk) == "nul" {
			utils.WrapErrorLog(errBlock.Error())
			go snapInactive(daemon.Folder, daemon.CoinID)
			continue
		}

		if daemon.CoinID == 0 {
			blk2, erBlockXDN := coind.WrapDaemon(daemon, 1, "getblockcount")
			bnmXDN, erBlockXDN := strconv.Atoi(strings.Trim(string(blk2), "\""))
			if erBlockXDN != nil {
				utils.WrapErrorLog(erBlockXDN.Error())
				go snapInactive(daemon.Folder, daemon.CoinID)
				continue
			}

			if !(blockhashXDN < (bnmXDN + 10)) || !(blockhashXDN > (bnmXDN - 10)) {
				utils.ReportMessage(fmt.Sprintf("SHIT BLOCK COUNT: Have %d, should have %d", bnmXDN, blockhashXDN))
				go snapInactive(daemon.Folder, daemon.CoinID)
				continue
			}
			utils.ReportMessage(fmt.Sprintf("All OKAY @ %s!", daemon.Folder))
			continue
		}

		var ing models.GetInfo
		p, er := coind.WrapDaemon(daemon, 5, "getinfo")
		if er != nil {
			go snapInactive(daemon.Folder, daemon.CoinID)
			continue
		}
		errJson := json.Unmarshal(p, &ing)
		if errJson != nil {
			go snapInactive(daemon.Folder, daemon.CoinID)
			continue
		}
		if len(ing.Errors) != 0 {
			go snapInactive(daemon.Folder, daemon.CoinID)
			continue
		}
		utils.ReportMessage(fmt.Sprintf("All OKAY @ %s!", daemon.Folder))
	}

	_, err = grpcClient.LastSeen(&grpcModels.LastSeenRequest{
		Items: lastSeen,
	})
	if err != nil {
		utils.WrapErrorLog("Can't post last seen to API")
	}
	utils.ReportMessage("-| All done |-")
	return
}

func masternodeActive() (*grpcModels.MasternodeActiveResponse, error) {
	url, err := exec.Command("bash", "-c", "ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\\.){3}[0-9]*).*/\\2/p'").Output()
	if err != nil {
		utils.ReportMessage(err.Error())
		return nil, err
	}
	tx := &grpcModels.MasternodeActiveRequest{Url: strings.TrimSpace(string(url))}

	payload, err := grpcClient.MasternodeActive(tx)
	if err != nil {
		utils.ReportMessage(err.Error())
		return nil, err
	}

	return payload, nil
}

func snapInactive(folder string, coinID int) {
	utils.ReportMessage(fmt.Sprintf("Snapping %s", folder))
	if coinID == 2 {

		_, errScript := exec.Command("bash", "-c", fmt.Sprintf("$HOME/snap %s", folder)).Output()
		if errScript != nil {
			utils.ReportMessage(errScript.Error())
			return
		}
		utils.ReportMessage(fmt.Sprintf("Snapped %s", folder))
	} else if coinID == 0 {
		_, errScript := exec.Command("bash", "-c", fmt.Sprintf("$HOME/Snap %s", folder)).Output()
		if errScript != nil {
			utils.ReportMessage(errScript.Error())
			return
		}
		time.Sleep(time.Second * 10)
		_, errScript = exec.Command("bash", "-c", fmt.Sprintf("systemctl --user restart %s", folder)).Output()
		if errScript != nil {
			utils.ReportMessage(errScript.Error())
			return
		}
		time.Sleep(time.Second * 30)
		utils.ReportMessage(fmt.Sprintf("Snapped %s", folder))
	} else if coinID == 6 {

		_, errScript := exec.Command("bash", "-c", fmt.Sprintf("$HOME/snapFDR %s", folder)).Output()
		if errScript != nil {
			utils.ReportMessage(errScript.Error())
			return
		}
		utils.ReportMessage(fmt.Sprintf("Snapped %s", folder))

	} else {

		utils.WrapErrorLog("Unknown coin")
		return
	}
}
