#
#RECIPE: Generic linear fitting
#
#CATEGORY: General
#
#GOALS: Fit generic data linearly
#
#USING: randomnumbers tool, fitter tool, pgplotter tool
#
#RESULTS: fitted coefficients and plot of data and fit
#
#ASSUME: 
#
#SYNOPSIS:
# The generic fitting tool in aips++ provides a wide range of fitting
# operations.  This script illustrates the simple case of linear fitting.
#

#SCRIPTNAME: linfitrec.g

#SCRIPT:

include 'randomnumbers.g'                # initialize randomnumbers tool
include 'fitting.g';                     # initialize fitting tool
include 'functionals.g';                 # initialize functionals server
include 'pgplotter.g'

x:=seq(1000)/500;                        # create independent variable vector
y:= 11.3 + 5.6*x;                        # create linear dependent variable

rand:=randomnumbers();                   # create randomnumbers tool
rand.reseed();                           # reseed randomnumbers tool

y:= y + rand.normal(mean=0.0,            # add zero-mean, variance=200.0
                    variance=1.0,        #  Gaussian noise to y
                    shape=1000);     

myfit:=fitter();                         # create fitter tool

f:=dfs.poly(1);                          # define (using functionals server)
                                         # 1st order (2 unknowns) polynomial

myfit.linear(f, x, y);                   # perform the fit on the date

sol:=myfit.solution();                   # retrieve solutions and report them
err:=myfit.error()
print 'Solution = ',sol;
print 'Errors   = ',err;

yfit:=sol[1] + sol[2]*x;                 # form dependent variable vector 
                                         #  from fit

mypg:=pgplotter();                       # create pgplotter tool

mypg.plotxy(x=x,                         # generate labelled plot of data pts
            y=y,
            plotlines=F,
            xtitle='X',
            ytitle='Y',
            title='Y vs. X');

mypg.plotxy(x=x,                         # add line plot of fit in green
            y=yfit,
            plotlines=T,
            newplot=F,
            linecolor=3);



#OUTPUT:
# Solution =  [11.2995 5.66225] 
# Errors   =  [0.0617396 0.053428] 
#  
#  (note that exact solutions depend upon the random numbers!)


#SUBMITTER: George Moellenbrock
#SUBMITAFFL: NRAO-Socorro
#SUBMITDATE: 2002-Jan-25
