package utils

import (
    "bufio"
    "fmt"
    "io"
    _ "io/ioutil"
    "log"
    "math"
    mathRand "math/rand"
    "net/http"
    "os"
    "runtime"
    "strings"
    "time"

    "github.com/bitly/go-simplejson"
    "github.com/joho/godotenv"
)

const (
    VERSION          = "0.0.5.5"
    STATUS    string = "status"
    OK        string = "OK"
    FAIL      string = "FAIL"
    ERROR     string = "hasError"
    ServerUrl string = "51.195.168.17"
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

func ReportError(w http.ResponseWriter, err string, statusCode int) {
    json := simplejson.New()
    json.Set("errorMessage", err)
    json.Set(STATUS, FAIL)
    json.Set(ERROR, true)

    payload, e := json.MarshalJSON()
    if e != nil {
        log.Println(err)
    }
    if !strings.Contains(err, "tx_id_UNIQUE") || strings.Contains(err, "Invalid Token, id User") {
        logToFile("")
        logToFile("//// - HTTP ERROR - ////")
        logToFile("HTTP call failed : " + err + "  Status code: " + fmt.Sprintf("%d", statusCode))
        logToFile("////==========////")
        logToFile("")
    }

    w.WriteHeader(statusCode)
    w.Header().Set("Content-Type", "application/json")
    _, _ = w.Write(payload)
    // json.NewEncoder(w).Encode(err)
    return
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

    w.WriteHeader(statusCode)
    w.Header().Set("Content-Type", "application/json")
    _, _ = w.Write(payload)
    // json.NewEncoder(w).Encode(err)
    return
}

func ReportErrorSilent(w http.ResponseWriter, err string, statusCode int) {
    json := simplejson.New()
    json.Set("errorMessage", err)
    json.Set(STATUS, FAIL)
    json.Set(ERROR, true)

    payload, e := json.MarshalJSON()
    if e != nil {
        log.Println(err)
    }

    w.WriteHeader(statusCode)
    w.Header().Set("Content-Type", "application/json")
    _, _ = w.Write(payload)
    // json.NewEncoder(w).Encode(err)
    return
}

func logToFile(message string) {
    f, err := os.OpenFile("sendApi.log", os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
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
    logToFile(message)
    logToFile("")
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

func GenerateInviteCode(length int) string {
    var letterRunes = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$&")
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

//func DecryptRequest(r *http.Request, url string) ([]byte, string, error) {
//	var urlNode string
//	cryptKey, errCrypt := database.ReadRow[string]("SELECT encryptKey FROM masternodes WHERE url = ?", urlNode, url)
//	if errCrypt != nil {
//		WrapErrorLog(errCrypt.Error())
//		return nil, "", errCrypt
//	}
//
//	body, err := io.ReadAll(r.Body)
//	bodyString := string(body)
//
//	message, err := DecryptMessage([]byte(cryptKey), bodyString)
//	if err != nil {
//		WrapErrorLog(err.Error())
//		return nil, "", err
//	}
//
//	return []byte(message), cryptKey, nil
//}
