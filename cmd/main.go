package main

import (
	"Strategy/config"
	"Strategy/internal/taker"
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
)

func main() {
	// Пробуем загрузить конфиг - сначала prod, потом dev
	var cfg *config.Config
	var err error

	if _, err := os.Stat(".env.prod"); err == nil {
		cfg, err = config.Load(".env.prod")
	} else {
		cfg, err = config.Load(".env")
	}

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
		AllowedOrigins:   []string{"*"}, // Разрешаем все источники для продакшена через nginx
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
	r.Get("/records", handler.GetAllRecords)

	log.Fatal(http.ListenAndServe(":"+cfg.Port, r))
}
