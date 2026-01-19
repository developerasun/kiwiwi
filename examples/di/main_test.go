package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/go-openapi/testify/v2/require"
	"go.uber.org/dig"
)

func Test_DependencyInjection(t *testing.T) {
	container := dig.New()

	NewDependency := func() string {
		return "Hello, World!"
	}
	NewPrinter := func(msg string) string {
		return fmt.Sprintf("[info] %s", msg)
	}

	t.Run("Should provider a simple depdency", func(t *testing.T) {
		t.Skip()
		if err := container.Provide(NewDependency); err != nil {
			t.Fatal(err)
		}

		iErr := container.Invoke(NewPrinter)
		require.NoError(t, iErr)
	})

	t.Run("Should provide a service to controller", func(t *testing.T) {
		type Service struct{}
		type Controller struct{}

		NewGin := func() *gin.Engine {
			gin.SetMode(gin.TestMode)
			return gin.Default()
		}
		NewService := func() *Service {
			return &Service{}
		}
		NewController := func(service *Service, engine *gin.Engine) {
			engine.GET("/", func(c *gin.Context) {
				c.String(200, "Hello, World!")
			})
			fmt.Println("serviced provided and controller safely invoked.")
			// go engine.Run(":8080")
			// require.NoError(t, err)
		}

		srv := NewGin()
		gErr := container.Provide(func() *gin.Engine {
			return srv
		})
		require.NoError(t, gErr)
		sErr := container.Provide(NewService)
		require.NoError(t, sErr)

		iErr := container.Invoke(NewController)
		require.NoError(t, iErr)

		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/", nil)
		srv.ServeHTTP(w, req)

		require.True(t, w.Code == http.StatusOK)
		t.Log("body: ", w.Body.String())
	})
}
