#!/usr/bin/env bash
# Rebuild the index from sources/ and vocabularies/, bring the engine back
# up, then apply patches/*.rq.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$ROOT"

[ -f .env ] || { echo "missing .env, copy .env.example and fill it in"; exit 1; }
set -a
. ./.env
set +a

MUSEUMS="artic cer el-tesoro europeana imatex joconde louvre mad met mfa mobilier mtmad musee-st-etienne paris-musees risd smithsonian unipa vam venezia versailles"
GEONAMES_MUSEUMS="artic cer imatex joconde louvre mad met mfa musee-st-etienne paris-musees risd smithsonian unipa vam venezia"

missing=0
for m in $MUSEUMS; do
  [ -d "sources/museums/$m" ] || { echo "missing sources/museums/$m"; missing=1; }
done
for m in $GEONAMES_MUSEUMS; do
  if [ ! -f "sources/geonames/$m-geonames.nt" ]; then
    echo "missing sources/geonames/$m-geonames.nt"
    missing=1
  fi
done
[ "$missing" -eq 0 ] || exit 1

QLEVER_FORCE_REBUILD="${QLEVER_FORCE_REBUILD:-1}" docker compose run --rm qlever-index
docker compose up -d --force-recreate qlever
docker compose up -d

echo "waiting for the engine healthcheck..."
until docker inspect silknow-qlever --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do
  sleep 5
done

port="${QLEVER_PORT:-8864}"
token="${QLEVER_ACCESS_TOKEN:-}"

echo "applying pipeline patches"
for patch in patches/*.rq; do
  echo "  $patch"
  response=$(curl -s --max-time 600 -X POST "http://127.0.0.1:$port/?access-token=$token" \
    -H "Content-Type: application/sparql-update" \
    --data-binary "@$patch") || response="curl failed"
  echo "${response:0:300}"
  echo
  if echo "$response" | grep -qiE "exception|error|invalid|denied"; then
    echo "PATCH FAILED: $patch"
    exit 1
  fi
done
