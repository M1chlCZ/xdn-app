package models

type Transaction struct {
	Id           int     `json:"id" db:"id"`
	Txid         string  `json:"txid" db:"txid"`
	Amount       float64 `json:"amount" db:"amount"`
	Confirmation int     `json:"confirmation" db:"confirmation"`
	Category     string  `json:"category" db:"category"`
	Address      string  `json:"address" db:"address"`
	Account      string  `json:"account" db:"account"`
	Date         string  `json:"date" db:"date"`
	ContactName  *string `json:"contactName" db:"contactName"`
	Notified     int     `json:"notified" db:"notified"`
}
