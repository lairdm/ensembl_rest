from django.db import models
from cassandra.cluster import Cluster
import cassandra
from .libs.serialize import xref_record

# Create your models here.

def cassandra_connect():

    cluster = Cluster(['127.0.0.1'], protocol_version=3)
    cluster.register_user_type('ensembl', 'xref_record', xref_record)
    session = cluster.connect('ensembl')
    session.row_factory = cassandra.query.ordered_dict_factory

    return session
