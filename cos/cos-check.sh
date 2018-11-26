#!/bin/bash
# cos-check.sh: What this script does
#
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)
# Created: Mon 26 Nov 2018 02:38:40 PM EST

IMG=rmt-fuser
docker exec ${IMG} cat /blast/blastdb/nr_v5.pal
docker exec ${IMG} find /blast/cache/ -type f
find logs blastdb -ls
docker volume inspect logs blastdb
docker run -v ${PWD}/blastdb:/blast:ro ubuntu cat /blast/blastdb/nr_v5.pal
docker run -v ${PWD}/blastdb:/blast:ro ubuntu find /blast -ls
