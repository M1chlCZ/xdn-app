package models

type Bugs struct {
	Id          int     `json:"id" db:"id"`
	IdUser      int     `json:"idUser" db:"idUser"`
	BugDesc     string  `json:"bugDesc" db:"bugDesc"`
	BugLocation string  `json:"bugLocation" db:"bugLocation"`
	DateSubmit  string  `json:"dateSubmit" db:"dateSubmit"`
	DateProcess string  `json:"dateProcess" db:"dateProcess"`
	Processed   int     `json:"processed" db:"processed"`
	Comment     *string `json:"comment" db:"comment"`
	Reward      float64 `json:"reward" db:"reward"`
}

type BugsAdmin struct {
	ID          int     `db:"id" json:"id"`
	IDUser      int     `db:"idUser" json:"idUser"`
	BugDesc     string  `db:"bugDesc" json:"bugDesc"`
	BugLocation string  `db:"bugLocation" json:"bugLocation"`
	DateSubmit  string  `db:"dateSubmit" json:"dateSubmit"`
	DateProcess string  `db:"dateProcess" json:"dateProcess"`
	Processed   int     `db:"processed" json:"processed"`
	Comment     *string `db:"comment" json:"comment"`
	Reward      float64 `db:"reward" json:"reward"`
	Addr        string  `db:"addr" json:"addr"`
	Username    string  `db:"username" json:"username"`
}
