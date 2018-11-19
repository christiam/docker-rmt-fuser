# Makefile for setting up remote-fuser in Docker
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)

SHELL=/bin/bash
.PHONY: build run_shared run clean check check2 stop run_local_volume run_local check_local stop_local

IMG=rmt-fuser

build: remote-fuser-ctl.ini
	docker build -t ${IMG} .

# This also brings remote-fuser-ctl.pl
remote-fuser-ctl.ini:
	curl -s ftp://ftp.ncbi.nlm.nih.gov/blast/executables/remote-fuser/remote-fuser.tgz | tar -zxf -
	head -20 ./config-gcs-access.sh > tmp.sh
	chmod +x tmp.sh
	./tmp.sh
	${RM} config-gcs-access.sh README.txt tmp.sh

# Exposes FUSE inside container, but not outside or to other containers
run: build
	[ -d logs ] || mkdir logs
	[ -d blastdb ] || mkdir blastdb
	#docker run -d --name rmt-fuser --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor=unconfined \
		--mount type=bind,src=${PWD}/logs,dst=/var/log \
		--mount type=bind,src=${PWD}/blastdb,dst=/blast \
		${IMG}
	docker run -d --name rmt-fuser --cap-add SYS_ADMIN --device /dev/fuse \
		--mount type=bind,src=${PWD}/logs,dst=/var/log \
		--mount type=bind,src=${PWD}/blastdb,dst=/blast \
		${IMG}

BP?=shared
# Fails b/c directory ${PWD}/blastdb isn't shared
run_shared: build	
	[ -d logs ] || mkdir logs
	[ -d blastdb ] || mkdir blastdb
	docker run -d --name rmt-fuser --privileged --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor=unconfined \
		-v ${PWD}/blastdb:/blast:${BP} \
		-v ${PWD}/logs:/var/log:rw \
		${IMG}

check:
	-docker exec rmt-fuser cat /blast/blastdb/nr_v5.pal
	-docker exec rmt-fuser find /blast/cache/ -type f
	-find logs blastdb -ls
	-docker volume inspect logs blastdb
	-docker run -v ${PWD}/blastdb:/blast:ro ubuntu cat /blast/blastdb/nr_v5.pal
	-docker run -v ${PWD}/blastdb:/blast:ro ubuntu find /blast -ls

check2:
	-docker exec rmt-fuser cat /blast/blastdb/nt_v5.nal

run_local_volume: build
	docker run -d --name rmt-fuser --privileged --cap-add SYS_ADMIN --device /dev/fuse \
		-v logs:/var/log \
		-v blastdb:/blast/blastdb ${IMG}
	-docker ps
	-docker volume ls

stop:
	-docker rm -f rmt-fuser
	${RM} -r logs blastdb
	-docker volume rm logs blastdb

fuse.xml: remote-fuser-ctl.ini
	curl -s `awk -F= '/^config/ {print $$2}' remote-fuser-ctl.ini` -o $@


clean:
	${RM} -r remote-fuser-ctl* cpanm local remote-fuser logs blastdb *.log

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
