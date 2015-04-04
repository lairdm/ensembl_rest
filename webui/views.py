from django.http import HttpResponse
from django.shortcuts import render
from cassandra.cluster import Cluster
import cassandra
from .libs.serialize import default_serialize, xref_record, serialize_stableids
from .libs.taxon import find_taxon
import json
import pprint

cluster = Cluster(['127.0.0.1'], protocol_version=3)
cluster.register_user_type('ensembl', 'xref_record', xref_record)
session = cluster.connect('ensembl')
session.row_factory = cassandra.query.ordered_dict_factory

def showapi(request):

    return

def symbolbyname(request, symbol, species=None):

    filter = {'name': symbol}
    query = "SELECT name, species, xrefs FROM xrefbyname WHERE name = %(name)s"
    if species:
        filter['species'] = find_taxon(species)
        query += " AND species = %(species)s"
    
    rows = session.execute(query, filter)

    rowset = []
    if species and rows:
        rowset = rows[0]
    else:
        for r in rows:
            rowset.append(r)

    data = json.dumps(rowset, indent=4, sort_keys=False, default=default_serialize)

    return HttpResponse(data, content_type="application/json")

def idbysymbol(request, symbol, species=None):

    filter = {'name': symbol}
    query = "SELECT name, species, stable_ids FROM xrefbyname WHERE name = %(name)s"
    if species:
        filter['species'] = find_taxon(species)
        query += " AND species = %(species)s"
    
    rows = session.execute(query, filter)

    rowset = []
    if species and rows:
        rowset = serialize_stableids(rows[0])
    else:
        for r in rows:
            rowset.append(serialize_stableids(r))

    data = json.dumps(rowset, indent=4, sort_keys=False, default=default_serialize)

    return HttpResponse(data, content_type="application/json")
