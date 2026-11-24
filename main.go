package main

import (
	"context"
	"log"
	"os"

	"github.com/gofiber/fiber/v3"
	"github.com/jackc/pgx/v5/pgxpool"

	"interview/api"
	"interview/bl"
	"interview/dblayer"
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

	// Wire the layers: dblayer -> bl -> api.
	svc := bl.NewOrderService(dblayer.NewOrderAccess(db))

	app := fiber.New()
	app.Use(api.RequestLogger)
	api.RegisterRoutes(app, svc)

	log.Fatal(app.Listen("0.0.0.0:3000"))
}
