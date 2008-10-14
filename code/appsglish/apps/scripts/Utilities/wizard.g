# wizard: Step through a number of operations in turn
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001
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
#   $Id: wizard.g,v 19.2 2004/08/25 02:10:53 cvsmgr Exp $
#

include 'widgetserver.g';
include 'autogui.g';
include 'note.g';

wizard := subsequence(title='Wizard', writetoscripter=T, needviewer=F,
		      widgetset=dws)
{
    private := [=];

    private.whenevers := as_integer([]);
    private.pushwhenever := function() {
      wider private;
      local lwe := last_whenever_executed();
      if (is_integer(lwe))                   # guard against fail values
          private.whenevers[len(private.whenevers) + 1] := lwe;
    }

    private.stopnow := F;

    private.font := '-*-courier-medium-r-normal--12-*';
    private.boldfont := '-*-courier-bold-r-normal--12-*';

    private.writetoscripter := writetoscripter;

    if (!have_gui()) {
        return throw('wizard - can not start GUI. ',
                     'Set DISPLAY environment variable?');
    }

    include 'serverexists.g';
    if(needviewer) {
      include 'viewer.g';
#                          
# See if we need a private color map or not by making
# a dummy displaypanel
#   
      widgetset.tk_hold();
      if (!serverexists('dv', 'viewer', dv)) {
	return throw('The viewer server "dv" is not running',
		     origin='wizard.g');
      }
      prvt.f0 := dv.newdisplaypanel(show=F, newcmap=unset);
      if (!is_fail(prvt.f0)) {
	newcmap := prvt.f0.newcmap();
	prvt.f0.done();
      } else {
	return throw('Unable to make any viewer displaypanels');
      }
      
      private.wholeframe := widgetset.frame(title=title, side='top', 
					    newcmap=newcmap);
    }
    else {
      private.wholeframe := widgetset.frame(title=title, side='top');
    }
#
# A menu bar containing File, Special, Options, Help
#
    private.menubar := widgetset.frame(private.wholeframe,side='left',
				       relief='raised');
#
# File Menu 
#
    private.filebutton := widgetset.button(private.menubar, 'File',
					   relief='flat', type='menu');
    private.filebutton.shorthelp := 'Do various operations';
    private.filemenu := [=];
    private.filemenu["dismiss"] :=
	widgetset.button(private.filebutton, 'Dismiss Window');
    private.filemenu["exit"] :=
	widgetset.button(private.filebutton, 'Done', type='halt');

    whenever private.filemenu['exit']->press do {
      note('Wizard stopping at next opportunity', origin='wizard');
      private.stopnow := T;
      deactivate;
    } private.pushwhenever();
# 
# Finally the Help menu
#
    private.rightmenubar := widgetset.frame(private.menubar,side='right');
    private.helpmenu := widgetset.helpmenu(private.rightmenubar,
					   menuitems=['simpleimage'],
					   refmanitems=['Refman:imager.simpleimage']);

    private.stepframe := widgetset.frame(private.wholeframe, side='left', expand='x');
    private.step := widgetset.text(private.stepframe, relief='groove', height=1, 
                         disabled=T,font=private.boldfont);
    private.wholeworkframe := widgetset.frame(private.wholeframe, relief='groove', 
                                    side='top');
    private.workinfoframe := widgetset.frame(private.wholeworkframe, side='left', 
                                   expand='x');
    private.workinfoframe.shorthelp := 'Displays more detailed information';

    private.workinfo := widgetset.text(private.workinfoframe, relief='flat', height=8, 
                         disabled=T,font=private.font);
    private.messageline := widgetset.messageline(private.wholeframe);
    private.controlframe := widgetset.frame(private.wholeframe, side='right',
                                 expand='x');
    private.nextbutton := widgetset.button(private.controlframe, 'Next ->',
				 font=private.font, type='action');
    private.nextbutton.text := 'next';
    private.cancelbutton := widgetset.button(private.controlframe, 'Cancel',
				   font=private.font);
    private.cancelbutton.text := 'cancel';
    private.killframe := widgetset.frame(private.controlframe, side='right',
                                 expand='x');
    private.killbutton := widgetset.button(private.killframe, 'Running: abort?',
					   background='red');
    private.killframe->unmap();
    private.killbutton.shorthelp := 'Kill this tool completely (use with care!)';
    whenever private.killbutton->press do {
      self->kill();
      deactivate;
    }  private.pushwhenever();
    
    private.error := widgetset.text(private.controlframe, height=1, width=50,
				    disabled=T, 
				    foreground='red', relief='ridge',
				    font=private.font);
    private.controlframe.shorthelp := 'Controls execution';


    if(private.writetoscripter) {
      include 'scripter.g';
      private.scripter :=
	  scripter(guititle=spaste(title, ' scripter gui (AIPS++)'),
				   widgetset=widgetset);
      if(is_record(private.scripter)&&has_field(private.scripter, 'gui'))
      {
	private.scripter.gui();
      }
    }
    else {
      private.scripter := F;
    }

    widgetset.tk_release();

    self.disable := function() {
        wider private;
        private.wholeframe->disable();
        private.wholeframe->cursor('watch');
    }

    self.enable := function() {
        wider private;
        private.wholeframe->enable();
        private.wholeframe->cursor('left_ptr');
    }

    self.laststep := function() {
      wider private;
      private.cancelbutton->disabled(T);
      private.nextbutton->text('Finish');
    }

    self.writestep := function(...) {
        wider private;
	widgetset.tk_hold();
        private.step->delete('start', 'end');
        private.step->insert(spaste(...), 'start');
	widgetset.tk_release();
    }

    self.writecode := function(...) {
        wider private;
	if(private.writetoscripter) {
          command := spaste(...);
	  if(is_record(private.scripter)&&has_field(private.scripter, 'gui'))
	  {
	    private.scripter.log(command);
	  }
	}
      }

    self.writeerror := function(...) {
        wider private;
	widgetset.tk_hold();
        private.error->delete('start', 'end');
        private.error->insert(spaste(...), 'start');
	widgetset.tk_release();
    }

    self.writeinfo := function(...) {
        wider private;
	widgetset.tk_hold();
        private.workinfo->delete('start', 'end');
        private.workinfo->insert(spaste(...), 'start');
	widgetset.tk_release();
    }

    self.workframe := function(new=F, side='top') {
        wider private;
        if (new || !has_field(private, 'workframe') || 
            !is_agent(private.workframe)) {
	  widgetset.tk_hold();
          if(is_agent(private.workframe)) private.workframe->unmap();
	  private.workframe := F;
	  private.workframe := widgetset.frame(private.wholeworkframe,
					       side=side);
	  widgetset.tk_release();
        }
        return ref private.workframe;
    }

    self.getparameters := function(title, explanation, ui) {
      wider self;
      
      widgetset.tk_hold();

      self.writestep(title);
      
      self.writeinfo(explanation);

      wholeworkframe := self.workframe(new=T, side='top');
      
      ag := autogui(ui, toplevel=wholeworkframe,
		    autoapply=F,
		    actionlabel='Apply',
		    widgetset=widgetset);

      if(is_fail(ag)) fail;
      if(!is_agent(ag)) fail 'Could not create autogui';
      widgetset.tk_release();
      
      if (!self.waitfornext()) {
	return F;
      }
      
      data := ag.get();
      ag.done();
      wholeworkframe := F;

      return data;
    }

    self.message := function(message) {
      wider private;
      if(has_field(private, 'messageline')) private.messageline->postnoforward(message);
      return T;
    }
    
    # If F, the user has pushed cancel and we don't want to do anything else.
    self.waitfornext := function() {
      wider private;
      self.enable();
      if(private.stopnow) {
	return F;
      }
      await private.nextbutton->press, private.cancelbutton->press,
        private.filemenu['exit']->press;
      if (($name == 'killed')||
	  (has_field($agent, 'text')&&
	   ($agent.text != 'next'))) {
	return F;
      }
      self.disable();
      return T;
    }
    
    self.done := function() {
      wider private;
      if(is_record(private)) {
	if(is_record(private.scripter)&&has_field(private.scripter, 'save'))
	{
	  private.scripter.save();
          private.scripter.done();
	}
        deactivate private.whenevers;
	private.wholeframe->unmap();
	private.wholeframe := F;
	private.wholeworkframe := F;
	val self := F;
	val private := F;
      }
    }

    result := widgetset.addpopuphelp(private, 5);

    result := self.disable();
}

