#
#RECIPE: Basic use of glish algebra and pgplotter
#
#CATEGORY: General
#
#GOALS: Plot some Doppler factors as a function of line-of-sight angle
#
#USING: pgplotter tool
#
#RESULTS: a plot of Doppler factors
#
#ASSUME: 
#
#SYNOPSIS:
# All non-interactive pgplot functions are available in the pgplotter
# tool in glish/aips++.  Their names are the same except the leading
# pg has been removed.  This script the basic use of the pgplotter
# tool.
#


#SCRIPTNAME: plotrec.g

#SCRIPT:

include 'pgplotter.g';                   # initialize pgplotter tool

ang:=[0:90];                             # create vector of angles (degrees)
beta:=0.75+[1:9]/40;                     # create vector of velocities

nang:=shape(ang);                        # store length of data vectors
nbeta:=shape(beta);

D:=array(0.0,nbeta,nang);                # create array, initialized with 0.0,
                                         #  of shape nbeta X nang to hold 
                                         #  Doppler factors

for (i in 1:nbeta) {                     # calculate D for all ang, beta
 gamma:=1.0/sqrt(1-beta[i]^2);
 for (j in 1:nang) {
  D[i,j]:=1.0/(gamma*(1-beta[i]*cos(ang[j]*pi/180.0)));
 }
}

mypg:=pgplotter();                       # create pgplotter tool

mypg.env(xmin=0.0,                       # draw axes with sensible limits
         xmax=90.0,
         ymin=0.5*min(D),
         ymax=1.1*max(D),
         just=0,
         axis=0);

mypg.lab(xlbl='LOS Angle',               # add axes labels and title
         ylbl='Doppler Factor',
         toplbl='Doppler Factor vs. LOS Angle');

mypg.sci(3);                             # change color to green

for (i in 1:nbeta) {                     # for each beta....

 mypg.line(xpts=ang,                     #  plot D(ang)
           ypts=D[i,]);

 mypg.ptxt(x=ang[3],                     #  label each line
           y=D[i,3],
           angle=0,
           fjust=0,
           text=spaste('\\g=',as_string(beta[i])));
}


#OUTPUT:
# (only a plot)

#SUBMITTER: George Moellenbrock
#SUBMITAFFL: NRAO-Socorro
#SUBMITDATE: 2002-Jan-26
