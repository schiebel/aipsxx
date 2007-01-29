# gbtdata: closure object for gbtdata i/o, used by gbtcalibrator
# Copyright (C) 2004,2005
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
# $Id: gbtdata.g,v 19.6 2006/04/18 18:03:31 bgarwood Exp $

# include guard
pragma include once

include "logger.g";
include "tables.g";

gbtdata := function(mainTab, scan, copies, memSize, ddid=unset, stateinfo=unset, elevs=unset)
{
    private := [=];
    public := [=];

    private.putPending := F;
    private.copies := copies;
    private.memSize := memSize;
    private.fixedShape := T;
    private.npol := 1;
    private.stateinfo := stateinfo;
    private.elevs := elevs;

    queryString := spaste('SCAN_NUMBER==',scan);
    if (!is_unset(ddid)) {
	queryString := spaste(queryString,' AND DATA_DESC_ID==',ddid);
    }
    private.tab := mainTab.query(queryString);
    if (is_fail(private.tab)) return private.tab;
    if (!is_table(private.tab)) fail('unexpected failure to find expected data');
    if (private.tab.nrows() == 0) {
	private.tab.done();
	fail('unexpected failure in selecting expected data');
    }
    private.stateTab := table(private.tab.getkeyword('STATE'),ack=F);
    if (!is_table(private.stateTab)) {
	fail('unexpected failure to open STATE table');
	private.tab.done();
    }

    private.gbtdatas := [=];

    private.getIntsPerChunk := function(sizePerInt, nints) {
	wider private;
	if (nints <= 1) return 1;

	if (sizePerInt*nints <= private.memSize) return nints;

	nints := as_integer(nints/2);
	return private.getIntsPerChunk(sizePerInt, nints);
    }

    private.decodeStateInfo := function()
    {
	wider private;
	if (is_unset(private.stateinfo)) {
	    private.stateinfo := [=];
	    stateCol := private.tab.getcol('STATE_ID');
	    private.stateinfo.states := unique(stateCol);
	    private.stateinfo.cal := array(F, len(private.stateinfo.states));
	    private.stateinfo.sig := array(T, len(private.stateinfo.states));
	    private.stateinfo.ncal := 0;
	    private.stateinfo.nsig := 0;
	    for (i in 1:len(private.stateinfo.states)) {
		thisState := private.stateinfo.states[i];
		if (thisState >= 0 && thisState < private.stateTab.nrows()) {
		    private.stateinfo.cal[i] := private.stateTab.getcell('CAL', thisState+1) == 1;
		    private.stateinfo.sig[i] := private.stateTab.getcell('SIG', thisState+1);
		}
		if (private.stateinfo.cal[i]) private.stateinfo.ncal +:= sum(stateCol==thisState);
		if (private.stateinfo.sig[i]) private.stateinfo.nsig +:= sum(stateCol==thisState);
	    }
	}
	return T;	    
    }

    private.decodeChunkState := function()
    {
	wider private;
	private.cal := array(F,len(private.stateid));
	private.sig := array(T,len(private.stateid));
	for (thisState in private.ustateid) {
	    istate := ind(private.stateinfo.states)[private.stateinfo.states==thisState];
	    stateMask := private.stateid == thisState;
	    private.cal[stateMask] := private.stateinfo.cal[istate];
	    private.sig[stateMask] := private.stateinfo.sig[istate];
	}
	return T;
    }

    private.getElevs := function()
    {
	wider private;
	if (is_unset(private.elevs)) {
	    private.elev := array(90.0, len(private.time));
	    ptab := table(private.tab.getkeyword('POINTING'),ack=F);
	    if (is_table(ptab) && ptab.nrows() > 0) {
		global __btime := min(private.time)-1.0;
		global __etime := max(private.time)+1.0;
		subptab := ptab.query('TIME IN [$__etime=:=$__btime]');
		ptab.done();
		if (subptab.nrows() > 0) {
		    atab := table(private.tab.getkeyword('ANTENNA'),ack=F);
		    if (is_table(atab)) {
			# for GBT data, there will be just one antenna position, just use it
			ap := atab.getcell('POSITION',1);
			atab.done();
			# GBT positions are stored as ITRF
			apmeas := dm.position('ITRF',dq.quantity(ap,'m'));
			dm.doframe(apmeas);
		    } else {
			# fall back to the position in the measures database
			dm.doframe(dm.observatory('GBT'));
		    }
		    pdir := subptab.getcol('DIRECTION');
		    ptime := subptab.getcol('TIME');
		    pint := subptab.getcol('INTERVAL')/2.0;
		    subptab.done();
		    prow := 1;
		    for (thisTime in unique(private.time)) {
			rowMask := private.time == thisTime;
			pMask := ptime==thisTime;
			if (any(pMask)) {
			    thisPtime := ptime[pMask];
			    thisRA := pdir[1,1,pMask];
			    thisDEC := pdir[2,1,pMask];
			    thistime := dm.epoch('UTC',dq.quantity(thisPtime[1],'s'));
			    dm.doframe(thistime);
			    thispos := dm.direction('J2000',
						    dq.quantity(thisRA,'rad'),
						    dq.quantity(thisDEC,'rad'));
			    thisazel := dm.measure(thispos,'AzEl');
			    private.elev[rowMask] := thisazel.m1.value * 180.0 / pi;
			} else {
			    while (prow <= len(ptime)) {
				if (thisTime < (ptime[prow] - pint)) {
				    # too early, do nothing
				    break;
				}
				if (thisTime > (ptime[prow] + pint)) {
				    # too late, go to next row
				    prow +:= 1;
				} else {
				    thistime := dm.epoch('UTC',dq.quantity(ptime[prow],'s'));
				    dm.doframe(thistime);
				    thispos := dm.direction('J2000',
							    dq.quantity(pdir[1,1,prow],'rad'),
							    dq.quantity(pdir[2,1,prow],'rad'));
				    thisazel := dm.measure(thispos,'AzEl');
				    private.elev[rowMask] := thisazel.m1.value * 180.0 / pi;
				    break;
				}
			    }
			}
		    }
		}
		subptab.done();
	    } else {
		if (is_table(ptab)) ptab.done();
	    }
	}
	return T;
    }


    private.getChunk := function(rowStart) {
	wider private;	
	private.thisRowStart := rowStart;
	if (private.singleChunk) {
	    private.thisRowEnd := private.totRows;
	    private.thisNrow := private.totRows;
	    private.floatData := private.tab.getcol('FLOAT_DATA');
	    private.weight := private.tab.getcol('WEIGHT');
	    private.flag := private.tab.getcol('FLAG');
	    private.sigma := private.tab.getcol('SIGMA');
	    private.stateid := private.tab.getcol('STATE_ID');
	    private.feed := private.tab.getcol('FEED1');
	    private.ddid := private.tab.getcol('DATA_DESC_ID');
	    private.texp := private.tab.getcol('EXPOSURE');
	    private.chunkTime := private.time;
	    private.chunkElev := private.elev;
	} else {
	    private.thisRowEnd := min((private.thisRowStart + private.rowsPerChunk - 1), private.totRows);
	    private.thisNrow := private.thisRowEnd - private.thisRowStart + 1;
	    private.floatData := private.tab.getcol('FLOAT_DATA', private.thisRowStart, private.thisNrow);
	    private.weight := private.tab.getcol('WEIGHT', private.thisRowStart, private.thisNrow);
	    private.flag := private.tab.getcol('FLAG', private.thisRowStart, private.thisNrow);
	    private.sigma := private.tab.getcol('SIGMA', private.thisRowStart, private.thisNrow);
	    private.stateid := private.tab.getcol('STATE_ID', private.thisRowStart, private.thisNrow);
	    private.feed := private.tab.getcol('FEED1', private.thisRowStart, private.thisNrow);
	    private.ddid := private.tab.getcol('DATA_DESC_ID', private.thisRowStart, private.thisNrow);
	    private.stateid := private.tab.getcol('STATE_ID', private.thisRowStart, private.thisNrow);
	    private.texp := private.tab.getcol('EXPOSURE', private.thisRowStart, private.thisNrow);
	    private.chunkTime := private.time[private.thisRowStart:private.thisRowEnd];
	    private.chunkElev := private.elev[private.thisRowStart:private.thisRowEnd];
	}
	private.uddid := unique(private.ddid);
	private.ustateid := unique(private.stateid);
	private.decodeChunkState();
	private.setMask();
	return T;
    }

    private.putChunk := function() {
	wider private;
	if (private.putPending) {
	    if (private.singleChunk) {
		private.tab.putcol('CORRECTED_DATA', private.floatData);
		private.tab.putcol('FLAG', private.flag);
		private.tab.putcol('SIGMA', private.sigma);
	    } else {
		# CORRECTED_DATA has to be done without any row selection,
		# but this works, I don't understand
		t2 := private.tab.selectrows([private.thisRowStart:private.thisRowEnd]);
		t2.putcol('CORRECTED_DATA', private.floatData);
		t2.putcol('FLAG', private.flag);
		t2.putcol('SIGMA', private.sigma);
		t2.done();
	    }
	    private.putPending := F;
	}
    }

    private.init := function() {
	wider private;
	private.decodeStateInfo();
	# is this a fixed shaped selection or does the shape vary?
	private.fixedShape := T;
	uddid := unique(private.tab.getcol('DATA_DESC_ID'));
	private.fullUddid := uddid;
	private.time := private.tab.getcol('TIME');
	private.getElevs();
	if (len(uddid)>1) {
	    # need to probe further
	    ddTab := table(private.tab.getkeyword('DATA_DESCRIPTION'),ack=F);
	    polTab := table(private.tab.getkeyword('POLARIZATION'),ack=F);
	    swTab := table(private.tab.getkeyword('SPECTRAL_WINDOW'),ack=F);
	    ncorr := polTab.getcell('NUM_CORR',ddTab.getcell('POLARIZATION_ID',uddid[1]+1)+1);
	    nchan := swTab.getcell('NUM_CHAN',ddTab.getcell('SPECTRAL_WINDOW_ID',uddid[1]+1)+1);
	    for (i in 2:len(uddid)) {
		thisNcorr := polTab.getcell('NUM_CORR',ddTab.getcell('POLARIZATION_ID',uddid[i]+1)+1);
		thisNchan := swTab.getcell('NUM_CHAN',ddTab.getcell('SPECTRAL_WINDOW_ID',uddid[i]+1)+1);
		if (thisNcorr != ncorr || thisNchan != nchan) {
		    private.fixedShape := F;
		    break;
		}
	    }
	    polTab.done();
	    swTab.done();
	    ddTab.done();
	} 
	if (private.fixedShape) {
	    dataShape := private.tab.getcell('FLOAT_DATA',1)::shape;
	    private.npol := dataShape[1];
	    private.totRows := private.tab.nrows();
	    nints := len(unique(private.tab.getcol('TIME')));
	    rowsPerInt := private.totRows/nints;
	    sizePerInt := dataShape[1]*dataShape[2]*rowsPerInt*4*private.copies;
	    
	    private.intsPerChunk := private.getIntsPerChunk(sizePerInt, nints);
	    private.rowsPerChunk := private.intsPerChunk * rowsPerInt;
	    private.singleChunk := private.rowsPerChunk >= private.totRows;
	    private.getChunk(1);
	} else {
	    # need a seperate one of these for each ddid
	    for (thisDdid in private.uddid) {
		private.gbtdatas[as_string(thisDdid)] := gbtdata(private.tab, private.copies, private.memSize, 
								 thisDdid, private.stateinfo, private.elev);
	    }
	}
	# these are useful to have around for sanity checks
	private.sanity := [=];
	private.sanity.nrows := private.tab.nrows();
	
	feed1:= private.tab.getcol('FEED1');
	private.sanity.feeds := unique(feed1);
	private.sanity.nfeeds := len(private.sanity.feeds);
	private.sanity.nfeed := array(0,private.sanity.nfeeds);
	for (i in ind(private.sanity.feeds)) {
	    private.sanity.nfeed[i] := sum(feed1==private.sanity.feeds[i]);
	}
	private.sanity.nddid := len(uddid);
	
	return T;
    }

    private.ensureNShape := function(arr, ndim)
    {
	wider private;

	if (len(arr) == 1) {
	    arr::shape := [1];
	}

	if (len(arr::shape) == ndim) return arr;

	if (private.npol == 1) {
	    # this will always get dropped
	    arr::shape := [1, arr::shape];
	}
	if (len(arr::shape) < ndim) {
	    if (len(arr) == 0) {
		arr::shape := [arr::shape, 0];
	    } else {
		arr::shape := [arr::shape, 1];
	    }
	}
	return arr;
    }
    private.ensure3Dshape := function(arr)
    {
	wider private;
	return private.ensureNShape(arr, 3);
    }

    private.ensure2Dshape := function(arr)
    {
	wider private;
	return private.ensureNShape(arr, 2);
    }

    private.removeDegenerateAxes := function(arr)
    {
	shape := as_integer([]);
	for (n in arr::shape) {
	    if (n > 1) {
		shape[len(shape)+1] := n;
	    }
	}
	if (len(shape) == 0) shape := len(arr);
	arr::shape := shape;
	return arr;
    }

    # return T only when a change was made
    private.setAmask := function(ref theMask, ref lastValue, theSequence, theValue)
    {
	result := F;
	if (is_unset(theValue)) {
	    if (lastValue != -1) {
		val theMask := array(T, len(theSequence));
		val lastValue := -1;
		result := T;
	    }
	} else {
	    if (theValue != lastValue) {
		val theMask := theSequence == theValue;
		val lastValue := theValue;
		result := T;
	    }
	}
	return result;
    }

    private.setMask := function(ddid=unset, feed=unset, cal=unset, sig=unset) {
	wider private;
	if (has_field(private,'mask')) {
	    # must have been called at least once
	    maskChanged := private.setAmask(private.ddMask, private.knownDd, private.ddid, ddid);
	    maskChanged := private.setAmask(private.feedMask, private.knownFeed, private.feed, feed) || maskChanged;
	    maskChanged := private.setAmask(private.calMask, private.knownCal, private.cal, cal) || maskChanged;
	    maskChanged := private.setAmask(private.sigMask, private.knownSig, private.sig, sig) || maskChanged;
	    if (maskChanged) {
		private.mask := private.ddMask & private.feedMask & private.calMask & private.sigMask;
	    }
	} else {
	    # initial call, set everything
	    nRow := len(private.ddid);
	    private.mask := private.ddMask := private.feedMask := private.calMask := private.sigMask := array(T, nRow);
	    private.knownDd := private.knownFeed := private.knownCal := private.knownSig := -1;
	}
	return T;
    }

    public.more := function() {
	wider private;
	if (private.fixedShape) {
	    return private.thisRowEnd < private.totRows;
	} else {
	    result := F;
	    for (thisData in private.gbtdatas) {
		result := result || thisData.more();
	    }
	}
	return result;
    }

    public.next := function() {
	wider private;
	if (private.fixedShape) {
	    private.putChunk();
	    if (public.more()) private.getChunk(private.thisRowEnd+1);
	} else {
	    for (thisData in private.gbtdatas) {
		thisData.next();
	    }
	}
	return T;
    }

    public.origin := function() {
	wider private;
	if (private.fixedShape && !private.fixedShape) {
	    private.putChunk();
	    private.getChunk(1);
	} else {
	    for (thisData in private.gbtdatas) {
		thisData.origin();
	    }
	}
	return T;
    }

    public.nfeed := function(feedid=unset) {
	wider private;
	result := 0;
	if (is_unset(feedid)) {
	    result := private.sanity.nfeeds;
	} else {
	    whichfeed := private.sanity.feeds == feedid;
	    if (sum(whichfeed) == 1) {
		result := private.sanity.nfeed[whichfeed];
	    }
	}
	return result;
    }

    public.nddid := function() {
	wider private;
	return private.sanity.nddid;
    }

    public.ncal := function() {
	wider private;
	return private.stateinfo.ncal;
    }

    public.nsig := function() {
	wider private;
	return private.stateinfo.nsig;
    }

    public.nrows := function() {
	wider private;
	return private.sanity.nrows;
    }

    public.flush := function() {
	wider private;
	if (private.fixedShape) {
	    private.putChunk();
	} else {
	    for (thisData in private.gbtdatas) {
		thisData.flush();
	    }
	}
	return T;
    }

    public.ufeed := function(ddid) {
	wider private;
	if (private.fixedShape) {
	    return unique(private.feed[private.ddid==ddid]);
	} else {
	    sddid := as_string(ddid);
	    if (has_field(private.gbtdatas,sddid)) {
		return private.gbtdatas[sddid].ufeed(ddid);
	    }
	}
	return F;
    }

    public.uddid := function() {
	wider private;
	return private.fullUddid;
    }

    public.usigDdid := function(feed, sig) {
	wider private;
	if (private.fixedShape) {
	    private.setMask(feed=feed, sig=sig);
	    result := unique(private.ddid[private.mask]);
	} else {
	    result := as_integer([]);
	    for (thisdata in private.gbtdatas) {
		thisRes := thisdata.usigDdid(feed, sig);
		if (len(thisRes) > 0) {
		    start := len(result)+1;
		    end := start + len(thisRes) - 1;
		    result[start:end] := thisRes;
		}
	    }
	}
	return result;
    }

    public.cal := function(ddid, feed) {
	wider private;
	if (private.fixedShape) {
	    private.setMask(ddid, feed);
	    return unique(private.cal[private.mask]);
	} else {
	    sddid := as_string(ddid);
	    if (has_field(private.gbtdatas, sddid)) {
		return private.gbtdatas[sddid].cal(ddid, feed);
	    }
	}
    }
    
    public.sig := function(ddid, feed) {
	wider private;
	if (private.fixedShape) {
	    private.setMask(ddid, feed);
	    return unique(private.sig[private.mask]);
	} else {
	    sddid := as_string(ddid);
	    if (has_field(private.gbtdatas, sddid)) {
		return private.gbtdatas[sddid].sig(ddid, feed);
	    }
	}
    }
    
    public.getdata := function(ddid, feed, cal=unset, sig=unset) {
	wider private;
	if (private.fixedShape) {
	    private.setMask(ddid, feed, cal, sig);
	    return private.ensure3Dshape(private.floatData[,,private.mask]);
	} else {
	    sddid := as_string(ddid);
	    if (has_field(private.gbtdatas, sddid)) {
		return private.gbtdatas[sddid].getdata(ddid, feed, cal, sig);
	    }
	}
	return F;
    }

    public.getAllData := function(ddid, feed, cal=unset, sig=unset) {
	wider private;
	result := public.getdata(ddid, feed, cal, sig);
	result::flag := public.getflag(ddid, feed, cal, sig);
	result::weight := public.getweight(ddid, feed, cal, sig);
	return result;
    }

    public.getweight := function(ddid, feed, cal=unset, sig=unset) {
	wider private;
	if (private.fixedShape) {
	    private.setMask(ddid, feed, cal, sig);
	    return private.ensure2Dshape(private.weight[,private.mask]);
	} else {
	    sddid := as_string(ddid);
	    if (has_field(private.gbtdatas, sddid)) {
		return private.gbtdatas[sddid].getweight(ddid, feed, cal, sig);
	    }
	}
	return F;
    }

    public.getflag := function(ddid, feed, cal=unset, sig=unset) {
	wider private;
	if (private.fixedShape) {
	    private.setMask(ddid, feed, cal, sig);
	    return private.ensure3Dshape(private.flag[,,private.mask]);
	} else {
	    sddid := as_string(ddid);
	    if (has_field(private.gbtdatas, sddid)) {
		return private.gbtdatas[sddid].getflag(ddid, feed, cal, sig);
	    }
	}
	return F;
    }

    public.getelev := function(ddid, feed, cal=unset, sig=unset) {
	wider private;
	if (private.fixedShape) {
	    private.setMask(ddid, feed, cal, sig);
	    return private.chunkElev[private.mask];
	} else {
	    sddid := as_string(ddid);
	    if (has_field(private.gbtdatas, sddid)) {
		return private.gbtdatas[sddid].getelev(ddid, feed, cal, sig);
	    }
	}
	return F;
    }

    public.gettime := function(ddid, feed, cal=unset, sig=unset) {
	wider private;
	if (private.fixedShape) {
	    private.setMask(ddid, feed, cal, sig);
	    return private.chunkTime[private.mask];
	} else {
	    sddid := as_string(ddid);
	    if (has_field(private.gbtdatas, sddid)) {
		return private.gbtdatas[sddid].gettime(ddid, feed, cal, sig);
	    }
	}
	return F;
    }

    public.gettexp := function(ddid, feed, cal=unset, sig=unset) {
	wider private;
	if (private.fixedShape) {
	    private.setMask(ddid, feed, cal, sig);
	    return private.texp[private.mask];
	} else {
	    sddid := as_string(ddid);
	    if (has_field(private.gbtdatas, sddid)) {
		return private.gbtdatas[sddid].gettexp(ddid, feed, cal, sig);
	    }
	}
	return F;
    }

    public.putdata := function(data, ddid, feed, cal=unset, sig=unset) {
	wider private;
	result := F;
	if (private.fixedShape) {
	    private.setMask(ddid, feed, cal, sig);
	    private.floatData[,,private.mask] := private.removeDegenerateAxes(data);
	    private.putPending := T;
	    result := T;
	} else {
	    sddid := as_string(ddid);
	    if (has_field(private.gbtdatas, sddid)) {
		result := private.gbtdatas[sddid].putdata(data, ddid, feed, cal, sig);
	    }
	}
	return result;
    }

    public.putAllData := function(data, flag, sigma, ddid, feed, cal=unset, sig=unset) {
	wider public;
	public.putdata(data, ddid, feed, cal, sig);
	public.putflag(flag, ddid, feed, cal, sig);
	public.putsigma(sigma, ddid, feed, cal, sig);
	return T;
    }

    public.putflag := function(flag, ddid, feed, cal=unset, sig=unset) {
	wider private;
	result := F;
	if (private.fixedShape) {
	    private.setMask(ddid, feed, cal, sig);
	    private.flag[,,private.mask] := private.removeDegenerateAxes(flag);
	    private.putPending := T;
	    result := T;
	} else {
	    sddid := as_string(ddid);
	    if (has_field(private.gbtdatas, sddid)) {
		result := private.gbtdatas[sddid].putflag(ddid, flag, feed, cal, sig);
	    }
	}
	return result;
    }

    public.putsigma := function(sigma, ddid, feed, cal=unset, sig=unset) {
	wider private;
	result := F;
	if (private.fixedShape) {
	    private.setMask(ddid, feed, cal, sig);
	    private.sigma[,private.mask] := private.removeDegenerateAxes(sigma);
	    private.putPending := T;
	    result := T;
	} else {
	    sddid := as_string(ddid);
	    if (has_field(private.gbtdatas, sddid)) {
		result := private.gbtdatas[sddid].putflag(ddid, flag, feed, cal, sig);
	    }
	}
	return result;
    }

    public.done := function() {
	wider private;
	if (private.fixedShape) {
	    private.putChunk();
	} else {
	    for (thisData in private.gbtdatas) {
		thisData.done();
	    }
	}
	private.stateTab.done();
	private.tab.done();
	val private := F;
	val public := F;
	return T;
    }

    public.debug := function() {
	wider private;
	return ref private;
    }

    private.init();

    return ref public;
}

doit := function(scan) {
    t0 := time();
    gd := gbtdata(t, scan, 5, 128*1024e3);
    for (ddid in gd.uddid()) {
	for (feed in gd.ufeed(ddid)) {
	    cal := gd.cal(ddid, feed);
	    sig := gd.sig(ddid, feed);
	    for (thisCal in cal) {
		for (thisSig in sig) {
		    fd := gd.getdata(ddid, feed, thisCal, thisSig);
		    f := gd.getflag(ddid, feed, thisCal, thisSig);
		    w := gd.getweight(ddid, feed, thisCal, thisSig);
		}
	    }
	}
    }
    gd.done();
    return time()-t0;
}
