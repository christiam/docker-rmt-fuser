# Makefile for FIXME
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)
# Created: Fri 16 Nov 2018 11:09:15 PM EST

.PHONY: mount
mount:
	[ -d ftp ] || mkdir ftp
	rclone --config rclone.conf mount ncbiftp:blast/db ${PWD}/ftp
	rm -fr ftp

.PHONY: ls
ls:
	rclone --config rclone.conf ls ncbiftp:blast/db

.PHONY: install-rclone
install-rclone:
	curl https://rclone.org/install.sh  | sudo bash

#DIR=${PWD}/ftp-rclone
#DIR=/tmp/ftp-rclone
#DIR=/var/ftp-rclone
DIR=/mnt/ftp-rclone
docker-mount:
	[ -d ${DIR} ] || sudo mkdir -p ${DIR}
	#sudo mount --make-shared `dirname ${DIR}`
	[ -d config ] || mkdir config
	cp rclone.conf config/
	docker run -d --name rclone-mount \
		--restart=unless-stopped \
		--cap-add SYS_ADMIN \
		--device /dev/fuse \
		--security-opt apparmor:unconfined \
		-e RemotePath="ncbiftp:blast/db" \
		-e MountCommands="--allow-other --allow-non-empty" \
		-e ConfigName="rclone.conf" \
		-v ${PWD}/config:/config \
		-v ${DIR}:/mnt/mediaefs:shared \
		mumiehub/rclone-mount
	#rm -fr config /tmp/ftp-rclone

check:
	-ls -l ${DIR}

.PHONY: clean
clean:
	-docker rm -f rclone-mount
	sudo rm -fr ftp config ${DIR}
