#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Constants
SILKNOW_PATH=${SILKNOW_PATH:-"/home/semantic/silknow"}
KB_PATH=${KB_PATH:-"${SILKNOW_PATH}/knowledge-base"}
CONVERTER_PATH=${CONVERTER_PATH:-"${SILKNOW_PATH}/converter"}
THESAURUS_PATH=${THESAURUS_PATH:-"${SILKNOW_PATH}/thesaurus"}
VIRTUOSO_DUMPS_PATH=${VIRTUOSO_DUMPS_PATH:-"/var/docker/virtuoso/silknow/data/dumps"}
VIRTUOSO_VOCABULARIES_PATH=${VIRTUOSO_VOCABULARIES_PATH:-"${VIRTUOSO_DUMPS_PATH}/vocabularies"}
VIRTUOSO_MUSEUMS_PATH=${VIRTUOSO_MUSEUMS_PATH:-"${VIRTUOSO_DUMPS_PATH}/museums"}
CONTAINER_NAME=${CONTAINER_NAME:-"silknow_virtuoso"}
LOG_FILE=${LOG_FILE:-"load_dump.log"}

# $1 = path to directory which contains RDF files
delete_rdf() {
  find "$1" -name "*.rdf" -type f -delete
  find "$1" -name "*.rdfs" -type f -delete
  find "$1" -name "*.ttl" -type f -delete
  find "$1" -name "*.n3" -type f -delete
}

# Parameters
name="${1}" # Graph name (e.g., "garin")
if [[ ! "${name}" ]]; then
  echo "Please enter a name (eg. garin, mfa-boston, risd-museum, vam, ...)"
  exit 1
fi
echo "Dump name: ${name}"

# Get container ID
containerId=$(docker ps -aqf "name=^${CONTAINER_NAME}$")
if [[ ! "${containerId}" ]]; then
  echo "${CONTAINER_NAME}: Container not found"
  exit 1
fi
echo "Docker container ID: ${containerId}"

# Copy new files from converter
cd "${CONVERTER_PATH}/output" || exit 1
git pull --rebase
echo "Removing previous RDF files in ${VIRTUOSO_MUSEUMS_PATH}/${name}/"
delete_rdf "${VIRTUOSO_MUSEUMS_PATH}/${name}/"
echo "Extracting ${name}.tar.gz into ${VIRTUOSO_MUSEUMS_PATH}/"
mkdir -p "${VIRTUOSO_MUSEUMS_PATH}"
tar -C "${VIRTUOSO_MUSEUMS_PATH}/" -zxf "${name}.tar.gz"

# Create SQL file
temp_file=$(mktemp)
touch "${temp_file}"
echo "Created temp file: ${temp_file}"

echo "DELETE FROM DB.DBA.load_list;" >> "${temp_file}"
echo "SPARQL CLEAR GRAPH <http://data.silknow.org/graph/${name}>;" >> "${temp_file}"
echo "ld_dir('dumps/museums/${name}/geonames', '*.rdf', 'http://data.silknow.org/graph/${name}');" >> "${temp_file}"
echo "ld_dir('dumps/museums/${name}/timespan', '*.ttl', 'http://data.silknow.org/graph/${name}');" >> "${temp_file}"
echo "ld_dir('dumps/museums/${name}/', '*.ttl', 'http://data.silknow.org/graph/${name}');" >> "${temp_file}"
echo "rdf_loader_run();" >> "${temp_file}"
echo "cl_exec('checkpoint');" >> "${temp_file}"
echo "DB.DBA.VT_INC_INDEX_DB_DBA_RDF_OBJ ();" >> "${temp_file}"
echo "SELECT * FROM DB.DBA.load_list WHERE ll_error IS NOT NULL;" >> "${temp_file}"
echo "DELETE FROM DB.DBA.load_list;" >> "${temp_file}"

# Copy SQL file to container
echo "Copying SQL file to the Docker container"
docker cp "${temp_file}" "${containerId}:/load_dump.sql"

# Execute SQL file
echo "Executing SQL file through isql-v inside the Docker container"
docker exec -i "${containerId}" sh -c "isql-v -U dba -P \${DBA_PASSWORD} < /load_dump.sql" &>> "${LOG_FILE}"
echo "Query output saved to ${LOG_FILE}"

# Cleanup
echo "Removing temp file: ${temp_file}"
rm "${temp_file}"

# Load patches
(cd "${SCRIPTPATH}" && ./load_patches.sh)
