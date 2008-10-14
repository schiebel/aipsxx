# gbtcalibrator: closure object for gbt calibration
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
# $Id: gbtcalibrator.g,v 19.15 2006/07/21 15:25:58 bgarwood Exp $

# include guard
pragma include once
include "sysinfo.g";
include "measures.g";
include "functionfitter.g";
include "fftserver.g";
include "gbtdata.g";

gbtcalibrator := function()
{
    private := [=];
    public := [=];

    private.ms := F;
    private.scansms := F;
    private.scans := F;
    private.rowsel := F;
    private.subSyscalTab := F;
    private.info := sysinfo();
    private.ffitter := F;
    private.fftserver := F;
    thisSysMem := 64;
    if (! aipsrc().findint(thisSysMem,'system.resources.memory',def=64)) thisSysMem := 64;

    private.memSize := 0.5 * thisSysMem * 1024e3;

    private.msg := function(msg, priority='NORMAL')
    {
	dl.log(message=msg, priority=priority, postcli=T);
    }

    private.error := function(msg)
    {
	wider private;
	private.msg(msg, 'SEVERE');
    }


    private.putTsys := function()
    {
	wider private;

	if (is_table(private.subSyscalTab)) {
	    for (thisFeed in private.syscalInfo) {
		for (thisInfo in thisFeed) {
		    if (thisInfo.nMainRows == 0) {
			# no actual data here, probably Ka data, skip it
			continue;
		    }
		    global __syscalRows__ := thisInfo.rows;
		    subsubsyscal := private.subSyscalTab.query('rownumber() in $__syscalRows__');
		    if (subsubsyscal.nrows() != len(__syscalRows__)) {
			private.error('Could not write Tsys values back to table - this should never happen.');
		    } else {
			rawTsys := subsubsyscal.getcol('TSYS');
			# need a translation to receptor here and iteration over that as appropriate
			for (thisCorr in 1:len(thisInfo.rcpts)) {
			    rawTsys[thisInfo.rcpts[thisCorr],] := thisInfo.tsys[thisCorr,];
			}
			nanmask := is_nan(rawTsys)
			if (sum(nanmask) > 0) {
			    rawTsys[nanmask] := 1.0/0.0;  # set bad data to inf Tsys
			}
			subsubsyscal.putcol('TSYS',rawTsys);
		    }
		    subsubsyscal.done();
		}
	    }		
	} else {
	    private.error('No SYSCAL table already opened to write Tsys values back to - this should never happen.');
	}
	return T;
    }

    private.baseline := function(ref arr, flag, range, order)
    {
	wider private;
	if (is_boolean(private.ffitter)) private.ffitter:=functionfitter();
	if (is_unset(range) || is_boolean(range)) range:=1:arr::shape[2];
	pf := dfs.poly(order);
	private.ffitter.setfunction(pf);
	allx := as_double(1:arr::shape[2]);
	# scale this to improve usefulness of fit at high orders
	allx /:= max(allx)
	rangeMask := array(F,arr::shape[2]);
	rangeMask[range] := T;
        anyFlags := sum(flag) > 0;
	for (k in 1:arr::shape[1]) {
	    for (j in 1:arr::shape[3]) {
                if (anyFlags) {
                    thisMask := rangeMask & !flag[k,,j];
                } else {
                    thisMask := rangeMask;
                }
		if (sum(thisMask) >= order) {
		    private.ffitter.setdata(allx[thisMask], arr[k,thisMask,j]);
		    # there may be a bug in linear here, but linear=F behaves
		    # the way I expect it to and linear=T does not
		    # but that means setparameters needs to be called to 
		    # avoid an error message
		    private.ffitter.setparameters(pf.parameters());
		    private.ffitter.fit(linear=F);
		    pf.setparameters(private.ffitter.getsolution());
		    arr[k,,j] -:= pf.f(allx);
		} # else all is flagged, not enough to fit given range
	    }
	};
	return T;
    }

    private.scaleByUnits := function(ref arr, units, calceffs, syscalInfo, elev)
    {
	wider private;
	# short circuit this if units is 0, factor is always 1 then
	if (units==0) {
	    d.uniput('factor',1);
	    d.uniput('units','TA');
	    return T;
	}
	thisFreq := syscalInfo.centerFreq;
	for (ind in 1:len(elev)) {
	    d.geteffonsky(thisFreq,elev[ind],units,calceffs);
	    arr[,,ind] *:= d.uniget('factor');
	}
	return T;
    }


    private.scanQuery := function(scans)
    {
	wider private;
	if (is_unset(scans)) {
	    queryString := spaste('SCAN_NUMBER > 0');
	} else if (len(scans) == 1) {
	    queryString := spaste('SCAN_NUMBER == ', scans);
	} else {
	    global __query_scan_list__ := scans;
	    queryString := spaste('SCAN_NUMBER in $__query_scan_list__');
	}
	return private.ms.query(queryString);
    }

    private.uniqueInOrder := function(s)
    {
	n := len(s);
	if (n == 1) return s;

	diff := s[2:n] - s[1:(n-1)];
	mask := diff != 0;
	result := s[1];
	if (any(mask)) {
	    result := [result,(s[2:n])[mask]];
	} 
	return result;
    }

    private.firstSpwin := function(spwin, swstate, sigstate) {
	wider private;
	# we need to put spwin in the order they each first appear in spwin
	# this does that
	# for FSWITCH data, need to do sig=T and sig=F separately
	if (swstate == 'FSWITCH' && len(sigstate) == len(spwin) &&
	    sum(sigstate) == len(sigstate)/2) {
	    sigFspw := private.firstSpwin(spwin[sigstate==T],'',F);
	    refFspw := private.firstSpwin(spwin[sigstate==F],'',F);
	    
	    # and merge them - starting with whatever sig comes first
	    
	    if (!sigstate[1]) {
		tmp := refFspw;
		refFspw := sigFspw;
		sigFspw := tmp;
	    }
	    result := array(1,2*len(sigFspw));
	    for (i in 1:len(sigFspw)) {
		result[i*2-1] := sigFspw[i];
		result[i*2] := refFspw[i];
	    }
	    return result;
	} else {
	    uspwin := unique(spwin);
	    fspw := array(0,len(uspwin));
	    ispw := ind(spwin);
	    for (i in 1:len(fspw)) {
		fspw[i] := (ispw[spwin==uspwin[i]])[1];
	    }
	    # fspw now holds the locations of spwin where each uspwin first 
	    # occurs so that when fspw is sorted, it will record the locations
	    # where a new spwin first occured - which indicates what the order
	    # of spwins encountered was.
	    
	    sfspw := sort(fspw);
	    ifspw := ind(fspw);
	    ospw := array(0,len(fspw));
	    for (i in 1:len(sfspw)) {
		ospw[i] := spwin[fspw[fspw==sfspw[i]]];
	    } 
	    return ospw;
	}
	return F;
    }

    private.scanSum := function(scan)
    {
	wider private;
	result := [=];
	result.scan := scan;
	result.scanMask := private.scan == scan;
	result.ufeed := unique(private.feed[result.scanMask]);
	result.procname := unique(private.procname[result.scanMask]);
	result.procseqn := unique(private.procseqn[result.scanMask]);
	result.procsize := unique(private.procsize[result.scanMask]);
	result.swstate := unique(private.swstate[result.scanMask]);
	result.swtchsig := unique(private.swtchsig[result.scanMask]);
	result.uddid := private.firstSpwin(private.ddid[result.scanMask], 
					   result.swstate, 
					   private.sig[result.scanMask]);

	return result;
    }

    private.setScanInfo := function()
    {
	wider private;

	# characterize the scans in scansms.  No need to be defensive here.
	private.time := private.scansms.getcol('TIME');
	private.feed := private.scansms.getcol('FEED1');
	private.ddid := private.scansms.getcol('DATA_DESC_ID');
	private.scan := private.scansms.getcol('SCAN_NUMBER');
	private.stateid := private.scansms.getcol('STATE_ID');
	private.uscan := private.uniqueInOrder(private.scan);
	private.ufeed := unique(private.feed);
	private.uddid := unique(private.ddid);

	private.procname := array('',private.scansms.nrows());
	private.procseqn := array(1,private.scansms.nrows());
	private.procsize := array(1,private.scansms.nrows());
	private.swtchsig := private.swstate := private.procname;
	private.sig := array(T,private.scansms.nrows());
	private.rows := [1:private.scansms.nrows()];

	stateTab := table(private.scansms.getkeyword('STATE'),ack=F);
	if (is_table(stateTab) && stateTab.nrows() > 0) {
	    stateObsmode := stateTab.getcol('OBS_MODE');
	    stateSig := stateTab.getcol('SIG');
	    stateCal := stateTab.getcol('CAL') == 1;  # makes sure its a bool
	    stateProc := array('',stateTab.nrows());
	    stateSwsig := array('',stateTab.nrows());
	    stateSwstate := array('',stateTab.nrows());
	    if (any(stateTab.colnames()=='NRAO_GBT_PROCSEQN')) {
		stateProcseqn := stateTab.getcol('NRAO_GBT_PROCSEQN');
	    } else {
		stateProcseqn := array(1,stateTab.nrows());
	    }
	    if (any(stateTab.colnames()=='NRAO_GBT_PROCSIZE')) {
		stateProcsize := stateTab.getcol('NRAO_GBT_PROCSIZE');
	    } else {
		stateProcsize := array(1,stateTab.nrows());
	    }
	    for (i in 1:stateTab.nrows()) {
		obsmode := split(stateObsmode[i],':');
		if (len(obsmode) == 3) {
		    stateProc[i] := obsmode[1];
		    stateSwstate[i] := obsmode[2];
		    stateSwsig[i] := obsmode[3];
		} else {
		    # this can't be GB data, warn, but go on
		    private.msg(spaste('Unexpected OBS_MODE value encountered',
				       ', this is probably not GBT data'),
				priority='WARN');
		    stateProc[i] := stateObsmode[i];
		}
	    }

	    # translate the STATE_IDs into procname, procsize, procseqn, 
	    # swtchsig, swstate, sig, and cal
	    okstateids := private.stateid >= 0 & 
		private.stateid < stateTab.nrows();
	    if (sum(okstateids) > 0) {
		private.stateid[okstateids] +:= 1; # correct to 1-relative indx
		theseStateids := private.stateid[okstateids];
		ustates := unique(theseStateids);
		for (state in ustates) {
		    thismask := theseStateids == state;
		    private.procname[thismask] := stateProc[state];
		    private.swtchsig[thismask] := stateSwsig[state];
		    private.swstate[thismask] := stateSwstate[state];
		    private.sig[thismask] := stateSig[state];
		    private.procsize[thismask] := stateProcsize[state];
		    private.procseqn[thismask] := stateProcseqn[state];
		}
	    }
	    if (sum(!okstateids) > 0) {
		# there are some bad ones
		badRows := !okstateids;
		private.stateid[badRows] := -1;
		# the other values should still have their default value 
		# at these rows
	    }
	} else {
	    # bad state table, set all stateid values to -1
	    private.stateid := array(-1, len(private.stateid));
	}

	if (is_table(stateTab)) stateTab.done();
	return T;
    }

    private.setSyscalInfo := function()
    {
	wider private;
	# no need to be completely defensive here
	syscalTab := table(private.scansms.getkeyword('SYSCAL'),
			   readonly=F,ack=F);
	if (!is_table(syscalTab)) {
	    private.error('No SYSCAL table found - this should never happen.');
	    return F;
	}
	if (is_table(private.subSyscalTab)) private.subSyscalTab.done();
	global __btime := min(private.time)-1.0;
	global __etime := max(private.time)+1.0;
	private.subSyscalTab := 
	    syscalTab.query('TIME<=$__etime && TIME>=$__btime');
	syscalTab.done();
	if (!is_table(private.subSyscalTab)) {
	    private.error('Could not do SYSCAL table selection - this should never happen.');
	    return F;
	}
	if (private.subSyscalTab.nrows() == 0) {
	    private.error('There are no matching rows in the SYSCAL table for this scan, can not calibrate');
	    private.subSyscalTab.done();
	    return F;
	}
	if (!any(private.subSyscalTab.colnames()=='TSYS')) {
	    private.error('There is no TSYS column in the SYSCAL table - this should never happen.');
	    private.subSyscalTab.done();
	    return F;
	}

	ddTab := table(private.scansms.getkeyword('DATA_DESCRIPTION'),ack=F);
	if (!is_table(ddTab)) {
	    private.error('There is no DATA_DESCRIPTION table - this should never happen.');
	    return F;
	}
	spwid := ddTab.getcol('SPECTRAL_WINDOW_ID');
	polid := ddTab.getcol('POLARIZATION_ID');
	usedPolid := polid[private.ddid+1];
	ddTab.done();
	
	uddid := unique(private.ddid);
	ufeed := unique(private.feed);
	
	polTab := table(private.scansms.getkeyword('POLARIZATION'),ack=F);
	if (!is_table(polTab)) {
	    private.error('There is no POLARIZATION table - this should never happen.');
	    return F;
	}
	receptors := [=];
	crossProdError := F;
	for (thisPol in unique(usedPolid)) {
	    stringPol := as_string(thisPol);
	    corrProd := polTab.getcell('CORR_PRODUCT',thisPol+1);
	    receptors[stringPol] := array(1,polTab.getcell('NUM_CORR',
							   thisPol+1));
	    # sanity check - early fillers got this wrong
	    if (len(receptors[stringPol]) != corrProd::shape[2]) {
		# default to the simple case - probably right
		receptors[stringPol] := ind(receptors[stringPol]);
	    } else {
		if (any(corrProd[1,] != corrProd[2,]) && !crossProdError) {
		    crossProdError := T;
		    private.error('These scans contain cross-polarization data, which is not yet supported.');
		    private.error('Calibration results are probably wrong');
		}
		receptors[stringPol] := corrProd[1,]+1;
	    }
	}
	polTab.done();
	
	swTab := table(private.scansms.getkeyword('SPECTRAL_WINDOW'),ack=F);
	if (!is_table(swTab)) {
	    private.error('There is no SPECTRAL_WINDOW table - this should never happen.');
	    return F;
	}

	private.syscalInfo := [=];
	syscalTimes := private.subSyscalTab.getcol('TIME');
	syscalFeeds := private.subSyscalTab.getcol('FEED_ID');
	syscalSPWids := private.subSyscalTab.getcol('SPECTRAL_WINDOW_ID');
	syscalRows := [1:len(syscalTimes)];
	hasTcalSpec := any(private.subSyscalTab.colnames()=='TCAL_SPECTRUM');

	missingRows := F;
	for (thisFeed in private.ufeed) {
	    thisFeedsInfo := [=];
	    for (thisDDid in private.uddid) {
		thisInfo := [=];
		mainMask := private.feed == thisFeed & 
		    private.ddid == thisDDid;
		mask := (syscalFeeds == thisFeed) & 
		    (syscalSPWids == (spwid[thisDDid+1]));
		thisSProw := spwid[thisDDid+1]+1;
		thisInfo.nchan := swTab.getcell('NUM_CHAN',thisSProw);
		nmid := as_integer(thisInfo.nchan/2.0 + 0.5);
		thisInfo.deltaf := 
		    abs(swTab.getcell('CHAN_WIDTH',thisSProw)[nmid]);
		cf := swTab.getcell('CHAN_FREQ',thisSProw);
		thisInfo.chanSpacing := thisInfo.deltaf;
		if (cf[2] < cf[1]) thisInfo.chanSpacing *:= -1.0;
		thisInfo.centerFreq := cf[nmid];
		thisPol := polid[thisDDid+1];
		theseRcpts := receptors[as_string(thisPol)];
		thisInfo.rcpts := theseRcpts;
		thisInfo.npol := len(theseRcpts);
		thisInfo.tcal := array(1.0,thisInfo.npol);
		thisInfo.tcal_spec := array(1.0, thisInfo.npol, 
					    thisInfo.nchan);
		thisInfo.nMainRows := sum(mainMask);
		thisInfo.sizeInBytes := 
		    thisInfo.npol * thisInfo.nchan * thisInfo.nMainRows * 4;
		if (sum(mask) > 0) {
		    thisInfo.rows := syscalRows[mask];
		    thisInfo.times := syscalTimes[mask];
		    # for a given scan, TCAL and TCAL_SPECTRUM will 
		    # not vary with time, just feed and spwid
		    rawTcal := private.subSyscalTab.getcell('TCAL',
							    thisInfo.rows[1]);
		    if (hasTcalSpec) {
			rawTcalSpec := 
			    private.subSyscalTab.getcell('TCAL_SPECTRUM',
							 thisInfo.rows[1]);
		    } else {
			rawTcalSpec := array(rawTcal,len(rawTcal),
					     thisInfo.nchan);
		    }
		    for (thisCorr in 1:thisInfo.npol) {
			thisInfo.tcal[thisCorr] := 
			    rawTcal[theseRcpts[thisCorr]];
			thisInfo.tcal_spec[thisCorr,] := 
			    rawTcalSpec[theseRcpts[thisCorr],];
		    }
		} else {
		    # check to see if this is going to be a problem
		    if (sum(mainMask) > 0) {
			# set up holders and default values, and issue a 
			# warning that things are wonky
			if (!missingRows) {
			    private.error('Some SYSCAL information is missing - calibration will be incomplete.');
			    missingRows := T; 
			    # only emit this once each time this function 
			    # is run
			}
			thisInfo.times := private.time[mainMask];
			thisInfo.rows := array(-1, len(thisInfo.times));
		    } else {
                        # otherwise things die, even though this isn't necessary
                        thisInfo.rows := 1;
                        thisInfo.times := -1.0;
                    }
		}
		# this is a holder for when tsys is actually determined
		thisInfo.tsys := array(1.0, thisInfo.npol, len(thisInfo.rows));

		thisFeedsInfo[as_string(thisDDid)] := thisInfo;
	    }
	    private.syscalInfo[as_string(thisFeed)] := thisFeedsInfo;
	}
	swTab.done();
	return T;
    }

    public.setms := function(msname)
    {
	wider private, public;
	public.closeMS();
	private.ms := table(msname,readonly=F,ack=F);
	if (!is_table(private.ms)) {
	    private.error(spaste('Could not open the MeasurementSet : ',
				 msname));
	    return F;
	}

	return T;
    }

    public.setscans := function(scans=unset)
    {
	wider private;
	if (!is_table(private.ms)) {
	    private.error('No MS has been set yet');
	    return F;
	}
	if (!is_unset(scans) && !is_integer(scans)) {
	    private.error('Scans must be integers');
	    return F;
	}
	if (!is_unset(scans) && len(scans) < 1) {
	    private.error('No scans specified');
	    return F;
	}
	if (is_unset(scans) ||
	    is_boolean(private.scans) || 
	    len(private.scans) != len(scans) || private.scans==scans) {
	    if (is_table(private.scansms)) private.scansms.done();
	    if (is_table(private.rowsel)) {
		private.rowsel.done();
		private.rowsel := F;
	    }
	    private.scans := F;
	    private.scansms := private.scanQuery(scans);
	    if (!is_table(private.scansms)) {
		private.error('Could not do SCAN_NUMBER selection on MS - this should not happen');
		return F;
	    }
	    if (private.scansms.nrows() == 0) {
		private.error('Those scans are not in this MeasurementSet');
		private.scansms.done();
		private.scansms := F;
		return F;
	    }
	    if (is_unset(scans)) {
		private.scans := unique(private.scansms.getcol('SCAN_NUMBER'));
	    } else {
		private.scans := scans;
	    }
	}  # otherwise its the same set of scans - reuse the selection

	ok := private.setScanInfo();
	ok := ok && private.setSyscalInfo();
	if (!ok) {
	    # the things are not ok, error message will have already 
	    # been issued
	    private.scansms.done();
	    private.scans := F;
	}

	return ok;
    }

    private.getMeanTsys := function(ons, offs, tcalspec, chanMask, flags) 
    {
	# shape of ons or offs is [npol, nchan, nspec]
	# returns [npol, nspec] - one tsys for each nspec
	# tcalspec is a single tcal spectrum for all ons and offs
	# with shape [npol,nchan]

	# watch for missing data - possible from Ka band
	if (len(ons) == 0 || len(offs) == 0) return F;

	is3d := len(ons::shape) == 3;
	nspec := 1;
	if (is3d) nspec := ons::shape[3];

	result := array(0.0, offs::shape[1], nspec);

	tsys := offs / (ons - offs);

	# scale by tcalspec
	if (!is3d) {
	    tsys *:= tcalspec;
	} else {
	    for (spec in 1:nspec) {
		tsys[,,spec] *:= tcalspec;
	    }
	}
	
	for (pol in 1:offs::shape[1]) {
	    if (!is3d) {
		result[pol,1] := mean(tsys[pol,chanMask]);
	    } else {
		for (spec in 1:nspec) {
		    theseChans := chanMask & flags[pol,,spec];
		    result[pol,spec] := mean(tsys[pol,theseChans,spec]);
		}
	    }
	}
	
	if (!is3d) { result::shape := result::shape[1];}
	else {
	    if (len(result::shape)==1) {
		result::shape := [result::shape,1];
	    }
	}
	
	return result;
    }
    
    private.scaleAll := function(ref data, ascale) 
    {
	if (len(data::shape) == 3) {
	    for (pol in 1:data::shape[1]) {
		for (spec in 1:data::shape[3]) {
		    data[pol,,spec] *:= ascale[pol,spec];
		}
	    }
	} else {
	    for (pol in 1:data::shape[1]) {
		data[pol,] *:= ascale[pol];
	    }
	}
    }

    private.avg := function(a, b) 
    {
	# watch for 0-length data, Ka band
	if (len(a) == 0 || len(b) == 0) return F;

	# best to avoid bloating weight, I think
	awt := a::weight;
	bwt := b::weight;
	result := a;
	for (pol in 1:awt::shape[1]) {
	    for (spec in 1:awt::shape[2]) {
		result[pol,,spec] := (a[pol,,spec]*awt[pol,spec] + b[pol,,spec]*bwt[pol,spec]) / (awt[pol,spec] + bwt[pol,spec]);
	    }
	}
	return result;
    }

    private.processNodTP := function(s1b1on, s1b1off, s1b2on, s1b2off, s2b1on, s2b1off, s2b2on, s2b2off,
				     tcals1, tcals2, tsysChanMask, tsys)
    {
	wider private;
	result := [=];
	result.tsys := 1.0;
	result.arr := 0.0;

	if (!is_boolean(tsys)) {
	    if (len(tsys) != s1b1on::shape[1]) {
		tsys := array(tsys[1],s1b1on::shape[1]);
	    }
	    if (len(s1b1on::shape) == 3) {
		tsys := array(tsys, s1b1on::shape[1], s1b1on::shape[3]);
	    } else {
		tsys := array(tsys, s1b1on::shape[1], 1);
	    }
	    meanTsys_b1s1 := tsys;
	    meanTsys_b2s2 := tsys;
	} else {
	    meanTsys_b1s1 := private.getMeanTsys(s1b1on, s1b1off, tcals1, tsysChanMask, !(s1b1on::flag | s1b1off::flag));
	    meanTsys_b2s2 := private.getMeanTsys(s2b2on, s2b2off, tcals2, tsysChanMask, !(s2b2on::flag | s2b2off::flag));
	}

	# get the sigs and refs, 
	sigs1t  := private.avg(s1b1off, s1b1on);
	refs1t  := private.avg(s1b2off, s1b2on);
	refs2t  := private.avg(s2b1off, s2b1on);
	sigs2t  := private.avg(s2b2off, s2b2on);

	result.arr := F;
	result.tsys := F;
	nsum := 0;

	# and the individual calibrated beams
	# do this carefully to watch out for missing data 
	# which is probably ka data
	if (!is_boolean(sigs1t) && !is_boolean(refs2t)) {
	    calb1t  := (sigs1t - refs2t)/refs2t;
	    private.scaleAll(calb1t, meanTsys_b1s1);
	    result.arr := calb1t;
	    result.tsys := meanTsys_b1s1;
	    nsum := 1;
	}

	if (!is_boolean(sigs2t) && !is_boolean(refs1t)) {
	    calb2t  := (sigs2t - refs1t)/refs1t;
	    private.scaleAll(calb2t, meanTsys_b2s2);
	    if (nsum == 0) {
		result.arr := calb2t;
		result.tsys := meanTsys_b2s2;
		nsum := 1;
	    } else {
		result.arr +:= calb2t;
		nsum +:= 1;
	    }
	}
	if (nsum > 0) result.arr /:= nsum;

	return result;
    }

    private.swap := function(ref a, ref b) {
	tmp := a;
	val a := b;
	val b := tmp;
	return T;
    }

    private.processNodBS := function(s1b1sigon, s1b1sigoff, s1b1refon, s1b1refoff,
				     s1b2sigon, s1b2sigoff, s1b2refon, s1b2refoff,
				     s2b1sigon, s2b1sigoff, s2b1refon, s2b1refoff,
				     s2b2sigon, s2b2sigoff, s2b2refon, s2b2refoff,
				     tcals1, tcals2, tsysChanMask, tsys)
    {
	wider private;

	result := [=];
	result.tsys := 1.0;
	result.arr := 0.0;

	if (!is_boolean(tsys)) {
	    if (len(tsys) != s1b1sigon::shape[1]) {
		tsys := array(tsys[1],s1b1sigon::shape[1]);
	    }
	    if (len(s1b1sigon::shape) == 3) {
		tsys := array(tsys, s1b1sigon::shape[1], s1b1sigon::shape[3]);
	    } else {
		tsys := array(tsys, s1b1sigon::shape[1], 1);
	    }
	    meanTsys_b1s1 := tsys;
	    meanTsys_b2s1 := tsys;
	    meanTsys_b1s2 := tsys;
	    meanTsys_b2s2 := tsys;
	} else {
	    meanTsys_b1s1 := private.getMeanTsys(s1b1refon, s1b1refoff, tcals1, 
						 tsysChanMask, !(s1b1refon::flag | s1b1refoff::flag));
	    meanTsys_b1s2 := private.getMeanTsys(s2b1sigon, s2b1sigoff, tcals2, 
						 tsysChanMask, !(s2b1sigon::flag | s2b1sigoff::flag));
	    meanTsys_b2s1 := private.getMeanTsys(s1b2sigon, s1b2sigoff, tcals1, 
						 tsysChanMask, !(s1b2sigon::flag | s1b2sigoff::flag));
	    meanTsys_b2s2 := private.getMeanTsys(s2b2refon, s2b2refoff, tcals2, 
						 tsysChanMask, !(s2b2refon::flag | s2b2refoff::flag));
	}
	
	# with the switch in the through position, i.e. "ref"
	sigs1t := private.avg(s1b1refoff, s1b1refon);
	refs1t := private.avg(s1b2refoff, s1b2refon);
	refs2t := private.avg(s2b1refoff, s2b1refon);
	sigs2t := private.avg(s2b2refoff, s2b2refon);
	
	# with the switch in the cross position, i.e. "sig"
	sigs1c := private.avg(s1b1sigoff, s1b1sigon);
	refs1c := private.avg(s1b2sigoff, s1b2sigon);
	refs2c := private.avg(s2b1sigoff, s2b1sigon);
	sigs2c := private.avg(s2b2sigoff, s2b2sigon);
	
	result.arr := F;
	result.tsys := F;
	nsum := 0;

	if (!is_boolean(sigs1t) && !is_boolean(refs2t)) {
	    calb1t := (sigs1t - refs2t)/refs2t;
	    private.scaleAll(calb1t, meanTsys_b1s1);
	    result.arr := calb1t;
	    result.tsys := meanTsys_b1s1;
	    nsum := 1;
	}

	if (!is_boolean(sigs2t) && !is_boolean(refs1t)) {
	    calb2t := (sigs2t - refs1t)/refs1t;
	    private.scaleAll(calb2t, meanTsys_b2s2);
	    if (nsum == 0) {
		result.arr := calb2t;
		result.tsys := meanTsys_b2s2;
		nsum := 1;
	    } else {
		result.arr +:= calb2t;
		nsum +:= 1;
	    }
	}
	
	if (!is_boolean(sigs1c) && !is_boolean(refs2c)) {
	    calb1c := (sigs1c - refs2c)/refs2c;
	    private.scaleAll(calb1c, meanTsys_b1s2);
	    if (nsum == 0) {
		result.arr := calb1c;
		result.tsys := meanTsys_b1s2;
		nsum := 1;
	    } else {
		result.arr +:= calb1c;
		nsum +:= 1;
	    }
	}

	if (!is_boolean(sigs2c) && !is_boolean(refs1c)) {
	    calb2c := (sigs2c - refs1c)/refs1c;
	    private.scaleAll(calb2c, meanTsys_b2s1);
	    if (nsum == 0) {
		result.arr := calb2c;
		result.tsys := meanTsys_b2s1;
		nsum := 1;
	    } else {
		result.arr +:= calb2c;
		nsum +:= 1;
	    }
	}

	if (nsum > 0) result.arr /:= nsum;
	
	return result;
    }

    private.getSigRefTsys := function(ons, offs, tcal, flags)
    {
	npol := ons::shape[1];
	nspec := ons::shape[3];
	result := array(1.0,npol,nspec);
	for (ipol in 1:npol) {
	    meanTcal := mean(tcal[ipol,]);
	    for (ispec in 1:nspec) {
		thisFlag := flags[ipol,,ispec];
		meanpower := mean((ons[ipol,thisFlag,ispec]+offs[ipol,thisFlag,ispec])/2.0);
		meancal := mean(ons[ipol,thisFlag,ispec]-offs[ipol,thisFlag,ispec]);
		result[ipol,ispec] := meanTcal * abs(meanpower/meancal);
	    }
	}
	return result;
    }

    private.processSigRef := function(sigon, sigoff, refon, refoff, tcal, tsys = unset)
    {
	wider private;

	result := [=];
	npol := sigon::shape[1];
	nspec := sigon::shape[3];
	if (is_unset(tsys)) {
	    result.tsysSig := private.getSigRefTsys(sigon, sigoff, tcal, !(sigon::flag | sigoff::flag));
	    result.tsysRef := private.getSigRefTsys(refon, refoff, tcal, !(refon::flag | refoff::flag));
	    tsysRef := result.tsysRef;
	} else {
	    tsysRef := tsys;
	    # don't need tsysSig here, trust caller doesn't need it returned
	}

	result.arr := private.avg(refon,refoff);
	
	result.arr := (private.avg(sigon,sigoff) - result.arr) / result.arr;
	for (ipol in 1:npol) {
	    thisTsys := tsysRef[ipol,];
	    for (ispec in 1:nspec) {
		result.arr[ipol,,ispec] *:= thisTsys[ispec];
	    }
	}
	return result;
    }

    private.processTP := function(on, off, tcal, meanTcalPower)
    {
	wider private;
	result := [=];
	result.tsys := private.getSigRefTsys(on, off, tcal, !(on::flag | off::flag));
	result.arr := private.avg(on,off);
	for (ipol in 1:result.arr::shape[1]) {
	    tcalScale := tcal[ipol,] / meanTcalPower[ipol];
	    for (iscan in 1:result.arr::shape[3]) {
		result.arr[ipol,,iscan] *:= tcalScale[iscan];
	    }
	}

	return result;
    }
    
    private.fold := function(ref sigRes, refRes, ref sigFlag, refFlag, 
			     sigCenterFreq, refCenterFreq, chanSpacing)
    {
	wider private;
	fshift := refCenterFreq - sigCenterFreq;
	fsw := fshift / chanSpacing;
	ishift := as_integer(abs(fsw)+0.5);
	# force a zero fraction shift for now, until a better one can be 
	# implemented which doesn't induce ringing
	# fracShift := abs(fsw) - ishift;
	fractShift := 0.0;

	if (fsw < 0) fractShift := -fractShift;
	if (abs(fractShift) > 0.01) {
	    if (is_boolean(private.fftserver)) {
		private.fftserver := fftserver();
	    }
	} else {
	    fractShift := 0.0;
	}

	if (ishift == 0 && fractShift == 0.0) {
	    private.msg('Frequency switch is 0 channels, result would be zero.  Ignoring request to fold data.',
			priority='WARN');
	    return F;
	}
	nchan := sigRes.arr::shape[2];
	if ((ishift+1) > nchan) {
	    private.msg('Frequency switch is > total number of channels.  Ignoring request to fold data.',
			priority='WARN');
	    return F;
	}
	# do any fraction shift
	if (fractShift != 0.0) {
	    shift := array(0.0, 3);
	    shift[2] := fractShift;
	    # before shifting, set the flagged channels to zero.  There's probably
	    # a better solution - like interpolation across them, but this
	    # should be better than nothing, I think.
	    refRes.arr[refFlag] := 0.0;
	    refRes.arr := private.fftserver.shift(refRes.arr, shift);
	}
	if (fsw > 0.0) {
	    sigChans := (1+ishift):nchan;
	    refChans := 1:(nchan-ishift);
	    sigRes.arr[,sigChans,] +:= refRes.arr[,1:(nchan-ishift),];
	    sigRes.arr[,sigChans,] /:= 2.0;
	    sigFlag[,sigChans,] := sigFlag[,sigChans,] | refFlag[,refChans,];
	    sigFlag[,refChans,] := sigFlag[,sigChans,];
	    sigRes.arr[,1:ishift,] := 0.0;
	} else {
	    sigChans := 1:(nchan-ishift);
	    refChans := (1+ishift):nchan;
	    sigRes.arr[,sigChans,] +:= refRes.arr[,refChans,];
	    sigRes.arr[,sigChans,] /:= 2.0;
	    sigFlag[,sigChans,] := sigFlag[,sigChans,] | refFlag[,refChans,];
	    sigFlag[,refChans,] := sigFlag[,sigChans,];
	    sigRes.arr[,(nchan-ishift+1):nchan,] := 0.0;
	}
	# the result should have tsys of the reference everywhere
	sigRes.tsysSig := sigRes.tsysRef;
	return T;
    }


    private.calNod := function(scanSum1, scanSum2, baseline, range, order, units, calceffs, flipsr, ddid=unset)
    {
	wider private;
	# NOD requires 4 copies
	scan1DDID := unset;
	scan2DDID := unset;
	if (!is_unset(ddid)) {
           scan1DDID := scanSum1.uddid[ddid];
           scan2DDID := scanSum2.uddid[ddid];
        }
	scan1data := gbtdata(private.ms, scanSum1.scan, 4, private.memSize, ddid=scan1DDID);
	scan2data := gbtdata(private.ms, scanSum2.scan, 4, private.memSize, ddid=scan2DDID);
	# final sanity check - everything must be symmetric.
	if ((scan1data.nrows() != scan2data.nrows()) ||
	    (scan1data.nfeed(scanSum1.ufeed[1]) != scan1data.nfeed(scanSum1.ufeed[2])) ||
	    (scan2data.nfeed(scanSum2.ufeed[1]) != scan1data.nfeed(scanSum2.ufeed[2])) ||
	    (scan1data.ncal() != 1/2*scan1data.nrows()) ||
	    (scan2data.ncal() != 1/2*scan2data.nrows()) ||
	    (scanSum1.swtchsig == "TPWCAL" && (scan1data.nsig() != scan1data.nrows())) ||
	    (scanSum2.swtchsig == "TPWCAL" && (scan2data.nsig() != scan2data.nrows())) ||
	    (scanSum1.swtchsig != "TPWCAL" && (scan1data.nsig() != 1/2*scan2data.nrows())) ||
	    (scanSum2.swtchsig != "TPWCAL" && (scan2data.nsig() != 1/2*scan2data.nrows()))) {
	    # there is a problem
            if (is_unset(ddid)) {
               private.msg('Some of the NOD data is missing',priority='WARN');
               scan1data.done();
               scan2data.done();
	       result := T;
               private.msg('Trying to do a NOD calibration of each individual spectral window',priority='WARN');
               for (idd in ind(scanSum1.uddid)) {
                  result := private.calNod(scanSum1, scanSum2, baseline, range, order, units, calceffs, flip, ddid=idd) && result;
               }
               if (!result) private.error('Unable to do any calibration on some or all of this data');
            } else {
	        if (scan1data.ncal() == 1/2*scan1data.nrows() &&
		   scan2data.ncal() == 1/2*scan2data.nrows()) {
                   scan1data.done();
                   scan2data.done();
	           private.msg(spaste('Missing expected data for IF=',ddid),priority='WARN');
		   private.msg('Will attempt to calibrate that IF in each scan separately as individual TPWCAL scans', 
                               priority='WARN');
		   result := private.calScan(scanSum1, baseline, range, order, units, calceffs,ddid=ddid);
		   result := private.calScan(scanSum2, baseline, range, order, units, calceffs,ddid=ddid) && result;
                } else {
                   scan1data.done();
                   scan2data.done();
                   result := F;
                }
	    } 
	    return result;
	}

	feed1 := scanSum1.ufeed[1];
	feed2 := scanSum1.ufeed[2];
	sfeed1 := as_string(feed1);
	sfeed2 := as_string(feed2);

	isTP := scanSum1.swtchsig == "TPWCAL";

	allIDDs := scanSum1.uddid;
	if (!is_unset(ddid)) allIDDs := ddid;

	while (T) {
	    # break out of this below, when scan1data.more() returns F
	    for (idd in allIDDs) {
		scan1ddid := scanSum1.uddid[idd];
		scan2ddid := scanSum2.uddid[idd];
		sddids1 := as_string(scan1ddid);
		sddids2 := as_string(scan2ddid);
		
		thisInfo1 := ref private.syscalInfo[sfeed1][sddids1];
		thisInfo2 := ref private.syscalInfo[sfeed2][sddids2];
		
		nchan := thisInfo1.nchan;
		inner80pctMask := array(F, nchan);
		inner80pctMask[(nchan*.1):(nchan*.9)] := T;
		
		if (has_field(thisInfo1,'tcal_spec')) {
		    # its safe to assume that both do
		    s1tcal := thisInfo1.tcal_spec;
		    s2tcal := thisInfo2.tcal_spec;
		} else {
		    s1tcal := array(0.0, thisInfo1.npol, nchan);
		    s2tcal := s1b1tcal;
		    tcal1 := thisInfo1.tcal;
		    tcal2 := thisInfo2.tcal;
		    for (pol in 1:thisInfo1.npol) {
			s1tcal[pol,] := tcal1[pol];
			s2tcal[pol,] := tcal2[pol];
		    }
		}
		
		if (isTP) {
		    s1b1on  := scan1data.getAllData(scan1ddid, feed1, T);
		    s1b1off := scan1data.getAllData(scan1ddid, feed1, F);
		    s1b2on  := scan1data.getAllData(scan1ddid, feed2, T);
		    s1b2off := scan1data.getAllData(scan1ddid, feed2, F);
		    s2b1on  := scan2data.getAllData(scan2ddid, feed1, T);
		    s2b1off := scan2data.getAllData(scan2ddid, feed1, F);
		    s2b2on  := scan2data.getAllData(scan2ddid, feed2, T);
		    s2b2off := scan2data.getAllData(scan2ddid, feed2, F);

		    if (len(s2b2on) == 0 || len(s2b2off) == 0) return F;

		    thisRes := private.processNodTP(s1b1on, s1b1off, s1b2on, s1b2off,
						    s2b1on, s2b1off, s2b2on, s2b2off,
						    s1tcal, s2tcal, inner80pctMask, F);

		    # flags should be an or of the individual state/beam/scan flags
		    allFlags := s1b1on::flag | s1b1off::flag | s1b2on::flag | s1b2off::flag |
			s2b1on::flag | s2b1off::flag | s2b2on::flag | s2b2off::flag;
		} else {
		    sig := T;
		    if (flipsr) sig := F;

		    s1b1sigon  := scan1data.getAllData(scan1ddid, feed1, T, sig);
		    s1b1sigoff := scan1data.getAllData(scan1ddid, feed1, F, sig);
		    s1b2sigon  := scan1data.getAllData(scan1ddid, feed2, T, sig);
		    s1b2sigoff := scan1data.getAllData(scan1ddid, feed2, F, sig);
		    s2b1sigon  := scan2data.getAllData(scan2ddid, feed1, T, sig);
		    s2b1sigoff := scan2data.getAllData(scan2ddid, feed1, F, sig);
		    s2b2sigon  := scan2data.getAllData(scan2ddid, feed2, T, sig);
		    s2b2sigoff := scan2data.getAllData(scan2ddid, feed2, F, sig);
		    s1b1refon  := scan1data.getAllData(scan1ddid, feed1, T, !sig);
		    s1b1refoff := scan1data.getAllData(scan1ddid, feed1, F, !sig);
		    s1b2refon  := scan1data.getAllData(scan1ddid, feed2, T, !sig);
		    s1b2refoff := scan1data.getAllData(scan1ddid, feed2, F, !sig);
		    s2b1refon  := scan2data.getAllData(scan2ddid, feed1, T, !sig);
		    s2b1refoff := scan2data.getAllData(scan2ddid, feed1, F, !sig);
		    s2b2refon  := scan2data.getAllData(scan2ddid, feed2, T, !sig);
		    s2b2refoff := scan2data.getAllData(scan2ddid, feed2, F, !sig);

		    thisRes := private.processNodBS(s1b1sigon, s1b1sigoff, s1b1refon, s1b1refoff,
						    s1b2sigon, s1b2sigoff, s1b2refon, s1b2refoff,
						    s2b1sigon, s2b1sigoff, s2b1refon, s2b1refoff,
						    s2b2sigon, s2b2sigoff, s2b2refon, s2b2refoff,
						    s1tcal, s2tcal, inner80pctMask, F);
		    if (is_boolean(thisRes)) return F;

		    if (is_boolean(thisRes.arr)) {
			private.error('Missing/unexpected data.  Can not calibrate using standard methods.');
			return F;
		    }

		    # flags should be an or of the individual state/beam/scan flags
		    # watch for missing data, work out number of integrations
		    # find maximum length
		    nint := max(len(s1b1sigon),len(s1b1sigoff),len(s1b2sigon),len(s1b2sigoff),len(s2b1sigon),len(s2b1sigoff));
		    nint /:= nchan * thisInfo1.npol;
		    if (nint <= 0) {
			private.error("Unexpected/missing data.  Can not calibrate using standard methods.");
			return F;
		    }
		    allFlags := array(F,thisInfo1.npol, nchan, nint);
		    if (len(s1b1sigon)) allFlags := allFlags | s1b1sigon::flag;
		    if (len(s1b1sigoff)) allFlags := allFlags | s1b1sigoff::flag;
		    if (len(s1b2sigon)) allFlags := allFlags | s1b2sigon::flag;
		    if (len(s1b2sigoff)) allFlags := allFlags | s1b2sigoff::flag;
		    if (len(s2b1sigon)) allFlags := allFlags | s2b1sigon::flag;
		    if (len(s2b1sigoff)) allFlags := allFlags | s2b1sigoff::flag;
		    if (len(s2b2sigon)) allFlags := allFlags | s2b2sigon::flag;
		    if (len(s2b2sigoff)) allFlags := allFlags | s2b2sigoff::flag;
		    if (len(s1b1refon)) allFlags := allFlags | s1b1refon::flag;
		    if (len(s1b1refoff)) allFlags := allFlags | s1b1refoff::flag;
		    if (len(s1b2refon)) allFlags := allFlags | s1b2refon::flag;
		    if (len(s1b2refoff)) allFlags := allFlags | s1b2refoff::flag;
		    if (len(s2b1refon)) allFlags := allFlags | s2b1refon::flag;
		    if (len(s2b1refoff)) allFlags := allFlags | s2b1refoff::flag;
		    if (len(s2b2refon)) allFlags := allFlags | s2b2refon::flag;
		    if (len(s2b2refoff)) allFlags := allFlags | s2b2refoff::flag;
		}

		if (baseline) private.baseline(thisRes.arr, allFlags, range, order);
		if (isTP) {
		    private.scaleByUnits(thisRes.arr, units, calceffs, thisInfo1, 
					 scan1data.getelev(scan1ddid, feed1, T));
		    texp := scan1data.gettexp(scan1ddid, feed1, T);
		    scan1Times := scan1data.gettime(scan1ddid, feed1, T);
		    scan2Times := scan2data.gettime(scan2ddid, feed1, T);
		} else {
		    private.scaleByUnits(thisRes.arr, units, calceffs, thisInfo1, 
					 scan1data.getelev(scan1ddid, feed1, T, T));
		    texp := scan1data.gettexp(scan1ddid, feed1, T, T);
		    if (len(texp) == 0) {
			# must be Ka data, try the other feed
			texp := scan1data.gettexp(scan1ddid, feed2, T, T);
			if (len(texp) == 0) {
			    private.error('Unexpected/missing data.  Can not calibrate using standard routines.');
			    return F;
			}
		    }
		    scan1Times := scan1data.gettime(scan1ddid, feed1, T, T);
		    if (len(scan1Times) == 0) {
			# must be Ka data, try the other feed
			scan1Times := scan1data.gettime(scan1ddid, feed2, T, T);
			if (len(scan1Times) == 0) {
			    private.error('Unexpected/missing data.  Can not calibrate using standard routines.');
			    return F;
			}
		    }
		    scan2Times := scan2data.gettime(scan2ddid, feed1, T, T);
		    if (len(scan2Times) == 0) {
			# must be Ka data, try the other feed
			scan2Times := scan2data.gettime(scan2ddid, feed2, T, T);
			if (len(scan2Times) == 0) {
			    private.error('Unexpected/missing data.  Can not calibrate using standard routines.');
			    return F;
			}
		    }
		}
		
		# sigma = tsys / sqrt(texp*deltaf)
		# assume feed1 deltaf == feed2 deltaf
		# assume exposure times are the same for all integrations here
		sigma := thisRes.tsys / sqrt(texp[1]*thisInfo1.deltaf);
		if (isTP) {
		    for (cal in T:F) {
			for (feed in feed1:feed2) {
			    scan1data.putAllData(thisRes.arr, allFlags, sigma, scan1ddid, feed, cal);
			    scan2data.putAllData(thisRes.arr, allFlags, sigma, scan2ddid, feed, cal);
			}
		    }
		} else {
		    for (cal in T:F) {
			for (sig in T:F) {
			    for (feed in feed1:feed2) {
				scan1data.putAllData(thisRes.arr, allFlags, sigma, scan1ddid, feed, cal, sig);
				scan2data.putAllData(thisRes.arr, allFlags, sigma, scan2ddid, feed, cal, sig);
			    }
			}
		    }
		}

		if (len(thisRes.tsys::shape)==1) thisRes.tsys::shape := [thisRes.tsys::shape,1];
		for (row in 1:len(scan1Times)) {
		    thisInfo1.tsys[,thisInfo1.times==scan1Times[row]] := thisRes.tsys[,row];
		    thisInfo1.tsys[,thisInfo1.times==scan2Times[row]] := thisRes.tsys[,row];
		    thisInfo2.tsys[,thisInfo2.times==scan1Times[row]] := thisRes.tsys[,row];
		    thisInfo2.tsys[,thisInfo2.times==scan2Times[row]] := thisRes.tsys[,row];
		}
	    }
	    if (!scan1data.more()) break;
	    scan1data.next();
	    scan2data.next();
	}
	scan1data.done();
	scan2data.done();
	return T;
    }

    private.calPswitch := function(scan1Sum, scan2Sum, baseline, range, order, units, calceffs, flipsr)
    {
	wider private;
	# PSWITCH requires 4.5 copies
	# need to know which is on and which is off
	if (scan1Sum.swstate ~ m/.*OFF/ ) {
	    onSum := scan2Sum;
	    offSum := scan1Sum;
	} else {
	    if (scan2Sum.swstate ~ m/.*OFF/ ) {
		onSum := scan1Sum;
		offSum := scan2Sum;
	    } else {
		# something is really wrong
		private.error('PSWITCH data appears to have no OFF scan.');
		private.msg('Will attempt to calibrate these scans as individual TPWCAL scans', priority='WARN');
		result := private.calScan(scanSum1, baseline, range, order, units, calceffs);
		result := private.calScan(scanSum2, baseline, range, order, units, calceffs) && result;
		return result;
	    }
	}
	if (flipsr) {
	    tmp := onSum;
	    onSum := offSum;
	    offSum := tmp;
	}
	ondata := gbtdata(private.ms, onSum.scan, 4.5, private.memSize);
	offdata := gbtdata(private.ms, offSum.scan, 4.5, private.memSize);

	# final sanity check - everything must be symmetric.
	if (ondata.nrows() != offdata.nrows()) {
	    # there is a problem
	    private.error('The number of integrations in the on scan is not the same as in the off scan');
	    ondata.done();
	    offdata.done();
	    return F;
	}
	if (ondata.ncal() != 1/2*ondata.nrows() ||
	    offdata.ncal() != 1/2*offdata.nrows()) {
	    # there is a problem
	    if (ondata.ncal() == 0 || ondata.ncal() == ondata.nrows() ||
		offdata.ncal() == 0 || offdata.ncal() == offdata.nrows()) {
		private.error('There is no CAL switching seen in at least one of these scans.');
	    } else {
		private.error('The number of CAL on samples does not equal the number of CAL off samples.');
	    }
	    ondata.done();
	    offdata.done();
	    return F;
	}
	# any sig switching within the scans are ignored
	if (ondata.nsig() != ondata.nrows() ||
	    offdata.nsig() != offdata.nrows() ||
	    ondata.nsig() == 0 || offdata.nsig() == 0) {
	    private.msg('SIGREF switching within each scan is ignored',priority='WARN');
	}

	while (T) {
	    # break out of this below when ondata.more() returns F
	    for (ifeed in ind(onSum.ufeed)) {
		onfeed := onSum.ufeed[ifeed];
		offfeed := offSum.ufeed[ifeed];
		sonfeed := as_string(onfeed);
		sofffeed := as_string(offfeed);

		for (idd in ind(onSum.uddid)) {
		    ondd := onSum.uddid[idd];
		    offdd := offSum.uddid[idd];
		    sondd := as_string(ondd);
		    soffdd := as_string(offdd);
		    
		    thisInfoOn := ref private.syscalInfo[sonfeed][sondd];
		    thisInfoOff := ref private.syscalInfo[sofffeed][soffdd];

		    # assume the same tcal is valid for both scans
		    if (has_field(thisInfoOn,'tcal_spec')) {
			tcal := thisInfoOn.tcal_spec;
		    } else {
			tcal := array(0.0, thisInfoOn.npol, nchan);
			tcalScalar := thisInfoOn.tcal;
			for (pol in 1:thisInfoOn.npol) {
			    tcal[pol,] := tcalScalar[pol];
			}
		    }

		    sigon := ondata.getAllData(ondd, onfeed, T);
		    sigoff := ondata.getAllData(ondd, onfeed, F);
		    refon := offdata.getAllData(offdd, offfeed, T);
		    refoff := offdata.getAllData(offdd, offfeed, F);

		    if ((len(sigon) == 0) && (len(sigoff) == 0) && (len(refon) == 0) && (len(refoff) == 0)) {
			# must be Ka data, skip this, it comes in on the other feed
			continue;
		    }

		    thisRes := private.processSigRef(sigon, sigoff, refon, refoff, tcal);

		    # flags are the or'ed flags from each state
		    flags := sigon::flag | sigoff::flag | refon::flag | refoff::flag;

		    if (baseline) private.baseline(thisRes.arr, flags, range, order);
		    private.scaleByUnits(thisRes.arr, units, calceffs, thisInfoOn, ondata.getelev(ondd, onfeed, T));

		    sigma := thisRes.tsysRef / sqrt(ondata.gettexp(ondd, onfeed, T)[1]*thisInfoOn.deltaf);
		    
		    for (cal in T:F) {
			ondata.putAllData(thisRes.arr, flags, sigma, ondd, onfeed, cal);
			offdata.putAllData(thisRes.arr, flags, sigma, offdd, offfeed, cal);
		    }

		    sigtimes := ondata.gettime(ondd, onfeed, T);
		    reftimes := offdata.gettime(offdd, offfeed, T);
		    if (len(thisRes.tsysRef::shape)==1) thisRes.tsysRef::shape := [thisRes.tsysRef::shape,1];
		    for (row in 1:len(sigtimes)) {
			onTimesMask := thisInfoOn.times==sigtimes[row];
			if (any(onTimesMask)) {
			    thisInfoOn.tsys[,onTimesMask] := thisRes.tsysRef[,row];
			}
			offTimesMask := thisInfoOff.times==sigtimes[row];
			if (any(offTimesMask)) {
			    thisInfoOff.tsys[,offTimesMask] := thisRes.tsysRef[,row];
			}
		    }
		    for (row in 1:len(reftimes)) {
			onTimesMask := thisInfoOn.times==reftimes[row];
			if (any(onTimesMask)) {
			    thisInfoOn.tsys[,onTimesMask] := thisRes.tsysRef[,row];
			}
			offTimesMask := thisInfoOff.times==reftimes[row];
			if (any(offTimesMask)) {
			    thisInfoOff.tsys[,offTimesMask] := thisRes.tsysRef[,row];
			}
		    }
		}
	    }
	    if (!ondata.more()) break;
	    ondata.next();
	    offdata.next();
	}
	ondata.done();
	offdata.done();

	return T;
    }

    private.calFswitch := function(scanSum, baseline, range, order, units, calceffs, fold, flipfold, flipsr)
    {
	wider private;
	# FSWITCH requires about 4.5 copies
	scandata := gbtdata(private.ms, scanSum.scan, 4.5, private.memSize);

	# sanity check - everything must be symmetric.
	if (scandata.ncal() != 1/2*scandata.nrows()) {
	    # there is a problem
	    if (scandata.ncal() == 0 || scandata.ncal() == scandata.nrows()) {
		private.error('There is no CAL switching seen in this scan.');
	    } else {
		private.error('The number of CAL on samples does not equal the number of CAL off samples.');
	    }
	    scandata.done();
	    return F;
	}
	if (scandata.nsig() != 1/2*scandata.nrows()) {
	    badSigRefFS := F;
	    if (scandata.nsig() == 0 || scandata.nsig() == scandata.nrows()) {
		private.error('There is no SIGREF switching seen in this scan.');
		# is this probably old data with no SIGREF switching?
		badSigRefFS := scandata.nsig() == scandata.nrows() && scandata.nddid()%2 == 0;
		if (badSigRefFS) {
		    private.error('Will try and guess at what SIGREF should have been');
		}		    
	    } else {
		private.error('The number of SIGREF on samples does not equal the number of SIGREF off samples.');
	    }
	    if (!badSigRefFS) {
		scandata.done();
		private.msg('Will attempt to calibrate this scan as a TPWCAL scan.', priority='WARN');
		return private.calScan(scanSum, baseline, range, order, units, calceffs);
	    }
	}

	sig := T;
	if (flipsr) sig := F;
	while (T) {
	    # break out of this below, when scandata.more() returns F
	    for (thisFeed in scanSum.ufeed) {
		sfeed := as_string(thisFeed);
		uSigddid := scandata.usigDdid(thisFeed, sig);
		uRefddid := scandata.usigDdid(thisFeed, !sig);
		sigSigIs := sig;
		refSigIs := !sig;
		if (badSigRefFS) {
		    # assume odd uSigddids are SIG and evens are REF
		    # unless flipped
		    if (flipsr) {
			allDdis := uRefddid;
			indx := ind(allDdis);
			uSigddid := allDdis[indx%2==1];
			uRefddid := allDdis[indx%2==0];
			sigSigIs := T;
		    } else {
			allDdis := uSigddid;
			indx := ind(allDdis);
			uSigddid := allDdis[indx%2==1];
			uRefddid := allDdis[indx%2==0];
			refSigIs := T;
		    }
		}

		for (idd in ind(uSigddid)) {
		    thisSigdd := uSigddid[idd];
		    thisRefdd := uRefddid[idd];
		    sddidsSig := as_string(thisSigdd);
		    sddidsRef := as_string(thisRefdd);
		    
		    thisInfoSig := ref private.syscalInfo[sfeed][sddidsSig];
		    thisInfoRef := ref private.syscalInfo[sfeed][sddidsRef];
		    
		    # assume the same tcal is valid for both sig and ref
		    if (has_field(thisInfoSig,'tcal_spec')) {
			tcal := thisInfoSig.tcal_spec;
		    } else {
			tcal := array(0.0, thisInfoSig.npol, nchan);
			tcalScalar := thisInfoSig.tcal;
			for (pol in 1:thisInfoSig.npol) {
			    tcal[pol,] := tcalScalar[pol];
			}
		    }

		    sigon := scandata.getAllData(thisSigdd, thisFeed, T, sigSigIs);
		    sigoff := scandata.getAllData(thisSigdd, thisFeed, F, sigSigIs);
		    refon := scandata.getAllData(thisRefdd, thisFeed, T, refSigIs);
		    refoff := scandata.getAllData(thisRefdd, thisFeed, F, refSigIs);

		    thisSigRes := private.processSigRef(sigon, sigoff, refon, refoff, tcal);
		    thisRefRes := private.processSigRef(refon, refoff, sigon, sigoff, tcal, thisSigRes.tsysSig);

		    sigFlags := sigon::flag | sigoff::flag;
		    refFlags := refon::flag | refoff::flag;

		    if (fold) {
			if (!flipfold) {
			    ok := private.fold(thisSigRes, thisRefRes, sigFlags, refFlags,
					       thisInfoSig.centerFreq, thisInfoRef.centerFreq,
					       thisInfoSig.chanSpacing);
			    refFlags := sigFlags;
			    thisRefRes := thisSigRes;
			} else {
			    thisRefRes.tsysSig := thisSigRes.tsysSig;
			    thisRefRes.tsysRef := thisSigRes.tsysRef;
			    ok := private.fold(thisRefRes, thisSigRes, refFlags, sigFlags, 
					       thisInfoSig.centerFreq, thisInfoRef.centerFreq,
					       thisInfoSig.chanSpacing);
			    sigFlags := refFlags;
			    thisSigRes := thisRefRes;
			}
		    }
		    
		    # necessary to do this here so that the return state of fold can be
		    # used, if it wasn't okay, proceed as if fold was false
		    if (fold && ok) {
			if (baseline) {
			    private.baseline(thisSigRes.arr, sigFlags, range, order);
			}
			private.scaleByUnits(thisSigRes.arr, units, calceffs, thisInfoSig,
					     scandata.getelev(thisSigdd, thisFeed, T, sig));
			# because the data have been folded, make sure ref and sig results are the same
			thisRefRes := thisSigRes;
		    } else {
			if (baseline) {
			    private.baseline(thisSigRes.arr, sigFlags, range, order);
			    private.baseline(thisRefRes.arr, refFlags, range, order);
			}
			elev := scandata.getelev(thisSigdd, thisFeed, T, sig);
			private.scaleByUnits(thisSigRes.arr, units, calceffs, thisInfoSig,  elev);
			# re-use whatever was previously set, either intentially by the
			# user, in which calceffs was already F or by the previous 
			# scaleByUnits, which will not have changed
			private.scaleByUnits(thisRefRes.arr, units, F, thisInfoSig, elev);
		    }

		    texp := scandata.gettexp(thisSigdd, thisFeed, T, sigSigIs);
		    sigmaSig := thisSigRes.tsysSig / sqrt(texp[1]*thisInfoSig.deltaf);
		    sigmaRef := thisSigRes.tsysRef / sqrt(texp[1]*thisInfoSig.deltaf);

		    for (cal in T:F) {
			scandata.putAllData(thisSigRes.arr, sigFlags, sigmaSig, thisSigdd, thisFeed, cal, sigSigIs);
			scandata.putAllData(thisRefRes.arr, refFlags, sigmaRef, thisRefdd, thisFeed, cal, refSigIs);
		    }

		    sigtimes := scandata.gettime(thisSigdd, thisFeed, T, sigSigIs);
		    reftimes := scandata.gettime(thisRefdd, thisFeed, T, refSigIs);
		    if (len(thisSigRes.tsysSig::shape)==1) thisSigRes.tsysSig::shape := [thisSigRes.tsysSig::shape,1];
		    if (len(thisSigRes.tsysRef::shape)==1) thisRefRes.tsysRef::shape := [thisSigRes.tsysRef::shape,1];
		    for (row in 1:len(sigtimes)) {
			infoSigTimesMask := thisInfoSig.times==sigtimes[row];
			if (any(infoSigTimesMask)) {
			    thisInfoSig.tsys[,infoSigTimesMask] := thisSigRes.tsysRef[,row];
			}
		    }
		    for (row in 1:len(reftimes)) {
			infoRefTimesMask := thisInfoRef.times==reftimes[row];
			if (any(infoRefTimesMask)) {
			    thisInfoRef.tsys[,infoRefTimesMask] := thisSigRes.tsysSig[,row];
			}
		    }
		}
	    }
	    if (!scandata.more()) break;
	    scandata.next();
	}
	scandata.done();

	return T;
    }


    private.calScan := function(scanSum, baseline, range, order, units, cacleffs, ddid=unset)
    {
	wider private;
	# TP data requires 5 copies
	scanDDID := unset
	if (!is_unset(ddid)) {
           scanDDID := scanSum.uddid[ddid];
        }
	scandata := gbtdata(private.ms, scanSum.scan, 5, private.memSize, ddid=scanDDID);

	# sanity checks - cal must be symmetric, sig is ignored.
	if (scandata.ncal() != 1/2*scandata.nrows()) {
	    # there is a problem
	    if (scandata.ncal() == 0 || scandata.ncal() == scandata.nrows()) {
		private.error('There is no CAL switching seen in this scan.');
	    } else {
		private.error('The number of CAL on samples does not equal the number of CAL off samples.');
	    }
	    scandata.done();
	    return F;
	}
	if (scandata.nsig() != 0 && scandata.nsig() != scandata.nrows()) {
	    private.msg('The SIGREF switching in this scan is ignored in TP calibration.',
			priority='WARN');
	}

	# two passes, first pass to get the mean of the on-off : mean acl power in all spec and channels
	# one for each feed, ddid
	meanCalPowers := [=];

	allIDDs := scanSum.uddid;
	if (!is_unset(ddid)) allIDDs := scanSum.uddid[ddid];

	while (T) {
	    # break out of this below, when scandata.more() returns F
	    for (thisFeed in scanSum.ufeed) {
		sfeed := as_string(thisFeed);
		if (!has_field(meanCalPowers, sfeed)) meanCalPowers[sfeed] := [=];

		for (thisDdid in allIDDs) {
		    sddid := as_string(thisDdid);		    
		    thisInfo := ref private.syscalInfo[sfeed][sddid];

		    if (!has_field(meanCalPowers[sfeed], sddid)) {
			thisMeanCalPower := [=];
			thisMeanCalPower.arr := array(0.0, thisInfo.npol);
			thisMeanCalPower.count := 0;
		    } else {
			thisMeanCalPower := meanCalPowers[sfeed][sddid];
		    }

		    on := scandata.getAllData(thisDdid, thisFeed, T);
		    off := scandata.getAllData(thisDdid, thisFeed, F);

		    diff := on - off;
		    flags := on::flag | off::flag;

		    for (ipol in 1:on::shape[1]) {
			thisMeanCalPower.arr[ipol] +:= sum((diff[ipol,,])[!flags[ipol,,]])
			}
		    thisMeanCalPower.count +:= on::shape[2]*on::shape[3] - sum(flags);
		    meanCalPowers[sfeed][sddid] := thisMeanCalPower;
		}
	    }
	    if (!scandata.more()) break;
	    scandata.next();
	}
	# reset back to the origin
	scandata.origin();

	# second pass, actually do the calibration, baseline, scaling, etc
	while (T) {
	    # break out of this below, when scandata.more() returns F
	    for (thisFeed in scanSum.ufeed) {
		sfeed := as_string(thisFeed);
		for (thisDdid in allIDDs) {
		    sddid := as_string(thisDdid);
		    
		    thisInfo := ref private.syscalInfo[sfeed][sddid];
		    thisMeanCalPower := meanCalPowers[sfeed][sddid];

		    if (has_field(thisInfo,'tcal_spec')) {
			tcal := thisInfo.tcal_spec;
		    } else {
			tcal := array(0.0, thisInfo.npol, nchan);
			tcalScalar := thisInfo.tcal;
			for (pol in 1:thisInfo.npol) {
			    tcal[pol,] := tcalScalar[pol];
			}
		    }

		    on := scandata.getAllData(thisDdid, thisFeed, T);
		    off := scandata.getAllData(thisDdid, thisFeed, F);

		    if ((len(on) == 0) && (len(off) == 0)) {
			# must be Ka data, this will come in in the other feed, then
			continue;
		    }

		    meanCalPower := thisMeanCalPower.arr/thisMeanCalPower.count;

		    thisRes := private.processTP(on, off, tcal, meanCalPower);

		    flags := on::flag | off::flag;

		    if (baseline) private.baseline(thisRes.arr, flags, range, order);
		    private.scaleByUnits(thisRes.arr, units, calceffs, thisInfo1, 
					 scandata.getelev(thisDdid, thisFeed, T));

		    sigma := thisRes.tsys / sqrt(scandata.gettexp(thisDdid, thisFeed, T)[1]*thisInfo.deltaf);

		    scandata.putAllData(thisRes.arr, flags, sigma, thisDdid, thisFeed, T);
		    scandata.putAllData(thisRes.arr, flags, sigma, thisDdid, thisFeed, F);

		    times := scandata.gettime(thisDdid, thisFeed, T);
		    if (len(thisRes.tsys::shape)==1) thisRes.tsys::shape := [thisRes.tsys::shape,1];
		    for (row in 1:len(times)) {
			infoTimesMask := thisInfo.times==times[row];
			if (any(infoTimesMask)) {
			    thisInfo.tsys[,infoTimesMask] := thisRes.tsys[,row];
			}
		    }
		}
	    }
	    if (!scandata.more()) break;
	    scandata.next();
	}

	scandata.done();

	return T;
    }

    public.cal := function(baseline=F, range=unset, order=1, units=0, flipsr=F,
			   fold=F, flipfold=F, calceffs=T, type=unset)
    {
	wider private;
	if (is_boolean(private.scans)) {
	    private.error('Nothing to calibrate - use setscans first');
	    return F;
	}
	skipNext := F;
	for (whichScan in ind(private.uscan)) {
	    if (skipNext) {
		skipNext := F;
		continue;
	    }
	    thisScan := private.uscan[whichScan];
	    scanSum := private.scanSum(thisScan);
	    if (!is_unset(type)) {
		# attempt to force certain calibration
		if (type == 'Nod') {
		    if (scanSum.procname != 'Nod') {
			private.msg('Forcing Nod (beam switched) calibration, may be inappropriate here',
				    priority='WARN');
			scanSum.procname := 'Nod';
		    }
		    scanSum.procseqn := 1;
		    scanSum.procsize := 2;
		} else if (type == 'FS') {
		    scanSum.procname := 'forced';
		    if (scanSum.swstate != 'FSWITCH') {
			private.msg('Forcing FS (frequency switched) calibration, may be inappropriate here',
				    priority='WARN');
			scanSum.swstate := 'FSWITCH';
		    }
		} else {
		    # anything else just try TP calibration
		    scanSum.procname := 'forced';
		    scanSum.swstate := 'TPWCAL';
		}
	    }		    
	    
	    scanSum2 := F;
	    if (scanSum.procname == 'Nod' ||
		scanSum.procname == 'OnOff' ||
		scanSum.procname == 'OffOn') {
		if (scanSum.procseqn != 1 || scanSum.procsize != 2) {
		    # can't be right, don't do it
		    scanSum.procname := '';
		    private.msg(paste('All scans in the sequence starting at scan=',thisScan,
				      'are not present - will calibrate each scan separately'),
				priority='WARN');
		} else {
		    whichScan +:= 1;
		    skipNext := T;
		    if (whichScan > len(private.uscan)) {
			# it doesn't exist
			scanSum.procname := '';
			private.msg(paste('All scans in the sequence starting at scan=',thisScan,
					  'are not present - will calibrate each scan separately'),
				    priority='WARN');
		    } else {
			scanSum2 := private.scanSum(private.uscan[whichScan]);
			if (!is_unset(type) && type == 'Nod') {
			    # forcing things to work out here
			    scanSum2.procname := 'Nod';
			    scanSum2.procsize := 2;
			    scanSum2.procseqn := 2;
			}
			if (scanSum2.procname != scanSum.procname ||
			    scanSum2.procsize != 2 || scanSum2.procseqn != 2) {
			    # false pair, must have been aborted
			    whichScan -:= 1;
			    skipNext := F;
			    scanSum.procname := '';
			    private.msg(paste('All scans in the sequence starting at scan=',thisScan,
					      'are not present - will calibrate each scan separately'),
					priority='WARN');
			}
		    }
		}
	    }
	    if (scanSum.procname == 'Nod' && 
		(scanSum.swtchsig == 'TPWCAL' || scanSum.swtchsig == 'BEAMSW') &&
		len(scanSum.ufeed == 2) &&
		scanSum2.swtchsig == scanSum.swtchsig &&
		len(scanSum.ufeed == 2)) {
		ok := private.calNod(scanSum, scanSum2, baseline, range, order, units, calceffs, flipsr);
	    } else if (scanSum.procname == 'OffOn' || 
		       scanSum.procname == 'OnOff') {
		ok := private.calPswitch(scanSum, scanSum2, baseline, range, order, units, calceffs, flipsr);
	    } else if (scanSum.swstate == 'FSWITCH') {
		ok := private.calFswitch(scanSum, baseline, range, order, units, calceffs, fold, flipfold,
					 flipsr);
	    } else {
		# the SIG state is always ignored here, so flipsr has no impact here.
		ok := private.calScan(scanSum, baseline, range, order, units, cacleffs);
	    }
	    if (ok) {
		ok:= private.scansms.putcolkeyword('CORRECTED_DATA','QuantumUnits',d.uniget('units'));
	    }
	    if (is_boolean(scanSum2)) {
		theseScans := scanSum.scan;
	    } else {
		theseScans := [scanSum.scan, scanSum2.scan];
	    }
	    if (ok) {
		private.msg(spaste('Scan ',theseScans,' calibrated.'));
	    } else {
		private.error(spaste('There was a problem calibrating scan ', theseScans));
	    }
	}
	private.putTsys();
	return T;
    }

    public.resync := function()
    {
	wider private, public;
	if (is_table(private.ms)) private.ms.resync();
	if (is_table(private.scansms)) {
	    scans := private.scans;
	    # force a re-selection
	    private.scans := F;
	    public.setscans(scans);
	}
	return T;
    }

    public.closeMS := function()
    {
	wider private;
	private.scans := F;
	if (is_table(private.rowsel)) private.rowsel.done();
	if (is_table(private.scansms)) private.scansms.done();
	if (is_table(private.subSyscalTab)) private.subSyscalTab.done();
	if (is_table(private.ms)) private.ms.done();
	return T;
    }

    public.done := function() 
    {
	wider private, public;

	public.closeMS();
	
	val private := F;
	val public := F;
	return T;
    }

    return ref public;
}


# all-on-one shortcut to do scans in a given ms and then exit
# this seems to be necessary with the current dish as the table
# interaction seems to end up closing the table here, somewhow
# it doesn't seem to be a real penalty as far as processing time
gbtcalscans := function(msname, scans, baseline=F, range=unset, order=1, units=0, flipsr=F,
			fold=F, flipfold=F, calceffs=T, type=unset) {
    gc := gbtcalibrator();
    result := gc.setms(msname);
    result := result && gc.setscans(scans);
    result := result && gc.cal(baseline, range, order, units, flipsr,
			       fold, flipfold, calceffs, type);
    gc.done();
    return result;
}
