package main

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/gofiber/fiber/v2"
	"golang.org/x/net/context"
	"log"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"
	"xdn-masternode/coind"
	"xdn-masternode/database"
	"xdn-masternode/fn"
	"xdn-masternode/grpcClient"
	"xdn-masternode/grpcModels"
	"xdn-masternode/grpcServer"
	"xdn-masternode/models"
	"xdn-masternode/utils"
)

func main() {
	utils.ReportMessage(fmt.Sprintf("XDN MN API v%s", utils.VERSION))

	utils.ReportMessage("Connecting to server...")
	errorRetry := utils.Retry(5, time.Second*10, setupSecureMNChannel)
	if errorRetry == nil {
		utils.ReportMessage("Connected to server")

		// Start GRPC Server
		go grpcServer.NewServer()

		appWallet := fiber.New(fiber.Config{AppName: "XDN MN API", StrictRouting: true})
		appWallet.Post("/txsubmit", submitTransaction)
		appWallet.Post("/masternode/register", registerMasternode)

		_ = utils.ScheduleFunc(fn.ScanMasternodes, time.Minute*60)

		go func() {
			err := appWallet.Listen("127.0.0.1:6600")
			if err != nil {
				utils.WrapErrorLog(err.Error())
				panic(err)
			}
		}()

		c := make(chan os.Signal, 1)
		signal.Notify(c, syscall.SIGTERM, syscall.SIGINT)

		<-c
		_, cancel := context.WithTimeout(context.Background(), time.Second*10)
		utils.ReportMessage("/// = = Shutting down = = ///")
		defer cancel()
		_ = appWallet.Shutdown()
		os.Exit(0)
	}
	utils.WrapErrorLog("Couldn't connect to server")
}

// FUNCTION HANDLERS
func setupSecureMNChannel() error {
	ping, err := grpcClient.Ping(&grpcModels.PingRequest{NodeID: 1})
	if err != nil {
		utils.ReportMessage("Ping to Server -> Failed!")
		utils.WrapErrorLog(fmt.Sprintf("err: %v\n", err))
		return err
	}
	if ping.Code == 200 {
		utils.ReportMessage("Ping to Server -> Success!")
	}
	getJWT, _ := database.GetEnc()
	if len(getJWT) != 0 {
		utils.ReportMessage("Already registered")
		return nil
	} else {
		utils.ReportMessage("Registering...")
	}
	url, err := exec.Command("bash", "-c", "ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\\.){3}[0-9]*).*/\\2/p'").Output()
	if err != nil {
		utils.WrapErrorLog(err.Error())
		log.Fatal(err)
	}

	jwtString := utils.GenerateSecureToken(8)
	errSQL := database.WriteJWT(jwtString)
	if errSQL != nil {
		utils.WrapErrorLog(fmt.Sprintf("DB PROBLEM: %s", errSQL.Error()))
		return errSQL
	}

	token, errToken := utils.CreateToken(8)
	if errToken != nil {
		utils.WrapErrorLog(fmt.Sprintf("err: %v\n", errToken))
		//log.Printf("err: %v\n", errToken)
		return errToken
	}
	tx := grpcModels.RegisterRequest{
		Token: token,
		Url:   strings.TrimSpace(string(url)),
	}
	utils.ReportMessage("Calling GRPC")
	response, err := grpcClient.CallRegisterRequest(&tx)
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("err: %v\n", err))
		return err
	}
	if response.Code != 200 {
		utils.WrapErrorLog(fmt.Sprintf("err: %v\n", response.Code))
		return errors.New(fmt.Sprintf("Server Status Code: %d", response.Code))
	}

	database.WriteToken(response.Encrypt)
	//getSnap() //TODO: uncomment
	return nil

}

// REST API HANDLERS
func registerMasternode(c *fiber.Ctx) error {
	nodeIP, err := exec.Command("bash", "-c", "ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\\.){3}[0-9]*).*/\\2/p'").Output()
	if err != nil {
		log.Fatal(err)
	}
	walletUser := c.Get("wallet_usr")
	walletPass := c.Get("wallet_pass")
	walletP := c.Get("wallet_port")
	walletPort, _ := strconv.Atoi(walletP)
	coinI := c.Get("coin_id")
	coinID, _ := strconv.Atoi(coinI)
	folder := c.Get("folder")
	conf := c.Get("conf_file")
	ip := c.Get("node_ip")
	mnPort, _ := strconv.Atoi(c.Get("mn_port"))

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

	adr, err := coind.WrapDaemon(daemon, 20, "getnewaddress")
	if err != nil {
		return utils.ReportError(c, "Wallet coin id is unreachable", http.StatusInternalServerError)
	}

	addr := strings.Trim(string(adr), "\"")

	if len(addr) == 0 {
		_, errScript := exec.Command("bash", "-c", fmt.Sprintf("./remove %s", folder)).Output()
		if errScript != nil {
			log.Println(errScript.Error())
			return utils.ReportError(c, fmt.Sprintf("Can't delete folder .%s", folder), http.StatusInternalServerError)

		}
		return utils.ReportError(c, "Error getting new address", http.StatusInternalServerError)

	}
	priv, err := coind.WrapDaemon(daemon, 5, "dumpprivkey", addr)
	if err != nil {
		return utils.ReportError(c, "Wallet coin id is unreachable", http.StatusInternalServerError)
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
		MnPort:     uint32(mnPort),
		PrivKey:    strings.Trim(string(priv), "\""),
	}
	resp, err := grpcClient.CallRegisterMN(tx)

	if resp.Code == 200 {
		pathsc := utils.GetHomeDir() + "/." + folder + "/txsubmit.sh"
		_, errScript := exec.Command("bash", "-c", fmt.Sprintf("sed -i \"s/nodeID=X/nodeID=%d/g\" %s", resp.NodeID, pathsc)).Output()
		if errScript != nil {
			return utils.ReportError(c, errScript.Error(), http.StatusInternalServerError)

		}
		err = database.WriteDaemon(walletUser, walletPass, int64(walletPort), folder, int(resp.NodeID), coinID, conf, ip, mnPort)
		if err != nil {
			return utils.ReportError(c, err.Error(), http.StatusInternalServerError)

		}
		return c.Status(200).JSON(fiber.Map{
			"code": resp.Code,
		})
	} else {
		return utils.ReportError(c, "Somethings fucked", http.StatusInternalServerError)

	}
}

func submitTransaction(c *fiber.Ctx) error {
	txid := c.Get("tx_id", "unknown")
	if txid == "unknown" {
		return utils.ReportError(c, "txid is unknown", fiber.StatusBadRequest)
	}
	nodeID, err := strconv.Atoi(c.Get("node_id", "unknown"))
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("err: %v\n", err))
		return utils.ReportError(c, "node id is unknown", fiber.StatusBadRequest)
	}
	coinID, err := strconv.Atoi(c.Get("coin_id", "unknown"))
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("err: %v\n", err))
		return utils.ReportError(c, "node id is unknown", fiber.StatusBadRequest)
	}
	utils.ReportMessage(fmt.Sprintf("txid: %s, node id: %d, coin id: %d", txid, nodeID, coinID))
	daemon, err := database.GetDaemon(nodeID)
	var ing models.GetTransactionXDN
	p, er := coind.WrapDaemon(*daemon, 5, "gettransaction", txid)
	if er != nil {
		log.Println("error transaction" + er.Error())
		return utils.ReportError(c, "Wallet coin id is unreachable", http.StatusInternalServerError)
	}
	errJson := json.Unmarshal(p, &ing)
	if errJson != nil {
		log.Println("error json " + errJson.Error())
		return utils.ReportError(c, "JSON is unparseable", http.StatusInternalServerError)

	}

	amount := ing.Amount
	if ing.Generated == true {
		amount = 150
	}

	tx := grpcModels.SubmitRequest{
		TxId:      ing.Txid,
		NodeId:    uint32(nodeID),
		Generated: ing.Generated,
		Amount:    amount,
		IdCoin:    uint32(coinID),
	}

	response, err := grpcClient.CallSubmitTX(&tx)
	if err != nil {
		return utils.ReportError(c, err.Error(), http.StatusInternalServerError)
	}
	return c.Status(200).JSON(fiber.Map{
		"code": response.Code,
	})
}
