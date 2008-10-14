# msbrick_selection_gui.g: gui's for msbrick ifr/freq/time selection
# J.E.Noordam, april 1999

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
# $Id: msbrick_selection_gui.g,v 19.0 2003/07/16 03:38:57 aips2adm Exp $

#---------------------------------------------------------


pragma include once
# print 'include msbrick_selection_gui.g  h01sep99';

#=========================================================
msbrick_selection_gui_ifrs := function (ifrs=F, ifr_number=F, 
					basel=F, tel_name=F,
					ant_name=F, ifr_name=F) {
    private := [=];
    public := [=];

    private.ifrs := ifrs;                       # current selection
    private.basel := basel;                     # baselines
    private.ifr_number := ifr_number;           # available ifrs
    private.tel_name := tel_name;
    private.ant_name := ant_name;               # optional string vector
    private.ifr_name := ifr_name;               # optional string vector
    # print 'msbrick_selection_gui_ifrs: input=\n',private;    # temporary

# Check the various constructor input arguments (called in init()): 

    private.check_input_args := function() {
	wider private;
	# print 'msbrick_selection_gui_ifrs: check_input_args()'; 
	if (is_boolean(private.tel_name)) private.tel_name := 'WSRT';
	if (private.tel_name=='WSRT') {
	    if (is_boolean(private.ant_name)) {
		# private.ant_name := "0 1 2 3 4 5 6 7 8 9 A B C D E F";
		private.ant_name := "0 1 2 3 4 5 6 7 8 9 A B C D";
	    }
	    private.nant := len(private.ant_name);
	    private.ant_shortname := private.ant_name;
	} else {
	    s := 'msbrick_selection_gui_ifrs:';
	    print s,'not recognised: tel_name=',private.tel_name;
	    return F;
	}
	return T;
    }

# Initialise:

    private.init := function() {
	wider private;
	r := private.check_input_args();
	if (!r) return F;

	include 'jenplot_pgwaux.g';
	private.pga := jenplot_pgwaux();        # incl profiler?
	whenever private.pga.agent -> done  do {
	    print 'private.pga event: done()';
	    public.agent -> dismiss(private.ifrs);
	}

	private.pga.attach_pgw(title='select ifrs');
	# inhibit boxcursor....? not really needed
	private.pga.env(axis='none');
	private.pga.message('drawing the screen....');

	dx := 0.1;
	dy := 0.1;

	private.pga.message('make_legend....');
	x0 := -1;
	y0 := -0.5;
	private.make_legend(x0, y0, dy);

	private.pga.message('make_ctrl_buttons....');
	x0 := 0.7;
	y0 := -0.5;
	private.make_ctrl_buttons(x0, y0);

	private.pga.message('make_special_clitems....');
	x0 := 0.7;
	y0 := 1;
	private.make_special_clitems(x0, y0, dy);

	private.pga.message('make_ant_clitems....');
	x0 := -1;
	y0 := 1;
	private.make_ant_clitems(x0, y0, dx, dy);

	private.pga.message('make_ifr_clitems....');
	x0 := -1;
	y0 := 1;
	private.make_ifr_clitems(x0, y0, dx, dy);

	private.pga.message('OK, go ahead');
	return T;
    }

# Agent for communication with outside world:

    public.agent := create_agent();
    whenever public.agent -> *  do {
	print 'msbrick_selection_gui_ifrs event:',$name;
	print '$value=',type_name($value),shape($value),':\n',$value;
    }


#--------------------------------------------------------------------

    private.make_ifr_clitems := function(x0=0, y0=0, dx=0.1, dy=0.1) {
	wider private;
	private.init_clindex();
	private.pga.bbuf('make_ifr_clitems');
	for (ant1 in [1:private.nant]) {
	    y := y0 - ant1*dy;
	    for (ant2 in [ant1:private.nant]) {
		x := x0 + ant2*dx;
		ifrname := spaste(private.ant_shortname[ant1],
				  private.ant_shortname[ant2]);
		ifrnr := 1000*ant1 + ant2;
		if (any(private.ifr_number==ifrnr)) {
		    emphasize := any(private.ifrs==ifrnr);
		    index := private.pga.clitem(x=x, y=y, text=ifrname, trace=F,
						emphasize=emphasize,
						userdata=ifrnr,
						callback=private.callback.ifr);
		    private.append_clindex(private.clindex.all, index);
		    if (emphasize) {
			private.append_clindex(private.clindex.input, index);
		    }
		    if (ant1==ant2) {
			private.append_clindex(private.clindex.autocorr, index);
		    } else {
			private.append_clindex(private.clindex.crosscorr, index);
			for (iant in [ant1,ant2]) {
			    private.append_clindex(private.clindex.ant[iant], index);
			}
			if (ant1<=10 && ant2<=10) {
			    private.append_clindex(private.clindex.wsrt_fixfix, index);
			} else if (ant1>10 && ant2>10) {
			    private.append_clindex(private.clindex.wsrt_movmov, index);
			} else {
			    private.append_clindex(private.clindex.wsrt_fixmov, index);
			}
		    }
		} else {
		    # private.pga.marker(x=x, y=y, label='-', trace=F);
		}
	    }
	}
	private.pga.ebuf('make_ifr_clitems');
	return T;
    }

# Clitems dealing with individual antennas:

    private.make_ant_clitems := function(x0=0, y0=0, dx=0.1, dy=0.1) {
 	wider private;
	private.pga.bbuf('make_ant_clitems');
	vertical := T;
	horizontal := F;
	magn := 1.5;                      # magnification factor
	for (ant in [1:private.nant]) {
	    antname := spaste(private.ant_shortname[ant]);
	    # Vertical column of clitems:
	    if (vertical) {
		y := y0 - ant*dy;
		x := x0;
		index := private.pga.clitem(x=x, y=y, text=antname,
					    userdata=ant,
					    color='green', charsize=magn,
					    callback=private.callback.ant);
	    }
	    # Horizontal row of clitems:
	    if (horizontal) {
		y := y0;
		x := x0 + ant*dx;
		index := private.pga.clitem(x=x, y=y, text=antname,
					    userdata=ant,
					    color='green', charsize=magn,
					    callback=private.callback.ant);
	    }
	    # private.append_clindex(private.clindex.ant[ant], index);
	}
	private.pga.ebuf('make_ant_clitems');
	return T;
    }

# Clitems for other groups of ifrs:

    private.make_special_clitems := function(x0=0, y0=0, dy=0.1) {
 	wider private;
	ss := "all none crosscorr autocorr";
	if (private.tel_name=='WSRT') {       # wsrt-specific
	    ss := [ss,"wsrt_fixmov wsrt_movmov wsrt_fixfix"];
	}
	ss := [ss,"input"];                   # last one
	private.pga.bbuf('make_special_clitems');
	x := x0;
	y := y0;
	magn := 1.5;                          # magnification factor
	for (s in ss) {
	    y -:= dy*magn;
	    private.pga.clitem(x=x, y=y, text=s,
			       color='green', charsize=magn,
			       callback=private.callback[s]);
	}
	private.pga.ebuf('make_special_clitems');
	return T;
    }


# Clitems for other groups of ifrs:

    private.make_legend := function(x0=0, y0=0, dy=0.1) {
 	wider private;
	ss := ' '; 
	n := 0;
	ss[n+:=1] := private.tel_name;
	ss[n+:=1] := 'Click on (groups of) ifrs';
	ss[n+:=1] := 'Selected ifrs are yellow';
	ss[n+:=1] := 'Click on dismiss button to finish';
	private.pga.bbuf('make_legend');
	x := x0;
	y := y0;
	magn := 1.5;                          # magnification factor
	for (s in ss) {
	    y -:= dy*magn;
	    private.pga.marker(x=x, y=y, label=s,
			       color='cyan', 
			       charsize=magn);
	}
	private.pga.ebuf('make_legend');
	return T;
    }


# Clitems for other groups of ifrs:

    private.make_ctrl_buttons := function(x0=0, y0=0, dy=0.1) {
 	wider private;
	private.pga.bbuf('make_ctrl_buttons');
	x := x0;
	y := y0;
	magn := 1.5;                          # magnification factor
	y -:= dy*magn;
	private.pga.clitem(x=x, y=y, text='OK',
			   color='background', charsize=magn,
			   background='yellow',
			   callback=private.callback.button_ok);
	y -:= dy*magn;
	private.pga.clitem(x=x, y=y, text='CANCEL',
			   color='background', charsize=magn,
			   background='red',
			   callback=private.callback.button_cancel);
	private.pga.ebuf('make_ctrl_buttons');
	return T;
    }

#------------------------------------------------------------------------
# The various categoies of clitem indices are stored as integer vectors:

    private.append_clindex := function(ref cc=F, index) {
	if (is_integer(cc)) {
	    val cc := [cc,index];              # index may be vector too
	} else {
	    print 'append_clindex: cc is',type_name(cc),index;
	    return F;
	}
	return T;
    }

    private.init_clindex := function() {
	wider private;
	val private.clindex := [=];
	ss := "input all crosscorr autocorr";
	ss := [ss,"wsrt_fixfix wsrt_movmov wsrt_fixmov"];
	for (s in ss) {
	    private.clindex[s] := [];
	}
	private.clindex.ant := [=];
	for (i in [1:private.nant]) {
	    private.clindex.ant[i] := [];
	}
	return T;
    }

#--------------------------------------------------------------
# Callback functions (cf is clitem definition record):

    private.callback := [=];               # record of functions

    private.callback.button_ok := function (cf=F) {
	# print 'callback: ok, cf=\n',cf;
	private.pga.done(notify=F);
	public.agent -> dismiss(private.ifrs);
    }
    private.callback.button_cancel := function (cf=F) {
	# print 'callback: cancel, cf=\n',cf;
	private.pga.done(notify=F);
	public.agent -> cancel();
    }

    private.callback.ifr := function (cf=F) {
	return private.mod_ifrs (cf.index,
				 toggle=F, value=!cf.emphasize);
    }
    private.callback.all := function (cf=F) {
	return private.mod_ifrs (private.clindex.all,
				 toggle=F, value=T);
    }
    private.callback.none := function (cf=F) {
	return private.mod_ifrs (private.clindex.all,
				 toggle=F, value=F);
    }
    private.callback.input := function (cf=F) {
	private.callback.none();
	r := private.mod_ifrs (private.clindex.input, 
			       toggle=F, value=T);
	private.pga.message('restored the input ifr selection');
	return r;
    }
    private.callback.ant := function (cf=F) {
	iant := cf.userdata;
	return private.mod_ifrs (private.clindex.ant[iant],
				 toggle=F, value=!cf.emphasize);
    }
    private.callback.autocorr := function (cf=F) {
	return private.mod_ifrs (private.clindex.autocorr,
				 toggle=F, value=!cf.emphasize);
    }
    private.callback.crosscorr := function (cf=F) {
	return private.mod_ifrs (private.clindex.crosscorr,
				 toggle=F, value=!cf.emphasize);
    }
    private.callback.wsrt_fixfix := function (cf=F) {
	return private.mod_ifrs (private.clindex.wsrt_fixfix,
				 toggle=F, value=!cf.emphasize);
    }
    private.callback.wsrt_movmov := function (cf=F) {
	return private.mod_ifrs (private.clindex.wsrt_movmov,
				 toggle=F, value=!cf.emphasize);
    }
    private.callback.wsrt_fixmov := function (cf=F) {
	return private.mod_ifrs (private.clindex.wsrt_fixmov,
				 toggle=F, value=!cf.emphasize);
    }

    private.mod_ifrs := function (index, toggle=T, value=F, trace=T) {
	s := spaste('mod_ifrs: n=',len(index));
	if (toggle) {
	    s := spaste(s,' toggle=',toggle);
	} else {
	    s := spaste(s,' value=',value);
	}
	if (trace) print s;
	private.pga.message(paste(s,'...'));
	for (i in index) {
	    cf := private.pga.get_clitem(i, copy=F);   # reference
	    if (toggle) {
		cf.emphasize := !cf.emphasize;         # toggle
	    } else {
		cf.emphasize := value;                 # set value
	    }
	} 
	private.pga.draw_clitems(index, trace=F);
	private.pga.message('finished');
	private.update_ifrs();
	return T;
    }

    private.update_ifrs := function () {
	wider private;
	ifrs := [];
	for (i in private.clindex.all) {
	    cf := private.pga.get_clitem(i);
	    if (cf.emphasize) {
		ifrs := [ifrs,cf.userdata];           # ifrnr
	    }
	}
	private.ifrs := ifrs;
	s := paste('total selected ifrs: ',len(private.ifrs));
	s := paste(s,'out of',len(private.ifr_number));
	private.pga.message(s);
	return T;
    }

#==========================================================================
# 
    private.init();
    return ref public;
};


#============================================================================
# Test-routine:

test_msbrick_selection := function () {
    ifr_number := [];
    ifrs := [];
    nant := 14;
    for (ant1 in [1:nant]) {
	if (ant1==8) next;                      # ignore
	for (ant2 in [ant1:nant]) {
	    if (ant2==3) next;                  # ignore
	    ifrnr := 1000*ant1 + ant2;
	    ifr_number := [ifr_number,ifrnr];
	    if (ant2<4) ifrs := [ifrs,ifrnr];
	}
    }
    return ref msbrick_selection_gui_ifrs(ifrs, ifr_number);
}
# print msg := test_msbrick_selection();
