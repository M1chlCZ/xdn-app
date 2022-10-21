package main

import (
	"crypto/tls"
	"github.com/gofiber/fiber/v2"
	"log"
)

func main() {
	// Fiber instance
	app := fiber.New()

	// Routes
	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("XDN DEX") // => https
	})

	// Create tls certificate
	cer, err := tls.LoadX509KeyPair("dex.crt", "dex.key")
	if err != nil {
		log.Fatal(err)
	}

	config := &tls.Config{Certificates: []tls.Certificate{cer}}

	// Create custom listener
	ln, err := tls.Listen("tcp", ":6500", config)
	if err != nil {
		panic(err)
	}

	// Start server with https/ssl enabled on http://localhost:443
	log.Fatal(app.Listener(ln))
}
