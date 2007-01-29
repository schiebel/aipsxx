# new array browser
#
#   Copyright (C) 1997,1998,1999,2000,2001
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
#   $Id: newab.g,v 19.1 2004/08/25 01:54:48 cvsmgr Exp $
#

pragma include once
include "guiframework.g"
include "infowindow.g"

_tmpab := [=];

newab := subsequence(ref showme, title='Array Browser', readonly=T,
                     display=F, plotter=F)
{
     # Initialization stuff
   if(!have_gui()){
      note('Arraybrowser only runs in a GUI enviorment');
      fail;
   }
   if(is_record(showme)){
      infowindow('Array browser only handles arrays!');
      fail;
   }
   global _tmpab;
     # check the array size
   tk_hold();
   priv := [=];
   priv.th := 20;
   priv.ptsPerChar := 12;
   priv.fn := '-adobe-courier-medium-r-normal--12-*';
   priv.warned := T;
   priv.display := display;
   priv.plotter := plotter;


   priv.setLimits := function(ref showme){
      wider priv;
      # print 'priv.setLimits';
      if(has_field(showme::, 'shape')){
        if(len(showme::shape) == 1){
          priv.cols := showme::shape;
          priv.rows := 1;
        } else {
           priv.rows := showme::shape[1];
           priv.cols := showme::shape[2];
        }
        priv.axes := showme::shape; 
      } else {
        priv.cols := len(showme);
        priv.rows := 1;
        priv.axes := len(showme); 
      }
   }  


   priv.showSliceFrame := function(){
      wider priv;
      if(priv.ad.sf.show){
         priv.ad.wf->map()
         priv.ad.sf.show := F;
      } else {
         priv.ad.wf->unmap()
         priv.ad.sf.show := T;
      }
   }

   priv.showGlishFrame := function(){
      wider priv;
      if(priv.ad.gf.show){
         priv.ad.gf->map()
         priv.ad.gf.show := F;
      } else {
         priv.ad.gf->unmap()
         priv.ad.gf.show := T;
      }
   }

   priv.init := function(ref showme){
      wider priv;
      global _tmpab;
      priv.setLimits(showme);
# Need a way to have multiple arrays so we don't clobber them

      if(!is_defined(_tmpab)){
        _tmpab := [=];
      }
      priv.aid := as_string(len(field_names(_tmpab)));
      _tmpab[priv.aid] := [=];
      _tmpab[priv.aid].showme := showme;
      # global this := ref showme;

      if(is_complex(showme)){
         priv.colwidth:=180;
      } else {
         priv.colwidth:=110;
      }

      frameWidth := priv.cols*priv.colwidth;
      if(frameWidth > 600){
         frameWidth := 600;
      }

      frameHeight := priv.rows*priv.th;
      if(frameHeight > 600){
         frameHeight := 600;
      } else {
         frameHeight := 1.1*frameHeight;
      }


      menus := [=];
      menus.file := [=];
      menus.file::text := 'File';
      menus.file::help :='Dismiss this window';
      menus.file.close := [=];
      menus.file.close.text := 'Done';
      menus.file.close.type := 'dismiss';
      menus.file.close.action := priv.dismiss;
 
      menus.options := [=]
      menus.options::text := 'Options';
      menus.options::help :='View Array Slice/Glish Command';

      menus.options.glishf := [=];
      menus.options.glishf.text := 'New glish variable/expression';
      menus.options.glishf.help := 'View another glish variable or expression';
      menus.options.glishf.type := 'check';
      menus.options.glishf.action := priv.showGlishFrame;

      menus.options.slicef := [=];
      menus.options.slicef.text := 'Slicer';
      menus.options.slicef.help := 'View another glish variable or expression';
      menus.options.slicef.type := 'check';
      menus.options.slicef.action := priv.showSliceFrame;

   
      menus.view := [=];
      menus.view::text := 'View';
      menus.view::help := 'Use a plotter or viewer';
      menus.view.display.text := 'in Default Display...';
      menus.view.display.action := function(){ wider showme; 
                                       wider priv;
                                       if(!(is_record(priv.display) &&
                                            has_field(priv.display, 'array'))){
                                            include "viewer.g"
                                            priv.display := dv;
                                       }
                                       priv.display.gui();
                                       vdps := priv.display.alldisplaypanels();
                                       mdd := priv.display.loaddata(showme, 'raster');
                                       vdps[1].register(mdd);
                                       }

      menus.view.plotcontour := [=];
      menus.view.plotcontour.text := 'PGplotter Contour...';
      menus.view.plotcontour.relief := 'flat';
      menus.view.plotcontour.action := function(){wider priv;
                                              include "pgplotter.g"
                                              if(is_boolean(priv.plotter))
                                                 priv.plotter := pgplotter();
                                              priv.plotter.gui();
                                              tmin := min(priv.plane);
                                              tmax := max(priv.plane);
                                              c := [1:5]*(tmax-tmin)/5;
                                              nc := 5
                                              tr := [0,1,0,0,0,1];
                                              priv.plotter.env(0, priv.rows, 0,
                                                              priv.cols, 0, 0);
                                              priv.plotter.cont(priv.plane, c,
                                                                nc, tr);
                                             }
      menus.view.plotraster := [=];
      menus.view.plotraster.text := 'PGplotter  Raster...';
      menus.view.plotraster.action := function(){wider priv;
                                             include "pgplotter.g"
                                             if(is_boolean(priv.plotter))
                                                priv.plotter := pgplotter();
                                              priv.plotter.gui();
                                              tmin := min(priv.plane);
                                              tmax := max(priv.plane);
                                              tr := [0,1,0,0,0,1];
                                              a := priv.plotter.qcol();
                                              priv.plotter.env(0, priv.rows, 0,
                                                              priv.cols, 0, 0);
                                              if(a[2] == 1)
                                                 priv.plotter.gray(priv.plane,
                                                               tmax, tmin, tr);
                                              else
                                                 priv.plotter.imag(priv.plane,
                                                               tmax, tmin, tr);
                                            }

      priv.helpmenu := function() {
         hmenu := [=];
         hmenu::useWidget := T;
         hmenu.help := [=];
         hmenu.help.text := 'Array Browser'
         hmenu.help.action := 'Refman:table.newab';
         return hmenu;
      }

      hmenu := priv.helpmenu();
      #
      priv.f := guiframework(title=title, menus=menus, helpmenu=hmenu,
                             actions=F);
      priv.viewHeight := priv.rows*priv.th;
      lastX := priv.rows*priv.colwidth;
      wf := priv.f.getworkframe();
      #

      priv.ad := [=];
      priv.ad.kf := dws.frame(wf, height=10, expand='x');
      priv.ad.wf := dws.frame(priv.ad.kf, side='left', expand='x');
      priv.ad.bf := dws.frame(priv.ad.wf, side='left', expand='x');
      priv.ad.b1 := dws.button(priv.ad.bf, text='view slice');

      priv.ad.gf := dws.frame(priv.ad.kf, side='left', expand='x');
      priv.ad.bg := dws.button(priv.ad.gf, text='glish command');
      priv.ad.eg := dws.entry(priv.ad.gf);

      priv.ad.help := [=];
      priv.ad.help.b1 := popuphelp(priv.ad.b1,
                              'View part of the array using a glish slice');

      priv.ad.help.eg := popuphelp(priv.ad.gf,
                              'Glish command or array variable name');

      priv.ad.wf->unmap();
      priv.ad.gf->unmap();
      priv.ad.gf.show := T;
      priv.sliceEntries();

      whenever priv.ad.b1->press do {
        priv.redraw();
      }

      whenever priv.ad.bg->press, priv.ad.eg->return do {
          cmd_line := priv.ad.eg->get('start', 'end');
          if(cmd_line ~ m/this/){
             _tmpab.this := ref showme;
             cmd_line := cmd_line ~ s/this/_tmpab.this/g;
          }
          dummy := eval(cmd_line);
          if(!is_fail(dummy)){
             if(len(dummy) > 1 && !is_record(dummy)){
                rdum := tk_hold();
                priv.doDisplay(dummy);
                rdum := tk_release();
             } else {
                iw := infowindow('Your glish command was not an array!');
             }
          } else {
             iw := infowindow('Your glish command failed!');
          }
      }


      #

      wfa := dws.frame(wf, side='left');
      wfb := dws.frame(wfa, side='top');
      tf := dws.frame(wfb, borderwidth=0, side='top', height=frameHeight,
                      width=frameWidth, expand='x');
      lf := dws.frame(tf, borderwidth=0, side='left', expand='x');
      lf1 := dws.frame(lf, borderwidth=0, side='left', expand='none',width=10);
      lf2 := dws.frame(lf, borderwidth=0, side='left', expand='x');
      rlc := dws.canvas(lf1, region=[0,0,10, priv.th], height=priv.th,
                        background='white', borderwidth=0, fill='none',
                        width=40);
      rlc->text(20, 0.5*priv.th, text='Row')
      priv.lc := dws.canvas(lf2, region=[0,0,lastX, priv.viewHeight],
                            height=priv.th, background='white', borderwidth=0,
                             fill='x');
   
      wf1 := dws.frame(wfb, borderwidth=0, side='left')
      rf := dws.frame(wf1, borderwidth=0, expand='y', width=40);
      priv.cf  := dws.frame(wf1, side='left', borderwidth=0);
      priv.rc := dws.canvas(rf, background='white',
                            region=[0,0,40, 10*priv.th],width=40,
                            borderwidth=0, relief='flat', fill='y',
                            height=2*priv.th);
      priv.c   := dws.canvas(priv.cf, background='white', borderwidth=0,
                             relief='flat',region=[0,0,lastX, 10*priv.th], 
                             height=frameHeight, width=frameWidth);
      priv.vsb := dws.scrollbar(wfa);
   
      priv.bf  := dws.frame(wf, side='right', borderwidth=0, expand='x');
      pad := dws.frame(priv.bf, expand='none', width=23, height=23,
                       relief='flat');
      priv.hsb := dws.scrollbar(priv.bf, orient='horizontal');
   
      priv.df := dws.frame(wf, side='right', expand='x');
      priv.dismiss := dws.button(priv.df, text='Dismiss', type='dismiss');

      whenever priv.dismiss->press do {
         priv.f.unmap();
      }

      whenever priv.vsb->scroll, priv.hsb->scroll do {
         priv.c->view($value);
         priv.rc->view($value);
         priv.lc->view($value);
      }
      whenever priv.c->yscroll do {
         priv.vsb->view($value);
         priv.rc->view($value);
      }
      whenever priv.c->xscroll do {
         priv.hsb->view($value);
         priv.lc->view($value);
      }
   }

   priv.sliceEntries := function(){
      # print 'priv.sliceEntries';
      wider priv;
      if(!has_field(priv.ad, 'e')){
         priv.ad.e := [=];
      } else {
         for(i in 1:len(priv.ad.e)){
            priv.ad.e[i] := F;
            priv.ad.help.e[i] := F;
         }
      }
      priv.ad.sf := F;
      priv.ad.sf := dws.frame(priv.ad.bf, side='left');
      priv.ad.sf.show := T;
      priv.slicetext := spaste('[1:',priv.axes[1]);
      for(i in 1:len(priv.axes)){
        priv.ad.e[i] := dws.entry(priv.ad.sf)
        priv.ad.help.e[i] := popuphelp(priv.ad.e[i],
                              'View part of the array using a glish slice');
        if(i == 1 || i == 2){
          priv.ad.e[i]->insert(spaste('1:',priv.axes[i]));
          if(i==2){
            priv.slicetext := spaste(priv.slicetext, ',1:', priv.axes[2]);
          }
        } else {
          priv.ad.e[i]->insert('1');
          priv.slicetext := spaste(priv.slicetext, ',1');
        }
        whenever priv.ad.e[i]->return do {
          priv.redraw()
        }
      }
      priv.slicetext := spaste(priv.slicetext, ']');
   }

   priv.dismiss := function(){ 
     wider priv;
     priv.f.unmap();
   }

   priv.cleanup := function(){
      global _tmpab;
      wider priv;
      priv.f.unmap();
      priv.f.dismiss();
      priv.ad := F;
      _tmpab[priv.aid].showme := F;
      _tmpab[priv.aid]        := F;
      priv := F;
   }

   priv.redraw := function() {
      wider priv;
      priv.f.busy(T);
      dum := spaste('_tmpab[\'',priv.aid,'\'].showme');
      slicetext := '[';
      if(len(priv.axes) > 1){
         for(i in 1:(len(priv.axes)-1)){
             slicetext := spaste(slicetext, priv.ad.e[i]->get(), ',');
         }
      }
      slicetext := spaste(slicetext, priv.ad.e[len(priv.axes)]->get(), ']');
      plane := eval(spaste(dum,slicetext));
      if(!is_fail(plane)){
         slicetext := priv.slicetext;
         priv.showplane(plane);
      }else{
         infowindow(spaste('Bad slice ', slicetext,
                    'requested. \n\nArray shape is ', priv.axes));
      }
      priv.f.busy(F);
   }


   priv.showarray := function(showme) {
      wider priv;
      # print 'priv.showarray';
      priv.f.busy(T);
      if(has_field(showme::, 'shape') && len(showme::shape) > 2){
         dum := spaste('_tmpab[\'',priv.aid,'\'].showme[,');
         for(i in 3:len(showme::shape)){
           dum := spaste(dum, ',1');
         }
         dum := spaste(dum, ']');
         plane := eval(dum);
      } else {
         plane := ref showme;
      }
      priv.showplane(plane);
      priv.f.updatestatus(paste('Array Shape:', priv.axes));
      priv.f.busy(F);
   }

   priv.showplane := function(ref plane) {
      wider priv;
      priv.plane := plane;
      if(has_field(plane::, 'shape')){
         rank := len(plane::shape);
         if(rank > 1){
           rows := plane::shape[1];
         } else {
           rows := plane::shape[1];
         }
      }else {
         rank := 1;
        rows := len(plane);
      }
      if(rank == 1){
         cols := rows;
         rows := 1;
      } else if(rank == 2){
         cols := plane::shape[2]
      } else {
         cols := plane::shape[2];
         infowindow('Can only display one plane n-dimensional array.');
         return;
      }
      priv.rows := rows;
      priv.cols := cols;
         # Calculate the column width based on the first column
      if(rows > 1){
        col1text := as_string(plane[1:rows, 1]);
      } else {
        col1text :=  as_string(plane[1]);
      }
      theWidth := 10+0.7*max(strlen(col1text))*priv.ptsPerChar;
      if(priv.colwidth < theWidth)
         priv.colwidth := theWidth;
      if(rows*cols > 1024*1024){
         infowindow(spaste('Can only display slices < ',1024*1024, ' elements.'));
         return;
      }
      priv.c->delete('all');
      priv.rc->delete('all');
      priv.lc->delete('all');
      x := 1:cols;
      x := x*priv.colwidth;
      newx := priv.colwidth*(cols+2);
      newy := priv.th*(rows+1);

      priv.c->region(0, 0, newx, newy);
      priv.lc->region(0, 0, newx, priv.th);
      priv.rc->region(0, 0, 40, newy);
      whys := [1:rows]*priv.th;
      collabel := as_string([1:rows]);
      priv.rc->text(20, whys, text=collabel, tag='row', anchor='e')
      for(i in 1:cols){
         priv.lc->text(x[i], 0.5*priv.th, text=as_string(i), tag='col', anchor='e');
         if(rows > 1){
               coltext := as_string(plane[1:rows, i]);
               priv.c->text(x[i], whys, text=coltext,
                            font=priv.fn, tag='cell', anchor='e');
         } else {
            priv.c->text(x[i], priv.th, text=as_string(plane[i]),
                         font=priv.fn, tag='cell', anchor='e');
         }
      }
   }

   priv.doDisplay := function(ref showme){
      wider priv;
      global _tmpab;
      # print 'priv.displayArray';
      _tmpab[priv.aid].showme := showme;
      priv.setLimits(showme);
      priv.sliceEntries();
      priv.showarray(showme);
   }

   priv.init(showme);
   priv.showarray(showme);
   rdum := tk_release();

     # Clean up
   whenever self->close do{
      priv.cleanup();
   }

   whenever priv.f.app.parent->killed do{
      priv.cleanup();
      deactivate;
   }

     # Reopen and display an array if one was sent.
   whenever self->gui, self->array, self->open do {
      if(!is_boolean(priv)){
         if(len($value) > 1 && !is_record($value)){
            rdum := tk_hold();
            priv.doDisplay($value);
            rdum := tk_release();
         }
         priv.f.map();
      } else {
         deactivate;
      }
   }
}

const arraybrowser := newab;
