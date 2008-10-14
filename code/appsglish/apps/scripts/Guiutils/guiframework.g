# guiframework: create a standard gui environment 
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.public.dismiss := function()
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
#   $Id: guiframework.g,v 19.2 2004/08/25 01:59:17 cvsmgr Exp $
#

#
#guiframework -- Function that creates a standard gui, with a menubar,
# areas for buttons, busy, titles, and all the window dressings needed
# for a guibased application
#

# Here are the public functions from guiframework.
#
#public.busy := function(flag=T)
#public.defaultmenus := function()
#public.defaulthelp := function()
#public.defaultactions := function()
#public.addmenus := function(menus)
#public.addhelp := function(helpmenu)
#public.addactions := function(actions)
#public.getworkframe := function()
#public.updatetitle := function(newtitle)
#public.updatestatus := function(newstatus)
#public.addactionhandler := function(aname, action)
#public.cleanup := function()

pragma include once

include "note.g"
include "bug.g"
include "guimisc.g"
include "about.g"
include "aips2help.g"
include "widgetserver.g"
include "popuphelp.g"


const guiframework := function( title='AIPS++ Window',
                                menus=T, helpmenu=T, actions=T,
                                guiframenote=note, parent=F, ws=dws)
{
   if(!have_gui()){
     fail('guiframework makes no sense without a gui!');
   }

   app := [=];            # All the gui parts are stored in app
   app.parent := parent;

   priv := [=];
   priv.note := guiframenote;
   priv.deftitle := 'AIPS++ Window';

   public := [=];         # Public functions and all that.
   public.handle := [=];
   public.handle.agent := create_agent();
   public.handle::returned := F;
   public.agents := [=];
   
   #Generic dismiss button, causes the guiframework to go away
   public.dismiss := function()
   {    wider app;
     wider public;
     if(is_agent(app.parent)){
        app.parent->unmap();
        public.cleanup();
     }
     app.f := 0;
     app.parent := 0;
   }

   # enables/disables everything inside the guiframework's toplevel frame,
   public.busy := function(flag=T)
   {
      wider app;
      if(flag){
        app.f->cursor('watch')
        app.f->disable();
      }else{
        app.f->enable();
        app.f->cursor('left_ptr')
      }
     
   }

   public.map := function() {
     wider app;
     app.f->map();
   }

   public.unmap := function() {
     wider app;
     app.f->unmap();
   }

   # the default file menu, Nothing special.
   priv.default_filemenu := function()
   {  wider public;
      file := [=];
      file::text := 'File';
      file.open := [=];
      file.open.text := 'Open...';
      file.open.relief := 'flat';
      file.open.action := subsequence () { 
            fc := filechooser(title='AIPS++ Filechooser -- Open File', wait=F);
            whenever fc->returns do {
               priv->returns(op='open', tabname=$value.guiReturns);
            }
         }
      file.save := [=];
      file.save.text := 'Save...'
      file.save.relief := 'flat';
      file.save.action := subsequence () {
            fc := filechooser(title='AIPS++ Filechooser -- Save File',
                              wait=F, writeOK=T);
            whenever fc->returns do {
               priv->returns(op='save', tabname=$value.guiReturns)
            }
         }
      file.blank1 := [=];
      file.blank1.text := '';
      file.blank1.relief :='flat';
      file.blank1.disable :=T;

      file.close := [=];
      file.close.text := 'Close';
      file.close.relief := 'flat';
      file.close.action := public.dismiss;

      return ref file ;
   }

   #default options menu
   priv.default_options := function()
   {
      options := [=];
      options::text := 'Options'
      options.browser := [=];
      options.browser::text := 'Browser'
      options.browser.text := 'Browser'
      options.browser.type := 'menu'
      options.browser.relief := 'flat'
   #
      options.browser.menu := [=];
      options.browser.menu.netscape := [=];
      options.browser.menu.netscape.text := 'Netscape';
      options.browser.menu.netscape.type := 'radio';
      options.browser.menu.netscape.relief := 'flat';
      options.browser.menu.netscape.action := function(){ global helpsystem;
                                            helpsystem::browser := 'netscape';}
   #
      options.browser.menu.mosaic := [=];
      options.browser.menu.mosaic.text := 'Mosaic';
      options.browser.menu.mosaic.type := 'radio';
      options.browser.menu.mosaic.relief := 'flat';
      options.browser.menu.mosaic.action := function(){global helpsystem;
                                            helpsystem::browser := 'mosaic';}
   #
      options.browser.menu.other := [=];
      options.browser.menu.other.text := 'Other';
      options.browser.menu.other.type := 'radio';
      options.browser.menu.other.relief := 'flat';
      options.browser.menu.other.action := function(){ global helpsystem;
                                            helpsystem::browser := 'other';}
      return ref options;
   }

   # Returns a reference to the default menus, file and options

   public.defaultmenus := function()
   {  wider priv;
      menus := [=];
      menus.file := priv.default_filemenu();
      menus.options := priv.default_options();
      return ref menus;
   }

   # Returns a reference to the default help menu

   public.defaulthelp := function()
   {
      hmenu := [=];
      hmenu::useWidget := T;
      return ref hmenu;
   }

   # Returns a reference to the default actions

   public.defaultactions := function()
   {  wider public;
      wider priv;
      action := [=];
      action.apply := [=];
      action.apply.text := 'Apply';
      action.apply.type := 'action';
      action.apply.action := function(){wider priv;
                                        priv.note('Apply Pressed')};
      action.reset := [=];
      action.reset.text := 'Reset';
      action.reset.action := function(){wider priv;
                                        priv.note('Reset Pressed')};
      action.cancel := [=];
      action.cancel.text := 'Cancel';
      action.cancel.type := 'dismiss';
      action.cancel.action := public.dismiss;
      return ref action;
   }

   #  Give a record of menus it adds the menus to the menu bar in order

   public.addmenus := function(menus)
   { wider app;
     wider priv;
     rStat := T;
     if(is_record(menus)){
        for(mname in field_names(menus)){
           priv.addmenu(app.mb.funs, mname, menus[mname]);
        }
     } else {
         if(!is_boolean(menus) || (is_boolean(menus) && menus != F)){
            priv.note('Failed to create menus',priority='SEVERE', 
		      origin='guiframework.admenus');
            fail('Unable to create menus');
         }
     }
     return rStat;
   }

   # Attaches a help menu to the help choice

   public.addhelp := function(helpitems)
   { wider app;
     wider priv;
     if(has_field(helpitems::, 'useWidget')){
        count :=len(field_names(helpitems));
        if(count > 0){
           for(i in 1:count){
             menutext[i] := helpitems[i].text;
             menuaction[i] := helpitems[i].action;
           }    
           app.mb.helpbutton := ws.helpmenu(app.mb.help, menuitems=menutext,
                                          refmanitems=menuaction);
        } else {
           app.mb.helpbutton := ws.helpmenu(app.mb.help);
        }
     } else {
       priv.addmenu(app.mb.help, 'help', helpitems);
     }
   }

   # Adds an individual menu to the menubar.  Note there are two menu bars
   # app.mb.funs (which starts on the left) and app.mb.help (which starts
   # on the right).

   # mb - frame containing the menubar
   # mname - Menu name
   # themenu - record containting the "menu"
   # tFlag - flag to identify whether to create the menubutton or not.
   #         typically set for menubar, individual picks in the menu don't
   #         usually need it.

   priv.addmenu := function(ref mb, mname, themenu, tFlag=T)
   { wider app;
     wider public;
     mtype := 'menu'
     if(has_field(themenu, 'type')){
        mtype := themenu.type;
      }
     if(tFlag){
        app.mb.btns[mname] := ws.button(mb, relief='flat', text=themenu::text,
                                     type=mtype);
        if(has_field(themenu::, 'help')){
           app.mb._pophelp[mname] := popuphelp(app.mb.btns[mname], themenu::help);
        }
     }
     if(is_record(themenu)){
           # Loop through all the fields in a menu
        for(pickone in field_names(themenu)){
              # set the default, relief, type, state, and enable flag
           brelief := 'flat'
           btype := 'plain';
           bstate := F;
           bdisabled := F;

           # modify the default menu parameters if requested
           if(has_field(themenu[pickone], 'relief')){
              brelief := themenu[pickone].relief;
           }
# 
           if(has_field(themenu[pickone], 'type')){
              btype := themenu[pickone].type;
              if((btype == 'radio' || btype == 'check') &&
                  has_field(themenu[pickone], 'state')){
                 bstate := themenu[pickone].state;
              }
           }
#
           if(has_field(themenu[pickone], 'disabled')){
              bdisabled := themenu[pickone].disabled;
           }
           # Typo should be disabled, but seems I have disable lots of places
           if(has_field(themenu[pickone], 'disable')){
              bdisabled := themenu[pickone].disable;
           }
#
           # Add the button to the menu
           app.mb.btns[spaste(mname,pickone)] := ws.button(app.mb.btns[mname],
                                    text=themenu[pickone].text, relief=brelief,
                                    type=btype, disabled=bdisabled,
                                    value=spaste(mname,pickone));
           # Add popup help if necessary
           if(has_field(themenu[pickone], 'help')){
              app.mb.btns._pophelp[spaste(mname, pickone)] := 
                                     popuphelp(app.mb.btns[spaste(mname,pickone)],
                                            themenu[pickone].help);
           }
           # Set the state of a button if necessary
           if(bstate){
             app.mb.btns[spaste(mname,pickone)]->state(bstate);
           }

           # here's where we map the call backs for menu actions.  we use
           # the value of the button to identify which call back to use.

           if(has_field(themenu[pickone], 'action')){
              public.handle[spaste(mname,pickone)] :=
                          themenu[pickone].action;
              whenever app.mb.btns[spaste(mname,pickone)]->press do {
                     # put the return value of the call back in a public place
                     # and set a flag that the call back has happened.
                  if(is_function(public.handle[$value])){
                     public.handle::value := public.handle[$value]();
                     public.handle::returned := T;
                     if(is_agent(public.handle::value)){
                        whenever public.handle::value->returns do {
                           public.handle.agent->returns($value);
                        }
                     }
                  }
              }
           }

           # here we recursively add menus for cascading menus

           if(has_field(themenu[pickone], 'menu')){
               priv.addmenu(app.mb.btns[spaste(mname)],
                            spaste(mname,pickone), themenu[pickone].menu, F);
           }
        }
     }
   } # end public.addmenu

   # Given a record of actions add them to the command frame as buttons.

   public.addactions := function(actions)
   { wider app;
     wider public;
     if(is_record(actions)){
        app.cmd.f := [=];
        app.cmd.b := [=];
        app.cmd.help := [=];
           # Loop through all actions needing a button
        for(bname in field_names(actions)){
            app.cmd.f[bname] := ws.frame(app.cmd);
            if(has_field(actions[bname], 'type')){
               app.cmd.b[bname] := ws.button(app.cmd.f[bname],
                                           actions[bname].text,
                                        value=bname, type=actions[bname].type);
            } else {
               app.cmd.b[bname] := ws.button(app.cmd.f[bname],
                                           actions[bname].text, value=bname);
            }
               # Add popup help if it has it specified
            if(has_field(actions[bname], 'help')) {
               app.cmd.help[bname] := popuphelp(app.cmd.b[bname],
                                                actions[bname].help);
            }
               # Add the handler if it has one specified
            if(has_field(actions[bname], 'action')) {
               public.addactionhandler(bname, actions[bname].action);
            } else {
               public.addactionhandler(bname, F);
            }
        }
     }
   }

   # Initialize the whole shebang

   priv.initialize := function(windowtitle, menus, helpmenu, actions)
   {  wider app;
      wider public;
      wider priv;
         # Create a top-level frame if necessary
      if(is_boolean(app.parent)){
         app.f := ws.frame(title=windowtitle, width=200, height=200);
         app.parent := ref app.f;
      } else {
         if(windowtitle != priv.deftitle) {
               # Put a title in the subframe if we want one.
            app.mf := ws.frame(app.parent)
            app.title := ws.message(app.mf, windowtitle);
            app.f := ws.frame(app.parent);
         } else {
            app.f := ref app.parent;
         }
      }
      #
      # Standard menu bar buttons if desired.
      #
      if(is_boolean(menus) && menus == T){
         menus := public.defaultmenus();
      }
      if(is_boolean(helpmenu) && helpmenu == T){
         helpmenu := public.defaulthelp();
      }
  
         # Make the menubar if we need one.
      if( is_record(menus) || is_record(helpmenu) ) {
         app.mb := [=];
         app.mb := ws.frame(app.f, side='left', expand='x', width=200,
                         relief='raised');
         app.mb.funs := ws.frame(app.mb, side='left', expand='x', height=10);
         app.mb.help := ws.frame(app.mb, side='right', expand='x', height=10);
         app.mb.btns := [=];
         app.mb.btns._pophelp := [=];
         app.mb._pophelp := [=];

   
         public.addmenus(menus);
         public.addhelp(helpmenu);
      }

         # User's put their components into the "work frame"

      app.work := ws.frame(app.f, relief='groove', expand='both');
         #
         #  Add action buttons if needed
         #
      if(is_boolean(actions) && actions == T){
         actions := public.defaultactions();
      }
      if(is_record(actions)){
         app.cmd := ws.frame(app.f, side='left', relief='flat', expand='x');
         public.addactions(actions);
      }

         # Make a status frame at the bottom of the frame.
      app.status.f := ws.frame(app.f, side='left', height=10, expand='x');
      app.status.label := ws.label(app.status.f, text='', pady=0, borderwidth=0);
      return ref app;
   }

      # Returns a reference to the work frame so folks can use it as a parent
      # for adding additional gui components

   public.getworkframe := function()
   {  return ref app.work; }


      # update the title of a window

   public.updatetitle := function(newtitle)
   { wider app;
     app.f->title(newtitle);
   }

   # Updates the status line of a window

   public.updatestatus := function(newstatus)
   { wider app;
     app.status.label->text(newstatus);
   }

   # Given an aname and an action, add them into the handle record.

   public.addactionhandler := function(aname, action)
   {  wider app;
      wider public;
      # avoid starting the whenever each time this is called
      # there is no point in checking the value of hasWhenever
      # in the attribute since if it is present, the whenever
      # for this aname has already been setup
      needs_whenever := T;
      if(has_field(public.handle, aname) && 
         has_field(public.handle[aname]::,"hasWhenever")){
         needs_whenever := F;
      }
      if(is_function(action)){
         public.handle[aname] := action;
      } else {
         #
         # Default action is to return the value of the button pressed.
         #
         public.handle[aname] := F;
      }
      if(needs_whenever){
         whenever app.cmd.b[aname]->press do {
            public.handle::bpressed := $value;
            if(is_function(public.handle[$value])){
               public.handle::value := public.handle[$value]();
            } else {
               public.handle::value := $value;
            }
            public.handle::returned := T;
         }
         public.handle[aname]::hasWhenever := T;
      }
   }

     # After dismissing a guiframework, go through and kill off as many agents
     # as we can find.
   public.cleanup := function(){
     wider public;
     if(is_record(public)){
       if(has_field(public, 'handle')){
          if(has_field(public.handle, 'agent')){
             public.handle.agent := F;
          }
          public.handle := F;
       }    
       if(has_field(public, 'app')){
         if(has_field(public.app, 'mb')){
            public.app.mb := F;
         }
         public.app := F;
       }
       if(has_field(public, 'agents') && is_record(public.agents)){
          for(field in field_names(public.agents)){
             public.agents[field] := F;
          }
          public.agents := F;
       }
     }
   }
   public.done := public.dismiss;

      # Having defined everything, initialize and return our public parts
   public.app := priv.initialize(title, menus, helpmenu, actions);
   return ref public;

}
const gf := guiframework;
