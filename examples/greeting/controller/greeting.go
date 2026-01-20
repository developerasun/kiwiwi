package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"

	"github.com/developerasun/kiwiwi/examples/greeting/service"
)

type greetingController struct {
  greetingService service.IGreetingService
}
type INewGreetingController interface {
  RegisterRoute(engine *gin.Engine)
}

func NewGreetingController(greetingService service.IGreetingService) INewGreetingController {
	return &greetingController{
	   greetingService: greetingService,
	}
}

func (c *greetingController) RegisterRoute(engine *gin.Engine) {
  GreetingRoutes := engine.Group("/api/greeting")

  GreetingRoutes.GET("/", c.Greeting)
}

// Greeting godoc
// @Summary Lorem ipsum dolor sit amet
// @Description Consectetur adipiscing elit. Integer ut maximus
// @Tags api
// @Produce json
// @Success  200 {object}  map[string]interface{}
// @Failure   500  {object}  map[string]interface{}
// @Router /api/greeting [GET]
func (c *greetingController) Greeting(ctx *gin.Context) {
	// Implementation goes here

	ctx.JSON(http.StatusOK, gin.H{
		"message": "ok",
	})
}
