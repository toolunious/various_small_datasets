#!/usr/bin/env bash

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export SHARED_DIR=${SCRIPT_DIR}/../../shared

source ${SHARED_DIR}/import/config.sh
source ${SHARED_DIR}/import/before.sh

MAX_INSERTS=${MAX_INSERTS:-100}
DO_DELETE=${DO_DELETE:-false}
while test $# -gt 0
do
    case "$1" in
        --delete)
            DO_DELETE=true
            ;;
        --max_inserts)
            MAX_INSERTS=$2
            shift
            ;;
        *) echo "argument $1"
            ;;
    esac
    shift
done

echo "Check if oplaadpalen exists"
TABLE_EXISTS=$(psql -Xt <<SQL
SELECT EXISTS (
   SELECT 1
   FROM   information_schema.tables
   WHERE  table_schema = 'public'
   AND    table_name = 'oplaadpalen'
   );
SQL
)

TABLE_EXISTS=${TABLE_EXISTS//[[:blank:]]/}
echo "TABLE_EXISTS:${TABLE_EXISTS} DO_DELETE:${DO_DELETE}"

if [[ ${DO_DELETE} = true ]] || [[ ${TABLE_EXISTS} = 'f' ]];
  then
    echo "Delete and recreate table"
    psql -X --set ON_ERROR_STOP=on <<SQL
\i ${SCRIPT_DIR}/oplaadpalen_create.sql
SQL
  else
    echo "Copy table"
    psql -X --set ON_ERROR_STOP=on <<SQL
\i ${SCRIPT_DIR}/oplaadpalen_copy.sql
SQL
fi

echo "Import and update data"
PYTHONPATH=${SCRIPT_DIR}/../.. python ${SCRIPT_DIR}/import_oplaadpalen_allego.py --max_inserts=${MAX_INSERTS}

PYTHONPATH=${SCRIPT_DIR}/../.. ${SCRIPT_DIR}/check_imported_data.py

echo "Rename tables"
psql -X --set ON_ERROR_STOP=on <<SQL
BEGIN;
ALTER TABLE IF EXISTS oplaadpalen RENAME TO oplaadpalen_old;
ALTER TABLE oplaadpalen_new RENAME TO oplaadpalen;
DROP TABLE IF EXISTS oplaadpalen_old;
COMMIT;
SQL

source ${SHARED_DIR}/import/after.sh