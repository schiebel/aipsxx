#RECIPE: Recipe to fill raw BIMA data into aips++ measurement set 
#
#CATEGORY: Synthesis - BIMA 
#
#GOALS: Fill raw BIMA data into aips++ measurement set (ms) 
#
#USING: mirfiller tool 
#
#RESULTS: Output is an aips++ measurement set, e.g., target.ms 
#
#ASSUME: Input data file is raw BIMA data, e.g., Target 
#
#SYNOPSIS:
# For convenience, first download the raw BIMA data from the BIMA Data
# Archive into a subdirectory named INPUTDATA, which is located in the 
# current directory. Remember to uncompress the data in this subdirectory 
# if you haven't already done so in DaRT, using "tar -xvf <filename>." 
# Then run the script below to write these data into an aips++ measurement
# set.

#SCRIPTNAME: bimafiller_rec.g  

#SCRIPT:
include 'os.g';                          # initialize os
include 'mirfiller.g';                   # initialize mirfiller tool

mf := mirfiller('./INPUTDATA/Target');   # create mirfiller tool
mf.fill('target.ms');                    # fill the data
mf.done();                               # close the mirfiller tool

exit;                                    # exit glish

#OUTPUT:
# NORMAL: Starting server mirfiller
# NORMAL: Server started: /appl/aips++/weekly/linux_gnu/bin/mirfiller 
#			(AIPS++ version: 1.7 (build #159))
#NORMAL: 
#Summary of Miriad UV dataset: ./INPUTDATA/Target
# Max. no. of visibility records:    3960
# Max. no. of spectral line windows: 16 (Max no. of channels: 512)
# Max. no. of wide-band channels:    18
# No. of array configurations:       1
# Telescopes: BIMA
# Polarizations found: YY
# Time Range: 2001/06/28/09:57:46 - 2001/06/28/14:38:07
#Sources:
#     BLLAC      22:02:43.29     +42.16.39.98 (1 field)
#Frequency Setup:
#   Mode 8, 512 line channels, 18 wide channels
# Window  #chans   start freq.     increment    bandwidth    rest freq.
#    1       32   112.14251 GHz   -3125.00 kHz  100.00 MHz    115.27120 GHz
#    2       32   112.04251 GHz   -3125.00 kHz  100.00 MHz    115.27120 GHz
#    3       32   111.94348 GHz   -3125.00 kHz  100.00 MHz    115.27120 GHz
#    4       32   111.84348 GHz   -3125.00 kHz  100.00 MHz    115.27120 GHz
#    5       32   111.74346 GHz   -3125.00 kHz  100.00 MHz    115.27120 GHz
#    6       32   111.64346 GHz   -3125.00 kHz  100.00 MHz    115.27120 GHz
#    7       32   111.54344 GHz   -3125.00 kHz  100.00 MHz    115.27120 GHz
#    8       32   111.44344 GHz   -3125.00 kHz  100.00 MHz    115.27120 GHz
#    9       32   114.88768 GHz    3125.00 kHz  100.00 MHz    115.27120 GHz
#   10       32   114.98768 GHz    3125.00 kHz  100.00 MHz    115.27120 GHz
#   11       32   115.08671 GHz    3125.00 kHz  100.00 MHz    115.27120 GHz
#   12       32   115.18671 GHz    3125.00 kHz  100.00 MHz    115.27120 GHz
#   13       32   115.28673 GHz    3125.00 kHz  100.00 MHz    115.27120 GHz
#   14       32   115.38673 GHz    3125.00 kHz  100.00 MHz    115.27120 GHz
#   15       32   115.48676 GHz    3125.00 kHz  100.00 MHz    115.27120 GHz
#   16       32   115.58676 GHz    3125.00 kHz  100.00 MHz    115.27120 GHz
#NORMAL: Input looks like a raw BIMA dataset; setting default defpass="rawbima"
#NORMAL: Starting mirfiller::fill
#NORMAL: Accepted 3960 input MIRIAD records.
#Loaded 71280 data records for
#       2035440 visibilities,
#       18 spectral windows,
#       1 polarization,
#       1 field, and
#       1 array configuration.
#NORMAL: Finished mirfiller::fill
#      25.71 real       11.66 user       13.83 system
#NORMAL: Successfully closed empty server: mirfiller


#CONCLUSION: Current directory should now contain the aips++ ms 
# (named "target.ms" in this example). The current implementation
# (version 1.7, build #159) should fill the multi-channel data and
# the wideband (one for each sideband) average by default.

#SUBMITTER: Anuj Sarma 
#SUBMITAFFL: NCSA Radio Astronomy Imaging Group, University of Illinois
#SUBMITDATE: 2002-FEB-08
