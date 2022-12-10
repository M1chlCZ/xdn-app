package models

type MasternodeStart struct {
	Overall string `json:"overall"`
	Detail  []struct {
		Alias  string `json:"alias"`
		Result string `json:"result"`
		Error  string `json:"error"`
	} `json:"detail"`
}
