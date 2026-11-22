package main

import (
	"context"
	"log"
	"os"

	"github.com/gofiber/fiber/v3"
	"github.com/jackc/pgx/v5/pgxpool"
)

// defaultDatabaseURL points at the local supermarket database (see seed.sh).
// Set DATABASE_URL to use a different one.
const defaultDatabaseURL = "postgres://postgres:postgres@localhost:5433/supermarket"

func main() {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = defaultDatabaseURL
	}

	db, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		log.Fatalf("database config: %v", err)
	}
	if err := db.Ping(context.Background()); err != nil {
		log.Fatalf("database unreachable: %v", err)
	}

	defer db.Close()

	app := fiber.New()

	app.Use(requestLogger)

	app.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok"})
	})

	app.Get("/orders", listOrders(db))

	log.Fatal(app.Listen(":3000"))
}
