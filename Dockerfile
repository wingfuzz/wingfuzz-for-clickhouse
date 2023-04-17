FROM clickhouse/binary-builder

RUN apt update && \
    apt install -y unixodbc-dev && \
    apt clean

COPY clickhouse-odbc /clickhouse-odbc

RUN cd /clickhouse-odbc && \
    rm -rf build && \
    mkdir -p build && \
    cd build && \
    cmake ..  && \
    make -j && \
    mkdir -p /opt/wfuzz/lib && \
    cp driver/libclickhouseodbc.so driver/libclickhouseodbcw.so /opt/wfuzz/lib

COPY aflpp /aflpp

RUN cd /aflpp && \
    LLVM_CONFIG=llvm-config-15 make PREFIX=/opt/wfuzz install -j

COPY input-set.tar.gz wfuzz.tar.gz /

RUN cd /opt && \
    tar xzvf /wfuzz.tar.gz && \
    mkdir /input-set && \
    cd /input-set && \
    tar xzvf /input-set.tar.gz

FROM clickhouse/binary-builder

RUN apt update && \
    apt install -y unixodbc-dev libsqlite3-dev libboost-serialization1.71.0 libboost-program-options1.71.0 && \
    apt clean

COPY --from=0 /opt/wfuzz /opt/wfuzz

ENV WFUZZ_PATH=/opt/wfuzz
