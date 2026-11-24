// Package bl holds the business logic. It sits between the api package (HTTP)
// and the dblayer package (SQL), so business rules live here, not in handlers
// or queries.
package bl

import (
	"context"

	"interview/dblayer"
	"interview/models"
)

// OrderService serves order and customer data to the api layer.
type OrderService struct {
	orders *dblayer.OrderAccess
}

// NewOrderService returns an OrderService that reads from orders.
func NewOrderService(orders *dblayer.OrderAccess) *OrderService {
	return &OrderService{orders: orders}
}

// ListOrders returns every order, newest first.
func (s *OrderService) ListOrders(ctx context.Context) ([]models.Order, error) {
	return s.orders.ListOrders(ctx)
}

// ListCustomersWithMoreThanTwoItems returns each customer who has at least one
// order with more than two line items, sorted by name.
func (s *OrderService) ListCustomersWithMoreThanTwoItems(ctx context.Context) ([]models.Customer, error) {
	return s.orders.ListCustomersWithMoreThanTwoItems(ctx)
}
