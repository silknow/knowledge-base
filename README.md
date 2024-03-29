# SILKNOW Knowledge Base

This repository contains scripts to deploy the Knowledge Base for project SILKNOW.


## Initializing the Knowledge Base

This section covers the steps required to set up a new Knowlede Base for the first time.

1. Clone [D2KLab/docker-virtuoso](https://github.com/D2KLab/docker-virtuoso) repository.

    ```bash
    git clone https://github.com/D2KLab/docker-virtuoso.git
    cd docker-virtuoso
    ```

2. Build the docker image.

    ```bash
    docker build -t d2klab/virtuoso .
    ```

3. Run the docker image.

    **Note:** make sure to replace `/var/docker/virtuoso/silknow/data` with the volume path where you want the Virtuoso database to be stored. It is also the path which will be used to copy the RDF files you wish to load into the Knowledge Base.

    ```bash
    docker run --name silknow_virtuoso \
      -p 8890:8890 -p 1111:1111 \
      -e DBA_PASSWORD=myDbaPassword \
      -e SPARQL_UPDATE=true \
      -e VIRT_SPARQL_ResultSetMaxRows=-1 \
      -e VIRT_SPARQL_MaxQueryCostEstimationTime=-1 \
      -e VIRT_SPARQL_MaxQueryExecutionTime=-1 \
      -v /var/docker/virtuoso/silknow/data:/data \
      -d d2klab/virtuoso
    ```

## Loading data into the Knowledge base

1. Copy all your RDF files into the `dumps` folder inside the data directory (e.g., `/var/docker/virtuoso/silknow/data/dumps`).

    Directory structure example:

    - `/var/docker/virtuoso/silknow/data/dumps/`
      - `vocabularies/`
        - `aat/*.ttl`
        - `category/*.ttl`
        - `commons/*.ttl`
        - `observation/*.ttl`
        - `temp/*.ttl`
        - `vocabulary/*.ttl`
      - `museums/`
        - `garin/*.ttl`
          - `geonames/*.rdf`
        - `imatex/*.ttl`
          - `geonames/*.rdf`
        - `vam/*.ttl`
          - `geonames/*.rdf`
        - etc.

2. Run the following scripts to load the commons vocabularies, and/or the museum sources into the Knowledge Base.

### Commons

The script [load_commons.sh](scripts/load_commons.sh) will load the folders which have been placed inside the `vocabularies` directory (see Step 1.)

```bash
cd scripts
./load_commons.sh
```

### Dump

The script [load_dump.sh](scripts/load_dump.sh) will load a specific source (e.g., garin, vam, risd, ...) into the Knowledge Base, including:

* any .ttl file inside the source folder.
* any .rdf file inside the `geonames` directory in the source folder.

Examples:

```bash
cd scripts
./load_dump.sh imatex
./load_dump.sh mad
./load_dump.sh mfa
./load_dump.sh risd
./load_dump.sh unipa
./load_dump.sh cer
./load_dump.sh garin
./load_dump.sh joconde
./load_dump.sh met
./load_dump.sh mtmad
./load_dump.sh vam
```

## Removing a single museum or graph

When you want to remove a single museum / dataset or graph just run the following command and replace "museumname" accordingly:
```
docker exec -i silknow_virtuoso sh -c "isql-v -U dba -P \${DBA_PASSWORD} exec='sparql CLEAR SILENT GRAPH <http://data.silknow.org/graph/museumname>;'"
```


### Patches

The script [load_patches.sh](scripts/load_patches.sh) will load all execute all SPARQL queries files which have been placed inside the `patches` directory.

## List of RDF namespaces

These prefixes are commonly used on this project:

| Prefix | URI |
| - | - |
| aat | http://vocab.getty.edu/aat/
| crmdig | http://www.ics.forth.gr/isl/CRMext/CRMdig.rdfs/ |
| crmsci | http://www.ics.forth.gr/isl/CRMsci/ |
| ecrm | http://erlangen-crm.org/current/ |
| efrbroo | http://erlangen-crm.org/efrbroo/ |
| time | http://www.w3.org/2006/time# |
| schema | http://schema.org/ |
| silk | http://data.silknow.org/ontology/ |

They can be imported into Virtuoso through the isql interface:

```
DB.DBA.XML_SET_NS_DECL ('aat', 'http://vocab.getty.edu/aat/', 2);
DB.DBA.XML_SET_NS_DECL ('crmdig', 'http://www.ics.forth.gr/isl/CRMext/CRMdig.rdfs/', 2);
DB.DBA.XML_SET_NS_DECL ('crmsci', 'http://www.ics.forth.gr/isl/CRMsci/', 2);
DB.DBA.XML_SET_NS_DECL ('ecrm', 'http://erlangen-crm.org/current/', 2);
DB.DBA.XML_SET_NS_DECL ('efrbroo', 'http://erlangen-crm.org/efrbroo/', 2);
DB.DBA.XML_SET_NS_DECL ('time', 'http://www.w3.org/2006/time#', 2);
DB.DBA.XML_SET_NS_DECL ('silk', 'http://data.silknow.org/ontology/', 2);
```

## Dereferencing

The list of path to be dereferenced is in `dereferencing/config.yml`.

For exporting the apache config and the script for adding them to Virtuoso, run:

```
cd dereferencing
npx list2dereference config.yml
docker cp "insert_vhost.sql" "silknow_virtuoso:/insert_vhost.sql"
docker exec -i "silknow_virtuoso" sh -c "isql-v -U dba -P \${DBA_PASSWORD} < /insert_vhost.sql"
```

**Note:** the apache2 configuration file has to be manually updated on the server. Fortunately, list2dereference also generates a file which contains the rules of the new VirtualHost. Copy the new rules to the existing configuration file (default location: `/etc/apache2/sites-available/data.silknow.org.conf`), then reload apache2 (ie. with `service apache2 reload`).

Read more at https://github.com/pasqLisena/list2dereference

## URL Shortening

The service can be accessed at https://data.silknow.org/c/.

To install the URL shortening service, run the following commands:

```
cd scripts
docker cp "c_uri_dav.vad" "silknow_virtuoso:/usr/local/virtuoso-opensource/share/virtuoso/vad/c_uri_dav.vad"
docker exec -i "silknow_virtuoso" sh -c "isql-v -U dba -P \${DBA_PASSWORD} exec=\"DB.DBA.VAD_INSTALL('/usr/local/virtuoso-opensource/share/virtuoso/vad/c_uri_dav.vad');\""
```

The service is hosted on the route `/c`. You may have to update the apache2 Virtual Host configuration to map the route, for example:

```
<Location /c>
    ProxyPreserveHost On
    ProxyPass http://localhost:8890/c
    ProxyPassReverse http://localhost:8890/c
</Location>
```
