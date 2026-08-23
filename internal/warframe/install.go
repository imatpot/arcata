package warframe

import (
	"os"
	"path/filepath"
	"time"

	"github.com/imatpot/arcata/internal/lib"
)

const (
	AUTO_ACCEPT_EULA_ENVNAME = "AUTO_ACCEPT_EULA"
	EULA_TIMEOUT_SECONDS     = 300
	IDLE_TIMEOUT_SECONDS     = 300
)

func Install() error {
	lib.LogPhase("INSTALLATION")

	paths := lib.GetWarframePaths()

	if err := checkMountPermissions(paths); err != nil {
		return lib.Errf("Mount permission check failed: %v", err)
	}

	lib.Log("Initializing Wine prefix...")
	if err := lib.ProtonRunCommand("wineboot", "-i"); err != nil {
		return lib.Errf("Failed to initialize Wine prefix: %v", err)
	}

	if _, err := os.Stat(paths.Launcher); os.IsNotExist(err) {
		lib.Logf("%s missing", paths.Launcher)
		if err := downloadAndExtractLauncherMsi(paths); err != nil {
			return lib.Errf("Failed to download and extract Warframe.msi: %v", err)
		}
	}

	if err := setInstallationDir(); err != nil {
		return lib.Errf("Failed to set installation directory: %v", err)
	}

	shouldAutoAcceptEula := lib.GetEnvOrElse(AUTO_ACCEPT_EULA_ENVNAME, "0") == "1"
	if shouldAutoAcceptEula {
		if err := autoAcceptEula(paths); err != nil {
			return lib.Errf("Failed to auto-accept EULA: %v", err)
		}
	} else {
		lib.LogWarningf("%s is disabled, skipping EULA acceptance. You will need to manually accept the EULA via VNC. The headless launcher will stop crashing after you accept the EULA and restart it.", AUTO_ACCEPT_EULA_ENVNAME)
	}

	return nil
}

func checkMountPermissions(paths lib.WarframePaths) error {
	for _, dir := range []string{
		paths.WinePrefix,
		paths.CompatDir,
	} {
		info, err := os.Stat(dir)

		if err != nil || !info.IsDir() {
			return lib.Errf("%s does not exist. If that is a bind mount, create the host directory yourself before starting the container.", dir)
		}

		if info.Mode()&0200 == 0 {
			return lib.Errf("%s is not writable. If that is a bind mount, create the host directory yourself before starting the container.", dir)
		}
	}

	return nil
}

func downloadAndExtractLauncherMsi(paths lib.WarframePaths) error {
	lib.Log("Downloading Warframe.msi...")

	msi := "/tmp/Warframe.msi"
	if err := lib.DownloadFile("https://content.warframe.com/dl/Warframe.msi", msi); err != nil {
		return lib.Errf("Failed to download Warframe.msi: %v", err)
	}

	if err := lib.ProtonRunCommand(
		"msiexec",
		"/a", `Z:\tmp\Warframe.msi`,
		"/qn", `TARGETDIR=C:\tmp`,
	); err != nil {
		return lib.Errf("Failed to extract Warframe.msi: %v", err)
	}

	extractionDir := filepath.Join(paths.WinePrefix, "drive_c/tmp")
	if _, err := os.Stat(extractionDir); os.IsNotExist(err) {
		return lib.Errf("Extraction directory %s went missing after MSI extraction", extractionDir)
	}

	extracted := filepath.Join(extractionDir, "LocalAppDataFolder/Warframe")
	if err := lib.MoveAllContents(extracted, paths.AppDataDir); err != nil {
		return lib.Errf("Failed to move extracted Launcherfiles: %v", err)
	}

	if err := os.RemoveAll(extractionDir); err != nil {
		return lib.Errf("Failed to remove extraction directory %s: %v", extractionDir, err)
	}

	if err := os.Remove(msi); err != nil {
		return lib.Errf("Failed to remove %s: %v", msi, err)
	}

	return nil
}

func setInstallationDir() error {
	lib.Log("Setting installation directory in registry...")

	if err := lib.ProtonRunCommand(
		"reg", "add", `HKEY_CURRENT_USER\Software\Digital Extremes\Warframe\Launcher`,
		"/v", "DownloadDir",
		"/t", "REG_SZ",
		"/d", `C:\users\steamuser\AppData\Local\Warframe\Downloaded`,
		"/f",
	); err != nil {
		return lib.Errf("Failed to edit registry: %v", err)
	}

	return nil
}

func autoAcceptEula(paths lib.WarframePaths) error {
	lib.Log("Auto-accepting EULA...")

	lib.Log("Forcing the launcher to download the EULA...")
	launcherProcess, err := lib.ProtonRunCommandEndless(paths.Launcher)
	if err != nil {
		return lib.Errf("Failed to run launcher to download EULA: %v", err)
	}

	lib.Log("Waiting for EULA to appear on filesystem...")
	for range EULA_TIMEOUT_SECONDS {
		if lib.PathExists(paths.Eula) {
			break
		} else {
			time.Sleep(1 * time.Second)
		}
	}

	if !lib.PathExists(paths.Eula) {
		return lib.Errf("EULA did not appear on filesystem after %d seconds", EULA_TIMEOUT_SECONDS)
	}

	lib.Log("Waiting for launcher to go idle...")
	idled := false
	for range IDLE_TIMEOUT_SECONDS {
		if info, err := os.Stat(paths.LauncherLog); err != nil {
			if now := (time.Time{}); now.Sub(info.ModTime()).Seconds() > 5 {
				idled = true
				break
			}
		}

		time.Sleep(1 * time.Second)
	}

	if !idled {
		return lib.Errf("Launcher did not go idle after %d seconds", IDLE_TIMEOUT_SECONDS)
	}

	lib.Log("Writing EULA hash to registry...")
	eulaHash, err := lib.HashFileMd5(paths.Eula)
	if err != nil {
		return lib.Errf("Failed to hash EULA file: %v", err)
	}

	if err := lib.ProtonRunCommand(
		"reg", "add", `HKEY_CURRENT_USER\Software\Digital Extremes\Warframe\Launcher`,
		"/v", "EulaHash",
		"/t", "REG_SZ",
		"/d", eulaHash,
		"/f",
	); err != nil {
		return lib.Errf("Failed to edit registry: %v", err)
	}

	lib.Log("Killing launcher process...")
	if err := launcherProcess.Process.Kill(); err != nil {
		return lib.Errf("Failed to kill launcher process: %v", err)
	}
	if err := launcherProcess.Wait(); err != nil {
		return lib.Errf("Failed to wait for launcher process to exit: %v", err)
	}

	return nil
}
