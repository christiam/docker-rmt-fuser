#!/bin/bash
# cos-build.sh: What this script does
#
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)
# Created: Mon 26 Nov 2018 02:36:57 PM EST

set -euo pipefail
shopt -s nullglob

IMG=rmt-fuser

cd /var
curl -s ftp://ftp.ncbi.nlm.nih.gov/blast/executables/remote-fuser/remote-fuser.tgz | sudo tar -zxf -
sudo head -20 ./config-gcs-access.sh > tmp.sh
sudo chmod +x tmp.sh
sudo bash -x ./tmp.sh
sudo rm -f config-gcs-access.sh README.txt tmp.sh
cd -
docker build -t ${IMG} .
