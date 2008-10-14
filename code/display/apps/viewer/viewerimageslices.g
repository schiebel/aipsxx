# viewerimageslices.g: Viewer support for slices/distances
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: viewerimageslices.g
#
# Emits events:
#
#   Name              Value
#  slice             rec.ddname
#                    rec.slice
#

pragma include once

include 'clipboard.g'
include 'note.g'
include 'serverexists.g'
include 'unset.g'
include 'misc.g'
include 'measures.g';
include 'quanta.g';
#
include 'image.g'
include 'widgetserver.g'

const viewerimageslices := subsequence (parent, widgetset=dws)
{
    if (!serverexists('dcb', 'clipboard', dcb)) {
       return throw('The clipboard server "dcb" is not running',
                     origin='viewerimageslices.g');
    }
    if (!serverexists('dm', 'measures', dm)) {
       return throw('The measures server "dm" is not running',
                     origin='viewerimageslices.g');
    }
    if (!serverexists('dq', 'quanta', dq)) {
       return throw('The quanta server "dq" is not running',
                     origin='viewerimageslices.g');
    }
    if (!serverexists('dms', 'misc', dms)) {
       return throw('The misc server "dms" is not running',
                     origin='viewerimageslices.g');
    }
#
    its := [=];
    its.ws := widgetset;
#
    its.getImageTool := [=];               # Callback: Get Image tool from ddname 
    its.getDisplayAxes := [=];             # Callback: Get display axes
    its.getOtherPixels := [=];             # Callback: Get pixel coordinate of non-display axes
#
    its.td := [=];                         # Tab dialog
    its.tabs := [=];                       # The tabs, indexed by ddname
    its.tabnames := "";                    # The tab names (indexed by integer)
    its.ddnames := "";                     # DisplayData names
    its.index := [=];                      # Tabs index. Indexed by ddname
    its.active := [=];                     # Activity status, indexed by ddname
#
    its.imageTool := [=];                  # Image tool indexed by ddname
    its.refpix := [=];                     # Ref pix indexed by ddname
#
    its.displayAxes := [=];                # The display (first two) pixel axes indexed by ddname
    its.isDirection := [=];                # Are the display axes in a DC - indexed by ddname
    its.plotter := [=];                    # Plotter names, indexed by ddname
    its.unit := [=];                       # Brightness units indexed by ddname
    its.coord := [=];                      # Non-display axes coords indexed by ddname
#
    its.slice := [=];                      # Holds slice values, indexed by ddname
    its.distance := [=];                   # Holds distance values, indexed by ddname
    its.polyline := [=];                   # Last good polyline event value indexed by ddname
#


### Private methods


###
   const its.addOneTab := function (ddname)
   {
      wider its;

# Overwrite if name exists, else we get in big logic tangles.

      if (has_field(its.index, ddname)) {
         n := its.index[ddname];
      } else {
         n := length(its.tabnames) + 1;
      }
#  
      tabname := ddname;
      its.tabnames[n] := tabname;
      its.ddnames[n] := ddname;
      its.index[ddname] := n;

# Create TAB, indexed by string converted integer
# and add it to the tabdialog widget

      ok := its.makeTab(n, ddname, tabname);
      if (is_fail(ok)) fail;
#
      return ok;
   }

###
   const its.assembleEvent := function (ddname, slice, dist)
   {
      wider its;
#
      r := [ddname=ddname, slice=slice, distance=dist];
      return r;
   }


###
    const its.clearGui := function (ddname)
    {
       wider its;
#
       its.tabs[ddname].f1.f0.value->text('');
       its.tabs[ddname].f1.f1.value->text('');
#
       return T;
    }
    

###
    const its.computeDistance := function(polyline, ddname)
    {
        wider its;
#
        rec := [=];
        tmpsep := 0.0;
        tmpposang := 0.0;
        local sepunit,posunit;
        axes := its.displayAxes[ddname];
        for (i in 1:(len(polyline.linear.x)-1)) {
            px1 := polyline.linear.x[i];
            px2 := polyline.linear.x[i+1];
            py1 := polyline.linear.y[i];
            py2 := polyline.linear.y[i+1];
#
            linp1 := its.refpix[ddname];
            linp1[axes[1]] := px1;
            linp1[axes[2]] := py1;
            linp2 := its.refpix[ddname];
            linp2[axes[1]] := px2;
            linp2[axes[2]] := py2;
            w1 := its.imageTool[ddname].toworld(linp1, 'm');
            if (is_fail(w1)) fail;
            w2 := its.imageTool[ddname].toworld(linp2, 'm');
            if (is_fail(w2)) fail;
            q := dm.separation(w1.direction, w2.direction);
            if (is_fail(q)) fail;
#
            tmpsep +:= dq.getvalue(q);
            sepunit := dq.getunit(q);
            q := dm.posangle(w1.direction, w2.direction);
            if (is_fail(q)) fail;
#
            tmpposang +:= dq.getvalue(q);
            posunit := dq.getunit(q);
        }
        rec.separation := dq.quantity(tmpsep,sepunit);
        rec.positionangle := dq.quantity(tmpposang,posunit);
#
        return rec;
    }       

###
    const its.displayIsDirection := function (ddname, cs)
    {
       wider its;
#
       local c1, c2, ac1, ac2;
       ok := cs.findaxis(c1, ac1, F, its.displayAxes[ddname][1]);
       if (is_fail(ok)) fail;
       ok := cs.findaxis(c2, ac2, F, its.displayAxes[ddname][2]);
       if (is_fail(ok)) fail;
       t1 := cs.coordinatetype(c1);
       if (is_fail(t1)) fail;
       t2 := cs.coordinatetype(c2);
       if (is_fail(t2)) fail;
#
       return (t1==t2 && t1=='Direction');
    }

###
    const its.makeTab := function (idx, ddname, tabname)
    {
       wider its;
       its.ws.tk_hold();
#
       its.tabs[ddname] := its.ws.frame(its.tdf, side='top', relief='raised');
#
# Buttons
#
       its.tabs[ddname].f0a := its.ws.frame(its.tabs[ddname], side='left');
       its.tabs[ddname].f0a.plot := its.ws.button(its.tabs[ddname].f0a, type='action', text='plot');
       its.ws.popuphelp(its.tabs[ddname].f0a.plot, 'Plot last polyline slice');
       its.tabs[ddname].f0a.autoplot := its.ws.button(its.tabs[ddname].f0a, type='check', text='Auto-plot', width=9);
       txt := spaste('When unchecked push the plot button to plot polyline slice');
       its.ws.popuphelp(its.tabs[ddname].f0a.autoplot, txt, 'Always plot polyline slice', combi=T, width=80);
#
       its.tabs[ddname].f0 := its.ws.frame(its.tabs[ddname], side='left');
       its.tabs[ddname].f0.copy := its.ws.button(its.tabs[ddname].f0, type='action', text='copy');
       its.ws.popuphelp(its.tabs[ddname].f0.copy, 'Copy polyline slice to clipboard');
       its.tabs[ddname].f0.autocopy := its.ws.button(its.tabs[ddname].f0, type='check', text='Auto-copy');
       its.ws.popuphelp(its.tabs[ddname].f0.autocopy, 
                        'Always copy polyline slice to clipboard when slice generated');
#
# Autocopy state
#
       whenever its.tabs[ddname].f0.autocopy->press do {
          ddname := its.td.which().name;  
          if (its.tabs[ddname].f0.autocopy->state()) {
             its.tabs[ddname].f0.copy->disabled(T);
          } else {
             its.tabs[ddname].f0.copy->disabled(F); 
          } 
       }
#
# Copy slice to clipboard
#
       whenever its.tabs[ddname].f0.copy->press do {
          ddname := its.td.which().name;  
          rec := its.assembleEvent (ddname, its.slice[ddname], its.distance[ddname]);
          dcb.copy(rec);
       }
# 
# Autoplot state
#
       whenever its.tabs[ddname].f0a.autoplot->press do {
          ddname := its.td.which().name;  
          if (its.tabs[ddname].f0a.autoplot->state()) {
             its.tabs[ddname].f0a.plot->disabled(T);
          } else {
             its.tabs[ddname].f0a.plot->disabled(F);
          }
       }
#
# Plot slice
#
       whenever its.tabs[ddname].f0a.plot->press do {
          ddname := its.td.which().name;  
#
          its.tabs[ddname]->disable();
          state := its.tabs[ddname].f0a.autoplot->state();
          its.tabs[ddname].f0a.plot->disabled(T);
          ok := its.plotSlice (ddname);
          if (is_fail(ok)) {
             note ('WARN', ok::message, origin='viewerimageslices.makeTab');
          }
          if (state) {
             its.tabs[ddname].f0a.plot->disabled(T);
          } else {
             its.tabs[ddname].f0a.plot->disabled(F);
          }
          its.tabs[ddname]->enable();
       }
#
# Interpolation type
#
       its.tabs[ddname].f0b := its.ws.frame(its.tabs[ddname], side='left', expand='none');
       its.tabs[ddname].f0b.label := its.ws.label(its.tabs[ddname].f0b, text='Interpolation Method');
       its.ws.popuphelp(its.tabs[ddname].f0b.label, 'Select the interpolation method for the slice');
       methods := "NEAREST LINEAR CUBIC";
       its.tabs[ddname].f0b.method := its.ws.optionmenu(its.tabs[ddname].f0b, labels=methods);
#
       whenever its.tabs[ddname].f0b.method->select do {
          ddname := its.td.which().name;  
          its.redoAll(ddname);
       }
#
# Distance results
#
       its.tabs[ddname].f1 := its.ws.frame(its.tabs[ddname], side='top', expand='none');
       its.tabs[ddname].f1.f0 := its.ws.frame(its.tabs[ddname].f1, side='left');
       its.tabs[ddname].f1.f0.label := its.ws.label(its.tabs[ddname].f1.f0, text='Distance  : ');
       txt := 'This field is only active for DirectionCoordinate planes';
       its.ws.popuphelp(its.tabs[ddname].f1.f0.label, txt, 'This field displays the sum of angular distances over all line segments', 
                        combi=T, width=80);
#
       its.tabs[ddname].f1.f0.value := its.ws.label(its.tabs[ddname].f1.f0, text='', width=10);       
       units := "deg arcmin arcsec mas rad";
       its.tabs[ddname].f1.f0.unit := its.ws.optionmenu(its.tabs[ddname].f1.f0, labels=units);
       whenever its.tabs[ddname].f1.f0.unit->select do {
          ddname := its.td.which().name;  
          u := $value.value;
          q := dq.convert(its.distance[ddname].separation,u);  
          its.tabs[ddname].f1.f0.value->text(sprintf("%8.3e",dq.getvalue(q))); 
       }
#
       its.tabs[ddname].f1.f1 := its.ws.frame(its.tabs[ddname].f1, side='left');
       its.tabs[ddname].f1.f1.label := its.ws.label(its.tabs[ddname].f1.f1, text='Pos. Ang. : ');
       txt := spaste('It is measured positive North->East \n',
                     'If the polyline tool has more than two points the \n',
                     'sum over all position angles is shown. \n',
                     'This field is only active for DirectionCoordinate planes');
       its.ws.popuphelp(its.tabs[ddname].f1.f1.label, txt, 'This field displays the position angle between polyline vertices',
                        combi=T, width=80);
       its.tabs[ddname].f1.f1.value := its.ws.label(its.tabs[ddname].f1.f1, text='', width=10);       
       units := "deg arcmin rad";
       its.tabs[ddname].f1.f1.unit := its.ws.optionmenu(its.tabs[ddname].f1.f1, labels=units);
       whenever its.tabs[ddname].f1.f1.unit->select do {
          ddname := its.td.which().name;  
          u := $value.value;
          q := dq.convert(its.distance[ddname].positionangle, u);  
          its.tabs[ddname].f1.f1.value->text(sprintf("%8.3e",dq.getvalue(q))); 
       }

# Add new TAB to the tabdialog widget

      ok := its.td.add(its.tabs[ddname], tabname);
      if (is_fail(ok)) fail;
      if (length(its.td.list())==1)  its.td.front(tabname);
#
      its.ws.tk_release();
#
      return T;
    }

###      
   const its.plotSlice := function (ddname)
   {   
      wider its;  
         
# Make plotter

      makeNew := F;
      if (!has_field(its.plotter, ddname)) {
         makeNew := T;
      } else {
         if (!has_field(its.plotter[ddname], 'gui')) makeNew := T;
      }
      if (makeNew) {
         include 'pgplotter.g';
         its.plotter[ddname] := pgplotter();
      }
#
      rec := its.slice[ddname];
      yLab := spaste('Intensity (', 
                     its.imageTool[ddname].brightnessunit(), 
                     ')');
#
      coord := its.coord[ddname];
      local tLab;
      const n := length(coord);
      if (n > 2) {
        tLab := spaste ('Slice from ', ddname, ' at pixel ', coord[3:n]);
      } else {
        tLab := spaste ('Slice from ', ddname);
      }
      pixels := rec.pixels[rec.mask==T];
      distance := rec.distance[rec.mask==T];
      ok := its.plotter[ddname].plotxy (distance, pixels, T, T, 
                                        'Distance (pixels)', yLab, tLab);
#
      return ok;
   }

###
   const its.redoAll := function (ddname)
   {
      wider its;

# Redo everything; slice/distance-gui/record/clipboard/plot

      method := its.tabs[ddname].f0b.method.getlabel();
      its.slice[ddname] := 
               its.imageTool[ddname].getslice(x=its.polyline[ddname].linear.x, 
                                              y=its.polyline[ddname].linear.y, 
                                              axes=its.displayAxes[ddname], 
                                              coord=its.coord[ddname], 
                                              method=method,
                                              plot=F);
#
      if (its.isDirection[ddname]) {
         its.distance[ddname] := its.computeDistance(polyline, ddname);
         its.writeGui (ddname, its.distance[ddname], its.slice[ddname]);
      }
      rec := its.assembleEvent (ddname, its.slice[ddname], its.distance[ddname]);
      if (its.tabs[ddname].f0.autocopy->state()) dcb.copy(rec);
      if (its.tabs[ddname].f0a.autoplot->state()) its.plotSlice (ddname);
      self->slice(rec);
      return T;
   }
 

###
    const its.writeGui := function (ddname, dist, slice)
    {
       its.ws.tk_hold();
       its.clearGui (ddname);

# Distance

       u := its.tabs[ddname].f1.f0.unit.getlabel();
       q := dq.convert(dist.separation, u);
       if (is_fail(q)) fail;
       its.tabs[ddname].f1.f0.value->text(sprintf("%8.3e",dq.getvalue(q))); 

# Position Angle

       u := its.tabs[ddname].f1.f1.unit.getlabel();
       q := dq.convert(dist.positionangle, u);
       if (is_fail(q)) fail;
       its.tabs[ddname].f1.f1.value->text(sprintf("%8.3e",dq.getvalue(q))); 
#
       its.ws.tk_release();
       return T;
    }


### Public methods

###
    const self.add := function (ddname) 
    {
       wider its;
#     
       if (has_field(its.index, ddname) && its.active[ddname]) {
          return throw (spaste('Entry ', ddname, ' is already active'),
                        origin='viewerimageslices.add');
       }
#
       ok := its.addOneTab(ddname); 
       if (is_fail(ok)) fail;
       its.active[ddname] := T;

# Store display axes (won't change often)

       rr := its.getDisplayAxes(ddname);
       its.displayAxes[ddname] := [rr.xPixelAxis, rr.yPixelAxis];

# Store image tool (reference; don't destroy)

       its.imageTool[ddname] := its.getImageTool(ddname);

# Store reference pixel

       cs := its.imageTool[ddname].coordsys();
       if (is_fail(cs)) fail;
       its.refpix[ddname] := cs.referencepixel();

# See if display axes hold DirectionCoordinate

       its.isDirection[ddname] := its.displayIsDirection (ddname, cs);
       if (!its.isDirection[ddname]) {
          its.clearGui (ddname);
          its.distance[ddname] := [=];
          its.tabs[ddname].f1.f0.unit.disabled(T);
          its.tabs[ddname].f1.f1.unit.disabled(T);
       }
       cs.done();
#
       return T;
    }

###
    const self.delete := function (ddname) 
    {
       wider its;
#
       if (has_field(its.active, ddname) && !its.active[ddname]) {
          return throw (spaste('Entry ', ddname, ' is not active'),
                        origin='viewerimageslices.delete');   
       }
#
       idx := its.index[ddname];
       tabname := its.tabnames[idx];
       ok := its.td.delete(tabname); 
       if (is_fail(ok)) fail;
#
       its.tabs[ddname] := F;
       its.active[ddname] := F;
#
       return T;
    }


###
    const self.done := function () 
    {
       wider its, self;
#
       ok := its.td.done();
#
       for (ddname in its.ddnames) {
          if (its.active[ddname]) {
             if (has_field(its.plotter, ddname) &&
                 has_field(its.plotter[ddname], 'gui')) {
                ok := its.plotter[ddname].done();
             }
          }
       }
#
       val its := F;
       val self := F;
#
       return T;
    }

###
   self.insertpolyline := function (polyline, true=F)
   {
      wider its;

# Distribute over DDs

      for (ddname in its.ddnames) {
         if (its.active[ddname]) {
            its.tabs[ddname]->disable();

# Get Image tool (reference)

            if (is_fail(im)) {
               its.tabs[ddname]->enable();
               fail;
            }

# Find pixel coordinate for non-display axes

           its.coord[ddname] := its.getOtherPixels (ddname);
           if (is_fail(its.coord[ddname])) fail;

# Generate slice
           
            if (length(polyline.linear.x)>1) {
               its.polyline[ddname] := polyline;
               method := its.tabs[ddname].f0b.method.getlabel();
               its.slice[ddname] := 
                  its.imageTool[ddname].getslice(x=its.polyline[ddname].linear.x, 
                                                 y=its.polyline[ddname].linear.y, 
                                                 axes=its.displayAxes[ddname], 
                                                 coord=its.coord[ddname], 
                                                 method=method,
                                                 plot=F);
               if (is_fail(its.slice[ddname])) {
                  its.tabs[ddname]->enable();
                  fail;
               }
            } else {
               its.tabs[ddname]->enable();
               note ('WARN', 'Slice must have at least two vertices', 
                     origin='viewerimageslices.insertpolyline');
               return T;
            }

# Compute distance information and write to GUI

            if (its.isDirection[ddname]) {
               its.distance[ddname] := its.computeDistance(polyline, ddname);
               if (is_fail(its.distance[ddname])) fail;
               ok := its.writeGui (ddname, its.distance[ddname], its.slice[ddname]);
            } else {
               its.distance[ddname] := [=];
            }

# Assemble event record

            rec := its.assembleEvent (ddname, its.slice[ddname], its.distance[ddname]);

# Clipboard

            if (its.tabs[ddname].f0.autocopy->state()) {
               dcb.copy(rec);
            }

# Plot

            if (its.tabs[ddname].f0a.autoplot->state()) {
              ok := its.plotSlice (ddname);
              if (is_fail(ok)) {
                 its.tabs[ddname]->enable();
                 fail;
              }
            }

# Event

            self->slice(rec);
            its.tabs[ddname]->enable();
         }
      }
   }

###
   const self.setcallbacks := function (callback1=unset, callback2=unset,
                                        callback3=unset)
#
# The idea is to get viewerimageanalysis to do as much of the
# work as possible, and keept viewerimageslices down largely
# to an interface layer.  So we use callbacks, inserted by viewerimageanalysis
# to do the work for us.
#
   {
      wider its;

# Arg. ddname, returns image Tool

      if (is_function(callback1)) {
         its.getImageTool := callback1;
      } else {
         if (!is_unset(callback1)) {
            return throw ('callback1 is not a function',
                           origin='viewerimageslices.setcallbacks');
         }
      }

# Arg. ddname, returnd display axes

      if (is_function(callback2)) {
         its.getDisplayAxes := callback2;
      } else {
         if (!is_unset(callback2)) {
            return throw ('callback2 is not a function',
                           origin='viewerimageslices.setcallbacks');
         }
      }

# Arg. ddname, returns non-display axes pixel coordinate

      if (is_function(callback3)) {f
         its.getOtherPixels := callback3;
      } else {
         if (!is_unset(callback3)) {
            return throw ('callback3 is not a function',
                           origin='viewerimageslices.setcallbacks');
         }
      }
#
      return T;
   }

###

   const self.update := function (ddname) 
   {
      wider its;
#
      if (has_field(its.active, ddname) && !its.active[ddname]) {
         return throw (spaste('Entry ', ddname, ' is not active'),
                       origin='viewerimageslices.update');
      }

# Update display axes

      rr := its.getDisplayAxes(ddname);
      its.displayAxes[ddname] := [rr.xPixelAxis, rr.yPixelAxis];
#
      cs := its.imageTool[ddname].coordsys();
      its.isDirection[ddname] := its.displayIsDirection (ddname, cs);
      if (!its.isDirection[ddname]) {
         its.clearGui (ddname);
         its.distance[ddname] := [=];
         its.tabs[ddname].f1.f0.unit.disabled(T);
         its.tabs[ddname].f1.f1.unit.disabled(T);
      } else {
         its.tabs[ddname].f1.f0.unit.disabled(F);
         its.tabs[ddname].f1.f1.unit.disabled(F);
      }
      cs.done();
#
      return T;
   }

### Constructor


# Tab dialog 

   its.td := its.ws.tabdialog(parent, colmax=3, title=unset);
   if (is_fail(its.td)) fail;

# Frame to put all the TABS in

   its.tdf := its.td.dialogframe();
   if (is_fail(its.tdf)) fail;
}
