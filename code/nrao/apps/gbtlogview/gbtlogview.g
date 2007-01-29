# gbtlogview.g:  a glishtk app to fill, browse & plot tables from gbt log files
#
#   Copyright (C) 1995,1996,1997,1999,2000,2002
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
#   $Id: gbtlogview.g,v 19.0 2003/07/16 03:42:25 aips2adm Exp $
#-----------------------------------------------------------------------------
include "gbtlogviewlog.g"
include "table.g"
include "newtb.g"
include "plotTableColumns.g"
include "widgetserver.g"
include "choice.g"
include "catalog.g"
include "smallbrowser.g"
include "quanta.g"
include "note.g"
#-----------------------------------------------------------------------------
include "gbtpg.g"
sdname:="";

# This whole thing needs to be turned into a closure or possibly a small set
# of closures.

#-----------------------------------------------------------------------------
# the Measures client is need for date as double to date as string conversion
include "measures.g";
toDate := function(dateInMJDDays)
{
    dateMeas := dq.unit(dateInMJDDays,"d");
    return dq.time(dateMeas,prec=6,form="day dmy");
}
global fillerPath := 'gbtlogfiller';
#-----------------------------------------------------------------------------
global devices;
devices := [=];
include "gbtlogdevices.g"
#-----------------------------------------------------------------------------
# read in functions which define buttons for special-purpose plotting, and
# provides the functions that will do the data extraction, manipulation and
# the actual plotting calls
include "gbtlogviewPlotSpecial.g"
#-----------------------------------------------------------------------------
setStartTime := function (startTime)
{
  global app;
  app.startTime := startTime;
}
#-----------------------------------------------------------------------------
setEndTime := function (endTime)
{
  global app;
  app.endTime := endTime;
}
#-----------------------------------------------------------------------------
getStartTime := function ()
{
  global app;
  return app.startTime;
}
#-----------------------------------------------------------------------------
getEndTime := function ()
{
  global app;
  return app.endTime;
}
#-----------------------------------------------------------------------------
setTableName := function (newTableName)
{
  global app;
  app.destinationTableName := newTableName;
  gui.updateOutputTableNameEntry();
}
#-----------------------------------------------------------------------------
getTableName := function ()
{
  global app;
  return app.destinationTableName;
}
#-----------------------------------------------------------------------------
inputDirectories := function ()
{
  global app;
  global __s:=[=]
  directories := array ('',1);
 
  count := 0;
  for (i in 1:len (app.inputDevices)) {
    if (app.inputDevices [i].selected) {
      count +:= 1;
      directories [count] := app.inputDevices [i].directory;
      }# if selected
    }# for i
   return directories;
}

inputdir := function ()
{
  global app,gui;
  global __s:=[=]
  directories := array ('',1);

  count := 0;
  for (i in 1:len (app.inputDevices)) {
    if (app.inputDevices [i].selected) {
      count +:= 1;
      directories [count] := app.inputDevices [i].directory;
      }# if selected
    }# for i
   if ((len(app.inputDevices) >= specifyDeviceIndex) && 
       app.inputDevices[specifyDeviceIndex].selected) {
	__s.adf := dws.frame(title='Specify device:');
        __s.adf.inc.lbl := dws.label(__s.adf,'Directory');
        __s.adf.inc.entry := dws.entry(__s.adf,width=25);
#	print 'sdname is ',sdname,len(sdname);
	__s.adf.inc.entry->insert(sdname);
        __s.adf.button := dws.button(__s.adf,'Go', type='action');
        __getdev();
        await __s.adf.button->press,__s.adf.inc.entry->return;
        val __s.adf := F;
   }
   if ((len(app.inputDevices) >= specifyAsciiIndex) && 
       app.inputDevices[specifyAsciiIndex].selected) {
       gui.startTimeEntry->delete ('start','end');
       gui.endTimeEntry->delete ('start','end');
       __s.aaf := dws.frame(title="ASCII table:");
       __s.aaf.inc.lbl := dws.label(__s.aaf,'Directory');
       __s.aaf.inc.entry := dws.entry(__s.aaf,width=25);
       __s.aaf.fl.lbl := dws.label(__s.aaf,'Filename');
       __s.aaf.fl.entry := dws.entry(__s.aaf,width=25);
       __s.aaf.inc.entry->insert('/GBTlogs/Receivers/');
       __s.aaf.button := dws.button(__s.aaf,'Go', type='action');
       __getasc();
       await __s.aaf.button->press,__s.aaf.inc.entry->return;
       val __s.aaf := F; 
  }
  return directories;
}
#-----------------------------------------------------------------------------
global __getdev:=function() {
	global app,__s;
	whenever __s.adf.button->press,__s.adf.inc.entry->return do {
		global sdname := __s.adf.inc.entry->get();
		app.inputDevices[specifyDeviceIndex].directory:=sdname;
	}
}
global __getasc:=function() {
	global app,__s,gui;
	whenever __s.aaf.button->press,__s.aaf.inc.entry->return do {
		app.inputDevices[specifyAsciiIndex].directory:=
		    __s.aaf.inc.entry->get();
		__s.name:=__s.aaf.fl.entry->get();
		global jname:=
		    spaste(app.inputDevices[specifyAsciiIndex].directory,__s.name);
		print jname;
	}
}
#
legitimateTable := function (tbl)
{
    return (is_table(tbl) && tbl.nrows() > 0);
}
#-----------------------------------------------------------------------------
initializeApp := function ()
{
  global app;
  global devices;

  app := [=];
  app.destinationTableName := 'logtable';
  app.startTime :=  'Nov 25 16:40:40 1995';
  app.endTime :=    'Nov 26 16:40:40 1995';
  app.inputDevices := devices;
  app.table := F;
  app.catalog := catalog();
  gui.validateButton->disabled (T);
  gui.browseButton->disabled (T);
  gui.plotColumnsButton->disabled (T);
  gui.plotSpecialButton->disabled (T);
}
#-----------------------------------------------------------------------------
createGUI := function ()
{
  global gui := [=];
  gui.standardButtonWidth := 15;

  gui.outerframe := dws.frame(side='top', title='GBT Log Data');
  gui.menuframe := dws.frame(gui.outerframe, side='left', relief='raise',
			     expand='x');
  gui.filemenu := dws.button(gui.menuframe, type='menu', text='File');
  gui.openbutton := dws.button(gui.filemenu, text='Open');
  gui.blankbutton := dws.button(gui.filemenu, text='', disabled=T);
  gui.exitbutton := dws.button(gui.filemenu, text='Exit', type='halt');

  gui.optionsmenu := dws.button(gui.menuframe, type='menu', text='Options');
  gui.smallBrowserButton := dws.button(gui.optionsmenu, type='radio', text='Small Browser');
  gui.tableBrowserButton := dws.button(gui.optionsmenu, type='radio', text='Table Browser');
  gui.smallBrowserButton->state(T);

  gui.helpframe := dws.frame(gui.menuframe, expand='x', side='right');
  gui.helpmenu := dws.helpmenu(gui.helpframe, 'gbtlogview', 
			       'Refman:gbt.gbt.logview',
			       helpitems='About gbtlogview');
  gui.outsideFrame := 
      dws.frame (gui.outerframe, side='left', title='GBT Log Data');
  
  gui.devicesFrame := 
      dws.frame (gui.outsideFrame, side='top');

  gui.devicesLabel := 
      dws.label (gui.devicesFrame, 'Data Source(s)');
  
  gui.devicesLBandSBFrame := 
      dws.frame (gui.devicesFrame, side='left');

  gui.devicesListBox := 
      dws.listbox (gui.devicesLBandSBFrame, width=19, height=5,
		   mode='multiple', exportselection=F);

  gui.devicesScrollbar := dws.scrollbar (gui.devicesLBandSBFrame);

  whenever gui.devicesListBox->yscroll do 
      gui.devicesScrollbar->view ($value);

  whenever gui.devicesScrollbar->scroll do
      gui.devicesListBox->view ($value)

  gui.dummyFrame :=
      dws.frame (gui.devicesFrame, height=30);

  gui.timeButtonsFrame := 
      dws.frame (gui.outsideFrame, side='top');


  gui.lastHourButton := 
      dws.button (gui.timeButtonsFrame,
		  text='Last Hour',
		  width=gui.standardButtonWidth);

  gui.lastDayButton := 
      dws.button (gui.timeButtonsFrame,
		  text='Last 24 Hours',
		  width=gui.standardButtonWidth);

  gui.lastWeekButton := 
      dws.button (gui.timeButtonsFrame,
		  text='Last 7 Days',
		  width=gui.standardButtonWidth);

  gui.showDateTemplateButton := 
      dws.button (gui.timeButtonsFrame,
		  text='Show Template',
		  width=gui.standardButtonWidth);

  gui.testDatesButton := 
      dws.button (gui.timeButtonsFrame,
		  text='Test Dates',
		  width=gui.standardButtonWidth);

  gui.timeFieldsFrame := 
      dws.frame (gui.outsideFrame, side='top');

  gui.startTimeFrame :=
      dws.frame (gui.timeFieldsFrame, side='left');
   
  gui.startTimeLabel :=
      dws.label (gui.startTimeFrame, '       Start Time');

  gui.startTimeEntry := 
      dws.entry (gui.startTimeFrame, width=30);

  gui.endTimeFrame :=
      dws.frame (gui.timeFieldsFrame, side='left');

  gui.endTimeLabel :=
      dws.label (gui.endTimeFrame, '         End Time');
  
  gui.endTimeEntry := 
      dws.entry (gui.endTimeFrame, width=30);

  gui.outputFileFrame :=
      dws.frame (gui.timeFieldsFrame, side='left');

  gui.outputLabel :=
      dws.label (gui.outputFileFrame, 'Output Table Name');

  gui.outputEntryFrame := 
      dws.frame(gui.outputFileFrame, side='top', borderwidth=0);
  gui.outputTableNameEntry := 
      dws.entry (gui.outputEntryFrame, width=30);
  # it needs a horizontal scroll bar to handle long names
  gui.outputEntryHSB := dws.scrollbar(gui.outputEntryFrame, orient='horizontal');
  whenever gui.outputEntryHSB->scroll do 
  { gui.outputTableNameEntry->view($value);}
  whenever gui.outputTableNameEntry->xscroll do 
  { gui.outputEntryHSB->view($value);}

  gui.buttonFrame := 
      dws.frame (gui.timeFieldsFrame, side='left');

  gui.spacer0 := 
      dws.frame (gui.buttonFrame, width=40);

  gui.validateButton :=
      dws.button (gui.buttonFrame,
		  text='Validate');
  
  gui.fillButton :=
      dws.button (gui.buttonFrame, text='Fill');

  gui.browseButton :=
      dws.button (gui.buttonFrame,
		  text='Browse');

  gui.plotButtonsFrame :=
      dws.frame (gui.buttonFrame);

  gui.plotColumnsButton :=
      dws.button (gui.plotButtonsFrame,
		  text='Plot Columns...',
		  width=gui.standardButtonWidth);

  gui.plotSpecialButton :=
      dws.button (gui.plotButtonsFrame,
		  text='Plot Special...',
		  width=gui.standardButtonWidth);
  
#  gui.quitButton :=
#      dws.button (gui.buttonFrame,
#		  text='Quit');

  # does the dl look like our dl
  if (is_defined('dl') && has_field(dl,'gui') &&
      is_function(dl.gui)) {
      gui.messages := dl.gui(gui.outerframe);
  }

  global devices;
  for (i in 1:len(devices)) 
      gui.devicesListBox->insert (devices [i].name);

  gui.opentable := function() {
      global app, gui;
      gui.browseButton->disabled (F);
      gui.plotColumnsButton->disabled (F);
      gui.plotSpecialButton->disabled (F);
      app.table := table(app.destinationTableName);
  }

  gui.updateOutputTableNameEntry := function() {
      gui.outputTableNameEntry->delete('start','end');
      gui.outputTableNameEntry->insert(app.destinationTableName);
  }

  junk := setupListBoxEventHandlers (gui.devicesListBox);
  junk := setupLastHourButtonAction (gui.lastHourButton);
  junk := setupLastDayButtonAction (gui.lastDayButton);
  junk := setupLastWeekButtonAction (gui.lastWeekButton);
  junk := setupDateTemplateButtonAction (gui.showDateTemplateButton);
  junk := setupTestDatesButtonAction (gui.testDatesButton);
  junk := setupValidateButtonAction (gui.validateButton);
  junk := setupFillButtonAction (gui.fillButton);
  junk := setupPlotColumnsButtonAction (gui.plotColumnsButton);
  junk := setupPlotSpecialButtonAction (gui.plotSpecialButton);
  junk := setupOutputTableNameEntry (gui.outputTableNameEntry);
  junk := setupStartTimeEntry (gui.startTimeEntry);
  junk := setupEndTimeEntry (gui.endTimeEntry);
  junk := setupBrowseButtonAction (gui.browseButton);
  junk := setupQuitButtonAction (gui.exitbutton);
  junk := setupOpenButtonAction (gui.openbutton);

}
#-----------------------------------------------------------------------------
setupListBoxEventHandlers := function (ref lb)
# first:  mark all of the inputDevices as 'not selected'.  
# second: ask the listbox widget for an array which describes which entries
#         have been selected by the user
# third:  if that array has one or more elements, then 
#            - get each string 
#            - mark any inputDevices which match the string as 'selected'
{
  global app;
  whenever lb->select do {
    for (i in 1:len (app.inputDevices)) app.inputDevices[i].selected := F
    indices := lb->selection ();
    if (len (indices) > 0) {
      for (i in 1:len (indices)) {
        deviceName := lb->get (indices [i]);
        for (j in 1:len (app.inputDevices)) {
          if (deviceName == app.inputDevices [j].name)
             app.inputDevices [j].selected := T;
          }# for j
        }# for i
      }# if 1 or more selections
   }# whenever
}
#-----------------------------------------------------------------------------
setupLastHourButtonAction := function (btn)
# find out the current time, and the current time minus one hour, and
# display each in the form
#
#   mm/dd/yyyy,hh:mm:ss
#
{

 whenever btn->press do {
     global result:=[=]
     onehour:=dq.unit(1,'h')
     prawstop:=dq.time(dq.unit('today'),form="ymd")
     prawstart:=dq.time(dq.sub(dq.unit('today'),onehour),form="ymd")
     pr2:=split(prawstop,"/")
     pr3:=split(prawstart,"/")
     result.pendTime:=paste(pr2[2],"/",pr2[3],"/",pr2[1],",",pr2[4],sep="") 
     result.pstartTime:=paste(pr3[2],"/",pr3[3],"/",pr3[1],",",pr3[4],sep="") 
     gui.startTimeEntry->delete ('start','end');
     gui.startTimeEntry->insert (result.pstartTime);
     gui.endTimeEntry->delete ('start','end');
     gui.endTimeEntry->insert (result.pendTime);
     setStartTime (result.pstartTime);
     setEndTime (result.pendTime);
   } # whenever

 return T;
}
#-----------------------------------------------------------------------------
setupLastDayButtonAction := function (btn)
# find out the current time, and the current time minus one day, and
# display each in the form
#
#   mm/dd/yyyy,hh:mm:ss
#
{

 whenever btn->press do {
     global result:=[=]
     oneday:=dq.unit(1,'d')
     prawstop:=dq.time(dq.unit('today'),form="ymd")
     prawstart:=dq.time(dq.sub(dq.unit('today'),oneday),form="ymd")
     pr2:=split(prawstop,"/")
     pr3:=split(prawstart,"/")
     result.pendTime:=paste(pr2[2],"/",pr2[3],"/",pr2[1],",",pr2[4],sep="")
     result.pstartTime:=paste(pr3[2],"/",pr3[3],"/",pr3[1],",",pr3[4],sep="")
     gui.startTimeEntry->delete ('start','end');
     gui.startTimeEntry->insert (result.pstartTime);
     gui.endTimeEntry->delete ('start','end');
     gui.endTimeEntry->insert (result.pendTime);
     setStartTime (result.pstartTime);
     setEndTime (result.pendTime);
   } # whenever


 return T;
}
#-----------------------------------------------------------------------------
setupLastWeekButtonAction := function (btn)
# find out the current time, and the current time minus one week, and
# display each in the form
#
#   mm/dd/yyyy,hh:mm:ss
#
{

 whenever btn->press do {
     global result:=[=]
     oneweek:=dq.unit(7,'d')
     prawstop:=dq.time(dq.unit('today'),form="ymd")
     prawstart:=dq.time(dq.sub(dq.unit('today'),oneweek),form="ymd")
     pr2:=split(prawstop,"/")
     pr3:=split(prawstart,"/")
     result.pendTime:=paste(pr2[2],"/",pr2[3],"/",pr2[1],",",pr2[4],sep="")
     result.pstartTime:=paste(pr3[2],"/",pr3[3],"/",pr3[1],",",pr3[4],sep="")
     gui.startTimeEntry->delete ('start','end');
     gui.startTimeEntry->insert (result.pstartTime);
     gui.endTimeEntry->delete ('start','end');
     gui.endTimeEntry->insert (result.pendTime);
     setStartTime (result.pstartTime);
     setEndTime (result.pendTime);
   } # whenever

 return T;
}
#-----------------------------------------------------------------------------
setupDateTemplateButtonAction := function (btn)
{
 global gui;
 template := 'MM/DD/YYYY,HH:MM:SS';

 whenever btn->press do {
   gui.startTimeEntry->delete ('start','end');
   gui.startTimeEntry->insert (template);
   gui.endTimeEntry->delete ('start','end');
   gui.endTimeEntry->insert (template);
   } # whenever

 return T;
}
#-----------------------------------------------------------------------------
setupTestDatesButtonAction := function (btn)
{
 global gui;
 #startDate := '04/10/1997,10:30:00';    # good for receiver data RC08_10
 #endDate   := '04/15/1997,12:00:00';    # and RC12_18
 startDate := '10/01/1997,18:05:00';    # good for weather data
 endDate   := '10/01/1997,22:05:00';

 whenever btn->press do {
   gui.startTimeEntry->delete ('start','end');
   gui.startTimeEntry->insert (startDate);
   gui.endTimeEntry->delete ('start','end');
   gui.endTimeEntry->insert (endDate);
   } # whenever

 return T;
}
#-----------------------------------------------------------------------------
createCommandFromGui := function ()
{
 setStartTimeFromGUI ();
 setEndTimeFromGUI ();
 setOutputTableNameFromGUI ();

 startTime := getStartTime ();
 fixedStartTime := standardizeDate (startTime);
 destinationTableName := getTableName ();
 #print 'startTime: ', startTime, ' ', fixedStartTime;

 sourceDirectories := inputdir ();

 endTime := getEndTime ();
 fixedEndTime := standardizeDate (endTime);
 fixedEndTime := standardizeDate (endTime);
 #print 'endTime: ', endTime, ' ', fixedEndTime;

 global fillerPath;
 fullCommand := spaste (fillerPath, ' ',
                        fixedStartTime, ' ', 
                        fixedEndTime, ' ',
                        destinationTableName, ' ',
                        inputDirectories ());
        
 return fullCommand;
}
#-----------------------------------------------------------------------------
setupFillButtonAction := function (btn)
{

    global gui, app, __s,jname;

    whenever btn->press do {
	#fullCommand := "ls -lap"; 
	fullCommand := createCommandFromGui ();
	gui.outputFrame := dws.frame (title='Filler Status');
	fs.lb := dws.frame(gui.outputFrame,side='left');
	fs.sb := dws.scrollbar(fs.lb);
	gui.outputTextWidget := 
	    dws.text (fs.lb, width=100,text=spaste(fullCommand,'\n'));
	whenever fs.sb->scroll do
	    gui.outputTextWidget->view($value);
	whenever gui.outputTextWidget->yscroll do
	    fs.sb->view($value);
	gui.outputFrameDismissButton :=
	    dws.button (gui.outputFrame,
			text='Dismiss', type='dismiss');
	whenever gui.outputFrameDismissButton->press do {
	    gui.outputFrame := F;
	}
	# print "about to execute: ", fullCommand;
	#gui.outputMessageWidget->text (fullCommand);
	# print "before await";
	#await gui.outputMessageWidget->*;
	# print "after await";
	#result := shell (fullCommand);
	#fullText := spaste (fullCommand, '\n');
	#for (i in 1:len (result))
	#   fullText := spaste (fullText, result [i], '\n');
	#gui.outputMessageWidget->text (fullText);

	if (has_field(app,'table') && is_record(app.table) &&
	    has_field(app.table,'close')) {
	    app.table.close();
	}
	app.table := F;
	if ((len(app.inputDevices) >= specifyAsciiIndex) && 
	    app.inputDevices[specifyAsciiIndex].selected) {
	    comstring:=split(fullCommand,' ');
	    asciitxt:=paste('......filling from ascii table',jname,'\n');
	    gui.outputTextWidget:=dws.text (fs.lb, width=100,text=asciitxt);
	    if (len(comstring)<=4) {
		fillerAgent :=tablefromascii(comstring[2],jname);
        	asciitxt:='....Done!\n'; # 
        	gui.outputTextWidget->append(asciitxt);}
	    else {
		fillerAgent := tablefromascii(comstring[4],jname);
		asciitxt:='....Done!\n';
		gui.outputTextWidget->append(asciitxt);}}
	else {
	    fillerAgent := shell (fullCommand, async=T);   
	}
	if (!(len(app.inputDevices) >= specifyAsciiIndex) || 
	    !app.inputDevices[specifyAsciiIndex].selected) {
	    whenever fillerAgent->stdout, fillerAgent->stderr do {
		childOutput := $value;
		gui.outputTextWidget->append (spaste(childOutput,'\n'));
		splitupText := split (childOutput);
	    }# whenever fillerAgent->stdout
	    whenever fillerAgent->done, fillerAgent->fail do {
		if ($name == 'fail') {
		    msg := 'the log filler failed unexpectedly, attempting to open logtable anyway';
		    note(msg,priority='SEVERE');
		    gui.outputTextWidget->append(spaste('WARNING:',msg));
		}
		junk := gui.opentable();
	    }# the fillerAgent has ended
	} # ends fillerAgent
	else {
	    junk := gui.opentable();
	}# if not device 17

	#todo: need to condition button enabling on completed, successful fill
	#gui.browseButton->disabled (F);
	#gui.plotColumnsButton->disabled (F);
	#gui.plotSpecialButton->disabled (F);
	# if (has_field(app,'table') && is_record(app.table) &&
	#   has_field(app.table,'close')) {
	#    app.table.close();
	# }
	#app.table := table (app.destinationTableName);
    }# whenever btn->press

    return T;
}
#-----------------------------------------------------------------------------
openActionCallback := function(file) {
    global app, gui;
    if (is_string(file)) {
	junk := setTableName(file);
	gui.opentable();
	# break the connection
	app.catalog.setselectcallback(0);
    } 
}
setupOpenButtonAction := function (btn)
{
    global app;
    whenever btn->press do {
	# make sure the catalog is visible, don't refresh here for speed
	app.catalog.gui(F);
	# and is displaying just Other Tables
	app.catalog.show(show_types='Other Table');
	# and set up the callback connections
	app.catalog.setselectcallback(openActionCallback);
    }
    return T;
}
#-----------------------------------------------------------------------------
setupBrowseButtonAction := function (btn)
{
    global app, gui;

    whenever btn->press do {
	if (gui.smallBrowserButton->state()) {
	    junk := gbtsmallbrowser(getTableName()).gui();
	} else {
	    junk := app.table.browse();
	}
    }

    return T;
}
#-----------------------------------------------------------------------------
setupPlotColumnsButtonAction := function (btn)
{

 global gui;

 whenever btn->press do {
   junk := runColumnPlottingDialogBox (app.table);
   }
}
#-----------------------------------------------------------------------------
setupPlotSpecialButtonAction := function (btn)
{
 global gui;

 whenever btn->press do {
   runSpecialPlottingDialogBox ();
   }
}
#-----------------------------------------------------------------------------
runSpecialPlottingDialogBox := function ()
{
  global gui;
  global app;

  gui.plotSpecialDialogBoxFrame := 
   dws.frame (title='Plot Special');

  gui.plotSpecialActionButtonFrame :=
    dws.frame (gui.plotSpecialDialogBoxFrame);

  addSpecialPlottingButtons (gui.plotSpecialActionButtonFrame);

  gui.plotSpecialDialogButtonsFrame := 
    dws.frame (gui.plotSpecialDialogBoxFrame,
	       side='left');

  gui.plotSpecialClearPlotButton := 
    dws.button (gui.plotSpecialDialogButtonsFrame,
            text='Clear');

  gui.plotSpecialDismissButton := 
    dws.button (gui.plotSpecialDialogButtonsFrame,
            text='Dismiss', type='dismiss');


  whenever gui.plotSpecialDismissButton->press do {
    gui.plotSpecialDialogBoxFrame := F;
    }

  whenever gui.plotSpecialClearPlotButton->press do {
    junk := pg.clear ();
    }

}# runSpecialPlottingDialogBox
#-----------------------------------------------------------------------------
setupQuitButtonAction := function (btn)
{

 whenever btn->press do {
     if (exitchoice()) {
	 exit;
     }
 }

 return T;
}
#-----------------------------------------------------------------------------
setupValidateButtonAction := function (btn)
{

 global gui;

 whenever btn->press do {
   checkValidityOfFillerArguments ();
   }

 return T;
}
#-----------------------------------------------------------------------------
checkValidityOfFillerArguments := function (gui)
# validity consists of
#  1. at least one data source selected
#  2. a legal start time
#  3. a legal end time
#  4. end time is later than start
#  5. a writable output table name
{
  numberOfDataSources := len (gui.devicesListBox->selection ());
  legalStartTime := validTimeString (getStartTime ());
  legalEndTime := validTimeString (getEndTime ());

}
#-----------------------------------------------------------------------------
setOutputTableNameFromGUI := function ()
{
  global gui;
  newTableName := gui.outputTableNameEntry->get ();
  setTableName (newTableName);
  
}
#-----------------------------------------------------------------------------
setupOutputTableNameEntry := function (tableNameEntryWidget)
{
    whenever tableNameEntryWidget->return do {
	setOutputTableNameFromGUI ();
	#newTableName := gui.outputTableNameEntry->get ();
	#setTableName (newTableName);
    }
}
#-----------------------------------------------------------------------------
setStartTimeFromGUI := function ()
{
  global gui;

  newStartTime := gui.startTimeEntry->get ();
  setStartTime (newStartTime);
}
#-----------------------------------------------------------------------------
setEndTimeFromGUI := function ()
{
  global gui;

  newEndTime := gui.endTimeEntry->get ();
  setEndTime (newEndTime);
}
#-----------------------------------------------------------------------------
setupStartTimeEntry := function (ref startTimeEntryWidget)
{
  global app;
  whenever startTimeEntryWidget->return do {
    setStartTimeFromGUI ();
    }
}
#-----------------------------------------------------------------------------
setupEndTimeEntry := function (ref endTimeEntryWidget)
{
  global app;
  whenever endTimeEntryWidget->return do {
    setStartTimeFromGUI ();
    }
}
#-----------------------------------------------------------------------------
createCommandDialogBox := function (msg)
{
  global gui;

  gui.commandFrame := 
    dws.frame (side='top', title='gbtlogfiller status');
  gui.commandDisplay := 
    dws.message (gui.commandFrame,
             width=600,
             text=msg);
  gui.cmdDismissButton := 
    dws.button (gui.commandFrame,
            text='Dismiss', type='dismiss');

  whenever gui.cmdDismissButton->press do {
    gui.commandFrame := F;
    }

}
#-----------------------------------------------------------------------------
standardizeDate := function (dateString)
# ask helper.pl to transform 
#       Sat Nov 25 12:17:07 1995     ->     11/25/1995,12:17:07
{
#  perlHelper->standardizeDate (dateString);
#  await perlHelper->standardizeDate;
#  fixedDateString := $value;
#  print "------------ in glish, standardizedDate: ", fixedDateString
  fixedDateString:=dateString
  return fixedDateString;

}
#-----------------------------------------------------------------------------
errorDialog := function (msg)
{
  global gui;

  f := dws.frame (title='Error!');
  messageWidget := 
     dws.message (f, text=msg);

  quitButton := dws.button (f, text='Dismiss', type='dismiss');

  whenever quitButton->press do {
     f := F;
     }

}
#-----------------------------------------------------------------------------
createGUI ();
initializeApp ();
setTableName('logtable');
#-----------------------------------------------------------------------------
#print 'The current table (once created by the \'Fill\' button) can be';
#print 'accessed as \'app.table\'.'
