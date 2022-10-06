package database

import (
	"fmt"
	"github.com/jmoiron/sqlx"
	"log"
	"xdn-voting/utils"
)

//type LS[type T] struct {
//value T
//next  *LinkedList[T]
//}

type DB struct {
	*sqlx.DB
}

var Database *DB

func New() {
	db, errDB := sqlx.Open("mysql", utils.GetENV("DB_CONN"))
	if errDB != nil {
		log.Fatal(errDB)
	}
	// Configure any package-level settings
	Database = &DB{db}
}

func ReadSql(SQL string, params ...interface{}) (*sqlx.Rows, error) {
	results, errRow := Database.Queryx(SQL, params...)
	if errRow != nil {
		fmt.Println(errRow.Error())
		return nil, errRow
	} else {
		return results, nil
	}
}

func ReadValue[T any](SQL string, params ...interface{}) (T, error) {
	var an T
	err := Database.QueryRow(SQL, params...).Scan(&an)
	if err != nil {
		i := getZero[T]()
		return i, err
	} else {
		return an, nil
	}
}

func ReadValueEmpty[T any](SQL string, params ...interface{}) T {
	var an T
	err := Database.QueryRow(SQL, params...).Scan(&an)
	if err != nil {
		i := getZero[T]()
		return i
	} else {
		return an
	}
}

func ReadStruct[T any](SQL string, params ...interface{}) (T, error) {
	rows, err := Database.Queryx(SQL, params...)
	if err != nil {
		i := getZero[T]()
		_ = rows.Close()
		return i, err
	} else {
		var s T
		s, err := ParseStruct[T](rows)
		if err != nil {
			_ = rows.Close()
			return getZero[T](), err
		}
		_ = rows.Close()
		return s, nil
	}
}

func ReadStructEmpty[T any](SQL string, params ...interface{}) T {
	rows, err := Database.Queryx(SQL, params...)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		i := getZero[T]()
		_ = rows.Close()
		return i
	} else {
		var s T
		s, err := ParseStruct[T](rows)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			_ = rows.Close()
			return getZero[T]()
		}
		_ = rows.Close()
		return s
	}
}

func ReadArrayStruct[T any](SQL string, params ...interface{}) ([]T, error) {
	rows, err := ReadSql(SQL, params...)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		i := getZeroArray[T]()
		return i, err
	} else {
		var s []T
		s = ParseArrayStruct[T](rows)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			_ = rows.Close()
			return getZeroArray[T](), err
		}
		_ = rows.Close()
		return s, nil
	}
}

func ReadArray[T any](SQL string, params ...interface{}) ([]T, error) {
	i := make([]T, 0)
	rows, err := Database.Queryx(SQL, params...)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return i, err
	} else {
		for rows.Next() {
			var s T
			if err := rows.StructScan(&s); err != nil {
				utils.WrapErrorLog(err.Error())
				return i, err
			} else {
				i = append(i, s)
			}
		}
		_ = rows.Close()
		return i, nil
	}
}

func ParseArrayStruct[T any](rows *sqlx.Rows) []T {
	var stk T
	stakeArray := make([]T, 0)

	count := 0
	for rows.Next() {
		count++
		if err := rows.StructScan(&stk); err != nil {
			utils.WrapErrorLog(err.Error())
			log.Printf("err: %v\n", err)
			return nil
		} else {
			stakeArray = append(stakeArray, stk)
		}
	}
	_ = rows.Close()
	return stakeArray
}

func ParseStruct[T any](rows *sqlx.Rows) (T, error) {
	var stk T
	for rows.Next() {
		if err := rows.StructScan(&stk); err != nil {
			_ = rows.Close()
			log.Printf("err: %v\n", err)
			return stk, err
		}
	}
	_ = rows.Close()
	return stk, nil
}

func getZero[T any]() T {
	var result T
	return result
}

func getZeroArray[T any]() []T {
	var result []T
	return result
}

func InsertSQl(SQL string, params ...interface{}) (int64, error) {
	//db, err := sqlx.Open("mysql", utils.GetENV("DB_CONN"))
	//if err != nil {
	//	return 0, err
	//}
	query, errStmt := Database.Exec(SQL, params...)
	//res, errStmt := query.Exec(params...)
	if errStmt != nil {
		//fmt.Printf("Can't Insert shit")
		return 0, errStmt
	}
	id, errLastID := query.LastInsertId()
	if errLastID != nil {
		return 0, errLastID
	}
	return id, nil
}

func GetSQL(SQL string, inter *struct{}, params ...interface{}) error {
	db, err := sqlx.Open("mysql", utils.GetENV("DB_CONN"))

	defer func(db *sqlx.DB) {
		_ = db.Close()
	}(db)

	err = db.Get(&inter, SQL, params...)
	if err != nil {
		return err
	}
	return nil
}
