package main

import (
	"github.com/gofiber/fiber/v2"
	"log"
	"xdn-dex/utils"
)

func main() {
	// Fiber instance
	app := fiber.New()

	// Routes
	app.Get("/api", func(c *fiber.Ctx) error {
		return c.SendString("XDN DEX") // => https
	})

	err := app.Listen(":6500")
	if err != nil {
		utils.WrapErrorLog(err.Error())
		log.Panic(err)
	}
}
