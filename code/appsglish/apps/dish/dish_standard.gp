# dish_stndard.gp: Standard plugins for dishpg.g
# Copyright (C) 1999,2000
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
# $Id: dish_standard.gp,v 19.1 2004/08/25 01:08:59 cvsmgr Exp $

pragma include once;
include 'types.g'


## We should probably make the following globally advertised at some point.

dish_standard := [=];

dish_standard.attach := function(ref pg) {

 private := [=];
 
 count_swinenv := function(ref plotter)
 {
  c := 0;
  n := plotter.displaylist().ndrawlist();
  for (i in 1:n)
   {
   tmp := plotter.displaylist().get(i);
   if (is_record(tmp) && has_field(tmp, '_method'))
    if (tmp._method=='swin' || tmp._method=='env')
     c +:= 1;
   }
  return c;
 }                                            

 set_orig := function(ref state, ref cmd, ref plotter)
 {
  wider private;
  private.count := 0
  n := plotter.displaylist().ndrawlist();
  if (n==0)
   {
   print 'No commands in display list!'
   state.original := 0
   state.last := 0
   return
   }
  for (i in 1:n) 
   {
   tmp := plotter.displaylist().get(i);
   if (is_record(tmp) && has_field(tmp, '_method')) 
    {
    if (tmp._method=='swin') 
     { 
     private.count +:= 1 ; 
     cmd.x1[private.count] := tmp.x1; 
     cmd.x2[private.count] := tmp.x2; 
     cmd.y1[private.count] := tmp.y1; 
     cmd.y2[private.count] := tmp.y2; 
     state.where[private.count] := i
     state.original._method[private.count] := tmp._method
     state.original.x1[private.count] := tmp.x1
     state.original.x2[private.count] := tmp.x2
     state.original.y1[private.count] := tmp.y1
     state.original.y2[private.count] := tmp.y2
     state.current.x1[private.count] := tmp.x1
     state.current.x2[private.count] := tmp.x2
     state.current.y1[private.count] := tmp.y1
     state.current.y2[private.count] := tmp.y2
     }
    else if (tmp._method=='env') 
     { 
     private.count +:= 1 ; 
     cmd.x1[private.count] := tmp.xmin; 
     cmd.x2[private.count] := tmp.xmax; 
     cmd.y1[private.count] := tmp.ymin; 
     cmd.y2[private.count] := tmp.ymax; 
     cmd.just[private.count] := tmp.just; 
     cmd.axis[private.count] := tmp.axis; 
     state.where[private.count] := i
     state.original._method[private.count] := tmp._method
     state.original.x1[private.count] := tmp.xmin
     state.original.x2[private.count] := tmp.xmax
     state.original.y1[private.count] := tmp.ymin
     state.original.y2[private.count] := tmp.ymax
     state.original.just[private.count] := tmp.just
     state.original.axis[private.count] := tmp.axis
     state.current.x1[private.count] := tmp.xmin
     state.current.x2[private.count] := tmp.xmax
     state.current.y1[private.count] := tmp.ymin
     state.current.y2[private.count] := tmp.ymax
     }
    }
   }
  state.last.x1 := state.original.x1[private.count]
  state.last.x2 := state.original.x2[private.count]
  state.last.y1 := state.original.y1[private.count]
  state.last.y2 := state.original.y2[private.count]
 }
 
 reset_full := function(ref state, ref plotter)
 {
  wider private;
  if (private.count==0)
   { print 'No commands in display list!'; return; }
  for (i in 1:private.count) 
   {
   state.current.x1[i] := state.original.x1[i]
   state.current.x2[i] := state.original.x2[i]
   state.current.y1[i] := state.original.y1[i]
   state.current.y2[i] := state.original.y2[i]
   tmp := [=]
   if (state.original._method[i]=='swin') 
    { 
    tmp._method := 'swin'
    tmp.x1 := state.original.x1[i]
    tmp.x2 := state.original.x2[i]
    tmp.y1 := state.original.y1[i]
    tmp.y2 := state.original.y2[i]
    }
   else if (state.original._method[i]=='env') 
    { 
    tmp._method := 'env'
    tmp.xmin := state.original.x1[i]
    tmp.xmax := state.original.x2[i]
    tmp.ymin := state.original.y1[i]
    tmp.ymax := state.original.y2[i]
    tmp.just := state.original.just[i]
    tmp.axis := state.original.axis[i]
    }
   plotter.displaylist().set(state.where[i], tmp);
   }
  state.last.x1 := state.original.x1[private.count]
  state.last.x2 := state.original.x2[private.count]
  state.last.y1 := state.original.y1[private.count]
  state.last.y2 := state.original.y2[private.count]
  plotter.refresh()
 }
 
 zoom_start := function(ref f, ref plotter, ref state)
 {
  wider private;
  msg :=  'Drag out the new area you want to see.  Dismiss zoom when done.';
  private.count := 0
  where := 0
  cmd := [=]
 
  if (length(state) == 0) 
   {
   state.where[1] := 0;
   state.original := [=]
   state.current := [=]
   old := plotter.record(F);
   state.message := message(f, msg);
   plotter.record(old);
   state.fullbutton := button(f, 'Reset Full View');
   whenever state.fullbutton->press do
    reset_full(state,plotter)
   }
 
  set_orig(state, cmd, plotter)
 
  if (!private.count) 
   return throw('zoom - no \'swin\' or \'env\' command in drawlist!');
 
  old := plotter.record(F);
  plotter.message(msg);
  plotter.record(old);
 
  start := F;
  devicestart := F;
 
  buttondown_callback := function(rec)
   {
   wider private,state, start, plotter, devicestart;
   if (private.count != count_swinenv(plotter))
    return throw('Zoom will not work because you have issued plot commands without dismissing the zoom tool first.  Unzoom, dismiss the zoom tool, and try again.');
   start := rec.world;
   devicestart := rec.device;
   plotter.cursor(mode='rect', color=1, x=start[1], y=start[2]);
   }
 
  buttonup_callback := function(rec)
  {
   wider private,start, plotter, devicestart, state, cmd
   end := rec.world;
   plotter.cursor('norm');
  
   if (devicestart[1]==rec.device[1] || devicestart[2]==rec.device[2])
    return T; # No-op if we have a zero-sized region
  	    
   if (devicestart[1] > rec.device[1])
    { command.x1 := end[1]; command.x2 := start[1]; } 
   else 
    { command.x1 := start[1]; command.x2 := end[1]; }
  
   if (devicestart[2] < rec.device[2]) 
    { command.y1 :=   end[2]; command.y2 := start[2]; } 
   else 
    { command.y1 := start[2]; command.y2 :=   end[2]; }

   if (command.x1<state.last.x1) command.x1 := state.last.x1
   if (command.y1<state.last.y1) command.y1 := state.last.y1
   if (command.x2>state.last.x2) command.x2 := state.last.x2
   if (command.y2>state.last.y2) command.y2 := state.last.y2
   if ((command.x2<state.last.x1) || (command.x1>state.last.x2) ||
       (command.y2<state.last.y1) || (command.y1>state.last.y2))
       return T;
       
  
   for (i in 1:private.count)
    {
    # values from the swin/env command to be updated
    ox1 := state.current.x1[i]
    ox2 := state.current.x2[i]
    oy1 := state.current.y1[i]
    oy2 := state.current.y2[i]
    #values from the last call to swin/env
    lx1 := state.last.x1
    lx2 := state.last.x2
    ly1 := state.last.y1
    ly2 := state.last.y2
    #new values read by the zoom box, in units of the last swin/env
    cx1 := command.x1
    cx2 := command.x2
    cy1 := command.y1
    cy2 := command.y2
    cmd.x1[i] := (cx1-lx1)/(lx2-lx1)*(ox2-ox1)+ox1
    cmd.x2[i] := (cx2-lx1)/(lx2-lx1)*(ox2-ox1)+ox1
    cmd.y1[i] := (cy1-ly1)/(ly2-ly1)*(oy2-oy1)+oy1
    cmd.y2[i] := (cy2-ly1)/(ly2-ly1)*(oy2-oy1)+oy1
    state.current.x1[i] := cmd.x1[i]
    state.current.x2[i] := cmd.x2[i]
    state.current.y1[i] := cmd.y1[i]
    state.current.y2[i] := cmd.y2[i]
    }
   state.last.x1 := cmd.x1[private.count]
   state.last.x2 := cmd.x2[private.count]
   state.last.y1 := cmd.y1[private.count]
   state.last.y2 := cmd.y2[private.count]
   for (i in (1:private.count))
    {
    command._method := state.original._method[i]
    if (command._method == 'swin')
     {
     command.x1 := cmd.x1[i]
     command.x2 := cmd.x2[i]
     command.y1 := cmd.y1[i]
     command.y2 := cmd.y2[i]
     command.xmin := command.xmax := command.ymin := command.ymax := 0
     command.axis := command.just := 0
     }
    else if (command._method == 'env')
     {
     command.xmin := cmd.x1[i]
     command.xmax := cmd.x2[i]
     command.ymin := cmd.y1[i]
     command.ymax := cmd.y2[i]
     command.axis := cmd.axis[i]
     command.just := cmd.just[i]
     command.x1 := command.x2 := command.y1 := command.y2 := 0
     }
    else
     return throw ('Error in pgplotter_standard!')
    plotter.displaylist().set(state.where[i], command);
    }
   plotter.refresh();
  }

  state.n1 := plotter.setcallback('button', buttondown_callback);
  state.n2 := plotter.setcallback('buttonup', buttonup_callback);
  return T;
 }
 
 zoom_suspend := function(ref f, ref plotter, ref state)
 {
  # Clear message
  old := plotter.record(F);
  plotter.message('');
  plotter.record(old);

  # Just return if we have no n1/n2 fields - assume that the start
  # command failed.

  if (!has_field(state, 'n1'))
   return F;

  plotter.deactivatecallback(state.n1);
  plotter.deactivatecallback(state.n2);
  return T;
 }

    line_start := function(ref f, ref plotter, ref state)
    {
	msg := 'View spectral lines from JPL line list in band';
	command := [=];
	where := 0;
	aipsroot:=sysinfo().root();
	thedir:='/data/catalogs/lines/jpl';
	pathname:=spaste(aipsroot,thedir,'');
	linelist:=table(pathname);

	if (length(state) == 0) {
	   state.lastwhere := 0;
	   old := plotter.record(F);
	   state.message := message(f,msg);
	   plotter.record(old);
	   state.linesbutton:=button(f,'Plot JPL lines');
		
	   whenever state.linesbutton->press do {
	     #find dish tool
	     if (is_defined('tm')) {
                currtools:=tm.tools();
                for (i in 1:len(currtools)) {
                    currtypes[i] := currtools[i].type;
                }
                if (any(currtypes=='dish')) {
	           dishname:=field_names(currtools)[currtypes=='dish'][1];
	        }
	     }
	     dishname:=symbol_value(dishname);
	     currentdat:=dishname.rm().getlastviewed();
	     arrlen:=currentdat.value.data.arr::shape[2];
	     newfreqs:=[=];
	     rf:=dq.quantity(currentdat.value.data.desc.restfrequency,'Hz');
	     myun:=currentdat.value.data.desc.chan_freq.unit;
	     if (myun=="m.s-1") {
		for (i in 1:currentdat.value.data.arr::shape[2]) {
		    a:=dm.doppler('radio',
		    spaste(currentdat.value.data.desc.chan_freq.value[i],myun));
		    newfreqs[i]:=dm.tofrequency('lsrk',a,rf);
		} #end loop over data array
		xbegin:=dm.getvalue(newfreqs[1])[1].value;
		xend:=dm.getvalue(newfreqs[len(newfreqs)])[1].value;
	     } else {
		xbegin:=currentdat.value.data.desc.chan_freq.value[1];
		xend:=currentdat.value.data.desc.chan_freq.value[arrlen];
		newq:=dq.quantity(currentdat.value.data.desc.chan_freq.value[1],
		                  currentdat.value.data.desc.chan_freq.unit);
		newfreqs[1]:=dm.frequency('rest',newq);
	     } # end unit loop
	     if (xend<xbegin) {
		tmp:=xend;
		xend:=xbegin;
		xbegin:=tmp;
	     }
	     ybegin:=plotter.qwin()[3];
	     yend:=plotter.qwin()[4];
	     querystring:=spaste('Frequency > ',xbegin/1.E6,' && Frequency < ',
                                 xend/1.E6);
	     subt:=linelist.query(querystring);
	     mylen:=subt.nrows();
	     if (mylen>=1) {
	     if (myun=="m.s-1") {
		if (!is_fail(subt)) {
		   print querystring,is_fail(subt);
		   lines:=subt.getcol('Molecule');
		   trans:=subt.getcol('Transition');
		   freqs:=subt.getcol('Frequency');
		   for (i in 1:subt.nrows()) {
		       freqmeas:=newfreqs[1];
		       freqmeas.refer:='REST';
		       freqmeas.m0.value:=freqs[i]*1.E6;
		       freqdopp:=dm.todoppler('lsrk',freqmeas,rf);
		       velmeas:=dm.toradialvelocity('lsrk',freqdopp);
		       vel:=(dm.getvalue(velmeas)[1].value)+currentdat.value.other.sdfits.vframe;
		       plotter.sci(5);
		       plotter.sch(1.0);
		       plotter.move(vel,0.8*yend);
		       plotter.draw(vel,yend);
		       plotter.ptxt(vel,ybegin,90,0,lines[i]);
		   }
		} else {print 'No lines found'}# end is_fail(subt) if
	     } else {
                xbegin:=plotter.qwin()[1]/1.E6;
                xend:=plotter.qwin()[2]/1.E6;
                ybegin:=plotter.qwin()[3];
                yend:=plotter.qwin()[4];
                querystring:=spaste('Frequency > ',xbegin,' && Frequency < ',
                                    xend);
                subt:=linelist.query(querystring);
	        if (!is_fail(subt)) {

                   lines:=subt.getcol('Molecule');
                   trans:=subt.getcol('Transition');
                   freqs:=subt.getcol('Frequency');
# Signal Sideband
                   for (i in 1:subt.nrows()) {
                       plotter.sci(5);
                       plotter.sch(1.0);
                       plotter.move(freqs[i]*1.E6,0.8*yend);
                       plotter.draw(freqs[i]*1.E6,yend);
                       plotter.ptxt(freqs[i]*1.E6,ybegin,90,0,lines[i]);
                   }
		} else {print 'no lines found'}# end is_fail(subt) if
	     }# end if on units;
	     }# end if on subtable length

	     plotter.refresh();
	} # end whenever
	} #end on if state==0
        # OK, find the 'settings' call: should be first
        n := plotter.displaylist().ndrawlist();
        for (i in 1:n) {
          tmp := plotter.displaylist().get(i);
          if (is_record(tmp) && has_field(tmp, '_method')) {
            if (tmp._method == 'settings') {
              command := tmp;
              where := i;
              break;
            }
          }
        }
# end
        if (!where) {
            state.lastchange := 0; # Make sure we reinit next time
            return throw('pages - no \'settings\' command in drawlist!');
        }

        old := plotter.record(F);
        plotter.message(msg);
        plotter.record(old);

        if (where != state.lastwhere) {
            state.original := command;
            state.last := command;
            state.lastwhere := where;
        }

        return T;
    }

    line_suspend := function(ref f, ref plotter, ref state)
    {
        # Clear message
        old := plotter.record(F);
        plotter.message('');
        plotter.record(old);
	linelist:=F;

        return T;
    }


    pg.addtool('zoom', zoom_start, zoom_suspend);
    pg.addtool('lineid',line_start, line_suspend);

    return T;
}
