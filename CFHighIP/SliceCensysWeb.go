package main

import (
	"fmt"
	"regexp"
)

func main() {
	data := `

`

	re := regexp.MustCompile(`(?m)(\d+\.\d+\.\d+\.\d+[\s\S]*?(?:None|\z))`)

	blocks := re.FindAllString(data, -1)

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

