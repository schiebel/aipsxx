# dishsmooth.g: dish smoother
#------------------------------------------------------------------------------
# Copyright (C) 1998,2000,2001,2002,2003
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
#    $Id: dishsmooth.g,v 19.2 2005/08/10 17:46:38 jmcmulli Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include 'mathematics.g';
include 'dishsmoothgui.g';

#test comment
## TODO : use flag and weights appropriately!

const dishsmooth := function(ref itsdish)
{
    private := [=];
    public := [=];

    # the default is to start off without the GUI
    private.gui := F;
    private.dish := itsdish;
    private.HANNING:=0;
    private.BOXCAR:=1;
    private.GAUSSIAN:=2;
    private.GWCHANNELUNITS:=1;
    private.GWAXISUNITS:=2;
    private.currType:=0;
    private.decimate:=F;
    private.intserver := F;


    private.fftserver := F;
    private.nan := 0/0;

    private.dosmooth := function(nominee,plotIt=T,cli=F) {
	wider private;
            type := F;
            cmd := "dish.ops().smooth().smoother().";
            arg := F;
            if (is_agent(private.gui)) {
                private.currType:=private.gui.currType();
                private.decimate:=private.gui.decimateState();
            }
            if (private.currType == private.HANNING) {
                type := "Hanning";
                if (3 > nominee.data.arr::shape[2]) {
                    dish.message('There are fewer than 3 elements in the data array.');
                    nominee := F;
                    return;
                }
                nominee := private.hanning(nominee,private.decimate);
#               history and log block
		currentHistoryLength:=len(nominee.hist);
                nominee.hist[currentHistoryLength+1]:=
		as_string(itsdish.history('dish.ops().smooth.settype',[type='HANNING']));
		nominee.hist[currentHistoryLength+2]:=
		as_string(itsdish.history('dish.ops().smooth.setdecimate',
		   [tOrF=private.decimate]));
                nominee.hist[currentHistoryLength+3]:=
		as_string(itsdish.history('dish.ops().smooth.apply'));
#               history and log block
            } else if (private.currType == private.BOXCAR) {
                if (private.gui.boxwidth()!='') 
                        private.boxwidth:=private.gui.boxwidth();
#		history and log block
                currentHistoryLength:=len(nominee.hist);
		nominee.hist[currentHistoryLength+1]:=
		as_string(itsdish.history('dish.ops().smooth.settype',[type='BOXCAR']));
                nominee.hist[currentHistoryLength+2]:=
		as_string(itsdish.history('dish.ops().smooth.setdecimate',
                   [tOrF=private.decimate]));
		nominee.hist[currentHistoryLength+3]:=
		as_string(itsdish.history('dish.ops().smooth.setboxwidth',
                   [boxwidth=private.boxwidth]));
		nominee.hist[currentHistoryLength+4]:=
		as_string(itsdish.history('dish.ops().smooth.apply'));
		itsdish.logcommand('dish.ops().smooth.setboxwidth',
                        [boxwidth=private.boxwidth]);
#		history and log block
                swidth := private.boxwidth;
                if (swidth == '') {
                    nominee := F;
                    private.dish.message('Enter a width!');
                    return;
                }
                width := as_integer(as_float(swidth) + 0.5);
                if (width < 1) {
                    nominee := F;
                    private.dish.message('The width must be >= 1');
                    return;
                }
                if (width > nominee.data.arr::shape[2]) {
                    private.dish.message('The width is more than the number of elements in the data array.');
                    nominee := F;
                    return;
                }
                type := "Boxcar";
                nominee := private.boxcar(nominee, width, private.decimate);
                arg := spaste('width=',width,',decimate=',private.decimate);
            } else {
		type := "Gaussian";
                private.gausswidth:=private.gui.gausswidth();
		private.gwcurrUnits := private.gui.gwunits();
#		history and log block
                currentHistoryLength:=len(nominee.hist);
		nominee.hist[currentHistoryLength+1]:=
		as_string(itsdish.history('dish.ops().smooth.settype',[type='GAUSSIAN']));
                nominee.hist[currentHistoryLength+2]:=
		as_string(itsdish.history('dish.ops().smooth.setgausswidth',
                   [gausswidth=private.gausswidth,units=private.gwcurrUnits]));
		nominee.hist[currentHistoryLength+3]:=
		as_string(itsdish.history('dish.ops().smooth.apply'));
                itsdish.logcommand('dish.ops().smooth.setgausswidth',
                     [gausswidth=private.gausswidth,units=private.gwcurrUnits]);
#
                swidth := private.gausswidth;
                if (swidth == '') {
                    nominee := F;
                    private.dish.message('Enter a width!');
                    return;
                }
                width := as_double(swidth);
                if (private.gwcurrUnits == private.GWAXISUNITS) {
                    global system;
                    currPrec := system.print.precision;
                    # this should be enough for floating point precision
                    system.print.precision := 8;
                    width /:= nominee.data.desc.chan_width;
                    width := as_double(as_string(width));
                    system.print.precision := currPrec;
                    system.print.precision := currPrec;
                }
                if (width == 0.0) {
                    nominee := F;
                    private.dish.message('The width can NOT be zero');
                    return;                
		}
                nominee := private.gaussian(nominee, width);
                cmd := spaste(cmd,'gaussian');
                arg := spaste('width=',width);
	    }
            resultDescription:=spaste(type,' smoothed spectra');
            if (type != "Hanning") {
                  resultDescription := spaste(resultDescription,
                                 ' using a width of ', width,' channels');
                  if (type == "Gaussian") {
                        resultDescription:=spaste(resultDescription,' (FWHM)');
                  }
            }
            if (type != "Gaussian") {
                if (private.decimate) {
                    resultDescription := spaste(resultDescription,
                                ', with decimation');
                 } else {
                    resultDescription := spaste(resultDescription,
                                ', with NO decimation');
                 }
            }
            if (!is_boolean(nominee)&private.flag!='sditerator'&cli==F) {
               resultName := private.dish.rm().add ('smooth',
                              resultDescription,nominee,'SDRECORD');
               private.dish.rm().select('end',plotIt);
               private.dish.message(resultDescription);
	       return T;
	    } 
	 
	return nominee;
    }

#  get the last variable in the results manager and return it
   private.getrecord := function(plotIt=T) {
        wider private;
        sz:=private.dish.rm().size();
        ok:=private.dish.rm().select(sz,plotIt);
        mysdr:=private.dish.rm().getlastviewed();
        if (is_sdrecord(mysdr.value)) {
                return mysdr.value;
        } else {
                return throw('FAIL: Not an SDRecord');
        }
   }


# lv: if boolean, get last selected, otherwise an SDRECORD/SDITERATOR has been
#     provided as lv; outf: if an SDITERATOR, can optionally provide an output
#     workingset.
    public.apply := function (lv=F,outf=F,plotIt=T) {
	wider private;
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
# will need to change this if move to getselectionvalues!
	__sdtemp__:=nominee;
        if (is_boolean(nominee)) {
           private.dish.message('Error!  An SDRecord has not yet been viewed');
        } else if (is_sdrecord(nominee)) {
	        private.flag:='sdrecord';
	   nominee:=private.dosmooth(nominee,plotIt);
           # and insert this into the results manager
#          # smoothing does not yet alter header.resolution, but it should';
	} else if (is_sditerator(__sdtemp__)) {
		private.flag:='sditerator';
		sdlength:=__sdtemp__.length();
		ok:=__sdtemp__.setlocation(1);
		if (is_boolean(outf)) {
			ok:=private.dish.open(spaste(nname,'_sm'),new=T);	
		} else {
			ok:=private.dish.open(outf,new=T);
		}
#	if (is_fail(ok)) return throw('Error: couldnt create working set');
		private.dish.rm().select('end');
		rmlen:=private.dish.rm().size();
		for (i in 1:sdlength) {
			ok:=__sdtemp__.setlocation(i);
			global __tempsdrec__ := __sdtemp__.get()
			__tempsdrec__ := private.dosmooth(ref __tempsdrec__,plotIt);
	ok:=private.dish.ops().save.setws(private.dish.rm().getnames(rmlen));
	ok:=private.dish.ops().save.apply(__tempsdrec__);
		}
        } else {
            private.dish.message('Smoothing is not supported on the current selection in the results manager');
        }
	return T;
    }

    public.dismissgui := function() {
        wider private;
        if (is_agent(private.gui)) {
            private.gui.done();
        }
        private.gui := F;
        return T;
    }

    public.done := function() {
        wider private;
        wider public;
        public.dismissgui();
        val private := F;
        val public := F;
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
	wider private;
	wider public;
        # don't build one if we already have one or there is no display
        if (!is_agent(private.gui) && widgetset.have_gui()) {
            private.gui := dishsmoothgui(parent, itsdish,
                                           itsdish.logcommand,
                                           widgetset);
#            private.updateGUIstate();
            whenever private.gui->done do {
		wider private;
                if (is_record(private)) private.gui := F;
            }

        }
        return private.gui;
    }

    public.opmenuname := function() {return 'Smooth';}

    public.opfuncname := function() {return 'smooth';}

    public.setdecimate := function(tOrF=F) {
	wider private;
	private.decimate := tOrF;
        private.gui.setdecimate(tOrF);
	return T;
    }
  
    public.setboxwidth:=function(boxwidth) {
	wider private;
	private.boxwidth:=as_string(boxwidth);
	private.gui.setboxwidth(private.boxwidth);
	return T;
    }

    public.setgausswidth:=function(gausswidth,units=1) {
	wider private;
#	if (units=='channels') {
#		myunits:=1;
#	} else {
#		myunits:=2;
#	}
	private.gui.setGWUnits(units);
	private.gausswidth:=as_string(gausswidth);
	private.gui.setgausswidth(private.gausswidth);
	return T;
    }
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

    public.settype := function(type='HANNING') {
	wider private;
	if (type=='HANNING') {
		private.currType:=0;
		if (is_agent(private.gui)) {
			private.gui.settype(private.currType);
		}
	} else if (type=='BOXCAR') {
		private.currType:=1;
               	if (is_agent(private.gui)) {
			private.gui.settype(private.currType);
		}
	} else if (type=='GAUSSIAN') {
		private.currType:=2;
                if (is_agent(private.gui)) {
			private.gui.settype(private.currType);
                }
	}
     	return T;
    }

    private.hanning := function(sdrec, decimate)
    {
	wider private;
	if (!is_sdrecord(sdrec)) fail('The input data is not an sdrecord.');
	nin := sdrec.data.arr::shape[2];
	if (3 > nin) fail('There are fewer than 3 elements in the data array!');

	nstokes := sdrec.data.arr::shape[1];
	result := sdrec;
	# decimate to every 2nd channel
	n := 2;
	startAt := 1;
	if (decimate) {
	    nout := as_integer((nin-1)/n);
	    endAt := startAt + (nout-1)*n;
	    centerseq := seq(startAt+1,endAt+1,n);
	    left := 1;
	    right := nout;
	    inc := n;
	    result.data.desc.chan_freq.value:=result.data.desc.chan_freq.value[centerseq];
	    result.data.desc.chan_width *:= n;
	    result.header.resolution    *:= n;
	    result.data.sigma           /:= sqrt(n);
	    # keep them consistent in size
	    newflag:=array(F,sdrec.data.arr::shape[1],nout);
	    newweight:=array(1,sdrec.data.arr::shape[1],nout);
	    newsigma:=array(1,sdrec.data.arr::shape[1],nout);
	    for (i in 1:sdrec.data.arr::shape[1]) {
		newflag[i,]:=result.data.flag[i,centerseq];
		newweight[i,]:=result.data.weight[i,centerseq];
		newsigma[i,]:=result.data.sigma[i,centerseq];
	    }
	    result.data.flag:=newflag;
	    result.data.weight:=newweight;
	    result.data.sigma:=newsigma;
	} else {
	    nout := nin;
	    left := 2;
	    right := nin-1;
	    endAt := nin-2;
	    inc := 1;
	}
	    
	result.data.arr := array(0.0,nstokes,nout);
	thisarr := sdrec.data.arr;
	# set the local data copy to 0.0 where its flagged - in case of NaNs
	thisarr[as_boolean(sdrec.data.flag)]:=0.0;
	# this will be zero where the data is flagged
	inmask := as_float(!sdrec.data.flag);
	outcount := array(0.0,result.data.arr::shape[1],
			  result.data.arr::shape[2]);
	if (nin > 1) {
	    if (!decimate) {
		# the end points, when not decimating
		result.data.arr[,1] := (3.0*thisarr[,1]*inmask[,1] + thisarr[,2]*inmask[,2]);
		outcount[,1] := 3.0*inmask[,1]+inmask[,2];
		result.data.arr[,nin] := (thisarr[,(nin-1)]*inmask[,(nin-1)] + 
					  3.0*thisarr[,nin]*inmask[,nin]);
		outcount[,nin] := inmask[,(nin-1)]+3.0*inmask[,nin];
	    }
	    if (nin > 2) {
		thisseq := seq(startAt,endAt,inc);
		outindx := [left:right]
		result.data.arr[,outindx] := thisarr[,thisseq]*inmask[,thisseq];
		outcount[,outindx] := inmask[,thisseq];
		thisseq +:= 1;
		result.data.arr[,outindx] +:= 2.0*thisarr[,thisseq]*inmask[,thisseq];
		outcount[,outindx] +:= 2.0*inmask[,thisseq];
		thisseq +:= 1;
		result.data.arr[,outindx] +:= thisarr[,thisseq]*inmask[,thisseq];
		outcount[,outindx] +:= inmask[,thisseq];
	    }
	    # flag where outcount == 0
	    result.data.flag := outcount == 0;
	    # set the outcount == 0 to 1.0 to avoid nans in result
	    outcount[result.data.flag] := 1.0;
	    result.data.arr /:= outcount;
	}
	return result;
    }

    private.boxcar := function(sdrec, n, decimate)
    {
	if (!is_sdrecord(sdrec)) fail('The input data is not an sdrecord');
	nin := sdrec.data.arr::shape[2];
	if (n > nin) fail('The width of the boxcar is larger than the number of elements in the data array.');
	if (!is_integer(n)) n := as_integer(n+0.5);

	nstokes := sdrec.data.arr::shape[1];

	if (n == 1) return sdrec;

	result := sdrec;

	# center of the boxcar
	c := (n+1.0)/2.0

	# number of stokes cells
	nstokes := sdrec.data.arr::shape[1];

	# this will hold the running boxcar total - one per stokes
	tot := array(0.0,nstokes);

	# this will hold the running count of cells contributing to tot
	count := array(0.0,nstokes);

	# starting location for calculation - actual output values
	# aren't set until this is >= 1
	inloc := c-n+1;
	# next point to add, this iteration
	nextloc := 1;
	# last point added - to be removed this iteration
	lastloc := nextloc-n;

	isOdd := n%2 != 0;

	if (!isOdd) {
	    inloc -:= 0.5;
	    c +:= 0.5;
	}

	outshape := result.data.arr::shape;
	inc := 1;
	if (decimate) {
	    # location of first pixel used in decimation is c
	    outseq := seq(c,nin,n);
	    inc := n;
            result.data.desc.chan_freq.value:=result.data.desc.chan_freq.value[outseq];
	    result.data.desc.chan_width *:= n;
            result.header.resolution    *:= n;
	    result.data.sigma           /:= sqrt(n);
	    outshape[2] := len(outseq);
	    # reshape the flag and weights to the same as the output
	    # default to everything flagged - in case something goes wrong
	    newflag:=array(T,outshape[1],outshape[2]);
	    # the weights are not used yet - just set them to input values
            newweight:=array(1,outshape[1],outshape[2]);
	    newsigma:=array(1,outshape[1],outshape[2]);
            for (i in 1:outshape[1]) {
                newweight[i,]:=result.data.weight[i,outseq];
                newsigma[i,]:=result.data.sigma[i,outseq];
            }
	    result.data.flag:=newflag;
	    result.data.weight:=newweight;
	    result.data.sigma:=newsigma;
	}
	result.data.arr := array(0.0,outshape[1],outshape[2]);
	result.data.flag := array(T,outshape[1],outshape[2]);
	# get a local copy of the data
	thisarr := sdrec.data.arr;
	# set the data in this copy to 0.0 where it is flagged - in case of NaNs
	thisarr[sdrec.data.flag] := 0.0;
	# this will be zero where the data is flagged and 1 where it isn't
	inmask := as_float(!sdrec.data.flag);

	outloc := 1;

	# initial value into tot
	if (isOdd) {
	    tot := thisarr[,nextloc];
	    count := inmask[,nextloc];
	} else {
	    tot := thisarr[,nextloc]/2.0;
	    count := inmask[,nextloc]/2.0;
	}

	nextloc +:= 1;
	lastloc +:= 1;
	inloc +:= 1;

	while (outloc <= outshape[2]) {
	    if (nextloc <= nin) {
		if (isOdd) {
		    tot +:= thisarr[,nextloc];
		    count +:= inmask[,nextloc];
		    if (lastloc >= 1) {
			tot -:= thisarr[,lastloc];
			count -:= inmask[,lastloc];
		    }
		} else {
		    tot +:= thisarr[,nextloc-1]/2.;
		    count +:= inmask[,nextloc-1]/2.;
		    tot +:= thisarr[,nextloc]/2.0;
		    count +:= inmask[,nextloc]/2.0;
		    if (lastloc >= 1) {
			if (lastloc > 1) {
			    tot -:= thisarr[,lastloc-1]/2.0;
			    count -:= inmask[,lastloc-1]/2.0;
			}
			tot -:= thisarr[,lastloc]/2.0;
			count -:= inmask[,lastloc]/2.0;
		    }
		}
	    }
	    nextloc +:= 1;
	    lastloc +:= 1;
	    if ((!decimate && inloc>= 1) || (decimate && (inloc-c)%n == 0)) {
		result.data.flag[,outloc] := count == 0.0;
		result.data.arr[,outloc] := tot/count;
		outloc +:= 1;
	    }
	    inloc +:= 1;
	}
	    
	return result;
    }

    # fwhm is the full width at half max of the convolving gaussian
    # the integral of the gaussian is 1
    # the gaussian is only calculated out to extent multiples of
    # the gaussian's standard deviation
    # std. dev = FWHM / (sqrt(8*ln(2)))

    private.gaussian := function(sdrec, fwhm, extent=5)
    {
	wider private;
	if (!is_sdrecord(sdrec)) fail('The input data is not an sdrecord');
	if (is_boolean(private.fftserver)) private.fftserver := fftserver();
	# characterize the gaussian convolution
	stddev := fwhm / (sqrt(8.0*ln(2.0)));
	gxlimit := as_integer(extent*stddev+0.5);
	g := [-gxlimit:gxlimit] / stddev;
	g *:= g;
	g /:= -2.;
	g := exp(g);
	g /:= (stddev * sqrt(2. * pi));
	result := sdrec;
	result.data.sigma           /:= sqrt(fwhm);
	# convolution happens separately for each stokes
	for (i in 1:result.data.arr::shape[1]) {
	    startat := 1;
	    endat := len(result.data.arr[i,]);
	    if (any(result.data.flag[i,])) {
		# need to supply interpolated values for the flagged data
		indgood := ind(result.data.arr[i,])[!result.data.flag[i,]];
		if (len(indgood) < 1) {
		    fail(paste('all of the data is flagged for stokes ',
			       result.data.desc.corr_type[i],'- no valid data to smooth'));
		}
		# don't use interpolated values beyond the end
		startat := indgood[1];
		endat := indgood[len(indgood)];
		# if startat == endat - nothing more to do here
		if (startat != endat) {
		    if (is_boolean(private.intserver)) private.intserver := interpolate1d();
		    private.intserver.initialize(indgood,result.data.arr[i,indgood]);
		    indbad := ind(result.data.arr[i,])[result.data.flag[i,]];
		    result.data.arr[i,indbad] := private.intserver.interpolate(indbad);
		    # leave flags as they are
		}
		    
	    }
	    y := result.data.arr[i,[startat:endat]];
	    y := private.fftserver.convolve(y,g);
	    if (len(g) > len(y)) {
		# g is longer than the convolution function due to flagging or 
		# just due to the original size of the data array
		# just return the central portion of the result
		# the return vector is always of equal length to the input
		# vector - this may not be the most appropriate thing
		# to do
		# I believe this must always be an integer
		offset := (len(g) - len(y))/2;
		y := y[(1+offset):(len(y)+offset)];
	    }
	    result.data.arr[i,[startat:endat]] := y;
	    # flag stays the same
	}
	return result;
    }

##smooth     Description: Smooths (hanning, boxcar, gaussian) a profile.
##           Example:     smooth() # defaults to a HANNING on displayed
##                        smooth(type='BOXCAR',width=5) # does a 5
##                        # channel wide boxcar smooth
##                        smooth(type='GAUSSIAN',width=3) # does a 3
##                        # channel wide gaussian smooth
##           Returns:     T (if successful)
##           Produces:    a profile in the results manager (smoothN)
    public.dsmooth := function(scanrec=F,type='HANNING',width=3,units='channels',
			       decimate=F,plotIt=T) {
	wider private,public;
        if (is_boolean(scanrec)) {
	    scanrec:=private.dish.rm().getlastviewed().value;
	}

	if (is_sdrecord(scanrec)) {
	    ok:=public.setdecimate(decimate);
	    ok:=public.settype(type);
	    if (units=='channels') {
                myunits:=1;
	    } else {
                myunits:=2;
	    };
	    if (type=='BOXCAR') {
                ok:=public.setboxwidth(width);
	    } else if (type=='GAUSSIAN') {
                ok:=public.setgausswidth(width,myunits);
	    };
	    private.flag:='sdrecord';
	    ok:=private.dosmooth(scanrec,cli=T);
	    #        return private.getrecord(plotIt);
	    return ok;
	} else {
	    print 'ERROR: Bad SDRecord';
	    return F;
	};
	return F;
    }

	    
    return public;
}
