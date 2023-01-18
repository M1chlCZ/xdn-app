package tests

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/bmizerany/assert"
	"github.com/simplereach/timeutils"
	"log"
	"net/http"
	"testing"
	"xdn-voting/models"
)

func TestLogin(t *testing.T) {
	serverAddr := "https://dex.digitalnote.org/api/api/v1"
	user := models.UserLogin{
		Username: "usertest",
		Password: "A123456a",
	}
	logData, _ := json.Marshal(user)
	writer, _ := http.Post(fmt.Sprintf("%s%s", serverAddr, "/login"), "application/json", bytes.NewBuffer(logData))

	assert.Equal(t, http.StatusOK, writer.StatusCode)

	var response map[string]interface{}
	err := json.NewDecoder(writer.Body).Decode(&response)
	if err != nil {
		t.Fatal(err)
	}

	_, token := response["token"]

	assert.Equal(t, true, token)

	_, refresh := response["refresh_token"]

	assert.Equal(t, true, refresh)
}

func BenchmarkAPI(b *testing.B) {
	serverAddr := "https://dex.digitalnote.org/api/api/v1"
	user := models.UserLogin{
		Username: "usertest",
		Password: "A123456a",
	}
	logData, _ := json.Marshal(user)
	writer, _ := http.Post(fmt.Sprintf("%s%s", serverAddr, "/login"), "application/json", bytes.NewBuffer(logData))
	var response map[string]interface{}
	err := json.NewDecoder(writer.Body).Decode(&response)
	if err != nil {
		b.Fatal(err)
	}

	shit, _ := response["token"]

	serverAddr = "https://dex.digitalnote.org/api/api/v1"
	var GetStakeStruct struct {
		Type     int    `json:"type"`
		Datetime string `json:"datetime"`
	}
	GetStakeStruct.Type = 1
	GetStakeStruct.Datetime = timeutils.Time{}.Format("2006-01-02")

	js, _ := json.Marshal(GetStakeStruct)

	for i := 0; i < b.N; i++ {
		log.Println(i)
		r, err := http.NewRequest("GET", fmt.Sprintf("%s/%s", serverAddr, "masternode/info"), bytes.NewBuffer(js))
		if err != nil {
			panic(err)
		}

		r.Header.Add("Content-Type", "application/json")
		r.Header.Add("Authorization", fmt.Sprintf("Bearer %s", shit))

		client := &http.Client{}
		res, err := client.Do(r)
		if err != nil {
			panic(err)
		}
		log.Println(fmt.Sprintf("%+v", res.Body))
		//unmashal body to struct
		//var resp map[string]interface{}
		//err = json.NewDecoder(res.Body).Decode(&resp)
		//if err != nil {
		//	b.Fatal(err)
		//}
		//log.Println(fmt.Sprintf("%+v", resp))
		defer res.Body.Close()

	}
}
