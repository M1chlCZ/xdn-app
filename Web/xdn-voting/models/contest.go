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
	Finished      int        `json:"finished" db:"finished"`
}

type ContestEntry struct {
	Id         int     `json:"id" db:"id"`
	Name       string  `json:"name" db:"name"`
	Amount     float32 `json:"amount" db:"amount"`
	UserAmount float32 `json:"userAmount" db:"userAmount"`
}

type ContestResponse struct {
	Id            int            `json:"idContest"`
	Name          string         `json:"contestName"`
	AmountToReach null.Float     `json:"amountToReach"`
	DateEnding    null.Time      `json:"dateEnding"`
	Entries       []ContestEntry `json:"entries"`
}
