package main

import (
	"fmt"
	"regexp"
)

func main() {
	text := `

`

	pattern := `(\d+\.\d+\.\d+\.\d+)\s*(\d+)`

	re := regexp.MustCompile(pattern)

	matches := re.FindAllStringSubmatch(text, -1)

	for _, m := range matches {
		ip := m[1] + ":" + m[2]

		fmt.Println(``)

	}
}

