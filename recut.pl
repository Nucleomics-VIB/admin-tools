#!/usr/bin/perl

# script: recut.pl
# The Missing Textutils, Ondrej Bojar, obo@cuni.cz
# http://www.cuni.cz/~obo/textutils
#
# 'recut' is a simple 'cut' but unlike 'cut' allows for repetitions and
# reordering of columns. 
# Added possibility to insert a string in a column between two '*' (SP:BITS)
#
# $Id: recut,v 1.5 2009-06-16 06:21:27 bojar Exp $

use strict;
use warnings;
use Getopt::Long;

my $cols=shift;

die "usage: recut 3-5,1,2,-4
Same as cut, but supports changed order of collumns.
Prints blank fields too.
" if !$cols;

my @use;
foreach my $item (split /,/,$cols) {
  if ($item =~ /^\*(.*)\*$/) {
    # add a string in a column, eg a fixed name for a bed file
    push @use, ("string".$1);
    next;
  }
  if ($item =~ /^([0-9]+)$/) {
    # an item in the form of "3", i.e. an exact column
    push @use, $1-1;
    next;
  }
  if ($item =~ /^([0-9]+)-$/) {
    # an item in the form of "3-", i.e. tail
    push @use, ("tail".($1-1));
    next;
  }
  if ($item =~ /^(-[0-9]+)$/) {
    # an item in the form of "-3", i.e. an item from the end
    push @use, $1;
    next;
  }
  if ($item =~ /^([0-9]+)-([0-9]+)$/) {
    my $b = ($1<=$2 ? $2 : $1);
    for(my $i=$1; $i<=$b; $i++) {
      push @use, $i-1;
    }
    next;
  }
  if ($item =~ /^([0-9]+)-(-[0-9]+)$/) {
    # an item in the form of "3--2", i.e. tail up to 2col from the right
    push @use, ("tailfrom".($1-1)."upto$2");
    next;
  }
  die "Bad item $item";
}
#print STDERR join(", ", @use)."\n";

my $nr=0;
while (<>) {
  $nr++;
  chomp;
  my @line = split /\t/;
  my @outline = ();
  for (my $i=0; $i<=$#use; $i++) {
    if ($use[$i] =~ /string(.*)/) {
      push @outline, $1;
	} elsif ($use[$i] =~ /tail([0-9]+)/) {
      push @outline, @line[$1..$#line];
    } elsif ($use[$i] =~ /tailfrom([0-9]+)upto(-[0-9]+)/) {
      push @outline, @line[$1..($#line+$2)];
    } else {
      push @outline, $line[$use[$i]];
    }
  }
  print join("\t", map {defined $_ ? $_ : ""} @outline)."\n";
}