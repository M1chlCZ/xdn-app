package models

type User struct {
	Id        int     `json:"id" db:"id"`
	Username  string  `json:"username" db:"username"`
	Password  string  `json:"password" db:"password"`
	Email     string  `json:"email" db:"email"`
	Addr      string  `json:"addr" db:"addr"`
	Admin     int     `json:"admin" db:"admin"`
	Level     int     `json:"level" db:"level"`
	Nickname  string  `json:"nickname" db:"nickname"`
	Banned    int     `json:"banned" db:"banned"`
	Realname  string  `json:"realname" db:"realname"`
	Avatar    *string `json:"avatar" db:"avatar"`
	Av        int     `json:"av" db:"av"`
	UDID      string  `json:"UDID" db:"UDID"`
	Privkey   string  `json:"privkey" db:"privkey"`
	TwoKey    *string `json:"twoKey" db:"twoKey"`
	TwoActive int     `json:"twoActive" db:"twoActive"`
}

type UsersTokenAddr struct {
	Id     int    `json:"id" db:"id"`
	Addr   string `json:"addr" db:"addr"`
	IdUser int    `json:"idUser" db:"idUser"`
}

type UserLogin struct {
	Username  string `json:"username"`
	Password  string `json:"password"`
	TwoFactor int64  `json:"twoFactor"`
}
