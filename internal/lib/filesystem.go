package lib

import (
	"crypto/md5"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

type WarframePaths struct {
	CompatDir   string
	WinePrefix  string
	AppDataDir  string
	LauncherDir string
	LauncherLog string
	Launcher    string
	Eula        string
}

func GetWarframePaths() WarframePaths {
	homeDir, _ := os.UserHomeDir()
	compatDir := filepath.Join(homeDir, ".local/share/Steam/compatibilitytools.d")

	winePrefix := GetEnvOrPanic("WINEPREFIX")
	appDataDir := filepath.Join(winePrefix, "drive_c/users/steamuser/AppData/Local/Warframe")

	launcherDir := filepath.Join(appDataDir, "Downloaded/Public/Tools")
	launcherLog := filepath.Join(appDataDir, "Launcher.log")
	launcher := filepath.Join(launcherDir, "Launcher.exe")
	eula := filepath.Join(appDataDir, "Downloaded/Public/Lotus/Language/EULA_en.rtf")

	return WarframePaths{
		CompatDir:   compatDir,
		WinePrefix:  winePrefix,
		AppDataDir:  appDataDir,
		LauncherDir: launcherDir,
		LauncherLog: launcherLog,
		Launcher:    launcher,
		Eula:        eula,
	}
}

type ArcataPaths struct {
	ArcataYaml    string
	ArcataCfg     string
	EeCfgTemplate string
	EeCfg         string
	DsCfgTemplate string
	DsCfg         string
}

func getArcataPaths() ArcataPaths {
	exe, err := os.Executable()
	if err != nil {
		LogFatalf("Failed to get executable path: %v", err)
		os.Exit(1)
	}

	warframePaths := GetWarframePaths()
	eeCfg := filepath.Join(warframePaths.AppDataDir, "EE.cfg")
	dsCfg := filepath.Join(warframePaths.AppDataDir, "DS.cfg")

	cwd := filepath.Dir(exe)

	arcataYaml := filepath.Join(cwd, "arcata.yaml")
	arcataCfg := filepath.Join(warframePaths.AppDataDir, "Arcata.cfg")

	templateDir := filepath.Join(cwd, "templates")
	eeCfgTemplate := filepath.Join(templateDir, "EE.cfg")
	dsCfgTemplate := filepath.Join(templateDir, "DS.cfg")

	return ArcataPaths{
		ArcataYaml:    arcataYaml,
		ArcataCfg:     arcataCfg,
		EeCfgTemplate: eeCfgTemplate,
		EeCfg:         eeCfg,
		DsCfgTemplate: dsCfgTemplate,
		DsCfg:         dsCfg,
	}
}

func PathExists(path string) bool {
	_, err := os.Stat(path)
	return !os.IsNotExist(err)
}

func MoveAllContents(source string, destination string) error {
	if err := os.MkdirAll(destination, 0755); err != nil {
		return err
	}

	entries, err := os.ReadDir(source)
	if err != nil {
		return err
	}

	for _, entry := range entries {
		sourcePath := filepath.Join(source, entry.Name())
		destinationPath := filepath.Join(destination, entry.Name())

		if err := os.Rename(sourcePath, destinationPath); err != nil {
			return err
		}
	}

	return nil
}

func HashFileMd5(path string) (string, error) {
	file, err := os.Open(path)
	if err != nil {
		return "", err
	}

	defer file.Close()

	hash := md5.New()
	if _, err := io.Copy(hash, file); err != nil {
		return "", err
	}

	return fmt.Sprintf("%X", hash.Sum(nil)), nil
}
