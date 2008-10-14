# getrc.g: uses sh() to interact with the getrc utility
#
#   Copyright (C) 1996,1997,1998,1999,2001
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: getrc.g,v 19.1 2004/08/25 01:33:53 cvsmgr Exp $
#

pragma include once;

# This is used in a few places during startup to avoid dependencies which would
# happen if the aipsrc DO was used.  find always checks first to see if aipsrc
# exists and it uses that if it does. 

# since getrc should only be made once, this file does that and replaces the
# constructor with the closure.  It has only one public member function:

# ok := getrc.find(value, keyword, def=F, usehome=T)  # lookup an aipsrc value

# nothing is actually started until find is called.

getrc := function() {

    public := [=];
    public::print.limit := 1;

    private := [=];

    private.sh:=F;

    public.find := function(ref value, keyword, def=F, usehome=T) {
      wider private;
      found := F;
      cmd := 'getrc';
      if (!usehome) {
	cmd := paste(cmd, '-i');
      }
      cmd := paste(cmd, keyword, '2> /dev/null');
      
      result := shell(cmd);
      if(len(result) && result!='') {
	val value := result
	found := T;
      }
      else {
	found := F;
      }
      if (!found&&is_string(def)) val value := def;
      return found;
    }

    public.dbg := private;
    
    return public;
}
	
const getrc := getrc();
