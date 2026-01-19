package controller

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/developerasun/kiwiwi/examples/hello-world/service"
)

type greetingsController struct {
	greetingsService service.IGreetingsService
}
type INewGreetingsController interface {
	RegisterRoute(engine *gin.Engine)
}

func NewGreetingsController(greetingsService service.IGreetingsService) INewGreetingsController {
	return &greetingsController{
		greetingsService: greetingsService,
	}
}

func (c *greetingsController) RegisterRoute(engine *gin.Engine) {
	GreetingsRoutes := engine.Group("/greetings")

	GreetingsRoutes.GET("/", c.Greetings)
}

// Greetings godoc
// @Summary Lorem ipsum dolor sit amet
// @Description Consectetur adipiscing elit. Integer ut maximus
// @Tags api
// @Produce json
// @Success  200 {object}  dto.GreetingsResponse
// @Failure   500  {object}  dto.GreetingsErrorResponse
// @Router /api/greetings [GET]
func (c *greetingsController) Greetings(ctx *gin.Context) {
	// Implementation goes here

	ctx.JSON(http.StatusOK, gin.H{
		"message": "hello world",
	})
}
