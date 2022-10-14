package web3

import (
	"encoding/hex"
	"fmt"
	"github.com/chenzhijie/go-web3"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"math/big"
	"strconv"
	"time"
	"xdn-voting/abi"
	"xdn-voting/utils"
)

var rpc *WB

type WB struct {
	*web3.Web3
}

func New() {
	var err error
	var rpcProviderURL = "https://greatest-flashy-silence.bsc.discover.quiknode.pro/780e1c3203b78046ad73e463c8ab9ae218a743b8/"
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
	name := "WXDN balanceOf"
	start := time.Now()
	elapsed := time.Since(start)
	valid := utils.Erc20verify(address)
	if !valid {
		return 0, fmt.Errorf("invalid erc20 address")
	}
	addr := common.HexToAddress(address)
	contract, err := rpc.Eth.NewContract(abi.WXDN, abi.WXDNContract)
	if err != nil {
		return 0, err
	}

	c, err := contract.Call("balanceOf", addr)
	if err != nil {
		return 0, err
	}

	//convert c to int64
	//convert
	bal := c.(*big.Int)
	b := WeiToString(bal)

	utils.ReportMessage(fmt.Sprintf("Balance: %f", b))
	utils.ReportMessage(fmt.Sprintf("%s took %s", name, elapsed))
	return b, nil
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
