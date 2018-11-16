# Makefile for setting up remote-fuser in Docker
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)

SHELL=/bin/bash
.PHONY: build push run

IMG=rmt-fuser

# Docker set up

build: remote-fuser-ctl.ini
	docker build -t ${IMG} .

# This also brings remote-fuser-ctl.pl
remote-fuser-ctl.ini:
	curl -s ftp://ftp.ncbi.nlm.nih.gov/blast/executables/remote-fuser/remote-fuser.tgz | tar -zxf -
	./config-gcs-access.sh
	${RM} config-gcs-access.sh README.txt

# N.B.: need these options to run FUSE https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities
# Conclusion, running rmt-fuser as a daemon doesn't work, as it's virtual file system isn't exposed. The only way to run it is as a single docker instance and then run BLAST in that.
run: build
	[ -d logs ] || mkdir logs
	[ -d blastdb ] || mkdir blastdb
	#docker run --rm --name rmt-fuser --cap-add SYS_ADMIN --device /dev/fuse -d -v ${PWD}/logs:/var/log -v ${PWD}/blastdb:/blast/blastdb ${IMG}	# shows nothing on local dir :(
	docker run -d --name rmt-fuser --privileged --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor=unconfined \
		--mount type=bind,src=${PWD}/logs,dst=/var/log --mount type=bind,src=${PWD}/blastdb,dst=/blast ${IMG}
	#	Fails b/c directory isn't shared
	#docker run -d --name rmt-fuser --privileged --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor=unconfined -v ${PWD}/blastdb:/blast:shared \
	#	-v ${PWD}/logs:/var/log:rw ${IMG}

check:
	docker exec rmt-fuser cat /blast/blastdb/nr_v5.pal
	ls -lhR logs blastdb

# The command above runs remote-fuser, mounts its data, but the rmt-fuser file system cannot be seen outside the container :(
# FIXME: am I missing something?
# TODO:  read https://thenewstack.io/methods-dealing-container-storage/

# these mounts do not work. The first one is not a bind, creates a volume whihc I cannot examine. The seocnd one creates volumes in doker, but I dont know how to get the data out of it
	#docker run --name rmt-fuser --cap-add SYS_ADMIN --device /dev/fuse -d -v logs:/var/log -v blastdb:/blast/blastdb ${IMG}
#run_with_docker_volume: build
#	docker run --name rmt-fuser --cap-add SYS_ADMIN --device /dev/fuse -d --mount type=volume,src=logs,dst=/var/log --mount type=volume,src=blastdb,dst=/blast/blastdb ${IMG}


stop:
	docker rm -f rmt-fuser


####################################
# Check remote-fuser locally

cpanm:
	curl -sL https://cpanmin.us -o $@
	chmod +x $@

local: cpanm
	./cpanm -l ./$@ Config::Simple Readonly

remote-fuser-ctl-local.ini:
	sed 's/^base_dir.*/base_dir = blastdb-local-remote-fuser/' remote-fuser-ctl.ini > $@

run_local: local remote-fuser-ctl-local.ini
	[ -d blastdb-local-remote-fuser ] || mkdir blastdb-local-remote-fuser
	PATH=${PATH}:. perl -I ${PWD}/local/lib/perl5 ./remote-fuser-ctl.pl --start --config ./remote-fuser-ctl-local.ini --verbose --logfile remote-fuser.log

check_local:
	ls -lhR blastdb-local-remote-fuser

stop_local:
	PATH=${PATH}:${PWD} PERL5LIB=${PWD}/local/lib/perl5 ./remote-fuser-ctl.pl --stop --config ./remote-fuser-ctl-local.ini --verbos
	${RM} -r blastdb-local-remote-fuser

clean:
	${RM} -r remote-fuser-ctl* cpanm local remote-fuser blastdb *.log
