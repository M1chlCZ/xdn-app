package service

import (
	"github.com/oschwald/geoip2-golang"
	"net"
	"strings"
	"time"
	"xdn-voting/database"
	"xdn-voting/utils"
)

func GetLocationData(ip string, idUser int64) {
	dbb, err := geoip2.Open("./GeoLite2-City.mmdb")
	if err != nil {
		utils.WrapErrorLog(err.Error())
	}
	defer func(dbb *geoip2.Reader) {
		_ = dbb.Close()
	}(dbb)

	ipp := net.ParseIP(strings.Split(ip, ":")[0])
	results, err := dbb.City(ipp)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	location, err := time.LoadLocation(results.Location.TimeZone)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}

	_, tzOffset := time.Now().In(location).Zone()

	_, err = database.InsertSQl("INSERT INTO location (ip, timeoffset, location, city, idUser) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE timeoffset = ?", ip, tzOffset, results.Country.Names["en"], results.City.Names["en"], idUser, tzOffset)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
}
