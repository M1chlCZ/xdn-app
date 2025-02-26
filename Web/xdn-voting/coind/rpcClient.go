package coind

import (
	"bytes"
	"context"
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"
	"xdn-voting/utils"
)

// A rpcClient represents a JSON RPC client (over HTTP(s)).
type rpcClient struct {
	serverAddr string
	user       string
	passwd     string
	httpClient *http.Client
	timeout    int
}

// rpcRequest represent a RCP request
type rpcRequest struct {
	Method  string      `json:"method"`
	Params  interface{} `json:"params"`
	Id      int64       `json:"id"`
	JsonRpc string      `json:"jsonrpc"`
}

// RPCErrorCode represents an error code to be used as a part of an RPCError
// which is in turn used in a JSON-RPC Response object.
//
// A specific type is used to help ensure the wrong errs aren't used.
type RPCErrorCode int

// RPCError represents an error that is used as a part of a JSON-RPC Response
// object.
type RPCError struct {
	Code    RPCErrorCode `json:"code,omitempty"`
	Message string       `json:"message,omitempty"`
}

// Guarantee RPCError satisfies the builtin error interface.
var _, _ error = RPCError{}, (*RPCError)(nil)

// Error returns a string describing the RPC error.  This satisfies the
// builtin error interface.
func (e RPCError) Error() string {
	return fmt.Sprintf("%d: %s", e.Code, e.Message)
}

type rpcResponse struct {
	Id     int64           `json:"id"`
	Result json.RawMessage `json:"result"`
	Err    *RPCError       `json:"error"`
}

func newClient(host string, port int, user, passwd string, useSSL bool, timeout int) (c *rpcClient, err error) {
	if len(host) == 0 {
		err = errors.New("Bad call missing argument host")
		return
	}
	var serverAddr string
	var httpClient *http.Client
	if useSSL {
		serverAddr = "https://"
		t := &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		}
		httpClient = &http.Client{Transport: t, Timeout: time.Duration(timeout) * time.Second}
	} else {
		serverAddr = "http://"
		httpClient = &http.Client{Timeout: time.Duration(timeout) * time.Second}
	}
	c = &rpcClient{serverAddr: fmt.Sprintf("%s%s:%d", serverAddr, host, port), user: user, passwd: passwd, httpClient: httpClient, timeout: timeout}
	return
}

// doTimeoutRequest process a HTTP request with timeout
func (c *rpcClient) doTimeoutRequest(timer *time.Timer, req *http.Request) (*http.Response, error) {
	type result struct {
		resp *http.Response
		err  error
	}
	done := make(chan result, 1)
	go func() {
		resp, err := c.httpClient.Do(req)
		done <- result{resp, err}
	}()
	// Wait for the read or the timeout
	select {
	case r := <-done:
		return r.resp, r.err
	case <-timer.C:
		return nil, errors.New("timeout reading data from server")
	}
}

// call prepare & exec the request
func (c *rpcClient) call(method string, params any) (rr rpcResponse, err error) {
	//connectTimer := time.NewTimer(time.Duration(c.timeout) * time.Second)
	ctx, cnc := context.WithTimeout(context.Background(), time.Duration(c.timeout)*time.Second)
	defer cnc()

	rpcR := rpcRequest{method, params, time.Now().UnixNano(), "2.0"}
	payloadBuffer := &bytes.Buffer{}
	jsonEncoder := json.NewEncoder(payloadBuffer)
	err = jsonEncoder.Encode(rpcR)
	if err != nil {
		utils.ReportMessage(fmt.Sprintf("Error encoding JSON RPC request %s", err.Error()))
		return
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.serverAddr, payloadBuffer)
	if err != nil {
		utils.ReportMessage(fmt.Sprintf("Error encoding JSON RPC request %s", err.Error()))
		return
	}
	req.Header.Add("Content-Type", "application/json;charset=utf-8")
	req.Header.Add("Accept", "application/json")

	// Auth ?
	if len(c.user) > 0 || len(c.passwd) > 0 {
		req.SetBasicAuth(c.user, c.passwd)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		utils.ReportMessage(fmt.Sprintf("Error encoding JSON RPC request %s", err.Error()))
		_ = req.Body.Close()
		return
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		utils.ReportMessage(fmt.Sprintf("Error encoding JSON RPC request %s", err.Error()))
		_ = resp.Body.Close()
		_ = req.Body.Close()
		return
	}
	if resp.StatusCode != 200 {
		utils.ReportMessage(fmt.Sprintf("RPC response: %s", string(data)))
		utils.ReportMessage(fmt.Sprintf("RPC response: %d", resp.StatusCode))
	}

	_ = resp.Body.Close()
	_ = req.Body.Close()
	err = json.Unmarshal(data, &rr)
	return
}
