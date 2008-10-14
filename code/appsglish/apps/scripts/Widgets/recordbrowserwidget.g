# recbrowserwidget.g: widget for displaying records in a canvas
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
# $Id: recordbrowserwidget.g,v 19.2 2004/08/25 02:18:18 cvsmgr Exp $

pragma include once;

include "widgetserver.g";
include "unset.g";

#
# Here be the recordbrowser, it's probably fragile when using it to edit
#

recordbrowserwidget := subsequence(parent=F, ref therecord=F, readonly=F,
                                   show=T, width=400, font=F, displaytable=T,
                                   widgetset=dws, title='Record Browser(AIPS++)')
{
   if(!is_record(therecord)){
      fail('You must specify a record for the record browser to work.');
   }
   private := [=];
   private.therecord := ref therecord; # the record we want to display
   private.readonly := readonly; # readonly flag set F to allow editing
   private.y := 1;               # Count of rows to display
   private.w := width;           # Initial width of the canvas
   private.displayAll := T;      # Whether or not subrecords are displayed
   private.font := '-adobe-courier-medium-r-normal--14-*'; # font
   private.spacing := 7;           # spacing between rows
   private.ed := [=];              # contains editable frame on canvas
   private.showAxes := 2;          # number of array axes that can be displayed
   private.showLimits := [20, 20]; # number of elements visible in a vector
   private.parent := parent;       # parent frame
   private.ab := [=];              # record of array browsers spawned
   private.tb := [=];              # record of table browsers spawned
   private.abcount := 0;           # count of array browsers
   private.tbcount := 0;           # count of table browsers
   private.ws := widgetset;        # widget set
   private.menu := F;              # popup menu
   private.self := ref self;       # hey a reference to myself so I can tell
                                   # myself what to do sometimes
   private.oldtag := '-1.-1';
   private.closeParent2 := F;
   private.title := title;

   private.displayTable := displaytable; # Flag to indicate table awareness
   if(private.displayTable){
      include "table.g"          
   }

     # If we're readonly who cares otherwise we should keep around a copy
     # of the original incase someone makes a mistake.

   if(!readonly){
      private.oldRec := therecord;
   }

   private.setfont := function(font=F){
      wider private;
         # Do font size calculations

      if(is_string(font)){
         private.font := font;
      }
      allfonts := private.f->fonts();
      fn_ss := private.font ~ s/\*/.*/g;
      eh := ind(allfonts)[allfonts ~ eval(spaste('m/',fn_ss,'/'))];
      if(len(eh) > 0){
         # Display a warning message if it's not a valid font?
         private.font := allfonts[eh[1]];
      }
        # OK try and guess the size of the fonts
      daFonts := split(private.font, '-')
      for(i in 1:len(daFonts)){
         if(as_integer(daFonts[i]) > 0){
            private.ptsPerChar := as_integer(daFonts[i]);
            break;
         }
      }
      if(private.ptsPerChar < 7 || private.ptsPerChar > 24)
         private.ptsPerChar := 14;
   }

     # well you'd think this could be a function, but the properties window
     # won't popup so...

   private.gui := subsequence(parent=F, show=T){
      wider private;
         # If we have a parent just use it otherwise create the frame
      if(is_agent(parent)) {
        private.f := widgetset.frame(parent, title=private.title)
      } else {
        private.f := widgetset.frame(title=private.title);
      }
      if(!show){
         private.f->unmap();
      }
      private.setfont(font);

         # Rest of the GUI

      private.f1 := widgetset.frame(private.f, side='left')
      private.f2 := widgetset.frame(private.f, side='right', expand='x');
      recInfo := [=];
      private.recInfo := private.parseRec('top', private.therecord);

      private.c := widgetset.canvas(private.f1, width=400, height=230,
                          region=[0,0,private.w,private.y*private.ptsPerChar],
                          background='white');
      private.vsb := widgetset.scrollbar(private.f1);
      private.pad := widgetset.frame(private.f2, expand='none', width=23,
                                     height=23, relief='flat');
      private.hsb := widgetset.scrollbar(private.f2,orient='horizontal');

         # Scroll bar handling

      whenever private.vsb->scroll do {
         private.c->view($value);
      }
      whenever private.hsb->scroll do {
         private.c->view($value);
      }
      whenever private.c->xscroll do {
        private.hsb->view($value);
      }
      whenever private.c->yscroll do {
        private.vsb->view($value);
      }

        # If asked for a popup menu do the following

      whenever private.c->showmenu do {
         private.menu := F
         private.menu := private.ws.frame(tlead=private.c, tpos='c',
                                          background='green');
         private.editme := $value.tag;
         if(!private.readonly){
            dfText := paste('Delete Field', private.editme);
            dWidth := strlen(dfText);
            private.pb := private.ws.button(private.menu, text='Properties',
                                            width=dWidth, relief='flat');
            private.bb := private.ws.button(private.menu, text= ' ',
                               disabled=T, relief='flat', width=dWidth);
            private.nb := private.ws.button(private.menu, text='New Field',
                               width=dWidth, relief='flat', value=$value.tag);
            private.db := private.ws.button(private.menu, width=dWidth,
                                            text=dfText,
                                            relief='flat', value=$value.tag);
            whenever private.nb->press do {
               private.menu := F;
               private.self->newfield(private.editme);
            }
            whenever private.db->press do {
               private.menu := F;
               private.self->deletefield(private.editme);
            }
         } else {
            private.pb := private.ws.button(private.menu, text='Properties',
                                            width=14, relief='flat');
         }
         whenever private.pb->press do {
            private.menu := F;
            private.self->showproperties();        
         }
      }

         # Anytime you hit the select button, clear the menu if it's there.

      private.c->bind('<Button-1>', 'clearmenu');

      whenever private.c->clearmenu do {
         if(is_agent(private.menu)){
            private.menu := F;
         }
         private.ed := [=];
      }

         # Display the record members
      private.y := 1; # Reset the value so we can actually see something
      private.doDisplay();


         # Toggle between display and undisplaying record members
      whenever private.c->picked do {
          #if something else has been edited, get those changes
        if(has_field(private.ed, 'e') && has_field(private, 'editme')){
           private.setValue(private.therecord, private.recInfo,
                            split(private.editme, '.'),
                            private.ed.e->get());
        }
        what2change := $value.tag;
        private.toggleDisplay(private.recInfo, split(what2change, '.'));
        private.doDisplay(bindneeded=F);
      }

         # Here we've picked an array and need to fire up the array browser.

      whenever private.c->pickedarray do {
           # Close out any outstanding edits before doing anything else
        if(has_field(private.ed, 'e') && has_field(private, 'editme')){
           private.setValue(private.therecord, private.recInfo,
                            split(private.editme, '.'),
                            private.ed.e->get());
           private.ed := [=];
        }
         include "newab.g";
         private.abcount +:= 1;
         private.ab[as_string(private.abcount)] :=
                    newab(private.getRecValue(private.therecord,
                          split($value.tag, '.')), readonly=private.readonly);
      }

         # Here we've picked a table and need to fire up the table browser.

      whenever private.c->pickedtable do {
           # Close out any outstanding edits before doing anything else
        if(has_field(private.ed, 'e') && has_field(private, 'editme')){
           private.setValue(private.therecord, private.recInfo,
                            split(private.editme, '.'),
                            private.ed.e->get());
           private.ed := [=];
        }
         private.tbcount +:= 1;
         daTable :=  private.getRecValue(private.therecord,
                                         split($value.tag, '.'));
         include "tablebrowser.g";
         private.tb[as_string(private.tbcount)] :=
                    tablebrowser(daTable, readonly=private.readonly);
      }

        # Get the tag of what to edit
      whenever private.c->editme do {
          #if something else has been edited, get those changes
        if(has_field(private.ed, 'e') && has_field(private, 'editme')){
           private.setValue(private.therecord, private.recInfo,
                            split(private.editme, '.'),
                            private.ed.e->get());
           private.doDisplay(bindneeded=F);
        }
        private.editme := $value.tag;
      }
 

        # Display an entry field on the canvas for editing
      whenever private.c->editwhere do {
         if(!has_field(private.ed, 'f')){
            private.edentry($value);
         }
      }

      private.edentry := function(theVal){
        wider private;
        private.edvalue := paste(private.getValue(private.recInfo,
                                 split(private.editme, '.')));
        if(!(private.edvalue == 'function' || private.edvalue == 'agent' ||
             private.edvalue == 'AIPS++ Table' ||
             private.edvalue ~ m/array\[.*\]/ )){
           xy := as_integer(split(theVal.tag, '.'));
           private.ed := [=];
           private.ed.f := private.c->frame(xy[1], xy[2],
                                            height=private.ptsPerChar,
                                            expand='x', background='white');
           private.ed.f1 := widgetset.frame(private.ed.f, side='left',
                                  height=private.ptsPerChar);
           private.ed.l := widgetset.label(private.ed.f1,
                                 text=paste(private.editme, '='),
                                 font=private.font);
           private.ed.e := widgetset.entry(private.ed.f1,
                                 width=(10+strlen(private.edvalue)),
                                 font=private.font);
           private.ed.e->insert(private.edvalue);

           whenever private.ed.e->return do{
              private.setValue(private.therecord, private.recInfo,
                               split(private.editme, '.'),
                               private.ed.e->get());
              private.doDisplay(bindneeded=F);
           }
        } else {
            if(private.edvalue ~ m/array\[.*\]/ ){
               print "an array!";
            }
        }
      }
   }

   private.doDisplay := function(bindneeded=T){
     wider private;
         # First we clean up any mess we made
     if(is_agent(private.menu))
        private.menu := F;
     private.c->delete('all');
     #private.c->deltag('picked');
     private.c->deltag('');
     private.ed := [=];           
         # Now display the info on a canvas

     private.displayMembers(private.recInfo, bindneeded=bindneeded);
         # Reset the canvas region so we can see it all.
     private.c->region(0, 0, 0.75*private.w,
                       private.y*(private.ptsPerChar+private.spacing));
   }

     # Gets the string to edit
   private.getValue := function(ref recInfo, fields){
      wider private;
      if(len(fields) > 1){
         return private.getValue(recInfo[ fields[1] ], fields[2:len(fields)]);
      } else {
         lastone := split(fields[1], '[,]');
         if(len(lastone) > 1)
            return recInfo[lastone[1]].val[as_integer(lastone[2])];
         else
            return recInfo[fields[1]].val;
      }
   }


      # Remove a field from a record, yes it's clunky but Darrell says it's 
      # the only way.
   private.deleteField := function(ref therecord, fields){
      wider private;
      if(len(fields) > 2){ 
         private.deleteField(therecord[fields[1]], fields[2:len(fields)]);
      } else {
         therecord[fields[1]] :=
            therecord[fields[1]][ind(therecord[fields[1]])[field_names(therecord[fields[1]]) != fields[2]]];
      }
   }
      # Get the data from a field in the record
   private.getRecValue := function(ref therecord, fields){
      wider private;
      if(len(fields) > 1){
         return private.getRecValue(therecord[ fields[1] ],fields[2:len(fields)]);
      } else {
            return ref therecord[fields[1]]
      }
   }

     # Sets the value
   private.setValue := function(ref therecord, ref recInfo, fields, myval){
      wider private;
      if(len(fields) > 1){
         private.setValue(therecord[fields[1]], recInfo[fields[1]],
                          fields[2:len(fields)], myval);
      } else {
         lastone := split(fields[1], '[,]');
         dummy := eval(myval);
         if(len(lastone) > 1){
            recInfo[lastone[1]].val[as_integer(lastone[2])] := myval;
            therecord[lastone[1]][as_integer(lastone[2]),] := eval(myval);
            if(!has_field(recInfo[lastone[1]], '_display')){
               recInfo[lastone[1]]._display := private.displayAll;
            }
         } else {
            recInfo[fields[1]].val := myval;
            therecord[fields[1]] := eval(myval);
            if(!has_field(recInfo[fields[1]], '_display')){
               recInfo[fields[1]]._display := private.displayAll;
            }
         }
      }
   }

     # Toggle between display and not display subrecords

   private.toggleDisplay := function(ref recInfo, fields){
      wider private;
      if(len(fields) > 1){
         private.toggleDisplay(recInfo[ fields[1] ], fields[2:len(fields)]);
      } else {
         if(recInfo[fields]._display)
            recInfo[fields]._display := F;
         else
            recInfo[fields]._display := T;
      }
   }

     # Display the record members

   private.displayMembers := function(recInfo, level=1, parentRec=F, bindneeded=T){
      wider private;
      if(level == 1)
        private.y := 1;
      for(field in field_names(recInfo)){
         # _display is a special field we set to determine whether to display
         # subrecords. 
         if(field != "_display"){
            if(is_boolean(parentRec)){
                  fieldTag := field;
            } else {
               fieldTag := spaste(parentRec, '.', field);
            }
            if(has_field(recInfo, '_display'))
                # Here we set array positions for matricies
            if(has_field(recInfo[field], 'apos')){
               fieldTag := array(fieldTag, len(recInfo[field].apos));
               for(i in 1:len(recInfo[field].apos)){
                  fieldTag[i] := spaste(fieldTag[i], recInfo[field].apos[i]);
               }
            }
            if(is_const(recInfo[field])){
               constFlag := '(const)';
            } else {
               constFlag := '';
            }
               # Write the text for a field, if the field has no text then it
               # is a record and we will recurse
            if(has_field(recInfo[field], 'text')){
               for(i in 1:len(recInfo[field].val)){
                  private.y := private.y + 1;
                  da_text := paste(recInfo[field].text[i], constFlag, "=",
                                   recInfo[field].val[i]);
                  private.c->deltag(fieldTag[i]);
                  private.c->text(level*private.ptsPerChar,
                            (private.ptsPerChar+private.spacing)*(private.y-1),
                             tag=fieldTag[i],
                             text=da_text, anchor='w', font=private.font);
                  w := (strlen(field)*level +
                        strlen(da_text))*private.ptsPerChar;
                  if(w > private.w){
                     private.w := w; # Adjust the maximum width of the canvas
                  }
                  xytag := spaste(level*private.ptsPerChar, '.',
                                  as_integer((private.y-1.65)*
                                  (private.ptsPerChar+private.spacing)));

                  if(!private.readonly && !is_const(recInfo[field])){
                     private.c->deltag(xytag);
                     #if(bindneeded){
                        if(da_text ~ m/array\[.*\]/) {
                           private.c->bind(fieldTag[i], '<Button-1>',
                                        'pickedarray');
                        } else {
                           private.c->bind(fieldTag[i], '<Button-1>', 'editme');
                        }
                     #}
                     private.c->addtag(xytag, fieldTag[i]);
                     private.c->bind(xytag, '<Button-1>', 'editwhere');
                  } else if(da_text ~ m/array\[.*\]/) {
                     private.c->addtag(xytag, fieldTag[i]);
                     if(bindneeded)
                     private.c->bind(fieldTag[i], '<Button-1>', 'pickedarray');
                  } else if(da_text ~ m/AIPS\+\+ Table/) {
                     private.c->addtag(xytag, fieldTag[i]);
                     if(bindneeded)
                     private.c->bind(fieldTag[i], '<Button-1>', 'pickedtable');
                  }
                  private.c->bind(fieldTag[i], '<Button-3>', 'showmenu');
               } 
            } else {
               private.y := private.y + 1;
               xytag := spaste(level*private.ptsPerChar, '.',
                               as_integer((private.y-1.65)*
                               (private.ptsPerChar+private.spacing)));
               if(recInfo[field]._display){
                  private.c->text(level*private.ptsPerChar,
                            (private.ptsPerChar+private.spacing)*(private.y-1),
                               text=paste('-', field, constFlag), tag=fieldTag,
                               anchor='w', font=private.font);
                  private.displayMembers(recInfo[field], level+1, fieldTag, bindneeded);
               } else {
                  private.c->text(level*private.ptsPerChar,
                            (private.ptsPerChar+private.spacing)*(private.y-1),
                               text=paste('+', field, constFlag), tag=fieldTag,
                               anchor='w', font=private.font);
               }
               if(bindneeded){
                  private.c->bind(fieldTag, '<Button-1>', 'picked');
                  private.c->bind(fieldTag, '<Button-3>', 'showmenu');
               }
            }
         }
      }
   }

     # parse the record
     # recInfo store useful information that we want to write on the canvas
     # there are three fields we need to know about
     # text - field name text
     # val  - an evalable string value for the field
     # apos - array place holder
     # _display - whether or not to display this field's subrecords

   # Returns T if v is the name of an AIPS++ table. To match v must:
   #	Be a string.
   #	Start with the magic prefix "Table: " added by GlishRecord.
   #	Be the name of an existing table.
   const is_tableName := function(v)
   {	return (is_string(v) && (v ~m/^Table: /) && tableexists(v));
   }

   private.parseRec := function(parent, therecord){
      wider private;
      recInfo := [=];
      for(field in field_names(therecord)){
         private.y := private.y + 1;
         if(is_record(therecord[field])){
              # if it's a record keep parsing unless we know about tables
            if(private.displayTable && is_table(therecord[field])){
                  recInfo[field] := [=];
                  recInfo[field].text := field;
                  recInfo[field].val := paste( 'AIPS++ Table --',
                                                therecord[field].name());
            } else {
               recInfo[field] := private.parseRec(field, therecord[field]);
            }
         }
	 else if( private.displayTable && is_tableName(therecord[field]))
	 { # Treat the name of a table as a table.
                  recInfo[field] := [=];
                  recInfo[field].text := field;
		  tname := therecord[field] ~ s/Table: //;
                  recInfo[field].val := paste( 'AIPS++ Table --', tname);
	 }
	 else if(is_function(therecord[field])) {
            recInfo[field] := [=];
            recInfo[field].text := field;
            recInfo[field].val := 'function';
         } else if(is_agent(therecord[field])) {
            recInfo[field] := [=];
            recInfo[field].text := field;
            recInfo[field].val := 'agent';
         } else if(shape(therecord[field])[1] > 1) {
            recInfo[field] := [=];
            recInfo[field].text := field;
            arrayInfo := shape(therecord[field]);
            if(len(arrayInfo) > 1){
               if(len(arrayInfo) > private.showAxes){
                  recInfo[field].val := spaste(type_name(therecord[field]),
                                            ' array', shape(therecord[field]));
               } else {
                  if(any(arrayInfo > private.showLimits[1:len(arrayInfo)])){
                     recInfo[field].val := spaste(type_name(therecord[field]),
                                            ' array', shape(therecord[field]));
                  } else {
                     for(i in 1:arrayInfo[2]){
                        recInfo[field].text[i] := spaste(field, '[',i, ',]');
                        recInfo[field].val[i] := as_evalstr(therecord[field][i,]);
                        recInfo[field].apos[i] := spaste('[',i,',]');
                     }
                  }
               }
            } else {
               if(arrayInfo[1] > private.showLimits[1]){
                  recInfo[field].val := spaste(type_name(therecord[field]),
                                        ' array[', shape(therecord[field]), ']');
               } else {
                  recInfo[field].val := as_evalstr(therecord[field]);
               }
            }
         } else {
            recInfo[field] := [=];
            recInfo[field].text := field;
            recInfo[field].val := as_evalstr(therecord[field]);
         }
         recInfo[field]._display := private.displayAll;
      }
      return recInfo;
   }

   # Create the gui

   if(!is_agent(private.parent)){
        # Hey we're the record browser!
      private.ws.setmode('app');
      private.parent := private.ws.frame(title=private.title);
      r := dws.recordbrowser(private.parent, therecord, readonly=readonly,
                                   font=font);
      f := dws.frame(private.parent, side='right');
      b := dws.button(f, 'Dismiss', type='dismiss');
      private.closeParent2 := T;
      whenever b->press do {
         r->close();
         private.parent->unmap();
      }      
   } else {
      theGui := private.gui(private.parent, show=show);
   }

   # Lots of events newrecord, record
   #                 font, close, show, readonly, reset, cleanup, vectorsize
   #                 showproperites, newfield, deletefield

   # Probably should send a closed or done event when closed.

   whenever self->newrecord, self->record do {
      private.therecord := $value;
      private.recInfo := private.parseRec('top', private.therecord);
      private.doDisplay();
   }

   whenever self->font do {
      private.setfont($value);
      private.doDisplay();
   }

   whenever self->close, self->unmap do {
      if(private.closeParent2)
         private.parent->unmap();
      else 
         private.f->unmap();
      if(private.abcount > 0){
         for(i in 1:private.abcount){
           private.ab[as_string(i)]->close();
         }
      }
      if(private.tbcount > 0){
        for(i in 1:private.tbcount){
          private.tb[as_string(i)]->close();
        }
      }
      if(is_agent(private.menu))
         private.menu:=F;
   }

   whenever self->show do {
      if(has_field(private, 'f') && is_agent(private.f)){
         private.f->map();
      } else {
       theGui := private.gui(private.parent);
      }
   }

   whenever self->readonly do {
       if(is_boolean($value)){
          private.readonly := $value;
       } else {
          if(private.readonly){
             private.readonly := F;
          } else {
             private.readonly := T;
          }
       }
       if(private.readonly)
            private.oldRec := therecord;
       private.doDisplay();
   }

   whenever self->cleanup do {
      private.f := 0;
   }

   whenever self->reset do {
      if(!private.readonly){
         private.therecord := private.oldRec;
      }
      private.doDisplay();
   }

   whenever self->vectorsize do {
      private.showLimits := $value;
      # Should adjust showAxes to len of showLimits but it's better done
      # with the array browser.
      private.doDisplay();
   }

   whenever self->showproperties do {
      propsDialog := private.displayProps();
      whenever propsDialog->newprops do {
        private.setfont($value.font);
        private.showLimits := eval($value.showLimits);
        private.doDisplay();
      }
   }


   whenever self->newfield do {
      nfd := private.newFieldDialog($value);
      whenever nfd->newfield do {
         private.setValue(private.therecord, private.recInfo,
                          split($value.fieldName, '.'), $value.fieldValue);
         private.recInfo := private.parseRec('top', private.therecord);
         private.doDisplay();
      }
   }

   whenever self->deletefield do {
      private.deleteField(private.therecord, split($value, '.'));
      private.recInfo := private.parseRec('top', private.therecord);
      private.doDisplay();
   }

   whenever self->title do {
      private.parent->title($value);
   }
 
     # Gee new field dialog editor

   private.newFieldDialog := subsequence(newfield){
     include "guiframework.g"
     include "infowindow.g"
     wider private;
     props := [=];
     action := [=];
     action.apply := [=];
     action.apply.text := 'Apply';
     action.apply.action := function(){
        wider props; 
        wider private;
        props.fieldName := props.fn->get();
        props.fieldValue := props.fv->get();
        dummy := eval(props.fieldValue);
        if(!is_fail(dummy)){
           self->newfield(fieldName=props.fieldName,
                          fieldValue=props.fieldValue);
           props.gf.dismiss();
        } else {
           infowindow(paste('Unable to eval your value: ',
                      props.fieldValue), 'Invalid eval string');
        }
     }
     action.cancel := [=];
     action.cancel.text := 'Dismiss';
     action.cancel.action := function(){
        wider props;
        props.gf.dismiss();
     };
     
     props.gf := guiframework('Add a field to a record', menus=F,
                             helpmenu=F, actions=action);
     props.wf := props.gf.getworkframe();
     props.af := private.ws.frame(props.wf, side='left');
     props.afn := private.ws.frame(props.af, side='top');
   
     props.fnl := private.ws.label(props.afn, text='Field Name',
                                   font=private.font);
     props.fn := private.ws.entry(props.afn, font=private.font);
     if(strlen(newfield) > 0){
        props.fn->insert(spaste(newfield, '.'));
     }

     props.afv := private.ws.frame(props.af, side='top');
     props.fvl := private.ws.label(props.afv, text='Value', font=private.font);
     props.fv := private.ws.entry(props.afv, font=private.font);
   }

      # Properties dialog for recordbrowser widget

   private.displayProps := subsequence() {
     include "guiframework.g"
     wider private;
     props := [=];
     action := [=];
     action.apply := [=];
     action.apply.text := 'Apply';
     action.apply.action := function(){
        wider props; 
        wider private;
        props.showLimits := props.a.e->get();
        self->newprops(font=props.newfont, showLimits=props.showLimits);
        props.gf.dismiss();
     }
     action.reset := [=];
     action.reset.text := 'Reset';
     action.reset.action := function(){
        wider props; 
        props.fc->reset()
     };
     action.cancel := [=];
     action.cancel.text := 'Dismiss';
     action.cancel.action := function(){
        wider props;
        props.gf.dismiss();
     };
     
     props.gf := guiframework('Record-Browser Properities', menus=F,
                             helpmenu=F, actions=action);

     props.wf := props.gf.getworkframe();

     props.af := private.ws.frame(props.wf, side='left');
     props.a.l := private.ws.label(props.af, text='Max array size visible',
                                   font=private.font);
     props.a.e := private.ws.entry(props.af, font=private.font);
     props.a.e->insert(as_evalstr(private.showLimits));
     props.fc := private.ws.fontchooserwidget(props.wf, private.font);

     props.newfont := private.font;
     props.showLimits := private.showLimits;
     whenever props.fc->newfont do {
        props.newfont := $value;
     }
   }
}
