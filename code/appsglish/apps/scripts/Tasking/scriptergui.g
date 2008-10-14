# scriptergui: GUI interface to the scripter object
# Copyright (C) 1999,2000,2001,2002
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
# $Id: scriptergui.g,v 19.2 2004/08/25 02:04:18 cvsmgr Exp $


include "widgetserver.g"
include "guiframework.g"
include "aipsrc.g"
include "popuphelp.g"


pragma include once

# The scripter GUI reguires a scripter object
# Since the scriptergui is a subsequence it handles several events, typically
# sent(or relayed) by the scripter object.
#
# close, - tidys everything up and d
# displayonly, - enable/disable the text canvas
# erase, - erases the content of the text canvas
# map, - maps us to the screen
# unmap, - hides the windows but doesn't kill anything
# addcommand, - add a command to the text canvas
# commands - Add a bunch of commands to the text canvas,
# importfile - import's a text file into the text canvas

scriptergui := subsequence(ref so, displayonly=F,
			   title='Scripter gui (AIPS++)', widgetset=dws){
   private := [=];
   private.scripter := ref so;
   private.displayonly := displayonly;
   private.help := [=];                     #Popup help for some items.
      # Need a "batch" command for running the script.
   private.batchcommand := 'unset DISPLAY; glish -l';
   private.autosavetime := 30.0;
   private.autosavefile := '.scripter_autosave';
   private.autosave   := T;
   private.saveNeeded := F;
   private.savecatalog := F;
   private.getcatalog := F;
   private.fn  := '-adobe-courier-medium-r-normal--14-*';

   found := drc.find(batchcommand, 'scripter.submitcommand');
   if(found){
     private.batchcommand := batchcommand;
   }

   found := drc.find(autosavetime, 'scripter.autosavetime')
   if(found){
     private.autosavetime := autosavetime;
   }
   found := drc.find(autosavefile, 'scripter.autosavefile')
   if(found){
     private.autosavefile := autosavefile;
   }
   found := drc.find(autosave, 'scripter.autosavefile')
   if(found){
     if(autosave == 'on' || autosave == 'T')
        private.autosave := T;
     else 
        private.autosave := F;
   }

  # Setup the standard menus

   private.filemenu := function(){
      wider private;
      file := [=];
      file::text := 'File';
      file::help := 'Open, Save as, Done'
      file.open := [=];
      file.open.text := 'Open...';
      # file.open.help := 'Open a file to use for scripting';
      file.open.relief := 'flat';
      file.open.action := subsequence () {
         wider private;
         private.gf.busy(T);
         include 'catalog.g'
         if(is_boolean(private.getcatalog))
            private.getcatalog := catalog();
	 private.getcatalog.gui();
	 private.getcatalog.show('.', 'Glish');
	 getit := function(selection) {
	   wider private;
	   if(is_string(selection)&selection!='') {
             private.self->importfile(selection);
	     private.gf.updatestatus(paste('Opened:',private.scripter.getlogfile()));
	   }
	 }
	 private.getcatalog.setselectcallback(getit);
         private.gf.busy(F);
      }
      file.saveas := [=];
      file.saveas.text := 'Save as...'
      # file.saveas.help := 'Save script into a file';
      file.saveas.relief := 'flat';
      file.saveas.action := subsequence () {
         wider private;
         private.gf.busy(T);
         include 'catalog.g'
         if(is_boolean(private.savecatalog))
            private.savecatalog := catalog();
	 private.savecatalog.gui();
	 private.savecatalog.show('.', 'Glish');
	 getit := function(selection) {
	   wider private;
	   if(is_string(selection)&selection!='') {
	     if(!is_fail(private.scripter.save(selection))){
	        private.gf.updatestatus(paste('Saved to:',private.scripter.getlogfile()));
                private.saveNeeded := F;
             } else {
                note('Unable to save file, check directory or file permissions?', priority='SEVERE', origin='scripter');
             }
	   }
	 }
	 private.savecatalog.setselectcallback(getit);
	 private.gf.busy(F);
      }

      file.blank := [=];
      file.blank.text := '';
      file.blank.relief :='flat';
      file.blank.disabled :=T;

      file.close := [=];
      file.close.text := 'Done';
      file.close.type := 'dismiss';
      # file.close.help := 'Close scripter window';
      file.close.relief := 'flat';
      file.close.action := function() {wider private;
         private.dismiss()
      }
      return ref file;
   }
   private.optionsmenu := function(){
     wider private;
     options := [=];
     options::text := 'Options';
     options::help := 'Toggle editing';
     options.edtoggle := [=];
      if(private.displayonly){
        edtext := 'Enable Editing';
      } else {
        edtext := 'Disable Editing';
      }
      options.edtoggle.text := edtext;
      options.edtoggle.type := 'plain';
      options.edtoggle.action := private.toggleEditFlag;
      return ref options;
   }

   private.toggleEditFlag := function(){
      wider private;
      private.displayonly := !private.displayonly;
      if(private.displayonly)
        edtext := 'Enable Editing';
      else
        edtext := 'Disable Editing';
      private.gf.app.mb.btns.optionsedtoggle->text(edtext);
      # print private.gf.app.cmd.f.submit;
   }

       # Define the actions when we press a button

   actions := [=];
   actions.submit := [=];
   actions.submit.text := 'Submit';
   actions.submit.type := 'action';
   actions.submit.help := 'Run the contents of the scripter buffer';
   actions.submit.action := function(){
     wider private;
     private.save();
     batchCommand := private.bentry->get();
     doit := paste(batchCommand, private.scripter.getlogfile());
     note(doit);
     a := shell(doit, async=T);
     whenever a->stdout do {
       print $value
     }
     private.gf.updatestatus(paste('Submitted:',
				 private.scripter.getlogfile()));
   }
   actions.save := [=];
   actions.save.text := 'Save';
   actions.save.help := 'Save the contents of the scripter buffer to a file';
   actions.save.action := function(){
     wider private;
     private.save();
     private.gf.updatestatus(paste('Saved to:',private.scripter.getlogfile()));
   }
   actions.clear := [=];
   actions.clear.text := 'Clear';
   actions.clear.help := 'Clear the contents of the scripter buffer';
   actions.clear.action := function(){
     wider private;
     private.commands->delete('start', 'end');
     private.saveNeeded := F;
     private.gf.updatestatus('Commands cleared.');
   }
   actions.dismiss := [=];
   actions.dismiss.text := 'Dismiss';
   actions.dismiss.help := 'Dismiss the scripter logger window';
   actions.dismiss.type := 'dismiss';
   actions.dismiss.action := function() {wider private; private.dismiss();}

   menus := [=];
   menus.file := private.filemenu();
   menus.options := private.optionsmenu();

   private.queryquit := subsequence(ws=dws){
         # Log ourselves to the managed popup list?
      tf := ws.frame(title='Scripter GUI Query', width='3i', side='top');
      mf := ws.frame(tf, width='3i');
      notice := ws.message(mf, 'Changes have been made, you can:\n', relief='flat',
                           font=private.fn);
      bf := ws.frame(tf, side='left', width='3i');
      sq := ws.button(bf, 'Save Changes',font=private.fn);
      qa := ws.button(bf, 'Quit Scripter Gui',font=private.fn);
      nq := ws.button(bf, 'Don\'t Quit',font=private.fn);
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

   dum := widgetset.tk_hold();

   # Setup the top-level window for the scripter gui

   private.gf := guiframework(title, menus=menus, actions=actions, ws=widgetset);
   private.self := ref self;
   private.mf := widgetset.frame(private.gf.getworkframe())
   private.batchf2 := widgetset.frame(private.mf, expand='x', side='top');
   private.batchf := widgetset.frame(private.batchf2, expand='x', side='left');
   private.blabel := widgetset.label(private.batchf, text='Submit command');
   private.bentry := widgetset.entry(private.batchf);
   private.help.howtorun := widgetset.popuphelp(private.bentry,
                                     'Command to issue to run the script file');

   private.bentry->insert(private.batchcommand);

   private.textf := widgetset.frame(private.mf, side='left', expand='both');
   private.commands := widgetset.text(private.textf, wrap='none', background='white',
                              width=100);
   private.help.commands := widgetset.popuphelp(private.commands,
            'Logged, loaded or edited commands for a run script');
   private.vsb := widgetset.scrollbar(private.textf, orient='vertical');
   private.hsbf := widgetset.frame(private.mf, side='right', expand='x');
   private.hsbb := widgetset.frame(private.hsbf, expand='none', height=23, width=23,
                           relief='groove');
   private.hsb := widgetset.scrollbar(private.hsbf, orient='horizontal');
#   private.buttonf := widgetset.frame(private.mf, expand='x');

   private.dismiss := function() {
      wider private;
      dismissGUI := F;
      if(private.saveNeeded){
         qq := private.queryquit();
         whenever qq->returns do {
           gotThis := $value;
           if(gotThis == 'save'){
              private.save();
              dismissGUI := T;
              private.saveNeeded := F;
           } else if(gotThis == 'quit'){
              dismissGUI := T;
              private.saveNeeded := F;
           } else {
              dismissGUI := F;
           }
           if(dismissGUI)
              private.gf.unmap();
               
         }
      } else {
         dismissGUI := T;
      }
      if(dismissGUI)
         private.gf.unmap();
   }

   private.save := function(savename = F) {
      wider private;
        #
        # OK here we see if we need to get any edits, then reset the log
        # to reflect the changes the user made.
        #
      if(!private.displayonly){
        private.scripter.reset();
        commands := split(private.commands->get('start', 'end'), '\n');
        if(len(commands) > 0){
           # Commented out as a work around for the { glish defect.
           # private.commands->delete('start', 'end');
           for(i in 1:len(commands)){
              private.scripter.log(commands[i], guilog=F);
           }
        }
      }
      if(!is_fail(private.scripter.save())){
         private.gf.updatestatus(paste('Saved to:',private.scripter.getlogfile()));
         private.saveNeeded := F;
         dummy := shell(paste('rm -f ', private.autosavefile));
      } else {
          note('Unable to save file, check directory or file permissions?', priority='SEVERE', origin='scripter');
      }
   }

   private.gf.addactionhandler('dismiss', private.dismiss);

   if(!private.displayonly){
      private.batchf2->map();
   } else {
      private.batchf2->unmap();
   }

      # Scroll events for the canvas

   whenever private.vsb->scroll, private.hsb->scroll do {
      private.commands->view($value);
   }

   whenever private.commands->xscroll do {
      private.hsb->view($value);
   }

   whenever private.commands->yscroll do {
      private.vsb->view($value);
   }

   whenever private.mf->killed do {
      private.self->close();
   }

   whenever self->close do {
      private.dismiss();
   }

   whenever system->exit do {
     if(is_record(private)){
         if(private.saveNeeded){
            include 'choicewindow.g'
            cw := choicewindow('The scripter file needs saving,\nYou may save or discard it.', "Save Discard");
            if(cw == 'Save'){
               private.scripter.save();
            }
         }
         dummy := shell(paste('rm -f ', private.autosavefile));
      }
   }

   whenever self->displayonly do {
      if(is_boolean($value) && ($value == T || $value == F)){
         private.displayonly := $value;
      } else {
         if(private.displayonly){
           private.displayonly := T;
         } else {
           private.displayonly := F;
         }
      }
      if(!private.displayonly){
         private.commands->disabled(F);
         private.batchf->map();
      } else {
         private.commands->disabled(T);
         private.batchf->unmap();
      }
   }
   whenever self->erase do {
      private.commands->delete('start', 'end');
      private.saveNeeded := F;
      private.gf.updatestatus('Commands cleared');
   }

   self.map  := function() {
     wider private;
     private.gf.map();
   }

   whenever self->map do {
      private.gf.map();
   }

   self.unmap  := function() {
     wider private;
     private.gf.unmap();
   }

   whenever self->unmap do {
      private.gf.unmap();
   }

   self.addcommand := function(value) {
      wider private;
      if(!(value~m/\n$/)) value := spaste(value, '\n');
      private.commands->insert(value, 'end');     
      private.commands->see('end');
      private.gf.updatestatus('Save needed');
      private.saveNeeded := T;
   }

   whenever self->addcommand do {
     self.addcommand($value);
   }

   self.commands := function(value) {
      theCommands := value
      howMany :=  len(theCommands);
      if(howMany > 0){
         for(i in 1:howMany){
	   if(!(theCommands[i]~m/\n$/)) theCommands[i] := spaste(theCommands[i], '\n');
	   private.commands->insert(theCommands[i], 'end');     
	   # private.commands->insert(spaste(theCommands[i], '\n'), 'end');     
         }
	 private.commands->see('end');
         private.gf.updatestatus('Save needed');
         private.saveNeeded := T;
      }
   }

   self.done := function() {
     wider private, self;
     self.unmap();
     for (field in field_names(private)) {
       if(is_agent(private[field])) private[field]:=F;
     }
     private := F;
     self := F;
     return T;
   }

   whenever self->commands do {
     self.commands();
   }

   whenever self->importfile do {
      filename := $value;
      private.scripter.load(filename);
   }

      # Set a timer to autosave the text pane
   if(private.autosave){
      private.timer := client("timer", private.autosavetime);
      private.oldcommands := "";
      whenever private.timer->ready do {
         if(!private.displayonly){
           commands := split(private.commands->get('start', 'end'), '\n');
           theTest := (any(commands != private.oldcommands));
           if(is_fail(theTest) || any(commands != private.oldcommands)){
              if(len(commands) > 0){
                 fd := open(split(paste(">", private.autosavefile)));
                 if(is_fail(fd)){
                   note(paste('Unable to write into the autosave file, check directory or file permissions?',
                          private.autosavefile), priority='SEVERE', origin='scripter');
                   private.gf.updatestatus(paste('Auto save to', private.autosavefile, 
                                             'not possible!'));
                 } else {
                    for(i in 1:len(commands)){
                       write(fd, commands[i]);
                    }
                    private.oldcommands := commands;
                    # note(paste('Scripter gui text auto saved to', private.autosavefile));
                    private.gf.updatestatus(paste('Scripter gui text auto saved to', private.autosavefile));
                 }
                 private.saveNeeded := T;
                 fd := 0;
              }
           }
         }
      }
   }
   dum := widgetset.tk_release();

   include 'choicewindow.g'
   fd := open(paste("<", private.autosavefile));
   if( !is_fail(fd)){
      fd := 0;
      note(paste("Auto-save file ", private.autosavefile, "detected."));
      cw := choicewindow(paste('An existing auto-save file', private.autosavefile, 'was detected,\nYou may load or discard it.'), "Load Discard");
      if(cw == 'Load'){
         private.scripter.load(private.autosavefile);
         private.saveNeeded := T;
      } else {
         dummy := shell(paste('rm -f ', private.autosavefile));
      }
   }

}
