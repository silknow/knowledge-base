#!/bin/bash

SILKNOW_PATH=${SILKNOW_PATH:-"/home/semantic/silknow"}
CONVERTER_PATH=${CONVERTER_PATH:-"${SILKNOW_PATH}/converter"}

# Load commons
echo "Loading commons..."
. ./load_commons.sh

# Load museum dumps
for f in "${CONVERTER_PATH}/output/"*.tar.gz; do
  base=$(basename "${f%.tar.gz}")
  echo "Loading dumps for ${base}..."
  . ./load_dump.sh "${base}"
done
