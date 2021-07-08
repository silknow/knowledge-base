#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Constants
SILKNOW_PATH=${SILKNOW_PATH:-"/home/semantic/silknow"}
CONVERTER_PATH=${CONVERTER_PATH:-"${SILKNOW_PATH}/converter"}

# Load prefixes
echo "Loading prefixes..."
(cd "${SCRIPTPATH}" && ./load_prefixes.sh)

# Load commons
echo "Loading commons..."
(cd "${SCRIPTPATH}" && ./load_commons.sh)

# Load museum dumps
for f in "${CONVERTER_PATH}/output/"*.tar.gz; do
  base=$(basename "${f%.tar.gz}")
  echo "Loading dumps for ${base}..."
  (cd "${SCRIPTPATH}" && ./load_dump.sh "${base}")
done

# Load patches
echo "Loading patches..."
(cd "${SCRIPTPATH}" && ./load_patches.sh)
