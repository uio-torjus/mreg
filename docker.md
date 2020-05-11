# Running with docker

Instructions for running `mreg` within a container.

## With Compose

Instructions for running `mreg` with `docker-compose`.

### Run tests

```text
docker-compose up --build test
```

### Run the server

Server should be reachable on port 8000 after running this.

```text
docker-compose up --build -d mreg
```

### Cleanup

```text
docker-compose down --rmi local
```

## Manually

Instructions for running mreg-container without compose.

### Build and create network

```text
docker build -t mreg:latest .
docker network create mreg
```

### Run a postgres-instance

```text
docker run --name mreg-db \
    -e POSTGRES_PASSWORD=mreg \
    -e POSTGRES_USER=mreg_user \
    --net=mreg \
    postgres:latest
```

### Run mreg tests

```text
docker run --name mreg-test \
    -e MREG_DB=pg \
    -e MREG_DB_PG_DATABASE=mreg_test \
    -e MREG_TEST=true \
    -e MREG_TEST_ONLY=true \
    -p 8000:8000 \
    --net=mreg \
    mreg:latest
```

### Run Server

```text
docker run --name mreg-test \
    -e MREG_DB=pg \
    -e MREG_DB_PG_DATABASE=mreg_test \
    -e MREG_TEST=true \
    -e MREG_TEST_ONLY=true \
    -p 8000:8000 \
    --net=mreg \
    mreg:latest
```


### Cleanup

```text
docker stop mreg mreg-test mreg-db
docker rm mreg mreg-test mreg-db
docker rmi mreg:latest
docker network rm mreg
```