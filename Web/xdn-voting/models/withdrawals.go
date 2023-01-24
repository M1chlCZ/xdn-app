package models

type Withdrawals struct {
	Amount      float64 `json:"amount" db:"amount"`
	DatePosted  string  `json:"datePosted" db:"datePosted"`
	DateChanged string  `json:"dateChanged" db:"dateChanged"`
	IdUserAuth  *int64  `json:"idUserAuth" db:"idUserAuth"`
	Username    *string `json:"username" db:"username"`
	Send        int     `json:"send" db:"send"`
	Auth        int     `json:"auth" db:"auth"`
	Processed   int     `json:"processed" db:"processed"`
	IdTx        *string `json:"idTx" db:"idTx"`
}
