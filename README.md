# SILKNOW Knowledge Graph

This repository contains the RDF sources, vocabularies, QLever configuration,
and patches used to deploy the knowledge graph at <https://data.silknow.org>.
The graph describes European silk heritage objects from the 15th to the 19th
century in CIDOC-CRM (ecrm). The
[silknow/converter](https://github.com/silknow/converter) converts the museum
collection records into ecrm and adds vocabulary alignments and property
predictions.

[QLever](https://github.com/ad-freiburg/qlever) serves SPARQL queries and RDF
dereferencing. [RDF Workbench](https://github.com/ehrhart/rdf-workbench)
provides the web interface.

- SPARQL endpoint and query console: <https://data.silknow.org/sparql>
- Resource dereferencing: `https://data.silknow.org/<path>/<id>`
- Explorer: <https://ada.silknow.org/>
- Thesaurus browser: <https://skosmos.silknow.org/>

## Graphs

| graph | source |
| - | - |
| `http://data.silknow.org/graph/<museum>` | `sources/museums/<museum>/*.ttl` and `sources/museums/<museum>/*/*.ttl` |
| `http://data.silknow.org/graph/<museum>` (geonames) | `sources/geonames/<museum>-geonames.nt` |
| `http://data.silknow.org/predictions` | `vocabularies/predictions/*.ttl.gz` |
| `http://data.silknow.org/aat` | `vocabularies/aat/*.ttl` |
| `http://data.silknow.org/vocabulary` | `vocabularies/vocabulary/*.ttl` |
| `http://data.silknow.org/commons` | `vocabularies/commons/*.nt` |
| `http://data.silknow.org/category` | `vocabularies/category/*.ttl` |
| `http://data.silknow.org/ontology` | `vocabularies/ontology/*.ttl` |
| `http://data.silknow.org/assignment` | `vocabularies/assignment/*.ttl` |
| `http://data.silknow.org/dimension` | `vocabularies/dimension/*.ttl` |
| `http://data.silknow.org/observation` | `vocabularies/observation/*.ttl` |

Museums: `artic`, `cer`, `el-tesoro`, `europeana`, `imatex`, `joconde`,
`louvre`, `mad`, `met`, `mfa`, `mobilier`, `mtmad`, `musee-st-etienne`,
`paris-musees`, `risd`, `smithsonian`, `unipa`, `vam`, `venezia`,
`versailles`.

The SPARQL UPDATEs in `patches/` run after every index build. `01` constructs
labels for objects whose source carries none. `02` removes europeana records
that duplicate a museum record.

## Dereferencing

The `DEREFERENCE_PATHS` variable in `.env` lists the IRI path prefixes that
the workbench serves as HTML and as RDF:

| path | example |
| - | - |
| activity | `http://data.silknow.org/activity/designer` |
| actor | `http://data.silknow.org/actor/SILKNOW` |
| assessment | `http://data.silknow.org/assessment/c25143ac-5a86-3b80-8586-4541c060b42c` |
| assignment | |
| category | `http://data.silknow.org/category/25` |
| collection | `http://data.silknow.org/collection/4153c6b7-fe05-3202-ae6f-153f33b2283f` |
| dimension | `http://data.silknow.org/dimension/width` |
| event | `http://data.silknow.org/event/0cc00b89-05da-3bc6-98c6-f72e75d32453` |
| image | `http://data.silknow.org/image/15f57b81-ac41-38d7-a365-6566796ad6ad` |
| inscription | `http://data.silknow.org/inscription/895bc1c3-c33d-3047-9cb6-4243f62b83ad` |
| object | `http://data.silknow.org/object/1bbc9317-de8f-3fc4-921b-d5c4e6d1ab86` |
| ontology | `http://data.silknow.org/ontology/T10` |
| organization | `http://data.silknow.org/organization/unipa` |
| place | `http://data.silknow.org/place/92ffc1ec-baa4-3fb1-babe-daf1fdbc038a` |
| production | `http://data.silknow.org/production/7b80de21-2112-3972-a53a-e56319ba46a2` |
| statement | `http://data.silknow.org/statement/74d5e4ac-6197-5a26-85b8-c724e4d21cc8` |
| timespan | `http://data.silknow.org/timespan/periods` |
| vocabulary | `http://data.silknow.org/vocabulary/facet` |

## Deploy

1. Copy `.env.example` to `.env` and set `QLEVER_ACCESS_TOKEN` (generate one
   with `openssl rand -hex 24`) and `WORKBENCH_ADMIN_PASSWORD`. Protect the
   file with `chmod 600 .env`.

2. Run `docker compose up -d`. On a fresh volume the first start builds the
   index and blocks until it finishes.

3. Run `bash qlever/deploy.sh` to force-rebuild the index and apply
   `patches/`.

## Data refresh

The index inputs live under `sources/` and `vocabularies/`. Edit them, commit,
and run `bash qlever/deploy.sh` to rebuild.
