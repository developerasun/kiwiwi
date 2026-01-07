# kiwiwi

## setup

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

## commands

run application.

```sh
# run a single file
zig run src/main.zig

# run all
zig build run
```

run test.

```sh
zig build test --verbose
```
