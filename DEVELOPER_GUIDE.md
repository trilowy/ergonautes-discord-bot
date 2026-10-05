# Developer guide

## Requirements

- [Zig] 0.16.0
- [watchexec]: optional, for reload on file change
- [direnv] + [Nix flake]: optional, auto-install Zig and watchexec when
  entering project directory


[direnv]:    https://direnv.net
[Nix flake]: https://nixos.org
[watchexec]: https://github.com/watchexec/watchexec
[Zig]:       https://ziglang.org


## Run

- Run server with:
  ```sh
  zig build run
  ```
- Or for reload on file change:
  ```sh
  watchexec --restart --exts zig,md --watch . -- "zig build run"
  ```
- Go to http://127.0.0.1:3000/


## Update dependencies

```sh
zig fetch --save git+https://github.com/karlseguin/http.zig#master
zig fetch --save git+https://github.com/karlseguin/log.zig#master
```


## Architecture

I used Zig because I like it. No other reason. The default language to use for
this kind of bot should be Javascript as all examples and libraries are made to
ease the use of this language. Probably a dumb decision to use Zig but who
cares, we might not be able to code by hand in the future, so let’s do what we
love, and not what must be done to be the most productive.

Also, Zig is fast and performant, I sincerely believe more applications should
be fast, given the incredible compute power we have in our hands.

It is a web server. Before starting, it first registers to Discord API all
commands it handles, so you don’t have to do it yourself when you add a new
command (plus, I might forget how to do it if I must do it by hand the few
times I add a new command).

It has an `/monitoring/health` endpoint so I can check with UptimeRobot if the
bot is down and restart it.

`/interactions` endpoint handle all Discord calls. It has a special
authentication and we are not able to call it with the right auth info as
Discord only gave us the public key. To test it on your computer, just comment
the lines calling `verifyDiscordRequest`, but be careful to not commit that,
otherwise Discord will disable the bot if we do not refuse correctly its
requests testing the auth check.

Documentations are embedded in the binary at compile time. All the magic
happens in `build.zig`. That way, it is easy to deploy, performant and secured,
just a fat binary to drop somewhere and run, no reading of the files on disk,
but you have to re-compile on each change, that’s the tradeoff.

CI/CD is done with Github Actions, and each commit on `main` branch
automatically deploy the new version of the bot a minute later. Other branches
do not launch the CI.

There is a bunch of manual configurations I had to do on the server it is
deployed on, and on Discord, but I won’t detail that here in public. In general,
we need an HTTPS URL with a valid certificate.

Boost a contributor command keeps in SQLite boosted user and the end date of
the boost. Once a day, it goes on all expired boosts in database and remove the
role and the database entry.

To know what role ID a role named `Contrib’` has on a Discord server, it look
it up once with Discord API then store it in memory.
