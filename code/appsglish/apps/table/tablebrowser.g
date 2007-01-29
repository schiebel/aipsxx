#   the table browser
#
#   Copyright (C) 1997,1998,1999,2000,2001,2002,2003
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
#   675 Massachusetts Ave, Cambridge, MA 02139, 
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: tablebrowser.g,v 19.3 2005/11/23 10:52:07 gvandiep Exp $
#

pragma include once

include "widgetserver.g"
include "guiframework.g"
include "inputframe.g"
include "table.g"
include "newab.g"
include "pgplotter.g"
include "progress.g"
include "combobox.g"
include "measures.g"
include "note.g"
include "popuphelp.g"
include "choicewindow.g"
include "infowindow.g"

tablebrowser := subsequence(tabHandle=F, readonly=T, rows2read=100, tbnote=note,
                     plotter=F, parentTable=F, show=T, hide=T, ws=dws, closeTable=F,
                     debug=F) {  
   if(!have_gui()){
      tbnote('Tablebrowser only runs in a GUI enviorment');
      fail;
   }
   tk_hold();
      #
      # OK set a whole bunch of private variables
      #
#   tbnote('Test version');
   # t1 := time();
   ws.setmode('app');
   priv := [=];
   priv.debug := debug;
   priv.plotter := plotter;
   priv.rows2read := rows2read;
   priv.needsSaving := create_agent();
   priv.notSaved := F;
   priv.m := [=];
   priv.edit := !readonly;
   priv.rowCount := 0;
   priv.displayVector := 5;
   priv.cached := [=];
   priv.cached.start := 1;
   priv.cached.first := 1;
   priv.cached.last := 1;
   priv.note := tbnote;
   priv.isgtk := !(as_string(frame) ~m/create_graphic/);
   priv.table := F;
   priv.needsdisplay := F;
   priv.parentTable := parentTable;
   priv.col := [=];
   priv.changed := [=];
   priv.editCount := 0;
   priv.popups := [=];
   priv.popCount := 0;
   priv.lastRow := F;
   priv.lastCol := F;
   priv.closeTable := closeTable;
   priv.showComplexAs := 'apd';
   priv.format := '%.3f';
   priv.complexFormat := '%.3f@%.3f';
   priv.help := [=];   # popup helps
   priv.nowhys := T;
   priv.magicNumber := 2.4;  # Use this number to size canvases better
   priv.newlines := 0;
   if(is_boolean(hide))
      priv.hide := hide;
   else
      priv.hide := to_upper(hide);

   if(is_boolean(show))
      priv.show := show;
   else
      priv.show := to_upper(show);


   priv.rowsNcanvas := rows2read;
   if(rows2read < 0)
      priv.displayCache := -1;
   else
      priv.displayCache := rows2read;
   priv.handleScrollBar := F;

   whenever priv.needsSaving->returns do {
      if($value && priv.edit){
          priv.notSaved := T;
          priv.f.updatestatus(paste(priv.table.name(), 'needs saving'));
      } else {
          priv.notSaved := F;
          priv.f.updatestatus(paste(priv.table.name(), 'changes saved'));
      }
   }

   #
   # Function that toggles editing 
   #
priv.toggleEditFlag := function() {
   wider priv;
   priv.edit := !priv.edit;
   if(!is_boolean(priv.table)){
      myname := priv.table.name()
      priv.table.close(unmap=F);
      priv.table.open(myname, readonly=!priv.edit)
      priv.ed.e := 0;
      priv.ed.f := 0;
        #
        # Should log a table fail and try and recover
        #
   }
   priv.setmenubtns();
}


   #
   # Toggle the menu buttons as needed
   #
priv.setmenubtns := function(){
      #
      # Change the text, disable buttons as appropriate
      #
   if(priv.edit){
      edtext := 'Disable Editing';
      if(!is_boolean(priv.table)){
         #priv.f.app.mb.btns.editcopy->disabled(F);
         priv.f.app.mb.btns.editnewrow->disabled(F);
         priv.f.app.mb.btns.filesave->disabled(F);
         priv.f.app.mb.btns.filesaveas->disabled(F);
         priv.f.app.mb.btns.viewtprop->disabled(F);
         priv.f.app.mb.btns.viewtkeys->disabled(F);
         priv.f.app.mb.btns.viewhide->disabled(F);
         priv.f.app.mb.btns.optionstaqlquery->disabled(F);
         priv.f.app.mb.btns.optionsplot->disabled(F);
         priv.f.app.mb.btns.optionstaqlselect->disabled(F);
         for(field in field_names(priv.col)){
            if(has_field(priv.col[field], 'hide') && !priv.col[field].hide){
               priv.col[field].mb.Putcol->disabled(F);
            }
         }
      } else {
         priv.f.app.mb.btns.editcut->disabled(T);
         priv.f.app.mb.btns.editcopy->disabled(T);
         priv.f.app.mb.btns.editnewrow->disabled(T);
         priv.f.app.mb.btns.filesave->disabled(T);
         priv.f.app.mb.btns.filesaveas->disabled(T);
         priv.f.app.mb.btns.viewtprop->disabled(T);
         priv.f.app.mb.btns.viewtkeys->disabled(T);
         priv.f.app.mb.btns.viewhide->disabled(T);
         priv.f.app.mb.btns.optionstaqlquery->disabled(T);
         priv.f.app.mb.btns.optionsplot->disabled(T);
         priv.f.app.mb.btns.optionstaqlselect->disabled(T);
         for(field in field_names(priv.col)){
            if(has_field(priv.col[field], 'hide') && !priv.col[field].hide){
               priv.col[field].mb.Putcol->disabled(T);
            }
         }
      }
   } else {
      edtext := 'Enable Editing';
      priv.f.app.mb.btns.editcut->disabled(T);
      priv.f.app.mb.btns.editcopy->disabled(T);
      priv.f.app.mb.btns.editnewrow->disabled(T);
      priv.f.app.mb.btns.filesave->disabled(T);
      priv.f.app.mb.btns.filesaveas->disabled(F);
      priv.f.app.mb.btns.viewtprop->disabled(F);
      priv.f.app.mb.btns.viewtkeys->disabled(F);
      priv.f.app.mb.btns.viewhide->disabled(F);
      priv.f.app.mb.btns.optionstaqlquery->disabled(F);
      priv.f.app.mb.btns.optionsplot->disabled(F);
      priv.f.app.mb.btns.optionstaqlselect->disabled(F);
      for(field in field_names(priv.col)){
         if(has_field(priv.col[field], 'hide') && !priv.col[field].hide){
            priv.col[field].mb.Putcol->disabled(T);
         }
      }
   }
   priv.f.app.mb.btns.editedtoggle->text(edtext);
}

   #
   # Adds a keyword to the popup keyword
   #
priv.addkw2pop := function( ref pop, ref keyrec, key){
    wider priv;
    wider ws;
    pop.kwf[key] := ws.frame(pop.canvasframe, side='right');
    pop.kwe[key] := ws.entry(pop.kwf[key], width=60);
    if(!has_field(priv, 'ntb'))
       priv.ntb := [=];
    if((is_string(keyrec[key]) && tableexists(keyrec[key])) || is_record(keyrec[key])){
       pop.kwb[key] := ws.button(pop.kwf[key], text=key, value=keyrec[key],
                              anchor='e', font=priv.fn);
       whenever pop.kwb[key]->press do {
          subTab := $value;
          if(is_record(keyrec[key])){
             priv.popCount := priv.popCount + 1;
             priv.popups[as_string(priv.popCount)] := 
                    ws.recordbrowser(F, keyrec[key], readonly=!priv.edit);
          } else {
             ptab := split(priv.table.name(), '/');
             priv.ntb[subTab] := tablebrowser(subTab, readonly=!priv.edit,
                               plotter=priv.plotter,
                               parentTable=ptab[len(ptab)]);
          }
       }
    } else {
       pop.kwl[key] := ws.label(pop.kwf[key], text=key, font=priv.fn);
    }
    nEls := len(keyrec[key]);
    if(nEls > 1){
      if(is_string(keyrec[key][1]))
         theKWtext := spaste('[\'', keyrec[key][1], '\', ');
      else 
         theKWtext := spaste('[', keyrec[key][1], ', ');
      if(nEls > 2){
         for(i in 2:(nEls-1)){
            if(is_string(keyrec[key][i]))
               theKWtext :=spaste(theKWtext, '\'', keyrec[key][i], '\', '); 
            else 
               theKWtext :=spaste(theKWtext, keyrec[key][i], ', '); 
         }
      }
      if(is_string(keyrec[key][nEls]))
         theKWtext :=spaste(theKWtext, '\'', keyrec[key][nEls], '\']');
      else
         theKWtext :=spaste(theKWtext, keyrec[key][nEls], ']');
    } else {
      theKWtext := as_string(keyrec[key]);
    }
    pop.kwe[key]->insert(theKWtext);
    textWidth := (strlen(key)+60)*priv.ptsPerChar*0.7;
    if(textWidth > pop.cwidth){
       pop.cwidth := textWidth;
       pop.canvas->region(0, 0, pop.cwidth, pop.cheight);
    }
}

   #
   # Makes a frame for displaying keywords
   #
priv.kwframe := function(ref pop, ref wf, keyrec) {
   wider priv;
   wider ws;
   pop.wf1 := ws.frame(wf, side='left')
   pop.cwidth := 500;
   pop.cheight := len(field_names(keyrec))*priv.th*2.4;
   pop.canvas := ws.canvas(pop.wf1, region=[0,0,pop.cwidth,pop.cheight], width=pop.cheight);
   pop.vsb := ws.scrollbar(pop.wf1);
   pop.canvasframe := pop.canvas->frame(0,0, side='top',height=pop.cheight,width=pop.cwidth);
   pop.bf  := ws.frame(wf, side='right', borderwidth=0, expand='x');
   pop.pad := ws.frame(pop.bf, expand='none', width=23,height=23,relief='groove');
   pop.hsb := ws.scrollbar(pop.bf, orient='horizontal');

   whenever pop.vsb->scroll do {
         pop.canvas->view($value);
   }

   whenever pop.hsb->scroll do {
         pop.canvas->view($value);
   }

   whenever pop.canvas->yscroll do {
            pop.vsb->view($value);
   }
   whenever pop.canvas->xscroll do {
            pop.hsb->view($value);
   }


   for(key in field_names(keyrec)) {
       priv.addkw2pop(pop, keyrec, key);
   }
} 

   #
   # Keyword popup, note if col=='table' then it displays table keywords
   # otherwises it's keywords for the column.
   #
   kwpopup := subsequence(col) {
      wider priv;
      wider ws;
      tk_hold();
      pop := [=];
      title := paste('Keywords for',col);

      if(col == 'table') {
         title := spaste(col, ' keywords');
         keyrec := priv.table.getkeywords();
      } else {
         keyrec := priv.table.getcolkeywords(col);
      }
      actions := T;
      if(!priv.edit) {
         actions := [=];
         actions.dismiss := [=];
         actions.dismiss.text := 'Dismiss'
         actions.dismiss.type := 'dismiss'
      }

      pop.f := guiframework(title, menus=F, helpmenu=F, actions=actions);
      pop.f.agents.doresetkeywords := [=];
      pop.f.agents.doresetkeywords[col] := create_agent();
      pop.f.agents.dogetkeywords := [=];
      pop.f.agents.dogetkeywords[col] := create_agent();

      priv.resetkeywords[col] := function() {
         wider pop;
         pop.f.agents.doresetkeywords[col]->returns(T);
      }

      priv.getkeywords[col] := function() {
         wider pop;
         pop.f.agents.dogetkeywords[col]->returns(T);
      }

      if(priv.edit){
         pop.f.addactionhandler('apply', priv.getkeywords[col]);
         pop.f.addactionhandler('reset', priv.resetkeywords[col]);
      } else {
         pop.f.addactionhandler('dismiss', pop.f.dismiss);
      }
      pop.wf := pop.f.getworkframe();
      pop.kwf := [=];
      pop.kwe := [=];
      pop.kwl := [=];
      if(priv.edit) {
         pop.kwf.add := ws.frame(pop.wf, side='left', expand='x')
         pop.kwb.add := ws.button(pop.kwf.add, text='Add', font=priv.fn);
         pop.kwb.remove := ws.button(pop.kwf.add, text='Remove', type='menu',
                                  font=priv.fn);
         pop.remove := [=];
         pop.remove[col] := [=];
         for(key in field_names(keyrec)){
             pop.remove[col][key] := [=];
             pop.remove[col][key].b := ws.button(pop.kwb.remove, text=key,
                                              value=paste(col, key),
                                              font=priv.fn);
             whenever pop.remove[col][key].b->press do {
                removeMe := split($value);
                if(has_field(keyrec, removeMe[2])){
                   eh := symbol_delete(spaste('keyrec.', removeMe[2]));
                   pop.kwf[removeMe[2]] := 0;
                   pop.kwe[removeMe[2]] := 0;
                   pop.kwl[removeMe[2]] := 0;
                   pop.kwb[removeMe[2]] := 0;
                   pop.remove[removeMe[1]][removeMe[2]].b := 0;
                }
                pop.f.updatestatus('Changes not saved unless Apply pressed.');
             }
         }
      }
      priv.kwframe(pop, pop.wf, keyrec);
      if(col == 'table'){
         pop.f.updatestatus(paste(priv.table.name(), 'keywords.'));
      } else {
         pop.f.updatestatus(paste(priv.table.name(),'column',col,'keywords.'));
      }

      if(priv.edit) {
         addcounter := 0;
         pop.kwf.newkey := [=];
         pop.kwe.newkey := [=];
         pop.kwl.newkey := [=];

         whenever pop.kwb.add->press do {
           addcounter := addcounter+1;
           pop.kwf.newkey[as_string(addcounter)] := [=];
           pop.kwe.newkey[as_string(addcounter)] := [=];
           pop.kwl.newkey[as_string(addcounter)] := [=];
   
           pop.kwf.newkey[as_string(addcounter)] :=
                                        ws.frame(pop.canvasframe, side='right');
           pop.kwe.newkey[as_string(addcounter)] :=
                      ws.entry(pop.kwf.newkey[as_string(addcounter)], width=60);
           pop.kwl.newkey[as_string(addcounter)] :=
                      ws.entry(pop.kwf.newkey[as_string(addcounter)], width=20);
           pop.kwe.newkey[as_string(addcounter)]->insert('New Value');
           pop.kwl.newkey[as_string(addcounter)]->insert('key');
           pop.cheight := (len(field_names(keyrec))+addcounter)*priv.th*priv.magicNumber;
           pop.canvas->region(0, 0, pop.cwidth, pop.cheight);
           pop.canvas->view('yview moveto 1.0');
         }
            #
            # Worried this may fail with more than one keyword popups displayed
            #  May want to register the column and keywords
            #
         whenever pop.f.agents.dogetkeywords[col]->returns do {
            if(col == 'table'){
               oldkeyrec := priv.table.getkeywords();
            } else {
               oldkeyrec := priv.table.getcolkeywords(col);
            }
            for( key in field_names(keyrec) ) {
               if(is_string(keyrec[key])){
                  if(len(keyrec[key]) > 1){
                     keyrec[key] := eval(pop.kwe[key]->get());
                  }else{
                     keyrec[key] := pop.kwe[key]->get();
                  }
               } else {
                  if(is_integer(keyrec[key]))
                     keyrec[key] := as_integer(pop.kwe[key]->get());
                  else if(is_float(keyrec[key]))
                     keyrec[key] := as_float(pop.kwe[key]->get());
                  else if(is_complex(keyrec[key]))
                     keyrec[key] := as_complex(pop.kwe[key]->get());
               }
            }
            if(addcounter > 0){
               for(i in 1:addcounter){
                  key := pop.kwl.newkey[as_string(i)]->get();
                  keyrec[key] := pop.kwe.newkey[as_string(i)]->get();
               }
            }
            priv.editCount := priv.editCount+1;
            edCount := as_string(priv.editCount);
            priv.changes[edCount] := [=];
            priv.changes[edCount].keyrec := oldkeyrec;
            priv.changes[edCount].kwop := 'modify';
            priv.changes[edCount].col := col;
            priv.needsSaving->returns(T);
            if(col == 'table'){
               stat := priv.table.putkeywords(keyrec);
            } else {
               stat := priv.table.putcolkeywords(col, keyrec);
            }
            if(is_fail(stat)){
               priv.note(paste('Table:', priv.table.name(),
                               'keywords not changed!', stat));
            }
            priv.f.app.mb.btns.editundo->disabled(F);
            pop.f.dismiss();
         }
         whenever pop.f.agents.doresetkeywords[col]->returns do {
            if(col == 'table'){
               keyrec := priv.table.getkeywords();
            } else {
               keyrec := priv.table.getcolkeywords(col);
            }
            for( key in field_names(keyrec) ){
               if(is_agent(pop.kwe[key])){
                  pop.kwe[key]->delete('start', 'end');
                  pop.kwe[key]->insert(as_string(keyrec[key]));
               } else {
                  priv.addkw2pop(pop, keyrec, key);
               }
            }
         }
      }
      whenever self->close do {
        pop.f.dismiss();
      }
      priv.popCount := priv.popCount+1;
      rdum := tk_release();
      priv.popups[as_string(priv.popCount)] := self;
   }
 
     #
     # Popup for table browser properties
     #
   proppopup := subsequence() {
      wider priv;
      wider ws;
      priv.f.busy(T);
      tk_hold();
      pop := [=];
      pop.f := guiframework('Table Browser Properties', menus=F, helpmenu=F);

      if(!is_boolean(priv.table)){
         pop.f.updatestatus(priv.table.name());
      }
      pop.f.agents.doprop := create_agent();
      pop.f.agents.doresetprop := create_agent();
      pop.wf := pop.f.getworkframe();

      pop.vector.f := ws.frame(pop.wf, side='right', expand='none');
      pop.vector.e := ws.entry(pop.vector.f);
      pop.vector.e->insert(as_string(priv.displayVector-1));
      pop.vector.l := ws.label(pop.vector.f, 'Vector elements to display',
                            font=priv.fn);

      pop.rows2cache.f := ws.frame(pop.wf, side='right', expand='none');
      pop.rows2cache.e := ws.entry(pop.rows2cache.f);
      pop.rows2cache.e->insert(as_string(priv.rows2read));
      pop.rows2cache.l := ws.label(pop.rows2cache.f, 'Rows to read (-1 for all)',
                                font=priv.fn);

      pop.fonts.f := ws.frame(pop.wf);
      pop.kf := pop.fonts.f->fonts();
      pop.cb := combobox(pop.fonts.f, 'Font', pop.kf, listboxheight=15,
                         entrywidth=max(strlen(pop.kf)), entrydisabled=T)
      fn_ss := priv.fn ~ s/\*/.*/g
      eh := ind(pop.kf)[pop.kf ~ eval(spaste('m/',fn_ss,'/'))];
      pop.cb.select(eh[1]-1);  #-1 cause the listbox is zero based.
      pop.cbagent := pop.cb.agent();

        #Add some explanatory text  of the properties

      pop.explainLabel := ws.label(pop.wf,'Explanation of Properities',height=10,
                                font=priv.bfn);
      pop.explain.f := ws.frame(pop.wf)
      explainText := '';
      explainText := paste(explainText,
      'Vector elements to display, Vectors less than or equal to the length ');
      explainText := paste(explainText, 'specified will show thier values. Otherwise a string that looks like [111 222]Type ');
      explainText := paste(explainText,  'will be displayed where 111 is the size of the first index, 222 the second, and Type is the type of array.');
      explainText := paste(explainText,  '  Selecting the array text will cause an array browser to be displayed.\n\n');

      
      explainText := paste(explainText,
             'Rows to read, specifies the number of rows that the browser');
      explainText := paste(explainText, 
             'will store in memory at any one time.  You shouldn\'t read in');
      explainText := paste(explainText,  'large tables all into memory. ');
      explainText := paste(explainText,
             'All rows read in will be drawn on the canvas.  If you choose');
      explainText := paste(explainText,
            ' a large number of rows it could take some time to display.');

      pop.explain.f := ws.frame(pop.wf);
      pop.explain.m := ws.text(pop.explain.f, text=explainText, height=15,
                            font=priv.fn);

      pop.newfont := F;
      whenever pop.cbagent->select do{
         newfont := pop.kf[as_integer($value)+1]
         pop.explain.m->font(newfont);
         pop.newfont := newfont;
      }

      priv.getprop := function() {
         wider pop;
         pop.f.agents.doprop->returns(T);
      }

      priv.resetprop := function() {
         wider pop;
         pop.f.agents.doresetprop->returns(T);
      }

      pop.f.addactionhandler('apply', priv.getprop);
      pop.f.addactionhandler('reset', priv.resetprop);

      whenever pop.f.agents.doresetprop->returns do {
         pop.rows2cache.e->delete('start','end');
         pop.vector.e->delete('start','end');
         pop.rows2cache.e->insert(as_string(priv.rows2read));
         pop.vector.e->insert(as_string(priv.displayVector-1));
      }

      whenever pop.f.agents.doprop->returns do {
         prop := [=];
         prop.op := 'prop';
         prop.vecSize := as_integer(pop.vector.e->get())+1;
         prop.rows2read := as_integer(pop.rows2cache.e->get());
         prop.newfont := pop.newfont;
         pop.f.dismiss();
         self->returns(prop);
      }

      whenever self->close do {
        pop.f.dismiss();
      }

      priv.popCount := priv.popCount+1;
      rdum := tk_release();
      priv.popups[as_string(priv.popCount)] := self;
      priv.f.busy(F);
   }

      #
      # Popup for undoing edits
      #
   undopopup := subsequence() {
     wider priv;
     wider ws;
     priv.popCount := priv.popCount+1;
     tk_hold();
     pop := [=];

     pop.agents.undo := create_agent();
     pop.agents.cancel := create_agent();
     
     action := [=];
     action.undo := [=];
     action.undo.text := 'Undo';
     action.undo.action := function(){wider pop; 
                                      pop.agents.undo->returns(T);}
     action.cancel := [=];
     action.cancel.text := 'Cancel';
     action.cancel.type := 'dismiss';
     action.cancel.action := function(){wider pop; 
                                        pop.agents.cancel->returns(T);}
                   
     pop.f := guiframework('Undo Edits', menus=F, helpmenu=F, actions=action);

     wf := pop.f.getworkframe();
     pop.f.f := [=];
        #
        # OK lots of edits lets put everything in a canvas
        #
     if(priv.editCount > 8){
       df := ws.frame(wf, side='left')
       df2 := ws.frame(df, side='top');
       pop.f.f.label := ws.frame(df2,expand='x',side='left',font=priv.fn);
       pop.f.l.label := ws.label(pop.f.f.label, text='Count', width=5,
                              font=priv.fn);
       pop.f.b.label := ws.label(pop.f.f.label, text='Undo',width=4,font=priv.fn);
       pop.f.e.label := ws.label(pop.f.f.label, text='Column:Row: Old Value',
                              font=priv.fn);
       df1 := ws.canvas(df2, region=[0,0,300,1.7*priv.th*priv.editCount]);
       vsb := ws.scrollbar(df);
       whenever vsb->scroll do {
         df1->view($value);
       }
       whenever df1->yscroll do {
          vsb->view($value);
       }
       tf := df1->frame(0,0,expand='both');
     } else {
       tf := ref wf;
       pop.f.f.label := ws.frame(wf,expand='x',side='left',font=priv.fn);
       pop.f.l.label := ws.label(pop.f.f.label, text='Count', width=5,
                              font=priv.fn);
       pop.f.b.label := ws.label(pop.f.f.label, text='Undo',width=4,font=priv.fn);
       pop.f.e.label := ws.label(pop.f.f.label, text='Column:Row: Old Value',
                              font=priv.fn);
     }
        #
        # loop through all the changes and try and display them
        #
     for(edCount in as_string(1:priv.editCount)){
        pop.f.f[edCount] := ws.frame(tf,expand='x',side='left');
        pop.f.l[edCount] := ws.label(pop.f.f[edCount], text=edCount, width=5,
                                  font=priv.fn);
        pop.f.b[edCount] := ws.button(pop.f.f[edCount], type='radio',
                                   text='', font=priv.fn);
        pop.f.e[edCount] := ws.entry(pop.f.f[edCount], disabled=T, width=40);
        theText := spaste(priv.changes[edCount].col,':',
                          priv.changes[edCount].row, ':')
        if(has_field(priv.changes[edCount], 'old')){
           theText := paste(theText, priv.changes[edCount].old);
        } else {
           theText := paste(theText, priv.changes[edCount].doeval);
        }
        pop.f.e[edCount]->insert(theText);
     }

     whenever pop.agents.undo->returns do {
        i := 0;
        undoThese := F;
        for(j in priv.editCount:1){
          if(pop.f.b[as_string(j)]->state()){
             i := i+1;
             undoThese[i] := j;
          }
        }
        pop.agents.cancel->returns(T);
        priv.undo(undoThese);
     }

     whenever pop.agents.cancel->returns do {
        pop.f.dismiss();
        pop.agents.undo := F;
        pop.agents.cancel := F;
        pop := F;
     }

      whenever self->close do {
        pop.f.dismiss();
      }

     priv.popCount := priv.popCount+1;
     rdum := tk_release();
     priv.popups[as_string(priv.popCount)] := self;
   }

      #
      # Yup it's the popup for plotting
      #
   plotpopup := subsequence() {
      wider ws;
      wider priv;
      tk_hold();
      if(priv.debug)
         print 'plotpopup start';
      pop := [=];
      pop.f := guiframework('Plot Columns', menus=F, helpmenu=F);
      pop.f.updatestatus(priv.table.name());

      pop.f.agents.doplot      := create_agent();
      pop.f.agents.doresetplot := create_agent();

      priv.getplot := function() {
         wider pop;
         wider priv;
         pop.f.busy(T);
         priv.f.busy(T);
         pop.f.agents.doplot->returns(T);
         priv.f.busy(F);
         pop.f.busy(F);
      }

      priv.resetplot := function() {
         wider pop;
         pop.f.agents.doresetplot->returns(T);
      }

      pop.f.addactionhandler('apply', priv.getplot);
      pop.f.addactionhandler('reset', priv.resetplot);

      if(priv.debug)
         print 'plotpopup ';
      pop.wf := pop.f.getworkframe();
       
      pop.ex := [=];
      pop.ex.f := ws.frame(pop.wf, side='right');
      pop.ex.e := ws.entry(pop.ex.f);
      pop.ex.b := ws.button(pop.ex.f, text='X', type='menu', font=priv.fn);
      pop.ex.help := [=];
      pop.ex.help.e := [=];
      pop.ex.help.b := popuphelp(pop.ex.b, 'Choose a Column');
      pop.ex.help.e := popuphelp(pop.ex.e, 'Enter glish expression or leave blank to use row number');

      pop.why := [=];
      pop.why.f := ws.frame(pop.wf, side='right');
      pop.why.e := ws.entry(pop.why.f);
      pop.why.b := ws.button(pop.why.f, text='Y', type='menu', font=priv.fn);
      pop.why.help.e := [=];
      pop.why.help.b := popuphelp(pop.why.b, 'Choose a Column');
      pop.why.help.e := popuphelp(pop.why.e, 'Enter glish expression or leave blank to use row number');

      pop.style := [=];
      pop.style.f := ws.frame(pop.wf, side='right')
      pop.style.lb := ws.label(pop.style.f, text='use',font=priv.fn);
      pop.style.p := ws.button(pop.style.f, text='Points', type='radio',
                            font=priv.fn);
      popuphelp (pop.style.p, 'Plot X vs Y as points');
      pop.style.l := ws.button(pop.style.f, text='Line', type='radio',
                            font=priv.fn);
      popuphelp (pop.style.l, 'Plot X vs Y as a line');
      pop.style.h := ws.button(pop.style.f, text='Hist', type='radio',
                            font=priv.fn);
      popuphelp (pop.style.h, 'Plot Y as a histogram');
      pop.style.la := ws.label(pop.style.f, text='Plot as',font=priv.fn);
      pop.style.l->state(T);

      pop.use := [=];
      pop.use.f := ws.frame(pop.wf, side='right');
      pop.use.l := ws.label(pop.use.f, text='Rows',font=priv.fn);
      pop.use.a := ws.button(pop.use.f, text='All', type='radio',font=priv.fn);
      pop.use.u := ws.button(pop.use.f, text='Unselected', type='radio',
                          font=priv.fn);
      pop.use.s := ws.button(pop.use.f, text='Selected', type='radio',
                          font=priv.fn);
      pop.use.a->state(T);

      for(col in field_names(priv.col)){
         if(is_numeric(priv.col[col].data) && priv.table.isscalarcol(col)){
            if(len(len(priv.col[col].data)) == 1){
               pop[col] := [=];
               pop[col].bx:= ws.button(pop.ex.b, value=col,text=col,font=priv.fn);
               pop[col].by:= ws.button(pop.why.b,value=col,text=col,font=priv.fn);
               whenever pop[col].bx->press do {
                  if($value == 'Clear'){
                     pop.ex.e->delete('start', 'end');
                  } else if($value == 'Row') {
                     pop.ex.e->delete('start', 'end');
                     pop.ex.e->insert(spaste('[1:',priv.table.nrows(), ']'));
                  } else {
                     pop.ex.e->insert($value);
                  }
               }
               whenever pop[col].by->press do {
                  if($value == 'Clear'){
                     pop.why.e->delete('start', 'end');
                  } else if($value == 'Row') {
                     pop.why.e->delete('start', 'end');
                     pop.why.e->insert(spaste('[1:',priv.table.nrows(), ']'));
                  } else {
                     pop.why.e->insert($value);
                  }
               }
            }
         }
      }
      for(col in "Row Clear"){
         pop[col].bx:= ws.button(pop.ex.b, value=col, text=col,font=priv.fn);
         pop[col].by:= ws.button(pop.why.b, value=col, text=col,font=priv.fn);
         whenever pop[col].bx->press do {
            if($value == 'Clear'){
               pop.ex.e->delete('start', 'end');
            } else if($value == 'Row') {
               pop.ex.e->delete('start', 'end');
               pop.ex.e->insert(spaste('[1:',priv.table.nrows(), ']'));
            } else {
               pop.ex.e->insert($value);
            }
         }
         whenever pop[col].by->press do {
            if($value == 'Clear'){
               pop.why.e->delete('start', 'end');
            } else if($value == 'Row') {
               pop.why.e->delete('start', 'end');
               pop.why.e->insert(spaste('[1:',priv.table.nrows(), ']'));
            } else {
               pop.why.e->insert($value);
            }
         }
      }
      whenever pop.f.agents.doresetplot->returns do {
         pop.ex.e->delete('start', 'end');
         pop.why.e->delete('start', 'end');
      }
      whenever pop.f.agents.doplot->returns do {
         pop.f.busy(T);
         for(col in field_names(priv.col)){
            dum := symbol_set(col, priv.table.getcol(col));
         }
         plot := [=];
         plot.op := 'plot';
         plot.type := 'line';
         if(pop.style.l->state()) plot.type := 'line';
         if(pop.style.p->state()) plot.type := 'scatter';
         if(pop.style.h->state()) plot.type := 'hist';
#
         if(pop.use.a->state())
            plot.use := 'all'
         else if(pop.use.s->state())
            plot.use := 'selected'
         else if(pop.use.u->state())
            plot.use := 'unselected'
   
         plot.x := pop.ex.e->get();
         plot.y := pop.why.e->get();
         plot.mywindow := pop.f;
         # pop.f.dismiss();
         self->returns(plot);
         pop.f.busy(F);
      }

      whenever self->close do {
        pop.f.dismiss();
      }

     priv.popCount := priv.popCount+1;
     rdum := tk_release();
     priv.popups[as_string(priv.popCount)] := self;
     if(priv.debug)
        print 'plotpopup loaded';
   }

      # This is the Table query popup

   taqlpopup := subsequence(query=T) {
      wider priv;
      wider ws;
      tk_hold();
      pop := [=];
   
      priv.getquery := function() {
         wider pop;
         pop.f.agents.doquery->returns(T);
      }

      priv.resetquery := function(){
         wider pop;
         pop.f.agents.doresetquery->returns(T);
      }
   
      priv.getselection := function() {
         wider pop;
         pop.f.agents.doselect->returns(T);
      }

      if(query) {
         pop.f := guiframework('Table Query', menus=F, helpmenu=F);
         pop.f.agents.doquery    := create_agent();
         pop.f.addactionhandler('apply', priv.getquery);
         pop.f.addactionhandler('reset', priv.resetquery);
         pop.f.updatestatus(paste('Query table:', priv.table.name()));
      }else {
         pop.f := guiframework('Table Selection', menus=F, helpmenu=F);
         pop.f.agents.doselect    := create_agent();
         pop.f.addactionhandler('apply', priv.getselection);
         pop.f.addactionhandler('reset', priv.resetquery);
         pop.f.updatestatus(paste('Select Rows from table',priv.table.name()));
      }
      pop.f.agents.doresetquery := create_agent();
      pop.wf := pop.f.getworkframe();
      pop.sel := [=];
      pop.sel.f := ws.frame(pop.wf, side='right');
      pop.sel.e := ws.entry(pop.sel.f);
      pop.sel.l := ws.label(pop.sel.f, 'Select',font=priv.fn);
      #
      pop.where := [=];
      pop.where.f := ws.frame(pop.wf, side='right');
      pop.where.e := ws.entry(pop.where.f);
      pop.where.l := ws.label(pop.where.f, text='Where',font=priv.fn);
      #
      pop.orderby := [=];
      pop.orderby.f := ws.frame(pop.wf, side='right');
      pop.orderby.e := ws.entry(pop.orderby.f);
      pop.orderby.l := ws.label(pop.orderby.f,  text='Order by',font=priv.fn);
      #
      pop.giving := [=];
      pop.giving.f := ws.frame(pop.wf, side='right');
      pop.giving.e := ws.entry(pop.giving.f);
      pop.giving.l := ws.label(pop.giving.f, text='Giving',font=priv.fn);
          # Needs to be a random unique file
      pop.giving.e->insert('/tmp/tbsearch.tab');
      if(query) {
         whenever pop.f.agents.doquery->returns do {
            query := [=];
            query.op      := 'tablequery';
            query.select  := pop.sel.e->get();
            query.where   := pop.where.e->get();
            query.orderby := pop.orderby.e->get();
            query.giving  := pop.giving.e->get();
            pop.f.dismiss();
            self->returns(query);
         }
      } else {
         whenever pop.f.agents.doselect->returns do {
            query := [=];
            query.op      := 'tableselect';
            query.select  := pop.sel.e->get();
            query.where   := pop.where.e->get();
            query.orderby := pop.orderby.e->get();
            query.giving  := pop.giving.e->get();
            pop.f.dismiss();
            self->returns(query);
         }
      }
      whenever pop.f.agents.doresetquery->returns do {
            pop.sel.e->delete('start','end');
            pop.where.e->delete('start','end');
            pop.orderby.e->delete('start','end');
            pop.giving.e->delete('start','end');
               # Needs to be a random unique file
            pop.giving.e->insert('/tmp/tbsearch.tab');
      }

      whenever self->close do {
        pop.f.dismiss();
      }

      rdum := tk_release();
      priv.popCount := priv.popCount+1;
      priv.popups[as_string(priv.popCount)] := self;
   }

   taqlquery := function(){
      taqlpopup();
      #
      # Will eventually use the taqlwidget
      #
      # wider priv;
      # include "taqlwidget.g"
      # priv.popCount := priv.popCount+1;
      # priv.popups[as_string(priv.popCount)] := taqlwidget(priv.table.getdesc());
      # whenever priv.popups[as_string(priv.popCount)]->returns do {
      #    priv.popups[as_string(priv.popCount)].getselect();
      # }
   }

   taqlselect := function(){taqlpopup(F);}

   priv.needscolmenu := T;
      #
      # Popup for hiding columns
      #
   priv.hidedialog := subsequence () {
      wider priv;
      wider ws;
      priv.f.busy(T);
      tk_hold();
      dum := [=];
      dum.f := guiframework('Hide/Show Columns', menus=F, helpmenu=F);
      dum.f.updatestatus(priv.table.name());
      gethide := function () {
         wider priv;
         wider dum;
         for(col in field_names(priv.col)){
            if(dum[col].h->state()){
                priv.col[col].hide := T;
            } else {
                priv.col[col].hide := F;
            }
         }
         dum.f.dismiss();
         dum.f := F;
         dum := F;
         priv.dolabels();
         priv.displayPage(priv.topVis, priv.rows2read, 1);
      }
      dum.f.addactionhandler('apply', gethide);
      dum.wf := dum.f.getworkframe();
      dum.wf1 := ws.frame(dum.wf, side='left', width=300);
      textHeight := len(field_names(priv.col))*priv.th*priv.magicNumber;
      cHeight := 900;
      if(cHeight > textHeight)
         cHeight := textHeight;
      dum.canvas := ws.canvas(dum.wf1, region=[0,0,300,textHeight], width=300);
      dum.canvasframe := dum.canvas->frame(0,0, side='top', height=cHeight,
                                           width=300);
      dum.headerlabel.f :=  ws.frame(dum.canvasframe, side='right');
      dum.headerlabel.l3 := ws.label(dum.headerlabel.f, text='Show',font=priv.fn);
      dum.headerlabel.l2 := ws.label(dum.headerlabel.f, text='Hide',font=priv.fn);
      dum.headerlabel.l1 := ws.label(dum.headerlabel.f, text='Column',
                                  font=priv.fn);

      resethide := function() {
         wider priv;
         wider ws;
         wider dum;
         priv.f.busy(T);
         for(col in field_names(priv.col)){
            if(has_field(priv.col[col], 'hide')){
               if(is_boolean(priv.col[col].hide) && priv.col[col].hide){
                  dum[col].h->state(T)
                  dum[col].s->state(F)
               } else {
                  dum[col].s->state(T)
                  dum[col].h->state(F)
               }
            } else {
               dum[col].h->state(F);
               dum[col].s->state(T);
            }
         }
         priv.f.busy(F);

      }
      dum.f.addactionhandler('reset', resethide);
      for(col in field_names(priv.col)){
         dum[col] := [=]
         dum[col].f := ws.frame(dum.canvasframe, side='right');
         dum[col].s := ws.button(dum[col].f,  type='radio', text='',font=priv.fn);
         dum[col].h := ws.button(dum[col].f,  type='radio', text='',font=priv.fn);
         dum[col].l := ws.label(dum[col].f,   priv.col[col].label,font=priv.fn);
         if(has_field(priv.col[col], 'hide')){
            if(is_boolean(priv.col[col].hide) && priv.col[col].hide){
               dum[col].h->state(T)
               dum[col].s->state(F)
            } else {
               dum[col].s->state(T)
               dum[col].h->state(F)
            }
         } else {
            dum[col].h->state(F);
            dum[col].s->state(T);
         }
      }
      dum.vsb := ws.scrollbar(dum.wf1);
      whenever dum.vsb->scroll do {
         dum.canvas->view($value);
      }

      whenever dum.canvas->yscroll do {
            dum.vsb->view($value);
      }

      whenever self->close do {
        if(is_record(dum))
           dum.f.dismiss();
      }

      priv.popCount := priv.popCount+1;
      rdum := tk_release();
      priv.popups[as_string(priv.popCount)] := self;
      priv.f.busy(F);
   }
      # Set the various menus

   priv.helpmenu := function() {
      hmenu := [=];
      hmenu::useWidget := T;
      hmenu.helptb := [=];
      hmenu.helptb.text := 'Table Browser'
      hmenu.helptb.action := 'Refman:table.tablebrowser';
   
      return ref hmenu;
   }

      
   priv.filemenu := function() {
      wider priv;
      file := [=];
      file::text := 'File';
      file::help := 'Open/Save Tables, Done';
      file.open := [=];
      file.open.text := 'Open...';
      file.open.relief := 'flat';
      file.open.action := subsequence () {
         priv.f.busy(T);
         dc := tablechooser(title='Table Chooser (AIPS++) -- Open Table',wait=F);
         whenever dc->returns do {
             self->returns(op='open', tabname=$value.guiReturns);
         }
         priv.f.busy(F);
      }
      file.opennew := [=];
      file.opennew.text := 'Open in new browser...';
      file.opennew.relief := 'flat';
      file.opennew.action := subsequence () {
         priv.f.busy(T);
         dc := tablechooser(title='Table Chooser (AIPS++) -- Open Table',wait=F);
         whenever dc->returns do {
             self->returns(op='opennew', tabname=$value.guiReturns);
         }
         priv.f.busy(F);
      }
      file.refresh := [=];
      file.refresh.text := 'Refresh';
      file.refresh.relief := 'flat';
      file.refresh.action := function () {
         wider priv;
         priv.needsdisplay := T;
         priv.opentable(priv.table.name(), refresh=T);
         priv.needsdisplay := F;
      }
      file.save := [=];
      file.save.text := 'Save'
      file.save.relief := 'flat';
      file.save.action := function () {
          wider priv;
          priv.f.busy(T);
          stat := priv.table.flush();
          if(is_fail(stat)){
            priv.note(paste('Table:', priv.table.name(),'not saved!', stat),
		      priority='SEVERE');
          }
          priv.needsSaving->returns(F);
         priv.f.busy(F);
      }
      file.saveas := [=];
      file.saveas.text := 'Save as...'
      file.saveas.relief := 'flat';
      file.saveas.action := subsequence () {
         wider priv;
         priv.f.busy(T);
         fc := tablechooser(title='Table Chooser (AIPS++) -- Save Table',
                            wait=F, writeOK=T);
         whenever fc->returns do {
            newTabName := $value.guiReturns;
            if(is_string(newTabName)){
               tablecopy(priv.table.name(), newTabName);
            }
         }
         priv.f.busy(F);
      }
      file.blank := [=];
      file.blank.text := '';
      file.blank.relief :='flat';
      file.blank.disabled :=T;

      file.close := [=];
      file.close.text := 'Done';
      file.close.relief := 'flat';
      file.close.type := 'dismiss';
      file.close.action := function() {wider priv; 
                                       dismissTB := T;
                                       if(priv.notSaved){
                                          dismissTB := F;
                                          qq := priv.queryquit();
                                          whenever qq->returns do {
                                             gotThis := $value;
                                             dismissTB := T;
                                             if(gotThis == 'save'){
                                                stat := priv.table.flush();
                                                if(is_fail(stat)){
                                                  priv.note(paste('Table:', 
								  priv.table.name(), 
								  'not saved!', stat), 
							    priority='SEVERE');
                                                } else {
                                                   priv.table.unlock();
                                                }
                                             }  else if(gotThis == 'noquit'){
                                                dismissTB := F;
                                             } else {
                                                priv.undoAll();
                                             }
                                             if(dismissTB){
                                                if(has_field(priv, "nab")){
                                                   if(is_agent(priv.nab)){
                                                            priv.nab->close(T);
                                                   }
                                                 }
                                                 priv.table.flush();
                                                 priv.closePopups();
                                                 if(priv.closeTable){
                                                    priv.table.close();
                                                    priv.table := 0;
                                                    priv.f.dismiss();
                                                 } else {
                                                    priv.f.unmap();
                                                 }
                                             }
                                          }
                                       } else {
                                          dismissTB := T
                                       }
                                       if(dismissTB){
                                          if(!is_boolean(priv.table)){
                                             if(priv.closeTable){
                                                priv.table.close();
                                                priv.table := F;
                                             }
                                          }
                                          if(priv.closeTable){
                                             priv.closePopups();
                                             priv.f.dismiss();
                                          } else {
                                             priv.f.unmap();
                                          }
                                       }
                                    }
      return ref file;
   }

      #
      # Popup to query whether to quit or not
      #
   priv.queryquit := subsequence(){
      wider ws;
         # Log ourselves to the managed popup list?
      tf := ws.frame(title='Table Browser Query', width='3i', side='top');
      mf := ws.frame(tf, width='3i');
      notice := ws.message(mf, 'Changes have been made, you can', font=priv.fn);
      bf := ws.frame(tf, side='left', width='3i');
      sq := ws.button(bf, 'Save Changes',font=priv.fn);
      qa := ws.button(bf, 'Quit Table Browser',font=priv.fn);
      nq := ws.button(bf, 'Don\'t Quit',font=priv.fn);
      whenever sq->press do {
         sq := 0; qa := 0; nq := 0; tf := 0;
         self->returns('save');
      }      
      whenever qa->press do {
         sq := 0; qa := 0; nq := 0; tf := 0;
         self->returns('quit');}      
      whenever nq->press do {
         sq := 0; qa := 0; nq := 0; tf := 0;
         self->returns('noquit');}      
   }

      #
      # Popup to query whether to save our changes or not
      #
   priv.querysave := subsequence(){
      wider ws;
         # Log ourselves to the managed popup list?
      tf := ws.frame(title='Save Changes in AIPS++ Table?',width='3i',side='top');
      mf := ws.frame(tf, width='3i');
      notice := ws.message(mf, 'Changes have been made, you can', font=priv.fn);
      bf := ws.frame(tf, side='left', width='3i');
      sq := ws.button(bf, 'Save Changes',font=priv.fn);
      qa := ws.button(bf, 'Discard Changes',font=priv.fn);
      whenever sq->press do {
         sq := 0; qa := 0; nq := 0; tf := 0;
         self->returns('save');
      }      
      whenever qa->press do {
         sq := 0; qa := 0; nq := 0; tf := 0;
         self->returns('quit');
      }      
   }

   priv.addcolumn := subsequence() {
      wider priv;
      wider ws;
      priv.f.busy(T);
      pop := [=];
      tk_hold();
      pop.gf := guiframework('Create a new column', menus=F, helpmenu=F);
      wf := pop.gf.getworkframe();
      f := ws.frame(wf, side='left');
      pop.typelabel := ws.label(f, text='Column type: ', font=priv.fn);
      pop.virtual := ws.button(f, text='Virtual', type='radio', font=priv.fn);
      pop.stored  := ws.button(f, text='Stored', type='radio', font=priv.fn);
      pop.virtual->state(T);
      if(!priv.edit){
         pop.stored->disabled(T);
      } else {
         pop.stored->state(T);
         pop.virtual->state(F);
         storage_managers := ['Aips IO', 'Tiled'];
      }
      fc := ws.frame(wf, side='left');
      fc1 := ws.frame(fc, side='left');
      fc2 := ws.frame(fc, side='left');
      
      pop.express := ws.button(fc1, text='Expression', type='menu', font=priv.fn);
      pop.entry := ws.entry(fc2, font=priv.fn);

      addmenupicks := function(picks, onlynumbers=F){
         wider pop;
         wider priv;
         for(pick in picks){
            if(!onlynumbers||(onlynumbers && is_numeric(priv.col[pick].data))){
               pop[pick] := [=];
               pop[pick].b:= ws.button(pop.express, value=pick, text=pick,
                                   font=priv.fn);
               whenever pop[pick].b->press do {
                  pop.entry->insert($value);
               }
            }
         }
      }

      if(pop.virtual->state()){
         addmenupicks(field_names(priv.col), T);
      } else {
         addmenupicks(storage_managers);
      }

      whenever pop.virtual->press do {
         pop.express := 0;
         pop.entry->delete('start', 'end');
         pop.express := ws.button(fc1, text='Expression', type='menu',
                               font=priv.fn);
         addmenupicks(field_names(priv.col), T);
      }

      whenever pop.stored->press do {
         pop.express := 0;
         pop.entry->delete('start', 'end');
         pop.express := ws.button(fc1, text='Storage manager', type='menu',
                               font=priv.fn);
         addmenupicks(storage_managers);
      }
      whenever self->close do {
        pop.f.dismiss();
      }
      priv.popCount := priv.popCount+1;
      tk_release();
      priv.popups[as_string(priv.popCount)] := self;
      priv.f.busy(F);
   }
      # 
   priv.cut := function() {
      wider priv;
      if(priv.rowCount > 0){
         for(i in priv.rowCount:1 ){
           tr := tablerow(priv.table);
           priv.editCount := priv.editCount+1;
           edCount := as_string(priv.editCount);
           priv.changes[edCount] := [=];
           priv.changes[edCount].row_op := 'delete';
           priv.changes[edCount].row := priv.pickedRows[i];
           priv.changes[edCount].tablerow := tr.get(priv.pickedRows[i]);
         }
         stat := priv.table.removerows(priv.pickedRows);
         if(is_fail(stat)){
            note('Unable to remove rows from table', priority= 'SEVERE');
         }
      }
      if(len(priv.selectedCols) > 0){
         for(col in priv.selectedCols){
            priv.col[col].hide := T;
            priv.col[col].deleteMe := T;
            priv.editCount := priv.editCount+1;
            edCount := as_string(priv.editCount);
            priv.changes[edCount] := [=];
            priv.changes[edCount].col_op := 'delete';
            priv.changes[edCount].col := col;
         }
      }
      priv.rowCount := 0;
      priv.redrawPage();
   }

      # Copy should take the selected rows and make copies, where they go
      # is anyones guess right now.
   priv.copy := function() {
      print 'Copy';
   }

      # Paste whatever's been copied
   priv.paste := function() {
      print 'paste';
   }

      # The undo function series, last, all, and select from a popup
   priv.undoLast := function() {
     wider priv;
     priv.undo(priv.editCount);
   }

   priv.undoAll := function() {
     wider priv;
     if(priv.editCount > 0){
        priv.undo([priv.editCount:1]);
     }
   }

   priv.undoDialog := function() {
      wider priv;
      priv.popups[as_string(priv.popCount)] := undopopup();
   }

      # Popup for showing table summary information

   priv.showTabSummary := function() {
     global gui;
     wider priv;
     wider ws;

     priv.f.busy(T);
     tk_hold();
     wreck := [=];
     wreck.title := 'Table Summary'

     wreck.actions := [=];
     wreck.actions.apply := [=];
     wreck.actions.apply.label := 'Apply'
     wreck.actions.apply.type := 'action'
     wreck.actions.apply.function := function(data){
               wider priv;
               priv.needsSaving->returns(T);
               }

     wreck.data := [=];
     wreck.data.tabname := [=];
     wreck.data.tabname.label := 'Table'
     wreck.data.tabname.default := priv.table.name()
     wreck.data.tabname.type := 'string';
     wreck.data.tabname.hint := 30;
#
     info := priv.table.info();
#
     wreck.data.type := [=];
     wreck.data.type.label := 'Type';
     wreck.data.type.default := info.type;
     wreck.data.type.type := 'string';
     wreck.data.type.hint := 20;
#
     wreck.data.subtype := [=];
     wreck.data.subtype.label := 'Subtype';
     wreck.data.subtype.default := info.subType;
     wreck.data.subtype.type := 'string';
     wreck.data.subtype.hint := 20;
#
     wreck.data.description := [=];
     wreck.data.description.label := 'Description';
     wreck.data.description.default := info.readme;
     wreck.data.description.type := 'text';
     wreck.data.description.hint := 40;
#
     wreck.data.shape := [=];
     wreck.data.shape.label := 'Shape';
     wreck.data.shape.default := paste(priv.table.ncols(), 'Columns by',
                                       priv.table.nrows(), 'Rows');
     wreck.data.shape.type := 'string';
     wreck.data.shape.hint := 25;
#

     priv.sumstuff := gui.inputform(wreck, dismiss=T, edit=priv.edit);
     wf := priv.sumstuff.gf.getworkframe();
     priv.sumstuff.gf.updatestatus(priv.table.name());
     keyrec := priv.table.getkeywords();
     priv.sumstuff.kwlabel := ws.label(wf, text='Keywords',font=priv.fn);
     priv.kwframe(priv.sumstuff.gf, wf, keyrec);
     priv.popCount := priv.popCount + 1;
     rdum := tk_release();
     priv.f.busy(F);

     # print 'Info: ', info;

   }

   priv.showTabKeys := function() {
     dum := kwpopup('table');
   }

   priv.viewmenu := function() {
      vmenu := [=];
      vmenu::text := 'View'
      vmenu::help := 'Table summary, keywords, hide/show columns';
#
      vmenu.tprop := [=];
      vmenu.tprop::text := 'Table Summary';
      vmenu.tprop.text := 'Table Summary...';
      vmenu.tprop.relief := 'flat';
      vmenu.tprop.action := priv.showTabSummary;
#
      vmenu.tkeys := [=];
      vmenu.tkeys::text := 'Table Keywords';
      vmenu.tkeys.text := 'Table Keywords...';
      vmenu.tkeys.relief := 'flat';
      vmenu.tkeys.action := priv.showTabKeys;

      vmenu.blank := [=];
      vmenu.blank.text := '';
      vmenu.blank.relief :='flat';
      vmenu.blank.disabled :=T;
#

      vmenu.hide := [=];
      vmenu.hide.text :='Hide/Show Columns...';
      vmenu.hide.relief :='flat';
      vmenu.hide.action := priv.hidedialog;
      return ref vmenu;
   }

   priv.editmenu := function() {
      wider priv;
      edmenu := [=];
      edmenu::text := 'Edit'
      edmenu::help := 'Various options edit options';
#
         edmenu.cut := [=];
         edmenu.cut::text := 'Cut';
         edmenu.cut.text := 'Cut';
         edmenu.cut.relief := 'flat';
         edmenu.cut.action := function(){wider priv;
                                         priv.cut();}
#
         edmenu.copy := [=];
         edmenu.copy::text := 'Copy';
         edmenu.copy.text := 'Copy';
         edmenu.copy.relief := 'flat';
#
         edmenu.paste := [=];
         edmenu.paste::text := 'Paste';
         edmenu.paste.text := 'Paste';
         edmenu.paste.relief := 'flat';
#
         edmenu.newrow := [=];
         edmenu.newrow::text := 'New Row';
         edmenu.newrow.text := 'New Row';
         edmenu.newrow.relief := 'flat';
         edmenu.newrow.action := function(){wider priv;
                                            if(!is_boolean(priv.table)){
                                                priv.table.addrows(1);
                                                priv.notSaved := F;
                                            }
                                              # Display the extra rows
                                              # Pretty clumsy needs improvement

                                            if((priv.lastShown+1) ==
                                                priv.table.nrows()){
                                               priv.displayPage(priv.topShown,
                                                                priv.rows2read,
                                                                0);
                                            }
                                           }
#        
         edmenu.newcol := [=];
         edmenu.newcol::text := 'New Column...';
         edmenu.newcol.text := 'New Column...';
         edmenu.newcol.relief := 'flat';
         edmenu.newcol.action :=  function(){wider priv; priv.addcolumn();}
#
         edmenu.undo := [=];
         edmenu.undo.text := 'Undo';
         edmenu.undo.relief := 'flat';
         edmenu.undo.type := 'menu';
#
         edmenu.undo.menu := [=];
         edmenu.undo.menu.last := [=];
         edmenu.undo.menu.last.text := 'Last';
         edmenu.undo.menu.last.relief := 'flat';
         edmenu.undo.menu.last.action := priv.undoLast;

         edmenu.undo.menu.all := [=];
         edmenu.undo.menu.all.text := 'All';
         edmenu.undo.menu.all.relief := 'flat';
         edmenu.undo.menu.all.action := priv.undoAll;

         edmenu.undo.menu.selected := [=];
         edmenu.undo.menu.selected.text := 'Choose...';
         edmenu.undo.menu.selected.relief := 'flat';
         edmenu.undo.menu.selected.action := priv.undoDialog;

         edmenu.undo.disabled := T;
         edmenu.newcol.disabled := T;

      if(priv.edit) {
         edmenu.cut.disabled := F;
         edmenu.copy.disabled := T;
         edmenu.paste.disabled := T;
         edmenu.newrow.disabled := F;

         edmenu.cut.action := priv.cut;
         edmenu.copy.action := priv.copy;
         edmenu.paste.action := priv.paste;
      } else {
         edmenu.cut.disabled := T;
         edmenu.copy.disabled := T;
         edmenu.paste.disabled := T;
         edmenu.newrow.disabled := T;
         priv.ed.e := 0;
         priv.ed.f := 0;
      }

      edmenu.blank := [=];
      edmenu.blank.text := '';
      edmenu.blank.relief :='flat';
      edmenu.blank.disabled :=T;

      edmenu.prop := [=];
      edmenu.prop.text := 'Properties...';
      edmenu.prop.relief := 'flat'
      edmenu.prop.action := proppopup;
      edmenu.browser := [=];
      edmenu.browser::text := 'Help Browser'
      edmenu.browser.text := 'Help Browser'
      edmenu.browser.type := 'menu'
      edmenu.browser.relief := 'flat'
#
      edmenu.browser.menu := [=];
      edmenu.browser.menu.netscape := [=];
      edmenu.browser.menu.netscape.text := 'Netscape';
      edmenu.browser.menu.netscape.type := 'radio';
      edmenu.browser.menu.netscape.relief := 'flat';
      edmenu.browser.menu.netscape.state := T;
      edmenu.browser.menu.netscape.action := function(){ global helpsystem;
                                            helpsystem::browser := 'netscape';}
#
      edmenu.browser.menu.mosaic := [=];
      edmenu.browser.menu.mosaic.text := 'Mosaic';
      edmenu.browser.menu.mosaic.type := 'radio';
      edmenu.browser.menu.mosaic.relief := 'flat';
      edmenu.browser.menu.mosaic.action := function(){global helpsystem;
                                         helpsystem::browser := 'mosaic';}
#
      edmenu.browser.menu.other := [=];
      edmenu.browser.menu.other.text := 'Other';
      edmenu.browser.menu.other.type := 'radio';
      edmenu.browser.menu.other.relief := 'flat';
      edmenu.browser.menu.other.action := function(){ global helpsystem;
                                         helpsystem::browser := 'other';}

      edmenu.blank1 := [=];
      edmenu.blank1.text := '';
      edmenu.blank1.relief :='flat';
      edmenu.blank1.disabled :=T;

      edmenu.edtoggle := [=];
      if(priv.edit)
        edtext := 'Disable Editing';
      else
        edtext := 'Enable Editing';
      edmenu.edtoggle.text := edtext;
      edmenu.edtoggle.type := 'plain';
      edmenu.edtoggle.action := priv.toggleEditFlag;
   

      return ref edmenu;
   }
#
   priv.optsmenu := function() {
      options := [=];
      options::text := 'Table'
      options::help := 'Query, Plot, make a subTable';

      options.taqlquery := [=];
      options.taqlquery.text := 'Query...';
      options.taqlquery.relief := 'flat'
      options.taqlquery.action := taqlquery;

      options.plot := [=];
      options.plot.text := 'Plot...';
      options.plot.relief := 'flat'
      options.plot.action := plotpopup;

      options.taqlselect := [=];
      options.taqlselect.text := 'Select...';
      options.taqlselect.relief := 'flat'
      options.taqlselect.action := taqlselect;
  
      return ref options;
   }

      # Initialize the table browser

   priv.initialize := function(){
      wider priv;
      menus := [=];
      menus.file := priv.filemenu();
      menus.edit := priv.editmenu();
      menus.view := priv.viewmenu();
      menus.options := priv.optsmenu();
      helpmenu := priv.helpmenu();
      title := 'Table Browser (AIPS++)';
      pTab := ['Un-named table'];
      if(!is_boolean(priv.table)){
         tName := split(priv.table.name());
         if(len(tName) > 0 && strlen(tName) > 0){
            pTab := split(tName, '/');
         }
         if(is_string(priv.parentTable)){
           title := spaste(title, ' -- ', priv.parentTable, '/',
                           pTab[len(pTab)]);
         } else {
           title := spaste(title, ' -- ', pTab[len(pTab)]);
         }
      }


      priv.f := guiframework(title, menus=menus, helpmenu=helpmenu, 
                             actions=F);
      return T;
   }


   # Construct the table browser's main window, rowsNcanvas tells us how big
   # to make the canvas for drawing.

priv.mainwindow := function(rowsNcanvas){
   wider priv;
   wider ws;
   dummy := priv.initialize();
   priv.f.app.mb.btns.editundo->disabled(T);
   priv.gth := 20;
   priv.ed := [=];
   priv.nrows := 1;
   lastX := 100;

   priv.wf  := priv.f.getworkframe();

   priv.th := 14;
   priv.ptsPerChar := 14;
   priv.fn := '-adobe-courier-medium-r-normal--14-*';
   priv.bfn := '-adobe-courier-bold-r-normal--14-*';

   priv.viewHeight := priv.th*(rowsNcanvas+1);
   priv.viewWidth := lastX;

   priv.wfa := ws.frame(priv.wf, side='left');
   priv.wfb := ws.frame(priv.wfa, side='top');
   priv.gtf := ws.frame(priv.wfb, borderwidth=0, side='left', height=priv.gth,
                     expand='x')
   priv.gtl := ws.label(priv.gtf, text='Go to',font=priv.fn);
   priv.gte := ws.entry(priv.gtf, width=12);
   priv.help.gte := popuphelp(priv.gte, 'Enter row number to display');

   priv.gtd := ws.label(priv.gtf, text='            ',font=priv.fn);
   priv.wfcf := ws.frame(priv.wfb, side='left');
   priv.wfbc := ws.frame(priv.wfcf, side='top');
   priv.tf  := ws.frame(priv.wfbc, borderwidth=0, side='top', height=priv.gth,
                     expand='x');
   priv.lf  := ws.frame(priv.tf, borderwidth=0, side='left');
   priv.lf1 := ws.frame(priv.lf, borderwidth=0, side='left', expand='none',
                     width=10);
   priv.lf2 := ws.frame(priv.lf, borderwidth=0, side='left', expand='x');
   priv.rcWidth := 65;
   priv.rlc := ws.canvas(priv.lf1, region=[0,0,10, priv.gth], height=priv.gth,
                      background='white', borderwidth=0, fill='none',width=priv.rcWidth);
   priv.lc  := ws.canvas(priv.lf2, region=[80,0,lastX, priv.gth], height=priv.gth,
                      background='white', borderwidth=0, width=400, fill='x');

   priv.help.lc := popuphelp(priv.lf2, 'Move over label text and select to get column options');
   priv.wf1 := ws.frame(priv.wfbc, borderwidth=0, side='left')
   priv.rf  := ws.frame(priv.wf1, borderwidth=0, expand='y', width=priv.rcWidth, padx=0);
   priv.cf  := ws.frame(priv.wf1, side='left', borderwidth=0, padx=0);
   priv.rc  := ws.canvas(priv.rf, region=[0, 0, priv.rcWidth, priv.viewHeight],
                      background='white', width=priv.rcWidth, borderwidth=0,
                      relief='flat', fill='y');
   priv.help.rc := popuphelp(priv.rf, 'Click on a row to select it');
   priv.c   := ws.canvas(priv.cf, region=[80, 0, lastX, priv.viewHeight],
                      background='white', borderwidth=0, relief='flat',
                      height=priv.th*25, width=400);
   priv.help.c := popuphelp(priv.cf, 'Click on a cell to select it');
   priv.vsb := ws.scrollbar(priv.wfcf);

   priv.bf  := ws.frame(priv.wfb, side='right', borderwidth=0, expand='x');
   priv.pad := ws.frame(priv.bf, expand='none', width=23, height=23,
                      relief='flat');
   priv.hsb := ws.scrollbar(priv.bf, orient='horizontal');
   priv.dismiss := [=];
   priv.dismiss.f := ws.frame(priv.wf, side='right', expand='x');
   priv.dismiss.b := ws.button(priv.dismiss.f, 'Dismiss', type='dismiss');
   priv.topPos := 1;
   priv.topShown := 1;
   priv.topVis := 1;
   priv.lastVis := priv.displayCache;
   priv.lastShown := 25;
   priv.lastPos := priv.viewHeight/priv.th;
   rowsVis := 25;
   priv.popup := [=];
   
      # Handles the goto field

   whenever priv.gte->return do {
      priv.visH := priv.c->height();
      rowsVis := as_integer(priv.visH/priv.th);
      go2Row := as_integer(priv.gte->get());
      if(has_field(priv.table, 'nrows') && go2Row <= priv.table.nrows()){
         priv.gotoRow(go2Row);
      } else {
         if(has_field(priv.table, 'nrows')){
            priv.note(spaste('Can\'t goto row ', go2Row,
			     ' only ', priv.table.nrows(), 
			     ' rows in table.'),
		      priority='WARN');
            tmp5 := choicewindow(paste('Can\'t goto row', go2Row, 'only',
                               priv.table.nrows(),
                              'rows in table. \n\nGo to last row?'), "Yes No");
            if(tmp5 == 'Yes'){
               priv.gotoRow(priv.table.nrows());
               priv.gte->delete('start', 'end');
               priv.gte->insert(as_string(priv.table.nrows()));
            }
         } else {
            priv.note(paste('Can\'t goto row ', go2Row,
                            'no table specified!'),
		      priority='WARN');
            tmp6 := infowindow(paste('Can\'t goto row ', go2Row, 
                               'no table specified!'));
         }
      }
   }

      #
      # vertical scollbar handling, if the table doesn't fit in cache
      # no sliding is allowed, otherwise it's as normal
      #
   whenever priv.vsb->scroll do {
      scbValue := $value
      priv.visH := priv.c->height();
      rowsVis := as_integer(priv.visH/priv.th)+1;
      rows2advance := 4;
      if(priv.handleScrollBar){
         scrollCmds := split(scbValue);
         if(priv.debug){
            print 'scroll commands', scrollCmds;
         }
         if(scrollCmds[1] == 'yview'){
            if(scrollCmds[2] == 'scroll'){
               if(scrollCmds[4] == 'pages'){
                  rows2advance := rowsVis;
               } else if(scrollCmds[4] == 'units'){
                  rows2advance := 2;
               }
               doDisplay := T;
               updown := as_integer(scrollCmds[3]);
               if(updown < 0){
                  a := priv.topShown-rows2advance+1;
                  if(priv.topShown < 2){
                    doDisplay := F;
                  }
               } else {
                  a := priv.topShown+rows2advance;
                  if(priv.lastShown  >= priv.table.nrows()){
                    doDisplay := F;
                  }
               }
               if(doDisplay){
                 priv.moveDisplay(a, rows2advance, updown, scrollCmds[4]);
               }
            } else if (scrollCmds[2] == 'moveto'){
                scrnPos := as_float(scrollCmds[3]);
                a := as_integer(priv.table.nrows()*scrnPos);
                priv.gotoRow(a);
            }
         }
      } else {
        priv.c->view(scbValue);
        priv.rc->view(scbValue);
      }
   }
      # Horizonal scrolling
   whenever priv.hsb->scroll do {
      priv.c->view($value);
      priv.lc->view($value);
   }

      # canvas scrolling
   whenever priv.c->yscroll do {
      if(!is_boolean(priv.table) && priv.handleScrollBar){
         a := [priv.topShown/priv.table.nrows(),
               (priv.topShown+rowsVis)/priv.table.nrows()];
         priv.vsb->view(a);
      } else {
         priv.vsb->view($value);
      }
   }
   whenever priv.c->xscroll do {
      priv.hsb->view($value);
      priv.lc->view($value);
   }

   priv.rlc->text(20, 0.5*priv.gth, text='Row', anchor='c', font=priv.bfn)
   priv.ctext := [=];

      #
      # Now we bind the mouse button the row and display canvases to allow
      # cell and row selection
      #
      # First row canvas bindings
      #
   priv.rc->bind('rowcell', '<Button-1>', 'picked');
   priv.rc->bind('<Button-1>', 'bdown');
   priv.rc->bind('<Button-2>', 'unpick');
   priv.rc->bind('boxed', '<Button-2>', 'unpick');
   priv.rc->bind('rowcell', '<Button-2>', 'pickmore');

   whenever priv.rc->unpick do {
      # print 'in rc->unpick ', priv.pickset;
      if(!priv.pickset){
         priv.unpickrow($value.world);
      } else {
         priv.pickrow($value.world, clear=F);
         priv.pickset := T;
      }
      priv.pickset := F;
   }
   whenever priv.rc->bdown do {
      if(!priv.pickset){
         priv.rc->delete('boxed');
         priv.c->delete('boxed');
         priv.ed.e := 0;
         priv.ed.f := 0;
         priv.pickrow($value.world);
      }
      priv.pickset := F;
   }
   whenever priv.rc->pickmore do{
      # print 'pickmore';
      row := as_integer($value.world[2]/priv.th) + priv.topPos -1;
      if(priv.rowCount == 0 || all(priv.pickedRows != row)){
         priv.pickrow($value.world, clear=F);
         priv.rowCount := priv.rowCount + 1;
         priv.pickedRows[priv.rowCount]:= row
         priv.pickset := T;
      } else {
         priv.pickedRows := priv.pickedRows[priv.pickedRows!=row];
         priv.pickset := F;
         priv.rowCount := priv.rowCount - 1;
         if(priv.edit && priv.rowCount == 0){
            priv.f.app.mb.btns.editcut->disabled(T);
            priv.f.app.mb.btns.editcopy->disabled(T);
         }
      }
      # print priv.pickedRows;
   }
   whenever priv.rc->picked do{
      priv.rc->delete('boxed');
      priv.pickrow($value.world);
      priv.pickset := T;
      priv.pickedRows[1] :=
          as_integer($value.world[2]/priv.th) + priv.topPos -1;
      priv.rowCount := 1;
      if(priv.edit){
         priv.f.app.mb.btns.editcut->disabled(F);
         priv.f.app.mb.btns.editcopy->disabled(F);
      }
   }

     #
     # Now the display canvas binding
     #
   priv.c->bind('cell', '<Button-1>', 'picked');
   priv.c->bind('<Button-1>', 'bdown');
   priv.c->bind('<Button-2>', 'unpick');
   priv.c->bind('boxed', '<Button-2>', 'unpick');
   priv.c->bind('cell', '<Button-2>', 'pickmore');
   
   priv.pickset := F;
   whenever priv.c->unpick do {
      if(!priv.pickset){
         priv.unpick($value.world);
         priv.pickset := F;
      } else {
         priv.pick($value.world, clear=F);
         priv.pickset := T;
      }
   }

   whenever priv.c->bdown do {
      if(!priv.pickset){
         priv.c->delete('boxed');
         priv.pick($value.world);
         priv.pickset := T;
      }
      priv.pickset := F;
   }

   whenever priv.c->pickmore do{
      priv.pick($value.world, clear=F);
      priv.pickset := T;
   }

   whenever priv.c->picked do{
      priv.c->delete('boxed');
      priv.pick($value.world);
      priv.pickset := T;
   }

   whenever priv.f.handle.agent->returns do {
      if(has_field($value, 'op')){
      
      if($value.op == 'open'){
          tabname := $value.tabname;
          if(is_string(tabname)){
             priv.needsdisplay := T;
             priv.opentable(tabname);
             priv.needsdisplay := F;
          }
      } else if($value.op == 'refresh'){
         priv.needsdisplay := T;
         priv.opentable(priv.table, refresh=T);
         priv.needsdisplay := F;
      } else if($value.op == 'opennew'){
          tabname := $value.tabname;
          if(is_string(tabname)){
             tmp2 := tablebrowser(tabname, plotter=priv.plotter);
          }
      } else if($value.op == 'plot'){
         cwin := $value.mywindow;
         priv.f.busy(T);
         cwin.busy(T);
         priv.plot.x := $value.x;
         priv.plot.y := $value.y;
         priv.plot.type := $value.type;

         xisepoch := F;
         yisepoch := F;
         if(has_field(priv.col, priv.plot.x)){
            if(has_field(priv.col[priv.plot.x], 'keywords')){
               if(has_field(priv.col[priv.plot.x].keywords, 'MEASINFO') &&
               strlen(priv.col[priv.plot.x].keywords.MEASINFO.type) > 0) {
                  if(priv.col[priv.plot.x].keywords.MEASINFO.type == 'epoch'){
                    xisepoch := T;
                  }
               }
            }
         }
         if(has_field(priv.col, priv.plot.y)){
            if(has_field(priv.col[priv.plot.y], 'keywords')){
               if(has_field(priv.col[priv.plot.y].keywords, 'MEASINFO') &&
               strlen(priv.col[priv.plot.y].keywords.MEASINFO.type) > 0) {
                  if(priv.col[priv.plot.y].keywords.MEASINFO.type == 'epoch'){
                    yisepoch := T;
                  }
               }
            }
         }

           # OK, here we check to see what we want plotted, if both
           # plot.x and plot.y are null, we warn the user and do nothing
           # if either one is evalable we set the other to ind(of it).
           # esstentially getting row versus value.

         doplot := T;
         if(!strlen(priv.plot.x)){
            if(strlen(priv.plot.y)){
               why := eval(priv.plot.y);
               ex := ind(why);
            } else {
               doplot := F;
            }
         } else {
            ex := eval(priv.plot.x);
            if(strlen(priv.plot.y)){
              why := eval(priv.plot.y);
            } else {
              why := ind(ex);
            }
         }
         goodWhy := T;
         if(is_fail(why) || !is_numeric(why) || (is_boolean(why) && len(why)==1)){
            goodWhy := F;
         }
         goodEx := T;
         if(is_fail(ex) || !is_numeric(ex) || (is_boolean(ex) && len(ex)==1)){
            goodEx := F;
         }
         if(!goodEx || !goodWhy){
            if(!goodWhy){
               amess := 'Tablebrowser plotxy: Invalid expression for Y axis';
            }
            if(!goodEx){
               amess := 'Tablebrowser plotxy: Invalid expression for X axis';
            }
            if(!goodEx && !goodWhy){
               amess := 'Tablebrowser plotxy: Invalid expressions for X and Y axes';
            }
            priv.note(amess, priority='SEVERE');
            dum := infowindow(amess);
            doplot := F;
         }

         if(doplot){
            limitPlot := F;
            if($value.use != 'all'){
               limitPlot := T;
               if($value.use == 'selected'){
                  selected := array(F,len(ex));
                  selected[priv.pickedRows] := T;
               } else {
                  selected := array(T,len(ex));
                  selected[priv.pickedRows] := F;
               }
            }
            if(limitPlot){
               ex := ex[selected];
               why := why[selected];
            }

            type := priv.plot.type;
            if(is_boolean(priv.plotter))
               priv.plotter := pgplotter();
            else 
               priv.plotter.gui();

         #Perhaps we should clear the plotting list? Or should the user
         #do it using pgplotter?
         #priv.plotter.clear();
            minWhy := min(why);
            maxWhy := max(why);
            minEx := min(ex);
            maxEx := max(ex);

            if(minWhy == maxWhy){
               minWhy -:= 1.0;
               maxWhy +:= 1.0;
            }
            if(minEx == maxEx){
               minEx -:= 1.0;
               maxEx +:= 1.0;
            }

            xopt := 'BCNST';
            yopt := 'BCNST';
            labelx := priv.plot.x;
            labely := priv.plot.y;
               # OK if they are epoch subtract off the min cause PgPlot can't handle
               # real large numbers i.e. doubles
            if(xisepoch){
              xopt := spaste(xopt, 'ZH');
              ex -:= minEx;
              maxEx -:= minEx;
              dq.setformat('dtime', 'utc');
              tabmeas := dq.quantity(minEx, priv.col[priv.plot.x].keywords.QuantumUnits);
              labelx := paste(labelx, 'since', dq.form.dtime(tabmeas));
             minEx := 0;
            }
            if(yisepoch){
              yopt := spaste(yopt, 'ZH');
              why -:= minWhy;
              maxWhy -:= minWhy;
              dq.setformat('dtime', 'utc');
              tabmeas := dq.quantity(minWhy, priv.col[priv.plot.y].keywords.QuantumUnits);
              labely := paste(labely, 'since', dq.form.dtime(tabmeas));
              minWhy := 0;
            }
#
            if (type != 'hist') {
               priv.plotter.env(minEx, maxEx, minWhy, maxWhy, 0, 0);
               priv.plotter.clear();
               priv.plotter.env(minEx, maxEx, minWhy, maxWhy, 0, 0);
               priv.plotter.tbox(xopt, 0.0, 0, yopt, 0.0, 0);
               priv.plotter.lab(labelx, labely, 'Table Browser Plot');
#
               if(type == 'line'){
                  #priv.plotter.line(ex, why);
                  priv.plotter.plotxy(ex, why, newplot=F);
               } else if(type == 'scatter') {
                  # priv.plotter.pt(ex, why, 1);
                  priv.plotter.plotxy(ex, why, newplot=F,plotlines=F);
               }
            } else if(type == 'hist') {
print 'plot'
               priv.plotter.hist(why, minWhy, maxWhy, 20, 0);
            }
            priv.plotter.refresh();
         } else {
            dum := infowindow('Nothing chosen to plot!');
         }
         priv.f.busy(F);
         cwin.busy(F);
            
      } else if($value.op =='prop') {
            # should put a flag in for redisplaying table.
         priv.rows2read := $value.rows2read;
         priv.displayCache := priv.rows2read;
         if(priv.displayCache < 0){
            priv.handleScrollBar := F;
            priv.rows2read := -1;
         }
         if($value.vecSize != priv.displayVector){
            priv.displayVector := $value.vecSize;
            priv.f.busy(T);
            priv.getdata(priv.topPos, force=T);
            priv.dolabels();
            priv.displayPage(priv.topShown, priv.rows2read, 0.0);
            priv.f.busy(F);
         }
         if(is_string($value.newfont)){
            priv.fn := $value.newfont;
            priv.bfn := priv.fn ~ s/medium/bold/;
            priv.ptsPerChar := as_integer(split(priv.fn, '-')[6]);
              #  Well this is another one I don't know why, but if the font
              # size is too big it doesn't need the extra pixel.
            if(priv.ptsPerChar > 14)
               priv.th := priv.ptsPerChar;
            else 
               priv.th := priv.ptsPerChar+1;
            if(priv.th <= 18){
               priv.gth := 20;
            } else {
               priv.gth := priv.th+5;
               priv.gtf->height(priv.gth);
               priv.tf->height(priv.gth);
            }

               # No need to do any of this if we haven't loaded a table
              
            if(!is_boolean(priv.table)){
               priv.f.busy(T);
               priv.gtl->font(priv.fn);
               priv.redrawPage();
                  # update the non display text
               priv.rlc->delete('all');
               priv.rlc->text(20, 0.5*priv.gth, text='Row', anchor='c',
                              font=priv.bfn)
               priv.f.busy(F);
            }
         }

      } else if($value.op =='tablequery') {
         priv.f.busy(F);
         priv.qtab := priv.table.query($value.where, $value.giving,
                                       $value.orderby, $value.select);
         priv.tmp := tablebrowser(priv.qtab.name(), plotter=priv.plotter);
         priv.f.busy(F);
      } else if ($value.op == 'tableselect') {
         priv.f.busy(T);
         priv.tmp1 := priv.table.query($value.where, $value.giving,
                                       $value.orderby, $value.select);
         priv.pickedRows := priv.tmp1.rownumbers();
         priv.selectrows(priv.pickedRows);
         priv.f.busy(F);
      }
      }
   }
   whenever priv.dismiss.b->press do {
      
      priv.closePopups();
      if(priv.closeTable){
         priv.table.close();
         priv.f.dismiss();
      } else {
         priv.f.unmap();
      }
   }
}

      # Handles all the canvas movement, whether to read/draw additional rows, 
      
   priv.moveDisplay := function(startRow, rows2Move, updown, op) {
      wider priv;
      if(startRow < 1){
         startRow := 1;
      }
      priv.visH := priv.c->height();
      rowsVis := as_integer(priv.visH/priv.th);

      if((startRow + rows2Move) > priv.table.nrows()){
         startRow := priv.table.nrows()-rowsVis+1;
      }
         
         #Now handle the screen drawing
      if(startRow < priv.topPos || (startRow+updown*rowsVis)>priv.lastPos && priv.lastPos < priv.table.nrows()){
         priv.nowhys := T;
         priv.displayPage(startRow, priv.rows2read, 0.0);
      } else {
         priv.topShown := startRow;
         priv.lastShown := startRow+updown*rowsVis;
         scrnPos := (startRow-priv.topPos+0.5)/priv.rows2read;
         priv.c->view(paste('yview moveto', scrnPos));
         priv.rc->view(paste('yview moveto', scrnPos));
      }
   }

   priv.gotoRow := function(go2Row){
      wider priv;
      # t1 := time()
      priv.visH := priv.c->height();
      rowsVis := as_integer(priv.visH/priv.th);
      if(go2Row < priv.topVis || go2Row > (priv.lastVis-rowsVis)){
         priv.displayPage(go2Row, priv.rows2read, 0.0);
      } else {
         if(go2Row > (priv.table.nrows()-rowsVis)){
            go2Row := priv.table.nrows()-rowsVis+1;
            scrnPos := 1.0;
         } else {
            scrnPos := (go2Row-priv.topPos+0.5)/priv.rows2read;
         }
         priv.c->view(paste('yview moveto', scrnPos));
         priv.rc->view(paste('yview moveto', scrnPos));
         priv.topShown := go2Row;
         priv.lastShown := priv.topShown + rowsVis;
      }
      # print 'Goto row: ', time() - t1;
   }
   #
   # May need to resolve inter-column spacing after data is read
   #
   # Some time in the not-to-distand future (today =27-apr98), we'll just grab
   # column.display from the table client rather than using .data.  About the
   # only time will need .data is when plotting or saving a column to a 
   # variable.
   #
   priv.getdata := function(start, force=F) {
      wider priv;
      # t1 := time();
      if(start < 1)
         start := 1;
      if(priv.cached.first != start || force){
         if(priv.rows2read < 0){
            priv.cached.first := 1;
            priv.cached.last := priv.nrows;
         } else {
            priv.cached.first := start;
            priv.cached.last := start+priv.rows2read;
         }
         for(col in priv.columnNames){
            if(priv.debug)
              print 'getdata ', col;
            if(!has_field(priv.col, col)){
               priv.col[col] := [=];
                 # set the default formatting for complex/real floats & doubles
               dataType := to_upper(split(priv.table.coldatatype(col)));
               if(priv.debug)
                 print 'getdata ', dataType;
               if(dataType == 'FLOAT' || dataType == 'DOUBLE')
                  priv.col[col].format := priv.format;
               if(dataType == 'COMPLEX' || dataType == 'DCOMPLEX')
                  priv.col[col].format := priv.complexFormat;
            }
            keyrec := priv.table.getcolkeywords(col);
            if(!has_field(priv.col[col], 'hide')){
                if(has_field(keyrec, 'BROWSER_HIDE')){
                   if(is_boolean(keyrec.BROWSER_HIDE )){
                     priv.col[col].hide := keyrec.BROSWER_HIDE;
                   }
                }
                if(!is_boolean(priv.hide)){
                   if(any(to_upper(col) == priv.hide)){
                      priv.col[col].hide := T;
                   }
                }
                if(!is_boolean(priv.show)){
                   if(any(to_upper(col) == priv.show)){
                      priv.col[col].hide := F;
                   } else {
                      priv.col[col].hide := T;
                   }
                }
            }
            if(has_field(keyrec, 'BROWSER_LABEL')){
               priv.col[col].label := keyrec.BROWSER_LABEL
            } else {
               priv.col[col].label := col;
               if(priv.debug)
                  print 'getdata ', keyrec;
               if(has_field(keyrec, 'UNIT') &&
                  strlen(keyrec.UNIT) > 0){
                  if(has_field(keyrec, 'MEASURE_TYPE') &&
                     strlen(keyrec.MEASURE_TYPE) > 0){
                     if(keyrec.MEASURE_TYPE == 'MPOSITION'){
                        refpos := '';
                        if(has_field(keyrec, 'MEASURE_REFERENCE')){
                           refpos := keyrec.MEASURE_REFERENCE;
                        }
                        priv.col[col].label := spaste(col, '(', refpos, 
                                               ' - long, lat, height)');
                     } else if(keyrec.MEASURE_TYPE == 'RADIALVELOCITY'){
                        refpos := '';
                        if(has_field(keyrec, 'MEASURE_REFERENCE')){
                           refpos := keyrec.MEASURE_REFERENCE;
                        }
                        priv.col[col].label := spaste(col, '(', refpos,
                                                      ' ', keyrec.UNIT, ')');
                     } else if(keyrec.MEASURE_TYPE == 'DIRECTION'){
                        refpos := '';
                        if(has_field(keyrec, 'MEASURE_REFERENCE')){
                           refpos := keyrec.MEASURE_REFERENCE;
                        }
                        priv.col[col].label := spaste(col, '(', refpos,
                                                      ' RA, Dec)');
                     } else if(keyrec.MEASURE_TYPE == 'EPOCH') {
                        refpos := '';
                        if(has_field(keyrec, 'MEASURE_REFERENCE') &&
                           strlen(keyrec.MEASURE_REFERENCE) > 0){
                           refpos := keyrec.MEASURE_REFERENCE;
                           priv.col[col].label := spaste(col, '(',refpos, ')');
                        } else {
                           priv.col[col].label := col;
                        }
                     } else if(keyrec.MEASURE_TYPE == 'FREQUENCY') {
                        tabmeas := 
                         dq.quantity(1.0, keyrec.UNIT);
                         theUnit := split(dq.form.tablefreq(tabmeas,
                                          showunit=T));
                        if(len(theUnit) > 1){
                           priv.col[col].units := theUnit[2];
                           priv.col[col].label :=
                               spaste(col, '(',theUnit[2], ')');
                        } else {
                           priv.col[col].units := theUnit;
                           priv.col[col].label :=
                               spaste(col, '(',theUnit, ')');
                        }
                     } else {
                        priv.col[col].label :=
                            spaste(col, '(',keyrec.UNIT, ')');
                     }
                  } else {
                     priv.col[col].label :=
                         spaste(col, '(',keyrec.UNIT, ')');
                  }
               } else if(has_field(keyrec, 'QuantumUnits')){
                  if(has_field(keyrec, 'MEASINFO') && has_field(keyrec.MEASINFO, 'type')){
                     if(keyrec.MEASINFO.type == 'direction'){
                        refpos := '';
                        if(has_field(keyrec.MEASINFO, 'Ref')){
                           refpos := keyrec.MEASINFO.Ref;
                        }
                        priv.col[col].label := spaste(col, '(', refpos,
                                                      ' RA, Dec)');
                     } else if(keyrec.MEASINFO.type == 'epoch' 
                             || keyrec.MEASINFO.type == 'uvw'
                             || keyrec.MEASINFO.type == 'position'){
                        refpos := '';
                        if(has_field(keyrec.MEASINFO, 'Ref') &&
                           strlen(keyrec.MEASINFO.Ref) > 0){
                           refpos := keyrec.MEASINFO.Ref;
                           priv.col[col].label := spaste(col, '(',refpos, ')');
                        } else {
                           priv.col[col].label := col;
                        }
                     } else if(keyrec.MEASINFO.type == 'radialvelocity'){
                           # Need to get unit into this mix.
                        refpos := '';
                        if(has_field(keyrec.MEASINFO, 'Ref') &&
                           strlen(keyrec.MEASINFO.Ref) > 0){
                           refpos := keyrec.MEASINFO.Ref;
                           priv.col[col].label := spaste(col, '(', keyrec.QuantumUnits, ' ',
                                                         refpos, ')');
                        } else {
                           priv.col[col].label := col;
                        }
                     } else if(keyrec.MEASINFO.type == 'frequency') {
                        tabmeas := 
                         dq.quantity(1.0, keyrec.QuantumUnits);
                         theUnit := split(dq.form.tablefreq(tabmeas,
                                          showunit=T));
                        if(len(theUnit) > 1){
                           priv.col[col].units := theUnit[2];
                           priv.col[col].label :=
                               spaste(col, '(',theUnit[2], ')');
                        } else {
                           priv.col[col].units := theUnit;
                           priv.col[col].label :=
                               spaste(col, '(',theUnit, ')');
                        }
                     } else {
                        # print paste(col, 'MEASINFO: ', keyrec.MEASINFO);
                        priv.col[col].label :=
                            spaste(col, '(',keyrec.QuantumUnits, ')');
                     }
                  } else {
                     priv.col[col].label :=
                         spaste(col, '(',keyrec.QuantumUnits, ')');
                  }
               }
               # print keyrec;
            }
            priv.col[col].keywords := keyrec;
            priv.getColData(col);
         }
      }
      # print 'getdata: ',time()-t1;
   }

   priv.measures2display := function(col, thedata, isscalar=F) {
      wider priv;
      rStat := F;
      if(has_field(priv.col[col].keywords, 'MEASURE_TYPE')){
         rowsNdisplay := priv.rows2read;
         if(rowsNdisplay > priv.table.nrows())
            rowsNdisplay := priv.table.nrows();
         if(priv.col[col].keywords.MEASURE_TYPE == 'EPOCH'){
            dq.setformat('dtime', 'utc');
            tabmeas := dq.quantity(thedata, priv.col[col].keywords.UNIT);
            priv.col[col].display := dq.form.dtime(tabmeas, showform=T);
            rStat := T;
         } else if(priv.col[col].keywords.MEASURE_TYPE == 'RADIALVELOCITY'){
            tabmeas := 
              dq.quantity(thedata, priv.col[col].keywords.UNIT);
            dq.setformat('vel', priv.col[col].keywords.UNIT);
            priv.col[col].display := dq.form.vel(tabmeas);
            if(isscalar){
              priv.col[col].display := priv.col[col].display  ~ s/[\[\],]//g;
              priv.col[col].display := split(priv.col[col].display)[1:rowsNdisplay];
            }
            rStat := T;
         } else if(priv.col[col].keywords.MEASURE_TYPE == 'FREQUENCY'){
            tabmeas := 
              dq.quantity(thedata, priv.col[col].keywords.UNIT);
            priv.col[col].display := dq.form.tablefreq(tabmeas);
            if(isscalar){
              priv.col[col].display := priv.col[col].display  ~ s/[\[\],]//g;
              priv.col[col].display := split(priv.col[col].display);
            }
            rStat := T;
         } else if(priv.col[col].keywords.MEASURE_TYPE == 'MPOSITION' &&
                   strlen(priv.col[col].keywords.MEASURE_REFERENCE)){
            arraylen := priv.rows2read;
            if(arraylen == -1 || arraylen > priv.table.nrows()){
               arraylen := priv.table.nrows();
            }
            priv.col[col].display := array('', arraylen, 1);
            dq.setformat('long', 'dms');
            dq.setformat('lat', 'dms');



            for(i in 1:rowsNdisplay){
              epos := dm.position(priv.col[col].keywords.MEASURE_REFERENCE, dq.unit([priv.col[col].data[,i]], priv.col[col].keywords.UNIT));
              priv.col[col].display[i] := paste(dq.form.long(epos.m0), dq.form.lat(epos.m1), dq.form.len(epos.m2));
            }
            rStat := T;
         } else if(priv.col[col].keywords.MEASURE_TYPE == 'DIRECTION' &&
                   strlen(priv.col[col].keywords.MEASURE_REFERENCE)){
            arraylen := priv.rows2read;
            if(arraylen == -1 || arraylen > priv.table.nrows()){
               arraylen := priv.table.nrows();
            }

            priv.col[col].display := array('', arraylen, 1);
            dq.setformat('long', 'hms');
            dq.setformat('lat', 'dms');

            lons := dq.quantity(thedata[1,], priv.col[col].keywords.UNIT);
            lats := dq.quantity(thedata[2,], priv.col[col].keywords.UNIT);

            tmplong := dq.form.long(lons);
            tmplat := dq.form.lat(lats);
            for(i in 1:rowsNdisplay){
              priv.col[col].display[i] := paste(tmplong[i], tmplat[i])
            }
            
            rStat := T;
         }
         if(is_fail(priv.col[col].display)){
            priv.col[col].display := 'Formatting failed!';
         }
         if(rStat && !isscalar){
            if(priv.debug){
               print 'measures2display shape', thedata::shape;
               print 'measures2display data', thedata;
               print 'measures2display display', priv.col[col].display;
            }
            priv.col[col].display::shape := thedata::shape;
         }
      }
      return rStat;
   }

   priv.tablemeasures2display := function(col, thedata, isscalar=F) {
      wider priv;
      rStat := F;
      if(has_field(priv.col[col].keywords, 'MEASINFO')){
         if(priv.debug)
            print 'Begin tablemeasures2display';
         rowsNdisplay := priv.rows2read;
         if(rowsNdisplay > priv.table.nrows())
            rowsNdisplay := priv.table.nrows();
         if(priv.col[col].keywords.MEASINFO.type == 'epoch'){
            dq.setformat('dtime', 'utc');
            tabmeas := dq.quantity(thedata, priv.col[col].keywords.QuantumUnits);
            if(priv.debug)
               print 'tablemeasures2display tabmeas ', tabmeas;
            priv.col[col].display := dq.form.dtime(tabmeas, showform=T);
            if(is_fail(priv.col[col].display)){
                # try reshaping
                oldshape := shape(tabmeas.value);
                dumshape := prod(oldshape);
                tabmeas.value::shape := dumshape;
                priv.col[col].display := dq.form.dtime(tabmeas, showform=T);
            }
            if(priv.debug)
               print 'tablemeasures2display display ', priv.col[col].display;
            rStat := T;
         } else if(priv.col[col].keywords.MEASINFO.type == 'radialvelocity'){
            tabmeas := 
              dq.quantity(thedata, priv.col[col].keywords.QuantumUnits);
            dq.setformat('vel', priv.col[col].keywords.QuantumUnits);
            priv.col[col].display := dq.form.vel(tabmeas);
            if(isscalar){
              priv.col[col].display := priv.col[col].display  ~ s/[\[\],]//g;
              priv.col[col].display := split(priv.col[col].display)[1:rowsNdisplay];
            }
            rStat := T;
         } else if(priv.col[col].keywords.MEASINFO.type == 'frequency'){
            tabmeas := 
              dq.quantity(thedata, priv.col[col].keywords.QuantumUnits);
            priv.col[col].display := dq.form.tablefreq(tabmeas);
            if(isscalar){
              priv.col[col].display := priv.col[col].display  ~ s/[\[\],]//g;
              priv.col[col].display := split(priv.col[col].display);
            }
            rStat := T;
         } else if(priv.col[col].keywords.MEASINFO.type == 'position' &&
                   strlen(priv.col[col].keywords.MEASINFO.Ref)){
            arraylen := priv.rows2read;
            if(arraylen == -1 || arraylen > priv.table.nrows()){
               arraylen := priv.table.nrows();
            }
            priv.col[col].display := array('', arraylen, 1);
            dq.setformat('long', 'dms');
            dq.setformat('lat', 'dms');



            if(any(priv.col[col].keywords.QuantumUnits != priv.col[col].keywords.QuantumUnits[1])){
               print 'A bug!';
            } else {
            for(i in 1:rowsNdisplay){
              epos := dm.position(priv.col[col].keywords.MEASINFO.Ref, dq.unit([thedata[,i]], priv.col[col].keywords.QuantumUnits[1]));
              priv.col[col].display[i] := paste(dq.form.long(epos.m0), dq.form.lat(epos.m1), dq.form.len(epos.m2));
            }
            }
            rStat := T;
         } else if(priv.col[col].keywords.MEASINFO.type == 'direction' &&
                   strlen(priv.col[col].keywords.MEASINFO.Ref)){
            arraylen := priv.rows2read;
            if(arraylen == -1 || arraylen > priv.table.nrows()){
               arraylen := priv.table.nrows();
            }

            priv.col[col].display := array('', arraylen, 1);
            dq.setformat('long', 'hms');
            dq.setformat('lat', 'dms');

            # print priv.col[col].keywords.MEASINFO.Ref, priv.col[col].keywords.QuantumUnits;
            # print priv.col[col].data[1,,], priv.col[col].data[2,,];
            #print shape(priv.col[col].data);
            lenshape := len(shape(thedata));
            if(priv.debug)
               print 'lenshape ', lenshape;
            if(lenshape == 3){
               lons := dq.quantity(thedata[1,,], priv.col[col].keywords.QuantumUnits[1]);
               lats := dq.quantity(thedata[2,,], priv.col[col].keywords.QuantumUnits[2]);
            } else if(lenshape == 2) {
               lons := dq.quantity(thedata[1,], priv.col[col].keywords.QuantumUnits[1]);
               lats := dq.quantity(thedata[2,], priv.col[col].keywords.QuantumUnits[2]);
            } else {
               lons := F;
               lats := F;
            }
            if(priv.debug)
               print lons, lat;
            tmplong := dq.form.long(lons);
            tmplat := dq.form.lat(lats);
            if(!is_fail(tmplong) && !is_fail(tmplat)){
               for(i in 1:rowsNdisplay){
                 priv.col[col].display[i] := paste(tmplong[i], tmplat[i])
               }
            } else {
               for(i in 1:rowsNdisplay){
                 priv.col[col].display[i] := 'Failed! Direction Format';
               }
            }
            rStat := T;
         }
         if(is_fail(priv.col[col].display)){
            priv.col[col].display := 'Formatting failed!';
         }
         if(rStat && !isscalar){
            if(priv.debug){
               print 'tablemeasures2display shape', thedata::shape;
               print 'tablemeasures2display data', thedata;
               print 'tablemeasures2display display', priv.col[col].display;
            }
            priv.col[col].display::shape := thedata::shape;
         }
         if(priv.debug)
            print 'End tablemeasures2display';
      }
      return rStat;
   }

     # Loads the data from the table into the .data and .display variables

   priv.getColData := function(col) {
      wider priv;
      # t1 := time();
      if(!(priv.table.coldatatype(col) ~ m/[Rr]ecord/)){
        if(priv.table.isscalarcol(col)){
          if(priv.rows2read < 0 || priv.rows2read >= priv.nrows){
             priv.col[col].data:= priv.table.getcol(col);
          } else {
             priv.col[col].data:= priv.table.getcol(col,
                           startrow=priv.cached.first, nrow=priv.rows2read);
          }
          # print priv.col[col].keywords
          # Note MEASURE_TYPE is the old style pretable measures way to handle measures
          # MEASINFO is the table measures way to handle measures in columns.
          #
          if(is_fail(priv.col[col].data)){
              priv.col[col].data[1:priv.nrows] := 'table.getcol failed!';
              priv.col[col].display[1:priv.nrows] := 'table.getcol failed!';
          }
	  doneit := F;
          if(has_field(priv.col[col].keywords, 'MEASURE_TYPE') &&
             strlen(priv.col[col].keywords.MEASURE_TYPE) > 0){
             doneit := priv.measures2display(col, priv.col[col].data, isscalar=T);
          } else if(has_field(priv.col[col].keywords, 'MEASINFO') &&
                    has_field(priv.col[col].keywords.MEASINFO, 'type') &&
                    strlen(priv.col[col].keywords.MEASINFO.type) > 0){
             doneit := priv.tablemeasures2display(col, priv.col[col].data, isscalar=T);
          }
	  if (!doneit) {
             if(is_byte(priv.col[col].data)){
                priv.col[col].data := as_integer(priv.col[col].data);
             }
             priv.col[col].display := as_string(priv.col[col].data);
          }
        } else  {
          priv.loadarray(col);
        }
      } else {
        priv.col[col].data[1:priv.nrows] := 'Record';
        priv.col[col].display[1:priv.nrows] := 'Record';
      }
      # print col, time()-t1;
   }
   
     # Some Notes: 
     #  There are three sets of numbers on the canvas to worry about
     #     Pos top-last topPos is the top Possible row to display
     #                  lastPos is the last Possible row to display
     #     Shown top-last topShown is the top row drawn on the canvas
     #                  lastShown is the last row drawn on the canvas
     #     Vis top-last topVis the top row visible on the canvas
     #                  lastVis is the last row visible on the canvas
     #
   priv.displayPage := function(startRow, rowsNPage, updown, setbusy=T) {
      wider priv;
      # t1 := time();
      if(setbusy)
         priv.f.busy(T);
      updown := 0.0;
      priv.c->delete('all');
      priv.rc->delete('all');
      vert := 1;
      priv.visH := priv.c->height();
      rowsVis := as_integer(priv.visH/priv.th);
      if(rowsNPage > priv.table.nrows())
         rowsNPage := priv.table.nrows();
      else if(rowsNPage < 0)
         rowsNPage := priv.table.nrows();
      if(startRow > 1){
         vert := 1;
         if((startRow + rowsNPage) > priv.cached.last){
            if(startRow + as_integer(0.75*rowsNPage) > priv.table.nrows()){
               priv.topVis := priv.table.nrows() - rowsNPage+1;
            } else {
               priv.topVis := startRow - as_integer(0.25*rowsNPage);
            }
            priv.getdata(priv.topVis, force=T);
         } else if((priv.cached.first > 1) &&
                  (startRow - as_integer(0.25*rowsNPage))<priv.cached.first){
            priv.topVis := startRow - as_integer(0.25*rowsNPage);
            priv.getdata(priv.topVis, force=T);
         }

         if(startRow < vert){
            priv.topPos := 1;
            priv.topShown := startRow;
            priv.topVis := 1;
            priv.lastVis := rowsNPage;
            priv.lastShown := rowsVis-1;
            priv.lastPos := rowsNPage;
         } else {
            priv.topPos := priv.cached.first - vert + 1;
            priv.topShown := startRow;
            priv.topVis := priv.topPos;
            priv.lastVis := priv.cached.first+rowsNPage-1;
            priv.lastShown := startRow+rowsVis-1;
            if(priv.lastShown > priv.table.nrows()){
               priv.lastShown := priv.table.nrows();
            }
            priv.lastPos := priv.topPos + rowsNPage;
         }

      } else {
         priv.topPos := 1;
         priv.topShown := startRow;
         priv.topVis := 1;
         priv.lastVis := rowsNPage;
         priv.lastShown := rowsVis;
         priv.lastPos := priv.viewHeight/priv.th;

         if(priv.cached.first > 1){
            priv.getdata(1, force=T);
         }
      }

        # Here we guard against going past the end of the table.
      if(priv.topShown > priv.table.nrows()-rowsVis){
         priv.topShown := priv.table.nrows()-rowsVis+1;
      }

      rows2draw := rowsNPage;
      if(priv.lastVis > priv.table.nrows()){
         priv.lastVis := priv.table.nrows();
      }
      lastdraw := vert+rows2draw -1;
      if((vert+rows2draw) > priv.table.nrows()){
         lastdraw := priv.table.nrows();
      }
      lastOne := priv.topPos+rows2draw-1;
      if(lastOne > priv.table.nrows()){
         lastOne := priv.table.nrows();
      }

          #insure lastdraw doesn't go past the end of the table.

     
      if(priv.topPos+lastdraw > priv.table.nrows()){
         lastdraw := priv.table.nrows()-priv.topPos+vert;
      }

      verts := [vert:lastdraw];

      #progressBar := progress(priv.topPos, lastOne,
      #            paste('AIPS++ Table', priv.table.name()), 'Rendering Rows');
      #progressBar.activate();

        # incase any thing has changed.
      doRows :=F;
      lastX := priv.setExes();
      priv.viewWidth := lastX+10;
      priv.lc->region(110,0, priv.viewWidth, priv.th);
      priv.rc->region(0, 0, priv.rcWidth, priv.viewHeight);
      priv.c->region(110, 0, priv.viewWidth, priv.viewHeight);
      priv.dolabels();	       

      if(doRows){
         yPlaces := priv.th*verts;
         rowTags := array('',1, len(verts));
         for(i in verts){
            rowCnt := priv.topPos + i - vert;
            # progressBar.update(priv.topPos+i);
            priv.rc->text(20, yPlaces[i], text=as_string(rowCnt),
                          tag='rowcell');
            datai := rowCnt - priv.cached.first + 1;
            rowTags[i] := spaste('Row:',datai);
            priv.displayRow(datai, yPlaces[i], rowTags[i]);
         }
      } else {
         if(priv.table.nrows() > 0){
            why := as_string(priv.topPos-1+verts);
	    for(field in priv.displayCols){
               priv.displayCol(field);
            }
            priv.setWhys();
	    for(field in priv.displayCols){
               priv.displayCol(field, T);
            }
	    if (priv.isgtk) {
		# gtk can display things as vectors, rivet can't
		#whys := [1:len(verts)]*priv.th;
		priv.rc->text(1, priv.whys, text=why, tag='rowcell', anchor='nw',
			      font=priv.fn);
	    } else {
		priv.rc->text(20, priv.th, text=paste(why,sep='\n'), tag='rowcell', anchor='n',
			      font=priv.fn);
	    }
         }
      }
      #progressBar.deactivate();
      if(has_field(priv, 'pickedRows')){
         priv.selectrows(priv.pickedRows);
      }
      if(has_field(priv, 'selectedCols')){
         for(col in priv.selectedCols){
            priv.selectcol(col);
         }
      }
      a := [(priv.topShown)/priv.table.nrows(),
               (priv.topShown+rowsVis)/priv.table.nrows()];
      priv.vsb->view(a);

      updown := (priv.topShown-priv.topPos+0.5)/priv.rows2read;
      if(priv.rows2read == -1 || priv.rows2read > priv.table.nrows()){
         updown := 0;
      }
      # print updown;
      eh := paste('yview moveto', updown);
      priv.c->view(eh);
      priv.rc->view(eh);

      if(setbusy)
         priv.f.busy(F);
      # print 'displayPage: ', time()-t1;
   }

      # Set the x coordinates for the columns
   priv.setExes := function() {
      wider priv;
      xPlace := 110;
      w := 0;
      colCount := 1;
      displayCols := '';
      for(field in field_names(priv.col)){
         w := priv.setColumnWidth(field, colCount);
         if(!has_field(priv.col[field], 'hide')  || !priv.col[field].hide ){
            priv.col[field].x := xPlace;
            if(priv.debug){
               print 'setExes', field, priv.col[field].x
            }
            priv.colX[colCount] := xPlace;
            xPlace := xPlace + priv.delX[field];
            displayCols := paste(displayCols, field, sep='!');
         } else {
            priv.col[field].x := -999;
            priv.colX[colCount] := -999;
         }
         colCount := colCount + 1;
      }
      priv.displayCols := split(displayCols, '!');
      if(priv.debug)
         print 'setExes', priv.displayCols;
      return (xPlace+w);
   }
      #
      # Draws a row on the canvas, datai the actual row in the table, yPlace
      #    is the canvas y-coordinate.
      #
      # In principle we could render the entire row adding the appropriate
      # number of spaces. This would limit the number of calls to
      #
   priv.displayRow1 := function(datai, yPlace, rowTag){
      wider priv;
      rowTag := spaste('Row:',datai);
      rowText := '';
      for(i in 1:len(priv.col)){
         if(priv.colX[i] > 0){
            cellTag := spaste('loc', priv.colX[i],':',yPlace);
            rowText := paste(rowText, cellTag);
         }
         priv.c->text(priv.colX[1], yPlace, text=rowText, font=priv.fn,
                          tag=['cell', rowTag], anchor='w');
      }
   }
   priv.displayRow := function(datai, yPlace, rowTag){
      wider priv;
      for(field in priv.displayCols){
            stat := priv.displayCell(field, datai, yPlace, rowTag)
      }
   }

   priv.setWhys := function(){
      wider priv;
      dIncr := 0;
      if(len(priv.newlines) > 1){
         for(i in 2:len(priv.newlines)){
             dIncr +:= priv.newlines[i-1];
             priv.whys[i] := priv.whys[i] + dIncr*priv.th;
         }
      }
      dIncr +:= priv.newlines[len(priv.newlines)];
      # Need to adjust the canvas size now
      priv.viewHeight := priv.whys[len(priv.whys)]+(dIncr+1)*priv.th;
      priv.rc->region(0, 0, priv.rcWidth, priv.viewHeight);
      priv.c->region(110, 0, priv.viewWidth, priv.viewHeight);
   }
   priv.displayCol := function(field, displayonly=F) {
      wider priv;
      field_tag := field ~ s/ /_/g
      priv.c->delete(field_tag);
      if (priv.isgtk) {
	  # gtk can display things as vectors, rivet can't
          if(priv.nowhys){
             priv.col[field].display;
	     priv.whys := [1:len(priv.col[field].display)]*priv.th;
             priv.nowhys := F;
             priv.newlines := priv.whys*0;
          }
            # Ok we check for embedded newlines in a column
          theText := priv.col[field].display ~ s/\n*$//;
          theText ~:= s/^\n*//;
          if(!displayonly && any(theText ~ m/\n/)){
             dIncr := 0;
             priv.newlines +:= theText ~ m/\n/g; 
          }
	  if(has_field(priv.col[field], 'x')){
	      priv.c->text(priv.col[field].x, priv.whys,
                           text=theText,
			   font=priv.fn, anchor='nw', tag=field_tag);
             if(priv.debug){
                print 'displayCol x', field, priv.col[field].x;
                print 'displayCol whys', field, whys;
                print 'displayCol display', field, priv.col[field].display;
             }
          }
      } else {
	  colText := paste(priv.col[field].display, sep='\n');
	  if(has_field(priv.col[field], 'x'))
	      priv.c->text(priv.col[field].x, priv.th, text=colText,
			   font=priv.fn, tag=field_tag, anchor='nw');
      }
   }

   priv.olddisplayCol := function(field) {
      wider priv;
      priv.c->delete(field);
      colText := paste(priv.col[field].display, sep='\n');
      if(has_field(priv.col[field], 'x'))
         priv.c->text(priv.col[field].x, priv.th, text=colText,
                 font=priv.fn, tag=field, anchor='nw');
   }

     #
     # Display the values for a given cell.  At some point we'll just load
     # everything into the display field and can ignore all the .data formating
     #
   priv.displayCell := function(field, datai, yPlace, rowTag) {
      wider priv;
      cellTag := paste(field,rowTag);
      if(has_field(priv.col[field], 'display')){
        dText := priv.col[field].display[datai];
      } else {
        if(has_field(priv.col[field], 'vector') &&
           (priv.col[field].vector < priv.displayVector)){
           if(len(priv.col[field].vector) == 1){
              d := priv.col[field].data[,datai];
           } else {
              d := priv.col[field].data[,,datai];
           }
           dText := paste(d);
        } else {
           # This part should never be executed, since display should
           # be set.
           dText := as_string(priv.col[field].data[datai]);
        }
      }
      priv.c->text(priv.col[field].x, yPlace, text=dText, font=priv.fn,
                    tag=[cellTag, 'cell', rowTag], anchor='w');
   }

      # Lots of cell/row selections now follow, fired off from the canvas
      # bindings.

   priv.unpick:= function(xyPt) {
      # print 'priv.unpick';
      wider priv;
      delx := 120;
      b := priv.colX[(xyPt[1]-delx/2) < priv.colX]
      col := b[1];
      row := as_integer(xyPt[2]/priv.th);
      rowid := spaste('Row:',row+priv.topPos-1,'Col:',col);
      priv.c->delete(rowid);
   }

   priv.unpickrow:= function(xyPt) {
      wider priv;
      row := as_integer(xyPt[2]/priv.th);
      rowid := spaste('Row:',row+priv.topPos-1);
      priv.rc->delete(rowid);
      priv.c->delete('boxed');
   }
     # Select an entire column
   priv.selectcol := function(colName) {
     wider priv;
     priv.rc->delete('boxed');
     priv.c->delete('boxed');
     col := priv.col[colName].x;
     delx := priv.delX[colName]
     for(row in 1:priv.rows2read){
         rowid := spaste('Row:',row+priv.topPos-1,'Col:',col);
         stopdraw := col+delx-10;
      
         priv.c->rectangle(col, row*priv.th, stopdraw,
                           (row+1)*priv.th, tag=rowid);
         priv.c->addtag('boxed', rowid);
     }
   }
      # Select a bunch of rows

   priv.selectrows := function(ref rows2pick) {
      wider priv;
      delx := 120;
      rowsvis := rows2pick[rows2pick > (priv.topPos -1 )];
      rowsvis := rowsvis[rowsvis < (priv.lastPos +1)];
      priv.rc->delete('boxed');
      priv.c->delete('boxed');
      if(len(rowsvis) > 0){
         for(i in 1:len(rowsvis)){
            rowid := spaste('Row:',rowsvis[i]);
            row := rowsvis[i]-priv.topPos+1;
            priv.rc->rectangle(0, row*priv.th, delx/2,
                               row*priv.th+priv.th, tag=rowid);
            priv.c->rectangle(0, row*priv.th,
                              priv.colX[len(priv.colX)]+delx/2,
                              row*priv.th+priv.th, tag=rowid);
            priv.rc->addtag('boxed', rowid);
            priv.c->addtag('boxed', rowid);
         }
      }
   }

     # Select one row

   priv.pickrow := function(xyPt, clear=T) {
      wider priv;
      delx := 2*priv.rcWidth;
      row := as_integer(xyPt[2]/priv.th);
      # print row+priv.topPos-1;
      if(clear){
         priv.c->delete('boxed');
         priv.rc->delete('boxed');
      }
      rowid := spaste('Row:',row+priv.topPos-1);
      priv.rc->rectangle(0, row*priv.th, delx/2,
                            row*priv.th+priv.th, tag=rowid);
      priv.c->rectangle(0, row*priv.th,
                           priv.colX[len(priv.colX)]+delx/2,
                           row*priv.th+priv.th, tag='boxed');
      priv.rc->addtag('boxed', rowid);
      # print rowid;
   }

      # This function is used when the user clicks on a cell, there's lots of
      # messy screen handling stuff going on here.  Be wary.

   priv.pick := function(xyPt, clear=T) {
      wider priv;
      wider ws;
      col := (priv.colX[(xyPt[1]-priv.delx) < priv.colX])[1];
      delx := (priv.delx[(xyPt[1]-priv.delx) < priv.colX])[1];
      row := as_integer(xyPt[2]/priv.th);
      offset := priv.topPos+row-priv.cached.first;
      if(offset > 0 && offset <= priv.table.nrows()) {
         if(clear){
            priv.c->delete('boxed');
            priv.rc->delete('boxed');
         }
         theVal := priv.col[priv.columnNames[priv.colX==col]].display[offset];

         rowid := spaste('Row:',row+priv.topPos-1,'Col:',col);
         stopdraw := col+delx-10;
      
         priv.c->rectangle(col, row*priv.th, stopdraw,
                           row*priv.th+priv.th, tag=rowid);
         priv.c->addtag('boxed', rowid);

         # If we're an array but not fully displayed fire off an array browser

         if(theVal ~ m/\[[0-9][ ,0-9]*\][A-Za-z]/){
            a := priv.table.getcell(priv.columnNames[priv.colX == col],
                                    row+priv.topPos - 1);
            newabTitle := paste(priv.columnNames[priv.colX == col],
                              'at row ',row+priv.topPos-1);
            priv.nab := newab(a, newabTitle, plotter=priv.plotter);
         } else if(theVal ~ m/Record/) {
            a := priv.table.getcell(priv.columnNames[priv.colX == col],
                                    row+priv.topPos - 1);
            newrbTitle := paste(priv.columnNames[priv.colX == col],
                              'at row ',row+priv.topPos-1);
            priv.rb := ws.recordbrowser(F, a, readonly=!priv.edit);
            priv.rb->title(newrbTitle);
            priv.popCount := priv.popCount + 1;
            priv.popups[as_string(priv.popCount)] := ref priv.rb;
         } else {
               # Otherwise if we're in an editing mode try put an entry frame
               # on the canvas and Tally Ho!
            if(priv.edit){
                  # Grab the old stuff and necessary and update the Cell
               if(has_field(priv.ed, 'e') && is_agent(priv.ed.e)){
                  updatedVal :=  priv.ed.e->get();
                  #col := priv.columnNames[priv.colX == col];
                  priv.updateCell(priv.lastCol, priv.lastRow, updatedVal);
                  priv.ed.e := 0;
                  priv.ed.f := 0;
               }

               xpos := col;
               if(xpos < 0)
                  xpos := 0;
               priv.ed.f := priv.c->frame(xpos, row*priv.th-priv.th*0.5,
                              height=priv.th, expand='x', background='white');

                 # Well I don't know why it's .6 and not .7 if delx > 110
                 # but hey it works.

               if(delx > 110)
                  textWidth := as_integer(0.5+delx/(priv.ptsPerChar*0.6));
               else 
                  textWidth := as_integer(0.5+delx/(priv.ptsPerChar*0.7));
               priv.ed.e := ws.entry(priv.ed.f, font=priv.fn, width=textWidth,
                                  background='white');
               priv.ed.e->insert(theVal);
               whenever priv.ed.e->return  do {
                   updatedVal :=  priv.ed.e->get();
                   # save updateVal to table
                   priv.updateCell(col, row, updatedVal);
                   priv.ed.e := 0;
                   priv.ed.f := 0;
               }
            }
         }
            # Keep track of last row and column if we point to another cell

         priv.lastRow := row;
         priv.lastCol := col;
      } 
   }

   # Update the value of a cell, col is column in canvas coordinates,
   # row is the row number in the table, and updatedVal is the new value
   # to put in the cell

priv.updateCell := function (col, row, updatedVal){
   wider priv;
   yPlace := row*priv.th;
   # print priv.columnNames[priv.colX == col], row, updatedVal;
   colName := priv.columnNames[priv.colX == col];
   datai := row + priv.topPos - 1;
   rowTag := spaste('Row:',datai);
   cellTag := colName;
   theVal := priv.col[colName].display[row];
   if(priv.debug)
      print "priv.updateCell theVal ", theVal, " ", theVal::shape;
   if(theVal != updatedVal){
      newval := F;
      priv.editCount := priv.editCount + 1;
      edCount := as_string(priv.editCount);
      priv.changes[edCount] := [=];
      priv.changes[edCount].col := colName;
      priv.changes[edCount].row := datai;
      priv.changes[edCount].cellTag := cellTag;
      
      # Old style

      if(has_field(priv.col[colName].keywords, 'MEASURE_TYPE')){
         if(priv.col[colName].keywords.MEASURE_TYPE == 'EPOCH'){
            mymeas := dm.epoch(priv.col[colName].keywords.MEASURE_REFERENCE,
                               updatedVal);
            newval := [=];
            if(has_field(priv.col[colName].keywords, 'UNIT') &&
               strlen(priv.col[colName].keywords.UNIT) > 0 &&
               !is_boolean(mymeas)){
               newval:= dq.convert(mymeas.m0, priv.col[colName].keywords.UNIT);
            }
         } else if(priv.col[colName].keywords.MEASURE_TYPE == 'MPOSITION'){
            posvec := split(updatedVal);
            mymeas := dm.position(priv.col[colName].keywords.MEASURE_REFERENCE,
                                  posvec[1], posvec[2],
                                  spaste(posvec[3],posvec[4]));
            newval := [=];
            if(has_field(priv.col[colName].keywords, 'UNIT') &&
               strlen(priv.col[colName].keywords.UNIT) > 0 &&
               !is_boolean(mymeas)){
               if(mymeas.m0.unit == 'm'){
                  theval:= dq.convert(mymeas.m0,
                                      priv.col[colName].keywords.UNIT);
                  newval.value[1] := theval.value;
                  theval:= dq.convert(mymeas.m1,
                                      priv.col[colName].keywords.UNIT);
                  newval.value[2] := theval.value;
                  theval:= dq.convert(mymeas.m2,
                                      priv.col[colName].keywords.UNIT);
                  newval.value[3] := theval.value;
               } else {
                  theval:= dq.convert(mymeas.ev0,
                                      priv.col[colName].keywords.UNIT);
                  newval.value[1] := theval.value;
                  theval:= dq.convert(mymeas.ev1,
                                      priv.col[colName].keywords.UNIT);
                  newval.value[2] := theval.value;
                  theval:= dq.convert(mymeas.ev2,
                                      priv.col[colName].keywords.UNIT);
                  newval.value[3] := theval.value;
               }
             
            }
         } else if(priv.col[colName].keywords.MEASURE_TYPE == 'DIRECTION'){
            dirvec := split(updatedVal);
            mymeas := dm.direction(priv.col[colName].keywords.MEASURE_REFERENCE,
                                  dirvec[1], dirvec[2]);
            newval := [=];
            if(has_field(priv.col[colName].keywords, 'UNIT') &&
               strlen(priv.col[colName].keywords.UNIT) > 0 &&
               !is_boolean(mymeas)){
               theval:= dq.convert(mymeas.m0, priv.col[colName].keywords.UNIT);
               newval.value[1] := theval.value;
               theval:= dq.convert(mymeas.m1, priv.col[colName].keywords.UNIT);
               newval.value[2] := theval.value;
            }
         } else if(priv.col[colName].keywords.MEASURE_TYPE == 'FREQUENCY'){
            if(has_field(priv.col[colName], 'units')){
               if(priv.debug)
                  print updatedVal;
               mymeas := dq.quantity(eval(updatedVal),
                                          priv.col[colName].units);
               newval := dq.convertfreq(mymeas,
                                        priv.col[colName].keywords.UNIT);
            }
         }
      } 

      # Tablemeasures style

      if(has_field(priv.col[colName].keywords, 'MEASINFO') && 
         has_field(priv.col[colName].keywords.MEASINFO, 'type')){
         if(priv.col[colName].keywords.MEASINFO.type == 'epoch'){
            mymeas := dm.epoch(priv.col[colName].keywords.MEASINFO.Ref,
                               updatedVal);
            newval := [=];
            if(has_field(priv.col[colName].keywords, 'QuantumUnits') &&
               strlen(priv.col[colName].keywords.QuantumUnits) > 0 &&
               !is_boolean(mymeas)){
               newval:= dq.convert(mymeas.m0, priv.col[colName].keywords.QuantumUnits);
            }
         } else if(priv.col[colName].keywords.MEASINFO.type == 'position'){
            posvec := split(updatedVal);
            mymeas := dm.position(priv.col[colName].keywords.MEASINFO.Ref,
                                  posvec[1], posvec[2],
                                  spaste(posvec[3],posvec[4]));
            newval := [=];
            if(has_field(priv.col[colName].keywords, 'QuantumUnits') &&
               strlen(priv.col[colName].keywords.QuantumUnits) > 0 &&
               !is_boolean(mymeas)){
               if(mymeas.m0.unit == 'm'){
                  theval:= dq.convert(mymeas.m0,
                                      priv.col[colName].keywords.QuantumUnits);
                  newval.value[1] := theval.value;
                  theval:= dq.convert(mymeas.m1,
                                      priv.col[colName].keywords.QuantumUnits);
                  newval.value[2] := theval.value;
                  theval:= dq.convert(mymeas.m2,
                                      priv.col[colName].keywords.QuantumUnits);
                  newval.value[3] := theval.value;
               } else {
                  theval:= dq.convert(mymeas.ev0,
                                      priv.col[colName].keywords.QuantumUnits);
                  newval.value[1] := theval.value;
                  theval:= dq.convert(mymeas.ev1,
                                      priv.col[colName].keywords.QuantumUnits);
                  newval.value[2] := theval.value;
                  theval:= dq.convert(mymeas.ev2,
                                      priv.col[colName].keywords.QuantumUnits);
                  newval.value[3] := theval.value;
               }
             
            }
         } else if(priv.col[colName].keywords.MEASINFO.type == 'direction'){
            dirvec := split(updatedVal);
            mymeas := dm.direction(priv.col[colName].keywords.MEASINFO.Ref,
                                  dirvec[1], dirvec[2]);
            newval := [=];
            if(has_field(priv.col[colName].keywords, 'QuantumUnits') &&
               strlen(priv.col[colName].keywords.QuantumUnits) > 0 &&
               !is_boolean(mymeas)){
               theval:= dq.convert(mymeas.m0, priv.col[colName].keywords.QuantumUnits);
               newval.value[1] := theval.value;
               theval:= dq.convert(mymeas.m1, priv.col[colName].keywords.QuantumUnits);
               newval.value[2] := theval.value;
            }
         } else if(priv.col[colName].keywords.MEASINFO.type == 'frequency'){
            if(has_field(priv.col[colName], 'units')){
               if(priv.debug)
                  print updatedVal;
               mymeas := dq.quantity(eval(updatedVal),
                                          priv.col[colName].units);
               newval := dq.convertfreq(mymeas,
                                        priv.col[colName].keywords.QuantumUnits);
            }
         } else if(priv.col[colName].keywords.MEASINFO.type == 'radialvelocity'){
            if(has_field(priv.col[colName], 'units')){
               if(priv.debug)
                  print updatedVal;
               mymeas := dq.quantity(eval(updatedVal),
                                          priv.col[colName].units);
               newval := dq.convertvel(mymeas,
                                        priv.col[colName].keywords.QuantumUnits);
            }
         }
      } 

      if(is_complex(priv.col[colName].data) || is_dcomplex(priv.col[colName].data)){
         mymeas := updatedVal;
         if( mymeas ~ m/@/){
              # OK split the amplitude and phase, turn it into a vector
              # if we need to do that, then generate the real and imaginary
              # parts.
            ampPhase := as_float(split(mymeas, '@, []'));
            amp := ampPhase[ind(ampPhase)%2 == 1];
            phase := ampPhase[ind(ampPhase)%2 == 0];
            rPart := amp*cos(pi*phase/180.0);
            iPart := amp*sin(pi*phase/180.0);
            newval := [=];
              # I'm not at all sure this is right since there could easily
              # be some array conformance problems.  putcell needs to be redone
              # so it conforms a plain vector to an array of (,1,n) or (, n,1)
            newval.value := array(complex(rPart, iPart), len(rPart), 1);
         }
      }
     
      if(split(priv.table.coldatatype(colName)) == 'String'){
         stat := priv.table.putcell(colName, datai, updatedVal);
         priv.changes[edCount].old := theVal;
      } else {
         if(!is_boolean(newval)){
            if(!is_boolean(mymeas)){
               priv.changes[edCount].old := priv.table.getcell(colName, datai);
               stat := priv.table.putcell(colName, datai, newval.value);
               if(!is_fail(stat)){
                  priv.changes[edCount].oldDisplay := theVal;
               }
            } else {
               stat := -1;
            }
         } else {
            stat := priv.table.putcell(colName, datai, eval(updatedVal));
            if(!is_fail(stat)){
               priv.changes[edCount].doeval := theVal;
            }
         }
      }
      if(!is_fail(stat) && stat != -1){

           # replace the numbers in the data vector

         priv.col[colName].display[row] := updatedVal;
         if(split(priv.table.coldatatype(colName)) == 'String'){
            priv.updateData(colName, row, updatedVal);
         } else if(!is_boolean(newval)) {
            priv.updateData(colName, row, newval.value);
         } else {
            priv.updateData(colName, row, eval(updatedVal));
         } 
            # Well if the text string is too big then redraw

         newWidth := (strlen(updatedVal)*priv.ptsPerChar*0.7)+10;
         if(newWidth <= priv.delX[priv.columnNames[priv.colX == col]]){
            priv.displayCol(colName);
         } else {
            priv.redrawPage();
         }
         priv.needsSaving->returns(T);
          
      } else {
         if(is_fail(stat)){
            priv.note(paste('Table:', priv.table.name(),
			    'cell not changed!', stat),
		      priority='SEVERE');
         }
         priv.changes[edCount] := [=];
         priv.editCount := priv.editCount - 1;
      }
      priv.f.app.mb.btns.editundo->disabled(F);
   }
}
   priv.redrawPage := function() {
      wider priv;
      priv.displayPage(priv.topShown, priv.rows2read, 0.0);
   }

   # Update the cell data in the table itself

   priv.updateData := function(col, row, updatedVal){
      wider priv;
      offset := priv.topPos+row-priv.cached.first;
      if(has_field(priv.col[col], 'vector')){
   
         if(len(priv.col[col].vector) ==  1 &&
            priv.col[col].vector < priv.displayVector &&
            has_field(priv.col[col], 'data')){
            priv.col[col].data[,offset] := updatedVal;
         } else {
            priv.col[col].data[,,offset] := updatedVal;
         }
      } else {
         if(is_string(updatedVal)) {
            priv.col[col].data[offset] := updatedVal;
         } else {
             priv.col[col].data[offset] := updatedVal;
         }
      }
   }
     #
     # Here's the code for undoing,  Basically it takes a vector edit ids
     # and loops through them restoring the old values as it goes. In principle
     # we could swap the old with new but I think I'll just null it out for now
     #
   priv.undo := function(what2undo){
     wider priv;
     for(undoEd in as_string(what2undo)){
        if(is_record(priv.changes[undoEd])){
           if( has_field(priv.changes[undoEd], 'cellTag')){
              priv.note(paste('Undoing edit for column',
			      priv.changes[undoEd].col,
			      'row', priv.changes[undoEd].row),
			priority='INFO');
              if(has_field(priv.changes[undoEd], 'doeval')){
                 oldDisplay := priv.changes[undoEd].doeval;
                 oldData := eval(priv.changes[undoEd].doeval);
              } else {
                 oldData := priv.changes[undoEd].old;
                 if(has_field(priv.changes[undoEd],'oldDisplay'))
                    oldDisplay := priv.changes[undoEd].oldDisplay;
                 else 
                    oldDisplay := priv.changes[undoEd].old;
              }
              # OK revise the data in the cache
              priv.updateData(priv.changes[undoEd].col,
                              priv.changes[undoEd].row, oldData);
                 # update the table
              priv.table.putcell(priv.changes[undoEd].col,
                                 priv.changes[undoEd].row,
                                 oldData);
                 # redraw the the screen
              if(priv.changes[undoEd].row >= priv.topPos  &&
                 priv.changes[undoEd].row < priv.topPos+priv.rows2read){
                 priv.col[priv.changes[undoEd].col].display[priv.changes[undoEd].row - priv.topPos + 1] := oldDisplay;
                 priv.displayCol(priv.changes[undoEd].col);
              }
           } else if(has_field(priv.changes[undoEd], 'kwop')){
             # undo a keyword edit
               if(priv.changes[undoEd].kwop == 'modify'){
                  if(priv.changes[undoEd].col == 'table'){
                     stat := priv.table.putkeywords(
                              priv.changes[undoEd].keyrec);
                  } else {
                     stat := priv.table.putcolkeywords(
                              priv.changes[undoEd].col,
                              priv.changes[undoEd].keyrec);
                  }
                  if(is_fail(stat)){
                     priv.note(paste('Table:', priv.table.name(),
                                'keywords not changed!'),
			       priority='SEVERE');
                  }
               } else if(priv.changes[undoEd].kwop == 'remove'){
                  if(priv.changes[undoEd].col == 'table'){
                     stat := priv.table.putkeyword(
                              priv.changes[undoEd].keyword,
                              priv.changes[undoEd].old,);
                  } else {
                     stat := priv.table.putcolkeyword(
                              priv.changes[undoEd].col,
                              priv.changes[undoEd].keyword,
                              priv.changes[undoEd].old);
                  }
                  if(is_fail(stat)){
                     priv.note(paste('Table:', priv.table.name(),
				     'keywords not changed!'),
			       priority='SEVERE');
                  }
               }
           }
           priv.changes[undoEd] := F;
        }
     }
        # Now we reshuffle the edits
     newEdCount := 0;
     numEds := as_string([1:priv.editCount]);
     for(edI in numEds){
       if(is_record(priv.changes[edI])){
          newEdCount := newEdCount+1;
          priv.changes[as_string(newEdCount)] := priv.changes[edI];
       }
     }
     priv.editCount := newEdCount;
     if(priv.editCount == 0)
        priv.f.app.mb.btns.editundo->disabled(T);
   }

      # Open the table for displaying in the table browser.

   priv.opentable := function(tabHandle, newwin=F, refresh=F){
      wider priv;
      # t1 := time();
      lastX := 100;
      load := T;
      if(refresh){
         go2Row := priv.topShown;
      }
      if(!is_boolean(priv.table)){
         priv.table.close();
         priv.c->delete('all');
         priv.rc->delete('rowcell');
         priv.lc->delete('label');
      }
      rowsNcanvas := priv.rowsNcanvas;
      if(is_string(tabHandle)){
         if((is_string(tabHandle) && tableexists(tabHandle))){
            priv.closeTable := T;
            priv.table := table(tabHandle, readonly=!priv.edit);
            priv.table.lock(priv.edit, 10);
            if(is_fail(priv.table)){
               priv.note(priv.table, priority='SEVERE');
            }
            if(priv.table.nrows() > 0){
               if(priv.rows2read > priv.table.nrows()){
                  rowsNcanvas := priv.table.nrows()+1;
               }
            } else {
               priv.note('No rows in table!', priority='WARN');
               tmp4 := infowindow('No rows in table!');
               load := F;
            }
         } else {
            priv.note(paste('Table:',tabHandle,'not found!'),
		      priority='WARN');
            tmp3 := infowindow(paste('Table:', tabHandle, 'not found!'));
            load := F;
         }
      } else if(is_boolean(tabHandle)){
         load := F;
      } else {
         if(has_field(tabHandle, 'ok') && is_table(tabHandle)){
            priv.table := tabHandle;
            priv.table.lock(priv.edit, 10);
            if(priv.table.nrows() > 0){
               if(priv.rows2read > priv.table.nrows()){
                  rowsNcanvas := priv.table.nrows()+1;
               }
            } else {
               priv.note('No rows in table!', priority='WARN');
               tmp4 := infowindow('No rows in table!');
               load := F;
            }
         } else {
            priv.note(paste('Not a Table Handle: ',tabHandle), priority='WARN');
            tmp4 := infowindow(paste('Not a Table Handle: ', tabHandle));
            load := F;
         }
      }
      #print 'setup main window...';
      if(newwin){
         priv.mainwindow(rowsNcanvas) 
      }
      #print 'setup.';
      if(load){
         priv.f.busy(T);
         tName := priv.table.name();
         if(strlen(tName)){
            ptab := split(priv.table.name(), '/');
         } else {
            ptab := ['Un-named table'];
         }
         priv.f.updatetitle(paste('Table Browser (AIPS++) --', ptab[len(ptab)]));
         priv.f.updatestatus(paste(priv.table.name(), priv.table.ncols(),
                                   'columns by', priv.table.nrows(), 'rows'));
         #print 'Ready', time()-t1;
         lastX := priv.loadtable();
         #print 'Set', time()-t1;
         rows2view := priv.displayCache;
         if(priv.rows2read >= priv.table.nrows() || priv.displayCache < 0){
            rows2view := priv.table.nrows();
            priv.lastVis := rows2view;
            priv.lastShown := rows2view;
            priv.handleScrollBar := F;
         }
         if(refresh){
            priv.displayPage(go2Row, rows2view, 0.0, F);
         } else {
            priv.displayPage(1, rows2view, 0.0, F);
         }
         priv.setmenubtns();
         if(priv.table.nrows() > priv.rows2read){
            priv.vsb->jump(T);
            priv.handleScrollBar := T;
         } else {
            priv.vsb->jump(F);
         }
         priv.f.busy(F);
      }
      #print 'load etal: ', time()-t1;
      return lastX;
   }

   priv.toFromGlish := subsequence(col, readonly=T){
     wider priv;
     wider ws;
     if(readonly){
        Title := 'Save column to glish variable';
     } else {
        Title := 'Read glish variable into column';
     }
     f := ws.frame(title=Title)
     f1 := ws.frame(f, side='left');
     f2 := ws.frame(f, side='left');
     f3 := ws.frame(f2, side='left');
     f4 := ws.frame(f2, side='left');
     f5 := ws.frame(f2, side='left');
     l := ws.label(f1, 'Glish Variable:',font=priv.fn);
     e := ws.entry(f1);
     e->insert(col);
     b1 := ws.button(f4, 'Apply',font=priv.fn, type='action');
     b2 := ws.button(f4, 'Cancel',font=priv.fn, type='dismiss');
     whenever b1->press, e->return do{
        closeup := T;
        if(readonly){
           d := symbol_set(e->get(), priv.table.getcol(col));
        } else {
           newvals := symbol_value(e->get());
           r := priv.table.putcol(col, newvals)
           if(is_fail(r)){
             note(spaste('Failed to update the column!',
                       '\nColumn ', col, ' and variable ', e->get(),
                       ' not the same shape?'), priority='SEVERE');
             closeup := F;
           } else {
             self->import(T);
           }
        }
        if(closeup){
          e := 0;
          f:=0;
        }
     }
     whenever b2->press do {
        e := 0;
        f := 0;
     }

      whenever self->close do {
        f := 0;
      }

      priv.popCount := priv.popCount+1;
      priv.popups[as_string(priv.popCount)] := self;
   }


      # Add the column menu for each column

   priv.addcolmenu := function(ref mb, field){
      wider priv;
      wider ws;
      priv.col[field].mb := [=];
      opts := "Select Description Keywords Hide Format Getcol Putcol"
      dataType := priv.table.coldatatype(field);
      if(dataType == 'COMPLEX' || dataType == 'DCOMPLEX'){
         opts := "Select Description Keywords Hide View Format Getcol Putcol"
      }
      if(!priv.table.isscalarcol(field)){
         opts := "Select Description Keywords Hide Format Getcol Putcol"
      }
      for( opt in opts ){
         if(opt == 'View'){
            priv.col[field].mb[opt] := ws.button(mb, opt, type='menu',
                                        value=paste(opt, field),font=priv.fn);
         } else {
            priv.col[field].mb[opt] := ws.button(mb, opt,
                                        value=paste(opt, field),font=priv.fn);
         }
         whenever priv.col[field].mb[opt]->press do {
            menuReturn := split($value);
            if(menuReturn[1] == 'Format'){
               dum := priv.formatCol(menuReturn[2], priv.col[menuReturn[2]]);
               whenever dum->formatted do {
                  priv.displayPage(priv.topShown, priv.rows2read, 0.0);
               }
            } else if(menuReturn[1] == 'Description') {
               keyrec := priv.table.getcoldesc(menuReturn[2]);
               priv.popCount := priv.popCount + 1;
               priv.popups[as_string(priv.popCount)] := 
                    ws.recordbrowser(F, keyrec, readonly=!priv.edit,
                            title=paste('Column', menuReturn[2], 'description'));
            } else if(menuReturn[1] == 'Keywords') {
               keyrec := priv.table.getcolkeywords(menuReturn[2]);
               if(len(field_names(keyrec)) > 0 || priv.edit)
                  dum := kwpopup(menuReturn[2]);
               else
                  dum := infowindow(spaste('No keywords for column ', menuReturn[2],
                                    '.'));
            } else if(menuReturn[1] == 'Hide') {
                priv.col[menuReturn[2]].hide := T
                priv.dolabels();
                priv.displayPage(priv.topVis, priv.rows2read, 1);
            } else if(menuReturn[1] == 'Display') {
                dum := priv.displayArray(menuReturn[2],
                                         priv.col[menuReturn[2]]);
               whenever dum->redisplay do {
                  priv.displayPage(priv.topShown, priv.rows2read, 0.0);
               }
            } else if(menuReturn[1] == 'Select') {
                priv.col[menuReturn[2]].selected := T;
                priv.selectedCols := menuReturn[2];
                priv.selectcol(menuReturn[2]);
            } else if(menuReturn[1] == 'Putcol') {
               a := priv.toFromGlish(menuReturn[2], readonly=F);
               whenever a->import do {
                  priv.getColData(col);
                      # Well if the text string is too big then redraw

                  newWidth := max((strlen(priv.col[col].display)*priv.ptsPerChar*0.7)+10);
                  if(newWidth <= priv.delX[col]){
                     priv.displayCol(colName);
                  } else {
                     priv.redrawPage();
                  }
                  priv.needsSaving->returns(T);
               }
            } else if(menuReturn[1] == 'Getcol') {
               a := priv.toFromGlish(menuReturn[2]);
            }
         }
      }
      if(!priv.edit){
         priv.col[field].mb.Putcol->disabled(T);
      }
   }

      # Column formatting code.  We need to handle vectors too.

   priv.formatCol := subsequence(colName, ref colData) {
     wider priv;
     wider ws;
     f := ws.frame(title=spaste('Format for column ', colName))
     f1 := ws.frame(f, side='left');
     f2 := ws.frame(f, side='left');
     f3 := ws.frame(f2, side='left');
     f4 := ws.frame(f2, side='left');
     f5 := ws.frame(f2, side='left');
     l := ws.label(f1, 'Format:',font=priv.fn);
     e := ws.entry(f1);
     priv.help.formate := popuphelp(e, 'C-style formating');
     if(has_field(colData, 'format')){
        e->insert(colData.format);
     } else {
        e->insert('%8.3f');
     }
     b1 := ws.button(f4, 'Apply',font=priv.fn, type='action');
     b2 := ws.button(f4, 'Cancel',font=priv.fn, type='dismiss');
     whenever b1->press, e->return do{
        colData.format := spaste(e->get(), ' ');
        if(!has_field(colData, 'vector')){
           colData.display := sprintf(colData.format, colData.data);
        } else {
           priv.setVectorDisplay(colName);
        }
        w := priv.setColumnWidth(colName);
        e := 0;
        f:=0;
        self->formatted(T);
     }
     whenever b2->press do {
        e := 0;
        f := 0;
     }

     whenever self->close do {
        e := 0;
        f := 0;
     }
     priv.popCount := priv.popCount + 1;
     priv.popups[as_string(priv.popCount)] := self;
   }

      # Array Column code.

   priv.displayArray := subsequence(colName, ref colData) {
     wider priv;
     wider ws;
     f := ws.frame(title=spaste('Display Array Members for Column ', colName))
     f1 := ws.frame(f, side='left');
     f2 := ws.frame(f, side='left');
     f3 := ws.frame(f2, side='left');
     f4 := ws.frame(f2, side='left');
     f5 := ws.frame(f2, side='left');
     l := ws.label(f1, 'Display ');
     e := ws.entry(f1);
     e->insert('%8.3f');
     b1 := ws.button(f4, 'Apply',font=priv.fn, type='action');
     b2 := ws.button(f4, 'Cancel',font=priv.fn, type='dismiss');
     colData.members := [=];
     whenever b1->press, e->return do{
        showThese := e->get();
        colData.members.show := as_integer(split(showThese, sep=' ,'));
        howMany := len(colData.members.show);
        if(howMany > 0){
           colData.members.labels := array('', howMany, 1);
           for(i in l:howMany){
              colData.members.labels[i] := paste(colName, '-', i);
           }
        } else {
           colData.members := F;
        }
        e := 0;
        f:=0;
        self->redisplay(T);
     }
     whenever b2->press do {
        e := 0;
        f := 0;
     }

     whenever self->close do {
        e := 0;
        f := 0;
     }
     priv.popCount := priv.popCount + 1;
     priv.popups[as_string(priv.popCount)] := self;
   }

      # Label all those columns

   priv.dolabels := function() {
      wider priv;
      wider ws;
      priv.lc->delete('all');
      priv.setExes();
      for(field in priv.displayCols) {
      
         priv.lcol[field] := [=];
         priv.lcol[field].lf := priv.lc->frame(priv.col[field].x, 0,
                                       height=priv.th, width=priv.delX[field],
                                       expand='none', tag='label');
         priv.lcol[field].mb := ws.button(priv.lcol[field].lf,
                                      text=priv.col[field].label, type='menu',
                                      background='white', borderwidth=0, font=priv.fn);
         priv.addcolmenu(priv.lcol[field].mb, field);
         if((has_field(priv.col[field], 'noFormatVector') && 
            priv.col[field].noFormatVector) ||
            (has_field(priv.col[field], 'vector') &&
            priv.col[field].vector >= priv.displayVector)) {
            priv.col[field].mb.Format->disabled(T);
         }
      }
   }

   priv.sortedcolumns := function(){
     wider priv;
     allColumnNames := priv.table.colnames();
     displayCols := priv.table.getkeyword('BROWSER_DISPLAY_COLUMNS');
     if(is_fail(displayCols)){
        sortedColumnNames := allColumnNames;
     } else {
        # OK now we set the order and set the hide flag
        for(col in displayCols){
               # Need to trap error if col is not really a column in the table
           if(any(col == allColumnNames)){
              priv.col[col] := [=];
                 # set the default formatting for complex/real floats & doubles
              dataType := to_upper(split(priv.table.coldatatype(col)));
              if(dataType == 'FLOAT' || dataType == 'DOUBLE')
                 priv.col[col].format := priv.format;
              if(dataType == 'COMPLEX' || dataType == 'DCOMPLEX')
                 priv.col[col].format := priv.complexFormat;
              priv.col[col].hide := F;
           } else {
             priv.note(paste('tablebrowser: Column', col, 'missing from table'));
           }
        }
        alreadySet := field_names(priv.col);
        for(col in allColumnNames){
          if(!any(col == alreadySet)){
             priv.col[col] := [=];
                 # set the default formatting for complex/real floats & doubles
             dataType := to_upper(split(priv.table.coldatatype(col)));
             if(dataType == 'FLOAT' || dataType == 'DOUBLE')
              priv.col[col].format := priv.format;
             if(dataType == 'COMPLEX' || dataType == 'DCOMPLEX')
              priv.col[col].format := priv.complexFormat;
             priv.col[col].hide := T;
          }
        }
        sortedColumnNames := field_names(priv.col);
     }
     return sortedColumnNames;
   }

      # Set everything up

   priv.loadtable := function(){
      wider priv;
      priv.colX := F;
      priv.delx := F;
      priv.col := [=];
      lastX := 110;
      priv.nrows := priv.table.nrows();
      priv.columnNames := priv.sortedcolumns();

      priv.getdata(1, force=T);

      lastX := priv.setExes();
      if(priv.rows2read < 0 || priv.rows2read > priv.nrows)
        priv.rowsNcanvas := priv.nrows;
      else 
        priv.rowsNcanvas := priv.rows2read;
      priv.viewHeight := priv.th*(priv.rowsNcanvas+1);
      priv.viewWidth := lastX+10;
      priv.lc->region(110,0, priv.viewWidth, priv.th);
      priv.rc->region(0, 0, priv.rcWidth, priv.viewHeight);
      priv.c->region(110, 0, priv.viewWidth, priv.viewHeight);
      priv.lcol := [=];
      priv.dolabels();

      return lastX;
   }  

      # Sets the column width, note priv.delx is set outside

   priv.setColumnWidth := function (col, colCount=-1) {
     wider priv;
     columnWidth := 110;
     dum1 := F;
     dum2 := F;
     dum3 := F;
     if(has_field(priv.col[col], 'display')){
        theText := priv.col[col].display ~ s/ *//
        theText ~:= s/\n*$//;
        theText ~:= s/^\n*//;
        textWidth := max(strlen(split(theText ~ s/$/\n/, '\n')))*priv.ptsPerChar*0.7;
        if(columnWidth < textWidth)
           columnWidth := textWidth+10;
     } else {
        if(has_field(priv.col[col], 'data')){
           dum2 := as_string(priv.col[col].data);
        
           textWidth := max(strlen(dum2))*priv.ptsPerChar*0.7;
           if(columnWidth < textWidth){
              columnWidth := textWidth+10;
           }
        }
         
        if(has_field(priv.col[col], 'vector') &&
           priv.col[col].vector < priv.displayVector ){
           if(len(priv.col[col].vector) ==  1 &&
                  has_field(priv.col[col], 'data')){
               d := len(priv.col[col].data);
               for(i in 1:(d/priv.col[col].vector)){
                  dum3[i] := sum(strlen(as_string(priv.col[col].data[,i])));
               }
           } else {
              d := len(priv.col[col].data);
              for(i in 1:(d/prod(priv.col[col].vector))){
                  dum3[i] := sum(strlen(as_string(priv.col[col].data[,,i])));
              }
           }
           textWidth := max(dum3)*priv.ptsPerChar*0.8;
           if(columnWidth < textWidth){
              columnWidth := textWidth+10;
           }
        }
     }
     if(has_field(priv.col[col], 'label')){
        if(strlen(priv.col[col].label)*priv.ptsPerChar > (columnWidth-10)){
           columnWidth := strlen(priv.col[col].label)*priv.ptsPerChar + 10; 
        }
     } else {
        if(strlen(col)*priv.ptsPerChar > (columnWidth-10)){
           columnWidth := strlen(col)*priv.ptsPerChar + 10; 
        }
     }

     priv.delX[col] := columnWidth;
     if(colCount > 0){
        priv.delx[colCount] := columnWidth;
     } else {
        # print (col == priv.columnNames);
     }
     return columnWidth;
   }
     # figures out how to display a vector

   priv.loadarray := function(col){
      wider priv;
      arraytext := priv.table.getcolshapestring(col, priv.cached.first,
                                                priv.rows2read);

      if(priv.debug)
         print 'loadarray ', arraytext;
      # print 'loadarray ', col, priv.col[col].noFormatVector;
      priv.col[col].noFormatVector := F;
      if(len(arraytext) == 1) {
          dum := split(arraytext);
          nrows := priv.rows2read;
          if(nrows > priv.table.nrows() || nrows < 1){
             nrows := priv.table.nrows();
          }
          if(len(dum) == 1) {
            priv.col[col].vector := as_integer(arraytext ~ s/\[([0-9]*)\]/$1/);
            if(priv.col[col].vector < priv.displayVector){
               if(priv.rows2read == -1 || priv.rows2read > priv.table.nrows()){
                  priv.col[col].data := priv.table.getcol(col);
               } else {
                  priv.col[col].data := priv.table.getcol(col,
                             startrow=priv.cached.first, nrow=priv.rows2read);
               }
             } else {
                priv.col[col].data := array(spaste(arraytext,
                              priv.table.coldatatype(col)), 1, nrows);
                priv.col[col].display := priv.col[col].data;
             }
          } else {
             if((arraytext ~ m/\[1, [0-9]*\]/) ||
                (arraytext ~ m/\[[0-9]*, 1\]/)) {
                 dims := arraytext ~ s/\[([0-9]*), ([0-9]*)\]/$1 $2/;
                 eX := as_integer(split(dims)[1]);
                 wHy := as_integer(split(dims)[2]);
                 if(eX < priv.displayVector && wHy < priv.displayVector) {
                    priv.col[col].vector := [eX, wHy]
                    if(priv.rows2read == -1 || priv.rows2read > priv.table.nrows()){
                       priv.col[col].data := priv.table.getcol(col);
                    } else {
                       priv.col[col].data := priv.table.getcol(col,
                             startrow=priv.cached.first, nrow=priv.rows2read);
                    }
                 } else {
                   priv.col[col].data :=
                          array(spaste(arraytext,priv.table.coldatatype(col)),
                                1, nrows);
                   priv.col[col].display := priv.col[col].data;
                 }
             } else {
                priv.col[col].data := 
                        array(spaste(arraytext,priv.table.coldatatype(col)),
                              1, nrows);
                priv.col[col].display := priv.col[col].data;
             }
          }
          if(priv.debug)
             print 'loadarray ', col, priv.col[col].data;
      } else {
        if(is_fail(arraytext) || any(arraytext[1] != arraytext)){
           arraylen := priv.rows2read;
           if(priv.rows2read < 0 || priv.rows2read > priv.table.nrows()){
              arraylen := priv.table.nrows();
           }
           priv.col[col].data := array('dummy', 1, arraylen);
           if(!is_fail(arraytext)){
              for(i in 1:arraylen){
                 priv.col[col].data[i] := spaste(arraytext[i],
                                              priv.table.coldatatype(col));
              }
           }
           priv.col[col].noFormatVector := T;
        } else {
            if(len(split(arraytext[1])) == 1){
               priv.col[col].vector :=
                    as_integer(arraytext[1] ~ s/\[([0-9]*)\]/$1/);
               if(priv.col[col].vector < priv.displayVector){
                 if(priv.rows2read < 0 || priv.rows2read > priv.table.nrows()){
                    priv.col[col].data := priv.table.getcol(col);
                 } else {
                    priv.col[col].data := priv.table.getcol(col,
                             startrow=priv.cached.first, nrow=priv.rows2read);
                 }
               } else {
                  arraylen := priv.rows2read;
                  if(priv.rows2read == -1 ||
                     priv.rows2read > priv.table.nrows()){
                     arraylen := priv.table.nrows();
                  }
                  priv.col[col].data := array('dummy', 1, arraylen);
                  for(i in 1:len(arraytext)){
                     priv.col[col].data[i] := spaste(arraytext[i],
                                              priv.table.coldatatype(col));
                  }
                  priv.col[col].noFormatVector := T;
               }
            } else {
              if((arraytext[1] ~ m/\[1, [0-9]*\]/) ||
                    (arraytext[1] ~ m/\[[0-9]*, 1\]/)){
                 dims := arraytext[1] ~ s/\[([0-9]*), ([0-9]*)\]/$1 $2/;
                 eX := as_integer(split(dims)[1]);
                 wHy := as_integer(split(dims)[2]);
                 if(eX < priv.displayVector && wHy < priv.displayVector){
                    priv.col[col].vector := [eX, wHy]
                    if(priv.rows2read < 0 || priv.rows2read > priv.table.nrows()){
                       priv.col[col].data := priv.table.getcol(col);
                    } else {
                       priv.col[col].data := priv.table.getcol(col,
                             startrow=priv.cached.first, nrow=priv.rows2read);
                    }
                 } else {
                    arraylen := priv.rows2read;
                    if(priv.rows2read == -1 ||
                       priv.rows2read > priv.table.nrows()){
                       arraylen := priv.table.nrows();
                    }
                    priv.col[col].data := array('dummy', 1, arraylen);
                    for(i in 1:len(arraytext)){
                       priv.col[col].data[i] := spaste(arraytext[i],
                                                  priv.table.coldatatype(col));
                    }
                    priv.col[col].noFormatVector := T;
                 }
             } else {
                 arraylen := priv.rows2read;
                 if(priv.rows2read == -1 ||
                    priv.rows2read > priv.table.nrows()){
                    arraylen := priv.table.nrows();
                 }
                 priv.col[col].data := array('dummy', 1, arraylen);
                 for(i in 1:len(arraytext)){
                    priv.col[col].data[i] := spaste(arraytext[i],
                                                  priv.table.coldatatype(col));
                 }
                 priv.col[col].noFormatVector := T;
             }
           }
         }
      }
      if(is_fail(priv.col[col].data)){
         if(priv.debug)
            print 'table.getcol failed';
         # priv.col[col].data[1:priv.nrows] := 'table.getcol failed!';
         priv.col[col].display[1:priv.nrows] := 'table.getcol failed!';
      } else {
         if((is_dcomplex(priv.col[col].data) || is_complex(priv.col[col].data)) && !has_field(priv.col[col],'showAs')){
            priv.col[col].showAs := priv.showComplexAs;
         }
         priv.setVectorDisplay(col);
      }
      # print 'loadarray ', col, priv.col[col].noFormatVector;
   }

   priv.setVectorDisplay := function(col) {
      wider priv;
      if(priv.debug)
         print 'begin setVectorDisplay ', col;
      if(priv.rows2read < 0 || priv.rows2read > priv.table.nrows()){
         arraylen := priv.table.nrows();
      }else{
         arraylen := priv.rows2read;
      }
      if(priv.debug)
         print 'setVectorDisplay arraylen', arraylen;
         # Make the vector of strings if we need to.
      if(!has_field(priv.col[col], 'display') || 
          len(priv.col[col].display) != arraylen){
         priv.col[col].display := array('', arraylen);
      }
      if(!priv.col[col].noFormatVector && has_field(priv.col[col], 'vector') &&
           (priv.col[col].vector < priv.displayVector)) {
         doneit := F;
         if(has_field(priv.col[col].keywords, 'MEASURE_TYPE') &&
            strlen(priv.col[col].keywords.MEASURE_TYPE) > 0) {
            doneit := priv.measures2display(col, priv.col[col].data);
         }
         if(has_field(priv.col[col].keywords, 'MEASINFO') &&
            has_field(priv.col[col].keywords.MEASINFO, 'type') &&
            strlen(priv.col[col].keywords.MEASINFO.type) > 0) {
            doneit := priv.tablemeasures2display(col, priv.col[col].data);
         }
         if(priv.debug){
            print 'setVectorDisplay doneit', doneit;
            print 'setVecotrDisplay display', priv.col[col].display;
         }
         if(!doneit){
            d := ref priv.col[col].data;
            if(priv.debug)
               print spaste('setVectorDisplay d*', d, '*');
            if(priv.debug)
               print 'setVectorDisplay is complex', is_complex(d), d;
            if((is_complex(d) || is_dcomplex(d)) && any(abs(d) != 0.0)){
               if(priv.col[col].showAs == 'apd'){
                  dText := sprintf(priv.col[col].format, abs(d),
                                                  180*arg(d)/pi);
               } else if(priv.col[col].showAs == 'apr'){
                  dText := sprintf(priv.col[col].format, abs(d), arg(d));
               } else {
                  dText := sprintf(priv.col[col].format, d);
               }
               dText := dText ~s/nan0x10000000/0.000/g
               dText := dText ~s/[Nn][Aa][Nn]/0.000/g
            } else {
               if(is_numeric(d) && has_field(priv.col[col], 'format') && !(is_dcomplex(d) || is_complex(d))){
                    dText := sprintf(priv.col[col].format, d);
               } else {
                    dText :=  as_string(d);
               }
            }
            dText::shape := d::shape;
            if(priv.debug)
               print spaste('setVectorDisplay dText*', dText, '*');
            if(priv.debug)
               print 'setVectorDisplay arraylen*', arraylen, '*';
            if(priv.debug)
               print 'setVectorDisplay len(dText)*', len(dText), '*';
              #
              # Well it's possible that there is nothing in d so guard against that
              #
            if(len(dText) > 0){
               for(i in 1:arraylen){
                  if(len(priv.col[col].vector) == 1){
                     dummy := paste(dText[,i]);
                     if(priv.debug)
                        print 'setVectorDisplay dummy*', dummy, '*';
                     if(dummy ~ m/\S/){
                        priv.col[col].display[i] := sprintf('[%s]', paste(dText[,i],
                                                     sep=', '));
                     } else {
                        priv.col[col].display[i] := ' ';
                     }
                  } else {
                     priv.col[col].display[i] := sprintf('[%s]',
                                                  paste(dText[,,i], sep=', '));
                  }
               } 
            } else {
              priv.col[col].display[1:arraylen] := ' ';
            }
            if(priv.debug)
               print 'setVectorDisplay dText*', dText, '*';
         }
      } else {
         priv.col[col].display := priv.col[col].data;
      }
      if(priv.debug){
         print 'setVectorDisplay display', priv.col[col].display
         print 'setVectorDisplay end', col;
      }
   }

   lastX := priv.opentable(tabHandle, T);


   # Handle external events

      #Been signaled to shutdown
   whenever self->close, self->done do {
      priv.closePopups();
      if(priv.closeTable){
         priv.table.close();
      }
      priv.f.dismiss();
   }

      #Resize that window
   priv.resizeInProgress := F;
   whenever priv.f.app.f->resize do {
       if (!priv.resizeInProgress) {
	   priv.resizeInProgress := T;
	   priv.visH := priv.c->height();
	   rowsVis := as_integer(priv.visH/priv.th);
	   if(priv.topShown+rowsVis > priv.lastVis){
	       priv.displayPage(priv.topShown, rows2read, 0.0);
	   }
	   priv.resizeInProgress := F;
       } 
   }

   whenever self->unmap do {
      priv.f.app.f->unmap();
   }

   whenever self->map do {
      priv.f.app.f->map();
   }

   whenever self->goto, self->scrollto do {
      go2Row := as_integer($value);
      priv.gotoRow(go2Row);
   }

      #Window manager tells me to go away
   whenever priv.f.app.parent->killed do {
      if(priv.edit && priv.notSaved){
         qq := priv.querysave();
         whenever qq->returns do {
            gotThis := $value;
            if(gotThis == 'save'){
               stat := priv.table.flush();
               if(is_fail(stat)){
                  priv.note(paste('Table:', priv.table.name(), 'not saved!', stat),
			    priority='SEVERE');
               } else {
                  priv.table.unlock();
               }
            } 
            priv.closePopups();
            if(priv.closeTable){
               priv.table.close();
            }
         }
      }
   }

   priv.closePopups := function() {
      wider priv;
      for(offspring in field_names(priv.popups)){
             priv.popups[offspring]->close();
      }
      if(has_field(priv, 'ntb')){
          for(offspring in field_names(priv.ntb)){
             if(priv.debug)
                print "closePopups", is_agent(priv.ntb[offspring]), offspring;
             priv.ntb[offspring]->close(T);
          }
      }
      if(has_field(priv, 'nab')){
         priv.nab->close(T);
      }
   }
   rdum := tk_release();
   #print 'completed', time()-t1;
} 

tablebrowser::print.level:=1

const newtb := function(tabHandle=F, readonly=T, rows2read=1000, tbnote=note,
                     plotter=F, parentTable=F, show=T, hide=T, ws=dws, closeTable=F,
                     debug=F) {  

      note('newtb has been depreicated please use tablebrowser instead.');
      return tablebrowser(tabHandle, readonly, rows2read, tbnote, plotter,
                          parentTable, show, hide, ws, closeTable, debug);
}
