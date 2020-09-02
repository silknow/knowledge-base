#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

SILKNOW_PATH=${SILKNOW_PATH:-"/home/semantic/silknow"}
CONVERTER_PATH=${CONVERTER_PATH:-"${SILKNOW_PATH}/converter"}
CONTAINER_NAME=${CONTAINER_NAME:-"silknow_virtuoso"}

# Load prefixes
docker cp "${SCRIPTPATH}/prefixes.sql" "${CONTAINER_NAME}:/prefixes.sql"
docker exec -i "${CONTAINER_NAME}" sh -c "isql-v -U dba -P \${DBA_PASSWORD} < /prefixes.sql"

# Load commons
echo "Loading commons..."
(cd "${SCRIPTPATH}" && ./load_commons.sh)

# Load museum dumps
for f in "${CONVERTER_PATH}/output/"*.tar.gz; do
  base=$(basename "${f%.tar.gz}")
  echo "Loading dumps for ${base}..."
  (cd "${SCRIPTPATH}" && ./load_dump.sh "${base}")
done
