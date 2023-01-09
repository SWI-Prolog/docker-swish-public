FROM debian:bullseye-slim

# Dockerfile for the public swish image.   This docker image is designed to allow
# for a quick update by changing ENV VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
        git curl unzip build-essential cmake autoconf ninja-build pkg-config \
	cleancss node-requirejs \
        ncurses-dev libreadline-dev libedit-dev \
        libgoogle-perftools-dev \
        libgmp-dev \
        libssl-dev \
        unixodbc-dev \
        zlib1g-dev libarchive-dev \
        libossp-uuid-dev \
        libxext-dev libice-dev libjpeg-dev libxinerama-dev libxft-dev \
        libxpm-dev libxt-dev \
        libdb-dev \
        libpcre2-dev \
        libyaml-dev \
        default-jdk junit4 \
	graphviz imagemagick \
	wamerican \
	libssh-dev openssh-client \
	libserd-dev libraptor2-dev \
	locales

RUN	sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen && \
	locale-gen
ENV	LC_ALL en_GB.UTF-8
ENV	LANG en_GB.UTF-8
ENV	LANGUAGE en_GB:en

RUN	mkdir /wordnet && cd /wordnet && \
	curl https://wordnetcode.princeton.edu/3.0/WNprolog-3.0.tar.gz > WNprolog-3.0.tar.gz && \
	tar zxf WNprolog-3.0.tar.gz
ENV	WNDB /wordnet/prolog

RUN	mkdir -p /usr/local/src && cd /usr/local/src && \
	git clone --recursive https://github.com/SWI-Prolog/swipl-devel.git && \
	cd swipl-devel && mkdir build && cd build && \
	cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=PGO -G Ninja .. && \
	ninja && ninja install

RUN	mkdir -p /usr/share/swi-prolog/pack
RUN	swipl -g "pack_install(chat80,[interactive(false),package_directory('/usr/share/swi-prolog/pack')])" -t halt
RUN	swipl -g "pack_install(wordnet,[interactive(false),package_directory('/usr/share/swi-prolog/pack')])" -t halt && \
	swipl -g "[library(wn)],load_wordnet" -t halt	
RUN	swipl -g "pack_install(libssh,[interactive(false),package_directory('/usr/share/swi-prolog/pack')])" -t halt

RUN	cd / && \
	git clone -b redis https://github.com/SWI-Prolog/swish.git && \
	make -C /swish RJS="nodejs /usr/share/nodejs/requirejs/r.js" \
		yarn-zip packs min
RUN	make -C /swish -j PACKS=hdt packs

# Update.  Run `make update-swish` or `make update-swipl` to update the `ENV` command
# below and redo the relevant part of the build

ENV	SWIPL_VERSION 3
RUN	git config --global pull.ff only
RUN	cd /usr/local/src/swipl-devel && git pull && \
	git submodule update --init && \
	cd build && cmake . && ninja && \
	ninja install
RUN	swipl -g "[library(wn)],load_wordnet" -t halt	
ENV	SWISH_VERSION Sun  8 Jan 18:25:06 CET 2023
RUN	cd /swish && git fetch && git checkout backend && git pull && \
	git submodule update --init && \
	make -C /swish RJS="nodejs /usr/share/nodejs/requirejs/r.js" min

HEALTHCHECK --interval=30s --timeout=2m --start-period=1m \
	CMD curl --fail -s --retry 3 --max-time 20 \
	-d ask="statistics(threads,V)" \
	-d template="csv(V)" \
	-d format=csv \
	-d solutions=all \
	http://localhost:3050/pengine/create || \
	bash -c 'kill -s 15 -1 && (sleep 10; kill -s 9 -1)'

COPY start-swish.sh start-swish.sh

ENV SWISH_DATA /data
ENV SWISH_HOME /swish
VOLUME ${SWISH_DATA}
WORKDIR ${SWISH_DATA}

ENTRYPOINT ["/start-swish.sh"]
