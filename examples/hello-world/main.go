package main

import (
	"github.com/developerasun/kiwiwi/examples/hello-world/controller"
	"github.com/developerasun/kiwiwi/examples/hello-world/service"
	"github.com/gin-gonic/gin"
	"go.uber.org/dig"
)

func NewGin() *gin.Engine {
	return gin.Default()
}

func main() {
	container := dig.New()

	container.Provide(NewGin)
	container.Provide(service.NewGreetingsService)
	container.Provide(controller.NewGreetingsController)

	container.Invoke(func(r *gin.Engine, gc controller.INewGreetingsController) {
		r.SetTrustedProxies(nil)
		gc.RegisterRoute(r)

		r.Run()
	})
}
