package web3

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/chenzhijie/go-web3"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"math/big"
	"strconv"
	"xdn-voting/abi"
	"xdn-voting/errs"
	"xdn-voting/models"
	"xdn-voting/utils"
)

var rpc *WB

type WB struct {
	*web3.Web3
}

func New() {
	var err error
	var rpcProviderURL = "https://bsc-dataseed1.binance.org/"
	wb, err := web3.NewWeb3(rpcProviderURL)
	if err != nil {
		panic(err)
	}
	blockNumber, err := wb.Eth.GetBlockNumber()
	if err != nil {
		panic(err)
	}
	fmt.Println("Current block number: ", blockNumber)
	rpc = &WB{wb}
}

func GetBlockNumber() (uint64, error) {
	return rpc.Eth.GetBlockNumber()
}

func CreateAddress() string {
	pv, err := crypto.GenerateKey()
	if err != nil {
		panic(err)
	}
	privateKey := hex.EncodeToString(crypto.FromECDSA(pv))
	err = rpc.Eth.SetAccount(privateKey)
	if err != nil {
		panic(err)
	}

	addr := crypto.PubkeyToAddress(pv.PublicKey)
	return addr.Hex()
}

func GetBalance(address string) (*big.Int, error) {
	addr := common.HexToAddress(address)
	return rpc.Eth.GetBalance(addr, nil)
}

func GetContractBalance(address string) (float64, error) {
	d := make(chan float64, 1)
	e := make(chan error, 1)
	go func(data chan float64, errChan chan error) {

		valid := utils.Erc20verify(address)
		if !valid {
			errChan <- fmt.Errorf("invalid erc20 address")
		}
		addr := common.HexToAddress(address)
		contract, err := rpc.Eth.NewContract(abi.WXDN, abi.WXDNContract)
		if err != nil {
			errChan <- err
		}

		c, err := contract.Call("balanceOf", addr)
		if err != nil {
			errChan <- err
		}

		bal := c.(*big.Int)
		b := WeiToString(bal)

		data <- b
	}(d, e)
	select {
	case data := <-d:
		close(d)
		close(e)
		return data, nil
	case err := <-e:
		close(d)
		close(e)
		return 0, err
	}
}

func WeiToString(amount *big.Int) float64 {
	compactAmount := big.NewInt(0)
	reminder := big.NewInt(0)
	divisor := big.NewInt(1e18)
	compactAmount.QuoRem(amount, divisor, reminder)
	s := fmt.Sprintf("%v.%v", compactAmount.String(), reminder.String())
	fl, err := strconv.ParseFloat(s, 64)
	if err != nil {
		return 0
	}
	return fl
}

func GetTokenTx(address string) (models.BSCTokenTX, error) {
	resp, getError := utils.POSTReq(fmt.Sprintf("https://api.bscscan.com/api?module=account&action=tokentx&address=%s&startblock=0&endblock=99999999&page=1&offset=100&sort=desc&apikey=XYWQ68CD5T5PTZEIG65ECMMAVGZD3TDQ5S", address), nil)
	if getError != nil {
		utils.WrapErrorLog(getError.ErrorMessage())
		return models.BSCTokenTX{}, errors.New(getError.ErrorMessage())
	}
	decGet := json.NewDecoder(resp.Body)
	decGet.DisallowUnknownFields()

	var respBody models.BSCTokenTX
	errJson := decGet.Decode(&respBody)
	errorJson, errorMessage := errs.ValidateJson(errJson)
	if errorJson == true {
		utils.WrapErrorLog(errorMessage)
		return models.BSCTokenTX{}, errors.New(errorMessage)
	}

	return respBody, nil
}
