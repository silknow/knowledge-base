#!/bin/bash

# Constants
SILKNOW_PATH=${SILKNOW_PATH:-"/home/semantic/silknow"}
KB_PATH=${KB_PATH:-"${SILKNOW_PATH}/knowledge-base"}
CONVERTER_PATH=${CONVERTER_PATH:-"${SILKNOW_PATH}/converter"}
THESAURUS_PATH=${THESAURUS_PATH:-"${SILKNOW_PATH}/thesaurus"}
LOG_FILE=${LOG_FILE:-"load_commons.log"}

# $1 = path to directory which contains RDF files
delete_rdf() {
  find "$1" -name "*.rdf" -or -name "*.rdf.gz" -type f -delete
  find "$1" -name "*.rdfs" -or -name "*.rdfs.gz" -type f -delete
  find "$1" -name "*.ttl" -or -name "*.ttl.gz" -type f -delete
  find "$1" -name "*.n3" -or -name "*.n3.gz" -type f -delete
}

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

  # Copy files from thesaurus
  cd "${THESAURUS_PATH}" || exit 1
  git pull --rebase
  mkdir -p "${VIRTUOSO_VOCABULARIES_PATH}/thesaurus"
  cp "thesaurus.ttl" "${VIRTUOSO_VOCABULARIES_PATH}/thesaurus/"

  # Update knowledge-base
  echo "Updating knowledge-base repository"
  cd "${KB_PATH}" || exit 1
  git pull --rebase

  # Copy files from vocabularies
  for folder in "${KB_PATH}/vocabularies/"*; do
    folderName=$(basename "$folder")
    echo "Copying vocabularies from: ${folderName}"
    mkdir -p "${VIRTUOSO_VOCABULARIES_PATH}/${folderName}"
    delete_rdf "${VIRTUOSO_VOCABULARIES_PATH}/${folderName}"
    cp -r "${KB_PATH}/vocabularies/${folderName}" "${VIRTUOSO_VOCABULARIES_PATH}/"
  done

  # Load files
  for folder in "${KB_PATH}/vocabularies/"*; do
    # graph extension name (ie. http://data.silknow.org/$2)
    graphPart=$(basename "$folder")
    # folder path in dumps/
    folderPath="vocabularies/${graphPart}"

    temp_file=$(mktemp)
    touch "${temp_file}"
    echo "Created temp file: ${temp_file}"

    echo "DELETE FROM DB.DBA.load_list;" >> "${temp_file}"
    echo "SPARQL CLEAR GRAPH <http://data.silknow.org/${graphPart}>;" >> "${temp_file}"
    echo "ld_dir('dumps/${folderPath}/', '*.*', 'http://data.silknow.org/${graphPart}');" >> "${temp_file}"
    echo "rdf_loader_run();" >> "${temp_file}"
    echo "cl_exec('checkpoint');" >> "${temp_file}"
    echo "SELECT * FROM DB.DBA.load_list WHERE ll_error IS NOT NULL;" >> "${temp_file}"
    echo "DELETE FROM DB.DBA.load_list;" >> "${temp_file}"

    echo "Copying SQL file to the Docker container"
    docker cp "${temp_file}" "${containerId}:/load_commons.sql"

    echo "Executing SQL file through isql-v inside the Docker container"
    docker exec -i "${containerId}" sh -c "isql-v -U dba -P \${DBA_PASSWORD} < /load_commons.sql" &>> "${LOG_FILE}"
    echo "Query output saved to ${LOG_FILE}"

    echo "Removing temp file: ${temp_file}"
    rm "${temp_file}"
  done
}

# Node 1
echo "load_commons::node1"
CONTAINER_NAME="silknow_virtuoso"
VIRTUOSO_DUMPS_PATH="/var/docker/virtuoso/silknow/data/dumps"
load

# Node 2
echo "load_commons::node2"
CONTAINER_NAME="silknow_virtuoso_node2"
VIRTUOSO_DUMPS_PATH="/var/docker/virtuoso/silknow_node2/data/dumps"
load
