package config

import (
	"github.com/ilyakaznacheev/cleanenv"
)

type Config struct {
	Port               string `env:"PORT" envDefault:"8080"`
	DbConnectionString string `env:"DB_CONNECTION_STRING"`
	Secret             string `env:"SECRET"`
	Mail               string `env:"MAIL"`
	SmtpHost           string `env:"SMTP_HOST"`
	SmtpPort           string `env:"SMTP_PORT"`
}

func Load(path string) (*Config, error) {
	var config Config
	err := cleanenv.ReadConfig(path, &config)
	if err != nil {
		panic(err)
	}
	err = cleanenv.ReadEnv(&config)
	if err != nil {
		panic(err)
	}
	return &config, nil
}
