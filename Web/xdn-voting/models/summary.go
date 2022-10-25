package models

type Summary struct {
	Data []struct {
		Difficulty       float64 `json:"difficulty"`
		DifficultyHybrid string  `json:"difficultyHybrid"`
		Supply           float64 `json:"supply"`
		Hashrate         string  `json:"hashrate"`
		LastPrice        float64 `json:"lastPrice"`
		Connections      int     `json:"connections"`
		Blockcount       int     `json:"blockcount"`
		Masternodecount  int     `json:"masternodecount"`
		Mempoolcount     int     `json:"mempoolcount"`
	} `json:"data"`
}
