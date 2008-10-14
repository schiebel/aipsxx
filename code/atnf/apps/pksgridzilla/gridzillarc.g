#-----------------------------------------------------------------------------
# gridzillarc.g - Startup script for the Parkes Multibeam gridder.
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
# $Id: gridzillarc.g,v 19.3 2004/10/19 06:31:28 mcalabre Exp $
#-----------------------------------------------------------------------------
# gridzillarc.g
#-----------------------------------------------------------------------------
# Startup script for the Parkes Multibeam gridder.  Copies environment
# variables into Glish global variables and then invokes gridzilla with GUI.
#
# The settings may be tailored via environment variable definitions as defined
# in a user's personal ~/.glishrc file or elsewhere.
#
# Environment:
#    AIPSPATH              AIPS++ directory hierarchy.
#    GRIDZILLA_MODE        Set to 'HIPASS', 'HVC' or 'ZOA' to enforce
#                          processing restrictions.
#    GRIDZILLA_SCRIPT_DIR  Directory where glish scripts reside.
#    GRIDZILLA_CLIENT_DIR  Directory where the gridder binary resides.
#    GRIDZILLA_ICON_DIR    Directory where the gridzilla icon resides.
#    GRIDZILLA_CUBCEN_DIR  If MB_CATALOG_PATH (as required by 'coverage') is
#                          not defined then this may be used to specify the
#                          directory containing the standard cube centre
#                          files, HIPASS_CUBE_CENTRES and HVC_CUBE_CENTRES.
#    GRIDZILLA_READ_DIR    Directory where the input files reside.
#    GRIDZILLA_WRITE_DIR   Directory where the output files are written.
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
if (has_field(environ, 'GRIDZILLA_MODE')) {
  args.config := environ.GRIDZILLA_MODE

  if (any(args.config == "HIPASS HVC ZOA")) {
    print spaste('    Using GRIDZILLA_MODE: "', args.config,
                 '" - enforcing ', args.config, ' processing options.')

  } else {
    # Unrecognized configuration, use GENERAL.
    args.config := 'GENERAL'
  }
}

# AIPS++ system area.
aipsarch := paste(split(environ.AIPSPATH)[1],
                  split(environ.AIPSPATH)[2], sep='/')

# Where glish scripts reside.
if (has_field(environ, 'GRIDZILLA_SCRIPT_DIR')) {
  system.path.include := ['.', environ.GRIDZILLA_SCRIPT_DIR]
  print spaste('Using GRIDZILLA_SCRIPT_DIR: ". ',
               environ.GRIDZILLA_SCRIPT_DIR, '"')
} else {
  system.path.include := ['.', paste(aipsarch, 'libexec', sep='/')]
}

# Where client binaries reside.
if (has_field(environ, 'GRIDZILLA_CLIENT_DIR')) {
  args.client_dir := environ.GRIDZILLA_CLIENT_DIR
  print spaste('Using GRIDZILLA_CLIENT_DIR: "', args.client_dir, '"')
} else {
  args.client_dir := paste(aipsarch, 'bin', sep='/')
}

# Where the gridzilla icon resides.
if (has_field(environ, 'GRIDZILLA_ICON_DIR')) {
  tk_iconpath(['.', environ.GRIDZILLA_ICON_DIR])
  print spaste('  Using GRIDZILLA_ICON_DIR: ". ', environ.GRIDZILLA_ICON_DIR,
               '"')
} else {
  tk_iconpath(['.', spaste(aipsarch, '/libexec/icons')])
}

# Where the standard cube centre files reside.
if (has_field(environ, 'GRIDZILLA_CUBCEN_DIR')) {
  args.cubcen_dir := environ.GRIDZILLA_CUBCEN_DIR
  print spaste('Using GRIDZILLA_CUBCEN_DIR: "',
               environ.GRIDZILLA_CUBCEN_DIR, '"')
} else {
  args.cubcen_dir := '/nfs/atapplic/multibeam/archive'
}

# Where the input files reside.
if (has_field(environ, 'GRIDZILLA_READ_DIR')) {
  args.directories := environ.GRIDZILLA_READ_DIR
  print spaste('  Using GRIDZILLA_READ_DIR: "', args.directories, '"')
}

# Where the output cubes are written.
if (has_field(environ, 'GRIDZILLA_WRITE_DIR')) {
  args.write_dir := environ.GRIDZILLA_WRITE_DIR
  print spaste(' Using GRIDZILLA_WRITE_DIR: "', args.write_dir, '"')
}

print ''

#-----------------------------------------------------------------------------

# Let users interact with it via a GUI.
grc.frame := frame(title='Parkes Multibeam Gridder', icon='gridzilla.xbm')

# Check for basic problems.
if (is_fail(grc.frame)) {
  print '\n\nWindow creation failed - check that the DISPLAY environment',
        'variable is set\nsensibly and that you have done \'xhost +\' as',
        'necessary.\n'
  exit
}

grc.message := label(grc.frame, 'Starting gridzilla...')

# Instantiate a gridder controller.
include 'gridzilla.g'
gridder := gridzilla()
if (is_fail(gridder)) {
  print gridder
  exit
}

gridder->setparm(args)

# Create the GUI.
grc.message := F
gridder->showgui(grc.frame)

whenever
  gridder->done do
    exit
