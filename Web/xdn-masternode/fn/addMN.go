package fn

import (
	"database/sql"
	"errors"
	"fmt"
	copy "github.com/otiai10/copy"
	"gopkg.in/yaml.v3"
	"log"
	mathRand "math/rand"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"xdn-masternode/coind"
	"xdn-masternode/database"
	"xdn-masternode/grpcClient"
	"xdn-masternode/grpcModels"
	"xdn-masternode/models"
	"xdn-masternode/utils"
)

func AddMN(params models.AddMNConfig) error {
	utils.ReportMessage(params.ToString())
	RPCUser := utils.GenerateSecureToken(8)
	RPCPassword := utils.GenerateSecureToken(16)
	PRT := 0

	yamlFile, err := os.ReadFile("/etc/netplan/01-netcfg.yaml")
	if err != nil {
		utils.ReportMessage(fmt.Sprintf("Error reading YAML file: %s\n", err))
		return err
	}

	config := models.NetConfig{}
	err = yaml.Unmarshal(yamlFile, &config)
	if err != nil {
		utils.ReportMessage(fmt.Sprintf("Error parsing YAML file: %s\n", err))
		return err
	}
	addrFree := config.Network.Ethernets["ens18"].Addresses[1:]
	ipv6regex := `([a-f0-9:]+:+)+[a-f0-9]+`
	for _, address := range addrFree {
		if _, err := regexp.Match(ipv6regex, []byte(address)); err != nil {
			utils.WrapErrorLog(fmt.Sprintf("Error matching regex: %s", address))
			addrFree = utils.RemoveElement(addrFree, address)
		}
	}
	coinDaemons, _ := database.GetAllDaemons()
loopic:
	for _, daemon := range *coinDaemons {
		for _, ip := range addrFree {
			b := utils.IPv6Equal(daemon.IP, ip)
			if b {
				//utils.ReportMessage(fmt.Sprintf("IP %s is already in use.", ip))
				addrFree = utils.RemoveElement(addrFree, ip)
				continue loopic
			}
			if !b {
				//utils.ReportMessage(fmt.Sprintf("IP %s is not in use.", ip))
			}
		}
	}

	if len(addrFree) == 0 {
		utils.ReportMessage("No free IP addresses found.")
		return errors.New("no free IPv6 addresses found.")
	}
	IP := addrFree[mathRand.Intn(len(addrFree))]

	dm, _ := database.GetLastDaemon(params.CoinID)
	lastFolder, _ := extractNumber(dm.Folder)
	num := lastFolder + 1
	if dm.WalletPort != 0 {
		PRT = dm.WalletPort + 1
	} else {
		PRT = params.PortPrefix*1000 + 1
	}
	if utils.IPv6Equal(IP, dm.IP) {
		if len(addrFree) > 1 {
			IP = addrFree[1]
		} else {
			return errors.New("No free IPv6 addresses found.")
		}
	}

	IP = strings.Split(IP, "/")[0]
	IP = strings.ReplaceAll(IP, "0000:0000:0000", "")

	homeFolder := utils.GetHomeDir()
	folderCoin := homeFolder + "/." + params.CoinFolder + fmt.Sprintf("%d", num)

	utils.ReportMessage(fmt.Sprintf("Creating folder: %s", folderCoin))

	//copy stuff to folderCoin
	err = os.Mkdir(folderCoin, 0755)
	if err != nil {
		_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
		utils.WrapErrorLog(err.Error())
		return err
	}
	utils.ReportMessage(fmt.Sprintf("Copying files from %s/%s to %s", homeFolder, params.BlockchainFolder, folderCoin))
	err = copy.Copy(fmt.Sprintf("%s/%s", homeFolder, params.BlockchainFolder), fmt.Sprintf("%s", folderCoin))
	if err != nil {
		_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
		utils.WrapErrorLog(err.Error())
		return err
	}
	utils.ReportMessage("Creating config file")
	err = os.WriteFile(fmt.Sprintf("%s/%s", folderCoin, params.ConfigFile), []byte(fmt.Sprintf(`rpcuser=%s
rpcpassword=%s
rpcallowip=127.0.0.1
rpcport=%d
port=%d
walletnotify=%s/txsubmit.sh %%s
listen=1
server=1
daemon=1
staking=0
maxconnections=150
externalip=[%s]
bind=[%s]:%d
masternodeaddr=[%s]:%d
`, RPCUser, RPCPassword, PRT, params.MasternodePort, folderCoin, IP, IP, params.MasternodePort, IP, params.MasternodePort)), 0600)
	if err != nil {
		_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
		utils.WrapErrorLog(err.Error())
		return err
	}
	utils.ReportMessage("Creating txsubmit file")
	err = os.WriteFile(fmt.Sprintf("%s/txsubmit.sh", folderCoin), []byte(fmt.Sprintf(`
#!/bin/bash

#######################################################################
# Config coin id
#######################################################################

coinID=%d
nodeID=X

#######################################################################
# Call API to submit transaction
#######################################################################

curl -X POST -H "node_id:\$nodeID" -H "tx_id:\$1" -H "coin_id:\$coinID" http://localhost:7466/submitTransaction`, params.CoinID)), 0755)
	if err != nil {
		_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
		utils.WrapErrorLog(err.Error())
		return err
	}
	utils.ReportMessage("Creating service file")
	err = os.WriteFile(fmt.Sprintf("%s/.config/systemd/user/%s%d.service", homeFolder, params.CoinFolder, num), []byte(fmt.Sprintf(`
[Unit]
Description=%sd
After=network.target
After=systemd-user-sessions.service
After=network-online.target

[Service]
Type=forking
ExecStart=%s/%s -datadir=%s
ExecStop=%s/%s -datadir=%s stop
TimeoutStartSec=180
Restart=on-failure
KillMode=process

[Install]
WantedBy=default.target`,
		params.CoinFolder, homeFolder, params.DaemonName, folderCoin, homeFolder, params.CliName, folderCoin)), 0600)
	if err != nil {
		_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
		utils.WrapErrorLog(err.Error())
		return err
	}

	err = exec.Command("systemctl", "--user", "daemon-reload").Run()
	if err != nil {
		_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
		utils.WrapErrorLog(err.Error())
		return err
	}
	err = exec.Command("systemctl", "--user", "enable", fmt.Sprintf("%s%d.service", params.CoinFolder, num)).Run()
	if err != nil {
		_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
		utils.WrapErrorLog(err.Error())
		return err
	}
	err = exec.Command("systemctl", "--user", "start", fmt.Sprintf("%s%d.service", params.CoinFolder, num)).Run()
	if err != nil {
		_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
		utils.WrapErrorLog(err.Error())
		return err
	}
	utils.ReportMessage("Starting daemon")

	nodeIP, err := exec.Command("bash", "-c", "ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\\.){3}[0-9]*).*/\\2/p'").Output()
	if err != nil {
		_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
		utils.WrapErrorLog(err.Error())
		log.Fatal(err)
	}
	walletUser := RPCUser
	walletPass := RPCPassword
	walletPort := PRT
	coinID := params.CoinID
	folder := params.CoinFolder + fmt.Sprintf("%d", num)
	conf := params.ConfigFile
	ip := IP
	mnPort := params.MasternodePort

	daemon := models.Daemon{
		ID:         0,
		WalletUser: walletUser,
		WalletPass: walletPass,
		WalletPort: walletPort,
		Folder:     folder,
		NodeID:     0,
		CoinID:     coinID,
		Conf:       conf,
		IP:         ip,
		MnPort:     mnPort,
		PassPhrase: sql.NullString{
			String: "",
		},
	}

	utils.ReportMessage("Getting new address")
	adr, err := coind.WrapDaemon(daemon, 20, "getnewaddress")
	if err != nil {
		_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
		utils.WrapErrorLog(errors.New("wallet coin id is unreachable").Error())
		return errors.New("wallet coin id is unreachable")
	}

	addr := strings.Trim(string(adr), "\"")

	if len(addr) == 0 {
		_, errScript := exec.Command("bash", "-c", fmt.Sprintf("./remove %s", folder)).Output()
		if errScript != nil {
			_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
			utils.WrapErrorLog(errScript.Error())
			return errors.New(fmt.Sprintf("Can't delete folder .%s", folder))

		}
		utils.WrapErrorLog("Error getting new address")
		return errors.New("Error getting new address")

	}

	utils.ReportMessage("Dumping private key")
	priv, err := coind.WrapDaemon(daemon, 5, "dumpprivkey", addr)
	if err != nil {
		_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
		utils.WrapErrorLog(errors.New("Wallet coin: Problem getting private key").Error())
		return errors.New("Wallet coin: Problem getting private key")
	}

	walletDeposit := strings.TrimSpace(addr)

	tx := &grpcModels.RegisterMasternodeRequest{
		WalletUSR:  strings.TrimSpace(walletUser),
		WalletPass: strings.TrimSpace(walletPass),
		WalletPort: uint32(walletPort),
		NodeIP:     strings.TrimSpace(string(nodeIP)),
		CoinID:     uint32(coinID),
		Folder:     folder,
		Address:    walletDeposit,
		Conf:       conf,
		Ip:         ip,
		PrivKey:    strings.Trim(string(priv), "\""),
		MnPort:     uint32(mnPort),
	}

	masternode, err := grpcClient.CallRegisterMN(tx)
	if err != nil {
		_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
		utils.WrapErrorLog(err.Error())
		return errors.New("Error registering masternode")
	}

	if masternode.Code == 200 {
		pathsc := utils.GetHomeDir() + "/." + folder + "/txsubmit.sh"
		_, errScript := exec.Command("bash", "-c", fmt.Sprintf("sed -i \"s/nodeID=X/nodeID=%d/g\" %s", masternode.NodeID, pathsc)).Output()
		if errScript != nil {
			_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
			utils.WrapErrorLog("Error changing node id in txsubmit.sh")
			return errors.New("Error changing node id in txsubmit.sh")
		}

		err = database.WriteDaemon(walletUser, walletPass, int64(walletPort), folder, int(masternode.NodeID), coinID, conf, ip, mnPort)
		if err != nil {
			_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
			utils.WrapErrorLog("Error writing daemon in database")
			return errors.New("Error writing daemon in database")
		}
		utils.ReportMessage(fmt.Sprintf("Masternode succesfully registered with id: %d", masternode.NodeID))
		return nil
	} else {
		_ = RemoveMN(fmt.Sprintf("%s%d", params.CoinFolder, num))
		utils.WrapErrorLog(fmt.Sprintf("Error registering masternode: Somethings fucked > %d", masternode.Code))
		return errors.New("Error registering masternode: Somethings fucked")
	}

}

func extractNumber(s string) (int, error) {
	var numStr strings.Builder

	for _, char := range s {
		if char >= '0' && char <= '9' {
			numStr.WriteRune(char)
		}
	}

	return strconv.Atoi(numStr.String())
}
