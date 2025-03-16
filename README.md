# TicTacToe

A simple tictactoe game that allows to play locally, vs CPU or Online.

## Try it out

[You can play it!](https://neo-ciber94.github.io/godot_tic_tac_toe/)

> This online version do not support online play because it was made using Godot high level
> multiplayer which is not supported on the web.

## Images

![Main Scene](/art/screenshots/screen_1.jpg)
![Game Scene](/art/screenshots/screen_2.jpg)

## Server

After you build the server for either linux or windows you can run it with:

```bash
./tictactoe-server --server
```

It suppots the environment variables:

- `PORT`: the port to run the server (defaults to 7000).
- `MAX_PLAYERS`: the max number of players to allow to connect (defaults to 128).

## Docker

To build a docker image of the server for linux run:

```bash
 docker build -t tictactoe-server .
```

And to run the image

```bash
docker run -dp 7000:7000/udp tictactoe-server
```

> Note that it requires UDP in the port, by default the port used its 7000,
> but can be changed with the `PORT` environment variable.

## Checklist

- [x] Local pvp mode
- [-] CPU pvc mode (minimax implementation is not correct)
- [x] Online pvp mode
- [x] Responsive ui, adapt to tablet, mobile, desktop
- [ ] Deploy dedicated server
- [x] Web build
- [x] Windows build
- [x] Android build
- [x] Add icons
- [x] Add dockerfile 
