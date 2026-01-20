package service

type greetingService struct {}
type IGreetingService interface {}

func NewGreetingService() IGreetingService {
	return &greetingService{ }
}
