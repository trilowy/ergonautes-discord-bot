# Ergonautes Discord Bot

Discord commands to invoque on Ergonautes Discord to get help responses on
frequently asked questions.


## Documentation

It auto-discovers documentation files at compile-time in `doc/` directory and
embed them in the server binary.

The name of the file is the name of the parameter in the Discord slash command,
keep it under 32 char.

The file should be in Markdown (`.md` extension).

Do not limit lines length in these files as Discord will render these line
returns.


## Requirements

- [Zig] 0.16.0
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
zig fetch --save git+https://github.com/karlseguin/http.zig#master
zig fetch --save git+https://github.com/karlseguin/log.zig#master
```


[direnv]:    https://direnv.net
[Nix flake]: https://nixos.org
[watchexec]: https://github.com/watchexec/watchexec
[Zig]:       https://ziglang.org
