package main

import (
	"fmt"
	"github.com/gofiber/fiber/v2"
	_ "github.com/gofiber/fiber/v2/utils"
	"github.com/jmoiron/sqlx"
	"log"
	"net/http"
	"strings"
	"xdn-voting/database"
	"xdn-voting/utils"
)

func main() {
	db, errDB := sqlx.Open("mysql", utils.GetENV("DB_CONN"))
	if errDB != nil {
		log.Fatal(errDB)
	}
	database.New(db)
	app := fiber.New()
	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("Hello, World 👋!")
	})

	app.Get("/test", isAuthorized(shit))

	err := app.Listen(":3000")
	if err != nil {
		log.Panic(err)
	}
}

func shit(c *fiber.Ctx) error {
	return c.Status(fiber.StatusInternalServerError).JSON(&fiber.Map{
		"success": false,
		"error":   "errJson.Error()",
	})
}

func isAuthorized(handler func(*fiber.Ctx) error) fiber.Handler {
	return func(c *fiber.Ctx) error {

		if len(c.Get("Authorization")) == 0 {
			err := "no token provided"
			return utils.ReportErrorSilent(c, err, http.StatusUnauthorized)
		}

		if len(c.Get("Content-Type")) != 0 {
			value := c.Get("Content-Type")
			if value != "application/json" {
				msg := "Content-Type header is not application/json"
				return utils.ReportErrorSilent(c, msg, http.StatusUnsupportedMediaType)
			}
		}
		//jwtKey := utils.GetENV("JWT_KEY")

		//var mySigningKey = []byte(jwtKey)

		tokenSplit := strings.Fields(c.Get("Authorization"))
		if len(tokenSplit) != 2 {
			return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
		}

		if tokenSplit[0] == "Bearer" {

			id, _, err := utils.ValidateKeyToken(tokenSplit[1])

			//data, err := database.ReadValue[sql.NullInt64]("SELECT ban FROM users WHERE idUser= ?", id)
			//if data.Valid {
			//	if data.Int64 == 1 {
			//		utils.ReportErrorSilent(c, "Banned user", http.StatusUnauthorized)
			//		return errors.New("banned user")
			//	}
			//}
			//if secret != nil {
			//	decodeString, err := hex.DecodeString(secret.(string))
			//	if err != nil {
			//		return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
			//	} else {
			//		lenght := len(decodeString)
			//		if lenght != 32 {
			//			return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
			//		}
			//	}
			//} else {
			//	return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
			//}

			//if len(secret.(string)) != 32 {
			//	utils.ReportErrorSilent(w, "Invalid Token", http.StatusUnauthorized)
			//	return
			//}

			if err != nil {
				return utils.ReportErrorSilent(c, "Invalid token", http.StatusUnauthorized)
			} else {
				c.Set("user_id", fmt.Sprintf("%d", id))
				return handler(c)
			}
		} else {
			return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
		}

	}
}
