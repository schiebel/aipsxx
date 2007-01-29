#gchooser.g: Display visibility data
#
#   Copyright (C) 1998,1999,2000,2001,2002
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
#   $Id: gchooser.g,v 19.3 2005/03/20 20:26:55 gmoellen Exp $

pragma include once;
    
include "widgetserver.g";

const gchooser := subsequence (parent=F, labels='', 
                               indices=[],
			       x=[], y=[],
			       xref=unset, yref=unset, autoref=F,
			       title='Graphical chooser (AIPS++)',
			       xlabel='X', ylabel='Y',
			       plottitle='',
			       axes='',
			       width=500, height=500,
			       pad=0.15,
			       embedded=F,
			       widgetset=dws)
{
  
  include 'note.g';
  include 'mathematics.g';

  private := [=];    # private data and helpers
  
  private.widgetset := widgetset;

  private.pgplotter := F;
  private.viewer := F;

  private.width := width;
  private.height := height;
  private.pad := pad;
  private.title := title;
  private.plottitle := plottitle;
  private.xlabel := xlabel;
  private.ylabel := ylabel;
  private.axes := axes;
  private.embedded := embedded;

  if(private.axes=='sky') {
    # RA should be positive:
    x[x<0.0]+:=(2.0*pi);
    # put RA and Dec into arcseconds:
    private.x := x * (360.0*3600.0/(2.0*pi));
#    private.x := x * (24.0*3600.0/(2.0*pi));
    private.y := y * (180.0*3600.0/pi);
  }
  else {
    private.x := x;
    private.y := y;
  }
  private.indices := indices;


  # find absolute largest plotting range
  private.xminlim := min(private.x);
  private.yminlim := min(private.y);
  private.xmaxlim := max(private.x);
  private.ymaxlim := max(private.y);

  rangex := private.xmaxlim - private.xminlim;
  rangey := private.ymaxlim - private.yminlim;

  private.xminlim -:= private.pad*abs(rangex)
  private.yminlim -:= private.pad*abs(rangey)
  private.xmaxlim +:= private.pad*abs(rangex)
  private.ymaxlim +:= private.pad*abs(rangey)

  if((private.xminlim==0.0)&&(private.xmaxlim==0.0)) {
    private.xminlim:=private.yminlim;
    private.xmaxlim:=private.ymaxlim;
  }
  if((private.yminlim==0.0)&&(private.ymaxlim==0.0)) {
    private.yminlim:=private.xminlim;
    private.ymaxlim:=private.xmaxlim;
  }
  if((private.xminlim==0.0)&&(private.xmaxlim==0.0)) {
    return throw('All axes are zero');
  }

  # the sky is bounded:
  if (private.axes=='sky') {
    private.xminlim := max(private.xminlim,+0.0);
    private.yminlim := max(private.yminlim,-90.0*3600.0);
    private.xmaxlim := min(private.xmaxlim,360.0*3600.0);
    private.ymaxlim := min(private.ymaxlim,90.0*3600.0);
  }

  # set plotting range to largest
  private.xmin:=private.xminlim;
  private.ymin:=private.yminlim;
  private.xmax:=private.xmaxlim;
  private.ymax:=private.ymaxlim;


  private.blc := F;

  private.whenevers := [];
  private.pushwhenever := function() {
    wider private;
    private.whenevers[len(private.whenevers) + 1] := last_whenever_executed();
  }
  
  private.nearest := function(rec) {
    wider private;
    index := 1;
    leastdist := (private.xmaxlim-private.xminlim)^2 + 
                 (private.ymaxlim-private.yminlim)^2;
    for(i in 1:length(private.x)) {
      if (private.x[i]>=private.xmin && private.x[i]<=private.xmax &&
          private.y[i]>=private.ymin && private.y[i]<=private.ymax ) {
        dist := (private.x[i]-rec.world[1])^2+(private.y[i]-rec.world[2])^2;
        if(dist<leastdist) { 
          leastdist := dist;
	  index := i;
        }
      }
    }
    return index;
  }


  # these are short labels, appropriate on a plot:
  private.labels := labels;

  private.mask := array(F, length(private.x));

  if(autoref) {
    rec:=[=];
    rec.world[1]:=sum(private.x)/length(private.x);
    rec.world[2]:=sum(private.y)/length(private.y);
    nearest := private.nearest(rec);
    private.x-:=private.x[nearest];
    private.y-:=private.y[nearest];
    note('Reference is ', private.indices[nearest], '  ',
	 private.labels[nearest]);
  }
  else {
    if(!is_unset(xref)) private.x-:=xref;
    if(!is_unset(yref)) private.y-:=yref;
  }

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
#  whenever private.frames["top"]->resize do {
#    if(private.lock()) {
#      $agent.self.plot();
#      private.unlock();
#    }
#  } private.pushwhenever();

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
    info := sprintf('Id: %g: %s', private.indices[nearest],
		    private.labels[nearest]);
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
      private.region(blc, trc);
      private.pgplotter.cursor('norm', x=rec.world[1], y=rec.world[2]);
      self->select(private.indices[private.mask]);
      private.blc := F;
    }
  }
  # Select the nearest
  private.callbacks['button2'] := function(rec) {
    wider private;
    nearest := private.nearest(rec);
    self->select(private.indices[nearest]);
    private.mask[nearest] := T;
    private.pgplotter.sci(3);
    private.pgplotter.pt(private.x[nearest], private.y[nearest], -4);
  }
  # Deselect the nearest
  private.callbacks['button3'] := function(rec) {
    wider private;
    nearest := private.nearest(rec);
    self->deselect(private.indices[nearest]);
    private.mask[nearest] := F;
    private.pgplotter.sci(2);
    private.pgplotter.pt(private.x[nearest], private.y[nearest], -4);
  }

  # Zoom 
  private.callbacks['key'] := function(rec) {
    wider self, private;  
    if (rec.key=='z' || rec.key=='Z') {
      zfact:=0.5;
      if (rec.key=='Z') zfact:=0.1;
      rangex:=abs(private.xmax - private.xmin);
      rangey:=abs(private.ymax - private.ymin);
      range:=mean(rangex,rangey);
      private.xmin:=rec.world[1] - zfact*range/2.0;
      private.xmax:=rec.world[1] + zfact*range/2.0;
      private.ymin:=rec.world[2] - zfact*range/2.0;
      private.ymax:=rec.world[2] + zfact*range/2.0;
      self.plot();
    } 
    else if (rec.key=='u' || rec.key=='U') {
      zfact:=2.0;
      if (rec.key=='U') zfact:=10.0;
      rangex:=abs(private.xmax - private.xmin);
      rangey:=abs(private.ymax - private.ymin);
      centerx:=mean(private.xmax,private.xmin);
      centery:=mean(private.ymax,private.ymin);

      private.xmin:=centerx - zfact*rangex/2.0;
      private.xmax:=centerx + zfact*rangex/2.0;
      private.ymin:=centery - zfact*rangey/2.0;
      private.ymax:=centery + zfact*rangey/2.0;

      private.xmin:=max(private.xmin, private.xminlim);
      private.ymin:=max(private.ymin, private.yminlim);
      private.xmax:=min(private.xmax, private.xmaxlim);
      private.ymax:=min(private.ymax, private.ymaxlim);
      self.plot();
    }
    else if (rec.key=='c' || rec.key=='C') {
      rangex:=abs(private.xmax - private.xmin);
      rangey:=abs(private.ymax - private.ymin);
      centerx:=mean(private.xmax,private.xmin);
      centery:=mean(private.ymax,private.ymin);
      private.xmin:=rec.world[1]-rangex/2.0;
      private.xmax:=rec.world[1]+rangex/2.0;
      private.ymin:=rec.world[2]-rangey/2.0;
      private.ymax:=rec.world[2]+rangey/2.0;
      private.xmin:=max(private.xmin, private.xminlim);
      private.ymin:=max(private.ymin, private.yminlim);
      private.xmax:=min(private.xmax, private.xmaxlim);
      private.ymax:=min(private.ymax, private.ymaxlim);
      self.plot();
    }
  }


  private.region := function(blc, trc) {
    wider private;
    private.pgplotter.sci(3);
    for (i in 1:length(private.x)) {
      x := private.x[i];
      y := private.y[i];
      if (x>=private.xmin && x<=private.xmax &&
          y>=private.ymin && y<=private.ymax ) {
        if((x>=blc[1])&&(x<=trc[1])&&(y>=blc[2])&&(y<=trc[2])) {
	  private.mask[i] := T;
	  private.pgplotter.pt(private.x[i], private.y[i], -4);
        }
      }
    }
  }
  
  private.all := function() {
    wider private;
    private.mask := array(T, length(private.x));
    private.pgplotter.sci(3);
    private.pgplotter.pt(private.x, private.y, -4);
  }
  
  private.none := function() {
    wider private;
    private.mask := array(F, length(private.x));
    private.pgplotter.sci(2);
    private.pgplotter.pt(private.x, private.y, -4);
  }
  
  private.insert := function(choices) {
    wider private;
    private.none();
    for (choice in choices) {
      if(any(private.indices==choice)) {
	for (i in 1:length(private.indices)) {
	  if(private.indices[i]==choice) {
	    private.mask[i] := T;
	    break;
	  }
	}
      }
    }
    private.pgplotter.sci(3);
    private.pgplotter.pt(private.x, private.y, -4);
    return T;
  }
  
  private.invert := function() {
    wider self, private;
    private.mask := !private.mask;
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
  if(private.embedded) private.frames["menu"]->unmap();
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
    private.xmin:=private.xminlim;
    private.ymin:=private.yminlim;
    private.xmax:=private.xmaxlim;
    private.ymax:=private.ymaxlim;
    self.plot();
  } private.pushwhenever();

  private.frames["bottomright"] := widgetset.frame(private.frames["bottom"],
						   side='right');
  if(!private.embedded) {
    private.buttons["DismissLower"] := widgetset.button(private.frames["bottomright"],
							"Dismiss",
							type="dismiss");
    private.buttons["DismissLower"].shorthelp := 'Dismiss without sending choices';
    whenever private.buttons["DismissLower"]->press do {
      self->dismiss();
      self.done();
    } private.pushwhenever();
  }
  private.buttons["Accept"] := widgetset.button(private.frames["bottomright"],
						 "Accept",
						 type="action");
  private.buttons["Accept"].shorthelp := 'Accept and send current choices';
  whenever private.buttons["Accept"]->press do {
    self->values(self.get());
  } private.pushwhenever();

  widgetset.addpopuphelp(private, 5);

  widgetset.tk_release();

  self.plot := function() {
    wider private;
    private.pgplotter.clear();
    private.pgplotter.bbuf();
    if(private.axes=='sky') {
      private.pgplotter.env(private.xmax,private.xmin,
                            private.ymin,private.ymax,
                            1,-1);
      private.pgplotter.swin(private.xmax/15.0,private.xmin/15.0,
                             private.ymin,private.ymax);
      private.pgplotter.tbox('BCSTNZYH', 0.0, 0, 'BCSTNZD', 0.0, 0);
      private.pgplotter.swin(private.xmax,private.xmin,
                             private.ymin,private.ymax);

    }
    else {
      private.pgplotter.env(private.xmin,private.xmax,
                             private.ymin,private.ymax,
			    1, 0);
    }
    private.pgplotter.sci(1);
    private.pgplotter.lab(private.xlabel, private.ylabel, private.plottitle);
    private.pgplotter.iden();
    for (i in 1:length(private.x)) {
      if(private.mask[i]) {
	private.pgplotter.sci(3);
      }
      else {
	private.pgplotter.sci(2);
      }
      private.pgplotter.pt(private.x[i], private.y[i], -4);
    }

    private.pgplotter.sci(1);
    private.pgplotter.sch(0.85);
    for (i in 1:length(private.x)) {
      if (private.x[i]>=private.xmin && private.x[i]<=private.xmax &&
        private.y[i]>=private.ymin && private.y[i]<=private.ymax ) {
	if(private.x[i]>=mean(private.x)) {
	  just := -0.1;
	  if (private.axes=='sky') just:=1.1;
          orient:=0.0;
	}
	else {
	  just := 1.1;
	  if (private.axes=='sky') just:=-0.1;
          orient:=0.0;
	}
	private.pgplotter.ptxt(private.x[i], private.y[i], orient,
		  	         just, as_string(private.indices[i]));
      }
    }
    private.pgplotter.sch(1.0);
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
    rec := [=];
    rec.selection := private.indices[private.mask];
    rec.labels := private.labels[private.mask];
    if(private.axes=='sky') {
      rec.x := private.x[private.mask] / (360.0*3600.0/(2.0*pi));
      rec.y := private.y[private.mask] / (180.0*3600.0/pi);
    }
    else {
      rec.x := private.x[private.mask];
      rec.y := private.y[private.mask];
    }
    return rec;
  }

  self.insert := function(choices) {
    wider private;
    return private.insert(choices);
  }

  result := self.plot();

}

gchoosertest := function() {
  include 'table.g';

  if(!tableexists('XCAS.ms')) {
    include 'imager.g';
    imagermaketestmfms();
  }
  dt:=table('XCAS.ms', ack=F);
  fields := unique(sort(dt.getcol('FIELD_ID')+1));
  dt.close();
  t:=table('XCAS.ms/FIELD', ack=F);
  position := t.getcol('PHASE_DIR');
  name := t.getcol('NAME');
  t.done();
  nfields := length(name);
  fieldids := 1:nfields;
  x := array(0.0, nfields);
  y := array(0.0, nfields);
  labels := [''];
  i := 0;
  for (field in fieldids) {
    if(any(field==fields)) {
      i+:=1;
      x[i] := position[1, , field];
      y[i] := position[2, , field];
      labels[i] := name[field];
    }
  }
  gc := gchooser(labels=labels, labels=labels, indices=fields, x=x, y=y, 
		 xlabel='Right Ascension', ylabel='Declination',
		 plottitle='Fields', axes='sky', width=500, height=500);
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
