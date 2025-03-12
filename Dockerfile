FROM barichello/godot-ci:4.4 as base

WORKDIR /source
COPY . ./
RUN godot --headless --verbose --export-release "Linux Server" "./build/linux/tictactoe-server"

FROM ubuntu:24.04 as runner
WORKDIR /app
COPY --from=base /source/build/linux/ ./
RUN apt update
RUN apt install libfontconfig1 -y
RUN chmod +x ./tictactoe-server

CMD ["./tictactoe-server", "--server"]