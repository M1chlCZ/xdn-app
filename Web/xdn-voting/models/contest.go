package models

import (
	"gopkg.in/guregu/null.v4"
)

type Contest struct {
	Id            int        `json:"id" db:"id"`
	Name          string     `json:"name" db:"name"`
	DateCreated   string     `json:"dateCreated" db:"dateCreated"`
	DateEnding    null.Time  `json:"dateEnding" db:"dateEnding"`
	AmountToReach null.Float `json:"amountToReach" db:"amountToReach"`
	IDCreator     int        `json:"idCreator" db:"idCreator"`
	Finished      int        `json:"finished" db:"finished"`
}

type ContestEntry struct {
	Id         int     `json:"id" db:"id"`
	Name       string  `json:"name" db:"name"`
	Amount     float32 `json:"amount" db:"amount"`
	UserAmount float32 `json:"userAmount" db:"userAmount"`
	Address    string  `json:"address" db:"address"`
	Goal       int64   `json:"goal" db:"goal"`
}

type ContestResponse struct {
	Id            int            `json:"idContest"`
	Name          string         `json:"contestName"`
	AmountToReach null.Float     `json:"amountToReach"`
	DateEnding    null.Time      `json:"dateEnding"`
	Entries       []ContestEntry `json:"entries"`
}
