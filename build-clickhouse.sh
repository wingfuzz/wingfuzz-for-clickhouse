#!/bin/bash

if [ -z "$2" ]; then
    echo "Usage: build-clickhouse.sh PATH_TO_CLICKHOUSE PATH_TO_BUILD"
    exit 1
fi

DOCKER_IMAGE=clickhouse-wingfuzz
