# chebyshev: a Chebyshev polynomial series function
# Copyright (C) 2000,2001,2002
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
# $Id: chebyshev.g,v 19.2 2004/08/25 01:43:09 cvsmgr Exp $

# include guard
pragma include once
 
include "servers.g";
include "unset.g";

const _define_chebyshev := function(ref serverid, toolid) {

    public:=[=];
    private:=[=];

    private.serverid := ref serverid;
    private.toolid := toolid;
    private.defval := 0;

    private.setcoeffsRec := [_method='setcoeffs', 
			     _sequence=private.toolid._sequence];

    const public.type := 'chebyshev';

    public.setcoeffs := function(coeffs) {
	wider private;
	private.setcoeffsRec.coeffs := coeffs;
	ok := defaultservers.run(private.serverid, private.setcoeffsRec);
	if (is_fail(ok)) return ok;
	return T;
    }

    private.setdefaultRec := [_method='setdefault', 
			      _sequence=private.toolid._sequence];

    public.setdefault := function(def=unset, mode='default') {
	wider private;

	if (is_unset(def)) {
	    private.setdefaultRec.val := private.defval;
	} else {
	    private.setdefaultRec.val := def;
	}
	private.setdefaultRec.mode := mode;
	ok := defaultservers.run(private.serverid, private.setdefaultRec);
	if (is_fail(ok)) return ok;
	private.defval := private.setdefaultRec.val;
	return T;
    }

    private.setintervalRec := [_method='setinterval', 
			       _sequence=private.toolid._sequence];

    public.setinterval := function(xmin, xmax) {
	wider private;
	private.setintervalRec.min := xmin;
	private.setintervalRec.max := xmax;
	ok := defaultservers.run(private.serverid, private.setintervalRec);
	if (is_fail(ok)) return ok;
	return T;
    }

    private.evalRec := [_method='eval', _sequence=private.toolid._sequence];

    public.eval := function(x) {
	wider private;
	private.evalRec.val := x;
	ok := defaultservers.run(private.serverid, private.evalRec);
	if (is_fail(ok)) return ok;
	return private.evalRec.val;
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

    private.derivRec := [_method='derivative', 
			 _sequence=private.toolid._sequence];

    public.derivative := function(host=unset, forcenewserver=F) {
	wider private;
        local ok := defaultservers.run(private.serverid, private.derivRec);
	local hdr := ref private.derivRec.hdr;
	return chebyshev(hdr.coeffs, hdr.interval[1], hdr.interval[2], 
			 hdr.def, hdr.mode, host, forcenewserver);
    }

    public.itemcon := function() {
	include 'itemcontainer.g';
	local data := [=];
	public.summary(data, verbose=F);

	local out := itemcontainer();
	out.fromrecord(data);
	out.set('_catagory', 'numericfunction');
	out.set('_nindep', 1);
	out.set('_toolname', 'chebyshev');
	out.set('_include', 'chebyshev.g');
	out.set('_constructor', 'chebyshevfromic');
	out.makeconst();

	return ref out;
    }

#    public.private := ref private;

    return ref public;
}

const chebyshev := function(coeffs=[0], xmin=-1, xmax=+1, def=0, mode='default',
			    host=unset, forcenewserver=F) 
{
    include 'servers.g';
    if (is_unset(host)) host := '';

#    defaultservers.suspend(T)
    serverid := defaultservers.activate('numerics', host, forcenewserver);
#    defaultservers.suspend(F)
    if(is_fail(serverid)) return serverid;
  
    toolid := defaultservers.create(serverid, 'chebyshev');
    if(is_fail(toolid)) return toolid;
  
    local out := _define_chebyshev(serverid, toolid);
    out.setdefault(def, mode);
    out.setinterval(xmin, xmax);
    out.setcoeffs(coeffs);

    return ref out;
} 

const chebyshevfromic := function(ref itemcon, host=unset, forcenewserver=F) {
    include 'itemcontainer.g';

    if (! is_itemcontainer(itemcon) || 
	! itemcon.has_item('_toolname') ||
	itemcon.get('_toolname') != 'chebyshev') 
      fail paste('attempt to create chebyshev tool from', 
		 'non-chebyshev itemcontainer');

    intv := itemcon.get('interval');
    return chebyshev(itemcon.get('coeffs'), intv[1], intv[2], 
		     itemcon.get('def'), itemcon.get('mode'), 
		     host, forcenewserver);
} 

const chebyshevdemo := function(mode='default') {
    include 'chebyshev.g';
    include 'pgplotter.g';

    coeffs := [1];
    cheb := chebyshev(coeffs=coeffs, xmin=-100, xmax=100);
    cheb.setdefault(mode=mode);
    x := [-200:200];

    pg := pgplotter();
    print 'Creating a pgplotter:';
    print '   pg := pgplotter();';

    print 'Creating a chebyshev tool:';
    print '   coeffs := [1];';
    print '   cheb := chebyshev(coeffs=coeffs, xmin=-100, xmax=100);';
    print spaste('   cheb.setdefault(mode=',"'",mode,"'",');');
    print '   x := [-200:200];';

    print 'Evaluating & plotting Chebyshev polynomial with different',
	'coefficients:'
    coeffs := [1];
    for(i in [0:4]) {
	print spaste('   coeffs := [', 
		     paste(split(as_string(coeffs), ' '), sep=', '), '];');
	print '   cheb.eval(x);';
	print '   y := cheb.eval(x);';
	print '   pg.plotxy1(x, y);';

	y := cheb.eval(x);
	pg.plotxy1(x, y, ylab=paste('coeffs:', as_string(coeffs)));
	coeffs := [coeffs, 1];
        cheb.setcoeffs(coeffs);
    }
    pg.sci(1);
    pg.mtxt('T', 0.5, 0.5, 0.5, paste('Default mode:', mode));
    return T;
}
