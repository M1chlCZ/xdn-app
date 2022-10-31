package models

import (
	"database/sql"
	"github.com/simplereach/timeutils"
)

type GetStakeStruct struct {
	Type     int            `json:"type"`
	Datetime timeutils.Time `json:"datetime"`
}

type StakeDailyGraph struct {
	Hours  int     `db:"hour" json:"hour"`
	Amount float64 `db:"amount" json:"amount"`
	Day    string  `db:"day" json:"day"`
}

type StakeWeeklyGraph struct {
	Amount float64 `db:"amount" json:"amount"`
	Day    string  `db:"day" json:"day"`
}

type StakeUsers struct {
	Id        int             `json:"id" db:"id"`
	IdUser    int             `json:"idUser" db:"idUser"`
	IdServer  int             `json:"idServer" db:"idServer"`
	Amount    sql.NullFloat64 `json:"amount" db:"amount"`
	Session   int             `json:"session" db:"session"`
	Active    int             `json:"active" db:"active"`
	DateStart sql.NullTime    `json:"dateStart" db:"dateStart"`
}

type CheckStakeDBStruct struct {
	Amount  sql.NullFloat64 `db:"amount"`
	Session int             `db:"session"`
}
