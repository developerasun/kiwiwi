package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"

	"github.com/developerasun/kiwiwi/examples/greeting/service"
	"github.com/developerasun/kiwiwi/examples/greeting/dto"
)

type greetingController struct {
  greetingService service.IGreetingService
}
type INewGreetingController interface {
  RegisterRoute(rg *gin.RouterGroup)
}

func NewGreetingController(greetingService service.IGreetingService) INewGreetingController {
	return &greetingController{
	   greetingService: greetingService,
	}
}

func (c *greetingController) RegisterRoute(rg *gin.RouterGroup) {
  greetingRoutes := rg.Group("/greeting")

  greetingRoutes.GET("/", c.Greeting)
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

	ctx.JSON(http.StatusOK, dto.GreetingResponse{
		Message: "ok",
	})
}

// Greeting godoc
// @Summary Lorem ipsum dolor sit amet
// @Description Consectetur adipiscing elit. Integer ut maximus
// @Tags api
// @Produce json
// @Success  200 {object}  dto.GreetingResponse
// @Failure   500  {object}  dto.GreetingErrorResponse
// @Router /api/greeting [GET]
func (c *greetingController) Greeting_UpdateMe19822(ctx *gin.Context) {
	// Implementation goes here

	ctx.JSON(http.StatusOK, dto.GreetingResponse{
		Message: "ok",
	})
}
