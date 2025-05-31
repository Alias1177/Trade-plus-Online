package main

import (
	"Strategy/config"
	"Strategy/internal/taker"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
)

func main() {
	cfg, err := config.Load(".env")
	if err != nil {
		log.Fatal("trouble with config")
	}

	db := taker.Connect(cfg)
	defer db.Close()

	handler := taker.New(cfg, db)

	r := chi.NewRouter()
	r.Use(middleware.Logger)

	// Используем официальный CORS middleware
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:3000"},
		AllowedMethods:   []string{"GET", "POST", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	r.Options("/insert", func(w http.ResponseWriter, r *http.Request) {
		// CORS headers уже установлены middleware
		w.WriteHeader(http.StatusOK)
	})
	r.Post("/insert", handler.InsertIntoDb)
	r.Get("/health", handler.Health)

	log.Fatal(http.ListenAndServe(":"+cfg.Port, r))
}
