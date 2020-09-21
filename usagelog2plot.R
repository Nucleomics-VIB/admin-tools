#!/usr/bin/env Rscript

# script: usagelog2plot.R
# Aim: plot from usage_log.sh output
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2018-07-23 v1.0
# v1.1: adding DiskGB as optional 3rd line
# v1.1.1: correct 3rd scale factor
#
# visit our Git: https://github.com/Nucleomics-VIB

# dependencies
suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("ggplot2"))

option_list <- list(
  make_option(c("-l", "--log"), type="character", default=NA,
              help="a comma-separated usage_log.sh log file output"),
  make_option(c("-o", "--outfile"), type="character", default=NA,
              help="base name for the output plot (default to input file basename)"),
  make_option(c("-t", "--thirddata"), type="character", default="diskGB",
              help="data to use for the 3rd plot (diskIO|diskGB)"),
  make_option(c("-f", "--format"), default="png",
              help="output format (png, pdf) (default %default)")
)

# parse options
opt <- parse_args(OptionParser(option_list=option_list))

if ( is.na(opt$log) ) {
  stop("A usage_log.txt file is required. See script usage (-h | --help)")
}

# set output file name
outname <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(opt$log))
name <- ifelse( is.na(opt$outfile), outname, opt$outfile )
filename <- paste0(name, ".", opt$format)

# load log data in
data <- read.delim(opt$log, sep = ",", dec = ".",
                  header=TRUE, comment.char = "#", stringsAsFactors=FALSE)

# count time from 0
init <- data[1,1]
data$time <- data[,1]-init

# remove dots from names
colnames(data) <- gsub('\\.', '', colnames(data))

# rescale factors for secondary plots
cpuscale <- max(data$memGB)/max(data$cpu)

# plot to file
if(opt$format == "png") {
  png(filename, width = 640, height = 480, units = "px"); # open the png device
  } else {
  pdf(filename, width = 8, height = 6); # open the pdf device
  }

# add creation date
print.date <- format(Sys.time(), "%B %d, %Y %H:%M:%S")

# create plot

# third data
if(opt$thirddata == "diskIO") {
    thirddata <- data$diskIO
    thirdscale <- max(data$memGB)/max(data$diskIO)/2
  } else {
    thirddata <- data$diskGB
    thirdscale <- max(data$memGB)/max(data$diskGB)/2
    if (thirdscale<0) thirdscale = 1/thirdscale
  }

p <- ggplot(data=data, aes(x=time)) +
  geom_line(aes(y=data$memGB), color="royalblue", size=0.75, alpha=0.4) +
  labs(title = paste0("usage log from: ", opt$log, " (", print.date, ")")) +
  labs(x = "time (seconds)") +
  geom_line(aes(y=data$cpu*cpuscale), color="orange4", size=0.75, alpha=0.4) +
  labs(y = "RAM used (GB)") +
  geom_line(aes(y=thirddata*thirdscale), color="grey80", size=0.5, alpha=0.4) +
  theme(axis.title.x = element_text(colour = "grey30"),
        axis.title.y = element_text(colour = "royalblue"),
        axis.title.y.right = element_text(colour = "orange4")
        ) +
  scale_y_continuous(sec.axis = sec_axis(~./cpuscale, name = "cpu load (%)")) +
  theme(panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.line = element_line(size = 0.5, linetype = "solid",
                                 colour = "grey60"),
        panel.background = element_blank())

# plot
p

null <- dev.off()  # turn the device off
