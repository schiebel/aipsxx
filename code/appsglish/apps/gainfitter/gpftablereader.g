# gpftablereader.g: reads data from a gain table
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
# $Id: gpftablereader.g,v 19.1 2004/08/25 01:16:45 cvsmgr Exp $

# pragma include once;

include 'gainpolyfit.g';
include 'table.g';
include 'measures.g';
include 'note.g';
include 'unset.g';

#@itemcontainer GainTableReaderOptionsItem
# contains options for configuring the default behavior of a gaintablereader
# tool.  Users normally do not create these items themselves; they are used
# primarily for creating gaintablereader tool constructors specialized for 
# certain telescopes.  The gaintablereader.getoptions() function will return
# an itemcontainer of this type.
# @field type      must be set to 'GainTableReaderOptionsItem'
# @field deforder  a record in which fields are 'amp', 'phase', 'real', and
#                    'imag'; the values are the default fit order for each 
#                    component.
# @field descfilter  a TaQL query that selects records from the CAL_DESC
#                    table.  Only those gains with CAL_DESC_IDs matching these
#                    records will be loaded.
# @field mainfilter  a TaQL query that selects records from the main gain table.
#                    Only those gains from these records will be loaded.
# @field gainfilter  a record indicating which gains in the GAIN array to 
#                    select.  Field names are taken from the following
#                    <pre>
#                        field   description              possible values
#                        -------------------------------------------------------
#                        spw     Spectral Window ID       1-based IDs appearing
#                                                         in the CAL_DESC table.
#                        chan    channel                  1-based channel nos.
#                        jones   Jones matrix element.    strings of the form
#                                                         'N M' where N,M are
#                                                         1-based indicies into
#                                                         the Jones matrix. E.g.
#                                                         '1 2', '2 2', etc.
#                        pol     polarization             types appearing in 
#                                                         CAL_DESC table; e.g.
#                                                         'X', 'Y', 'R', etc.
#                        leak    leakage terms            Same as pol; 'X' 
#                                                         refers to the 
#                                                         sensitivity to Y in 
#                                                         the X receptor.
#                    </pre>
#                    If one of the above fields is not given, all matching 
#                    gains are selected.  'pol' and 'leak' are an alternative 
#                    way to 'jones' for selecing Jones matrix element; the 
#                    selection indicated these 3 items are "ORed" together 
#                    and converted to a 'jones' selection.  If 'pol' or 'leak'
#                    is the unset value, that portion of the Jones matrix 
#                    should not be selected.  
# @field indepaxis  the independent axis; must be either 'time' or 'freq'.
#                    This is represents the independent variable in the 
#                    fitting process and what will appear along the plots' 
#                    x-axis.
# @field selaxes   a list of names representing independent selection
#                    variables; a gainpolyfit tool will be created for each 
#                    unique combination of selection variables.  Examples 
#                    include 'ant', 'receptor', or 'polarization'.  Each is 
#                    as a label for the GUI and as field names for records
#                    internal to the gainpolyfitter tool that hold the 
#                    individual gainpolyfit tools.
# @field selindex  a list of column names iterate over.  There should be one
#                    value for each element in selaxes.  Gain solutions with
#                    identical values in these columns will be loaded
#                    together into the same gainpolyfit tool.  The names should 
#                    be taken from those that appear in the main or from the 
#                    special "pseudo-column" names.  The latter set are used 
#                    for iterating over the elements in the gain array.  The
#                    "pseudo-column" names are:
#                    <pre>
#                        spw        iterate over each spectral window.
#                        chan       iterate over each channel.
#                        jones      iterate over each jones matrix element.
#                                   If the jones matrix is 2x2, then the total
#                                   number of elements along this axis is 4.
#                        pol        iterate over the diagonal elements of the
#                                   jones matrix
#                        leak       iterate over the off-diagonal elements.
#                    </pre>
#                    Use of 'jones', 'pol', and 'leak' are mutually exclusive.
##

const GAINTABLEREADEROPTIONSITEM := 'GainTableReaderOptionsItem';
const _pseucols := "spw chan pol leak jones";
const DEFAULT_GPFREADOPTIONS := 
     [type=GAINTABLEREADEROPTIONSITEM, 
      mainfilter='', descfilter='', gainfilter=[=],
      indepaxis='time', deforder=[amp=0, phase=2, real=2, imag=2], 
      selaxes="Ant Pol", selindex="ANTENNA1 pol", fudgewts=F];

#@tool public gpftablereader
#  a tool for loading gains from a table into gainpolyfit tools.
#
#@constructor
# @param  gains       the name of the input gains table.  No default.
# @param  loadfits    load any previously calculated fits from the table, if 
#                     they exist.  This may cause some options to be overridden.
# @param  validonly   if true, only valid (pre-fit) gain solutions be loaded.
#                     The default is false, loading all gains; however, invalid
#                     gains will be masked as bad.
# @param  options     the options for setting up the tool as a 
#                     GainPolyFitterOptionsItem.  
gpftablereader := function(gains, options=DEFAULT_READOPTIONS) {
    private := [opts=DEFAULT_GPFREADOPTIONS, gtblname=gains];
    
    public := [=];

    # merge input options with defaults.
    private.setoptions := function(options=[=]) {
	wider private;
	local opts := itemcontainer();
	opts.fromrecord(private.opts);
	opts.fromrecord(options);
	private.opts := opts.torecord();
	opts.done();
	return T;
    }
    private.setoptions(options);

    #@ 
    # return the current set of reader options
    public.getoptions := function() {
	wider private;
	return private.opts;
    }

    #@
    # return a temporary table name
    private.tmptblname := function(base='gpftmp', dir='/tmp') {
	return spaste(dir,'/',base,'_',random(10,99),
		      as_integer(1000*(time()-998492857)));
    }

    #@
    # set the filtering TaQL where strings that constrain the data that is
    # read in.
    # @param main   the where string for the main table
    # @param desc   the where for the CAL_DESC sub-table.
    public.setfilters := function(main=unset, desc=unset, gain=unset) {
	wider private;
	if (! is_unset(main)) {
	    if (! is_string(main)) 
		fail paste('gpftablereader.setfilters(): ',
			   'main param not a string:', main);
	    private.opts.mainfilter := main;
	}
	if (! is_unset(desc)) {
	    if (! is_string(main)) 
		fail paste('gpftablereader.setfilters(): ',
			   'desc param not a string:', desc);
	    private.opts.descfilter := desc;
	}
	if (! is_unset(gain)) {
	    if (! is_string(main)) 
		fail paste('gpftablereader.setfilters(): ',
			   'gain param not a string:', gain);
	    private.opts.gainfilter := gain;
	}
    }

    #@
    # open and filter the gain tables according to the filters
    private.filter := function(gains, ref main, ref desc, 
			       mainfilt=unset, descfilt=unset) 
    {
	wider private;
	if (is_unset(mainfilt)) mainfilt := private.opts.mainfilter;
	if (is_unset(descfilt)) descfilt := private.opts.descfilter;

	# filter the description table as necessary
	local dtbl := spaste(gains,"/CAL_DESC");
	if (strlen(descfilt) > 0) {
	    val desc := tablecommand(paste('select from', dtbl, 'where', 
					   descfilt));
	    if (is_fail(desc)) fail paste('gpftablereader.loadgpfdata():',
					  'bad descfilter string:\n    ',
					  descfilt, '\n    ', desc::message);
				       
	    if (desc.nrows() <= 0) fail paste('No gains matching CAL_DESC',
					      'selection:', descfilt);
	} else {
	    val desc := table(dtbl);
	    if (is_fail(desc)) 
		fail paste('gpftablereader.loadgpfdata():\n    ', 
			   desc::message);

	    if (desc.nrows() <= 0) {
		desc.done();
		fail 'No rows found in CAL_DESC';
	    }
	}

	# get the description ids loaded.
	local ids := desc.rownumbers() - 1;
	local i;
	local idfilter := '';
	for(i in ids) {
	    if (strlen(idfilter) > 0) idfilter := spaste(idfilter, ' || ');
	    idfilter := spaste(idfilter, 'CAL_DESC_ID==', i);
	}

	if (strlen(mainfilt) > 0) {
	    mainfilt := spaste(mainfilt, '&& (', idfilter, ')');
	} else {
	    mainfilt := idfilter;
	}

	# create the view of the gains main table
	if (strlen(mainfilt) > 0) {
	    val main := tablecommand(paste('select from', gains, 'where', 
					   mainfilt));
	    if (is_fail(main)) fail paste('gpftablereader.loadgpfdata():',
					  'bad mainfilter string:\n    ',
					  mainfilt, '\n    ', main::message);
	    if (main.nrows() <= 0) {
		main.done();
		fail paste('No gains matching', mainfilt);
	    }
	}
	else {
	    val main := table(gains);
	    if (is_fail(desc)) 
		fail paste('gpftablereader.loadgpfdata():\n    ', 
			   desc::message);
	}

	return T;
    }

    #@
    # return an empty array of a given type
    private.initarray := function(type) {
	if (! is_string(type)) 
	    fail paste('non-string passed to initarray():', type);
	if (type == 'integer') {
	    return as_integer([]);
	} else if (type == 'double') {
	    return as_double([]);
	} else if (type == 'complex') {
	    return as_complex([]);
	} else if (type == 'boolean') {
	    return as_boolean([]);
	} else if (type == 'string') {
	    return as_string([]);
	} else if (type == 'dcomplex') {
	    return as_dcomplex([]);
	} else if (type == 'float') {
	    return as_float([]);
	} else if (type == 'short') {
	    return as_short([]);
	} else if (type == 'byte') {
	    return as_byte([]);
	} else {
	    fail paste("unknown type:", type);
	}
    }

    #@ 
    # return a boolean array indicating which gains to select from the 
    # gain array
    private.gainselection := function(desc, filter=[=]) {
	if (! has_field(filter, 'spw') && ! has_field(filter, 'chan') && 
	    ! has_field(filter, 'pol') && ! has_field(filter, 'leak') && 
	    ! has_field(filter, 'jones'))
	    return array(T, desc.NUM_RECEPTORS, desc.NUM_RECEPTORS, 
			 desc.NUM_SPW, desc.NUM_CHAN);

	local out := array(F, desc.NUM_RECEPTORS, desc.NUM_RECEPTORS, 
			   desc.NUM_SPW, desc.NUM_CHAN);
	local i,j,idx,jstr,p;

	local spw;
	if (has_field(filter, 'spw') && ! is_unset(filter.spw)) {
	    spw := rep(F, desc.NUM_SPW);
	    for(i in filter.spw) {
		spw[desc.SPECTRAL_WINDOW_ID == i-1] := T;
	    }
	} 
	else {
	    spw := rep(T, desc.NUM_SPW);
	}

	local chan;
	if (has_field(filter, 'chan') && ! is_unset(filter.chan)) {
	    chan := rep(F, desc.NUM_CHAN);
	    chan[filter.chan[filter.chan < desc.NUM_CHAN]] := T;
	} 
	else {
	    chan := rep(T, desc.NUM_CHAN);
	}

	if (has_field(filter, 'jones') && ! is_unset(filter.jones)) {
	    for(jstr in filter.jones) {
		idx := as_integer(split(jstr));
		if (is_fail(idx)) 
		    fail paste('illegal value for gainfilter:', jstr);
		if (any(idx > desc.NUM_RECEPTORS)) next;
		out[idx[1], idx[2], spw, chan] |:= T;
	    }
	}
	if (has_field(filter, 'pol')) {
	    if (is_unset(filter.pol)) {
		for (i in 1:desc.NUM_RECEPTORS) {
		    out[i, i, spw, chan] &:= F;
		}
	    }
	    else {
		for(p in filter.pol) {
		    idx := desc.POLARIZATION_TYPE == p;
		    if (any(idx)) out[idx, idx, spw, chan] |:= T;
		}
	    }
	}
	if (has_field(filter, 'leak')) {
	    if (is_unset(filter.leak)) {
		for (i in 1:desc.NUM_RECEPTORS) {
		    for (j in 1:desc.NUM_RECEPTORS) {
			if (i == j) next;
			out[i, j, spw, chan] &:= F;
		    }
		}
	    }
	    else {
		local p1, p2;
		for (p in filter.leak) {
		  if (p == 'X') p2 := 'Y';
		  else if (p == 'Y') p2 := 'X';
		  else if (p == 'R') p2 := 'L';
		  else if (p == 'L') p2 := 'R';
		  else next;
		  
		  p1 := ind(desc.POLARIZATION_TYPE)[desc.POLARIZATION_TYPE==p];
		  p2 := ind(desc.POLARIZATION_TYPE)[desc.POLARIZATION_TYPE==p2];
		  
		  out[p1, p2, spw, chan] |:= T;
		}
	    }
	}

	return out;
    }

    #@
    # load data from a gain table into a given record, flattening arrays
    # and combining data from the description sub-table.
    private.loaddata := function(ref gdata, ref gtbl, ref dtbl, 
				 selindex, indepaxis, gainfilter) 
    {
	local drow, mrow, i, col, tmpname, ok, gmask;
	local ddata := [=];
	local ids := dtbl.rownumbers() - 1;
	local cols := ["GAIN SOLUTION_OK FIT FIT_WEIGHT"];
	val gdata := [=];

	local maincols := gtbl.colnames();
	local mainsel := [];               # axes on cols from the main table
	local pseusel := [];               # axes on pseudo-columns
	local unknsel := [];               # unrecognized column names
	for(col in [cols, selindex]) {
	    if (any(maincols == col)) {
		if (! any(mainsel == col)) mainsel := [mainsel, col];
#		gdata[col] := [];
	    }
	    else if (any(_pseucols == col)) {
		if (! any(_pseucols)) pseusel := [pseusel, col];
#		gdata[col] := [];
	    }
	    else {
		unknsel := [unknsel, col];
	    }
	}
	if (length(unknsel) > 0) 
	    fail paste("gpftablereader: unrecognized (pseudo-)column(s):", col);

	if (indepaxis == 'time') {
	    mainsel := unique(["TIME TIME_EXTRA_PREC", mainsel]);
#  	    gdata.TIME := [];
#  	    gdata.TIME_EXTRA_PREC := [];
	}
	local mcols := mainsel;
#  	gdata.spw := [];
#  	gdata.chan := [];
#  	gdata.jones := "";
#  	gdata.pol := "";
#  	gdata.isleak := [];

	i := 0;
	for(drow in 1:dtbl.nrows()) {
	    ok := private.loadddata(dtbl, ddata, drow);
	    if (is_fail(ok)) return ok;
	    local subdata := [=];

	    # this is a hack for non-standard calibration tables
	    if (strlen(ddata.POLARIZATION_TYPE) == 0) {
		note(spaste('Fixing POLARIZATION_TYPE for CAL_DESC_ID=', 
			    ids[drow]), origin='gainpolyfitter');
		if (ddata.NUM_RECEPTORS == 1) {
		    ddata.POLARIZATION_TYPE := "X";
		} else {
		    ddata.POLARIZATION_TYPE := "X Y";
		}
	    }

	    # create mask for selecting elements from the gain array 
	    gmask := private.gainselection(ddata, gainfilter);
	    if (is_fail(gmask)) return gmask;
#	    print gmask;

	    tmpname := private.tmptblname();
	    subtbl := gtbl.query(spaste('CAL_DESC_ID==', ids[drow]), tmpname);
	    if (is_fail(subtbl)) fail subtbl::message;
	    private.loadgdata(subtbl, subdata, mcols);

#  	    # initialize each array to the proper type
#  	    if (drow == 1) {
#  		for(col in mcols) {
#  		    gdata[col] := private.initarray(type_name(subdata[col]));
#  		}
#  		gdata.spw := 
#  		    private.initarray(type_name(ddata.SPECTRAL_WINDOW_ID));
#  		gdata.chan := private.initarray(type_name(ddata.CHAN_FREQ));
#  		gdata.chan := private.initarray('integer');
#  		gdata.jones := private.initarray('string');
#  		gdata.pol := private.initarray('string');
#  		gdata.isleak := private.initarray('boolean');
#  		print "SOLUTION_OK type:", type_name(gdata.SOLUTION_OK);
#  		print "SOLUTION_OK type:", type_name(gdata.GAIN);
#  		print "SOLUTION_OK type:", type_name(gdata.isleak);
#  	    }

	    for (mrow in 1:subtbl.nrows()) {
	      for(j in 1:ddata.NUM_RECEPTORS) {
		for(k in 1:ddata.NUM_RECEPTORS) {
		  for(w in 1:ddata.NUM_SPW) {
		    if (length(subdata.GAIN::shape) == 5) {

		      # This method is based on the standard document
		      for(c in 1:ddata.NUM_CHAN[w]) {
			if (! gmask[j,k,w,c]) next;
			i +:= 1;
			for(col in mainsel) {
			    gdata[col][i] := subdata[col][mrow];
			}
			gdata.GAIN[i] := subdata.GAIN[j,k,w,c,mrow];
			gdata.SOLUTION_OK[i] := 
			    subdata.SOLUTION_OK[j,k,w,c,mrow];
			gdata.FIT[i] := subdata.FIT[j,k,w,c,mrow];
			gdata.FIT_WEIGHT[i] := subdata.FIT_WEIGHT[j,k,w,c,mrow];
			gdata.spw[i] := ddata.SPECTRAL_WINDOW_ID[w];
#			gdata.chan[i] := ddata.CHAN_FREQ[c];
			gdata.chan[i] := c-1;
#  			gdata.jones[i] := spaste(ddata.POLARIZATION_TYPE[j],
#  						 ddata.POLARIZATION_TYPE[k]);
			gdata.jones[i] := paste(j, k);
			gdata.pol[i] := ddata.POLARIZATION_TYPE[j];
			gdata.isleak[i] := j != k;
		      }
		    }
		    else {
			# This method is based on current calibration tables
#			gm := gmask[j,k,w,1];
#			print spaste('gmask[',j,k,w,1,'] = ', gm);
			if (! gmask[j,k,w,1]) next;
			i +:= 1;
			for(col in mainsel) {
			    gdata[col][i] := subdata[col][mrow];
			}
			gdata.GAIN[i] := subdata.GAIN[j,k,w,mrow];
			gdata.SOLUTION_OK[i] := subdata.SOLUTION_OK[w,mrow];
			gdata.FIT[i] := subdata.FIT[w,mrow];
			if (private.opts.fudgewts) {
			    gdata.FIT_WEIGHT[i] := subdata.FIT_WEIGHT[2,mrow];
			} else {
			    gdata.FIT_WEIGHT[i] := subdata.FIT_WEIGHT[w,mrow];
			}
			gdata.spw[i] := ddata.SPECTRAL_WINDOW_ID[w];
#			gdata.chan[i] := ddata.CHAN_FREQ[1];
			gdata.chan[i] := 0;
#  			gdata.jones[i] := spaste(ddata.POLARIZATION_TYPE[j],
#  						 ddata.POLARIZATION_TYPE[k]);
			gdata.jones[i] := paste(j, k);
			gdata.pol[i] := ddata.POLARIZATION_TYPE[j];
			gdata.isleak[i] := (j != k);
		    }
		  }
		}
	      }
	    }

	    subtbl.done();
	    if (tableexists(tmpname)) tabledelete(tmpname);
	}
	if (i == 0) 
	    note('no matching gain data found', priority='WARN', 
		 origin='gpftablereader');

	return T;
    }

    #@ 
    # load selected columns from the main table
    private.loadgdata := function(ref gtbl, ref gdata, mcols) {
	val gdata := [=];
	local col;

	# load the needed data from the main table
	for(col in mcols) {
	    gdata[col] := gtbl.getcol(col);
	}
	# gdata.id := gtbl.getcol('CAL_DESC_ID');

	return T;
    }

    #@
    # load description data from a given row
    private.loadddata := function(ref dtbl, ref ddata, row) {
	val ddata := [=];
	local col, row;
	if (row < 1 || row > dtbl.nrows()) 
	    fail paste('gpftablereader (internal error): row out of range:', 
		       row);
	local dcols := [ "SPECTRAL_WINDOW_ID CHAN_FREQ POLARIZATION_TYPE",
		         "NUM_SPW NUM_CHAN NUM_RECEPTORS N_JONES" ];

	# load the needed data from the main table
	val ddata := [=];
	for(col in dcols) {
	    ddata[col] := dtbl.getcell(col, row);
	}

	return T;
    }

    #@
    # return a frequency measure for a given frequency value
    private.getfreqref := function(ref dtbl, freqval) {
	local types := "rest lsrk lsrd bary geo topo galacto";

	# in the unlikely case that multiple descriptions feature different
	# frequency reference types, this simplification will cause fitting
	# inaccuracies.
	local t := dtbl.getcell('MEAS_FREQ_REF', 1)

	return dm.frequency(types[t], freqval);
    }

    #@ 
    # read in the gain data and load gainpolyfit tools according to the
    # configured options.
    private.readbyoptions := function(ref data, gains, validonly=F) {
	wider private;
	local col;

	# create views of the gains and description tables
	local gtbl, dtbl;
	local ok := private.filter(gains, gtbl, dtbl);
	if (is_fail(ok)) return ok;

#	val data := [=];
	data.gtbl := ref gtbl;
	data.dtbl := ref dtbl;

	# load the gain data, flattening array data and combining with 
	# description data
	local gdata := [=];
	ok := private.loaddata(gdata, gtbl, dtbl, 
			       private.opts.selindex, private.opts.indepaxis,
			       private.opts.gainfilter);
	if (is_fail(ok)) return ok;

	# determine the domain of gain indicies
	data.axes := private.opts.selindex;
	data.axispos := [=];
	local axistype := [];
	for (col in data.axes) {
	    if (col == 'leak') {
		data.axispos[col] := unique(gdata.pol);
	    }
	    else {
		data.axispos[col] := unique(gdata[col]);
	    }
	    if (has_field(data.axispos, col)) 
		axistype := [axistype, type_name(data.axispos[col])];
	}

	# define the x-reference and scale
	local xoff, xref, xscale;
	if (private.opts.indepaxis == 'time') {
	    xoff := min(gdata.TIME);
	    minxref := dm.epoch('utc', spaste(xoff,'s'));
	    if (is_fail(minxref)) return minxref;
	    maxxref := dm.epoch('utc', spaste(max(gdata.TIME), 's'));
	    if (is_fail(maxxref)) return maxxref;
#	    xscale := xoff;
	}
	else {
	    xoff := min(gdata.CHAN_FREQ);
	    minxref := private.getfreqref(dtbl, spaste(xoff,'Hz'));
	    if (is_fail(minxref)) return minxref;
	    maxxref := dm.frequency(minxref.refer, 
				    spaste(max(gdata.CHAN_FREQ),'Hz'));
	    if (is_fail(maxxref)) return maxxref;
#	    xscale := xoff;
	}
	xscale := 1;

	data.xref := [=];
	data.xref.min := minxref;
	data.xref.max := maxxref;
	data.xref.scale := xscale;

	local ridx := rep(1, length(data.axes));
	local lim := rep(0, length(data.axes));
	local mask := [=];
	for(i in ind(axistype)) {
	    lim[i] := length(data.axispos[i]) + 1;
	    mask[i] := rep(T, length(gdata.GAIN));
	}
	mask[length(lim)+1] := rep(T, length(gdata.GAIN));
	if (validonly) mask[length(lim)+1] &:= gdata.SOLUTION_OK;
	data.idxmap := seq(prod(lim-1));
	data.idxmap::shape := lim - 1;

	# load the data into gainpolyfit tools
	local mask, x, g, m, e;
	local maski := length(mask);
	local n := 1;
	data.gpfit := [=];
	while (any(ridx != lim)) {

	    # create a selection mask
	    for(j in (maski-1):1) {
		col := private.opts.selindex[j];
#		print j, "mask for", col, "=", data.axispos[col][ridx[j]];

		# column must contain scalar data!
		mask[j] := mask[j+1];
		if (col == 'leak') {
		    mask[j] &:= gdata.isleak & 
				gdata.pol == data.axispos.leak[ridx[j]];
		}
		else if (col == 'pol') {
		    mask[j] &:= ! gdata.isleak & 
			        gdata.pol == data.axispos.pol[ridx[j]];
		}
		else {
		    mask[j] &:= gdata[col] == data.axispos[col][ridx[j]];
		}
	    }
	    maski := 1;

	    # create the gainpolyfit tools.  Currently, assuming ampphase=T
	    data.gpfit[n] := gainpolyfit(deforder1=private.opts.deforder.amp,
					 deforder2=private.opts.deforder.phase,
					 ampphase=T);

	    # extract the x-axis data
	    if (private.opts.indepaxis == 'time') {
		x := (gdata.TIME[mask[1]] - xoff) / xscale;
		x +:= gdata.TIME_EXTRA_PREC[mask[1]] / xscale;
	    }
	    else {
		x := (gdata.CHAN_FREQ[mask[1]] - xoff) / xscale;
	    }
#	    print spaste('N(x,', n, ') = ', length(x));

	    g := gdata.GAIN[mask[1]];
	    e := 1.0/sqrt(gdata.FIT_WEIGHT[mask[1]]);
	    m := gdata.SOLUTION_OK[mask[1]];

	    data.gpfit[n].setdata(T, x, g, e, m, minxref, xscale);
	    n +:= 1;

	    # iterate the index
	    j := 1;
	    ridx[j] +:= 1;
	    maski := 2;
	    while (j < length(ridx) && ridx[j] >= lim[j]) {
		ridx[j] := 1;
		j +:= 1;
		maski +:= 1;
		ridx[j] +:= 1;
	    }
	    if (j == length(ridx) && ridx[j] >=  lim[j]) break;
	}

	# convert column values for those columns representing indicies 
	# from a 0-based convention to 1-based convention.
	for(col in field_names(data.axispos)) {
	    if (is_integer(data.axispos[col]) && 
		(col ~ m/^ANTENNA\d$/ || col == 'spw' || col == 'chan' ||
		 col ~ m/_ID$/ || col ~ m/^FEED\d$/)) 
	    {
		data.axispos[col] +:= 1;
	    }
	}

#	dtbl.done();
#	gtbl.done();
	return T;
    }

    #@ 
    # read in the gain data and load gainpolyfit tools according to the
    # configured options.
    private.readbyfits := function(ref data, gains, which, validonly=F) {
	wider private;
	note(paste("Reading saved fits not yet supported;",
		   "reverting to by-options reading"),
	     priority="WARN", origin("gpftablereader"));
	return private.readbyoptions(data, gains, validonly);
    }

    #@ 
    # create and load a set of gainpolyfit tools from a gain table.
    # @param gpfinfo     a record to hold the gainpolyfit data, including
    #                      the gainpolyfit tools
    # @param loadfits    if >0, load the tools from fits saved under this 
    #                      index, if it exists; otherwise load according 
    #                      to configured options
    # @param validonly   if T, load only valid gain solutions
    public.loadgpfdata := function(ref gpfinfo, loadfits=T, validonly=F) {
	wider private;
	local gains := ref private.gtblname;
	local out;
	if (loadfits > 0 && tableexists(spaste(gains,'/CAL_FITS'))) {
	    out := private.readbyfits(gpfinfo, gains, loadfits, validonly);
	} else {
	    out := private.readbyoptions(gpfinfo, gains, validonly);
	}
	if (is_fail(out)) 
	    note(priority='SEVERE', origin='gpftablereader', out::message);

	return out;
    }

    public.done := function() {
	public := F;
	return T;
    }

    return ref public;
}

#  readopts := DEFAULT_READOPTIONS;
#  readopts.selaxes := "ant sideband pol";
#  readopts.selindex := "ANTENNA1 spw pol";
#  readopts.mainfilter := 'ANTENNA1 < 10';
#  readopts.gainfilter := [jones=['1 1']];
#  # readopts.gainfilter := [jones=['1 1','1 2'], spw=1, pol=unset, leak="R L"];
#  # readopts.descfilter := 'MS_NAME == "phcal"';
#  rdr := gpftablereader('gcal.for_ray', options=readopts);
#  gpf := [=];
#  ok := rdr.loadgpfdata(gpf, validonly=T);
