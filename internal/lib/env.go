package lib

import (
	"fmt"
	"os"
)

func GetEnvOrEmpty(name string) string {
	return os.Getenv(name)
}

func GetEnvOrElse(name string, fallback string) string {
	if value := GetEnvOrEmpty(name); value != "" {
		return value
	}

	return fallback
}

func GetEnvOrPanic(name string) string {
	if value := GetEnvOrEmpty(name); value != "" {
		return value
	}

	message := fmt.Sprintf("Environment variable %s is not set", name)
	LogFatal(message)
	panic(message)
}
