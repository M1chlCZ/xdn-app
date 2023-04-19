package models

import (
	"database/sql"
	"encoding/json"
)

type WithReq struct {
	Id           int            `db:"id" json:"id"`
	IdUser       int            `db:"idUser" json:"idUser"`
	Username     string         `db:"username" json:"username"`
	Amount       float64        `db:"amount" json:"amount"`
	SentAmount   float64        `db:"sentAmount" json:"sentAmount"`
	Address      string         `db:"address" json:"address"`
	Auth         int            `db:"auth" json:"auth"`
	Send         int            `db:"send" json:"send"`
	DatePosted   string         `db:"datePosted" json:"datePosted"`
	DateChanged  string         `db:"dateChanged" json:"dateChanged"`
	Processed    int            `db:"processed" json:"processed"`
	IdUserAuth   sql.NullInt64  `db:"idUserAuth" json:"idUserAuth"`
	TxID         sql.NullString `db:"idTx" json:"idTx"`
	WithdrawType int            `db:"withdrawType" json:"withdrawType"`
}

type WithReqVote struct {
	Id           int            `db:"id" json:"id"`
	IdUser       int            `db:"idUser" json:"idUser"`
	Username     string         `db:"username" json:"username"`
	Amount       float64        `db:"amount" json:"amount"`
	Address      string         `db:"address" json:"address"`
	Auth         int            `db:"auth" json:"auth"`
	Send         int            `db:"send" json:"send"`
	DatePosted   string         `db:"datePosted" json:"datePosted"`
	DateChanged  string         `db:"dateChanged" json:"dateChanged"`
	Processed    int            `db:"processed" json:"processed"`
	IdUserAuth   sql.NullInt64  `db:"idUserAuth" json:"idUserAuth"`
	TxID         sql.NullString `db:"idTx" json:"idTx"`
	WithdrawType int            `db:"withdrawType" json:"withdrawType"`
	IdUserVoting sql.NullInt64  `db:"idUserVoting" json:"idUserVoting"`
	Upvote       sql.NullInt64  `db:"upvote" json:"upvotes"`
	Downvote     sql.NullInt64  `db:"downvote" json:"downvotes"`
	CurrentUser  bool           `db:"currentUser" json:"currentUser"`
	SentAmount   float64        `db:"sentAmount" json:"sentAmount"`
}

func (w *WithReqVote) MarshalJSON() ([]byte, error) {
	return json.Marshal(&struct {
		Id           int     `db:"id" json:"id"`
		IdUser       int     `db:"idUser" json:"idUser"`
		Username     string  `db:"username" json:"username"`
		Amount       float64 `db:"amount" json:"amount"`
		Address      string  `db:"address" json:"address"`
		Auth         int     `db:"auth" json:"auth"`
		Send         int     `db:"send" json:"send"`
		DatePosted   string  `db:"datePosted" json:"datePosted"`
		DateChanged  string  `db:"dateChanged" json:"dateChanged"`
		Processed    int     `db:"processed" json:"processed"`
		IdUserAuth   int     `db:"idUserAuth" json:"idUserAuth"`
		TxID         *string `db:"idTx" json:"idTx"`
		WithdrawType int     `db:"withdrawType" json:"withdrawType"`
		IdUserVoting int     `db:"idUserVoting" json:"idUserVoting"`
		Upvote       int     `db:"upvote" json:"upvotes"`
		Downvote     int     `db:"downvote" json:"downvotes"`
		CurrentUser  bool    `db:"currentUser" json:"currentUser"`
	}{
		Id:           w.Id,
		IdUser:       w.IdUser,
		Username:     w.Username,
		Amount:       w.Amount,
		Address:      w.Address,
		Auth:         w.Auth,
		Send:         w.Send,
		DatePosted:   w.DatePosted,
		DateChanged:  w.DateChanged,
		Processed:    w.Processed,
		IdUserAuth:   InlineIF[int](w.IdUserAuth.Valid, int(w.IdUserAuth.Int64), 0),
		TxID:         &w.TxID.String,
		WithdrawType: w.WithdrawType,
		IdUserVoting: InlineIF[int](w.IdUserVoting.Valid, int(w.IdUserVoting.Int64), 0),
		Upvote:       InlineIF[int](w.Upvote.Valid, int(w.Upvote.Int64), 0),
		Downvote:     InlineIF[int](w.Downvote.Valid, int(w.Downvote.Int64), 0),
		CurrentUser:  w.CurrentUser,
	})
}
