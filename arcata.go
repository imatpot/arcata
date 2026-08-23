package main

import (
	"os"

	"github.com/imatpot/arcata/internal/lib"
	"github.com/imatpot/arcata/internal/monitoring"
	"github.com/imatpot/arcata/internal/warframe"
)

func main() {
	if err := monitoring.StartVnc(); err != nil {
		lib.LogFatalf("Failed to start VNC server: %v", err)
	}

	if err := warframe.Install(); err != nil {
		lib.LogFatalf("Failed to install Warframe: %v", err)
		os.Exit(1)
	}

	if err := warframe.StartDedicatedServers(); err != nil {
		lib.LogFatalf("Error while running dedicated servers: %v", err)
		os.Exit(1)
	}
}
