# dishstat : the sdstatistics_app closure object
#------------------------------------------------------------------------------
# Copyright (C) 1997,1998,1999,2000,2001,2002,2003
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
#
#    $Id: dishstat.g,v 19.1 2004/08/25 01:11:40 cvsmgr Exp $
#
#------------------------------------------------------------------------------

# include guard
pragma include once
 
include "mathematics.g"
include "dishstatgui.g"


## TODO : use flag and weights appropriately!

const dishstat := function(ref itsdish)
{
    private := [=];
    public := [=];

    private.sdutil := F;
    private.gui := F;
    private.dish := itsdish;
#    private.xunits:=F;
    private.myranges:='';
#    private.outp:='TERM';

    # takes a Matrix of ranges [2,nranges] and orders them,
    # eliminating overlap and duplication
    private.orderRange := function(ranges) {
#	if (len(ranges[1,]) < 2) return ranges;
	for (i in 1:ranges::shape[2]) {
		ord:=order(ranges[,i]);
		ranges[,i]:=ranges[ord,i];
	}
	ord := order(ranges[1,]);

	return ranges;

	mask := array(T,len(ord));

	for (i in len(ord):2) {
	    if (ranges[1,ord[i-1]] == ranges[1,ord[i]]) {
		mask[ord[i]] := F;
		ranges[2,ord[i-1]] := max(ranges[2,ord[[i-1]:i]]);
	    }
	}

	if (sum(mask) < 2) return ranges[,ord[mask]];

	ord := ord[mask];
	mask := array(T,len(ord));

	for (i in len(ord):2) {
	    if (ranges[2,ord[i-1]] >= ranges[1,ord[i]]) {
		mask[ord[i]] := F;
		ranges[1,ord[i-1]] := min(ranges[1,ord[[i-1]:i]]);
		ranges[2,ord[i-1]] := max(ranges[2,ord[[i-1]:i]]);
	    }
	}


	if (sum(mask) < 2) return ranges[,ord[mask]];

	# and similarly for the max side
	ranges := ranges[,ord[mask]];
	ord := order(ranges[2,]);
	mask := array(T,len(ord));

	for (i in len(ord):2) {
	    if (ranges[2,ord[i-1]] == ranges[2,ord[i]]) {
		mask[ord[i]] := F;
		ranges[1,ord[i-1]] := min(ranges[1,ord[[i-1]:i]]);
	    }
	}


	if (sum(mask) < 2) return ranges[,ord[mask]];

	ord := ord[mask];
	mask := array(T,len(ord));

	for (i in len(ord):2) {
	    if (ranges[2,ord[i-1]] >= ranges[1,ord[i]]) {
		mask[ord[i]] := F;
		ranges[1,ord[i-1]] := min(ranges[1,ord[[i-1]:i]]);
		ranges[2,ord[i-1]] := max(ranges[2,ord[[i-1]:i]]);
	    }
	}
	return ranges[,ord[mask]];
    }
    
    # converts a Matrix of ranges [2,nranges] [1,n] := min; [2,n] := max
    # the units expected here are channel numbers
    private.maskFromRanges := function(ranges)
    {
	m := F;
	# round to nearest integer
	ranges := as_integer(ranges+0.5);
	ranges := private.orderRange(ranges);
	# watch for the range going below a certain size and the shape
	# getting too small
	if (len(ranges)==2) ranges::shape := [2,1];
	for (i in 1:ranges::shape[2]) {
	    if (i == 1) {
		curr := 0;
	    } else {
		curr := len(m);
	    }
	    new := ranges[2,i]-ranges[1,i]+1;
	    m[(curr+1):(curr+new)] := ranges[1,i]:ranges[2,i];
	}
	return m;
    }

    private.stringFromRanges := function(ranges)
    {
	result := "";
	global system;
	currPrec := system.print.precision;
	# this should be enough for floating point precisions
	system.print.precision := 8;
	if (ranges::shape[2] > 0) {
	    for (i in 1:ranges::shape[2]) {
		if (ranges[1,i] == ranges[2,i]) {
		    result := spaste(result,as_string(ranges[1,i]),' ');
		} else {
		    result := spaste(result,'[',as_string(ranges[1,i]),':',
				     as_string(ranges[2,i]),'] ');
		}
	    }
	}
	system.print.precision := currPrec;
	return result;
    }

    # using xDesc (an SDRecord desc record) convert xVals to channel numbers
    private.toChan := function(xVals, xDesc) {
	if (has_field(xDesc,'crval')) {
	return result := abs((xVals - xDesc.crval)/xDesc.cdelt) + xDesc.crpix;
	} else {
	return F;
	}
    }

    private.toX := function(chans, xDesc) {
	if (has_field(xDesc,'crpix')) {
	return result := (chans-xDesc.crpix)*xDesc.cdelt + xDesc.crval;
	} else {
	return F;
	}
    }

    private.dostat := function(sdrec) {
	wider private;
        if (is_agent(private.gui)) {
            private.myranges:=private.gui.myranges();
        }
	myranges:=private.dish.plotter.ranges();
        if (!is_sdrecord(sdrec)) {
		print "ERROR: The input data is not an SDRecord";
		return F;
	}; 
        if (!is_string(myranges)) {
		print 'ERROR: Ranges is not a string';
		return F;
	};
        if (is_boolean(private.sdutil)) private.sdutil := sdutil();
#
	xvec:=private.dish.plotter.ips.getcurrentabcissa();
	#yvec:=private.dish.plotter.ips.getordinate().data;
	yvec:=sdrec.data.arr;
	fvec:=private.dish.plotter.ips.getmask();
        # first, convert the ranges to a matrix
        if (len(split(myranges)) == 0) {
                rmat:=xvec;
        } else {
                rmat := public.rangeStringToMatrix(myranges);
        };
        if (is_fail(rmat)) {
		print 'ERROR: Bad ranges ';
		return F;
	};
	mask := (xvec>=min(rmat) & xvec<=max(rmat)) & fvec;
	if (!any(mask)) {
		print 'ERROR: No data found in range';
		return F;
	};
	#loop over polarizations
	newrec:=[=];
	for (j in 1:yvec::shape[1]){
	yvecseg:=yvec[j,mask];
	xvecseg:=xvec[mask];
	#
	pd:=spaste('pol_',j);
    	newrec[pd]:=[=];
	newrec[pd].peak:=max(yvecseg);
	deltay:=sum(yvecseg)/len(yvecseg);
	newrec[pd].area:=deltay*(max(rmat)-min(rmat));
	newrec[pd].min:=min(yvecseg);
	newrec[pd].rms:=stddev(yvecseg);
	newrec[pd].scan:=sdrec.header.scan_number;
	newrec[pd].centroid:=0;
	newrec[pd].vpeak:=xvecseg[yvecseg==newrec[pd].peak];
	newrec[pd].startint:=min(rmat);
	newrec[pd].stopint:=max(rmat);
	# get centroid
	halfarea:=sum(yvecseg)/2.;
	if (halfarea>=0) {
		centroidi:=0;
		for (i in 1:len(yvecseg)) {
			thesum:=sum(yvecseg[1:i]);
			if (thesum>=halfarea) {
			   # this is the location where the sum exceeds/equals
			   # the half area
			   centroidi:=i;
			   break;
			}
    		}
		# correct for fractional x-axis to get centroid
		frac_channel:=(thesum-halfarea)/(yvecseg[centroidi]);
		newrec[pd].centroid:=xvecseg[centroidi];
	} else {
		newrec[pd].centroid:=0.0;
        };
	}; #end loop over polarization
#	newrec[i].centroid:=xvecseg[centroidi]-frac_channel;
#	csys.done();
        return newrec;
    }

#   old name = intervalstat
    public.apply := function(lv=F,outf=F)
    {
        wider private,public;
        if (is_boolean(lv)) {
           if (private.dish.doselect()) {
                if (private.dish.rm().selectionsize()==1) {
                        lv := private.dish.rm().getselectionvalues();
                        nominee := ref lv;
#                       nname := lv.name;
                        nname:=private.dish.rm().getselectionnames();
                } else {
                        return throw('did not work');
                }
           } else {
                lv := private.dish.rm().getlastviewed();
                nominee := ref lv.value;
                name := lv.name;
           }
        } else {
                nominee := ref lv;
                nname:='temp';
        }
	newrec:=[=]; #initialize newrec
        # This global is currently necessary because eval does its work
        # only on global things
 
        if (is_boolean(nominee)) {
            private.dish.message('Error! An SDRecord has not yet been viewed');
	    return F;
 	} else if (is_sdrecord(nominee)) {
		newrec:=private.dostat(nominee);
	} else if (is_sditerator(nominee)) {
		sdlength:=nominee.length()
		ok:=nominee.setlocation(1);
#                if (is_boolean(outf)) {
#                        ok:=private.dish.open(spaste(nname,'_sm'),new=T);
#                } else {
#                        ok:=private.dish.open(outf,new=T);
#                }
#       if (is_fail(ok)) return throw('Error: couldnt create working set');
#                private.dish.rm().select('end');
                rmlen:=private.dish.rm().size();
                for (i in 1:sdlength) {
                        ok:=nominee.setlocation(i);
                        global __tempsdrec__ := nominee.get()
			newrec:=private.dostat(__tempsdrec__);
			print newrec;
		}
	}
	if (is_boolean(newrec)) {
		return F;
	};
	if (is_agent(private.gui)) private.gui.setvalues(newrec[1]);
        return newrec;
    }

#    public.debug := function() {
#	wider private;
#	return private;
#    }

#   dismisses gui
    public.dismissgui := function() {
	wider private;
	if (is_agent(private.gui)) {
		private.gui.done();
	}
	private.gui := F;
	return T;
    }

#   done with this closure; this makes it impossible to use the public part
#   of this after invoking this function
    public.done := function() {
	wider private,public;
	public.dismissgui();
	val private := F;
	val public  := F;
	return T;
    }

    # return any state information as a record
    public.getstate := function() {
        wider private;
        state := [=];

        # all of the state is currently in the GUI, it should be here instead
        if (is_agent(private.gui)) {
            state := private.gui.getstate();
        }
        return state;
    }

    public.gui := function(parent, widgetset=dws) {
	wider private,public;
	#don't build one if we already have one
	if (!is_agent(private.gui)&&widgetset.have_gui()) {
		private.gui := dishstatgui(parent,itsdish,itsdish.logcommand,
			widgetset);
#		private.updateGUIstate();
		whenever private.gui->done do {
		    wider private;
		    if (is_record(private)) private.gui:=F;
		}
	}
    return private.gui;
    }

    public.opmenuname := function() {return 'Statistics';}

    public.opfuncname := function() {return 'statistics';}

    public.rangeStringToMatrix := function(rangeString)
    {
	wider private;
	if (is_boolean(private.sdutil)) private.sdutil := sdutil();
	return private.sdutil.parseranges(rangeString);
    }

#    public.rangeStringToUnitString := function(rangeString, desc, toXUnits=F)
#    {
#	wider private;
	# first, convert the string to a matrix
#	rmat := public.rangeStringToMatrix(rangeString);
#	if (is_fail(rmat)) fail;
#	if (toXUnits) {
#	    # then convert them to x-axis values
#	    rmat := private.toX(rmat, desc);
#	} else {
#	    # then convert them to channel numbers
#	    rmat := private.toChan(rmat, desc);
#	}
	# and finally convert it to a string
#	return private.stringFromRanges(rmat);
#    }
    
#    public.setoutput := function(outp) {
#	wider private;
#	private.output:=outp;
#	return T;
#    }

    public.setranges := function(myranges) {
	wider private;
	private.myranges:=myranges;
	if (is_agent(private.gui)) private.gui.setranges(myranges);
	return T;
    }

#    public.setunits := function(xunits) {
#	wider private;
#	private.xunits:=xunits;
#	if (is_agent(private.gui)) private.gui.setunits(xunits);
#	return T;
#    }

    public.setstate := function(state) {
        wider private;
	result := F;
        if (is_record(state)) {
            # just forward it to the gui
            if (is_agent(private.gui)) {
                result := private.gui.setstate(state);
            }
        }
	return result;
    }

##statistics Description: Generate statistics over a region.
##           Example:     mystat:=stats(range='[50:100]');
##                        - mystat
##                        [peak=3.96164307, area=1462.6009, min=2.85664238,
##                        rms=0.781353476, scan=5,centroid=-2464.06787,
##                        vpeak=1360.03394]
##           Returns:     A record with the above information
##           Produces:    NA
   public.dstats := function(scanrec=F,range=F,units=unset){
	wider private,public;
	if (!is_unset(units)) {
	    print 'WARNING: d.dstats units argument is ignored currently.';
	}
	#print 'range is ',range,is_string(range);
        if (is_boolean(scanrec)) {
                scanrec:=private.dish.rm().getlastviewed().value;
        }
	if (!is_sdrecord(scanrec)) {
		print 'ERROR: Not a valid SDRecord';
		return F;
	};
#        if (units=='channels') {
#                units:=F;
#        } else {
#                units:=T;
#        };
        if (is_boolean(range)) {
             range:=private.dish.plotter.ranges();
        } else {
	     if (!is_string(range)) {
		print 'ERROR: Ranges must be given as a string';
		print '       range="[10:100]"';
		return F;
	     };
             private.dish.plotter.putranges(range);
        };
#       ok:=public.setunits(units);
#       ok:=public.setranges(range);
        return public.apply();
   }


    return public;
}
