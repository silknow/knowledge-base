#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

load() {
  # Load prefixes
  docker cp "${SCRIPTPATH}/prefixes.sql" "${CONTAINER_NAME}:/prefixes.sql"
  docker exec -i "${CONTAINER_NAME}" sh -c "isql-v -U dba -P \${DBA_PASSWORD} < /prefixes.sql"
}

# Node 1
echo "load_prefixes::node1"
CONTAINER_NAME="silknow_virtuoso"
load

# Node 2
echo "load_prefixes::node1"
CONTAINER_NAME="silknow_virtuoso_node2"
load
