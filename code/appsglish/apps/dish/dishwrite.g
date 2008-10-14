# dishwrite.g: the dish Write operation.
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
#    $Id: dishwrite.g,v 19.2 2006/06/28 19:37:14 bgarwood Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include 'dishwritegui.g';

const dishwrite := function(ref itsdish)
{
    public := [=];
    private := [=];
    private.ofname := '';
    private.gui := F;
    private.dish := itsdish;


    private.updateGUIstate := function() {
        wider private;
        if (is_agent(private.gui)) {
            private.gui.setof(private.ofname);
            private.gui.sethistory(private.history);
            private.gui.setselection(private.selection);
        }
    }

    # write the last viewed record to the named disk file
    public.apply := function(lv=F) {
        wider private;
        if (is_boolean(lv)) {
	    lv:=private.dish.rm().getlastviewed();
	    nominee:=ref lv.value;
	    if (is_fail(lv)) {
		private.dish.message('Error! An SDRecord has not yet been viewed');
		return F;
	    } else if (is_sditerator(lv.value)) {
		private.dish.message('Print from SDIterator not supported');
	    }
        } else {
	    nominee := ref lv;
	}			# 
	# confirm that it is an SDRECORD
	if (!is_sdrecord(nominee)) {
	    return throw('Error! Not an SDRECORD');
	}
	# the shape of y is [nstokes, nchan]
	nstokes := nominee.data.arr::shape[1];
	nchan := nominee.data.arr::shape[2];
	if (nstokes > 4) {
	    private.dish.message('Unable to write out data with > 4 stokes axes');
	} else {
	    # get the entry
	    if (is_agent(private.gui)) {
                private.ofname := private.gui.getof();
                if (strlen(private.ofname) == 0) private.ofname := '';
	    } # otherwise use what is there
	}
	ent := as_string(private.ofname);
	isdefault := F;
	if (ent=='') {
	    # use default value but do not enter it into the entry box
	    ent := spaste(as_string(nominee.header.scan_number),'.spc');
	    isdefault := T;
	}
	# ensure value used is the one selected, unless used the default value
	# open it as the output file
	fp:=open([">",ent]);
	# construct the x values
# newSD
#      myx := [1:nchan];
#      myx -:= lv.value.data.desc.crpix;
#      myx *:= lv.value.data.desc.cdelt;
#      myx +:= lv.value.data.desc.crval;
# newSD
	flagmask:=nominee.data.flag;
	thisdata := nominee.data.arr;
	#myx := nominee.data.desc.chan_freq.value;
	#use the imager to plot out the proper units
###
#      ok:=private.dish.plotter.plotrec(nominee);
	myx:=private.dish.plotter.ips.getcurrentabcissa();
	# write out info on the type and units
	# construct format strings appropriatly for nstokes
	# first column is 16 characters wide
	typefmt := '%14s \t';
	unitfmt := '%14s \t';
	datafmt := '%14e \t';
	stokesAxes := nominee.data.desc.corr_type;
	abcunits   := private.dish.plotter.ips.getabcissaunit();
	abcunits   := spaste(abcunits,'-',private.dish.plotter.ips.getdoppler());
	ordunits   := nominee.data.desc.units;
	type       := ['ABSCISSA',stokesAxes];
	units      := [abcunits,ordunits];
	# just to be sure, possibly a warning should be emitted
	if (len(stokesAxes) != nstokes) stokesAxes := array('',nstokes);
	fnan := 0.0/0.0; 
	for (i in 1:nstokes) {
	    datafmt := paste(datafmt,'%14e');
	    thisdata[i,][flagmask[i,]] := fnan;
	}
	# we need to do this before the newlines are added
	datafmt := spaste(datafmt,'\n');
	fprintf(fp,typefmt,type);
	fprintf(fp,'\n');
	fprintf(fp,unitfmt,units);
	fprintf(fp,'\n');
	# I don't see a better way to do this.eval might be an option but that
	# would require making some of these symbols global.  Still, there shouldn't
	# be more than 4 stokes under any circumstances
	if (nstokes == 1) {
            fprintf(fp,datafmt,myx,thisdata);
	} else if (nstokes == 2) {
	    fprintf(fp,datafmt,myx,thisdata[1,],thisdata[2,]);
	} else if (nstokes == 3) {
	    fprintf(fp,datafmt,myx,thisdata[1,],thisdata[2,],thisdata[3,]);
	} else if (nstokes == 4) {
	    fprintf(fp,datafmt,myx,thisdata[1,],thisdata[2,],thisdata[3,],thisdata[4,]);
	}
	fp := F;
#         ds.log('# and make sure the output file has been closed');
#         ds.log('fp := F');
	private.dish.message(spaste('Spectrum written to file: ',ent));
    }

    public.tofile := function(outfile=F, scanrec=F) {
	wider public;
	if (is_boolean(outfile)) {
		print 'ERROR: No outfile specified';
		return F;
	};
        if (is_boolean(scanrec)) {
                scanrec:=private.dish.rm().getlastviewed().value;
        }
	if (!is_sdrecord(scanrec)) {
		print 'ERROR: No valid SDRecord specified';
		return F;
	};
        ok:=public.setof(outfile);
        ok:=public.apply(scanrec);
        return ok;
   }


    public.dismissgui := function() {
        wider private;
        if (is_agent(private.gui)) private.gui.done();
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

    public.getstate := function() {
        wider private;
        state := [=];
#        if (is_agent(private.gui)) private.ofname := private.gui.ofname();
        state.ofname := private.ofname;
        return state;
    }

    public.opmenuname := function() { return 'Write to file';}
    public.opfuncname := function() { return 'write';}

    public.gui := function(parent, widgetset=dws) {
	wider private;
	wider public;
	if (!is_agent(private.gui) && widgetset.have_gui()) {
	    private.gui:= dishwritegui(parent, public, private.dish, widgetset);
	}
	return private.gui;
    }

    public.opmenuname := function() { return 'Write to File';}
    public.opfuncname := function() { return 'write';}

    public.setstate := function(state) {
	wider public;
	result := F;
	ofname := '';
	    
	if (is_record(state) && has_field(state, 'ofname') &&
	    is_string(state.ofname) && len(state.ofname) == 1) {
	    ofname := state.ofname;
	}
	return public.setof(ofname);
    }

    # set the output disk file
    public.setof := function(ofname,updateGUI=T) {
	wider private;
        if (is_string(ofname)) {
            private.ofname := ofname;
            if (updateGUI && is_agent(private.gui)) {
                private.gui.setof(private.ofname);
            }
        }
        return T;
    } 

    return public;
}
