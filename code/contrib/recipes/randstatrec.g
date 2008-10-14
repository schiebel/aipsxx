#
#RECIPE: Random numbers and statistics in glish
#
#CATEGORY: General
#
#GOALS: Form random numbers, report statistics, and plot a histogram
#
#USING: randomnumbers tool, statistics tool, pgplotter tool
#
#RESULTS: various statistical parameters and a histogram
#
#ASSUME:
#
#SYNOPSIS:
# Random numbers drawn from a variety of distributions are available in the
# randomnumbers tool.  This script demonstrates the formation of a normally 
# distributed random sample using a randomnumbers tool.  The global 
# functions available in the statistics tool are used to demonstrate how to 
# obtain various statistical measures of the random numbers.  The pgplotter
# tool is used to plot a histogram of the random numbers.
#

#SCRIPTNAME: randstatrec.g

#SCRIPT:
include 'randomnumbers.g';               # initialize randomnumbers tool
include 'statistics.g';                  # initialize statistics tool
include 'pgplotter.g';                   # initialize pgplotter tool

rand:=randomnumbers();                   # create randomnumbers tool

rand.reseed();                           # generate new seed

x:=rand.normal(mean=18.0,                # create vector of 10000 gaussian-
               variance=3.0,             #  distributed numbers with
               shape=10000);             #  mean=18, variance=3

print 'Mean       = ', mean(x);          # report statistics
print 'Median     = ', median(x);
print 'Variance   = ', variance(x);
print 'Stand. Dev.= ', stddev(x);
print 'Skew       = ', skew(x);

mypg:=pgplotter();                       # create pgplotter tool

mypg.hist(data=x,                        # plot histogram of data
          datmin=10.0,
          datmax=26.0,
          nbin=36,
          pgflag=0);


#OUTPUT:
# Mean       =  18.0068
# Median     =  18.0115
# Variance   =  3.0592
# Stand. Dev.=  1.74906
# Skew       =  -0.0224615

#SUBMITTER: George Moellenbrock 
#SUBMITAFFL: NRAO-Socorro
#SUBMITDATE: 2002-Jan-23
