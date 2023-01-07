package utils

import (
	"bufio"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	firebase2 "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"fmt"
	"github.com/bitly/go-simplejson"
	"github.com/dgrijalva/jwt-go"
	_ "github.com/go-sql-driver/mysql"
	"github.com/gofiber/fiber/v2"
	"github.com/joho/godotenv"
	"google.golang.org/api/option"
	"io"
	_ "io/ioutil"
	"log"
	"math"
	"math/big"
	mathRand "math/rand"
	"net/http"
	"os"
	"os/exec"
	"regexp"
	"runtime"
	"strings"
	"time"
	"unicode"
	"xdn-voting/encrypt"
	"xdn-voting/models"
)

const (
	VERSION              = "0.0.1.8"
	STATUS        string = "status"
	OK            string = "OK"
	FAIL          string = "FAIL"
	ERROR         string = "hasError"
	ERROR_MESSAGE        = "errorMessage"
)

var colorReset = "\033[0m"
var colorRed = "\033[31m"

//var colorGreen = "\033[32m"
//var colorYellow = "\033[33m"
//var colorBlue = "\033[34m"
//var colorPurple = "\033[35m"
//var colorCyan = "\033[36m"
//var colorWhite = "\033[37m"

func InlineIF(condition bool, a interface{}, b interface{}) interface{} {
	if condition {
		return a
	}
	return b
}

func InlineIFT[T any](condition bool, a T, b T) T {
	if condition {
		return a
	}
	return b
}

func GetENV(key string) string {
	err := godotenv.Load(".env")
	if err != nil {
		WrapErrorLog("Error loading .env file")
	}
	return os.Getenv(key)
}

func ReportError(c *fiber.Ctx, err string, statusCode int) error {
	json := fiber.Map{
		"errorMessage": err,
		STATUS:         FAIL,
		ERROR:          true,
	}

	if !strings.Contains(err, "tx_id_UNIQUE") || strings.Contains(err, "Invalid Token, id User") {
		logToFile("")
		logToFile("//// - HTTP ERROR - ////")
		logToFile("HTTP call failed : " + err + "  Status code: " + fmt.Sprintf("%d", statusCode))
		logToFile("////==========////")
		logToFile("")
	}

	return c.Status(statusCode).JSON(json)
	// json.NewEncoder(w).Encode(err)
}

func ReportOK(w http.ResponseWriter, err string, statusCode int) {
	json := simplejson.New()
	json.Set("message", err)
	json.Set(STATUS, OK)
	json.Set(ERROR, false)

	payload, e := json.MarshalJSON()
	if e != nil {
		log.Println(err)
	}
	ReportMessage(err)
	w.WriteHeader(statusCode)
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(payload)
	// json.NewEncoder(w).Encode(err)
	return
}

func ReportErrorSilent(c *fiber.Ctx, err string, statusCode int) error {
	json := fiber.Map{
		"errorMessage": err,
		STATUS:         FAIL,
		ERROR:          true,
	}
	return c.Status(statusCode).JSON(json)
}

func ReportEncError(enc string, w http.ResponseWriter, err string, statusCode int) {
	url, errors := exec.Command("bash", "-c", "ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\\.){3}[0-9]*).*/\\2/p'").Output()
	if errors != nil {
		log.Fatal(errors)
	}
	json := simplejson.New()
	json.Set("errorMessage", err)
	json.Set(STATUS, FAIL)
	json.Set(ERROR, true)

	payload, e := json.MarshalJSON()
	if e != nil {
		log.Println(err)
	}
	logToFile("")
	logToFile("//// - HTTP ERROR - ////")
	logToFile("HTTP call failed : " + err + "  Status code: " + fmt.Sprintf("%d", statusCode))
	logToFile("////==========////")
	logToFile("")

	w.Header().Add("url", string(url))
	encryptMessage, _ := encrypt.EncMessage(enc, payload)
	_ = SendResponse(w, []byte(encryptMessage))
	// json.NewEncoder(w).Encode(err)
	return
}

func CreateToken(userId uint64) (string, error) {
	var err error
	//Creating Access Token
	jwtKey := GetENV("JWT_KEY")

	atClaims := jwt.MapClaims{}
	atClaims["authorized"] = true
	atClaims["idUser"] = userId
	atClaims["exp"] = time.Now().Add(time.Hour * 24 * 365).Unix()
	at := jwt.NewWithClaims(jwt.SigningMethodHS256, atClaims)
	token, err := at.SignedString([]byte(jwtKey))
	if err != nil {
		return "", err
	}
	return token, nil
}

func GenerateSecureToken(length int) string {
	b := make([]byte, length)
	if _, err := rand.Read(b); err != nil {
		return ""
	}
	return hex.EncodeToString(b)
}

func SendResponse(w http.ResponseWriter, payload []byte) error {
	w.Header().Set("User-agent", "XDN Service v"+VERSION)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(200)
	_, err := w.Write(payload)
	if err != nil {
		return err
	}
	return nil
}

func ScheduleFunc(f func(), interval time.Duration) *time.Ticker {
	ticker := time.NewTicker(interval)
	go func() {
		for range ticker.C {
			f()
			//ReportMessage("Scheduled function executed")
		}
	}()
	return ticker
}

func logToFile(message string) {
	f, err := os.OpenFile("api.log", os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
	if err != nil {
		log.Printf("error opening file: %v\n", err)
	}
	wrt := io.MultiWriter(os.Stdout, f)
	log.SetOutput(wrt)
	log.Println(message)
	_ = f.Close()
}

func WrapErrorLog(message string) {
	if !strings.Contains(message, "tx_id_UNIQUE") {
		logToFile("//// - ERROR - ////")
		logToFile(message)
		logToFile("////===========////")
		logToFile("")
	}
}

func ReportMessage(message string) {
	go func() {
		logToFile(message)
		logToFile("")
	}()
}

func round(num float64) int {
	return int(num + math.Copysign(0.5, num))
}

func ToFixed(num float64, precision int) float64 {
	output := math.Pow(10, float64(precision))
	return float64(round(num*output)) / output
}

func TrimQuotes(s string) string {
	if len(s) >= 2 {
		if c := s[len(s)-1]; s[0] == c && (c == '"' || c == '\'') {
			return s[1 : len(s)-1]
		}
	}
	return s
}

func GetHomeDir() string {
	if runtime.GOOS == "windows" {
		home := os.Getenv("HOMEDRIVE") + os.Getenv("HOMEPATH")
		if home == "" {
			home = os.Getenv("USERPROFILE")
		}
		return home
	} else if runtime.GOOS == "linux" {
		home := os.Getenv("XDG_CONFIG_HOME")
		if home != "" {
			return home
		}
	}
	return os.Getenv("HOME")
}

func FmtDuration(d time.Duration) string {
	d = d.Round(time.Second)
	h := d / time.Hour
	d -= h * time.Hour
	m := d / time.Minute
	d -= m * time.Minute
	s := d / time.Second
	return fmt.Sprintf("%02d:%02d:%02d", h, m, s)
}

func ArrContains(s []string, e string) bool {
	for _, a := range s {
		if a == e {
			return true
		}
	}
	return false
}

func GenerateNewPassword(length int) string {
	var letterRunes = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
	b := make([]rune, length)
	for i := range b {
		if i%8 == 0 && i != 0 {
			b[i] = '-'
		} else {
			mathRand.Seed(time.Now().UnixNano())
			b[i] = letterRunes[mathRand.Intn(len(letterRunes))]
		}
		//b[i] = letterRunes[mathRand.Intn(len(letterRunes))]
	}
	return string(b)
}

func GenerateSocialsToken(length int) string {
	var letterRunes = []rune("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
	b := make([]rune, length)
	for i := range b {
		mathRand.Seed(time.Now().UnixNano())
		if i%4 == 0 && i != 0 {
			b[i] = '-'
			b[i+1] = letterRunes[mathRand.Intn(len(letterRunes))]
		} else {
			b[i] = letterRunes[mathRand.Intn(len(letterRunes))]
		}
		//b[i] = letterRunes[mathRand.Intn(len(letterRunes))]
	}
	return string(b)
}

func ReadFile(fileName string) ([]string, error) {
	file, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer func(file *os.File) {
		err := file.Close()
		if err != nil {
			WrapErrorLog(err.Error())
			return
		}
	}(file)

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}
	return lines, scanner.Err()
}

func ReadAvatar(filename string) ([]byte, error) {
	return os.ReadFile(filename)
}

func InTimeSpan(start, end, check time.Time) bool {
	return check.After(start) && check.Before(end)
}

func IsUpper(s string) bool {
	for _, r := range s {
		if !unicode.IsUpper(r) && unicode.IsLetter(r) {
			return false
		}
	}
	return true
}

func IsLower(s string) bool {
	for _, r := range s {
		if !unicode.IsLower(r) && unicode.IsLetter(r) {
			return false
		}
	}
	return true
}

func Erc20verify(address string) bool {
	erc20 := regexp.MustCompile("^0x[a-fA-F0-9]{40}$")
	return erc20.MatchString(address)
}

func Authorized(handler func(*fiber.Ctx) error) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if len(c.Get("Authorization")) == 0 {
			err := "no token provided"
			return ReportError(c, err, http.StatusUnauthorized)
		}
		if len(c.Get("Content-Type")) != 0 {
			value := c.Get("Content-Type")
			if value != "application/json" {
				//ReportMessage("JSON content is required")
				//	msg := "Content-Type header is not application/json"
				//	return ReportError(c, msg, http.StatusUnsupportedMediaType)
			} else {
				//ReportMessage("JSON content")
			}
		}

		tokenSplit := strings.Fields(c.Get("Authorization"))
		if len(tokenSplit) != 2 {
			return ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
		}

		if tokenSplit[0] == "Bearer" {
			id, secret, err := ValidateKeyToken(tokenSplit[1])
			//data, err := database.ReadValue[sql.NullInt64]("SELECT ban FROM users WHERE idUser= ?", id)
			//if data.Valid {
			//	if data.Int64 == 1 {
			//		utils.ReportErrorSilent(c, "Banned user", http.StatusUnauthorized)
			//		return errors.New("banned user")
			//	}
			//}
			if secret != nil {
				decodeString, err := hex.DecodeString(secret.(string))
				if err != nil {
					return ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
				} else {
					length := len(decodeString)
					if length != 32 {
						return ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
					}
				}
			} else {
				return ReportErrorSilent(c, "Invalid Token", http.StatusUnauthorized)
			}

			if err != nil {
				return ReportError(c, "Invalid token", http.StatusUnauthorized)
			} else {
				c.Request().Header.Set("user_id", fmt.Sprintf("%d", id))
				c.Request().Header.Set("user_secret", secret.(string))
				return handler(c)
			}
		} else {
			return ReportError(c, "Invalid Token", http.StatusUnauthorized)
		}

	}
}

func HashPass(password string) string {
	h := sha256.Sum256([]byte(password))
	str := fmt.Sprintf("%x", h[:])
	return str
}

func GetDaemon() *models.Daemon {
	return &DaemonWallet
}

func RandInt(min int, max int) int {
	return min + mathRand.Intn(max-min)
}

func SendMessage(token string, title string, body string, data map[string]string) {
	opts := []option.ClientOption{option.WithCredentialsFile("xdn-project.json")}
	c := &firebase2.Config{
		ProjectID: "xdn-project",
	}
	firebase, err := firebase2.NewApp(context.Background(), c, opts...)
	if err != nil {
		WrapErrorLog(err.Error())
		return
	}
	mess, err := firebase.Messaging(context.Background())
	if err != nil {
		WrapErrorLog(err.Error())
		return
	}
	_, err = mess.Send(context.Background(), &messaging.Message{
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Data:     data,
			Notification: &messaging.AndroidNotification{
				ChannelID: "xdn1",
				Title:     title,
				Body:      body,
				Icon:      "@drawable/ic_notification",
			},
		},
		Data:  data,
		Token: token, // a token that you received from a client
	})

	if err != nil {
		//WrapErrorLog(err.Error())
		return
	}
}

func RandNum(elements int) int64 {
	nBig, err := rand.Int(rand.Reader, big.NewInt(int64(elements)))
	if err != nil {
		WrapErrorLog(err.Error())
		return int64(elements - 1)
	}
	//r := mathRand.New(mathRand.NewSource(int64(new(maphash.Hash).Sum64())))
	//r = mathRand.New(mathRand.NewSource(int64(new(maphash.Hash).Sum64())))
	return nBig.Int64()
}
