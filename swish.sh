#!/bin/bash

port=3050
sshport=3250
data="$(pwd)"
dopts=
sopts=
fake=no
IMG=${IMG-swish}
name=
RESTART="--restart unless-stopped"

config-only()
{ port=0
  sshport=0
  RESTART=--rm
  dopts+=" -it"
}


done=no
while [ $done = no ]; do
  case "$1" in
    --port=*)	port="$(echo $1 | sed 's/[^=]*=//')"
		shift
		;;
    --name=*)	name="$(echo $1 | sed 's/[^=]*=//')"
		shift
		;;
    --ssh=*)	sshport="$(echo $1 | sed 's/[^=]*=//')"
		shift
		;;
    --data=*)	data="$(echo $1 | sed 's/[^=]*=//')"
		shift
		;;
    --with-R=*) from="$(echo $1 | sed 's/[^=]*=//')"
		dopts="$dopts --volumes-from $from"
		shift
		;;
    --with-R)	dopts="$dopts --volumes-from rserve"
		shift
		;;
    -n)		fake=yes
		shift
		;;
    -d)		dopts="$dopts -d"
		shift
		;;
    -it)	dopts="$dopts -it"
		shift
		;;
    --rm)	RESTART=--rm
		shift
		;;
    --help|--auth*|--add-user|--add-config|--list-config)
	        sopts+=" $1"
		config-only
		shift
		;;
    *)		sopts+=" $*"
		done=yes
		;;
  esac
done

if [ "$sshport" != 0 ]; then
    SSHMAP="-p 127.0.0.1:$sshport:3250"
else
    SSHMAP=
fi

if [ "$port" != 0 ]; then
    HTTPMAP="-p 127.0.0.1:$port:3050"
else
    HTTPMAP=
fi

if [ ! -z "$name" ]; then
    dopts+=" --name=$name"
fi

if [ $fake = no ]; then
  docker run $RESTART $HTTPMAP $SSHMAP -v "$data":/data $dopts $IMG $sopts
else
  echo docker run $RESTART $HTTPMAP $SSHMAP -v "$data":/data $dopts $IMG $sopts
fi
