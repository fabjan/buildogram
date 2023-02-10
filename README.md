# Buildogram

[![latest release](https://img.shields.io/github/v/release/fabjan/buildogram?label=latest%20release&logo=github&sort=semver)](https://github.com/fabjan/buildogram/releases)

Shows stats for your CI pipelines.

See build times or test results over time. Like so:

[![Build history](https://buildogram.srv.fmbb.se/bars/fabjan/buildogram?cb=1)](https://github.com/fabjan/buildogram/actions)

Inspired by the simplicity of the great [CI-BuildStats](https://github.com/dustinmoris/CI-BuildStats).

## Quick start

```sh
gleam test  # Run the tests
gleam run   # Run the project
gleam shell # Run an Erlang shell
```

## Deploying

For each release, a container image is pushed to [buildogram packages](https://github.com/fabjan/buildogram/pkgs/container/buildogram).

You can run it locally with Docker:

```shell session
$ docker run --rm -p3000:3000 -it ghcr.io/fabjan/buildogram:latest
[main] 🛠 HTTP cache item limit: 100
[main] ✨ Buildogram is now listening on :3000
[main] Use Ctrl+C, Ctrl+C to stop.
```

Try fetching the diagram from another terminal:

```shell session
$ curl http://localhost:3000/bars/fabjan/buildogram
<svg xmlns="http://www.w3.org/2000/svg" width="400" height="100" > <rect x="0" y="74" width="5" height="26" fill="red" onclick="window.open('https://github.com/fabjan/buildogram/actions/runs/3507479383', '_blank')" />
<rect x="6" y="18" width="5" height="82" fill="red" onclick="window.open('https://github.com/fabjan/buildogram/actions/runs/3508779840', '_blank')" />
<rect x="12" y="10" width="5" height="90" fill="green" onclick="window.open('https://github.com/fabjan/buildogram/actions/runs/3508826797', '_blank')" />
<rect x="18" y="17" width="5" height="83" fill="green" onclick="window.open('https://github.com/fabjan/buildogram/actions/runs/3509164502', '_blank')" />
<rect x="24" y="25" width="5" height="75" fill="green" onclick="window.open('https://github.com/fabjan/buildogram/actions/runs/3558553196', '_blank')" /> <g><line  x1="0" y1="0" x2="0" y2="100" stroke="black"/><line  x1="0" y1="10" x2="400" y2="10" stroke="black" stroke-dasharray="5,5"/><text x="1" y="12" font-size="12" font-family="sans-serif" fill="black">57s</text><text x="1" y="100" font-size="12" font-family="sans-serif" fill="black">0s</text></g> </svg>
```

## Building

You can use the [Dockerfile](./Dockerfile) to build your own container image. By default it listens on port 3000.

Build with docker (takes a good while):

```shell session
$ docker build -t buildogram -t buildogram:dev .
$ docker run --rm -p3000:3000 -it buildogram:dev
```

You can then try it out locally with curl as described above.
