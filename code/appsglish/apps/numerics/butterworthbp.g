# butterworthbp
# Copyright (C) 2001,2002
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
# $Id: butterworthbp.g,v 19.2 2004/08/25 01:42:58 cvsmgr Exp $

# include guard
# pragma include once
 
include "servers.g";
include "unset.g";

const _define_butterworthbp := function(ref serverid, toolid) {

    public:=[=];
    private:=[state=[=]];

    private.serverid := ref serverid;
    private.toolid := toolid;

    const public.type := 'butterworthbp';

    private.setRec := [_method='set', _sequence=private.toolid._sequence];

    public.set := function(bpass=unset, order=unset, peak=unset) {
	wider private;

	if (is_unset(bpass)) bpass := private.state.bpass;
	if (is_unset(order)) order := private.state.order;
	if (is_unset(peak)) peak := private.state.peak;

	if (length(order) == 1) order[2] := order[1];
	if (any(order < 0)) 
	    fail "butterworthbp.set(): negative order specified";

	private.setRec.bpass := sort(bpass);
	private.setRec.order := order;
	private.setRec.peak := peak;

	ok := defaultservers.run(private.serverid, private.setRec);
	if (is_fail(ok)) return ok;

	public.summary(private.state, verbose=F);
	return T;
    }

    private.evalRec := [_method='eval', _sequence=private.toolid._sequence];

    public.eval := function(x) {
	wider private;
	private.evalRec.x := x;
	ok := defaultservers.run(private.serverid, private.evalRec);
	if (is_fail(ok)) return ok;
	return private.evalRec.x;
    }
	
    private.summaryRec := [_method='summary', 
			   _sequence=private.toolid._sequence];

    public.summary := function(ref desc=[=], verbose=T) {
	wider private;

	private.summaryRec.verbose := verbose;
        ok := defaultservers.run(private.serverid, private.summaryRec);
	if (is_fail(ok)) return ok;
	val desc := private.summaryRec.hdr;
        return T;
    }

    # shut down this tool.  This function will close the input file.
    public.done:=function() { 
	wider private, public;
        ok := defaultservers.done(private.serverid, private.toolid.objectid);
        if (is_fail(ok)) fail;
	val private := F;
	val public := F;
	return T;
    }

    public.itemcon := function() {
	include 'itemcontainer.g';
	local data := [=];
	public.summary(data, verbose=F);

	local out := itemcontainer();
	out.fromrecord(private.state);
	out.set('_catagory', 'numericfunction');
	out.set('_nindep', 1);
	out.set('_name', 'butterworthbp');
	out.set('_include', 'butterworthbp.g');
	out.set('_constructor', 'butterworthbpfromic');
	out.makeconst();

	return ref out;
    }

#    public.private := ref private;

    public.summary(private.state, verbose=F);

    return ref public;
}

butterworthbp := function(bpass=unset, order=unset, peak=unset, 
			  host=unset, forcenewserver=F) 
{
    include 'servers.g';
    if (is_unset(host)) host := '';

#    defaultservers.suspend(T)
    serverid := defaultservers.activate('numerics', host, forcenewserver);
#    defaultservers.suspend(F)
    if(is_fail(serverid)) return serverid;
  
    toolid := defaultservers.create(serverid, 'butterworthbp');
    if(is_fail(toolid)) return toolid;
  
    local out := _define_butterworthbp(serverid, toolid);
    if (! is_unset(bpass) || ! is_unset(order) || ! is_unset(peak))
	out.set(bpass, order, peak);

    return ref out;
} 

butterworthbpfromic := function(ref itemcon, host=unset, forcenewserver=F) {
    include 'itemcontainer.g';

    if (! is_itemcontainer(itemcon) || 
	! itemcon.has_item('_name') ||
	itemcon.get('_name') != 'butterworthbp') 
      fail paste('attempt to create butterworthbp tool from', 
		 'non-butterworthbp itemcontainer');

    return butterworthbp(itemcon.get('bpass'), itemcon.get('order'), 
			 itemcon.get('peak'), host, forcenewserver);
} 

butterworthbpdemo := function() {
    include 'pgplotter.g';

    note('Create the function:\n',
	 '   butt := butterworthbp([0,1,2]);\n', origin='butterworthbpdemo');
    local butt := butterworthbp([0,1,2]);
    butt.summary();

    note('Set the low- and high-pass orders :\n   butt.set(order=[10, 13]);',
	 origin='butterworthbpdemo');
    butt.set(order=[10, 13]);

    note('Now evaluate and plot the function:\n',
	 '   x := [-50:150];\n',
	 '   x /:= 50.0;\n',
	 '   y := butt.eval(x);\n',
	 '   include \'pgplotter.g\';\n',
	 '   pg := pgplotter();\n',
	 '   pg.plotxy1(x, y, \'X\', \'Order: 10, 13\');',
	 origin='butterworthbpdemo');

    local x := [-50:150];
    x /:= 50.0;
    local y := butt.eval(x);
    local pg := pgplotter();
    pg.plotxy1(x, y, 'X', 'Order: 10, 13');

    note('Now see plotter for examples of curves with orders 0-6',
	 origin='butterworthbpdemo');

    for(i in [0:6]) {
	butt.set(order=i);
	y := butt.eval(x);
	pg.plotxy1(x, y, 'X', paste('Order:', i));
    }

    return T;
}
