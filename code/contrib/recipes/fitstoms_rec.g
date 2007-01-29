#CATAGORY: Synthesis
#
#GOALS: Execution and detailed documentation of fitstoms
#
#USING: fitstoms constructor in ms tool
#
#RESULTS: A measurement set will be created from a fits u-v data set on disk
#
#ASSUME: External data set available to host cpu
#
#SYNOPSIS:
# This script executes fitstoms to create a measurement set from a disk
# data set <link fitstoms>.  The script includes relevant documentation
# for running the script, and general remarks for loading u-v data into
# aips++.
#
#     This script will read U-V fits data only from disk into an aips++
#  measurement set.  Only the u-v data and information from the following
#  extension files: antenna (AN); frequency (FQ); and source (SU) are used.
#  Hence, no calibration and flagging information in the U-V fits data can
#  be transferred to the aips++ measurment set.  Use SPLIT in aips to
#  apply these corrections before transferring to aips++.
#
#     For reading archive vla-format data or vlba-format data, into aips++
#  use vlafillerfromtape.g <link> or vlafillerfromdisk.g <link>.
#
#     If the u-v fits data set is on tape, it must first be read onto disk.
#
#     To write the data from tape to disk, use mt and dd commands in unix.
#   Example:
#      mt -f /dev/nsto  rewind          where /dev/nsto is the tape drive name
#      mt -f /dev/nsto  fsf n           skip n files as necessary
#      dd if=/dev/nsto of=DATA.UV ibs=28800 obs=2880
#                                       copy data from this file to DATA.UV
#                                       obs=blocksize must be 2880.
#                                       ibs=BLOCKING * 2880 from FTP run
#                                       ibs=28800 is most common
#
#SCRIPTNAME: fitstoms_rec.g
#
#------------------------------------------------------------------------------
# INITIATION AND INPUT PARAMTERS:
#
  include 'ms.g';                      # initiate measurement set tool
  include 'os.g';                      # initiate operating system tool

# Mandatory input parameters:
                                       # UVFITs data file
   FITSNAME      := 'AXAF1.FITS';
   MSNAME        := 'AXAFC1.ms';       # Measurement set name
#
# Optional input parameters (rarely changed);
#
   READONLY      := T;                 # Default
   LOCK          := F;                 # Default
   HOST          := '';                # Default
   FORCENEWSERVER:= F;                 # Default
#------------------------------------------------------------------------------
# SCRIPT COMMANDS:
#
  if (dos.fileexists (file=FITSNAME))  # Does fits file exist?      
  {  print 'Found file ', FITSNAME; 
#
# Construct the fitstoms tool and load in the data.
#
      mf:= fitstoms(msfile=MSNAME,     # Fitsoms function call
           fitsfile=FITSNAME, 
           readonly=READONLY,
           lock=LOCK,
           host=HOST,
           forcenewserver=FORCENEWSERVER);
#
      mf.summary();                    # Write summary of file on logger 
      mf.done();                       # Close constructor
  }
     else                              # Cannot find fitsfile. abort
  {   print '****** ERROR ******';
      print 'Did not find fitsfile ', fitsname;
      print 'Aborting fitstoms_scr.g';
  }
#------------------------------------------------------------------------------
#
#OUTPUT: 
#   New measurement set is created
#   Output is straight-forward.
#
#SUBMITTER: Ed Fomalont
#SUBMITAFFL: NRAO-Charlottesville
#SUBMITDATE: 2002-Mar-23
