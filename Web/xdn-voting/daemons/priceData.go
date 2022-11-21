package daemons

import (
	"encoding/json"
	"io"
	"strconv"
	"xdn-voting/models"
	"xdn-voting/utils"
)

var PriceDat map[string]float64

func PriceData() {
	getAny, getError := utils.GETAny("https://api.coingecko.com/api/v3/coins/digitalnote?tickers=false&market_data=true&community_data=false&developer_data=false&sparkline=false")
	if getError != nil {
		utils.WrapErrorLog("COINGECKO ISSUE" + " " + getError.ErrorMessage() + " " + strconv.Itoa(getError.StatusCode()))
		return
	}
	body, _ := io.ReadAll(getAny.Body)
	var pr models.PriceDatStruct
	err := json.Unmarshal(body, &pr)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	PriceDat = map[string]float64{
		"usd":  pr.MarketData.CurrentPrice.Usd,
		"eur":  pr.MarketData.CurrentPrice.Eur,
		"jpy":  pr.MarketData.CurrentPrice.Jpy,
		"gbp":  pr.MarketData.CurrentPrice.Gbp,
		"aud":  pr.MarketData.CurrentPrice.Aud,
		"cad":  pr.MarketData.CurrentPrice.Cad,
		"chf":  pr.MarketData.CurrentPrice.Chf,
		"sek":  pr.MarketData.CurrentPrice.Sek,
		"dkk":  pr.MarketData.CurrentPrice.Dkk,
		"nzd":  pr.MarketData.CurrentPrice.Nzd,
		"rub":  pr.MarketData.CurrentPrice.Rub,
		"try":  pr.MarketData.CurrentPrice.Try,
		"hkd":  pr.MarketData.CurrentPrice.Hkd,
		"sgd":  pr.MarketData.CurrentPrice.Sgd,
		"krw":  pr.MarketData.CurrentPrice.Krw,
		"twd":  pr.MarketData.CurrentPrice.Twd,
		"thb":  pr.MarketData.CurrentPrice.Thb,
		"pln":  pr.MarketData.CurrentPrice.Pln,
		"czk":  pr.MarketData.CurrentPrice.Czk,
		"huf":  pr.MarketData.CurrentPrice.Huf,
		"zar":  pr.MarketData.CurrentPrice.Zar,
		"uah":  pr.MarketData.CurrentPrice.Uah,
		"nok":  pr.MarketData.CurrentPrice.Nok,
		"mxn":  pr.MarketData.CurrentPrice.Mxn,
		"ils":  pr.MarketData.CurrentPrice.Ils,
		"brl":  pr.MarketData.CurrentPrice.Brl,
		"myr":  pr.MarketData.CurrentPrice.Myr,
		"php":  pr.MarketData.CurrentPrice.Php,
		"idr":  pr.MarketData.CurrentPrice.Idr,
		"btc":  pr.MarketData.CurrentPrice.Btc,
		"eth":  pr.MarketData.CurrentPrice.Eth,
		"ltc":  pr.MarketData.CurrentPrice.Ltc,
		"bch":  pr.MarketData.CurrentPrice.Bch,
		"xrp":  pr.MarketData.CurrentPrice.Xrp,
		"eos":  pr.MarketData.CurrentPrice.Eos,
		"link": pr.MarketData.CurrentPrice.Link,
		"dot":  pr.MarketData.CurrentPrice.Dot,
		"yfi":  pr.MarketData.CurrentPrice.Yfi,
		"aed":  pr.MarketData.CurrentPrice.Aed,
		"ars":  pr.MarketData.CurrentPrice.Ars,
	}
}
