package main

import (
	"fmt"
	"regexp"
)

func main() {
	data := `

`
	
	blocks := splitByIP(data)

	for _, b := range blocks {
		ipRe := regexp.MustCompile(`(\d+\.\d+\.\d+\.\d+)`)
		ip := ipRe.FindString(b)
        
		portRe := regexp.MustCompile(`\s*(\d+)\s*\/\s*HTTP`)
        
		portStr := portRe.FindAllStringSubmatch(b, -1)
		for _, p := range portStr {
          fmt.Println( ``)
		}
	
	}
}

func splitByIP(text string) []string {
	ipRe := regexp.MustCompile(`\d+\.\d+\.\d+\.\d+`)

	var result []string

	first := ipRe.FindStringIndex(text)
	if first == nil {
		return result
	}

	text = text[first[0]:]

	for {
		indices := ipRe.FindAllStringIndex(text, 2)

		if len(indices) == 1 {
			result = append(result, strings.TrimSpace(text))
			break
		}

		block := text[:indices[1][0]]
		result = append(result, strings.TrimSpace(block))

		text = text[indices[1][0]:]
	}

	return result
}

