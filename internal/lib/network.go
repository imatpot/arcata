package lib

import (
	"io"
	"net/http"
	"os"
)

func DownloadFile(url string, path string) error {
	response, err := http.Get(url)
	if err != nil {
		return err
	}

	file, err := os.Create(path)
	if err != nil {
		return err
	}

	defer file.Close()

	_, err = io.Copy(file, response.Body)
	return err
}
