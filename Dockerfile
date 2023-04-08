FROM clickhouse/binary-builder

RUN apt update && \
    apt install -y unixodbc-dev && \
    apt clean

COPY . /

RUN cd /aflpp && \
    LLVM_CONFIG=llvm-config-15 make PREFIX=/opt/wfuzz install && \
    cd /clickhouse-odbc && \
    mkdir -p build && \
    cd build && \
    cmake ..  && \
    make && \
    mkdir -p /opt/wfuzz/lib && \
    cp driver/libclickhouseodbc.so driver/libclickhouseodbcw.so /opt/wfuzz/lib

FROM clickhouse/binary-builder

RUN apt update && \
    apt install -y unixodbc-dev && \
    apt clean

COPY --from=0 /opt/wfuzz /opt/wfuzz
