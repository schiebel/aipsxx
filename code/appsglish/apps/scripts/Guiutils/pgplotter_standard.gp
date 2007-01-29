# pgplotter_standard.gp: Standard plugins for pgplotter
#
#   Copyright (C) 1998,2000,2002,2003
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
#   $Id: pgplotter_standard.gp,v 19.3 2004/08/25 02:00:39 cvsmgr Exp $
#


pragma include once;
include 'types.g'
note('pgplotter_standard plugin included');

## We should probably make the following globally advertised at some point.
colormaps := function()
{
    public := pvt := [=];
    pvt.maps := [=];


    public.addmap := function(name, l, r, g, b) {
        wider pvt;
        if (!is_string(name) || length(name) != 1) {
            return throw('colormaps.addmap - name must be a scalar string');
        }
        if (!is_numeric(l) || !is_numeric(r) || !is_numeric(g) ||
            !is_numeric(b) || length(l) != length(r) ||
            length(r) != length(g) || length(g) != length(b) || length(l)<2) {
            return throw(spaste('colormaps.addmap - l,r,g,b must be ',
                                ' same-length numeric arrays (length>1)'));
        }
        if (any(r<0) || any(g<0) || any(b<0) ||
            any(r>1) || any(g>1) || any(b>1)) {
            return throw(spaste('colormaps.addmap - r,g,b must all ',
                                'be >=0.0 and <=1.0'));
        }
        if (has_field(pvt.maps, name)) {
            return throw(spaste('colormaps.addmap - colormap named ', name,
                                ' has already been defined!'));
        }
        pvt.maps[name] := [l=l, r=r, g=g, b=b];
    }

    public.getmap := function(name) {
        if (!is_string(name) || length(name) != 1) {
            return throw('colormaps.getmap - name must be a scalar string');
        }
        if (!has_field(pvt.maps, name)) {
            return throw(spaste('colormaps.getmap - colormap named ', name,
                                ' has not been defined!'));
        }
        return pvt.maps[name];
    }

    public.mapnames := function() {
        wider pvt;
        return field_names(pvt.maps);
    }

    # Add some standard colormaps
    public.addmap('Gray', l=[0,1], r=[0,1], g=[0,1], b=[0,1]);
    public.addmap('Rainbow',
                  l=[-0.5, 0.0, 0.17, 0.33, 0.50, 0.67, 0.83, 1.0, 1.7],
                  r=[0.0, 0.0,  0.0,  0.0,  0.6,  1.0,  1.0, 1.0, 1.0],
                  g=[0.0, 0.0,  0.0,  1.0,  1.0,  1.0,  0.6, 0.0, 1.0],
                  b=[0.0, 0.3,  0.8,  1.0,  0.3,  0.0,  0.0, 0.0, 1.0]);
    public.addmap('Heat',
                  l=[0.0, 0.2, 0.4, 0.6, 1.0],
                  r=[0.0, 0.5, 1.0, 1.0, 1.0],
                  g=[0.0, 0.0, 0.5, 1.0, 1.0],
                  b=[0.0, 0.0, 0.0, 0.3, 1.0]);
    public.addmap('AIPS',
                  l=[0.0, 0.1, 0.1, 0.2, 0.2, 0.3, 0.3, 0.4, 0.4, 0.5,
                     0.5, 0.6, 0.6, 0.7, 0.7, 0.8, 0.8, 0.9, 0.9, 1.0],
                  r=[0.0, 0.0, 0.3, 0.3, 0.5, 0.5, 0.0, 0.0, 0.0, 0.0,
                     0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
                  g=[0.0, 0.0, 0.3, 0.3, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8,
                     0.6, 0.6, 1.0, 1.0, 1.0, 1.0, 0.8, 0.8, 0.0, 0.0],
                  b=[0.0, 0.0, 0.3, 0.3, 0.7, 0.7, 0.7, 0.7, 0.9, 0.9,
                     0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]);
    public.addmap('IRAF',
                  l=[0.0, 0.5, 0.5, 0.7, 0.7, 0.85, 0.85, 0.95, 0.95, 1.0],
                  r=[0.0, 1.0, 0.0, 0.0, 0.3,  0.8,  0.3,  1.0,  1.0, 1.0],
                  g=[0.0, 0.5, 0.4, 1.0, 0.0,  0.0,  0.2,  0.7,  1.0, 1.0],
                  b=[0.0, 0.0, 0.0, 0.0, 0.4,  1.0,  0.0,  0.0, 0.95, 1.0]);

    return ref public;
}

colormaps := colormaps();
pgplotter_standard := [=];
pgplotter_standard.attach := function(ref pg)
{
 private := [=];
 
 cursor_start := function(ref f, ref plotter, ref state) {
  wider private;
  state.msg := message(f,'Cursor Setting Tool')
  state.button1 := button(f, 'Crosshair');
  whenever state.button1->press do
    plotter.cursor('cross')
  state.button2 := button(f, 'Normal');
  whenever state.button2->press do
   plotter.cursor('norm')
  return T
 }
 
 cursor_suspend := function(ref f, ref plotter, ref state) {
  return T
 }

    colormap_start := function(ref f, ref plotter, ref pvt)
    {
        msg :=  'Choose a colormap, then drag cursor for brightness/contrast';
        old := plotter.record(F);
        plotter.message(msg);
        plotter.record(old);

        if (length(pvt) == 0) init := T; else init := F;

        # OK, first find the last 'ctab' call, if any
        n := plotter.displaylist().ndrawlist();
        where := 0;
        command := [=];
        for (i in n:1) {
            tmp := plotter.displaylist().get(i);
            if (is_record(tmp) && has_field(tmp, '_method') &&
                tmp._method == 'ctab') { #
                command := tmp;
                original := command;
                where := i;
            }
        }

        if (!where) {
            return throw('Error in colormap - no \'ctab\' command found.  The \
colormap tool is used for modifying colors in \'ctab\', which is generally \
used with images.  To modify colors on a line plot or scatter plot, use  \
the \'Edit\' menu option and alter the color indices in the \'sci\' entries.');
        }

        pvt.update := function(l, r, g, b, contrast=1, bright=0.5) {
            old := plotter.record(F);
            plotter.ctab(l, r, g, b, contrast, bright);
            plotter.record(old);
        }

        if (init) {
            names := colormaps.mapnames();
            names := ['Original', names];

            pvt.original := original;
            pvt.frame := frame(f, side='top');
            pvt.mapbutton := button(pvt.frame, names[1], type='menu');
            pvt.mapbutton.name := names[1];
            pvt.mapmenu := [=];
            pvt.contrast := pvt.original.contra;
            pvt.bright := pvt.original.bright;
            pvt.l := original.l;
            pvt.r := original.r;
            pvt.g := original.g;
            pvt.b := original.b;
            for (name in names) {
                pvt.mapmenu[name] := button(pvt.mapbutton, name);
                pvt.mapmenu[name].name := name;
                if (name == 'Original') {
                    pvt.mapmenu[name].map := [l=pvt.original.l,
                                                  r=pvt.original.r,
                                                  g=pvt.original.g,
                                                  b=pvt.original.b];
                } else {
                    pvt.mapmenu[name].map := colormaps.getmap(name);
                }
                whenever pvt.mapmenu[name]->press do {
                    wider pvt;
                    local myname := $agent.name;
                    pvt.l := $agent.map.l;
                    pvt.r := $agent.map.r;
                    pvt.g := $agent.map.g;
                    pvt.b := $agent.map.b;
                    pvt.mapbutton->text(myname);
                    pvt.mapbutton.name := myname;
                    pvt.update(pvt.l, pvt.r, pvt.g,
                                   pvt.b, pvt.contrast,
                                   pvt.bright);
                }
            }

        }

        pvt.follow := F;
        pvt.size := plotter.size()*1.0;
        motion_callback := function(rec) {
            wider pvt;
            if (pvt.follow) {
                x := rec.device[1];
                y := rec.device[2];
                pvt.bright := 1.0*(pvt.size[1]-x)/pvt.size[1];
                pvt.contrast := 0.2 + 5*(pvt.size[2]-y)/pvt.size[2];
                pvt.contrast;
                pvt.update(pvt.l, pvt.r, pvt.g,
                               pvt.b, pvt.contrast,
                               pvt.bright);
            }
        }
        down_callback := function(rec) {
            wider pvt;
            pvt.follow := T;
            plotter.cursor('cross');
        }
        up_callback := function(rec) {
            wider pvt;
            pvt.follow := F;
            plotter.cursor('norm');
        }
        pvt.call1 := plotter.setcallback('motion', motion_callback);
        pvt.call2 := plotter.setcallback('button', down_callback);
        pvt.call3 := plotter.setcallback('buttonup', up_callback);



        return T;
    }

    colormap_suspend := function(ref f, ref plotter, ref pvt)
    {
        # Remove message
        old := plotter.record(F);
        plotter.message('');
        plotter.record(old);

        if (!has_field(pvt, 'cal1')) {
            # The start probably failed
            return F;
        }

        plotter.deactivatecallback(pvt.call1);
        plotter.deactivatecallback(pvt.call2);
        plotter.deactivatecallback(pvt.call3);

        # OK, first find the last 'ctab' call, if any
        n := plotter.displaylist().ndrawlist();
        where := 0;
        command := [=];
        for (i in n:1) {
            tmp := plotter.displaylist().get(i);
            if (is_record(tmp) && has_field(tmp, '_method') &&
                tmp._method == 'ctab') { #
                command := tmp;
                original := command;
                where := i;
            }
        }
        # OK, put the current colormap back
        command.l := pvt.l;
        command.r := pvt.r;
        command.g := pvt.g;
        command.b := pvt.b;
        command.bright := pvt.bright;
        command.contra := pvt.contrast;
        plotter.displaylist().set(where, command);

        return T;
    }


 pg.addtool('cursor', cursor_start, cursor_suspend);
 pg.addtool('colormap', colormap_start, colormap_suspend);

 return T;
}
