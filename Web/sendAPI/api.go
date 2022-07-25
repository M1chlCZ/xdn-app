package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"github.com/gofiber/fiber/v2"
	"github.com/jmoiron/sqlx"
	"log"
	"sendAPI/coind"
	"sendAPI/database"
	"sendAPI/models"
	"sendAPI/utils"
	"strings"
)

var client *coind.Coind

func main() {
	app := fiber.New()
	var errClient error
	client, errClient = coind.New("127.0.0.1", 18094, "yourusername", "gMFJfFGFuJpbPGVXD5FQZWoYqWBX6LXk", false, 30)
	if errClient != nil {
		utils.ReportMessage(errClient.Error())
		panic(errClient)
		return
	}

	db, errDB := sqlx.Open("mysql", "xndUser:TEgZ6vjtEj2n&s@tcp(127.0.0.1:3306)/mobile?parseTime=true")
	if errDB != nil {
		log.Fatal(errDB)
	}
	database.New(db)

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
		AddressReceiver string  `json:"address_send"`
		AddressSender   string  `json:"address_receive"`
		Amount          float64 `json:"amount"`
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
		utils.WrapErrorLog(fmt.Sprintf("%v, addr: %s", errJson.Error(), payload.AddressReceiver))
		return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
			"success": false,
			"error":   errJson.Error(),
		})
	}
	utils.ReportMessage(fmt.Sprintf("Sending %f to %s from %s", payload.Amount, payload.AddressReceiver, payload.AddressSender))
	totalCoins := 0.0
	myUnspent := make([]models.ListUnspent, 0)
	for _, unspent := range ing {
		if unspent.Address == payload.AddressSender {
			if unspent.Spendable == true {
				utils.ReportMessage(fmt.Sprintf("Found unspent input: %f", unspent.Amount))
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
		utils.WrapErrorLog(fmt.Sprintf("not enough coins, addr: %s", payload.AddressReceiver))
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
		payload.AddressReceiver: payload.Amount,
		payload.AddressSender:   txBack}

	utils.ReportMessage(fmt.Sprintf("firstParam: %v secondParam %v", firstParam, secondParam))

	call, err = client.Call("createrawtransaction", firstParam, secondParam)
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("createrawtransaction error, addr: %s", payload.AddressReceiver))
		return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
			"success": false,
			"error":   "createrawtransaction Error",
		})
	}
	utils.ReportMessage(fmt.Sprintf("createrawtransaction: %s", string(call)))

	hex := strings.Trim(string(call), "\"")

	call, err = client.Call("signrawtransaction", hex)
	if err != nil {
		utils.WrapErrorLog(fmt.Sprintf("signrawtransaction error, addr: %s", payload.AddressReceiver))
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
		utils.WrapErrorLog(fmt.Sprintf("sendrawtransaction error, addr: %s", payload.AddressReceiver))
		return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
			"success": false,
			"error":   "sendrawtransaction Error",
		})
	}
	utils.ReportMessage(fmt.Sprintf("sendrawtransaction: %s", string(call)))

	tx := strings.Trim(string(call), "\"")
	userSend, _ := database.ReadValue[sql.NullString]("SELECT username FROM users WHERE addr = ?", payload.AddressSender)
	userReceive, _ := database.ReadValue[sql.NullString]("SELECT username FROM users WHERE addr = ?", payload.AddressReceiver)
	_, errInsert := database.InsertSQl("INSERT INTO transaction(txid, account, amount, confirmation, address, category) VALUES (?, ?, ?, ?, ?, ?)", tx, userSend.String, payload.Amount*-1, 0, payload.AddressSender, "send")
	if errInsert != nil {
		utils.WrapErrorLog(fmt.Sprintf("insert transaction error, addr: %s error %s", payload.AddressSender, errInsert.Error()))
	}
	if userReceive.Valid {
		_, errInsert2 := database.InsertSQl("INSERT INTO transaction(txid, account, amount, confirmation, address, category) VALUES (?, ?, ?, ?, ?, ?)", tx, userReceive.String, payload.Amount, 0, payload.AddressReceiver, "receive")
		if errInsert2 != nil {
			utils.WrapErrorLog(fmt.Sprintf("insert transaction error, addr: %s error: %s", payload.AddressReceiver, errInsert2.Error()))
		}
	}
	return c.Status(fiber.StatusOK).JSON(&fiber.Map{
		"success": true,
		"tx":      tx,
	})
}
