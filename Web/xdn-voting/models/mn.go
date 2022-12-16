package models

import (
	"database/sql"
	"encoding/json"
	"time"
)

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

type ListMN struct {
	ID int    `db:"id" json:"id"`
	IP string `db:"ip" json:"ip"`
}

type MNList struct {
	IP             string  `db:"ip" json:"ip"`
	IDNode         int     `db:"idNode" json:"idNode"`
	Amount         float64 `db:"amount" json:"amount"`
	LastRewardDate string  `db:"lastRewardDate" json:"lastRewardDate"`
	Address        string  `db:"address" json:"address"`
}

type MNListInfo struct {
	ID         int           `db:"id" json:"id"`
	IP         string        `db:"ip" json:"ip"`
	DateStart  string        `db:"dateStart" json:"dateStart"`
	LastSeen   sql.NullInt64 `json:"lastSeen" db:"last_seen"`
	TimeActive sql.NullInt64 `json:"timeActive" db:"active_time"`
	Average    string        `db:"average" json:"average"`
}

func (u *MNListInfo) MarshalJSON() ([]byte, error) {
	return json.Marshal(&struct {
		ID         int       `db:"id" json:"id"`
		IP         string    `db:"ip" json:"ip"`
		DateStart  string    `db:"dateStart" json:"dateStart"`
		LastSeen   time.Time `json:"lastSeen" db:"last_seen"`
		TimeActive int64     `json:"timeActive" db:"active_time"`
		Average    string    `db:"average" json:"average_pay_time"`
	}{
		LastSeen:   InlineIF[time.Time](u.LastSeen.Valid, time.Unix(u.LastSeen.Int64, 0), time.Time{}),
		TimeActive: InlineIF[int64](u.TimeActive.Valid, u.TimeActive.Int64, 0),
		ID:         u.ID,
		IP:         u.IP,
		DateStart:  u.DateStart,
		Average:    u.Average,
	})
}

func InlineIF[T any](condition bool, a T, b T) T {
	if condition {
		return a
	}
	return b
}

func (u *MNListInfo) AddAverage(value string) {
	u.Average = value
}

type PendingMN struct {
	IDNode int `db:"idNode" json:"idNode"`
}

type Collateral struct {
	Amount int64 `db:"collateral" json:"amount"`
}

type MNInfoResponse struct {
	Status              string       `json:"status"`
	Error               bool         `json:"hasError"`
	ActiveNodes         int          `json:"active_nodes"`
	AveragePayTime      string       `json:"average_pay_time"`
	AverageRewardPerDay float32      `json:"average_reward_per_day"`
	AverageTimeToStart  string       `json:"average_time_to_start"`
	AveragePayForDay    float32      `json:"average_pay_day"`
	ROI                 float32      `json:"roi"`
	FreeList            []ListMN     `json:"free_list"`
	MnList              []MNListInfo `json:"mn_list"`
	PendingList         []PendingMN  `json:"pending_list"`
	Collateral          int64        `json:"collateral"`
	CollateralTiers     []int64      `json:"collateral_tiers"`
	NodeRewards         []MNList     `json:"node_rewards"`
}

type MNInfoStruct struct {
	IdCoin int `json:"idCoin"`
}

type MasternodeClient struct {
	ID         int            `db:"id"`
	WalletUser string         `db:"wallet_usr"`
	WalletPass string         `db:"wallet_pass"`
	WalletPort int            `db:"wallet_port"`
	NodeIP     string         `db:"node_ip"`
	IP         string         `db:"ip"`
	CoinID     int            `db:"coin_id"`
	Address    string         `db:"address"`
	PrivKey    string         `db:"priv_key"`
	Folder     string         `db:"folder"`
	Conf       string         `db:"conf"`
	Active     int            `db:"active"`
	Locked     int            `db:"locked"`
	LastSeen   sql.NullString `db:"last_seen"`
	ActiveTime sql.NullInt64  `db:"active_time"`
}

type MNUnlockStruct struct {
	IdNode int `json:"idNode"`
}

type SetMN struct {
	CoinID int64 `json:"idCoin"`
	NodeID int   `json:"node_id"`
}

type MNWithStruct struct {
	IdNode int `json:"idNode"`
}

type Client struct {
	Id          int64          `db:"id"`
	IdCoin      int64          `db:"idCoin"`
	Url         string         `db:"url"`
	Token       string         `db:"token"`
	Encrypt     string         `db:"encryptKey"`
	DepositAddr string         `db:"depositAddr"`
	Masternode  int            `db:"masternode"`
	PrivKey     string         `db:"privkey"`
	PassPhrase  sql.NullString `db:"passphrase"`
}

type MNUsers struct {
	Id          int    `db:"id"`
	IdUser      int    `db:"idUser"`
	IdCoin      int    `db:"idCoin"`
	Tier        int    `db:"tier"`
	IdNode      int    `db:"idNode"`
	Session     int    `db:"session"`
	Active      int    `db:"active"`
	DateStart   string `db:"dateStart"`
	DateChanged string `db:"dateChanged"`
}
