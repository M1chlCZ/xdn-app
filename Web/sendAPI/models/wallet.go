package models

type ListUnspent struct {
	Txid          string  `json:"txid"`
	Vout          int     `json:"vout"`
	Address       string  `json:"address"`
	Account       string  `json:"account"`
	ScriptPubKey  string  `json:"scriptPubKey"`
	Amount        float64 `json:"amount"`
	Confirmations int     `json:"confirmations"`
	Spendable     bool    `json:"spendable"`
}

type SignRawTransaction struct {
	Hex      string `json:"hex"`
	Complete bool   `json:"complete"`
}

type RawTxArray struct {
	Txid string `json:"txid"`
	Vout int    `json:"vout"`
}
