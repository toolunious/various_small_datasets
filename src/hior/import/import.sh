#!/usr/bin/env bash

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export SHARED_DIR=${SCRIPT_DIR}/../../shared

source ${SHARED_DIR}/import/config.sh
source ${SHARED_DIR}/import/before.sh

echo "Process import data"
python ${SCRIPT_DIR}/import.py "${DATA_DIR}/HIOR Amsterdam.xls" ${TMPDIR}

echo "Create tables"
psql -X --set ON_ERROR_STOP=on << SQL
\i ${SCRIPT_DIR}/hior_data_create.sql
SQL

echo "Import data"
psql -X --set ON_ERROR_STOP=on <<SQL
\i ${TMPDIR}/hior_items_new.sql
\i ${TMPDIR}/hior_properties_new.sql
SQL

echo "Rename tables"
psql -X --set ON_ERROR_STOP=on <<SQL
BEGIN;
ALTER TABLE IF EXISTS hior_items RENAME TO hior_items_old;
ALTER TABLE IF EXISTS hior_properties RENAME TO hior_properties_old;
ALTER TABLE hior_items_new RENAME TO hior_items;
ALTER TABLE hior_properties_new RENAME TO hior_properties;
DROP TABLE IF EXISTS hior_items_old CASCADE;
DROP TABLE IF EXISTS hior_properties_old CASCADE;
COMMIT;
SQL

source ${SHARED_DIR}/import/after.sh