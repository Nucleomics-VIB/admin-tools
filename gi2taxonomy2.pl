#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

# script gi2taxonomy2.pl
# from a text file with gi accession (one per line)
# get corresponding taxid from the ncbi dump nucl_gb.accession2taxid.gz 
# and from nucl_wgs.accession2taxid.gz (whole genomes)
# using the taxid, get the corresponding 7-level taxonomy from the ncbi taxonomy
# (created using https://github.com/zyxue/ncbitax2lin)
# return a new text file with:
# gi,taxid,domain,kingdom,phylum,class,order,family,genus,species
# save hashes to gzipped dumps for next runs 
# NOTE: this script uses a lot of RAM to store large hashes
# it may not work on every computer without 'complaining'
# SP@NC 2023-08-30; v1.0
#
# visit our Git: https://github.com/Nucleomics-VIB

$| = 1;  # Turn off output buffering

my $gi_file;
my $gbaccession2taxid = 'nucl_gb.accession2taxid.gz';
my $wgsaccession2taxid = 'nucl_wgs.accession2taxid.gz';
my $lineages_file;
my $output_file;

# Define hash filenames
my $gi_taxid_dump_file = 'gi_taxid_dump.dat.gz';
my $taxonomy_levels_dump_file = 'taxonomy_levels_dump.dat.gz';

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
# Hashes to store data
#############################

my %gi_taxid_map;
my %taxonomy_levels;

# Check if dump files exist and load data if they do
if (-e $gi_taxid_dump_file && -e $taxonomy_levels_dump_file) {
    print "# Loading existing hash data from previously dumped files...\n";
    
    %gi_taxid_map = load_dump($gi_taxid_dump_file);
    %taxonomy_levels = load_dump($taxonomy_levels_dump_file);
} else {
    print "# no hash dumps found, loading data from archives and creating dumps\n";
    
    ######### 1: nucl_gb.accession2taxid.gz ##########
    print "# loading the ncbi gb_accession2taxid data from $gbaccession2taxid\n";

    open my $gbgiacc_fh, '-|', "zcat $gbaccession2taxid" or die "Error opening $gbaccession2taxid: $!";
    # code for loading gbaccession2taxid
    my $progress1 = 0;
    while (<$gbgiacc_fh>) {
        chomp;
        my @fields = split /\t/;
        my ($taxid, $gi) = ($fields[2], $fields[3]);  # Taxid is in column 3, GI is in column 4
        $gi_taxid_map{$gi} = $taxid;
        $progress1++;
        if ($progress1 % 500000 == 0) {
            print ".";
        }
    }
    close $gbgiacc_fh;

    print "\n";

    ######### 2: nucl_wgs.accession2taxid.gz ##########
    print "# loading the ncbi wgs_accession2taxid data from $wgsaccession2taxid\n";

    open my $wgsgiacc_fh, '-|', "zcat $wgsaccession2taxid" or die "Error opening $wgsaccession2taxid: $!";
    # code for loading wgsaccession2taxid
    my $progress2 = 0;
    while (<$wgsgiacc_fh>) {
        chomp;
        my @fields = split /\t/;
        my ($taxid, $gi) = ($fields[2], $fields[3]);  # Taxid is in column 3, GI is in column 4
        $gi_taxid_map{$gi} = $taxid;
        $progress2++;
        if ($progress2 % 500000 == 0) {
            print ".";
        }
    }
    close $wgsgiacc_fh;
    
    print "\n";

    #######################################
    # Hash to store gi and taxonomy levels
    #######################################

    print "# loading the ncbi lineage data from $lineages_file\n";

    open my $lineage_fh, "-|", "zcat $lineages_file" or die "Error opening $lineages_file: $!";
    # code for loading lineage data
    my $progress3 = 0;
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

    print "\n";

    # Save hashes to dump files
    print "# saving the hashes to disk for faster reload next run\n";
    save_dump(\%gi_taxid_map, $gi_taxid_dump_file);
    save_dump(\%taxonomy_levels, $taxonomy_levels_dump_file);
}

####################################
# Process GI list and print results
####################################

open my $output_fh, '>', $output_file or die "Error opening $output_file for writing: $!";
foreach my $gi (@gi_list) {
    chomp $gi;
    if (exists $gi_taxid_map{$gi}) {
        my $taxid = $gi_taxid_map{$gi};
        if (exists $taxonomy_levels{$taxid}) {  
            print $output_fh "$gi,$taxid,$taxonomy_levels{$taxid}\n";
        } else {
            print $output_fh "$gi,$taxid,,\n";
        }
    } else {
        warn "$gi not found\n";
    }
}
close $output_fh;

##########################################
# functions to load and dump large hashes 
##########################################

sub save_dump {
    my ($data_ref, $filename) = @_;
    open my $dump_fh, '|-', "gzip -c > $filename" or die "Error opening $filename for writing: $!";
    print $dump_fh join("\n", map { "$_ $data_ref->{$_}" } keys %$data_ref);
    close $dump_fh;
}

sub load_dump {
    my ($filename) = @_;
    open my $dump_fh, '-|', "gzip -dc $filename" or die "Error opening $filename for reading: $!";
    my %data;
    while (<$dump_fh>) {
        chomp;
        my ($key, $value) = split;
        $data{$key} = $value;
    }
    close $dump_fh;
    return %data;
}
