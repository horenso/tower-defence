#!/bin/bash

zig build

while true; do

    inotifywait -e modify,create,delete -r ./lib -r ./res && \
    zig build && pgrep game | xargs kill -USR1

done
