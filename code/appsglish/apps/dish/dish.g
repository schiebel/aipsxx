# dish.g: AIPS++ single-dish environment.
#------------------------------------------------------------------------------
#   Copyright (C) 1999,2000,2001,2002,2003
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#    $Id: dish.g,v 19.7 2006/09/06 19:23:13 bgarwood Exp $
#
#------------------------------------------------------------------------------

pragma include once;

include "aipsrc.g";
include "dishgui.g";
include "dish_itbrowser.g";
include "dishplot.g";
include "dishresman.g";
include "dparams.g";
include 'imageprofilesupport.g';
include 'logger.g'
include 'ms.g';
include "note.g";
include 'pgplotter.g';
include "plugins.g";
include "scripter.g";
include "sdaverager.g";
include "sditerator.g";
include "unset.g";
include "widgetserver.g";

# the dish closure

dish := function()
{
    private := [=];
    public := [=];

	ds.log('include \'dish.g\';');
        ds.log('d:=dish()');

#
#    private.unirec:=[=];
    public.unirec:=[=];
    private.feed:=F;

    wider public;
    btime := time();

    # This is an agent when the GUI is present and available
    private.gui := F;

    # this record will hold the operations closures
    private.ops := [=];
    private.tools:=[=];

    # required for toolmanager
#    public.toggui := function() {
#        ok:=public.gui();
#    return ok;
#    };

     private.workingset := F;
     private.filein:=F;
     private.fileout := F;
     private.wsname := F;
    private.subset := F;
    private.subsetScan := -1;
     private.sdutil:=sdutil();


    # the logging state - actually kept in the GUI when available
    private.dologging := F;

    # a function for browsing an sditerator
    private.browse_sditer := function(data, name)
    { 
	wider public;
	return sditbrowser(data,name,public.view_sdrec,
		rmpaste=public.rm().paste,itsdish=public);
    }

#  function to provide all scannumbers
   private.listscans := function() {
        wider private;
        if (is_sditerator(private.workingset)) {
           scannums:=private.workingset.getheadervector('scan_number')[1];
        } else {
	   print 'Bad/Unselected sditerator:Use filein and try again';
	   return F;
        };
        return scannums;
   }

#  function to help parse string vector specifications
   private.parsescanlist := function(scanstr) {
        wider private;
        scanstring:='';
        scans:=split(scanstr,',');
        for (i in 1:len(scans)) {
           if (len(split(scans[i],":"))==1&&i!=len(scans)) {
                scanstring:=spaste(scanstring,scans[i],',',scans[i],',');
           } else if (len(split(scans[i],":"))==1){
                scanstring:=spaste(scanstring,scans[i],',',scans[i]);
           } else if (len(split(scans[i],":"))==2&&i!=len(scans)) {
                a:=split(scans[i],'[');
                b:=split(a,']');
                c:=split(b,':');
                scanstring:=spaste(scanstring,c[1],',',c[2],',');
           } else {
                a:=split(scans[i],'[');
                b:=split(a,']');
                c:=split(b,':');
                scanstring:=spaste(scanstring,c[1],',',c[2]);
           }

        }
        scanstring:=spaste('[',scanstring,']');
        return scanstring;
   }

#  get the last variable in the results manager and return it
   private.getrecord := function() {
	wider private;
        sz:=private.rm.size();
        ok:=private.rm.select(sz);
        mysdr:=private.rm.getlastviewed();
        if (is_sdrecord(mysdr.value)) {
                return mysdr.value;
        } else {
		print 'FAIL: Not an SDRecord';	
		return F;
        }
   }

   #appends things to a list
   private.append := function(ref list,thing) {
        for (i in 1:len(thing)) {
            list[len(list)+i] := thing;
        }
        return T;
   }

#  get a vector of row numbers for an input vector of scan numbers and subscans
   private.getrowvector:=function(sn,ss) {
        wider private;
        locvec:=[];
        ws_scannums:=private.listscans();
        for (i in 1:len(sn)) {
                mask:=ws_scannums==sn[i];
                location:=(1:len(ws_scannums))[mask];
                maskss:=ind(ss)<=len(location);
                nss:=ss[maskss];
                nloc:=location[nss];
                locvec:=[locvec,nloc];
        }
        return locvec;
    }

    # the plotter will be found here, when necessary
    private.plotter := F;

    private.whenevers := [=];

    private.cleanupGUI := function()
    {
	wider private;
	if (!is_boolean(private.gui)) {
	    for (op in private.ops) {
		op.dismissgui();
	    }
	    for (tl in private.tools) {
		tl.dismissgui();
	    }
#	    private.dologging := private.gui.dologging();
	    private.gui.dismissgui();
	    private.gui := F;
	    deactivate private.whenevers.gui;
	}
    }

    # add an operation to this GUI given an include file and the name of
    # the constructor function for that operation.  The operation
    # constructor takes as its argument a reference to the public
    # part of dish.  It returns the operation closure which must
    # obey its own rules described elsewhere.
    const public.addop := function(includefile, ctorname)
    {
        wider public;
        wider private;
        global __newop__, __dish__;
        tmp := eval(paste('include',as_evalstr(includefile)));
        if (is_fail(tmp)) fail;
        if (is_boolean(tmp)&&!tmp)
            fail paste("Cannot include ",includefile);
        if (is_defined(ctorname) && is_function(symbol_value(ctorname))) {
            public.busy(T);
            # we must do things in the global name space here
            __dish__ := public;
            __newop__ := F;
            command := spaste('__newop__ := ',ctorname,'(__dish__)');
            ok := eval(command);
            if (is_fail(ok)) {
                public.busy(F);
                fail;
            }
            # sanity check
            if (!is_record(__newop__) || !private.verifyOp(__newop__)) {
                public.busy(F);
                fail(spaste(ctorname,' did not return a valid operation'));
            }
            # okay, add it in
            itsname := __newop__.opfuncname();
            private.ops[itsname] := __newop__;
            # remember the include file as part of the state info
            private.opsinfo[itsname] := [=];
            private.opsinfo[itsname].includefile := includefile;
            private.opsinfo[itsname].ctor := ctorname;
            # if we have a GUI already up, add this to it, default is unmapped
            if (is_agent(private.gui)) {
                itsgui := private.ops[itsname].gui(private.gui.opsframe(),
                                                   private.gui.widgetset());
                private.gui.newop(itsgui, private.ops[itsname].opmenuname(),F);
            } else {
                private.mapped[private.ops[itsname].opmenuname()] := F;
            }
            public.busy(F);
        }
    }

#   same for tools
    const public.addtool := function(includefile, ctorname)
    {
        wider public;
        wider private;
        global __newop__, __dish__;
        tmp := eval(paste('include',as_evalstr(includefile)));
        if (is_fail(tmp)) fail;
        if (is_boolean(tmp)&&!tmp)
            fail paste("Cannot include ",includefile);
        if (is_defined(ctorname) && is_function(symbol_value(ctorname))) {
            public.busy(T);
            # we must do things in the global name space here
            __dish__ := public;
            __newop__ := F;
            command := spaste('__newop__ := ',ctorname,'(__dish__)');
            ok := eval(command);
            if (is_fail(ok)) {
                public.busy(F);
                fail;
            }
            # sanity check
            if (!is_record(__newop__) || !private.verifyOp(__newop__)) {
                public.busy(F);
                fail(spaste(ctorname,' did not return a valid operation'));
            }
            # okay, add it in
            itsname := __newop__.opfuncname();
            private.tools[itsname] := __newop__;
            # remember the include file as part of the state info
            private.tlsinfo[itsname] := [=];
            private.tlsinfo[itsname].includefile := includefile;
            private.tlsinfo[itsname].ctor := ctorname;
            # if we have a GUI already up, add this to it, default is unmapped
            if (is_agent(private.gui)) {
                itsgui := private.tools[itsname].gui(private.gui.opsframe(),
                                                   private.gui.widgetset());
                private.gui.newtool(itsgui,private.tools[itsname].opmenuname(),F);
            } else {
                private.mapped[private.tools[itsname].opmenuname()] := F;
            }
            public.busy(F);
        }
    }

    const private.defaultops := function() {
        wider public;
        # add in the default operations
        public.addop('dishaverage.g','dishaverage');
        public.addop('dishbaseline.g','dishbaseline');
 	public.addop('dishcalculator.g','dishcalculator');
        public.addop('dishfunction.g','dishfunction');
#	public.addop('dishgauss.g','dishgauss');
	public.addop('dishregrid.g','dishregrid');
        public.addop('dishsave.g','dishsave');
        public.addop('dishselect.g','dishselect');
    	public.addop('dishsmooth.g','dishsmooth');
	public.addop('dishstat.g','dishstat');
	public.addop('dishwrite.g','dishwrite');
	public.addtool('dishmsplot.g','dishmsplot');
	public.addtool('dishimager.g','dishimager');
    }
#

#

# indicate that the gui is busy
    const public.busy := function(tOrF)
    {
        wider private;
        if (is_agent(private.gui)) {
            private.gui.busy(tOrF);
        }
    }

##clearrm    Description: Clear all variables from the results manager,
##                        clear plotter, reset to default state.
##           Example:     clearrm();
##           Returns:     T (if successful)
##           Produces:    NA
   public.clearrm := function() {
	wider public;
        ok:=public.restorestate(usedefault=T);
        return ok;
   }


# access all private members to help debug - comment this out!
#    public.debug := function() {wider private; return private;}

    # set whether this is logged or not when a GUI is present and used
    const public.dologging := function(torf) {
        wider private;
        if (is_boolean(torf)) {
            private.dologging := torf;
            if (is_agent(private.gui)) private.gui.dologging(torf);
        }
    }

##files      Description: Prints the currently set values for filein/out.
##           Example:     files();
##           Returns:     the values of filein and fileout
   public.files := function(quiet=F) {
        wider private;
	if (!quiet) {
		if (is_boolean(private.filein))
			filein := 'not set'
		else
			filein := private.filein
		if (is_boolean(private.fileout))
			fileout := 'not set'
		else
			fileout := private.fileout
        	print 'Current filein is  : ',filein;
        	print 'Current fileout is : ',fileout;
		return T
	}
        dumrec:=[=];
        dumrec.filein:=private.filein;
        dumrec.fileout:=private.fileout;
        return dumrec;
   }

##filein     Description: Sets the scan group that will be manipulated.
##           Example:     filein(dishdemo2);
##           Returns:     T (if successful);
##           Produces:    NA
##           Note:        The value given to filein should be a scan group
##                        variable present in the results manager or
##                        defined at the command line.
   public.filein := function(wsname) {
        wider private;
        if (is_string(wsname)) {
           private.wsname:=wsname;
           private.filein:=wsname;
           private.workingset := symbol_value(wsname);
	   # clear cache used by getscans
	   if (is_sditerator(private.subset)) private.subset.done();
	   private.subset := F;
	   private.subsetScan := -1;
	   if (!is_sditerator(private.workingset)) {
		dl.log(message='sditerator not found',priority='SEVERE',postcli=T);
		return F;
	   };
        } else {
	   dl.log(message='Not a valid sditerator',priority='SEVERE',postcli=T);
           return F;
        };
        return T;
   }

    #Function to do an sditerator unlock
    public.unlock := function() {
  	wider public;
   	#retrieve name of active sditerator
   	#technique to avoid sticky table locking issues
   	rmname:=eval(public.files(T).filein)
   	ok:=rmname.unlock();
	return ok;
    };

    public.lock := function() {
        wider public;
        #retrieve name of active sditerator
        #technique to avoid sticky table locking issues
        rmname:=eval(public.files(T).filein)
        ok:=rmname.lock(0);
        return ok;
    };

   public.gauss := function(ngauss,guess=F,prompt=F,pol=1,bchan=F,echan=F,plotfit=T,plotresid=F,ploteach=F,ret=F) {
	wider private,public;
	include 'image.g';
	if (ngauss>10) {
		dl.log(message='10 gaussians max',priority='SEVERE',postcli=T)
		return F
		}
	p3 := array(0,10,2)
	p4 := array(0,10,2)
	lv:=public.rm().getlastviewed().value;
	est         := [=];
	est.xabs    := public.plotter.ips.getisabs();
	est.xunit   := public.plotter.ips.getabcissaunit();
    	if (est.xunit == 'pix' || est.xunit == 'index') {
		dl.log(message='gauss function does not currently handle pixels',priority='SEVERE',postcli=T)
		dl.log(message='choose another unit on the plotter',priority='SEVERE',postcli=T)
		return F;
	};

	if (is_boolean(bchan)) bchan := 1
	if (is_boolean(echan)) echan := lv.data.arr::shape[2]
	if (prompt) {
		dl.log(message='Follow instructions on the plotter\'s message line for entering',priority='NORMAL',postcli=T)
		dl.log(message='restrictions and initial guesses for the fits.',priority='NORMAL',postcli=T)
		d.plotter.message('click on the left of the range to be fit')
		p1 := public.plotter.ips.getx()
		d.plotter.message('click on the right of the range to be fit')
		p2 := public.plotter.ips.getx()
		for (i in 1:ngauss) {
			d.plotter.message(spaste('click on the estimated peak of gaussian ',i))
			p3[i,] := public.plotter.ips.getxy()
			d.plotter.message(spaste('click on the estimated half-width of gaussian ',i))
			p4[i,] := public.plotter.ips.getxy()
			}
		d.plotter.message('')
		}
	est.yunit   := public.plotter.ips.getordinateunit();
	est.doppler := public.plotter.ips.getdoppler();
	
	sddata := public.plotter.ips.getordinate(pol).data;
	mycsys   := coordsys(spectral=T);
	currx  := public.plotter.ips.getcurrentabcissa();
	xaxis  := dq.quantity(currx, est.xunit);

	#restfreq:=dq.quantity(sddata.data.desc.reffrequency,'Hz');
	restfreq:=public.rm().getlastviewed().value.data.desc.restfrequency;
	if (est.xunit ~ m/m/ ) {
#   	   ok:=mycsys.setspectral(velocities=xaxis,restfreq=restfreq,
#		refcode=lv.data.desc.refframe,doppler=lv.header.veldef);
   	   ok:=mycsys.setspectral(velocities=xaxis,restfreq=restfreq,
		refcode=public.plotter.ips.getrefframe(),
		doppler=public.plotter.ips.getdoppler());
	   if (is_fail(ok)) fail;
	} else {
#   	   ok:=mycsys.setspectral(frequencies=xaxis,restfreq=restfreq,
#		refcode=lv.data.desc.refframe,doppler=lv.header.veldef);
   	   ok:=mycsys.setspectral(frequencies=xaxis,restfreq=restfreq,
		refcode=public.plotter.ips.getrefframe(),
		doppler=public.plotter.ips.getdoppler());
	   if (is_fail(ok)) fail;
	};
	if (prompt) {
	  if (currx[1]>currx[2]) {
	    firstpix := ind(currx)[currx==currx[p1>currx][1]]
	    lastpix  := ind(currx)[currx==currx[p2>currx][1]]
	    }
	  else {
	     firstpix := ind(currx)[currx==currx[p1<currx][1]]
	     lastpix  := ind(currx)[currx==currx[p2<currx][1]]
	    }
	 bchan := sort([firstpix,lastpix])[1]
	 echan := sort([firstpix,lastpix])[2]
	 }
	myim:=imagefromarray(pixels=sddata,csys=mycsys);
        if (is_fail(myim)) fail;

	regn := drm.box(bchan,echan)
	est1 := myim.fitprofile(vals,resid,fit=F,ngauss=ngauss,estimate=est,axis=1,region=regn);
	if (is_fail(est1)) fail;
	if (len(est1.elements)<1) {
		dl.log(message='gauss failed.',priority='SEVERE',postcli=T)
		return F
		}

	if (!is_boolean(guess)) {
	   for (i in 1:ngauss) {
		est1.elements[i].parameters:=guess[i,];
	   }
	}
	if (prompt)
		for (i in 1:ngauss) {
			est1.elements[i].parameters[1] := p3[i,2]
			est1.elements[i].parameters[2] := p3[i,1]
			est1.elements[i].parameters[3] := 2*abs(p3[i,1]-p4[i,1])
		}
	#est1.elements[i].parameters -> vector of: [height, center, width];

	fit := myim.fitprofile(vals,resid,fit=T,ngauss=ngauss,estimate=est1,axis=1,region=regn);
	if (is_fail(fit)) fail;

	ysum := 0
	retval := [=]
	for (i in 1:len(fit.elements)) {
	        print 'Gauss: ',i
		params:=fit.elements[i].parameters
	        errors:=fit.elements[i].errors;
		retval.h[i] := params[1]
		retval.c[i] := params[2]
		retval.w[i] := params[3]
		retval.herr[i] := errors[1]
		retval.cerr[i] := errors[2]
		retval.werr[i] := errors[3]
		if (any(params<0.0001) || any(errors<0.0001)) {
	                printf('Center: %-8.6e   Height: %-8.6e    Width: %-8.6e\n', params[2],params[1],params[3]);
	                printf('C-err : %-8.6e   H-err : %-8.6e    W-err: %-8.6e\n', errors[2],errors[1],errors[3]);
			}
		else {
	                printf('Center: %16.6f   Height: %16.6f    Width: %16.6f\n', params[2],params[1],params[3]);
	                printf('C-err : %16.6f   H-err : %16.6f    W-err: %16.6f\n', errors[2],errors[1],errors[3]);
			}
		ysum +:= params[1]*exp(-4*ln(2)*((currx-params[2])/params[3])^2)
		if (ploteach)
		  public.plotter.plotxy(currx,params[1]*exp(-4*ln(2)*((currx-params[2])/params[3])^2),newplot=F,linecolor=11,plotlines=T)
	};
	residual := sddata-ysum
	if (plotresid)
		public.plotter.plotxy(currx,residual,newplot=F,linecolor=1,plotlines=T)
	public.plotter.plotxy(currx,sddata,newplot=F,linecolor=1+pol,plotlines=T)
	if (plotfit)
		public.plotter.plotxy(currx,ysum,newplot=F,linecolor=15,plotlines=T)
	mycsys.done();
	myim.done();
	if (ret)
		return retval
	else
		return T;
   }


   public.wsname := function(){return private.wsname;};

#  General find utility.
##find       Description: Find any variables that match foo
##           Example:     find("smo");
##           Returns:     Any matching values
   public.find := function(myfoo="") {
        wider private;
        global x_sn:=symbol_names();
        tmp:=spaste('x_sn[x_sn ~ m/',myfoo,'/ ]');
        return eval(tmp);
   }


    const public.doselect := function() {
	wider private;
	if (is_agent(private.gui)) {
	    if (is_boolean(private.gui.select())) {
		return private.gui.select();
	    }
	}
    }

# close down everything
    const public.done := function()
    {
        wider private;
        wider public;
	dl.log(message='dish is exiting.',priority='NORMAL',postcli=T);
	if (is_agent(private.gui)){
	    if (private.gui.savewhendone()) {
		public.savestate();
	    }
	}
        if (is_agent(private.gui)) {
            private.gui.dismissgui();
	    public.plotter.done();
        }
        private.gui := F;

	private.rm.done();

        for (field in field_names(private.ops)) {
            if (has_field(private.ops[field], "done")) {
                private.ops[field].done();
	    }

        }
        for (field in field_names(private.tools)) {
            if (has_field(private.tools[field], "done"))
                private.tools[field].done();

        }
        private.ops := [=];
	private.tools:=[=];
	# clear any privately opened sditerators
	if (is_sditerator(private.subset)) private.subset.done();
	val private := F;
	val public := F;
	return T;
    }

    # unmap the GUI
    const public.nogui := function() {
	wider private;
	private.gui.frame->unmap();
	return T;
    }

    # private function which creates the cached selection on the
    # given scan number.  If there is a problem, an error message
    # is returned in errmsg and the return value is F. The subset
    # will not be recreated unless the force argument is T or
    # the scan number of the subset (private.subsetScan) is not
    # equal to the scannum argument value, which must have a single
    # element.
    private.createSubset := function(scannum, force, ref errmsg) {
	wider private;
	val errmsg := "";
	result := T;
	if (len(scannum) != 1) {
	    val errmsg := 'scannum must only contain a single scan number';
	    result := F;
	} else {
	    if (!is_sditerator(private.workingset)) {
		val errmsg := paste('Failed to acquire scan -- Make sure you',
				    'have run filein(scangroup) on your observations');
		result := F;
	    } else {
		# can we reuse this subset
		if (force || !is_sditerator(private.subset) || 
		    private.subsetScan != scannum) {
		    # close any open subsets
		    if (is_sditerator(private.subset)) private.subset.done();
		    # reset subsetScan to default, incase setting subset fails
		    private.subsetScan := -1;
		    private.subset := 
			private.workingset.select([header=[scan_number=[scannum,scannum]]]);
		    if (is_fail(private.subset)) {
			val errmsg := 'Failed to acquire scan';
			result := F;
		    } else if (private.subset.length() == 0) {
			val errmsg := 'Length is 0';
			result := F;
		    }
		    # okay, the subscan is set and has non-zero length, 
		    private.subsetScan := scannum;
		}
	    }
	}
	return result;
    }

##getscan    Description: Retrieves the indicated profile (subscan) of the selected scan
##                        number from the current scan group.  The subscan defaults to 1,
##                        the first profile.  Set resync to T (true) if the data in filein
##                        for this scan number has new subscans since the last call to 
##                        to this function.
##           Example:     myspec:=getscan(1);
##           Returns:     a profile (in the example, myspec is the profile)
##           Produces:    a profile
    const public.getscan := function(scannum,subscan=1,resync=F,setgs=T) {
        wider private;
	if (!private.createSubset(scannum, resync, errmsg)) {
	    dl.log(message=errmsg, priority='WARN',postcli=T);
	    return F;
	}
	if (subscan < 1) {
	    dl.log(message='subscan must be > 0', priority='WARN',postcli=T);
	    return F;
	}
	if (subscan > private.subset.length()) {
	    dl.log(message=paste('subscan is too large.  There are only', 
		       private.subset.length(),'subscans in scan',scannum),
		 priority='WARN',postcli=T);
	    return F;
	}
	ok := private.subset.setlocation(subscan);
	if (!ok) {
	    dl.log(message='Failed to acquire subscan - this should never happen',
		 priority='SEVERE',postcli=T);
	    return F;
	}
	result := private.subset.get();
	if (is_fail(result)) {
	    dl.log(message='Failed to acquire subscan - this should never happen',
		 priority='SEVERE',postcli=T);
	    return F;
	}
	if (setgs) public.uniput('globalscan1',result);
	return result;
    }

    # return the number of subscans associated with the indicated scan number.
    # if resync is T, the selection on scan number will always happen.
    const public.nsubscans := function(scannum, resync=F) {
	if (!private.createSubset(scannum, resync, errmsg)) {
	    dl.log(message=errmsg,priority='WARN');
	    return F;
	}
	return private.subset.length();
    }

   const public.setfeed := function(feednum=1) {
        wider private;
        private.feed:=feednum;
        return T;
   }

   const public.getfeed := function() {
        wider private;
        return private.feed;
   };



    # fire up the GUI
    const public.gui := function(parent=F, widgetset=dws)
    {
        wider private;
        wider public;
	if (is_agent(private.gui)) {
	    private.gui.frame->map();
	};
        if (!is_agent(private.gui)) {
            tk_hold();
            private.gui := dishgui(parent, widgetset, __dish__);
            private.gui.dologging(private.dologging);

            # watch for events here
            whenever private.gui->["killed done"] do {
                private.cleanupGUI();
            }
            whenever private.gui->addoper do {
                public.addop($value.file, $value.ctor);
            }
            whenever private.gui->open do {
                access := $value.access;
                new := $value.new;
                file := $value.file;
                ok := public.open(file, access, new);
                # log it
                if (is_string(ok)) {
                    private.gui.logcommand('dish.open',
                          [fullPathname=file, access=access, new=new]);
                }
            }
            whenever private.gui->map do {
                private.mapped[$value.op] := $value.mapped;
            }

            private.whenevers.gui := last_whenever_executed();
            # add the results manager to its frame
            private.rm.gui(private.gui.rmframe(),
                           watchedagent=private.gui,
                           widgetset=widgetset);
            # add any existing ops to its frame
            for (op in private.ops) {
                if (has_field(op, 'gui')) {
                    itsgui := op.gui(private.gui.opsframe(),
                                     private.gui.widgetset());
                    private.gui.newop(itsgui, op.opmenuname(),
                                      private.mapped[op.opmenuname()]);
                }
            }
	    for (tl in private.tools) {
                if (has_field(tl, 'gui')) {
                    itsgui := tl.gui(private.gui.opsframe(),
                                     private.gui.widgetset());
                    private.gui.newtool(itsgui, tl.opmenuname(),
                                      private.mapped[tl.opmenuname()]);
                }
            }
            tk_release();
        }
    }

    #method for simplified help at the command line
    const public.help := function(dishfn=F,driveweb=F) {
           if (is_string(dishfn)) {
              fullstring:=spaste('dish.dish.dish.',dishfn,'.function');
                print fullstring;
           } else {
	      dl.log(message='ERROR: You must specify a command as a string',
		priority='WARNING',postcli=T);
	      dl.log(message='       e.g., d.help("calib")',priority='WARNING',
		postcli=T);
              return F;
           };
           print help(fullstring);
           if (driveweb) web();
           return T;
};

    #method is the name of function and data are arguments
    const public.history := function(method,data=[=]) {
	wider private;

#	if (is_defined('tm')) {

#        currtools:=tm.tools();
#        for (i in 1:len(currtools)) {
#                currtypes[i] := currtools[i].type;
#        }
#        if (any(currtypes=='dish')) {
#                private.toolname:=field_names(currtools)[currtypes=='dish'][1];
#        } else {
               private.toolname:='mytool';
#                return F;
#        }
    # replace prefab 'dish' with real toolname
        tmp:=split(method,'.');
        method:=as_string(private.toolname);
        if (len(tmp)>1) {
                for (i in 2:len(tmp)) {
                        method:=spaste(method,'.',tmp[i]);
                }
        }

	#} else { 
	method:='mytool';
	#}
#	print 'is it a record ',is_record(data);

        if (is_string(method) && is_record(data)) {
            command := spaste(method,'(');
            first := T;
            hasReturn := F;
            for (field in field_names(data)) {
                if (field == 'return' && is_string(data[field])) {
                    command := spaste(data[field],' := ',command);
                    hasReturn := T;
                } else {
                    if (!first) {
                        command := spaste(command,',');
                    }
                    command := spaste(command, field,'=');
                    if (len(data[field]) == 0) {
                        command := spaste(command,'[]');
                    } else {
                        command := spaste(command, as_evalstr(data[field]));
                    }
                    first := F;
                }
            }
            command := spaste(command,')');
            if (!hasReturn) {
                command := spaste('ok := ',command);
            }
	    return command;
        }
    } # end history

##history  Description: Adds a string/vector of strings to a record's history.
##           Example:     history(myrec,'1.5*(on-off)/off');
##           Returns:     T (if successful)
##           Produces:    appends the string to the profiles history
   public.dhistory := function(ref scanrec,hist_info) {
        wider private;
        private.append(scanrec.hist,hist_info);
   }


##           Produces:    NA
   public.info := function() {
	wider public;
#        if (!brief) {
#                aipspath:=split(environ.AIPSPATH)[1];
#                temp:=spaste('grep \"##\" ',aipspath,
#			'/code/trial/apps/dish/dish.g');
#                #temp:=spaste('grep \"##\" ','dishcli.g');
#                info:=shell(spaste(temp,"|grep -v spaste"));
#                printf('%40s\n',info);
#                return T;
#        } else {
#                aipspath:=split(environ.AIPSPATH)[1];
#                temp:=spaste('grep "##" ',aipspath,
#			'/code/trial/apps/dish/dish.g');
#                #temp:=spaste('grep \"##\" ','dishcli.g');
#                temp2:=spaste(temp,'|grep "Desc"');
#                info:=shell(temp2);
#                printf('%40s\n',info);
#                return T;
#        }
#        return F;
	commands:=field_names(public);
	scommands:=sort(commands);
	scommands:=scommands[scommands!='addop' & scommands!='addtool' & 
		scommands!='debug' & scommands!='type' & scommands!='tools']
	scommands:=scommands[scommands!='view_sdrec' & scommands!='doselect']
#	printf('%15s\t',scommands);

        maximum := 0
        for (i in scommands)
         if ((strlen(i)+1)>maximum) maximum := strlen(i)+1
        ncols := min(as_integer(80/maximum),len(scommands))
        nrows := as_integer((len(scommands)-1)/ncols) + 1
        strformat := spaste('%-',maximum,'s')
        if (len(scommands)!=nrows*ncols) {
         for (i in (len(scommands)+1):nrows*ncols)
           scommands[i] := ' '
         }
        for (i in 1:nrows) {
         for (j in 1:ncols)
          printf(strformat,scommands[(j-1)*nrows+i])
         printf('\n')
         } 
    return T
    }

##listscans  Description: List scans from the active scan group
##           Example:     listscans();
##                        [1 2]
##           Returns:     a list of scans
##           Produces:    a vector of scan numbers
   public.listscans := function() {
        wider private;
        if (is_sditerator(private.workingset)) {
#          dl.note(private.workingset.getheadervector('scan_number')[1]);
           scannums:=private.workingset.getheadervector('scan_number')[1];
        } else {
	   dl.log(message='Bad/Unselected sditerator: Use filein and try again',priority='SEVERE',postcli=T)
	   return F;
        };
        return unique(scannums);
   }


    # method is the name of function to log
    # data are the arguments, by name
    # if there is an argument named "return" which is
    # a non-zero length string, then that string is used
    # as the lh side of the full command, if no return
    # is specified, "ok" is assumed.
	#8/29/00 - why not just make this call the history!
    const public.logcommand := function(method, data=[=]) {
	wider private;
	# just forward it to the GUI, if available
	if (is_agent(private.gui))
	    private.gui.logcommand(method, data);
    }

    # send a message to the GUI status line when the GUI is
    # present
    const public.message := function(msg)
    {
        wider private;
        if (is_agent(private.gui)) {
                private.gui->post(msg)
        }
	return T;
    }

##mult       Description: Scales (multiplies) a profile by a factor.
##           Example:     From the getscan example above:
##                        mult(dum,2.0);
##           Returns:     T (if successful)
##           Produces:    a profile in the results manager (applyfuncN)
   public.mult := function(factor,scanrec=F) {
     wider private;
	ops:=ref private.ops;
        if (is_boolean(scanrec)) {
                scanrec:=private.rm.getlastviewed().value;
        }
     if (is_sdrecord(scanrec)) {
        temp:=spaste('ARR*',factor);
#        ok:=private.ops().function.setfn(temp);
#        ok:=private.ops().function.apply(scanrec);
        ok:=ops.function.setfn(temp);
        ok:=ops.function.apply(scanrec);

        return private.getrecord();
     } else {
	print 'FAIL: Bad SDRecord';
	return F;
     };
     return F;
   }

    const public.news := function () {
	wider public;
	print '---------------------------------------------------';
	print 'Added support for observing modes: '
	print 'Procedure  	Switch State	Switch Signal'
	print '    TRACK:	NONE:		TPWCAL'
	print '    TRACK:	FSWITCH:	FSW12'
	print ' ';
	print 'Added calibration routine:'
	print '    SRcal(sigscans,refscans,...): '
	print '       Performs (S-R)/R, where R is a vector of ';
	print '       reference scans which are averaged and'
	print '       then applied to each signal scan';
	print '---------------------------------------------------';
	return T;
   };

# open a file from the command line
##open       Description: Opens a scangroup on disk; loads into results
##                        manager. Available as a global variable with all
##                        the associated functionality of a scangroup
##                        (e.g. field_names(scangroup))
##           Example:     d.open('dishdemo2');
##           Returns:     T (if successful)
##           Produces:    a variable in the results manager named for the
##                        opened file.
##           Note:        the file name should exist on disk in the specified
##                        directory.
    public.open := function (fullPathname, access='r', new=F, corrdata=T,
			filein=T) {
        wider private,public;
	if (is_boolean(access) && access==T) access:='r';
	if (!is_string(fullPathname)) {
		print 'ERROR: Not a valid pathname, MS';
		return F;
	};
        if (is_string(fullPathname) && strlen (fullPathname) > 0) {
            public.busy(T);
            splitLongFilename := split (fullPathname,'/');
            shortname := splitLongFilename [len (splitLongFilename)];
            workingSet := F;
            readOnly := T;
            isNew := F;
	    reallyOpened := T;
            if (new) {
                isNew := T;
                readOnly := F;
# verify that this is a new file, stat will return an empty record
                if (len(stat(fullPathname)) != 0) {
                    dl.log(message=paste('Could not open',fullPathname,
                               'as a new working set - file exists.'),
                         priority='SEVERE', postcli=T,
                         origin=spaste('dish.open(',fullPathName,',',
                                       access,',',new,')'));
                    public.busy(F);
                    return F;
                }
                workingSet := newsditerator(fullPathname);
		ok:=workingSet.flush();
		ok:=workingSet.unlock();
            } else {
                if (as_string(access) ~ m/.*w.*/) {
                    readOnly := F;
                }
		# only open this if an existing sditerator of the same
		# name isn't already opened
		if (public.rm().size() > 0) {
		    for (i in 1:public.rm().size()) {
			if (is_sditerator(public.rm().getvalues(i)) &&
			    public.rm().getvalues(i).name() == fullPathname) {
			    reallyOpened := F;
			    workingSet := public.rm().getvalues(i);
			    actualName := public.rm().getnames(i);
			    workingSet.resync();
			    actualLoc := i;
			    break;
			}
		    }
		}
		if (reallyOpened) {
		    # it hasn't been opened yet, do it here
		    workingSet := sditerator (fullPathname, 
					      readonly=readOnly,correcteddata=corrdata);
		}
            }
            if (is_fail(workingSet) || !is_sditerator(workingSet)) {
                dl.log(message=paste('Could not open',fullPathname,'as a working set'),
                     priority='SEVERE', postcli=T,
                     origin=spaste('dish.open(',fullPathName,',',access,',',
                                   new,')'));
                public.busy(F);
                return F;
            }
	    if (reallyOpened) {
		numberOfRecords := workingSet.length ();
		description :=  spaste ('SD dataset from file');
		decorate := F;
		if (public.rm().size()>=1) {
		    if (any(public.rm().getnames(1:public.rm().size())==shortname)) 
			decorate := T;
		};
		actualName := public.rm().add (shortname, description,
					       workingSet, 'SDITERATOR',
					       decorate=decorate);
 
		actualLoc:=public.rm().size();
	    }
	    myws:=public.rm().getnames(actualLoc);
	    private.wsname:=myws;
	    if (!new) {
                ok:=public.ops().select.newworkingset(actualName, workingSet);
            }
            public.busy(F);
	    if (is_agent(private.gui)) {
               private.gui.logcommand('dish.open',
                          [fullPathname=fullPathname, access=access, new=new]);
	    }
        }
	if (filein) {ok:=public.filein(private.wsname)};
        private.wsname:=myws;

	return T;
    }


# close a scangroup from the command line
##close      Description: Closes an already open scangroup on disk; clears it
##                        from the results manager.  It also clears any
##                        internally cached information associated with that
##                        scangroup.
##           Example:     d.close('dishdemo2');
##           Returns:     T (if successful)
##           Produces:    the global variable dishdemo2 will be made unusable
##                        as a scangroup.
##           Note:        The scangroup should be the string that this is
##                        known by in the results manager.
    public.close := function (scangroup) {
        wider private,public;
	if (!is_string(scangroup)) {
	    print 'ERROR: please supply the name of a scangroup to close.';
	    return F;
	};
	# open does two things
	# it puts the opened sditerator into the results manager and, if
	# filein is T, it sets filein to the name of that WS.
	# So, close here must first find this scangroup in the results manager
	# and then it needs to check if that is also the current filein.
	# If so, it needs to turn it off as filein and close any
	# cached internal subset that might be associated with it.
	# find this one in the results manager
	deleted := F;
	if (!is_boolean(scangroup)) {
	    ok:=d.rm().selectbyname(scangroup);
	    delind:=d.rm().getselectind();
	    if (!is_boolean(delind)) {
		ok:=d.rm().delete(d.rm().getselectind());
		deleted := T;
	    };
	};
	if (!deleted) {
	    print 'ERROR: ', scangroup, ' could not be found in the results manager.';
	} else {
	    if (!is_boolean(private.filein) && private.filein == scangroup) {
		private.filein := F;
		if (is_sditerator(private.subset)) {
		    private.subset.done();
		    private.subset := F;
		    private.subsetScan := -1;
		    private.workingset := F;
		    private.wsname := F;
		}
	    }
	}
	
	return deleted;
    }


    # return the operation closures
    # this returns a record with one field for each operation, by name
    const public.ops := function()
    {
        wider private;
# try to limit some of the public names space and get rid of public funcs
# we don't want them using;
	tempops:=private.ops;
	for (i in 1:len(field_names(tempops))) {
	tempops[i]:=tempops[i][field_names(tempops[i])!='dismissgui'];
	tempops[i]:=tempops[i][field_names(tempops[i])!='gui'];
#	tempops[i]:=tempops[i][field_names(tempops[i])!='opfuncname'];
#	tempops[i]:=tempops[i][field_names(tempops[i])!='opmenuname'];
#	tempops[i]:=tempops[i][field_names(tempops[i])!='getstate'];
#	tempops[i]:=tempops[i][field_names(tempops[i])!='setstate'];
	}
        return tempops
    }
    const public.tools := function()
    {
	temptools:=private.tools;
	for (i in 1:len(field_names(temptools))) {
	temptools[i]:=temptools[i][field_names(temptools[i])!='dismissgui'];
	temptools[i]:=temptools[i][field_names(temptools[i])!='gui'];
	temptools[i]:=temptools[i][field_names(temptools[i])!='opfuncname'];
	}
	return temptools;
    }

    private.verifyOp := function(op) {
	# checks for the required fields
	result := is_record(op);
	reqd := "opmenuname opfuncname gui dismissgui getstate setstate done";
	opt := "apply";
	for (field in reqd) {
	    result := result && has_field(op, field);
	    result := result && is_function(op[field]);
	}
	for (field in opt) {
	    if (has_field(op,field)) {
		result := result && is_function(op[field]);
	    }
	}
	return result;
    }

    # return the plotter
    private.plotter := function() {
    	wider private,public;
	return dishpgplotter(itsdish=public);
    };

    # return the results manager
    const public.rm := function()
    {
        wider public,private;
        return private.rm;
    }

const public.header := function() {
	wider public;
#        g:=public.rm().getlastviewed().value;
	g:=public.uniget('globalscan1');
        if (!is_sdrecord(g)) {
           print 'No data in memory'
           return F
        }
 scanstats:=public.qscan(g.header.scan_number);
 dq.setformat('long','hms')
 dq.setformat('lat','dms')
 printf('Proj : %-18.18s Src  : %-15.15s    Proc : %-15s\n',
  g.other.gbt_go.PROJID,
  g.other.gbt_go.OBJECT,
  g.other.gbt_go.PROCNAME)
 printf('Obs  : %-18.18s RA   : %-15s    PType: %-15s\n',
  g.other.gbt_go.OBSERVER,
  dm.dirshow(g.header.direction)[1],
  g.other.gbt_go.PROCTYPE)
 printf('Scan : %-15d    Dec  : %-15s    OType: %-15s\n',
  g.other.gbt_go.SCAN,
  dm.dirshow(g.header.direction)[2],
  g.other.gbt_go.OBSTYPE)
 printf('Seq  : %-15s    Epoch: %-15s    Swtch: %-15s\n',
  spaste(g.other.gbt_go.PROCSEQN,'/',g.other.gbt_go.PROCSIZE),
  dm.dirshow(g.header.direction)[3],
  g.other.gbt_go.SWSTATE)
 dateStr := dq.time(dm.getvalue(dm.measure(g.header.time, 'utc'))[1],form='ymd')
 dateStr =~ s/\/+/$$/g
 printf('Date : %-15s    Az   : %-15.3f    Swsig: %-15s\n',
  spaste(dateStr[1],'-',dateStr[2],'-',dateStr[3]),
  g.header.azel.m0.value*180/pi,
  g.other.gbt_go.SWTCHSIG)
 printf('Time : %-12s UT    El   : %-15.3f    Ints : %-15d\n',
  dq.time(dm.getvalue(dm.measure(g.header.time, 'utc'))[1]),
  g.header.azel.m1.value*180/pi,
  scanstats.ints)
 printf('\n')
 printf('Tsys : %-15s    Trx  : %-15s    Tcal : %-15s\n',
  sprintf('%-6.2f',g.header.tsys),
  sprintf('%-6.2f',g.header.trx),
  sprintf('%-6.2f',g.header.tcal))
 printf('\n')
 printf('BW   : %-8.3f (MHz)     Res  : %-8.3f (kHz)\n',
  abs(g.header.bandwidth)/1e6,
  abs(g.header.resolution)/1e3)
 printf('Expos: %-15.3f    Durat: %-15.3f\n',
  g.header.exposure,
  g.header.duration)
 return T
}

##plotcom    Description: Performs a PGPLOT function
##           Example:     plotcom('mtxt',T,0,0,0,"This is a note");
##           Returns:     T (if successful)
   public.plotcom := function(command, ...) {
        wider private,public;
        ok:=public.plotter.plotter_command(command, ...);
   };

# Function to strip out a single polarization from multi-polarization data
  public.getpol := function(tmprec,pol) {
      wider private;
      avgrec:=tmprec;
      avgrec.data.arr:=array(as_float(0.0),1,tmprec.data.arr::shape[2]);
      avgrec.data.flag:=array(F,1,tmprec.data.arr::shape[2]);
      avgrec.data.weight:=array(as_float(0.0),1,tmprec.data.arr::shape[2]);
      avgrec.data.sigma:=array(as_float(0.0),1,tmprec.data.arr::shape[2]);
      avgrec.data.arr[1,]:=tmprec.data.arr[pol,];
      avgrec.data.flag[1,]:=tmprec.data.flag[pol,];
      avgrec.data.weight[1,]:=tmprec.data.weight[pol,];
      avgrec.data.sigma[1,]:=tmprec.data.sigma[pol,];
      avgrec.data.desc.corr_type:=tmprec.data.desc.corr_type[pol];
      avgrec.header.tsys:=tmprec.header.tsys[pol];
      avgrec.header.trx:=tmprec.header.trx[pol];
      avgrec.header.tcal:=tmprec.header.tcal[pol];
      ## ensure that these last 4 are seen as vectors
      avgrec.data.desc.corr_type::shape := 1;
      avgrec.header.tsys::shape := 1;
      avgrec.header.trx::shape := 1;
      avgrec.header.tcal::shape :=1;
      return avgrec;
  };

##plotscan   Description: Plots a profile.
##           Example:     From the getscan example above:
##                        plotscan(myspec);
##           Returns:     T (if successful)
##           Produces:    A plot on the DISH plotter.
   public.plotscan := function(scanrec,overlay=F,pol=F) {
        wider private,public;
        if (is_sdrecord(scanrec)) {
           xvec:=scanrec.data.desc.chan_freq.value;
#          yvec:=scanrec.data.arr[1,];
           yvec:=scanrec.data.arr;
           name:='';
           object:=scanrec.header.source_name;
           xlabel:=scanrec.data.desc.chan_freq.unit;
           ylabel:='';
           overlay:=overlay;
           # need to make into an appropriate RM variable
           # set this as the last viewed item
           temp:=[=];
           temp.name:=object;
           temp.value:=scanrec;
           temp.description:='manually plotted scan';
	   if (!is_boolean(pol)) temp.value:=public.getpol(temp.value,pol);
           private.rm.setlastviewed(temp);
#
	   public.uniput('globalscan1',temp.value);
           public.plotter.plotrec(temp.value,overlay=overlay);
#
           return T;
        } else {
	   print 'ERROR: Bad Record';
	   return F;
        };
    }

##plotxy     Description: Plots two vectors in the DISH plotter.
##           Example:     x:=1:100; y:=sin(x); plotxy(x,y);
##           Returns:     T (if successful)
##           Produces:    A plot on the DISH plotter.
   public.plotxy := function(xarray,yarray,newplot=T) {
	wider public;
	myci:=public.plotter.qci();
        public.plotter.plotxy(xarray,yarray,T,newplot,linecolor=myci);
        return T;
   }

##range
   public.range := function(xmin=F,xmax=F,ymin=F,ymax=F){
	wider public,private;
	private.oldrange:=public.plotter.qwin();
	if (is_boolean(xmin)) xmin:=private.oldrange[1];
	if (is_boolean(xmax)) xmax:=private.oldrange[2];
	if (is_boolean(ymin)) ymin:=private.oldrange[3];
	if (is_boolean(ymax)) ymax:=private.oldrange[4];
	private.plotrange:=[xmin,xmax,ymin,ymax];
	#print 'plotrange ',private.plotrange;
	#toggle off auto buttons;
	public.plotter.xauto->state(F);
	public.plotter.yauto->state(F);
	ok:=public.plotter.swin(xmin,xmax,ymin,ymax);
	ok:=public.show();
	return T;
   };

   public.fullrange:=function(){
	wider public,private;
        #toggle on auto buttons;
        public.plotter.xauto->state(T);
        public.plotter.yauto->state(T);
	current_units:=public.plotter.ips.getabcissaunit();
	ok:=public.plotter.ips.setabcissaunit(current_units);
	public.plotter.ips->unitchange();
	private.plotrange:=public.plotter.qwin();
   	return T;
    };

##rmadd      Description: Add a profile to the results manager.
##           Example:     From the getscan example above:
##                        rmadd(myspec);
##           Returns:     the name of the variable in the results manager
##           Produces:    a profile in the results manager
   public.rmadd := function(sdrec=F,name='',desc='') {
	wider public,private;
	if (is_boolean(sdrec)) {
		sdrec:=public.uniget('globalscan1');
	};
        if (is_sdrecord(sdrec)) {
                if (name=='') {
                        name:=sdrec.header.source_name;
                } else {
                        name:=name;
                }
                ok:=private.rm.add(name,desc,sdrec,type='SDRECORD');
                return ok;
        } else {
		print 'FAIL: Not an SDRecord';
		return F;
        }
        return F;
   }

    public.plotter := private.plotter();

    # restore the state of dish and its operations from disk
    const public.restorestate := function(usedefault=F)
    {
        wider private;
        wider public;
	if (!is_boolean(usedefault)) {
		print 'ERROR: Argument must be T or F'
		return F;
	};
	stime:=time();
        public.busy(T);
        if (usedefault) {
            public.message('restoring to default state');
#            if (public.plotter.is_active()) {
#                public.plotter.done();
#            }
            rmstate := [=];
            public.rm().setstate([=]);
            opstate := [=];
            ops := public.ops();
            for (i in 1:len(ops)) {
                thisop := ops[i];
                 if (has_field(thisop,'setstate') &&
                     is_function(thisop.setstate)) {
                     thisop.setstate([=]);
#JPM dismiss gui really disables the gui operation
#		     thisop.dismissgui();
                 }
	    }
	    tlstate:=[=];
	    tls := public.tools();
            for (i in 1:len(tls)) {
                thistl := tls[i];
                 if (has_field(thistl,'setstate') &&
                     is_function(thistl.setstate)) {
                     thistl.setstate([=]);
#JPM dismiss gui really disables the gui operation
#                    thistl.dismissgui();
                 }
            }
	    public.busy(F);
            return T;
        }

	# not default so let's fill it in.
        # first, the results manager
        public.message('Restoring DISH to the previously saved state ...');
        rmstate := dparams.get('rmstate');
        if (is_fail(rmstate) || rmstate.type != 'resultsmanager') {
            rmstate := [=];
            rmstate.value := [=];
        }
        # the dish state, mostly used when there are opstates
        dishstate := dparams.get('dishstate');
        if (is_fail(dishstate) || dishstate.type != 'dish') {
            dishstate := [=];
            dishstate.value := [=];
        }
        if (has_field(dishstate.value,'dologging')) {
            public.dologging(dishstate.value.dologging);
        } else {
            public.dologging(F);
        }
        # the op states
        opstates := dparams.get('opstate');
        if (!is_fail(opstates) && opstates.type == 'operations') {
            if (!has_field(dishstate.value,'opsinfo'))
                dishstate.value.opsinfo := [=];
            if (!has_field(dishstate.value,'mapped'))
                dishstate.value.mapped := [=];
            for (op in field_names(opstates.value)) {
                # is the op already known and available
                thisop := F;
                if (has_field(private.ops, op)) {
                    thisop := private.ops[op];
                } else {
                    # do we know how to make it
                    if (has_field(dishstate.value.opsinfo, op)) {
                        public.addop(dishstate.value.opsinfo[op].includefile,
                                     dishstate.value.opsinfo[op].ctor);
                    }
                    # now do we know about it
                    if (has_field(private.ops, op)) {
                        thisop := private.ops[op];
                    }
                }
                if (!is_boolean(thisop)) {
                    thisop.setstate(opstates.value[op]);
                }
            }
            # try and map anything which should be
            opcount := 0;
            opnames := as_string([]);
            for (op in private.ops) {
                opcount +:= 1;
                opnames[opcount] := op.opmenuname();
            }
            for (op in field_names(dishstate.value.mapped)) {
                if (any (opnames == op)) {
                    if (is_agent(private.gui)) {
                        private.gui.mapop(op, dishstate.value.mapped[op]);
                    } else {
                        private.mapped[op] := dishstate.value.mapped[op];
                    }
                }
            }
        }
        tlstates := dparams.get('tlstate');
        if (!is_fail(tlstates) && tlstates.type == 'tools') {
            if (!has_field(dishstate.value,'tlsinfo'))
                dishstate.value.tlsinfo := [=];
            if (!has_field(dishstate.value,'mapped'))
                dishstate.value.mapped := [=];
            for (tl in field_names(tlstates.value)) {
                # is the tool already known and available
                thistl := F;
                if (has_field(private.tools, tl)) {
                    thistl := private.tools[tl];
                } else {
                    # do we know how to make it
                    if (has_field(dishstate.value.tlsinfo, tl)) {
                        public.addtool(dishstate.value.tlsinfo[tl].includefile,
                                     dishstate.value.tlsinfo[tl].ctor);
                    }
                    # now do we know about it
                    if (has_field(private.tools, tl)) {
                        thistl := private.tools[tl];
                    }
                }
                if (!is_boolean(thistl)) {
                    thistl.setstate(tlstates.value[tl]);
                }
            }
            # try and map anything which should be
            tlcount := 0;
            tlnames := as_string([]);
            for (tl in private.tools) {
                tlcount +:= 1;
                tlnames[tlcount] := tl.opmenuname();
            }
            for (tl in field_names(dishstate.value.mapped)) {
                if (any (tlnames == tl)) {
                    if (is_agent(private.gui)) {
                        private.gui.maptool(tl, dishstate.value.mapped[tl]);
                    } else {
                        private.mapped[tl] := dishstate.value.mapped[tl];
                    }
                }
            }
        }
	uni2state := dparams.get('uni2')
	if (!is_fail(uni2state)) public.uniput('jnk',uni2state.value)
	#do this last;
        public.rm().setstate(rmstate.value);
	# the selection GUI needs to prodded at the end in case there was
	# a current-working-set set in the state - it can't actually be used
	# until the rm is reset to that state
	# make sure that op exists before trying to use it
	if (is_function(public.ops().select.setPendingCWS)) {
	    public.ops().select.setPendingCWS();
	}
        public.message('Dish restored to a previously saved state.');
        public.busy(F);
        return T;
    }

    # save the state of dish and all its operations to disk
    const public.savestate := function()
    {
        wider private;
        wider public;
        # the state of dish
        public.message('saving the current state of dish.');
        dishstate := [=];
        dishstate.opsinfo := private.opsinfo;
	dishstate.tlsinfo := private.tlsinfo;
        dishstate.mapped := private.mapped;
        dishstate.dologging := private.dologging;
        if (is_agent(private.gui)) dishstate.dologging := private.gui.dologging();
        dparams.set('dishstate','dish',dishstate);
        # the state of the results manager
        dparams.set('rmstate','resultsmanager',public.rm().getstate());
        # the state of the operations
        opstates := [=];
        ops := public.ops();
        for (op in field_names(ops)) {
            opstates[op] := ops[op].getstate();
        }
	# the state of the tools
	tlstates:=[=];
	tls := public.tools();
     	for (tl in field_names(tls)) {
	    tlstates[tl] := tls[tl].getstate();
   	}
        dparams.set('opstate','operations',opstates);
        dparams.set('tlstate','tools',tlstates);
	dparams.set('uni2','uni2',public.uniget())
        dparams.save();
        public.message('current dish state saved');
        return T;
    }

##scanadd    Description: Add scan2 to scan1
##           Example:     sumscan:=scansub(scan1,scan2);
##           Returns:     An SDRecord
   public.scanadd := function(scan1,scan2) {
        wider public;
        if (is_sdrecord(scan1)&is_sdrecord(scan2)) {
                if (!all(scan1.data.arr::shape==scan2.data.arr::shape)) {
                        print 'ERROR: Shapes are different';
                        return F;
                };
                resscan:=scan1;
                resscan.data.arr:=scan1.data.arr+scan2.data.arr;
#                ok:=public.rmadd(resscan);
#                rmlen:=private.rm.size();
#                ok:=private.rm.select(rmlen);
                return resscan;
        } else {
		print 'FAIL: Inputs are not SDRecords';
		return F;
        }
   }

##scansub    Description: Subtract scan2 from scan1
##           Example:     subscan:=scansub(scan1,scan2);
##           Returns:     An SDRecord
   public.scansub := function(scan1,scan2) {
        wider public;
        if (is_sdrecord(scan1)&is_sdrecord(scan2)) {
                if (!all(scan1.data.arr::shape==scan2.data.arr::shape)) {
                        print 'ERROR: Shapes are different';
                        return F;
                };
                resscan:=scan1;
                resscan.data.arr:=scan1.data.arr-scan2.data.arr;
#                ok:=public.rmadd(resscan);
#                rmlen:=private.rm.size();
#                ok:=private.rm.select(rmlen);
                return resscan;
        } else {
                print 'FAIL: Inputs are not SDRecords';
                return F;
        }
   }

##scandiv    Description: Divide scan1 by scan2
##           Example:     divscan:=scandiv(scan1,scan2);
##           Returns:     An SDRecord
   public.scandiv := function(scan1,scan2) {
        wider public;
        if (is_sdrecord(scan1)&is_sdrecord(scan2)) {
                if (!all(scan1.data.arr::shape==scan2.data.arr::shape)) {
                        print 'ERROR: Shapes are different';
                        return F;
                };
                resscan:=scan1;
                resscan.data.arr:=scan1.data.arr/scan2.data.arr;
#                ok:=public.rmadd(resscan);
#                rmlen:=private.rm.size();
#                ok:=private.rm.select(rmlen);
                return resscan;
        } else {
                print 'FAIL: Inputs are not SDRecords';
                return F;
        }
   }

   public.scansrr := function(scan1,scan2) {
	wider public;
	if (is_sdrecord(scan1)&is_sdrecord(scan2)) {
		if (!all(scan1.data.arr::shape==scan2.data.arr::shape)) {
			print 'ERROR: Shapes are different';
			return F;
		};
		resscan:=scan1;
		resscan.data.arr:=scan1.data.arr-scan2.data.arr;
		resscan.data.arr /:= scan2.data.arr;
#		ok:=public.rmadd(resscan);
#		rmlen:=private.rm.size();
#		ok:=private.rm.select(rmlen);
		return resscan;
	} else {
                print 'FAIL: Inputs are not SDRecords';
                return F;
	}
   };

##scanmult   Description: Multiply scan1 by scan2
##           Example:     multscan:=scandiv(scan1,scan2);
##           Returns:     An SDRecord
   public.scanmult := function(scan1,scan2) {
        wider public;
        if (is_sdrecord(scan1)&is_sdrecord(scan2)) {
                if (!all(scan1.data.arr::shape==scan2.data.arr::shape)) {
                        print 'ERROR: Shapes are different';
                        return F;
                };
                resscan:=scan1;
                resscan.data.arr:=scan1.data.arr*scan2.data.arr;
#                ok:=public.rmadd(resscan);
#                rmlen:=private.rm.size();
#                ok:=private.rm.select(rmlen);
                return resscan;
        } else {
                print 'FAIL: Inputs are not SDRecords';
                return F;
        }
   }

##scanscale       Description: Scale scan1 by sfactor
##                Example:     scaledscan:=scanscale(scan1,2.0);
##                Returns:     An SDRecord
   public.scanscale := function(scan1,sfactor) {
        wider public;
        if ((len(sfactor) != 1) && (scan1.data.arr::shape[1] != len(sfactor))) {
		dl.log(message='Arrays do not have the appropriate size',priority='SEVERE',postcli=T)
		return F;
        }

        if (is_sdrecord(scan1)) {
                resscan:=scan1;
		if (len(sfactor)==1)
		  resscan.data.arr:=scan1.data.arr*sfactor
		else
                  for (i in 1:len(sfactor))
                   resscan.data.arr[i,]:=scan1.data.arr[i,]*sfactor[i];
                return resscan;
        } else {
                dl.log(message='Input scan1 is not an SDRecord',priority='SEVERE',postcli=T)
                return F;
        }
   }

##scanbias        Description: Add a bias to scan
##                Example:     biasscan:=scanbias(scan1,2.0);
##                Returns:     An SDRecord
   public.scanbias := function(scan1,offset) {
        wider public;
        if ((len(offset) != 1) && (scan1.data.arr::shape[1] != len(offset))) {
		dl.log(message='Arrays do not have the appropriate size',priority='SEVERE',postcli=T)
		return F;
        }

        if (is_sdrecord(scan1)) {
                resscan:=scan1;
		if (len(offset)==1)
		  resscan.data.arr:=scan1.data.arr+offset
		else
                  for (i in 1:len(offset))
                   resscan.data.arr[i,]:=scan1.data.arr[i,]+offset[i];
                return resscan;
        } else {
                dl.log(message='Input scan1 is not an SDRecord',priority='SEVERE',postcli=T)
                return F;
        }
   }

##summary Description: Prints out a more detailed summary of scans.
##           Example:  summary();
##           Returns:  list information on a scangroup to the screen.
##                Produces:    NA
   public.summary := function(verbose=F) {
        wider private;
        if (is_boolean(public.files(T).filein)) {
                dl.log(message='No MS specified - use filein,open or import',priority='SEVERE',postcli=T)
                return F;
        };
        msname:=eval(public.files(T).filein).name();
	myms:=ms(msname);
        if (!is_fail(myms)) {
           ok:=myms.summary(verbose=verbose);
        } else {
           print 'Not an MS; use d.gms, d.listscans for more information';
           return F;
        }
        return ok;
   }
#
    const public.statefile := function(fullPathname) {
        wider private;
	if (!is_string(fullPathname)) {
		print 'ERROR: Bad Path name';
		return F;
	};
        return dparams.setparamfile(fullPathname);
    }

#   necessary for toolmanager
    const public.type := function() {return 'dish'};

    const public.uniput := function(univar,unival) {
	wider public;
	if (is_record(unival) && has_field(unival,'astack'))
	 public.unirec := unival
        else
 	 public.unirec[univar]:=unival;
    };

    const public.uniget := function(univar=F) {
        wider public;
        if (is_boolean(univar)) {
                return public.unirec
        } else if (has_field(public.unirec,univar)) {
                   return public.unirec[univar];
	}
	return F;
    };

    const public.view_sdrec:=function(data,name,overlay=F,refocus=T,frombase=F)
    {
        wider public,private;
	initial:=time();
    if (has_field(data,"data") && has_field(data.data,"arr") &&
        has_field(data.data.arr::,"shape") && len(data.data.arr::shape == 2) &&
        data.data.arr::shape[1] >= 1) {
	xvec := data.data.desc.chan_freq.value;
	ylabel := data.data.desc.units;
	xlabel := data.data.desc.chan_freq.unit;
	flag   := data.data.flag;
        if (strlen(data.data.desc.units)) {
            xlabel := spaste(xlabel,' (',data.data.desc.chan_freq.unit,')');
        }

#        public.plotter.create ();
        # this seems to be necessary to avoid a bug when overlay=F
        # and the plotrec call follows a previous plot with overlay=T
	 public.plotter.plotrec(data);
    } else {
	print 'ERROR: Bad Record, can not plot';
	return F;
    }
}

    private.rm := dishresman(private.browse_sditer,sdrecordbrowser,public.view_sdrec,ref public);

    # okay, at start up, do we automatically make the gui? 
    # that is the default, but check the aipsrc value
    # dish.gui.auto
    drc.findbool(startgui, "dish.gui.auto", def=T);

    # make sure we start with at least the default operations
    private.defaultops();

    if (startgui) {
	public.gui();
    } else {
	public.plotter.screen();
    }

    # make sure this cleans itself up on exit
    whenever system->exit do { if (is_record(public) && has_field(public,'done')) public.done();}

    # make sure the status line says we're ready
    public.message('dish is ready.');

    # restore the state - just does the rm for now
    # the state is automatically saved by .done() on exit.
    # currently all stored in same place each time (dparms.g).
    dorestore:=F;
    drc.find(dorestore,'dish.statefile',def="T");
    dorestore:=as_boolean(dorestore);
#
    if (dorestore) {
        junk2:=public.restorestate();
        if (is_fail(junk2)) {
                note('restorestate seems to have failed');
        } 
    }



#   trial passing of rm functions to the main of dish for the toollmanager
#    for (i in field_names(public.rm())) 
#    {
#	public[i]:=public.rm()[i];
#    }
	
        dl.log(message=sprintf('Time to initialize DISH = %3.1f secs',
	       time()-btime),priority='NORMAL',postcli=T)

public.aver := ref public.ops().average.daver;
public.base := ref public.ops().baseline.dbase;
#public.save := ref public.ops().save.apply;
public.select:=ref public.ops().select.dselect;
public.smooth:=ref public.ops().smooth.dsmooth;
public.stat := ref public.ops().statistics.dstats;
public.writetofile := ref public.ops().write.tofile;
public.ls := ref dos.ls

public.save := function(sdrec=F,outf=F) {
  wider public
  if (is_boolean(sdrec))
    sdrec := public.uniget('globalscan1')
  if (!is_sdrecord(sdrec)) {
    dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
    return F
    }
  if (is_boolean(outf)) {
    public.ops().save.apply(sdrec)
    print 'globalscan saved to ',d.files(T).fileout
    }
  else {
    ok := public.ops().save.apply(sdrec,outf)
    if (ok) print 'globalscan saved to ',outf
    }
  ok:=eval(public.files(T).fileout).flush();
  return T
}

public.fileout := function(workingset) {
  wider private,public;
	if (workingset ~ m/\./ || workingset ~ m/-/) {
	   dl.log(message='Illegal name; changing illegal characters to underscores',priority='WARNING',postcli=T);
           workingset =~ s/-/_/g; # substitute any '-' with '_'
           workingset =~ s/\./_/g; # substitute any '.' with '_'
        };
  neednewfile := F
  origfiles := public.files(T)
  private.fileout:=workingset;

  size := public.rm().size();
  if (size > 0) {
     names := public.rm().getnames(seq(size));
     which := ind(names)[names == workingset];
     if (len(which) == 1) {
        v := symbol_value(names[which]);
        if (is_sditerator(v) && v.iswritable()) {
           public.ops().save.setws(workingset);
	   private.fileout:=workingset;
	   return T;
        } else {
           dl.log(message='Not an SDIterator or not writable',
                  priority='SEVERE',postcli=T)
           private.fileout := origfiles.fileout
           return F;
        }
     } else {
        neednewfile := T
     }
  } else {
     neednewfile := T
  };

  if (neednewfile) {
     if (dos.fileexists(workingset)) {
        tryopen:=public.open(workingset,access='w');
        if (tryopen) {
           ok:=public.filein(origfiles.filein);
           ok := public.ops().save.setws(workingset)
           return T;
        };
     } else {
        public.open(workingset,new=T)
        newok := public.ops().save.setws(workingset);
        if (!newok) {
           dl.log(message='Error in fileout',priority='SEVERE',postcli=T)
           private.fileout := origfiles.fileout
           return F
        }
       public.filein(origfiles.filein)
        dl.log(message=spaste('New file ',workingset,' is created'),postcli=T,
            priority='NORMAL')
     };
   };
  return T;
}

public.zline := function(torF) {
	wider public;
	public.plotter.zline(torF);
	return T;
};

    plugins.attach('mydish',public);

    return ref public;
}


#    const defaultdish:=dish();
#    const d:=ref defaultdish;

#    defaultlogger.log('', 'NORMAL', 'defaultdish (d) ready', 'dish');

    # Add defaultdish to the GUI if necessary
    if (any(symbol_names(is_record)=='objrepository') &&
        has_field(objrepository, 'notice')) {
        objrepository.notice('defaultdish', 'dish');
    }

#const d := dish();

#const daver := ref d.ops().average.daver;
#const dbase := ref d.ops().baseline.dbase;
#const dsave := ref d.ops().save.apply;
#const dselect:=ref d.ops().select.dselect;
#const dsmooth:=ref d.ops().smooth.dsmooth;
#const dstat := ref d.ops().statistics.dstats;

#ok := symbol_set(d)
#
#names:=field_names(d);
#
#for (i in names) {
#	dum:=spaste('const ',i,':= ref ',i);
#	ok:=eval(dum);
#};
