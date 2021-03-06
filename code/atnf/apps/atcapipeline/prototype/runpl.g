#-----------------------------------------------------------------------------
# runpl.g: Script to run the ATCA pipeline in interactive CL mode
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

include 'atcapl.g'
include 'plgui.g'

# Initialise pipeline object
pl := atcapl()
display_intro()
pl.choose_global_options()

# Run process
if(pl.get_level() == BEGINNER || pl.get_level() == EXPERT){
  if(pl.get_flow() == ONE){
    while(1){
      # Run one stage at a time
      ok := pl.run_ui(pl.get_stage())
      if(is_fail(ok)) fail
      pl.choose_stage()
    }
  }
  else{
    print "Not implemented yet"
    pl.done()
  }
}

# End cleanly 
pl.done()



