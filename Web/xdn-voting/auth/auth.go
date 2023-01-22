package auth

import (
	"encoding/hex"
	"fmt"
	"github.com/gofiber/fiber/v2"
	"net/http"
	"strings"
	"xdn-voting/database"
	"xdn-voting/utils"
)

func Authorized(handler func(*fiber.Ctx) error) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if len(c.Get("Authorization")) == 0 {
			err := "no token provided"
			return utils.ReportError(c, err, http.StatusUnauthorized)
		}
		if len(c.Get("Content-Type")) != 0 {
			value := c.Get("Content-Type")
			if value != "application/json" {
				//ReportMessage("JSON content is required")
				//	msg := "Content-Type header is not application/json"
				//	return ReportError(c, msg, http.StatusUnsupportedMediaType)
			} else {
				//ReportMessage("JSON content")
			}
		}

		tokenSplit := strings.Fields(c.Get("Authorization"))
		if len(tokenSplit) != 2 {
			return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
		}

		if tokenSplit[0] == "Bearer" {
			id, secret, err := utils.ValidateKeyToken(tokenSplit[1])
			//data, err := database.ReadValue[sql.NullInt64]("SELECT ban FROM users WHERE idUser= ?", id)
			//if data.Valid {
			//	if data.Int64 == 1 {
			//		utils.ReportErrorSilent(c, "Banned user", http.StatusUnauthorized)
			//		return errors.New("banned user")
			//	}
			//}
			if secret != nil {
				decodeString, err := hex.DecodeString(secret.(string))
				if err != nil {
					return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
				} else {
					length := len(decodeString)
					if length != 32 {
						return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
					}
				}
			} else {
				return utils.ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
			}
			ban := database.ReadValueEmpty[bool]("SELECT banned FROM users WHERE id= ?", id)
			if ban {
				return utils.ReportErrorSilent(c, "Banned user", http.StatusUnauthorized)
			}
			if err != nil {
				return utils.ReportError(c, "Invalid token", http.StatusUnauthorized)
			} else {
				c.Request().Header.Set("user_id", fmt.Sprintf("%d", id))
				c.Request().Header.Set("user_secret", secret.(string))
				return handler(c)
			}
		} else {
			return utils.ReportError(c, "Invalid Token", http.StatusUnauthorized)
		}

	}
}
