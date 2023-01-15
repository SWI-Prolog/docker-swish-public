#!/bin/bash

check()
{ curl --fail -s --retry 3 --max-time 5 \
       -d ask="statistics(threads,V)" \
       -d template="csv(V)" \
       -d format=csv \
       -d solutions=all \
       http://localhost:3050/pengine/create
  return $?
}

stop()
{ pid=$(pgrep swipl)
  echo "Health check failed.  Killing swipl at pid=$pid"
  kill -TERM $pid
  timeout 10 tail --pid=$pid -f /dev/null
  if [ $? == 124 ]; then
      echo "Gracefull termination failed.  Forcing"
      if [ $pid == 1 ]; then
	  kill -- $pid
      else
	  kill -9 $pid
      fi
  fi
  echo "Done"
}

starting()
{ if [ -f /var/run/epoch ]; then
      epoch=$(cat /var/run/epoch)
      running=$(($(date "%+s") - $epoch))
      [ $running -gt 60 ] || return 1
  fi
  echo "Starting, so not killing"
  return 0
}

check || starting || stop

