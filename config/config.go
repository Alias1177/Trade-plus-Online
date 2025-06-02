package config

import (
	"github.com/ilyakaznacheev/cleanenv"
)

type Config struct {
	Port               string `env:"PORT" envDefault:"8080"`
	DbConnectionString string `env:"DB_CONNECTION_STRING"`
	Secret             string `env:"EMAIL_PASSWORD"`
	Mail               string `env:"EMAIL_ADDRESS"`
	SmtpHost           string `env:"SMTP_HOST"`
	SmtpPort           string `env:"SMTP_PORT"`
}

func Load(path string) (*Config, error) {
	var config Config

	// Пробуем загрузить из файла, если он существует
	// но не паникуем если файла нет (для Docker контейнеров)
	_ = cleanenv.ReadConfig(path, &config)

	// Загружаем из переменных окружения (приоритет)
	err := cleanenv.ReadEnv(&config)
	if err != nil {
		panic(err)
	}
	return &config, nil
}
