package models

import "database/sql"

type WithReq struct {
	Id          int            `db:"id" json:"id"`
	IdUser      int            `db:"idUser" json:"idUser"`
	Username    string         `db:"username" json:"username"`
	Amount      float64        `db:"amount" json:"amount"`
	Address     string         `db:"address" json:"address"`
	Auth        int            `db:"auth" json:"auth"`
	Send        int            `db:"send" json:"send"`
	DatePosted  string         `db:"datePosted" json:"datePosted"`
	DateChanged string         `db:"dateChanged" json:"dateChanged"`
	Processed   int            `db:"processed" json:"processed"`
	IdUserAuth  sql.NullInt64  `db:"idUserAuth" json:"idUserAuth"`
	TxID        sql.NullString `db:"idTx" json:"idTx"`
}
