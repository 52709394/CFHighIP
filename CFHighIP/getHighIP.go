package main

import (
	"fmt"
	"regexp"
)

func main() {
	text := `

`

	re := regexp.MustCompile(`(?m)^\s*https\:\/\/(\d+\.\d+\.\d+\.\d+(?:\:\d+|))\s+`)

	matches := re.FindAllStringSubmatch(text, -1)

	for _, m := range matches {
		var ip string

		if matched, _ := regexp.MatchString(`\:\d+$`, m[1]); matched {
			ip = m[1]
		} else {
			ip = m[1] + ":443"
		}

		fmt.Println(``)

	}
}


