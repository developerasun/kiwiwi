package service

type greetingsService struct {}
type IGreetingsService interface {}

func NewGreetingsService() IGreetingsService {
	return &greetingsService{ }
}
