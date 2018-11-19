#!/bin/bash
# tbp.sh: Test the various bind propagation parameters
#
# Author: Christiam Camacho (christiam.camacho@gmail.com)
# Created: Mon Nov 19 06:36:20 2018

OPTS=(shared slave private rshared rslave rprivate)
for o in "${OPTS[@]}"; do
    echo $o
    make stop run_shared check BP=$o
done

