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
	d := make(chan *sqlx.Rows, 1)
	e := make(chan error, 1)
	go func(data chan *sqlx.Rows, errChan chan error) {
		results, errRow := Database.Queryx(SQL, params...)
		if errRow != nil {
			fmt.Println(errRow.Error())
			errChan <- errRow
			//return nil, errRow
		} else {
			data <- results
			//return results, nil
		}
	}(d, e)
	select {
	case data := <-d:
		close(d)
		close(e)
		return data, nil
	case err := <-e:
		close(d)
		close(e)
		return nil, err
	}
}

func ReadValue[T any](SQL string, params ...interface{}) (T, error) {
	d := make(chan T, 1)
	e := make(chan error, 1)
	go func(data chan T, err chan error) {
		var an T
		errDB := Database.QueryRow(SQL, params...).Scan(&an)
		if errDB != nil {
			//i := getZero[T]()
			err <- errDB
			//data <- i
			//return i, err
		} else {
			data <- an
			//err <- nil
			//return an, nil
		}
	}(d, e)
	select {
	case data := <-d:
		close(d)
		close(e)
		return data, nil
	case err := <-e:
		close(d)
		close(e)
		return getZero[T](), err
	}
}

func ReadValueEmpty[T any](SQL string, params ...interface{}) T {
	d := make(chan T, 1)
	e := make(chan error, 1)
	go func(data chan T, err chan error) {
		var an T
		errDB := Database.QueryRow(SQL, params...).Scan(&an)
		if errDB != nil {
			//i := getZero[T]()
			err <- errDB
			//data <- i
			//return i, err
		} else {
			data <- an
			//err <- nil
			//return an, nil
		}
	}(d, e)
	select {
	case data := <-d:
		close(d)
		close(e)
		return data
	case _ = <-e:
		close(d)
		close(e)
		return getZero[T]()
	}
}

func ReadStruct[T any](SQL string, params ...interface{}) (T, error) {
	d := make(chan T, 1)
	e := make(chan error, 1)
	go func(data chan T, err chan error) {
		rows, errDB := Database.Queryx(SQL, params...)
		if errDB != nil {
			err <- errDB
			//data <- i
			//return i, err
		} else {
			var s T
			s, errDB := ParseStruct[T](rows)
			if errDB != nil {
				_ = rows.Close()
				//return getZero[T](), err
				err <- errDB
			}
			_ = rows.Close()
			data <- s
			//err <- nil
			//return s, nil
		}
	}(d, e)
	select {
	case data := <-d:
		close(d)
		close(e)
		return data, nil
	case err := <-e:
		close(d)
		close(e)
		return getZero[T](), err
	}
}

func ReadStructEmpty[T any](SQL string, params ...interface{}) T {
	d := make(chan T, 1)
	go func(data chan T) {
		rows, err := Database.Queryx(SQL, params...)
		if err != nil {
			utils.WrapErrorLog(err.Error())
			i := getZero[T]()
			data <- i
			//return i
		} else {
			var s T
			s, err := ParseStruct[T](rows)
			if err != nil {
				utils.WrapErrorLog(err.Error())
				_ = rows.Close()
				data <- getZero[T]()
				//return getZero[T]()
			}
			_ = rows.Close()
			data <- s
		}
	}(d)
	select {
	case data := <-d:
		close(d)
		return data
	}
}

func ReadArrayStruct[T any](SQL string, params ...interface{}) ([]T, error) {
	d := make(chan []T, 1)
	e := make(chan error, 1)
	go func(data chan []T, err chan error) {
		rows, errDB := ReadSql(SQL, params...)
		if errDB != nil {
			//utils.WrapErrorLog(err.Error())
			//i := getZeroArray[T]()
			//data <- i
			err <- errDB
		} else {
			var s []T
			s = ParseArrayStruct[T](rows)
			if errDB != nil {
				_ = rows.Close()
				err <- errDB
			}
			_ = rows.Close()
			data <- s
		}
	}(d, e)
	select {
	case data := <-d:
		close(d)
		close(e)
		return data, nil
	case err := <-e:
		close(d)
		close(e)
		return getZeroArray[T](), err
	}
}

func ReadArray[T any](SQL string, params ...interface{}) ([]T, error) {
	d := make(chan []T, 1)
	e := make(chan error, 1)
	go func(data chan []T, err chan error) {
		i := make([]T, 0)
		rows, errDB := Database.Queryx(SQL, params...)
		if errDB != nil {
			utils.WrapErrorLog(errDB.Error())
			//data <- i
			err <- errDB
		} else {
			for rows.Next() {
				var s T
				if errDB := rows.StructScan(&s); errDB != nil {
					//data <- i
					err <- errDB
				} else {
					i = append(i, s)
				}
			}
			_ = rows.Close()
			data <- i
		}
	}(d, e)
	select {
	case data := <-d:
		close(d)
		close(e)
		return data, nil
	case err := <-e:
		close(d)
		close(e)
		return getZeroArray[T](), err
	}
}

func ParseArrayStruct[T any](rows *sqlx.Rows) []T {
	d := make(chan []T, 1)
	e := make(chan error, 1)
	go func(data chan []T, errChan chan error) {
		var stk T
		stakeArray := make([]T, 0)
		count := 0
		for rows.Next() {
			count++
			if err := rows.StructScan(&stk); err != nil {
				utils.WrapErrorLog(err.Error())
				log.Printf("err: %v\n", err)
				errChan <- err
				//return nil
			} else {
				stakeArray = append(stakeArray, stk)
			}
		}
		_ = rows.Close()
		data <- stakeArray
		//return stakeArray
	}(d, e)
	select {
	case data := <-d:
		close(d)
		close(e)
		return data
	case _ = <-e:
		close(d)
		close(e)
		return nil
	}
}

func ParseStruct[T any](rows *sqlx.Rows) (T, error) {
	d := make(chan T, 1)
	e := make(chan error, 1)
	go func(data chan T, errChan chan error) {
		var stk T
		for rows.Next() {
			if err := rows.StructScan(&stk); err != nil {
				_ = rows.Close()
				log.Printf("err: %v\n", err)
				errChan <- err
			}
		}
		_ = rows.Close()
		data <- stk
	}(d, e)
	select {
	case data := <-d:
		close(d)
		close(e)
		return data, nil
	case err := <-e:
		close(d)
		close(e)
		return getZero[T](), err
	}
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
		utils.WrapErrorLog(errStmt.Error())
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
