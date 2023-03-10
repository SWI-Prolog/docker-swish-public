#!/bin/bash

port=3050
data="$(pwd)"
dopts=
fake=no

done=no
while [ $done = no ]; do
  case "$1" in
    --port=*)	port="$(echo $1 | sed 's/[^=]*=//')"
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
    *)		done=yes
		;;
  esac
done

if [ $fake = no ]; then
  docker run -p $port:3050 -p 3250:3250 -v "$data":/data $dopts swish $*
else
  echo docker run -d --restart unless-stopped -p 127.0.0.1:$port:3050 -p 127.0.0.1:3250:3250 -v "$data":/data $dopts swish $*
fi
