#!/bin/bash

# Constants
CONTAINER_NAME=${CONTAINER_NAME:-"silknow_virtuoso"}
LOG_FILE=${LOG_FILE:-"load_dump.log"}

# Parameters
name="${1}" # Graph name (e.g., "garin")
if [[ ! "${name}" ]]; then
  echo "Please enter a name (eg. garin, mfa-boston, risd-museum, vam, ...)"
  exit 1
fi
echo "Dump name: ${name}"

containerId=$(docker ps -aqf "name=${CONTAINER_NAME}")
if [[ ! "${containerId}" ]]; then
  echo "${CONTAINER_NAME}: Container not found"
  exit 1
fi
echo "Docker container ID: ${containerId}"

temp_file=$(mktemp)
touch "${temp_file}"
echo "Created temp file: ${temp_file}"

echo "DELETE FROM DB.DBA.load_list;" >> "${temp_file}"
echo "SPARQL CLEAR GRAPH <http://data.silknow.org/${name}>;" >> "${temp_file}"
echo "ld_dir('dumps/museums/${name}/geonames', '*.rdf', 'http://data.silknow.org/${name}');" >> "${temp_file}"
echo "ld_dir('dumps/museums/${name}/', '*.ttl', 'http://data.silknow.org/${name}');" >> "${temp_file}"
echo "rdf_loader_run();" >> "${temp_file}"
echo "cl_exec('checkpoint');" >> "${temp_file}"
echo "DELETE FROM DB.DBA.load_list;" >> "${temp_file}"

echo "Copying SQL file to the Docker container"
docker cp "${temp_file}" "${containerId}:/load_dump.sql"

echo "Executing SQL file through isql-v inside the Docker container"
docker exec -i "${containerId}" sh -c "isql-v -U dba -P \${DBA_PASSWORD} < /load_dump.sql" &>> "${LOG_FILE}"
echo "Query output saved to ${LOG_FILE}"

echo "Removing temp file: ${temp_file}"
rm "${temp_file}"
