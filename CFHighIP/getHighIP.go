package main

import (
	"fmt"
	"regexp"
)

func main() {
	text := `

`
	
	userUrl := ``

	if matched, _ := regexp.MatchString(`(?m)^\s*https\:\/\/(\d+\.\d+\.\d+\.\d+)((?:\:\d+|))\s+`, text); !matched {
		return
	}

	if matched, _ := regexp.MatchString(`(?m)^(.*?\@)\d+\.\d+\.\d+\.\d+\:\d+(\?.*?)$`, userUrl); !matched {
		return
	}

	urlRe := regexp.MustCompile(`(?m)^(.*?\@)\d+\.\d+\.\d+\.\d+\:\d+(\?.*?)$`)

	urlMatch := urlRe.FindStringSubmatch(userUrl)

	ipRe := regexp.MustCompile(`(?m)^\s*https\:\/\/(\d+\.\d+\.\d+\.\d+)((?:\:\d+|))\s+`)

	ipMatchs := ipRe.FindAllStringSubmatch(text, -1)

	for _, p := range ipMatchs {
		var ip string

		if p[2] != "" {
			ip = p[1] + p[2]
		} else {
			ip = p[1] + ":443"
		}

		fmt.Println(urlMatch[1] + ip + urlMatch[2])

	}
}
