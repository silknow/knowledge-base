#!/bin/bash

# Constants
SILKNOW_PATH=${SILKNOW_PATH:-"/home/semantic/silknow"}
KB_PATH=${KB_PATH:-"${SILKNOW_PATH}/knowledge-base"}
CONVERTER_PATH=${CONVERTER_PATH:-"${SILKNOW_PATH}/converter"}
THESAURUS_PATH=${THESAURUS_PATH:-"${SILKNOW_PATH}/thesaurus"}
VIRTUOSO_DUMPS_PATH=${VIRTUOSO_DUMPS_PATH:-"/var/docker/virtuoso/silknow/data/dumps"}
VIRTUOSO_VOCABULARIES_PATH=${VIRTUOSO_VOCABULARIES_PATH:-"${VIRTUOSO_DUMPS_PATH}/vocabularies"}
VIRTUOSO_MUSEUMS_PATH=${VIRTUOSO_MUSEUMS_PATH:-"${VIRTUOSO_DUMPS_PATH}/museums"}
CONTAINER_NAME=${CONTAINER_NAME:-"silknow_virtuoso"}
LOG_FILE=${LOG_FILE:-"load_commons.log"}

# $1 = path to directory which contains RDF files
delete_rdf() {
  find "$1" -name "*.rdf" -type f -delete
  find "$1" -name "*.rdfs" -type f -delete
  find "$1" -name "*.ttl" -type f -delete
  find "$1" -name "*.n3" -type f -delete
}

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

# Get container ID
containerId=$(docker ps -aqf "name=${CONTAINER_NAME}")
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

# Copy files from ontologies
echo "Copying ontologies vocabularies"
mkdir -p "${VIRTUOSO_VOCABULARIES_PATH}/ontologies"
delete_rdf "${VIRTUOSO_VOCABULARIES_PATH}/ontologies"
cp -r "${KB_PATH}/vocabularies/ontologies" "${VIRTUOSO_VOCABULARIES_PATH}/"

# Copy files from vocabulary_aat
echo "Copying aat vocabularies"
mkdir -p "${VIRTUOSO_VOCABULARIES_PATH}/vocabulary_aat"
delete_rdf "${VIRTUOSO_VOCABULARIES_PATH}/vocabulary_aat"
cp -r "${KB_PATH}/vocabularies/vocabulary_aat" "${VIRTUOSO_VOCABULARIES_PATH}/"

# Copy new files from commons
echo "Copying commons vocabularies"
mkdir -p "${VIRTUOSO_VOCABULARIES_PATH}/commons"
delete_rdf "${VIRTUOSO_VOCABULARIES_PATH}/commons"
cp -r "${KB_PATH}/vocabularies/commons" "${VIRTUOSO_VOCABULARIES_PATH}/"

# Load files
load "ontologies" "ontology"
load "commons" "commons"
load "thesaurus" "vocabulary"
load "vocabulary_aat" "vocabulary_aat"
