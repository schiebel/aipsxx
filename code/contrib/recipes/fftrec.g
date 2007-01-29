#
#RECIPE: Fourier transforms, convolution, etc. in Glish
#
#CATEGORY: General
#
#GOALS: Perform Fourier transforms, convolution on arbitrary data
#
#USING: fftserver tool, pgplotter tool, mathematics module
#
#RESULTS: transformed, convolved data plotted in pgplotter
#
#ASSUME: 
#
#SYNOPSIS:
# The generic tools in aips++ include an fftserver tool which allows
# transforms of data of any dimension and size.  Convolution is also
# provided.
#


#SCRIPTNAME: fftrec.g

#SCRIPT:

include 'fftserver.g';                   # initialize fft tool
include 'pgplotter.g';                   # initialize pgplotter tool
include 'mathematics.g';                 # initialize mathematics tools

ang:=2*pi*[1:100]/15.0;                  # create vector of angles

y:=complex(cos(ang),sin(ang));           # create phasor vector from angles

mypg1:=pgplotter();                      # create pgplotter tool

mypg1.plotxy(x=ang,                      # plot data
             y=real(y),
             xtitle='Angle',
             ytitle='Real(y)');

myfft:=fftserver();                      # create fft tool

myfft.complexfft(y,-1);                  # perform complexfft in place

bins:=seq(shape(y));                     # vector of bins
amps:=abs(y);                            # amplitude of transform

mypg2:=pgplotter();                      # create pgplotter tool

mypg2.plotxy(x=bins,                     # plot transform
             y=amps,
             xtitle='bin',
             ytitle='abs[FT(y)]',
             title='fftserver example');

smth:=gaussian1d(x=[-25:25],             # generate 1d Gaussian
                 height=1.0,
                 center=0.0,
                 fwhm=10.0);

ysmth:=myfft.convolve(amps,smth);        # convolve transform amplitudes
                                         #  with the Gaussian

ysmth:=ysmth/max(ysmth);                 # normalize to peak

mypg2.plotxy(x=bins,                     # plot convolved amplitudes on
             y=ysmth,                    #  same plot, in green
             newplot=F,
             linecolor=3);


#OUTPUT:
# (only plots)

#SUBMITTER: George Moellenbrock
#SUBMITAFFL: NRAO-Socorro
#SUBMITDATE: 2002-Jan-25
