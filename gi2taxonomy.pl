#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

# script gi2taxonomy.pl
# from a text file with gi accession (one per line)
# get corresponding taxid from the ncbi dump nucl_gb.accession2taxid.gz 
# and from nucl_wgs.accession2taxid.gz (whole genomes)
# using the taxid, get the corresponding 7-level taxonomy from the ncbi taxonomy
# (created using https://github.com/zyxue/ncbitax2lin)
# return a new text file with:
# gi,taxid,domain,kingdom,phylum,class,order,family,genus,species
# SP@NC 2023-08-30; v1.0
#
# visit our Git: https://github.com/Nucleomics-VIB

$| = 1;  # Turn off output buffering

my $gi_file;
my $gbaccession2taxid = 'nucl_gb.accession2taxid.gz';
my $wgsaccession2taxid = 'nucl_wgs.accession2taxid.gz';
my $lineages_file;
my $output_file;

# Parse command line arguments using Getopt::Long
GetOptions(
    "i=s" => \$gi_file,
    "n=s" => \$gbaccession2taxid,
    "g=s" => \$wgsaccession2taxid,
    "l=s" => \$lineages_file,
    "o=s" => \$output_file,
);

# Check for the correct number of arguments
if (!defined $gi_file || !defined $lineages_file || !defined $output_file) {
    die "Usage: $0 -i gi_list.txt -l lineages.gz -o output.csv [-n gbaccession2taxid] [-g wgsaccession2taxid]\n";
}

###############
# Read GI list
###############

open my $gi_fh, '<', $gi_file or die "Error opening $gi_file: $!";
my @gi_list = <$gi_fh>;
close $gi_fh;

#############################
# Hash to store gi => taxid
#############################

my %gi_taxid_map;

######### 1: nucl_gb.accession2taxid.gz ##########
print "# loading the ncbi gb_accession2taxid data from $gbaccession2taxid\n";

# parse $gbaccession2taxid
open my $gbgiacc_fh, '-|', "zcat $gbaccession2taxid" or die "Error opening $gbaccession2taxid: $!";

# Skip the first line (column titles)
<$gbgiacc_fh>;

my $progress1 = 0;
while (<$gbgiacc_fh>) {
    chomp;
    my @fields = split /\t/;
    my ($taxid, $gi) = ($fields[2], $fields[3]);  # Taxid is in column 3, GI is in column 4
    $gi_taxid_map{$gi} = $taxid;
    
    $progress1++;
    if ($progress1 % 100000 == 0) {
        print ".";
    }
}
close $gbgiacc_fh;

print "\n";

######### 2: nucl_wgs.accession2taxid.gz ##########
print "# loading the ncbi $wgsaccession2taxid data from $wgsaccession2taxid\n";

# parse $wgsaccession2taxid
open my $wgsgiacc_fh, '-|', "zcat $wgsaccession2taxid" or die "Error opening $wgsaccession2taxid: $!";

# Skip the first line (column titles)
<$wgsgiacc_fh>;

my $progress2 = 0;
while (<$wgsgiacc_fh>) {
    chomp;
    my @fields = split /\t/;
    my ($taxid, $gi) = ($fields[2], $fields[3]);  # Taxid is in column 3, GI is in column 4
    $gi_taxid_map{$gi} = $taxid;
    
    $progress2++;
    if ($progress2 % 100000 == 0) {
        print ".";
    }
}
close $wgsgiacc_fh;

print "\n";

#########################################
# Hash to store taxid => taxonomy levels
#########################################

print "# loading the ncbi lineage data from $lineages_file\n";

# Open the lineages.gz file for reading
open my $lineage_fh, "-|", "zcat $lineages_file" or die "Error opening $lineages_file: $!";

# Skip the first line (titles)
<$lineage_fh>;

my %taxonomy_levels;
my $progress3 = 0;

# Process each line of the gzipped file
while (my $line = <$lineage_fh>) {
    chomp $line;

    my @fields = split /,/, $line;
    next if scalar(@fields) < 8; # Skip lines with less than 8 columns

    my $taxid = shift @fields;

    my $taxonomy_string = join(',', @fields[0..6]);
    $taxonomy_levels{$taxid} = $taxonomy_string;
    
    $progress3++;
    if ($progress3 % 100000 == 0) {
        print ".";
    }
}

close $lineage_fh;

####################################
# Process GI list and print results
####################################

# return empty array if taxonomy not found
my $nolevels = ",,,,,,";

# Open the output file for writing
open my $output_fh, '>', $output_file or die "Error opening $output_file for writing: $!";

# Process GI list and print results to the output file
foreach my $gi (@gi_list) {
    chomp $gi;
    if (exists $gi_taxid_map{$gi}) {
        my $taxid = $gi_taxid_map{$gi};
        if (exists $taxonomy_levels{$taxid}) {  
            print $output_fh "$gi,$taxid,$taxonomy_levels{$taxid}\n";
        } else {
            print $output_fh "$gi,$taxid,$nolevels\n";
        }
    } else {
        warn "$gi not found\n";
    }
}
