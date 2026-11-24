// Package models holds the data types shared by the api, bl and dblayer
// packages.
package models

import "time"

// Order is one order with its customer, sales rep and line-item totals.
type Order struct {
	OrderID      string
	OrderDate    time.Time
	Status       string
	CustomerID   string
	CustomerName string
	EmployeeID   *string // nil when the order has no sales rep
	EmployeeName *string
	ItemCount    int     // units across all line items
	Total        float64 // sum of quantity * unit_price
}
