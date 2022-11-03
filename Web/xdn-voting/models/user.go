package models

import "database/sql"

type User struct {
	Id           int            `json:"id" db:"id"`
	Username     string         `json:"username" db:"username"`
	Password     string         `json:"password" db:"password"`
	Email        string         `json:"email" db:"email"`
	Addr         string         `json:"addr" db:"addr"`
	Admin        int            `json:"admin" db:"admin"`
	Level        int            `json:"level" db:"level"`
	Nickname     string         `json:"nickname" db:"nickname"`
	Banned       int            `json:"banned" db:"banned"`
	Realname     string         `json:"realname" db:"realname"`
	Avatar       sql.NullString `json:"avatar" db:"avatar"`
	Av           int            `json:"av" db:"av"`
	UDID         string         `json:"UDID" db:"UDID"`
	Privkey      sql.NullString `json:"privkey" db:"privkey"`
	TwoKey       sql.NullString `json:"twoKey" db:"twoKey"`
	TwoActive    int            `json:"twoActive" db:"twoActive"`
	TokenSocials sql.NullString `json:"tokenSocials" db:"tokenSocials"`
}

type UsersTokenAddr struct {
	Id     int    `json:"id" db:"id"`
	Addr   string `json:"addr" db:"addr"`
	IdUser int    `json:"idUser" db:"idUser"`
}

type DataRefreshToken struct {
	Token        string `json:"token"`
	RefreshToken string `json:"refreshToken"`
}
