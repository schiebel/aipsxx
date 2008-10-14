# quantagui.g: Access to quanta classes using a gui
# Copyright (C) 1998,1999,2000
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
# $Id: quantagui.g,v 19.2 2004/08/25 01:49:23 cvsmgr Exp $
#
# This file is not meant to be included independently. quanta.g will include
# it if and when necessary.
#
pragma include once;

include 'widgetserver.g';
include 'note.g';
include 'clipboard.g';
include 'serverexists.g';
include 'popuphelp.g';
include 'scrolllistbox.g';
#
# Closure object
#
const quantagui := function(ref private, ref public, widgetset=dws) {
    
  if (!serverexists('dcb', 'clipboard', dcb)) {
    return throw(spaste('The clipboard server "dcb" is either not ',
			'running or not valid'),
		 origin='quantagui.g');
  };
  if (!serverexists('dq', 'quanta', dq)) {
    return throw(spaste('The quanta server "dq" is either not running ',
			'or not valid'),
		 origin='quantagui.g');
  };

  global system;
  units := [=];
#
# Start GUI interface method
#
# gui() start GUI interface
#
  const private.gui := function(parent=F) {
    return private.unitgui(parent=parent);
  }
#
# Subsidiary gui methods
#
# List frame
#
  const private.listgui := function(title='', txt='') {
    wider private;
    if (dq.testbf()) {
      fn0 := dq.createbf(title=title);
      if (!dq.testbf(fn0)) return F;
      fr0 := dq.getbf(fn0);
      fr00 :=  widgetset.frame(fr0, side='left', borderwidth=0);
      tx000 :=  widgetset.scrolllistbox(fr00,
					hscrollbar=F, vscrollbar=T,
					seeoninsert=F,
					background='lightgrey',
					width=80, height=16);
      bt01 :=  widgetset.button(fr0, 'Dismiss', type='dismiss');
      whenever bt01->press do val fr0 := F;
      local a := split(txt ~ s/\t/     /g, '\n');
      tx000->insert(a);
    } else print txt;
    return T;
  }
#
# Error frame
#
  const private.errorgui := function(txt='') {
    wider private;
    if (dq.testbf()) {
      fr0 :=  widgetset.frame(title='Measures/Quanta error');
      if (!is_agent(fr0)) return F;
      lb00 :=  widgetset.label(fr0, relief='sunken', background='red',
			       text='ERROR');
      lb01 :=  widgetset.message(fr0, text=txt);
      bt02 :=  widgetset.button(fr0, 'OK');
      whenever bt02->press do fr0 := F;
    } else print txt;
    return T;
  }
#
# Value enter frame
#
  const private.entergui := function(txt='', deflt='') {
    wider private;
    cm := F;
    if (dq.testbf()) {
      fn0 := dq.createbf(title='Specify value');
      if (!dq.testbf(fn0)) return F;
      fr0 := dq.getbf(fn0);
      lb00 :=  widgetset.label(fr0, text=spaste('Specify value for ',txt));
      en01 :=  widgetset.entry(fr0, width=10, background='white');
      en01->insert(as_string(deflt));
      fr02 :=  widgetset.frame(fr0, side='left');
      bt020 :=  widgetset.button(fr02, 'OK');
      bt021 :=  widgetset.button(fr02, 'Cancel');
      await bt020->press, bt021->press, en01->return;
      if ($agent != bt021) cm := en01->get();
      val fr0 := F;
    } else {
      cm := readline(prompt=spaste('Specify value for ', txt,
				   '[', deflt, ']: '));
      if (len(cm) == 0 || strlen(cm) == 0) cm := deflt;
    };
    if (is_string(cm)) return cm;
    fail('dq.entergui');
  }
#
# Delete a frame
#
  const private.deletebf := function(n=0) {
    wider private;
    if (dq.testbf(n)) popupremove(dq.getbf(n));
  }
#
# Horizontal fill gui
#
  const private.fillhgui := function(fr0, sz=50) {
    return  widgetset.frame(fr0, width=sz, height=1);
  }
#
# Vertical fill frame
#
  const private.fillvgui := function(fr0, sz=50) {
    return  widgetset.frame(fr0, height=sz, width=1);
  }
#
# Top bar frame standard fill out
#
  const private.bargui := function(fr0, ref outfr, opt=T, name='Tool') {
    wider private;
    fr00 :=  widgetset.frame(fr0, side='left', relief='raised', expand='x');
    bt000 :=  widgetset.button(fr00, 'File', type='menu', relief='flat');
    a := spaste('Menu of window operations:\n',
		'- close the current window\n');
    widgetset.popuphelp(bt000, a, 'File button', combi=T);
    mn0000 := [=];
    mn0000.Close :=  widgetset.button(bt000, 'Done', value='Close');
    whenever mn0000.Close->press do val outfr := F;
    
    if (opt) {
      bt001 :=  widgetset.button(fr00, name, type='menu', relief='flat');
    } else fr009ab := private.fillhgui(fr00);
    
    if (opt) return [created = fr00, button = bt001];
    else return [created = fr00];
  }
#
  const private.bargui2 := function(ref fr0, head, txt) {
    wider private;
    fr0.fillhgui := private.fillhgui(fr0);
    fr0.bt01 := widgetset.helpmenu(fr0, head, spaste('Refman:', txt));
  }
#
# Make units frame
#
  const private.unitgui := function(parent=F) {
    wider private;
    widgetset.tk_hold();
    fn0 := dq.createbf(title='Unit handling', parent=parent);
    if (!dq.testbf(fn0)) {
      widgetset.tk_release();
      return F;
    };
    fr0 := dq.getbf(fn0);
    fr0->unmap();
    widgetset.tk_release();
    fr00 := private.bargui(fr0, fr0, name='Map');
#
# Stack values
#
    units.stackp := 0;
    units.stack := [=];
    units.fill := F;
    units.error := F;
    units.first := T;
    units.v0 := dq.unit('0.0');
    units.angle := 'deg';
#
# Top bar menu
#
    widgetset.popuphelp(fr00.button, spaste('Make a list of the selected ',
					    'known units.'));
    mn000 := [=];
    for (i in "All Prefix SI Customary User Constants") {
      mn000[i] :=  widgetset.button(fr00.button, i, value=i);
      whenever mn000[i]->press do {
	lval := $value;
	a := dq.map(lval);
	private.listgui(paste(lval,'names'), a);
      }
    };
    private.bargui2(fr00.created, 'Units', 'quanta.quanta.gui');
#
# Workspace
#
# Value frame
#
    fr01 :=  widgetset.frame(fr0, side='left');
    
    fr010 :=  widgetset.frame(fr01, relief='sunken');
    
    lb0100 :=  widgetset.label(fr010, text='Input (x)',
			       foreground='darkgreen');
    widgetset.popuphelp(lb0100,
			spaste('Input window. Specify the quantity ',
			       '(value+units or special time/angle ',
			       'types) in the entry window. The stack ',
			       'is shown below. The calculator is RPN.'));
    fr010a := widgetset.frame(fr010, side='left');
    en0101 :=  widgetset.entry(fr010a, background='white', relief='groove',
			       width=40, exportselection=T);
    en0101->bind('<Tab>', 'tab');
    en0101->bind('<Key>', 'key');
    widgetset.popuphelp(en0101, spaste('Enter a quantity (value+units or ',
				       'time/angle. Note that due to ',
				       'scanning limitations 1d is 1deg. To ',
				       'specify 1 day, it should be given as ',
				       '1.d, i.e. with a non-integer value.'));
    bt010a := widgetset.button(fr010a, '', bitmap='', relief='flat');
    widgetset.popuphelp(bt010a,
			spaste('Status:\n',
			       'Hand:        input mode\n',
			       'Red cross:   illegal entry\n',
			       'Green tick:  top of stack'));
    fr0102 :=  widgetset.frame(fr010, side='left');
    bt01020 :=  widgetset.button(fr0102, '^', value='^');
    widgetset.popuphelp(bt01020, 'Pop from stack');
    bt01021 :=  widgetset.button(fr0102, 'v', value='v');
    widgetset.popuphelp(bt01021, spaste('Push onto stack (as will Return ',
					'and Tab do)'));
    bt01023 :=  widgetset.button(fr0102, 'x<>y', value='x<>y');
    widgetset.popuphelp(bt01023, 'Exchange entry and top of stack');
    fr010230 := private.fillhgui(fr0102,sz=20);
    bt01023a := widgetset.button(fr0102, '', bitmap='hand.xbm');
    widgetset.popuphelp(bt01023a, 'Allow edit of input value');
    whenever bt01023a->press do {
      if (!units.fill) {
	units.first := F;
	units.fill := T;
	units.error := F;
	bt010a->bitmap('hand.xbm');
	bt010a->foreground('black');
      };
    }
    fr010230a := private.fillhgui(fr0102,sz=20);
    bt01024 :=  widgetset.button(fr0102, 'dup', value='dup');
    widgetset.popuphelp(bt01024, 'Duplicate top of stack value');
    bt01025 :=  widgetset.button(fr0102, 'copy', value='copy');
    widgetset.popuphelp(bt01025, 'Copy top of stack value to clipboard');
    bt01026 :=  widgetset.button(fr0102, 'paste', value='paste');
    widgetset.popuphelp(bt01025, 'Copy from clipboard to top of stack');
    fr0103 :=  widgetset.frame(fr010, relief='sunken');
    fr01030 :=  widgetset.frame(fr0103, side='left', expand='none');
    bx010300 :=  widgetset.scrolllistbox(fr01030,
					 hscrollbar=F, vscrollbar=T,
					 seeoninsert=F,
					 background='lightgrey',
					 width=30, height=10);
    widgetset.popuphelp(bx010300, 'RPN value stack');
    whenever en0101->key do {
      cm := $value.key;
      if (cm != '	') {
	if (!units.fill && !units.first) {
	  if (private.get_unit()) private.push_unit(units.v0);
	  en0101->delete('start','end');
	  if (strlen(cm) == 1 && strlen($value.sym) == 1) en0101->insert(cm);
	};
	units.first := F;
	units.fill := T;
	units.error := F;
	bt010a->bitmap('hand.xbm');
	bt010a->foreground('black');
      };
    }
    whenever en0101->return, en0101->tab, bt01021->press do {
      if (!units.error) {
	if (units.fill) private.get_unit();
	else private.push_unit(units.v0);
      };
    }
#
# Units frame
#
    fr011 := widgetset.frame(fr010, relief='sunken');
    lb0110 := widgetset.label(fr011, text='Conversion/definition units',
			      foreground='darkgreen');
    widgetset.popuphelp(lb0110, spaste('Specify the units to which to ',
				       'convert, ',
				       'or the unit name (like MYJY) you ',
				       'want to define'));
    en0111 := widgetset.entry(fr011, background='white', relief='groove',
			      width=20,
			      exportselection=T);
    en0111->bind('<Tab>', 'tab');
    widgetset.popuphelp(en0111, spaste('Specify the units to which to ',
				       'convert, ',
				       'or the unit name (like MYJY) you ',
				       'want to define'));
    whenever en0111->return, en0111->tab do {
      cm := $value;
      if (!dq.check(cm)) a := private.toq(cm);
    }
#
# Action frame
#
    fr012 := widgetset.frame(fr01, relief='sunken');
    lb0120 := widgetset.label(fr012, text='Operators', 
			      foreground='darkgreen');
    widgetset.popuphelp(lb0120, 'Operations on the RPN stack');
#
# Create action buttons
#
    boxl := "pop clear convert canon define";
    boxla := "+ - * / neg FITS";
    boxlb := "sin cos tan abs floor dms";
    boxlc := "asin acos atan atan2 ceil hms";
    boxld := "log log10 exp sqrt";
    fr0121 := widgetset.frame(fr012, side='left');
    fr01210 := widgetset.frame(fr0121);
    fr012100 := [=];
    bt0121000 := [=];
    mg0121001 := [=]
    for (i in boxl) {
      fr012100[i] := widgetset.frame(fr01210, side='left', expand='x');
      bt0121000[i] := widgetset.button(fr012100[i], '', type='plain',
				       value=i);
      mg0121001[i] := widgetset.message(fr012100[i], text=i, pady=5,
					justify='left', relief='flat');
      if (i == 'pop') {
	widgetset.popuphelp(bt0121000[i], 'Pop value from stack');
	widgetset.popuphelp(mg0121001[i], 'Pop value from stack');
      } else if (i == 'clear') {
	widgetset.popuphelp(bt0121000[i], 'Clear stack');
	widgetset.popuphelp(mg0121001[i], 'Clear stack');
      } else if (i == 'convert') {
	widgetset.popuphelp(bt0121000[i],
			    'Convert x to conversion units specified');
	widgetset.popuphelp(mg0121001[i],
			    'Convert x to conversion units specified');
      } else if (i == 'canon') {
	widgetset.popuphelp(bt0121000[i],
			    'Convert x to canonical units');
	widgetset.popuphelp(mg0121001[i],
			    'Convert x to canonical units');
      } else if (i == 'define') {
	widgetset.popuphelp(bt0121000[i],
			    'Define the conversion unit as x');
	widgetset.popuphelp(mg0121001[i],
			    'Define the conversion unit as x');
      };
    };
    fr012100a := widgetset.frame(fr01210, side='left', expand='x');
    bt0121000a := widgetset.button(fr012100a, '', type='menu',
				   padx=8, pady=5,
				   relief='raised');
    mg0121001a := widgetset.message(fr012100a, text='const', pady=5,
				    justify='left',
				    relief='flat');
    widgetset.popuphelp(bt0121000a, 'Get a pre-defined constant');
    widgetset.popuphelp(mg0121001a, 'Get a pre-defined constant');
    mn0121002a := [=];
    for (i in private.units_const) {
      t := i; t := spaste(t, private.units_const_txt[i]);
      mn0121002a[i] := widgetset.button(bt0121000a, t, value=i);
    };
    fr01211 := widgetset.frame(fr0121);
    for (i in boxla) {
      fr012100[i] := widgetset.frame(fr01211, side='left', expand='x');
      bt0121000[i] := widgetset.button(fr012100[i], '', type='plain',
				       value=i);
      mg0121001[i] := widgetset.message(fr012100[i], text=i, pady=5,
					justify='left',
					relief='flat');
      if ( i == 'neg') {
	widgetset.popuphelp(bt0121000[i], 'Negate x');
	widgetset.popuphelp(mg0121001[i], 'Negate x');
      } else if ( i == 'FITS') {
	widgetset.popuphelp(bt0121000[i],
			    'Define non-standard units used in FITS');
	widgetset.popuphelp(mg0121001[i],
			    'Define non-standard units ised in FITS');
      } else {
	widgetset.popuphelp(bt0121000[i], spaste('y ', i, ' x'));
	widgetset.popuphelp(mg0121001[i], spaste('y ', i, ' x'));  
      };
    };
    fr01212 := frame(fr0121);
    for (i in boxlb) {
      fr012100[i] := widgetset.frame(fr01212, side='left', expand='x');
      bt0121000[i] := widgetset.button(fr012100[i], '', type='plan',
				       value=i);
      mg0121001[i] := widgetset.message(fr012100[i], text=i, pady=5,
					justify='left',
					relief='flat');
      if (i == 'dms') {
	widgetset.popuphelp(bt0121000[i], paste('format as', i));
	widgetset.popuphelp(mg0121001[i], paste('format as', i));
      } else {
	widgetset.popuphelp(bt0121000[i], spaste(i, '(x)'));
	widgetset.popuphelp(mg0121001[i], spaste(i, '(x)'));
      };
    };
    fr01213 := frame(fr0121);
    for (i in boxlc) {
      fr012100[i] := widgetset.frame(fr01213, side='left', expand='x');
      bt0121000[i] := widgetset.button(fr012100[i], '', type='plan',
				       value=i);
      mg0121001[i] := widgetset.message(fr012100[i], text=i, pady=5,
					justify='left',
					relief='flat');
      if (i == 'atan2') {
	widgetset.popuphelp(bt0121000[i], 'atan(y/x)');
	widgetset.popuphelp(mg0121001[i], 'atan(y/x)');
      } else if (i == 'hms') {
	widgetset.popuphelp(bt0121000[i], paste('format as', i));
	widgetset.popuphelp(mg0121001[i], paste('format as', i));
      } else {
	widgetset.popuphelp(bt0121000[i], spaste(i, '(x)'));
	widgetset.popuphelp(mg0121001[i], spaste(i, '(x)'));
      };
    };
    fr01214 := frame(fr0121);
    for (i in boxld) {
      fr012100[i] := widgetset.frame(fr01214, side='left', expand='x');
      bt0121000[i] := widgetset.button(fr012100[i], '', type='plan',
				       value=i);
      mg0121001[i] := widgetset.message(fr012100[i], text=i, pady=5,
					justify='left',
					relief='flat');
      widgetset.popuphelp(bt0121000[i], spaste(i, '(x)'));
      widgetset.popuphelp(mg0121001[i], spaste(i, '(x)'));
    };
    fr012102 := private.fillvgui(fr012);
    fr01022 :=  widgetset.frame(fr012102, side='top' );
    fr012101 := widgetset.frame(fr01022, side='left');
    fr0121010 := widgetset.frame(fr012101, side='left', width='80');
    mg0121010 := widgetset.message(fr0121010, relief='sunken', text=' ',
				   width=80);
    widgetset.popuphelp(mg0121010, 'Last stack operation performed');
    fr0121011 := private.fillhgui(fr012101,sz=20);
    bt0121010 := widgetset.button(fr012101, 'deg', type='menu', relief='flat');
    widgetset.popuphelp(bt0121010, 'Select default angle units');
    mn012101 := [=];
    for (i in "deg rad") {
      mn012101[i] := widgetset.button(bt0121010, i, value=i);
      whenever mn012101[i]->press do {
	units.angle := $value;
	bt0121010->text($value);
      }
    };
    fr0121012 := private.fillhgui(fr012101,sz=100);
    mg010220 :=  widgetset.message(fr012101, relief='sunken', pady=4,
				   text='0');
    widgetset.popuphelp(mg010220, 'Shows last entry in canonical units');
#
# Fill first values
#
    bt010a->bitmap('tick.xbm');
    bt010a->foreground('darkgreen');
    bt0121010->text(units.angle);
    fr0->map();
#
# Get entry handling
#
    private.get_unit := function() {
      wider units;
      if (!units.error) {
	if (units.fill) {
	  cm := en0101->get();
	  if (cm == '') cm := '0.0';
	  if (dq.check(cm)) {
	    mg010220->text(dq.tos(dq.canonical(private.toq(cm))));
	    units.v0 := dq.unit(cm);
	    units.fill := F;
	    units.error := F;
	    bt010a->bitmap('tick.xbm');
	    bt010a->foreground('darkgreen');
	  } else {
	    units.error := T;
	    bt010a->bitmap('cross.xbm');
	    bt010a->foreground('darkred');
	    return F;
	  };
	};
      } else return F;
      return T;
    }
    
    private.put_unit := function(cm) {
      wider units;
      en0101->delete('start','end');
      if (dq.check(cm)) {
	if (is_string(cm)) en0101->insert(cm);
	else en0101->insert(dq.tos(cm));
	mg010220->text(dq.tos(dq.canonical(private.toq(cm))));
	units.v0 := dq.unit(cm);
	units.fill := F;
	units.error := F;
	bt010a->bitmap('tick.xbm');
	bt010a->foreground('darkgreen');
      } else {
	if (is_string(cm)) en0101->insert(cm);
	units.fill := T;
	units.error := T;
	bt010a->bitmap('cross.xbm');
	bt010a->foreground('darkred');
	return F;
      };
      return T;
    }
    
    private.pop_unit := function() {
      wider units;
      if (units.stackp > 0) {
	lbv := units.stack[units.stackp];
	bx010300->delete('start');
	units.stackp -:= 1;
	private.put_unit(lbv);
      } else private.put_unit('0.0');
      return T;
    }
    
    private.push_unit := function(cm) {
      wider units;
      if (is_string(cm)) bx010300->insert(cm, 'start');
      else bx010300->insert(dq.tos(cm), 'start');
      units.stackp +:= 1;
      units.stack[units.stackp] := dq.unit(cm);
      return T;
    }
    
    private.pushnew_unit := function(cm) {
      wider units;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	private.push_unit(units.v0);
      };
      private.put_unit(cm);
      return T;
    }
#
# Actions
#
# Exchange top 2 on stack
#
    whenever bt01023->press do {
      lval := $value;
      lbv := dq.unit('0.0');
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (units.stackp > 0) lbv := units.stack[units.stackp];
	else units.stackp +:= 1;
	lbs := units.v0;
	bx010300->delete('start');
	bx010300->insert(dq.tos(lbs),'start');
	units.stack[units.stackp] := lbs;
	private.put_unit(lbv);
	mg0121010->text(lval);
      };
    }	  
#
# Duplicate top of stack
#
    whenever bt01024->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	bx010300->insert(dq.tos(units.v0),'start');
	units.stackp +:= 1;
	units.stack[units.stackp] := units.v0;
	mg0121010->text(lval);
      };
    }
#
# Copy to clipboard
#
    whenever bt01025->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	dcb.copy(units.v0);
	mg0121010->text(lval);
      };
    }
#
# Paste from  clipboard
#
    whenever bt01026->press do {
      lval := $value;
      if (dq.check(dcb.paste())) {
	private.pushnew_unit(dq.tos(dcb.paste()));
	mg0121010->text(lval);
      } else if (is_string(dcb.paste())) {
	private.pushnew_unit(dcb.paste());
	mg0121010->text(lval);
      } else dq.errorgui('Cannot paste an illegal quantity');
  }
#
# constant
#
    for (i in private.units_const) {
      whenever mn0121002a[i]->press do {
	lval := $value;
	private.pushnew_unit(dq.tos(dq.constants(lval)));
	mg0121010->text(lval);
      }
    };
#
# pop
#
    whenever bt0121000.pop->press, bt01020->press do {
      lval := $value;
      if (private.pop_unit()) mg0121010->text(lval);
    }
#
# clear
#
    whenever bt0121000.clear->press do { 
      bx010300->delete('start','end');
      en0101->delete('start','end');
      units.stackp := 0;
      units.fill := F;
      units.error := F;
      units.first := T;
      units.v0 := dq.unit('0.0');
      bt010a->bitmap('tick.xbm');
      bt010a->foreground('darkgreen');
      mg0121010->text($value);
    }
#
# convert
#
    whenever bt0121000.convert->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	venv := en0111->get();
	lbv := dq.convert(units.v0, private.toq(venv));
	if (dq.check(venv)) {
	  private.put_unit(lbv);
	  mg0121010->text($value);
	};
      };
    }
#
# canonical
#
    whenever bt0121000.canon->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	private.put_unit(dq.tos(dq.canonical(private.toq(units.v0))));
	mg0121010->text(lval);
      };
    }
#
# +
#
    whenever bt0121000['+']->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (units.stackp > 0) {
	  lbv := units.stack[units.stackp];
	  lbs := units.v0;
	  if (dq.compare(lbv, lbs)) {
	    lbv := dq.add(lbv, lbs);
	    bx010300->delete('start');
	    units.stackp -:= 1;
	    private.put_unit(lbv);
	    mg0121010->text(lval);
	  } else dq.errorgui('Incompatible units for operation');
	};
      };
    }
#
# -
#
    whenever bt0121000['-']->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (units.stackp > 0) {
	  lbv := units.stack[units.stackp];
	  lbs := units.v0;
	  if (dq.compare(lbv, lbs)) {
	    lbv := dq.sub(lbv, lbs);
	    bx010300->delete('start');
	    units.stackp -:= 1;
	    private.put_unit(lbv);
	    mg0121010->text(lval);
	  } else dq.errorgui('Incompatible units for operation');
	};
      };
    }
#
# *
#
    whenever bt0121000['*']->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (units.stackp > 0) {
	  lbv := units.stack[units.stackp];
	  lbs := units.v0;
	  lbv := dq.mul(lbv, lbs);
	  bx010300->delete('start');
	  units.stackp -:= 1;
	  private.put_unit(lbv);
	  mg0121010->text(lval);
	};
      };
    }
#
# /
#
    whenever bt0121000['/']->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (units.stackp > 0) {
	  lbv := units.stack[units.stackp];
	  lbs := units.v0;
	  lbv := dq.div(lbv, lbs);
	  bx010300->delete('start');
	  units.stackp -:= 1;
	  private.put_unit(lbv);
	  mg0121010->text(lval);
	};
      };
    }
#
# negate
#
    whenever bt0121000.neg->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	lbn := private.toq(units.v0);
	lbn.value := -lbn.value;
	private.put_unit(lbn);
	mg0121010->text(lval);
      };
    }
#
# define
#
    whenever bt0121000.define->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	lbv := units.v0;
	venv := en0111->get();
	if (venv != '') {
	  dq.define(venv, lbv);
	  mg0121010->text(lval);
	};
      };
    }
#
# fits
#
    whenever bt0121000.FITS->press do {
      lval := $value;
      dq.fits();
      mg0121010->text(lval);
    }
#
# sin
#
    whenever bt0121000.sin->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (dq.is_angle(units.v0)) {
	  lbv := dq.sin(units.v0);
	  private.put_unit(lbv);
	  mg0121010->text(lval);
	} else if (dq.compare(units.v0, dq.unit('1'))) {
	  lbv := dq.sin(dq.unit(units.v0.value, units.angle));
	  private.put_unit(lbv);
	  mg0121010->text(lval);
	} else {
	  dq.errorgui('Illegal units for function');
	};
      };
    }
#
# cos
#
    whenever bt0121000.cos->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (dq.is_angle(units.v0)) {
	  lbv := dq.cos(units.v0);
	  private.put_unit(lbv);
	  mg0121010->text(lval);
	} else if (dq.compare(units.v0, dq.unit('1'))) {
	  lbv := dq.cos(dq.unit(units.v0.value, units.angle));
	  private.put_unit(lbv);
	  mg0121010->text(lval);
	} else {
	  dq.errorgui('Illegal units for function');
	};
      };
    }
#
# tan
#
    whenever bt0121000.tan->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (dq.is_angle(units.v0)) {
	  lbv := dq.tan(units.v0);
	  private.put_unit(lbv);
	  mg0121010->text(lval);
	} else if (dq.compare(units.v0, dq.unit('1'))) {
	  lbv := dq.tan(dq.unit(units.v0.value, units.angle));
	  private.put_unit(lbv);
	  mg0121010->text(lval);
	} else {
	  dq.errorgui('Illegal units for function');
	};
      };
    }
#
# asin
#
    whenever bt0121000.asin->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (dq.compare(units.v0, '1')) {
	  lbv := dq.asin(units.v0);
	  private.put_unit(dq.convert(lbv, units.angle));
	  mg0121010->text(lval);
	} else {
	  dq.errorgui('Illegal units for function');
	};
      };
    }
#
# acos
#
    whenever bt0121000.acos->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (dq.compare(units.v0, '1')) {
	  lbv := dq.acos(units.v0);
	  private.put_unit(dq.convert(lbv, units.angle));
	  mg0121010->text(lval);
	} else {
	  dq.errorgui('Illegal units for function');
	};
      };
    }
#
# atan
#
    whenever bt0121000.atan->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (dq.compare(units.v0, '1')) {
	  lbv := dq.atan(units.v0);
	  private.put_unit(dq.convert(lbv, units.angle));
	  mg0121010->text(lval);
	} else {
	  dq.errorgui('Illegal units for function');
	};
      };
    }
#
# atan2
#
    whenever bt0121000.atan2->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (units.stackp > 0) {
	  lbs := units.stack[units.stackp];
	  lbv := units.v0;
	  if (dq.compare(lbv, '1') && dq.compare(lbs, '1')) {
	    lbv := dq.atan2(lbv, lbs);
	    bx010300->delete('start');
	    units.stackp -:= 1;
	    private.put_unit(dq.convert(lbv, units.angle));
	    mg0121010->text(lval);
	  } else {
	    dq.errorgui('Illegal units for function');
	  };
	};
      };
    }
#
# abs
#
    whenever bt0121000.abs->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	lbv := dq.abs(units.v0);
	private.put_unit(lbv);
	mg0121010->text(lval);
      };
    }
#
# ceil
#
    whenever bt0121000.ceil->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	lbv := dq.ceil(units.v0);
	private.put_unit(lbv);
	mg0121010->text(lval);
      };
    }
#
# floor
#
    whenever bt0121000.floor->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	lbv := dq.floor(units.v0);
	private.put_unit(lbv);
	mg0121010->text(lval);
      };
    }	
#
# dms
#
    whenever bt0121000.dms->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (dq.is_angle(units.v0)) {
	  private.put_unit(dq.angle(units.v0));
	  mg0121010->text(lval);
	} else if (dq.compare(units.v0, dq.unit('1'))) {
	  private.put_unit(dq.angle(dq.unit(units.v0.value, units.angle)));
	  mg0121010->text(lval);
	} else {
	  dq.errorgui('Illegal units for function');
	};
      };
    }
#
# hms
#
    whenever bt0121000.hms->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (dq.is_angle(units.v0)) {
	  private.put_unit(dq.time(units.v0));
	  mg0121010->text(lval);
	} else if (dq.compare(units.v0, dq.unit('1'))) {
	  private.put_unit(dq.time(dq.unit(units.v0.value, units.angle)));
	  mg0121010->text(lval);
	} else {
	  dq.errorgui('Illegal units for function');
	};
      };
    }
#
# log
#
    whenever bt0121000.log->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (!dq.compare(units.v0, '1')) {
	  dq.errorgui('Illegal units for function');
	} else {
	  lbv := dq.log(units.v0);
	  private.put_unit(lbv);
	  mg0121010->text(lval);
	};
      };
    }
#
# log10
#
    whenever bt0121000.log10->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (!dq.compare(units.v0, '1')) {
	  dq.errorgui('Illegal units for function');
	} else {
	  lbv := dq.log10(units.v0);
	  private.put_unit(lbv);
	  mg0121010->text(lval);
	};
      };
    }
#
# exp
#
    whenever bt0121000.exp->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	if (!dq.compare(units.v0, '1')) {
	  dq.errorgui('Illegal units for function');
	} else {
	  lbv := dq.exp(units.v0);
	  private.put_unit(lbv);
	  mg0121010->text(lval);
	};
      };
    }
#
# sqrt
#
    whenever bt0121000.sqrt->press do {
      lval := $value;
      if (!units.error && 
	  (!units.fill || (units.fill && private.get_unit()))) {
	lbv := dq.sqrt(units.v0);
	if (is_fail(lbv)) dq.errorgui('Cannot take sqrt');
	else {
	  private.put_unit(lbv);
	  mg0121010->text(lval);
	};
      };
    }
#
# end unitgui
#
    note('GUI started for quantities', priority='NORMAL', origin='quanta');
    return T;
  }
#
# End server constructor
#
  return T;
} # constructor
