# Buildogram

Shows stats for your CI pipelines.

See build times or test results over time. Like so:

[![Build history](https://buildogram.srv.fmbb.se/bars/fabjan/buildogram)](https://github.com/fabjan/buildogram/actions)

Inspired by the simplicity of the great [CI-BuildStats](https://github.com/dustinmoris/CI-BuildStats).

## Quick start

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

## Deploying

See [buildogram packages](https://github.com/fabjan/buildogram/pkgs/container/buildogram).

You can also use the [Dockerfile](./Dockerfile) to build your own container image. By default it listens on port 3000.

Build with docker (takes a good while):

```sh
docker build -t buildogram .
```

You can then try it out locally with curl:

```shell session
$ docker run --rm -d -p3000:3000 buildogram:latest
9c28f144abc326e71c04b43242267ede278175c248284e42f1f5b8975850dce3

$ curl http://localhost:3000/bars/fabjan/buildogram
<svg xmlns="http://www.w3.org/2000/svg" width="400" height="100" > <rect x="0" y="74" width="5" height="26" fill="red" onclick="window.open('https://github.com/fabjan/buildogram/actions/runs/3507479383', '_blank')" />
<rect x="6" y="18" width="5" height="82" fill="red" onclick="window.open('https://github.com/fabjan/buildogram/actions/runs/3508779840', '_blank')" />
<rect x="12" y="10" width="5" height="90" fill="green" onclick="window.open('https://github.com/fabjan/buildogram/actions/runs/3508826797', '_blank')" />
<rect x="18" y="17" width="5" height="83" fill="green" onclick="window.open('https://github.com/fabjan/buildogram/actions/runs/3509164502', '_blank')" />
<rect x="24" y="25" width="5" height="75" fill="green" onclick="window.open('https://github.com/fabjan/buildogram/actions/runs/3558553196', '_blank')" /> <g><line  x1="0" y1="0" x2="0" y2="100" stroke="black"/><line  x1="0" y1="10" x2="400" y2="10" stroke="black" stroke-dasharray="5,5"/><text x="1" y="12" font-size="12" font-family="sans-serif" fill="black">57s</text><text x="1" y="100" font-size="12" font-family="sans-serif" fill="black">0s</text></g> </svg>
```
