#!/bin/bash -x
find ${PWD}/foo ${PWD}/bar
docker exec testbp ls -l /app
docker exec testbp touch /app/empty-from-inside-container
find ${PWD}/foo ${PWD}/bar
