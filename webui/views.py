from django.http import HttpResponse
from django.shortcuts import render
from cassandra.cluster import Cluster
from django.template import RequestContext
from django.shortcuts import render
import cassandra
from models import find_parent_gene, lookup_xrefs, lookup_molecules
from .libs.serialize import default_serialize, serialize_stableids
from .libs.taxon import find_molecule_type, find_transcript_rec, find_exon_rec
import json
import pprint

def showapi(request):
    return render(request, 'index.html')


def symbolbyname(request, symbol, species=None):

    kwargs = {'cols': ['name', 'species', 'xrefs']}
    if species:
        kwargs['species'] = species

    rows = lookup_xrefs(symbol, **kwargs)

    rowset = []
    if species and rows:
        rowset = rows[0]
    elif rows:
        for r in rows:
            rowset.append(r)

    data = json.dumps(rowset, indent=4, sort_keys=False, default=default_serialize)

    return HttpResponse(data, content_type="application/json")

def idbysymbol(request, symbol, species=None):

    kwargs = {'cols': ['name', 'species', 'stable_ids']}
    if species:
        kwargs['species'] = species

    rows = lookup_xrefs(symbol, **kwargs)

    rowset = []
    if species and rows:
        rowset = serialize_stableids(rows[0])
    else:
        for r in rows:
            rowset.append(serialize_stableids(r))

    data = json.dumps(rowset, indent=4, sort_keys=False, default=default_serialize)

    return HttpResponse(data, content_type="application/json")

def moleculebyid(request, id):

    m_type = find_molecule_type(id)

    if m_type != u'G':
        m_path = find_parent_gene(id)

        if m_path:
            gene_id = m_path['gene']
        else:
            gene_id = None
    else:
        gene_id = id

    if gene_id:
        rows = lookup_molecules(gene_id)
    else:
        rows = []

    data = []

    if rows:
        if m_type == u'G':
            data = rows
            # If it's not a gene we know we need to at least
            # go to the transcript level
        elif m_type == u'T':
            data = find_transcript_rec(rows[0], id)
        elif m_type == u'E':
            data = find_exon_rec(rows[0], id, m_path)
    
    data = json.dumps(data, indent=4, sort_keys=False, default=default_serialize)

    return HttpResponse(data, content_type="application/json")
