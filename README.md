# Setting up remote-fuser to serve BLASTDBs

## Objective
To encapsulate the `remote-fuser` application so that it can provide a FUSE
containing BLAST databases.

## Instructions

`make run` creates and runs a docker container with remote-fuser configured to get 
BLAST databases from GCS, however, these cannot be seen outside the container

`make check` demonstrates that.

`make stop` stops and removes the most recently started remote-fuser docker container.

## Future work
