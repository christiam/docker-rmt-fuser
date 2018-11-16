FROM ubuntu:18.04
LABEL Description="remote-fuser daemon from the NCBI VDB toolkit" Vendor="NCBI/NLM/NIH" Maintainer=camacho@ncbi.nlm.nih.gov

USER root
RUN apt-get -y -m update && \
    apt-get install -y \
    fuse \
    cpanminus \
    libconfig-simple-perl \
    libreadonly-perl \
    libxml2-dev \
    libnet-perl \
    perl-doc \
    wget && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /sbin
RUN wget -q ftp://ftp.ncbi.nlm.nih.gov/blast/temp/remote-fuser-wb3176 -O remote-fuser && \
    chmod +x remote-fuser
COPY remote-fuser-ctl.pl /sbin/
RUN chmod +x /sbin/remote-fuser-ctl.pl
WORKDIR /etc
COPY remote-fuser-ctl.ini .

RUN mkdir -p /blast/blastdb

#VOLUME ["/var/log", "/blast/"]

WORKDIR /tmp

CMD ["/sbin/remote-fuser-ctl.pl", "--start", "--verbose", "--foreground", "--config", "/etc/remote-fuser-ctl.ini" ]
