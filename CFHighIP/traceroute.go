package main

import (
	"fmt"
	"os/exec"
	"regexp"
)

func main() {
	text := `
	`

	pattern := `(\d+\.\d+\.\d+\.\d+)(\/\d+)`

	re := regexp.MustCompile(pattern)

	matches := re.FindAllStringSubmatch(text, -1)

	for _, ip := range matches {

		out, err := exec.Command(
			"./nexttrace_windows_amd64.exe",
			"--source",
			"192.168.3.83",
			ip[1]).CombinedOutput()

		if err != nil {
			fmt.Println("err:", err)
			continue
		}

		if matched, _ := regexp.MatchString(`59\.43\.\d+\.\d+`, string(out)); matched {
			fmt.Println(ip[1] + ip[2])
		} else {
			fmt.Println(ip[1] + ip[2] + "不是")
		}

	}

}
