#!/bin/bash -x

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/env.sh"

cd $DATADIR

$DATABASE -- \
  --path=$DATADIR \
  --http_port=$PORT \
  --mysql_port= \
  --postgresql_port= \
  --tcp_port= \
  >>$TEST_DIR/server.log \
  2>>$TEST_DIR/server.err.log


