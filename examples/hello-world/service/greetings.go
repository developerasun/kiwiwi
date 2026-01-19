package service

type greetingsService struct{}
type IGreetingsService interface {
	Nationality() string
}

func NewGreetingsService() IGreetingsService {
	return &greetingsService{}
}

func (gs *greetingsService) Nationality() string {
	return "US"
}
