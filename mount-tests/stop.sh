#!/bin/bash -x
docker logs testbp
docker rm -f testbp
sudo umount ${PWD}/bar
sudo rm -fr ${PWD}/foo ${PWD}/bar
