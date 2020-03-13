#!/bin/bash

CWD="${PWD}"
SILKNOW_PATH=${SILKNOW_PATH:-"/home/semantic/silknow"}
KB_PATH=${KB_PATH:-"${SILKNOW_PATH}/knowledge-base"}
CONVERTER_PATH=${CONVERTER_PATH:-"${SILKNOW_PATH}/converter"}
THESAURUS_PATH=${THESAURUS_PATH:-"${SILKNOW_PATH}/thesaurus"}
VIRTUOSO_DUMPS_PATH=${VIRTUOSO_DUMPS_PATH:-"/var/docker/virtuoso/silknow/data/dumps"}
VIRTUOSO_VOCABULARIES_PATH=${VIRTUOSO_VOCABULARIES_PATH:-"${VIRTUOSO_VOCABULARIES_PATH}/vocabularies"}
VIRTUOSO_MUSEUMS_PATH=${VIRTUOSO_MUSEUMS_PATH:-"${VIRTUOSO_DUMPS_PATH}/museums"}

# $1 = path to directory which contains RDF files
delete_rdf() {
  find "$1" -name "*.rdf" -type f -delete
  find "$1" -name "*.rdfs" -type f -delete
  find "$1" -name "*.ttl" -type f -delete
  find "$1" -name "*.n3" -type f -delete
}

# Copy new files from converter
cd "${CONVERTER_PATH}/output" || exit 1
git pull --rebase
for f in ./*.tar.gz; do
  base=$(basename "${f%.tar.gz}")
  echo "Removing previous RDF files in ${VIRTUOSO_MUSEUMS_PATH}/${base}/"
  delete_rdf "${VIRTUOSO_MUSEUMS_PATH}/${base}/"
  echo "Extracting ${f} into ${VIRTUOSO_MUSEUMS_PATH}/"
  tar -C "${VIRTUOSO_MUSEUMS_PATH}/" -zxvf "${f}"
done

# Copy files from thesaurus
cd "${THESAURUS_PATH}" || exit 1
git pull --rebase
mkdir -p "${VIRTUOSO_VOCABULARIES_PATH}/thesaurus"
cp "thesaurus.ttl" "${VIRTUOSO_VOCABULARIES_PATH}/thesaurus/"

# Update knowledge-base
cd "${KB_PATH}" || exit 1
git pull --rebase

# Copy files from ontologies
mkdir -p "${VIRTUOSO_VOCABULARIES_PATH}/ontologies"
delete_rdf "${VIRTUOSO_VOCABULARIES_PATH}/ontologies"
cp -r "${KB_PATH}/vocabularies/ontologies" "${VIRTUOSO_VOCABULARIES_PATH}/"

# Copy files from vocabulary_aat
mkdir -p "${VIRTUOSO_VOCABULARIES_PATH}/vocabulary_aat"
delete_rdf "${VIRTUOSO_VOCABULARIES_PATH}/vocabulary_aat"
cp -r "${KB_PATH}/vocabularies/vocabulary_aat" "${VIRTUOSO_VOCABULARIES_PATH}/"

# Copy new files from commons
mkdir -p "${VIRTUOSO_VOCABULARIES_PATH}/commons"
delete_rdf "${VIRTUOSO_VOCABULARIES_PATH}/commons"
cp -r "${KB_PATH}/vocabularies/commons" "${VIRTUOSO_VOCABULARIES_PATH}/"

# Go back to script directory
cd "${CWD}" || exit 1

# Load commons
. ./load_commons.sh

# Load museum dumps
for f in "${CONVERTER_PATH}/output/"*.tar.gz; do
  base=$(basename "${f%.tar.gz}")
  . ./load_dump.sh "${base}"
done