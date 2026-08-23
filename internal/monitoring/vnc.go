package monitoring

import (
	"os"
	"path/filepath"

	"github.com/imatpot/arcata/internal/lib"
)

const (
	VNC_PORT_ENVNAME = "VNC_PORT"
	VNC_PASS_ENVNAME = "VNC_PASSWORD"
	DISPLAY_ENVNAME  = "VNC_PASSWORD"
)

func StartVnc() error {
	lib.LogPhase("VNC")

	port := lib.GetEnvOrElse(VNC_PORT_ENVNAME, "5900")

	display := lib.GetEnvOrPanic(DISPLAY_ENVNAME)
	password := lib.GetEnvOrEmpty(VNC_PASS_ENVNAME)

	if password == "" {
		return startVncUnauthenticated(display, port)
	} else {
		return startVncAuthenticated(display, port, password)
	}
}

func startVncUnauthenticated(display string, port string) error {
	lib.Logf("Starting unauthenticated VNC on port %s...", port)

	if err := lib.RunCommand(
		"vncserver", display,
		"-rfbport", port,
		"-geometry", "1280x800",
		"-depth", "24",
		"-localhost", "no",
		"-SecurityTypes", "None",
		"--I-KNOW-THIS-IS-INCESURE",
	); err != nil {
		return lib.Errf("Failed to start VNC server: %v", err)
	}

	return nil
}

func startVncAuthenticated(display string, port string, password string) error {
	lib.Logf("Starting authenticated VNC on port %s...", port)

	homeDir, _ := os.UserHomeDir()

	vncDir := filepath.Join(homeDir, ".vnc")
	if err := os.MkdirAll(vncDir, 0700); err != nil {
		return lib.Errf("Failed to create VNC directory: %v", err)
	}

	passwd := filepath.Join(vncDir, "passwd")
	passwdContent, err := lib.PipeStringIntoRunCommand(password, "vncpasswd", "-f")
	if err != nil {
		return lib.Errf("Failed to generate VNC password: %v", err)
	}

	if err := os.WriteFile(passwd, []byte(passwdContent), 0600); err != nil {
		return lib.Errf("Failed to write VNC password file: %v", err)
	}

	if err := lib.RunCommand(
		"vncserver", display,
		"-rfbport", port,
		"-geometry", "1280x800",
		"-depth", "24",
		"-localhost", "no",
	); err != nil {
		return lib.Errf("Failed to start VNC server: %v", err)
	}

	return nil
}
