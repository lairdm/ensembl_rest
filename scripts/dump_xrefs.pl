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

open FH, "<taxon.txt" or die "Error opening taxon.txt: $!";

while(<FH>) {
    chomp;

    my @pieces = split;

print "Doing $pieces[1] ($pieces[0])\n";
system("./xref_dump.pl $pieces[2] $pieces[0] >xrefs_$pieces[1]_$pieces[2].cql");
}

print "Done\n";
