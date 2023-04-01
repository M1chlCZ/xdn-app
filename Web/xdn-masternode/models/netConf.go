package models

type NetConfig struct {
	Network struct {
		Version   int                 `yaml:"version"`
		Renderer  string              `yaml:"renderer"`
		Ethernets map[string]Ethernet `yaml:"ethernets"`
	} `yaml:"network"`
}

type Ethernet struct {
	Match       map[string]string   `yaml:"match"`
	Addresses   []string            `yaml:"addresses"`
	Gateway6    string              `yaml:"gateway6"`
	Routes      []map[string]string `yaml:"routes"`
	Nameservers map[string][]string `yaml:"nameservers"`
}
