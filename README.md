![GitHub last commit](https://img.shields.io/github/last-commit/developerasun/kiwiwi)
![Static Badge](https://img.shields.io/badge/Is_Jake_Working_On_This_Now-Yes-green)

# kiwiwi

The missing scaffold tool for [`Gin`](https://github.com/gin-gonic/gin) web framework.

## Table of contents

- [getting started](#getting-started)
- [setup](#setup)
  - [package manager](#package-manager)
  - [language server](#language-server)
- [commands](#commands)
- [reference](#reference)

## getting started

build binary.

```sh
zig build
```

elevate a privilege.

```sh
cd zig-out/bin
sudo chmod +x ./kiwiwi
```

run the binary.

```sh
./kiwiwi Cat

project kiwiwi with version 0.1
firstArg: Cat
template: package controller

import (
	"github.com/gin-gonic/gin"
)

@kiwiwi should escape double `{ }` for zig formatting
func CatController(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, gin.H{
		Message: "ok",
	})
}
```

In a local testing, 

run `./dev.run.sh --co Cat`

```sh
▶ Kiwiwi app start
▶ Build and run with forwarded arguments
project kiwiwi with version 0.1
firstArg: Cat
template: package controller

import (
	"github.com/gin-gonic/gin"
)

@kiwiwi should escape double `{ }` for zig formatting
func CatController(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, gin.H{
		Message: "ok",
	})
}
```

## setup

### package manager

install `asdf` package manager first. 

```sh
# download asdf binary from github release page
# https://github.com/asdf-vm/asdf/releases
```

and then install `zig` and `zls` with the [`asdf-zig`](https://github.com/asdf-community/asdf-zig) community plugin.
editor auto complete will not with without the language server `zls`.

```sh
asdf install zig 0.15.1
assdf set zig 0.15.1
asdf reshim zig
```

check version. zig and zls version should be matched.

```sh
zig version
zls version
```

### language server

Depending on your editor, language server `zls` will be set slightly different. On zed, install `zig` extension first. 
And create `.zed` directory with `settings.json` file.

run `asdf which zls` command and copy the path for target language server.

```json
// .zed/settings.json
{
  "lsp": {
    "zls": {
      "binary": {
        "path": "asdf which zls result here",
        "arguments": []
      }
    }
  },
  "languages": {
    "Zig": {
      "language_servers": ["zls"],
      "format_on_save": "on"
    }
  }
}
```

On VS Code, install official `Zig Language` extension. and then create `.vscode` directory with `settings.json` file.
run `asdf which zig`, `asdf which zls` commands and copy the path for target language server.

```json
// .vscode/settings.json
{
  "zig.zls.enabled": "on",
  "zig.path": "asdf which zig result here",
  "zig.zls.path": "asdf which zls result here",
  "zig.zls.enableSnippets": true
}
```

## commands

a bit of helper commands to build and test zig application.

```sh
# build and run whole application
  ./dev.run.sh         
  
  # build and run one target file
  ./dev.run.sh --build-one [filename] 
  
  # run test suites
  ./dev.run.sh --test
```

## reference

- [zig.guide: Formatting specifiers](https://zig.guide/standard-library/formatting-specifiers)
- [zig.guide: Running tests](https://zig.guide/getting-started/running-tests)
- [github: gin-scaffold](https://github.com/dcu/gin-scaffold)
- [zed docs: language support: Go](https://zed.dev/docs/languages/go#go)

nestjs/cli

```sh
pnpm nest --help

Usage: nest <command> [options]

Options:
  -v, --version                                   Output the current version.
  -h, --help                                      Output usage information.

Commands:
  new|n [options] [name]                          Generate Nest application.
  build [options] [app]                           Build Nest application.
  start [options] [app]                           Run Nest application.
  info|i                                          Display Nest project details.
  add [options] <library>                         Adds support for an external library to your project.
  generate|g [options] <schematic> [name] [path]  Generate a Nest element.
    Schematics available on @nestjs/schematics collection:
      ┌───────────────┬─────────────┬──────────────────────────────────────────────┐
      │ name          │ alias       │ description                                  │
      │ application   │ application │ Generate a new application workspace         │
      │ class         │ cl          │ Generate a new class                         │
      │ configuration │ config      │ Generate a CLI configuration file            │
      │ controller    │ co          │ Generate a controller declaration            │
      │ decorator     │ d           │ Generate a custom decorator                  │
      │ filter        │ f           │ Generate a filter declaration                │
      │ gateway       │ ga          │ Generate a gateway declaration               │
      │ guard         │ gu          │ Generate a guard declaration                 │
      │ interceptor   │ itc         │ Generate an interceptor declaration          │
      │ interface     │ itf         │ Generate an interface                        │
      │ library       │ lib         │ Generate a new library within a monorepo     │
      │ middleware    │ mi          │ Generate a middleware declaration            │
      │ module        │ mo          │ Generate a module declaration                │
      │ pipe          │ pi          │ Generate a pipe declaration                  │
      │ provider      │ pr          │ Generate a provider declaration              │
      │ resolver      │ r           │ Generate a GraphQL resolver declaration      │
      │ resource      │ res         │ Generate a new CRUD resource                 │
      │ service       │ s           │ Generate a service declaration               │
      │ sub-app       │ app         │ Generate a new application within a monorepo │
      └───────────────┴─────────────┴──────────────────────────────────────────────┘
```
