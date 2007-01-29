# msbrick_MS.g: Interactio with MS for msbrick.g
# J.E.Noordam, oct 1998

# Copyright (C) 1996,1997,1998,1999
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
# $Id: msbrick_MS.g,v 19.0 2003/07/16 03:38:51 aips2adm Exp $

#---------------------------------------------------------


pragma include once
# print 'include msbrick_MS.g  h30aug99'

include 'msbrick_select.g'
# include 'tracelogger.g';


#=========================================================
test_msbrick_MS := function () {
    msbMS := msbrick_MS();
    return ref msbMS;
};

#=========================================================
msbrick_MS := function () {
    private := [=];
    public := [=];

    private.init := function() {
	wider private;
	private.msb_select := msbrick_select();	# functions
	private.initMS();			# MS-related
    }

    private.tw := [=];				# temporary
    private.tw.append := function (v) {
	# print 'msbrick_MS: tw.append():',v;
	public.agent -> text(v);
    }
    private.tw.message := function (v) {
	# print 'msbrick_MS: tw.message():',v;
	public.agent -> message(v);
    }


#=========================================================
# Public interface:

    public.agent := create_agent();	# communication

    public.private := function(copy=F) {	# access to private part
	if (copy) return private;		# return a copy
	return ref private;			# return a reference
    }


#--------------------------------------------------------------
# Some private helper-functions
#--------------------------------------------------------------

    public.summaryMSdo := function() {
	print ' ';
	private.MS.msdo.summary(header,verbose=T);
	print 'msdo.summary() header:',header,'\n';
    }

    public.summaryMS := function() {
	s := paste(' \n \n Summary of MS:',private.MS.msname)
	for (fname in field_names(private.MS)) {
	    r := private.MS[fname];
	    s := spaste(s,'\n MS.',fname,': ',type_name(r),' ',shape(r));
	    if (is_record(r)) {
		# do nothing
	    } else if (len(r)<30) {
		s := paste(s,'value=',r);
	    } else if (is_numeric(r)) {
		s := paste(s,'range=',min(r),max(r));
	    }
	}
	for (fname in field_names(private.MS.msrange)) {
	    r := private.MS.msrange[fname];
	    s := spaste(s,'\n MS.msrange.',fname,': ',type_name(r),' ',shape(r))
	    if (len(r)<30) {
		s := paste(s,'value=',r);
	    } else if (is_numeric(r)) {
		s := paste(s,'range=',min(r),max(r));
	    }
	}
	private.tw.append(s);
	private.tw.append(' ');
	return s;
    }

    public.closeMS := function() {
	wider private;
	s := paste('closed:',private.MS.msname);
	if (public.checkMS(F)) {
	    private.MS.mstable.close();
	    private.MS.msdo.close();
	    private.initMS();	
	}
	private.tw.message(s);
	return T;
    }

    public.inspectMS := function() {
	if (public.checkMS(T)) {
	    inspect(private.MS.mstable, private.MS.msshortname);
	}
    }

    public.inspectMSdo := function() {
	if (public.checkMS(T)) {
	    inspect(private.MS.msdo, private.MS.msshortname);
	}
    }
    public.inspectMSrecord := function() {
	inspect(private.MS, 'private.MS');
    }

    public.checkMS := function(mess=F) {
	if (private.MS.msdefined) {
	    return T;
	} else {
	    s := paste('open an MS first!');	 	    private.tw.message(s);	 
	    return F;
	}
    }

# Initialise private.MS:

    private.initMS := function() {
	wider private;
	private.MS := [=];
	private.MS.msdefined := F;
	private.MS.msname := F;
	private.MS.msshortname := F;
	val private.MS.msdo := F;
	val private.MS.mstable := F;
	private.MS.msreadonly := T;

	private.MS.spectral_window_id := F;   # one-relative? (msdo)
	private.MS.array_id := F;             # one-relative (msdo)	

	private.MS.nrow := F;
	private.MS.colnames := F;
	private.MS.colnames_SYSCAL := F;
	private.MS.tel_name := F;

	# Should really be in MS.msrange (depends on array_id)
	private.MS.ant_pos := F;
	private.MS.ant_pos1D := F;
	private.MS.ant_xpos := F;
	private.MS.ant_ypos := F;
	private.MS.ant_zpos := F;
	private.MS.ant_id0 := F;
	private.MS.ant_id1 := F;
	private.MS.ant_name := F;
	private.MS.ant_shortname := F;

	private.MS.pol_names := "X Y";             #.....?
	private.MS.pol_codes := [-1,-1];           #.....?

	private.MS.msrange := [=];
	return T
    }

    public.getMSfield := function(fname, trace=F) {
	s := paste('getMSfield(',fname,'):');
	if (!has_field(private,'MS')) {
	    s := paste(s,'no field private.MS');
	} else if (!is_record(private.MS)) {
	    s := paste(s,'private.MS not a record');
	} else if (has_field(private.MS,fname)) {
	    return private.MS[fname];
	} else {
	    s := paste(s,'fname not recognised');
	}
	if (trace) print s;
	return F;
    }



    public.getMSrange := function(fname, trace=F) {
	s := paste('getMSrange(',fname,'):');
	if (!has_field(private,'MS')) {
	    s := paste(s,'no field private.MS');
	} else if (!is_record(private.MS)) {
	    s := paste(s,'private.MS not a record');
	} else if (!has_field(private.MS,'msrange')) {
	    s := paste(s,'no field private.MS.msrange');
	} else if (!is_record(private.MS.msrange)) {
	    s := paste(s,'private.MS.msrange not a record');
	} else if (has_field(private.MS.msrange,fname)) {
	    return private.MS.msrange[fname];
	} else {
	    s := paste(s,'fname not recognised, trying getMSfield..');
	    print s;
	    return public.getMSfield(fname);
	}
	if (trace) print s;
	return F;
    }

# Open an MS (ask if no name given explicitly):

    public.openMS := function(name=F, readonly=T) {
	wider private;
	public.closeMS();				# close any open MS's
	if (is_boolean(name)) {
	    s := paste('using MS chooser, coming up...');
	    private.tw.message(s);
	    if (F) {				# old way (home!!)
		private.tw.append(paste(s,'(old system)'));
		fc := chooser();		# obsolete
		await fc -> *;			# if chooser()
		#...................................# if chooser()
		name := fc.returns.guiReturns;	# if chooser()
	    } else {				# new way
		private.tw.append(paste(s,'(new system)'));
		print 'NB: replace filechooser with catalog!';
		ftc := tablechooser();		# see guimisc.g
		name := ftc.guiReturns;		# ftc is NOT an agent
	    }
 	    # print 'guiReturns: name=',name;
	    if (is_boolean(name)) {
		private.tw.message('cancelled: no MS selected');
		return F;		        # cancelled
	    }
	}
	s := paste('opening MS:',name,'...');
	private.tw.message(s);
	private.tw.append(s);

	include 'ms.g';					# only if required
	private.MS.msname := name;			# input argument
	private.MS.msreadonly := readonly;		# input argument
	private.MS.mstable := table(private.MS.msname); # default: readonly=T 
	# private.MS.mstable := table(private.MS.msname, 
	#			    read_only=private.MS.msreadonly);  # old
	#			    readonly=private.MS.msreadonly);   # new
	if (is_fail(private.MS.mstable)) {
	    print private.MS.mstable;			# print the fail
	    print s := paste('openMS: failed, name=',private.MS.msname);
	    private.tw.append(s);
	    private.tw.message(s);
	    fail(private.MS.mstable);			# pass on the fail
	} 

	s := paste('opening MS:',private.MS.msname);
	s := paste(s,' nrows=',private.MS.mstable.nrows());
	private.tw.append(s);
	private.tw.message(s);

	s := paste('busy reading MS info....'); 
	private.tw.append(s);
	private.tw.message(s);

	ss := split(private.MS.msname,'/');		# look for slash
	private.MS.msshortname := ss[len(ss)];		# name without directory

	private.MS.msdo := ms(private.MS.msname);
	public.readMSgeneral();				# general info from MS
	public.msdo_selectinit();			# spwin/array selection

	private.MS.msdefined := T;			# set switch
	public.summaryMS();				# display summary
	s := paste('OK, MS opened succesfully.');
	private.tw.append(s);
	private.tw.message(s);
	return private.MS.msname;			# return MS name!
    }

#----------------------------------------------------------------------
# Make sure that the right array and spectral window have been chosen:
# Change if necessary, and read the MS anew:

    public.msdo_selectinit := function (array_id=F, spectral_window_id=F, 
					change=F, trace=F) {
	wider private;
	s := paste('msdo_selectinit():',array_id,spectral_window_id,change);
	if (trace) print s;
	if (is_boolean(private.MS.array_id)) {		# first time only
	    private.MS.array_id := 1;			# default
	    private.MS.spectral_window_id := 1;		# default (0 means all!)
	    change := T;				# see below
	    r := private.MS.msdo.selectinit(reset=T);	# unselected ms
	    if (is_fail(r)) {
	    	print r
	    	fail(r)
	    }
	    fnames := "array_id spectral_window_id";
	    s := 'msdo_selectinit(reset)';
	    rr := public.msdo_range(fnames, trace=trace, origin=s);
	    for (fname in fnames) {
	    	private.MS.msrange[fname] := rr[fname];
	    }
	}
	if (is_integer(array_id)) {
	    if (private.MS.array_id != array_id) change := T;
	    private.MS.array_id := array_id;
	}
	if (is_integer(spectral_window_id)) {
	    if (private.MS.spectral_window_id != spectral_window_id) change := T;
	    private.MS.spectral_window_id := spectral_window_id;
	}
	if (!change) {
	    s := paste('msdo_selectinit(): no change in array/spwin selection.');
	    if (trace) print s;
	    private.tw.message(s);
	} else {
	    array_id := public.getMSfield('array_id');
	    spectral_window_id := public.getMSfield('spectral_window_id');
	    s := paste('msdo.selectinit() change:');
	    s := paste(s,'array_id=',array_id,'spectral_window_id=',spectral_window_id);
	    if (trace) print s;
	    private.tw.message(s);

	    r := private.MS.msdo.selectinit(array_id, spectral_window_id);
	    if (is_fail(r)) {
	    	print r;
	    	fail(r);
	    }
	    fnames := "array_id spectral_window_id";
	    s := 'msdo_delectinit(change)';
	    rr := public.msdo_range(fnames, trace=trace, origin=s);
	    for (fname in fnames) {
	    	private.MS[fname] := rr[fname];	    # current values, NOT msrange!
	    }
	    public.readMSranges();		# some depend with spwin/array
	}
	
	return T;
    }

# Helper function:

    public.msdo_range := function (fnames, trace=T, origin=F) {
	rr := private.MS.msdo.range(fnames);
	if (trace) print paste('msdo_range():',origin);
	for (fname in fnames) {
	    s := spaste(' - ',fname,':');
	    if (!has_field(rr,fname)) {
	    	print paste(s,'  ** field missing from rr! **');
	    } else if (trace) {
		r := rr[fname];
		s := paste(s,type_name(r),shape(r));
		s := paste(s,'range=',r[1:min(5,len(r))]);
		if (len(r)>5) s := paste(s,'...');
	    	print s;
	    }
	}
	return rr;
    }

#----------------------------------------------------------
# Read data from the MS:

    public.readMSgeneral := function(trace=F) { 
	wider private;
	s := 'readMSgeneral(): start.....';
	if (trace) print s;
	private.tw.append(s);

	private.MS.nrow := private.MS.mstable.nrows();
	private.MS.colnames := private.MS.mstable.colnames();

    # read directly from various MS sub-tables:

	t := table(private.MS.mstable.getkeyword("SYSCAL"));
	private.MS.colnames_SYSCAL := t.colnames();
	t.close();					# necessay?

	t := table(private.MS.mstable.getkeyword("ARRAY"));
	private.MS.tel_name := t.getcol("NAME");        # e.g. WSRT
	t.close();					# necessay?

	t := table(private.MS.mstable.getkeyword("FIELD"));
	private.MS.msrange.radec := t.getcol("POINTING_DIR");
	t.close();

	t := table(private.MS.mstable.getkeyword("ANTENNA"));
	arrid := t.getcol("ARRAY_ID");                  # zero-relative
	array_id0 := max(0,private.MS.array_id-1);  
	sv := [arrid==array_id0];                       # selection vector
	if (trace) print 'array_id0=',array_id0,'sv=',sv;

	private.MS.ant_id0 := t.getcol("ANTENNA_ID")[sv]; # 0-relative
	private.MS.ant_id1 := 1 + private.MS.ant_id0[sv]; # 1-relative
	nant := len(private.MS.ant_id0);                # nr of antennas
	if (trace) print nant,'id0=',private.MS.ant_id0;
	if (trace) print nant,'id1=',private.MS.ant_id1;

       	pp := t.getcol("POSITION");	                # antenna pos
	pdim := shape(pp);
	private.MS.ant_pos := array(0.0,3,nant);
	if (len(pdim)==1 && pdim[1]==len(sv)) {         # 1D (early WSRT)
	    private.MS.ant_pos[2,] := pp[sv];           # forgiving....
	} else if (len(pdim)==2 && pdim[1]==3) {        # [3,nant]
	    private.MS.ant_pos := pp[,sv];              # OK, normal
	} else {                                        # ND...?
	    print 'unexpected ant_pos: pdim=',pdim; 
	    # do what..?
	}
	private.MS.ant_xpos := private.MS.ant_pos[1,];
	private.MS.ant_ypos := private.MS.ant_pos[2,];
	private.MS.ant_zpos := private.MS.ant_pos[3,];
	private.MS.ant_pos1D := array(0.0,nant);
	refpos := private.MS.ant_pos[,1];               # reference
	for (iant in [1:nant]) {
	    pos1D := 0.0;
	    for (j in [1:3]) {
		d := private.MS.ant_pos[j,iant] - refpos[j];
		pos1D +:= d*d;
	    }
	    private.MS.ant_pos1D[iant] := sqrt(pos1D);
	}
	if (trace) print 'ant_pos=',private.MS.ant_pos;
	if (trace) print 'refpos=',refpos;
	if (trace) print 'ant_pos1D=',private.MS.ant_pos1D;
	    
	private.MS.ant_name := t.getcol("NAME")[sv];	# WSRT0, WSRT1 etc
	if (private.MS.tel_name == 'WSRT') {
	    wsrtants := "0 1 2 3 4 5 6 7 8 9 A B C D E F";
	    private.MS.ant_shortname := wsrtants[private.MS.ant_id1];
	} else {
	    private.MS.ant_shortname := private.MS.ant_name;
	}
	if (trace) print 'ant_name=     ',private.MS.ant_name;
	if (trace) print 'ant_shortname=',private.MS.ant_shortname;
	t.close();

	s := 'readMSgeneral(): finished';
	if (trace) print s;
	private.tw.append(s);
	return T;
    }


# Read the MS parameter ranges that depend on spwin/array:

    public.readMSranges := function() { 
	wider private;
	private.tw.append('readMSranges(): start.....');

    # read ranges with msdo.range():

	fnames := ["num_corr corr_names corr_types"];
	fnames := [fnames, "chan_freq"];
	fnames := [fnames, "ifr_number antenna1 antenna2"];
	fnames := [fnames, "time times"];
	fnames := [fnames, "field_id fields"];

	s := 'readMSranges(): getting ranges...';
	private.tw.append(s);
	rr := public.msdo_range(fnames, trace=T, origin=s);
	for (fname in field_names(rr)) {
	    private.MS.msrange[fname] := rr[fname];		# add copies
	}

    # Some range quantities derived from current ranges:

	private.MS.msrange.basel := [];
	ifr_number := public.getMSrange('ifr_number');
	ant_pos := public.getMSfield('ant_pos');
	for (i in ind(ifr_number)) {
	    iant2 := ifr_number[i]%1000;
	    iant1 := (ifr_number[i]-iant2)/1000;
	    s := spaste(ifr_number[i],'(',iant1,',',iant2,'):');
	    basel := 0;
	    for (j in [1:3]) {
		r := ant_pos[j,iant2] - ant_pos[j,iant1];
		basel +:= r*r;
	    }
	    private.MS.msrange.basel[i] := sqrt(basel);
	    # print s := paste(s,private.MS.msrange.basel[i],'(m)');
	}	

	private.tw.append('readMSranges(): finished');
	return T;
    }

#--------------------------------------------------------------------------
# Decoding user inputs (used in ms2uvbrick and externally):

    public.decode_fields := function(fields, test=F) {
    	if (!public.checkMS()) return F;
	field_ids := public.getMSrange('field_id');
	names := public.getMSrange('fields');
	return private.msb_select.decode_fields(fields, names, 
					field_ids, test=test);
    }

    public.decode_times := function (times, test=F) {
    	if (!public.checkMS()) return F;
	MJDtimes := public.getMSrange('times');
	return private.msb_select.decode_cs (times, MJDtimes, test=test) 
    }

    public.decode_fchs := function (fchs, test=F) {
    	if (!public.checkMS()) return F;
	chan_freq := public.getMSrange('chan_freq');
	return private.msb_select.decode_cs (fchs, chan_freq, test=test) 
    }

    public.decode_ifrs := function (ifrs, test=F) {
    	if (!public.checkMS()) return F;
	ifr_number := public.getMSrange('ifr_number');
	basel := public.getMSrange('basel');
	tel_name := public.getMSfield('tel_name');
	return private.msb_select.decode_ifrs (ifrs, ifr_number, 
					       basel, test=test, 
					       context=tel_name); 
    }

    public.decode_ants := function (ants, test=F) {
    	if (!public.checkMS()) return F;
	ant_id1 := public.getMSfield('ant_id1');
	ant_pos := public.getMSfield('ant_pos1D');
	tel_name := public.getMSfield('tel_name');
	return private.msb_select.decode_ants (ants, ant_id1, 
					       ant_pos, test=test, 
					       context=tel_name); 
    }

    public.decode_corrs := function(corrs, test=F) {
    	if (!public.checkMS()) return F;
	names := public.getMSrange('corr_names');
	types := public.getMSrange('corr_types');
	return private.msb_select.decode_corrs(corrs, names, 
					       types, test=test);
    }

    public.decode_pols := function(pols, test=F) {
    	if (!public.checkMS()) return F;
	pol_names := public.getMSfield('pol_names');
	pol_codes := public.getMSfield('pol_codes');
	return private.msb_select.decode_pols(pols, pol_names, 
					      pol_codes, test=test);
    }
    

#--------------------------------------------------------------------------
# Read MS data-brick and aux info, using msdo where possible, and mstable otherwise. 
# NB: For the moment, a uvbrick can only contain a single spectral window (or array):
#     But it can contain multiple fields (assuming its data-shapes are the same!). 

    public.ms2uvbrick := function(ref uvbrick, pp=[=], trace=F) { 
	wider private;
	if (!public.checkMS()) return F;

	tel_name := public.getMSfield('tel_name');	# use as switch....
	aux := [=];					# auxiliary information

	for (fname in "corrs ifrs fchs times") {
	    if (!has_field(pp,fname)) pp[fname] := '*';		# default (all)
	}
	if (!has_field(pp,'fields')) pp.fields := F;		# default (all)
	if (!has_field(pp,'datatypes')) pp.datatypes := 'data';	# default

	public.msdo_selectinit(pp.array_id, pp.spectral_window_id);	# check/select

	uvbrick.addtoaux (aux, 'msname', public.getMSfield('msshortname'));
	fnames := "tel_name spectral_window_id array_id";
	for (fname in fnames) {		
	    uvbrick.addtoaux (aux, fname, public.getMSfield(fname));
	}

	selrec := [=];						# msdo.select();

	rr := public.decode_ifrs (pp.ifrs);
	if (is_fail(rr)) print rr;				# problem
	selrec.ifr_number := rr.subset;

	rr := public.decode_times (pp.times);
	if (is_fail(rr)) print rr;				# problem
	selrec.times := rr.subset;
	if (rr.average) {
	    # s := paste('\n ** warning: time-averaging not supported here!');
	    # s := paste(s,'\n             use the uvbrick \'select\' operation.') 
	    # print s,'\n';
	    # return F;						# escape
	}

	axes := "field";		
	rr := public.decode_fields (pp.fields);
	if (is_fail(rr)) print rr;				# problem
	selrec.field_id := rr.subset;
	uvbrick.addtoaux (aux, 'field_id', selrec.field_id, axes);		
	uvbrick.addtoaux (aux, 'fields', pp.fields, axes);	# temporary		
	# uvbrick.addtoaux (aux, 'DECdeg', simrec.DECdeg, axes);		
	# uvbrick.addtoaux (aux, 'sinDEC', sin(simrec.DECdeg * deg2rad), axes);


	if (trace) print 'ms2uvbrick: msdo.select() input record selrec:';
	for (fname in field_names(selrec)) {
	    vv := selrec[fname];
	    s := paste(' - ',fname,':',type_name(vv),shape(vv));
	    s := paste(s,'value=',vv[min(5,len(vv))]);
	    if (len(vv)>5) s := spaste(s,'...'); 
	    if (trace) print s;
	}
	private.MS.msdo.select(selrec);				# msdo.select()

	rr := public.decode_corrs (pp.corrs);
	if (is_fail(rr)) print rr;				# problem
	if (trace) print 'ms2uvbrick: corrs=',rr.subset;
	private.MS.msdo.selectpolarization(rr.subset);

	rr := public.decode_fchs (pp.fchs);
	if (is_fail(rr)) print rr;				# problem
	if (trace) print 'ms2uvbrick: fchs=',rr.nout,rr.first,rr.nav,rr.ninc;
	private.MS.msdo.selectchannel(rr.nout,rr.first,rr.nav,rr.ninc);

	required := "axis_info u v";                            # "w uvdist"?
	required := [required,"HA UT LAST MJD97"];
	for (item in required) {
	    if (!any(pp.datatypes==item)) {
		if (trace) print 'ms2uvbrick: add required item:',item;
		pp.datatypes := [pp.datatypes, item];	        # always
	    }
	}
	if (trace) print 'ms2uvbrick: datatypes=',pp.datatypes;

	#--------------------------------------
	# print 'ms2uvbrick: reading of MS avoided (testing)'
	# return;
	#--------------------------------------
 
	private.tw.message('reading selected data from MS...');
	msrec := private.MS.msdo.getdata(pp.datatypes, ifraxis=T);
	if (is_fail(msrec)) {
	    print msrec;
	    private.tw.message('problem reading data from MS');
	    fail(msrec);
	}
	private.tw.message('finished reading data from MS');

	# Some information about the data:
	uvbrick.addtoaux (aux, 'data_descr', pp.datatypes[1]); # ??
	uvbrick.addtoaux (aux, 'data_descr', 'corr.coeff');    # vis?
	uvbrick.addtoaux (aux, 'data_unit', 'cc');             # Jy?

	axes := "ant";                                          # ant
	ant_id1 := public.getMSfield('ant_id1');
	ant_shortname := public.getMSfield('ant_shortname');
	ant_name := public.getMSfield('ant_name');
	ant_pos1D := public.getMSfield('ant_pos1D');
	uvbrick.addtoaux (aux, 'ant_shortname', ant_shortname, axes);	# first!	
	uvbrick.addtoaux (aux, 'ant_id1', ant_id1, axes);		
	uvbrick.addtoaux (aux, 'ant_name', ant_name, axes);		
	uvbrick.addtoaux (aux, 'ant_pos1D', ant_pos1D, axes);		

	axes := "pol";                                          # pol (?)
	pol_names := public.getMSfield('pol_names');		# ....?
	pol_codes := public.getMSfield('pol_codes');		# ....?
	uvbrick.addtoaux (aux, 'pol_name', pol_names, axes);		
	uvbrick.addtoaux (aux, 'pol_code', pol_codes, axes);		

	# Obsolete?
	# go through the ifrs, and select on antenna1/2.
	# ant1 := private.MS.mstable.getcol('ANTENNA1');
	# ant2 := private.MS.mstable.getcol('ANTENNA2');
	# uvw := private.MS.mstable.getcol('UVW');	# uu/vv[ifr,time]
	# field := private.MS.mstable.getcol('FIELD_ID');	# ifr_field[ifr], field[time]
	# axes := "ifr time"
	# uvbrick.addtoaux (aux, 'ifr_ucoord', uu, axes, kind='coord');		
	# uvbrick.addtoaux (aux, 'ifr_vcoord', vv, axes, kind='coord');		

	# private.selectinit();
	# items := "u v w uvdist";
	# private.getdata(items, ifraxis=[F,T]);

	private.tw.message('filling uv-brick....');
	r := uvbrick.fill(msrec, aux);		# fill uvbrick
	private.tw.message('finished filling uv-brick');
	return r;
    }

#--------------------------------------------------------------------------
# Read MS data-brick and aux info, using msdo where possible, and mstable otherwise. 
# NB: For the moment, a antbrick can only contain a single spectral window (or array):
#     But it can contain multiple fields (assuming its data-shapes are the same!). 

    public.ms2antbrick := function(ref antbrick, pp=[=], trace=F) { 
	wider private;
	if (trace) print '\n**********\n ms2antbrick():\n*************\n';
	if (!public.checkMS()) return F;

	tel_name := public.getMSfield('tel_name');	# use as switch....
	aux := [=];					# auxiliary information

	for (fname in "pols ants fchs times") {
	    if (!has_field(pp,fname)) pp[fname] := '*';		# default (all)
	}
	if (!has_field(pp,'fields')) pp.fields := F;		# default (all)
	if (!has_field(pp,'colname')) pp.colname := 'NFRA_TPOFF';	

	public.msdo_selectinit(pp.array_id, pp.spectral_window_id);	# check/select

	antbrick.addtoaux (aux, 'msname', public.getMSfield('msshortname'));
	fnames := "tel_name spectral_window_id array_id";
	for (fname in fnames) {		
	    antbrick.addtoaux (aux, fname, public.getMSfield(fname));
	}


	msrec := [=];                                           # data-record
	# msrec.data := ...
	# msrec.flag := ...
	# msrec.weight := ...
	msrec.axis_info := [=];
	# msrec.axis_info.time_axis.MJDseconds := ...;	     
	# msrec.axis_info.time_axis.UT := ...;	     
	# msrec.axis_info.time_axis.HA := ...;	     
	# msrec.axis_info.time_axis.LAST := ...;	     

	avant_id1 := public.getMSfield('ant_id1');        # available
	rr := public.decode_ants (pp.ants);
	if (is_fail(rr)) {
	    print rr;				          # problem
	    sv := rep(T,len(avant_id1));                  # use all
	} else {
	    sv := rep(F,len(avant_id1));                  # selection vector
	    for (i in ind(avant_id1)) {
		if (any(avant_id1[i]==rr.subset)) sv[i] := T;
	    }
	}
	for (fname in "ant_id1 ant_name ant_shortname ant_pos1D") {
	    vv := public.getMSfield(fname)[sv];                # select
	    msrec.axis_info.ant_axis[fname] := vv;	       # 
	}
	ant_id1 := msrec.axis_info.ant_axis.ant_id1;      # used below!
	nant := len(ant_id1);                             # used below!
	if (trace) print 'ms2antbrick: nant=',nant,' sv=',sv;

	avpol_names := public.getMSfield('pol_names');          # available
	rr := public.decode_pols (pp.pols);                     # specified
	if (is_fail(rr)) {
	    print rr;				                # problem
	    sv := rep(T,2);                                     # selection vector
	} else {
	    sv := rep(T,2);                                     # selection vector
	    for (i in ind(avpol_names)) {
		if (any(avpol_names[i]==rr.subset)) sv[i] := T;
	    }
	}
	pol_names := public.getMSfield('pol_names')[sv]; 
	pol_codes := public.getMSfield('pol_codes')[sv];	
	npol := len(pol_names);
	if (trace) print 'ms2antbrick: npol=',npol,' sv=',sv,pol_names,pol_codes;
	msrec.axis_info.pol_axis.pol_name := pol_names;	     
	msrec.axis_info.pol_axis.pol_code := pol_codes;	     

	# rr := public.decode_fchs (pp.fchs);
	# if (is_fail(rr)) print rr;				# problem
	# msrec.axis_info.freq_axis.chan_freq := rr.subset;
	# print 'ms2antbrick: fchs=',rr.nout,rr.first,rr.nav,rr.ninc;
	msrec.axis_info.freq_axis.chan_freq := [1.0];           # (Hz);	     
	msrec.axis_info.freq_axis.resolution := [1.0];          # (Hz);	     
	nfreq := len(msrec.axis_info.freq_axis.chan_freq);      # used below!
	if (trace) print 'ms2antbrick: nfreq=',nfreq;

        # Read the MS SYSCAL sub-table (locally, temporarily)	s
	s := 'reading selected ant data from MS...';
	if (trace) print s;
	private.tw.message(s);
	systab := table(private.MS.mstable.getkeyword("SYSCAL"));
	if (is_fail(systab)) {
	    print systab;
	    fail(systab);
	}

	array_id := public.getMSfield('array_id');      # one-relative
	array_id0 := max(0,array_id-1);                 # zero-relative
	arrid := systab.getcol('ARRAY_ID');
	sv := [arrid==array_id0];
	if (trace) print 'array_id0=',array_id0,'sv:',len(sv),len(sv[sv]);

	tt := systab.getcol('TIME')[sv];
	if (trace) print 'ntt=',len(tt),' range(relative)=',range(tt)-min(tt); 
	aa := systab.getcol('ANTENNA_ID')[sv];
	if (trace) print 'naa=',len(aa),' range(0-rel)=',range(aa);
	# NB: This table does not have a SPECTRAL_WINDOW_ID column!
	# sw := systab.getcol('SPECTRAL_WINDOW_ID')[sv];

	if (pp.colname=='derived_TPOFF/TPON' ||
	    pp.colname=='derived_TSYS_MULT') {
	    colname := "NFRA_TPON NFRA_TPOFF";
	} else if (pp.colname=='derived_TNOISE') {
	    colname := "NFRA_TPON NFRA_TPOFF TSYS";
	} else {
	    colname := pp.colname;
	}

	rr := [=];
	nrr := 0;
	for (name in colname) {
	    r := private.getsyscol (colname=name, systab=systab, trace=F,
				    aa=aa, tt=tt, sv=sv, ant_id1=ant_id1,
				    npol=npol, nant=nant, nfreq=nfreq);
	    if (is_fail(r)) {
		print r;
		fail(r);
	    }
	    rr[nrr+:=1] := r;
	    msrec.axis_info.time_axis.MJDseconds := r.MJDseconds;
	}
	systab.close();			 # close the SYSCAL table
	private.tw.message('finished reading data from MS');

	unit := ' ';
	if (pp.colname=='derived_TPOFF/TPON') {
	    msrec.data := rr[2].data/rr[1].data;
	} else if (pp.colname=='derived_TSYS_MULT') {
	    offon := rr[2].data/rr[1].data;
	    msrec.data := -(offon-1)/offon;
	} else if (pp.colname=='derived_TNOISE') {
	    offon := rr[2].data/rr[1].data;
	    qq := -(offon-1)/offon;
	    msrec.data := rr[3].data * qq;
            unit := 'K'; 
	} else {
	    msrec.data := rr[1].data;
	}

	# Some information about the data:
	antbrick.addtoaux (aux, 'data_descr', pp.colname);
	antbrick.addtoaux (aux, 'data_unit', unit);

	private.tw.message('filling ant-brick....');
	r := antbrick.fill_antbrick(msrec, aux);		# fill antbrick
	private.tw.message('finished filling ant-brick');
	return r;
    }


# Helper function to read a SYSCAL column

    private.getsyscol := function (colname, ref systab, aa=F, tt=F, 
				   sv=F, ant_id1=F, trace=T, 
				   npol=F, nant=F, nfreq=F, ntime=F) {

	if (trace) print 'getsyscol(',colname,'):';
	rr := [=];                            # output record
	dd := systab.getcol(colname);         # read the data
	ddim := shape(dd);       # [nrcp,ntime] or [nrcp,nchan,ntime]

	# Check data dimensions and select with sv:
	if (len(ddim) == 2) {                 # [nrcp,ntime]
	    dd := dd[,sv];                    # select              
	    ddim[2] := len(sv[sv]);
	    dd::shape := ddim;
	} else if (len(ddim) == 3) {          # [nrcp,nchan,ntime]
	    dd := dd[,,sv];                   # select
	    ddim[3] := len(sv[sv]);
	    dd::shape := ddim;
	} else {
	    print s := 'getsyscol: column data has wrong shape!';
	    fail(s);		
	}
	if (trace) print 'shape(dd)=',shape(dd),ddim;


	# Set up the data-array to be filled:
	nsv1_ref := 0;
	for (antid0 in [ant_id1-1]) {         # zero-relative
	    if (antid0==0) next;              # skip antid0=0
	    sv1 := [aa==antid0];              # selection vector
	    nsv1 := len(sv1[sv1]);            # selected length
	    if (nsv1==0) next;                # skip empty ones
	    nsv1_ref := nsv1;                 # reference length
	    rr.MJDseconds := tt[sv1];
	    ntime := nsv1_ref;
	    zero := 0*dd[1];                  # correct type
	    rr.data := array(zero,npol,nfreq,nant,ntime);  # initialise
	    if (trace) {
		print 'shape(rr.data)=',shape(rr.data),npol,nfreq,nant,ntime;
	    }
	    break;                            # OK, escape
	}
	if (nsv1_ref==0) {                    # none found
	    print s := paste('getsyscol: problem, none found');
	    fail(s);
	}


	# Sort the data from the MS column into the data-array:
	ifreq := 1;                           # temporary....
	iant := 0;
	for (antid0 in [ant_id1-1]) {         # zero-relative
	    iant +:= 1;                       # index in rr.data
	    sv1 := [aa==antid0];               # selection vector
	    nsv1 := len(sv1[sv1]);               # selected length
	    if (nsv1<=0) {                     # empty..?
		print 'getsyscol: no data for antid0=',antid0;
		next;                         # skip
	    } else if (nsv1!=nsv1_ref) {
		s := 'getsyscol: length mismatch for antid0=';
		s := paste(s,antid0,':',nsv1,'i.s.o',nsv1_ref);
		print s;
		next;                         # skip...
	    }
	    if (npol==1) {            # nr of SELECTED pols!
		ipol := 1;            # temporary (use SELECTED ipol!)
		rr.data[1,ifreq,iant,] := dd[ipol,sv1];
		mean := sum(rr.data[1,ifreq,iant,])/nsv1;
	    } else {
		for (ipol in [1:2]) {
		    rr.data[ipol,ifreq,iant,] := dd[ipol,sv1];
		}
		mean := sum(rr.data[,ifreq,iant,])/(2*nsv1);
	    }
	    if (trace) {
		print iant,'antid0=',antid0,': nsv1=',nsv1,'mean=',mean;
	    }
	}

	return rr;                            # return record
    }



#=========================================================
# Finished. Initialise and return the public interface:

    private.init();
    return public
};				# closing bracket
#=========================================================


# msbMS := test_msbrick_MS();	# run test-routine
# msbMS := msbrick_MS();		# create an msb object













