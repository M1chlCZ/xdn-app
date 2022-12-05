package models

import "database/sql"

type MnVerify struct {
	IdCoin       int     `db:"idCoin"`
	IdUser       int     `db:"idUser"`
	Amount       float64 `db:"amount"`
	IncomingTXID int     `db:"incoming_id"`
	WalletTXID   int     `db:"wallet_id"`
	NodeID       int     `db:"idNode"`
	TXID         string  `db:"tx_id"`
}

type WalletMNTX struct {
	Id        int           `db:"id"`
	IdCoin    int           `db:"idCoin"`
	IdNode    int           `db:"idNode"`
	Amount    float64       `db:"amount"`
	IdUser    sql.NullInt64 `db:"idUser"`
	Generated bool          `db:"mn_tx"`
	TXID      string        `db:"tx_id"`
	Processed bool          `db:"processed"`
	DateC     string        `db:"date_created"`
	DateP     string        `db:"processed_at"`
}
