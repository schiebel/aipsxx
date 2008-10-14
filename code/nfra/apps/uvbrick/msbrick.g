# msbrick.g: User interface for uvbrick manipulation
# J.E.Noordam, june 1998

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
# $Id: msbrick.g,v 19.0 2003/07/16 03:38:49 aips2adm Exp $

#---------------------------------------------------------


pragma include once
# print 'include msbrick.g  w01sep99'

include 'msbrick_select.g';	# parameter selection functions
include 'msbrick_help.g';	# help text and functions
include 'msbrick_simul.g';	# uvbrick simulation functions
include 'msbrick_MS.g';		# MS interaction functions

include 'logger.g';

include 'jenguic.g'	        # boxmessage
# include 'guicomponents.g'	# tablechooser?
include 'inspect.g';		# includes textwindow, menubar etc
include 'textwindow.g';		# includes menubar, textformatting etc
# include 'tracelogger.g';
include 'buttonscript.g';	# script generation
include 'list.g';		# for data-groups/uvbricks 
include 'uvbrick.g';		# uvdata-bricks 
include 'profiler.g';		# also used for tracing/printing 


#=========================================================
test_msbrick := function () {
    msb := msbrick();
    return ref msb;
};

#=========================================================
msbrick := function (context='WSRT') {
    private := [=];
    public := [=];

    private.context := context;				# input argument

    private.init := function() {
	wider private, public;

	private.bricklist := list('bricks');		# uv/ant-bricks

	whenever private.bricklist.agent -> select do {	# new brick
	    private.currbrick := private.bricklist.get();	# reference
	    s := paste('msbrick: selected brick',$value);
	    print 'bricklist: current index=',private.bricklist.current();
	    # private.tw.append(s);
	}

	private.resultlist := list('results');		# interm.results

	whenever private.resultlist.agent -> select do {# selected
	    private.curresult := private.resultlist.get();	# reference
	    s := paste('msbrick: selected result',$value);
	    # private.tw.append(s);
	    print 'resultlist: current index=',private.resultlist.current();
    	    private.curresult_summary();	        # display summary
	}

	private.grouplist := list('data-groups');	# data-groups

	whenever private.grouplist.agent -> select do {	# new data-group
	    # s := paste('msbrick: selected data-group',$value);
	    # private.tw.append(s);
	    # private.tw.append(private.dlt.summary());	# display summary
	}

	private.uvbrick := uvbrick('dummy');	# empty brick, for functions only;

	private.currbrick := F;			# current brick
	private.brick_counter := 0;		# counter
	private.curresult := F;			# intermediary result
	private.result_counter := 0;		# counter

	private.msb_help := msbrick_help();
	private.msb_select := msbrick_select(private.context);
	private.msb_simul := msbrick_simul(private.context);
	private.msb_MS := msbrick_MS();
	whenever private.msb_MS.agent -> message do {
	    public.message($value);		# tw.message()
	}
	whenever private.msb_MS.agent -> text do {
	    public.text($value);		# tw.append()
	}

	private.trace := F;			# tracelogger
	private.tw := F;			# text-window (gui)
	private.pgw := F;			# pgplot widget
	private.guic := jenguic();              # boxmessage etc
	private.tf := textformatting();		# text-formatting functions
	private.bscr := buttonscript();		# script generation
	private.prof := profiler('msbrick');	# also tracing/printing
	private.launch();			# launch gui always

	private.bscr.verbatim ('msb := msbrick()');
    }


#=========================================================
# Public interface:

    public.agent := create_agent();	# communication

    public.gui := function(parentframe=F) {
	return private.launch();
    }
    public.openMS := function(name=F) {
	private.bscr.funcall('msb.openMS');
    	msname := private.msb_MS.openMS(name);
	if (is_fail(msname)) fail(msname);
	private.tw.label(paste('msbrick:',msname));
    	return private.msb_MS.getMSfield('msshortname');
    }
    public.closeMS := function() {
	private.bscr.funcall('msb.closeMS');
	r := private.msb_MS.closeMS();
	private.tw.label('msbrick: no MS open');
	return r;
    }
    public.checkMS := function(mess=T) {
	return private.msb_MS.checkMS(mess);
    }
    public.printtextwindow := function() {
	return private.tw.print();
    }
    public.cleartextwindow := function() {
	return private.tw.clear();
    }
    public.message := function (text) {
	if (is_record(private.tw)) {
	    private.tw.message(text);
	}
    }
    public.text := function (text) {
	if (is_record(private.tw)) {
	    private.tw.append(text);
	}
    }

    public.private := function(copy=F) {	# access to private part
	if (copy) return private;		# return a copy
	return ref private;			# return a reference
    }

    public.done() := function () {return public.dismiss()}
    public.dismiss := function() {
	if (is_record(private.tw)) private.tw.close();
    	private.dismiss ();
    }


#--------------------------------------------------------------
# Some private helper-functions
#--------------------------------------------------------------
# Print a hardcopy of the given text, using the given filename:

    private.print := function (txt=F, filename='/tmp/msbrick.print', 
			       trace=F, test=F) {
	return private.prof.print(txt=txt, filename=filename,
				  trace=trace, test=test);
   }

# Exit the program in an orderly manner: 

    private.dismiss := function() {
	wider private;
	trace := T;
	if (is_record(private.pgw)) {
	    if (trace) print 'msbrick.dismiss: private.pgw.done()';
	    private.pgw.done();
	}
	if (trace) print 'msbrick.dismiss:private.msb_MS.closeMS() ';
	private.msb_MS.closeMS();		# ....?
	if (trace) print 'msbrick.dismiss: private.bscr.close()';
	private.bscr.close();
	if (trace) print 'msbrick.dismiss: private.resultlist.delete()';
	private.resultlist.delete();
	if (trace) print 'msbrick.dismiss: private.resultlist.delete()';
	private.bricklist.delete();
	if (trace) print 'msbrick.dismiss: private.grouplist.delete()';
	private.grouplist.delete();
	if (trace) print 'msbrick.dismiss: val private := F';
	val private := F;			# ....?
    }

# Check the availability of a 'current' uvbrick:

    private.currbrick_inspect := function (origin=' ') {
	s := paste('currbrick_inspect:',origin);
	if (!private.currbrick_check(s, mess=T)) return F;
	private.currbrick.inspect();
	return T;
    }
    private.currbrick_showdata := function (origin=' ') {
	s := paste('currbrick_showdata:',origin);
	if (!private.currbrick_check(s, mess=T)) return F;
	s := private.currbrick.showdata('msbrick: current brick');
	private.tw.append(s);				# display
	return T;
    }
    private.currbrick_showaxisinfo := function (origin=' ') {
	s := paste('currbrick_showaxisinfo:',origin);
	if (!private.currbrick_check(s, mess=T)) return F;
	s := private.currbrick.showaxisinfo('msbrick: current brick');
	private.tw.append(s);				# display
	return T;
    }
    private.currbrick_showhistory := function (origin=' ') {
	s := paste('currbrick_showhistory:',origin);
	if (!private.currbrick_check(s, mess=T)) return F;
	s := private.currbrick.history();
	private.tw.append(s);				# display
	return T;
    }
    private.currbrick_showsize := function (origin=' ') {
	s := paste('currbrick_showsize:',origin);
	if (!private.currbrick_check(s, mess=T)) return F;
	s := private.currbrick.showsize();
	private.tw.append(s);				# display
	return T;
    }
    private.currbrick_showsummary := function (origin=' ') {
	s := paste('currbrick_showsummary:',origin);
	if (!private.currbrick_check(s, mess=F)) return F;
	s := private.currbrick.summary('msbrick: current brick');
	private.tw.append(s);				# display
	return T;
    }

    private.currbrick_list_attached := function() {
	if (private.currbrick_check(mess=F)) {
	    s := private.currbrick.list_attached();
	    print 'currbrick_list_attached:',s;
	    if (len(s)==0) return 'empty';
	    return s;
	}
	return 'no brick!'
    } 

    private.currbrick_check := function (origin=' ', uvant=F, mess=F) {
	# print 'private.currbrick_check(',origin,uvant,mess,')';
	r := private.is_brick(private.currbrick, uvant, mess);
	if (is_fail(r)) print r;
	if (r) return T;                               # OK
	if (mess) {                                    
	    s := paste(origin,': no suitable brick:');
	    s := paste(a,'of type:',uvant);
	    private.tw.message(s);
	    private.tw.menubar().givehelp(s);
	}
	return F;                                      # not OK 
    }

    private.currbrick_is_uvbrick := function (mess=T) {
	print 'msbrick.currbrick_is_uvbrick():';
	r := private.is_uvbrick (private.currbrick, mess=mess);
	if (!is_boolean(r)) {
	    s := paste('msbrick.currbrick_is_uvbrick() ->',type_name(r));
	} else if (r) {
	    return T;                                  # OK
	} else {
       	    s := 'current brick is not an uvbrick!'; 
	}
	private.tw.message(s);
	return s;
    }

    private.currbrick_is_antbrick := function (mess=T) {
	r := private.is_antbrick (private.currbrick, mess=mess);
	if (!is_boolean(r)) {
	    s := paste('msbrick.currbrick_is_antbrick() ->',type_name(r));
	} else if (r) {
	    return T;                                  # OK
	} else {
       	    s := 'current brick is not an antbrick!'; 
	}
	private.tw.message(s);
	return s;
    }


# Check whether the argument is a uvbrick/antbrick object:
    
    private.is_antbrick := function (ref brick=F, mess=F) {
	return private.is_brick (brick, 'antbrick', mess);
    }
    private.is_uvbrick := function (ref brick=F, mess=F) {
	return private.is_brick (brick, 'uvbrick', mess);
    }

    private.is_brick := function (ref brick=F, uvant=F, mess=F) {
	s := paste('is_brick(',type_name(brick),uvant,'):');
	if (!is_record(brick)) {
	    if (mess) print paste(s,'not a record!');
	} else if (!has_field(brick,'uvbrick')) {
	    if (mess) print paste(s,'no field: uvbrick!');
	    return F;	                       # not a brick object
	} else if (!has_field(brick,'type')) {
	    if (mess) print paste(s,'no field: brick.type!');
	    return F;		               # not a uvbrick
	} else if (is_boolean(uvant)) {        # type not specified
	    if (mess) print paste(s,'OK, any brick.type');
	    return T;                          # OK
	} else if (any(uvant==brick.type())) { # can be vector               
	    if (mess) print paste(s,'correct brick.type:',brick.type());
	    return T;                          # OK
	} else {
	    if (mess) print paste(s,'wrong brick.type:',brick.type());
	}
	return F;			       # not OK
    }


#------------------------------------------------------------------------
# Records of functions used in the parameter-interface, and their place-holders: 

    private.choice_uvb := [=];				# record of functions
    private.choice_ms := [=];				# record of functions
    private.choice_sim := [=];				# record of functions
    private.help_uvb := [=];				# record of functions
    private.help_ms := [=];				# record of functions
    private.help_sim := [=];				# record of functions
    private.gui_uvb := [=];				# record of functions
    private.gui_ms := [=];				# record of functions
    private.gui_sim := [=];				# record of functions
    private.test_uvb := [=];				# record of functions
    private.test_ms := [=];				# record of functions
    private.test_sim := [=];				# record of functions
    private.check_uvb := [=];				# record of functions
    private.check_ms := [=];				# record of functions
    private.check_sim := [=];				# record of functions
    private.decode_uvb := [=];				# record of functions

    for (fname in "corrs ifrs fchs times fields spwins arrays pols ants") {
    	private.test_ms[fname] := function(spec) {
    	    if (!public.checkMS()) return F;
	    return spaste('test_ms(',spec,') not yet implemented');
        }
    	private.test_uvb[fname] := function(spec) {
	    if (is_boolean(private.currbrick)) return F;
	    return spaste('test_uvb(',spec,') not yet implemented');
	}
    	private.test_sim[fname] := function(spec) {
	    return spaste('test_sim(',spec,') not yet implemented');
	}
    	private.help_ms[fname] := function() {
	    return spaste('help_ms.',fname,'() not yet implemented');
        }
    	private.help_uvb[fname] := function() {
	    return spaste('help_uvb.',fname,'() not yet implemented');
	}
    	private.help_sim[fname] := function() {
	    return spaste('help_sim.',fname,'() not yet implemented');
	}
    	private.gui_ms[fname] := function(current_value=F) {
	    return spaste('gui_ms.',fname,'() not yet implemented');
        }
    	private.gui_uvb[fname] := function(current_value=F) {
	    wider private;
	    print 'private.gui_uvb[fname]: current_value=',current_value;
	    private.tempguiagent := create_agent();
	    private.tempguiframe := frame(title=spaste('gui_uvb.default'),
					  side='left');
	    private.tempguibutton_1 := button(private.tempguiframe,'dismiss',
					    background='orange');
	    private.tempguibutton_2 := button(private.tempguiframe,'cancel',
					    background='red');
	    whenever private.tempguibutton_1 -> press do {    # mandatory
		private.tempguiagent -> dismiss('value from gui');
		deactivate whenever_stmts(private.tempguiagent).stmt;
		val private.tempguiframe := F;	              # remove gui
	    }
	    whenever private.tempguibutton_2 -> press do {    # mandatory
		private.tempguiagent -> cancel('gui cancelled');
		deactivate whenever_stmts(private.tempguiagent).stmt;
		val private.tempguiframe := F;	              # remove gui
	    }
	    return ref private.tempguiagent;	# wait for dismiss-event
	}
    	private.gui_sim[fname] := function(current_value=F) {
	    return spaste('gui_sim.',fname,'() not yet implemented');
	}
    	private.check_ms[fname] := function(value) {
	    # print spaste('check_ms(',value,') not yet implemented');
	    return T;					# ok, no action
        }
    	private.check_uvb[fname] := function(value) {
	    # print spaste('check_uvb(',value,') not yet implemented');
	    return T;					# ok, no action
	}
    	private.check_sim[fname] := function(value) {
	    # print spaste('check_sim(',value,') not yet implemented');
	    return T;					# ok, no action
	}
    	private.choice_ms[fname] := function() {
    	    if (!public.checkMS()) return F;
	    return private.msb_MS.getMSrange(fname);
        }
    	private.choice_uvb[fname] := function() {
	    if (is_boolean(private.currbrick)) return F;
	    return paste(private.currbrick.get(fname));	
        }
    	private.choice_sim[fname] := function() {
	    return T;			# private.msb_simul.get_simavail(fname)?
        }
    	private.decode_uvb[fname] := function(spec, test=F) {
	    return spaste('decode_uvb.',fname,'() not yet implemented');
	}
    }

    private.get_uvb := [=];				# record of functions
    private.get_ms := [=];				# record of functions

    for (fname in "name") {
    	private.get_uvb[fname] := function() {
	    if (is_boolean(private.currbrick)) return F;
	    return private.currbrick[fname]();
	}
    }

#------------------------------------------------------------------------
# Spectral-window selection: 

    private.help_ms.spwins := function () {
	s := paste('Selecting spectral windows from MS:')
	s := paste(s,'\n - A uvbrick contains a SINGLE spectral window.') 
	s := paste(s,'\n - Selecting more than one results in multiple bricks.') 
	return s; 
    }

    private.choice_ms.spwins := function () {
    	if (!public.checkMS()) return F;
	icurr := private.msb_MS.getMSfield('spectral_window_id');
	iirange := private.msb_MS.getMSrange('spectral_window_id');
	return private.msb_select.choice_spwins (iirange, icurr);
    }


#------------------------------------------------------------------------
# MS SYSCAL sub-table: column-names: 

    private.choice_ms.colnames_SYSCAL := function () {
    	if (!public.checkMS()) return F;
	print 'inside private.choice_ms.colnames_SYSCAL()';
	ss := private.msb_MS.getMSfield('colnames_SYSCAL');
	ss := [ss,"derived_TNOISE derived_TPOFF/TPON"];
	ss := [ss,"derived_TSYS_MULT"];
	return ss;
    }

#------------------------------------------------------------------------
# Array selection: 

    private.help_ms.arrays := function () {
	s := paste('Selecting spectral windows from MS:')
	s := paste(s,'\n - A uvbrick contains data from a SINGLE (sub-)array.') 
	s := paste(s,'\n - Selecting more than one results in multiple bricks.') 
	return s; 
    }

    private.choice_ms.arrays := function () {
    	if (!public.checkMS()) return F;
	icurr := private.msb_MS.getMSfield('array_id');
	iirange := private.msb_MS.getMSrange('array_id');
	return private.msb_select.choice_arrays (iirange, icurr);
    }

#------------------------------------------------------------------------
# Field-selection:

    private.choice_ms.fields := function () {
    	if (!public.checkMS()) return F;
	field_ids := private.msb_MS.getMSrange('field_id');
	names := private.msb_MS.getMSrange('fields');
	return private.msb_select.choice_fields(names, field_ids);
    }

    private.help_ms.fields := function() {
    	if (!public.checkMS()) return F;
	field_ids := private.msb_MS.getMSrange('field_id');
	names := private.msb_MS.getMSrange('fields');
	radec := private.msb_MS.getMSrange('radec');
    	return private.msb_select.help_fields(names, field_ids, radec);
    }

    private.test_ms.fields := function(fields) {
    	if (!public.checkMS()) return F;
	return private.msb_MS.decode_fields(fields, test=T)
    }

#------------------------------------------------------------------------
# Data-type selection:

    private.choice_uvb.datatype := function() {
	if (!private.currbrick_check()) return F;
	return private.currbrick.datatypes();
    }

    private.choice_ms.datatype := function() {
    	if (!public.checkMS()) return F;
	dt := "data corrected_data model_data";
	dt := [dt,"amplitude corrected_amplitude model_amplitude"];
	dt := [dt,"phase corrected_phase model_phase"];
	dt := [dt,"real corrected_real model_real"];
	dt := [dt,"imaginary corrected_imaginary model_imaginary"];
	return dt;
    }

#------------------------------------------------------------------------
# Decode the given corrs-string to select corrs for msdo.getdata:

    private.help_uvb.corrs := function() {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	return private.help_ms.corrs();
    }
    private.help_ms.corrs := function() {
    	if (!public.checkMS()) return F;
	return 'no help needed: the choice says it all'
    }

    private.choice_uvb.corrs := function () {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	cc := private.currbrick.get('corr_name');
	return private.msb_select.choice_corrs (cc, ms=F);	# tel_name....
    }
    private.test_ms.corrs := function(corrs) {
    	if (!public.checkMS()) return F;
	return private.msb_MS.decode_corrs(corrs, test=T)
    }
    private.choice_ms.corrs := function () {
    	if (!public.checkMS()) return F;
	cc := private.msb_MS.getMSrange('corr_names');
	return private.msb_select.choice_corrs (cc, ms=T);	# tel_name....
    }

    private.test_uvb.corrs := function(corrs) {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	return private.decode_uvb.corrs(corrs, test=T)
    }
    private.decode_uvb.corrs := function(corrs, test=F) {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	names := private.currbrick.get('corr_name');
	types := private.currbrick.get('corr_type');
	return private.msb_select.decode_corrs(corrs, names, types, test=test);
    }

#------------------------------------------------------------------------
# Decode the given corrs-string to select times for msdo.getdata:

    private.help_uvb.pols := function() {
	if (!private.currbrick_check(uvant='antbrick')) return F;
	return private.help_ms.pols();
    }
    private.help_ms.pols := function() {
    	if (!public.checkMS()) return F;
	return 'no help needed: the choice says it all'
    }
    private.choice_uvb.pols := function () {
	if (!private.currbrick_check(uvant='antbrick')) return F;
	cc := private.currbrick.get('pol_name');
	return private.msb_select.choice_pols (cc);	# tel_name....
    }
    private.test_ms.pols := function(pols) {
    	if (!public.checkMS()) return F;
	return private.msb_MS.decode_pols(pols, test=T)
    }
    private.choice_ms.pols := function () {
    	if (!public.checkMS()) return F;
	cc := private.msb_MS.getMSfield('pol_names');
	return private.msb_select.choice_pols (cc);	# tel_name....
    }

    private.test_uvb.pols := function(pols) {
	if (!private.currbrick_check(uvant='antbrick')) return F;
	return private.decode_uvb.pols(pols, test=T)
    }
    private.decode_uvb.pols := function(pols, test=F) {
	if (!private.currbrick_check(uvant='antbrick')) return F;
	names := private.currbrick.get('pol_name');
	codes := private.currbrick.get('pol_code');
	return private.msb_select.decode_pols(pols, names, codes, test=test);
    }


#------------------------------------------------------------------------
# Decode the given times-string to select times for msdo.getdata:

    private.help_uvb.times := function() {
	if (!private.currbrick_check()) return F;
	MJDtimes := private.currbrick.get('MJDseconds');
    	return private.msb_select.help_times(MJDtimes);
    }
    private.help_ms.times := function() {
    	if (!public.checkMS()) return F;
	MJDtimes := private.msb_MS.getMSrange('times');
    	return private.msb_select.help_times(MJDtimes);
    }

    private.choice_uvb.times := function() {
	if (!private.currbrick_check()) return F;
	MJDtimes := private.currbrick.get('MJDseconds');
    	return private.msb_select.choice_cs(MJDtimes);
    }
    private.choice_ms.times := function () {
    	if (!public.checkMS()) return F;
	MJDtimes := private.msb_MS.getMSrange('times');
    	return private.msb_select.choice_cs(MJDtimes);
    }

    private.test_uvb.times := function (times) {
	if (!private.currbrick_check()) return F;
	return private.decode_uvb.times (times, test=T);
    }
    private.test_ms.times := function (times) {
    	if (!public.checkMS()) return F;
	return private.msb_MS.decode_times (times, test=T);
    }

    private.decode_uvb.times := function (times, test=F) {
	if (!private.currbrick_check()) return F;
	MJDtimes := private.currbrick.get('MJDseconds');
	return private.msb_select.decode_cs (times, MJDtimes, test=test) 
    }


#------------------------------------------------------------------------
# Decode the given fchs-string to select fchs for msdo.selectchannel:

    private.help_uvb.fchs := function () {
	if (!private.currbrick_check()) return F;
	chan_freq := private.currbrick.get('chan_freq');
    	return private.msb_select.help_fchs(chan_freq);
    }
    private.help_ms.fchs := function() {
    	if (!public.checkMS()) return F;
	chan_freq := private.msb_MS.getMSrange('chan_freq');
    	return private.msb_select.help_fchs(chan_freq);
    }

    private.choice_uvb.fchs := function () {
	if (!private.currbrick_check()) return F;
	chan_freq := private.currbrick.get('chan_freq');
	return private.msb_select.choice_cs (chan_freq);
    }
    private.choice_ms.fchs := function () {
    	if (!public.checkMS()) return F;
	chan_freq := private.msb_MS.getMSrange('chan_freq');
	return private.msb_select.choice_cs (chan_freq);
    }

    private.test_uvb.fchs := function (fchs) {
	if (!private.currbrick_check()) return F;
	return private.decode_uvb.fchs (fchs, test=T);
    }
    private.test_ms.fchs := function (fchs) {
    	if (!public.checkMS()) return F;
	return private.msb_MS.decode_fchs (fchs, test=T);
    }

    private.decode_uvb.fchs := function (fchs, test=F) {
	if (!private.currbrick_check()) return F;
	chan_freq := private.currbrick.get('chan_freq');
	return private.msb_select.decode_cs (fchs, chan_freq, test=test) 
    }


#------------------------------------------------------------------------
# Decode the given ifr-string to select ifr-numbers from those available:

    private.help_uvb.ifrs := function () {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	ifr_number := private.currbrick.get('ifr_number');
	basel := private.currbrick.get('baseline');
	tel_name := private.currbrick.get('tel_name');
	return private.msb_select.help_ifrs (ifr_number, basel);  # tel_name....
    }
    private.help_ms.ifrs := function() {
    	if (!public.checkMS()) return F;
	ifr_number := private.msb_MS.getMSrange('ifr_number');
	basel := private.msb_MS.getMSrange('basel');
	return private.msb_select.help_ifrs (ifr_number, basel);  # tel_name....
    }
    private.help_sim.ifrs := function () {
	ifr_number := private.msb_simul.get_simavail('ifr_number');
	basel := private.msb_simul.get_simavail('basel');
	tel_name := private.msb_simul.get_simavail('tel_name');
    	return private.msb_select.help_ifrs(ifr_number, basel, tel_name);
    }

    private.choice_uvb.ifrs := function () {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	ifr_number := private.currbrick.get('ifr_number');
	basel := private.currbrick.get('baseline');
	tel_name := private.currbrick.get('tel_name');
    	return private.msb_select.choice_ifrs(ifr_number, basel);  # tel_name....
    }
    private.choice_ms.ifrs := function () {
    	if (!public.checkMS()) return F;
	ifr_number := private.msb_MS.getMSrange('ifr_number');
	basel := private.msb_MS.getMSrange('basel');
    	return private.msb_select.choice_ifrs(ifr_number, basel);  # tel_name....
    }
    private.choice_sim.ifrs := function () {
	ifr_number := private.msb_simul.get_simavail('ifr_number');
	basel := private.msb_simul.get_simavail('basel');
	tel_name := private.msb_simul.get_simavail('tel_name');
    	rr := private.msb_select.choice_ifrs(ifr_number, basel, tel_name);
	return rr;
    }

    private.test_ms.ifrs := function (ifrs) {
	return private.msb_MS.decode_ifrs (ifrs, test=T);
    }
    private.test_uvb.ifrs := function (ifrs) {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
        return private.decode_uvb.ifrs (ifrs, test=T);
    }
    private.test_sim.ifrs := function (ifrs) {
	return private.msb_simul.decode_ifrs (ifrs, test=T);
    }

    private.gui_uvb.ifrs := function(ifrs=F) {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	ifr_number := private.currbrick.get('ifr_number');
	basel := private.currbrick.get('baseline');
	tel_name := private.currbrick.get('tel_name');
	return private.msb_select.gui_ifrs (ifrs, ifr_number, 
					    basel, tel_name);
    }

    private.gui_ms.ifrs := function(ifrs=F) {
    	if (!public.checkMS()) return F;
	ifr_number := private.msb_MS.getMSrange('ifr_number');
	basel := private.msb_MS.getMSrange('basel');
	tel_name := 'WSRT';                            # temporary!!
	return private.msb_select.gui_ifrs (ifrs, ifr_number, 
					    basel, tel_name);
    }

    private.gui_sim.ifrs := function(ifrs=F) {
        print 'gui_sim.ifrs: ifrs=',ifrs;
	ifr_number := private.msb_simul.get_simavail('ifr_number');
	basel := private.msb_simul.get_simavail('basel');
	tel_name := private.msb_simul.get_simavail('tel_name');
	return private.msb_select.gui_ifrs (ifrs, ifr_number, 
					    basel, tel_name);
    }

    #-------------------------------------- temporary overwrite!
    private.gui_sim.ifrs := function(ifrs=F) {
	wider private;
        print '\n *** msbrick(local).gui_sim.ifrs:';
        print 'input: ifrs=',type_name(ifrs),shape(ifrs);

	ifr_number := private.msb_simul.get_simavail('ifr_number');
	basel := private.msb_simul.get_simavail('basel');
	tel_name := private.msb_simul.get_simavail('tel_name');

	ifrec := private.msb_select.decode_ifrs (ifrs, ifr_number, 
						 basel, test=F, 
						 context=tel_name);
	print 'decode_ifrs: ifrec.subset=',ifrec.subset;
	include 'msbrick_selection_gui.S.gui_g';

	private.selection_gui := msbrick_selection_gui_ifrs(ifrec.subset,
							    ifr_number,
							    basel=basel,
							    tel_name=tel_name);
	print 'selection_gui=',type_name(private.selection_gui);

	private.tempguiagent := create_agent();                 # mandatory
	whenever private.selection_gui.agent -> dismiss do {	# mandatory
	    private.tempguiagent -> dismiss($value);
	    val private.selection_gui := F;                     # remove gui
	    deactivate whenever_stmts(private.tempguiagent).stmt;
	}
	return ref private.tempguiagent;	# wait for dismiss-event
    }
    #---------------------------------------------


    private.decode_uvb.ifrs := function (ifrs, test=F) {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	ifr_number := private.currbrick.get('ifr_number');
	basel := private.currbrick.get('baseline');
	tel_name := private.currbrick.get('tel_name');
	return private.msb_select.decode_ifrs (ifrs, ifr_number, 
			basel, test=test, context=tel_name);
    }

#------------------------------------------------------------------------
# Decode the given ant-string to select ant-numbers from those available:

    private.help_uvb.ants := function () {
	if (!private.currbrick_check(uvant='antbrick')) return F;
	ant_id1 := private.currbrick.get('ant_id1');
	ant_pos1D := private.currbrick.get('ant_pos1D');
	tel_name := private.currbrick.get('tel_name');
	return private.msb_select.help_ants (ant_id1, ant_pos1D);  # tel_name....
    }
    private.help_ms.ants := function() {
    	if (!public.checkMS()) return F;
	ant_id1 := private.msb_MS.getMSfield('ant_id1');
	ant_pos1D := private.msb_MS.getMSfield('ant_pos1D');
	return private.msb_select.help_ants (ant_id1, ant_pos1D);  # tel_name....
    }
    private.help_sim.ants := function () {
	ant_id1 := private.msb_simul.get_simavail('ant_id1');
	ant_pos1D := private.msb_simul.get_simavail('ant_pos1D');
	tel_name := private.msb_simul.get_simavail('tel_name');
    	return private.msb_select.help_ants(ant_id1, ant_pos1D, tel_name);
    }

    private.choice_uvb.ants := function () {
	if (!private.currbrick_check(uvant='antbrick')) return F;
	ant_id1 := private.currbrick.get('ant_id1');
	ant_pos1D := private.currbrick.get('ant_pos1D');
	tel_name := private.currbrick.get('tel_name');
    	return private.msb_select.choice_ants(ant_id1, ant_pos1D);  # tel_name....
    }
    private.choice_uvb.ref_ant := function () {
	if (!private.currbrick_check()) return F;               # uvbrick/antbrick      
	ant_id1 := private.currbrick.get('ant_id1');
	ant_pos1D := private.currbrick.get('ant_pos1D');
	tel_name := private.currbrick.get('tel_name');
    	return private.msb_select.choice_refant(ant_id1, ant_pos1D);  # tel_name....
    }
    private.choice_ms.ants := function () {
    	if (!public.checkMS()) return F;
	ant_id1 := private.msb_MS.getMSfield('ant_id1');
	ant_pos1D := private.msb_MS.getMSfield('ant_pos1D');
    	rr := private.msb_select.choice_ants(ant_id1, ant_pos1D);  # tel_name....
	# The following is a bit of a kludge....
	if (is_record(rr)) rr[1] := '* (-E) (-F)';                 # WSRT!!
    	return rr;
    }
    private.choice_sim.ants := function () {
	ant_id1 := private.msb_simul.get_simavail('ant_id1');
	ant_pos1D := private.msb_simul.get_simavail('ant_pos1D');
	tel_name := private.msb_simul.get_simavail('tel_name');
    	rr := private.msb_select.choice_ants(ant_id1, ant_pos1D, tel_name);
	return rr;
    }

    private.test_ms.ants := function (ants) {
	return private.msb_MS.decode_ants (ants, test=T);
    }
    private.test_uvb.ants := function (ants) {
	if (!private.currbrick_check(uvant='antbrick')) return F;
        return private.decode_uvb.ants (ants, test=T);
    }
    private.test_sim.ants := function (ants) {
	r := private.msb_simul.decode_ants (ants, test=T);
	return private.msb_simul.decode_ants (ants, test=T);
    }

    private.decode_uvb.ants := function (ants, test=F) {
	if (!private.currbrick_check(uvant='antbrick')) return F;
	ant_id1 := private.currbrick.get('ant_id1');
	ant_pos1D := private.currbrick.get('ant_pos1D');
	tel_name := private.currbrick.get('tel_name');
	return private.msb_select.decode_ants (ants, ant_id1, 
			ant_pos1D, test=test, context=tel_name);
    }


#--------------------------------------------------------------------
# Calibrator selection:

    private.choice_calibrator := function () {
	# if (!private.currbrick_check(uvant='uvbrick')) return F;
    	return private.msb_select.choice_calibrator();
    }
    private.test_calibrator := function (cal) {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	fMHz := private.currbrick.fMHz();        # mean frequency
    	return private.msb_select.test_calibrator(cal, fMHz);
    }
    private.help_calibrator := function () {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	fMHz := private.currbrick.fMHz();        # mean frequency
    	return private.msb_select.help_calibrator(fMHz);
    }
    private.decode_calibrator := function (cal) {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	fMHz := private.currbrick.fMHz();        # mean frequency
    	return private.msb_select.decode_calibrator(cal, fMHz);
    }


#--------------------------------------------------------------------
# Antenna parameter selection (WSRT assumed!):

    private.choice_Tsys := function () {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	fMHz := private.currbrick.fMHz();        # mean frequency
    	return private.msb_select.choice_Tsys(fMHz);
    }
    private.help_Tsys := function () {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	fMHz := private.currbrick.fMHz();        # mean frequency
    	return private.msb_select.help_Tsys(fMHz);
    }

    private.choice_aperteff := function () {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	fMHz := private.currbrick.fMHz();        # mean frequency
    	return private.msb_select.choice_aperteff(fMHz);
    }
    private.help_aperteff := function () {
	if (!private.currbrick_check(uvant='uvbrick')) return F;
	fMHz := private.currbrick.fMHz();        # mean frequency
    	return private.msb_select.help_aperteff(fMHz);
    }

#================================================================================
#================================================================================
#================================================================================
# Make the msbrick gui:

     private.launch := function () {
	wider private;
	tk_hold();

    	private.tw := textwindow('msbrick')
    	whenever private.tw.agent->message do {
	    # print 'message:',$value;
    	}
    	whenever private.tw.agent->close do {
	    private.dismiss();
	    # print 'textwindow close event';
    	}

    	private.bricklist.gui(private.tw.menuframe());
    	private.resultlist.gui(private.tw.menuframe());
    	# private.grouplist.gui(private.tw.menuframe());

	private.make_menu_file();
	private.make_menu_brick();
	private.make_menu_decomp();
	private.make_menu_result();
	private.make_menu_misc();

	# # private.mbagent := private.tw.menubar().getmenuframe();
	# private.mbagent := private.tw.menubar().getbuttonframe();
	# private.appctrl := private.guic.appctrl(private.mbagent, 
	# 					help='msbrick');

	menu := 'help'
	defrec := private.tw.menubar().defrecinit('msbrick',menu);  
	private.tw.menubar().makemenuitem(defrec, private.help_msbrick1);    

	defrec := private.tw.menubar().defrecinit('manual',menu);  
	private.tw.menubar().makemenuitem(defrec, private.display_manual);    

	tk_release();
	return T;
    }

#-----------------------------------------------------------------
# Display a 'manual' consisting of the various help-texts:
# The textwindow is cleared first, so that only the manual may be printed (?);

    private.display_manual := function () {
	private.tw.clear();				# clear the textwindow
	sep := paste('\n',rep('-',25));			# separator

	s := 'introduction and overview:';
	private.tw.append(paste('\n',sep,'\n',s,sep,'\n\n'));
	private.tw.append(private.help_msbrick());

	s := 'selection syntax for ifr/freq/time:'
	private.tw.append(paste('\n',sep,'\n',s,sep,'\n\n'));
	ifr_number := [1002,2003,3004,1003,2004,1004];
	basel := [144,144,144,288,288,432]; 
	private.tw.append(private.msb_select.help_ifrs(ifr_number, basel));
	chan_freq := 327 + [0:255]*0.1;
	private.tw.append(private.msb_select.help_fchs(chan_freq));
	MJDtimes := [0:719]*120;			# add large number (sec)
	private.tw.append(private.msb_select.help_times(MJDtimes));

	s := 'some packaged routines:'
	private.tw.append(paste('\n',sep,'\n',s,sep,'\n\n'));
	for (fname in "bandpass timepoly") {
	    private.tw.append(private.helptext[fname]());
	}
	return T;
    }


    private.help_msbrick1 := function() {
	private.tw.menubar().givehelp(private.help_msbrick());
    }

    private.help_msbrick := function() {
	return private.msb_help.show('msbrick');
    }


#-----------------------------------------------------------------
# File menu (MS etc)

    private.make_menu_file := function(menu='file') {

	defrec := private.tw.menubar().defrecinit('open MS',menu);
	private.tw.menubar().makemenuitem(defrec, public.openMS);

	defrec := private.tw.menubar().defrecinit('[open MS]',menu);
	defrec.paramchoice.funcname := 'openMS';
	defrec.paramhide.funcname := T;
	defrec.prompt := 'Open an MS';
	ss := 'use filechooser';
	ss := [ss,'/data1/...MS'];
	ss := [ss,'/dzbdat/tms/...MS'];
	ss := [ss,'./...MS'];
	defrec.paramchoice.MSname := ss;
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('close MS',menu); 
	private.tw.menubar().makemenuitem(defrec, public.closeMS); 

	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);	#------------------
	#--------------------------------------------

	defrec := private.tw.menubar().defrecinit('show MS summary',menu); 
	private.tw.menubar().makemenuitem(defrec, private.msb_MS.summaryMS); 

	defrec := private.tw.menubar().defrecinit('show msdo summary',menu); 
	private.tw.menubar().makemenuitem(defrec, private.msb_MS.summaryMSdo); 


	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);	
	#--------------------------------------------
	submenu := private.tw.menubar().makemenu('inspect MS',menu)

	defrec := private.tw.menubar().defrecinit('inspect MS table', submenu); 
	private.tw.menubar().makemenuitem(defrec, private.msb_MS.inspectMS); 

	defrec := private.tw.menubar().defrecinit('inspect msdo', submenu); 
	private.tw.menubar().makemenuitem(defrec, private.msb_MS.inspectMSdo); 

	defrec := private.tw.menubar().defrecinit('inspect MS record', submenu); 
	private.tw.menubar().makemenuitem(defrec, private.msb_MS.inspectMSrecord); 

	defrec := private.tw.menubar().defrecinit('msdo.selectinit()', menu);
	defrec.paramchoice.funcname := 'msdo_selectinit';
	defrec.paramhide.funcname := T;
	defrec.prompt := 'Test of msdo.selectinit'
	for (fname in "spwins arrays") {
	    defrec.paramshape[fname] := 'vector';
	    defrec.paramchoice[fname] := ref private.choice_ms[fname];
	    defrec.paramtest[fname] := ref private.test_ms[fname];
	    defrec.paramcheck[fname] := ref private.check_ms[fname];
	    defrec.paramhelp[fname] := ref private.help_ms[fname];
	}
	private.tw.menubar().makemenuitem(defrec, private.menuaction);
 
	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);
	#--------------------------------------------
    	private.tw.standardmenuitem('print');    
    	private.tw.standardmenuitem('printcommand');    
    	private.tw.standardmenuitem('clear');    

	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);
	#--------------------------------------------
   	private.tw.standardmenuitem('dismiss');    

	return T;
    }

#-----------------------------------------------------------------

    private.make_menu_ms2uvbrick := function(ref menu=F) {

	defrec := private.tw.menubar().defrecinit('general uvbrick',menu); 
	defrec.prompt := 'Specify extraction parameters'
	defrec.paramchoice.funcname := 'get_uvbrick';
	defrec.paramhide.funcname := T;

	for (fname in "spwins arrays corrs fchs ifrs times fields") {
	    defrec.paramshape[fname] := 'vector';
	    defrec.paramchoice[fname] := ref private.choice_ms[fname];
	    defrec.paramtest[fname] := ref private.test_ms[fname];
	    defrec.paramcheck[fname] := ref private.check_ms[fname];
	    defrec.paramhelp[fname] := ref private.help_ms[fname];
	}
	# defrec.paramgui.ifrs := ref private.gui_ms.ifrs;

	defrec.paramchoice.datatype := ref private.choice_ms.datatype;
	defrec.paramchoiceonly.datatype := T;
	defrec.paramhelp.datatype := 'a uv-brick contains a single type';

	defrec.paramchoice.incl_flags := [T, F];
	defrec.paramhelp.incl_flags := 'if T, include flag-brick';

	defrec.paramchoice.incl_weights := [F, T];
	defrec.paramhelp.incl_weights := 'if T, include weightbrick (size!)';

	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	return T;
    }

#-----------------------------------------------------------------

    private.make_menu_ms2antbrick := function(ref menu=F) {

	defrec := private.tw.menubar().defrecinit('MS.SYSCAL column',menu); 
	defrec.prompt := 'Specify extraction parameters'
	defrec.paramchoice.funcname := 'get_antbrick';
	defrec.paramhide.funcname := T;
	for (fname in "ants pols fchs times") {
	    defrec.paramshape[fname] := 'vector';
	    defrec.paramchoice[fname] := ref private.choice_ms[fname];
	    defrec.paramtest[fname] := ref private.test_ms[fname];
	    defrec.paramcheck[fname] := ref private.check_ms[fname];
	    defrec.paramhelp[fname] := ref private.help_ms[fname];
	}
	defrec.paramchoice.colname := private.choice_ms.colnames_SYSCAL;
	defrec.paramchoiceonly.colname := T;
	defrec.paramhelp.colname := 'from MS SYSCAL table';
	defrec.paramchoice.plot := [T,F];
	defrec.paramchoiceonly.plot := T;
	private.tw.menubar().makemenuitem(defrec, private.menuaction);


	defrec := private.TOPOR_basic ('for TOPOR (WSRT)', menu=menu);
	defrec.prompt := 'Specify antbrick for TOPOR (WSRT)'
	defrec.paramchoice.funcname := 'TOPOR';
	for (fname in "ants pols") {
	    defrec.paramshape[fname] := 'vector';
	    defrec.paramhide[fname] := F;         # see TOPOR_basic()
	    defrec.paramchoice[fname] := ref private.choice_ms[fname];
	    defrec.paramtest[fname] := ref private.test_ms[fname];
	    defrec.paramcheck[fname] := ref private.check_ms[fname];
	    defrec.paramhelp[fname] := ref private.help_ms[fname];
	}
	defrec.paramchoice.colname := "NFRA_TPOFF";
	defrec.paramhide.colname := T;
	defrec.paramchoice.plot := [F,T];
	defrec.paramchoiceonly.plot := T;
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	return T;
    }
    

#----------------------------------------------------------------------------
# Uvbrick plot menu:

    private.make_menu_plot := function(ref menu=F) {

	defrec := private.tw.menubar().defrecinit('uvdata-slices',menu); 
	defrec.prompt := 'Specify plotting parameters'
	defrec.onlyif := private.currbrick_is_uvbrick;
	defrec.paramchoice.funcname := 'plot_data_slices';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.datatype := ref private.choice_uvb.datatype;
	s := "freq time HA UT LAST MJD97 uvdist ifr corr";
	# s := [s,"RA DEC"];				# [ant,time]....	
	defrec.paramchoice.xaxis := s;
	defrec.paramhelp.xaxis := 'x-axis of plotted slice(s)';	
	defrec.paramchoice.group := "ifr corr freq time";	
	defrec.paramhelp.group := 'the items in a group are plotted together';	
	s := "ampl phase_rad phase_deg logampl real_part imag_part real-imag";	
	defrec.paramchoice.cx2real := s;
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('FIT (bandpass)',menu); 
	defrec.onlyif := private.currbrick_is_uvbrick;
	defrec.paramchoice.funcname := 'plot_data_FIT';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.datatype := ref private.choice_uvb.datatype;
	defrec.paramchoice.xaxis := 'freq';
	defrec.paramchoice.group := "ifr";	
	defrec.paramchoice.cx2real := "ampl";
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('TIF',menu); 
	defrec.onlyif := private.currbrick_is_uvbrick;
	defrec.paramchoice.funcname := 'plot_data_TIF';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.datatype := ref private.choice_uvb.datatype;
	defrec.paramchoice.xaxis := 'time';
	defrec.paramchoice.group := "ifr";	
	defrec.paramchoice.cx2real := "ampl";
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('RIF',menu); 
	defrec.onlyif := private.currbrick_is_uvbrick;
	defrec.paramchoice.funcname := 'plot_data_RIF';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.datatype := ref private.choice_uvb.datatype;
	defrec.paramchoice.xaxis := 'uvdist';
	defrec.paramchoice.group := "ifr";	
	defrec.paramchoice.cx2real := "ampl";
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('uvdata statistics',menu); 
	defrec.prompt := 'Specify statistics parameters'
	defrec.onlyif := private.currbrick_is_uvbrick;
	defrec.paramchoice.funcname := 'statistics';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.datatype := ref private.choice_uvb.datatype;
	defrec.paramshape.variable := 'vector';	
	defrec.paramchoice.variable := [=]; n := 0;	
	defrec.paramchoice.variable[n+:=1] := "freq";
	defrec.paramchoice.variable[n+:=1] := "time";
	defrec.paramchoice.variable[n+:=1] := "corr";
	defrec.paramchoice.variable[n+:=1] := "ifr";
	defrec.paramchoice.variable[n+:=1] := "corr ifr";
	defrec.paramchoice.variable[n+:=1] := "ifr time";
	defrec.paramchoice.variable[n+:=1] := "corr ifr time";
	defrec.paramhelp.variable := 'variable axes';	
	s := "ampl logampl phase_rad phase_deg real_part imag_part none";	
	defrec.paramchoice.cx2real := s;
	defrec.paramchoice.plot := [T,F];
	defrec.paramchoice.print := [F,T];
	# private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('uv-coverage',menu); 
	defrec.prompt := 'Specify uvcoverage plotting parameters';
	defrec.onlyif := private.currbrick_is_uvbrick;
	defrec.paramchoice.funcname := 'uvcoverage';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.unit := "meter wavelength";	
	defrec.paramchoiceonly.unit := T;	
	# defrec.paramchoice.xygrid := [F,T];	
	# defrec.paramchoiceonly.xygrid := T;	
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);
	#--------------------------------------------

	defrec := private.tw.menubar().defrecinit('ant-slices',menu); 
	defrec.prompt := 'Specify plotting parameters';
	defrec.onlyif := private.currbrick_is_antbrick;
	defrec.paramchoice.funcname := 'plot_data_slices';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.datatype := ref private.choice_uvb.datatype;
	defrec.paramchoice.xaxis := "time freq";
	defrec.paramhelp.xaxis := 'x-axis of plotted slice(s)';	
	defrec.paramchoice.group := "ant pol freq time";	
	defrec.paramhelp.group := 'the items in a group are plotted together';	
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	return T;
    }

#----------------------------------------------------------------------------
# Uvbrick inspect menu:

    private.make_menu_inspect := function(ref menu=F) {

	defrec := private.tw.menubar().defrecinit('brick history', menu); 
	private.tw.menubar().makemenuitem(defrec, private.currbrick_showhistory);

	defrec := private.tw.menubar().defrecinit('brick size', menu);
	private.tw.menubar().makemenuitem(defrec, private.currbrick_showsize);

	defrec := private.tw.menubar().defrecinit('brick axis info', menu); 
	private.tw.menubar().makemenuitem(defrec, private.currbrick_showaxisinfo);

	defrec := private.tw.menubar().defrecinit('brick summary', menu); 
	private.tw.menubar().makemenuitem(defrec, private.currbrick_showsummary);

	defrec := private.tw.menubar().defrecinit('brick data (!)', menu); 
	private.tw.menubar().makemenuitem(defrec, private.currbrick_showdata);

	defrec := private.tw.menubar().defrecinit('inspect brick', menu); 
	private.tw.menubar().makemenuitem(defrec, private.currbrick_inspect);

	defrec := private.tw.menubar().defrecinit('inspect attached', menu);
	defrec.prompt := 'Select attached info to be inspected'
	s := paste('Some applications attach records with specific information',
		   '\n   to a brick, to be used during processing.',
		   '\n Examples are WSRT applications MAKECAL and ELFI.',
		   '\n These records may be inspected in detail here.',
		   '\n ');
	defrec.help := s;
	defrec.paramchoice.funcname := 'inspect_attached';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.attached := ref private.currbrick_list_attached;
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	return T;
    }


#-----------------------------------------------------------------
# uv-brick simulation menu:

    private.make_menu_simul := function(ref menu=F) {

	defrec := private.simul_basic ('general uvbrick',menu);
	defrec.paramchoice.source[1] := "double_far";
	private.tw.menubar().makemenuitem(defrec, private.menuaction);


	defrec := private.simul_basic ('uvbrick for ant_decomp',menu);
	s := paste('Antenna decomposition of dipole (receptor) errors:',
		   '\n - receptor phase-zeroes:     uses XX/YY, applied to all',
		   '\n - receptor gain factors:     uses XX/YY, applied to all',
		   '\n - dipole position errors:    uses XY/YX, applied to self',
		   '\n - receptor ellipticities:    uses XY/YX, applied to self',
		   '\n - X/Y phase-zero difference: uses XY/YX, applied to all',
		   '\n ',
		   '\n Procedure:',
		   '\n 1: Simulate a suitable uvbrick.',
		   '\n 2: Corrupt the data, using the \'corrupt\' option.',
		   '\n 3: Use suitable option in \'decomp\' menu to decompose.',
		   '\n NB: If multiple categories of simulated errors,',
		   '\n     solve for them in the above order.',
		   '\n ');
	defrec.help := s;
	defrec.prompt := 'Simulation of a uv-brick for antenna decomposition'
	defrec.paramchoice.name := 'simul_antdecomp';	
	defrec.paramchoice.fMHz := [=]; n := 0;			# reset
	defrec.paramchoice.fMHz[n+:=1] := [1,327.0,1.0];	# one channel
	defrec.paramchoice.fMHz[n+:=1] := [10,327.0,1.0];	# multiple channels
	defrec.paramchoice.HAdeg := [=]; n := 0;
	defrec.paramchoice.HAdeg[n+:=1] := [5,0.0,1.0];		# 5 time slots
	defrec.paramchoice.corrs := [=]; n := 0;
	defrec.paramchoice.corrs[n+:=1] := "XX XY YX YY";
	defrec.paramchoice.corrs[n+:=1] := "XX YY";
	defrec.paramchoice.corrs[n+:=1] := "XY YX";
	defrec.paramchoice.source := "point_central";
	defrec.paramhide.bandpass := T;
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.simul_basic ('uvbrick for delay offset',menu);
	s := paste('Antenna decomposition of receptor delay offsets:',
		   '\n Procedure:',
		   '\n 1: Simulate a suitable uvbrick.',
		   '\n 2: Corrupt the data, using the \'corrupt\' option.',
		   '\n 3: Use option \'decomp delay_offset\' to decompose.',
		   '\n ');
	defrec.help := s;
	defrec.prompt := 'Simulation of a uv-brick for delay offsets'
	defrec.paramchoice.name := 'simul_antdecomp';	
	defrec.paramchoice.fMHz := [=]; n := 0;			# reset
	defrec.paramchoice.fMHz[n+:=1] := [10,327.0,1.0];	# multiple channels
	defrec.paramchoice.HAdeg := [=]; n := 0;
	defrec.paramchoice.HAdeg[n+:=1] := [5,0.0,1.0];		# 5 time slots
	defrec.paramchoice.corrs := [=]; n := 0;
	defrec.paramchoice.corrs[n+:=1] := "XX XY YX YY";
	defrec.paramchoice.corrs[n+:=1] := "XX YY";
	defrec.paramchoice.source := "point_central";
	defrec.paramhide.source := T;
	defrec.paramhide.bandpass := T;
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);	
	#--------------------------------------------

	defrec := private.simul_basic ('uvbrick for DELFI',menu);
	defrec.prompt := 'Simulation of a uv-brick for \'DELFI\''
	defrec.paramchoice.name := 'simul_DELFI';	
	defrec.paramchoice.fMHz := [=]; n := 0;			# reset
	defrec.paramchoice.fMHz[n+:=1] := [1,327.0,5.0];	# one channel
	defrec.paramchoice.fMHz[n+:=1] := [1,1412.0,5.0];	# one channel
	defrec.paramchoice.fMHz[n+:=1] := [1,4950.0,5.0];	# one channel
	defrec.paramchoice.HAdeg := [=]; n := 0;
	defrec.paramchoice.HAdeg[n+:=1] := [20,0.0,1.0];	# 20 slots
	s := paste('The DELFI antenna decomposition has an arbitrary delay-zero point',
		   '\n With XX/YY only, there will be a X/Y delay-difference!',
		   '\n This will cause decorrelation in the XY/YX corrs!',
		   '\n\n By including XY/YX in DELFI, this problem disappears.',
		   '\n In this case, the calibrator should have some Stokes U,',
		   '\n   in order to have sufficient signal in XY/YX.');
	defrec.paramhelp.corrs := paste(s,'\n\n',defrec.paramhelp.corrs);
	defrec.paramchoice.corrs := [=]; n := 0;
	defrec.paramchoice.corrs[n+:=1] := "XX YY";
	defrec.paramchoice.corrs[n+:=1] := "XX XY YX YY";
	defrec.paramchoice.source := "point_central";
	defrec.paramchoice.flux_IQUV := [=]; n := 0;
	defrec.paramchoice.flux_IQUV[n+:=1] := [1.0,0,0,0];	# unpolarised
	defrec.paramchoice.flux_IQUV[n+:=1] := [1.0,0,0.1,0];	# 10% U 
	defrec.paramhide.bandpass := T;
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.simul_basic ('uvbrick for MAKECAL',menu);
	defrec.prompt := 'Simulation of a uv-brick for \'MAKECAL\''
	defrec.paramchoice.name := 'simul_MAKECAL';	
	defrec.paramchoice.DECdeg := [=]; n := 0;
	defrec.paramchoice.DECdeg[n+:=1] := [20.0,40.0,60.0,80.0];
	defrec.paramchoice.fMHz := [=]; n := 0;			# reset
	defrec.paramchoice.fMHz[n+:=1] := [1,1412.0,1.0];	# one channel
	defrec.paramchoice.fMHz[n+:=1] := [1,4950.0,1.0];	# one channel
	defrec.paramchoice.HAdeg := [=]; n := 0;
	defrec.paramchoice.HAdeg[n+:=1] := [20,-10.0,1.0];	# 20 slots
	defrec.paramchoice.corrs := [=]; n := 0;
	defrec.paramchoice.corrs[n+:=1] := "XX YY";
	defrec.paramchoice.source := "point_central";
	defrec.paramchoice.flux_IQUV := [=]; n := 0;
	defrec.paramchoice.flux_IQUV[n+:=1] := [1.0,0,0,0];	# unpolarised
	defrec.paramhide.bandpass := T;
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.simul_basic ('uvbrick for POINTING',menu);
	defrec.prompt := 'Simulation of a uv-brick for \'POINTING\''
	defrec.paramchoice.name := 'simul_POINTING';	
	defrec.paramchoice.DECdeg := [=]; n := 0;
	defrec.paramchoice.DECdeg[n+:=1] := [-20,10,50];
	defrec.paramchoice.DECdeg[n+:=1] := [-20,-10,0,20,50,80.0];
	defrec.paramchoice.fMHz := [=]; n := 0;			# override
	defrec.paramchoice.fMHz[n+:=1] := [1,1412.0,1.0];	# one channel
	defrec.paramchoice.fMHz[n+:=1] := [1,4950.0,1.0];	# one channel
	defrec.paramchoice.HAdeg := [=]; n := 0;		# override
	defrec.paramchoice.HAdeg[n+:=1] := [40,-20.0,1.0];	# nDECdeg*12 slots
	defrec.paramchoice.HAdeg[n+:=1] := [100,-80.0,1.0];	# nDECdeg*12 slots
	defrec.paramchoice.corrs := [=]; n := 0;		# override
	defrec.paramchoice.corrs[n+:=1] := "XX YY";
	defrec.paramchoice.source := "point_central";
	defrec.paramchoice.flux_IQUV := [=]; n := 0;
	defrec.paramchoice.flux_IQUV[n+:=1] := [1.0,0,0,0];	# unpolarised
	defrec.paramhide.bandpass := T;
	private.tw.menubar().makemenuitem(defrec, private.menuaction);


	defrec := private.simul_basic ('uvbrick for CI',menu);
	defrec.prompt := 'Simulation of a uv-brick with CI obs'
	defrec.paramchoice.name := 'simul_CI';	
	defrec.paramchoice.fMHz := [=]; n := 0;			# reset
	defrec.paramchoice.fMHz[n+:=1] := [4096,850.0,0.001];	# 4096 channel
	defrec.paramchoice.HAdeg := [=]; n := 0;
	defrec.paramchoice.HAdeg[n+:=1] := [5,0.0,1.0];		# 5 time slots
	defrec.paramchoice.corrs := [=]; n := 0;
	defrec.paramchoice.corrs[n+:=1] := "XX YY";
	defrec.paramchoice.ifrs := [=]; n := 0;			# override
	defrec.paramchoice.ifrs[n+:=1] := '6.A 7.B 8.C 9.D -*=';
	defrec.paramchoice.source := "point_central";
	defrec.paramchoice.bandpass := [T,F];
	defrec.paramchoice.centralpeak := [T,F];
	defrec.paramhide.sep9A := T;
	private.tw.menubar().makemenuitem(defrec, private.menuaction);


	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);	
	#--------------------------------------------

	defrec := private.simul_basic_antbrick ('antbrick',menu);
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	return T;
    }

# Helper function: create a basic defrec for brick simulation:

    private.simul_basic := function (name, menu='simulate') {
	defrec := private.tw.menubar().defrecinit(name,menu); 
	defrec.prompt := 'Specify simulation parameters';
	defrec.refresh := T;			# test: refresh panel
	defrec.paramchoice.funcname := 'sim_uvbrick';
	defrec.paramhide.funcname := T;

	private.simul_basic_item('telescope', defrec);
	private.simul_basic_item('fMHz', defrec);
	private.simul_basic_item('HAdeg', defrec);

	defrec.paramhelp.corrs := ' ';
	defrec.paramshape.corrs := 'vector';
	defrec.paramchoice.corrs := [=]; n := 0;
	defrec.paramchoice.corrs[n+:=1] := "XX YY";
	defrec.paramchoice.corrs[n+:=1] := "XX XY YX YY";
	defrec.paramchoice.corrs[n+:=1] := "XY YX";
	defrec.paramchoice.corrs[n+:=1] := "XX";
	defrec.paramchoice.corrs[n+:=1] := "YY";
	defrec.paramchoice.corrs[n+:=1] := "RR RL LR LL";
	defrec.paramchoice.corrs[n+:=1] := "RR LL";
	defrec.paramchoice.corrs[n+:=1] := "RL LR";
	defrec.paramchoice.corrs[n+:=1] := "RR";
	defrec.paramchoice.corrs[n+:=1] := "LL";

	defrec.paramshape.ifrs := 'vector';
	defrec.paramchoice.ifrs := ref private.choice_sim.ifrs;
	defrec.paramtest.ifrs := ref private.test_sim.ifrs;
	defrec.paramcheck.ifrs := ref private.check_sim.ifrs;
	defrec.paramhelp.ifrs := ref private.help_sim.ifrs;
	defrec.paramgui.ifrs := ref private.gui_sim.ifrs;
	# Override private.choice_sim.ifrs():
	defrec.paramchoice.ifrs := [=]; n := 0;
	defrec.paramchoice.ifrs[n+:=1] := '([1:5].[2:7])  (-*=) -3';
	defrec.paramchoice.ifrs[n+:=1] := '(f.m)';      # fixed-movable only
	defrec.paramchoice.ifrs[n+:=1] := '[0:3].[0:3] (-*=)';
	defrec.paramchoice.ifrs[n+:=1] := '([1:2].[3:4]) ([6:7].[7:9]) (-*=)';
	defrec.paramchoice.ifrs[n+:=1] := '(*) (-*=) (-L>150)';
	defrec.paramchoice.ifrs[n+:=1] := '(*) (-[E,F]) (-*=)';

	private.simul_basic_item('sep9A', defrec);

	s := paste('Declination (degr) of field centre(s)',
		   '\n The number of values controls the number of fields.',	
		   '\n ');	
	defrec.paramhelp.DECdeg := s;
	defrec.paramshape.DECdeg := 'vector';
	defrec.paramchoice.DECdeg := [=]; n := 0;
	defrec.paramchoice.DECdeg[n+:=1] := 30.0;
	defrec.paramchoice.DECdeg[n+:=1] := [20.0,40.0,60.0,80.0];

	s := paste('Simulated source distribution:',
		   '\n                  flux(Jy)      l     m*sinDEC',	
		   '\n - point_central:   IQUV       0.0       0.0',	
		   '\n - point_close:     IQUV       0.1       0.1',	
		   '\n - point_far:       IQUV       2.0       2.0',	
		   '\n - double_close:    IQUV      -0.01     -0.01',	
		   '\n                   0.1*I       0.09      0.09',	
		   '\n - double_far:      IQUV      -0.2      -0.2',	
		   '\n                   0.1*I       1.8       1.8',	
		   '\n - double_equal:    IQUV      -0.6      -0.6',	
		   '\n                   1.0*I       1.4       1.4',	
		   '\n NB: Only the brightest source may be polarised (IQUV),',	
		   '\n     as specified with the parameter flux_IQUV.',	
		   '\n NB: (l,m) are in units: lambda/shortest_baseline.',	
		   '\n ');	
	defrec.paramhelp.source := s;
	sc := "point_central";
	sc := [sc,"double_far double_close double_equal"];  
	sc := [sc," point_far point_close point_central"];
	# sc := [sc,"extended_just extended_very"];  
	sc := [sc,"testdata_real testdata_complex"];  
	defrec.paramchoice.source := sc;

	s := paste('Stokes parameters (Jy) of brightest simulated source:',
		   '\n Give a vector of 4 (real) values I,Q,U,V:',	
		   '\n For WSRT, use non-zero U to get signal into XY/YX.',	
		   '\n ');	
	defrec.paramhelp.flux_IQUV := s;
	defrec.paramshape.flux_IQUV := 'vector';
	defrec.paramchoice.flux_IQUV := [=]; n := 0;
	defrec.paramchoice.flux_IQUV[n+:=1] := [1.0,0,0,0];	# unpolarised
	defrec.paramchoice.flux_IQUV[n+:=1] := [1.0,0,0.1,0];	# 10% U 
	defrec.paramchoice.flux_IQUV[n+:=1] := [1.0,0.1,0,0];	# 10% Q
	defrec.paramchoice.flux_IQUV[n+:=1] := [1.0,0,0,0.01];	#  1% V
	defrec.paramchoice.flux_IQUV[n+:=1] := '3C48';
	# defrec.paramchoice.flux_IQUV[n+:=1] := '3C84';
	defrec.paramchoice.flux_IQUV[n+:=1] := '3C123';
	defrec.paramchoice.flux_IQUV[n+:=1] := '3C196';
	defrec.paramchoice.flux_IQUV[n+:=1] := '3C286';
	defrec.paramchoice.flux_IQUV[n+:=1] := '3C295';

	defrec.paramchoice.Tsys := 100;
	defrec.paramhelp.Tsys := 'nominal system temperature (K)';

	defrec.paramchoice.sensitivity := 0.1;
	defrec.paramhelp.sensitivity := 'system sensitivity (K/Jy)';

	private.simul_basic_item('bandpass', defrec);

	return defrec;
    }

# Helper function: create a basic defrec for antbrick simulation:

    private.simul_basic_antbrick := function (name, menu='simulate') {
	defrec := private.tw.menubar().defrecinit(name,menu); 
	defrec.prompt := 'Specify antbrick simulation parameters';
	defrec.refresh := T;			# test: refresh panel
	defrec.paramchoice.funcname := 'sim_antbrick';
	defrec.paramhide.funcname := T;

	private.simul_basic_item('telescope', defrec);
	private.simul_basic_item('fMHz', defrec);
	private.simul_basic_item('HAdeg', defrec);
	for (fname in "ants") { 
	    defrec.paramshape[fname] := 'vector';
	    defrec.paramchoice[fname] := ref private.choice_sim[fname];
	    defrec.paramtest[fname] := ref private.test_sim[fname];
	    defrec.paramcheck[fname] := ref private.check_sim[fname];
	    defrec.paramhelp[fname] := ref private.help_sim[fname];
	    # defrec.paramgui[fname] := ref private.gui_sim[fname];
	}
	defrec.paramhelp.pols := ' ';
	defrec.paramshape.pols := 'vector';
	defrec.paramchoice.pols := [=]; n := 0;
	defrec.paramchoice.pols[n+:=1] := "X Y";
	defrec.paramchoice.pols[n+:=1] := "X";
	defrec.paramchoice.pols[n+:=1] := "Y";
	private.simul_basic_item('sep9A', defrec);
	private.simul_basic_item('bandpass', defrec);

	return defrec;
    }

# Helper function: create a basic defrec item for brick simulation:

    private.simul_basic_item := function (name, ref defrec=F) {

	if (name=='telescope') {
	    defrec.paramcheck.telescope := ref function (v=F) {
		print 'paramcheck.telescope: value=',v;
		return T;					# necessary!
	    }
	    defrec.paramchoice.telescope := "WSRT";
	    defrec.paramchoiceonly.telescope := T;		# no others yet


	} else if (name=='fMHz') {
	    s := paste('Specification of simulated frequency channels.',
		       '\n Give a vector of 3 loop parameters:',	
		       '\n - 1st:   the total number of channels',	
		       '\n - 2nd:   the centre freq (MHz) of the first channel',	
		       '\n - 3rd:   the channel bandwidth (MHz)',	
		       '\n - [4th]: the freq increment (MHz) between channels',	
		       '\n NB: By default the 4th number is equal to the 3rd.',	
		       '\n ');	
	    defrec.paramhelp.fMHz := s;
	    defrec.paramshape.fMHz := 'vector';
	    defrec.paramchoice.fMHz := [=]; n := 0;
	    defrec.paramchoice.fMHz[n+:=1] := [128,327.0,2.0];	# wide f-range
	    defrec.paramchoice.fMHz[n+:=1] := [10,327.0,1.0];	# 10 channels
	    defrec.paramchoice.fMHz[n+:=1] := [1,300.0,5.0];	# one channel
	    defrec.paramchoice.fMHz[n+:=1] := [4096,850.0,0.01];	# CI
	    defrec.paramchoice.fMHz[n+:=1] := [256,1412.0,0.1];

	} else if (name=='HAdeg') {
	    s := paste('Specification of simulated time-slots.',
		       '\n Give a vector of 3-4 loop parameters:',	
		       '\n - 1st:   the total number of time-slots',	
		       '\n - 2nd:   the centre HA (deg) of the first slot',	
		       '\n - 3rd:   the HA integration \'time\' (deg)',	
		       '\n - [4th]: the HA increment (deg) between slots',	
		       '\n NB: By default the 4th number is equal to the 3rd.',	
		       '\n\n NB: One degr in HA equals 4 min (240 sec) in time.',	
		       '\n ');	
	    defrec.paramhelp.HAdeg := s;
	    defrec.paramshape.HAdeg := 'vector';
	    defrec.paramchoice.HAdeg := [=]; n := 0;
	    defrec.paramchoice.HAdeg[n+:=1] := [20,-30.0,1.0];	# 20 slots
	    defrec.paramchoice.HAdeg[n+:=1] := [6,-30.0,2.0];	# 6 slots
	    defrec.paramchoice.HAdeg[n+:=1] := [1,-30.0,2.0];	# one slot
	    defrec.paramchoice.HAdeg[n+:=1] := [720,-90.0,0.25];	# 12 hrs

	} else if (name=='bandpass') {
	    defrec.paramhelp.bandpass := 'apply bandpass';
	    defrec.paramchoice.bandpass := [F,T];

	} else if (name=='sep9A') {
	    defrec.paramhelp.sep9A := 'separation between RT9 and RTA';
	    defrec.paramchoice.sep9A := [72.0,36,54,96,144];

	} else {
	    print 'simul_basic_item: not recognised:',name;
	    return F;
	}
	return T;
    }

#-----------------------------------------------------------------
# uv-brick corruption  menu:

    private.make_menu_corrupt := function(ref menu=F) {
 
    	defrec := private.corrupt_basic ('dippos/ellipt errors', menu);
	defrec.prompt := 'Specify (WSRT) dipole error parameters';
	defrec.paramchoice.funcname := 'corrupt_diperr';
	defrec.paramhelp.rms_dipposerr := 'rms dipole position angle error (rad)';
	defrec.paramchoice.rms_dipposerr := [0.01,0,0.01,0.1];
	defrec.paramhelp.rms_ellipticity := 'rms receptor ellipticity error (rad)';
	defrec.paramchoice.rms_ellipticity := [0.01,0,0.01,0.1];
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

    	defrec := private.corrupt_basic ('phase/gain errors', menu);
	defrec.prompt := 'Specify phase/gain error parameters';
	defrec.paramchoice.funcname := 'corrupt_pgerr';
	defrec.paramhelp.rms_loggain := 'rms receptor 10log(gain) error';
	defrec.paramchoice.rms_loggain := [0.1,0,0.1,0.5,1,2];
	defrec.paramhelp.rms_phase := 'rms receptor phase error (rad)';
	defrec.paramchoice.rms_phase := [0.1,0,0.1,0.5,1,2];
	defrec.paramhelp.pzd := 'X/Y (or R/L) phase zero difference (rad)';
	defrec.paramchoice.pzd := [0,0.1,0.5,1,2];
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

    	defrec := private.corrupt_basic ('delay_offset errors', menu)
	defrec.prompt := 'Specify delay offset parameters'
	defrec.paramchoice.funcname := 'corrupt_deloff';
	defrec.paramhelp.rms_nsec := 'rms receptor delay offset (nsec)';
	defrec.paramchoice.rms_nsec := [10,0.0,1,2,5,10,20,50,100];
	defrec.paramhelp.mean_nsec := 'mean receptor delay offset (nsec)';
	defrec.paramchoice.mean_nsec := [0.0,1,2,5,10,20,50,100];
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);
	#--------------------------------------------

    	defrec := private.corrupt_basic ('errors for DELFI', menu);
	defrec.prompt := 'Simulate a WSRT DELFI observation';
	defrec.paramchoice.funcname := 'corrupt_DELFI';
	defrec.paramshape.stepping_ants := 'vector';	
	defrec.paramchoice.stepping_ants := [=]; n := 0;	
	defrec.paramchoice.stepping_ants[n+:=1] := "0 1";	
	defrec.paramchoice.stepping_ants[n+:=1] := "A B C D";	
	defrec.paramhelp.step_nsec := 'delay-step of \'stepping\' antennas';
	defrec.paramchoice.step_nsec := [10,5];
	s := paste('The DELFI (WSRT DCB) delay stepping will be simulated',
		   '\n for random antenna (receptor) delays with the given rms.',
		   '\n NB: The current uv-brick should be suitable..',	
		   '\n');
	defrec.paramhelp.rms_simul_nsec := s;	
	defrec.paramchoice.rms_simul_nsec := [5,0,1,3,5,10,20];	
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

    	defrec := private.corrupt_basic ('errors for MAKECAL', menu);
	defrec.prompt := 'Simulate a WSRT MAKECAL observation';
	defrec.paramchoice.funcname := 'corrupt_MAKECAL';
	defrec.paramhelp.rms_antpos_dx := 'antpos dx (dHA) error (m)';
	defrec.paramchoice.rms_antpos_dx := [0,0.001,0.01,0.1];
	defrec.paramhelp.rms_antpos_dy := 'antpos dy (length) error (m)';
	defrec.paramchoice.rms_antpos_dy := [0.01,0,0.001,0.01,0.1];
	defrec.paramhelp.rms_antpos_dz := 'antpos dz (dDEC) error (m)';
	defrec.paramchoice.rms_antpos_dz := [0,0.001,0.01,0.1];
	defrec.paramchoice.mean_antpos_dx := [-0.01,0.001,0.01,0.1,1];
	defrec.paramchoice.mean_antpos_dy := [0,0.001,0.01,0.1,1];
	defrec.paramchoice.mean_antpos_dz := [0.01,0.001,0.01,0.1,1];
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

    	defrec := private.corrupt_basic ('errors for POINTING', menu);
	defrec.prompt := 'Simulate a WSRT POINTING observation';
	defrec.paramchoice.funcname := 'corrupt_POINTING';
	defrec.paramchoice.ndeg_poly_HA := [2,0,1,2,3,4] 
	defrec.paramchoice.ndeg_poly_DEC := [2,0,1,2,3,4] 
	defrec.paramchoice.rms_polycoeff_HA := [10,0,1,10,100,1000] 
	defrec.paramchoice.rms_polycoeff_DEC := [10,0,1,10,100,1000] 
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	return T;
    }

#-----------------------------------------------------------------
# uv-brick corruption menu (noise/spikes etc):

    private.make_menu_noise := function(ref menu=F) {

	defrec := private.tw.menubar().defrecinit('add noise',menu); 
	defrec.prompt := 'Specify parameters for noise'
	defrec.paramchoice.funcname := 'addnoise';
	defrec.paramhide.funcname := T;
	defrec.paramhelp.SNR := 'Specify the S/N on the simulated uv-data.';
	defrec.paramchoice.SNR := [100,1e6,1e5,1e4,1e3,100,10,3,2,1,0.5,0.1];
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('add spikes',menu); 
	defrec.prompt := 'Specify parameters for noise and RFI'
	defrec.paramchoice.funcname := 'addspikes';
	defrec.paramhide.funcname := T;
	s := paste('Specify a percentage of artificial spikes on the uv-data.', 
		   '\n They are added to randomly chosen uv-samples.',	
		   '\n Purpose: for testing flagging etc.',	
		   '\n ');	
	defrec.paramhelp.perc_spikes := s;
	defrec.paramchoice.perc_spikes := [1,0.001,0.01,0.1,1,10];
	defrec.paramhelp.rms_spikes := 'rms of spike sizes (Jy)';
	defrec.paramchoice.rms_spikes := [0.1,1,10];
	defrec.paramhelp.mean_spikes := 'overall mean of all spikes (Jy)';
	defrec.paramchoice.mean_spikes := [0,0.1,1,10];
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	return T;
    }

# Helper function: create a basic defrec for simulation:

    private.corrupt_basic := function (name, menu='simulate') {
	defrec := private.tw.menubar().defrecinit(name,menu); 
	defrec.prompt := 'Specify corruption parameters';
	defrec.onlyif := private.currbrick_is_uvbrick;
	defrec.refresh := T;			# test: refresh panel
	defrec.paramchoice.funcname := 'corrupt';
	defrec.paramhide.funcname := T;
	defrec.paramhelp.display := 'display the corrupted result';
	defrec.paramchoice.display := [T,F];
	defrec.paramhelp.suspend := 'If T, start in step-by-step mode';
	defrec.paramchoice.suspend := [F,T];
	return defrec;
    }

#-----------------------------------------------------------------
# brick menu:

    private.make_menu_brick := function(menu='brick') {

	# Get a brick from the MS:
	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);
	#--------------------------------------------
	submenu := private.tw.menubar().makemenu('uvbrick from MS', menu);
	private.make_menu_ms2uvbrick(submenu);
	submenu := private.tw.menubar().makemenu('antbrick from MS', menu);
	private.make_menu_ms2antbrick(submenu);

	# Simulation of uv/ant brick:
	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);
	#--------------------------------------------
	submenu := private.tw.menubar().makemenu('simulate brick', menu);
	private.make_menu_simul(submenu);
	submenu := private.tw.menubar().makemenu('simulate errors', menu);
	private.make_menu_corrupt(submenu);
	submenu := private.tw.menubar().makemenu('add noise etc', menu);
	private.make_menu_noise(submenu);

	# Selection/averaging of a brick:
	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);
	#--------------------------------------------
	submenu := private.tw.menubar().makemenu('sub-brick',menu); 
	private.make_menu_selectav(submenu);		 

	# Plotting:
	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);
	#--------------------------------------------
	submenu := private.tw.menubar().makemenu('plot',menu); 
	private.make_menu_plot(submenu);		 

	# Inspection:
	submenu := private.tw.menubar().makemenu('inspect',menu); 
	private.make_menu_inspect(submenu);		 

	# Flagging:
	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);
	#--------------------------------------------
	submenu := private.tw.menubar().makemenu('flag',menu); 
	private.make_menu_flag(submenu);		 

	# Misc brick operations:
	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);
	#--------------------------------------------
	submenu := private.tw.menubar().makemenu('misc', menu);
	private.make_menu_brickops(submenu);		 

	# Exchange and interaction with 'result-list':
	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);
	#--------------------------------------------
	defrec := private.tw.menubar().defrecinit('brick -> result',menu);
	private.tw.menubar().makemenuitem(defrec, private.currbrick_to_curresult);

	return T;
    }


#-----------------------------------------------------------------
# brick selection/averaging menu:

    private.make_menu_selectav := function(ref menu=F) {
	
	defrec := private.tw.menubar().defrecinit('uvbrick',menu); 
	defrec.prompt := 'Specify selection/averaging parameters:'
	s := paste('help',
		   '\n ',
		   '\n ');
	defrec.help := s;
	defrec.onlyif := private.currbrick_is_uvbrick;
	defrec.paramchoice.funcname := 'selav';    
	defrec.paramhide.funcname := T;
	for (fname in "corrs fchs ifrs times") {
	    defrec.paramshape[fname] := 'vector';
	    defrec.paramchoice[fname] := ref private.choice_uvb[fname];
	    defrec.paramtest[fname] := ref private.test_uvb[fname];
	    defrec.paramhelp[fname] := ref private.help_uvb[fname];
	    # defrec.paramgui[fname] := ref private.gui_uvb[fname];     #.....
	}
	defrec.paramgui.ifrs := ref private.gui_uvb.ifrs;             #.....
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('antbrick',menu); 
	defrec.prompt := 'Specify selection/averaging parameters:'
	s := paste('help',
		   '\n ',
		   '\n ');
	defrec.help := s;
	defrec.onlyif := private.currbrick_is_antbrick;
	defrec.paramchoice.funcname := 'selav';  
	defrec.paramhide.funcname := T;
	for (fname in "ants pols fchs times") {
	    defrec.paramshape[fname] := 'vector';
	    defrec.paramchoice[fname] := ref private.choice_uvb[fname];
	    defrec.paramtest[fname] := ref private.test_uvb[fname];
	    defrec.paramhelp[fname] := ref private.help_uvb[fname];
	}
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);
	#--------------------------------------------

	defrec := private.tw.menubar().defrecinit('time-average',menu); 
	defrec.paramchoice.funcname := 'selav';        # new
	defrec.paramhide.funcname := T;
	for (fname in "corrs fchs ifrs times") {
	    # defrec.paramshape[fname] := 'vector';
	    defrec.paramchoice[fname] := '*';
	}
	# defrec.paramshape.times := 'vector';
	defrec.paramchoice.times := 'average';
	private.tw.menubar().makemenuitem(defrec, private.menuaction);


	defrec := private.tw.menubar().defrecinit('freq-average',menu); 
	defrec.paramchoice.funcname := 'selav';        # new
	defrec.paramhide.funcname := T;
	for (fname in "corrs fchs ifrs times") {
	    # defrec.paramshape[fname] := 'vector';
	    defrec.paramchoice[fname] := '*';
	}
	# defrec.paramshape.fchs := 'vector';
	defrec.paramchoice.fchs := 'average';
	private.tw.menubar().makemenuitem(defrec, private.menuaction);



	return T;
    }


#-----------------------------------------------------------------
# uv-brick flagging menu:

    private.make_menu_flag := function(ref menu=F) {

 	defrec := private.tw.menubar().defrecinit('clip',menu); 
	defrec.prompt := 'Specify clipping (flagging) parameters'
	s := paste('flag the uvbrick data by clipping',
		   '\n ',
		   '\n ');
	defrec.help := s;
	defrec.paramchoice.funcname := 'clip';
	defrec.paramhide.funcname := T;
	s := "ampl logampl phase_rad phase_deg real_part imag_part";	
	defrec.paramchoice.cx2real := s;
	s := paste('Flag all data for which abs(y)>threshold',
		   '\n NB: If treshold>0, this takes precedence over diff!');
	defrec.paramhelp.threshold := s;	
	defrec.paramchoice.threshold := [0,1,10,100];	
	s := 'differentiate first along this axis (only if threshold=0!)';	
	defrec.paramhelp.diffaxis := s;
	defrec.paramchoice.diffaxis := "freq time";	
	defrec.paramhelp.derivn := 'Use the nth derivative';	
	defrec.paramchoice.derivn := [1,0,1,2];	
	s := paste('Flag all data for which (y-<y>)>nsigma*rms',	
		   '\n NB: In this case, y is the nth derivative.')
	defrec.paramhelp.nsigma := s;
	defrec.paramchoice.nsigma := [2,1:7];
	defrec.paramhelp.display := 'display the process (interactive)'	
	defrec.paramchoice.display := [T,F];
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	return T;
    }

#-----------------------------------------------------------------
# uv-brick operations menu:

    private.make_menu_brickops := function(ref menu=F) {
	
	defrec := private.tw.menubar().defrecinit('sort',menu, T); 
	defrec.prompt := 'Specify sorting parameters'
	s := 'sort the uvbrick data along the indicated axis'
	defrec.help := s;
	defrec.paramchoice.sort_axis := "baselength";	
	defrec.paramhelp.sort_axis := 'will be sorted in ascending order';	
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('convert data',menu, T); 
	defrec.prompt := 'Specify data conversion operation'
	s := 'Convert the uvbrick data'
	defrec.help := s;
	ops := "abs log 2log ln exp sin cos";
	ops := [ops,"ampl logampl phase_rad phase_deg"];
	ops := [ops,"real_part imag_part conj"];
	defrec.paramchoice.conversion := ops;
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('differentiate',menu, T); 
	defrec.prompt := 'Specify data differentiation'
	s := 'Convert the uvbrick data w.r.t. the given coord axis'
	defrec.help := s;
	defrec.paramchoice.axis := "freq time";	
	defrec.paramhelp.axis := 'differentiate along this axis';	
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('rename',menu, T); 
	defrec.prompt := 'rename the brick'
	s := 'rename the brick'
	defrec.help := s;
	defrec.paramchoice.name := private.get_uvb.name;	
	defrec.paramhelp.name := 'give the name of the brick';
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);	#------------------
	#--------------------------------------------

	defrec := private.tw.menubar().defrecinit('fit polynomial',menu); 
	defrec.prompt := 'Specify polynomial fit parameters'
	s := paste('Fit a polynomial (ndeg<=10) to the data, along a given axis.',
		   '\n The result can either:',
		   '\n - be stored as polynomial coefficients',
		   '\n - be subtracted from the data',
		   '\n - replace the data',
		   '\n If complex data, real/imag are fitted separately.',
		   '\n If clip_nsigma>0, the data will be clipped on the',
		   '\n   basis of a first fit, and then fitted again.',
		   '\n');
	defrec.help := s;
	defrec.paramchoice.funcname := 'fitpoly';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.fitfunc := 'polynomial';	
	defrec.paramhide.fitfunc := T;
	defrec.paramchoice.ndeg := [2,0:10];	
	defrec.paramchoiceonly.ndeg := T;		# fitter only goes to 10!	
	defrec.paramhelp.ndeg := 'give the polynomial degree (<=10)';	
	defrec.paramchoice.fitaxis := "freq time";	
	defrec.paramhelp.fitaxis := 'polynomials will be fitted along this axis';	
	defrec.paramchoice.clip_nsigma := [-1,1,2,3,5,7,9];
	defrec.paramhelp.clip_nsigma := 'if >0, there will be two iterations'	
	for (s in "left centre right") {
	    fname := spaste('ignore_',s);
	    defrec.paramchoice[fname] := [0,1,2,5];
	    defrec.paramhelp[fname] := paste('nr of points ignored at',s);
	}
	defrec.paramchoice.result := "polcoeff subtract replace";
	defrec.paramhelp.result := 'if polcoeff, output is an array of polynomial coeff.';
	defrec.paramchoice.display := [T,F];
	defrec.paramhelp.display := 'if T, fit is displayed on-line';
	# private.tw.menubar().makemenuitem(defrec, private.menuaction);

	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);	#------------------
	#--------------------------------------------

	defrec := private.tw.menubar().defrecinit('bandpass',menu); 
	defrec.prompt := 'Estimate the average bandpass';
	defrec.help := ref private.helptext.bandpass;
	defrec.paramchoice.funcname := 'bandpass';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.flag := [F,T];		# supply clipdiff rms?	
	defrec.paramchoice.times := "average";		# function? arg!!	
	defrec.paramchoice.apply := [T,F];		# F is nop/display	
        # private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('timepoly',menu); 
	defrec.prompt := 'Estimate the average time-polynomial';
	s := paste('Produces a new brick, averaged over freq',
		   '\n From this, polynomial coefficients are estimated.',
		   '\n These may be applied (subtracted) from the original brick.',
		   '\n');
	defrec.help := s;
	defrec.paramchoice.funcname := 'timepoly';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.flag := [F,T];		# supply clipdiff rms?	
	defrec.paramchoice.fchs := "average";		# function? arg!!	
	defrec.paramchoice.ndeg := [5,0:10];		# default is 5...?	
	defrec.paramchoiceonly.ndeg := T;		# fitter only goes to 10!	
	defrec.paramchoice.display := [T,F];		# displays fitting	
	defrec.paramchoice.apply := [T,F];		# retain?	
	# private.tw.menubar().makemenuitem(defrec, private.menuaction);

	return T;
    }


#-----------------------------------------------------------------
# Deal with various kinds of results:

    private.make_menu_result := function(menu='result') {


	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);	#------------------
	#--------------------------------------------

	defrec := private.tw.menubar().defrecinit('plot gsb',menu);
	defrec.prompt := 'select gsb object to be plotted';
	defrec.paramchoice.gsb := ref private.curresult_choice_gsb;
	defrec.paramchoiceonly.gsb := T;
	defrec.paramhelp.gsb := 'available gsb ojects in result-record';
	private.tw.menubar().makemenuitem(defrec, 
					  private.curresult_plot_gsb);

	defrec := private.tw.menubar().defrecinit('report',menu);
	defrec.prompt := 'select report';
	defrec.paramchoice.report := ref private.curresult_choice_report;
	defrec.paramchoiceonly.report := T;
	defrec.paramhelp.report := 'available reports in result-record';
	defrec.paramchoice.hardcopy := [T,F];
	private.tw.menubar().makemenuitem(defrec, 
					  private.curresult_print_report);

	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);	#------------------
	#--------------------------------------------

	defrec := private.tw.menubar().defrecinit('show summary',menu);
	private.tw.menubar().makemenuitem(defrec, private.curresult_summary);

	defrec := private.tw.menubar().defrecinit('show data',menu);
	private.tw.menubar().makemenuitem(defrec, private.curresult_showdata);

	defrec := private.tw.menubar().defrecinit('inspect in detail',menu);
        defrec.action := ref function() {
	    include 'inspect.g';
	    inspect(private.curresult,'result');
	} 
	private.tw.menubar().makemenuitem(defrec);


	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);
	#--------------------------------------------

	defrec := private.tw.menubar().defrecinit('apply (to uvbrick)',menu); 
	defrec.prompt := 'Specify application to the data'
	defrec.paramchoice.funcname := 'apply';
	defrec.paramhide.funcname := T;
	ops := "automatic add subtract multiply divide power nop"
	defrec.paramchoice.operation := ops;
	what := [=];
	what[1] := "result"	 		# string instr.
	what[2] := [2,0.5];				# scalar
	defrec.paramchoice.what := what;	
	private.tw.menubar().makemenuitem(defrec, private.menuaction);


	defrec := private.tw.menubar().defrecinit('result -> brick-list',menu);
	private.tw.menubar().makemenuitem(defrec, 
					  private.curresult_to_currbrick);

	return T;
    }

#-----------------------------------------------------------------
# Various antenna decomposition applications:

    private.make_menu_decomp := function(menu='decomp') {

 	defrec := private.decomp_basic ('delay offsets', menu);
	for (rcperr in "rcp_delay_offset rcp_phase") {
	    defrec.paramchoice[rcperr] := [T,F];        # default: F;
	    defrec.paramchoiceonly[rcperr] := T;
	    defrec.paramhide[rcperr] := F;
	}
	# defrec.paramhide.rcp_delay_offset := T;
	defrec.paramchoice.rcp_phase := [F,T];          # default: F;

	defrec.paramchoice.calibrator := [=];
	defrec.paramchoice.calibrator[1] := [1.0,0.0,0.0,0.0];   # cps
	defrec.paramhide.calibrator := T;               # default: cps
	s := paste('Solve for receptor delay-offsets (nsec)',
		   '\n by means of phase-gradients over the freq-band');
	defrec.help := s;
	private.tw.menubar().makemenuitem(defrec, private.exec.decompant);

 	defrec := private.decomp_basic ('phase-zeroes', menu);
	for (rcperr in "rcp_phase") {
	    defrec.paramchoice[rcperr] := [T,F];
	    defrec.paramchoiceonly[rcperr] := T;
	    defrec.paramhide[rcperr] := T;
	}
	defrec.paramchoice.calibrator := [=];
	defrec.paramchoice.calibrator[1] := [1.0,0.0,0.0,0.0];   # cps
	defrec.paramhide.calibrator := T;               # default: cps
	private.tw.menubar().makemenuitem(defrec, 
					  private.exec.decompant);


 	defrec := private.decomp_basic ('X/Y phase-zero diff (pzd)', menu);
	ss := "rcp_gain_real rcp_phase";
	ss := [ss,"rcp_ellipticity rcp_dipposerr"];
	ss := [ss,"rcp_pzd"];
	for (rcperr in ss) {
	    defrec.paramchoice[rcperr] := [T,F];
	    defrec.paramchoiceonly[rcperr] := T;
	    defrec.paramhide[rcperr] := F;
	}
	defrec.paramchoice.calibrator := [=];;
	defrec.paramchoice.calibrator[1] := [1.0,0.0,0.0,0.0];
	# defrec.paramhide.calibrator := T;               # default: cps
	defrec.paramchoiceonly.calibrator := T;         # inhibit choice
	defrec.paramchoiceonly.ref_ant := T;            # inhibit choice
	defrec.paramhide.convert2Jy := F;
	defrec.paramhide.Tsys_nominal := F;
	defrec.paramhide.aperteff := F;
	private.tw.menubar().makemenuitem(defrec, private.exec.decompant);


	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);	#------------------
	#--------------------------------------------

 	defrec := private.decomp_basic ('IF Tsys', menu);
	for (rcperr in "rcp_Tsys") {
	    defrec.paramchoice[rcperr] := [T,F];
	    defrec.paramchoiceonly[rcperr] := T;
	    defrec.paramhide[rcperr] := T;
	}
	defrec.paramhide.calibrator := F;               # needed
	defrec.paramhide.ref_ant := T;                  # not relevant
	defrec.paramhide.convert2Jy := F;
	defrec.paramhide.Tsys_nominal := F;
	defrec.paramhide.aperteff := F;
	private.tw.menubar().makemenuitem(defrec, 
					  private.exec.decompant);

 	defrec := private.decomp_basic ('gain factors', menu);
	for (rcperr in "rcp_gain_real") {
	    defrec.paramchoice[rcperr] := [T,F];
	    defrec.paramchoiceonly[rcperr] := T;
	    defrec.paramhide[rcperr] := T;
	}
	defrec.paramhide.calibrator := F;               # needed
	defrec.paramhide.ref_ant := T;                  # not relevant
	defrec.paramhide.convert2Jy := F;
	defrec.paramhide.Tsys_nominal := F;
	defrec.paramhide.aperteff := F;
	private.tw.menubar().makemenuitem(defrec, 
					  private.exec.decompant);


	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);	#------------------
	#--------------------------------------------

 	defrec := private.decomp_basic ('mosys (??)', menu);
	for (rcperr in "rcp_phase") {
	    defrec.paramchoice[rcperr] := [T,F];
	    defrec.paramchoiceonly[rcperr] := T;
	    defrec.paramhide[rcperr] := T;
	}
	defrec.paramchoice.times[1] := '*';
	defrec.paramchoiceonly.times := T;
	s := paste('Do a separate solution for each time-slot');
	defrec.paramhelp.times := s;
	private.tw.menubar().makemenuitem(defrec, private.exec.decompant);


	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);	#------------------
	#--------------------------------------------

	defrec := private.tw.menubar().defrecinit('DELFI (WSRT)',menu); 
	defrec.help := private.msb_help.help('DELFI');
	defrec.prompt := 'WSRT DCB delay offset estimation'
	defrec.paramchoice.funcname := 'DELFI';
	defrec.paramhide.funcname := T;
	defrec.paramshape.stepping_ants := 'vector';	
	defrec.paramchoice.stepping_ants := [=]; n := 0;	
	defrec.paramchoice.stepping_ants[n+:=1] := "0 1";	
	defrec.paramchoice.stepping_ants[n+:=1] := "A B C D";	
	defrec.paramhelp.step_nsec := 'delay-step of \'stepping\' antennas';
	defrec.paramchoice.step_nsec := [10,5];
	defrec.paramhelp.ndeg := 'degree of fitted polynomial';
	defrec.paramchoice.ndeg := [2];
	defrec.paramchoiceonly.ndeg := T;
	defrec.paramhelp.display := 'display each fit to the uv-data';
	defrec.paramchoice.display := [T,F];
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('MAKECAL (WSRT)',menu); 
	s := 'MAKECAL: estimation of WSRT antenna positions';
	defrec.help := s;
	defrec.prompt := 'WSRT antenna position estimation'
	defrec.paramchoice.funcname := 'MAKECAL';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.solve_antpos_dx := [T,F];
	defrec.paramchoice.solve_antpos_dy := [T,F];
	defrec.paramchoice.solve_antpos_dz := [T,F];
	defrec.paramchoice.solve_antphase_error := [F,T];
	defrec.paramhide.solve_antphase_error := T;
	defrec.paramchoice.solve_clock_error := [F,T];
	defrec.paramhide.solve_clock_error := T;
	defrec.paramchoice.solve_DEC_error := [F,T];
	defrec.paramhide.solve_DEC_error := T;
	defrec.paramchoice.solve_freq_error := [F,T];
	defrec.paramhide.solve_freq_error := T;
	defrec.paramhelp.display := 'display the fit';
	defrec.paramchoice.display := [T,F];
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	defrec := private.tw.menubar().defrecinit('POINTING (WSRT)',menu); 
	s := 'POINTING: estimation of WSRT antenna pointing errors';
	defrec.help := s;
	defrec.prompt := 'WSRT antenna position estimation'
	defrec.paramchoice.funcname := 'POINTING';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.assume_circular := [T,F];
	defrec.paramhide.assume_circular := T;
	defrec.paramchoice.assume_norotation := [T,F];
	defrec.paramhide.assume_norotation := T;
	defrec.paramhelp.display := 'display the fit';
	defrec.paramchoice.display := [T,F];
	private.tw.menubar().makemenuitem(defrec, private.menuaction);


	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);	#------------------
	#--------------------------------------------

	defrec := private.tw.menubar().defrecinit('result -> TMS',menu); 
	s := paste('Pass the \'current\' result to TMS (WSRT).',
		   '\n e.g. phase zeroes or delay offsets.',
		   '\n NB: The current result must be a decomp result, of course.',
		   '\n',
		   '\n NB: Only the result for the FIRST time-slot is taken!',
		   '\n');
	defrec.help := s;
	defrec.prompt := 'ant/rcp decompisition to TMS'
	defrec.paramchoice.funcname := 'decomp2tms';
	defrec.paramhide.funcname := T;
	defrec.paramchoice.send2tms := [F,T];
	defrec.paramhelp.send2tms := 'If F, nothing is actually sent';
	# defrec.paramchoice.fixpa_set := 'now: always 60!';
	# defrec.paramchoiceonly.fixpa_set := T;
	# defrec.paramhelp.fixpa_set := 'specify the WSRT fixpa set nr';
	defrec.paramhelp.hardcopy := 'print a hardcopy of what is sent';
	defrec.paramchoice.hardcopy := [T,F];
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	#--------------------------------------------
	private.tw.menubar().makemenuseparator(menu);	#------------------
	#--------------------------------------------

	defrec := private.TOPOR_basic('TOPOR (WSRT)', menu=menu);
	defrec.prompt := 'do TOPOR (WSRT)';
	defrec.onlyif := private.currbrick_is_antbrick;
	defrec.paramchoice.funcname := 'exec_TOPOR';
	private.tw.menubar().makemenuitem(defrec, private.menuaction);

	return T;
    }

# Helper function: create a basic defrec for TOPOR:

    private.TOPOR_basic := function (name, menu='??') {
	defrec := private.tw.menubar().defrecinit(name, menu); 
	defrec.paramchoice.funcname := 'exec_TOPOR';
	defrec.paramhide.funcname := T;
	for (fname in "ants pols colname") {
	    defrec.paramchoice[fname] := T;         # place-holder
	    defrec.paramhide[fname] := T;           # default
	}
	defrec.paramchoice.TPref := [=]; n:=0;
	defrec.paramchoice.TPref[n+:=1] := F;
	defrec.paramchoice.TPref[n+:=1] := 1.0;
	s := paste('Total Power values are compared to an expected value.',
		   '\n This value may be specified here.',
		   '\n If boolean (F), the average measured value is used.',
		   '\n');
	defrec.paramhelp.TPref := s;
	defrec.paramchoice.hardcopy := [T,F];
	defrec.paramhide.hardcopy := F;
	defrec.help := 'Specific WSRT option';
	return defrec;
    }


# Hekper function: define basic ant/rcp defrec, to be overridden in details:

    private.decomp_basic := function (name, menu='decomp') {
 	defrec := private.tw.menubar().defrecinit(name, menu); 
	defrec.prompt := 'Antenna (receptor, really) decomposition'
	defrec.onlyif := private.currbrick_is_uvbrick;
	defrec.paramchoice.funcname := 'decompant';
	defrec.paramhide.funcname := T;

	# NB: The order of the following is IMPORTANT!
	s := "rcp_delay_offset";
	s := [s,"rcp_gain_real rcp_phase"];
	s := [s,"rcp_ellipticity rcp_dipposerr"];	
	s := [s,"rcp_pzd"];
	s := [s,"rcp_Tsys"];
	# s := [s,"rcp_gain_complex"];
	# s := [s,"ant_dipposerr"];	
	# s := [s,"ant_pointing ant_position"];	
	for (rcperr in s) {
	    defrec.paramchoice[rcperr] := [F,T];  
	    s1 := paste('If T, an antenna decomposition solution',
			'\n will be made for parameter:',rcperr);
	    defrec.paramhelp[rcperr] := s1;	    
	    defrec.paramhide[rcperr] := T;	  
	}

	for (fname in "times fchs corrs ifrs") {
	    defrec.paramshape[fname] := 'vector';
	    defrec.paramchoice[fname] := [=];
	    # defrec.paramchoiceonly[fname] := T;
	    defrec.paramtest[fname] := ref private.test_uvb[fname];
	    defrec.paramhelp[fname] := ref private.help_uvb[fname];
	}

	n := 0;
	defrec.paramchoice.ifrs[n+:=1] := '* (-*=) (-E) (-F)';
	defrec.paramchoice.ifrs[n+:=1] := '*';
	# defrec.paramchoiceonly.ifrs := F;              # allow choice
	n := 0;
	defrec.paramchoice.corrs[n+:=1] := '*';
	n := 0;
	defrec.paramchoice.times[n+:=1] := 'average';
	defrec.paramchoice.times[n+:=1] := '*';
	s := paste('If the uvbrick contains more than one time-slot,',
		   '\n first make a new uvbrick by averaging over all time-slots.',
		   '\n');
	defrec.paramhelp.times := s;
	n := 0;
	defrec.paramchoice.fchs[n+:=1] := '*/0.75';
	s := paste('If the uvbrick contains more than one freq-channel,',
		   '\n first make a new uvbrick by averaging over channels.',
		   '\n NB: Only the central 75% of channels are used, to avoid band edges.',
		   '\n NB: If delay offsets are to be determined, this is done over.',
		   '\n     the central 75% of the channels, PRIOR to any averaging.',
		   '\n');
	defrec.paramhelp.fchs := s;

	defrec.paramshape.calibrator := 'vector';
	defrec.paramchoice.calibrator := ref private.choice_calibrator;
	defrec.paramhelp.calibrator := ref private.help_calibrator;
	defrec.paramtest.calibrator := ref private.test_calibrator;
	defrec.paramhide.calibrator := F;

	defrec.paramchoice.ref_ant := ref private.choice_uvb.ref_ant;
	s := paste('A reference antenna may be specified.',
		   '\n If none, the average over all antennas will be used.',
		   '\n');
	defrec.paramhelp.ref_ant := s;

	defrec.paramchoice.convert2Jy := [T,F];
	defrec.paramchoiceonly.convert2Jy := T;
	defrec.paramhide.convert2Jy := T;

	defrec.paramchoice.Tsys_nominal := ref private.choice_Tsys;
	defrec.paramhelp.Tsys_nominal := ref private.help_Tsys;
	defrec.paramunit.Tsys_nominal := 'K';
	defrec.paramhide.Tsys_nominal := T;

	defrec.paramchoice.aperteff := ref private.choice_aperteff;
	defrec.paramhelp.aperteff := ref private.help_aperteff;
	defrec.paramhide.aperteff := T;

	for (fname in "apply_corr display hardcopy step_by_step") {
	    defrec.paramchoice[fname] := [T,F];
	    defrec.paramhide[fname] := T;
	}
	return defrec;
    }

#-----------------------------------------------------------------
# Miscellaneous menu:

    private.make_menu_misc := function(menu='misc') {

	defrec := private.tw.menubar().defrecinit('buttonscript',menu); 
	# private.tw.menubar().makemenuitem(defrec, private.bscr.gui); 

	return T;
    }

#---------------------------------------------------------------
#---------------------------------------------------------------
# General menu-action for menubar buttons. It knows what to do with the
# parameter-record pp:

    private.menuaction := function (pp=F) {
	wider private;
	s1 := paste('msbrick.menuaction():');
	print s := paste(' \n \n ',s1,'pp=',pp);
	# private.tw.append(s);
	if (private.currbrick_check(s1, mess=F)) {
	    # private.currbrick.abort(s1);	# abort any hanging loops..
	}

	s := paste('busy with action:',pp.funcname,'...');
	private.tw.message(s);

	if (is_string(pp)) {	# occurs if only one menubar parameter....
	    print 'menuaction: string pp=',pp;
	    s := pp;
	    pp := [=];
	    pp.funcname := s;			

	} else if (!is_record(pp)) {
	    print 'menuaction: pp not a record:',type_name(pp),pp;
	    private.tw.message(paste('break: problem with',pp.funcname));
	    return F;
	} else if (!has_field(pp,'funcname')) {
	    print 'menuaction: record pp does not have field funcname \n',pp;
	    private.tw.message(paste('break: problem with',pp.funcname));
	    return F;
	} else if (pp.funcname == 'dummy') {
	    private.tw.message(paste(pp.funcname,': no action'));

	} else if (pp.funcname == 'openMS') {
	    if (pp.MSname=='use filechooser') pp.MSname := F;
	    public.openMS(pp.MSname); 

	} else if (pp.funcname == 'get_uvbrick') {
	    public.get_uvbrick(pp); 

	} else if (pp.funcname == 'get_antbrick') {
	    public.get_antbrick(pp); 

	} else if (pp.funcname == 'TOPOR') {
	    public.get_antbrick(pp); 
	    private.exec.TOPOR(pp);
	} else if (pp.funcname == 'exec_TOPOR') {
	    private.exec.TOPOR(pp);

	} else if (pp.funcname == 'msdo_selectinit') {
	    private.msb_MS.msdo_selectinit(pp.arrays[1], pp.spwins[1]);

	} else if (pp.funcname == 'sim_uvbrick') {
	    public.simulate_brick(pp, 'uvbrick'); 

	} else if (pp.funcname == 'sim_antbrick') {
	    public.simulate_brick(pp, 'antbrick'); 

	} else if (pp.funcname == 'rename') {
	    if (!private.currbrick_check(pp.funcname)) return F;
    	    private.currbrick.name(pp.name);
	    s := private.currbrick.label();  
	    private.bricklist.itemlabel(label=s);	# update label
	    s := paste('renamed brick to:',pp.name);
	    private.tw.message(s);

	} else if (pp.funcname == 'sort') {
	    if (!private.currbrick_check(pp.funcname)) return F;
    	    r := private.currbrick.sort(pp.sort_axis);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'selav') {            # select/average
	    r := private.exec.selav(pp);

	} else if (pp.funcname == 'decomp2tms') {
	    private.curresult_to_TMS(pp);

	} else if (pp.funcname == 'bandpass') {
	    private.exec.bandpass(pp);

	} else if (pp.funcname == 'timepoly') {
	    private.exec.timepoly(pp);

	} else if (pp.funcname == 'apply') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    pp.rhv := pp.what;				# right-hand value
	    if (pp.rhv=='result') pp.rhv := private.curresult;	# ref?
    	    r := private.currbrick.apply(pp);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'addnoise') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    private.msb_simul.addnoise(private.currbrick, pp);

	} else if (pp.funcname == 'addspikes') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    private.msb_simul.addspikes(private.currbrick, pp);

	} else if (pp.funcname == 'corrupt_pgerr') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    r := private.msb_simul.corrupt_pgerr(private.currbrick, pp);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'corrupt_deloff') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    r := private.msb_simul.corrupt_deloff(private.currbrick, pp);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'corrupt_diperr') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    r := private.msb_simul.corrupt_diperr(private.currbrick, pp);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'corrupt_BEAMSHAPE') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    r := private.msb_simul.corrupt_BEAMSHAPE(private.currbrick, pp);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'BEAMSHAPE') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    private.check_pgw();			# private.pgw
    	    r := private.currbrick.BEAM(pp, private.pgw);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'corrupt_POINTING') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    r := private.msb_simul.corrupt_POINTING(private.currbrick, pp);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'POINTING') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    private.check_pgw();			# private.pgw
    	    r := private.currbrick.BEAM(pp, private.pgw);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'corrupt_MAKECAL') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    r := private.msb_simul.corrupt_MAKECAL(private.currbrick, pp);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'MAKECAL') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    private.check_pgw();			# private.pgw
    	    r := private.currbrick.MAKECAL(pp, private.pgw);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'DELFI') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    private.check_pgw();			# private.pgw
    	    r := private.currbrick.DELFI(pp, private.pgw);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'corrupt_DELFI') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    vv := private.msb_simul.gaussnoise(32, rms=pp.rms_simul_nsec, mean=0.0);
	    pp.simul_nsec := vv;			# attach to pp
	    pp.simulate := T;
    	    r := private.currbrick.DELFI(pp);		# NB: no pgw!
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'inspect_attached') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    include 'inspect.g';
	    inspect(private.currbrick.get_attached(pp.attached),pp.attached);

	} else if (pp.funcname == 'convert') {
	    if (!private.currbrick_check(pp.funcname)) return F;
    	    r := private.currbrick.convert(pp);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'fitpoly') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    private.check_pgw();			# private.pgw
    	    r := private.currbrick.fit(pp, private.pgw);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'clip') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    private.check_pgw();			# private.pgw
    	    r := private.currbrick.clip(pp, private.pgw);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'statistics') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    private.check_pgw();			# private.pgw
    	    r := private.currbrick.statistics(pp, private.pgw);
    	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'plot_data_slices' ||
		   pp.funcname == 'plot_data_TIF' ||
		   pp.funcname == 'plot_data_FIT' ||
		   pp.funcname == 'plot_data_RIF') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    private.check_pgw();			# private.pgw
	    r := private.currbrick.plot_data_slices(pp, private.pgw);
	    private.deal_with_result (pp, r);

	} else if (pp.funcname == 'uvcoverage') {
	    if (!private.currbrick_check(pp.funcname)) return F;
	    private.check_pgw();			# private.pgw
    	    r := private.currbrick.plot_uvcoverage(pp, private.pgw);
    	    private.deal_with_result (pp, r);

	} else {
	    s := paste('menuaction: not recognised:',pp.funcname);
	    print s;
	    private.tw.message(s);
	    return F;
	}
	s := paste('finished action:',pp.funcname);
	private.tw.message(s);
	return T;
    }

# Some functions called by menuaction():


# Some menu-items are just headers: They call the following action:

    private.notanaction := function() { 
	s := paste('not an action: just a header');
	private.tw.message(s);
    }

#---------------------------------------------------------------------
# Packaged routines (called by menu_action()):
#---------------------------------------------------------------------

    private.exec := [=];			# record of functions
    private.helptext := [=];			# record of functions

# Packaged operation: estimate/correct all 4 types of receptor errors:

    private.exec.decompant := function (pp=[=]) {
	wider private;
	if (!private.currbrick_check('exec.decompant')) return F;
	# print 'icurr=',icurr := private.bricklist.current();

	# Make a sub-brick by selection/averaging (if required):
	pp_fchs_selav := [fchs=pp.fchs];        # keep for later
	if (has_field(pp,'rcp_delay_offset')) {
	    # Special case: rcp_delay_offset uses phase-gradients:
	    if (pp.rcp_delay_offset) pp.fchs := '0.75';
	} 
	private.exec.selav(pp);                 # select/average

	private.check_pgw();			# private.pgw
	pp.iquv := private.decode_calibrator(pp.calibrator);

	# NB: The order is important here (for some of them)
	ss := "rcp_gain_real rcp_phase";
	ss := [ss,"rcp_ellipticity rcp_dipposerr"];	
	ss := [ss,"rcp_pzd"];
	ss := [ss,"rcp_Tsys"];
	ss := [ss,"rcp_delay_offset"];
	# ss := [ss,"rcp_gain_complex"];
	# ss := [ss,"ant_dipposerr"];	
	# ss := [ss,"ant_pointing ant_position"];

	# private.appctrl.enable();
	escape := F;
	do_selav_fchs := F;
	appctrl_test := F;                               
	for (rcperr in field_names(pp)) {
	    # print 'exec.decompant:',rcperr;
	    if (any(rcperr==ss) && pp[rcperr]) {
		s := paste('decompant: solving for:',rcperr,'...');
		private.tw.message(s);             # without \n..!
		print s := paste('\n **********************\n',s);
		private.tw.append(s);

		# Special case: attach two antbricks to pp:
		if (rcperr=='rcp_Tsys') {
		    private.currbrick_remember();  # remember current one
		    pp.auxbrick := [=];
		    for (name in "derived_TSYS_MULT") {
			public.get_antbrick ([colname=name]); 
			pp.auxbrick[name] := private.bricklist.get();
		    }
		    private.currbrick_restore();   # restore remembered one
		}

		if (appctrl_test) {                # temporary....!
		    print 'actual operations are disabled tor testing...';
		} else {
		    if (do_selav_fchs) {           # AFTER rcp_delay_offset
			private.exec.selav(pp_fchs_selav); 
		    }
		    pp.decomp := rcperr;
		    r := private.currbrick.decompant(pp, private.pgw);
		    origin := paste('exec.decompant',rcperr);
		    private.deal_with_result (pp, r, origin=origin);
		    if (is_fail(r)) {
			s := paste('problem with:',rcperr);
			s := paste(s,': sequence aborted');
			private.tw.message(s);
			print s := paste(s,'\n **********************\n');
			private.tw.append(s);
			escape := T;
		    }
		    if (escape) break;             # finish properly

		    # Display/print some results:
		    if (rcperr=='rcp_Tsys') {
			qq := [report='antrcp', hardcopy=T];
			private.curresult_print_report (qq);
		    }
		    # private.curresult_to_TMS();    # just display

		    # Special case: AFTER rcp_delay_offset (see above):
		    if (rcperr=='rcp_delay_offset') do_selav_fchs := T;
		}
		if (escape) break;
		s := paste('finished solving for:',rcperr);
		private.tw.message(s);
		print s := paste(s,'\n **********************\n');
		private.tw.append(s);

		# Application control:
		# if (private.appctrl.status('continue')) {
		#     print 'private.appctrl continue=T: continue';
		#     pp.step_by_step := F;
		# }
		# private.appctrl.suspend(enforce=pp.step_by_step);
		# if (private.appctrl.status('cancel')) {
		#     print 'private.appctrl cancel=T: escape';
		#     escape := T;
		# }
		if (escape) break;
	    }
	    if (escape) break;
	}
	# private.appctrl.disable();
	return T;
    }

    private.helptext.decompant := function() {
	s := paste('Estmating and applying various dipole errors:',
		   '\n ');
	return s;
    }

# Helper function: select/average over freq-channels and/or time-slots:

    private.exec.selav := function (pp=F, trace=F) {
	if (trace) print 'exec.selav():',field_names(pp);
	# Do some checks:
	if (!private.currbrick_check('exec.selav', mess=T)) {
	    if (trace) print 'currbrick_check() -> F';
	    return F;
	} else if (private.is_uvbrick(private.currbrick, mess=F)) {
	    ss := "fchs times ifrs corrs";            # uvbricke axes
	} else if (private.is_antbrick(private.currbrick, mess=F)) {
	    ss := "fchs times ants pols";             # antbrick axes
	} else {
	    if (trace) print 'brick type not recognised';
	    private.is_brick(private.currbrick, mess=T);
	    return F;
	}
	if (trace) print ss;

	# Make the input record for uvbrick.selav(rr): 
	rr := [=];
	for (fname in ss) {                           # all relevant axes
	    s := spaste('exec.selav(): ',fname);
	    if (!has_field(pp,fname)) {
		s := paste(s,'axis not specified');
		if (trace) print s;
		private.tw.append(s);
		private.tw.message(s);
		next;                                 # axis not specified
	    }
	    s := spaste(s,'=',pp[fname]);
	    s := paste(s,'(',len(pp[fname]),len(split(pp[fname],'')),')');
	    axis := private.brick_axis[fname];
	    naxis := private.currbrick.length(axis);
	    print 'exec.selav:',fname,'axis=',axis,naxis;
	    if (len(pp[fname])==1 && pp[fname]=='*') {
		s := paste(s,'wildcard(*)');
		if (trace) print s;
		private.tw.append(s);
		private.tw.message(s);
		next;                                 # copy axis entirely
	    } 
	    if (pp[fname]=='average') {
		if (naxis<=1) {
		    s := paste(s,'average, and naxis=',naxis);
		    if (trace) print s;
		    private.tw.append(s);
		    private.tw.message(s);
		    next;                             # one only
		}
	    }
	    vv := private.decode_uvb[fname](pp[fname]);
	    if (is_record(vv)) {
		if (trace) print fname,':',field_names(vv);
	    } else {
		print fname,': vv is not a record:',type_name(vv);
		next;
	    }
	    rr[axis] := vv;
	    if (trace) print s;
	    private.tw.append(s);
	    private.tw.message(s);
	}

	if (len(rr)==0) {
	    s := spaste('msbrick.exec.selav(): not required');
	    private.tw.append(s);
	    return T;                           # not required
	} 

	# OK, select/average the specified axes:
	r := private.currbrick.selav(rr, trace=trace);
	private.deal_with_result (pp, r, origin='exec.selav', 
				  rlist=F);	# new brick to bricklist 
	return T;
    }

# Translation between msbrick usage and brick_axis names:

    private.brick_axis := [=]; 
    private.brick_axis.ifrs  := 'ifr';
    private.brick_axis.ants  := 'ant';
    private.brick_axis.times := 'time';
    private.brick_axis.fchs  := 'freq';
    private.brick_axis.pols  := 'pol';
    private.brick_axis.corrs := 'corr';

# Packaged operation: make suggestions for attenuator settings
# for the WSRT, using SYSCAL sub-table column NFRA_TPOFF

    private.exec.TOPOR := function (pp=[hardcopy=T]) {
	print 'exec.TOPOR(',pp,')';
	r := private.currbrick_check('exec.TOPOR', 
				     'antbrick', mess=T);
	if (!r) return F;                      # not an antbrick
	# Make a sub-brick by selection/averaging (if required):
	private.exec.selav([fchs='average',times='average']);             

	r := private.currbrick.TOPOR(pp);      # returns string
    	if (is_fail(r)) {
	    s := paste('antbrick.TOPOR() failed!');
	    private.tw.message(s);
	    private.tw.append(s);
	    private.tw.append(r);
	    return s;
	} 
	private.tw.append(r);                  # TOPOR string
	if (pp.hardcopy) {                     # print hardcopy
	    s := private.currbrick.legend();
	    private.print(paste(s,'\n',r)); 
	}
	return r;
    }

# Packaged operation: estimate and divide out the bandpass:

    private.exec.bandpass := function (pp=[=]) {
	if (!private.currbrick_check('exec.bandpass')) return F;
	# print 'icurr=',icurr := private.bricklist.current();
	# Make a sub-brick by selection/averaging (if required):
	private.exec.selav([times='average']);             

	pp.operation := 'divide';
	pp.rhv := private.curresult;	# attach to param-record
	r := private.currbrick.apply(pp);
	private.deal_with_result (pp, r);
	return T;
    }

    private.helptext.bandpass := function() {
	s := paste('Estimating and applying bandpass corrections:',
		   '\n Produces a new brick, averaged over time',
		   '\n This brick may be applied (divided) to the original one.',
		   '\n ');
	return s;
    }

# Packaged operation: estimate and remove a time-polynomial:

    private.exec.timepoly := function (pp) {
	if (!private.currbrick_check('exec.timepoly')) return F;
        # print 'icurr=',icurr := private.bricklist.current();
	# Make a sub-brick by selection/averaging (if required):
	private.exec.selav([fchs='average']);             

	pp.fitaxis := 'time';
	r := private.curresult.fit(pp, private.pgw);
	private.deal_with_result (pp, r);
	pp.operation := 'subtract';
	pp.rhv := private.curresult;	# attach to param-record
	r := private.currbrick.apply(pp);
	private.deal_with_result (pp, r);
    }

    private.helptext.timepoly := function() {
	s := paste('Estmating and subtract a polynomial variation in time:',
		   '\n Produces a new uv-brick, averaged over freq',
		   '\n From this, polynomial coeff ere estimated',
		   '\n   for each corr/ifr individually.',
		   '\n NB: Separate polynomials for the real and imag parts.',
		   '\n These time-polynomials are then subtracted',
		   '\n   from the original data.',
		   '\n');
	return s;
    }


#=============================================================================
# Dealing with results:
#=============================================================================

# Deal with the result of an operation:
# If rlist=F, put brick results into the brick list.

    private.deal_with_result := function (pp=[=], ref result=F, 
					  rlist=T, origin=F) {
	wider private;

	if (is_string(origin)) {
	    # OK, given explicitly
	} else if (has_field(pp,'funcname')) {
	    origin := pp.funcname;
	} else {
	    origin := '??';
	}
    	s := paste('\n \n \n *** result of action:',origin);
    	s := paste(s,': ->',type_name(result));
	private.tw.append(s);
	print s;

	s := paste('input pp=:\n',private.tf.summary(pp,'pp'));
	private.tw.append(s);
    	if (is_fail(result)) {
	    print result;
	    private.tw.append(paste(result));
	    print paste('------------ escape --------\n');
	    return F;
	}
	# print s;

	# name := paste(origin,'->',private.result_label(result));
	name := paste(private.result_label(result));       # ....?
	# name := spaste(name,' (',origin,')');
	if (private.is_brick(result) && !rlist) {
	    s := paste(s,'(brick)');
	    private.bricklist.append(result,name);         # append to list
	    private.currbrick := private.bricklist.get();  # get reference
	} else if (origin=='statistics') {
	    private.tw.append(result.string);
	} else {
	    # n := private.curresult_counter +:= 1;           # increment 
	    # name := spaste(n,': ',name);		   # prepend...?
	    private.resultlist.append(result,name);	   # append to list
	    private.curresult := private.resultlist.get(); # get reference
	    if (is_boolean(result)) {
	    	s := paste(s,'value=',result);
	    } else if (is_numeric(result)) {
	    	s := paste(s,'shape=',shape(result));
	    }
	}
	# print 'deal_with_result:',s;

	sep := paste('-------------------------------\n'); # end indicator
	private.tw.append(sep);
	print sep;
	return T;
    }


    private.result_label := function (ref result) {

	if (private.is_brick(result)) {
	    s := result.label();

	} else if (private.uvbrick.is_decomprec(result)) {
	    s := paste(result.label);		
	    s := spaste(s,' (',result.descr,')');
	    s := spaste(s,' (MS=',result.msname,')');

	} else if (is_record(result)) {
	    if (has_field(result,'label')) {
		s := paste(result.label);	# 
	    } else {
		s := paste('record, fields:',field_names(result));
	    }	

	} else {
	    s := paste(type_name(result),shape(result),':');
	    if (is_string(result)) {
		s := paste(s,result);
	    } else if (is_boolean(result)) {
		if (len(result)==1) {
		    s := paste(s,'value=',result);
		} else {
		    s := paste(s,'nTrue=',len(result[result]));
		    s := paste(s,'nFalse=',len(result[!result]));
		} 
	    } else if (is_numeric(result)) {
		if (len(result)<=5) {
		    s := paste(s,'value=',result);
		} else {
		    s := paste(s,'min',min(result));
		    s := paste(s,'max',max(result));
		} 
	    }
	}
	return s;					# return string
    } 

# Show the current intermediary result (private.curresult):
    
    private.curresult_summary := function() {
	s := paste('\n\n Summary of last result (in results-list):'); 
	label := private.result_label(private.curresult);
	s := paste(s,'\n time=',time(),' result:',label,':');
    	if (private.is_brick(private.curresult)) {
	    s := paste(s,private.curresult.type(),':');
	    s := paste(s,', shape=',private.curresult.shape());
	    s := paste(s,', size(bytes)=',private.curresult.size());
	    s := paste(s,'\n',private.curresult.history());	
    	} else if (is_record(private.curresult)) {
	    s := paste(s,'record');
	    if (has_field(private.curresult,'type')) {
		s := paste(s,', type=',private.curresult.type);
	    }
	    s := paste(s,'\nfield_names:\n',field_names(private.curresult));
	    # s := paste(s,'\n',private.tf.summary(private.curresult,'result'));
	} else {
	    s := private.tf.summary(private.curresult,'result')
	}
	private.tw.append(s);
    }

# Make the current brick the last result (for applying):
    
    private.currbrick_to_curresult := function() {
	wider private;
    	if (!private.is_brick(private.currbrick)) {
	    s := paste('current brick is not a brick!');
	    s := paste(s,', but',type_name(private.currbrick));
	    private.tw.message(s);
	    return F;
	}
	# NB: private.currbrick is a reference to bricklist. Get a copy first.
	name := private.bricklist.itemlabel();		# get displayed name
	tmp := private.bricklist.get(copy=T);		# get a copy i.s.a. ref
	private.resultlist.append(tmp, name); 		# append to other list
	private.curresult := private.resultlist.get();	# get reference
	private.bricklist.remove();			# remove last item
	private.bricklist.get();			# get last item
	return T;
    }

# Restore the brick with the given index to 'current':

    private.currbrick_restore := function(index=F) {
	wider private;
	if (is_boolean(index)) {
	    index := private.currbrick_remembered;
	}
	newindex := private.bricklist.current(index);
	label := private.bricklist.itemlabel();         # clumsy....
	private.bricklist.itemlabel(label=label);       # clumsy....
	print 'restore as current uvbrick: index=',index,newindex,label;
	private.currbrick := private.bricklist.get();   # reference
	return T;
    }

    private.currbrick_remember := function() {
	wider private;
	index := private.bricklist.current();
	private.currbrick_remembered := index;
	print 'remember current uvbrick, index=',index;
	return T;
    }


# Make private.curresult into the current brick (if it is one):
    
    private.curresult_to_currbrick := function() {
	wider private;
    	if (!private.is_brick(private.curresult)) {
	    s := paste('result is not a brick!');
	    s := paste(s,', but',type_name(private.curresult));
	    private.tw.message(s);
	    return F;
	}
	# NB: private.currbrick is a reference to bricklist. Get a copy first.
	name := private.resultlist.itemlabel();		# get displayed name
	tmp := private.resultlist.get(copy=T);		# get a copy i.s.a. ref
	private.bricklist.append(tmp, name);		# append to other list
	private.currbrick := private.bricklist.get();	# get reference
	private.resultlist.remove();			# remove last item
	private.resultlist.get();			# get last item
	return T;
    }

# Convey the contents of private.curresult to TMS (if it is a decomprec):
    
    private.curresult_to_TMS := function(pp=[send2tms=F, hardcopy=T]) {
	wider private;
	print 'curresult_to_TMS(',pp,')';
	r := private.currbrick.decomp2tms(pp, private.curresult);
    	if (is_fail(r)) {
	    s := paste('decomp2tms() failed!');
	    private.tw.message(s);
	    private.tw.append(s);
	    private.tw.append(r);
	    return s;
	} 
	private.tw.append(r);                 # TMS string
	if (pp.send2tms) {                    # sent to TMS
	    # private.resultlist.remove();    # remove last item
	    s := 'decomprec (should be) removed from result-list';
	    private.tw.append(s);
	}
	if (pp.hardcopy) {                    # print hardcopy
	    s := private.currbrick.legend();
	    private.print(paste(s,'\n',r)); 
	}
	return r;
    }

# Show the data of private.curresult:
    
    private.curresult_showdata := function() {
	wider private;
    	if (private.is_brick(private.curresult)) {
	    s := private.curresult.showdata();
	    # private.tw.append(s);
	} else if (private.uvbrick.is_decomprec(private.curresult)) {
	    s := private.currbrick.decompshow(private.curresult);
	    # private.tw.append(s);
	} else {
	    s := private.tf.fully(private.curresult,'result');	
	    # private.tw.append(s);
	}	    
	title := private.result_label(private.curresult);
	private.guic.boxmessage (text=s, title=paste(title), 
				 background='white',
				 maxrows=40, maxcols=80);

	return T;
    }

# Show/print the reports attached to private.curresult:

    private.curresult_choice_report := function () {
	if (private.uvbrick.is_decomprec(private.curresult)) {
	    fnames := field_names(private.curresult.report);
	    if (len(fnames)<=0) return F;      # none available
	    return fnames;
	}
	return F;                              # forget it
    }

    private.curresult_print_report := function (pp=F) {
	s := paste('\n msbrick.curresult_print_report(',pp,'):');
	if (!private.uvbrick.is_decomprec(private.curresult)) {
	    s := paste(s,'curresult is not a decomp record');
	    return private.tw.append(s);
	} else if (!has_field(pp,'report')) {  # not specified
	    pp.report := F;                    # use the first
	} 
	private.tw.append(s);
	fnames := field_names(private.curresult.report);
	nfnames := len(fnames);
	if (nfnames<=0) {
	    return paste('no reports available');
	} else if (is_boolean(pp.report)) {    # not specified
	    pp.report := fnames[1];            # use the first
	} else if (pp.report=='first') {       # generic spec
	    pp.report := fnames[1];            # use the first
	} else if (pp.report=='last') {        # generic spec
	    pp.report := fnames[nfnames];      # use the last
	} else if (!any(fnames==pp.report)) {
	    return paste('reports not recognised:',pp.report);
	}
	ss := private.curresult.report[pp.report]; # OK, get it
	if (pp.hardcopy) private.print(ss);
	return private.tw.append(ss);
    }

# Plot the gsb-objects attached to private.curresult:
    
    private.curresult_choice_gsb := function () {
	if (!private.check_pgw(create=F)) return F; 
	fnames := private.pgw.get_gsb_fields(private.curresult);
	if (is_boolean(fnames)) return F;
	if (len(fnames)<=0) return F;
	return ['all',fnames];                 # all=mosaick               
    }

    private.curresult_plot_gsb := function (fname=F) {
	s := paste('msbrick.curresult_plot_gsb(',type_name(fname),'):');
	# print paste(s,fname);
	if (!private.uvbrick.is_decomprec(private.curresult)) {
	    s := paste(s,'curresult is not a decomp record');
	} else if (!is_string(fname)) {
	    s := paste(s,'fname is not a string:',fname);
	} else if (fname=='all') {
	    if (len(private.curresult.gsb)<=0) return F;  #..?
	    private.check_pgw();
	    private.pgw.mosaick(private.curresult.gsb, trace=T);
	} else {
	    private.check_pgw();
	    r := private.pgw.put_gsb(private.curresult.gsb[fname]);
	    if (is_fail(r)) print r;
	    return T;
	}
	print s;
	private.tw.append(s);
	private.tw.message(s);
	return F;
    }


#=============================================================================
# Make new bricks (from MS or simlation):
#=============================================================================

# Get a brick from the MS:

    public.get_uvbrick := function (pp) {
	wider private;
	private.tw.append(paste('\n\n\n get_uvbrick: input pp=',pp));
	if (!public.checkMS()) return F;

	dt := [pp.datatype,'axis_info'];		# datatypes
	if (pp.incl_flags) dt := [dt,'flag'];		# optional
	if (pp.incl_weights) dt := [dt,'weight'];	# optional 
	pp.datatypes := dt;

	for (spectral_window_id in pp.spwins) {
	    for (array_id in pp.arrays) {
		pp.spectral_window_id := spectral_window_id;
		pp.array_id := array_id;
		pp.name := spaste('get_uvbrick():');    # ......?
		private.bricklist.append(uvbrick(pp.name, private.tw), 
				         pp.name);		# init in list
		private.currbrick := private.bricklist.get();	# reference

	    	r := private.msb_MS.ms2uvbrick(private.currbrick, pp); 
	    	if (is_fail(r)) {			# problem
	    	    print r;				# if fail
	    	    print s := paste('msb.get_uvbrick: problem');
		    private.tw.append(s);
		    private.tw.append(paste(r));
		    s1 := 'removed the failed brick from the brick-list';
		    private.tw.append(s1);
		    private.bricklist.remove();
	    	    fail(s);
	    	} 

		# Average over time here, if required (not done by msdo):
		# NB: This causes problem in loops of more than one!!
		private.exec.selav ([times=pp.times]);
		# (NB: Remove the un-averaged brick from the blicklist afterwards!)

		private.brick_counter +:= 1;             # increment
		pp.name := spaste('<',private.brick_counter,'>');
		private.currbrick.name(pp.name);	# rename uvbrick

		msname := private.msb_MS.getMSfield('msname');
		s := paste('Get uvbrick from MS:',msname);
		private.currbrick.addtohistory(s);
		for (fname in field_names(pp)) {
	    	    s := spaste(' - pp.',fname,':');
	    	    s := paste(s,pp[fname]);
	    	    private.currbrick.addtohistory(s);
		}

		# s := private.currbrick.label('MS')    # prepend 'MS ->'
		s := private.currbrick.label();  
		private.bricklist.itemlabel(label=s);	# update label
		s := paste('new uvbrick created:',s);
		private.tw.append(s);
		# private.currbrick_showsummary();	# display 
	    }						# next array_id
	}						# next spectral_window_id

	private.tw.message('uvbrick(s) read successfully');
	return T;						# mandatory (?)
    }

# Get an ant-brick from the MS:

    public.get_antbrick := function (pp) {
	wider private;
	private.tw.append(paste('\n\n\n get_antbrick: input pp=',pp));
	if (!public.checkMS()) return F;

	if (!has_field(pp,'plot')) pp.plot := F;       # use jenmisc.checkfield()!

	pp.spwins := 1;                                # ....?
	pp.arrays := 1;                                # ....?

	for (spectral_window_id in pp.spwins) {
	    for (array_id in pp.arrays) {
		pp.spectral_window_id := spectral_window_id;
		pp.array_id := array_id;
		pp.name := spaste('get_antbrick():');    # ......?
		private.bricklist.append(uvbrick(pp.name, private.tw), 
				         pp.name);		# init in list
		private.currbrick := private.bricklist.get();	# reference

	    	r := private.msb_MS.ms2antbrick(private.currbrick, pp); 
	    	if (is_fail(r)) {			# problem
	    	    print r;				# if fail
	    	    print s := paste('msb.get_antbrick: problem');
		    private.tw.append(s);
		    private.tw.append(paste(r));
		    s1 := 'removed the failed brick from the brick-list';
		    private.tw.append(s1);
		    private.bricklist.remove();
	    	    fail(s);
	    	} 

		# Average over time here, if required (not done by msdo):
		# private.exec.selav ([times=pp.times]);
		# (NB: Remove the un-averaged brick from the blicklist afterwards!)

		private.brick_counter +:= 1;             # increment
		pp.name := spaste('<',private.brick_counter,'>');
		private.currbrick.name(pp.name);	# rename uvbrick

		msname := private.msb_MS.getMSfield('msname');
		s := paste('Get antbrick from MS:',msname);
		private.currbrick.addtohistory(s);
		for (fname in field_names(pp)) {
	    	    s := spaste(' - pp.',fname,':');
	    	    s := paste(s,pp[fname]);
	    	    private.currbrick.addtohistory(s);
		}

		# s := private.currbrick.label('MS');   # prepend 'MS ->'
		s := private.currbrick.label();
		private.bricklist.itemlabel(label=s);	# update label
		s := paste('new antbrick created:',s);
		private.tw.append(s);
		# private.currbrick_showsummary();	# display 

		if (pp.plot) {
		    private.check_pgw();		# private.pgw
		    qq := [xaxis='time', group='ant'];
		    r := private.currbrick.plot_data_slices(qq, private.pgw);
		    private.deal_with_result (qq, r);
		}
	    }						# next array_id
	}						# next spectral_window_id

	private.tw.message('antbrick(s) read successfully');
	return T;						# mandatory (?)
    }

# Simulate a uv/ant-brick:

    public.simulate_brick := function (pp, uvant=F) {
	wider private;
	s := paste('simulate_brick(pp,',uvant,'): input pp=');
	private.tw.message(paste(s,'...'));
	private.tw.append(paste('\n \n \n',s,'\n',pp));

	private.brick_counter +:= 1;                     # increment
	pp.name := spaste('<',private.brick_counter,'>');

	private.bricklist.append(uvbrick(pp.name, private.tw), 
				 pp.name);		# initialise in the list
	private.currbrick := private.bricklist.get();	# reference
	if (uvant=='uvbrick') {
	    private.msb_simul.simulate_uvbrick(private.currbrick, pp);
	} else if (uvant=='antbrick') {
	    private.msb_simul.simulate_antbrick(private.currbrick, pp);
	} else {
	    print s := paste('not recognised: uvant=',uvant);
	    private.tw.message(s);
	    return F;
	}
	# s := private.currbrick.label('simul');          # prepend with ->
	s := private.currbrick.label();                 # 
	s := spaste(s,' (source=',pp.source,')');       # append source name
	private.bricklist.itemlabel(label=s);		# update list-label
	private.currbrick_showsummary();		# display 
	private.tw.message('brick simulated successfully');
	return T;					# mandatory (?)
    }


#----------------------------------------------------------------------------
# Helper function: attach a pgplotter widget to private.pgw: 

    private.check_pgw := function(create=T) {
	wider private;
	if (!has_field(private,'has_pgw')) private.has_pgw := F;
	if (!private.has_pgw) {				# no pgplot widget
	    if (!create) return F;                      # do nothing
	    print 'msbrick check_pgw: make private.pgw';
	    include 'jenplot.g';
	    private.pgw := jenplot();		        # make one
	    private.pgw.gui('msbrick');			# launch the gui
	    private.has_pgw := T;			# indicator
	    whenever private.pgw.agent -> * do {
		s1 := paste($name,type_name($value),shape($value));
		print '\n msbrick: jenplot event:',s1;
		if ($name=='done') {
		    print 'msbrick: private.pgw.agent -> done event',$value;
		    # print 'msbrick: val private.pgw := F (disabled)';
		    # val private.pgw := F;			# (DON'T!!)
		    print 'msbrick: private.has_pgw := F (disabled)';
		    private.has_pgw := F;
		} else if ($name=='appl_continue') {
		    # do what?
		} else if ($name=='appl_cancel') {
		    # do what?
		} else {
		    print 'msbrick: jenplot event not recognised:',s1;
		}
	    }
	} else {
	    print 'check_pgw: private.pgw already exists';
	}
	return T;
    }

    private.check_pgplotter := function () {
	wider private;
	if (!has_field(private,'pgplotter')) private.pgplotter := F;
	if (is_boolean(private.pgplotter)) {
	    include 'pgplotter.g';			# only when needed
	    private.pgplotter := pgplotter();
	}
	return T; 
    }


#=========================================================
# Finished. Initialise and return the public interface:

    private.init();
    return public
};				# closing bracket
#=========================================================


# msb := test_msbrick();	# run test-routine
msb := msbrick();		# create an msb object













