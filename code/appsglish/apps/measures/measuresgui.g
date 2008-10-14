# measuresgui.g: Access to measures classes using a gui
# Copyright (C) 1998,1999,2000,2001,2002,2003
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: measuresgui.g,v 19.3 2004/08/25 01:29:52 cvsmgr Exp $
#
# This file is not meant to be included independently. measures.g will include
# it if and when necessary.
#
pragma include once;

include 'widgetserver.g';
include 'clipboard.g';
include 'note.g';
include 'choice.g';
#
#
# Closure object
#
  const measuresgui := function(ref private, ref public, widgetset=dws) {

    if (!serverexists('dcb', 'clipboard', dcb)) {
       return throw('The clipboard server "dcb" is either not running or not valid',
                     origin='measuresgui.g');
    }
    if (!serverexists('dq', 'quanta', dq)) {
       return throw('The quanta server "dq" is either not running or not valid',
                     origin='measuresgui.g');
    }
    global system;
#
# showframe (g) show specified frame elements on CLI or GUI
#
    const private.showframe := function(g=T) {
      wider private;
      if (g && dq.testbf()) {
	if (!is_agent(private.frameshow[1]) ||
	    has_field(private.frameshow[1], 'killed')) {
	  widgetset.tk_hold();
	  nf0 := dq.createbf(title='Frame values set');
	  if (!dq.testbf(nf0)) {
	    widgetset.tk_release();
	    return F;
	  };
	  private.frameshow[1] := dq.getbf(nf0);
	  private.frameshow[1]->unmap();
	  widgetset.tk_release();
	  fr00 := private.bargui(private.frameshow[1], private.frameshow[1],
				 opt=F, xt=T);
	  private.bargui2(fr00.created, 'Frames',
		       'measures.measures.doframe');
	  private.frameshow[2] := widgetset.frame(private.frameshow[1], side='left');
	  private.frameshow[3] := widgetset.frame(private.frameshow[2]);
	  private.frameshow[4] := widgetset.frame(private.frameshow[2], width=5);
	  private.frameshow[5] := widgetset.frame(private.frameshow[2]);

	  frfill := function(ref fr, nam, tx, ns) {
	    wider private;
	    private.frameshow[spaste(nam, 'tx')] := tx;
	    private.frameshow[spaste(nam, '0a')] :=
	      widgetset.frame(fr[3], side='left');
	    private.frameshow[spaste(nam, '0')] :=
	      widgetset.label(private.frameshow[spaste(nam, '0a')],
		    text=tx, justify='left', anchor='w');
	    private.frameshow[spaste(nam, '1b')] :=
	      widgetset.frame(fr[4], side='left');
	    private.frameshow[spaste(nam, '1')] :=
	      widgetset.label(private.frameshow[spaste(nam, '1b')],
		    text='none', width=5, relief='sunken');
	    private.frameshow[spaste(nam, '1a')] :=
	      widgetset.frame(fr[5], side='left');
	    for (i in ns) {
	      private.frameshow[spaste(nam, i)] :=
		widgetset.label(private.frameshow[spaste(nam, '1a')],
		      text='', relief='sunken');
	    };
	  }

	  frfill(private.frameshow, 'lb01', 'Epoch'           , "2 3");
	  frfill(private.frameshow, 'lb02', 'Direction'       , "2 3");
	  frfill(private.frameshow, 'lb03', 'Position'        , "2 3 4");
	  frfill(private.frameshow, 'lb04', 'Radial velocity' , "2");
	  frfill(private.frameshow, 'lb05', 'Frequency'       , "2");
	  frfill(private.frameshow, 'lb06', 'Comet'           , "2");
          private.frameshow[1]->map();
	};
	if (length(private.framestack) > 0) {
	  private.frameshow[2]->unmap();
	  for (i in ind(private.framestack)) {
	    x := '';
	    if (has_field(private.framestack[i], 'lb') &&
		is_string(private.framestack[i].lb))
	      x := spaste('(', private.framestack[i].lb, ')');
	    if (!has_field(private.framestack[i]) && 
		is_string(private.framestack[i])) {
	      x := spaste('(', private.framestack[i], ')');
	      private.frameshow.lb060->text(paste(private.frameshow.lb06tx,x));
	      private.frameshow.lb061->text(public.comettype());
	    } else if (private.framestack[i].type == 'epoch') {
	      private.frameshow.lb010->text(paste(private.frameshow.lb01tx,x));
	      private.frameshow.lb011->text(private.framestack[i].refer);
	      private.frameshow.lb012->text(dq.time(private.framestack[i].m0,
							form="mjd"));
	      private.frameshow.lb013->text(dq.time(private.framestack[i].m0,
							form="ymd"));
	    } else if (private.framestack[i].type == 'direction') {
	      private.frameshow.lb020->text(paste(private.frameshow.lb02tx,x));
	      private.frameshow.lb021->text(private.framestack[i].refer);
	      private.frameshow.lb022->text(dq.time(private.framestack[i].m0));
	      private.frameshow.lb023->text(dq.angle(private.framestack[i].m1));
	    } else if (private.framestack[i].type == 'position') {
	      private.frameshow.lb030->text(paste(private.frameshow.lb03tx,x));
	      private.frameshow.lb031->text(private.framestack[i].refer);
	      private.frameshow.lb032->text(dq.angle(private.framestack[i].m0));
	      private.frameshow.lb033->text(dq.angle(private.framestack[i].m1));
	      private.frameshow.lb034->text(dq.tos(private.framestack[i].m2));
	    } else if (private.framestack[i].type == 'radialvelocity') {
	      private.frameshow.lb040->text(paste(private.frameshow.lb04tx,x));
	      private.frameshow.lb041->text(private.framestack[i].refer);
	      private.frameshow.lb042->text(dq.tos(private.framestack[i].m0));
	    } else if (private.framestack[i].type == 'frequency') {
	      private.frameshow.lb050->text(paste(private.frameshow.lb05tx,x));
	      private.frameshow.lb051->text(private.framestack[i].refer);
	      private.frameshow.lb052->text(dq.tos(private.framestack[i].m0));
	    };
	  };
	  private.frameshow[2]->map();
	};
      } else {
	if (length(private.framestack) > 0) {
	  for (i in ind(private.framestack))
	    print private.framestack[i];
	};
      };
      return T;
    }
#
# showauto (g) show specified auto elements on CLI or GUI
#
    const private.showauto := function(g=T) {
      wider private;
      if (g && dq.testbf() && length(private.autostack) > 0) {
	if (!is_agent(private.autoshow[1]) ||
	    has_field(private.autoshow[1], 'killed')) {
	  widgetset.tk_hold();
	  nf0 := dq.createbf(title='Automatic conversions');
	  if (!dq.testbf(nf0)) {
	    widgetset.tk_release();
	    return F;
	  };
	  private.autoshow[1] := dq.getbf(nf0);
          private.autoshow[1]->unmap();
	  widgetset.tk_release();
	  fr00 := private.bargui(private.autoshow[1],
				 private.autoshow[1], opt=F);
	  private.bargui2(fr00.created, 'Frames',
		       'measures.measures.doframe');

	  frfill := function(ref fr, nam, tx, ns) {
	    wider private;
	    private.autoshow[spaste(nam, '0')] :=
	      widgetset.label(fr, text=tx, width=16, justify='left');
	    private.autoshow[spaste(nam, '1')] :=
	      widgetset.label(fr, text='none', width=5, relief='sunken');
	    for (i in ns) {
	      private.autoshow[spaste(nam, i)] :=
		label(fr, text='', relief='sunken');
	    };
	  }

	  private.autoshow.fr01 := widgetset.frame(private.autoshow[1], side='left');
	  frfill(private.autoshow.fr01, 'lb01', 'Epoch           ', "2 3");
	  private.autoshow.fr02 := widgetset.frame(private.autoshow[1], side='left');
	  frfill(private.autoshow.fr02, 'lb02', 'Direction       ', "2 3");
	  private.autoshow.fr04 := widgetset.frame(private.autoshow[1], side='left');
	  frfill(private.autoshow.fr04, 'lb04', 'Radial velocity ', "2");
          private.autoshow.fr05 := widgetset.frame(private.autoshow[1], side='left');
	  frfill(private.autoshow.fr05, 'lb05', 'Frequency       ', "2");
          private.autoshow[1]->map();
	};
	if (length(private.autostack) > 0) {
	  for (i in ind(private.autostack)) {
	    if (is_record(private.autostack[i]) &&
		has_field(private.autostack[i], "meas")) {
	      cr := public.measure(private.autostack[i].meas,
				   private.autostack[i].ref,
				   off=private.autostack[i].oof);
	      if (private.autostack[i].meas.type == 'epoch') {
		if (has_field(private.framestack, "epoch"))
		  cr := public.measure(private.framestack['epoch'],
				       private.autostack[i].ref,
				       off=private.autostack[i].oof);
		private.autoshow.lb011->text(cr.refer);
		private.autoshow.lb012->text(dq.time(cr.m0,
						      form="mjd"));
		if (cr.refer == 'LAST' || cr.refer == 'LMST' ||
		    cr.refer == 'GMST1' || cr.refer == 'GAST')
		  private.autoshow.lb013->text(' ');
		else
		  private.autoshow.lb013->text(dq.time(cr.m0,
							form="ymd"));
	      } else if (private.autostack[i].meas.type == 'direction') {
		private.autoshow.lb021->text(cr.refer);
		private.autoshow.lb022->text(dq.form.long(cr.m0));
		private.autoshow.lb023->text(dq.form.lat(cr.m1));
	      } else if (private.autostack[i].meas.type == 'radialvelocity') {
		private.autoshow.lb041->text(cr.refer);
		private.autoshow.lb042->text(dq.tos(cr.m0));
              } else if (private.autostack[i].meas.type == 'frequency') {
                private.autoshow.lb051->text(cr.refer);
                private.autoshow.lb052->text(dq.tos(cr.m0));
	      };
	    };
	  };
	};
      } else {
	if (length(private.autostack) > 0) {
	  for (i in ind(private.autostack)) {
	    cr := public.measure(private.autostack[i].meas,
				 private.autostack[i].ref,
				 off=private.autostack[i].oof);
	    if (private.autostack[i].meas.type == 'epoch') {
	      if (has_field(private.framestack, "epoch"))
		cr := public.measure(private.framestack['epoch'],
				     private.autostack[i].ref,
				     off=private.autostack[i].oof);
	    };
	    print cr;
	  };
	};
      };
      return T;
    }
#
# Get user routine name and format
#
    const private.rtname := function(ref where) {
      wider private;
      widgetset.tk_hold();
      frm0 := widgetset.frame(title='User routine information');
      frm0->unmap();
      widgetset.tk_release();
      frm01 := widgetset.frame(frm0, side='left');
      l0 := widgetset.label(frm01, 'Formatting:         ');
      widgetset.popuphelp(l0, spaste('Specify the type of formatting'));
      bt0 := widgetset.button(frm01, where.shbt, type='menu', relief='sunken',
		    background='white');
      mn0 := [=];
      for (i in "unit long lat len vel freq dtime") {
	mn0[i] := widgetset.button(bt0, i, value=i);
	whenever mn0[i]->press do {
	  where.shbt := $value;
	  bt0->text(where.shbt);
	}
      };
      frm02 := widgetset.frame(frm0, side='left');
      l := widgetset.label(frm02, 'Name of user routine:');
      widgetset.popuphelp(l, spaste('Specify a global glish variable name ',
			  'which is a routine that will be ',
			  'executed to get user result. The ',
			  'routine has a measure as argument, ',
			  'and should return a quantity.'));
      e := widgetset.entry(frm02, width=10, background='white', relief='groove',
		 exportselection=T, width=12);
      e->bind('<Tab>', 'tab');
      e->insert(where.rtname);
      name := where.rtname;
      widgetset.popuphelp(e, spaste('Type variable name'));
      frm03 := widgetset.frame(frm0, side='left');
      bt1 := widgetset.button(frm03, 'OK', type='action');
      bt2 := widgetset.button(frm03, 'Dismiss', type='dismiss');
      frm0->map();
      await e->return, e->tab, bt1->press, bt2->press;
      if ($agent != bt2) name := e->get();
      if (name != '') where.rtname := name;
      popupremove(e);
      popupremove(l);
      popupremove(l0);
      popupremove(frm0);
    }
#
# Start GUI interface method
#
# gui() start GUI interface
#
    const private.gui := function(parent=F) {
      if (dq.testbf(n=T)) return T;
      if (!have_gui()) return F;
      widgetset.tk_hold();
      frn0 := dq.createbf(title='Measure tools and applications',
			  parent=parent, onlyone=T);
      if (!dq.testbf(frn0)) {
	widgetset.tk_release();
	return F;
      };
      dq.getbf(frn0)->unmap();
      widgetset.tk_release();
      bfr := private.bargui(dq.getbf(frn0), dq.getbf(frn0), xt=T, mt=T);
      widgetset.popuphelp(bfr.button, spaste('A set of generic tools ',
				   'to work  with quantities and/or ',
				   'epochs, directions and other ',
				   'measures.'));
      box := [=];
      for (i in 
	     "Epoch Direction Position Frequency RadialVelocity Doppler") {
	box[i] := widgetset.button(bfr.button, i, value=i);
	whenever box[i]->press do { 
          if ($value == 'Epoch') {
	    public.epochgui();
	  } else if ($value == 'Position') {
	    public.positiongui();
	  } else if ($value == 'Direction') {
	    public.directiongui();
	  } else if ($value == 'Frequency') {
	    public.frequencygui();
	  } else if ($value == 'Doppler') {
	    public.dopplergui();
	  } else if ($value == 'RadialVelocity') {
	    public.radialvelocitygui();
	  } else dq.errorgui(paste(paste("Selected", $value),
				   "type not yet implemented"));
	}
      };
      private.bargui2(bfr.created, 'Measures', 'general.measures');
      dq.getbf(frn0)->map();
#
# GUI started
#
      note('GUI started for measures',
	   priority='NORMAL', origin='measures');
      return (dq.testbf(frn0));
    }
#
# Subsidiary gui methods
#
# Horizontal fill gui
#
    const private.fillhgui := function(fr0, sz=50) {
      return widgetset.frame(fr0, width=sz, height=1);
    }
#
# Vertical fill frame
#
    const private.fillvgui := function(fr0, sz=50) {
      return widgetset.frame(fr0, height=sz, width=1);
    }
#
# Top bar frame standard fill out
#
    const private.bargui := function(fr0, ref outfr, opt=T, name='Tool',
				  xt=F, mt=F) {
      wider private;
      private.fillobslist();
      private.filllinelist();
      private.fillsourcelist();
      fr00 := widgetset.frame(fr0, side='left', relief='raised', expand='x');
      bt000 := widgetset.button(fr00, 'File', type='menu', relief='flat');
      a := spaste('Menu of window operations:\n',
		  '- close the current window\n',
		  '- close all other measures-related tool windows\n');
      if (mt) {
	a := spaste(a, '- exit the glish session');
      };
      widgetset.popuphelp(bt000, a, 'File button', combi=T);
      mn0000 := [=];
      mn0000.Close := widgetset.button(bt000, 'Dismiss window', value='Close',
				       type='dismiss');
      if (mt) {
	  mn0000.All := widgetset.button(bt000,
					 'Dismiss other measures windows', 
					 value='All', type='dismiss');
      };
      whenever mn0000.Close->press do {
	 popupremove(outfr);
      }
      if (mt) {
	  whenever mn0000.All->press do {
	      dq.delallbf();
	  }
      };
      if (mt) {
	mn0000.Exit := widgetset.button(bt000, 'Exit Glish', value='Exit');
	mn0000.Exit->foreground('red');
	whenever mn0000.Exit->press do {
	  local a := choice('Really exit?', "Yes Cancel", default=2);
	  if (a == 'Yes') {
	    dq.delallbf(T);
	    exit;
	  };
	};
      };
      if (xt) {
	bt0020 := [=];
	bt0020a := [=];
	bt002 := widgetset.button(fr00, 'Format', type='menu', relief='flat');
	widgetset.popuphelp(bt002, spaste('Specify:\n',
				'- output display formats\n',
				'- interval for automatic timers\n',
				'- limits (e.g. elevation limit)'),
		  'Formats button', combi=T);
	for (i in ['Precision...',  'Angle precision...',
		  'Time precision...']) {
	  bt0020[i] := widgetset.button(bt002, i);
	};
	whenever bt0020['Precision...']->press do
	  dq.setformat('prec', '...');
	whenever bt0020['Angle precision...']->press do
	  dq.setformat('aprec', '...');
	whenever bt0020['Time precision...']->press do
	  dq.setformat('tprec', '...');
	for (i in ["Longitude Latitude Rise/set-time Elevation-limit",
	       "Auto-interval", 'Velocity', 'Frequency', 'Doppler type',
	       'Default unit']) {
	  bt0020[i] := widgetset.button(bt002, i, value=i, type='menu');
	  bt0020a[i] := [=];
	};
	i := 'Longitude';
	for (j in dq.getformat('lst').long) {
	  bt0020a[i][j] := widgetset.button(bt0020[i], j, value=j);
	  whenever bt0020a[i][j]->press do
	    dq.setformat('long', $value);
	};
	i := 'Latitude';
	for (j in dq.getformat('lst').lat) {
	  bt0020a[i][j] := widgetset.button(bt0020[i], j, value=j);
	  whenever bt0020a[i][j]->press do
	    dq.setformat('lat', $value);
	};
	i := 'Rise/set-time';
	for (j in dq.getformat('lst').dtime) {
	  bt0020a[i][j] := widgetset.button(bt0020[i], j, value=j);
	  whenever bt0020a[i][j]->press do
	    dq.setformat('dtime', $value);
	};
	i := 'Elevation-limit';
	for (j in dq.getformat('lst').elev) {
	  bt0020a[i][j] := widgetset.button(bt0020[i], j, value=j);
	  whenever bt0020a[i][j]->press do
	    dq.setformat('elev', $value);
	};
	i := 'Auto-interval';
	for (j in dq.getformat('lst').auto) {
	  bt0020a[i][j] := widgetset.button(bt0020[i], j, value=j);
	  whenever bt0020a[i][j]->press do {
	    dq.setformat('auto', $value);
	  };
	};
	i := 'Velocity';
	for (j in dq.getformat('lst').vel) {
	  bt0020a[i][j] := widgetset.button(bt0020[i], j, value=j);
	  whenever bt0020a[i][j]->press do {
	    dq.setformat('vel', $value);
	  };
	};
	i := 'Frequency';
	for (j in dq.getformat('lst').freq) {
	  bt0020a[i][j] := widgetset.button(bt0020[i], j, value=j);
	  whenever bt0020a[i][j]->press do {
	    dq.setformat('freq', $value);
	  };
	};
	i := 'Doppler type';
	for (j in dq.getformat('lst').dop) {
	  bt0020a[i][j] := widgetset.button(bt0020[i], j, value=j);
	  whenever bt0020a[i][j]->press do {
	    dq.setformat('dop', $value);
	  };
	};
	i := 'Default unit';
	for (j in dq.getformat('lst').unit) {
	  bt0020a[i][j] := widgetset.button(bt0020[i], j, value=j);
	  whenever bt0020a[i][j]->press do {
	    dq.setformat('unit', $value);
	  };
	};
      };
      if (xt) {
	bt0030 := [=];
	private.timcl := F;
	fr00x3a := widgetset.frame(fr00, side='left');
	bt003a := widgetset.button(fr00x3a, 'Frame', type='menu', relief='flat');
	widgetset.popuphelp(bt003a, spaste('Fast specification options for ',
				 'the reference frame ',
				 'for Measure conversions ',
				 '(like where you are and when ',
				 'you are interested; ',
				 'which direction you are looking)'),
		  'Frame button', combi=T);
	bt003a0 := [=];
	bt003a0['When'] := widgetset.button(bt003a, 'When', type='menu');
	for (i in ["Now Auto No-Auto Date/time...",
		  'Offset from now...', "Full-epoch"]) {
	  bt0030[i] := widgetset.button(bt003a0['When'], i);
	};
	whenever bt0030['Now']->press do
	  public.framenow();
	whenever bt0030['Auto']->press do {
	  t := dq.getformat('auto');
	  public.frameauto(t);
	};
	whenever bt0030['No-Auto']->press do
	  private.timcl := F;
	whenever bt0030['Date/time...']->press do {
	  a := (public.epoch('UTC',
			     dq.entergui('Date/time', 
					 dq.time(dq.quantity('today'),
						 form="time ymd"))));
	  if (is_measure(a)) public.doframe(a);
	};
	whenever bt0030['Offset from now...']->press do {
	  a := public.epoch('UTC',
			    dq.entergui('offset date/time from now', 
					dq.time(dq.quantity('1.0d'),
						form="time mjd")),
			    off=public.epoch('utc','today'));
	  if (is_measure(a)) {
	    a := public.measure(a, 'utc');
	    public.doframe(a);
	  };
	};
	whenever bt0030['Full-epoch']->press do public.epochgui();

	bt003a0['Where'] := widgetset.button(bt003a, 'Where on Earth', type='menu');
	bt0040 := [=];
	for (i in "Observatory Longitude... Full-position") {
	  if (i == 'Observatory')
	    bt0040[i] := widgetset.button(bt003a0['Where'], i, type='menu');
	  else
	    bt0040[i] := widgetset.button(bt003a0['Where'], i);
	};
	mn00400 := [=];
	for (i in private.posval.obs) {
	  mn00400[i] := widgetset.button(bt0040[1], i, value=i);
	  whenever mn00400[i]->press do {
	    j := $value;
	    cr := public.observatory(j);
	    cr.lb := j;
	    public.doframe(cr);
	  }
	};
	whenever bt0040['Longitude...']->press do {
	  e := '180deg';
	  if (has_field(private.framestack, 'position') &&
	      is_measure(private.framestack['position'])) {
	    e := paste(dq.angle(private.framestack['position'].m0));
	  };
	  c := dq.entergui('Longitude', e);
	  if (!is_fail(c)) {
	    a := (public.position('WGS84', c[1], '0deg', '0m'));
	    if (is_measure(a)) public.doframe(a);
	  };
	};
	whenever bt0040['Full-position']->press do public.positiongui();

	bt003a09['Rest'] := widgetset.button(bt003a, 'Line rest frequency',
					     type='menu');
	bt00409 := [=];
	for (i in "Line Frequency... Full-frequency") {
	  if (i == 'Line') {
	    bt00409[i] := widgetset.selectablelist(parent=bt003a09['Rest'],
						   lead=bt003a09['Rest'],
						   label='Line', updatelabel=F,
						   list=private.frqval.line);

	  } else {
	    bt00409[i] := widgetset.button(bt003a09['Rest'], i);
	  };
	};
	whenever bt00409['Line']->select do {
	  j := $value.item;
	  cr := public.spectralline(j);
	  cr.lb := j;
	  public.doframe(cr);
	}

	whenever bt00409['Frequency...']->press do {
	  a := (public.frequency('REST',
				 dq.entergui('frequency',
					     dq.tos(dq.constants('HI')))));
	  if (is_measure(a)) public.doframe(a);
	};
	whenever bt00409['Full-frequency']->press do public.frequencygui();

	bt003a09a['Which'] := widgetset.button(bt003a, 'Which direction',
					       type='menu');
	bt00409a := [=];
	for (i in "Source Planet J2000... Full-direction") {
	  if (i == 'Planet') {
	    bt00409a[i] := widgetset.button(bt003a09a['Which'], i,
					    type='menu');
	  } else if (i == 'Source') {
            bt00409a.listsel := widgetset.selectablelist(parent=bt003a09a['Which'], 
							 lead=fr00x3a,
							 updatelabel=T,
							 label='Source',
							 list=private.dirval.source, 
                                             hlp='Select source');
	  } else {
	    bt00409a[i] := widgetset.button(bt003a09a['Which'], i);
          }
	};
	mn004009a := [=];
	for (i in private.dirval.planet) {
	  mn004009a[i] := widgetset.button(bt00409a['Planet'], i, value=i);
	  whenever mn004009a[i]->press do {
	    j := $value;
	    cr := public.direction(j);
	    cr.lb := j;
	    private.fillnow();
	    public.doframe(cr);
	  }
	};
	whenever bt00409a.listsel->select do {
	  cr := public.source($value.item);
	  cr.lb := $value.item;
	  public.doframe(cr);
	}
	whenever bt00409a['J2000...']->press do {
	  e := '12:00 -20d00m';
	  if (has_field(private.framestack, 'direction') &&
	      is_measure(private.framestack['direction'])) {
	    e := paste(dq.time(private.framestack['direction'].m0),
		       dq.angle(private.framestack['direction'].m1));
	  };
	  c := dq.entergui('RA DEC', e);
	  if (!is_fail(c)) {
	    c := split(paste(c, '0deg 0deg'));
	    a := (public.direction('J2000', c[1], c[2]));
	    if (is_measure(a)) public.doframe(a);
	  };
	};
	whenever bt00409a['Full-direction']->press do public.directiongui();

	bt003a09b['What'] := widgetset.button(bt003a, 'What velocity', type='menu');
	bt00409b := [=];
	for (i in ['Velocity...', 'Velocity (radio def)...',
		  'Velocity (optical def)...', "Full-velocity"]) {
	  bt00409b[i] := widgetset.button(bt003a09b['What'], i, value=i);
	};
	whenever bt00409b['Velocity...']->press,
	         bt00409b['Velocity (optical def)...']->press,
	         bt00409b['Velocity (radio def)...']->press do {
	  e := '0km/s';
	  j := $value;
	  if (has_field(private.framestack, 'radialvelocity') &&
	      is_measure(private.framestack['radialvelocity'])) {
	    if (j == 'Velocity...') {
	      e := (dq.form.vel(private.framestack['radialvelocity'].m0));
	    } else if (j == 'Velocity (radio def)...') {
	      e := dq.form.vel(public.
				   todoppler('radio',
				      private.framestack['radialvelocity']).m0);
	    } else {     
	      e := dq.form.vel(public.
				   todoppler('opt',
				      private.framestack['radialvelocity']).m0);
	    };
	  };
	  c := dq.entergui('Velocity (LSRK)', e);
	  if (!is_fail(c)) {
	    if (j == 'Velocity...') {
	      a := (public.radialvelocity('LSRK', c[1]));
	    } else if (j == 'Velocity (radio def)...') {
	      a := public.toradialvelocity('LSRK', 
					   public.
					   doppler('radio', c[1]));
	    } else {
	      a := public.toradialvelocity('LSRK', 
					   public.
					   doppler('opt', c[1]));
	    };
	    if (is_measure(a)) public.doframe(a);
	  };
	};
	whenever bt00409b['Full-velocity']->press do public.radialvelocitygui();

	bt003a0['Comet'] :=
	  widgetset.button(bt003a, 'Which comet');
	whenever bt003a0['Comet']->press do {
	  public.framecomet(dq.entergui('Comet table name', ''));
	};

	bt003a0['Show'] := widgetset.button(bt003a, 'Show active frame');
	bt003a0['No-show'] := widgetset.button(bt003a, 'No-show of active frame');
	whenever bt003a0['Show']->press do public.showframe();
	whenever bt003a0['No-show']->press do val private.frameshow[1] := F;
      };
      
      fr009ab := private.fillhgui(fr00);

      if (opt) {
	bt001 := widgetset.button(fr00, name, type='menu', relief='flat');
      };

      if (mt) {
	fr00x5a := widgetset.frame(fr00, side='left');
	bt005 := widgetset.button(fr00x5a, 'Application', type='menu', relief='flat');
	widgetset.popuphelp(bt005, spaste('A set of special, pre-programmed ',
				'operations, like:\n',
				'- clocks (LST, UTC, ...)\n',
				'- rise/set times\n',
				'In most cases you have to specify ',
				'where you are (or want to be), ',
				'with Frame->Where.'),
		  'Application', combi=T);
	bt0050a := [=];
	for (i in ["Time Clock Rise/set", 'Frequency to velocity',
		  'Velocity to frequency']) {
	  bt0050a[i] := widgetset.button(bt005, i, value=i, type='menu');
	  if (i == 'Rise/set') {
	    widgetset.popuphelp(bt0050a[i], spaste('Give the rise and set time ',
					 'of a source (for today if ',
					 'no Frame->When set), ',
					 'at the place specified ',
					 'with Frame->Where'));
	    bt0050b := [=];
	    for (j in "Source Planet Current J2000...") {
	      if (j == 'Planet') {
		bt0050b[j] := widgetset.button(bt0050a[i], j, value=j, type='menu');
		bt0050ba := [=];
		for (i1 in private.dirval.planet) {
		  bt0050ba[i1] := widgetset.button(bt0050b[j], i1, value=i1);
		};
	      } else if (j == 'Source') {
		bt0050b.listsel := widgetset.selectablelist(parent=bt0050a[i], lead=fr00x5a, 
			                        label='Source', updatelabel=T,
                                                list=private.dirval.source, 
                                                hlp='Select source');
	      } else {
		bt0050b[j] := widgetset.button(bt0050a[i], j, value=j);
	      };
	    };
	  } else if (i == 'Time') {
	    widgetset.popuphelp(bt0050a[i], spaste('Show current time in ',
					 'variety of formats.\n',
					 'Stop display with MB1.'));
	    bt0050 := [=];
	    for (j in "UTC Local LST Solar") {
	      bt0050[j] := widgetset.button(bt0050a[i], j, value=j);
	    };
	  } else if (i == 'Clock') {
	    widgetset.popuphelp(bt0050a[i], spaste('Start a clock in specified ',
					 'time type. Dismiss with ',
					 'MB1.'));
	    bt0051 := [=];
	    for (j in "UTC Local LST Solar") {
	      bt0051[j] := widgetset.button(bt0050a[i], j, value=j);
	    };
	  } else if (i == 'Frequency to velocity') {
	    widgetset.popuphelp(bt0050a[i], spaste('Convert a frequency to a ',
					 'velocity.\n',
					 'Note that a rest frequency ',
					 'is needed (see Frame).'));
	    bt0050xa := [=];
	    for (j in "Line Frequency...") {
	      if (j == 'Line') {
		bt0050xa[j] := widgetset.selectablelist(parent=bt0050a[i],
						   lead=bt0050a[i],
						   label='Line', updatelabel=F,
						   list=private.frqval.line);
	      } else {
		bt0050xa[j] := widgetset.button(bt0050a[i], j, value=j);
	      };
	    };
	  } else if (i == 'Velocity to frequency') {
	    widgetset.popuphelp(bt0050a[i], spaste('Convert a velocity to a ',
					 'frequency.\n',
					 'Note that a rest frequency ',
					 'is needed (see Frame).'));
	    bt0050xb := [=];
	    for (j in "Velocity...") {
	      bt0050xb[j] := widgetset.button(bt0050a[i], j, value=j);
	    };
	  };
	};
	bt0051a := F;
	whenever bt0050['LST']->press do {
	  if (!is_measure(private.getwhere())) {
	    dq.errorgui('Specify where you are with Frame->Where');
	  } else {
	    a := dq.time(public.measure(public.epoch('UTC', 'today'),
					    'LAST').m0, 6);
	    if (!is_agent(bt0051a)) {
	      bt0051a := widgetset.button(fr00, a);
	      bt0051a->bind('<Button-2>', 'mb2');
	      widgetset.popuphelp(bt0051a, spaste('LAST\n',
					'- Press MB1 to update\n',
					'- Press MB2 to dismiss\n'));
	      whenever bt0051a->mb2 do {
		popupremove(bt0051a);
	      }
	      whenever bt0051a->press do {
		a := dq.time(public.measure(public.epoch('UTC', 'today'),
						'LAST').m0, 6);
		bt0051a->text(a);
	      }
	    } else {
	      bt0051a->text(a);
	    };
	  };
	}
	bt0053a := F;
	whenever bt0050['UTC']->press do {
	  a := dq.time(public.measure(public.epoch('UTC', 'today'),
					  'UTC').m0, 6);
	  if (!is_agent(bt0053a)) {
	    bt0053a := widgetset.button(fr00, a);
	    bt0053a->bind('<Button-2>', 'mb2');
	    widgetset.popuphelp(bt0053a, spaste('UTC\n',
				      '- Press MB1 to update\n',
				      '- Press MB2 to dismiss\n'));
	    whenever bt0053a->mb2 do {
	      popupremove(bt0053a);
	    }
	    whenever bt0053a->press do {
	      a := dq.time(public.measure(public.epoch('UTC', 'today'),
					      'UTC').m0, 6);
	      bt0053a->text(a);
	    }
	  } else {
	    bt0053a->text(a);
	  };
	}
	bt0054a := F;
	whenever bt0050['Local']->press do {
	  a := dq.time(public.measure(public.epoch('UTC', 'today'),
					  'UTC').m0, 6, form="local");
	  if (!is_agent(bt0054a)) {
	    bt0054a := widgetset.button(fr00, a);
	    bt0054a->bind('<Button-2>', 'mb2');
	    widgetset.popuphelp(bt0054a, spaste('Local time\n',
				      '- Press MB1 to update\n',
				      '- Press MB2 to dismiss\n'));
	    whenever bt0054a->mb2 do {
	      popupremove(bt0054a);
	    }
	    whenever bt0054a->press do {
	      a := dq.time(public.measure(public.epoch('UTC', 'today'),
					      'UTC').m0, 6, form="local");
	      bt0054a->text(a);
	    }
	  } else {
	    bt0054a->text(a);
	  };
	}
	bt0055a := F;
	whenever bt0050['Solar']->press do {
	  if (!is_measure(private.getwhere())) {
	    dq.errorgui('Specify where you are in Frame');
	  } else {
	    b := public.measure(public.epoch('UTC', 'today'), 'UTC');
	    b := dq.add(b.m0,
			dq.totime(private.framestack['position'].m0));
	    a := dq.time(b, 6);
	    if (!is_agent(bt0055a)) {
	      bt0055a := widgetset.button(fr00, a);
	      bt0055a->bind('<Button-2>', 'mb2');
	      widgetset.popuphelp(bt0055a, spaste('Solar time at specified where\n',
					'- Press MB1 to update\n',
					'- Press MB2 to dismiss\n'));
	      whenever bt0055a->mb2 do {
		popupremove(bt0055a);
	      }
	      whenever bt0055a->press do {
		b := public.measure(public.epoch('UTC', 'today'), 'UTC');
		b := dq.add(b.m0,
			    dq.totime(private.framestack['position'].m0));
		a := dq.time(b, 6);
		bt0055a->text(a);
	      }
	    } else {
	      bt0055a->text(a);
	    };
	  };
	}
	whenever bt0051['LST']->press do {
	  if (!is_measure(private.getwhere())) {
	    dq.errorgui('Specify where you are in Frame');
	  } else {
	      a := dq.time(public.measure(public.epoch('UTC', 'today'),
					      'LAST').m0, 6);
	      if (!is_defined("bt0052") || !is_agent(bt0052)) {
		fr0052 := widgetset.frame(title='LAST');
		bt0052 := widgetset.button(fr0052, a);
		widgetset.popuphelp(bt0052, 'LAST clock\nPress to dismiss');
		t := dq.convert(dq.totime(dq.getformat('auto')),
				    's');
		private.alstcl := client("timer", t.value);
		whenever private.alstcl->ready do {
		  a := dq.time(public.measure(public.epoch('UTC', 'today'),
						  'LAST').m0, 6);
		  bt0052->text(a);
		}
		whenever bt0052->press do {
		  private.alstcl := F;
		  popupremove(bt0052);
		  popupremove(fr0052);
		}
	      };
	  };
	}
	whenever bt0051['UTC']->press do {
	  a := dq.time(public.measure(public.epoch('UTC', 'today'),
					  'UTC').m0, 6);
	  if (!is_defined("bt0054") || !is_agent(bt0054)) {
	    fr0054 := widgetset.frame(title='UTC');
	    bt0054 := widgetset.button(fr0054, a);
	    widgetset.popuphelp(bt0054, 'UTC clock\nPress to dismiss');
	    t := dq.convert(dq.totime(dq.getformat('auto')), 's');
	    private.alutcl := client("timer", t.value);
	    whenever private.alutcl->ready do {
		a := dq.time(public.measure(public.epoch('UTC', 'today'),
						'UTC').m0, 6);
		bt0054->text(a);
	    }
	    whenever bt0054->press do {
	      private.alutcl := F;
	      popupremove(bt0054);
	      popupremove(fr0054);
	    }
	  };
	}
	whenever bt0051['Local']->press do {
	  a := dq.time(public.measure(public.epoch('UTC', 'today'),
					  'UTC').m0, 6, form="local");
	  if (!is_defined("bt0058") || !is_agent(bt0058)) {
	    fr0058 := widgetset.frame(title='Local time');
	    bt0058 := widgetset.button(fr0058, a);
	    widgetset.popuphelp(bt0058, 'Local time clock\nPress to dismiss');
	    t := dq.convert(dq.totime(dq.getformat('auto')), 's');
	    private.alutcl := client("timer", t.value);
	    whenever private.alutcl->ready do {
	      a := dq.time(public.measure(public.epoch('UTC', 'today'),
					      'UTC').m0, 6, form="local");
	      bt0058->text(a);
	    }
	    whenever bt0058->press do {
	      private.alutcl := F;
	      popupremove(bt0058);
	      popupremove(fr0058);
	    }
	  };
	}
	whenever bt0051['Solar']->press do {
	  if (!is_measure(private.getwhere())) {
	    dq.errorgui('Specify where you are in Frame');
	  } else {
	    b := public.measure(public.epoch('UTC', 'today'), 'UTC');
	    b := dq.add(b.m0,
			dq.totime(private.framestack['position'].m0));
	    a := dq.time(b, 6);
	    if (!is_defined("bt0059") || !is_agent(bt0059)) {
	      fr0059 := widgetset.frame(title='Solar time');
	      bt0059 := widgetset.button(fr0059, a);
	      widgetset.popuphelp(bt0059, 'Solar time clock\nPress to dismiss');
	      t := dq.convert(dq.totime(dq.getformat('auto')),
				  's');
	      private.alutcl := client("timer", t.value);
	      whenever private.alutcl->ready do {
		b := public.measure(public.epoch('UTC', 'today'), 'UTC');
		b := dq.add(b.m0,
			    dq.totime(private.framestack['position'].m0));
		a := dq.time(b, 6);
		bt0059->text(a);
	      }
	      whenever bt0059->press do {
		private.alutcl := F;
		popupremove(bt0059);
		popupremove(fr0059);
	      }
	    };
	  };
	}
#
# Rise/set display
#
	fr0055 := F;
	bt0055 := F;
	bt0056 := F;
	displayrs := function(c, ref fr00) {
	  wider fr0055;
	  wider bt0055;
	  wider bt0056;
	  wider private;

	  if (!is_measure(c)) c := split(c);
	  b := "fault fault";
	  if (!is_measure(c) &&
	      (length(c) != 2 || !dq.is_angle(c[1]) ||
	      !dq.is_angle(c[2]))) {
	    dq.errorgui('Incorrect RA and/or DEC specified');
	  } else {
	    if (is_measure(c)) {
	      c := public.measure(c, 'j2000');
	    } else {
	      c := public.direction('J2000', c[1], c[2]);
	      public.doframe(c);
	    };
	    private.risecoord := c;
	    d := public.rise(private.risecoord, dq.getformat('elev'));
	    if (!is_fail(d)) {
	      private.getrs(d, b);
	      if (!is_agent(fr0055)) {
		fr0055 := widgetset.frame(fr00, relief='groove');
		fr0055a := widgetset.frame(fr0055, side='left');
		bt0057a := widgetset.button(fr0055a, dq.getformat('elev'), type='menu');
		widgetset.popuphelp(bt0057a, 'Select elevation limit');
		bt0057 := widgetset.button(fr0055a, dq.getformat('dtime'), type="menu");
		widgetset.popuphelp(bt0057, 'Select time type for display');
		bt0055 := widgetset.button(fr0055, b[1], foreground='blue');
		bt0055->bind('<Button-2>', 'mb2');
		widgetset.popuphelp(bt0055, spaste('Rise time\n',
					 '- Recalculate with MB1\n',
					 '- Dismiss with MB2'));
		bt0056 := widgetset.button(fr0055, b[2],foreground='red');
		bt0056->bind('<Button-2>', 'mb2');
		widgetset.popuphelp(bt0056, spaste('Set time\n',
					 '- Recalculate with MB1\n',
					 '- Dismiss with MB2'));
		mn0057 := [=];
		for (j in dq.getformat('lst').dtime) {
		  mn0057[j] := widgetset.button(bt0057, j, value=j);
		  whenever mn0057[j]->press do {
		    dq.setformat('dtime', $value);
		    bt0057->text(dq.getformat('dtime'));
		    private.getrs(d, b);
		    bt0055->text(b[1]);
		    bt0056->text(b[2]);
		  }
		};
		mn0057a := [=];
		for (j in dq.getformat('lst').elev) {
		  mn0057a[j] := widgetset.button(bt0057a, j, value=j);
		  whenever mn0057a[j]->press do {
		    dq.setformat('elev', $value);
		    bt0057a->text(dq.getformat('elev'));
		    d := public.rise(private.risecoord, 
				     dq.getformat('elev'));
		    if (!is_fail(d)) {
		      private.getrs(d, b);
		      bt0055->text(b[1]);
		      bt0056->text(b[2]);
		    };
		  }
		};
		whenever bt0055->mb2, bt0056->mb2 do {
		  popupremove(bt0057a);
		  popupremove(bt0057);
		  popupremove(bt0055);
		  popupremove(bt0056);
		  popupremove(fr0055);
		}
		whenever bt0055->press, bt0056->press do {
		    private.getrs(d, b);
		    bt0055->text(b[1]);
		    bt0056->text(b[2]);
		}
	      } else {
		bt0055->text(b[1]);
		bt0056->text(b[2]);
	      };
	    };
	  };
	}
#
# Velocity/frequency display
#
 	fr0055y := [vel=F, freq=F];
	bt0055y := [vel=F, freq=F];
	displayvf := function(c, ref fr00) {
	  wider fr0055y;
	  wider bt0055y;
	  wider private;

	  getvf := function(c, ref b) {
	    if (c == 'vel') {
	      if (dq.getformat('dop') == 'true') {
		d := public.radialvelocity('lsrk', 
					   private.applic.vel);
	      } else {
		d := public.toradialvelocity('lsrk',
					     public.doppler(dq.getformat('dop'),
							private.applic.vel));
	      };
	      if (is_fail(private.getfrq(d, b))) fail;
	    } else {
	      d := public.frequency('lsrk', private.applic.freq);
	      if (is_fail(private.getrv(d, b, dq.getformat('dop')))) fail;
	    };
	    return T;
	  }
	
	  bya := [''];
	  if (!is_fail(getvf(c, bya))) {
	    if (!is_agent(fr0055y[c])) {
	      fr0055y[c] := widgetset.frame(fr00, relief='groove');
	      fr0055ya[c] := widgetset.frame(fr0055y[c], side='left');
	      bt0057ya[c] := widgetset.button(fr0055ya[c], dq.getformat('dop'),
				    type='menu');
	      widgetset.popuphelp(bt0057ya[c], 'Select type of velocity');
	      mn0057ya[c] := [=];
	      for (j in dq.getformat('lst').dop) {
		mn0057ya[c][j] := widgetset.button(bt0057ya[c], j, value=j);
		whenever mn0057ya[c][j]->press do {
		  dq.setformat('dop', $value);
		  bt0057ya[c]->text(dq.getformat('dop'));
		  if (!is_fail(getvf(c, bya))) bt0055y[c]->text(bya[1]);
		}
	      };
	      if (c == 'vel') {
		bt0057y[c] := widgetset.button(fr0055ya[c], dq.getformat('freq'),
				     type="menu");
		widgetset.popuphelp(bt0057y[c],
			  'Select frequency type for display');
		mn0057y[c] := [=];
		for (j in dq.getformat('lst').freq) {
		  mn0057y[c][j] := widgetset.button(bt0057y[c], j, value=j);
		  whenever mn0057y[c][j]->press do {
		    dq.setformat('freq', $value);
		    if (!is_fail(getvf(c, bya))) {
		      bt0057y[c]->text(dq.getformat('freq'));
		      bt0055y[c]->text(bya[1]);
		    };
		  }
		};
	      } else {
		bt0057y[c] := widgetset.button(fr0055ya[c], dq.getformat('vel'),
				     type="menu");
		widgetset.popuphelp(bt0057y[c],
			  'Select velocity type for display');
		mn0057y[c] := [=];
		for (j in dq.getformat('lst').vel) {
		  mn0057y[c][j] := widgetset.button(bt0057y[c], j, value=j);
		  whenever mn0057y[c][j]->press do {
		    dq.setformat('vel', $value);
		    if (!is_fail(getvf(c, bya))) {
		      bt0057y[c]->text(dq.getformat('vel'));
		      bt0055y[c]->text(bya[1]);
		    };
		  }
		};
	      };
	      bt0055y[c] := widgetset.button(fr0055y[c], bya[1]);
	      bt0055y[c]->bind('<Button-2>', 'mb2');
	      if (c == 'vel') {
		widgetset.popuphelp(bt0055y[c], spaste('Frequency\n',
					     '- Recalculate with MB1\n',
					     '- Dismiss with MB2'));
	      } else {
		widgetset.popuphelp(bt0055y[c], spaste('Velocity\n',
					     '- Recalculate with MB1\n',
					     '- Dismiss with MB2'));
	      };
	      whenever bt0055y[c]->mb2 do {
		popupremove(bt0055y[c]);
		popupremove(bt0057y[c]);
		popupremove(bt0057ya[c]);
		popupremove(fr0055ya[c]);
		popupremove(fr0055y[c]);
	      }
	      whenever bt0055y[c]->press do {
		if (!is_fail(getvf(c, bya))) bt0055y[c]->text(bya[1]);
	      }
	    } else {
	      if (!is_fail(getvf(c, bya))) bt0055y[c]->text(bya[1]);
	    };
	  };
	}
           
	whenever bt0050b['J2000...']->press do {
	  e := '12:00 -20d00m';
	  if (has_field(private.framestack, 'direction') &&
	      is_measure(private.framestack['direction'])) {
	    e := paste(dq.time(private.framestack['direction'].m0),
		       dq.angle(private.framestack['direction'].m1));
	  };
	  c := dq.entergui('RA DEC (J2000)', e);
	  if (!is_fail(c)) { 
	    displayrs(c, fr00);
	  };
	}
	whenever bt0050b['Current']->press do {
	  e := F;
	  if (has_field(private.framestack, 'direction') &&
	      is_measure(private.framestack['direction'])) {
	    e := public.measure(private.framestack['direction'], 'j2000');
	  } else {
	    dq.errorgui('No current direction in Frame');
	  };
	  if (is_measure(e)) { 
	    displayrs(e, fr00);
	  };
	}
	for (i1 in private.dirval.planet) {
	  whenever bt0050ba[i1]->press do {
	    j := $value;
	    e := public.direction(j);
	    private.fillnow();
	    if (is_measure(e)) e := public.measure(e, 'j2000');
	    if (is_measure(e)) { 
	      displayrs(e, fr00);
	    } else {
	      dq.errorgui('Error in planetary calculation');
	    };
	  }
	};
	whenever bt0050b.listsel->select do {
	  e := public.source($value.item);
	  private.fillnow();
	  if (is_measure(e)) e := public.measure(e, 'j2000');
	  if (is_measure(e)) { 
	    displayrs(e, fr00);
	  } else {
	    dq.errorgui('Error in source position calculation');
	  };
	}
	whenever bt0050xa['Frequency...']->press do {
	  e := dq.tos(private.applic.freq);
	  c := dq.entergui('frequency', e);
	  if (!is_fail(c)) {
	    if (!dq.check(c) ||
		!is_measure(public.frequency('rest', c))) {
	      dq.errorgui('Illegal frequency given');
	    } else {
	      private.applic.freq := c;
	      displayvf('freq', fr00);
	    };
	  };
	}
	whenever bt0050xa['Line']->select do {
	  j := $value.item;
	  c := public.spectralline(j);
	  private.applic.freq := public.getvalue(c);
	  displayvf('freq', fr00);
	}
	whenever bt0050xb['Velocity...']->press do {
	  e := dq.tos(private.applic.vel);
	  c := dq.entergui('velocity', e);
	  if (!is_fail(c)) {
	    if (!dq.check(c) ||
		!is_measure(public.radialvelocity('lsrk', c))) {
	      dq.errorgui('Illegal velocity given');
	    } else {
	      private.applic.vel := c;
	      displayvf('vel', fr00);
	    };
	  };
	}
      };

      if (opt) {
	return [created = fr00, button = bt001];
      } else return [created = fr00];
    }
#
    const private.bargui2 := function(ref fr0, head, txt) {
      fr0.fr00 := private.fillhgui(fr0);
      fr0.bt01 := widgetset.helpmenu(fr0, head, spaste('Refman:', txt));
    }
#
# Info frame
#
    private.makeinfo := function(ref valrec, tp, wd1=10, tx1='Data:',
				 wd2=25,
				 expl='Special on above result') {
      bvx := ' ';
      if (!valrec.rt[tp].bt->state()) {
	valrec.rt[tp].frm0xx := F;
      } else {
	if (!is_agent(valrec.rt[tp].frm0xx)) {
	  widgetset.tk_hold();
	  valrec.rt[tp].frm0xx := widgetset.frame(valrec.en.fr011c, side='top',
					borderwidth=0);
	  valrec.rt[tp].frm0xx->unmap();
	  widgetset.tk_release();
	  valrec.rt[tp].frm0a := widgetset.frame(valrec.rt[tp].frm0xx, side='left',
				       borderwidth=0);
	  valrec.rt[tp].frm0b := widgetset.frame(valrec.rt[tp].frm0a, side='top',
				       borderwidth=0);
	  valrec.rt[tp].l1 := widgetset.listbox(valrec.rt[tp].frm0b, width=wd1, height=1,
				      relief='flat',
				      borderwidth=0,
				      exportselection=T);
	  valrec.rt[tp].l1->insert(tx1);
	  valrec.rt[tp].frm0c := widgetset.frame(valrec.rt[tp].frm0a, side='top');
	  valrec.rt[tp].bx1x := widgetset.listbox(valrec.rt[tp].frm0c, width=wd2, 
					height=1, relief='flat',
					borderwidth=0,
					exportselection=T);
	  widgetset.popuphelp(valrec.rt[tp].bx1x, expl);
	  valrec.rt[tp].frm0d := widgetset.frame(valrec.rt[tp].frm0a, side='top');
	  valrec.rt[tp].frm0dlstm := [=];
	  if (is_string(valrec.rt[tp].shbt)) {
	    valrec.rt[tp].frm0dlst := widgetset.button(valrec.rt[tp].frm0d, 
				     dq.getformat(valrec.rt[tp].shbt),
					     type='menu');
	    valrec.rt[tp].frm0dlst->bind('<Button-2>', 'mb2');
	    widgetset.popuphelp(valrec.rt[tp].frm0dlst, 
		      spaste('Select format type\n',
			     '- MB2 will dismiss display'));
	    whenever valrec.rt[tp].frm0dlst->mb2 do {
	      popupremove(valrec.rt[tp].bx1x);
	      popupremove(valrec.rt[tp].frm0dlst);
	      popupremove(valrec.rt[tp].frm0xx);
	      valrec.rt[tp].bt->state(F);
	    }
	    for (j4 in dq.getformat('lst')[valrec.rt[tp].shbt]) {
	      valrec.rt[tp].frm0dlstm[j4] := 
		button(valrec.rt[tp].frm0dlst, j4,
		       value=j4);
	      whenever valrec.rt[tp].frm0dlstm[j4]->press do {
		dq.setformat(valrec.rt[tp].shbt, $value);
		for (itp in valrec.do) {
		  if (valrec.rt[itp].bt->state()) {
		    if (is_string(valrec.rt[itp].shbt)) {
		      valrec.rt[itp].frm0dlst->
			text(dq.getformat(valrec.rt[itp].shbt));
		    };
		    bvx := valrec.rt[itp].rout(valrec.cr);
		    valrec.rt[itp].bx1x->delete('start', 'end');
		    valrec.rt[itp].bx1x->insert(bvx);
		  };
		};
	      }
	    };
	  };	
	};
	valrec.rt[tp].frm0xx->map();
      };
      if (is_agent(valrec.rt[tp].frm0xx)) {
	valrec.rt[tp].frm0dlst->text(dq.getformat(valrec.rt[tp].shbt));
	bvx := valrec.rt[tp].rout(valrec.cr);
	valrec.rt[tp].bx1x->delete('start', 'end');
	valrec.rt[tp].bx1x->insert(bvx);
      };
    }
#
# Make measures value and result frame
#
    private.valresgui := function(ref fr0, ref valrec, tpc='measure', 
				  tp='Measure', tpraze=F, tfrm=T, tprest=F,
				  nval=1,
				  itxt=['Specify input 1.'],
				  lbhgt=3, lbtxt='',
				  bt=F, btv='', bti='',
				  mn=F, mnv='', mni='',
				  mny=F, mnyv='', mnyi='',
				  btc=F, btci='', btcd='',
				  btxt=F, btxti='', btxtm='',
				  mndo=F, mndov='', mndoi='',
				  mndoc0=F, mndoc1=F) {
      fr01 := widgetset.frame(fr0, side='left');
      fr010aa := widgetset.frame(fr01, relief='sunken');
      fr010 := widgetset.frame(fr010aa, expand='none');
      lb0100 := widgetset.label(fr010, text='Input', foreground='darkgreen');
      widgetset.popuphelp(lb0100, spaste('The Input (left) part of the frame ',
			       'is used to specify a value and ',
			       'reference type (in the ',
			       'white entry fields). The bottom part ',
			       'shows the active input value (in ',
			       'different formats). The buttons operate ',
			       'on the input value.'),
		paste(tp, 'input'));
      fr0101 := [=];
      lb0101 := [=];
      for (i in 1:nval) {
	fr0101[i] := widgetset.frame(fr010, side='left');
	lb0101[i] := widgetset.label(fr0101[i], text=valrec.inp[i]);
	widgetset.popuphelp(lb0101[i], spaste(itxt[i],
				    '\nEntries are activated by a TAB, ',
				    'CR, or by one of the action ',
				    'buttons.'));
	valrec.en[i] := widgetset.entry(fr0101[i], background='white', relief='groove',
			      fill='x', width=50,
			      exportselection=T);
	valrec.en[i]->bind('<Tab>','tab');
	valrec.en[i]->bind('<Key>','key');
	widgetset.popuphelp(valrec.en[i], spaste(itxt[i],
				       '\nEntries are activated by a TAB, ',
				       'CR, or by one of the action ',
				       'buttons.'));
      };
      for(i0 in 1:nval) {
	valrec.en[i0].myid := i0;
	whenever valrec.en[i0]->return, valrec.en[i0]->tab do {
	  i0 := $agent.myid;
	  if (valrec.getn(i0)) {
	    ok := T;
	    j := 1;
	    while (ok && j <= nval) {
	      if (j != i0) ok := valrec.entry.f[j];
	      j +:= 1;
	    };
	    if (ok) valrec.get();
	  };
	}
	whenever valrec.en[i0]->key do {
	  i0 := $agent.myid; 
	  if ($value.key != '	') {
	    valrec.entry.v[i0] := '';
	    valrec.entry.lb := F;
	  };
	}
      };
      fr0103a := widgetset.frame(fr010, side='left');
      bt0105 := widgetset.button(fr0103a, '^', value='^');
      widgetset.popuphelp(bt0105, 'Reload last typed value');
      if (is_string(bt)) {
	valrec.en.bt1 := widgetset.button(fr0103a, bt, value=btv);
	widgetset.popuphelp(valrec.en.bt1, bti);
      };
      if (is_string(mny)) {
        valrec.en.listsel := widgetset.selectablelist(parent=fr0103a, lead=fr0103a,
                                          label=mny, updatelabel=T,
                                          list=mnyv, hlp=mny);
      };	
      if (is_string(mn)) {
	valrec.en.mn1 := widgetset.selectablelist(parent=fr0103a, lead=fr0103a,
                                                  label=mn, updatelabel=F, list=mnv,
                                                  hlp=mni);
      };	
      fr0103f := private.fillhgui(fr0103a);
#
      hlp := spaste('Specify the current input value ',
                    'as an offset to any further ',
                    'input (or clear the offset).\n',
                    'Button is red if offset set. ',
                    'Note that the offset is used in ',
                    'conversion, setting the frame, ',
                    'or setting the offset.');
      bt0104b := widgetset.actionoptionmenu(fr0103a, labels="set clear show", hlp=hlp,
                                            updatelabel=F);
      bt0104b.setlabel('Offset');
#
      if (tfrm || (tprest && valrec.inref == 'REST')) {
	valrec.en.bt0104a := widgetset.button(fr0103a, 'Frame it', type='plain');
	widgetset.popuphelp(valrec.en.bt0104a, spaste('Use the current input ',
					    'value ',
					    'as the reference frame ',
					    tpc,
					    ' for (other) conversions.'));
      } else {
	valrec.en.bt0104a := widgetset.button(fr0103a, '        ', type='plain', 
				    relief='flat');
	widgetset.popuphelp(valrec.en.bt0104a, spaste('No use of ', tpc,
					    ' as frame entry'));
      };
      fr0103g := private.fillhgui(fr0103a);
      if (btxt) {
	valrec.en.bt0103x := widgetset.optionmenu(fr0103a, labels=btxtm,
						  hlp=spaste('Select the input ',btxti));
      };
#
      if (tpraze) {
         valrec.en.bt0103a := widgetset.button(parent=fr0103a, type='check', text='RAZE');
         hlp2 := spaste('When checked, will only use the ',
                        'integral day part (after a possible ',
                        'conversion): handy for offsets, e.g. ',
                        'when specifying an input sidereal ',
                        'time.');
         widgetset.popuphelp(valrec.en.bt0103a, hlp2);
      }
      valrec.en.bt0103 := widgetset.optionmenu(parent=fr0103a, 
                                               labels=valrec.ref,
                                               hlp='Reference code',
					       hlp2='Select the input reference type.',
					       nbreak=32);
      startItem := valrec.inref;
      if (tpraze) {
         startItem =~ s/\R_//g;               # remove leading "R_"  -- bit ugly to do this
      }
      valrec.en.bt0103.selectlabel(startItem);
#
#
      bt0104 := widgetset.button(fr0103a, 'Convert->', type='action');
      widgetset.popuphelp(bt0104, spaste('Convert the current input value ',
			       '(with its code and possible offset) ',
			       'to the result type code value.'));
      valrec.en.bx1 := widgetset.listbox(fr010, width=40, height=lbhgt,
			       exportselection=T);
      widgetset.popuphelp(valrec.en.bx1, spaste('Detailed description of input ',
				      '(taking offset into account):\n',
				      lbtxt));
      fr010d := private.fillvgui(fr010aa);
#
# Result frame
#
      fr011aa := widgetset.frame(fr01, relief='sunken');
      fr011 := widgetset.frame(fr011aa, expand='none');
      lb0110 := widgetset.label(fr011, text='Result', foreground='darkgreen');
      widgetset.popuphelp(lb0110, spaste('Result (right part) of measure frame. ',
			       'The result of a conversion will be ',
			       'displayed in the selected output type'),
		'Result frame');
      fr011a := widgetset.frame(fr011, side='left');
      en0111 := widgetset.listbox(fr011a, width=30, height=nval,
				  background='lightgrey',
				  exportselection=T);
      widgetset.popuphelp(en0111, 'Result of conversion');
      if (btc) {
	fr011b := widgetset.frame(fr011a);
	btclst := [=];
	btcmlst := [=]
	for (i4 in 1:nval) {
          values := [=];
	  formats := dq.getformat('lst')[btcd[i4]];
	  for (j4 in 1:length(formats)) {
             value := [=];
             value[1] := formats[j4]; value[2] := btcd[i4]; value[3] := paste(i4);
             values[j4] := value;
          }
#
# To do this with an extendoptionmenu is non-trivial.
#
	  btclst[i4] := widgetset.optionmenu(fr011b, pady=3, 
                                             labels=formats, 
                                             values=values,
                                             hlp=paste('Select output format for',btci[i4]));
          btclst[i4].selectlabel(dq.getformat(btcd[i4]));

          whenever btclst[i4]->select do {
             a := $value.value;
             dq.setformat(a[2], a[1]);
             btclst[as_integer(a[3])].setlabel(dq.getformat(a[2]));
             en0111->delete('start', 'end');
             en0111->insert(valrec.form(valrec.cr));
          }
	}
      }
      fr0113a := widgetset.frame(fr011, side='left');
#
      bt0112:= widgetset.optionmenu(parent=fr0113a,
                                    labels=valrec.ref,
                                    hlp='Reference code',
                                    hlp2='Select the output reference type.',
				    nbreak=32);
      if (tpraze) {
         bt0112a := widgetset.button(parent=fr0113a, type='check', text='RAZE');
         hlp2 := spaste('Select the output reference type.',
                        'Raze (if checked) will only use the ',
                        'integral day part (after a possible ',
                        'conversion): handy for offsets, e.g. ',
                        'when specifying a sidereal ',
                        'time.');
         widgetset.popuphelp(bt0112a, hlp2);
      }
      startItem := valrec.outref;
      if (tpraze) {
         startItem =~ s/\R_//g;               # remove leading "R_"  -- bit ugly to do this
      }
      bt0112.selectlabel(startItem);
#
      if (btxt) {
	bt0112x := widgetset.optionmenu(fr0113a, labels=btxtm,
                                        hlp=spaste('Select the output ',btxti));
        bt0112x.selectlabel(valrec.dop.inref);
      };
#
      fr0113f := private.fillhgui(fr0113a);
      hlp := spaste('Specify the current input value ',
                    '(note that the INPUT value is used!) ',
                    'as an offset to any further ',
                    'result display (or clear the offset)\n',
                    'Button is red if offset set.');
      bt0114b := widgetset.actionoptionmenu(fr0113a, labels="set clear show", hlp=hlp,
                                      updatelabel=F);
      bt0114b.setlabel('Offset');
#
#      bt0114c := widgetset.button(fr0113a, 'Export');
#      widgetset.popuphelp(bt0114c, spaste('Export the result value to a ',
#				'glish global variable (name will be ',
#				'asked for). The exported value will ',
#				'also be the value of the dq.import() ',
#				'glish method.'),
#		'Export button', combi=T);
      bt0114c := widgetset.button(fr0113a, 'Copy');
      widgetset.popuphelp(bt0114c, 'Copy the result value to the clipboard');
      if (is_string(mndo)) {
	valrec.rt.mn2 := widgetset.button(fr0113a, mndo, type='menu', relief='groove'); 
	widgetset.popuphelp(valrec.rt.mn2, mndoi);
	for (i1 in mndov) {
	  valrec.rt[i1].bt := widgetset.button(valrec.rt.mn2, i1, value=i1,
				     type='check');
	  valrec.rt[i1].bt->state(F);
	  if (is_string(mndoc0) && is_string(mndoc1) && i1 == mndoc0) {
	    whenever valrec.rt[i1].bt->press do {
	      valrec.rt[mndoc1].bt->state(valrec.rt[mndoc0].bt->state());
	      valrec.rt.doinfo(valrec);
	    }
	  } else if (is_string(mndoc0) && is_string(mndoc1) && i1 == mndoc1) {
	    whenever valrec.rt[i1].bt->press do {
	      valrec.rt[mndoc0].bt->state(valrec.rt[mndoc1].bt->state());
	      valrec.rt.doinfo(valrec);
	    }
	  } else {
	    whenever valrec.rt[i1].bt->press do valrec.rt.doinfo(valrec);
	  };
        };
      };	
#
      bx0113 := widgetset.listbox(fr011, width=30, height=lbhgt,
				  background='lightgrey',
				  exportselection=T);
      widgetset.popuphelp(bx0113, spaste('Detailed result of conversion ',
			       '(taking offset into account):\n',
			       lbtxt),
		'Result of conversion');
      valrec.en.fr011c := private.fillvgui(fr011aa);
#
# Actions
#
# Convert
#
      whenever bt0104->press do {		# Convert
	if (valrec.get()) {
	  cs := public[tpc](valrec.inref, valrec.entry.m,
			    off=valrec.inoff);
	  cr := public.measure(cs, valrec.outref, off=valrec.outoff);
	  if (is_measure(cr)) {
	    for (i4x in 1:nval) {
	      btclst[i4x]->text(dq.getformat(btcd[i4x]));
	    };
	    en0111->delete("start", "end");
	    en0111->insert(valrec.form(cr));
	    bx0113->delete('start', 'end');
	    bx0113->insert(valrec.show(cr));
	    valrec.cr := cr;
            if (mndo) valrec.rt.doinfo(valrec);
	    public.doshowauto(cs, valrec.outref, valrec.outoff);
	  } else {
	    a := dq.errorgui(spaste('Cannot convert: ',
					'probably missing frame information'));
	  };
	} else {
	  a := dq.errorgui(paste('Cannot convert: no', tp,
				     'specified'));
	};
      }
#
# Set frame
#
      if (tfrm || tprest) {
	whenever valrec.en.bt0104a->press do {
	  if (tfrm || (tprest && valrec.inref == 'REST')) {
	    if (valrec.get()) {
	      cr := public[tpc](valrec.inref, valrec.entry.m,
				off=valrec.inoff);
	      if (has_field(valrec.entry, 'lb') && is_string(valrec.entry.lb))
		cr.lb := valrec.entry.lb;
	      public.doframe(cr);
	    } else {
	      a := dq.errorgui(paste('Cannot set frame: no', tp,
					 'specified'));
	    };
	  };
	}
      };
#
# Input offset
#
      whenever bt0104b->select do {
        lb := $agent.getlabels()[$value.index];
        if (lb=='set') {
           if (valrec.get()) {
              valrec.inoff := public[tpc](valrec.inref, valrec.entry.m, 
                                          off=valrec.inoff);
              bt0104b.setforeground('red');
           } else {
              a := dq.errorgui(paste('Cannot set offset: no', tp,
				     'specified'));
           }
	} else if (lb=='clear') {
           valrec.inoff := F;
           bt0104b.setforeground('black');
        } else if (lb=='show') {
           valrec.en.bx1->delete('start', 'end');
           valrec.en.bx1->insert(valrec.show(valrec.inoff));
        }
      }
#
# Output offset
#
      whenever bt0114b->select do {
        lb := $agent.getlabels()[$value.index];
        if (lb=='set') {
           if (valrec.get()) {
              valrec.outoff := public[tpc](valrec.inref, valrec.entry.m, 
                                          off=valrec.inoff);
              bt0114b.setforeground('red');
           } else {
              a := dq.errorgui(paste('Cannot set offset: no', tp,
				     'specified'));
           }
	} else if (lb=='clear') {
           valrec.outoff := F;
           bt0114b.setforeground('black');
        } else if (lb=='show') {
           bx0113->delete('start', 'end');
           bx0113->insert(valrec.show(valrec.outoff));
        }
      }
#
# Input integer part
#
      if (tpraze) {
         whenever valrec.en.bt0103a->press do {
            if ($agent->state()) {
               label := valrec.en.bt0103.getlabel();
               valrec.inref := spaste('R_', label);
            } else {
               valrec.inref := label;
            }
         }
      }
#
# Output integer part
#
      if (tpraze) {
         whenever bt0112a->press do {
            if ($agent->state()) {
               label := bt0112.getlabel();
               valrec.outref := spaste('R_', label);
            } else {
               valrec.outref := label;
            }
         }
      }
#
# Copy to clipboard
#
      whenever bt0114c->press do {
         dcb.copy(valrec.cr);
      }
# 
# ^
#
      whenever bt0105->press do {
	if (has_field(valrec.entry, 'lv')) {
	  for (i in 1:nval) {
	    valrec.en[i]->delete("start","end");
	    if (len(valrec.entry.lv) >= i) {
	      valrec.en[i]->insert(valrec.entry.lv[i]);
	    };
	  };
	};
      }
#
# References
#
      if (btxt) {
	for (i31 in btxtm) {
          whenever valrec.en.bt0103x->select do {
	    valrec.dop.inref := $value.label;
	    for (j in 1:nval) valrec.entry.v[j] := '';
	    valrec.en.bx1->delete('start', 'end');
	  }
          whenever bt0112x->select do {
	    valrec.dop.outref := $value.label;
	    en0111->delete('start', 'end');
	    bx0113->delete('start', 'end');
	  }
	}
      }
      whenever valrec.en.bt0103->select do {
         valrec.inref := $value.label;
#
         if (tpraze) {
            if (valrec.en.bt0103a->state()) {
               valrec.inref := spaste('R_', valrec.inref);
            }
         }
#
         if (tprest) {
            if (valrec.inref == 'REST') {
               valrec.en.bt0104a->relief('raised');
               valrec.en.bt0104a->text('Frame it');
            } else {
               valrec.en.bt0104a->relief('flat');
               valrec.en.bt0104a->text('        ');
            }
         }
#
         if (has_field(valrec, 'isplanet')) valrec.isplanet := F;
         for (j in 1:nval) valrec.entry.v[j] := '';
      }
      whenever bt0112->select do {
         valrec.outref := $value.label;
#
         if (tpraze) {
            if (bt0112a->state()) {
               valrec.outref := spaste('R_', valrec.outref);
            }
         }
         en0111->delete("start", "end");
         bx0113->delete("start", "end");
      }
#
# Ready
#
    }
#
# Make epoch frame
#
    const private.epochgui := function(parent=F) {
      wider private;
      widgetset.tk_hold();
      fn0 := dq.createbf(title='Epoch handling', parent=parent);
      if (!dq.testbf(fn0)) {
	widgetset.tk_release();
	return F;
      };
      fr0 := dq.getbf(fn0);
      fr0->unmap();
      widgetset.tk_release();
      fr00 := private.bargui(fr0, fr0, opt=F, xt=T);
#
# Top bar menu
#
      private.epval.cr := F;
      private.bargui2(fr00.created, 'Epoch',
		      'measures.measures.epochgui');
#
# Workspace
#
# Epoch entry
#
      private.epval.nval := 1;
      private.epval.inp := ['Epoch:'];
      private.epval.entry := [=];
      private.epval.entry.m := [=];
      private.epval.entry.v := [=];
      private.epval.entry.lv := [=];
      private.epval.entry.f := [=];
      for (i in 1:private.epval.nval) {
	private.epval.entry.f[i] := F;
	private.epval.entry.v[i] := '';
	private.epval.entry.m[i] := dq.quantity('0');
	private.epval.entry.lv[i] := '';
      };
      private.epval.en := [=];
      private.epval.en.mn1lst := [=];
      private.epval.inoff := F;
      private.epval.outoff := F;

      private.epval.show := function(ref cr) {
	if (is_measure(cr)) {
	  if (cr.refer == 'LAST' || cr.refer == 'LMST' ||
	      cr.refer == 'GMST1' || cr.refer == 'GAST') {
	    a := ' ';
	  } else {
	    a := dq.time(cr.m0, form="time day ymd");
	  };
	  return [a,
		 dq.time(cr.m0, form="time mjd"),
		 dq.tos(cr.m0)];
	};
	return ' ';
      }

      private.epval.form := function(ref cr) {
	if (is_measure(cr)) {
	  return [dq.time(cr.m0)];
	};
	return ' ';
      }

      private.epval.getn := function(n) {
	wider private;
	ok := T;
        if (!has_field(private.epval.entry, 'm') ||
	    len(private.epval.entry.m) < 1 ||
	    !has_field(private.epval.entry, 'v') ||
	    len(private.epval.entry.v) < 1 ||
	    private.epval.entry.v[n] == '' ||
	    private.epval.entry.v[n] == 'today' ||
	    private.epval.entry.v[n] == 'now') {
          cm := private.epval.en[n]->get();
	  if (cm == 'now') cm := 'today';
          if (cm == '' || !dq.check(cm)) {
	    ok := F;
	  } else {
	    private.epval.entry.v[n] := cm;
            if (dq.is_angle(cm)) {
              private.epval.entry.m[n] := dq.totime(cm);
	    } else {
	      ok := F;
	    };
	  };
	};
	if (!ok) {
	  private.epval.entry.v[n] := '';
	  dq.errorgui(paste('Illegal units for', private.epval.inp[n],
				'entry'));
	};
	private.epval.entry.f[n] := ok;
	return ok;
      }
      
      private.epval.get := function() {
	wider private;
	ok := T;
	if (!private.epval.getn(1)) {
	  ok := F;
	} else {
	  cr := public.epoch(private.epval.inref,
			     private.epval.entry.m[1],
			     off=private.epval.inoff);
	  if (!is_measure(cr)) {
	    ok := F;
	  } else {
	    cr := public.measure(cr, private.epval.inref);
	    if (!is_measure(cr)) {
	      ok := F;
	    } else {
	      private.epval.en.bx1->delete('start', 'end');
	      private.epval.en.bx1->insert(private.epval.show(cr));
	      private.epval.entry.lv[1] := private.epval.entry.v[1];
	    };
	  };
	  if (!ok) {
	    dq.errorgui('Cannot make a proper (offset-) epoch from input');
	    private.epval.entry.v[1] := '';
	  };
        };
	return ok;
      }

      private.valresgui(fr0, private.epval, 'epoch',
			'Epoch', tpraze=T,
			nval=private.epval.nval,
			itxt=[spaste('Specify an epoch. The aips++ preferred ',
                                     'way is yyyy/mm/dd/hh:mm:ss.t, but ',
                                     'other formats (dd-mon-yy; 12h25m; ',
                                     'today (for now); mjd/hh:mm:ss) are ',
				     'acceptable.')],
			lbhgt=3,
			lbtxt=spaste('- civil date (if not sidereal time)\n',
				     '- MJD (or MGSD) + time\n',
				     '- MJD (or MGSD)'),
			bt='Now', btv='now',
			bti=spaste('Use current time as input value.',
				   'In addition it will be placed in ',
				   'the reference frame.'));
#
# Now button
#
      whenever private.epval.en.bt1->press do {
	private.epval.inref := 'UTC';
	private.epval.en.bt0103.setlabel(private.epval.inref);
	private.epval.en[1]->delete("start","end");
	private.epval.en[1]->insert('today');
	private.epval.entry.v[1] := ''; 
	if (private.epval.get()) {
	  cr := public.measure(public.epoch(private.epval.inref,
					    private.epval.entry.m[1]),
	                       private.epval.inref);
	  public.doframe(cr);
	};
      }
#
# Ready
#
      fr0->map();
      return T;
    }
#
# Make position frame
#
    const private.positiongui := function(parent=F) {
      wider private;
      widgetset.tk_hold();
      fn0 := dq.createbf(title='Position handling', parent=parent);
      if (!dq.testbf(fn0)) {
	widgetset.tk_release();
	return F;
      };
      fr0 := dq.getbf(fn0);
      fr0->unmap();
      widgetset.tk_release();
      fr00 := private.bargui(fr0, fr0, opt=F, xt=T);
#
# Top bar menu
#
      private.bargui2(fr00.created, 'Position',
		      'measures.measures.positiongui');
#
# Workspace
#
# Position entry
#
      private.posval.cr := F;
      private.posval.nval := 3;
      private.posval.inp := ['Longitude or X:',
		    'Latitude  or Y:',
		    'Height    or Z:'];
      private.posval.entry := [=];
      private.posval.entry.m := [=];
      private.posval.entry.v := [=];
      private.posval.entry.lv := [=];
      private.posval.entry.f := [=];
      for (i in 1:private.posval.nval) {
	private.posval.entry.f[i] := F;
	private.posval.entry.v[i] := '';
	private.posval.entry.m[i] := dq.quantity('0');
	private.posval.entry.lv[i] := '';
      };
      private.posval.en := [=];
      private.posval.en.mn1lst := [=];
      private.posval.inoff := F;
      private.posval.outoff := F;
      private.fillobslist();
#
# Show full position
#
      private.posval.show := function (ref cr) {
	if (is_measure(cr)) {
	  ev := public.addxvalue(cr);
	  return [dq.angle(cr.m0),
	          dq.angle(cr.m1),
		  dq.tos(cr.m2),
		  dq.tos(ev[1]),
		  dq.tos(ev[2]),
		  dq.tos(ev[3])];
	};
	return ' ';
      }

      private.posval.form := function(ref cr) {
	if (is_measure(cr)) {
	  return [dq.form.long(cr.m0),
	          dq.form.lat(cr.m1),
		  dq.form.len(cr.m2)];
	};
	return ' ';
      }
      
      private.posval.getn := function(n=1) {
	wider private;
	ok := T;
        if (!has_field(private.posval.entry, 'm') ||
	    len(private.posval.entry.m) < n ||
	    !has_field(private.posval.entry, 'v') ||
	    len(private.posval.entry.v) < n ||
	    private.posval.entry.v[n] == '') {
          cm := private.posval.en[n]->get();
          if (cm == '' || !dq.check(cm)) {
	    ok := F;
	  } else {
	    private.posval.entry.v[n] := cm;
            if (n < 3 && dq.is_angle(cm)) {
              private.posval.entry.m[n] := dq.toangle(cm);
	    } else if (dq.compare(cm, '1m')) {
	      private.posval.entry.m[n] := dq.quantity(cm);
            } else {
	      ok := F;
            };
	  };
	};
	if (!ok) {
	  private.posval.entry.v[n] := '';
	  dq.errorgui(paste('Illegal units for', private.posval.inp[n],
				'entry'));
	};
	private.posval.entry.f[n] := ok;
	return ok;
      }
      
      private.posval.get := function() {
	wider private;
	ok := T;
	if (!private.posval.getn(1) || !private.posval.getn(2) ||
	    !private.posval.getn(3) ||
	    (dq.is_angle(private.posval.entry.m[1]) && 
	     !dq.is_angle(private.posval.entry.m[2])) ||
	    (dq.is_angle(private.posval.entry.m[2]) &&
	     !dq.is_angle(private.posval.entry.m[1]))) {
	  ok := F;
	} else {
	  cr := public.position(private.posval.inref,
				private.posval.entry.m,
				off=private.posval.inoff);
	  if (!is_measure(cr)) {
	    ok := F;
	  } else {
	    cr := public.measure(cr, private.posval.inref);
	    if (!is_measure(cr)) {
	      ok := F;
	    } else {
	      private.posval.en.bx1->delete('start', 'end');
	      private.posval.en.bx1->insert(private.posval.show(cr));
	      private.posval.entry.lv := private.posval.entry.v;
	    };
	  };
	  if (!ok) {
	    dq.errorgui(spaste('Cannot make a proper (offset-) ',
				   'position from input'));
	  };
	};
	return ok;
      }

      private.valresgui(fr0, private.posval, 'position',
			'Position',
			nval=private.posval.nval,
			itxt=[spaste('Specify a longitude. ',
				     'The aips++ preferred ',
				     'way is hh:mm:ss.t or dd.mm.ss.t, but ',
				     'other formats (.h.m., .d.m. .deg) ',
				     'are acceptable.\n',
				     'Another option is specifying the X of ',
				     'rectangular coordinates (with length ',
				     'units). In that case the other entries ',
				     'should be Y and Z. '),
			     spaste('Specify a latitude. ',
				    'The aips++ preferred ',
				    'way is dd.mm.ss.t or hh:mm:ss.t, but ',
				    'other formats (.h.m., .d.m. .deg) ',
				    'are acceptable.\n',
				    'Another option is specifying the Y of ',
				    'rectangular coordinates (with length ',
				    'units). In that case the other entries ',
				    'should be X and Z. '),
			     spaste('Specify a height above sea level. or ',
				    'above centre of Earth (with length ',
				    'units.\n',
				    'Another option is specifying the Z of ',
				    'rectangular coordinates (with length ',
				    'units). In that case the other entries ',
				    'should be X and Y. ')],
			lbhgt=6,
			lbtxt=spaste('- longitude (in dms)\n',
				     '- latitude (in dms)\n',
				     '- height\n',
				     '- rectangular coordinates'),
			mn='OBS', mnv=private.posval.obs,
			mni='Select position for an observatory',
			btc=T,
			btci=['longitude', 'latitude', 'height'],
			btcd=['long', 'lat', 'len']);
#
# Observatories
#
    whenever private.posval.en.mn1->select do {
       j := $value.item;
#
       cr := public.observatory(j);
       private.posval.inref := cr.refer;
       private.posval.en.bt0103.setlabel(private.posval.inref);
       for (k in 1:private.posval.nval) {
         private.posval.en[k]->delete("start","end");
         private.posval.entry.v[k] := ''; 
       };
       private.posval.en[1]->insert(dq.tos(cr.m0));
       private.posval.en[2]->insert(dq.tos(cr.m1));
       private.posval.en[3]->insert(dq.tos(cr.m2));
       if (private.posval.get()) {
         cr := public.measure(cr, private.posval.inref,
                              off=private.posval.inoff);
         private.posval.entry.lb := j;
         cr.lb := j;
         public.doframe(cr);
       };
     }
#
# Ready
#
      fr0->map();
      return T;
    }
#
# Make direction frame
#
    const private.directiongui := function(parent=F) {
      wider private;
      widgetset.tk_hold();
      fn0 := dq.createbf(title='Direction handling', parent=parent);
      if (!dq.testbf(fn0)) {
	widgetset.tk_release();
	return F;
      };
      fr0 := dq.getbf(fn0);
      fr0->unmap();
      widgetset.tk_release();
      fr00 := private.bargui(fr0, fr0, opt=F, xt=T);
#
# Top bar menu
#
      private.bargui2(fr00.created, 'Direction',
		      'measures.measures.directiongui');
#
# Workspace
#
# Direction entry
#
      private.dirval.cr := F;
      private.dirval.nval := 2;
      private.dirval.inp := ['Longitude:',
		     'Latitude: '];
      private.dirval.entry := [=];
      private.dirval.entry.m := [=];
      private.dirval.entry.v := [=];
      private.dirval.entry.lv := [=];
      private.dirval.entry.f := [=];
      for (i in 1:private.dirval.nval) {
	private.dirval.entry.f[i] := F;
	private.dirval.entry.v[i] := '';
	private.dirval.entry.m[i] := dq.quantity('0');
	private.dirval.entry.lv[i] := '';
      };
      private.dirval.en := [=];
      private.dirval.en.mn1lst := [=];
      private.dirval.inoff := F;
      private.dirval.outoff := F;
      private.dirval.isplanet := F;
      private.fillsourcelist();
#
# Show full direction
#
      private.dirval.show := function (ref cr) {
	if (is_measure(cr)) {
	  if (has_field(cr, 'isplanet') && cr.isplanet) {
	    return ' ';
	  } else {
	    ev := public.addxvalue(cr);
	    return [dq.angle(cr.m0),
	            dq.angle(cr.m1),
		    dq.tos(ev[1]),
		    dq.tos(ev[2]),
		    dq.tos(ev[3])];
	  };
	};
	return ' ';
      }

      private.dirval.form := function(ref cr) {
	if (is_measure(cr)) {
	  return [dq.form.long(cr.m0),
	          dq.form.lat(cr.m1)];
	};
	return ' ';
      }
     
      private.dirval.getn := function(n=1) {
	wider private;
	ok := T;
        if (private.dirval.isplanet ||
	    !has_field(private.dirval.entry, 'm') ||
	    len(private.dirval.entry.m) < n ||
	    !has_field(private.dirval.entry, 'v') ||
	    len(private.dirval.entry.v) < n ||
	    private.dirval.entry.v[n] == '') {
          if (private.dirval.isplanet) {
	    cm := '0deg';
	  } else {
	    cm := private.dirval.en[n]->get();
	  };
          if (cm == '') {
	    ok := F;
	  } else {
	    private.dirval.entry.v[n] := cm;
            if (dq.is_angle(cm)) {
              private.dirval.entry.m[n] := dq.toangle(cm);
            } else {
	      ok := F;
            };
	  };
	};
	if (!ok) {
	  private.dirval.entry.v[n] := '';
	  dq.errorgui(paste('Illegal units for', private.dirval.inp,
				'entry'));
	};
	private.dirval.entry.f[n] := ok;
	return ok;
      }
      
      private.dirval.get := function() {
	wider private;
	ok := T;
	if (!private.dirval.getn(1) || !private.dirval.getn(2)) {
	  ok := F;
	} else {
	  cr := public.direction(private.dirval.inref,
				 private.dirval.entry.m,
				 off=private.dirval.inoff);
	  if (!is_measure(cr)) {
	    ok := F;
	  } else {
	    cr := public.measure(cr, private.dirval.inref);
	    if (!is_measure(cr)) {
	      ok := F;
	    } else {
	      if (private.dirval.isplanet) cr.isplanet := T;
	      private.dirval.en.bx1->delete('start', 'end');
	      private.dirval.en.bx1->insert(private.dirval.show(cr));
	      private.dirval.entry.lv := private.dirval.entry.v;
	    };
	  };
	  if (!ok) {
	    dq.errorgui(spaste('Cannot make a proper (offset-) ',
				   'direction from input'));
	  };
	};
	return ok;
      }
#
# DO
#
      private.dirval.do := ["Rise Set Co-latitude User..."];
      private.dirval.rt := [=];
      for (i in private.dirval.do) {
	private.dirval.rt[i] := [=];
	private.dirval.rt[i].frm0xx := F;
      };
      
      private.dirval.rt.doinfo := function(ref valrec) {
	for (i in valrec.do) {
	  if (i == valrec.do[1]) {
	    private.makeinfo(valrec, i, wd1=12, tx1='Rise:',
			     wd2=25, expl='Rise time');
	  } else if (i == valrec.do[2]) {
	    private.makeinfo(valrec, i, wd1=12, tx1='Set:',
			     wd2=25, expl='Setting time');
	  } else if (i == valrec.do[3]) {
	    private.makeinfo(valrec, i, wd1=12, tx1='Co-latitude:',
			     wd2=25, expl='Co-latitude (zenith-angle)');
	  } else if (i == valrec.do[4]) {
	    if (valrec.rt[i].bt->state() && 
		!is_agent(valrec.rt[i].frm0xx)) {
	      private.rtname(valrec.rt[i]);
	    };
	    private.makeinfo(valrec, i, wd1=12, tx1='User data:',
			     wd2=25, expl='User calculated data');
	  };
	};
      }
      
      private.dirval.rt[private.dirval.do[1]].shbt := 'dtime';
      private.dirval.rt[private.dirval.do[1]].rout := function(ref cr) {
	bvx := [' ', ' '];
	if (is_measure(cr)) {
	  dvx := public.rise(cr, dq.getformat('elev'));
	  if (!is_fail(dvx)) private.getrs(dvx, bvx);
	};
	return bvx[1];
      }
      
      private.dirval.rt[private.dirval.do[2]].shbt := 'elev';
      private.dirval.rt[private.dirval.do[2]].rout := function(ref cr) {
	bvx := [' ', ' '];
	if (is_measure(cr)) {
	  dvx := public.rise(cr, dq.getformat('elev'));
	  if (!is_fail(dvx)) private.getrs(dvx, bvx);
	};
	return bvx[2];
      }
      
      private.dirval.rt[private.dirval.do[3]].shbt := 'lat';
      private.dirval.rt[private.dirval.do[3]].rout := function(ref cr) {
	bvx := [' '];
	if (is_measure(cr)) {
          dvx := dq.sub('90deg', dq.toangle(cr.m1));
          bvx := dq.form.lat(dvx);
	};
	return bvx;
      }

      private.dirval.rt[private.dirval.do[4]].shbt := 'unit';
      private.dirval.rt[private.dirval.do[4]].rtname := '__dodir';
      private.dirval.rt[private.dirval.do[4]].rout := function(ref cr) {
	bvx := ' ';
	if (is_measure(cr)) {
	  global __tmpval;
	  __tmpval := cr;
	  if (is_defined(private.dirval.rt[private.dirval.do[4]].rtname)) {
	    dvx := eval(spaste(private.dirval.rt[private.dirval.do[4]].rtname,
			       '(__tmpval)'));
	    if (is_quantity(dvx)) {
	      bvx := dq.form[private.dirval.rt[private.dirval.do[4]].shbt](dvx);
	    };
	  } else {
	    bvx := paste('no', private.dirval.rt[private.dirval.do[4]].rtname);
	  };
	};
        return bvx;
      }

      private.valresgui(fr0, private.dirval, 'direction',
			'Direction',
			nval=private.dirval.nval,
			itxt=[spaste('Specify a longitude. ',
				     'The aips++ preferred ',
				     'way is hh:mm:ss.t or dd.mm.ss.t, but ',
				     'other formats (.h.m., .d.m. .deg) ',
				     'are acceptable.'),
			     spaste('Specify a latitude. The aips++ preferred ',
				    'way is dd.mm.ss.t or hh:mm:ss.t, but ',
				    'other formats (.h.m., .d.m. .deg) ',
				    'are acceptable.')],
			lbhgt=5,
			lbtxt=spaste('- longitude (in dms)\n',
				     '- latitude (in dms)\n',
				     '- direction cosines'),
			mn='Planet', mnv=private.dirval.planet,
			mni='Select a planet (and convert it with When given)',
			mny='Source', mnyv=private.dirval.source,
			mnyi='Select a source',
			btc=T,
			btci=['longitude', 'latitude'],
			btcd=['long', 'lat'],
			mndo='Info', mndov=private.dirval.do,
			mndoi='Add additional information about result',
			mndoc0=private.dirval.do[1],
			mndoc1=private.dirval.do[2]);
#
# Sources
#
      whenever private.dirval.en.listsel->select do {
	cr := public.source($value.item);
	private.dirval.inref := cr.refer;
	private.dirval.en.bt0103.setlabel(private.dirval.inref);
        private.dirval.isplanet := F;
	for (k in 1:private.dirval.nval) {
	  private.dirval.en[k]->delete("start","end");
	  private.dirval.entry.v[k] := ''; 
	};
	private.dirval.en[1]->insert(dq.time(cr.m0));
	private.dirval.en[2]->insert(dq.angle(cr.m1));
	if (private.dirval.get()) {
	  cr := public.measure(cr, private.dirval.inref);
	  private.dirval.entry.lb := $value.item;
	};
      }
#
# Planets
#
      whenever private.dirval.en.mn1->select do {
        j := $value.item;
#
        private.dirval.inref := j;
        private.dirval.en.bt0103.setlabel(private.dirval.inref);
        cr := public.direction(private.dirval.inref);
        private.dirval.isplanet := T;
        for (k in 1:private.dirval.nval) {
           private.dirval.en[k]->delete("start","end");
           private.dirval.entry.v[k] := ''; 
        };
        if (private.dirval.get()) {
           cr := public.measure(cr, private.dirval.inref);
           private.dirval.entry.lb := j;
           private.fillnow();
        };
      }
#
# Ready
#
      fr0->map();
      return T;
    }
#
# Make frequency frame
#
    const private.frequencygui := function(parent=F) {
      wider private;
      widgetset.tk_hold();
      fn0 := dq.createbf(title='Frequency handling', parent=parent);
      if (!dq.testbf(fn0)) {
	widgetset.tk_release();
	return F;
      };
      fr0 := dq.getbf(fn0);
      fr0->unmap();
      widgetset.tk_release();
      fr00 := private.bargui(fr0, fr0, opt=F, xt=T);
#
# Top bar menu
#
      private.frqval.cr := F;
      private.bargui2(fr00.created, 'Frequency',
		      'measures.measures.frequencygui');
#
# Workspace
#
# Frequency entry
#
      private.frqval.nval := 1;
      private.frqval.inp := ['Frequency:'];
      private.frqval.entry := [=];
      private.frqval.entry.m := [=];
      private.frqval.entry.v := [=];
      private.frqval.entry.lv := [=];
      private.frqval.entry.f := [=];
      for (i in 1:private.frqval.nval) {
	private.frqval.entry.f[i] := F;
	private.frqval.entry.v[i] := '';
	private.frqval.entry.m[i] := dq.quantity('0');
	private.frqval.entry.lv[i] := '';
      };
      private.frqval.en := [=];
      private.frqval.en.mn1lst := [=];
      private.frqval.inoff := F;
      private.frqval.outoff := F;
      private.filllinelist();

      private.frqval.show := function(ref cr) {
	if (is_measure(cr)) {
	  return [dq.tos(dq.convertfreq(cr.m0, 'MHz')),
	          dq.tos(dq.convertfreq(cr.m0, 'cm')),
		  dq.tos(dq.convertfreq(cr.m0, 'keV'))];
	};
	return ' ';
      }
      
      private.frqval.form := function(ref cr) {
	if (is_measure(cr)) {
	  return [dq.form.freq(cr.m0)];
	};
	return ' ';
      }

      private.frqval.getn := function(n) {
	wider private;
	ok := T;
        if (!has_field(private.frqval.entry, 'm') ||
	    len(private.frqval.entry.m) < 1 ||
	    !has_field(private.frqval.entry, 'v') ||
	    len(private.frqval.entry.v) < 1 ||
	    private.frqval.entry.v[n] == '') {
          cm := private.frqval.en[n]->get();
          if (cm == '' || !dq.check(cm)) {
	    ok := F;
	  } else {
	    private.frqval.entry.v[n] := cm;
	    if (dq.checkfreq(cm)) {
              private.frqval.entry.m[n] := dq.quantity(cm);
	    } else {
	      ok := F;
	    };
	  };
	};
	if (!ok) {
	  private.frqval.entry.v[n] := '';
	  dq.errorgui(paste('Illegal units for', private.frqval.inp,
				'entry'));
	};
	private.frqval.entry.f[n] := ok;
	return ok;
      }

      private.frqval.get := function() {
	wider private;
	ok := T;
	if (!private.frqval.getn(1)) {
	  ok := F;
	} else {
	  cr := public.frequency(private.frqval.inref,
				 private.frqval.entry.m[1],
				 off=private.frqval.inoff);
	  if (!is_measure(cr)) {
	    ok := F;
	  } else {
	    cr := public.measure(cr, private.frqval.inref);
	    if (!is_measure(cr)) {
	      ok := F;
	    } else {
	      private.frqval.en.bx1->delete('start', 'end');
	      private.frqval.en.bx1->insert(private.frqval.show(cr));
	      private.frqval.entry.lv[1] := private.frqval.entry.v[1];
	    };
	  };
	  if (!ok) {
	    dq.errorgui('Cannot make a proper (offset-) frequency from input');
	    private.frqval.entry.v[1] := '';
	  };
        };
	return ok;
      }
#
# DO
#
      private.frqval.do := ['Radial velocity'];
      private.frqval.rt := [=];
      for (i in private.frqval.do) {
	private.frqval.rt[i] := [=];
	private.frqval.rt[i].frm0xx := F;
      };
      
      private.frqval.rt.doinfo := function(ref valrec) {
	for (i in valrec.do) {
	  if (i == valrec.do[1]) {
	    private.makeinfo(valrec, i, wd1=10, tx1='Velocity:',
			     wd2=25,
			     expl='Radial velocity of result frequency');
	  };
	};
      }
      
      private.frqval.rt[private.frqval.do[1]].shbt := 'vel';
      private.frqval.rt[private.frqval.do[1]].rout := function(ref cr) {
	bvx := [' '];
	if (is_measure(cr)) {
	  private.getrv(cr, bvx);
	};
	return bvx;
      }

      private.valresgui(fr0, private.frqval, 'frequency',
			'Frequency', tfrm=F, tprest=T,
			nval=private.frqval.nval,
			itxt=[spaste('Specify a frequency. ',
				     'It can be specified ',
				     'as frequency, wavelength, wavenumber, ',
				     'time, angle/time',
				     'energy, impulse')],
			lbhgt=3,
			lbtxt=spaste('- frequency\n',
				     '- wavelength\n',
				     '- wave energy'),
			mn='Line', mnv=private.frqval.line,
			mni='Select a spectral line',
			btc=T,
			btci=['frequency'],
			btcd=['freq'],
			mndo='Info', mndov=private.frqval.do,
			mndoi='Add additional information about result');
#
# Line
#
	whenever private.frqval.en.mn1->select do {
	  j := $value.item;
#
	  cr := public.spectralline(j);
	  private.frqval.inref := cr.refer;
	  private.frqval.en.bt0103.setlabel(private.frqval.inref);
	  private.frqval.en.bt0104a->relief('raised');
	  private.frqval.en.bt0104a->text('Frame it');
	  for (k in 1:private.frqval.nval) {
	    private.frqval.en[k]->delete("start","end");
	    private.frqval.entry.v[k] := 'x'; 
	  };
	  private.frqval.en[1]->insert(dq.tos(cr.m0));
	  private.frqval.entry.v[1] := 'x';
	  private.frqval.entry.m[1] := cr.m0;
	  if (private.frqval.get()) {
	    cr := public.measure(cr, private.frqval.inref,
				 off=private.frqval.inoff);
	    private.frqval.entry.lb := j;
	    cr.lb := j;
	    public.doframe(cr);
	  };
	}
#      };
#
# Ready
#
      fr0->map();
      return T;
    }
#
# Make doppler frame
#
    const private.dopplergui := function(parent=F) {
      wider private;
      widgetset.tk_hold();
      fn0 := dq.createbf(title='Doppler handling', parent=parent);
      if (!dq.testbf(fn0)) {
	widgetset.tk_release();
	return F;
      };
      fr0 := dq.getbf(fn0);
      fr0->unmap();
      widgetset.tk_release();
      fr00 := private.bargui(fr0, fr0, opt=F, xt=T);
#
# Top bar menu
#
      private.dplval.cr := F;
      private.bargui2(fr00.created, 'Doppler',
		      'measures.measures.dopplergui');
#
# Workspace
#
# Doppler entry
#
      private.dplval.nval := 1;
      private.dplval.inp := ['Doppler:'];
      private.dplval.entry := [=];
      private.dplval.entry.m := [=];
      private.dplval.entry.v := [=];
      private.dplval.entry.lv := [=];
      private.dplval.entry.f := [=];
      for (i in 1:private.dplval.nval) {
	private.dplval.entry.f[i] := F;
	private.dplval.entry.v[i] := '';
	private.dplval.entry.m[i] := dq.quantity('0');
	private.dplval.entry.lv[i] := '';
      };
      private.dplval.en := [=];
      private.dplval.en.mn1lst := [=];
      private.dplval.inoff := F;
      private.dplval.outoff := F;

      private.dplval.show := function(ref cr) {
	if (is_measure(cr)) {
	  return (dq.tos(public.toradialvelocity('lsrk', cr).m0));
	};
	return ' ';
      }
      
      private.dplval.form := function(ref cr) {
	if (is_measure(cr)) {
	  return [dq.form.vel(cr.m0)];
	};
	return ' ';
      }

      private.dplval.getn := function(n) {
	wider private;
	ok := T;
        if (!has_field(private.dplval.entry, 'm') ||
	    len(private.dplval.entry.m) < 1 ||
	    !has_field(private.dplval.entry, 'v') ||
	    len(private.dplval.entry.v) < 1 ||
	    private.dplval.entry.v[n] == '') {
          cm := private.dplval.en[n]->get();
          if (cm == '' || !dq.check(cm)) {
	    ok := F;
	  } else {
	    private.dplval.entry.v[n] := cm;
	    if (dq.compare(cm,'1') || dq.compare(cm,'1m/s')) {
              private.dplval.entry.m[n] := dq.quantity(cm);
	    } else {
	      ok := F;
	    };
	  };
	};
	if (!ok) {
	  private.dplval.entry.v[n] := '';
	  dq.errorgui(paste('Illegal units for', private.dplval.inp,
				'entry'));
	};
	private.dplval.entry.f[n] := ok;
	return ok;
      }

      private.dplval.get := function() {
	wider private;
	ok := T;
	if (!private.dplval.getn(1)) {
	  ok := F;
	} else {
	  cr := public.doppler(private.dplval.inref,
			       private.dplval.entry.m[1],
			       off=private.dplval.inoff);
	  if (!is_measure(cr)) {
	    ok := F;
	  } else {
	    cr := public.measure(cr, private.dplval.inref);
	    if (!is_measure(cr)) {
	      ok := F;
	    } else {
	      private.dplval.en.bx1->delete('start', 'end');
	      private.dplval.en.bx1->insert(private.dplval.show(cr));
	      private.dplval.entry.lv[1] := private.dplval.entry.v[1];
	    };
	  };
	  if (!ok) {
	    dq.errorgui('Cannot make a proper (offset-) doppler from input');
	    private.dplval.entry.v[1] := '';
	  };
        };
	return ok;
      }
#
# DO
#
      private.dplval.do := ['frequency'];
      private.dplval.rt := [=];
      for (i in private.dplval.do) {
	private.dplval.rt[i] := [=];
	private.dplval.rt[i].frm0xx := F;
      };
      
      private.dplval.rt.doinfo := function(ref valrec) {
	for (i in valrec.do) {
	  if (i == valrec.do[1]) {
	    private.makeinfo(valrec, i, wd1=10, tx1='Frequency:',
			     wd2=25,
			     expl='Frequency of result velocity');
	  };
	};
      }
      
      private.dplval.rt[private.dplval.do[1]].shbt := 'freq';
      private.dplval.rt[private.dplval.do[1]].rout := function(ref cr) {
	bvx := [' '];
	if (is_measure(cr)) {
	  private.getfrq(public.toradialvelocity('lsrk', cr), bvx);
	};
	return bvx;
      }

      private.valresgui(fr0, private.dplval, 'doppler',
			'Doppler', tfrm=F,
			nval=private.dplval.nval,
			itxt=[spaste('Specify a Doppler velocity as a ',
				     'velocity or as a fraction (like z)',
				     'Note: TRUE cannot have fraction')],
			lbhgt=1,
			lbtxt=spaste('- true velocity\n'),
			btc=T,
			btci=['velocity'],
			btcd=['vel'],
                        mndo='Info', mndov=private.dplval.do,
			mndoi='Add additional information about result');
#
# Ready
#
      fr0->map();
      return T;
    }
#
# Make radialvelocity frame
#
    const private.radialvelocitygui := function(parent=F) {
      wider private;
      widgetset.tk_hold();
      fn0 := dq.createbf(title='Radialvelocity handling', parent=parent);
      if (!dq.testbf(fn0)) {
	widgetset.tk_release();
	return F;
      };
      fr0 := dq.getbf(fn0);
      fr0->unmap();
      widgetset.tk_release();
      fr00 := private.bargui(fr0, fr0, opt=F, xt=T);
#
# Top bar menu
#
      rvvval.dop := [=];
      private.rvval.dop.ref :=
	"TRUE RADIO OPTICAL Z RATIO RELATIVISTIC BETA GAMMA";
      private.rvval.dop.inref := 'TRUE';
      private.rvval.dop.outref := 'TRUE';
      private.rvval.cr := F;
      private.bargui2(fr00.created, 'Radial Velocity',
		      'measures.measures.radialvelocitygui');
#
# Workspace
#
# Radial velocity entry
#
      private.rvval.nval := 1;
      private.rvval.inp := ['Velocity:'];
      private.rvval.entry := [=];
      private.rvval.entry.m := [=];
      private.rvval.entry.v := [=];
      private.rvval.entry.lv := [=];
      private.rvval.entry.f := [=];
      for (i in 1:private.rvval.nval) {
	private.rvval.entry.f[i] := F;
	private.rvval.entry.v[i] := '';
	private.rvval.entry.m[i] := dq.quantity('0');
	private.rvval.entry.lv[i] := '';
      };
      private.rvval.en := [=];
      private.rvval.en.mn1lst := [=];
      private.rvval.inoff := F;
      private.rvval.outoff := F;

      private.rvval.show := function(ref cr) {
	if (is_measure(cr)) {
	  return (dq.tos(cr.m0));
	};
	return ' ';
      }
      
      private.rvval.form := function(ref cr) {
	if (is_measure(cr)) {
	  if (private.rvval.dop.outref == 'TRUE') {
	    return [dq.form.vel(cr.m0)];
	  } else {
	    return (dq.form.vel(public.todoppler(private.rvval.dop.outref,
						     cr).m0));
	  };
	};
	return ' ';
      }

      private.rvval.getn := function(n) {
        wider private;
	ok := T;
        if (!has_field(private.rvval.entry, 'm') ||
	    len(private.rvval.entry.m) < 1 ||
	    !has_field(private.rvval.entry, 'v') ||
	    len(private.rvval.entry.v) < 1 ||
	    private.rvval.entry.v[n] == '') {
          cm := private.rvval.en[n]->get();
          if (cm == '' || !dq.check(cm)) {
	    ok := F;
	  } else {
	    private.rvval.entry.v[n] := cm;
            if (private.rvval.dop.inref == 'TRUE' &&
		dq.compare(cm,'1m/s')) {
	      private.rvval.entry.m[n] := dq.quantity(cm);
	    } else if (!(private.rvval.dop.inref == 'TRUE') &&
		       (dq.compare(cm,'1m/s') ||
			dq.compare(cm,'1'))) {
	      cr := public.toradialvelocity(private.rvval.inref,
				      public.doppler(private.rvval.dop.inref,
							   dq.quantity(cm)));
	      private.rvval.entry.m[n] := cr.m0;
	    } else {
	      ok := F;
	    };
	  };
	};
	if (!ok) {
	  private.rvval.entry.v[n] := '';
	  dq.errorgui(paste('Illegal units for', private.rvval.inp,
				'entry'));
	};
	private.rvval.entry.f[n] := ok;
	return ok;
      }

      private.rvval.get := function() {
	wider private;
	ok := T;
	if (!private.rvval.getn(1)) {
	  ok := F;
	} else {
	  cr := public.radialvelocity(private.rvval.inref,
				      private.rvval.entry.m[1],
				      off=private.rvval.inoff);
	  if (!is_measure(cr)) {
	    ok := F;
	  } else {
	    cr := public.measure(cr, private.rvval.inref);
	    if (!is_measure(cr)) {
	      ok := F;
	    } else {
	      private.rvval.en.bx1->delete('start', 'end');
	      private.rvval.en.bx1->insert(private.rvval.show(cr));
	      private.rvval.entry.lv[1] := private.rvval.entry.v[1];
	    };
	  };
	  if (!ok) {
	    dq.errorgui('Cannot make a proper (offset-) velocity from input');
	    private.rvval.entry.v[1] := '';
	  };
        };
	return ok;
      }
#
# DO
#
      private.rvval.do := ['Frequency'];
      private.rvval.rt := [=];
      for (i in private.rvval.do) {
	private.rvval.rt[i] := [=];
	private.rvval.rt[i].frm0xx := F;
      };
      
      private.rvval.rt.doinfo := function(ref valrec) {
	for (i in valrec.do) {
	  if (i == valrec.do[1]) {
	    private.makeinfo(valrec, i, wd1=10, tx1='Frequency:',
			     wd2=25,
			     expl='Frequency of result velocity');
	  };
	};
      }
      
      private.rvval.rt[private.rvval.do[1]].shbt := 'freq';
      private.rvval.rt[private.rvval.do[1]].rout := function(ref cr) {
	bvx := [' '];
	if (is_measure(cr)) {
	  private.getfrq(cr, bvx);
	};
	return bvx;
      }

      private.valresgui(fr0, private.rvval, 'radialvelocity',
			'Radial velocity',
			nval=private.rvval.nval,
			itxt=[spaste('Specify a radial velocity as a ',
				     'velocity or as a fraction (like z)',
				     '(not for TRUE)')],
			lbhgt=1,
			lbtxt=spaste('- true velocity\n'),
			btc=T,
			btci=['velocity'],
			btcd=['vel'],
			btxt=T,
			btxti='Doppler mode type.',
			btxtm=private.rvval.dop.ref,
			mndo='Info', mndov=private.rvval.do,
			mndoi='Add additional information about result');
#
# Ready
#
      fr0->map();
      return T;
    }
#
# End server constructor
#
    return T;
  } # constructor
