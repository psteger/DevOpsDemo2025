package main

import (
	"time"

	"github.com/gofiber/fiber/v2"
)

func HealthHandler(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"status": "pass"})
}

func MessageHandler(c *fiber.Ctx) error {
	response := fiber.Map{
		"message":   "Automate none of the things!",
		"timestamp": time.Now().Unix(),
	}
	return c.JSON(response)
}
