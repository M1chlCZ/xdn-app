package models

type TokenTX struct {
	//IdUser          int    `json:"idUser" db:"idUser"`
	Hash string `json:"hash" db:"hash"`
	//Blocknumber     int    `json:"blocknumber" db:"blocknumber"`
	TimestampTX int `json:"timestampTX" db:"timestampTX"`
	//Blockhash       string `json:"blockhash" db:"blockhash"`
	FromAddr string `json:"fromAddr" db:"fromAddr"`
	ToAddr   string `json:"toAddr" db:"toAddr"`
	//ContractAddr    string `json:"contractAddr" db:"contractAddr"`
	ContractDecimal int    `json:"contractDecimal" db:"contractDecimal"`
	Amount          string `json:"amount" db:"amount"`
	//TokenName       string `json:"tokenName" db:"tokenName"`
	//TokenSymbol     string `json:"tokenSymbol" db:"tokenSymbol"`
	//Gas             string `json:"gas" db:"gas"`
	//GasPrice        string `json:"gasPrice" db:"gasPrice"`
	//GasUsed         string `json:"gasUsed" db:"gasUsed"`
	Confirmations int `json:"confirmations" db:"confirmations"`
}

type GetTokenTxReq struct {
	Timestamp int `json:"timestamp"`
}
