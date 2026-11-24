package api

import (
	"errors"
	"log"
	"time"

	"github.com/gofiber/fiber/v3"
)

// RequestLogger logs the method, path, status, and latency of every request.
func RequestLogger(c fiber.Ctx) error {
	start := time.Now()
	err := c.Next()

	// Errors are turned into responses by the app's error handler only after
	// this middleware returns, so derive the status from the error itself.
	status := c.Response().StatusCode()
	if err != nil {
		status = fiber.StatusInternalServerError
		var fe *fiber.Error
		if errors.As(err, &fe) {
			status = fe.Code
		}
	}

	log.Printf("%s %s -> %d (%s)", c.Method(), c.Path(), status, time.Since(start))
	return err
}
