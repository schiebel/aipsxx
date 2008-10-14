#combochooser.g: Display visibility data
#
#   Copyright (C) 1998,1999,2000,2001
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
#   $Id: combochooser.g,v 19.2 2004/08/25 02:12:42 cvsmgr Exp $

pragma include once;
    
include "widgetserver.g";

const combochooser := subsequence (parent=F, 
                                   idx1=[], labels1='', 
                                   idx2=[], labels2='', imask=[],
				   title='Combination chooser (AIPS++)',
				   xlabel='First', ylabel='Second',
				   width=500, height=500,
				   plottitle='Combinations',
				   pad=0.25,
				   widgetset=dws)
{
  
  include 'note.g';

  private := [=];    # private data and helpers
  
  private.widgetset := widgetset;

  private.pgplotter := F;

  private.width := width;
  private.height := height;
  private.pad := pad;
  private.title := title;
  private.plottitle := plottitle;
  private.xlabel := xlabel;
  private.ylabel := ylabel;

  private.x := array(0, length(idx1), length(idx2));
  private.y := array(0, length(idx1), length(idx2));
  private.idx1 := idx1;
  private.idx2 := idx2;

  if (!is_boolean(imask)) {
    imask:=array(T,length(idx1)*length(idx2));
  }
  private.imask := imask;

  for (i in 1:length(idx2)) {
    private.x[,i] := as_float(1:length(idx2));
  }
  for (i in 1:length(idx1)) {
    private.y[i,] := as_float(1:length(idx1));
  }
  private.x::shape:=array(length(idx1)*length(idx2), 1)
  private.y::shape:=array(length(idx1)*length(idx2), 1)

  private.blc := F;

  private.whenevers := [];
  private.pushwhenever := function() {
    wider private;
    private.whenevers[len(private.whenevers) + 1] := last_whenever_executed();
  }
  
  private.nearest := function(rec) {
    wider private;
    index := 1;
    leastdist := 100000;
    for(i in 1:length(private.x)) {
      if (private.imask[i]) {
        dist := (private.x[i]-rec.world[1])^2+(private.y[i]-rec.world[2])^2;
        if(dist <=0.5) {
	  leastdist := dist;
	  index := i;
        }
      }
    }
    return index;
  }

  private.getpairs := function(list) {
    wider private;
    if(length(list)==1) {
      i := as_integer(list);
      rec := array(0, 2, 1);
      x := private.idx1[as_integer(private.x[i])];
      y := private.idx2[as_integer(private.y[i])];
      rec[,1] := [x, y];
    }
    else {
      rec := array(0, 2, sum(list));
      n := 0;
      for (i in 1:length(list)) {
	if(list[i]) {
	  n +:=1;
	  x := private.idx1[as_integer(private.x[i])];
	  y := private.idx2[as_integer(private.y[i])];
	  rec[,n] := [x, y];
	}
      }
    }
    return rec;
  }

  private.labels1 := labels1;
  private.labels2 := labels2;
  private.mask := array(F, length(private.x));

#
# The frame for the GUI
#
  private.frames := [=];
  widgetset.tk_hold();
  if(is_agent(parent)) {
    private.frames["top"] := widgetset.frame(parent, width=private.width,
					     height=private.height);
  }
  else {
    private.frames["top"] := widgetset.frame(title=private.title,
					     width=private.width,
					     height=private.height);
  }
  private.frames["top"].self := ref self;
  whenever private.frames["top"]->resize do {
    if(private.lock()) {
      $agent.self.plot();
      private.unlock();
    }
  } private.pushwhenever();

  private.isbusy := F;
  private.lock := function() {
    wider private;
    if(!private.isbusy) {
      private.isbusy := T;
      private.frames["top"]->cursor('watch');
      private.frames["top"]->disable();
      return T;
    }
    else {
      return F;
    }
  }
  private.unlock := function() {
    wider private;
    private.isbusy := F;
    private.frames["top"]->cursor('left_ptr');
    private.frames["top"]->enable();
    return T;
  }

  private.callbacks := [=];
  # Show the nearest
  private.callbacks['motion'] := function(rec) {
    wider private;
    nearest := private.nearest(rec);
    x:=as_integer(private.x[nearest])
    y:=as_integer(private.y[nearest])
    info := sprintf ('%s (%g) -- %s (%g)', private.labels1[x], x,
                                           private.labels2[y], y);
    private.pgplotter.message(info);
  }
  # Select the nearest
  private.callbacks['button1'] := function(rec) {
    wider private;
    private.blc := rec.world;
    private.pgplotter.cursor('rect', x=rec.world[1], y=rec.world[2]);
  }
  private.callbacks['buttonup'] := function(rec) {
    wider private, self;
    if(!is_boolean(private.blc)) {
      private.trc := rec.world;
      for (i in 1:2) {
	blc[i] := min(private.blc[i], private.trc[i]);
	trc[i] := max(private.blc[i], private.trc[i]);
      }
      nonzero:=private.region(blc, trc);
      private.pgplotter.cursor('norm', x=rec.world[1], y=rec.world[2]);
      if (nonzero) self->select(private.getpairs(private.mask));
      private.blc := F;
    }
  }
  # Select the nearest
  private.callbacks['button2'] := function(rec) {
    wider private;
    nearest := private.nearest(rec);
    self->select(private.getpairs(nearest));
    private.mask[nearest] := T;
    private.pgplotter.sci(3);
    private.pgplotter.pt(private.x[nearest], private.y[nearest], -4);
  }
  # Deselect the nearest
  private.callbacks['button3'] := function(rec) {
    wider private;
    nearest := private.nearest(rec);
    self->deselect(private.getpairs(nearest));
    private.mask[nearest] := F;
    private.pgplotter.sci(2);
    private.pgplotter.pt(private.x[nearest], private.y[nearest], -4);
  }
  
  private.region := function(blc, trc) {
    wider private;
    private.pgplotter.sci(3);
    nonzero:=F;
    for (i in 1:length(private.x)) {
      x := private.x[i];
      y := private.y[i];
      if(private.imask[i] && ((x>=blc[1])&&(x<=trc[1])&&(y>=blc[2])&&(y<=trc[2]))) {
        nonzero:=T;
	private.mask[i] := T;
	private.pgplotter.pt(private.x[i], private.y[i], -4);
      }
    }
    return nonzero;
  }
  
  private.all := function() {
    wider private;
    private.mask := array(T, length(private.x));
    private.mask:=(private.mask & private.imask);
    private.pgplotter.sci(3);
    private.pgplotter.pt(private.x[private.mask], private.y[private.mask], -4);
  }
  
  private.none := function() {
    wider private;
    private.mask := array(F, length(private.x));
    private.pgplotter.sci(2);
    private.pgplotter.pt(private.x[private.imask], private.y[private.imask], -4);
  }
  
  private.insert := function(choices) {
    wider private;
    private.none();
    for (choice in choices) {
      if(any(private.idx1==choice)) {
        for (i in 1:length(private.x)) {
	  if (private.x[i]==choice) {
	    private.mask[i] := T;
	    break;
          }
	}
      }
    }
    private.pgplotter.sci(3);
    private.pgplotter.pt(private.x[nearest], private.y[nearest], -4);
    return T;
  }
  
  private.invert := function() {
    wider self, private;
    private.mask := !private.mask;
    private.mask := (private.mask & private.imask);
    return self.plot();
  }
  
  private.save := function(file) {
    wider private;
    private.pgplotter.plotfile(file);
  }
  
  private.print := function(file) {
    wider private;
    private.pgplotter.postscript(file);
    if(!has_field(private, 'printer')) {
      include 'printer.g';
      private.printer := printer();
    }
    private.printer.gui(file);
  }

  private.frames["menu"] := widgetset.frame(private.frames['top'], side='left');
  private.buttons['File'] := widgetset.button(private.frames['menu'], 'File',
					      type='menu');
  private.guientry := widgetset.guientry();

  private.buttons['Save'] := widgetset.button(private.buttons['File'],
					      'Save');
  private.buttons['Save'].shorthelp := 'Save plot to an AIPS++ plot file';
  whenever private.buttons['Save']->press do {
    if(private.lock()) {
      private.buttons['Filename'] := private.guientry.file(types='Plot file');
      whenever private.buttons['Filename']->value do {
	private.buttons['Filename'].done();
	file := $value;
	if(file!='') {
	  private.save(file);
	}
        deactivate;
      } private.pushwhenever();
      private.unlock();
    }
  } private.pushwhenever();
  private.buttons['Print'] := widgetset.button(private.buttons['File'],
					       'Print');
  private.buttons['Print'].shorthelp := 'Print plot as a postscript file';
  whenever private.buttons['Print']->press do {
    if(private.lock()) {
      private.buttons['Filename'] := private.guientry.file(types='Postscript');
      whenever private.buttons['Filename']->value do {
	file := $value;
	private.buttons['Filename'].done();
	if(file!='') {
	  private.print(file);
	}
	deactivate;
      } private.pushwhenever();
      private.unlock();
    }
  } private.pushwhenever();

  private.buttons["Dismiss"] := widgetset.button(private.buttons["File"],
						 "Dismiss",
						 type="dismiss");
  private.buttons["Dismiss"].shorthelp := 'Dismiss without sending choices';
  whenever private.buttons["Dismiss"]->press do {
    self->dismiss();
    self.done();
  } private.pushwhenever();

  private.frames["rightmenu"] := widgetset.frame(private.frames['menu'],
						 side='right');

  private.helpmenu := widgetset.helpmenu(private.frames['rightmenu']);

  private.frames["view"] := widgetset.frame(private.frames["top"], side='top');
  include 'pgplotwidget.g';
  private.pgplotter:= pgplotwidget(private.frames['view'],
				   background='white', foreground='black',
				   havemessages=T,
				   size=[width,height],
				   widgetset=private.widgetset);
  for (what in field_names(private.callbacks)) {
    private.callbacknumbers[what] :=
	private.pgplotter.setcallback(what, private.callbacks[what]);
    private.pgplotter.activatecallback(private.callbacknumbers[what]);
  }
  private.frames["bottom"] := widgetset.frame(private.frames["top"], side='left');
  
  private.buttons["None"] := widgetset.button(private.frames["bottom"],
					       "None");
  private.buttons["None"].shorthelp := 'Select none';
  whenever private.buttons["None"]->press do {
    private.none();
  } private.pushwhenever();
  private.buttons["All"] := widgetset.button(private.frames["bottom"],
					       "All");
  private.buttons["All"].shorthelp := 'Select all';
  whenever private.buttons["All"]->press do {
    private.all();
  } private.pushwhenever();
  private.buttons["Invert"] := widgetset.button(private.frames["bottom"],
					       "Invert");
  private.buttons["Invert"].shorthelp := 'Invert selections';
  whenever private.buttons["Invert"]->press do {
    private.invert();
  } private.pushwhenever();
  private.buttons["Refresh"] := widgetset.button(private.frames["bottom"],
					       "Refresh");
  private.buttons["Refresh"].shorthelp := 'Refresh the plot';
  whenever private.buttons["Refresh"]->press do {
    self.plot();
  } private.pushwhenever();

  private.frames["bottomright"] := widgetset.frame(private.frames["bottom"],
						   side='right');
  private.buttons["DismissLower"] := widgetset.button(private.frames["bottomright"],
						 "Dismiss",
						 type="dismiss");
  private.buttons["DismissLower"].shorthelp := 'Dismiss without sending choices';
  whenever private.buttons["DismissLower"]->press do {
    self->dismiss();
    self.done();
  } private.pushwhenever();
  private.buttons["Accept"] := widgetset.button(private.frames["bottomright"],
						 "Accept",
						 type="action");
  private.buttons["Accept"].shorthelp := 'Accept and send current choices';
  whenever private.buttons["Accept"]->press do {
    self->values(self.get());
  } private.pushwhenever();

  widgetset.addpopuphelp(private, 5);

  widgetset.tk_release();

  minx := min(private.x);
  miny := min(private.y);
  maxx := max(private.x);
  maxy := max(private.y);

  rangex := maxx - minx;
  rangey := maxy - miny;

  if((minx==0.0)&&(maxx==0.0)) {
    minx:=miny;
    maxx:=maxy;
  }
  if((miny==0.0)&&(maxy==0.0)) {
    miny:=minx;
    maxy:=maxx;
  }
  if((minx==0.0)&&(maxx==0.0)) {
    return throw('All axes are zero');
  }

  self.plot := function() {
    wider private;
    private.pgplotter.clear();
    private.pgplotter.bbuf();
    private.pgplotter.env(minx-private.pad*abs(rangex),
			  maxx,
			  miny-private.pad*abs(rangey),
			  maxy,
			  0, -2);
    private.pgplotter.iden();
    for (i in 1:length(private.x)) {
      if(private.mask[i]) {
	private.pgplotter.sci(3);
      }
      else {
	private.pgplotter.sci(2);
      }
      if (private.imask[i]) {
        private.pgplotter.pt(private.x[i], private.y[i], -4);
      }
    }
    private.pgplotter.sci(1);
    private.pgplotter.lab(private.xlabel, private.ylabel, private.plottitle);
    for (i in 1:length(private.labels1)) {
      x := as_float(i);
      info := sprintf ('%s (%g)', private.labels1[i], i);
      private.pgplotter.ptxt(x, 0.0, 90.0, 1.0, info);
    }
    for (i in 1:length(private.labels2)) {
      y := as_float(i);
      info := sprintf ('%s (%g)', private.labels2[i], i);
      private.pgplotter.ptxt(0.0, y, 0.0,  1.0, info);
    }


    private.pgplotter.ebuf();
  }

  self.done := function() {
    wider private, self;

    if(!is_record(private)) return F;

    private.frames["top"]->unmap();

    for (what in field_names(private.callbacks)) {
      private.pgplotter.deactivatecallback(private.callbacknumbers[what]);
    }
    private.pgplotter.page();
    private.pgplotter.done();

    deactivate private.whenevers;

    for (i in field_names(private.buttons)) {
      if(is_record(private.buttons[i])&&
	 has_field(private.buttons[i], 'done')&&
	 is_function(private.buttons[i].done)) {
	private.buttons[i].done();
      }
      private.buttons[i] := F;
    }
    for (i in field_names(private.frames)) {
      private.frames[i]->unmap();
      private.frames[i] := F;
    }
    for (i in field_names(private)) {
      if(is_record(private[i])&&
	 has_field(private[i], 'done')&&
	 is_function(private[i].done)) {
	private[i].done();
      }
      private[i] := F;
    }
    val private := F;
    self->done();
    return F;
  }
  
  self.get := function() {
    wider private;
    return [selection=private.getpairs(private.mask)];
  }

  self.insert := function(choices) {
    wider private;
    print "Running self.insert: choices=", choices;
    return private.insert(choices);
  }

  result := self.plot();

}

combochoosertest := function() {
  include 'table.g';

  if(!tableexists('3C273XC1.ms')) {
    include 'imager.g';
    imagermaketestms();
  }
  dt:=table('3C273XC1.ms', ack=F);
  ants := dt.getcol('ANTENNA1')+1;
  dt.close();
  t:=table('3C273XC1.ms/ANTENNA', ack=F);
  position := t.getcol('POSITION');
  station := t.getcol('STATION');
  antids := 1:length(station);
  t.done();
  ants := unique(sort(ants));
  nant := length(ants);
  labels := '';
  i := 0;
  for (ant in antids) {
    if(any(ant==ants)) {
      i+:=1;
      labels[i] := station[ant];
    }
  }
  gc := combochooser(labels=labels, indices=ants, xlabel='Antenna1',
		     ylabel='Antenna2', width=500, height=500);
  whenever gc->values do {
    print "Values are ", $value;
    gc.done();
  }
  whenever gc->select do {
    print "Selected ", $value
  }
  whenever gc->deselect do {
    print "Deselected ", $value
  }
}
