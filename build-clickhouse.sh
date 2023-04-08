#!/bin/bash

if [ -z "$BUILDER_IMAGE" ]; then
    BUILDER_IMAGE=clickhouse-wingfuzz
fi

if [ -z "$2" ]; then
    echo "Usage: build-clickhouse.sh PATH_TO_CLICKHOUSE PATH_TO_BUILD [PATH_TO_CACHE]"
    exit 1
fi

PATH_TO_CLICKHOUSE=`realpath $1`
PATH_TO_BUILD=`realpath $2`

if [ ! -z "$3" ]; then
    PATH_TO_CACHE=`realpath $3`
    mkdir -p $PATH_TO_CACHE/cargo $PATH_TO_CACHE/ccache
    CACHE_ARG="-v $PATH_TO_CACHE/cargo:/rust/cargo/registry -v $PATH_TO_CACHE/ccache:/root/.cache/ccache"
fi

if [ -z "$NO_ASAN" ]; then
    DOCKER_USE_ASAN="-DSANITIZE=address"
else
    DOCKER_USE_ASAN="-USANITIZE"
fi

docker run -it --rm -v $PATH_TO_CLICKHOUSE:/workdir -v $PATH_TO_BUILD:/build $CACHE_ARG $BUILDER_IMAGE \
    bash -c 'cd /build && \
             cmake /workdir \
                   -DCMAKE_C_COMPILER=/opt/wfuzz/bin/afl-clang-fast \
                   -DCMAKE_CXX_COMPILER=/opt/wfuzz/bin/afl-clang-fast \
                   -DENABLE_EXAMPLES=0 \
                   -DENABLE_UTILS=0 \
                   -DENABLE_BENCHMARKS=0 \
                   -DENABLE_THINLTO=0 \
                   -DENABLE_TCMALLOC=0 \
                   -DENABLE_JEMALLOC=0 \
                   -DENABLE_CHECK_HEAVY_BUILDS=0 \
                   -DENABLE_EMBEDDED_COMPILER=0 \
                   -DENABLE_SSL=1 \
                   -DUSE_UNWIND=ON \
                   '"$DOCKER_USE_ASAN"' \
                   && \
             ninja -v
            '
