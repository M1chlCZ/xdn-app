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
	Id          int             `json:"id" db:"id"`
	IdUser      int             `json:"idUser" db:"idUser"`
	IdServer    int             `json:"idServer" db:"idServer"`
	Amount      sql.NullFloat64 `json:"amount" db:"amount"`
	Session     int             `json:"session" db:"session"`
	Active      int             `json:"active" db:"active"`
	Autostake   bool            `json:"autostake" db:"autostake"`
	DateStart   sql.NullTime    `json:"dateStart" db:"dateStart"`
	DateChanged sql.NullTime    `json:"dateChanged" db:"dateChanged"`
}

type CheckStakeDBStruct struct {
	Amount  sql.NullFloat64 `db:"amount"`
	Session int             `db:"session"`
}

type StakeGetEntry struct {
	Hours  int64   `db:"hour" json:"hour default 0"`
	Amount float64 `db:"amount" json:"amount"`
	Day    string  `db:"day" json:"day"`
}

type PayoutStake struct {
	Id       int     `db:"id"`
	IdUser   int     `db:"idUser"`
	IdServer int     `db:"idServer"`
	Txid     string  `db:"txid"`
	Session  int     `db:"session"`
	Amount   float64 `db:"amount"`
	Datetime string  `db:"datetime"`
	Credited int     `db:"credited"`
}
