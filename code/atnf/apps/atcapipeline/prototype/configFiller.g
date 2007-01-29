#-----------------------------------------------------------------------------
# configFiller.g: Filler Configuration class for the ATCA pipeline
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

include 'os.g'
include 'config.g'
include 'atcapl.g'
include 'error.g'
include 'interpreter.g'

configfiller := subsequence(pl){

  par := config(pl)
  INHERIT(self, par)
  its := INTERNAL(par)

  const its.parse_rpfitsnames := function(rpfitsnames){
    wider its

    its.rpfitsnames := [=]
    value := ['']
    names := split(rpfitsnames)

    anyvalid := F
    for(i in names){
      if(dos.fileexists(i) == F){
        printf('Warning: Invalid FITS file name %s\n', i)
        continue
      }
      value := [value, i]
      anyvalid := T
    }
    if(anyvalid){
      ok := its.set_rpfitsnames(value)
      if(is_fail(ok)) return fatal(PARMERR, 'Error settig rpfitsnames', ok::)
      its.rpfitsnames.mode := 'override'
    }
    else
      return fatal(IOERR, 'No valid RPFITS files entered')
    return T
  }

  const its.set_rpfitsnames := function(rpfitsnames){
    return its.set('rpfitsnames',1,'const','string','Names of RPFITs files','rpfitsnames',rpfitsnames)
  }

  const self.determine_logic := function(){
    # do nothing - not needed yet
    return T
  }

  const self.load_meta := function(){
    # do nothing - don't need any metadata yet
    return T
  }

  const self.calc := function(){
    # do nothing - don't need this yet
    return T
  }

  const self.ask_fitsname := function(){
    if(its.level.val != AUTO && its.level.val != WS){
      valid := F
      while(!valid){
        rpfitsnames := readline(prompt='Enter name of input FITS file/s: (no default)>> ')
        names := split(rpfitsnames)
        valid := T
#        for(i in names){
#          if(!dos.fileexists(i)){
#            print 'The file you have chosen does not exist.'
#            valid := F
#            break
#          }
#        }
      }
      ok := its.set_rpfitsnames(rpfitsnames)
      if(is_fail(ok)) return fatal(IOERR, 'Error setting RPFITS name', ok::)
    }
    return T
  }


# Constructor
  ok := its.load('default.filler.config', FILL)
  if(is_fail(ok)) 
    return fatal(PARMERR, 'Error loading config file for Filler', ok::)

  ok := self.copy_general_config(pl)
  if(is_fail(ok))
    return fatal(PARMERR, 'Error transferring settings to Filler config', ok::)

  ok := self.ask_fitsname()
  if(is_fail(ok))
    return fatal(IOERR, 'Error setting RPFITS name', ok::)
}









