package api

import (
	"log"

	"github.com/gofiber/fiber/v3"

	"interview/bl"
)

// customerResponse is one entry in a customers response.
type customerResponse struct {
	CustomerID   string `json:"customer_id"`
	CustomerName string `json:"customer_name"`
}

// listCustomersWithMoreThanTwoItems handles GET /customers/more-than-two-items
// and returns each customer who has at least one order with more than two line
// items, sorted by name.
func listCustomersWithMoreThanTwoItems(svc *bl.OrderService) fiber.Handler {
	return func(c fiber.Ctx) error {
		customers, err := svc.ListCustomersWithMoreThanTwoItems(c.Context())
		if err != nil {
			log.Printf("list customers with more than two items: %v", err)
			return fiber.ErrInternalServerError
		}

		// Non-nil so an empty result is sent as [] rather than null.
		resp := make([]customerResponse, 0, len(customers))
		for _, cu := range customers {
			resp = append(resp, customerResponse{
				CustomerID:   cu.ID,
				CustomerName: cu.Name,
			})
		}

		return c.JSON(fiber.Map{"customers": resp})
	}
}
