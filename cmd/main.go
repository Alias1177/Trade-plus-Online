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
	// Загружаем продакшн конфигурацию
	cfg, err := config.Load("prod.env")
	if err != nil {
		log.Fatal("Failed to load production config:", err)
	}

	db := taker.Connect(cfg)
	defer db.Close()

	handler := taker.New(cfg, db)

	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	// CORS для продакшена
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	// API routes
	r.Route("/api", func(r chi.Router) {
		r.Options("/insert", func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusOK)
		})
		r.Post("/insert", handler.InsertIntoDb)
		r.Get("/health", handler.Health)
		r.Get("/records", handler.GetAllRecords)
	})

	// Backward compatibility routes
	r.Options("/insert", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	r.Post("/insert", handler.InsertIntoDb)
	r.Get("/health", handler.Health)
	r.Get("/records", handler.GetAllRecords)

	log.Printf("🚀 Server starting on port %s", cfg.Port)
	log.Fatal(http.ListenAndServe(":"+cfg.Port, r))
}
