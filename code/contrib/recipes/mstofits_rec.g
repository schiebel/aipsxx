#
#RECIPE: Script to convert measurement set into a u-v fits file.
#
#CATAGORY: Synthesis
#
#GOALS: Execution and detailed documentation of mstofits
#
#USING: mstofits function in ms tool
#
#RESULTS: A u-v FITS data set will be created from an aips++ measurement set
#
#ASSUME: Measurement set exists
#
#SYNOPSIS:
#    This script executes mstofits to create a u-v FITS data set from an
# AIPS++ measurement set <link mstofits>.
#
#    It is advised to use combinespw=T in order to combine all IF's
# into one data record in the FITS.  This is necessary if the data will then
# be read into AIPS.  Otherwise, there are several records which will
# have the same time stamp, which confuses some software systems.
# 
#SCRIPTNAME: mstofits_rec.g
#
#
# INITIATION AND INPUT PARAMETERS:
#
  include 'ms.g';                      # initiate measurement set tool

# Mandatory input parameters:
                                       # Measurement set name
   MSNAME        := '/aips++/data/demo/autoflag/WSRT-test.MS2';

   FITSFILE      := 'TESTUVFITS';      # UVFITs data file

   COMBINESPW    := T;                 # Combine all IF's into one
                                       # FQ table.  This option is recommended

# Optional input parameters (rarely changed);

   COLUMN        := 'corrected'        # Default.  Other options are
                                       #   'model', 'observed'
   WRITESYSCAL   := F;                 # Default.  If T, then 'GC' and
                                       #   'TY' tables written
   MULTISOURCE   := F;                 # Default
#------------------------------------------------------------------------------
# SCRIPT COMMANDS:
#
     print 'msname ', MSNAME           # Print msname

                                       # Open ms tool
     m1 := ms(MSNAME);
#
     m1.tofits(fitsfile= FITSFILE,     # Function tofits
          column      = COLUMN,
          writesyscal = WRITESYSCAL,
          multisource = MULTISOURCE,
          combinespw  = COMBINESPW)
#
     m1.done();                         # Close ms tool
#
#------------------------------------------------------------------------------
#
#OUTPUT: 
#   New u-v FITS files is created.
#   Output is straight-forward.
#
#SUBMITTER: Ed Fomalont
#SUBMITAFFL: NRAO-Charlottesville
#SUBMITDATE: 2002-Feb-11
