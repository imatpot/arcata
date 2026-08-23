package lib

import (
	"fmt"
	"time"
)

const (
	RED     = "\033[31m"
	YELLOW  = "\033[33m"
	BLUE    = "\033[34m"
	MAGENTA = "\033[35m"
	RESET   = "\033[0m"

	TIME_FORMAT = "2006-01-02 15:04:05" // who the hell came up with this effed up convention
)

func Log(message string) {
	now := time.Now().Format(TIME_FORMAT)
	fmt.Printf("%s[ARCATA]%s [%s] %s\n", MAGENTA, RESET, now, message)
}

func Logf(messagef string, args ...any) {
	Log(fmt.Sprintf(messagef, args...))
}

func LogWarning(message string) {
	Log(fmt.Sprintf("%sWARNING%s: %s", YELLOW, RESET, message))
}

func LogWarningf(messagef string, args ...any) {
	LogWarning(fmt.Sprintf(messagef, args...))
}

func LogFatal(message string) {
	Log(fmt.Sprintf("%sFATAL%s: %s", RED, RESET, message))
}

func LogFatalf(messagef string, args ...any) {
	LogFatal(fmt.Sprintf(messagef, args...))
}

func LogPhase(message string) {
	Log(fmt.Sprintf("%s[PHASE]%s %s", BLUE, RESET, message))
}
