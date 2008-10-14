#-----------------------------------------------------------------------------
# plgui.g: Display functions for the ATCA pipeline
#-----------------------------------------------------------------------------
# Copyright (C) 1996-2004
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id:
#-----------------------------------------------------------------------------
#

pragma include once

const display_quick_help := function(){
  printf('Usage: glish runws.g --stage <stage> --msname <msname>\n')
  printf('       --outdir <outdir> [OPTION]...\n')
  printf('\n')
  printf('  Run ATCA pipeline in one of 4 stages fill, edit, calib or image\n')
  printf('  Usage instructions depend on the stage being run. For more information:\n')
  printf('\n')
  printf('  > glish runws.g --help\n')
  printf('\n')
  printf('  To run in interactive mode, run:\n')
  printf('  > glish runpl.g\n')
  printf('\n')
  exit
}

const display_ws_help := function(){
  printf('Usage: glish runws.g --stage <stage> --msname <msname>\n')
  printf('       --outdir <outdir> [OPTION]...\n')
  printf('\n')
  printf('  Run ATCA pipeline in one of 4 stages fill, edit, calib or image\n')
  printf('  Usage instructions depend on the stage being run - see below\n')
  printf('\n')
  printf('  To run in interactive mode, run:\n')
  printf('  > glish runpl.g\n')
  printf('\n')
  printf('-----------------------------------------------\n')
  printf('Filling\n')
  printf('-----------------------------------------------\n')
  printf('Mandatory:\n')
  printf('  --stage          followed by the word FILL\n')
  printf('  --msname         the name for the output measurement set\n')
  printf('  --outdir         a directory for results (images/plots/logs)\n')
  printf('  --rpfitsnames    the names of the input FITS files\n')
  printf('\n')
  printf('Optional:\n')
  printf('  --options        filling options, choose 1 or more from\n') 
  printf('                     (birdie|reweight|noxycorr|compress|fastmosaic)\n')
  printf('                     eg. --options "birdie reweight"\n')
  printf('  --sourceNames    list of field names (sources) to select\n')
  printf('  --ifchain        select IF 1 or IF 2\n')
  printf('  --lowfreq        the lowest frequency to load (eg. 1GHz\n')
  printf('  --highfreq       the highest frequency to load (eg. 2GHz)\n')
  printf('  --firstscan      the first scan to load\n')
  printf('  --lastscan       the last scan to load\n')
  printf('  --numchan        select on the number of channels in the first IF\n')
  printf('  --bandwidth      select on the bandwidth of the first IF (in MHz)\n')
  printf('  --shadow         dish size for flagging shadowed data (in metres)\n')
  printf('\n')    
  printf('-----------------------------------------------\n')
  printf('Editing\n')
  printf('-----------------------------------------------\n')
  printf('Mandatory:\n')
  printf('  --stage          followed by the word EDIT\n')
  printf('  --msname         the name of the input measurement set\n')
  printf('  --outdir         a directory for results (images/plots/logs)\n')
  printf('\n')
  printf('Optional:\n')
  printf('  --doFlagging     do you want to run automatic flagging? T or F\n')
  printf('  --threshold      threshold for time-median flagging (no. of std devs)\n')
  printf('  --plotRaw        do you want to plot the raw data? T or F\n')
  printf('  --plotFlagged    do you want to plot the flagged data? T or F\n')
  printf('\n')
  printf('-----------------------------------------------\n')
  printf('Calibration\n')
  printf('-----------------------------------------------\n')
  printf('Mandatory:\n')
  printf('  --stage          followed by the word CALIB\n')
  printf('  --msname         the name of the input measurement set\n')
  printf('  --outdir         a directory for results (images/plots/logs)\n')
  printf('  --ddesc          EITHER process a data subset by identifying it by\n')
  printf('                     freq,bandwidth,channels,polarizations \n') 
  printf('                     eg. --ddesc \'1384MHz\',\'128MHz\',33,4\n')
  printf('                   OR process all of the data use the word all\n')
  printf('                     eg. --ddesc all\n')
  printf('\n')
  printf('Optional:\n')
  printf('  --primary        follows the --ddesc flag to define the primary calibrator\n')
  printf('                     for that data set. eg. --primary 1934-638\n')
  printf('  --calibrators    follows the --ddesc flag to define the\n')
  printf('                     target-calibrator matches for that data set.\n')
  printf('                     eg. --ddesc all --calibrators ACO3266b,0438-436\n')
  printf('                     defines the target as AC03266b and the secondary \n')
  printf('                     calibrator as 0438-436 for the entire data set\n')
  printf('  --refant         reference antenna to use for calibration\n')
  printf('  --intervalP      interval for parallactic angle correction (in seconds)\n')
  printf('  --intervalG      calibration interval for gains (in seconds)\n')
  printf('  --intervalD      calibration interval for leakages (in seconds)\n')
  printf('  --intervalB      calibration interval for bandpass (in seconds)\n')
  printf('\n')
  printf('-----------------------------------------------\n')
  printf('Imaging\n')
  printf('-----------------------------------------------\n')
  printf('Mandatory:\n')
  printf('  --stage          followed by the word IMAGE\n')
  printf('  --msname         the name of the input measurement set\n')
  printf('  --outdir         a directory for results (images/plots/logs)\n')
  printf('  --ddesc          EITHER process a data subset by identifying it by\n')
  printf('                     freq,bandwidth,channels,polarizations \n') 
  printf('                     eg. --ddesc \'1384MHz\',\'128MHz\',33,4\n')
  printf('                   OR process all of the data use the word all\n')
  printf('                     eg. --ddesc all\n')
  printf('\n')
  printf('Optional:\n')
  printf('  --targetNames    follows the --ddesc flag to define the target sources\n')
  printf('                   to be imaged for that data set. eg. --targetNames A3266\n')
  printf('  --mode           type of processing (channel|mfs|velocity)\n')
  printf('  --stokes         which stokes parameters to image eg. IQUV \n')
  printf('  --nx             size of image in pixels (X axis)\n')
  printf('  --ny             size of image in pixels (Y axis)\n')
  printf('  --doClean        do you want to deconvolve using CLEAN? T or F\n')
  printf('  --algorithm      which CLEAN algorithm to use, choose from:\n')
  printf('                     (hogbom|clark|multiscale)\n')
  printf('  --niter          number of CLEAN iterations to perform\n')
  printf('  --loopgain       loop gain for cleaning\n')
  printf('  --threshold      flux level at which to stop CLEANing eg. 0Jy\n')
  printf('  --doMem          do you want to deconvole using MEM? T or F\n')
  printf('  --malgorithm     which MEM algorithm to use, choose from:\n')
  printf('                     (entropy|emptiness)\n')
  printf('  --mniter         number of MEM iterations to perform\n')
  printf('  --sigma          image sigma to try to achieve (using MEM) eg. 0.001Jy\n')
  printf('  --targetflux     target flux for image (using MEM) eg. 1.0Jy\n')
  exit
}

const display_intro := function(){
  printf('\n')
  printf('%---------------------------------------------%\n')
  printf('%                                             %\n')
  printf('% Welcome to the ATCA data reduction pipeline %\n')
  printf('% (currently a prototype only)                %\n')
  printf('%                                             %\n')
  printf('%---------------------------------------------%\n')
#  printf('\n')
  return T
}

const display_mode := function(){
  printf('\n')
  printf('-----------------------------------------------\n')
  printf('\n')
  printf('Please select mode to run pipeline in:\n')
  printf('         Synthesis\n')
#  printf('         spectral Line\n')
#  printf('         Pulsar bin\n')
  printf('         eXit\n')
  return readline(prompt='Choose mode (default = S) >> ') 
}

const display_flow := function(){
  printf('\n')
  printf('-----------------------------------------------\n')
  printf('\n')
  printf('Please select how to run pipeline:\n')
  printf('         One stage at a time\n')
#  printf('         Preset\n')
#  printf('         Load configs\n')
  printf('         eXit\n')
  return readline(prompt='Choose mode (default = O) >> ')
}

const display_stage := function(){
  printf('\n')
  printf('-----------------------------------------------\n')
  printf('\n')
  printf('Please select stage of pipeline to run:\n')
  printf('         Fill data\n')
  printf('         Edit data\n')
  printf('         Calibrate data\n')
  printf('         Image data\n')
  printf('         eXit\n')
  return readline(prompt='Choose stage (default = F) >> ')
}

const display_level := function(){
#  printf('\n')
#  printf('-----------------------------------------------\n')
  printf('\n')
  printf('Please select level to run pipeline at:\n')
  printf('         Beginner\n')
  printf('         Advanced\n')
  printf('         eXit\n')
  return readline(prompt='Choose level (default = B) >> ')
}
