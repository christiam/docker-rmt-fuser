FROM ubuntu:18.04
LABEL Description="remote-fuser daemon from the NCBI SRA toolkit" \
    Vendor="NCBI/NLM/NIH" \
    URL="https://github.com/ncbi/sra-tools" \
    Maintainer=camacho@ncbi.nlm.nih.gov 

USER root
RUN apt-get -y -m update && \
    apt-get install -y \
    fuse libxml2-dev \
    curl \
    libconfig-simple-perl \
    libreadonly-perl \
    perl-doc && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /sbin
RUN curl -s ftp://ftp.ncbi.nlm.nih.gov/blast/executables/remote-fuser/remote-fuser.tgz | tar -zxf - && \
    chmod +x remote-fuser && \
    head -20 ./config-gcs-access.sh > tmp.sh && bash ./tmp.sh && \
    rm -fr config-gcs-access.sh README.txt tmp.sh
COPY remote-fuser-ctl.pl /sbin/
RUN chmod +x /sbin/remote-fuser-ctl.pl
WORKDIR /etc
COPY remote-fuser-ctl.ini .

RUN mkdir -p /blast/blastdb

#VOLUME ["/var/log", "/blast/"]

WORKDIR /tmp

CMD ["/sbin/remote-fuser-ctl.pl", "--start", "--verbose", "--foreground", "--config", "/etc/remote-fuser-ctl.ini" ]
