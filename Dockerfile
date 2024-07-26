FROM debian:bookworm-slim

# Dockerfile for the public swish image.   This docker image is designed to allow
# for a quick update by changing ENV VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
        git curl ca-certificates unzip \
	build-essential cmake ninja-build pkg-config \
	autoconf autotools-dev automake libtool \
	gdb \
	cleancss node-requirejs uglifyjs \
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
	graphviz imagemagick \
	wamerican \
	libssh-dev openssh-client \
	libserd-dev libraptor2-dev \
	locales

RUN	sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen && \
	locale-gen
ENV	LC_ALL=en_GB.UTF-8
ENV	LANG=en_GB.UTF-8
ENV	LANGUAGE=en_GB:en

RUN	mkdir /wordnet && cd /wordnet && \
	curl https://wordnetcode.princeton.edu/3.0/WNprolog-3.0.tar.gz > WNprolog-3.0.tar.gz && \
	tar zxf WNprolog-3.0.tar.gz
ENV	WNDB=/wordnet/prolog

ENV	REBUILD_MOST=4
RUN	mkdir -p /usr/local/src && cd /usr/local/src && \
	git clone --recursive https://github.com/SWI-Prolog/swipl-devel.git && \
	cd swipl-devel && mkdir build && cd build && \
	cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=PGO -G Ninja .. && \
	ninja && ninja install

RUN	mkdir -p /usr/share/swi-prolog/pack
RUN	swipl pack install -y --dir=/usr/share/swi-prolog/pack chat80 wordnet libssh
RUN	git -C /usr/share/swi-prolog/pack clone -b swish https://github.com/JanWielemaker/clpBNR_pl clpBNR
RUN	swipl -g "[library(wn)],load_wordnet" -t halt

RUN	cd / && \
	git clone https://github.com/SWI-Prolog/swish.git && \
	make -C /swish RJS="nodejs /usr/share/nodejs/requirejs/r.js" \
		yarn-zip packs min
RUN	make -C /swish -j PACKS=hdt packs

# Update.  Run `make update-swish` or `make update-swipl` to update the `ENV` command
# below and redo the relevant part of the build

ENV	SWIPL_VERSION="Mon Dec  4 13:51:01 CET 2023"
RUN	git config --global pull.ff only
RUN	cd /usr/local/src/swipl-devel && (git pull || git pull) && \
	git submodule update --init && \
	find . -name '*.qlf' | xargs rm && \
	cd build && rm -rf home && cmake . && ninja && \
	rm -rf /usr/lib/swipl && \
	ninja install
RUN	swipl -g "[library(wn)],load_wordnet" -t halt
ENV	SWISH_VERSION="Wed Jan 11 23:52:48 CET 2023"
RUN	git -C /usr/share/swi-prolog/pack/clpBNR fetch && \
	git -C /usr/share/swi-prolog/pack/clpBNR reset --hard origin/swish
RUN	cd /swish && git pull && \
	git submodule update --init && \
	make -C /swish RJS="nodejs /usr/share/nodejs/requirejs/r.js" min

COPY health.sh health.sh
HEALTHCHECK --interval=30s --timeout=2m --start-period=1m CMD /health.sh

COPY start-swish.sh start-swish.sh

ENV SWISH_DATA=/data
ENV SWISH_HOME=/swish
VOLUME ${SWISH_DATA}
WORKDIR ${SWISH_DATA}

ENTRYPOINT ["/start-swish.sh"]
