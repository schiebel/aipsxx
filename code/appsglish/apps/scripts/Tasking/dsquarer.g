# dsquarer.g: Access to the demonstration squarer class
# Copyright (C) 1996,1997,2002
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#

if (! is_defined('squarer_g_included')) {
    squarer_g_included := 'yes';

include "servers.g"
#defaultservers.trace(T)   # useful for seeing exactly what's going on.
                           # Voluminous output!
#defaultservers.suspend(T) # useful for debugging so you can attach
                           # to the servers pid.

const squarer := function(host='', forcenewserver = F) {
    private := [=]
    public := [=]
	
    private.agent := defaultservers.activate("dsquarer", host, 
                                        forcenewserver)
    private.id := defaultservers.create(private.agent, "squarer")

    private.squareRec := [_method="square", _sequence=private.id._sequence]
    public.square := function(v) {
  	wider private
        private.squareRec["val"] := v
 	return defaultservers.run(private.agent, private.squareRec)
    }

    # It is often useful to have an id() that returns the object id.
    public.id := function()
    {
	wider private;
	return private.id.objectid;
    }

    # This is the equivalent of a destructor, it destructs the server object,
    # shuts down the server if there are no more objects in it, and causes the
    # glish proxy object to be "destoryed".
    public.done := function()
    {
	wider private, public;
	ok := defaultservers.done(private.agent, public.id());
	if (ok) {
	    private := F;
	    val public := F;
	}
	return ok;
    }

    return ref public
}  # constructor

} # include guard

sq := squarer();

t0 := time();
for (i in 1:5000) {
   sq2 := sq.square(i);
}

if (sq2 != i*i) {
    print "Fail!"
}

print "\nMethod invocations per second: ", i/(time() - t0)

sq.done();
exit
