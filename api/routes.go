// Package api is the HTTP layer: routes, handlers, response shapes and
// middleware. Handlers call the bl package and never touch the database.
package api

import (
	"github.com/gofiber/fiber/v3"

	"interview/bl"
)

// RegisterRoutes adds every endpoint to router.
func RegisterRoutes(router fiber.Router, svc *bl.OrderService) {
	router.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok"})
	})

	router.Get("/orders", listOrders(svc))
	router.Get("/customers/more-than-two-items", listCustomersWithMoreThanTwoItems(svc))
}
