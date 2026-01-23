package dto

import "time"

type GreetingOkResponse struct {
	Message string `json:"message"`
}

type GreetingErrorResponse struct {
	Message   string    `json:"message"`
	Code        int       `json:"code"`
	Timestamp time.Time `json:"timestamp"`
	Path         string    `json:"path"`
}

type GreetingRequest struct {
	Message string `json:"message"`
}

type GreetingResponse struct {
	Message string `json:"message"`
}
