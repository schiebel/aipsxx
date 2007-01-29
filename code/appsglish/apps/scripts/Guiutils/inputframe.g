#
#   Copyright (C) 1997,1998,1999,2000
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
#   $Id: inputframe.g,v 19.2 2004/08/25 01:59:47 cvsmgr Exp $
#
#pragma include once

# Useful functions
#    gui.tabform
#    gui.inputform
#
#       Some testing scripts
#    gui.testinputs
#    gui.testform
#    gui.testtab
#
# First cut at record interface gui --
#   Needs documentation
#   Needs include guard
#   Needs better integration with gui framework
#   Needs not to resize windows when mapping/unmapping frames
#   Labeling of frames probably makes sense
#   I suspect lots of other stuff
#
#  Here's a brief description of the record interface
#
# record interface
# gui.inputform(loadngo record)
# title - text in the window title
# label - text in the window
# actions - (a.label a.function)record of functions
# layout - ignored for now
#
# data - record of datums
# results - record of results
# progress - T or F
#
#  
#
# record datum
#
# label - Description of datum field
# type - string
#        float
#        double
#        long
#        integer
#        file
#        table
#        time
#        date
#        text - string with more than oneline of text
#
# required - boolean required for processing
# hint - check, radio, list, menu
# enums - vector of allowed values
# multiple - boolean for allowing multiple choices of enums
# range.min 
# range.max
# default
# verify - function to verify input
# mask - display mask
# help.url
# help.text

include "popuphelp.g"
include "widgetserver.g"
include "guiframework.g"
include "infowindow.g"
include "note.g"
   #
   # gui.stackform create a stack of input forms, you must supply the parent
   # and the methods, you control which frame is visible.
   #
gui.stackform := function(methods, parent){
  public := [=];
  private := [=];
  private.gtf := [=];
  private.frames := [=]
  private.currTop := F;
  private.parent := parent;

    #
    # Create the placeholders for the frames
    #
  private.method_names := field_names(methods);
  private.methods:= methods;
    #
    # Move the desired frame name to the front
    #
  private.tofrontbyname := function(tabName){
     tk_hold();
     wider private;
     if(!is_boolean(private.currTop)) {
        #private.gtf[private.currTop].cleanup();
        #private.gtf[private.currTop].gf.dismiss();
        #private.gtf[private.currTop].gf := F;
        #private.gtf[private.currTop] := F;
        #private.gtf.method[private.currTop] := F
        private.frames[private.currTop]->unmap();
        #private.frames[private.currTop] := F;
        # collect_garbage();
     }
     if(has_field(private.frames,tabName)){
        private.frames[tabName]->map();
     } else {
        private.frames[tabName] := dws.frame(private.parent, relief='raised',
                                         borderwidth=1);
        private.gtf[tabName] := gui.inputform(private.methods[tabName],
                parent=private.frames[tabName], someid=tabName);
     }
     private.currTop := tabName;
     tk_release();
  }
    #
    # Move the desired frame number ot the front
    #
  private.tofrontbynumber := function(frameID){
     wider private;
     private.tofrontbyname(private.method_names[frameID]);
  }
    #
    # Move the desired frame to the front
    #
  public.tofront := function(frameID){
     wider private;
     if(is_integer(frameID)){
        private.tofrontbynumber(frameID);
     } else if(is_string(frameID)){
        private.tofrontbyname(frameID);
     } else {
       fail;
     }
  }
    #
    # Returns the list of frame names
    #
  public.framenames := function(){
     wider private;
     return private.method_names;
  }
    #
    # Set input data
    #
  public.setinput := function(stackID, ref data){
     wider private;
     if(is_integer(stackID)){
        private.gtf[private.method_names[stackID]].setinput(data);
     } else if(is_string(stackID)){
        private.gtf[stackID].setinput(data);
     } else {
       fail;
     }
  }
    # May want to add a cleanup function
#
  private.tofrontbynumber(1);   # Display the first frame in the list
#
  return ref public;
}
gui.deftitle := 'AIPS++ Tab Input Form';
gui.tabform := function(methods, title=gui.deftitle, dismiss=F, parent=F, tabcount=0, side='left')
{
  self := [=];
  self.gf := [=];
  self.gtf := [=];
  self.frames := [=];
  self.btn := [=];
  self.currTop := F;

  hmenu := F;
  if(is_boolean(parent)){
     hmenu := [=];
     hmenu::text := 'Help';
     hmenu.about := [=];
     hmenu.about.text := 'About';
     hmenu.about.relief := 'flat';
     hmenu.about.action := about;
  }
  self.gf := guiframework(title, F, hmenu, F, parent=parent);
  wf := self.gf.getworkframe();
  wf->side(side);

    # 
    # Here we decide whether to use a scroll bar or tabframes
    # 
  mcount := len(field_names(methods));
  # tabFrame := dws.frame(wf, side='left', relief='raised', borderwidth=1);
  tabFrame := dws.frame(wf, side='left', relief='raised', borderwidth=1);
  if(has_field(methods::, 'categories') && mcount > tabcount){
    ntf := dws.frame(tabFrame, side='top');
    cf := dws.frame(ntf, side='left');
    df := dws.frame(ntf, height=10);
    look := F;
    for(method in field_names(methods::categories)){
       if(is_boolean(methods::categories[method]) && methods::categories[method] == T){
         showmembers[method] := field_names(methods);
       } else {
         showmembers[method]:= methods::categories[method];
       }
       text4btn := method;
       if(has_field(methods::categories[method]::, 'label'))
          text4btn := methods::categories[method]::label;
       catbtn[method] := dws.button(cf, text=text4btn, type='radio', value=method);
       if(is_boolean(look)){
          look := method;
          catbtn[method]->state(T);
       }
       whenever catbtn[method]->press do {
          look := $value;
          if(is_agent(self.lb)){
            self.lb->delete('start', 'end')
            self.lb->insert(showmembers[look]);
            self.lb->select('0');
            self.tofront(showmembers[look][1]);
          }
       }
    }
    tf := dws.frame(ntf, side='left');
  } else {
    showmembers.all := field_names(methods);
    tf := ref tabFrame;
    look := 'all';
  }
  doTabs := T;
  if(mcount > tabcount){
     doTabs := F;
     dtf := dws.frame(tf, side='left', expand='y');
     self.lb := dws.listbox(dtf);
        # Attach scroll bar to the list box if necessary
     sb := dws.scrollbar(dtf);
     whenever sb->scroll do
        self.lb->view($value);
     whenever self.lb->yscroll do
        sb->view($value);
  }
  inFrame := dws.frame(wf, borderwidth=0);

  disallow := "";
  grayMethods := "";
  if(has_field(methods::, 'disallow'))
     disallow := methods::disallow;
  if(has_field(methods::, 'show'))
     grayMethods := methods::show;
  for(method in field_names(methods)){
    if(!any(method == disallow) || any(method == grayMethods)){
       self.frames[method] := dws.frame(inFrame, relief='raised', borderwidth=1);
       frameTitle := '';
       if(has_field(methods[method], 'title'))
          frameTitle := methods[method].title;
       self.gtf[method] := gui.inputform(methods[method], title=frameTitle,
                                         dismiss=dismiss,
                                       parent=self.frames[method], someid=method);
       self.frames[method]->unmap();

       methodName := method;
       if(has_field(methods[method], 'label'))
          methodName := methods[method].label
       if(doTabs){
         disabled := F;
         if(any(method == grayMethods))
            disabled := T;
         self.btn[method] := dws.button(tf, text=methodName, value=method,
                                    borderwidth=1, disabled=disabled)
         whenever self.btn[method]->press do {
            self.tofront($value);
         }
       } else {
         if(!any(method == grayMethods)){
            self.lb->insert(methodName);
            self.lb->select('0');
            whenever self.lb->select do {
               self.tofront(showmembers[look][$value+1]);
            }
         }
       }
    }
  }

  self.tofront := function(tabName)
  {
     tk_hold();
     wider self;
     if (!is_boolean(self.currTop)) {
        if(has_field(self.btn, tabName))
           self.btn[self.currTop]->relief('raised');
         self.frames[self.currTop]->unmap();
     }
     if(has_field(self.btn, tabName))
        self.btn[tabName]->relief('sunken');
     self.frames[tabName]->map();
     self.currTop := tabName;
     tk_release();
  }

  self.tofront(field_names(methods)[1]);

  self.dismisshandler := function(dismissButton) {
    wider self;
    for(method in field_names(self.gtf)){
       self.gtf[method].addactionhandler(dismissButton, self.gf.dismiss);
    }
  }
    #
    # Set input data
    #
  self.setinput := function(stackID, ref data){
     wider self;
     if(is_string(stackID)){
        self.gtf[stackID].setinput(data);
     } else {
       fail;
     }
  }
  return ref self;
}

gui.inputform := function(scrnInputs, title='AIPS++ Input Form', dismiss=F, parent=F, incount=15, helpdisplay=F, someid=F, edit=T)
{
   private := [=];
   private.guiElements := [=];
   private::someid := someid;
   if(edit){
      private.noedit := F;
   } else {
      private.noedit := T;
   }

   private.usedefaults := function(ref guiElements){
     for(field in field_names(guiElements)){
        defValue := '';
        if(has_field(guiElements[field], 'default'))
           defValue := guiElements[field].default;
        if(has_field(guiElements[field], 'en')){
           guiElements[field].en->delete('start', 'end');
           guiElements[field].en->insert(defValue,'start');
        }
        if(has_field(guiElements[field], 's')){
           guiElements[field].s->value(defValue);
        }
        if(has_field(guiElements[field], 'rb')){
           if(len(as_byte(defValue) > 0))
              guiElements[field].rb[defValue]->state(T);
        }
        if(has_field(guiElements[field], 'cb')){
           for(btn in field_names(guiElements[field].cb)){
              if(any(btn == defValue))
                 guiElements[field].cb[btn]->state(T);
              else
                 guiElements[field].cb[btn]->state(F);
           }
        }
        if(has_field(guiElements[field], 'lb')){
           guiElements[field].lb->clear('start', 'end');
           guiElements[field].lb->select(defValue);
           for(myVal in defValue){
              count := ind(guiElements[field].enums)[guiElements[field].enums == myVal];
              guiElements[field].lb->select(as_string(count-1));
           }
        }
     }
   }

   private.timeok := function(theString, varname){
     rStat := T;
     ok := theString ~ 
	 m/[0-9]?[0-9][h: ][0-5]?[0-9][m: ]?[0-5]?[0-9]?[.]?[0-9]*/;
     if(ok == 0){
        if(len(as_byte(theString)) > 0){
           slogan := spaste(varname, ' is improperly formatted, \'', theString,
                           '\', for time.');
        } else {
           slogan := spaste('No time was specified for ', varname,
                            '.  Please enter a time.\n');
        }
        slogan := spaste(slogan, '\nTime format is hh:mm:ss.sss');
        slogan := spaste(slogan, '\n\nTrailing and leading 0\'s are unecessary.');
        infowindow(slogan, 'AIPS++ Bad Time Input');
        rStat := F;
     }
   return rStat;}

   private.dateok := function(theString, varname){
   rStat := T;
     ok := theString ~ m/[0-9]?[0-9]?[0-9]?[0-9]\/[0-1]?[0-9]\/[0-3]?[0-9]/;
     if(!ok){
        if(len(as_byte(theString)) > 0){
           slogan := spaste(varname, ' is improperly formatted, \'', theString,
                         '\' for a date.');
        } else {
           slogan := spaste('No date was specified for ', varname,
                            '.  Please enter a date.\n');
        }
     
        slogan := spaste(slogan, '\nDate format is yyyy/mm/dd');
        slogan := spaste(slogan, '\n\nTrailing and leading 0\'s are unecessary.');
        infowindow(slogan, 'AIPS++ Bad Date Input');
        rStat := F;
     }
   return rStat;
}

   private.choosemode := function(data){
      chooseMode := 'browse'
      defValues := '';

      if(has_field(data, 'default'))
         defValues := data.default;

      if(has_field(data, 'multiple')){
         if(data.multiple){
            chooseMode := 'extended'
         } else {
            if(len(defValues) > 1){
               infowindow(spaste('Multiple values for ', data),
                          'AIPS++ inputframe');
            }
         }
      } else {
         if(len(defValues) > 1){
            chooseMode := 'extended'
         }
      }
      return chooseMode;
   }

   private.dolabel := function(parent, labelData, data, field){
      theLabel := [=]
      if(has_field(data[field], 'help')){
         if(has_field(data[field].help, 'url')){
            theLabel[field] := dws.button(parent, text=labelData,
					  relief='groove', value=field);
            whenever theLabel[field]->press do
               help(data[$value].help.url);
	  } else {
            theLabel[field] := dws.label(parent, labelData, justify='left',
					 width=20, fill='none');
	    if(has_field(data[field].help, 'text')) 
		theLabel[field].shorthelp := data[field].help.text;
         }
      } else {
         theLabel[field] := dws.label(parent, labelData, justify='left',
				      width=20, fill='none');
      }
      addpopuphelp(theLabel[field], 2);
      return theLabel[field];
   }
   public.cleanup := function(){
     wider private;
     # print 'inputframe start ', len(active_agents());
     if(is_record(private.guiElements)){
        for(field in field_names(private.guiElements) ){
          if(is_record(private.guiElements[field])){
             for(subfield in field_names(private.guiElements[field] )){
                private.guiElements[field][subfield] := F;
             }
          }
          ge[field] := F;
        }
        private.guiElements.canvas := F;
        if(has_field(private.guiElements, 'cleanup'))
           if(is_function(private.guiElements.cleanup))
              private.guiElements.cleanup();
        private.guiElements := F;
     }
     private := F;
   }
   private.creategui := function(ref wf, ref data, ref lastData = F){
      wider private;
      const standWidth := 15;
      helplines := 0;
      if(has_field(scrnInputs, 'helplines'))
         helplines := scrnInputs.helplines;
      ge := [=];
      if(len(field_names(data)) > incount){
         ge.cf := dws.frame (wf, side='left', expand='both');
         ge.canvas := canvas(ge.cf, borderwidth=0, width=360, height=360, region=[0,0,400,44*(len(field_names(data))+helplines)]);
         ge.vsb := dws.scrollbar(ge.cf, orient='vertical');
         whenever ge.vsb->scroll do
            ge.canvas->view($value);
         whenever ge.canvas->yscroll do
            ge.vsb->view($value);
         ge.gf := ge.canvas->frame( 0, 0, borderwidth=0);
      } else {
         ge.gf := wf;
      }
      for(field in field_names(data)){
         ge[field] := [=];
         ge[field].line := dws.frame(ge.gf, side='left', relief='groove',expand='x', width=300)
         ge[field].f1 := dws.frame(ge[field].line, expand='none');
         ge[field].f2 := dws.frame(ge[field].line, side='left', expand='x');
         if(helpdisplay){
            ge[field].f3 := dws.frame(ge[field].line, width=180, side='left');
         }
         labelData := field;
         ge[field].type := data[field].type;
         if(has_field(data[field], 'label'))
            labelData := data[field].label;
         if(data[field].type == 'file' || data[field].type == 'table'){
            ge[field].l := private.dolabel(ge[field].f1, labelData, data, field);
            ge[field].en := dws.entry(ge[field].f2, width=25, disabled=private.noedit);
            ge[field].b := dws.button(ge[field].f2, text='Browser...', value=field);
            whenever ge[field].b->press do {
               thisone := $value;
               if(ge[thisone].type == 'file'){
                  b := filechooser();
               } else if(ge[thisone].type == 'table'){
                  b := tablechooser();
               } else {
                  b := datachooser();
               }
               ge[thisone].en->delete('start', 'end');
               ge[thisone].en->insert(b.guiReturns, 'start');
            }
         } else {
            if(has_field(data[field], 'enums')){
               ge[field].enums := data[field].enums;
               if(has_field(data[field], 'hint')){
                  if(data[field].hint == 'list'){
                     # Add a listbox

                     # ge[field].l := label(ge[field].f, labelData);
                     ge[field].l := private.dolabel(ge[field].f1, labelData, data, field);
                     ge[field].lb := dws.listbox(ge[field].f2,
                                       mode=private.choosemode(data[field]));
                     ge[field].lb->insert(data[field].enums);
                  } else if(data[field].hint == 'menu'){
		    ge[field].b := dws.button(ge[field].f1, text=labelData,
                                          type='menu');
                     for(i in 1:len(data[field].enums))
                         ge[field].mb[i] := dws.button(ge[field].b,
                                               text=data[field].enums[i],
                                               relief='flat');
                  } else {
                     # ge[field].l := label(ge[field].f, labelData, width=25, justify='right');
                     ge[field].l := private.dolabel(ge[field].f1, labelData, data, field);
                     bname := 'ab';
                     if(data[field].hint == 'check')
                        bname := 'cb'
                     else if(data[field].hint == 'radio')
                        bname := 'rb'
      
                     for(bn in data[field].enums){
                         ge[field][bname][bn] := dws.button(ge[field].f2,
                                                    text=bn,
                                                    type=data[field].hint);
                     }
                  }
               } else {
                   # ge[field].l := label(ge[field].f, labelData);
                   ge[field].l := private.dolabel(ge[field].f1, labelData, data, field);
                   if(len(data[field].enums) < 5){
                     for(rb in data[field].enums){
                         ge[field].rb[rb] := dws.button(ge[field].f2,
                                               text=rb, type='radio');
                     }
                   } else {
                     # Use a list box
                     ge[field].l := private.dolabel(ge[field].f1, labelData,
                                                    data, field);
                     ge[field].lb := dws.listbox(ge[field].f2,
                                       mode=private.choosemode(data[field]));
                     ge[field].lb->insert(data[field].enums);
                   }
               }
            } else if(has_field(data[field], 'range')){
               if(has_field(data[field].range, 'min') &&
                  has_field(data[field].range, 'max')){
                  if(data[field].type == 'integer'  || data[field].type == 'long'){
                     ge[field].s := scale(ge[field].f2, data[field].range.min,
                                          data[field].range.max,
                                          text=data[field].label);
                  } else {
                     # ge[field].l := label(ge[field].f, labelData);
                     ge[field].l :=
                        private.dolabel(ge[field].f1, labelData, data, field);
                     ge[field].en := dws.entry(ge[field].f2, width=standWidth, disabled=private.noedit);
                     if(helpdisplay && has_field(data[field], 'help') &&
                        has_field(data[field].help, 'text'))
                        ge[field].m := dws.message(ge[field].f3,
						   text=data[field].help.text, width=400);
                  }
               } else {
                  ge[field].l := private.dolabel(ge[field].f1, labelData, data, field);
                  ge[field].en := dws.entry(ge[field].f2, width=standWidth,disabled=private.noedit);
                  if(helpdisplay && has_field(data[field], 'help') && has_field(data[field].help, 'text'))
                     ge[field].m := dws.message(ge[field].f3, text=data[field].help.text, width=400);
               }
            } else {

               ge[field].l := private.dolabel(ge[field].f1, labelData, data, field);
               fieldSize := standWidth;
               if(has_field(data[field], 'hint')){
                  fieldSize := data[field].hint;
               } 
               if(data[field].type == 'text'){
                  ge[field].en := dws.text(ge[field].f2, height=3, width=fieldSize, disabled=private.noedit);
               } else {

   # Put an info type here that generates a label only.

                  ge[field].en := dws.entry(ge[field].f2, width=fieldSize, disabled=private.noedit);
               }
               if(helpdisplay && has_field(data[field], 'help') && has_field(data[field].help, 'text'))
                  ge[field].m := dws.message(ge[field].f3, text=data[field].help.text, width=400);
               varname := field;
               if(has_field(data[field], 'validate'))
                  ge[field].validate := data[field].validate;
               else if(data[field].type == 'date')
                  ge[field].validate := private.dateok;
               else if(data[field].type == 'time')
                  ge[field].validate := private.timeok;
               else if(has_field(data[field], 'range')){
                  if(!has_field(data[field].range, 'max')){
                     ge[field].validate := function(inString, varname){
                        return (as_double(inString) >= data[field].range.min);
                     }
                  }else if(!has_field(data[field].range, 'min')){
                     ge[field].validate := function(inString, varname){
                       return (as_double(inString) <= data[field].range.max);
                     }
                  }else{
                     ge[field].validate := function(inString, varname){
                       return (as_double(inString) <= data[field].range.max &&
                               as_double(inString) >= data[field].range.min);
                     }
                  }
               }
            }
            if(has_field(data[field], 'default'))
              ge[field].default := data[field].default;
         }
      }
      private.usedefaults(ge)
      return ref ge;
   }
     #
   public.setinput := function(ref data){
     wider private;
     for(field in field_names(private.guiElements)){
        if(has_field(data, field)){
           if(has_field(private.guiElements[field], 'en')){
              private.guiElements[field].en->delete('start', 'end');
              if(has_field(data[field]::, '_text')){
                 private.guiElements[field].en->insert(data[field]::_text, 'start');
              } else {
                 private.guiElements[field].data := data[field]
                 if( ! is_string(data[field]) ) {
                    private.guiElements[field].en->insert(as_evalstr(data[field]), 'start');
                 } else {
                    private.guiElements[field].en->insert(data[field], 'start');
                 }
              }
           } else if(has_field(private.guiElements[field], 's')){
              private.guiElements[field].s->value(data[field]);
           } else if(has_field(private.guiElements[field], 'rb')){
              if(len(as_byte(data[field]) > 0))
                 private.guiElements[field].rb[data[field]]->state(T);
           } else if(has_field(private.guiElements[field], 'cb')){
              for(btn in field_names(private.guiElements[field].cb)){
                 if(any(btn == as_string(data[field])))
                    private.guiElements[field].cb[btn]->state(T);
                 else
                    private.guiElements[field].cb[btn]->state(F);
              }
           } else if(has_field(private.guiElements[field], 'lb')){
              private.guiElements[field].lb->clear('start', 'end');
              private.guiElements[field].lb->select(data[field]);
              for(myVal in data[field]){
                 count := ind(private.guiElements[field].enums)[private.guiElements[field].enums == as_string(myVal)];
                 private.guiElements[field].lb->select(as_string(count-1));
              }
           }
        }
     }
   }
      #
   private.getinput := function(ref guiElements){
     wider private;
     data := [=];
     data._method := private::someid;
     for(field in field_names(guiElements)){
        if(has_field(guiElements[field], 'en')){
           theText := guiElements[field].en->get()
           if(guiElements[field].type == 'string' ||
              guiElements[field].type == 'date'   ||
              guiElements[field].type == 'time'   ||
              guiElements[field].type == 'table'   ||
              guiElements[field].type == 'file'){
	       data[field] := theText;
	   } else if (guiElements[field].type == 'vector_string'){
	       data[field] := split(theText);
	       data[field]::_text := theText;
           } else {
              if(has_field(guiElements[field], 'data')){
                 if( len(guiElements[field].data) < 101){
                    data[field] := eval(theText);
                    data[field]::_text := theText;
                 } else {
                    data[field] := ref guiElements[field].data;
                 }
              } else {
                 data[field] := eval(theText);
                 data[field]::_text := theText;
              }
             
           }
              # If there is a validation routine, run it.
           #if(as_byte(data[field])[1] == as_byte('$')[1]){
              #data_bytes := as_byte(data[field])
              #varname := as_string(data_bytes[2:len(data_bytes)]);
              #data[field] := symbol_value(varname);  
              #data[field] := data[field][varname];  #make it not a record.
           #}
           if(has_field(guiElements[field], 'validate')){
              required := F;
              if(has_field(guiElements[field], 'required'))
                 required := guiElements[field].required;
              checkit := T;
              if(!required && len(as_byte(data[field])) == 0){
                    checkit := F;                
              }
              if(checkit){
                 rStat := guiElements[field].validate(data[field], field);
                 if(rStat == F){ # If the validation fails notify the user
                 #note(spaste('Invalid input: ', data[field]), priority'SEVERE');
                    data := F;
                    break;       # Break the for loop
                 }
              }
           }
        }
        if(has_field(guiElements[field], 's')){
           data[field] := guiElements[field].s->value();
        }
        if(has_field(guiElements[field], 'rb')){
           for(btn in field_names(guiElements[field].rb)){
              rbtn := guiElements[field].rb[btn]->state();
              if(rbtn){
                 data[field] := btn;
              }
           }
        }
        if(has_field(guiElements[field], 'cb')){
           data[field] := '';
           for(btn in field_names(guiElements[field].cb)){
              cbtn := guiElements[field].cb[btn]->state();
              if(cbtn)
                 data[field] := paste(data[field], btn);
           }
           data[field] := split(data[field]);
        }
        if(has_field(guiElements[field], 'lb')){
           data[field] := guiElements[field].lb->selection();
        }
        if(has_field(guiElements[field], 'type')){
           if(guiElements[field].type == 'boolean'){
              data[field] := as_boolean(data[field]);
           }else if(guiElements[field].type == 'byte'){
              data[field] := as_byte(data[field]);
           }else if(guiElements[field].type == 'short'){
              data[field] := as_short(data[field]);
           }else if(guiElements[field].type == 'integer'){
              data[field] := as_integer(data[field]);
           }else if(guiElements[field].type == 'float'){
              data[field] := as_float(data[field]);
           }else if(guiElements[field].type == 'double'){
              data[field] := as_double(data[field]);
           }else if(guiElements[field].type == 'complex'){
              data[field] := as_complex(data[field]);
           }else if(guiElements[field].type == 'dcomplex'){
              data[field] := as_dcomplex(data[field]);
           }
        }
     }
     return ref data;
   }

   if(is_record(scrnInputs) && has_field(scrnInputs, 'data') && has_field(scrnInputs, 'actions')){
        if(!has_field(scrnInputs, 'title'))
           scrnInputs.title := title;
          # Make the help menu
        hmenu := [=];
        hmenu::text := 'Help';
        hmenu.about := [=];
        hmenu.about.text := 'About';
        hmenu.about.relief := 'flat';
        hmenu.about.action := about;
        findhelp := "explain data actions";
        if(helpdisplay)
           findhelp := "explain actions";
        for(rec in findhelp){
           if(has_field(scrnInputs, rec)){
              for(field in field_names(scrnInputs[rec])){
                 if(has_field(scrnInputs[rec][field], 'help')){
                    hmenu[field] := [=];
                    if(has_field(scrnInputs[rec][field].help, 'url')){
                       hmenu[field].text := field;
                       hmenu[field].helpurl :=
                                        scrnInputs[rec][field].help.url;
                       hmenu[field].action := function(){
                                         wider hmenu;
                                         bites := as_byte($value)
                                         id := as_string(bites[5:len(bites)]);
                                         help(hmenu[id].helpurl);
                                         };
                    }else{
                       hmenu[field].text := field;
                       hmenu[field].helptext :=
                                         scrnInputs[rec][field].help.text;
                       hmenu[field].action := function(){
                                         wider hmenu;
                                         bites := as_byte($value)
                                         id := as_string(bites[5:len(bites)]);
                                         infowindow(hmenu[id].helptext,
                                                    'AIPS Help Window');
                                         };
                    }
                    hmenu[field].relief := 'flat';
                 }
              }
           }
        }
          # Make the action buttons
        actions := [=];
        for(field in field_names(scrnInputs.actions)){
           actions[field] := [=];
           actions[field].text := field;
           if(has_field(scrnInputs.actions[field], 'label')){
              actions[field].text := scrnInputs.actions[field].label;
           }
           if(has_field(scrnInputs.actions[field], 'type')){
              actions[field].type := scrnInputs.actions[field].type;
           }
              # Needs to be non blocking.
           actions[field].action := function(){
                                   wider private;
                                   waspressed := public.gf.handle::bpressed;
                                   data := private.getinput(private.guiElements);
                                   if(is_record(data)){
                                      if(has_field(scrnInputs.actions[waspressed], 'function')){
                                         scrnInputs.actions[waspressed].function(data);
                                      }
                                      if(dismiss)
                                         public.gf.dismiss();
                                   } else {
                                      note('No record returned');
                                   }
                                 }
        }
        if(!private.noedit){
           actions.reset := [=];
           actions.reset.text := 'Reset';
           actions.reset.action := function(){wider private;
             private.usedefaults(private.guiElements);
           };
        }

          
      # Make the master frame

        if(is_boolean(parent)){
           actions.dismiss := [=];
           actions.dismiss.text := 'Dismiss';
           actions.dismiss.type := 'dismiss';
           public.gf := guiframework(scrnInputs.title, F, hmenu, actions);
        
           private.guiElements := private.creategui(public.gf.getworkframe(),
                                                    scrnInputs.data);
           public.gf.addactionhandler('dismiss', public.gf.dismiss);
        } else {
           public.gf := guiframework(scrnInputs.title, F, F, actions, parent=parent);
        
           private.guiElements := private.creategui(public.gf.getworkframe(),
                                                    scrnInputs.data);
        }
   } else {
      note('Invalid record for gui.inputform');
   }

   public.addactionhandler := function(name, handler){
     public.gf.addactionhandler(name, handler);
   }

   return ref public;
}

#
# Want a gui for tabbed frames basically r.tab.f, r.tab.f := wreck1, etc...
# Loop through all the field names in tab and produces either a tab or listbox
# of goodies.
# Also, do a r.showtab, which is a list of members to show, could also do a
# r.disabletab which shows but disables those tabs.
#

gui.testinputs := function()
{  global gui;
   
#
   wreck := [=];
   wreck.actions := [=];  
   wreck.data := [=];  
#
   wreck.title := 'Test of input form';
#
   wreck.data.name := [=];
   wreck.data.name.label := 'Name';
   wreck.data.name.type := 'string';
   wreck.data.name.default := 'Your name here'
#
   wreck.data.slider := [=];
   wreck.data.slider.label := 'Slider';
   wreck.data.slider.type := 'integer';
   wreck.data.slider.range.min := 1;
   wreck.data.slider.range.max := 100;
   wreck.data.slider.default := 42;
#
   wreck.data.rb := [=];
   wreck.data.rb.label := 'radio button';
   wreck.data.rb.type := 'string';
   wreck.data.rb.default := "three"
   wreck.data.rb.enums := "one two three four";
#
   wreck.data.cb := [=];
   wreck.data.cb.label := 'check button';
   wreck.data.cb.hint := 'check';
   wreck.data.cb.type := 'string';
   wreck.data.cb.default := "one three"
   wreck.data.cb.enums := "one two three four";
#
   wreck.data.lb := [=];
   wreck.data.lb.label := 'list box';
   wreck.data.lb.type := 'string';
   wreck.data.lb.multiple := F;
   wreck.data.lb.enums := "one two three four five six seven";
   wreck.data.lb.default := "two five";
#
   wreck.data.file := [=];
   wreck.data.file.label := 'file';
   wreck.data.file.type := 'file';
#
   wreck.data.data := [=];
   wreck.data.data.label := 'data';
   wreck.data.data.type := 'table';
#
   wreck.data.date := [=];
   wreck.data.date.label := 'date';
   wreck.data.date.type := 'date';
#
   wreck.data.time := [=];
   wreck.data.time.label := 'time';
   wreck.data.time.type := 'time';
#
   wreck.actions.go := [=];
   wreck.actions.go.label := 'Go';
   wreck.actions.go.function := function(data){print 'data:', data;}
#
   fgf := gui.inputform(wreck);
}

gui.testframe := function()
{  global gui;
#
   wreck := [=];
   wreck.actions := [=];  
   wreck.data := [=];  
#
   wreck.title := 'Test of input form';
#
   wreck.data.name := [=];
   wreck.data.name.label := 'Name';
   wreck.data.name.type := 'string';
   wreck.data.name.default := 'Your name here'
   wreck.data.name.help := [=];
   wreck.data.name.help.text := 'Your help text here';
#
   wreck.data.slider := [=];
   wreck.data.slider.label := 'Slider';
   wreck.data.slider.type := 'integer';
   wreck.data.slider.range.min := 1;
   wreck.data.slider.range.max := 100;
   wreck.data.slider.default := 42;
#
   wreck.data.rb := [=];
   wreck.data.rb.label := 'radio button';
   wreck.data.rb.type := 'integer';
   wreck.data.rb.default := "3"
   wreck.data.rb.enums := "1 2 3 4";
   wreck.data.rb.help := [=];
   wreck.data.rb.help.url := 'Refman';
#
   wreck.data.cb := [=];
   wreck.data.cb.label := 'check button';
   wreck.data.cb.hint := 'check';
   wreck.data.cb.type := 'integer';
   wreck.data.cb.default := "1 3"
   wreck.data.cb.enums := "1 2 3 4";
#
   wreck.data.lb := [=];
   wreck.data.lb.label := 'list box';
   wreck.data.lb.type := 'string';
   wreck.data.lb.multiple := F;
   wreck.data.lb.enums := "one two three four five six seven";
   wreck.data.lb.default := "five";
#
   wreck.data.file := [=];
   wreck.data.file.label := 'file';
   wreck.data.file.type := 'file';
#
   wreck.data.data := [=];
   wreck.data.data.label := 'data';
   wreck.data.data.type := 'table';
#
   wreck.data.date := [=];
   wreck.data.date.label := 'date';
   wreck.data.date.type := 'date';
#
   wreck.data.time := [=];
   wreck.data.time.label := 'time';
   wreck.data.time.type := 'time';
#
   wreck.actions.go := [=];
   wreck.actions.go.label := 'Go';
   wreck.actions.go.function := function(data){print 'Data:', data;}
#
   wreck.actions.dismiss := [=];
   wreck.actions.dismiss.text := 'Dismiss';
   wreck.actions.dismiss.type := 'dismiss';
#
   hmenu := [=];
   hmenu::text := 'Help';
   hmenu.about := [=];
   hmenu.about.text := 'About';
   hmenu.about.relief := 'flat';
   hmenu.about.action := about;

   gf := guiframework('Test for guiinputs', F, hmenu, F)
   fgf := gui.inputform(wreck, parent=gf.getworkframe());
   fgf.addactionhandler('dismiss', gf.dismiss);
}

gui.testtab := function()
{  global gui;
#
   wreck := [=];

   wreck1 := [=];
   wreck2 := [=];
   wreck3 := [=];
   wreck4 := [=];
   wreck5 := [=];
   wreck6 := [=];

   wreck1.actions := [=];  
   wreck1.data := [=];  
   wreck1.title := 'Test of tab form, pane 1';
#
   wreck2.actions := [=];  
   wreck2.data := [=];  
   wreck2.title := 'Test of tab form, pane 2';
#
   wreck3.actions := [=];  
   wreck3.data := [=];  
   wreck3.title := 'Test of tab form, pane 3';
#
   wreck4.actions := [=];  
   wreck4.data := [=];  
   wreck4.title := 'Test of tab form, pane 4';
#
   wreck5.actions := [=];  
   wreck5.data := [=];  
   wreck5.title := 'Test of tab form, pane 5';
#
   wreck6.actions := [=];  
   wreck6.data := [=];  
   wreck6.title := 'Test of tab form, pane 6';
#
   wreck1.data.name := [=];
   wreck1.data.name.label := 'Name';
   wreck1.data.name.type := 'string';
   wreck1.data.name.default := 'Your name here'
#
   wreck2.data.slider := [=];
   wreck2.data.slider.label := 'Slider';
   wreck2.data.slider.type := 'integer';
   wreck2.data.slider.range.min := 1;
   wreck2.data.slider.range.max := 100;
   wreck2.data.slider.default := 42;
#
   wreck3.data.rb := [=];
   wreck3.data.rb.label := 'radio button';
   wreck3.data.rb.type := 'string';
   wreck3.data.rb.default := "three"
   wreck3.data.rb.enums := "one two three four";
#
   wreck4.data.cb := [=];
   wreck4.data.cb.label := 'check button';
   wreck4.data.cb.hint := 'check';
   wreck4.data.cb.type := 'string';
   wreck4.data.cb.default := "one three"
   wreck4.data.cb.enums := "one two three four";
#
   wreck5.data.lb := [=];
   wreck5.data.lb.label := 'list box';
   wreck5.data.lb.type := 'string';
   wreck5.data.lb.multiple := F;
   wreck5.data.lb.enums := "one two three four five six seven";
   wreck5.data.lb.default := "five";
#
   wreck6.data.file := [=];
   wreck6.data.file.label := 'file';
   wreck6.data.file.type := 'file';
#
   wreck1.data.data := [=];
   wreck1.data.data.label := 'data';
   wreck1.data.data.type := 'table';
#
   wreck2.data.date := [=];
   wreck2.data.date.label := 'date';
   wreck2.data.date.type := 'date';
#
   wreck3.data.time := [=];
   wreck3.data.time.label := 'time';
   wreck3.data.time.type := 'time';
#
   wreck1.actions.go := [=];
   wreck1.actions.go.label := 'Go';
   wreck1.actions.go.function := function(data){print data;}
#
   wreck1.actions.dismiss := [=];
   wreck1.actions.dismiss.text := 'Dismiss';
   wreck1.actions.dismiss.type := 'dismiss';
#
   wreck2.actions.go := [=];
   wreck2.actions.go.label := 'Go';
   wreck2.actions.go.function := function(data){print data;}
#
   wreck2.actions.dismiss := [=];
   wreck2.actions.dismiss.text := 'Dismiss';
   wreck2.actions.dismiss.type := 'dismiss';
#
   wreck3.actions.go := [=];
   wreck3.actions.go.label := 'Go';
   wreck3.actions.go.function := function(data){print data;}
#
   wreck3.actions.dismiss := [=];
   wreck3.actions.dismiss.text := 'Dismiss';
   wreck3.actions.dismiss.type := 'dismiss';
#
   wreck4.actions.go := [=];
   wreck4.actions.go.label := 'Go';
   wreck4.actions.go.function := function(data){print data;}
#
   wreck4.actions.dismiss := [=];
   wreck4.actions.dismiss.text := 'Dismiss';
   wreck4.actions.dismiss.type := 'dismiss';
#
   wreck5.actions.go := [=];
   wreck5.actions.go.label := 'Go';
   wreck5.actions.go.function := function(data){print data;}
#
   wreck5.actions.dismiss := [=];
   wreck5.actions.dismiss.text := 'Dismiss';
   wreck5.actions.dismiss.type := 'dismiss';
#
   wreck6.actions.go := [=];
   wreck6.actions.go.label := 'Go';
   wreck6.actions.go.function := function(data){print data;}
#
   wreck6.actions.dismiss := [=];
   wreck6.actions.dismiss.text := 'Dismiss';
   wreck6.actions.dismiss.type := 'dismiss';
#
   wreck.tab1 := wreck1;
   wreck.tab2 := wreck2;
   wreck.tab3 := wreck3;
   wreck.tab4 := wreck4;
   wreck.tab5 := wreck5;
   wreck.tab6 := wreck6;
#   wreck::disallow := "tab3 tab4";
#   wreck::show := "tab3";
   wreck::categories := [=];
   wreck::categories.All := T;
   wreck::categories.First3 := "tab1 tab2 tab3";
   wreck::categories.Last3 := "tab4 tab5 tab6";
   wreck::categories.Last3::label := 'Label for last 3 functions'

   fgf := gui.tabform(wreck, tabcount=3, side='left');
   fgf.dismisshandler('dismiss')
}

# const gui := gui;
