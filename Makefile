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
	#	--mount type=bind,src=${PWD}/logs,dst=/var/log \
	#	--mount type=bind,src=${PWD}/blastdb,dst=/blast \
	#	${IMG}
	docker run -d --name rmt-fuser --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor=unconfined \
		--mount type=bind,src=${PWD}/logs,dst=/var/log \
		--mount type=bind,src=${PWD}/blastdb,dst=/blast \
		${IMG}

BP?=shared
# docker: Error response from daemon: linux mounts: path /home/camacho/docker-rmt-fuser/blastdb is mounted on /home but it is not a shared mount.
run_shared: build	
	[ -d logs ] || mkdir logs
	[ -d blastdb ] || mkdir blastdb
	docker run -d --name rmt-fuser --privileged --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor=unconfined \
		-v ${PWD}/blastdb:/blast:${BP} \
		-v ${PWD}/logs:/var/log:rw \
		${IMG}

make_shared:
	mount --make-shared /

check:
	-docker exec ${IMG} cat /blast/blastdb/nr_v5.pal
	-docker exec ${IMG} find /blast/cache/ -type f
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
	-docker exec rmt-fuser /sbin/remote-fuser-ctl.pl --stop --verbose --config /etc/remote-fuser-ctl.ini
	-docker rm -f rmt-fuser
	sudo ${RM} -r logs blastdb
	-docker volume rm logs blastdb

fuse.xml: remote-fuser-ctl.ini
	curl -s `awk -F= '/^config/ {print $$2}' remote-fuser-ctl.ini` -o $@


clean:
	${RM} -r remote-fuser-ctl* cpanm local remote-fuser logs blastdb *.log

####################################
# Test bind propagation
HOST_DIR=/srv/test
CONTAINER_DIR=/foo
bind_propagation_start:
	[ -d ${HOST_DIR} ] || sudo mkdir -p ${HOST_DIR}
	docker run --name testbp -d --privileged --cap-add SYS_ADMIN --device /dev/fuse \
		--mount type=bind,src=${HOST_DIR},dst=${CONTAINER_DIR},bind-propagation=shared \
		ubuntu sleep infinity
	#docker run --name testbp -d --privileged -v ${HOST_DIR}:${CONTAINER_DIR}:shared ubuntu
	ls -lha ${HOST_DIR}

bind_propagation_check:
	docker exec testbp mkdir -p ${CONTAINER_DIR}/bin
	docker exec testbp mount --bind /bin ${CONTAINER_DIR}/bin
	#docker exec testbp mount --bind --make-shared /bin ${CONTAINER_DIR}/bin
	ls -lha ${HOST_DIR}

bind_propagation_stop:
	-docker stop testbp
	-docker logs testbp
	-docker rm testbp
	-sudo ${RM} -r ${HOST_DIR}

####################################
# COS setup (see cos-*sh scripts)
.PHONY: cos_start cos_stop

TYPE?=n1-standard-8
ZONE?=us-east4-b
VM_IMG?=cos-stable-70-11021-99-0
cos_start:
	@[ ! -z "${GCP_PRJ}" ] || \
		{ echo "Please define GCP_PRJ environment variable"; exit 1; }
	gcloud compute instances create rmt-fuser-test-${USER} \
		--machine-type ${TYPE} \
		--image ${VM_IMG} \
		--image-project=cos-cloud \
        --scopes cloud-platform \
        --project ${GCP_PRJ} \
		--zone ${ZONE}

cos_stop:
	@[ ! -z "${GCP_PRJ}" ] || \
		{ echo "Please define GCP_PRJ environment variable"; exit 1; }
	gcloud compute instances delete rmt-fuser-test-${USER} --project ${GCP_PRJ} --zone ${ZONE}

####################################
DST=/etc/systemd/system/docker.service.d
.PHONY: overrides_blank overrides_shared
overrides_blank:
	echo -e '[Service]\nMountFlags=' > overrides.conf
	[ -d ${DST} ] || sudo mkdir -p ${DST}
	sudo mv overrides.conf ${DST}

overrides_shared:
	echo -e '[Service]\nMountFlags=shared' > overrides.conf
	[ -d ${DST} ] || sudo mkdir -p ${DST}
	sudo mv overrides.conf ${DST}

rm_overrides:
	sudo ${RM} overrides.conf ${DST}

####################################
#.PHONY: publish
# VERSION=0.1
#publish: build
#	docker tag rmt-fuser christiam/docker-rmt-fuser:${VERSION}
#	docker tag rmt-fuser christiam/docker-rmt-fuser:latest
#	docker push christiam/docker-rmt-fuser

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
	PATH=${PATH}:${PWD} PERL5LIB=${PWD}/local/lib/perl5 ./remote-fuser-ctl.pl --stop --config ./remote-fuser-ctl-local.ini --verbose
	${RM} -r blastdb-local-remote-fuser
