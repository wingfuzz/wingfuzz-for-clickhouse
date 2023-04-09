#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/env.sh"

echo "Creating data dir"

mkdir -p $DATADIR
cd $DATADIR
rm -rf *

echo "Starting server"
echo "Commmand: $DATABASE \
  --pidfile=$DATADIR/server.pid \
  -- \
  --path=$DATADIR \
  --http_port=$PORT \
  --mysql_port= \
  --postgresql_port= \
  --tcp_port="

$DATABASE \
  --pidfile=$DATADIR/server.pid \
  -- \
  --path=$DATADIR \
  --http_port=$PORT \
  --mysql_port= \
  --postgresql_port= \
  --tcp_port= \
  >>$TEST_DIR/init.log \
  2>>$TEST_DIR/init.err.log \
  &

for i in {1..30}
do
    echo "Check server status ... $i"
    curl -s --fail -X POST http://default:@127.0.0.1:$PORT/query -d 'select 1' >/dev/null 2>/dev/null
    if [ "$?" == "0" ]; then
        OK=1
        break
    fi
    sleep 1
done

if [ -z "$OK" ]; then
    echo "Cannot start database"
    EXIT=1
else
    echo "Server is started, create database ..."
    curl -s --fail -X POST http://default:@127.0.0.1:$PORT/query -d 'create database test' >/dev/null 2>/dev/null
    curl -s --fail -X POST http://default:@127.0.0.1:$PORT/query -d 'create database test2' >/dev/null 2>/dev/null
    EXIT=$?
fi

echo "Stopping server with PID" `cat $DATADIR/server.pid`

kill `cat $DATADIR/server.pid`

wait `cat $DATADIR/server.pid`

exit $EXIT
