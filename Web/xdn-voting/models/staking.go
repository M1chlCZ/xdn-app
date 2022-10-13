package models

import "github.com/simplereach/timeutils"

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
