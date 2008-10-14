#-----------------------------------------------------------------------------
# livedata.g: Startup script for Parkes multibeam data reduction.
#-----------------------------------------------------------------------------
# Copyright (C) 1996-2006
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
# $Id: livedata.g,v 19.9 2006/02/14 07:28:49 mcalabre Exp $
#-----------------------------------------------------------------------------
# Startup script for Parkes Multibeam data reduction.  Copies environment
# variables into Glish global variables and then invokes a livedatascheduler
# with GUI.
#
# The settings may be tailored via environment variable definitions as defined
# in a user's personal ~/.glishrc file or elsewhere.
#
# Environment:
#    AIPSPATH             AIPS++ directory hierarchy.
#    LIVEDATA_MODE        Set to 'HIPASS' to enforce HIPASS restrictions.
#    LIVEDATA_SCRIPT_DIR  Directory where glish scripts reside.
#    LIVEDATA_CLIENT_DIR  Directory where client binaries reside.
#    LIVEDATA_ICON_DIR    Directory where the livedata icon resides.
#    LIVEDATA_READ_DIR    Directory where the input files reside.
#    LIVEDATA_READ_RETRY  Number of times (> 0) the MBFITS reader should retry
#                         reading the input file after it encounters an EOF.
#                         There is a 10s wait between retries.  This is
#                         provided for realtime reading of the file as it is
#                         being written by the correlator.
#    LIVEDATA_WRITE_DIR   Directory where the output files are written.
#
# Original: 1998/09/16, Mark Calabretta
#-----------------------------------------------------------------------------
pragma include once

# Check that DISPLAY is defined.
if (!has_field(environ, 'DISPLAY')) {
  print 'DISPLAY is not defined - abort!'
  exit
}

# Check that AIPSPATH is defined.
if (!has_field(environ, 'AIPSPATH')) {
  print 'AIPSPATH is not defined - abort!'
  exit
}


# Get arguments from environment variables.
args := [=]

# Restricted processing modes or generic?
if (has_field(environ, 'LIVEDATA_MODE')) {
  args.config := environ.LIVEDATA_MODE

  if (args.config == 'AUDS') {
    # Arecibo ALFA Ultra Deep Survey, no parameters are enforced.
    args.read_mask := '*.fits'
    print spaste('      Using LIVEDATA_MODE: "', args.config,
                 '" - setting AUDS processing options.')

  } else if (args.config == 'GASS') {
    # Parkes Galactic All Sky Survey, no parameters are enforced.
    args.read_mask := '*.hpf'
    print spaste('      Using LIVEDATA_MODE: "', args.config,
                 '" - setting GASS processing options.')

  } else if (args.config == 'HIPASS') {
    # HI Parkes All Sky Survey - certain parameters are fixed.
    args.read_mask := '*.hpf'
    print spaste('      Using LIVEDATA_MODE: "', args.config,
                 '" - enforcing HIPASS processing options.')

  } else if (args.config == 'HVC') {
    # Parkes High Velocity Cloud survey - certain parameters are fixed.
    print spaste('      Using LIVEDATA_MODE: "', args.config,
                 '" - enforcing HVC processing options.')

  } else if (args.config == 'METHANOL') {
    # Parkes Methanol survey, no parameters are enforced.
    args.read_mask := '*.rpf'
    print spaste('      Using LIVEDATA_MODE: "', args.config,
                 '" - setting METHANOL processing options.')

  } else if (args.config == 'MOPRA') {
    # Mopra OTF mapping, no parameters are enforced.
    args.read_mask := '*.rpf'
    print spaste('      Using LIVEDATA_MODE: "', args.config,
                 '" - setting MOPRA processing options.')

  } else if (args.config == 'ZOA') {
    # Zone Of Avoidance survey - certain parameters are fixed.
    args.read_mask := '*.hpf'
    print spaste('      Using LIVEDATA_MODE: "', args.config,
                 '" - enforcing ZOA processing options.')

  } else {
    # Unrestricted usage.
    if (args.config != 'CONTINUUM') args.config := 'GENERAL'
    print spaste('      Using LIVEDATA_MODE: "', args.config, '"')
  }
}

# AIPS++ system area.
aipsarch := paste(split(environ.AIPSPATH)[1],
                  split(environ.AIPSPATH)[2], sep='/')

# Where glish scripts reside.
if (has_field(environ, 'LIVEDATA_SCRIPT_DIR')) {
  system.path.include := ['.', environ.LIVEDATA_SCRIPT_DIR]
  print spaste('Using LIVEDATA_SCRIPT_DIR: ". ', environ.LIVEDATA_SCRIPT_DIR,
               '"')
} else {
  system.path.include := ['.', paste(aipsarch, 'libexec', sep='/')]
}

# Where client binaries reside.
if (has_field(environ, 'LIVEDATA_CLIENT_DIR')) {
  args.client_dir := environ.LIVEDATA_CLIENT_DIR
  print spaste('Using LIVEDATA_CLIENT_DIR: "', args.client_dir, '"')
} else {
  args.client_dir := paste(aipsarch, 'bin', sep='/')
}

# Where the livedata icon resides.
if (has_field(environ, 'LIVEDATA_ICON_DIR')) {
  tk_iconpath(['.', environ.LIVEDATA_ICON_DIR])
  print spaste('  Using LIVEDATA_ICON_DIR: ". ', environ.LIVEDATA_ICON_DIR,
               '"')
} else {
  tk_iconpath(['.', spaste(aipsarch, '/libexec/icons')])
}

# Number of read retries.
if (has_field(environ, 'LIVEDATA_READ_RETRY')) {
  args.read_retry := environ.LIVEDATA_READ_RETRY
  if (!(is_integer(args.read_retry) && args.read_retry > 1)) {
    args.read_retry := 1
  }
  print 'Using LIVEDATA_READ_RETRY:', args.read_retry
}

# Where the input files reside.
if (has_field(environ, 'LIVEDATA_READ_DIR')) {
  args.read_dir := environ.LIVEDATA_READ_DIR
  print spaste('  Using LIVEDATA_READ_DIR: "', args.read_dir, '"')
}

# Where the output files are written.
if (has_field(environ, 'LIVEDATA_WRITE_DIR')) {
  args.write_dir := environ.LIVEDATA_WRITE_DIR
  print spaste(' Using LIVEDATA_WRITE_DIR: "', args.write_dir, '"')
}

print ''

#-----------------------------------------------------------------------------

# Instantiate a scheduler.
include 'livedatascheduler.g'
ldsched := scheduler()
if (is_fail(ldsched)) exit

ldsched->setparm(args)

# Create the GUI.
ldsched->showgui()

if (args.config == 'HIPASS') {
  # Start clients.
  await ldsched->guiready
  ldsched.reducer->setparm([bandpass = T,
                            monitor  = T,
                            stats    = T,
                            writer   = T])
}

whenever
  ldsched->done do
    exit
