package daemons

import (
	"database/sql"
	"fmt"
	"time"
	"xdn-voting/database"
	"xdn-voting/utils"
)

var stats []map[int]string

func MNStatistic() {
	stats = make([]map[int]string, 0)

	type Coins struct {
		CoinID int64 `db:"coinID"`
	}

	coinsList, errDB := database.ReadArrayStruct[Coins]("SELECT coin_id as coinID FROM mn_clients group by coin_id")
	if errDB != nil {
		utils.WrapErrorLog(errDB.Error())
		return
	}

	for _, cn := range coinsList {
		coinID := cn.CoinID
		type listMN struct {
			ID   int    `db:"id" json:"id"`
			IP   string `db:"ip" json:"ip"`
			Addr string `db:"address" json:"address"`
		}
		freeMasternodesQuery := "SELECT id, ip, address FROM mn_clients WHERE active = 1 AND coin_id = ? AND active = 1"

		s, errDB := database.ReadArrayStruct[listMN](freeMasternodesQuery, coinID)
		if errDB != nil {
			utils.WrapErrorLog(fmt.Sprintf("%v, Node ID: %d", errDB.Error(), coinID))
			return
		}

		var count int64 = 0
		var sumFirst int64 = 0
		for _, node := range s {
			sqlFirst := "SELECT IFNULL(TIMESTAMPDIFF(MICROSECOND, tt.d, tt.d2) DIV 1000,0) as milli FROM (SELECT a.dateChanged as d, b.datetime as d2 FROM users_mn as a, payouts_masternode as b WHERE a.idNode = ? AND a.active= 1 AND a.session = b.session AND a.idNode = b.idNode ORDER BY datetime ASC  LIMIT 1) as tt"
			averageFirstTime, err := database.ReadValue[sql.NullInt64](sqlFirst, node.ID)
			if err != nil || averageFirstTime.Valid == false {
				continue
			}
			if averageFirstTime.Int64 > 0 {
				sumFirst += averageFirstTime.Int64
				count++
			}
		}
		if count > 0 {
			avgFirstStart := sumFirst / count
			dur := time.Duration(avgFirstStart) * time.Millisecond
			m := make(map[int]string)
			m[int(coinID)] = fmt.Sprintf("%v", utils.FmtDuration(dur))
			stats = append(stats, m)
		}
	}
}

func GetMNStatistic() []map[int]string {
	return stats
}
