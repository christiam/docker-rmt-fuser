# Setting up remote-fuser in Docker

## Objective
To encapsulate the `remote-fuser` application in a docker container so that it
can provide a FUSE containing BLAST databases to other containers.

### Background
`remote-fuser` is a command line application from the [NCBI SRA toolkit][1] which
facilitates setting up FUSE on the local host. The BLAST database files 
reside in the `gs://blast-db` GCS bucket.

## Instructions

*N.B.*: these instructions assume Ubuntu Linux

* `make run` creates and runs a docker container with remote-fuser configured to get 
 BLAST databases from GCS, however, these cannot be seen outside the container
* `make check` runs a few commands to demonstrate that.
* `make run_shared` same as `make run` but it sets the bind-propagation to the value of 
the `BP` environment variable (`shared` by default).
* `make stop` stops and removes the most recently started remote-fuser docker container.
* `make clean` removes all binaries and locally downloaded scripts
* `make fuse.xml` retrieves the `remote-fuser` configuration file
 
[1]: https://github.com/ncbi/sra-tools
