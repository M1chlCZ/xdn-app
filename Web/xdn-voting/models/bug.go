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
