CREATE KEYSPACE Ensembl WITH replication = {'class': 'SimpleStrategy', 'replication_factor' : 1};
USE Ensembl;

CREATE TYPE Ensembl.xref_record (
  is_synonym boolean,
  primary_name text,
  primary_id text,
  description text,
  info_type text,
  info_text text,
  db_display_name text,
  dbname text,
  synonyms set<text>,
  stable_ids set<text>
);

CREATE TABLE Ensembl.xrefbyname (
  name text,
  species int,
  stable_ids map<text, text>,
  xrefs set<frozen <Ensembl.xref_record>>,
  PRIMARY KEY (name, species)
);

CREATE TYPE Ensembl.exon (
  start int,
  end int,
  id text,
  version int
);
//WITH comment='Base exon unit';

CREATE TYPE Ensembl.translation (
  start int,
  end int,
  id text,
  version int,
  length int
);
// WITH comment='Base translation unit';

CREATE TYPE Ensembl.transcript (
  start int,
  end int,
  id text,
  version int,
  biotype text,
  display_name text,
  is_canonical boolean,
  exons set<frozen <Ensembl.exon>>,
  translation frozen <Ensembl.translation>
);
// WITH comment='Base trascript unit';

CREATE TABLE Ensembl.molecules (
  id text,
  species int, // Use taxon id
  version int,
  start int,
  end int,
  seq_region_name text,
  strand int,
  db_type text,
  source text,
  logical_name text,
  description text,
  display_name text,
  assembly_name text,
  biotype text,
  transcripts set<frozen <Ensembl.transcript>>,
  PRIMARY KEY (species, id)
;
// WITH comment='Base unit for a physical molecule';

CREATE TABLE Ensembl.molecule_root (
  id text,
  species int,
  gene_id text,
  transcript_id text,
  PRIMARY KEY (species, id)
);
