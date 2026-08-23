package lib

import (
	"errors"
	"fmt"
)

func Err(message string) error {
	return errors.New(message)
}

func Errf(message string, args ...any) error {
	message = fmt.Sprintf(message, args...)
	return Err(message)
}
