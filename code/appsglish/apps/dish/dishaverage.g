# dishaverage.g: the dish averaging operation.
#------------------------------------------------------------------------------
#   Copyright (C) 1999,2000,2001,2002
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
#    $Id: dishaverage.g,v 19.1 2004/08/25 01:09:09 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include 'dishaveragegui.g';
include 'sditerator.g';

const dishaverage := function(ref itsdish)
{
    # we start off with the functions in sdaverager
    private := sdaverager();

    public := [=];

    # we save the state setting parts of the averager and
    # replace them with our own versions here
    # sdaverager functions used to go into the public
    # private.setweighting := public.setweighting;
    # private.setalignment := public.setalignment;
    # private.dorestshift := public.dorestshift;

    # the only other state is whether a selection happens first
    private.selection := F;

    private.gui := F;
    private.dish := itsdish;
    private.wsname := F;
    private.sdutil := sdutil();


#  get the last variable in the results manager and return it
   private.getrecord := function() {
        wider private;
        sz:=private.dish.rm().size();
        ok:=private.dish.rm().select(sz);
        mysdr:=private.dish.rm().getlastviewed();
        if (is_sdrecord(mysdr.value)) {
                return mysdr.value;
        } else {
                return throw('FAIL: Not an SDRecord');
        }
   }


    public.apply := function(selws=F,cli=F) {
        wider private;
        newIsOld := T;
	if (is_boolean(selws)) {
        	newWorkingSet := private.dish.ops().select.cws();
		if (!is_sditerator(newWorkingSet)) {
                   newWorkingSet := 
			symbol_value(private.dish.rm().getselectionnames()[1]);
		}
                ok:=private.dish.message('using current working set');
	} else {
	        if (is_sditerator(selws)) {
	           newWorkingSet := selws;}
	}
        if (!is_sditerator(newWorkingSet)) {
            ok:=private.dish.message('Error! No working set selected.');
            return F;
        }
        if (newWorkingSet.length () < 1) {
            ok:=private.dish.message('Error!  Zero-length working set');
            return F;
        }
        if (private.selection) {
            ok:=private.dish.message('dataset obtained from results manager, now making selection...');
            ws := private.dish.ops().select.apply(fromgui=!cli,returnws=T);
            if (is_fail(ws)) fail;
            if (is_boolean(ws)) {
                ok:=private.dish.message('no selection criteria specified');
            } else {
                # safe to use it at this point
                newWorkingSet := ws;
                newIsOld := F;
                arg := [=];
                arg.fromgui := T;
		arg.returnws:=T
                ok:=private.dish.logcommand('dish.ops().select.apply',arg);
            }
        }
        if (newIsOld) {
            arg := [=];
            arg.return := 'ws';
            ok:=private.dish.logcommand('dish.ops().select.cws',arg);
        }
        numberOfRecords := newWorkingSet.length ();
        if (numberOfRecords < 1) {
            ok:=private.dish.message('Error!  Zero-length working set - nothing to average');
            # clean up the zero-length working set if we made it here
            if (!newIsOld) tmp := newWorkingSet.done();
            return F;
        }
        sdrecAverage:= private.averagews (newWorkingSet);
        # we don't need newWorkingSet at this point, unless it
        # was the same as the old on (in which case it should NOT be deleted)
        if (!newIsOld) {
            tmp := newWorkingSet.done();
        }
        # did the average work?
        if (is_sdrecord(sdrecAverage)) {
	    if (cli==T) {
		return sdrecAverage;
	    } else {
            resultDescription := spaste(as_string(numberOfRecords),' averaged spectra');
            resultName := private.dish.rm().add ('average', resultDescription,
                                                 sdrecAverage, 'SDRECORD');      
            # Will this always be the 'end' item?  I'm pretty sure it will.
            # this should result in it being displayed
            ok:=private.dish.rm().select('end');
	    };
        } else {
            ok:=private.dish.message('An error occured during averaging - see the logged messages for details');
        }
        return T;
    }


    # dismiss the gui 
    public.dismissgui := function() {
        wider private;
        if (is_agent(private.gui)) private.gui.done();
        private.gui := F;
        return T;
    }

    # done with this closure, this makes it impossible to use the public
    # part of this after invoking this function
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

        state.selection := private.selection;
        state.alignment := private.getalignment();
        state.restshift := private.restshiftstate();
        state.weighting := private.getweighting();

        return state;
    }

    public.gui := function(parent, widgetset=dws) {
	wider private;
	wider public;
	# don't build one if we already have one or there is no display
	if (!is_agent(private.gui) && widgetset.have_gui()) {
	    private.gui := dishaveragegui(parent, public, 
					  itsdish.logcommand,
					  widgetset);
	}
	return private.gui;
    }

    public.opfuncname := function() { return 'average';}
    public.opmenuname := function() { return 'Averaging';}

    # set the state from the indicated record
    # invoking this with an empty record should reset this to its
    # initial state
    public.setstate := function(state) {
	wider private, public;
	if (is_record(state)) {
	    if (has_field(state,'alignment') && is_string(state.alignment)) 
		public.setalignment(state.alignment);
	    else 
		public.setalignment('NONE');
	    if (has_field(state,'restshift') && is_boolean(state.restshift))
		public.dorestshift(state.restshift);
	    else 
		public.dorestshift(F);
	    if (has_field(state,'weighting') && is_string(state.weighting)) 
		public.setweighting(state.weighting);
	    else
		public.setweighting('NONE');
	    if (has_field(state,'selection') && is_boolean(state.selection))
		public.doselection(state.selection);
	    else
		public.doselection(T);
	}
	return T;
    }

    # the state setting functions
    public.setweighting := function(weighting) {
	wider private;
	result := F;
	if (is_string(weighting) && any(weighting == "NONE RMS TSYS WEIGHT")) {
	    result := private.setweighting(weighting);
	    # inform the GUI if it exists
	    if (is_agent(private.gui)) {
		private.gui.setweighting(weighting);
	    }
	}
	return result;
    }

    public.setalignment := function(alignment) {
	wider private;
	result := F;
	if (is_string(alignment) && any(alignment == "NONE VELOCITY XAXIS")) {
	    result := private.setalignment(alignment);
	    # inform the GUI if it exists
	    if (is_agent(private.gui)) {
		private.gui.setalignment(alignment);
	    }
	}
	return result;
    }

    public.doselection := function(doselection) {
	wider private;
	result := F;
	if (is_boolean(doselection)) {
	    private.selection := doselection;
	    result := T;
	    # inform the GUI if it exists
	    if (is_agent(private.gui)) {
		private.gui.doselection(doselection);
	    }
	}
	return result;
    }

    public.dorestshift := function(dorestshift) {
	wider private;
	result := F;
	if (is_boolean(dorestshift)) {
	    result := private.dorestshift(dorestshift);
	    # inform the GUI if it exists
	    if (is_agent(private.gui)) {
		private.gui.dorestshift(dorestshift);
	    }
	}
	return result;
    }

    # set the default state
    public.setstate([=]);

    private.averagews := function(sdit)
    {
	wider private,public;
	# by default, returns an empty record which can be tested to see if
	# a problem has occurred
	result := [=];

	# clear any ongoing average
	private.clear();

	numberOfRecords := sdit.length();
	msg := spaste ('begin averaging ',as_string(numberOfRecords), ' spectra');
	private.dish.message(msg);
	startTime := time ();
   
	# we need to return an sdrecord from this function, and it should 
	# be constructed from the many fields in the records that contribute
	# to the caluculated average.  as a first attempt at 
	# constructing this (25 nov 96), i make a simple copy of the first
	# record in the working set, and create new values for the y-axis,
	# the x-axis (which is implicit in crval,crpix,&cdelt), and add
	# some appropriate history comments

	currloc := sdit.location();
	sdit.origin();
	sdrecReturnValue := sdit.get();

	if (private.accumiterator(sdit)) {
	    ok:=sdit.setlocation(currloc);

	    endTime := time ();
	    elapsedTime := endTime-startTime;
	    elapsedTime::print.precision := 2;
	    ratePerRecord := elapsedTime/numberOfRecords;
	    ratePerRecord::print.precision := 2;
	    msg := spaste (as_string(numberOfRecords), ' spectra: ', 
			   as_string(elapsedTime), ' seconds, ', 
			   as_string(ratePerRecord),' per spectra.');
	    ok:=private.dish.message(msg);
	    
	    if (private.average(ref sdrecReturnValue)) {
		currentHistoryLength := len (sdrecReturnValue.hist);

		# changes need to be reflected in the history
		#
		sdrecReturnValue.hist [currentHistoryLength+1] :=  
		    private.dish.history('dish.ops().average.setweighting',
		    [weighting=private.getweighting()]);
		sdrecReturnValue.hist [currentHistoryLength+2] :=
		    private.dish.history('dish.ops().average.setalignment',
		    [alignment=private.getalignment()]);
		sdrecReturnValue.hist [currentHistoryLength+3] :=
		    private.dish.history('dish.ops().average.doselection',
		    [doselection=private.selection]);
		sdrecReturnValue.hist [currentHistoryLength+4] :=
		    private.dish.history('dish.ops().average.dorestshift',
		    [dorestshift=private.restshiftstate()]);
		sdrecReturnValue.hist [currentHistoryLength+5] :=
		    private.dish.history('dish.ops().average.apply');

		# make sure that the resulting hist array has the correct shape
		sdrecReturnValue.hist::shape := len(sdrecReturnValue.hist);
		ok:=private.dish.message('average calculated');
		elapsedTime := time() - startTime;
		elapsedTime::print.precision := 2;
		ratePerRecord := elapsedTime/numberOfRecords;
		ratePerRecord::print.precision := 2;
		msg := spaste ('average calculated: ', 
			       as_string(elapsedTime),' seconds, ',
				as_string(ratePerRecord),' per spectra.');
		private.dish.message(msg);
		result := sdrecReturnValue;
	    }
	}
	return result;
    }

    public.averagews:=ref private.averagews

##aver       Description: averages specified groups of scans,subscans
##           Example:     myavg:=aver([2,3,4],[1,3]);
##           Returns:     T (if successful)
##           Produces:    working_setx (where x is an incremented number)
##                                which contains the selected scans
##                             averagex (where x is an incremented number)
const public.daver:=function(scanlist=F,subscanlist=F,weighting='TSYS',
			alignment='NONE') {
        wider private,public;
	args:=missing();
#	print 'phases are ',private.dish.qdumps(scanlist)[2];
	critrec:=[=];
	if (!is_boolean(scanlist)) {
		scanlistvec:=scanlist;
	} else {
		scanlistvec:=private.dish.listscans();
	};
	private.wsname:=private.dish.wsname();
	if (is_boolean(private.wsname)) fail;
        ok:=private.dish.ops().select.setws(private.wsname);
        ok:=public.setweighting(weighting);
        ok:=public.setalignment(alignment);
        if (is_boolean(scanlist) & is_boolean(subscanlist)) {
                ok:=private.dish.ops().select.setcriteria(critrec=[=]);
        } else if (!is_boolean(scanlist) & is_boolean(subscanlist)) {
                scanlist:=private.sdutil.parseranges(as_string(scanlist));
                critrec:=[=];
                critrec:=[header=[scan_number=scanlist]];
                ok:=private.dish.ops().select.setcriteria(critrec=critrec);
        } else if (is_boolean(scanlist) & !is_boolean(subscanlist)) {
          if (!is_string(subscanlist)) {
                subscanlist:=private.sdutil.parseranges(as_string(subscanlist));
                subscanlist:=subscanlist[1,];
                scans:=private.dish.ops().select.cws().getheadervector('scan_number');
                scans:=scans.scan_number;
                uscans:=unique(scans);
                #All scans must have same number of subscans
                subscannum:=len(scans)/len(uscans);
                #
                rows:=1:len(scans);
                rowmask:=!(rows==rows); # all F
                #build row mask
                tmp:=[];
                for (i in subscanlist) {
                   tmp:=[tmp,i+(0:(len(uscans)-1))*subscannum];
                }
                rowlist:=sort(tmp);
                critrec:=[=];
                critrec.row:=private.sdutil.parseranges(as_string(rowlist));
                ok:=private.dish.ops().select.setcriteria(critrec=critrec);
          } else if (is_string(subscanlist)) {
                scans:=private.dish.ops().select.cws().getheadervector('scan_number');
                scans:=scans.scan_number;
                uscans:=unique(scans);
                #All scans must have same number of subscans

                if (subscanlist=='odd') {
                   rows:=1:len(scans);
                   rows:=rows[rows%2!=0];
                   critrec:=[=];
                   critrec.row:=private.sdutil.parseranges(as_string(rows));
                   ok:=private.dish.ops().select.setcriteria(critrec=critrec);
                } else if (subscanlist=='even') {
                   rows:=1:len(scans);
                   rows:=rows[rows%2==0];
                   critrec:=[=];
                   critrec.row:=private.sdutil.parseranges(as_string(rows));
                   critrec.row:=private.sdutil.parseranges(as_string(rows));
                   ok:=private.dish.ops().select.setcriteria(critrec=critrec);
               } else if (split(subscanlist,'')[2]=='/') {
#                   orows:=rows;
		   rows:=1:len(scans);
                   phase:=as_integer(split(subscanlist,'/'))[1];
                   nphases:=as_integer(split(subscanlist,'/'))[2];
                   rows:=(rows[ind(rows)%nphases==0])-(nphases-phase);
		   #print 'phases are ',phase,nphases,' rows ',rows;
                   critrec.row:=private.sdutil.parseranges(as_string(rows));
                   ok:=private.dish.ops().select.setcriteria(critrec=critrec);
#               } else if (subscanlist=='caloff') {
                } else {
                   dl.note('Unrecognized subscan parameter');
                   return F;
                };
          }; #end if is_string(subscanlist)
        } else if (!is_boolean(scanlist) & !is_boolean(subscanlist)) {
                scanlist:=private.sdutil.parseranges(as_string(scanlist))[1,];
                scans:=private.dish.ops().select.cws().getheadervector('scan_number');
                scans:=scans.scan_number;
                scanmask:=!(scans==scans);
                for (i in scanlist) { scanmask:=scanmask | scans==i; };
                rows:=(1:len(scans))[scanmask];
                subscanmask:=!(rows==rows);
           if (is_string(subscanlist)) {
                if (subscanlist=='odd') {
#                   rows:=1:len(rows);
                   rows:=rows[rows%2!=0];
                   critrec:=[=];
                   critrec.row:=private.sdutil.parseranges(as_string(rows));
                   critrec.row:=private.sdutil.parseranges(as_string(rows));
                   ok:=private.dish.ops().select.setcriteria(critrec=critrec);
                } else if (subscanlist=='even') {
#                   rows:=1:len(rows);
                   rows:=rows[rows%2==0];
                   critrec:=[=];
                   critrec.row:=private.sdutil.parseranges(as_string(rows));
                   critrec.row:=private.sdutil.parseranges(as_string(rows));
                   ok:=private.dish.ops().select.setcriteria(critrec=critrec);
               } else if (split(subscanlist,'')[2]=='/') {
		   orows:=rows;
		   phase:=as_integer(split(subscanlist,'/'))[1];
		   nphases:=as_integer(split(subscanlist,'/'))[2];
		   rows:=(rows[ind(rows)%nphases==0])-(nphases-phase);
                   critrec.row:=private.sdutil.parseranges(as_string(rows));
                   ok:=private.dish.ops().select.setcriteria(critrec=critrec);
                } else {
                   dl.note('Unrecognized subscan parameter');
                   return F;
                };
           } else {
                subscanlist:=private.sdutil.parseranges(as_string(subscanlist));
                subscanlist:=subscanlist[1,];
                uscans:=unique(scanlist);
                #All scans must have same number of subscans
                subscannum:=len(rows)/len(uscans);
                #
                #build row mask
                tmp:=[];
                for (i in subscanlist) {
                   tmp:=[tmp,i+(0:(len(uscans)-1))*subscannum];
                }
                rowlist:=sort(tmp);
                rowlist:=rows[rowlist];
                critrec:=[=];
                critrec.row:=private.sdutil.parseranges(as_string(rowlist));
                ok:=private.dish.ops().select.setcriteria(critrec=critrec);
           };
        };
#        print 'critrec is ',critrec;
        ok:=public.doselection(T);
        ok:=public.setweighting(weighting);
        ok:=public.setalignment(alignment);
        result:=public.apply(cli=T);
	result.header.scan_number:=scanlistvec;
#        size:=private.dish.rm().size();
#       now return the sdrecord
#        return private.getrecord();
	return result;
   }


    return public;
}
