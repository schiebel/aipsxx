# whenever_manager.g is part of the GDC server
# Copyright (C) 2000
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
# Correspondence concerning the GDC server should be addressed as follows:
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
# $Id: whenever_manager.g,v 19.0 2003/07/16 06:03:31 aips2adm Exp $
# ------------------------------------------------------------------------------

# whenever_manager.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++

# Description:
# ------------
# This file contains the glish function for manipulating glish "whenever"
# statements.

# glish function:
# ---------------
# whenever_manager.

# Modification history:
# ---------------------
# 2000 May 05 - Nicholas Elias, USNO/NPOI
#               File created with glish function whenever_manager{ }.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# whenever_manager

# Description:
# ------------
# This glish function creates a whenever_manager tool (interface) for
# manipulating glish "whenever" statements.

# Inputs:
# -------
# None.

# Outputs:
# --------
# The whenever_manager tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2000 May 05 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const whenever_manager := function( ) {

  # Initialize the variables

  whenever_list := F;
  
  public := [=];

  
  # Define the 'done' public member function
  
  const public.done := function( ) {
    wider public, whenever_list;
    whenever_list := F;
    val public := F;
    return( T );
  }
  
  
  # Define the 'whenever' public member function

  const public.whenever := function( gui = '', instance = '' ) {
    wider whenever_list;
    if ( gui == '' ) {
      return( !is_boolean( whenever_list ) );
    } else if ( !has_field( whenever_list, gui ) ) {
      return( F );
    } else if ( instance == '' ) {
      return( !is_boolean( whenever_list[gui] ) );
    } else if ( has_field( whenever_list[gui], instance ) ) {
      if ( !is_boolean( whenever_list[gui][instance] ) ) {
        return( T );
      } else {
        return( F );
      }
    } else {
      return( F );
    }
  }
  
  
  # Define the 'whenever_add' public member function
  
  const public.whenever_add := function( gui, instance ) {
    wider whenever_list;
    if ( !has_field( whenever_list, gui ) ) {
      whenever_list[gui] := F;
    }
    if ( !public.whenever( gui, instance ) ) {
      whenever_list[gui][instance] := last_whenever_executed();
      return( T );
    } else {
      return( F );
    }
  }
  
  
  # Define the 'whenever_delete' public member function
  
  const public.whenever_delete := function( gui = '', instance = '' ) {
    wider whenever_list;
    if ( !public.whenever( gui, instance ) ) {
      return( F );
    }
    if ( gui == '' ) {
      for ( g in 1:length(whenever_list) ) {
        for ( i in 1:length(whenever_list[g]) ) {
          deactivate whenever_list[g][i];
          whenever_list[g][i] := F;
        }
      }
    } else if ( instance == '' ) {
      for ( i in 1:length(whenever_list[gui]) ) {
        deactivate whenever_list[gui][i];
        whenever_list[gui][i] := F;
      }
    } else {
      deactivate whenever_list[gui][instance];
      whenever_list[gui][instance] := F;
    }
    return( T );
  }
  
  
  # Define the 'whenever_activate' public member function
  
  const public.whenever_activate := function( gui = '', instance = '' ) {
    wider whenever_list;
    if ( !public.whenever( gui, instance ) ) {
      return( F );
    }
    if ( gui == '' ) {
      for ( g in 1:length(whenever_list) ) {
        for ( i in 1:length(whenever_list[g]) ) {
          activate whenever_list[g][i];
        }
      }
    } else if ( instance == '' ) {
      for ( i in 1:length(whenever_list[gui]) ) {
        activate whenever_list[gui][i];
      }
    } else {
      activate whenever_list[gui][instance];
    }
    return( T );
  }
  
  
  # Define the 'whenever_deactivate' public member function
  
  const public.whenever_deactivate := function( gui = '', instance = '' ) {
    wider public, whenever_list;
    if ( !public.whenever( gui, instance ) ) {
      return( F );
    }
    if ( gui == '' ) {
      for ( g in 1:length(whenever_list) ) {
        for ( i in 1:length(whenever_list[g]) ) {
          deactivate whenever_list[g][i];
        }
      }
    } else if ( instance == '' ) {
      for ( i in 1:length(whenever_list[gui]) ) {
        deactivate whenever_list[gui][i];
      }
    } else {
      deactivate whenever_list[gui][instance];
    }
    return( T );
  }
  
  
  # Return the whenever manager
  
  return( ref public );

}
