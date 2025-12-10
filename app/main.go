package main

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/healthcheck"
)

func main() {
	app := fiber.New()

	// Use Fiber's health middleware for /healthz
	app.Use("/healthz", healthcheck.New())

	// REST API
	app.Get("/api/message", MessageHandler)

	app.Listen(":8080")
}
