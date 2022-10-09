package web3

import (
	"encoding/hex"
	"fmt"
	"github.com/chenzhijie/go-web3"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"math/big"
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
