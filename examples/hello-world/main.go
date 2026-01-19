package main

import (
	"github.com/developerasun/kiwiwi/examples/hello-world/controller"
	"github.com/developerasun/kiwiwi/examples/hello-world/service"
	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()
	r.SetTrustedProxies(nil)

	c := controller.NewGreetingsController(service.NewGreetingsService())
	c.RegisterRoute(r)

	r.Run()
}
