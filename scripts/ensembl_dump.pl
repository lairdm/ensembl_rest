#!/usr/bin/perl

use strict;

use DBI;
use Cwd qw(abs_path getcwd);
use Getopt::Long;
use Data::Dumper;

BEGIN{
# Find absolute path of script
my ($path) = abs_path($0) =~ /^(.+)\//;
chdir($path);
sub mypath { return $path; }
};

my $taxon = 9606;

my $dbh = DBI->connect("DBI:mysql:database=homo_sapiens_core_79_38;host=localhost",
			   'root',
			   'password');
die "Error: Unable to connect to the database: $DBI::errstr\n" if ! $dbh;

$dbh->{mysql_auto_reconnect} = 1;

my $fetch_genes = $dbh->prepare("SELECT gene_id, biotype, gene.analysis_id, analysis.logic_name, seq_region.name, seq_region_start, seq_region_end, seq_region_strand, xref.display_label, source, status, gene.description, canonical_transcript_id, stable_id, gene.version FROM gene, analysis, xref, seq_region WHERE gene.seq_region_id = seq_region.seq_region_id AND gene.analysis_id = analysis.analysis_id AND gene.display_xref_id = xref.xref_id AND is_current = 1"); # AND gene_id = 10260026");

my $fetch_transcript = $dbh->prepare("SELECT transcript_id, transcript.analysis_id, analysis.logic_name, seq_region_start, seq_region_end, xref.display_label, biotype, transcript.description, canonical_translation_id, stable_id, transcript.version FROM transcript, analysis, xref WHERE transcript.analysis_id = analysis.analysis_id AND transcript.display_xref_id = xref.xref_id AND gene_id = ?");

my $fetch_translation = $dbh->prepare("SELECT translation_id, seq_start, seq_end, stable_id, version FROM translation WHERE transcript_id = ?");

my $fetch_exon = $dbh->prepare("SELECT exon.exon_id, seq_region_start, seq_region_end, stable_id, exon.version FROM exon, exon_transcript WHERE exon.exon_id = exon_transcript.exon_id AND exon_transcript.transcript_id = ?");

$fetch_genes->execute();

# Fetch all the genes
while(my @row = $fetch_genes->fetchrow_array()) {
#    print join(',', @row) . "\n";

    my $desc = $row[11];
$desc =~ s|'|''|g;
$desc =~ s|/|\\/|g;

my $insert = "INSERT INTO Ensembl.molecules (id, species, version, start, end, seq_region_name, strand, db_type, source, logical_name, description, display_name, assembly_name, biotype, transcripts) VALUES ('$row[13]', $taxon, $row[14], $row[5], $row[6], '$row[4]', $row[7], 'core', '$row[9]', '$row[3]', '$desc', '$row[8]', 'GRCh38', '$row[1]'";

    $fetch_transcript->execute($row[0]);
    if($fetch_transcript->rows > 0) {
	$insert .= ", {\n";
    }
    my @pieces;
    while(my @t_row = $fetch_transcript->fetchrow_array()) {
#	print "\t" . join(',', @t_row) . "\n";

	my @t_pieces;
	push @t_pieces, "start: $t_row[3]";
	push @t_pieces, "end: $t_row[4]";
	push @t_pieces, "id: '$t_row[9]'";
	push @t_pieces, "version: $t_row[10]";
	push @t_pieces, "biotype: '$t_row[6]'" if($row[6]);
	push @t_pieces, "display_name: '$t_row[6]'" if($row[6]);
	push @t_pieces, "is_canonical: true" if($row[12] == $t_row[0]);

	$fetch_translation->execute($t_row[0]);
	die "More than one translation!\n" if($fetch_translation->rows > 1);
	if($fetch_translation->rows > 0) {
	    my $trans_str = "{ ";
	    while(my @p_row = $fetch_translation->fetchrow_array()) {
#		print "\t\t" . join(',', @p_row) . "\n";

		my @p_pieces;
		push @p_pieces, "start: $p_row[1]";
		push @p_pieces, "end: $p_row[2]";
		push @p_pieces, "id: '$p_row[3]'";
		push @p_pieces, "version: $p_row[4]";
		push @p_pieces, "length: " . ($p_row[2] - $p_row[2]);

		$trans_str .= join(',', @p_pieces);

		print "INSERT INTO Ensembl.molecule_root (id, species, gene_id, transcript_id) VALUES ('$p_row[3]', $taxon, '$row[13]', '$t_row[9]');\n";
	    }

	    $trans_str .= " }\n";
	    push @t_pieces, "translation: $trans_str";
	}

	$fetch_exon->execute($t_row[0]);
	if($fetch_exon->rows > 0) {
	    my @exons;
	    while(my @e_row = $fetch_exon->fetchrow_array()) {
#		print "\t\t\t" . join(',', @e_row) . "\n";

		my @e_pieces;
		push @e_pieces, "start: $e_row[1]";
		push @e_pieces, "end: $e_row[2]";
		push @e_pieces, "id: '$e_row[3]'";
		push @e_pieces, "version: $e_row[4]";

		push @exons, "{ " . join(',', @e_pieces) . " }\n";

		print "INSERT INTO Ensembl.molecule_root (id, species, gene_id, transcript_id) VALUES ('$e_row[3]', $taxon, '$row[13]', '$t_row[9]');\n";
	    }

	    push @t_pieces, "exons: {" . join(',', @exons) . " }\n";
	}

	push @pieces, "{ " . join(',', @t_pieces) . " }\n";

	print "INSERT INTO Ensembl.molecule_root (id, species, gene_id) VALUES ('$t_row[9]', $taxon, '$row[13]');\n";

    }
    if($fetch_transcript->rows > 0) {
	$insert .= join(',', @pieces);
	$insert .= '}';
    }


    $insert .= ');';

    print $insert . "\n";
}
