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
my $database = 'homo_sapiens_core_79_38';

$taxon = $ARGV[0] if($ARGV[0]);
$database = $ARGV[1] if($ARGV[1]);

print "// using taxon id $taxon\n";
print "// using database $database\n";

my $dbh = DBI->connect("DBI:mysql:database=$database;host=localhost",
			   'root',
			   'password');
die "Error: Unable to connect to the database: $DBI::errstr\n" if ! $dbh;

$dbh->{mysql_auto_reconnect} = 1;

my $fetch_xref_distinct = $dbh->prepare("SELECT DISTINCT display_label FROM xref");

my $fetch_xrefs = $dbh->prepare("SELECT xref.xref_id, xref.dbprimary_acc, xref.display_label, xref.description, xref.info_type, xref.info_text, external_db.db_display_name, GROUP_CONCAT( DISTINCT object_xref.ensembl_id ) AS ensembl_id, GROUP_CONCAT( DISTINCT external_synonym.synonym ) AS synonym, GROUP_CONCAT( DISTINCT gene.stable_id ) AS gene_id, GROUP_CONCAT( DISTINCT transcript.stable_id ) AS transcript_id, xref.version, external_db.db_name FROM xref LEFT JOIN external_db ON xref.external_db_id = external_db.external_db_id LEFT JOIN object_xref ON object_xref.xref_id = xref.xref_id LEFT JOIN external_synonym ON xref.xref_id = external_synonym.xref_id LEFT JOIN gene ON object_xref.ensembl_id = gene.gene_id LEFT JOIN transcript ON object_xref.ensembl_id = transcript.transcript_id GROUP BY xref.xref_id");

# WHERE xref.display_label =  'BRCA2'

#$fetch_xref_distinct->execute();

#while(my @row = $fetch_xref_distinct->fetchrow_array()) {
#    print "INSERT INTO Ensembl.xrefbyname(name, species) VALUES ('$row[0]', $taxon);\n";
#}


$fetch_xrefs->execute();

# Fetch all the genes
while(my @row = $fetch_xrefs->fetchrow_array()) {
#    print join(',', @row) . "\n";

    my $desc = $row[3];
    $desc =~ s|'|''|g;
    $desc =~ s|/|\\/|g;
    my $info_text = $row[5];
    $info_text =~ s|'|''|g;
    $info_text =~ s|/|\\/|g;
    my $display_name = $row[6];
    $display_name =~ s|'|''|g;
    $display_name =~ s|/|\\/|g;

    my $name = $row[2];
    $name =~ s/ //g;
    $name =~ s/'//g;
    $name =~ s/\-//g;
    $name =~ s/\///g;
    $name =~ s/\\//g;
    $name =~ s/\|//g;
    $name =~ s/\(//g;
    $name =~ s/\)//g;
    $name =~ s/\[//g;
    $name =~ s/\]//g;
    $name =~ s/\+//g;

    # First we're going to insert the stable IDs for this xref
    my @stable_ids;
    my $ensembl_type;
    if($row[9]) {
	@stable_ids = split ',', $row[9];
	$ensembl_type = 'gene';
    } elsif($row[10]) {
	@stable_ids = split ',', $row[10];
	$ensembl_type = 'transcript';
    } else {
	# Skipping unmapped xrefs for now
	next;
    }
    my $ids_str = join ',', map { qq/'$_'/ } @stable_ids;

    for my $id (@stable_ids) {
	print "UPDATE Ensembl.xrefbyname SET stable_ids = stable_ids + {'$id': '$ensembl_type'} WHERE name = '$name' AND species = $taxon;\n";
    }

    my $insert = "UPDATE Ensembl.xrefbyname SET xrefs = xrefs + { {";

my @pieces;
push @pieces, "primary_id: '$row[1]'" if($row[1]);
push @pieces, "description: '$desc'" if($desc);
push @pieces, "info_type: '$row[4]'" if($row[4]);
push @pieces, "info_text: '$info_text'" if($info_text);
push @pieces, "db_display_name: '$display_name'" if($display_name);
push @pieces, "stable_ids: {$ids_str}";
push @pieces, "version: $row[11]";
push @pieces, "dbname: '$row[12]'";

# If synonyms
if($row[8]) {
    my $synrow = $row[8];
    $synrow =~ s/\(//g;
    $synrow =~ s/\)//g;
    $synrow =~ s/\[//g;
    $synrow =~ s/\]//g;
    $synrow =~ s/\+//g;
    $synrow =~ s/\\//g;
    $synrow =~ s/\///g;
    $synrow =~ s/\///g;
    $synrow =~ s/\|//g;
    $synrow =~ s/'//g;
    $synrow =~ s/\-//g;
    $synrow =~ s/ //g;
    my @synonyms = split ',', $synrow;

    for my $synonym (@synonyms) {
	my @subsyns = grep !"$synonym", @synonyms;
	push @subsyns, $name;
	my $synonym_str = join ',', map { qq/'$_'/ } @subsyns;

	my $syn_insert = $insert . join(',', @pieces,"is_synonym: true, primary_name: '$name'");
	$syn_insert .= " } } WHERE name = '$synonym' AND species = $taxon;\n";
	print $syn_insert;
    }

    my $synonym_str = join ',', map { qq/'$_'/ } @synonyms;
    push @pieces, "synonyms: {$synonym_str}";
}

    push @pieces, "is_synonym: false";
    $insert .= join ',', @pieces;


    $insert .= "} } WHERE name = '$name' AND species = $taxon;\n";

    print $insert;


}

exit;

