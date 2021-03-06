import argparse
import logging
import objectstore
import os
from various_small_datasets.generic.source import OBJECTSTORE

log = logging.getLogger(__name__)


def get_objectstore_file(location, dir1):
    path = "/".join(location.split("/")[1:])
    output_path = dir1 + '/' + path
    if os.path.isfile(output_path):
        log.warning(f"File {output_path} exists. Skip download")
        return
    else:
        log.warning(f"Get file {output_path}")
    connection = objectstore.get_connection(OBJECTSTORE)
    container = location.split("/")[0]
    new_data = objectstore.get_object(connection, {'name': path}, container)
    with open(output_path, 'wb') as file:
        file.write(new_data)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('filename')
    args = parser.parse_args()
    tmpdir = os.getenv('TMPDIR', '/tmp/')
    get_objectstore_file(args.filename, tmpdir)
