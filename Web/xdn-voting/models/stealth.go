package models

type StealthBalance struct {
	Immature  float32 `json:"immature"`
	Balance   float32 `json:"balance"`
	Spendable float32 `json:"spendable"`
}

type Stealth struct {
	ID       int64  `db:"id"`
	Addr     string `db:"addr"`
	IDUser   int64  `db:"idUser"`
	AddrName string `db:"addrName"`
}
