#!/bin/bash
# cos-run.sh: Runs the remote-fuser docker container
#
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)
# Created: Mon 26 Nov 2018 02:37:43 PM EST

set -euo pipefail
shopt -s nullglob

IMG=rmt-fuser

[ -d logs ] || sudo mkdir logs
[ -d blastdb ] || sudo mkdir blastdb
#docker run -d --name rmt-fuser --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor=unconfined \
#    --mount type=bind,src=${PWD}/logs,dst=/var/log \
#    --mount type=bind,src=${PWD}/blastdb,dst=/blast \
#    ${IMG}
docker run -d --name rmt-fuser --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor=unconfined \
    -v ${PWD}/logs:/var/log:rw \
    -v ${PWD}/blastdb:/blast:shared \
    ${IMG}
