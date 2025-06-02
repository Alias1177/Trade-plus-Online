package config

import (
	"fmt"
	"log"
	"os"

	"github.com/ilyakaznacheev/cleanenv"
)

type Config struct {
	Port               string `env:"PORT" envDefault:"8080"`
	DbConnectionString string `env:"DB_CONNECTION_STRING" env-required:"true"`
	EmailPassword      string `env:"EMAIL_PASSWORD" env-required:"true"`
	EmailAddress       string `env:"EMAIL_ADDRESS" env-required:"true"`
	SmtpHost           string `env:"SMTP_HOST" envDefault:"smtp.mail.ru"`
	SmtpPort           string `env:"SMTP_PORT" envDefault:"465"`
}

func Load(path string) (*Config, error) {
	var config Config

	// Проверяем существование файла
	if _, err := os.Stat(path); err != nil {
		log.Printf("⚠️ Config file %s not found, using environment variables only", path)
	} else {
		// Загружаем из файла если существует
		if err := cleanenv.ReadConfig(path, &config); err != nil {
			return nil, fmt.Errorf("failed to read config file %s: %w", path, err)
		}
		log.Printf("✅ Config loaded from %s", path)
	}

	// Загружаем из переменных окружения (приоритет)
	if err := cleanenv.ReadEnv(&config); err != nil {
		return nil, fmt.Errorf("failed to read environment variables: %w", err)
	}

	// Валидация
	if err := config.Validate(); err != nil {
		return nil, fmt.Errorf("config validation failed: %w", err)
	}

	log.Printf("📧 Email config: %s via %s:%s", config.EmailAddress, config.SmtpHost, config.SmtpPort)

	return &config, nil
}

func (c *Config) Validate() error {
	if c.DbConnectionString == "" {
		return fmt.Errorf("DB_CONNECTION_STRING is required")
	}
	if c.EmailPassword == "" {
		return fmt.Errorf("EMAIL_PASSWORD is required")
	}
	if c.EmailAddress == "" {
		return fmt.Errorf("EMAIL_ADDRESS is required")
	}
	return nil
}
