package models

import "fmt"

type AddMNConfig struct {
	CoinFolder       string
	PortPrefix       int
	MasternodePort   int
	BlockchainFolder string
	ConfigFile       string
	DaemonName       string
	CliName          string
	CoinID           int
}

func (s *AddMNConfig) ToString() string {
	return fmt.Sprint("Adding Masternode \nCoinFolder: ", s.CoinFolder, "\n", "PortPrefix: ", s.PortPrefix, "\n", "MasternodePort: ", s.MasternodePort, "\n", "BlockchainFolder: ", s.BlockchainFolder, "\n", "ConfigFile: ", s.ConfigFile, "\n", "DaemonName: ", s.DaemonName, "\n", "CliName: ", s.CliName, "\n", "CoinID: ", s.CoinID, "\n")
}

type MasternodeTemplate struct {
	Id               int    `json:"id" db:"id"`
	CoinFolder       string `json:"coinFolder" db:"coinFolder"`
	PortPrefix       int    `json:"portPrefix" db:"portPrefix"`
	MasternodePort   int    `json:"masternodePort" db:"masternodePort"`
	BlockchainFolder string `json:"blockchainFolder" db:"blockchainFolder"`
	ConfigFile       string `json:"configFile" db:"configFile"`
	DaemonPath       string `json:"daemonPath" db:"daemonPath"`
	CliPath          string `json:"cliPath" db:"cliPath"`
	CoinID           int    `json:"coinID" db:"coinID"`
}
