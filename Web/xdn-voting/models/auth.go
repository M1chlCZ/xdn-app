package models

type Auth struct {
	Id int `json:"id"`
}

type UserLogin struct {
	Username  string `json:"username"`
	Password  string `json:"password"`
	TwoFactor string `json:"twoFactor"`
}

type RefreshToken struct {
	Token string `json:"token"`
}

type RefreshTokenStruct struct {
	Id        int64  `db:"id"`
	IdUser    int64  `db:"idUser"`
	RefToken  string `db:"refreshToken"`
	Used      int8   `db:"used"`
	CreatedAt string `db:"createdAt"`
}

type RegisterUserStruct struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Email    string `json:"email"`
	RealName string `json:"realname"`
	Udid     string `json:"udid"`
}
