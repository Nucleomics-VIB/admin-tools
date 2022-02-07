#!/usr/bin/env gawk -f

# script: parse_delim.awk
# Parse a csv file and return key=value pairs
# output is csv unless other separator is provided
## alt with different separator
## usage: parse_delim.awk -v OFS="|" infile
#
# HowTo: bash parsing of this script's output to array
# IFS=$'\n' arr=($(shared/parse_delim.awk -v sep=" " shared/test/example.txt))
# echo "print number of elements: ${#arr[@]}"
# echo "print the array elements: ${arr[@]}"
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2020-09-15 v0.1

function push(array,element)
{
  array[length(array)+1] = element
}

function join(array, start, end, sep, result, i)
{
  if (sep == "")
    sep = " "
  else if (sep == SUBSEP) # magic value
    sep = ""
    result = array[start]
  for (i = start + 1; i <= end; i++)
      result = result sep array[i]
  return result
}

BEGIN {
  FS=",";
  if (! OFS) {
    OFS=",";
  }
}
NR==1{
split($0,name,FS); # store column names in array
next
}
/^$/ {next}; # ignore blank lines
{
delete res; # empty array
for (n in name) {
  # add one key=value for each column
  push(res, sprintf("%s=%s", name[n], $n))
  }
# join the array into a string and print it
row=join(res, 1, length(res), OFS)
print row
}
