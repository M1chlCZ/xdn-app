package utils

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"
)

const (
//VERSION = "0.0.0.1"

// STATUS string = "status"
// OK     string = "OK"
// FAIL   string = "FAIL"
// POST   string = "POST"
// GET_REQ    string = "GET_REQ"
// ERROR  string = "hasError"
)

func GetReq(url string, token string) (*http.Response, *GetError) {
	urlGet := "https://app.rocketbot.pro/api/mobile/" + url
	var jsonStr = []byte("{}")
	req, err := http.NewRequest("GET", urlGet, bytes.NewBuffer(jsonStr))
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("User-agent", "XDN Service v"+VERSION)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		_ = req.Body.Close()
		client.CloseIdleConnections()
		return nil, &GetError{message: err.Error(), statusCode: http.StatusInternalServerError}
	}

	//fmt.Println("response Status:", resp.StatusCode)
	//fmt.Println("response Headers:", resp.Header)
	//fmt.Println("response body:", resp.Body)
	if resp.StatusCode != 200 {
		_ = req.Body.Close()
		_ = resp.Body.Close()
		client.CloseIdleConnections()
		return nil, &GetError{message: resp.Status, statusCode: http.StatusUnauthorized}
	}
	_ = req.Body.Close()
	client.CloseIdleConnections()
	return resp, nil
}

func GETAny(url string) (*http.Response, *GetError) {
	urlGet := url
	var jsonStr = []byte("{}")
	req, err := http.NewRequest("GET", urlGet, bytes.NewBuffer(jsonStr))
	req.Header.Set("User-agent", "XDN Service v"+VERSION)
	req.Header.Set("Content-Type", "plain/text")
	req.Header.Set("Connection", "close")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		_ = req.Body.Close()
		client.CloseIdleConnections()
		return nil, &GetError{message: err.Error(), statusCode: http.StatusInternalServerError}
	}

	//fmt.Println("response Status:", resp.StatusCode)
	//fmt.Println("response Headers:", resp.Header)
	//fmt.Println("response body:", resp.Body)
	if resp.StatusCode != 200 {
		_ = req.Body.Close()
		_ = resp.Body.Close()
		client.CloseIdleConnections()
		return nil, &GetError{message: resp.Status, statusCode: http.StatusUnauthorized}
	}
	_ = req.Body.Close()
	client.CloseIdleConnections()
	return resp, nil
}

func POSTReq(url string, body map[string]string) (*http.Response, *GetError) {
	urlGet := url
	var jsonStr, _ = json.Marshal(body)
	req, err := http.NewRequest("POST", urlGet, bytes.NewBuffer(jsonStr))
	req.Header.Set("User-agent", "XDN Service v"+VERSION)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Connection", "close")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		_ = req.Body.Close()
		client.CloseIdleConnections()
		return nil, &GetError{message: err.Error(), statusCode: http.StatusInternalServerError}
	}

	//fmt.Println("response Status:", resp.StatusCode)
	//fmt.Println("response Headers:", resp.Header)
	//fmt.Println("response body:", resp.Body)
	if resp.StatusCode != 200 {
		_ = req.Body.Close()
		_ = resp.Body.Close()
		client.CloseIdleConnections()
		return nil, &GetError{message: resp.Status, statusCode: resp.StatusCode}
	}
	_ = req.Body.Close()
	client.CloseIdleConnections()
	return resp, nil
}

func ContactServer(url string, endpoint string, json []byte) (*http.Response, *GetError) {
	urlGet := "http://" + strings.TrimSpace(url) + ":7465" + endpoint
	//fmt.Println(urlGet)
	var jsonStr = json
	req, err := http.NewRequest("POST", urlGet, bytes.NewBuffer(jsonStr))
	if err != nil {
		return nil, &GetError{message: err.Error(), statusCode: http.StatusInternalServerError}
	}
	req.Header.Set("User-agent", "XDN Service v"+VERSION)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Connection", "close")

	client := &http.Client{}
	resp, errD := client.Do(req)
	if errD != nil {
		_ = req.Body.Close()
		client.CloseIdleConnections()
		return nil, &GetError{message: errD.Error(), statusCode: http.StatusInternalServerError}
	}

	if resp.StatusCode != 200 {
		fmt.Println("response Status:", resp.StatusCode)
		fmt.Println("response Headers:", resp.Header)
		_ = req.Body.Close()
		_ = resp.Body.Close()
		client.CloseIdleConnections()
		return nil, &GetError{message: resp.Status, statusCode: http.StatusUnauthorized}
	}
	_ = req.Body.Close()
	client.CloseIdleConnections()
	return resp, nil
}

func ContactServerRetry(url string, endpoint string, json []byte) error {
	urlGet := "http://" + strings.TrimSpace(url) + ":7465" + endpoint
	var jsonStr = json
	//fmt.Println(urlGet)
	req, err := http.NewRequest("POST", urlGet, bytes.NewBuffer(jsonStr))
	if err != nil {
		_ = req.Body.Close()
		return errors.New(err.Error())
		//return &GetError{message: err.Error(), statusCode: http.StatusInternalServerError}
	}
	req.Header.Set("User-agent", "XDN Service v"+VERSION)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Connection", "close")

	client := &http.Client{}
	resp, errD := client.Do(req)
	if errD != nil {
		_ = req.Body.Close()
		return errors.New(fmt.Sprintf("%d", resp.StatusCode))
		//return nil, &GetError{message: errD.Error(), statusCode: http.StatusInternalServerError}
	}

	if resp.StatusCode != 200 {
		_ = req.Body.Close()
		_ = resp.Body.Close()
		client.CloseIdleConnections()
		return errors.New(fmt.Sprintf("%d", resp.StatusCode))
		//return nil, &GetError{message: resp.Status, statusCode: http.StatusUnauthorized}
	}
	_ = req.Body.Close()
	_ = resp.Body.Close()
	client.CloseIdleConnections()
	return nil
}

func ContactServerEncrypt(url string, endpoint string, json []byte, urlSc string) (*http.Response, error) {
	urlGet := "http://" + strings.TrimSpace(url) + ":7465" + endpoint
	var jsonStr = json
	//fmt.Println(urlGet)
	req, err := http.NewRequest("POST", urlGet, bytes.NewBuffer(jsonStr))
	if err != nil {
		return nil, errors.New(err.Error())
		//return &GetError{message: err.Error(), statusCode: http.StatusInternalServerError}
	}
	req.Header.Set("User-agent", "XDN Service v"+VERSION)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("url", urlSc)

	client := &http.Client{}
	resp, errD := client.Do(req)
	if errD != nil {
		_ = req.Body.Close()
		client.CloseIdleConnections()
		return nil, errors.New(fmt.Sprintf("%d", resp.StatusCode))
		//return nil, &GetError{message: errD.Error(), statusCode: http.StatusInternalServerError}
	}

	if resp.StatusCode != 200 {
		_ = req.Body.Close()
		_ = resp.Body.Close()
		client.CloseIdleConnections()
		return nil, errors.New(fmt.Sprintf("%d", resp.StatusCode))
		//return nil, &GetError{message: resp.Status, statusCode: http.StatusUnauthorized}
	}
	_ = req.Body.Close()
	client.CloseIdleConnections()
	return resp, nil
}

func ContactClient(url string, endpoint string, token string, json []byte, params ...string) (*http.Response, *GetError) {
	urlGet := "http://" + strings.TrimSpace(url) + ":7466" + endpoint
	//fmt.Println(urlGet)
	var method = http.MethodPost
	var jsonStr = json
	if len(params) != 0 {
		method = http.MethodGet
	}
	req, err := http.NewRequest(method, urlGet, bytes.NewBuffer(jsonStr))
	if err != nil {
		_ = req.Body.Close()
		return nil, &GetError{message: err.Error(), statusCode: http.StatusInternalServerError}
	}
	req.Header.Set("User-agent", "XDN Service v"+VERSION)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))

	client := &http.Client{}
	resp, errD := client.Do(req)
	if errD != nil {
		_ = req.Body.Close()
		client.CloseIdleConnections()
		return nil, &GetError{message: errD.Error(), statusCode: http.StatusInternalServerError}
	}

	if resp.StatusCode != 200 {
		fmt.Println("response Status:", resp.StatusCode)
		fmt.Println("response Headers:", resp.Header)
		_ = req.Body.Close()
		_ = resp.Body.Close()
		client.CloseIdleConnections()
		//WrapErrorLog(err.Error())
		return nil, &GetError{message: resp.Status, statusCode: http.StatusUnauthorized}
	}
	_ = req.Body.Close()
	client.CloseIdleConnections()
	return resp, nil
}

func Retry(attempts int, sleep time.Duration, f func() error) (err error) {
	errorChan := make(chan error)
	go func() {
		for i := 0; i < attempts; i++ {
			errorChan <- f()
			if err != nil {
				fmt.Println("This was attempt number", i+1)
				fmt.Println(colorRed, fmt.Sprintf("error occured after attempt %d from %d: %s", i+1, attempts, err.Error()))
				//fmt.Println(string(colorRed), errorovia[i])
				fmt.Print(colorReset, "")
				//log.Printf("error occured after attempt number %d: %s", i+1, err.Error())
				fmt.Println("sleeping for: ", sleep.String())
				time.Sleep(sleep)
				//sleep *= 2
				continue
			}
			break
		}
	}()

	select {
	case err := <-errorChan:
		return err
	}
}

func RetryServer(attempts int, sleep time.Duration, serverURL string, endpoint string, payload []byte) (err error) {
	for i := 0; i < attempts; i++ {
		err = ContactServerRetry(serverURL, endpoint, payload)
		if err != nil && err.Error() != "409" {
			fmt.Println("This was attempt number", i+1)
			fmt.Println(colorRed, fmt.Sprintf("error occured after attempt %d from %d: %s", i+1, attempts, err.Error()))
			//fmt.Println(string(colorRed), errorovia[i])
			fmt.Print(colorReset, "")
			//log.Printf("error occured after attempt number %d: %s", i+1, err.Error())
			fmt.Println("sleeping for: ", sleep.String())
			time.Sleep(sleep)
			//sleep *= 2
			continue
		}
		break
	}
	if err == nil {
		return nil
	} else if err.Error() == "409" {
		return nil
	} else {
		return err
	}
}

func RetryServerPayload(attempts int, sleep time.Duration, serverURL string, endpoint string, payload []byte, url string) (response *http.Response, err error) {
	var resp *http.Response
	for i := 0; i < attempts; i++ {
		resp, err = ContactServerEncrypt(serverURL, endpoint, payload, url)
		if err != nil && err.Error() != "409" {
			fmt.Println("This was attempt number", i+1)
			fmt.Println(colorRed, fmt.Sprintf("error occured after attempt %d from %d: %s", i+1, attempts, err.Error()))
			//fmt.Println(string(colorRed), errorovia[i])
			fmt.Print(colorReset, "")
			//log.Printf("error occured after attempt number %d: %s", i+1, err.Error())
			fmt.Println("sleeping for: ", sleep.String())
			time.Sleep(sleep)
			//sleep *= 2
			continue
		}
		break
	}

	if err == nil {
		return resp, nil
	} else {
		return nil, err
	}
}

func IPv6Equal(ip1, ip2 string) bool {
	// Parse IP addresses and CIDR notation
	cidrNum := 0
	if strings.Contains(ip1, "/") {
		cidrNum, _ = strconv.Atoi(strings.Split(ip1, "/")[1])
	}

	if strings.Contains(ip2, "/") {
		cidrNum, _ = strconv.Atoi(strings.Split(ip2, "/")[1])
	}
	addr1, net1, err1 := net.ParseCIDR(ip1)
	if err1 != nil {
		addr1 = net.ParseIP(ip1)
		net1 = &net.IPNet{IP: addr1, Mask: net.CIDRMask(cidrNum, 128)}
	}

	addr2, net2, err2 := net.ParseCIDR(ip2)
	if err2 != nil {
		addr2 = net.ParseIP(ip2)
		net2 = &net.IPNet{IP: addr2, Mask: net.CIDRMask(cidrNum, 128)}
	}

	if addr1 == nil || addr2 == nil {
		return false
	}

	// Check if addresses are in the same subnet
	return net1.Contains(addr2) && net2.Contains(addr1)
}

//fn DecryptRequest(r *http.Request, url string) ([]byte, string, error) {
//	var urlNode string
//	cryptKey, errCrypt := database.ReadRow[string]("SELECT encryptKey FROM masternodes WHERE url = ?", urlNode, url)
//	if errCrypt != nil {
//		WrapErrorLog(errCrypt.Error())
//		return nil, "", errCrypt
//	}
//
//	body, err := io.ReadAll(r.Body)
//	bodyString := string(body)
//
//	message, err := DecryptMessage([]byte(cryptKey), bodyString)
//	if err != nil {
//		WrapErrorLog(err.Error())
//		return nil, "", err
//	}
//
//	return []byte(message), cryptKey, nil
//}
