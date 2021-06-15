
# Introduction ------------------------------------------------------------


# This script shows basic steps of an exploratorive data analysis of fossil
# data, including binning and sampling standardization.

# Set-up
# load the packages necessary for the analysis
library(divDyn)
library(here)


# Data --------------------------------------------------------------------

# If you have downloaded fossil data via the API directly, load it into R from
# the raw_data folder via read.csv() and the here() function.

###



###

# If you want to load the data via the URL, paste it into the read.csv()
# function and then write the raw data to the raw_data folder via write.csv()
# and the here() function.

###



###



# Binning -----------------------------------------------------------------

# To use the occurrences in the divDyn package in an efficient way, the entries
# must be assigned to a discrete time scale. Two of these time-scales are
# included in the divDyn package: the widely-used 10 myr time scale of the
# Paleobiology Database, and another one based on the stratigraphic stages of
# Ogg et al. (2016). These can loaded with the data() function.

###
# 10 million year timescale
data(bins)
# stage-level timescale
data(stages)
###


# You can learn more about these time scales if you type in ?bins or ?stages.
# The first time scale (bins) has 49 entries identifying roughly 10-million year
# bins. The second one (stages) has almost double the stratigraphic resolution,
# but some of the ICS stages are clumped to ensure a more even distribution of
# durations (cf. Miocene and Pliocene). It is easier to handle the two
# timescales with the same functions if the time bin names have identical column
# names in both tables.

###
# names of the bins
colnames(bins)[colnames(bins)=="X10"] <- "name"
# names of the bins
colnames(stages)[colnames(stages)=="stage"] <- "name"
###

# The original data in the Paleobiology Database get their stratigraphic
# information based on the 7 early_interval and late_interval values. The valid
# entries in these variables come from a list of interval names that convert
# them to numeric ages and establish connections between the different entries.
# In the dynamic timescale of Fossilworks (J. Alroy), they are also linked to
# the 10 million year timescale and the ICS stages (Ogg et al. 2016), without
# the changes in the Neogene. The early_interval and late_interval values
# designate stratigraphic position in a straightforward way: the early_interval
# marks the oldest possible age and the late_interval the youngest. If a single
# name suffices to describe the inherent uncertainty of an interval, the
# late_interval remains empty.

# Using a complete download of collections from Fossilworks, divDyn compiled a table
# that resolves these ‘interval’ entries to the timescales of our interest. This
# table is the stratkeys object, which can be attached by running
# data(stratkeys). The rows in this table were then transformed to list type
# entries that can be used by the categorize() function. Similarly to the
# environmental variables, this can be found in the keys object.

# The stratigraphic binning starts with figuring out which numbered bins the
# early_interval and late_interval entries are assigned to. Let’s start with the
# 10 million year bins.

###
# categorize entries as they are in the lookup table
binMin <- categorize(dat[ ,"early_interval"], keys$binInt)
binMax <- categorize(dat[ ,"late_interval"], keys$binInt)
###

# Then the entries have to be converted to simple numeric values.

###
binMin <- as.numeric(binMin)
binMax <- as.numeric(binMax)
###

# This code creates two vectors of numeric bin numbers, where NA entries
# indicate that the names were not found in the table, and -1 entries indicate
# empty character strings (where no late_interval entry is given). As our goal
# is to retain only those occurrences that have precise enough stratigraphic
# assignments, we only want to consider those occurrences that have either the
# same binMin or binMax number or where binMax is -1. This is accomplished by
# the following steps.

# First, a final, empty vector is defined.

###
dat$bin <- rep(NA, nrow(dat))
###

# Then the condition above is expressed indicating which rows have only a single
# assigned bin number.

###
binCondition <- c(
  # the early and late interval fields indicate the same bin
  which(binMax==binMin),
  # or the late_interval field is empty
  which(binMax==-1))
###

# Finally, those values are copied, where the condition is true

###
# in these entries, use the bin indicated by the early_interval
dat$bin[binCondition] <- binMin[binCondition]
###


# The final object is a column in the data table, where dat$bin is a single
# variable of integers that have NA entries where the collection/occurrence
# cannot be assigned to a single bin in the time scale.




# Task 1 ------------------------------------------------------------------

# Repeat the steps above with your own data. But bin your data to stages instead
# of 10 myr bins (using keys$stgInt).

###



###




# Sampling standardization ------------------------------------------------

# Sampling-standardized values can be calculated with a single function called
# subsample().

###
sqsStagesPlot <- subsample(dat, bin="stg", tax="clgen", coll="collection_no", q=0.7,
                           iter=100, ref="reference_no",singleton="ref", type="sqs", duplicates=FALSE,
                           excludeDominant=TRUE, largestColl =TRUE, output="dist")
###

# The function above is configured to use the ‘Shareholder Quorum Subsampling’
# (Alroy, 2010a, 2010b) or ‘coverage-based rarefaction’ (Chao and Jost, 2012)
# method (type="sqs") that subsamples the data down to an even level of sample
# coverage (Good, 1953). 
# The function is configured to use a reference-based ‘singleton’ treatment
# (singleton="ref") for overall sampling correction, excluding dominant taxa
# from all calculations involving frequencies (excludeDominant=TRUE) and with
# the separate treatment of the largest collection in the time slice
# (largestColl=TRUE), as indicated by Alroy (2010a). Setting output to "dist"
# makes the function return the results of individual subsampling trials. Please
# take a look at the help files of the functions ?subsample or ?subtrialSQS if
# you want to know more.

# You can plot the corrected sampled in bin diversity like this for one trial of
# the subsampling.

###
tsplot(stages, boxes="sys", shading="sys", xlim=4:95, ylim=c(0,2800),
       ylab="Richness (corrected SIB)" , xlab="Age (Ma)")
lines(stages$mid, sqsStagesPlot$divCSIB[ ,51], col="#00000088", lwd=2)
legend("topleft", bg="white", legend= "subsampling trial",
       col= "blue", lwd=3, inset=c(0.01, 0.01))
###

# And to plot all subsampling results, you have to iterate through the trials.
# Here are the results of the 100 trials above: 

###
# only plot
tsplot(stages, boxes="sys", shading="sys", xlim=4:95, ylim=c(0,1000),
       ylab="Subsampled richness (corrected SIB)", xlab="Age (Ma)")

# loop through all trial results
for(i in 1:ncol(sqsStagesPlot$divCSIB)){
  lines(stages$mid, sqsStagesPlot$divCSIB[,i], col="#00000088")
}

# the mean of the trial results
meanRes <- apply(sqsStagesPlot$divCSIB, 1, mean, na.rm=T)
lines(stages$mid, meanRes, col="#CC3300", lwd=2)
###




# Task 2 ------------------------------------------------------------------

# Standardize your own binned data and plot 100 trials of the subsampling
# procedure together with the mean over all trials as explained above. You can
# use any metric you prefer, but preferentially start with the corrected sampled
# in bin diversity divCSIB.

###


###