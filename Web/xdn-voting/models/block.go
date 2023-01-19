package models

type BlockTX struct {
	Active        string  `json:"active"`
	Tx            TxBlock `json:"tx"`
	Confirmations int     `json:"confirmations"`
	Blockcount    int     `json:"blockcount"`
}
type VinBlock struct {
	Addresses string `json:"addresses"`
	Amount    int64  `json:"amount"`
}
type VoutBlock struct {
	Addresses string `json:"addresses"`
	Amount    int64  `json:"amount"`
}
type TxBlock struct {
	Vin        []VinBlock  `json:"vin"`
	Vout       []VoutBlock `json:"vout"`
	Total      int64       `json:"total"`
	Timestamp  int         `json:"timestamp"`
	Blockindex int         `json:"blockindex"`
	ID         string      `json:"_id"`
	Txid       string      `json:"txid"`
	Blockhash  string      `json:"blockhash"`
	V          int         `json:"__v"`
}
