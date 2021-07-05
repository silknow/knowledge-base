#!/bin/bash

# Constants
SILKNOW_PATH=${SILKNOW_PATH:-"/home/semantic/silknow"}
KB_PATH=${KB_PATH:-"${SILKNOW_PATH}/knowledge-base"}
LOG_FILE=${LOG_FILE:-"patches.log"}

load() {
  VIRTUOSO_VOCABULARIES_PATH=${VIRTUOSO_VOCABULARIES_PATH:-"${VIRTUOSO_DUMPS_PATH}/vocabularies"}
  VIRTUOSO_MUSEUMS_PATH=${VIRTUOSO_MUSEUMS_PATH:-"${VIRTUOSO_DUMPS_PATH}/museums"}

  # Get container ID
  containerId=$(docker ps -aqf "name=^${CONTAINER_NAME}$")
  if [[ ! "${containerId}" ]]; then
    echo "${CONTAINER_NAME}: Container not found"
    exit 1
  fi
  echo "Docker container ID: ${containerId}"

  for file in "${KB_PATH}/patches/"*; do
    # Create SQL file
    temp_file=$(mktemp)
    touch "${temp_file}"
    echo "Created temp file: ${temp_file}"

    query=$(<${file})
    echo "SPARQL ${query} ;" >> "${temp_file}"

    # Copy SQL file to container
    echo "Copying SQL file to the Docker container"
    docker cp "${temp_file}" "${containerId}:/patch.sql"

    # Execute SQL file
    echo "Executing SQL file through isql-v inside the Docker container"
    docker exec -i "${containerId}" sh -c "isql-v -U dba -P \${DBA_PASSWORD} < /patch.sql" &>> "${LOG_FILE}"
    echo "Query output saved to ${LOG_FILE}"

    # Cleanup
    echo "Removing temp file: ${temp_file}"
    rm "${temp_file}"
  done
}

# Node 1
echo "load_patches::node1"
CONTAINER_NAME="silknow_virtuoso"
VIRTUOSO_DUMPS_PATH="/var/docker/virtuoso/silknow/data/dumps"
load

# Node 2
echo "load_patches::node2"
CONTAINER_NAME="silknow_virtuoso_node2"
VIRTUOSO_DUMPS_PATH="/var/docker/virtuoso/silknow_node2/data/dumps"
load
