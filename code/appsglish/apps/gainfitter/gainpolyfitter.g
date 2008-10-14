# gainpolyfitter.g: Performs fits for gainpolyfitter.
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
# $Id: gainpolyfitter.g,v 19.1 2004/08/25 01:16:25 cvsmgr Exp $

pragma include once;

include 'gainpolyfit.g';
include 'gpftablereader.g';
include 'gainpolyfittergui.g';
include 'os.g';
include 'table.g';
include 'measures.g';
include 'polyfitter.g';
include 'itemmanager.g';

#@itemcontainer GainPolyFitterOptionsItem
# contains options for configuring the default behavior of a gainpolyfitter 
# tool.  Users normally do not create these items themselves; they are used
# primarily for creating gainpolyfitter tool constructors specialized for 
# certain telescopes.  The gainpolyfitter.getoptions() function will return
# an itemcontainer of this type.
# @field type      must be set to 'GainPolyFitterOptionsItem'
# @field nsamp     the default number of samples to evaluate when displaying
#                     a representation of a fit.
# @field autofit   if true, automatically fit the gains whenever
# @field readopts  reader options as a GainTableReaderOptionsItem
# @field guiopts   gui options as a GainPolyFitterGuiOptionsItem
##

const GAINPOLYFITTEROPTIONSITEM := 'GainPolyFitterOptionsItem';

const DEFAULT_GPFOPTIONS := 
    [type=GAINPOLYFITTEROPTIONSITEM, autofit=T, tsampintv=60, fsampintv=1000,
     extrapolate=F, readopts=DEFAULT_GPFREADOPTIONS, 
     plotopts=DEFAULT_GPFPLOTTEROPTIONS, guiopts=DEFAULT_GPFGUIOPTIONS ];

BIMA_GPFOPTIONS := DEFAULT_GPFOPTIONS;
BIMA_GPFOPTIONS.readopts.gainfilter := [jones=['1 1']];
BIMA_GPFOPTIONS.readopts.selaxes := "Ant Sideband";
BIMA_GPFOPTIONS.readopts.selindex := "ANTENNA1 spw";
BIMA_GPFOPTIONS.guiopts.axisbuttonlayout := [=];
BIMA_GPFOPTIONS.guiopts.axisbuttonlayout[1] := "Ant";
BIMA_GPFOPTIONS.guiopts.axisbuttonlayout[2] := "Sideband Component";
# BIMA_GPFOPTIONS.guiopts.xscale := "1/3";
# BIMA_GPFOPTIONS.guiopts.yscale := "1/4";
BIMA_GPFOPTIONS.plotopts.errorbarscale := 3;
BIMA_GPFOPTIONS.plotopts.linestyle := "none";
BIMA_GPFOPTIONS.axisdecor := [Sideband=[labels="Lower Upper", 
					initstate=[T, T], 
					showtitle=T, tags="LSB USB"],
			      Component=[labels="Phase Amp", initstate=[T, T], 
					 showtitle=T, tags="Phase Amp"],
			      Ant=[initstate=rep(T,3)]];

# This gets around a calibrater bug
BIMA_GPFOPTIONS.readopts.fudgewts := T;

VLA_GPFOPTIONS := DEFAULT_GPFOPTIONS;
ATCA_GPFOPTIONS := DEFAULT_GPFOPTIONS;

const GPF_4COMPVALUES := "Phase Amp Real Imag";
const GPF_2COMPVALUES := "Phase Amp";
const GPF_COMPVALUES := GPF_2COMPVALUES;
const GPF_AMP := GPF_2COMPVALUES[2];
const GPF_PHASE := GPF_2COMPVALUES[1];
const GPF_REAL := GPF_4COMPVALUES[3];
const GPF_IMAG := GPF_4COMPVALUES[4];

#@tool public gainpolyfitter
#  a tool for fitting polynomials to a set of antenna gains obtained from 
#  a gain table
#
#@constructor
# create a gainpolyfitter tool.
# @param  gains       the name of the input gains table.  No default.
# @param  loadfits    load any previously calculated fits from the table, if 
#                     they exist.  This may cause some options to be 
#                     overridden.
# @param  validonly   if true, only valid (pre-fit) gain solutions be loaded.
#                     The default is false, loading all gains; however, invalid
#                     gains will be masked as bad.
# @param  options     the options for setting up the tool as a record with 
#                     one or more fields that make up a 
#                     GainPolyFitterOptionsItem.  These will override the 
#                     default values that defined in DEFAULT_GPFOPTIONS.  
#                     Other predefined values include BIMA_GPFOPTIONS, 
#                     ATCA_GPFOPTIONS, and VLA_GPFOPTIONS.
gainpolyfitter := function(gains, gui=T, loadfits=T, validonly=F, options=F) {
    private := [=];
    public := [=];
    data := [tablename=gains, gpfit=[=], fitter=polyfitter(), 
	     sampset=F, gui=F];

    data.opts := itemmanager(type=GAINPOLYFITTEROPTIONSITEM, 
			     name='gpfoptions');
    data.opts.fromrecord(DEFAULT_GPFOPTIONS);
    if (is_record(options)) data.opts.fromrecord(options);

    data.axisdecor := data.opts.get('axisdecor');
    data.axisdecor::filled := F;
    data.decorlisteners := listenermanager('gpfdecoration');
    data.actionlisteners := listenermanager('gpfaction');
    
    # read in the data
    local rdr := gpftablereader(gains, data.opts.get('readopts'));
    rdr.loadgpfdata(data, loadfits, validonly);
    rdr.done();

    #@ 
    # return the full set of fitter options.  This is not normally
    # used by the interactive user but rather by supporting tools or 
    # specialized scripts.
    ##
    public.getoptions := function() {
	wider data;
	return data.opts.torecord();
    }

    #@
    # return the value of an option.  This is not normally
    # used by the interactive user but rather by supporting tools or 
    # specialized scripts.
    # @param name     the option name
    ##
    public.getoption := function(name) { 
	wider data; 
	return data.opts.get(name);
    }

    #@
    # set the value of an option.  Listeners will be notified about change.
    # It is only possible to set top level options.  This is not normally
    # used by the interactive user but rather by supporting tools or 
    # specialized scripts.
    # @param name     the option name
    # @param value    the new value to assign
    # @param who      the name of the actor setting this change.  This 
    #                     will be sent to listeners.  The default is an 
    #                     empty string, indicating that the actor is 
    #                     anonymous.
    # @param skipwho  if true (the default), the listener associated
    #                     this name will not be notified.
    ##
    public.setoption := function(name, value, who='', skipwho=T) {
	wider data;
	if (! data.opts.has_item(name)) 
	    fail paste('setoption: unrecognized option:', name);
	data.opts.set(name, value, who=who, skipwho=skipwho);
	return T;
    }

    #@
    # get the decoration associated with a given axis.  This is not normally
    # used by the interactive user but rather by supporting tools used to
    # support plotting and GUIs.
    # @param axis  the axis name, as in one of the values returned by 
    #                   fitsetaxes().  In addition, an extra axis name,
    #                   Component is supported to set decoration attributes
    #                   associated with components of the gains
    ##
    public.axisdecoration := function(axis) {
	wider private, data;
	if (! data.axisdecor::filled) private.fillaxisdecor();
	if (! has_field(data.axisdecor, axis)) 
	    fail paste('axisdecoration: axis name not found:', axis);
	return data.axisdecor[axis];
    }

    #@
    # get the decoration item associated with a given axis.  This is not 
    # normally used by the interactive user but rather by supporting tools 
    # used to support plotting and GUIs.
    # @param axis     the axis name, as in one of the values returned by 
    #                   fitsetaxes().  In addition, an extra axis name,
    #                   Component is supported to set decoration attributes
    #                   associated with components of the gains
    # @param item     the attribute name.  Recognized values include...
    ##
    public.getaxisdecoritem := function(axis, item, default=unset) {
	wider private, data;
	if (! data.axisdecor::filled) private.fillaxisdecor();
	if (! has_field(data.axisdecor, axis)) 
	    fail paste('axisdecoration: axis name not found:', axis);

	if (has_field(data.axisdecor[axis], item)) {
	    return data.axisdecor[axis][item];
	} 
	else if (! is_unset(default)) {
	    return default;
	}
	else {
	    fail paste('getaxisdecoritem: item not set:', item);
	}
    }

    #@
    # merge given decoration items for a given axis into those currently 
    # set.  This is not normally
    # used by the interactive user but rather by supporting tools used to
    # support plotting and GUIs.
    # @param axis     the axis name, as in one of the values returned by 
    #                   fitsetaxes().  In addition, an extra axis name,
    #                   Component is supported to set decoration attributes
    #                   associated with components of the gains
    # @param decor    a record whose fields are decoration attribute names
    #                    and values are the attribute values.  
    # @param who      the actor requesting the update.  
    # @param skipwho  if true (the default), the listener associated
    #                     this name will not be notified.
    ##
    public.mergeaxisdecor := function(axis, decor, who='', skipwho=T) {
	wider private, data, public;
	if (! data.axisdecor::filled) private.fillaxisdecor();
	if (! has_field(data.axisdecor, axis)) 
	    fail paste('mergeaxisdecor: axis name not found:', axis);

	local item, ok;
	for (item in field_names(decor)) {
	    ok := public.setaxisdecoritem(axis, item, decor[item], who);
	    if (is_fail(ok)) return ok;
	}
	
	return ok;
    }

    #@
    # set a decoration item for a given axis.  This is not normally
    # used by the interactive user but rather by supporting tools used to
    # support plotting and GUIs.  Listeners will be alerted to this update
    # @param axis     the axis name, as in one of the values returned by 
    #                   fitsetaxes().  In addition, an extra axis name,
    #                   Component is supported to set decoration attributes
    #                   associated with components of the gains
    # @param item     the decoration attribute to set
    # @param value    the value to give.  This value may be modified 
    #                   (usually in length) prior to setting.
    # @param who      the actor requesting the update.
    # @param skipwho  if true (the default), the listener associated
    #                     this name will not be notified.
    ## 
    public.setaxisdecoritem := function(axis, item, value, who='', skipwho=T) {
	wider private, data;
	if (! data.axisdecor::filled) private.fillaxisdecor();
	if (! has_field(data.axisdecor, axis)) 
	    fail paste('setaxisdecoritem: axis name not found:', axis);

	local old := unset;
	if (has_field(data.axisdecor[axis], item)) {
	    old := data.axisdecor[axis][item];

	    if (! is_record(value) && type_name(old) == type_name(value) &&
		len(old) > len(value))
	    {
		data.axisdecor[axis][item][1:len(value)] := value;
	    } else {
		data.axisdecor[axis][item] := value;
	    }
	}
	else {
	    data.axisdecor[axis][item] := value;
	}

	# alert listeners about update
	data.decorlisteners.tell([axis=axis, item=item, old=old, new=value],
				 who, skipwho=skipwho);

	return T;
    }

    #@
    # load up the decoration attributes
    ##
    private.fillaxisdecor := function() {
	wider data, public;
	local axnames := public.fitsetaxes();
	local axdec := ref data.axisdecor;
	local dvals, axn;

	for(axn in [axnames, 'Component']) {
	    if (! has_field(axdec, axn)) axdec[axn] := [=];

	    # item: values 
	    if (axn == 'Component') {
		dvals := GPF_COMPVALUES;
	    } else {
		dvals := public.axisvals(axn);
	    }
	    axdec[axn].values := dvals;

	    # item: labels
	    dvals := as_string(axdec[axn].values);
	    if (has_field(axdec[axn], 'labels') && 
		is_string(axdec[axn].labels)      )
	    {
		dvals[1:len(axdec[axn].labels)] := axdec[axn].labels;
	    }
	    axdec[axn].labels := dvals;

	    # item: tags
	    dvals := '';
	    if (axn == 'Component') {
		dvals := GPF_COMPVALUES;
	    }
	    else {
		for(i in [1:len(axdec[axn].labels)]) 
		    dvals[i] := paste(axn, axdec[axn].labels[i]);
	    }
	    if (has_field(axdec[axn], 'tags') && 
		is_string(axdec[axn].tags)      )
	    {
		dvals[1:len(axdec[axn].tags)] := axdec[axn].tags;
	    }
	    axdec[axn].tags := dvals;

	    # item: initstate
	    dvals := rep(F, length(axdec[axn].values));
	    dvals[1] := T;
	    if (has_field(axdec[axn], 'initstate') && 
		is_boolean(axdec[axn].initstate)      )
	    {
		dvals[1:len(axdec[axn].initstate)] := axdec[axn].initstate;
	    }
	    axdec[axn].initstate := dvals;

	    # item: showtitle
	    if (! has_field(axdec[axn], 'showtitle') || 
		! is_boolean(axdec[axn].showtitle)     )
	    {
		axdec[axn].showtitle := T;
	    } 
	    else if (len(axdec[axn].showtitle) != 1) {
		axdec[axn].showtitle := axdec[axn].showtitle[1];
	    }
	}

	return T;
    }

    #@ 
    # return the shape of the "array" of fit engines
    public.fitsetshape := function() { return data.idxmap::shape; }

    #@
    # return the dimensionality of the "array" of fit engines.
    public.fitsetdim := function() { return length(data.idxmap::shape); }

    #@ 
    # return the names identifying the axes of the "array" of fit engines
    public.fitsetaxes := function() {
	return data.opts.get('readopts').selaxes;
    }

    #@ 
    # return the axis values for a given axis of the "array" of fit engines
    # @param name  the name of the axis
    public.axisvals := function(name) {
	return data.axispos[data.opts.get('readopts').selaxes == name];
    }

    #@
    # return a numeric index for the fit engine matching the name constraints.
    # F is returned if the input record does not map to a single engine.
    # @param recidx  a record whose fields are the values returned by 
    #                   fitsetaxes and the values are taken from those 
    #                   returned by axisvals().  Fields that are not 
    #                   relevent are ignored.
    public.indexbyname := function(recidx) {
	wider public, private, data;
	if (! is_record(recidx)) 
	    fail paste("gainpolyfitter.indexbyname(): input recidx not",
		       "a record:", recidx);
	local axes := public.fitsetaxes();
	local axcols := data.opts.get('readopts').selindex;
	local fld, a, v;
	local out := rep(0, length(data.idxmap::shape));
	for(fld in field_names(recidx)) {
	    a := ind(axes)[fld == axes];
	    if (length(a) > 0) {
		v := data.axispos[axcols[a]][data.axispos[axcols[a]] == 
					     recidx[fld]];
		if (length(v) == 0) return F;
		out[a] := v;
	    }
	}
	if (any(out == 0)) return F;

	return out;
    }

    #@ 
    # return the fit engine, a gainpolyfit tool, for a given index
    # @param index   a vector representing the position in the "array" of
    #                  fit engines.
    public.getfitengine := function(index) {
	wider data, private;
	if (! is_integer(index)) 
	    fail spaste('gainpolyfitter.getfitengine(): invalid index:', 
			index);

	if (length(index) != length(data.idxmap::shape))
	    fail spaste('gainpolyfitter.getfitengine(): incorrect index size',
			'\n    need length=', length(data.idxmap::shape), 
			'; got ', length(index));
		       
	local out := private.fitengine(index);
	if (is_fail(out)) {
	    out::message := paste('gainpolyfitter.getfitengine():', 
				  out::message);
	    fail out::message;
	}

	return ref out;
    }

    private.fitengine := function(index) {
	wider data;
	local idx := [=];
	local i;
	for(i in 1:length(index)) idx[i] := index[i];
	return ref data.gpfit[data.idxmap[idx]];
    }

    #@ 
    # show the gui.  
    public.gui := function(ref tool=[=]) {
	wider data, private, public;

	# set evaluation data, if necessary
#	if (! data.sampset) private.sample(evaluate=T);
	if (! data.sampset) public.setsampling(evaluate=T);

	# bring up gui
	if (is_boolean(data.gui)) {
	    local options := data.opts.get('guiopts');
	    if (! has_field(options, 'plotopts')) 
		options.plotopts := data.opts.get('plotopts');
	    data.gui := gainpolyfittergui(public, options);
	    if (is_fail(data.gui)) {
		val tool := F;
		return data.gui;
	    }
	}

	val tool := ref data.gui;
	return T;
    }

    #@
    # save the current fits to a gain table
    # @param ensurefit   if true, make sure that fits are up to date before
    #                       saving.
    public.save := function(ensurefit=T) {
	print "Saving fits TBI";
	return F;
    }

    #@
    # return the name of the gain table from which gains were extracted
    public.gaintable := function() {
	wider data;
	return data.tablename;
    }

    #@
    # return the sampling data associated with a given index
    # @param index       the fitengine index, as returned from indexbyname()
    # @param ensureeval  if true, re-evaluate the fits if needed.
    ##
    public.getsampling := function(index, ensureeval=T) {
	wider public;
	return public.getfitengine(index).getsampling(ensureeval);
    }

    #@
    # return the fitted data associated with a given index
    # @param index       the fitengine index, as returned from indexbyname()
    ##
    public.getdata := function(index) {
	wider public;
	return public.getfitengine(index).getdata();
    }

    #@
    # return the domain interval (e.g. time/freq) covered by this fitter
    # return 2-element float vector
    # @param absolute  If false (the default), the values will be relative
    #                     to the starting value; that is, the first value 
    #                     will be zero.  If true, the values will be absolute 
    #                     time/frequency values.  
    ##
    public.getdomain := function(absolute=F) {
	wider data;
	local unit := '';
	local out := [0, 0];

	if (data.xref.min.type == 'epoch') 
	    unit := 's';
	else if (data.xref.min.type == 'frequency') 
	    unit := 'Hz';
	if (strlen(unit) > 0) {
	    out := [dq.getvalue(dq.convert(data.xref.min.m0, unit)), 
		    dq.getvalue(dq.convert(data.xref.max.m0, unit))];
	}

	if (! absolute) out -:= out[1];
	return out;
    }

    #@
    # return the measurement type of the independent variable.  
    # @return string indicating type, usually either 'epoch' (for time)
    #                   or 'frequency'
    public.getdomaintype := function() {
	wider data;
	return data.xref.min.type;
    }
	
    #@
    # return the breakpoints for the data associated with a given index
    # @param index       the fitengine index, as returned from indexbyname()
    ##
    public.getbreakpoints := function(index) {
	wider public;
	return public.getfitengine(index).getbreakpoints();
    }
	
    #@
    # return the current fit orders for the data associated with a given index
    # @param index       the fitengine index, as returned from indexbyname()
    # @param ampreal  if true, return the fit order(s) for the first component
    #                     gain.  If false, return the fit order(s) for the 
    #                     second component gain.
    # @param interval a vector of indicies for the intervals of interest (as
    #                     returned by getinterval()).
    #                     An empty vector (the default) means get all intervals.
    # @param integer array containing the orders for each fit interval
    ##
    public.getorder := function(index, ampreal, interval=[]) {
	wider public;
	local out := public.getfitengine(index).getorder(ampreal,interval);
#	if (! is_fail(out)) out := out[1];
	return out;
    }
	
    #@
    # set the current fit order for the data associated with a given index
    # @param order    the new fit order
    # @param index    the fitengine index, as returned from indexbyname()
    # @param ampreal  if true, set the fit order(s) for the first component
    #                     gain.  If false, set the fit order(s) for the 
    #                     second component gain.
    # @param interval a vector of indicies for the intervals of interest (as
    #                     returned by getinterval()).  An empty vector (the 
    #                     default) means set all intervals.
    # @param refit    if true, the fit for the the given index will be 
    #                     recalculated.  
    # @param who      the name of the actor setting this change.  This 
    #                     will be sent to listeners.  The default is an 
    #                     empty string, indicating that the actor is 
    #                     anonymous.
    # @param skipwho  if true (the default), the listener associated
    #                     this name will not be notified.
    ##
    public.setorder := function(order, index, ampreal, interval=[], refit=F,
				who='', skipwho=T) 
    {
	wider public, data;
	local engine := public.getfitengine(index);
	engine.setorder(order, ampreal, interval);
	if (refit) engine.fit(data.fitter);

	# alert listeners about update
	data.actionlisteners.tell([fitindex=index, action='order', 
				   input=[ampreal=ampreal, interval=interval]],
				  who, skipwho=skipwho);

	return T;
    }

    #@
    # return the interval index for a given fit engine index and x-axis value
    # @param x      the x-axis value
    # @param index  the engine index
    # @param absolute if false (the default), x is a value relative to the 
    #                     starting time/frequency; if true, x is an absolute 
    #                     value of time/frequency.
    ##
    public.getinterval := function(x, index, absolute=F) {
	wider public;

	if (absolute) x -:= public.getdomain(absolute=T)[1];

	local engine := public.getfitengine(index);
	if (is_fail(engine)) return engine;
	return engine.getinterval(x);
    }

    #@ 
    # add a breakpoint to a given fit set.  The fit order assigned to the 
    # two resulting fit intervals will be that of the interval that was 
    # split.  
    # @param x        the x-axis location to place the breakpoint
    # @param index    the fitengine index, as returned from indexbyname()
    # @param absolute if false (the default), x is a value relative to the 
    #                     starting time/frequency; if true, x is an absolute 
    #                     value of time/frequency.
    # @param refit    if true, the fit for the the given index will be 
    #                     recalculated.  
    # @param who      the name of the actor setting this change.  This 
    #                     will be sent to listeners.  The default is an 
    #                     empty string, indicating that the actor is 
    #                     anonymous.
    # @param skipwho  if true (the default), the listener associated
    #                     this name will not be notified.
    ##
    public.addbreakpoint := function(x, index, absolute=F, refit=F,
				     who='', skipwho=T) 
    {
	wider public, data;

	if (absolute) x -:= public.getdomain(absolute=T)[1];

	local engine := public.getfitengine(index);
	local intv := engine.getinterval(x);
	local order := [0, 0];
	order[1] := engine.getorder(T, intv);
	order[2] := engine.getorder(F, intv);

	engine.addbreakpoint(x, order[1], order[2]);
	if (refit) engine.fit(data.fitter);

	# alert listeners about update
	data.actionlisteners.tell([fitindex=index, action='addbreakpoint', 
				   input=[x=x, absolute=absolute]],
				  who, skipwho=skipwho);

	return T;
    } 

    #@
    # remove the sub-range that encloses the given x location.  This is
    # done by removing the next breakpoint after the location, unless
    # the location falls in the last interval.  This this latter case,
    # the breakpoint prior to the location is removed.  False
    # is returned if only one sub-range currently exists or if x 
    # is past the last range.
    # @param x  the position along the x-axis
    # @param index    the fitengine index, as returned from indexbyname()
    # @param refit    if true, the fit for the the given index will be 
    #                     recalculated.  
    # @param who      the name of the actor setting this change.  This 
    #                     will be sent to listeners.  The default is an 
    #                     empty string, indicating that the actor is 
    #                     anonymous.
    # @param skipwho  if true (the default), the listener associated
    #                     this name will not be notified.
    ##
    public.deleteinterval := function(x, index, refit=F, who='', skipwho=T) {
	wider private, public, data;
	local engine := public.getfitengine(index);
	if (is_fail(engine)) return engine;

	local ok := engine.deleteinterval(x);
	if (! is_fail(ok) && refit) engine.fit(data.fitter);

	# alert listeners about update
	data.actionlisteners.tell([fitindex=index, action='deleteinterval', 
				   input=[x=x]], who, skipwho=skipwho);

	return ok;
    }

    #@
    # set a masks for specified data from a given engine
    # @param datind the data indicies of the data point to mask
    # @param index  the fitengine index, as returned from indexbyname()
    # @param tf     T or F.  True means that the value is valid and should
    #               be used in fitting.
    # @param refit    if true, the fit for the the given index will be 
    #                     recalculated.  
    # @param who      the name of the actor setting this change.  This 
    #                     will be sent to listeners.  The default is an 
    #                     empty string, indicating that the actor is 
    #                     anonymous.
    # @param skipwho  if true (the default), the listener associated
    #                     this name will not be notified.
    ##
    public.setmask := function(datind, index, tf, refit=F, who='', skipwho=T) {
	wider public, private, data;
	if (! is_integer(datind) || any(datind < 1)) 
	    fail paste('setmask: illegal data indicies:', datind);
	local engine := public.getfitengine(index);
	if (is_fail(engine)) return engine;

	local i, ok;
	for (i in datind) {
	    ok := engine.setmask(i, tf);
	    if (is_fail(ok) && len(datind) > 1) {
		note('Trouble setting mask at index ', i, ': ', ok::message,
		     priority='WARN', origin='gainpolyfitter');
	    }
	}

	if (len(datind) == 1 && is_fail(ok)) return ok;
	if (refit) engine.fit(data.fitter);

	# alert listeners about update
	data.actionlisteners.tell([fitindex=index, action='setmask', 
				   input=[datind=datind, tf=tf]], 
				  who, skipwho=skipwho);

	return T;
    }

    #@
    # create a new gain table and fill it with gains calculated by 
    # evaluating the fits.
    ##
    public.writegains := function(outgains, extrapolate=F) {
	
	return T;
    }
	
    #@ 
    # add a listener
    # @param callback   a function to be called when an option or decoration
    #                     is updated.  This function should have the following 
    #                     signature:
    #                     <pre>
    #                        function(state=[=], name='', who='')
    #                     where 
    #                        state    a record desribing the change (see
    #                                   below)
    #                        name     the name associated with the change. If 
    #                                   an option was changed, this will be
    #                                   'gpfoptions'; if a selection was made,
    #                                   this will be 'gpfdecoration'.
    #                        who      the name of the actor that requested the 
    #                                   chang; an empty string means "unknown".
    #                     </pre>
    #                     For an option change, the state record will have the 
    #                     following fields:
    #                     <pre>
    #                        item     the name of the option that was changed.
    #                        old      the old value
    #                        new      the new value
    #                     </pre>
    #                     For a decoration update, the state record will have
    #                     following fields:
    #                     <pre>
    #                        axis     the name of the axis selected on
    #                        item     the decoration attribute updated
    #                        old      the old value
    #                        new      the new value
    #                     </pre>
    # @param who        the name to associate with the listener.  This will
    #                     be returned by this function.  If a name is not 
    #                     provided, a unique name will be provided and 
    #                     returned.
    # @return string  represting the name given to the new listener.  
    ##
    public.addlistener := function(callback, who='') {
	wider data;
	local name := data.opts.addlistener(callback, who);
	data.decorlisteners.addlistener(callback, who=name);
	data.actionlisteners.addlistener(callback, who=name);
	return name;
    }

    #@
    # remove a listener.  The callback associated with the given name will
    # be thrown away.
    # @param who   the name of the listener to remove
    ##
    public.removelistener := function(who) {
	wider private;
	data.decorlisteners.removelistener(who);
	data.actionlisteners.removelistener(who);
	return data.opts.removelistener(who);
    }	

    #@ 
    # shut down this tool
    ##
    public.done := function() {
	wider data, public;
	local i;
	data.decorlisteners.done();
	data.actionlisteners.done();
	data.opts.done();
	for(i in ind(data.gpfit)) {
	    data.gpfit[i].done();
	}
	val public := F;
	return T;
    }

    #@
    # set the sampling parameters and apply them to the fit engines 
    # @param sampintv     the sampling interval.  If the domain type is 
    #                       'epoch', this should be in seconds; if it is
    #                       'frequency', this should be in Hertz.
    #                       If unset, the current default value stored 
    #                       in the 'sampintv' option will be used.
    # @param extrapolate  if true, all masks associated with the sampled 
    #                       data will be set to true; if false, only those
    #                       sampled positions for which there are two 
    #                       bounding real data points will be set to true.
    #                       If unset, the current default value stored 
    #                       in the 'extrapolate' option will be used.
    # @param who      the name of the actor setting this change.  This 
    #                     will be sent to listeners.  The default is an 
    #                     empty string, indicating that the actor is 
    #                     anonymous.
    # @param skipwho  if true (the default), the listener associated
    #                     this name will not be notified.
    ##
    public.setsampling := function(evaluate=F, sampintv=unset, 
				   extrapolate=unset, who='', skipwho=T) 
    {
	wider data;
	local intv := sampintv;
	if (is_unset(intv)) intv := data.opts.get('sampintv');
	local extrap := extrapolate;
	if (is_unset(extrap)) extrap := data.opts.get('extrapolate', F);

	local domain := public.getdomain();
	local nsamp := as_integer(ceiling((domain[2]-domain[1]) / intv));
	local xsamp := seq(nsamp) - 1;
	xsamp *:= intv;
	xsamp /:= data.xref.scale;

	local mask, obs, bp, i, j, k;
	for(i in ind(data.gpfit)) {
	    mask := unset;
	    if (! extrap) {
		# don't allow extrapolation into regions that are not 
		# surrounded by valid data
		obs := data.gpfit[i].getdata();
		if (any(obs.mask)) {
   		    mask := rep(T, nsamp);

		    # loop through fitting intervals
		    bp := data.gpfit[i].getbreakpoints();
		    st := [domain[1], bp];
		    en := [bp, domain[2]];
		    for(j in 1:len(st)) {
			k := ind(obs.x)[obs.mask & 
					obs.x >= st[j] & obs.x <= en[j]];
			if (len(k) == 0) {
			    # no good data in this interval; flag entire 
			    # interval
			    mask[xsamp > obs.x & xsamp <= en[j]] := F;
			}
			else {
			    # flag interval before first good point and 
			    # after last good point.
			    mask[xsamp < obs.x[k[1]]] := F;
			    mask[xsamp > obs.x[k[len(k)]]] := F;
			}
		    }
		}
		else {
		    mask := rep(F, nsamp);
		}
	    }

	    data.gpfit[i].setsampling(xsamp, reeval=evaluate, 
				      fitter=data.fitter, mask=mask,
				      xref=data.xref.min,
				      xscale=data.xref.scale);
	}

	if (! is_unset(sampintv)) 
	    data.opts.set('sampintv', intv, who=who, skipwho=skipwho);
	if (! is_unset(extrapolate)) 
	    data.opts.set('extrapolate', extrap, who=who, skipwho=skipwho);

	# alert listeners about update
	data.actionlisteners.tell([fitindex=unset, action='setsampling',
				   input=[sampintv=intv, extrapolate=extrap]],
				  who, skipwho=skipwho);
	    
	data.sampset := T;
	return T;
    }

    private.sample := function(evaluate=F) {
	wider public, data;

	local domain := public.getdomain();
	local nsamp := data.opts.get('nsamp', 200);
	local xsamp := seq(nsamp) - 1;
	xsamp *:= ((domain[2]-domain[1]) / (nsamp-1));
	xsamp /:= data.xref.scale;

	for(i in ind(data.gpfit)) {
	    data.gpfit[i].setsampling(xsamp, reeval=evaluate, 
				      xref=data.xref.min,
				      xscale=data.xref.scale);
	}
	    
	data.sampset := T;
	return T;
    }



##############################
#  more initialization
##############################

    # set the sampling interval to use
    data.opts.set('sampintv', data.opts.get('tsampintv', 60));
    if (public.getdomaintype() == 'frequency') 
	data.opts.set('sampintv', data.opts.get('fsampintv', 1000));

#    if (gui) private.sample(evaluate=F);
    if (gui) public.setsampling(evaluate=F);

    # establish initial fits
    for(i in ind(data.gpfit)) {
	data.gpfit[i].fit(data.fitter, force=T);
    }

    if (gui) public.gui();

    public.data := ref data;
    public.private := ref private;

    return ref public;
}

#@constructor
# create a gainpolyfitter tool that is configured for handling BIMA 
# telescope gains
#
# @param  gains       the name of the input gains table.  No default.
# @param  loadfits    load any previously calculated fits from the table, if 
#                     they exist.  This may cause some options to be 
#                     overridden.
# @param  validonly   if true, only valid (pre-fit) gain solutions be loaded.
#                     The default is false, loading all gains; however, invalid
#                     gains will be masked as bad.
# @param  options     the options for setting up the tool as a record with 
#                     one or more fields that make up a 
#                     GainPolyFitterOptionsItem.  These will override the 
#                     default values that defined in BIMA_GPFOPTIONS. 
# @param  options     the options for setting up the tool as a 
#                     GainPolyFitterOptionsItem.  
gainpolyfitterbima := function(gains, gui=T, loadfits=T, validonly=F, 
			       options=F) 
{
    local opts := itemmanager(type=GAINPOLYFITTEROPTIONSITEM, 
			      name='gpfoptions');
    opts.fromrecord(BIMA_GPFOPTIONS);
    if (is_record(options)) opts.fromrecord(options);

    return gainpolyfitter(gains, gui, loadfits, validonly, opts.torecord());
}

# gpf := gainpolyfitterbima('gcal.for_ray', gui=T, loadfits=F)

