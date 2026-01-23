package main

import (
	"log"

	"github.com/developerasun/kiwiwi/examples/greeting/controller"
	"github.com/developerasun/kiwiwi/examples/greeting/service"
	"github.com/gin-gonic/gin"
	"go.uber.org/dig"
	// docs "github.com/developerasun/kiwiwi/examples/greeting/docs"
	// swaggerfiles "github.com/swaggo/files"
	// ginSwagger "github.com/swaggo/gin-swagger"
)

func NewGin() *gin.Engine {
	return gin.Default()
}

// @title kiwiwi template API
// @version 0.1
// @description kiwiwi template API documentation
// @BasePath /
func main() {
	container := dig.New()
	container.Provide(NewGin)

	// inject more depedencies here
	container.Provide(service.NewGreetingService)
	container.Provide(controller.NewGreetingController)

	container.Invoke(func(r *gin.Engine, gc controller.INewGreetingController) {
		r.SetTrustedProxies(nil)
		rg := r.Group("/api")
		// docs.SwaggerInfo.BasePath = ""
		// r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerfiles.Handler))

		gc.RegisterRoute(rg)
		log.Fatal(r.Run())
	})
}
