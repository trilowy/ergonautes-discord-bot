# Ergonautes Discord Bot

Discord commands to invoque on Ergonautes Discord to get help responses on
frequently asked questions.


## Requirements

- [Zig] 0.15.2
- [watchexec]: optional, for reload on file change
- [direnv] + [Nix flake]: optional, auto-install Zig and watchexec when
  entering project directory


## Run

- Run server with:
  ```sh
  zig build run
  ```
- Or for reload on file change:
  ```sh
  watchexec --restart --exts zig --watch src/ -- "zig build run"
  ```
- Go to http://127.0.0.1:3000/


## Update dependencies

```sh
zig fetch --save git+https://github.com/karlseguin/http.zig#zig-0.15
zig fetch --save git+https://github.com/karlseguin/log.zig#zig-0.15
zig fetch --save=curl git+https://github.com/jiacai2050/zig-curl#0.15
```


[direnv]:    https://direnv.net
[Nix flake]: https://nixos.org
[watchexec]: https://github.com/watchexec/watchexec
[Zig]:       https://ziglang.org
