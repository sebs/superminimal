#!/bin/bash
    
# 1. use pg sql docker container 
CONTAINER_NAME=urls-db-test-pg
POSTGRES_PASSWORD=
POSTGRES_USER=
POSTGRES_DB=postgres
TEST_DB=testdb

# Start PostgreSQL container if not running
if [ ! "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
  if [ "$(docker ps -aq -f status=exited -f name=$CONTAINER_NAME)" ]; then
    docker start $CONTAINER_NAME
  else
    docker run --name $CONTAINER_NAME -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD -e POSTGRES_USER=$POSTGRES_USER -e POSTGRES_DB=$POSTGRES_DB -p 5432:5432 -d postgres:15
    # Wait for PostgreSQL to be ready
    echo "Waiting for PostgreSQL to start..."
    until docker exec $CONTAINER_NAME pg_isready -U $POSTGRES_USER; do sleep 1; done
  fi
fi

# 2. drop test database if exists
cat <<EOF | docker exec -i $CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB
DROP DATABASE IF EXISTS $TEST_DB;
EOF

# 3. create test database using create.sql
cat <<EOF | docker exec -i $CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB
CREATE DATABASE $TEST_DB;
EOF
docker exec -i $CONTAINER_NAME psql -U $POSTGRES_USER -d $TEST_DB < create.sql

# 4. run test.sql
docker exec -i $CONTAINER_NAME psql -U $POSTGRES_USER -d $TEST_DB < test.sql
