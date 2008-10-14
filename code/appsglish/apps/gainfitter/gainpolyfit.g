# gainpolyfitter_fitter.g: Performs fits for gainpolyfitter.
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
# $Id: gainpolyfit.g,v 19.1 2004/08/25 01:16:20 cvsmgr Exp $

pragma include once;

include 'polyfitresult.g';
include 'unset.g';

#@itemcontainer GainDataArrayItem
# contains data representing gains, either measured or calculated, over a 
# range of an independent variable.  All component arrays must have the same
# length.
# @field type     must be set to 'GainDataArrayItem'
# @field xref     a measure representing a value for the x-axis, defining the 
#                    measure type for the independent variable (optional).  The
#                    value itself is used only if xscale is also present and 
#                    represents the origin of the x vector such that the 
#                    measures associated with the x axis = x*xscale + xref. 
#                    If xscale is not present, only the measure info is used.  
#                    This is commonly either a time measure or a frequency 
#                    measure.
# @field xscale   a scaling factor for scaling the data held in the x vector
#                    (optional).  If this is present, xref must also be present.
# @field ampphase a boolean (optionl); if true, the gain data represent 
#                    amplitude/phase pairs.  If false, the gain data represent
#                    real/imaginary pairs.
# @field x        an array containing the sampling of the independent variable.
# @field g1       an array containing the first component of the complex gain 
#                    (either the amplitude or real component).
# @field g2       an array containing the second component of the complex gain 
#                    (either the phase or imaginary component).  phase is 
#                    measured in radians.
# @field mask     a boolean array indicating at which values of x the values
#                    of g1 and g2 are valid.  T means the datum pair is valid.
# @field err      the error associated with the gain data (optional).  
#                    If err2 is not provided, then this is a total amplitude 
#                    error applicable to both g1 and g2; otherwise, it applies
#                    only to the first component.  This is relevent when 
#                    g1 and g2 are measured values.
# @field err2     the error associated with the second component.

#@itemcontainer DualPolyFitItem 
# contains a pair of polyfitresults for a given range along the domain.  This
# is used by gainpolyfit to hold fit results for the complex components of 
# a vector of gains.  The range is nominally defined by its ending value along 
# the x-axis; however, a starting value can be included as well.
#
# @field type     must be set to 'DualPolyFitItem'
# @field resulta  a polyfitresult tool for the first fit result (optional)
# @field resultb  a polyfitresult tool for the second fit result (optional)
# @field itema    a PolyFitResult item container for the first fit (optional)
# @field itemb    a PolyFitResult item container for the second fit (optional)
# @field xend     the maximum value along the x-axis for which these fits
#                    are valid.
# @field xstart   the minimum value along the x-axis for which these fits
#                    are valid.  (optional)
# @field data     a record containing the data that produced the fits 
#                    (optional).  The fields arrays of equal length and 
#                    include x, ya, yb, and err, holding x-axis data, 
#                    the y-axis data for the two fits, and the error in 
#                    y-axis measurements.  If the data record is present, it 
#                    must contain all 4 sub-fields.
# @field samp     a record containing a sampling of the fitted polynomia
#                    (optional).  The fields arrays of equal length and 
#                    include x, ya, and yb, holding x-axis data, and 
#                    the y-axis data for the two fits.  If the data record 
#                    is present, it must contain all 3 sub-fields.
##

const DUALPOLYFITITEM := 'DualPolyFitItem';

#@global
# return the index of the nearest data value to a given test value
# @param x     the test value
# @param data  the vector of values
const gpfnearestindex := function(x, data) {
    l := len(data);

    if(x <= data[1]) {
	nearest := 1;
    } else
	if(x >= data[l])
	    nearest := l;
    else {
	local lower := ind(data)[data <= x]; # Indices of values <= x.
	local higher:= ind(data)[data >= x]; # Indices of values >= x.
	low := lower[len(lower)];
	xl := data[low];		# The highest point <= x;
	high := higher[1];
	xh := data[high];		# The smallest point >= x;
	dx := (xh-xl)/2.0;		# 1/2 distance between them.
	if(x <= (xl+dx))
	    nearest := low;
#       else if(x > (xh-dx))
	else
	    nearest := high;
    }
    return nearest;
}

#@global
# return the index of the nearest data value to a given test value
# @param x     the test value
# @param data  the vector of values
const gpfnearestvalue := function(x, data) {
    return data[gpfnearestindex(x,data)];
}

#@global
# subtract the average of a vector from the vector
# @param v   the vector of values
##
const gpfremoveavg := function(v=[1]) {
    return v - sum(v)/len(v);
}

#@global
# unwrap a phase vector
# @param p   the phase vector
const gpfunwrap := function(p, reverse=F) {
    local offset := pi*2;
    local o2 := offset/2.0;

    local ave := 0.0;
    local i := 1;
    local diff;
    local inc := 1;
    local lim := length(p)+1;
    if (reverse) {
	i := length(p);
	inc *:= -1;
	lim := 0;
    }

    while (i != lim) {
	diff := (p[i]-ave);
	if (abs(diff) > o2) {
	    if (diff < 0) 
		p[i] +:= floor(abs(diff+o2)/offset+1)*offset;
	    else
		p[i] -:= floor((diff-o2)/offset+1)*offset;
	}
	ave +:= (p[i] - ave)/i;
	i +:= inc;
    }
    if (! reverse) p := gpfunwrap(p, T);

    return p;
}

const gpfoldunwrap := function(p) {
    offset := pi*2.0;
    if(len(p)==1)
	return p;
    local o2 := offset/2;
    local lp := len(p);
    local pdiff :=  p[2:lp] - p[1:(lp-1)];

    # Indexes of large phase jumps (over 1/2 a circle).
    local jumpi := ind(pdiff)[abs(pdiff) > o2];
    if(len(jumpi) == 0)
	return p;
    local up := p;
    for (i in jumpi) {
	if(pdiff[i] > 0.0)
	    up[[(i+1):lp]] -:= offset;
	else
	    up[[(i+1):lp]] +:= offset;
    }
    return up;
}

#@tool public gainpolyfit
#  a tool for handling a series of polynomial fits of antenna gains for 
#  a range of values along x-axis.
#
#@constructor 
# create a generic gainpolyfit.  Normally, one would construct the this
# tool via timegainpolyfit() or freqgainpolyfit(); however, this constructor
# allows full flexibility for specifying the independent axis.  Initially,
# this set of fits will contain only one range.
# @param xref      a measure representing a value for the x-axis, defining the 
#                    measure type for the independent variable.  The value
#                    itself is ignored; only the measure info is used.  This
#                    is commonly either a time measure or a frequency measure.
# @param ampphase  if T, this basis for fitting gains is amplitude-phase;
#                    otherwise, it is real-imaginary.  Default=T
# @param index     a string representing relevence of this fit.  Typically,
#                    this is a TAQL query that selects the records from a gain 
#                    table from which this fit has been derived.  Default=''
# @param deforder1 the default fitting order for the first component of the
#                    gain.  The default depends on the value of ampphase: if T,
#                    the default is 0; otherwise, it is 2.
# @param deforder2 the default fitting order for the second component of the
#                    gain.  The default depends on the value of ampphase: if T,
#                    the default is 1; otherwise, it is 2.
# @param xdata     the values along the independent axis that this fit is
#                    derived from.  Default is [].
# @param gdata1    the first component of the gain from which this fit is 
#                    derived from.  If ampphase=T, then these are amplitudes;
#                    otherwise, they are real components.  Default is [].
# @param gdata2    the second component of the gain from which this fit is 
#                    derived from.  If ampphase=T, then these are amplitudes;
#                    otherwise, they are real components.  Default is [].
gainpolyfit := function(deforder1=-1, deforder2=-1, index='', 
			ampphase=T, ref xdata=[], ref gdata=[], ref err=unset, 
			ref mask=unset, xref=unset, xscale=unset, 
			ref pherr=unset, extrapolate=F) 
{
    ####################################################################
    # data components of this tool
    #   public     the public functions
    #   private    the private functions
    #   info       the fit results held as linked list of fit intervals
    #   data       the data to use to calculate fits
    #   samp       the data calculated from the fits
    ####################################################################

    public := [type='gainpolyfit'];
    private := [=]

    # need to check validity of xref
    # fits is a linked list contain the chain of ranges covering the 
    # range of xdata.  Each element in the chain (this) is a DualPolyFitItem.
    info := [index=index, extrapolate=extrapolate, 
	     fits=[this=unset, next=unset]];

    data := [type='GainDataArrayItem', xref=xref, ampphase=ampphase, 
	     x=[], mask=[], g1=[], g2=[], err=[], err2=[]];
    samp := [type='GainDataArrayItem', xref=xref, ampphase=ampphase, 
	     x=[], mask=[], g1=[], g2=[]];

    ########################################
    # set a few functions we need right away
    ########################################

    # create an empty DualPolyFitItem 
    private.makeemptyfit := function(deforder1, deforder2, xend=0, xstart=unset)
    {
	fit := [type=DUALPOLYFITITEM, xend=xend];
	if (! is_unset(xstart)) fit.xstart := xstart;
	fit.resulta := polyfitresult(deforder1);
	fit.resultb := polyfitresult(deforder2);
	return ref fit;
    }

    # assign the relevent portion of a data set to a given DualPolyFitItem
    private.assigndata := function(ref dset, ref dpfi, isfitdata=T, start=1) {
	local f := 'frange';
	if (! isfitdata) f := 'srange';

	if (start < 1 || start > len(dset.x)) {
	    dpfi[f] := [first=0, last=0];
	    return start;
	}
	wider private;

	local out := [first=start];
	local i := start;
	while (i < len(dset.x) && dset.x[i+1] <= dpfi.xend) {
	    i +:= 1;
	}
	out.last := i;

	dpfi[f] := out;

	return i+1;
    }

    #@
    # set whether to extrapolate during sampling.  If false, the masks 
    # associated with the fit sampling data will be set and updated to 
    # ensure that valid ranges are bounded by valid gains.  If true, 
    # the sampling masks are set to true whereever the fits are valid, 
    # allowing for extrapolation beyond the range of good gains.
    # @param tf  if true, extrapolation is turned on
    ##
    public.setextrapolating := function(tf) { 
	wider info;
	if (is_boolean(tf)) {
	    info.extrapolate := tf[1];
	    return T;
	}
	return F;
    }

    #@ 
    # return whether extrapolation during sampling is turned on.  
    ##
    public.isextrapolating := function() { 
	wider info; 
	return info.extrapolate; 
    }

    #@ 
    # mark all fits as needing to be updated
    public.resetfits := function() {
	wider info;
	local lnk := ref info.fits;
	if (is_unset(info.fits.this)) return T
	while (! is_unset(lnk)) {
	    if (lnk.this.resulta.setfitstate() > POLYFITSTATE.NEED)
		lnk.this.resulta.setfitstate(POLYFITSTATE.NEED);
	    if (lnk.this.resultb.setfitstate() > POLYFITSTATE.NEED)
		lnk.this.resultb.setfitstate(POLYFITSTATE.NEED);
	    lnk := ref lnk.next;
	}
	return T;
    }

    #@ 
    # set the basis used for fitting gains.  Gains can be fit either 
    # using amplitude and phase components or real and imaginary.  
    # Switching the basis can, in some cases, "degrade" the stored 
    # errors; that is, if real and imaginary errors have been specified
    # separately, then a conversion to amplitude and phase will result 
    # in a loss of information in those errors.  
    # @param tf   if true, the basis will be amplitude and phase;
    #                 otherwise, it will be real and imaginary.
    public.setampphase := function(tf) {
	wider data, samp, public;
	if (tf != data.ampphase) {
	    public.resetfits();
	    data.ampphase := tf;
	    if (len(data.x) > 0) {
		if (data.ampphase) {
		    local gdata := complex(data.g1, data.g2);
		    data.g1 := abs(gdata);
		    data.g2 := arg(gdata);
		    data.err2 := asin(data.err/data.g1);
		    if (len(data.err2) > 0) 
			data.err2[is_nan(data.err2)] := pi/4;
		} else {
		    local gdata := complex(data.g1*cos(data.g2), 
					   data.g1*sin(data.g2));
		    data.g1 := real(gdata);
		    data.g2 := imag(gdata);
		    data.err2 := data.err;
		}
	    }
	    if (len(samp.x) > 0 && data.ampphase != samp.ampphase) {
		if (data.ampphase) {
		    local gdata := complex(samp.g1, samp.g2);
		    samp.g1 := abs(gdata);
		    samp.g2 := arg(gdata);
		} else {
		    local gdata := complex(samp.g1*cos(samp.g2), 
					   samp.g1*sin(samp.g2));
		    samp.g1 := real(gdata);
		    samp.g2 := imag(gdata);
		}
	    }
	}

	return T;
    }

    #@
    # set the complex data to be fit.  All input arrays must have the 
    # same number of elements.  If xref is provided and is different from
    # the previously set fit or sampling data, the old sampling data will 
    # be emptied.  
    # @param ampphase  a boolean indicating whether the data should be fit
    #                     as amplitude/phase or real/imaginary
    # @param xdata   an array holding the independent variable data
    # @param gdata   an array of the complex gains
    # @param err     an array containing the error in the input gain 
    #                    solutions (gdata).  If not provided, the error is 
    #                    assumed to be constant and small.
    # @param mask    a boolean array containing the mask.  A true value means
    #                    that the datum is valid.
    # @param xref    a measure representing a value for the x-axis, defining 
    #                    the measure type for the independent variable 
    #                    (optional).  The value itself is used only if xscale 
    #                    is also present and represents the origin of the 
    #                    x vector such that the measures associated with the 
    #                    x axis = x*xscale + xref.  If xscale is not present, 
    #                    only the measure info is used.  This is commonly 
    #                    either a time measure or a frequency measure.  The
    #                    default is unset.
    # @param xscale  a scaling factor for the data held in the x array.  If 
    #                    this parameter is present, xref must also be present.
    #                    The fitting will be done directly on the xdata and 
    #                    gdata arrays; this value is indicative only.
    # @param pherr   an array containing an error in phase (in radians) for 
    #                    the input gains (optional).  If not provided, an 
    #                    estimation will be calculated from err as needed.
    public.setdata := function(ampphase, ref xdata, ref gdata, ref err=unset, 
			       ref mask=unset, xref=unset, xscale=unset, 
			       ref pherr=unset) 
    {
	wider data, samp, public;
	npts := len(xdata);
	if (is_unset(mask)) mask := rep(T, npts);
	if (is_unset(err)) err := 
	    rep(0.001*min(abs(gdata[abs(gdata) > 0])), npts);
	if (len(gdata) != npts || len(err) != npts || len(mask) != npts) 
	  fail "gainpolyfit.setdata(): inconsistant input array lengths";
	if (! is_unset(pherr) && len(pherr) != npts) 
	  fail "gainpolyfit.setdata(): inconsistant array length for pherr";
	if (! is_boolean(mask)) {
	    print "mask is a", type_name(mask);
          fail "gainpolyfit.setdata(): non-boolean type passed for mask array";
	}
	if (! is_unset(xscale) && is_unset(xref)) 
	  fail "gainpolyfit.setdata(): xscale provided without xref";
	if (! is_unset(xref) && 
	    (! has_field(xref, 'type') || ! has_field(xref, 'refer'))) 
	  fail "gainpolyfit.setdata(): xref is not a measure";

	if (! is_unset(xref)) {
	    data.xref := xref;
	    if (is_unset(samp.xref) || 
		xref.type != samp.xref.type || xref.refer != samp.xref.refer) 
	    {
		samp.xref := xref;
		samp.x := [];
		samp.g1 := [];
		samp.g2 := [];
		samp.mask := [];
	    }
	}

	# set new gain basis (ampphase) and reset the fits.  
	public.setampphase(ampphase);
	public.resetfits();

	local gd := sort_pair(xdata, gdata);
	data.x := sort(xdata);
	if (ampphase) {
	    data.g1 := abs(gd);
#	    data.g2 := arg(gd);
	    data.g2 := gpfunwrap(arg(gd));
	    if (is_complex(err) || is_dcomplex(err)) err := abs(err);
	    data.err := err;
	    if (is_unset(pherr)) {
		data.err2 := asin(err/data.g1);
		if (len(data.err2) > 0) data.err2[is_nan(data.err2)] := pi/4;
	    } else {
		data.err2 := pherr;
	    }
	}
	else {
	    data.g1 := real(gd);
	    data.g2 := imag(gd);
	    if (! is_unset(pherr)) {
		err := abs(err);
		err := complex(err*cos(pherr), err*sin(pherr));
	    } else if (! is_complex(err) && ! is_dcomplex(err)) {
		err := complex(err, 0);
	    }
	    data.err := real(err);
	    data.err2:= imag(err);
	}
	data.mask := mask;
	if (! is_unset(xscale)) data.xscale := xscale;

	# distribute the data to the individual intervals
	lnk := ref info.fits;
	local i := 1;
	if (len(data.x) > 0) {
	    if (! has_field(lnk.this, 'xstart') || data.x[1] < lnk.this.xstart)
		lnk.this.xstart := data.x[1];
	    while (! is_unset(lnk)) {
		if (lnk.this.xend == 0 && is_unset(lnk.next)) 
		    lnk.this.xend := max(data.x);
		i := private.assigndata(data, lnk.this, T, i);
		if (! is_unset(lnk.next) && has_field(lnk.next.this, 'xstart'))
		    lnk.next.this.xstart := lnk.this.xend;
		lnk := ref lnk.next;
	    }
	}

	return T;
    }

    ###############################
    # initialize internal data
    ###############################

    if (deforder1 < 0) {
	if (ampphase) deforder1 := 0;
	else deforder1 := 2;
    }
    if (deforder2 < 0) {
	if (ampphase) deforder2 := 1;
	else deforder2 := 2;
    }

    if (is_unset(xref)) {
	include 'measures.g';
	xref := dm.epoch('utc', 'today');
    }
    public.setdata(ampphase, xdata, gdata, err, mask, xref, xscale, pherr);

    local xmax := 0;
    if (len(xdata) > 0) xmax := max(xmax);
    info.fits.this := private.makeemptyfit(deforder1, deforder2, xmax);

    #@ 
    # return the reference measure that defines the measure type of the 
    # x-axis
    public.getmeasref := function() { wider info; return info.xref; }

    #@
    # return true if this set of gain fits are done on amplitude and phase
    # components of the gains.  If false is return, fits are done on real 
    # and imaginary components.
    public.isampphase := function() { wider info; return info.ampphase; }

    #@ 
    # set the index string.  This string represents the relevence of this
    # fit to some larger context.  Typically, this is a TAQL query that 
    # selects the records from a gain table from which this fit has been 
    # derived.  It is not used internally.
    public.setindex := function(str) { wider info; info.index := str; }

    #@ 
    # return the current index string.  This string represents the relevence 
    # of this fit to some larger context.  Typically, this is a TAQL query that 
    # selects the records from a gain table from which this fit has been 
    # derived.  It is not used internally.
    public.getindex := function() { wider info; return info.index; }

    #@
    # set the default evaluation sampling.  
    # @param x        an array containing a sampling of the independent 
    #                    variable.  The array is passed by reference for 
    #                    read-only use.
    # @param reeval   if true, reevaluate the current fits at the new data
    # @param fitter   the fitter tool to use.  If not provided, one will be
    #                    created
    # @param mask     an optional array containing masks for the sampling
    #                    data.  If provided, this array must be the same 
    #                    length as the x array.  Masks for sampling data
    #                    are not used internally by this tool; the fit is  
    #                    evaluated for each value in x regardless of the mask. 
    #                    This parameter merely provides a place to store 
    #                    masks used externally with the sampled data (and 
    #                    thus are returned by getsampling()).
    # @param xref     a measure representing a value for the x-axis, defining 
    #                    the measure type for the independent variable 
    #                    (optional).  The type must be consistant with the 
    #                    currently set fit data.  The value of the measure 
    #                    itself is used only if xscale 
    #                    is also present and represents the origin of the 
    #                    x vector such that the measures associated with the 
    #                    x axis = x*xscale + xref.  If xscale is not present, 
    #                    only the measure info is used.  This is commonly 
    #                    either a time measure or a frequency measure.  The
    #                    default is to assume the current measure type of 
    #                    the current fit data.
    # @param xscale   a scaling factor for the data held in the x array.  If 
    #                    this parameter is present, xref must also be present.
    #                    The fitting will be done directly on the xdata and 
    #                    gdata arrays; this value is indicative only.
    public.setsampling := function(ref x, reeval=T, ref fitter=F, 
				   mask=unset, xref=unset, xscale=unset) 
    {
	wider samp, data, info, private;
	if (! is_unset(xscale) && is_unset(xref)) 
	  fail "gainpolyfit.setsampling(): xscale provided without xref";
	if (! is_unset(xref) && 
	    ! has_field(xref, 'type') && ! has_field(xref, 'refer')) 
	  fail "gainpolyfit.setsampling(): xref is not a measure";
	if (! is_unset(xref) && 
	    (xref.type != data.xref.type || xref.refer != data.xref.refer))
	  fail "gainpolyfit.setsampling(): inconsistent xref type";

	local l := len(x);
	if (! is_unset(mask) && len(mask) != l)
	    fail spaste('gainpolyfit.setsampling(): number of masks (=',
			len(mask), ') != number of x-points (=', l, ')');

	samp.x := sort(x);
	samp.g1 := rep(0, l);
	samp.g2 := rep(0, l);
	samp.mask := mask;
	if (is_unset(samp.mask)) samp.mask := rep(T, l);
	if (! is_unset(xref)) samp.xref := xref;
	if (! is_unset(xscale)) samp.xscale := xscale;

	# distribute the data to the individual intervals
	if (reeval && is_boolean(fitter)) fitter := polyfitter();
	lnk := ref info.fits;
	local i := 1;
	local valid := unset;
	while (! is_unset(lnk)) {
	    i := private.assigndata(samp, lnk.this, F, i);
	    if (reeval) {
		if (!info.extrapolate) valid := private.validvals(lnk.this);
		private.doeval(samp, lnk.this, fitter, valid=valid);
	    }
	    else {
		if (lnk.this.resulta.getfitstate() > POLYFITSTATE.OK)
		    lnk.this.resulta.setfitstate(POLYFITSTATE.OK);
		if (lnk.this.resultb.getfitstate() > POLYFITSTATE.OK)
		    lnk.this.resultb.setfitstate(POLYFITSTATE.OK);
	    }
	    lnk := ref lnk.next;
	}

	return T;
    }

    #@ 
    # return the current internal sampling of the fit 
    # @return GainDataArrayItem  
    public.getsampling := function(ensureeval=T, ref fitter=F) {
	wider samp, info;
	if (ensureeval) {
	    if (is_boolean(fitter)) fitter := polyfitter();
	    local lnk := ref info.fits;
	    local valid := unset;
	    while (! is_unset(lnk)) {
		if (lnk.this.resulta.getfitstate() < POLYFITSTATE.EVALUATED ||
		    lnk.this.resultb.getfitstate() < POLYFITSTATE.EVALUATED)
		{
		    if (!info.extrapolate) valid := private.validvals(lnk.this);
		    private.doeval(samp, lnk.this, fitter, valid=valid);
		}
		lnk := ref lnk.next;
	    }
	}
	return samp;
    }

    #@ 
    # return the data used to calculate the fits
    # @return GainDataArrayItem  
    public.getdata := function() {  
	wider data; 
	return data;  
    }

    # find the last link whose x end value is less than a given value
    private.findappendfit := function(x) {
	wider info;
	lnk := ref info.fits;
	if (is_unset(lnk.this) || x <= lnk.this.xend) return unset;
	while (! is_unset(lnk.next) && x > lnk.next.this.xend) {
	    lnk := ref lnk.next;
	}
	return ref lnk;
    }

    #@ 
    # return the interval index that contains the given x-axis value
    # @param x  the x-axis value
    ##
    public.getinterval := function(x) {
	wider info;
	local interval := 1;
	lnk := ref info.fits;
	if (is_unset(lnk.this) || x <= lnk.this.xend) return 1;
	while (! is_unset(lnk.next)) {
	    lnk := ref lnk.next;
	    interval +:= 1;
	    if (x <= lnk.this.xend) break;
	}

	return interval;
    }

    #@
    # return the range of x-axis value covered by a given interval.
    # @param  i   the interval index.  The default (i <= 0) is to return 
    #               the range of the entire x-axis.
    # @return a 2-element array giving the beginning and end values.  [0, 0] 
    #            is returned if the range is not yet determined.
    public.getintervalrange := function(i=0) {
	wider data, info, private;
	local lnk;
	local out := [0, 0];
	if (len(data.x) <= 0) return out;
	if (i <= 0) {
	    lnk := info.fits;
	    out[1] := lnk.this.xstart;
#	    out[1] := data.x[1];
#	    out[2] := data.x[len(data.x)];
	    while (! is_unset(lnk.next)) {
		lnk := lnk.next;
	    }
	    out[2] := lnk.this.xend;
	}
	else {
	    i -:= 1;
	    if (i == 0) {
		lnk := info.fits;
		if (! has_field(lnk.this, 'xstart')) 
		    lnk.this.xstart := min(lnk.this.xend, data.x[1]);
		out[1] := min(lnk.this.xstart, data.x[1]);
	    }
	    else {
		lnk := private.getinterval(i);
		out[1] := lnk.this.xend;
		if (is_unset(lnk.next)) return [0, 0];
		lnk := lnk.next;
	    }
	    out[2] := lnk.this.xend;
	}
	return out;
    }

    #@
    # Add a breakpoint at a specific value, inserting a new sub-range
    # for fitting
    # @param x      the location along the x-axis to set the breakpoint
    # @param order1 the default order for the first component of the new 
    #                 range.  If not supplied the default set at 
    #                 construction will be used.
    # @param order2 the default order for the second component of the new 
    #                 range.  If not supplied the default set at 
    #                 construction will be used.
    public.addbreakpoint := function(x, order1=-1, order2=-1) {
	wider private, info, data, samp;
	local afterfit := private.findappendfit(x);
	local lnk := [=];
	local i := 1;
	local j := 1;
	if (is_unset(afterfit)) {
	    # new breakpoint is before the end point of the first interval
	    if (order1 < 0) 
		order1 := info.fits.this.resulta.getorder();
	    if (order2 < 0) 
		order2 := info.fits.this.resultb.getorder();
	    lnk := [this=private.makeemptyfit(order1, order2, x, 
					      min(info.fits.this.xstart, x)),
		    next=ref info.fits];
	    info.fits.this.xstart := x;
	    info.fits.this.resulta.setfitstate(POLYFITSTATE.NEED);
	    info.fits.this.resultb.setfitstate(POLYFITSTATE.NEED);
	    lnk.this.frange := [first=1, last=0];
	    if (len(samp.x) > 0) lnk.this.srange := [first=1, last=0];
	    info.fits := ref lnk;
	    afterfit := ref lnk;
	}
	else {
	    # new breakpoint is after the first interval
	    if (order1 < 0) 
		order1 := afterfit.this.resulta.getdefaultorder();
	    if (order2 < 0) 
		order2 := afterfit.this.resultb.getdefaultorder();

	    lnk := [this=private.makeemptyfit(order1, order2, x), next=unset];
	    if (has_field(afterfit.this, 'xstart')) 
		lnk.this.xstart := afterfit.this.xend;
	    if (! is_unset(afterfit.next)) {
		lnk.next := ref afterfit.next;
		lnk.next.this.resulta.setfitstate(POLYFITSTATE.NEED);
		lnk.next.this.resultb.setfitstate(POLYFITSTATE.NEED);
	    }
	    afterfit.next := ref lnk;
	    i := afterfit.this.frange.last + 1;
	    if (has_field(afterfit.this, 'srange')) 
		j := afterfit.this.srange.last + 1;
	    afterfit := ref lnk;
	}
	lnk.this.resulta.setfitstate(POLYFITSTATE.NEED);
	lnk.this.resultb.setfitstate(POLYFITSTATE.NEED);

	i := private.assigndata(data, lnk.this, T, i);
	if (len(samp.x) > 0) j := private.assigndata(samp, lnk.this, F, j);
	if (! is_unset(lnk.next)) {
	    lnk.next.this.resulta.setfitstate(POLYFITSTATE.NEED);
	    lnk.next.this.resultb.setfitstate(POLYFITSTATE.NEED);
	    i := private.assigndata(data, lnk.next.this, T, i);
	    if (len(samp.x) > 0) 
		j := private.assigndata(samp, lnk.next.this, F, j);
	    lnk := ref lnk.next;
	}
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
    public.deleteinterval := function(x) {
	wider private, info, data;
	local doomed, lnk;

	# make sure we have more than one interval 
	if (is_unset(info.fits.next)) return F;

        priorintv := private.findappendfit(x);
	if (is_unset(priorintv)) {

	    # matches first interval 
	    doomed := ref info.fits;
	}
	else if (is_unset(priorintv.next)) {

	    # matches beyond last interval
	    return F;
	}
	else {

	    # matches interval in the middle
	    doomed := ref priorintv.next;

#  	    # reset the fit for the prior interval
#  	    priorintv.this.resulta.setfitstate(POLYFITSTATE.NEED);
#  	    priorintv.this.resultb.setfitstate(POLYFITSTATE.NEED);

#  	    # update break information for prior interval 
#  	    priorintv.this.xend := doomed.this.xend;
#  	    if (has_field(priorintv.this, 'frange') && 
#  		has_field(doomed.this, 'frange')) 
#  		priorintv.this.frange[2] := doomed.this.frange[2];
#  	    if (has_field(priorintv.this, 'srange') && 
#  		has_field(doomed.this, 'srange')) 
#  		priorintv.this.srange[2] := doomed.this.srange[2];
	}

	# do not delete last range
	if (is_unset(doomed.next)) return F;

	# reconnect chain removing matched link
	if (is_unset(priorintv)) {
	    info.fits := ref doomed.next;
	    lnk := ref info.fits;
	    if (has_field(lnk.this, 'xstart')) 
		lnk.this.xstart := min(data.x);
	}
	else {
	    priorintv.next := ref doomed.next;
	    lnk := ref priorintv.next;
	    if (has_field(lnk.this, 'xstart')) 
		lnk.this.xstart := priorintv.this.xend;
	}

	# reset the fit for the following interval
	lnk.this.resulta.setfitstate(POLYFITSTATE.NEED);
	lnk.this.resultb.setfitstate(POLYFITSTATE.NEED);
	
	# update range information of following interval as necessary
	if (has_field(lnk.this, 'frange'))
	    lnk.this.frange[1] := doomed.this.frange[1];
	if (has_field(lnk.this, 'srange'))
	    lnk.this.srange[1] := doomed.this.srange[1];

	# shut down tools in matched link
	doomed.this.resulta.done();
	doomed.this.resultb.done();
	return T;
    }

    #@ 
    # return a vector containing the current breakpoints
    public.getbreakpoints := function() {
	wider info;
	if (is_unset(info.fits.next)) return [];

	local out := [info.fits.this.xend];
	local i := 1;
	local lnk := ref info.fits.next;
	while (! is_unset(lnk)) {
	    i +:= 1;
	    out[i] := lnk.this.xend;
	    lnk := ref lnk.next;
	}
	return out[1:(len(out)-1)];
    }

    private.getinterval := function(i=0) {
	wider info;
	local n := 0;
	local lnk := ref info.fits;
	if (! is_unset(lnk.this)) n +:= 1;
	while (n < i && ! is_unset(lnk.next)) {
	    lnk := ref lnk.next;
	    n +:= 1;
	}
	if (n < i) return unset;
	return lnk;
    }

    #@ 
    # return the number of fit intervals.  This is equal to the number of 
    # breakpoints + 1.  
    public.getintervalcount := function() {
	wider info;
	local n := 0;
	local lnk := ref info.fits;
	if (! is_unset(lnk.this)) n +:= 1;
	while (! is_unset(lnk.next)) {
	    n +:= 1;
	    lnk := ref lnk.next;
	}
	return n;
    }

    private.getfitinterval := function(index) {
	wider info;
	local lnk := ref info.fits;
	local i := 1;
	while (i < index && ! is_unset(index)) {
	    i +:= 1;
	    lnk := ref lnk.next;
	}
	if (i < index) 
	    fail "index out of range";
	return lnk.this;
    }

    #@ 
    # return the fit information for a given interval as a DualPolyFitItem.
    # @param index      the interval index
    public.getfitinfo := function(index=1) {
	wider private;
	if (index < 1) 
	    fail paste("gainpolyfit.getfitinfo(): index out of range:", index);
	local fit := private.getfitinterval(index);
	if (is_fail(fit)) 
	    fail paste("gainpolyfit.getfitinfo(): index out of range:", index);
	return fit;
    }

    #@ 
    # return the fit information for all intervals
    # @param interval a vector of indicies for the intervals of interest.  
    #                     An empty vector (the default) means set all intervals.
    # @return DualPolyFitItem pseudo-vector
    public.getallfitinfo := function() {
	wider info;
	local out := [=];
	local i := 1;
	local lnk := ref info.fits;
	while (! is_unset(lnk.next)) {
	    out[as_string(i)] := lnk.this;
	    i +:= 1;
	    lnk := ref lnk.next;
	}
	return out;
    }

    #@
    # recalculate the fits according to the current state of the mask, order
    # selection, and data
    # @param fitter    the fitter tool to use
    # @param reduced   an (empty) array to fill with the indices of intervals 
    #                   whose orders had to be reduced due to lack of data.
    #                   This array will be returned empty if this function 
    #                   returns T.
    # @param failed    an (empty) array to fill with the indices of intervals 
    #                   for which the fitting failed.
    #                   This array will be returned empty if this function 
    #                   returns T.
    # @param force     if true, force the recalculation regardless of an 
    #                   interval's state; otherwise, the recalculation will
    #                   only be done for the intervals whose fit state indicates
    #                   a recalculation is needed.  The default is F.
    # @param reeval    if true, reevaluate the sample data if they are set.
    # @return boolean  T if fits for all intervals were successful without 
    #                   any reduction in fit orders.
    public.fit := function(ref fitter, ref reduced=[], ref failed=[], 
			   force=F, reeval=T) 
    {
	wider info, data, samp;
	local lnk := ref info.fits;
	local expected, got;
	local i:=1;
	local offmask := rep(F, len(data.mask));
	local m,j;
	local valid := unset;
	while (! is_unset(lnk)) {
	    if (! force && 
		lnk.this.resulta.getfitstate() >= POLYFITSTATE.OK &&
		lnk.this.resultb.getfitstate() >= POLYFITSTATE.OK)
	    {
		# We don't need to recalculate the fit, so re-evaluate
		# the sample data (if desired) and move on.
		#
		if (reeval && 
		    lnk.this.resulta.getfitstate() < POLYFITSTATE.EVALUATED &&
		    lnk.this.resultb.getfitstate() < POLYFITSTATE.EVALUATED) 
		{
		    if (!info.extrapolate) valid := private.validvals(lnk.this);
		    private.doeval(samp, lnk.this, fitter, valid=valid);
		}
		lnk := ref lnk.next;
		next;
	    }

	    if (lnk.this.frange.first==0) {   

		# no valid data in this interval, so mark it as failed 
		# and move on
		#
		failed[len(failed)+1] := i;
		i +:= 1;
		lnk.this.resulta.setfitstate(POLYFITSTATE.FAILED);
		lnk.this.resultb.setfitstate(POLYFITSTATE.FAILED);
		lnk := ref lnk.next;
		next;
	    }

	    # set the mask for this range
	    j := lnk.this.frange.last;
	    if (j > len(data.mask)) j := len(data.mask);
	    m := offmask;
	    m[lnk.this.frange.first:j] := T;
	    m &:= data.mask;

	    expected := lnk.this.resulta.getorder();
	    got := lnk.this.resulta.fit(data.x[m], data.g1[m], data.err[m], 
					fitter, !force);

	    # check to see if fit failed; mark as such if necessary
	    if (is_fail(got)) {
		failed[len(failed)+1] := i;
		i +:= 1;
		lnk.this.resultb.setfitstate(POLYFITSTATE.FAILED);
		lnk := ref lnk.next;
		next;
	    }

	    # check to see if the fit order got reduced (for insufficient
	    # data) and note it.
	    if (got != expected) reduced[len(reduced)+1] := i;

	    expected := lnk.this.resultb.getorder();
	    got := lnk.this.resultb.fit(data.x[m], data.g2[m], data.err2[m], 
					fitter, !force);
	    if (is_fail(got)) {
		failed[len(failed)+1] := i;
		i +:= 1;
		lnk.this.resulta.setfitstate(POLYFITSTATE.FAILED);
		lnk := ref lnk.next;
		next;
	    }
	    if (got != expected && reduced[len(reduced)] != i) 
		reduced[len(reduced)+1] := i;

	    if (reeval) {
		if (!info.extrapolate) valid := private.validvals(lnk.this);
		private.doeval(samp, lnk.this, fitter, valid=valid);
	    }
	    lnk := ref lnk.next;
	    i +:= 1;
	}

	return (len(reduced) == 0 && len(failed) == 0);
    }

    #@
    # return the fit results to either component of the gain.  
    public.getfitresults := function(ampreal=T) {
	wider info;
	local r := 'resultb';
	if (ampreal) r:= 'resulta';
	local out := [=];
	local i := 1;
	local lnk := ref info.fits;
	while (! is_unset(lnk)) {
	    out[as_string(i)] := lnk.this[r].getdata();
	    lnk := ref lnk.next;
	    i +:= 1;
	}
	return out;
    }

    #@
    # evaluate the fits at the given sampling, returning the results as 
    # a GainDataArrayItem.  
    # @param x        	  an array containing a sampling of the independent.  
    #                 	    The array is passed by reference for read-only use.
    # @param fitter   	  the fitter tool to use
    # @param extrapolate  if true, set the masks to ensure that ranges of valid
    #                       values in the returned data are bounded by valid
    #                       gains.
    public.eval := function(ref x, ref fitter, extrapolate=F) {
	wider private, data;
	local out := [type ='GainDataArrayItem', x=sort(x), mask=[], 
		      g1=[], g2=[]];
	local l := len(x);
	out.mask := rep(T, l);
	out.g1 := rep(0, l);
	out.g2 := rep(0, l);
	local valid := unset;

	local lnk := ref info.fits;
	local which, ok;
	local st := x[1];
	st -:= 1;
	while (! is_unset(lnk)) {
	    if (st <= lnk.this.xend &&
		lnk.this.resulta.getfitstate() >= POLYFITSTATE.OK &&
		lnk.this.resultb.getfitstate() >= POLYFITSTATE.OK)
	    {
		which := rep(F, len(out.x));
		which[out.x > st & out.x <= lnk.this.xend] := T;
		if (! extrapolate) 
		    valid := private.validvals(lnk.this);
		ok := private.doeval(out, lnk.this, fitter, F, which, valid);
		if (is_fail(ok)) return ok;
		st := lnk.this.xend;
	    }
	    lnk := ref lnk.next;
	}

	return out;
    }

    # return a valid set of values for trusting an evaluation of the fit
    private.validvals := function(ref dpfi) {
	wider data;
	local mask := rep(F, len(data.x));
	mask[dpfi.frange[1]:dpfi.frange[2]] := T;
	return data.x[mask & data.mask];
    }

    # evaluate the fit at the current sampling
    private.doeval := function(ref dset, dpfi, ref fitter, updstate=T, 
			       which=unset, valid=unset) 
    {
	local ok, y;
	local allok := T;
	if (len(dset.x) == 0) return T;
	if (is_boolean(which)) {
	    if (len(which) != len(dset.x)) 
		fail spaste('Length of mask array (=', len(which), 
			    ') does not match length of input array (=', 
			    len(dset.x));
	    if (all(!which)) return T;
	}
	else {
	    if (! has_field(dpfi,'srange') || 
		dpfi.srange.first == 0       ) return T;
	    which := rep(F, len(dset.x));
	    which[dpfi.srange.first:dpfi.srange.last] := T;
	}

	dset.mask[which] := T;

	if (dpfi.resulta.getfitstate() < POLYFITSTATE.OK) {
	    dset.g1[which] := 0;
	    dset.mask[which] := F;
	}
	else {
	    y := [];
	    ok := dpfi.resulta.eval(y, dset.x[which], fitter);
	    if (is_unset(ok)) {
		dset.g1[which] := 0;
		dset.mask[which] := F;
		if (updstate) dpfi.resulta.setfitstate(POLYFITSTATE.OK);
		allok := F;
	    } 
	    else { 
		if (updstate) dpfi.resulta.setfitstate(POLYFITSTATE.EVALUATED);
		dset.g1[which] := y;
	    }
	}

	if (dpfi.resultb.getfitstate() < POLYFITSTATE.OK) {
	    dset.g2[which] := 0;
	    dset.mask[which] := F;
	}
	else {
	    y := [];
	    ok := dpfi.resultb.eval(y, dset.x[which], fitter);
	    if (is_unset(ok)) {
		dset.g2[which] := 0;
		dset.mask[which] := F;
		if (updstate) dpfi.resultb.setfitstate(POLYFITSTATE.OK);
		allok := F;
	    } 
	    else {
		if (updstate) dpfi.resultb.setfitstate(POLYFITSTATE.EVALUATED);
		dset.g2[which] := y;
	    }
	}

	if (! is_unset(valid)) {
	    if (len(valid) > 0) 
		dset.mask[which & 
			(dset.x < valid[1] | dset.x > valid[len(valid)])] := F;
	    else 
		dset.mask[which] := F;
	}

	return allok;
    }

    #@
    # remove all break points and invalidate the fits
    public.resetranges := function() {
	wider private, info, data;
	if (! is_unset(info.fits.next)) private.removetoend(info.fits.next);
	info.fits.this.xend := 0;
	if (len(data.x) > 0) info.fits.this.xend := max(data.x);
	info.fits.this.resulta.setfitstate(POLYFITSTATE.NONE);
	info.fits.this.resultb.setfitstate(POLYFITSTATE.NONE);
	return T;
    }

    #@private
    # recursively remove the link and all those attached after it
    private.removetoend := function(ref lnk) {
	wider private;
	if (! is_unset(lnk.next)) 
	    private.removetoend(lnk.next);
	if (! is_unset(lnk.this)) {
	    lnk.this.resulta.done();
	    lnk.this.resultb.done();
	}
	lnk := unset;
	return T;
    }

    #@ 
    # change the mask for a given gain
    # @param index  the index of the data point to mask
    # @param tf     T or F.  True means that the value is valid and should
    #               be used in fitting.
    public.setmask := function(index, tf) {
	wider data, private, info;
	if (index < 1 || index > len(data.x)) 
	    fail "gainpolyfit.setmask(): index out of range";
	if (data.mask[index] != tf) {
	    lnk := private.findappendfit(data.x[index]);
	    if (is_unset(lnk)) {
		lnk := ref info.fits;
	    } 
	    else if (! is_unset(lnk.next)) {
		lnk := ref lnk.next;
	    }
	    if (! is_unset(lnk)) {
		lnk.this.resulta.setfitstate(POLYFITSTATE.NEED);
		lnk.this.resultb.setfitstate(POLYFITSTATE.NEED);
	    }
	    data.mask[index] := tf;
	}
	return T;
    }

    #@ 
    # return the mask for an individual gain or all the gains as a vector
    # @param index   if not provided (or <= 0), the entire mask array will
    #                   be returned
    public.getmask := function(index=0) {
	wider data;
	if (index < 1) return data.mask;
	if (index > len(data.x)) 
	    fail "gainpolyfit.getmask(): index out of range";
	return data.mask[index];
    }

    #@
    # return the minimum fit state.  Since the maximum fit state is 
    # POLYFITSTATE.OK, the minimum fit state indicates whether new fits
    # are needed for any of the ranges 
    public.getfitstate := function() {
	wider private, info;
	local out := min(info.fits.this.resulta.getfitstate(), 
			 info.fits.this.resultb.getfitstate() );
	local lnk := ref info.fits.next;
	while (! is_unset(lnk)) {
	    out := min(lnk.this.resulta.getfitstate(),
		       lnk.this.resultb.getfitstate(), out);
	    lnk := ref lnk.next;
	}
	return out;
    }

    #@ 
    # set the fit order for a given interval
    # @param order      the order to set.  A value < 0 means return it to its
    #                     default value.
    # @param ampreal    a boolean: if true, set the order for the first 
    #                     component (amp or real).  If false, set the second
    #                     component (phase or imaginary)
    # @param interval   a vector of indicies for the intervals of interest.  
    #                     An empty vector (the default) means set all intervals.
    # @return int vector  the new orders for all intervals
    public.setorder := function(order, ampreal, interval=[]) {
	wider private;
	return private.order(T, order, ampreal, interval);
    }

    private.order := function(doset, order, ampreal, interval=[]) {
	wider info, public;
	if (len(interval) == 0) interval := [1:public.getintervalcount()];
	local i := 1;
	local j := 1;
	local lnk := ref info.fits;
	local out := [];
	local result;
	while (! is_unset(lnk)) {
	    if (ampreal) {
		result := ref lnk.this.resulta; 
	    } else {
		result := ref lnk.this.resultb; 
	    }
	    if (doset) {
		if (any(interval == i)) result.setorder(order);
		out[i] := result.getorder();
	    } else if (any(interval == i)) {
		out[j] := result.getorder();
		j +:= 1;
	    }		
	    i +:= 1;
	    lnk := ref lnk.next;
	}
	return out;
    }

    #@
    # return the fit orders for a given intervals.
    # @param ampreal  if true, return the fit order(s) for the first component
    #                     gain.  If false, return the fit order(s) for the 
    #                     second component gain.
    # @param interval a vector of indicies for the intervals of interest.  
    #                     An empty vector (the default) means set all intervals.
    public.getorder := function(ampreal, interval=[]) {
	wider private;
	return private.order(F, -1, ampreal, interval);
    }

    #@ 
    # close down this tool
    public.done := function() {
	wider public, info;
	ok := public.resetranges();
	info.fits.this.resulta.done();
	info.fits.this.resultb.done();
	val public := F;
	return T;
    }

    public.getprivate := function() { wider private; return private; }
    public.getinfo := function() { wider info; return ref info; }

    return ref public;
}

const gainpolyfittest := function(gettool=F) {

    tests := [=];
    print "### Testing polyfitresult...";
    tests['polyfitresult'] := polyfitresulttest();

    print "### Testing gainpolyfit...";
    include 'randomnumbers.g';
    include 'measures.g';

    # test tool construction
    xref := dm.epoch('utc', 'today');
    gpfit := gainpolyfit(ampphase=F);
    if (is_fail(gpfit)) return gpfit;
    tests.construction := (has_field(gpfit, 'type') && 
			   gpfit.type == 'gainpolyfit');
    if (! tests.construction) fail "construction failure";

    # create some fake data
    xin := seq(0, 49);
    ph := 2*xin - 30;
    ph[26:50] := xin[26:50] - 5;
    amp := rep(5, 50);
    gideal := complex(amp*cos(ph*pi/180), amp*sin(ph*pi/180));

    # test setting/getting data
    gpfit.setdata(T, xin, gideal, xref=xref, xscale=1);
    data := gpfit.getdata();
    tests.getdata := (has_field(data, 'type') && 
		      data.type == 'GainDataArrayItem');
    tests.setdata := (recequal_(data.xref, xref) && data.ampphase &&
		      all(data.x == xin) && all(abs(data.g1 - 5) < 1e-15) && 
		      all(abs(data.g2 - ph*pi/180) < 1e-15) &&
		      all(abs(data.err - 0.005) < 1e-15) &&
		      all(abs(data.err2 - 0.001) < 1e-9) &&
		      data.xscale == 1);

    tests.getintervalcount := (gpfit.getintervalcount() == 1);

    # test break points and the assignment of ranges
    rnge := gpfit.getintervalrange();
    tests.getintervalrange0 := (rnge[1] == 0 && rnge[2] == 49);
    tests.getintervalrange1 := (gpfit.getintervalrange(1) == rnge);
    tests.addbreakpoint := gpfit.addbreakpoint(24.5);
    if (tests.getintervalcount)
	tests.getintervalcount := (gpfit.getintervalcount() == 2);

    # make sure internal data assignments work properly
    info := gpfit.getinfo();
    tests.assigndata := (has_field(info.fits.this,'frange') && 
			 info.fits.this.frange.first == 1 && 
			 info.fits.this.frange.last == 25 && 
			 has_field(info.fits.this,'xstart') &&
			 info.fits.this.xstart == 0 && 
			 has_field(info.fits.this,'xend') &&
			 info.fits.this.xend == 24.5);
    if (tests.assigndata) 
	tests.assigndata := (has_field(info.fits.next.this,'frange') && 
			     info.fits.next.this.frange.first == 26 && 
			     info.fits.next.this.frange.last == 50 && 
			     has_field(info.fits.next.this,'xstart') &&
			     info.fits.next.this.xstart == 24.5 && 
			     has_field(info.fits.next.this,'xend') &&
			     info.fits.next.this.xend == 49);

    tests.getintervalrange2 := (gpfit.getintervalrange(2) == [24.5,49]);
    if (tests.addbreakpoint) 
	tests.addbreakpoint := (gpfit.getintervalrange(1) == [0, 24.5] &&
				tests.getintervalrange2 && 
				tests.getintervalcount);

    # test setting/gettign the order
    gpfit.setorder(0, T);
    gpfit.setorder(2, F);
    tests.setorder := (len(gpfit.getorder(T))== 2  && 
		       all(gpfit.getorder(T) == 0) &&
		       all(gpfit.getorder(F) == 2));

    # test fitting ideal data
    fitter := polyfitter();
    reduced := [];
    failed := [];
    ok := gpfit.fit(fitter, reduced, failed);
    tests.fitideal := (is_boolean(ok) && ok && 
		       len(reduced)==0 && len(failed)==0);
    results := gpfit.getfitresults(T);
    tests.getfitresults := (len(results)==2 && 
			    results[1].type == 'PolyFitResultItem' && 
			    results[2].type == 'PolyFitResultItem');
    if (tests.fitideal) 
	tests.fitideal := (results[1].state == 3 && 
			   results[2].state == 3 && 
			   len(results[1].coeff) == 1 && 
			   results[1].coeff == 5 && 
			   results[1].chisq < 1.0e-5 && 
			   len(results[2].coeff) == 1 && 
			   results[2].coeff == 5 && 
			   results[2].chisq < 1.0e-5);
    if (tests.fitideal) {
	results := gpfit.getfitresults(F);
	if (tests.getfitresults) 
	    tests.getfitresults := (len(results)==2 && 
				    results[1].type == 'PolyFitResultItem' && 
				    results[2].type == 'PolyFitResultItem');
	tests.fitideal := (results[1].state == 3 && 
			   results[2].state == 3 && 
			   len(results[1].coeff) == 3 && 
			   len(results[2].coeff) == 3 && 
			   abs(results[1].coeff[1]*180/pi + 30) < 1.0e-5 && 
			   abs(results[2].coeff[1]*180/pi +  5) < 1.0e-5 && 
			   abs(results[1].coeff[2]*180/pi -  2) < 1.0e-5 && 
			   abs(results[2].coeff[2]*180/pi -  1) < 1.0e-5 && 
			   abs(results[1].chisq) < 1.0e-5 && 
			   abs(results[2].chisq) < 1.0e-5);
    }

    # add some errors to the data
    rand := randomnumbers();
    err := rand.normal(100, 1, 50) / 100 - 1;
    rand.done();
    ph +:= 500*err;
    ph *:= pi/180;
    amp +:= 50*err;
    gdata := complex(amp*cos(ph), amp*sin(ph));

    # passed corrupted data to tool
    gpfit.setdata(T, xin, gdata, err=rep(0.5, 50), pherr=rep(5*pi/180.0, 50), 
		  xref=xref, xscale=1);
    tests.resetdata := (len(gpfit.getorder(T))== 2  && 
			all(gpfit.getorder(T) == 0) &&
			all(gpfit.getorder(F) == 2) && 
			gpfit.getintervalrange(1) == [0, 24.5] && 
			gpfit.getintervalrange(2) == [24.5,49] && 
			gpfit.getfitstate() == POLYFITSTATE.NEED);

    gpfit.setorder(1, F);
    ok := gpfit.fit(fitter, reduced, failed);
    tests.fitwerr := (is_boolean(ok) && ok && 
		       len(reduced)==0 && len(failed)==0);
    results := gpfit.getfitresults(T);
    print "amp: ", results;

    if (tests.fitwerr) 
	tests.fitwerr := (results[1].state == 3 && 
			  results[2].state == 3 && 
			  len(results[1].coeff) == 1 && 
			  abs(results[1].coeff - 5) < results[1].error && 
			  results[1].error <= 0.5 &&
			  results[1].chisq < 25 && 
			  len(results[2].coeff) == 1 && 
			  abs(results[2].coeff - 5) < results[1].error && 
			  results[1].error <= 0.5 &&
			  results[2].chisq < 50);
    if (tests.fitwerr) {
	results := gpfit.getfitresults(F);
	print "phase: ", results;
	error1 := results[1].error * 180.0/pi;
	error2 := results[2].error * 180.0/pi;
	tests.fitwerr := (results[1].state == 3 && 
			  results[2].state == 3 && 
			  len(results[1].coeff) == 2 && 
			  len(results[2].coeff) == 2 && 
  			  abs(results[1].coeff[1]*180/pi + 30) <2* error1[1] && 
  			  abs(results[2].coeff[1]*180/pi +  5) < error2[1] && 
  			  abs(results[1].coeff[2]*180/pi -  2) <2* error1[2] && 
  			  abs(results[2].coeff[2]*180/pi -  1) < error2[2] && 
			  abs(results[1].chisq) < 25 && 
			  abs(results[2].chisq) < 35);
    }

    # test deleting an interval
    tests.addbreakpoint2 := gpfit.addbreakpoint(42.4);
    if (tests.getintervalcount)
	tests.getintervalcount := (gpfit.getintervalcount() == 3);
    if (tests.addbreakpoint2) 
	tests.addbreakpoint2 := (gpfit.getintervalrange(1) == [0, 24.5] &&
				 gpfit.getintervalrange(2) == [24.5, 42.4] &&
				 gpfit.getintervalrange(3) == [42.4, 49] &&
				 tests.getintervalcount);

    # make sure internal data assignments work properly
    info := gpfit.getinfo();
    fits := ref info.fits.next;
    tests.assigndata2 := (! is_unset(fits) && has_field(fits.this,'frange') && 
			 fits.this.frange.first == 26 && 
			 fits.this.frange.last == 43);
    if (tests.assigndata2) 
	tests.assigndata2 := (has_field(fits.next.this,'frange') && 
			      fits.next.this.frange.first == 44 && 
			      fits.next.this.frange.last == 50);

    tests.deleteinterval := F;
    if (tests.addbreakpoint2) {
	tests.addbreakpoint2 := (gpfit.addbreakpoint(52) && 
				 gpfit.getintervalrange(1) == [0, 24.5] &&
				 gpfit.getintervalrange(2) == [24.5, 42.4] &&
				 gpfit.getintervalrange(3) == [42.4, 49] &&
				 gpfit.getintervalrange(4) == [49, 52] &&
				 gpfit.getintervalcount() == 4);
	tests.deleteinterval := gpfit.deleteinterval(45);
	if (tests.deleteinterval) 
	    tests.deleteinterval := (gpfit.getintervalcount() == 3);
	if (tests.deleteinterval) 
	    tests.deleteinterval := (! gpfit.deleteinterval(50));
	if (tests.deleteinterval) 
	    tests.deleteinterval := (gpfit.deleteinterval(35) &&
				     gpfit.getintervalcount() == 2 &&
				     gpfit.deleteinterval(10) && 
				     gpfit.getintervalcount() == 1);
    }
	
    local tnames := field_names(tests);
    local succeed := 0;
    local failed := 0;
    local ftests := [''];
    for(name in tnames) {
	if (tests[name]) {
	    succeed +:= 1;
	} else {
	    failed +:= 1;
	    ftests[failed] := name;
	}
    }
    print spaste("Tests succeeded=", succeed, "; failed=", failed);
    if (failed > 0) {
	print "Failed tests: ", ftests;
    }

    fitter.done();
    if (gettool) return ref gpfit;

    gpfit.done();
    return (failed == 0);
}

const recequal_ := function(r1, r2) {
    if (r1 == r2) return T;
    if (! is_record(r1) || ! is_record(r2)) return F;
    if (len(r1) != len(r2)) return F;
    for (f in field_names(r1)) {
	if (! has_field(r2, f) || type_name(r1[f]) != type_name(r2[f])) 
	    return F;
	if (r1[f] != r2[f] && ! recequal_(r1[f], r2[f])) return F;
    }
    return T;
}

# gpfit := gainpolyfittest();
