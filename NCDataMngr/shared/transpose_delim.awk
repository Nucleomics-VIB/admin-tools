#!/usr/bin/env gawk -f

# script: transpose_delim.awk
# Parse a csv delimited file and convert columns into rows
# assuming:
#   row 1 contains column names without spaces or weird characters 
#   all rows habve equal number of columns 
#
# usage transpose_delim.awk infile
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2020-09-17 v0.1


BEGIN {
  FS=",";
  OFS=",";
}
{
  for (i = 1; i <= NF; i++) {
    if(NR == 1) {
      s[i] = $i;
    } else {
      s[i] = s[i] " " $i;
    }
  }
}
END {
  for (i = 1; s[i] != ""; i++) {
    print s[i];
  }
}
