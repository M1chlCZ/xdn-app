package errs

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"strings"
)

func ValidateJson(err error) (bool, string) {
	var syntaxError *json.SyntaxError
	var unmarshalTypeError *json.UnmarshalTypeError
	var msg = ""
	var er = false

	if err == nil {
		return false, ""
	}
	switch {
	case errors.As(err, &syntaxError):
		msg = fmt.Sprintf("Request body contains badly-formed JSON (at position %d)", syntaxError.Offset)
		//http.Error(w, msg, http.StatusBadRequest)

	case errors.Is(err, io.ErrUnexpectedEOF):
		msg = fmt.Sprintf("Request body contains badly-formed JSON")
		//http.Error(w, msg, http.StatusBadRequest)

	case errors.As(err, &unmarshalTypeError):
		msg = fmt.Sprintf("Request body contains an invalid value for the %q field (at position %d)", unmarshalTypeError.Field, unmarshalTypeError.Offset)
		//http.Error(w, msg, http.StatusBadRequest)

	case strings.HasPrefix(err.Error(), "json: unknown field "):
		fieldName := strings.TrimPrefix(err.Error(), "json: unknown field ")
		msg = fmt.Sprintf("Request body contains unknown field %s", fieldName)
		//http.Error(w, msg, http.StatusBadRequest)

	case errors.Is(err, io.EOF):
		msg = "Request body must not be empty"
		//http.Error(w, msg, http.StatusBadRequest)

	case err.Error() == "http: request body too large":
		msg = "Request body must not be larger than 1MB"

	default:
		log.Println(err.Error())
		msg = err.Error()
		//http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
	}
	if msg == "" {
		er = false
	} else {
		er = true
	}
	return er, msg

}
