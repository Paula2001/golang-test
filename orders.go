package main

import (
	"log"
	"time"

	"github.com/gofiber/fiber/v3"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Order is one entry in the GET /orders response.
type Order struct {
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

const listOrdersQuery = `
SELECT o.order_id,
       o.order_date,
       o.status,
       c.customer_id,
       c.name,
       e.employee_id,
       e.name,
       COALESCE(SUM(oi.quantity), 0)                 AS item_count,
       COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total
FROM orders o
JOIN customers c        ON c.customer_id = o.customer_id
LEFT JOIN employees e   ON e.employee_id = o.employee_id
LEFT JOIN order_items oi ON oi.order_id  = o.order_id
GROUP BY o.order_id, c.customer_id, e.employee_id
ORDER BY o.order_date DESC, o.order_id`

// listOrders handles GET /orders and returns every order, newest first.
func listOrders(db *pgxpool.Pool) fiber.Handler {
	return func(c fiber.Ctx) error {
		rows, err := db.Query(c.Context(), listOrdersQuery)
		if err != nil {
			log.Printf("list orders: %v", err)
			return fiber.ErrInternalServerError
		}

		orders, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (Order, error) {
			var o Order
			var date time.Time
			err := row.Scan(&o.OrderID, &date, &o.Status, &o.CustomerID, &o.CustomerName,
				&o.EmployeeID, &o.EmployeeName, &o.ItemCount, &o.Total)
			o.OrderDate = date.Format(time.DateOnly)
			return o, err
		})
		if err != nil {
			log.Printf("list orders: %v", err)
			return fiber.ErrInternalServerError
		}

		return c.JSON(fiber.Map{"orders": orders})
	}
}
