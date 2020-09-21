#!/usr/bin/env Rscript

# script: pmid2bibtex.R
# Aim: convert a single PMID (or a piped list of pmid's) to a BIBTEX / BIBLATEX formatted reference file
# requires RefManageR and optparse + base R packages
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2017-09-22 v1.0
#
# visit our Git: https://github.com/Nucleomics-VIB

# dependencies
suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("RefManageR"))

option_list <- list(
	make_option(c("-l", "--list"), type="character", default=NA,
		help="a comma-separated list of pmid's"), 
	make_option(c("-f", "--file"), type="character", default=NA,
		help="a text file with one pmid per line"), 
	make_option(c("-o", "--outfile"), type="character", default=NA,
		help="base name for the output bib file (default to stdout)"),
	make_option(c("-a", "--append"), action="store_true", default=FALSE,
		help="append content to existing bib file (default overwrite)"),
	make_option(c("-x", "--outformat"), default="bibtex",
		help="outout format (bibtex, biblatex) (default %default)")		
  )

# PARSE OPTIONS
opt <- parse_args(OptionParser(option_list=option_list))

file.type <- ifelse(opt$append, "a+", "w+") 

if ( is.na(opt$list) & is.na(opt$file) ) {
  stop("Some pmid required. See script usage (-h | --help)")
}

# either from list or from file (or stop)

# allow blobbing several pmid's
if ( ! is.na(opt$list) ) {
	pmid.list <- unlist(strsplit(opt$list, split=","))
} else { 
	if( file.access(opt$file) == -1) {
		stop(sprintf("Specified file ( %s ) does not exist", opt$file))
	} else {
		pmid.list <- read.table(opt$file, header=F)
		pmid.list <- pmid.list[['V1']]
	}
}

# query and fetch
bib <- GetPubMedByID(pmid.list, db = "pubmed")

if (length(bib)){

	if ( is.na(opt$outfile) ) {
		fh <- stdout()
	} else {
		fh <- file(opt$outfile, open=file.type )
	}

	# write results
	if (opt$outformat == "bibtex") {
		writeLines(toBibtex(bib), fh)
	} else if (opt$outformat == "biblatex") {
		writeLines(toBiblatex(bib), fh)
	} else {
		stop(sprintf("Specified output format ( %s ) is not supported", opt$outformat))
	}
	
	on.exit(if (isOpen(fh)) close(fh))
}
