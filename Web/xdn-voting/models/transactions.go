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

type MNTX struct {
	Txid            string        `json:"txid"`
	Version         int           `json:"version"`
	Time            int           `json:"time"`
	Locktime        int           `json:"locktime"`
	Vin             []Vin         `json:"vin"`
	Vout            []Vout        `json:"vout"`
	Amount          int           `json:"amount"`
	Fee             float64       `json:"fee"`
	Confirmations   int           `json:"confirmations"`
	Bcconfirmations int           `json:"bcconfirmations"`
	Blockhash       string        `json:"blockhash"`
	Blockindex      int           `json:"blockindex"`
	Blocktime       int           `json:"blocktime"`
	Walletconflicts []interface{} `json:"walletconflicts"`
	Timereceived    int           `json:"timereceived"`
	Details         []Details     `json:"details"`
}
type ScriptSig struct {
	Asm string `json:"asm"`
	Hex string `json:"hex"`
}
type Vin struct {
	Txid      string    `json:"txid"`
	Vout      int       `json:"vout"`
	ScriptSig ScriptSig `json:"scriptSig"`
	Sequence  int64     `json:"sequence"`
}
type ScriptPubKey struct {
	Asm       string   `json:"asm"`
	Hex       string   `json:"hex"`
	ReqSigs   int      `json:"reqSigs"`
	Type      string   `json:"type"`
	Addresses []string `json:"addresses"`
}
type Vout struct {
	Value        float64      `json:"value"`
	N            int          `json:"n"`
	ScriptPubKey ScriptPubKey `json:"scriptPubKey"`
}
type Details struct {
	Account  string  `json:"account"`
	Address  string  `json:"address"`
	Category string  `json:"category"`
	Amount   float64 `json:"amount"`
	Fee      float64 `json:"fee,omitempty"`
}
