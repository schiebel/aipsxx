# pgplotter_demo.gp: PGPLOT demo plugin for pgplotter.
#
#   Copyright (C) 1998,1999,2000,2001
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: pgplotter_demo.gp,v 19.2 2004/08/25 02:00:29 cvsmgr Exp $
#


pragma include once;
include 'types.g'
include 'widgetserver.g'

pgplotter_demo := [=];
pgplotter_demo.init := function() {
# Causing the pgplotter edit defect.
# I'm not sure what purpose this is supposed to serve.
# Braatz - 7/6/01
#    types.class('pgplotter').group('aips++').
#	method('demo', 'PGPLOT examples', category='plugin.demo').
#	boolean('interactive', T, help='Allow user to control interactively?');
    return T;
}

pgplotter_demo.attach := function(ref pg) {
pg.demo:=function(interactive=T) {

#
      ISEED:=1;
      IM := 2147483647
      IA := 16807
      IQ := 127773 
      IR := 2836
      AM := 128.0/as_double(IM)



VALUE := [ '1', '2', '3', '4', '5', '6', '7', '8', '9', 
           '10', '11', '12', '13',
	  'One panel', 'Four panels', 'Six panels'];

if(interactive) {
  f := dws.frame(title='PGPlotter Demo',side='top', expand='none');

  f.rec := [=]

  for (i in 1:13)
  {
    f.rec[i] := dws.button(f, paste('Example ',VALUE[i]), width=17 )
      }
  
  f.cbf := dws.frame(f, side='top', relief='groove');
  
  for (i in 14:16)
  {
    f.rec[i] := dws.button(f.cbf, paste('Use ',VALUE[i]), type='radio', width=15);
  }
  f.rec[14]->state(T);
  
  f.rec[17] := dws.button(f, 'Dismiss');
}
  

      FX:=function( temp )
{
      return sin( temp * 5.0 )
}

      FY:=function( temp )
{
      return sin( temp * 4.0 )
}

      function XYMAXMIN (ref xmin, ref xmax, ref ymin, ref ymax)
{
#-----------------------------------------------------------------------
# slightly enlarge the plotting window
#-----------------------------------------------------------------------
         if (xmin < 0.) xmin := xmin * 1.05
         if (xmin > 0.) xmin := xmin * 0.95
         if (xmax < 0.) xmax := xmax * 0.95
         if (xmax > 0.) xmax := xmax * 1.05
         if (ymin < 0.) ymin := ymin * 1.05
         if (ymin > 0.) ymin := ymin * 0.95
         if (ymax < 0.) ymax := ymax * 0.95
         if (ymax > 0.) ymax := ymax * 1.05

}

      const PGFUNT :=function(FX, FY, N, TMIN, TMAX, PGFLAG)
{
#-----------------------------------------------------------------------
#draw a curve defined by parametric equation X = FX(T), Y = FY(T)
# N: the number of points required by to define the curve
# TMIN, TMAX: the minimum and maximum values of the parameter T
# PGFLAG: if PGFLAG = 1, the curve is plotted in the current window
#                   = 0, pg.env is called automatically to start a new plot
#-----------------------------------------------------------------------
      N1 := N + 1
      XR := array(0, N1)
      YR := array(0, N1)

# Compute the function at N points, and use PGLINE to draw it.

      incr := (TMAX - TMIN) / N
      for (I in 1:(N+1)) {
          temp := incr*(I-1) + TMIN
          XR[I] := FY(temp)
          YR[I] := FX(temp)
      }

      if (PGFLAG == 0) {
         pg.bbuf()
         pg.save()
         xmin := min(XR)
         xmax := max(XR)
         ymin := min(YR)
         ymax := max(YR)
         XYMAXMIN (ref xmin, ref xmax, ref ymin, ref ymax)
         pg.env(xmin, xmax, ymin, ymax, 0,1)
      }

      pg.line(XR,YR)

      if (PGFLAG == 0) {
         pg.unsa()
         pg.ebuf()
      }
}

      const PGBSJ0:=function(XX)
{
#-----------------------------------------------------------------------
# Bessel function of order 0 (approximate).
# Reference: bramowitz and Stegun: Handbook of Mathematical Functions.
#-----------------------------------------------------------------------
     
      X := abs(XX)
      tt := 0
      if (X <= 3.0) {
         XO3 := X/3.0
         temp := XO3*XO3
         tt := 1.0 + temp*(-2.2499997 + temp*( 1.2656208 +
                     temp*(-0.3163866 + temp*( 0.0444479 +
                     temp*(-0.0039444 + temp*( 0.0002100) )))))
      } else {
         temp := 3.0/X
         t1 :=  0.79788456 + temp*(-0.00000077 + temp*(-0.00552740 +
                temp*(-0.00009512 + temp*( 0.00137237 + temp*(-0.00072805 +
                temp*( 0.00014476))))))
         THETA0 := X - 0.78539816 + temp*(-0.04166397 +
                 temp*(-0.00003954 + temp*( 0.00262573 +
                 temp*(-0.00054125 + temp*(-0.00029333 + temp*( 0.00013558))))))
         tt := t1*cos(THETA0)/sqrt(X)
      }
      return tt
}

      const PGBSJ1:=function(XX)
{
#-----------------------------------------------------------------------
# Bessel function of order 1 (approximate).
# Reference: Abramowitz and Stegun: Handbook of Mathematical Functions.
#-----------------------------------------------------------------------

      X := abs(XX)
      tt := 0
      if (X <= 3.0) {
         XO3 := X/3.0
         temp := XO3*XO3
         t1 := 0.5 + temp*(-0.56249985 + temp*( 0.21093573 +
                     temp*(-0.03954289 + temp*( 0.00443319 +
                     temp*(-0.00031761 + temp*( 0.00001109))))))
         tt := t1*XX
      } else {
         temp := 3.0/X
         t1 :=    0.79788456 + temp*( 0.00000156 + temp*( 0.01659667 + 
            temp*( 0.00017105 + temp*(-0.00249511 + temp*( 0.00113653 + 
            temp*(-0.00020033))))))
         THETA1 := X   -2.35619449 + temp*( 0.12499612 + temp*( 0.00005650 +
                  temp*(-0.00637879 + temp*( 0.00074348 + temp*( 0.00079824 +
                  temp*(-0.00029166))))))
         tt := t1*cos(THETA1)/sqrt(X)
      }
      if (XX < 0.0) tt := -tt
      return tt
}

      const PGRAND:=function()
{
#-----------------------------------------------------------------------
# Returns a uniform random deviate between 0.0 and 1.0.
#
# NOTE: this is not a good random-number generator; it is only
# intended for exercising the PGPLOT routines.
#
# Based on: Park and Miller's "Minimal Standard" random number
#   generator (Comm. ACM, 31, 1192, 1988)
#
# Arguments:
#  ISEED  (in/out) : seed.
#-----------------------------------------------------------------------
      wider ISEED

      wider IM, IA, IQ, IR, AM

      K := as_integer( ISEED/IQ )
      ISEED := as_integer( IA*(ISEED-K*IQ) - IR*K )
      if (ISEED < 0) ISEED := ISEED+IM
      return AM*( as_integer(ISEED/128) )
}

      const PGRNRM :=function()
{
#-----------------------------------------------------------------------
# Returns a normally distributed deviate with zero mean and unit 
# variance. The routine uses the Box-Muller transformation of uniform
# deviates. For a more efficient implementation of this algorithm,
# see Press et al., Numerical Recipes, Sec. 7.2.
#
# Arguments:
#  ISEED  (in/out) : seed used for PGRAND random-number generator.
#
# Subroutines required:
#  PGRAND -- return a uniform random deviate between 0 and 1.
#
# History:
#  1995 Dec 12 - TJP.
#-----------------------------------------------------------------------
      wider ISEED

      R := 0
      X := 1
      while (R >= 1. || R == 0.) {
         X := 2.0*PGRAND() - 1.0
         Y := 2.0*PGRAND() - 1.0
         R := X*X + Y*Y
      }
      return X*sqrt(-2.0*log(R)/R)
}

      PGFUNX:=function(FY, N, XMIN, XMAX, PGFLAG)
{
#-----------------------------------------------------------------------
#draw a curve defined by parametric equation Y = FY(T)
# N: the number of points required by to define the curve
# TMIN, TMAX: the minimum and maximum values of the parameter T
# PGFLAG: if PGFLAG = 1, the curve is plotted in the current window
#                   = 0, pg.env is called automatically to start a new plot
#-----------------------------------------------------------------------
      N1 := N + 1
      XR := array(0, N1)
      YR := array(0, N1)

# Compute the function at N points, and use PGLINE to draw it.

      incr := (XMAX - XMIN) / N
      for (K in 1:(N+1)) {
          temp := incr*(K-1) + XMIN
          XR[K] := temp
          YR[K] := FY(temp)
      }

      if (PGFLAG == 0) {
         xmin := min(XR) 
         xmax := max(XR)
         ymin := min(YR)
         ymax := max(YR)
         XYMAXMIN (ref xmin, ref xmax, ref ymin, ref ymax)

         pg.bbuf()
         pg.save()
         pg.env(xmin, xmax, ymin, ymax, 0,1)
      }
      pg.line(XR,YR)

      if (PGFLAG == 0) {
         pg.unsa()
         pg.ebuf()
      }
}

      PGFUNY :=function(FX, N, YMIN, YMAX, PGFLAG)
{
#-----------------------------------------------------------------------
#draw a curve defined by parametric equation X = FX(T)
# N: the number of points required by to define the curve
# TMIN, TMAX: the minimum and maximum values of the parameter T
# PGFLAG: if PGFLAG = 1, the curve is plotted in the current window
#                   = 0, pg.env is called automatically to start a new plot
#-----------------------------------------------------------------------
      N1 := N + 1
      XR := array(0, N1)
      YR := array(0, N1)

# Compute the function at N points, and use PGLINE to draw it.

      incr := (YMAX - YMIN) / N
      for (I in 1:(N+1)) {
          temp := incr*(I-1) + YMIN
          YR[I] := temp
          XR[I] := FX(temp)
      }

      if (PGFLAG == 0) {
         xmin := min(XR) 
         xmax := max(XR)
         ymin := min(YR)
         ymax := max(YR)
         XYMAXMIN (ref xmin, ref xmax, ref ymin, ref ymax)

         pg.bbuf()
         pg.save()
         pg.env(xmin, xmax, ymin, ymax, 0,1)
      }

      pg.line(XR,YR)

      if (PGFLAG == 0) {
         pg.unsa()
         pg.ebuf()
      }
}

const PGEX1 := function()
{
#-----------------------------------------------------------------------
# This example illustrates the use of PGENV, PGLAB, PGPT, PGLINE.
#-----------------------------------------------------------------------
      XR := array(0, 60)
      YR := array(0, 60)
      XS := [1, 2, 3, 4., 5]
      YS := [1, 4, 9, 16, 25]

# Call PGENV to specify the range of the axes and to draw a box, and
# PGLAB to label it. The x-axis runs from 0 to 10, and y from 0 to 20.

      #pg.clear()
      pg.bbuf()
      pg.save()
      pg.env(0.,10.,0.,20.,0,1)
      pg.lab('(x)', '(y)', 'PGPLOT Example 1:  y = x\\u2')

# Mark five points (coordinates in arrays XS and YS), using symbol
# number 9.

      pg.pt(XS,YS,9)

# Compute the function at 60 points, and use PGLINE to draw it.

      I := 1:60
      XR := 0.1*I
      YR := XR^2
      pg.line(XR,YR)
      pg.unsa()
      pg.ebuf()
}

const PGEX2 := function()
{
#-----------------------------------------------------------------------
# Repeat the process for another graph. This one is a graph of the
# sinc (sin x over x) function.
#-----------------------------------------------------------------------
      XR := array(0, 100)
      YR := array(0, 100)
#
      #pg.clear()
      pg.bbuf()
      pg.save()
      pg.env(-2.,10.,-0.4,1.2,0,1)
      pg.lab("(x)", "sin(x)/x", "PGPLOT Example 2:  Sinc Function")
      for (I in 1:100) {
          XR[I] := (I-20)/6.
          YR[I] := 1.0
          if (XR[I] != 0.0) YR[I] := sin(XR[I])/XR[I]
      }

# Restore attributes to defaults.

      pg.line(XR,YR)
      pg.unsa()
      pg.ebuf()
}

const PGEX3 := function()
{
#----------------------------------------------------------------------
# This example illustrates the use of PGBOX and attribute routines to
# mix colors and line-styles.
#----------------------------------------------------------------------
      PI := 3.14159265
      XR := array(0, 360)
      YR := array(0, 360)

# Call PGENV to initialize the viewport and window; the
# AXIS argument is -2, so no frame or labels will be drawn.

      #pg.clear()
      pg.bbuf()
      pg.save()
      pg.env(0.,720.,-2.0,2.0,0,-2)

# Set the color index for the axes and grid (index 5 = cyan).
# Call PGBOX to draw first a grid at low brightness, and then a
# frame and axes at full brightness. Note that as the x-axis is
# to represent an angle in degrees, we request an explicit tick 
# interval of 90 deg with subdivisions at 30 deg, as multiples of
# 3 are a more natural division than the default.

      pg.sci(14)
      pg.box('G',30.0,0,'G',0.2,0)
      pg.sci(5)
      pg.box('ABCTSN',90.0,3,'ABCTSNV',0.0,0)

# Call PGLAB to label the graph in a different color (3=green).

      pg.sci(3)
      pg.lab("x (degrees)","f(x)","PGPLOT Example 3")

# Compute the function to be plotted: a trig function of an
# angle in degrees, computed every 2 degrees.

      I := 1:360
      XR := 2.0*I
      ARG := XR/180.0*PI
      YR := sin(ARG) + 0.5*cos(2.0*ARG) + 0.5*sin(1.5*ARG+PI/3.0)

# Change the color (6=magenta), line-style (2=dashed), and line
# width and draw the function.

      pg.sci(6)
      pg.sls(2)
      pg.slw(3)
      pg.line(XR,YR)

# Restore attributes to defaults.

      pg.ebuf()
      pg.unsa()
}

      const PGEX4 :=function()
{
#-----------------------------------------------------------------------
# Demonstration program for PGPLOT: draw histograms.
#-----------------------------------------------------------------------
      wider ISEED
      DATA := array(0, 1000)
      X := array(0,620)
      Y := array(0,620)

# Call PGRNRM to obtain 1000 samples from a normal distribution.

      ISEED := -5678921
      for (I in 1 : 1000) {
          DATA[I] := PGRNRM()
      }

# Draw a histogram of these values.

      #pg.clear()
      pg.bbuf()
      pg.save()
      pg.hist(DATA,-3.1,3.1,31,0)

# Samples from another normal distribution.

      for (I in 1 : 200) {
          DATA[I] := 1.0+0.5*PGRNRM()
      }

# Draw another histogram (filled) on same axes.

      pg.sci(15)
      pg.hist(DATA, -3.1, 3.1, 31, 3)
      pg.sci(0)
      pg.hist(DATA, -3.1, 3.1, 31, 1)
      pg.sci(1)

# Redraw the box which may have been clobbered by the histogram.

      pg.box('BST', 0.0, 0, ' ', 0.0, 0)

# Label the plot.

      pg.lab("Variate", "Count", "PGPLOT Example 4:  Histograms (Gaussian)")

# Superimpose the theoretical distribution.

      I := 1:620
      X := -3.1 + 0.01*(I-1)
      Y := 0.2*1000./sqrt(2.*3.14159265)*exp(-0.5*X*X)
      pg.line(X,Y)
      pg.ebuf()
      pg.unsa()
}

      const PGEX5 :=function()
{
#----------------------------------------------------------------------
# Demonstration program for the PGPLOT plotting package.  This example
# illustrates how to draw a log-log plot.
# PGPLOT subroutines demonstrated:
#    PGENV, PGERRY, PGLAB, PGLINE, PGPT, pg.sci.
#----------------------------------------------------------------------
      RED :=2
      GREEN :=3
      CYAN :=5

      FREQ := [ 26., 38., 80., 160., 178., 318.,
                 365., 408., 750., 1400., 2695., 2700.,
                 5000., 10695., 14900. ]
      FLUX := [ 38.0, 66.4, 89.0, 69.8, 55.9, 37.4,
                 46.8, 42.4, 27.0, 15.8, 9.09, 9.17,
                 5.35, 2.56, 1.73 ]
      ERR := [6.0, 6.0, 13.0, 9.1, 2.9, 1.4,
                 2.7, 3.0, 0.34, 0.8, 0.2, 0.46,
                0.15, 0.08, 0.01 ]

# Call PGENV to initialize the viewport and window; the AXIS argument 
# is 30 so both axes will be logarithmic. The X-axis (frequency) runs 
# from 0.01 to 100 GHz, the Y-axis (flux density) runs from 0.3 to 300
# Jy. Note that it is necessary to specify the logarithms of these
# quantities in the call to PGENV. We request equal scales in x and y
# so that slopes will be correct.  Use PGLAB to label the graph.
#
      #pg.clear()
      pg.bbuf()
      pg.save()
      pg.sci(CYAN)
      pg.env(-2.0,2.0,-0.5,2.5,1,30)
      pg.lab("Frequency, \\gn (GHz)",
                  "Flux Density, S\\d\\gn\\u (Jy)",
                  "PGPLOT Example 5:  Log-Log plot")
#
# Draw a fit to the spectrum (don't ask how this was chosen). This 
# curve is drawn before the data points, so that the data will write 
# over the curve, rather than vice versa.
#
      I := 1 : 100
      X := 1.3 + I*0.03
      XP := X - 3.0
      YP := 5.18 - 1.15*X - 7.72*exp(-X)
      pg.sci(RED)
      pg.line(XP, YP)

# Plot the measured flux densities: here the data are installed with a
# DATA statement; in a more general program, they might be read from a
# file. We first have to take logarithms (the -3.0 converts MHz to GHz).

      XPP := log(FREQ) - 3.0
      YPP := log(FLUX)
      pg.sci(GREEN)
      pg.pt(XPP, YPP, 17)

# Draw +/- 2 sigma error bars: take logs of both limits.

      YHI := log(FLUX + 2.*ERR)
      YLO := log(FLUX - 2.*ERR)
      pg.erry(XPP, YLO, YHI, 1.0)
      pg.sch(3)

      pg.errb(5, XP, YP, 0.2, 1.0)
      pg.errb(6, XP, YP, 0.1, 1.0)

      pg.ebuf()
      pg.unsa()
}

      const PGEX6 :=function()
{
#----------------------------------------------------------------------
# Demonstration program for the PGPLOT plotting package.  This example
# illustrates the use of PGPOLY, PGCIRC, and PGRECT using SOLID, 
# OUTLINE, HATCHED, and CROSS-HATCHED fill-area attributes.
#----------------------------------------------------------------------
      TWOPI := 2.0*3.14159265
      NPOL := 6
      X := array(0, 10)
      Y := array(0, 10)
      N1 := [ 3, 4, 5, 5, 6, 8 ]
      N2 := [ 1, 1, 1, 2, 1, 3 ]
      LAB := [=]
      LAB[1] := 'Fill style 1 (solid)'
      LAB[2] := 'Fill style 2 (outline)'
      LAB[3] := 'Fill style 3 (hatched)'
      LAB[4] := 'Fill style 4 (cross-hatched)'

# Initialize the viewport and window.

      pg.page()
      pg.bbuf()
      pg.save()
      pg.svp(0.0, 1.0, 0.0, 1.0)
      pg.wnad(0.0, 10.0, 0.0, 10.0)

# Label the graph.

      pg.sci(1)
      pg.mtxt('T', -2.0, 0.5, 0.5, 
          'PGPLOT example 6: fill area: routines PGPOLY, PGCIRC, PGRECT')

# Draw assorted polygons.

      for (K in 1:4) {
         pg.sci(1)
         Y0 := 10.0 - 2.0*K
         pg.text(0.2, Y0+0.6, LAB[K])
         pg.sfs(K)
         for (I in 1:NPOL) {
            pg.sci(I)
            for (J in 1:N1[I]) {
               X[J] := I + 0.5*cos(N2[I]*TWOPI*(J-1)/N1[I])
               Y[J] := Y0 + 0.5*sin(N2[I]*TWOPI*(J-1)/N1[I])
            }
            pg.poly (X[1:N1[I]],Y[1:N1[I]])
         }
         pg.sci(7)
         pg.circ(7.0, Y0, 0.5)
         pg.sci(8)
         pg.rect(7.8, 9.5, Y0-0.5, Y0+0.5)
      }

      pg.unsa()
      pg.ebuf() 
}

      const PGEX7 :=function()
{
#-----------------------------------------------------------------------
# A plot with a large number of symbols; plus test of PGERRB.
#-----------------------------------------------------------------------
      wider ISEED
      XS := array(0,300)
      YS := array(0,300)
      XR := array(0,101)
      YR := array(0,101)

# Window and axes.

      #pg.clear()
      pg.bbuf()
      pg.save()
      pg.sci(1)
      pg.env(0., 5., -0.3, 0.6, 0, 1)
      pg.lab('\\fix', '\\fiy', 'PGPLOT Example 7: scatter plot')

# Random data points.

      ISEED := -45678921
      for (I in 1:300) {
          XS[I] := 5.0*PGRAND()
          YS[I] := XS[I]*exp(-XS[I]) + 0.05*PGRNRM()
      }
      pg.sci(3)
      pg.pt(XS,YS,3)
      pg.pt(XS[101],YS[101],17)
      pg.pt(XS[201],YS[201],21)

# Curve defining parent distribution.

      I := 1:101
      XR := 0.05*(I-1)
      YR := XR*exp(-XR)
      pg.sci(2)
      pg.line(XR, YR)

# Test of PGERRB.

      XP := XS[101]
      YP := YS[101]
      XSIG := 0.2
      YSIG := 0.1
      pg.sci(5)
      pg.sch(3.0)
      pg.errb(1, XP, YP, XSIG, 1.0)
      pg.errb(1, XP, YP, YSIG, 1.0)
      pg.pt(XP,YP,21)
#
      pg.unsa()
      pg.ebuf()
}
 
      const PGEX8 :=function()
{
#-----------------------------------------------------------------------
# Demonstration program for PGPLOT. This program shows some of the
# possibilities for overlapping windows and viewports.
# T. J. Pearson  1986 Nov 28
#-----------------------------------------------------------------------
      XR := array(0,720)
      YR := array(0,720)
#-----------------------------------------------------------------------
# Color index:
      BLACK := 0
      WHITE := 1
      RED := 2
      GREEN := 3
      BLUE := 4
      CYAN := 5
      MAGENT := 6
      YELLOW := 7
# Line style:
      FULL := 1
      DASHED := 2
      DOTDSH := 3
      DOTTED := 4
      FANCY := 5
# Character font:
      NORMAL := 1
      ROMAN := 2
      ITALIC := 3
      SCRIPT := 4
# Fill-area style:
      SOLID := 1
      HOLLOW := 2
#-----------------------------------------------------------------------

      pg.page()
      pg.bbuf()
      pg.save()

# Define the Viewport

      pg.svp(0.1, 0.6, 0.1, 0.6)

# Define the Window

      pg.swin(0.0, 630.0, -2.0, 2.0)

# Draw a box

      pg.sci(CYAN)
      pg.box('ABCTS', 90.0, 3, 'ABCTSV', 0.0, 0)
      pg.lab(' ',' ','PGPLOT Example 8:  sin ')

# Draw labels

      pg.sci (RED)
      pg.box('N',90.0, 3, 'VN', 0.0, 0)

# Draw SIN line

      I := 1:360
      XR := 2.0*I
      YR := sin(XR/57.29577951)
      pg.sci (MAGENT)
      pg.sls (DASHED)
      pg.line (XR,YR)

# Draw COS line by redefining the window

      pg.swin (90.0, 720.0, -2.0, 2.0)
      pg.sci (YELLOW)
      pg.sls (DOTTED)
      pg.line (XR,YR)
      pg.sls (FULL)

# Re-Define the Viewport

      pg.svp(0.45,0.85,0.45,0.85)

# Define the Window, and erase it

      pg.swin(0.0, 180.0, -2.0, 2.0)
      pg.sci(0)
      pg.rect(0.0, 180., -2.0, 2.0)

# Draw a box

      pg.sci(BLUE)
      pg.box('ABCTSM', 60.0, 3, 'VABCTSM', 1.0, 2)

# Draw SIN line

      pg.sci (WHITE)
      pg.sls (DASHED)
      pg.line (XR,YR)

      pg.unsa()
      pg.ebuf()
}

      const PGEX9 :=function()
{
#----------------------------------------------------------------------
# Demonstration program for the PGPLOT plotting package.  This example
# illustrates curve drawing with PGFUNT; the parametric curve drawn is
# a simple Lissajous figure.
#                              T. J. Pearson  1983 Oct 5
#----------------------------------------------------------------------

      #pg.clear()
      pg.bbuf()
      pg.save()
      pg.sci(5)

      PGFUNT (FX,FY,360,0.0,2.0*3.14159265,0)

# Call PGLAB to label the graph in a different color.

      pg.sci(3)
      pg.lab('x','y','PGPLOT Example 9:  routine PGFUNT')
 
      pg.unsa()
      pg.ebuf()
}

      const PGEX10 :=function()
{
#----------------------------------------------------------------------
# Demonstration program for the PGPLOT plotting package.  This example
# illustrates curve drawing with PGFUNX.
#                              T. J. Pearson  1983 Oct 5
#----------------------------------------------------------------------
# The following define mnemonic names for the color indices and
# linestyle codes.
      BLACK := 0
      WHITE := 1
      RED := 2
      GREEN := 3
      BLUE := 4
      CYAN := 5
      MAGENT := 6
      YELLOW := 7
      FULL := 1
      DASH := 2
      DOTD := 3

# Call PGFUNX twice to draw two functions (autoscaling the first time).

      #pg.clear()
      pg.bbuf()
      pg.save()

      pg.sci(YELLOW)
      PGFUNX (PGBSJ0,500,0.0,10.0*3.14159265,0)

      pg.sci(RED)
      pg.sls(DASH)
      PGFUNX (PGBSJ1,500,0.0,10.0*3.14159265,1)

# Call PGLAB to label the graph in a different color. Note the
# use of "\f" to change font.  Use pg.mtxt to write an additional
# legend inside the viewport.

      pg.sci(GREEN)
      pg.sls(FULL)
      pg.lab('\\fix', '\\fiy', '\\frPGPLOT Example 10: routine PGFUNX')
      pg.mtxt('T', -4.0, 0.5, 0.5, '\\frBessel Functions')

# Call PGARRO to label the curves.

      pg.arro(8.0, 0.7, 1.0, PGBSJ0(1.0))
      pg.arro(12.0, 0.5, 9.0, PGBSJ1(9.0))
      pg.stbg(GREEN)
      pg.sci(0)
      pg.ptxt(8.0, 0.7, 0.0, 0.0, ' \\fiy = J\\d0\\u(x)')
      pg.ptxt(12.0, 0.5, 0.0, 0.0, ' \\fiy = J\\d1\\u(x)')

      pg.unsa()
      pg.ebuf()
}

      const PGEX11 :=function()
{
#-----------------------------------------------------------------------
# Test routine for PGPLOT: draws a skeletal dodecahedron.
#-----------------------------------------------------------------------
      NVERT := 20
      T0 := 1.618
      T1 := 1.0+T0
      T2 := -1.0*T0
      T3 := -1.0*T1

      X := array(0., 2)
      Y := array(0., 2)

# Cartesian coordinates of the 20 vertices.

      VERT:=array([T0, T0, T0,    T0, T0,T2,
                T0,T2, T0,     T0,T2,T2,
                T2, T0, T0,    T2, T0,T2,
                T2,T2, T0,     T2,T2,T2,
                T1,1.0,0.0,    T1,-1.0,0.0,
                T3,1.0,0.0,    T3,-1.0,0.0,
                0.0,T1,1.0,    0.0,T1,-1.0,
                0.0,T3,1.0,    0.0,T3,-1.0,
                1.0,0.0,T1,    -1.0,0.0,T1,
                1.0,0.0,T3,    -1.0,0.0,T3],3,20)

# Initialize the plot (no labels).

      #pg.clear()
      pg.bbuf()
      pg.save()
      pg.env(-4.,4.,-4.,4.,1,-2)
      pg.sci(2)
      pg.sls(1)
      pg.slw(1)

# Write a heading.

      pg.lab(' ',' ','PGPLOT Example 11:  Dodecahedron')

# Mark the vertices.

      for (I in 1:NVERT) {
          ZZ := VERT[3,I]
          pg.pt(VERT[1,I]+0.2*ZZ,VERT[2,I]+0.3*ZZ,9)
      }

# Draw the edges - test all vertex pairs to find the edges of the 
# correct length.

      pg.slw(3)
      for (I in 2:NVERT) {
          for (J in 1 : (I-1) ) {
              R := 0.
              for (K in 1:3) {
                  R:=R+(VERT[K,I]-VERT[K,J])^2
              }
              R := sqrt(R)
              if (abs(R-2.0) <= 0.1) {
                 ZZ := VERT[3,I]
                 X[1] := VERT[1,I]+0.2*ZZ 
                 Y[1] := VERT[2,I]+0.3*ZZ 
                 ZZ := VERT[3,J]
                 X[2] := VERT[1,J]+0.2*ZZ 
                 Y[2] := VERT[2,J]+0.3*ZZ 
                 pg.line(X,Y)
              }
          }
      }
      pg.unsa()
      pg.ebuf()
}

      const PGEX12:=function()
{
#-----------------------------------------------------------------------
# Test routine for PGPLOT: draw arrows with PGARRO.
#-----------------------------------------------------------------------
# Number of arrows.

      NV := 16

# Select a square viewport.

      #pg.clear()
      pg.bbuf()
      pg.save()
      pg.sch(0.7)
      pg.sci(2)
      pg.env(-1.05,1.05,-1.05,1.05,1,-1)
      pg.lab(' ', ' ', 'PGPLOT Example 12: PGARRO')
      pg.sci(1)

# Draw the arrows

      K := 1
      D := 360.0/57.29577951/NV
      A := -D
      for (I in 1:NV) {
          A := A+D
          X := cos(A)
          Y := sin(A)
          XT := 0.2*cos(A-D)
          YT := 0.2*sin(A-D)
          pg.sah(K, 80.0-3.0*I, 0.5*I/NV)
          pg.sch(0.25*I)
          pg.arro(XT, YT, X, Y)
          K := K+1
          if (K > 2) K := 1
      }

      pg.unsa()
      pg.ebuf()
}

      const PGEX13:=function()
{
#----------------------------------------------------------------------
# This example illustrates the use of PGTBOX.
#----------------------------------------------------------------------
      N :=10
      X1 := [0.0,0.0,0.0,0.0, -8000.0, 100.3, 205.3, -45000.0, 0.0,0.0]
      X2 := [8000.0,8000.0,8000.0,8000.0,8000.0,101.3,201.1,-100000.0,
             -100000.0,-100000.0]
      XOPT := ['BSTN', 'BSTNZ', 'BSTNZH', 'BSTNZD', 'BSNTZHFO', 
           'BSTNZD', 'BSTNZHI', 'BSTNZHP', 'BSTNZDY', 'BSNTZHFOY']

      pg.page()
      pg.bbuf()
      pg.save()
      pg.sch(0.7)

      for (I in 1:N) {
        pg.svp(0.15, 0.85, (0.7+(N-I))/N, (0.7+(N-I+1))/N ) 
        pg.swin(X1[I], X2[I], 0.0, 1.0)
        pg.tbox(XOPT[I], 0.0, 0,' ', 0.0, 0)
        pg.lab(paste('Option = ',XOPT[I]), ' ', ' ')
        if (I == 1) {
           pg.mtxt('B', -1.0, 0.5, 0.5, '\\fiAxes drawn with PGTBOX')
        }
      }
      pg.ebuf()
      pg.unsa()
}


if(interactive) {
  whenever f.rec[1]->press do
      PGEX1();

  whenever f.rec[2]->press do 
      PGEX2();

  whenever f.rec[3]->press do 
      PGEX3();

  whenever f.rec[4]->press do 
      PGEX4();

  whenever f.rec[5]->press do 
      PGEX5();

  whenever f.rec[6]->press do 
      PGEX6();

  whenever f.rec[7]->press do
      PGEX7();

  whenever f.rec[8]->press do
      PGEX8();

  whenever f.rec[9]->press do
      PGEX9();

  whenever f.rec[10]->press do
      PGEX10();

  whenever f.rec[11]->press do
      PGEX11();

  whenever f.rec[12]->press do
      PGEX12();

  whenever f.rec[13]->press do
      PGEX13();

  whenever f.rec[14]->press do
      pg.subp(1,1);

  whenever f.rec[15]->press do

  whenever f.rec[16]->press do
      pg.subp(3,2);

  whenever f.rec[17]->press do
      f := F;

}
else {
      pg.subp(4,4);
      PGEX1();
      PGEX2();
      PGEX3();
      PGEX4();
      PGEX5();
      PGEX6();
      PGEX7();
      PGEX8();
      PGEX9();
      PGEX10();
      PGEX11();
      PGEX12();
      PGEX13();
      pg.plotfile('demo.plot');
}
#      PROGRAM PGDE13
#-----------------------------------------------------------------------
# Demonstration program for PGPLOT with multiple devices.
# It requires an interactive device which presents a menu of graphs
# to be displayed on the second device, which may be interactive or
# hardcopy.
#-----------------------------------------------------------------------
#
 return T;
}
    return T;
}

