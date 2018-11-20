#!/bin/bash -x
sudo mkdir -p ${PWD}/foo ${PWD}/bar
ls -la ${PWD}/foo ${PWD}/bar
sudo mount --bind --make-shared ${PWD}/foo ${PWD}/bar
ls -la ${PWD}/foo ${PWD}/bar
docker run --name testbp -d --privileged \
	--mount type=bind,src=${PWD}/foo,dst=/app,bind-propagation=shared \
	ubuntu sleep infinity
