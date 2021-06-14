#!/usr/bin/env bash

set -o nounset

${DLD_DEV:=}
[[ ! -z "$DLD_DEV" ]] && set -x #conditional debug output

# Definition of the isql connection to Virtuoso
bin="isql-vt"
host=${VIRTUOSO_HOST}
port=${VIRTUOSO_PORT}
user=${VIRTUOSO_USER}
password=${VIRTUOSO_PASSWORD}

store_import_dir="/virtuoso/metadataimport"

# Wrap the execution of isql commands to receive the return code and output
run_virtuoso_cmd () {
    VIRT_OUTPUT=`echo "$1" | "$bin" -H "$host" -S "$port" -U "$user" -P "$password" 2>&1`
    VIRT_RETCODE=$?
    if [[ $VIRT_RETCODE -eq 0 ]]; then
        echo "$VIRT_OUTPUT" | tail -n+5 | perl -pe 's|^SQL> ||g'
        return 0
    else
        echo -e "[ERROR] running the these commands in virtuoso:\n$1\nerror code: $VIRT_RETCODE\noutput:"
        echo "$VIRT_OUTPUT"
        let 'ret = VIRT_RETCODE + 128'
        return $ret
    fi
}

# Check if the virtuoso is up and running
# This is needed during the bootstrapping process in a docker setup
test_connection () {
    if [[ -z $1 ]]; then
        echo "[ERROR] missing argument: retry attempts"
        exit 1
    fi

    t=$1

    run_virtuoso_cmd 'status();'
    while [[ $? -ne 0 ]] ;
    do
        echo -n "."
        sleep 2
        echo $t
        let "t=$t-1"
        if [ $t -eq 0 ]
        then
            echo "timeout"
            return 2
        fi
        run_virtuoso_cmd 'status();'
    done
}

cd "$store_import_dir"

echo "[INFO] waiting for store to come online"

: ${CONNECTION_ATTEMPTS:=60}
test_connection "${CONNECTION_ATTEMPTS}"
if [ $? -eq 2 ]; then
    echo "[ERROR] store not reachable"
    exit 1
fi

# Give some more seconds to the virtuoso to really accept updates
sleep 3

echo "[INFO] initializing named graph"
run_virtuoso_cmd "sparql CREATE SILENT GRAPH <${GRAPH}>;"
echo "Created graph: $GRAPH"

#ensure that all supported formats get into the load list
#(since we have to excluse graph-files *.* won't do the trick
echo "[INFO] registring RDF documents for import"
for ext in nt nq owl rdf ttl xml; do
    # documentation: # http://docs.openlinksw.com/virtuoso/fn_ld_dir/

    lines=`ls -hal *.$ext | grep $ext | wc -l`
    lines=$(($lines + 1))
    if [ $lines -gt 1 ]; then
        echo "[INFO] now loading the following files: $(ls -hal *.$ext)"

        run_virtuoso_cmd "ld_dir ('${store_import_dir}', '*.${ext}', '$GRAPH');"
    fi
done

echo "[INFO] deactivating auto-indexing"
run_virtuoso_cmd "DB.DBA.VT_BATCH_UPDATE ('DB.DBA.RDF_OBJ', 'ON', NULL);"

echo '[INFO] Starting load process...';

# Bulk-loading: http://vos.openlinksw.com/owiki/wiki/VOS/VirtBulkRDFLoader

load_cmds=`cat <<EOF
log_enable(2);
checkpoint_interval(-1);
set isolation = 'uncommitted';
rdf_loader_run();
log_enable(1);
checkpoint_interval(60);
EOF`
run_virtuoso_cmd "$load_cmds";

echo "[INFO] making checkpoint..."
run_virtuoso_cmd 'checkpoint;'

echo "[INFO] re-activating auto-indexing"
run_virtuoso_cmd "DB.DBA.RDF_OBJ_FT_RULE_ADD (null, null, 'All');"
run_virtuoso_cmd 'DB.DBA.VT_INC_INDEX_DB_DBA_RDF_OBJ ();'

echo "[INFO] making checkpoint..."
run_virtuoso_cmd 'checkpoint;'

echo "[INFO] update/filling of geo index"
run_virtuoso_cmd 'rdf_geo_fill();'

echo "[INFO] making checkpoint..."
run_virtuoso_cmd 'checkpoint;'

echo "[INFO] bulk load done; terminating loader"
