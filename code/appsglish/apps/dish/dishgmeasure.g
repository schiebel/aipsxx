# dishgmeasure.g: implementation of NAIC galaxy profile measure functionality
# Copyright (C) 2001,2002,2003
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
# $Id: dishgmeasure.g,v 19.5 2004/08/25 01:10:14 cvsmgr Exp $

# include guard
pragma include once

include 'fitting.g';
include 'statistics.g';
include 'note.g';

const dishgmeasure := function(itsdish)
{
    public:=[=];
    private:=[=];

    private.dish:=itsdish;
    private.fitter := F;

    # first, some private utility functions

    # given two channels, do a simple linear interpolation to
    # find the v value corresponding to x == f.  It is assumed
    # that x and v are real arrays and that i1 and i2 are
    # integers that point to valid elements in each - the
    # linear interpolation is done between these two channels.
    private.frac := function(x, v, i1, i2, f) {
	return (f-x[i1])/(x[i2]-x[i1])*(v[i2]-v[i1]) + v[i1];
    }

    # given x and v vectors, left and right channel numbers and
    # corresponding levels, interpolate v to get velocities
    # where x == each level.  Assumes that
    # x[chanLeft-1] <= levelLeft <= x[chanLeft]
    # x[chanRight] >= levelRight >= x[chanRight+1]
    private.interpVel := function(x, v, chanLeft, chanRight,
				  levelLeft, levelRight,
				  ref vleft, ref vright)
    {
	if (chanLeft == 1) {
	    # at left edge, don't interpolate
	    val vleft := v[1];
	} else {
	    val vleft := private.frac(x, v, chanLeft-1, chanLeft, levelLeft);
	}
	if (chanRight == len(x)) {
	    # at right edge, don't interpolate
	    val vright := v[chanRight];
	} else {
	    val vright := private.frac(x, v, chanRight, chanRight+1, levelRight);
	}
    }

    # Using a single level, flevel, find the location in x where the 
    # value of x rises above that level searching from each end point
    # (first and last).  Sets chanLeft and chanRight to the
    # integer channel number of each found endpoint.  Sets vleft and
    # vright to the linearly interpolated value of v assocated with the value
    # of flevel in x (i.e. this is the approximage value of v where
    # x == flevel at each end point).
    private.singleLevel := function(x, v, flevel, first, last,
				    ref chanLeft, ref chanRight,
				    ref vleft, vright)
    {
	wider private;
	# ensure that first < last - only changes local values
	if (first > last) {
	    tmp := first;
	    first := last;
	    last := tmp;
	}
	jl := first;
	while (jl < last && x[jl]<flevel) jl +:= 1;
	jr := last;
	while (jr > first && x[jr]<flevel) jr -:= 1;
	val chanLeft := jl;
	val chanRight := jr;
	private.interpVel(x, v, chanLeft, chanRight, flevel, flevel,
			  ref vleft, ref vright);
    }


    # ADAPTED from IDL routines provided by NAIC

    # this is used by the two two-horned fitting methods 

    # this subroutine is a first step at automating the velocity
    # measurement for double horned profiles. The subroutine
    # will return the fluxes and channel numbers of the two 
    # horns. First the entire profile btween the user flagged
    # limits first and last (first < last) is searched
    # for peaks, a peak being defined as a channel which has
    # more flux than niso channels on either side of it. niso
    # is scaled linearly with the width of the profile (i.e.
    # first - last) and is 5 when (first = last = 40);
    # If the profile has only one peak, then it is treated
    # as a double horned profile in  which the peaks are 
    # coincident. If there are more than two peaks then
    # the outer two peaks are regarded as the horns of the 
    # profile UNLESS one of the inner peaks is more than
    # a factor of fact times larger than an exterior peak.
    # In that case the closest exterior peak is replaced
    # by the larger interior peak. In case there is more than
    # one interior peak that is a factor of fact larger than
    # the exterior peak, the outer most larger peak is
    # used.
    private.pksearch := function(x,first,last,
				 ref ipl,ref ipr, ref fpl,ref fpr) 
    {
 
	#                  INPUT VARIABLES
	# x        array containg the profile
	# first   user defined left end of the profile
	# last    user defined right end of the profile

 
	#                 OUTPUT VARIABLES
	# ipl      channel number of left peak
	# ipr      channel number of right peak
	# fpl      Flux of the left peak
	# fpr      Flux of the right peak

	#                INTERNAL VARIABLES
	# npeak    number of peaks in the profile
	# pkchan   array containing channel numbers of the peaks
	# niso     a peak is defined as a channel with more
	#          flux than  niso channels on either side
	# icntr    the midpoint of the profile
	# pcntr    the channel number of the central peak
	# i,j      dummy integers for  looping control
	# fact     an internal peak has to be greater than
	#          fact times an exterior peak to be considered
	#          the profile horn

	# fact is set here, the user has no control over it
	fact := 2.0;

	val ipl := first;
	val fpl := x[ipl];
	val ipr := last;
	val fpr := x[ipr];

	# CHNNELS ON EITHER SIDE TO BE CONSIDERED A
	# PEAK
	niso := as_integer(5.0*(ipr - ipl)/40.0);
	if (niso<3) niso := 3;
	else if (niso>7) niso := 7;

	# and now limit niso so that, when combined with 
	# first and last things are always okay - these
	# will be rare occurances
	niso := min(niso, (len(x)-first));
	niso := min(niso, (last-1));

	# FIND ALL PEAKS BETWEEN THE FLAGED LIMITS
	# initial empty array to hold the peaks
	# I don't believe this is vectorizable - so this
	# will be slow.

	pkchan := as_integer([]);
	ok := T;
	for (i in first:(first+niso)) {
	    ok := T;
	    for (j in 0:(niso-1)) { 
		if (x[i] < x[i+j]) {
		    ok := F;
		    break;
		}
	    }
	    if (ok) {
		for (j in 0:(i-first)) {
		    if (x[i] < x[i-j+1]) {
			ok := F;
			break;
		    }
		}
		if (ok) {
		    pkchan[len(pkchan)+1]:=i;
		}
	    }
	}
	
	if ((first+niso) <= (last-niso)) {
	    for (i in (first+niso):(last-niso)) {
		ok := T;
		for (j in 0:(niso-1)) {
		    if ((x[i] < x[i+j]) || (x[i] < x[i-j])) {
			ok := F;
			break;
		    }
		}
		if (ok) {
		    pkchan[len(pkchan)+1] := i;
		}
	    }
	}
	
	for (i in (last-niso):last) {
	    ok := T;
	    for (j in 0:(niso-1)) {
		if (x[i] < x[i-j]) {
		    ok := F;
		    break;
		}
	    }
	    if (ok) {
		for (j in 0:(last-i)) {
		    if (x[i] < x[i+j-1]) {
			ok := F;
			break;
		    }
		}
		if (ok) {
		    pkchan[len(pkchan)+1]:=i;
		}
	    }
	}
	
	npeak := len(pkchan); 
	
	# IF THERE IS ONLY ONE PEAK, THE LEFT AND RIGHT
	# SIDES ARE COINCIDENT
	# there must be at least one peak
	if (npeak == 1) {
	    val ipl := pkchan[1];
	    val fpl := x[ipl];
	    val ipr := ipl;
	    val fpr := fpl;
	} else if (npeak == 2) {
	    # IF THERE ARE ONLY TWO PEAKS, THEN LEFT AND
	    # RIGHT ARE 1 AND 2
	    val ipl := pkchan[1];
	    val ipr := pkchan[2];
	    val fpl := x[ipl];
	    val fpr := x[ipr];
	} else {
	    # IF THERE ARE MORE THAN TWO PEAKS TREAT THE 
	    # OUTERMOST TWO PEAKS AS THE PROFILE,
	    # UNLESS ONE OF THE INTERIOR PEAKS IS MORE 
	    # THAN fact TIMES LARGER THAN THE EXTERIOR
	    # PEAKS (SEE EXPLANATION AT START)
	    val ipl := pkchan[1];
	    val fpl := x[ipl];
	    val ipr := pkchan[npeak];
	    val fpr := x[ipr];
	    icntr := (pkchan[npeak] + pkchan[1])/2;
	    pcntr :=  2;
	    # find the center - consider the peaks in two halfs
	    j := 2;
	    while (j<(npeak-1) && pkchan[j] < icntr) j+:=1;
	    # at this point, j points at the first peak after icntr

	    pcntr := j;
	    j := pcntr;
	    while (j >= 2) {
		if (x[pkchan[j]] > fact*x[pkchan[1]] && x[pkchan[j]]>fpl) {
		    val ipl := pkchan[j];
		    val fpl := x[ipl];
		}
		j := j -1;
	    }
	    j := pcntr + 1;
	    while (j <= (npeak-1)) {
		if (x[pkchan[j]] > fact*x[pkchan[npeak]] && x[pkchan[j]]>fpr) {
		    val ipr := pkchan[j];
		    val fpr := x[ipr];
		}
		j := j + 1;
	    }
	}
    }


    # flux integral (sum(x*dv)) between two channels - assumed to be ordered
    # (i.e. first < last).  Channel width of channel i is 1/2 of
    # the distance between the velocities of the two adjacent 
    # channels - dv(i) = abs(v(i+1)-v(i-1))/2.0.  If first or last
    # is at an end point, only the distance to the one adjacent 
    # channel is used for that channel.
    private.fluxInt := function(x, v, first, last) {
	rangeMask := [first:last];
	dv := array(0.0,len(rangeMask));
	vfirst := first;
	dvfirst := 1;
	vlast := last;
	dvlast := len(dv);
	if (first == 1) {
	    vfirst +:= 1;
	    dvfirst +:= 1;
	}
	if (last == len(x)) {
	    vlast -:= 1;
	    dvlast -:= 1;
	}
	# the one remaining pathological case, 2 channels
	# at this point vfirst == vlast
	if (vfirst >= vlast) {
	    dv[1:len(dv)] := abs(v[2]-v[1]);
	} else {
	    # the channels we know aren't at the end points
	    vrangeMask := [vfirst:vlast];
	    dv[dvfirst:dvlast] := abs((v[vrangeMask+1] - v[vrangeMask-1]) / 2.0);
	    # and any end points as necessary
	    if (vfirst != first) {
		# this means first is at an end
		dv[1] := abs(v[first+1]-v[first]);
	    }
	    if (vlast != last) {
		# this means last is at an end
		dv[len(dv)] := abs(v[last]-v[last-1]);
	    }
	}

	return sum(x[rangeMask]*dv);
    }

    # basic sanity checks common to all functions.  origin is astring
    # used in the output to note if there is a problem.  Return T if
    # we're sane.
    private.basicSanity := function(x, v, first, last, flevel, origin)
    {
	if (len(x) != len(v)) {
	    note("The length of x and v do not agree", priority='SEVERE',
		 origin=origin);
	    return F;
	}
	# single x, v arrays
	if (len(x) == 1) {
	    note("There is only one element in the x and v vectors", priority='SEVERE',
		 origin=origin);
	    return F;
	}
	if (first == last) {
	    note("first and last are the same element - no range specified",
		 priority='SEVERE', origin=origin);
	    return F;
	}
	# first and last are valid elements
	if (first < 0 || first > len(x)) {
	    note(spaste("The value of first is not a valid element in x and v :",first),
		 priority='SEVERE', origin=origin);
	    return F;
	}
	if (last < 0 || last > len(x)) {
	    note(spaste("The value of last is not a valid element in x and v :",last),
		 priority='SEVERE', origin=origin);
	    return F;
	}
	# if flevel > 1, keep going but warn of possibly unexpected results
	if (flevel > 1) {
	    note("flevel is > 1, do not necessarily expect a correct answer",
		 priority='WARN',origin=origin);
	}
	return T;
    }

    # The individual measurement methods ("operation modes" in unipops).
    # Each one returns a record with at least these fields - fluxint (flux
    # integral), vel (a characteristic velocity), and vwidth (a characteristic
    # velocity width), level, limits, and type (a string identifying the
    # method used).
    # Individual methods may return additional values.  A return value that
    # is not a record means a severe error has occured - the method has failed.
    # 

    # function to generate the basic return record with default values
    private.basicResult := function() {
	return [fluxint=0.0, vel=0.0, vwidth=0.0, level=0.0, limits=[0.0,0.0],
		type='none'];
    }

    # function to draw marks on the plotter with the resultant info
    public.draw := function(bigrec) {
	wider private,public;
	for (i in 1:2) {
	    myx:=public.pixtoany(bigrec.limits[i]);
	    if (has_field(bigrec,'mean')) {
	    	myy:=bigrec.mean;
	    } else if (has_field(bigrec,'peak')) {
		if (len(bigrec.peak)==1) {
			myy:=bigrec.peak;
		} else {
			myx:=public.pixtoany(bigrec.peakchan[i]);
			myy:=bigrec.peak[i];
		}
	    } else {
		myy:=0.
		myx:=public.pixtoany(bigrec.limits[i]);
	    }; 
	    private.dish.plotter.ips.point(x=myx,y=myy,ci=7);
	};
	oldci:=private.dish.plotter.qci();	
	private.dish.plotter.sci(7);
	private.dish.plotter.mtxt('R',1,0,0,spaste('Int Flux: ',bigrec.fluxint,
		' K km/s'))
	private.dish.plotter.mtxt('R',2,0,0,spaste('Velocity: ',bigrec.vel, 
		' km/s'));
	private.dish.plotter.mtxt('R',3,0,0,spaste('Delta V: ',bigrec.vwidth,
		' km/s'));
	private.dish.plotter.sci(oldci);
    };

    # function to convert displayed unit to channels
    public.anytopix := function(myval) {
	wider private,public;
        currframe:=private.dish.plotter.ips.getrefframe();
        ok:=private.dish.plotter.csys.setconversiontype(spectral=currframe);
#        xposition:=private.dish.plotter.curs().x;
	xposition:=myval;
        currunits:=private.dish.plotter.ips.getabcissaunit();
        if (currunits=='pix' || currunits=='index') {
           return as_integer(xposition);
        } else if (currunits=='km/s' || currunits=='m/s' ) {
          xquant:=dq.quantity(xposition,currunits);
          ok:=private.dish.plotter.csys.setconversiontype(spectral=currframe);
          xfreq:=private.dish.plotter.csys.vtf(dq.getvalue(xquant),
          velunit=private.dish.plotter.ips.getabcissaunit(),frequnit='Hz');
          specworld:=dq.quantity(xfreq,'Hz');
          myworld:=private.dish.plotter.csys.toworld([1,1,1]);
          myworld[3]:=dq.getvalue(specworld);
          ok:=private.dish.plotter.csys.setconversiontype(spectral=currframe);
          return as_integer(private.dish.plotter.csys.topixel(myworld)[3])
        } else {
          xquant:=dq.quantity(xposition,currunits);
          specworld:=dq.convert(xquant,'Hz');
	  myworld:=private.dish.plotter.csys.toworld([1,1,1]);
	  myworld[3]:=dq.getvalue(specworld);
          ok:=private.dish.plotter.csys.setconversiontype(spectral=currframe);
          return as_integer(private.dish.plotter.csys.topixel(myworld)[3])
        };
};

    public.pixtoany := function(myval) {
        wider private,public;
        currframe:=private.dish.plotter.ips.getrefframe();
        ok:=private.dish.plotter.csys.setconversiontype(spectral=currframe);
#        xposition:=private.dish.plotter.curs().x;
        xposition:=myval;
        currunits:=private.dish.plotter.ips.getabcissaunit();
        if (currunits=='pix' || currunits=='index') {
           return xposition;
        } else if (currunits=='km/s' || currunits=='m/s' ) {
          xquant:=dq.quantity(xposition,'pix');
          ok:=private.dish.plotter.csys.setconversiontype(spectral=currframe);
          xworld:=dq.quantity(private.dish.plotter.csys.toworld([1,1,dq.getvalue(xquant)])[3],'Hz');
          ok:=private.dish.plotter.csys.setconversiontype(spectral=currframe);
          xvel:=private.dish.plotter.csys.ftv(dq.getvalue(xworld),
          velunit=currunits,frequnit='Hz');
          return xvel;
        } else {
          xquant:=dq.quantity(xposition,'pix');
          ok:=private.dish.plotter.csys.setconversiontype(spectral=currframe);
          xworld:=dq.quantity(private.dish.plotter.csys.toworld([1,1,dq.getvalue(xquant)])[3],'Hz');
	  xworld:=dq.convert(xworld,currunits);
          return dq.getvalue(xworld);
        };
};


    # NAIC mode 1 - start and stopping point for flux integral is where the
    # flux level (x vector) first rises above flevel times the mean flux
    # over the region of interest (from first, through last, inclusive)
    # with the search starting from each endpoint.  The channels where the 
    # flux actually exceeds that level are used as the end points of the 
    # flux integral.  The characteristic velocity is the average
    # of the crossing points - which are calculated by linear interpolation
    # between the adjacent channel values (i.e. this is an estimate of the
    # velocity where x is equal to that level).  The velocity
    # width is the difference in these two velocities.  The v argument is
    # assumed to contain velocities.  The average flux (avg) is the average of
    # x over the entire region of interest.  Level is the input level (flevel).
    # limits are the channels used in the flux integral.  In addition, this
    # method adds a "mean" field to hold the mean value over the range.  The
    # value of type for this method is "mean".

    const public.mean := function(lv=F, first=F, last=F, flevel=0.1, usecurs=F)
    {
	wider private;

	if (!any([first,last,flevel])) {
		dl.note('ERROR: bad arguments; Usage: (lv,first,last,flevel)');
		return F;
	}
	if (is_boolean(lv)) {
	     lv := private.dish.rm().getlastviewed();
             nominee := ref lv.value;
             name := lv.name;
	  #   v:=private.dish.plotter.ips.getcurrentabcissa();
	     v:=private.dish.plotter.csys.frequencytovelocity(nominee.data.desc.chan_freq.value,'Hz');
        } else {
	     dl.note('ERROR: Mode not enabled ');
	     return F;
#             nominee := ref lv;
#             nname:='temp';
#	     v:=
        };

        x:=nominee.data.arr;
# loop to see if we need to determine the channels
	if (usecurs) {
	   private.dish.plotter.message('Use mouse to mark left of profile');
			xcurr:=private.dish.plotter.curs().x;
			first:=public.anytopix(xcurr);
			private.dish.plotter.message('...mark right of profile')
			xcurr:=private.dish.plotter.curs().x;
			last:=public.anytopix(xcurr);
	};

	if (!is_integer(first) | !is_integer(last)) {
		dl.note('ERROR: Ranges must be in channels');
		dl.note('     : Use usecurs=T to set range with the mouse');
		return F;
	};
	# sanity check
	if (!private.basicSanity(x,v,first,last,flevel,'dishgmeasure.mean')) return F;

	# initial the result
	result := private.basicResult();

	result.type := 'mean';
	result.mean := mean(x[first:last]);
	result.level := flevel*result.mean;
	# find the crossing points
	private.singleLevel(x, v, result.level, first, last,
			    ref cl, ref cr, ref vl, ref vr);
	result.vel := (vl+vr)/2.0;
	result.vwidth := abs(vr-vl);
	result.limits := [cl,cr];
	result.fluxint := private.fluxInt(x,v,cl,cr);
	ok:=public.draw(result);
	return result;
    }

    # NAIC mode 2 - identical to mean except that the cutoff level is the
    # peak value times flevel.  Also, you can optionally supply a noise
    # estimation (the rms argument).  This is subtracted from the peak
    # value before it is multiplied by flevel.  The returned fields
    # here are nearly identical to those in mean.  The only difference is
    # that there is a peak field here instead of mean.  That is the 
    # actual peak, not the value reduced by rms.  The type of this
    # method is "peak".
    const public.peak :=function(lv=F,first=F,last=F,flevel=0.1,rms=0.0,usecurs=F)
    {
	wider private;
        if (!any([first,last,flevel])) {
                dl.note('ERROR: bad arguments; Usage: (lv,first,last,flevel)');
                return F;
        }
#        if (len(split(private.dish.plotter.ips.getabcissaunit(),'/'))!=2) {
#                dl.note('ERROR: This tool requires plotter velocity units');
#                return F;
#        };
        if (is_boolean(lv)) {
             lv := private.dish.rm().getlastviewed();
             nominee := ref lv.value;
             name := lv.name;
#             v:=private.dish.plotter.ips.getcurrentabcissa();
             v:=private.dish.plotter.csys.frequencytovelocity(nominee.data.desc.chan_freq.value,'Hz');
        } else {
             dl.note('ERROR: Mode not enabled ');
             return F;
#             nominee := ref lv;
#             nname:='temp';
#            v:=
        };

        x:=nominee.data.arr;
#	loop to see if we need to determine channels
        if (usecurs) {
           private.dish.plotter.message('Use mouse to mark left of profile');
                        xcurr:=private.dish.plotter.curs().x;
                        first:=public.anytopix(xcurr);
                        private.dish.plotter.message('...mark right of profile')
                        xcurr:=private.dish.plotter.curs().x;
                        last:=public.anytopix(xcurr);
        };
        if (!is_integer(first) | !is_integer(last)) {
                dl.note('ERROR: Ranges must be in channels');
                dl.note('     : Use usecurs=T to set range with the mouse');
                return F;
        };
	# sanity check
	if (!private.basicSanity(x,v,first,last,flevel,'dishgmeasure.peak')) return F;

	# additional sanity check on rms
	if (rms < 0.0) {
	    # warn but go on
	    note("rms is < 0, do not necessarily expect a correct answer", 
		 priority='WARN', origin='dishmeasure.peak');
	}

	# initial the result
	result := private.basicResult();

	result.type := 'peak';
	result.peak := max(x[first:last]) - rms;
	result.level := flevel*result.peak;
	# find the crossing points
	private.singleLevel(x, v, result.level, first, last,
			    ref cl, ref cr, ref vl, ref vr);
	result.vel := (vl+vr)/2.0;
	result.vwidth := abs(vr-vl);
	result.limits := [cl,cr];
	result.fluxint := private.fluxInt(x,v,cl,cr);
        ok:=public.draw(result);
	return result;
    }

    # NAIC mode 3 - similar to peak except that there are two cutoff 
    # levels determined for the data.  Peaks are found within 10 channels
    # from each guessed peak location (peak1 and peak2), the cuttoff levels are
    # then set to be flevel times each peak.  The value from the peak near
    # first is used to set the lower channel limit and the value from the
    # peak near last is used to set the upper channel limit in the same
    # way that peak and mean set those channel limits.  As with peak, you
    # optionally supply a noise estimate (the rms argument) which is 
    # subtracted from the peak values before they are multiplied by flevel.
    # The return value fields are nearly the same as in peak.  Here,
    # the level and peak fields have 2 elements.  There is also a peakchan
    # field which contains the refined locations of the two peaks.
    # The type of this method is "twopeak"
    const public.twopeak := function(lv=F, first=F, last=F, peak1=F, peak2=F, flevel=0.1, rms=0.0, usecurs=F)
    {
	wider private;

        if (!any([first,last,flevel])) {
                dl.note('ERROR: bad arguments; Usage: (lv,first,last,flevel)');
                return F;
        }
#        if (len(split(private.dish.plotter.ips.getabcissaunit(),'/'))!=2) {
#                dl.note('ERROR: This tool requires plotter velocity units');
#                return F;
#        };
        if (is_boolean(lv)) {
             lv := private.dish.rm().getlastviewed();
             nominee := ref lv.value;
             name := lv.name;
#             v:=private.dish.plotter.ips.getcurrentabcissa();
             v:=private.dish.plotter.csys.frequencytovelocity(nominee.data.desc.chan_freq.value,'Hz');

        } else {
             dl.note('ERROR: Mode not enabled ');
             return F;
#             nominee := ref lv;
#             nname:='temp';
#            v:=
        };

        x:=nominee.data.arr;
        if (usecurs) {
           private.dish.plotter.message('Use mouse to mark left of profile');
           xcurr:=private.dish.plotter.curs().x;
           left:=public.anytopix(xcurr);
	   private.dish.plotter.message('...mark left peak');
	   xcurr:=private.dish.plotter.curs().x;
	   pk1:=public.anytopix(xcurr);
           private.dish.plotter.message('...mark right peak');
           xcurr:=private.dish.plotter.curs().x;
           pk2:=public.anytopix(xcurr);
           private.dish.plotter.message('...mark right of profile')
           xcurr:=private.dish.plotter.curs().x;
           right:=public.anytopix(xcurr);
           # do a sort as necessary
           first:=min(left,right);
           last:=max(left,right);
           peak1:=min(pk1,pk2);
           peak2:=max(pk1,pk2);
        };
	# Make defaults for the peak be the ends of the profile
	if (is_boolean(peak1)) peak1:=first;
	if (is_boolean(peak2)) peak2:=last;
        if (!is_integer(first) | !is_integer(last)) {
                dl.note('ERROR: Ranges must be in channels');
                dl.note('     : Use usecurs=T to set range with the mouse');
                return F;
        };
	# sanity check
	if (!private.basicSanity(x,v,first,last,flevel,'dishgmeasure.twopeak')) return F;

	# additional sanity check on location of peaks
	# peaks must be within first and last
	if (peak1 < first || peak1 > last) {
	    note("peak1 is outside the range of first and last",
		 priority='SEVERE', origin='dishmeasure.twopeak');
	    return F;
	}
	if (peak2 < first || peak2 > last) {
	    note("peak2 is outside the range of first and last",
		 priority='SEVERE', origin='dishmeasure.twopeak');
	    return F;
	}

	# additional sanity check on rms
	if (rms < 0.0) {
	    # warn but go on
	    note("rms is < 0, do not necessarily expect a correct answer", 
		 priority='WARN', origin='dishmeasure.twopeak');
	}

	# initial the result
	result := private.basicResult();

	result.type := 'twopeak';
	# find the two peaks
	peakl := as_integer(peak1);
	peakr := as_integer(peak2);
	peak1Mask := max(peak1-10,first):min(peak1+10,last);
	peak2Mask := max(peak2-10,first):min(peak2+10,last);
	fpeakl := max_with_location(x[peak1Mask],peakl);
	fpeakr := max_with_location(x[peak2Mask],peakr);
	# correct locations to true location
	peakl := peak1Mask[1]+peakl-1;
	peakr := peak2Mask[1]+peakr-1;

	# ensure that peakl is a lower channel number than peakr
	if (peakl > peakr) {
	    tmp := peakl;
	    peakl := peakr;
	    peakr := tmp;
	    # also move fpeakl and fpeakr
	    tmp := fpeakl;
	    fpeakl := fpeakr;
	    fpeakr := tmp;
	}

	result.peak := [fpeakl,fpeakr];
	result.peak -:= rms;
	result.peakchan := [peakl,peakr];
	result.level := flevel*result.peak;

	# find the crossing points
	# lower crossing point must be towards a lower channel number from
	# fpeakl
	jl := peakl;
	while (jl >= first && x[jl]>=result.level[1]) jl -:= 1;
	# the above always goes one too far, unless it didn't move
	if (jl != peakl) jl +:= 1;
	jr := peakr;
	while (jr <= last && x[jr]>=result.level[2]) jr +:= 1;
	# the above always goes one too far, unless it didn't move
	if (jr != peakr) jr -:= 1;

	private.interpVel(x, v, jl, jr, result.level[1], result.level[2],
			  ref vl, ref vr);

	result.vel := (vl+vr)/2.0;
	result.vwidth := abs(vr-vl);
	result.limits := [jl,jr];
	result.fluxint := private.fluxInt(x,v,jl,jr);
        ok:=public.draw(result);
	return result;
    }


    # NAIC mode 4
    #  Adapted from IDL routines.
    #             this subroutine calculates the width and average
    #  velocity of a galaxy spectrum. The two halves of the double 
    #  horned profile are treated separately. For each half, the 
    #  peak is determined (it is assumed that the two peaks are on either
    #  side of the center of the user specified limits first and LAST).
    #  Then on each side of the profile a polynomial (by default
    #  1st order) is fit to a user specified portion of the profile.
    #  If the fit is poor, (i.e. (chisqr - deg.of.freedom) > 3 times
    #  sqrt(2*deg.of.freedom)), the user is given the option of fitting
    #  a 2nd degree polynomial and/or changing the levels between
    #  which to fit. The FR points (where FR is a user specified fraction
    #  of the peak flux) on either side of the profile are located by 
    #  interpolation between the two data points that bracket the
    #  FR point. The interpolaton is done by channel number and then 
    #  the velocity corresponding to the interpolated channel number 
    #  is computed. The average velocity is taken to be the mean of
    #  these two velocities and the width is taken to be the difference
    #  between these two velocities.
    #  The uncertainity in the velocity measurment is then calculated
    #  from the rms in the baseline and the coefficients of the 
    #  fitted polynomial. Finally the area bewteen the channels
    #  first and last is computed as in the other methods.

    const public.areape := function(lv=F,first=F,last=F,levs=F,rms=unset,
		usecurs=F,norder=1)
    {
	wider private;

        if (!any([first,last,levs])) {
                dl.note('ERROR: bad arguments; Usage: (lv,first,last,levs)');
                return F;
        }
        if (is_boolean(lv)) {
             lv := private.dish.rm().getlastviewed();
             nominee := ref lv.value;
             name := lv.name;
#             v:=private.dish.plotter.ips.getcurrentabcissa();
             v:=private.dish.plotter.csys.frequencytovelocity(nominee.data.desc.chan_freq.value,'Hz');
        } else {
             dl.note('ERROR: Mode not enabled ');
             return F;
#             nominee := ref lv;
#             nname:='temp';
#            v:=
        };

        x:=nominee.data.arr;
	# loop to see if we need to determine the channels
        if (usecurs) {
           private.dish.plotter.message('Use mouse to mark left of profile');
                        xcurr:=private.dish.plotter.curs().x;
                        first:=public.anytopix(xcurr);
                        private.dish.plotter.message('...mark right of profile')
                        xcurr:=private.dish.plotter.curs().x;
                        last:=public.anytopix(xcurr);
        };

        if (!is_integer(first) | !is_integer(last)) {
                dl.note('ERROR: Ranges must be in channels');
                dl.note('     : Use usecurs=T to set range with the mouse');
                return F;
        };

	#  x       is the array containg the spectrum which is to be measured
	#  v       is the array containing the velocity information for x 
	#  first  is the (user set) channel number of the left edge of the spectrum
	#  last   is the (user set) channel number of the right edge of the spectrum
	#  levs    a 3-element array specifying the levels between which to do 
	#          the polynomial fitting and the level at which to measure.
	#          levs[1] is the upper fraction of the peak flux
	#          levs[2] is the lower fraction of the peak flux, the fitting
	#                  is done between these levels.
	#          levs[3] is the fraction of the peak flux at which to measure
	#  rms     rms noise in the spectrum
	#  norder  The order of the polynomial to use in the fitting.  Can only
	#          be 1 or 2.
	
	# The returned result contains these fields:
	
	#  fluxint is the area under the spectrum within first and last
	#  vel     is the average velocity of the profile
	#  vwidth  is the width of the profile
	#  level   is the same as the input levs
	#  limits  is [first,last]
	#  lchans  are the channels corresponding to levs for the left peak
	#  rchans  are the channels corresponding to levs for the right peak
	#  type    is 'areape'
	#  vrms    is the rms error associated with the velocity measurement
	#  badfit  True if the fit to the profiles was poor.
	#  badpeak True if there was a problem setting the peaks.  In that
        #          case, the other return values are unreliable.
	
	#                          INTERNAL VARIABLES
	
	#   a      parameters of the POLYNOMIAL fit x = a(1) + a(2)*v + ..
	#   fpl    LEFT HALF PEAK FLUX LEVEL IN THE SPECTRUM
	#   fpr    RIGHT HALF PEAK FLUX LEVEL IN THE SPECTRUM
	#   fr1    FRACTION OF PEAK FLUX AT WHICH TO STOP LINEAR FIT TO PROFILE
	#   fr2    FRACTION OF PEAK FLUX AT WHICH TO START LINEAR FIT TO PROFILE
	#   fr     FRACTION OF PEAK FLUX AT WHICH TO CALCULATE WIDTH
	#   ifr1l  LEFT fr1 CHANNEL
	#   ifr2l  LEFT fr2 CHANNEL
	#   ifr1r  RIGHT fr1 CHANNEL
	#   ifr2r  RIGHT fr1 CHANNEL
	#   ifrl   LEFT  CHANNEL at level fr
	#   ifrr   RIGHT CHANNEL at level fr
	#   vrmsl  RMS ERROR ASSOCIATED WITH THE VELOCITY ESTIMATE
	#          AT FLUX LEVEL fr OF THE LEFT HALF OF THE PROFILE
	#   vrmsr  RMS ERROR ASSOCIATED WITH THE VELOCITY ESTIMATE
	#          AT FLUX LEVEL fr OF THE RIGHT HALF OF THE PROFILE
	#   yfrl   LEFT fr POINT
	#   yfrr   RIGHT fr POINT

	# sanity checks - flevel check not triggered here
	if (!private.basicSanity(x,v,first,last,0.0,'dishgmeasure.areape')) return F;

	# additional checks specific to this method
	# last must be > first - reorder them here
	if (first>last) {
	    tmp := first;
	    first := last;
	    last := tmp;
	}
	# first can't be the first channel
	if (first <= 1) {
	    note('first must be larger than 1',
		 priority='SEVERE',origin='dishgmeasure.areape');
	    return F;
	}
	# last can't be the last channel
	if (last >= len(x)) {
	    note('last must be less than the number of channels',
		 priority='SEVERE',origin='dishgmeasure.areape');
	    return F;
	}

	# there must be 3 elements in levs
	if (len(levs) != 3) {
	    note('levs must have 3 elements',
		 priority='SEVERE',origin='dishgmeasure.areape');
	    return F;
	}	

	# rms must be positive
	if (!is_unset(rms) && rms < 0) {
	    note('rms must be positive',
		 priority='SEVERE',origin='dishgmeasure.areape');
	    return F;
	}	

	# norder must be 1 or 2
	if (norder != 1 && norder != 2) {
	    note('norder must be either 1 or 2',
		 priority='SEVERE',origin='dishgmeasure.areape');
	    return F;
	}
	
	result.type := 'areape';

	fr1 := levs[1];
	fr2 := levs[2];
	fr := levs[3];
	
	# search for the peaks
	private.pksearch(x,first,last,ipl,ipr,fpl,fpr);
	
	# locate the fr1, fr2, and fr points
	
	# since ipl is >= first, this iterates towards lower chan numbers from ipl
	ifr1l := ifr2l := first;
	ifrl1 := first;
	ifr1lSet := ifr2lSet := F;
	ifrl1Set := F;
	for (i in ipl:first) {
	    if (!ifr1lSet && (x[i] < (fr1*fpl))) {
		ifr1l := i;
		ifr1lSet := T;
	    }
	    if (!ifr2lSet && (x[i] < (fr2*fpl))) {
		ifr2l := i;
		ifr2lSet := T;
	    }
	    if (!ifrl1Set && (x[i] < (fr*fpl))) {
		ifrl1 := i;
		ifrl1Set := T;
	    }
	    if (ifr1lSet && ifr2lSet && ifrl1Set) break;
	}
	# ifr1l is now first pixel from left peak towards left edge with
	# a flux < fr1 * left peak
	# ifr2l is now first pixel from left peak towards left edge with
	# a flux < fr2 * left peak
	# ifr1l is now first pixel from left peak towards left edge with
	# a flux < fr * left peak
	
	# ifrl2 is searched for from first towards ipl
	ifrl2 := ipl;
	for (i in first:ipl) {
	    if (x[i] > (fr*fpl)) {
		ifrl2 := i;
		break;
	    }
	}
	# ifrl2 is now the first pixel from the left edge to the left peak
	# with a flux > fr * left peak
	
	if (ifr1l <= ifr2l) {
	    ifr1l := ifr2l + 1;
	    note('Upper and lower profile points of left peak coincide!',
		 priority='WARN', origin='dishgmeasure.areape');
	}
	result.lchans := array(0,3);
	result.lchans[1] := ifr1l;
	result.lchans[2] := ifr2l;
	
	# and this iterates towards higher chan numbers from ipr
	ifr1r := ifr2r := last;
	ifrr1 := last;
	ifr1rSet := ifr2rSet := F;
	ifrr1Set := F;
	for (i in ipr:last) {
	    if (!ifr1rSet && (x[i] < (fr1*fpr))) {
		ifr1r := i;
		ifr1rSet := T;
	    }
	    if (!ifr2rSet && (x[i] < (fr2*fpr))) {
		ifr2r := i;
		ifr2rSet := T;
	    }
	    if (!ifrr1Set && (x[i] < (fr*fpr))) {
		ifrr1 := i;
		ifrr1Set := T;
	    }
	    if (ifr1rSet && ifr2rSet && ifrr1Set) break;
	}
	# ifr1r is now first pixel from right peak towards right edge with
	# a flux < fr1 * right peak
	# ifr2l is now first pixel from right peak towards right edge with
	# a flux < fr2 * right peak
	# ifr1l is now first pixel from right peak towards right edge with
	# a flux < fr * right peak
	
	# ifrr2 is searched for from last towards ipr
	ifrr2 := ipr;
	for (i in last:ipr) {
	    if (x[i] > (fr*fpr)) {
		ifrr2 := i;
		break;
	    }
	}
	# ifrr2 is now the first pixel from the right edge to the right peak
	# with a flux > fr * right peak
	
	if (ifr1r >= ifr2r) {
	    ifr2r := ifr1r + 1;
	    note('Upper and lower profile points of right peak coincide!',
		 priority='WARN', origin='dishgmeasure.areape');
	}
	result.rchans := array(0,3);
	result.rchans[1] := ifr1r;
	result.rchans[2] := ifr2r;
	
	# use the default fitter to get a private tool if necessary
	if (is_boolean(private.fitter)) {
	    private.fitter := dfit.fitter();
	}
	
	# linear fit to find place where flux == fr using ifrl1
	# this is on left side of left peak
	c := [ifrl1:(ifrl1+1)];
	dfit.fitpoly(1,c,x[c],id=private.fitter);
	a := dfit.solution(id=private.fitter);
	yfrl1 := (fpl*fr -a[1])/a[2];
	
	# linear fit to find place where flux == fr using ifrl2
	# this is on left side of left peak
	c := [(ifrl2-1):ifrl2];
	dfit.fitpoly(1,c,x[c],id=private.fitter);
	a := dfit.solution(id=private.fitter);
	yfrl2 := (fpl*fr -a[1])/a[2];
	
	# average these two results to get place where flux=fr
	# on left side of left peak
	yfrl := (yfrl1+yfrl2)/2.0;
	ifrl := as_integer(yfrl);
	
	# linear fit to find place where flux == fr using ifrr1
	# this is on left side of right peak
	c := [(ifrr1-1):ifrr1];
	dfit.fitpoly(1,c,x[c],id=private.fitter);
	a := dfit.solution(id=private.fitter);
	yfrr1 := (fpr*fr -a[1])/a[2];
	
	# linear fit to find place where flux == fr using ifrr2
	# this is on left side of right peak
	c := [ifrr2:(ifrr2+1)];
	dfit.fitpoly(1,c,x[c],id=private.fitter);
	a := dfit.solution(id=private.fitter);
	yfrr2 := (fpr*fr -a[1])/a[2];
	
	# average these two results to get place where flux=fr
	# on left side of right peak
	yfrr := (yfrr1 + yfrr2)/2.0;
	ifrr := as_integer(yfrr);
	
	# fit a polynomial of order norder to the sides
	# of the profile and calculate the velocity
	# uncertainity and width
	
	# fit to the left side using lower and upper points
	c := [ifr2l:ifr1l];
	dfit.fitpoly(norder,c,x[c],sd=rms,id=private.fitter);
	a := dfit.solution(id=private.fitter);
	nfree := len(c) - (norder+1);
	ftst1 := 0.0;
	if (nfree > 0) ftst1 := (dfit.chi2(id=private.fitter) - nfree)/sqrt(2.0*nfree);
	else if (nfree < 0) {
	    note(spaste(norder,' order polynomial fit to ', len(c), ' points'),
		 priority='WARN', origin='dishgmeasure.areape');
	}
	
	if (!is_unset(rms)) {
	    if (norder == 1) {
		vrmsl := rms/a[2]*(v[ifrl]- v[ifrl-1]);
	    } else if (norder == 2) {
		vrmsl := rms/(2.0*a[3]*yfrl+a[2])*(v[ifrl]-v[ifrl-1]);
	    }
	} else {
	    vrmsl := 0.0;
	}
	# prevent the velocity error on left side from exceeding  
	# the velocity range of the whole fit.
	
	deltaVF := abs(v[ifr2l]-v[ifr1l]);
	
	if (vrmsl > deltaVF) vrmsl := deltaVF;
	
	# fit to the right side using upper and lower points
	c := [ifr1r:ifr2r];
	dfit.fitpoly(norder,c,x[c],sd=rms,id=private.fitter);
	a := dfit.solution(id=private.fitter);
	nfree := len(c) - (norder+1);
	ftst2 := 0.0;
	if (nfree > 0) ftst2 := (dfit.chi2(id=private.fitter) - nfree)/sqrt(2.0*nfree);
	else if (nfree < 0) {
	    note(spaste(norder,' order polynomial fit to ', len(c), ' points'),
		 priority='WARN', origin='dishgmeasure.areape');
	}
	
	if (!is_unset(rms)) {
	    if (norder == 1) {
		vrmsr := rms/a[2]*(v[ifrr]-v[ifrr-1]);
	    } else if (norder == 2) {
		vrmsr := rms/(2.0*a[3]*yfrr+a[2])*(v[ifrr]-v[ifrr-1]);
	    }
	} else {
	    vrmsr := 0.0;
	}
	
	# prevent the velocity error on right side from exceeding 
	# the velocity range of the whole fit.
	
	deltaVF := abs(v[ifr1r]-v[ifr2r]);
	if (vrmsr > deltaVF) vrmsr := deltaVF;
	
	# if the fit is poor let the user reset the parameters
	
	if ((abs(ftst1) > 3.0) || (abs(ftst2) > 3.0)) {
	    note(spaste('Poor fit to profile: the normalized chisqr are ',ftst1,' and ',ftst2),
		 priority='WARN', origin='dishgmeasure.areape');
	    note(spaste('Number of points used to fit left and right halves are ',
			(ifr1l-ifr2l+1),' and ',(ifr2r-ifr1r+1)),
		 priority='WARN', origin='dishgmeasure.areape');
	    result.badfit := T;
	} else {
	    result.badfit := F;
	}
	
	
	# calculate the velocity width and average velocity
	
	ifrl := as_integer(yfrl);
	result.lchans[3] := ifrl;
	vfrl := v[ifrl] + (yfrl - as_double(ifrl))*(v[ifrl+1]-v[ifrl]);
	
	ifrr := as_integer(yfrr);
	result.rchans[3] := ifrr;
	vfrr := v[ifrr] + (yfrr - as_double(ifrr))*(v[ifrr+1]-v[ifrr]);
	result.vwidth := abs(vfrr - vfrl);
	result.vel := (vfrl + vfrr)/2.0;
	result.vrms := sqrt((vrmsl^2 +vrmsr^2)/2.0);
	if (ifrl > ifrr) {
	    note('error in picking the peaks, please pick the peaks again',
		 priority='SEVERE',origin='dishgmeasure.areape');
	    result.badpeak := T;
	} else {
	    result.badpeak := F;
	}
	
	result.limits := [first,last];
	result.fluxint := private.fluxInt(x,v,first,last);
	
        ok:=public.draw(result);
	return result;
    }

    # NAIC mode 5
    #  Adapted from IDL routines.
    #             this subroutine calculates the width and average
    #  velocity of a galaxy spectrum. The two halves of the double
    #  horned profile are treated separately. For each half, the 
    #  peak is determined (it is assumed that the two peaks are on either
    #  side of the center of the user specified limits first and LAST).
    #  Then each on each side of the profile  a polynomial (by default
    #  1st order) is fit to a user specified portion of the profile.
    #  If the fit is poor, (i.e. (chisqr - deg.of.freedom) > 3 times
    #  sqrt(2*deg.of.freedom)), the user is given the option of fitting
    #  a 2nd degree polynomial and/or changing the levels between
    #  which to fit. Finaly using the fitted polynomial, the fr points
    #  (where fr is a user specified fraction of the peak flux) on
    #  either side of the profile is located. The interpolaton
    #  is done by channel number and then the velocity corresponding
    #  to the interpolated channel number is computed. The average velocity
    #  is taken to be the mean of these two velocities and the
    #  width is taken to be the difference bwteen these two velocities.
    #  The uncertainity in the velocity measurment is then calculated
    #  from the covariance matrix of the coefficients of the fitted
    #  polynomial. Finally the area of the profile between the limits
    #  first and last is computed as summation (x(i)*dv(i)), where
    #  dv(i) is the velocity difference between channels i and i-1.
    #  PEAK channels are flagged and the fitted polynomials are plotted.
    const public.areapf := function(lv=F,first=F,last=F,levs=F,rms=unset,
			usecurs=F,norder=1)
    {
	wider private; 

        if (!any([first,last,levs])) {
                dl.note('ERROR: bad arguments; Usage: (lv,first,last,levs)');
                return F;
        }
        if (is_boolean(lv)) {
             lv := private.dish.rm().getlastviewed();
             nominee := ref lv.value;
             name := lv.name;
#             v:=private.dish.plotter.ips.getcurrentabcissa();
             v:=private.dish.plotter.csys.frequencytovelocity(nominee.data.desc.chan_freq.value,'Hz');
        } else {
             dl.note('ERROR: Mode not enabled ');
             return F;
#             nominee := ref lv;
#             nname:='temp';
#            v:=
        };

        x:=nominee.data.arr;
	# loop to see if we need to determine the channels
        if (usecurs) {
           private.dish.plotter.message('Use mouse to mark left of profile');
                        xcurr:=private.dish.plotter.curs().x;
                        first:=public.anytopix(xcurr);
                        private.dish.plotter.message('...mark right of profile')
                        xcurr:=private.dish.plotter.curs().x;
                        last:=public.anytopix(xcurr);
        };

        if (!is_integer(first) | !is_integer(last)) {
                dl.note('ERROR: Ranges must be in channels');
                dl.note('     : Use usecurs=T to set range with the mouse');
                return F;
        };
	# x       is the array containg the spectrum which is to be measured
	# v       is the array containing the velocity information for x 
	# first  is the (user set) channel number of the left edge of the spectrum
	# last   is the (user set) channel number of the right edge of the spectrum
	# levs    a 3-element array specifying the levels between which to do 
	#         the polynomial fitting and the level at which to measure.
	#         levs[1] is the upper fraction of the peak flux
	#         levs[2] is the lower fraction of the peak flux, the fitting
	#                 is done between these levels.
	#         levs[3] is the fraction of the peak flux at which to measure
	# rms     rms noise in the spectrum (as estimated by base.f)
	# norder  The order of the polynomial to use in the fitting.  Can only
	#         be 1 or 2.
             

	# The returned result contains these fields:
	# fluxint is the area under the spectrum within the first and last
	# vel     is the average velocity of the profile
	# vwidth  is the width of the profile
	# level   is the same as the input levs
	# limits  is [first,last]
	# lchans  are the channels corresponding to levs for the left peak
	# rchans  are the channels corresponding to levs for the right peak
	# type    is 'areapf'
	# vrms    is the rms error associated with the velocity measurement
	# badfit  True if the fit to the profiles was poor.
	# badpeak True if there was a problem setting the peaks.  In that
        #          case, the other return values are unreliable.


	#                          INTERNAL VARIABLES
   
	#  a      parameters of the POLYNOMIAL fit x = a(1) + a(2)*v + ..
	#  b      DUMMY VECTOR USED TO CONDENSE rms CALCULATION CODE
	#  covar  MATRIX CONTAINING COVARIANCE OF THE COEFFICIENTS
	#          OF THE FITTED POLYNOMIALS
	#  fpl    LEFT HALF PEAK FLUX LEVEL IN THE SPECTRUM
	#  fpr    RIGHT HALF PEAK FLUX LEVEL IN THE SPECTRUM
	#  fr1    FRACTION OF PEAK FLUX AT WHICH TO STOP LINEAR FIT TO PROFILE
	#  fr2    FRACTION OF PEAK FLUX AT WHICH TO START LINEAR FIT TO PROFILE
	#  fr     FRACTION OF PEAK FLUX AT WHICH TO CALCULATE WIDTH
	#  I,J    DUMMY INTEGERS FOR LOOPING CONTROL
	#  ifr1l  LEFT fr1 CHANNEL
	#  ifr2l  LEFT fr2 CHANNEL
	#  ifr1r  RIGHT fr1 CHANNEL
	#  ifr2r  RIGHT fr1 CHANNEL
	#  ifrl   LEFT  CHANNEL at fr level
	#  ifrr   RIGHT CHANNEL at fr level
	#  vrmsl  rms ERROR ASSOCIATED WITH THE VELOCITY ESTIMATE
	#         AT FLUX LEVEL fr OF THE LEFT HALF OF THE PROFILE
	#  vrmsr  rms ERROR ASSOCIATED WITH THE VELOCITY ESTIMATE
	#         AT FLUX LEVEL fr OF THE RIGHT HALF OF THE PROFILE
	#  yfrl   LEFT fr POINT
	#  yfrr   RIGHT fr POINT

	# sanity checks - flevel check not triggered here
	if (!private.basicSanity(x,v,first,last,0.0,'dishgmeasure.areapf')) return F;

	# additional checks specific to this method
	# last must be > first - reorder them here
	if (first>last) {
	    tmp := first;
	    first := last;
	    last := tmp;
	}
	# first can't be the first channel
	if (first <= 1) {
	    note('first must be larger than 1',
		 priority='SEVERE',origin='dishgmeasure.areapf');
	    return F;
	}
	# last can't be the last channel
	if (last >= len(x)) {
	    note('last must be less than the number of channels',
		 priority='SEVERE',origin='dishgmeasure.areapf');
	    return F;
	}

	# there must be 3 elements in levs
	if (len(levs) != 3) {
	    note('levs must have 3 elements',
		 priority='SEVERE',origin='dishgmeasure.areapf');
	    return F;
	}	

	# rms must be positive
	if (!is_unset(rms) && rms < 0) {
	    note('rms must be positive',
		 priority='SEVERE',origin='dishgmeasure.areapf');
	    return F;
	}

	# norder must be 1 or 2
	if (norder != 1 && norder != 2) {
	    note('norder must be either 1 or 2',
		 priority='SEVERE',origin='dishgmeasure.areap');
	    return F;
	}

	result.type := 'areapf'
	    fr1 := levs[1];
	fr2 := levs[2];
	fr := levs[3];

	# search for the peaks
	private.pksearch(x,first,last,ipl,ipr,fpl,fpr);

	# locate the fr1 and fr2 and fr points

	ifr1l := ifr2l := first;
	ifr1lSet := ifr2lSet := F;
	for (i in ipl:first) {
	    if (!ifr1lSet && x[i] < (fr1*fpl)) {
		ifr1l := i;
		ifr1lSet := T;
	    }
	    if (!ifr2lSet && x[i] < (fr2*fpl)) {
		ifr2l := i;
		ifr2lSet := T;
	    }
	    if (ifr1lSet && ifr2lSet) break;
	}
	
	if (ifr1l <= ifr2l) {
	    ifr1l := ifr2l + 1;
	    note('Upper and lower profile points of left peak coincide!',
		 priority='WARN', origin='dishgmeasure.areapf');
	}
	result.lchans := array(0,3);
	result.lchans[1] := ifr1l;
	result.lchans[2] := ifr2l;

	# and this iteraterates towards higher chan numbers from ipr
	ifr1r := ifr2r := last;
	ifr1rSet := ifr2rSet := F;
	for (i in ipr:last) {
	    if (!ifr1rSet && x[i] < (fr1*fpr)) {
		ifr1r := i;
		ifr1rSet := T;
	    }
	    if (!ifr2rSet && x[i] < (fr2*fpr)) {
		ifr2r := i;
		ifr2rSet := T;
	    }
	    if (ifr1rSet && ifr2rSet) break;
	}
	
	if (ifr1r >= ifr2r) {
	    ifr2r := ifr1r + 1;
	    note ('Upper and lower profile points of right peak coincide!',
		  priority='WARN',origin='areapf');
	}
	result.rchans := array(0,3);
	result.rchans[1] := ifr1r;
	result.rchans[2] := ifr2r;

	# locate the fr points

	# use the default fitter to get a private tool if necessary
	if (is_boolean(private.fitter)) {
	    private.fitter := dfit.fitter();
	}

	# fit a polynomial of order norder to the left half
	# of the profile and locate the fr point.

	dl_max := as_double(ifr1l - ifr2l);

	c := [ifr2l:ifr1l];
	dfit.fitpoly(norder,c,x[c],sd=rms,id=private.fitter);
	a := dfit.solution(id=private.fitter);
	covar := dfit.covariance(id=private.fitter);
	nfree := len(c) - (norder+1);
	ftst1 := 0.0;
	if (nfree > 0) ftst1 := (dfit.chi2(id=private.fitter) - nfree)/sqrt(2.0*nfree);
	else if (nfree < 0) {
	    note(spaste(norder,' order polynomial fit to ', len(c), ' points'),
		 priority='WARN', origin='dishgmeasure.areape');
	}

	if (norder == 1) {
	    yfrl := (fpl*fr -a[1])/a[2];
	    ifrl := as_integer(yfrl);
	} else {
	    yfrls := sqrt(a[2]*a[2] -4.0*(a[1]-fr*fpl)*a[3]);
	    yfrl := -a[2]+yfrls;
	    yfrl := yfrl /(2.0*a[3]);
	    ifrl := as_integer(yfrl);
	    if ((ifrl < ifr2l) || (ifrl > ifr1l)) {
		yfrl := -a[2]-yfrls;
		yfrl := yfrl /(2.0*a[3]);
		ifrl := as_integer(yfrl);
	    }
	}
	result.lchans[3] := ifrl;

	# Calculate the uncertainity in the velocity measurement
	# and constrain it to less than the interval of fit
	
	b := [1.0, yfrl, yfrl*yfrl];
	frms := 0.0;
	
	for (i in [1:(norder+1)]) {
	    frms := frms + sum(b[i]*b[1:(norder+1)]*covar[i,]);
	}

	# frms is the square of the error on the flux, use the error itself
	frms := sqrt(frms)
	
	if (norder == 1) epsl_ch := frms/a[2];
	else epsl_ch := frms/(2.0*a[3]*yfrl+a[2]);
	if (epsl_ch <= dl_max) {
	    vrmsl := epsl_ch*(v[ifrl]-v[ifrl-1]);
	} else {
	    vrmsl := dl_max*(v[ifrl]-v[ifrl-1]);
	}

	# fit a polynomial of order norder to the right half
	# of the profile and locate the fr point
	
	dr_max := as_double(ifr2r - ifr1r);

	c := [ifr1r:ifr2r];
	dfit.fitpoly(norder,c,x[c],sd=rms,id=private.fitter);
	a := dfit.solution(id=private.fitter);
	covar := dfit.covariance(id=private.fitter);
	nfree := len(c) - (norder+1);
	ftst2 := 0.0;
	if (nfree > 0) ftst2 := (dfit.chi2(id=private.fitter) - nfree)/sqrt(2.0*nfree);
	else if (nfree < 0) {
	    note(spaste(norder,' order polynomial fit to ', len(c), ' points'),
		 priority='WARN', origin='dishgmeasure.areape');
	}
	
	if (norder == 1) {
	    yfrr := (fpr*fr -a[1])/a[2];
	    ifrr := as_integer(yfrr);
	} else {
	    yfrrs := sqrt(a[2]*a[2] -4.0*(a[1]-fr*fpr)*a[3]);
	    yfrr := -a[2]+yfrrs;
	    yfrr := yfrr /(2.0*a[3]);
	    ifrr := as_integer(yfrr);
	    if ((ifrr < ifr1r) || (ifrr > ifr2r)) {
		yfrr := -a[2]-yfrrs;
		yfrr := yfrr /(2.0*a[3]);
		ifrr := as_integer(yfrr);
	    }
	}
	result.rchans[3] := ifrr;

	# Calculate the uncertainity in the velocity measurement
	# and constrain it to less than the interval of fit
	b := [1.0, yfrr, yfrr*yfrr];
	frms := 0.0;
	
	for (i in [1:(norder+1)]) {
	    frms := frms + sum(b[i]*b[1:(norder+1)]*covar[i,]);
	}

	# frms is the square of the error on the flux, use the error itself
	frms := sqrt(frms)
	
	if (norder == 1) {
	    epsr_ch := frms/a[2];
	} else {
	    epsr_ch := frms/(2.0*a[3]*yfrr+a[2]);
	}
	if (epsr_ch <= dr_max) {
	    vrmsr := epsr_ch*(v[ifrr]-v[ifrr-1]);
	} else {
	    vrmsr := dr_max*(v[ifrr]-v[ifrr-1]);
	}

	# if the fit is poor let the user reset the parameters

	if ((abs(ftst1) > 3.0) || (abs(ftst2) > 3.0)) {
	    note(spaste('Poor fit to profile: the normalized chisqr are ',ftst1,' and ',ftst2),
		 priority='WARN', origin='dishgmeasure.areapf');
	    note(spaste('Number of points used to fit left and right halves are ',
			(ifr1l-ifr2l+1),' and ',(ifr2r-ifr1r+1)),
		 priority='WARN', origin='dishgmeasure.areapf');
	    result.badfit := T;
	} else {
	    result.badfit := F;
	}
 
	# calculate the velocity width and average velocity

	ifrl := as_integer(yfrl);
	vfrl := v[ifrl] + (yfrl -as_double(ifrl))*(v[ifrl+1]-v[ifrl]);
	
	ifrr := as_integer(yfrr);
	vfrr := v[ifrr] + (yfrr -as_double(ifrr))*(v[ifrr+1]-v[ifrr]);
	result.vwidth:= abs(vfrr - vfrl);
	result.vel := (vfrl + vfrr)/2.0;
	result.vrms := sqrt((vrmsl^2 + vrmsr^2)/2.0);

	if (ifrl > ifrr) {
	    note('error in picking the peaks, please pick the peaks again',
		 priority='SEVERE',origin='dishgmeasure.areapf');
	    result.badpeak := T;
	} else {
	    result.badpeak := F;
	}

	result.limits := [first,last];
	result.fluxint := private.fluxInt(x,v,first,last);
	
        ok:=public.draw(result);
	return result;
    }


    const public.done := function() 
    {
	wider private;
	wider public;
	if (!is_boolean(private.fitter)) {
	    dfit.done(id=private.fitter);
	}
	val public := F;
    }

#    const public.debug := private;
    return ref public;
}
