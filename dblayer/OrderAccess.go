package dblayer

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"interview/models"
)

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

// listOrdersMoreThanTwo returns each customer who has at least one order with
// more than two line items (distinct products), listed once, sorted by name.
const listOrdersMoreThanTwo = `
SELECT DISTINCT c.customer_id,
       c.name
FROM orders o
JOIN customers c    ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id  = o.order_id
GROUP BY o.order_id, c.customer_id
HAVING COUNT(*) > 2
ORDER BY c.name, c.customer_id`

// OrderAccess reads orders from the database.
type OrderAccess struct {
	db *pgxpool.Pool
}

// NewOrderAccess returns an OrderAccess that queries db.
func NewOrderAccess(db *pgxpool.Pool) *OrderAccess {
	return &OrderAccess{db: db}
}

// ListOrders returns every order, newest first. The result is never nil.
func (a *OrderAccess) ListOrders(ctx context.Context) ([]models.Order, error) {
	rows, err := a.db.Query(ctx, listOrdersQuery)
	if err != nil {
		return nil, fmt.Errorf("list orders: %w", err)
	}

	orders, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (models.Order, error) {
		var r models.Order
		err := row.Scan(&r.OrderID, &r.OrderDate, &r.Status, &r.CustomerID, &r.CustomerName,
			&r.EmployeeID, &r.EmployeeName, &r.ItemCount, &r.Total)
		return r, err
	})
	if err != nil {
		return nil, fmt.Errorf("list orders: %w", err)
	}

	return orders, nil
}

// ListCustomersWithMoreThanTwoItems returns each customer who has at least one
// order with more than two line items, sorted by name. The result is never nil.
func (a *OrderAccess) ListCustomersWithMoreThanTwoItems(ctx context.Context) ([]models.Customer, error) {
	rows, err := a.db.Query(ctx, listOrdersMoreThanTwo)
	if err != nil {
		return nil, fmt.Errorf("list customers with more than two items: %w", err)
	}

	customers, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (models.Customer, error) {
		var c models.Customer
		err := row.Scan(&c.ID, &c.Name)
		return c, err
	})
	if err != nil {
		return nil, fmt.Errorf("list customers with more than two items: %w", err)
	}

	return customers, nil
}
