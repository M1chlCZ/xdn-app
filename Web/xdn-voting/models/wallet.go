package models

type ListUnspent struct {
	Txid          string  `json:"txid"`
	Vout          int     `json:"vout"`
	Address       string  `json:"address"`
	Account       string  `json:"account"`
	ScriptPubKey  string  `json:"scriptPubKey"`
	Amount        float64 `json:"amount"`
	Confirmations int     `json:"confirmations"`
	Spendable     bool    `json:"spendable"`
}

type SignRawTransaction struct {
	Hex      string `json:"hex"`
	Complete bool   `json:"complete"`
}

type RawTxArray struct {
	Txid string `json:"txid"`
	Vout int    `json:"vout"`
}

type GetTransaction struct {
	Txid     string `json:"txid"`
	Version  int    `json:"version"`
	Time     int    `json:"time"`
	Locktime int    `json:"locktime"`
	Vin      []struct {
		Txid      string `json:"txid"`
		Vout      int    `json:"vout"`
		ScriptSig struct {
			Asm string `json:"asm"`
			Hex string `json:"hex"`
		} `json:"scriptSig"`
		Sequence int64 `json:"sequence"`
	} `json:"vin"`
	Vout []struct {
		Value        float64 `json:"value"`
		N            int     `json:"n"`
		ScriptPubKey struct {
			Asm       string   `json:"asm"`
			Hex       string   `json:"hex"`
			ReqSigs   int      `json:"reqSigs"`
			Type      string   `json:"type"`
			Addresses []string `json:"addresses"`
		} `json:"scriptPubKey"`
	} `json:"vout"`
	Amount          float64       `json:"amount"`
	Fee             float64       `json:"fee"`
	Confirmations   int           `json:"confirmations"`
	Bcconfirmations int           `json:"bcconfirmations"`
	Blockhash       string        `json:"blockhash"`
	Blockindex      int           `json:"blockindex"`
	Blocktime       int           `json:"blocktime"`
	Walletconflicts []interface{} `json:"walletconflicts"`
	Timereceived    int           `json:"timereceived"`
	Details         []struct {
		Account  string  `json:"account"`
		Address  string  `json:"address"`
		Category string  `json:"category"`
		Amount   float64 `json:"amount"`
		Fee      float64 `json:"fee"`
	} `json:"details"`
}

type ListTransactions []struct {
	Account         string        `json:"account"`
	Address         string        `json:"address"`
	Category        string        `json:"category"`
	Amount          float64       `json:"amount"`
	Confirmations   int           `json:"confirmations"`
	Bcconfirmations int           `json:"bcconfirmations"`
	Blockhash       string        `json:"blockhash,omitempty"`
	Blockindex      int           `json:"blockindex,omitempty"`
	Blocktime       int           `json:"blocktime,omitempty"`
	Txid            string        `json:"txid"`
	Walletconflicts []interface{} `json:"walletconflicts"`
	Time            int           `json:"time"`
	Timereceived    int           `json:"timereceived"`
}

type ListStakeRewards []struct {
	Account         string  `json:"account"`
	Address         string  `json:"address"`
	Category        string  `json:"category"`
	Amount          float64 `json:"amount"`
	Confirmations   int     `json:"confirmations"`
	Bcconfirmations int     `json:"bcconfirmations"`
	Blockhash       string  `json:"blockhash"`
	Txid            string  `json:"txid"`
	Time            int     `json:"time"`
	Timereceived    int     `json:"timereceived"`
}

type DaemonStatus struct {
	Block           bool `json:"block"`
	BlockStake      bool `json:"blockStake"`
	WalletStake     bool `json:"stakingActive"`
	BlockCount      int  `json:"blockCount"`
	MasternodeCount int  `json:"masternodeCount"`
}

type StakingInfo struct {
	Enabled          bool    `json:"enabled"`
	Staking          bool    `json:"staking"`
	Errors           string  `json:"errors"`
	Currentblocksize int     `json:"currentblocksize"`
	Currentblocktx   int     `json:"currentblocktx"`
	Pooledtx         int     `json:"pooledtx"`
	Difficulty       float64 `json:"difficulty"`
	SearchInterval   int     `json:"search-interval"`
	Weight           int64   `json:"weight"`
	Netstakeweight   int64   `json:"netstakeweight"`
	Expectedtime     int     `json:"expectedtime"`
	Stakethreshold   int     `json:"stakethreshold"`
}
