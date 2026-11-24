package api

import (
	"log"
	"time"

	"github.com/gofiber/fiber/v3"

	"interview/bl"
)

// orderResponse is one entry in the GET /orders response.
type orderResponse struct {
	OrderID      string  `json:"order_id"`
	OrderDate    string  `json:"order_date"` // YYYY-MM-DD
	Status       string  `json:"status"`
	CustomerID   string  `json:"customer_id"`
	CustomerName string  `json:"customer_name"`
	EmployeeID   *string `json:"employee_id"` // null when the order has no sales rep
	EmployeeName *string `json:"employee_name"`
	ItemCount    int     `json:"item_count"` // units across all line items
	Total        float64 `json:"total"`      // sum of quantity * unit_price
}

// listOrders handles GET /orders and returns every order, newest first.
func listOrders(svc *bl.OrderService) fiber.Handler {
	return func(c fiber.Ctx) error {
		orders, err := svc.ListOrders(c.Context())
		if err != nil {
			log.Printf("list orders: %v", err)
			return fiber.ErrInternalServerError
		}

		// Non-nil so an empty result is sent as [] rather than null.
		resp := make([]orderResponse, 0, len(orders))
		for _, o := range orders {
			resp = append(resp, orderResponse{
				OrderID:      o.OrderID,
				OrderDate:    o.OrderDate.Format(time.DateOnly),
				Status:       o.Status,
				CustomerID:   o.CustomerID,
				CustomerName: o.CustomerName,
				EmployeeID:   o.EmployeeID,
				EmployeeName: o.EmployeeName,
				ItemCount:    o.ItemCount,
				Total:        o.Total,
			})
		}

		return c.JSON(fiber.Map{"orders": resp})
	}
}
