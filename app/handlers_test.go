package main

import (
	"encoding/json"
	"net/http/httptest"
	"testing"

	"github.com/gofiber/fiber/v2"
	"github.com/stretchr/testify/require"
)

func TestHealthHandler(t *testing.T) {
	app := fiber.New()
	app.Get("/healthz", HealthHandler)

	req, _ := app.Test(httptest.NewRequest("GET", "/healthz", nil))
	require.Equal(t, 200, req.StatusCode)
}

func TestMessageHandler(t *testing.T) {
	app := fiber.New()
	app.Get("/api/message", MessageHandler)

	req, _ := app.Test(httptest.NewRequest("GET", "/api/message", nil))
	require.Equal(t, 200, req.StatusCode)

	var response map[string]interface{}
	err := json.NewDecoder(req.Body).Decode(&response)
	require.NoError(t, err)

	require.Equal(t, "Automate none of the things!", response["message"])
	require.IsType(t, float64(0), response["timestamp"])
}
