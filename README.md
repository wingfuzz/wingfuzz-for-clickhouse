# Test ClickHouse with WINGFUZZ

## 1. Update submodules

We use git submodules to store dependencies. 
You should update them before build the docker image.

```bash
# This submodule doesn't require recursive modules
git submodule update --init --progress aflpp
# But this submodule requires
git submodule update --init --progress --recursive clickhouse-odbc
```

## 1. build docker image

```bash
docker build . -t clickhouse-wingfuzz
```

## 2. build clickhouse

```

```