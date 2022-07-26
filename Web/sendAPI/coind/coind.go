package coind

import (
	_ "errors"
	"log"
	_ "strconv"
)

const (
	// VERSION represents bicoind package version
	VERSION = 0.1
	// RpcclientTimeout DEFAULT_RPCCLIENT_TIMEOUT represent http timeout for rcp client
	RpcclientTimeout = 30
)

// Coind A Bitcoind represents a Bitcoind client
type Coind struct {
	client *rpcClient
}

// New return a new bitcoind
func New(host string, port int, user, passwd string, useSSL bool, timeoutParam ...int) (*Coind, error) {
	var timeout = RpcclientTimeout
	// If the timeout is specified in timeoutParam, allow it.
	if len(timeoutParam) != 0 {
		timeout = timeoutParam[0]
	}

	rpcClient, err := newClient(host, port, user, passwd, useSSL, timeout)
	if err != nil {
		return nil, err
	} else {
		return &Coind{rpcClient}, nil
	}
}

func (b *Coind) Call(command string, par ...interface{}) ([]byte, error) {
	r, err := b.client.call(command, par)
	if err != nil {
		log.Println(err.Error())
		return nil, err
		//fmt.Printf("err: %v\n", err)
	}
	return r.Result, nil
}
