from blist import sortedset
import pprint

def default_serialize(obj):

    if isinstance(obj, sortedset):
        serial = list(obj)
        return serial

    if isinstance(obj, xref_record):
        return obj.to_json()

def serialize_stableids(obj):

    json_obj = {'name': obj['name'],
                'species': obj['species']
                }

    json_obj['ids'] = []
    for id in obj['stable_ids']:
        json_obj['ids'].append({'id': id, 'type': 'gene'})

    return json_obj

class xref_record(object):
    elements = []

    def __init__(self, *args, **kwargs):

        for a in kwargs:
            setattr(self,a,kwargs[a])
            self.elements.append(a)

    def to_json(self):

        json_obj = {}

        for e in self.elements:
            if e == 'is_synonym' and not getattr(self, e):
                json_obj[e] = False
                continue
            json_obj[e] = getattr(self, e) if getattr(self, e) else ""

        return json_obj
