package main

import (
	"encoding/json"
	"fmt"
	"github.com/gofiber/fiber/v2"
	"sendAPI/coind"
	"sendAPI/models"
	"sendAPI/utils"
	_ "sendAPI/utils"
	"strings"
)

var client *coind.Coind

func main() {
	app := fiber.New()
	var errClient error
	client, errClient = coind.New("127.0.0.1", 18094, "yourusername", "gMFJfFGFuJpbPGVXD5FQZWoYqWBX6LXk", false, 30)
	if errClient != nil {
		utils.ReportMessage(errClient.Error())
		//utils.ReportError(w, "Wallet coin id is unreachable", http.StatusInternalServerError)
		//return
	}

	app.Get("/hello", func(c *fiber.Ctx) error {
		return c.SendString("Hello, World 👋!")
	})
	app.Post("/send", sendCoin)

	err := app.Listen("127.0.0.1:6900")
	if err != nil {
		return
	}
}

func sendCoin(c *fiber.Ctx) error {
	payload := struct {
		AddressSend    string  `json:"address_send"`
		AddressReceive string  `json:"address_receive"`
		Amount         float64 `json:"amount"`
	}{}

	if err := c.BodyParser(&payload); err != nil {
		return err
	}

	call, err := client.Call("listunspent")
	if err != nil {
		utils.ReportMessage(err.Error())
	}

	var ing []models.ListUnspent
	errJson := json.Unmarshal(call, &ing)
	if errJson != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
			"success": false,
			"error":   errJson.Error(),
		})
	}
	totalCoins := 0.0
	myUnspent := make([]models.ListUnspent, 0)
	for _, unspent := range ing {
		if unspent.Address == payload.AddressReceive {
			if unspent.Spendable == true {
				utils.ReportMessage(fmt.Sprintf("Found unspent coin: %f", unspent.Amount))
				totalCoins += unspent.Amount
				myUnspent = append(myUnspent, unspent)
			}
		}
	}

	inputs := make([]models.ListUnspent, 0)
	inputsAmount := 0.0
	for _, spent := range myUnspent {
		inputsAmount += spent.Amount
		inputs = append(inputs, spent)
		if inputsAmount > payload.Amount {
			break
		}
	}

	inputsCount := len(inputs)
	fee := 0.0001 * float64(inputsCount)
	txBack := inputsAmount - fee - payload.Amount

	if totalCoins <= (payload.Amount + fee) {
		return c.Status(fiber.StatusConflict).JSON(&fiber.Map{
			"success": false,
			"error":   "not enough coins",
		})
	}

	var firstParam []models.RawTxArray
	for _, input := range inputs {
		fparam := models.RawTxArray{
			Txid: input.Txid,
			Vout: input.Vout,
		}
		firstParam = append(firstParam, fparam)
	}

	secondParam := map[string]interface{}{
		payload.AddressSend:    payload.Amount,
		payload.AddressReceive: txBack}

	utils.ReportMessage(fmt.Sprintf("firstParam: %v secondParam %v", firstParam, secondParam))

	call, err = client.Call("createrawtransaction", firstParam, secondParam)
	if err != nil {
		utils.ReportMessage(err.Error())
		return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
			"success": false,
			"error":   "createrawtransaction Error",
		})
	}
	utils.ReportMessage(fmt.Sprintf("createrawtransaction: %s", string(call)))

	hex := strings.Trim(string(call), "\"")

	call, err = client.Call("signrawtransaction", hex)
	if err != nil {
		utils.ReportMessage(err.Error())
		return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
			"success": false,
			"error":   "signrawtransaction Error",
		})
	}
	utils.ReportMessage(fmt.Sprintf("signrawtransaction: %s", string(call)))

	var sign models.SignRawTransaction
	errJson = json.Unmarshal(call, &sign)
	if errJson != nil {
		utils.ReportMessage(errJson.Error())
		return errJson
	}

	call, err = client.Call("sendrawtransaction", sign.Hex)
	if err != nil {
		utils.ReportMessage(err.Error())
		return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
			"success": false,
			"error":   "sendrawtransaction Error",
		})
	}
	utils.ReportMessage(fmt.Sprintf("sendrawtransaction: %s", string(call)))

	tx := strings.Trim(string(call), "\"")
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"success": true,
		"tx":      tx,
	})
}
