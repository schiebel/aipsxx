#
#RECIPE: Polynomial fitting using the fitter tool
#
#CATEGORY: General
#
#GOALS: Fit a quadratic to miscellaneous data
#
#USING: randomnumbers tool, fitter tool, pgplotter tool
#
#RESULTS: fit parameters and plots of data and fit
#
#ASSUME: 
#
#SYNOPSIS:
# The fitting tool in aips++ provides a wide range of fitting
# operations.  This script illustrates a quadratic polynomial
# fit.


#SCRIPTNAME: polyfitrec.g

#SCRIPT:

include 'randomnumbers.g';               # initialize randomnumbers tool
include 'fitting.g';                     # initialize fitting tool
include 'functionals.g';                 # initialize the functionals server
include 'pgplotter.g';

x:=seq(1000)/500.0;                      # create independent variable vector
y:= 11.3 - 9.2*x + 8.3*x*x;              # create quadratic dependent variable

rand:=randomnumbers();                   # create randomnumbers tool
rand.reseed();                           # reseed randomnumbers tool

y:= y + rand.normal(mean=0.0,            # add zero-mean, variance=200.0
                    variance=1.0,        #  Gaussian noise to y
                    shape=1000);     

myfit:=fitter();                         # create fitter tool

f:=dfs.poly(2)                           # 2nd order polynomial (3 unknowns)

myfit.linear(f,x,y);                     # perform the fit

sol:=myfit.solution();                   # retrieve solutions and report them
err:=myfit.error()
print 'Solution = ',sol;
print 'Errors   = ',err;

yfit:=sol[1] + sol[2]*x + sol[3]*x*x;    # form dependent variable vector 
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
# Solution =  [11.2936 -9.1973 8.29129] 
# Errors   =  [0.0946353 0.218319 0.105594] 


#SUBMITTER: George Moellenbrock
#SUBMITAFFL: NRAO-Socorro
#SUBMITDATE: 2002-Jan-28


