package lib

import (
	"os"
	"os/exec"
	"strings"
)

const (
	PROTON_WRAPPER = "umu-run"
)

func RunCommand(exe string, args ...string) error {
	command := exec.Command(exe, args...)
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr

	return command.Run()
}

func PipeStringIntoRunCommand(piped string, exe string, args ...string) ([]byte, error) {
	command := exec.Command(exe, args...)
	command.Stdin = strings.NewReader(piped)
	command.Stderr = os.Stderr

	return command.Output()
}

func ProtonRunCommand(exe string, args ...string) error {
	return RunCommand(PROTON_WRAPPER, append([]string{exe}, args...)...)
}

func RunCommandEndless(exe string, args ...string) (*exec.Cmd, error) {
	command := exec.Command(exe, args...)
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr

	return command, command.Start()
}

func ProtonRunCommandEndless(exe string, args ...string) (*exec.Cmd, error) {
	return RunCommandEndless(PROTON_WRAPPER, append([]string{exe}, args...)...)
}
