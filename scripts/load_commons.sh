#!/bin/bash

# Constants
CONTAINER_NAME=${CONTAINER_NAME:-"silknow_virtuoso"}
LOG_FILE=${LOG_FILE:-"load_commons.log"}

containerId=$(docker ps -aqf "name=${CONTAINER_NAME}")
if [[ ! "${containerId}" ]]; then
  echo "${CONTAINER_NAME}: Container not found"
  exit 1
fi
echo "Docker container ID: ${containerId}"

# $1 = folder name in dumps/
# $2 = graph extension name (ie. http://data.silknow.org/$2)
load() {
  folderName="${1}"
  graphPart="${2}"

  temp_file=$(mktemp)
  touch "${temp_file}"
  echo "Created temp file: ${temp_file}"

  echo "DELETE FROM DB.DBA.load_list;" >> "${temp_file}"
  echo "SPARQL CLEAR GRAPH <http://data.silknow.org/${graphPart}>;" >> "${temp_file}"
  echo "ld_dir('dumps/${folderName}/', '*.*', 'http://data.silknow.org/${graphPart}');" >> "${temp_file}"
  echo "rdf_loader_run();" >> "${temp_file}"
  echo "cl_exec('checkpoint');" >> "${temp_file}"
  echo "DELETE FROM DB.DBA.load_list;" >> "${temp_file}"

  echo "Copying SQL file to the Docker container"
  docker cp "${temp_file}" "${containerId}:/load_commons.sql"

  echo "Executing SQL file through isql-v inside the Docker container"
  docker exec -i "${containerId}" sh -c "isql-v -U dba -P \${DBA_PASSWORD} < /load_commons.sql" &>> "${LOG_FILE}"
  echo "Query output saved to ${LOG_FILE}"

  echo "Removing temp file: ${temp_file}"
  rm "${temp_file}"
}

load "ontologies" "ontology"
load "commons" "commons"
load "thesaurus" "vocabulary"
load "vocabulary_aat" "vocabulary_aat"
