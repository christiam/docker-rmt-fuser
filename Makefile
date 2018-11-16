# Makefile for setting up remote-fuser in Docker
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)

SHELL=/bin/bash
.PHONY: build push run

IMG=rmt-fuser

build: remote-fuser-ctl.ini
	docker build -t ${IMG} .

# This also brings remote-fuser-ctl.pl
remote-fuser-ctl.ini:
	curl -s ftp://ftp.ncbi.nlm.nih.gov/blast/executables/remote-fuser/remote-fuser.tgz | tar -zxf -
	./config-gcs-access.sh
	${RM} config-gcs-access.sh README.txt

# Conclusion, running rmt-fuser as a daemon doesn't work, as it's virtual file system isn't exposed. The only way to run it is as a single docker instance and then run BLAST in that.
run: build
	[ -d logs ] || mkdir logs
	[ -d blastdb ] || mkdir blastdb
	docker run -d --name rmt-fuser --privileged --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor=unconfined \
		--mount type=bind,src=${PWD}/logs,dst=/var/log \
		--mount type=bind,src=${PWD}/blastdb,dst=/blast \
		${IMG}

# Fails b/c directory ${PWD}/blastdb isn't shared
run2: build	
	[ -d logs ] || mkdir logs
	[ -d blastdb ] || mkdir blastdb
	docker run -d --name rmt-fuser --privileged --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor=unconfined \
		-v ${PWD}/blastdb:/blast:shared \
		-v ${PWD}/logs:/var/log:rw \
		${IMG}

# shows nothing on local blastdb dir
run0: build
	[ -d logs ] || mkdir logs
	[ -d blastdb ] || mkdir blastdb
	docker run -d --name rmt-fuser --cap-add SYS_ADMIN --device /dev/fuse \
		-v ${PWD}/logs:/var/log \
		-v ${PWD}/blastdb:/blast/blastdb \
		${IMG}

check:
	-docker exec rmt-fuser cat /blast/blastdb/nr_v5.pal
	-docker exec rmt-fuser  ls /blast/cache/
	ls -lhR logs blastdb

# these mounts do not work.
run_local_volume: build
	docker run -d --name rmt-fuser --cap-add SYS_ADMIN --device /dev/fuse \
		-v logs:/var/log \
		-v blastdb:/blast/blastdb ${IMG}

run_with_docker_volume: build
	docker run -d --name rmt-fuser --cap-add SYS_ADMIN --device /dev/fuse \
		--mount type=volume,src=logs,dst=/var/log \
		--mount type=volume,src=blastdb,dst=/blast/blastdb \
		${IMG}

stop:
	docker rm -f rmt-fuser


####################################
# Check remote-fuser locally

cpanm:
	curl -sL https://cpanmin.us -o $@
	chmod +x $@

local: cpanm
	./cpanm -l ./$@ Config::Simple Readonly

remote-fuser-ctl-local.ini: remote-fuser-ctl.ini
	sed 's/^base_dir.*/base_dir = blastdb-local-remote-fuser/' $^ > $@

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
