#!/usr/bin/env python

# script: gi2taxonomy.py
# Add 7-level taxonomy to a list of NCBI gi accessions
# NOTES:
# performs queries live and can be very slow if too many gi are provided
# requires biopython and ete3
# the first run will download taxdump.tar.gz from the NCBI
#
# SP@NC; 2023-08-29; v1.0
#
# visit our Git: https://github.com/Nucleomics-VIB

import sys
from Bio import Entrez
from ete3 import NCBITaxa

if len(sys.argv) != 2:
    print("Usage: python script.py <file_path>")
    sys.exit(1)

file_path = sys.argv[1]

# Read GI numbers from the specified text file (one per line)
with open(file_path, "r") as file:
    gi_list = [line.strip() for line in file]

Entrez.email = "stephane.plaisance@vib.be"  # Replace with your email

##########

def get_taxon_id(gi):
    handle = Entrez.efetch(db="nuccore", id=gi, rettype="gb", retmode="text")
    record = handle.read()
    handle.close()
    taxon_id = ""
    for line in record.split("\n"):
        if "db_xref" in line and "taxon:" in line:
            taxon_id = line.split("taxon:")[1].split("\"")[0]
            break
    return taxon_id

##########

def get_taxonomy_names(taxon_id):
    ncbi = NCBITaxa()
    lineage = ncbi.get_lineage(taxon_id)
    names = ncbi.get_taxid_translator(lineage)
    taxonomy_names = []
    for level in lineage:
        rank = ncbi.get_rank([level])
        if rank[level] in ['domain', 'kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species']:
            taxonomy_names.append(names[level])
    return ','.join(taxonomy_names)

##########

for gi in gi_list:
    taxon_id = get_taxon_id(gi)
    taxonomy_names = get_taxonomy_names(taxon_id)
    print(f'{gi},{taxon_id},{taxonomy_names}')
