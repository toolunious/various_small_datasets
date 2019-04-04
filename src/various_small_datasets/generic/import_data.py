import logging
from datetime import datetime

from django.contrib.gis.geos import GEOSGeometry

from various_small_datasets.generic.catalog import get_model_def, get_import_def, get_source_def
from various_small_datasets.generic.check import check_import
from various_small_datasets.generic.db import create_new_datatable, roll_over_datatable
from various_small_datasets.generic.model import get_django_model
from various_small_datasets.generic.source import get_source

log = logging.getLogger(__name__)


class JSONImporter(object):
    def __init__(self, import_def, model_def):
        self.import_def = import_def
        self.model_def = model_def

    def import_data(self, source):
        model = get_django_model(self.import_def['target'], self.model_def, new_table=True)
        for entry in source:
            fields = {}
            for mapping in self.import_def['mapping']['mappings']:
                source = self._get_source(entry, mapping['source'])
                if 'transform' in mapping:
                    source = self._transform(mapping['transform'], source)
                fields[mapping['target']] = source

            model(**fields).save()

    @staticmethod
    def _get_source(entity, path):
        def _recurse_dict(sub_dict, path):
            if len(path) == 1:
                return sub_dict.get(path[0], None)
            else:
                return _recurse_dict(sub_dict.get(path[0], None), path[1:])

        return _recurse_dict(entity, path.split('.'))

    @staticmethod
    def _transform(transform_def, source):
        if transform_def['type'] in ["time_from_string", "date_from_string"]:
            if source is None:
                return None
            date = datetime.strptime(source, transform_def['properties']['pattern'])
            if transform_def['type'] == "time_from_string":
                return str(date.time())
            return date
        elif transform_def['type'] == 'geometry_from_geojson':
            return GEOSGeometry(str(source))
        else:
            raise NotImplementedError


class GeoJSONImporter(JSONImporter):
    def import_data(self, source):
        super().import_data(source['features'])


def do_import(dataset_name):
    model_def = get_model_def(dataset_name)
    import_def = get_import_def(dataset_name)
    source_def = get_source_def(dataset_name)

    create_new_datatable(import_def['target'], model_def)

    source = get_source(source_def)

    if source_def['type'] == "GeoJSON":
        importer = GeoJSONImporter(import_def, model_def)
    elif import_def['type'] == "JSON":
        importer = JSONImporter(import_def, model_def)
    else:
        raise NotImplementedError

    importer.import_data(source)

    check_import(import_def, model_def)

    roll_over_datatable(import_def['target'], model_def)
