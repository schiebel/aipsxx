# cuttlefish.g is part of Cuttlefish (NPOI data reduction package)
# Copyright (C) 1999,2000,2001
# United States Naval Observatory; Washington, DC; USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is designed for use only in AIPS++ (National Radio Astronomy
# Observatory; Charlottesville, VA; USA) in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
# See the GNU Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning Cuttlefish should be addressed as follows:
#        Internet email: nme@nofs.navy.mil
#        Postal address: Dr. Nicholas Elias
#                        United States Naval Observatory
#                        Navy Prototype Optical Interferometer
#                        P.O. Box 1149
#                        Flagstaff, AZ 86002-1149 USA
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: cuttlefish.g,v 19.0 2003/07/16 06:02:01 aips2adm Exp $
# ------------------------------------------------------------------------------

# cuttlefish.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file initializes the Cuttlefish glish/aips++ package.

# Modification history:
# ---------------------
# 1999 Jan 29 - Nicholas Elias, USNO/NPOI
#               File created.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Set constants

const format_const := to_upper( "ASCII HDS TABLE" );

# ------------------------------------------------------------------------------

# Include general Cuttlefish *.g files (do not modify)

if ( !include 'hds.g' ) {
  throw( 'Cannot include hds.g ...', origin = 'cuttlefish' );
}

if ( !include 'gdc1.g' ) {
  throw( 'Cannot include gdc1.g ...', origin = 'cuttlefish' );
}

if ( !include 'gdc1token.g' ) {
  throw( 'Cannot include gdc1token.g ...', origin = 'cuttlefish' );
}

if ( !include 'gdc2token.g' ) {
  throw( 'Cannot include gdc2token.g ...', origin = 'cuttlefish' );
}


# Include Cuttlefish *.g files for *.cha files (do not modify)

if ( !include 'delayjitter.g' ) {
  throw( 'Cannot include delayjitter.g ...', origin = 'cuttlefish' );
}

if ( !include 'drydelay.g' ) {
  throw( 'Cannot include drydelay.g ...', origin = 'cuttlefish' );
}

if ( !include 'geoparms.g' ) {
  throw( 'Cannot include geoparms.g ...', origin = 'cuttlefish' );
}

if ( !include 'grpdelay.g' ) {
  throw( 'Cannot include grpdelay.g ...', origin = 'cuttlefish' );
}

if ( !include 'ibconfig.g' ) {
  throw( 'Cannot include ibconfig.g ...', origin = 'cuttlefish' );
}

if ( !include 'fdlpos.g' ) {
  throw( 'Cannot include fdlpos.g ...', origin = 'cuttlefish' );
}

if ( !include 'loginfo.g' ) {
  throw( 'Cannot include loginfo.g ...', origin = 'cuttlefish' );
}

if ( !include 'natjitter.g' ) {
  throw( 'Cannot include natjitter.g ...', origin = 'cuttlefish' );
}

if ( !include 'obconfig.g' ) {
  throw( 'Cannot include obconfig.g ...', origin = 'cuttlefish' );
}

if ( !include 'scaninfo.g' ) {
  throw( 'Cannot include scaninfo.g ...', origin = 'cuttlefish' );
}

if ( !include 'sysconfig.g' ) {
  throw( 'Cannot include sysconfig.g ...', origin = 'cuttlefish' );
}

if ( !include 'wetdelay.g' ) {
  throw( 'Cannot include wetdelay.g ...', origin = 'cuttlefish' );
}


# Include specialized Cuttlefish *.g files (modify, if necessary)

if ( !include 'melvin.g' ) {
  throw( 'Cannot include melvin.g ...', origin = 'cuttlefish' );
}


# Set system variable

system.print.precision := 17;

