package database

import (
	"database/sql"
	"fmt"
	_ "github.com/mutecomm/go-sqlcipher"
	"log"
	"net/url"
	"os"
	"strconv"
	"xdn-masternode/models"
	_ "xdn-masternode/models"
	"xdn-masternode/utils"
)

type DBClient struct {
	client *sql.DB
}

var colorReset = "\033[0m"

const dbName string = "./.xcvb"

const dbVersion int = 5

var dbClient DBClient

func InitDB() (*DBClient, error) {
	if dbClient.client != nil {
		return &dbClient, nil
	}
	utils.ReportMessage("DB opening")
	key := url.QueryEscape("mdxy#*WLJRIVRb5e")
	dbname := fmt.Sprintf("%s?_pragma_key=%s&_pragma_cipher_page_size=4096", dbName, key)

	exists := false
	if _, err := os.Stat(dbName); err != nil {
		exists = false
	} else {
		exists = true
	}

	db, err := sql.Open("sqlite3", dbname)

	if err != nil {
		err := os.Remove(dbName)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			return nil, err
		}
		utils.WrapErrorLog(err.Error())
		return nil, err
	}

	if !exists {
		_ = ExecQuery(db, fmt.Sprintf("PRAGMA user_version = %d", dbVersion))
	}
	initTables(db)
	dbClient = DBClient{client: db}
	return &dbClient, nil
}

func initTables(db *sql.DB) {
	createTokenTable := `CREATE TABLE IF NOT EXISTS TOKEN_TABLE (
		"id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,		
		"token" TEXT
	  );`

	createJWTTable := `CREATE TABLE IF NOT EXISTS JWT_TABLE (
		"id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,		
		"JWT" TEXT
	  );`

	createDaemonTable := `CREATE TABLE IF NOT EXISTS DAEMON_TABLE (
		"id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,		
		"wallet_usr" TEXT NOT NULL,
		"wallet_pass" TEXT NOT NULL,
		"wallet_port" INTEGER NOT NULL,
		"folder" TEXT NOT NULL,
		"node_id" INTEGER NOT NULL,
		"coin_id" INTEGER NOT NULL,
		"conf" TEXT NOT NULL,
		"mn_port" INT NOT NULL,
		"ip" TEXT NOT NULL,
		"wallet_passphrase" TEXT
	  );`

	createStakingDeamonTable := `CREATE TABLE IF NOT EXISTS STAKING_DAEMON_TABLE (
		"id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,		
		"wallet_usr" TEXT NOT NULL,
		"wallet_pass" TEXT NOT NULL,
		"wallet_port" INTEGER NOT NULL,
		"coin_id" INTEGER NOT NULL,
		"wallet_passphrase" TEXT
	  );`

	err := ExecQuery(db, createJWTTable)
	err = ExecQuery(db, createTokenTable)
	err = ExecQuery(db, createDaemonTable)
	err = ExecQuery(db, createStakingDeamonTable)

	err, i := GetVersion(db)
	if err != nil {
		return
	}

	switch i {
	case 0, 1:
		err = ExecQuery(db, "ALTER TABLE DAEMON_TABLE ADD COLUMN conf TEXT NOT NULL DEFAULT ('')")
		err = ExecQuery(db, "ALTER TABLE DAEMON_TABLE ADD COLUMN ip TEXT NOT NULL DEFAULT ('')")
		break
	case 2:
		err = ExecQuery(db, "ALTER TABLE DAEMON_TABLE ADD COLUMN mn_port INT NOT NULL DEFAULT 0")
		break
	case 3:
		err = ExecQuery(db, "ALTER TABLE DAEMON_TABLE ADD COLUMN wallet_passphrase TEXT")
	default:
		break
	}

	err = ExecQuery(db, fmt.Sprintf("PRAGMA user_version = %d", dbVersion))

	if err != nil {
		fmt.Printf("Error while creating table token")
		fmt.Println(err.Error())
		return
	}

}

func ExecQuery(db *sql.DB, sql string) error {
	statementJWT, err := db.Prepare(sql) // Prepare SQL Statement
	if err != nil {
		fmt.Println(err.Error())
	}
	_, err = statementJWT.Exec()
	if err != nil {
		fmt.Printf("Error while creating table jwt")
		fmt.Println(err.Error())
		return err
	}
	_ = statementJWT.Close()
	return nil
}

//fn GetQuery(db *sql.DB, sql string, params ...any) (interface{}, error) {
//	rows, err := db.Query(sql, params...)
//	if err != nil {
//		return nil, err
//	}
//	for rows.Next() {
//
//	}
//}

func (db *DBClient) InsertToken(token string) error {
	insertStudentSQL := `INSERT INTO TOKEN_TABLE(token) VALUES (?)`
	statement, err := db.client.Prepare(insertStudentSQL) // Prepare statement.

	if err != nil {
		return err

	}
	_, err = statement.Exec(token)
	if err != nil {
		return err

	}

	return nil
}

func (db *DBClient) getDBJWT() (error, string) {
	insertStudentSQL := `SELECT JWT FROM JWT_TABLE LIMIT 1`
	rows := db.client.QueryRow(insertStudentSQL)
	var JWT string
	err := rows.Scan(&JWT)

	if err != nil {
		return err, ""
		//log.Fatalln(err.Error())
	}

	return nil, JWT
}

func (db *DBClient) getTOKEN() (error, string) {
	insertStudentSQL := `SELECT token FROM TOKEN_TABLE LIMIT 1`
	rows := db.client.QueryRow(insertStudentSQL)
	var JWT string
	err := rows.Scan(&JWT)

	if err != nil {
		return err, ""
		//log.Fatalln(err.Error())
	}

	return nil, JWT
}

func (db *DBClient) InsertJwt(jwt string) error {
	insertStudentSQL := `INSERT INTO JWT_TABLE(JWT) VALUES (?)`
	statement, err := db.client.Prepare(insertStudentSQL)

	if err != nil {
		return err
		//log.Fatalln(err.Error())
	}
	_, err = statement.Exec(jwt)
	if err != nil {
		return err
		//log.Fatalln(err.Error())
	}

	return nil
}

func (db *DBClient) InsertDaemon(walletUsr string, walletPass string, walletPort int64, folder string, nodeID int, coinID int, conf string, ip string, mnPort int) error {
	insertStudentSQL := `INSERT INTO DAEMON_TABLE("wallet_usr", "wallet_pass", "wallet_port", "folder", "node_id", "coin_id", "conf", "ip", "mn_port") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
	statement, err := db.client.Prepare(insertStudentSQL)

	if err != nil {
		return err
		//log.Fatalln(err.Error())
	}
	_, err = statement.Exec(walletUsr, walletPass, walletPort, folder, nodeID, coinID, conf, ip, mnPort)
	if err != nil {
		return err
		//log.Fatalln(err.Error())
	}

	return nil
}

func (db *DBClient) InsertDaemonStaking(walletUsr string, walletPass string, walletPort int64, coinID int, walletPassphrase string) error {
	insertStudentSQL := `INSERT INTO STAKING_DAEMON_TABLE("wallet_usr", "wallet_pass", "wallet_port", "coin_id", "wallet_passphrase") VALUES (?, ?, ?, ?, ?)`
	statement, err := db.client.Prepare(insertStudentSQL)

	if err != nil {
		return err
		//log.Fatalln(err.Error())
	}
	_, err = statement.Exec(walletUsr, walletPass, walletPort, coinID, walletPassphrase)
	if err != nil {
		return err
		//log.Fatalln(err.Error())
	}

	return nil
}

func (db *DBClient) getDAEMON(NodeID int) (*models.Daemon, error) {
	insertStudentSQL := `SELECT * FROM DAEMON_TABLE WHERE node_id = ?`
	rows, _ := db.client.Query(insertStudentSQL, NodeID)

	var dm models.Daemon
	for rows.Next() {
		err := rows.Scan(&dm.ID, &dm.WalletUser, &dm.WalletPass, &dm.WalletPort, &dm.Folder, &dm.NodeID, &dm.CoinID, &dm.Conf, &dm.MnPort, &dm.IP, &dm.PassPhrase)
		if err != nil {
			return &dm, err
			//log.Fatalln(err.Error())
		}
	}

	_ = rows.Close()
	return &dm, nil
}

func (db *DBClient) getDAEMONFolder(Folder string) (*models.Daemon, error) {
	insertStudentSQL := `SELECT * FROM DAEMON_TABLE WHERE folder LIKE ?`
	rows, _ := db.client.Query(insertStudentSQL, "%"+Folder)

	var dm models.Daemon
	for rows.Next() {
		err := rows.Scan(&dm.ID, &dm.WalletUser, &dm.WalletPass, &dm.WalletPort, &dm.Folder, &dm.NodeID, &dm.CoinID, &dm.Conf, &dm.MnPort, &dm.IP, &dm.PassPhrase)
		if err != nil {
			return &dm, err
			//log.Fatalln(err.Error())
		}
	}

	_ = rows.Close()
	return &dm, nil
}

func (db *DBClient) getDAEMONStaking(NodeID int) (*models.Daemon, error) {
	insertStudentSQL := `SELECT * FROM STAKING_DAEMON_TABLE WHERE coin_id = ?`
	rows, _ := db.client.Query(insertStudentSQL, NodeID)

	var dm models.Daemon
	for rows.Next() {
		err := rows.Scan(&dm.ID, &dm.WalletUser, &dm.WalletPass, &dm.WalletPort, &dm.CoinID, &dm.PassPhrase)
		if err != nil {
			return &dm, err
			//log.Fatalln(err.Error())
		}
	}

	_ = rows.Close()
	return &dm, nil
}

func (db *DBClient) getAllDaemons() (*[]models.Daemon, error) {
	insertStudentSQL := `SELECT * FROM DAEMON_TABLE WHERE 1`
	rows, _ := db.client.Query(insertStudentSQL)

	dmArr := make([]models.Daemon, 0)
	for rows.Next() {
		var dm models.Daemon
		err := rows.Scan(&dm.ID, &dm.WalletUser, &dm.WalletPass, &dm.WalletPort, &dm.Folder, &dm.NodeID, &dm.CoinID, &dm.Conf, &dm.MnPort, &dm.IP, &dm.PassPhrase)
		if err != nil {
			log.Printf("err: %v\n", err)
			return &dmArr, err
			//log.Fatalln(err.Error())
		} else {
			dmArr = append(dmArr, dm)
		}
	}

	_ = rows.Close()
	return &dmArr, nil
}

type CoinID struct {
	ID int `db:"coin_id"`
}

func (db *DBClient) getAllCoins() (*[]CoinID, error) {
	insertStudentSQL := `SELECT coin_id FROM DAEMON_TABLE WHERE 1 GROUP BY coin_id`
	rows, _ := db.client.Query(insertStudentSQL)
	dmArr := make([]CoinID, 0)
	for rows.Next() {
		var dm CoinID
		err := rows.Scan(&dm.ID)
		if err != nil {
			log.Printf("err: %v\n", err)
			return &dmArr, err
			//log.Fatalln(err.Error())
		} else {
			dmArr = append(dmArr, dm)
		}
	}

	_ = rows.Close()
	return &dmArr, nil
}

func (db *DBClient) removeDaemon(NodeID int) (sql.Result, error) {
	insertStudentSQL := `DELETE FROM DAEMON_TABLE WHERE node_id = ?`
	rows, _ := db.client.Exec(insertStudentSQL, NodeID)
	return rows, nil
}

func GetVersion(db *sql.DB) (error, int) {
	insertStudentSQL := `PRAGMA user_version`
	rows := db.QueryRow(insertStudentSQL)
	var Ver string
	err := rows.Scan(&Ver)

	if err != nil {
		return err, 0
		//log.Fatalln(err.Error())
	}

	atoi, err := strconv.Atoi(Ver)
	if err != nil {
		return err, 0
	}
	return nil, atoi
}

func (db *DBClient) Ping() {
	fmt.Println(colorReset, "ping")
}

func WriteToken(token string) {
	clientDb, err := InitDB()
	if err != nil {
		fmt.Println(err)
		fmt.Printf("Error creating DB")

	}
	errdb := clientDb.InsertToken(token)
	if errdb != nil {
		fmt.Println(errdb.Error())
		return
	}
	//clientDb.SetupTables()
}

func WriteJWT(JWT string) error {
	clientDb, err := InitDB()
	if err != nil {
		fmt.Println(err)
		fmt.Printf("Error creating DB")
		return err
	}

	errdb := clientDb.InsertJwt(JWT)
	if errdb != nil {
		fmt.Println(errdb.Error())
		return errdb
	}
	return nil
	//clientDb.SetupTables()
}

func GetJWT() (string, error) {
	clientDb, err := InitDB()
	if err != nil {
		fmt.Println(err)
		fmt.Printf("Error creating DB")

	}
	errdb, jwt := clientDb.getDBJWT()
	if errdb != nil {
		fmt.Println(errdb.Error())
		return "", errdb
	}
	return jwt, nil
	//clientDb.SetupTables()
}

func GetEnc() (string, error) {
	clientDb, err := InitDB()
	if err != nil {
		fmt.Println(err)
		fmt.Printf("Error creating DB")

	}
	errdb, jwt := clientDb.getTOKEN()
	if errdb != nil {
		fmt.Println(errdb.Error())
		return "", errdb
	}
	return jwt, nil
	//clientDb.SetupTables()
}

func WriteDaemon(walletUsr string, walletPass string, walletPort int64, folder string, nodeID int, coinID int, conf string, ip string, mnport int) error {
	clientDb, err := InitDB()
	if err != nil {
		fmt.Println(err)
		fmt.Printf("Error creating DB")
		return err
	}

	errdb := clientDb.InsertDaemon(walletUsr, walletPass, walletPort, folder, nodeID, coinID, conf, ip, mnport)
	if errdb != nil {
		fmt.Println(errdb.Error())
		return errdb
	}
	return nil
	//clientDb.SetupTables()
}

func WriteDaemonStaking(walletUsr string, walletPass string, walletPort int64, coinID int, passphrase string) error {
	clientDb, err := InitDB()
	if err != nil {
		fmt.Println(err)
		fmt.Printf("Error creating DB")
		return err
	}

	errdb := clientDb.InsertDaemonStaking(walletUsr, walletPass, walletPort, coinID, passphrase)
	if errdb != nil {
		fmt.Println(errdb.Error())
		return errdb
	}
	return nil
	//clientDb.SetupTables()
}

func GetDaemon(NodeID int) (*models.Daemon, error) {
	clientDb, err := InitDB()
	if err != nil {
		fmt.Println(err)
		fmt.Printf("Error creating DB")

	}

	res, errdb := clientDb.getDAEMON(NodeID)
	if errdb != nil {
		fmt.Println(errdb.Error())
		return &models.Daemon{}, errdb
	}
	return res, nil
	//clientDb.SetupTables()
}

func GetDaemonFolder(Folder string) (*models.Daemon, error) {
	clientDb, err := InitDB()
	if err != nil {
		fmt.Println(err)
		fmt.Printf("Error creating DB")

	}

	res, errdb := clientDb.getDAEMONFolder(Folder)
	if errdb != nil {
		fmt.Println(errdb.Error())
		return &models.Daemon{}, errdb
	}
	return res, nil
	//clientDb.SetupTables()
}

func GetAllDaemons() (*[]models.Daemon, error) {
	clientDb, err := InitDB()
	if err != nil {
		fmt.Println(err)
		fmt.Printf("Error creating DB")

	}

	res, errdb := clientDb.getAllDaemons()
	if errdb != nil {
		fmt.Println(errdb.Error())
		return &[]models.Daemon{}, errdb
	}
	return res, nil
	//clientDb.SetupTables()
}

func GetAllCoins() (*[]CoinID, error) {
	clientDb, err := InitDB()
	if err != nil {
		fmt.Println(err)
		fmt.Printf("Error creating DB")

	}

	res, errdb := clientDb.getAllCoins()
	if errdb != nil {
		fmt.Println(errdb.Error())
		return &[]CoinID{}, errdb
	}
	return res, nil
	//clientDb.SetupTables()
}

func GetDaemonStaking(coinID int) (*models.Daemon, error) {
	clientDb, err := InitDB()
	if err != nil {
		fmt.Println(err)
		fmt.Printf("Error creating DB")

	}

	res, errdb := clientDb.getDAEMONStaking(coinID)
	if errdb != nil {
		fmt.Println(errdb.Error())
		return &models.Daemon{}, errdb
	}
	return res, nil
	//clientDb.SetupTables()
}

func RemoveDaemon(NodeID int) (sql.Result, error) {
	clientDb, err := InitDB()
	if err != nil {
		fmt.Println(err)
		fmt.Printf("Error creating DB")

	}
	res, errdb := clientDb.removeDaemon(NodeID)
	if errdb != nil {
		fmt.Println(errdb.Error())
		return res, errdb
	}
	return res, nil
	//clientDb.SetupTables()
}
