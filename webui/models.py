from django.db import models
from cassandra.cluster import Cluster
import cassandra
from .libs.serialize import xref_record, base_udt
from .libs.taxon import find_taxon

# Create your models here.

def cassandra_connect():

#    cluster = Cluster(['192.168.1.7'], protocol_version=3)
    cluster = Cluster(['127.0.0.1'], protocol_version=3)
    cluster.register_user_type('ensembl', 'xref_record', xref_record)
    cluster.register_user_type('ensembl', 'exon', base_udt)
    cluster.register_user_type('ensembl', 'translation', base_udt)
    cluster.register_user_type('ensembl', 'transcript', base_udt)
    session = cluster.connect('ensembl')
    session.row_factory = cassandra.query.ordered_dict_factory

    return session

def lookup_xrefs(symbol, *args, **kwargs):

    session = cassandra_connect()

    filter = {'name': symbol}
    if 'cols' in kwargs:
        col_str = ','.join(kwargs['cols'])
    else:
        col_str = '*'

    query = "SELECT " + col_str + " FROM xrefbyname WHERE name = %(name)s"
    if 'species' in kwargs:
        print "species: " + kwargs['species']
        filter['species'] = find_taxon(kwargs['species'])
        query += " AND species = %(species)s"

    rows = session.execute(query, filter)

    return rows

def lookup_molecules(id, *args, **kwargs):

    session = cassandra_connect()

    filter = {'id': id}
    if 'cols' in kwargs:
        col_str = ','.join(cols)
    else:
        col_str = '*'

    query = "SELECT " + col_str + " FROM molecules WHERE species = 9606 AND id = %(id)s"

    rows = session.execute(query, filter)

    return rows


def find_parent_gene(id):

    session = cassandra_connect()

    filter = {'id': id}
    query = "SELECT * from molecule_root WHERE id = %(id)s AND species = 9606"

    rows = session.execute(query, filter)

    # Yes I know, just grabbing row zero, horrible
    # this is just a proof of concept with serious
    # breakage potential
    if rows:
        return {'gene': rows[0]['gene_id'],
                'transcript': rows[0]['transcript_id'] }

    return None
