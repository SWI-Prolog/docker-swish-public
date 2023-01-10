#!/bin/bash

check()
{ curl --fail -s --retry 3 --max-time 20 \
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
      kill -9 $pid
  fi
  echo "Done"
}

check || stop

