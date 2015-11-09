#!/usr/bin/env Rscript
#
# usage: diagram.r csvfile pngfile
#

args <- commandArgs(TRUE)
csvfile <- args[1]
pngfile <- args[2]

# read statistics
dbstat <- read.csv( csvfile, sep=';' )

# convert timestamps to dates
dbstat$time <- as.POSIXct(dbstat$time)

# skip missing values
dbstat <- dbstat[ !is.na(dbstat$count), ]

if (nrow(dbstat) < 3 ) {
    message("not enough data in ",csvfile)
    quit("no",FALSE)    
}

# scientific notation only if required
options(scipen=1)

png(pngfile)

par(mar=c(4,6,2,2))
plot(dbstat, pch=20, ann=F, yaxt="n" )

# Anzahl
yticks = axTicks(2);
axis(2, yticks, labels=format(yticks, big.mark=" "), las=1)

# Grid. TODO: show year and month
grid(col="lightgray", lty="dotted")

lines(dbstat, type="l")

off <- dev.off()
message("saved ",pngfile)
