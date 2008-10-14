# aipsrcedit.g: Allow editing of aipsrc variables
#
#   Copyright (C) 1998,1999,2000,2002
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
#   $Id: aipsrcedit.g,v 19.1 2004/08/25 01:33:23 cvsmgr Exp $
#

pragma include once;

include 'types.g';
include 'aipsrc.g';
include 'note.g';
include 'widgetserver.g';
include 'autogui.g'
include 'popupmenu.g'

pragma include once;

aipsrcedit := function(widgetset=dws) {
  
  private := [=];
  public  := [=];

  private.ui := [=];
  private.ui['system.packages'] :=
      [listname='system.packages',
       dlformat='system.packages',
       context='system',
       ptype='string',
       help='List of packages',
       default='general utility',
       allowunset=T,
       dir='inout'];
  private.ui['user.cache'] :=
      [listname='user.cache',
       dlformat='user.cache',
       context='user',
       ptype='string',
       help='Directory for storage of cache files',
       allowunset=T,
       default='$HOME/aips++/cache', dir='inout'];
  private.ui['user.initfiles'] :=
      [listname='user.initfiles',
       dlformat='user.initfiles',
       context='user',
       ptype='string',
       help='List of which .g files to load on startup for the user',
       allowunset=T,
       default=unset, dir='inout'];
  private.ui['aipsview.exe'] :=
      [listname='aipsview.exe',
       dlformat='aipsview.exe',
       context='aipsview',
       ptype='string',
       help='aipsview executable',
       default='aipsview',
       allowunset=T,
       dir='inout'];
  private.ui['aipsview.numcolors'] :=
      [listname='aipsview.numcolors',
       dlformat='aipsview.numcolors',
       context='aipsview',
       ptype='choice',
       help='available number of colours',
       default='BW',
       popt=['BW', 'ALL', '200'],
       allowunset=T,
       dir='inout'];
  private.ui['aipsview.background'] :=
      [listname='aipsview.background',
       dlformat='aipsview.background',
       context='aipsview',
       ptype='string',
       help='background colour',
       default='white',
       allowunset=T,
       dir='inout'];
  private.ui['aipsview.foreground'] :=
      [listname='aipsview.foreground',
       dlformat='aipsview.foreground',
       context='aipsview',
       ptype='string',
       help='foreground colour',
       default='black',
       allowunset=T,
       dir='inout'];
  private.ui['catalog.default'] :=
      [listname='catalog.default',
       dlformat='catalog.default',
       context='catalog',
       ptype='choice',
       help='output medium to use',
       default='gui',
       popt=['gui', 'screen'],
       allowunset=T,
       dir='inout'];
  private.ui['catalog.confirm'] :=
      [listname='catalog.confirm',
       dlformat='catalog.confirm',
       context='catalog',
       ptype='boolean',
       help='Confirm operations?',
       default=F,
       allowunset=T,
       dir='inout'];
  private.ui['catalog.view.Glish'] :=
      [listname='catalog.view.Glish',
       dlformat='catalog.view.Glish',
       context='catalog',
       ptype='string',
       help='Viewer for Glish files',
       allowunset=T,
       default=unset, dir='inout'];
  private.ui['catalog.view.PostScript'] :=
      [listname='catalog.view.PostScript',
       dlformat='catalog.view.PostScript',
       context='catalog',
       ptype='string',
       help='Viewer for PostScript files',
       default='ghostview',
       allowunset=T,
       dir='inout'];
  private.ui['catalog.view.ascii'] :=
      [listname='catalog.view.ascii',
       dlformat='catalog.view.ascii',
       context='catalog',
       ptype='string',
       help='Viewer for ascii files',
       allowunset=T,
       default=unset, dir='inout'];
  private.ui['toolmanager.default'] :=
      [listname='toolmanager.default',
       dlformat='toolmanager.default',
       context='toolmanager',
       ptype='choice',
       help='Output medium to use',
       default='gui',
       popt=['gui', 'cli'],
       allowunset=T,
       dir='inout'];
  private.ui['toolmanager.refresh'] :=
      [listname='toolmanager.refresh',
       dlformat='toolmanager.refresh',
       context='toolmanager',
       ptype='choice',
       help='Default refresh interval (s)',
       default='10s',
       popt=['No-refresh', '10s', '30s', '60s'],
       allowunset=T,
       dir='inout'];
  private.ui['logger.file'] :=
      [listname='logger.file',
       dlformat='logger.file',
       context='logger',
       ptype='string',
       help='Log file name',
       default='aips++.log',
       allowunset=T,
       dir='inout'];
  private.ui['logger.default'] :=
      [listname='logger.default',
       dlformat='logger.default',
       context='logger',
       ptype='choice',
       help='Where to write log messages',
       default='gui',
       popt=['gui', 'screen'],
       allowunset=T,
       dir='inout'];
  private.ui['logger.glish'] :=
      [listname='logger.glish',
       dlformat='logger.glish',
       context='logger',
       ptype='choice',
       help='What to log from glish',
       default='input',
       popt=['input', 'output', 'both', 'none'],
       allowunset=T,
       dir='inout'];
  private.ui['measures.default'] :=
      [listname='measures.default',
       dlformat='measures.default',
       context='measures',
       ptype='choice',
       help='specify user interface medium',
       default='screen',
       popt=['gui', 'screen'],
       allowunset=T,
       dir='inout'];
  private.ui['measures.precession.d_interval'] :=
      [listname='measures.precession.d_interval',
       dlformat='measures.precession.d_interval',
       context='measures',
       ptype='scalar',
       help='interval in days over which linear interpolation of precession calculation is appropiate',
       allowunset=T,
       default=0.1, dir='inout'];
  private.ui['measures.nutation.d_interval'] :=
      [listname='measures.nutation.d_interval',
       dlformat='measures.nutation.d_interval',
       context='measures',
       ptype='scalar',
       help='interval in days over which linear interpolation of nutation calculation is appropiate',
       allowunset=T,
       default=0.04, dir='inout'];
  private.ui['measures.nutation.b_useiers'] :=
      [listname='measures.nutation.b_useiers',
       dlformat='measures.nutation.b_useiers',
       context='measures',
       ptype='boolean',
       help='use the IERS Earth orientation parameters tables to calculate nutation',
       default=F,
       allowunset=T,
       dir='inout'];
  private.ui['measures.nutation.b_usejpl'] :=
      [listname='measures.nutation.b_usejpl',
       dlformat='measures.nutation.b_usejpl',
       context='measures',
       ptype='boolean',
       help='use the JPL DE database (use measures.jpl.ephemeris to specify which one) to calculate nutation',
       default=F,
       allowunset=T,
       dir='inout'];
  private.ui['measures.aberration.d_interval'] :=
      [listname='measures.aberration.d_interval',
       dlformat='measures.aberration.d_interval',
       context='measures',
       ptype='scalar',
       help='interval in days over which linear interpolation of aberration calculation is appropiate',
       allowunset=T,
       default=0.04, dir='inout'];
  private.ui['measures.aberration.b_usejpl'] :=
      [listname='measures.aberration.b_usejpl',
       dlformat='measures.aberration.b_usejpl',
       context='measures',
       ptype='boolean',
       help='use the JPL DE database (use measures.jpl.ephemeris to specify which one) to calculate aberration',
       default=F,
       allowunset=T,
       dir='inout'];
  private.ui['measures.solarpos.d_interval'] :=
      [listname='measures.solarpos.d_interval',
       dlformat='measures.solarpos.d_interval',
       context='measures',
       ptype='scalar',
       help='interval in days over which linear interpolation of solar position calculation is appropiate',
       allowunset=T,
       default=0.04, dir='inout'];
  private.ui['measures.solarpos.b_usejpl'] :=
      [listname='measures.solarpos.b_usejpl',
       dlformat='measures.solarpos.b_usejpl',
       context='measures',
       ptype='boolean',
       help='use the JPL DE database (use measures.jpl.ephemeris to specify which one) to calculate solar position',
       default=F,
       allowunset=T,
       dir='inout'];
  private.ui['measures.ierseop97.directory'] :=
      [listname='measures.ierseop97.directory',
       dlformat='measures.ierseop97.directory',
       context='measures',
       ptype='directory',
       help='directory for the IERSeop97 table',
       allowunset=T,
       default=unset, dir='inout'];
  private.ui['measures.ierspredict.directory'] :=
      [listname='measures.ierspredict.directory',
       dlformat='measures.ierspredict.directory',
       context='measures',
       ptype='directory',
       help='directory for the IERSpredict table',
       allowunset=T,
       default=unset, dir='inout'];
  private.ui['measures.tai_utc.directory'] :=
      [listname='measures.tai_utc.directory',
       dlformat='measures.tai_utc.directory',
       context='measures',
       ptype='directory',
       help='directory for the TAI_UTC leap second table',
       allowunset=T,
       default=unset, dir='inout'];
  private.ui['measures.measiers.b_notable'] :=
      [listname='measures.measiers.b_notable',
       dlformat='measures.measiers.b_notable',
       context='measures',
       ptype='boolean',
       help='do not use the IERSeop97 or IERSpredict tables',
       default=F,
       allowunset=T,
       dir='inout'];
  private.ui['measures.measiers.b_forcepredict'] :=
      [listname='measures.measiers.b_forcepredict',
       dlformat='measures.measiers.b_forcepredict',
       context='measures',
       ptype='boolean',
       help='use always the IERSpredict table',
       default=F,
       allowunset=T,
       dir='inout'];
  private.ui['measures.measiers.d_predicttime'] :=
      [listname='measures.measiers.d_predicttime',
       dlformat='measures.measiers.d_predicttime',
       context='measures',
       ptype='scalar',
       help='use always the IERSpredict table if coordinate conversion time is less than given number of days ago',
       allowunset=T,
       default=5, dir='inout'];
  private.ui['measures.jpl.ephemeris'] :=
      [listname='measures.jpl.ephemeris',
       dlformat='measures.jpl.ephemeris',
       context='measures',
       ptype='choice',
       help='specify JPL ephemeris',
       default='DE200',
       popt=['DE200', 'DE405'],
       allowunset=T,
       dir='inout'];
  private.ui['measures.DE200.directory'] :=
      [listname='measures.DE200.directory',
       dlformat='measures.DE200.directory',
       context='measures',
       ptype='directory',
       help='directory for the DE200 table',
       allowunset=T,
       default=unset, dir='inout'];
  private.ui['measures.DE405.directory'] :=
      [listname='measures.DE405.directory',
       dlformat='measures.DE405.directory',
       context='measures',
       ptype='directory',
       help='directory for the DE405 table',
       allowunset=T,
       default=unset, dir='inout'];
  private.ui['user.aipsdir'] :=
      [listname='user.aipsdir',
       dlformat='user.aipsdir',
       context='user',
       ptype='directory',
       help='default user\'s aips++ base directory',
       default='$HOME/aips++',
       allowunset=T,
       dir='inout'];
  private.ui['user.directories.work'] :=
      [listname='user.directories.work',
       dlformat='user.directories.work',
       context='user',
       ptype='string',
       help='list of directories to put scratch files',
       default='. /tmp',
       allowunset=T,
       dir='inout'];
  private.ui['user.dowait'] :=
      [listname='user.dowait',
       dlformat='user.dowait',
       context='user',
       ptype='boolean',
       help='Wait for asynchronous methods to finish?',
       default=F,
       allowunset=T,
       dir='inout'];
  private.ui['user.aipsrc.edit.keep'] :=
      [listname='user.aipsrc.edit.keep',
       dlformat='user.aipsrc.edit.keep',
       context='user',
       ptype='scalar',
       help='the number of edits of an aipsrc keyword that are kept as history when saving automatically to the users .aipsrc',
       allowunset=T,
       default=5, dir='inout'];
  private.ui['user.display.memory'] :=
      [listname='user.display.memory',
       dlformat='user.display.memory',
       context='user',
       ptype='boolean',
       help='display memory usage in a GUI barchart?',
       default=F,
       allowunset=T,
       dir='inout'];
  private.ui['system.resources.numcpu'] :=
      [listname='system.resources.numcpu',
       dlformat='system.resources.numcpu',
       context='system',
       ptype='scalar',
       help='number of cpu\'s on machine',
       allowunset=T,
       default=1, dir='inout'];
  private.ui['system.resources.memory'] :=
      [listname='system.resources.memory',
       dlformat='system.resources.memory',
       context='system',
       ptype='scalar',
       help='amount of memory on machine in Mb',
       allowunset=T,
       default=64, dir='inout'];
  private.ui['system.time.tzoffset'] :=
     [listname='system.time.tzoffset',
      dlformat='system.time.tzoffset',
      context='system',
      ptype='string',
      help='time zone offset',
      default='00:00',
      allowunset=T,
      dir='inout'];
  private.ui['printer.default'] :=
      [listname='printer.default',
       dlformat='printer.default',
       context='printer',
       ptype='string',
       help='Print queue',
       allowunset=T,
       default=unset, dir='inout'];
  private.ui['printer.paper'] :=
      [listname='printer.paper',
       dlformat='printer.paper',
       context='printer',
       ptype='choice',
       help='paper size on print queue',
       default='letter',
       popt=['A3', 'A4', 'letter'],
       allowunset=T,
       dir='inout'];
  private.ui['help.directory'] :=
      [listname='help.directory',
       dlformat='help.directory',
       context='help',
       ptype='directory',
       help='directory for the Refman help system',
       allowunset=T,
       default=unset, dir='inout'];
  private.ui['help.systemfile'] :=
      [listname='help.systemfile',
       dlformat='help.systemfile',
       context='help',
       ptype='directory',
       help='name of the Table directory with the help system',
       allowunset=T,
       default=unset, dir='inout'];
  private.ui['help.keywordfile'] :=
      [listname='help.keywordfile',
       dlformat='help.keywordfile',
       context='help',
       ptype='directory',
       help='name of the help system keyword Table',
       allowunset=T,
       default=unset, dir='inout'];
  private.ui['help.browser'] :=
      [listname='help.browser',
       dlformat='help.browser',
       context='help',
       ptype='string',
       help='browser to use for help display',
       default='netscape',
       allowunset=T,
       dir='inout'];
  private.ui['help.server'] :=
      [listname='help.server',
       dlformat='help.server',
       context='help',
       ptype='string',
       help='server to obtain help information from',
       default='file://localhost',
       allowunset=T,
       dir='inout'];

  private.values := [=];

  private.prefergui := unset;

#########################################################################
# Private functions
#
  private.save := function(data, filename='aipsrc') {

    note(paste('Saving aipsrc values to file:', filename));

    f:=open(paste('>', filename));
    for (i in field_names(data)) {
      if(!is_unset(data[i])) {
	s:=spaste(i,':	',data[i]);
	write(f, s);
      }
    }
    f:=F;
  }

# Can we and do we prefer to use a gui?
  private.usegui := function(prefergui=unset) {

    # First case: if we don't have it, don't use it!
    if(!have_gui()) return F;

    # Next, input overrides
    if(!is_unset(prefergui)) {
      # prefergui set, if it is true then we will use the gui
      # despite what the aipsrc file or the usegui says
      if(is_boolean(prefergui)) return prefergui;
    }
    else {
      # prefergui not set so we look at the aipsrc values
      found := drc.find(desired, 'aipsrcedit.default');
      #
      # Default is no gui
      #
      if (found&&desired=='gui') {
	prefergui := T;      
      }
      else {
	prefergui := F;
      }
    }
    
    # Next case, the use may have said to use the gui using 
    # the setgui function
    if(is_boolean(private.prefergui)) return private.prefergui;

    return prefergui;
  }
  
#########################################################################
# Public functions
#
  
  const public.gui := function(filename='aipsrc') {

    wider private;

    if(has_field(private, 'topframe')&&is_agent(private.topframe)) {
      private.topframe->map();
      return T;
    }

    # Fill in the values using either the default (for 'out' only)
    # or the value as last used
    for (arg in field_names(private.ui)) {
      found := drc.find(desired, arg);
      
      if(found) {
	private.ui[arg].value := desired;
      }
      else {
	private.ui[arg].value := private.ui[arg].default;
      }
    }

    widgetset.tk_hold();

    
    private.topframe := widgetset.frame(title='aipsrc Editor (AIPS++)',
					side='top');
      
    private.menubar := widgetset.frame(private.topframe,side='left',
				       relief='raised',
				       expand='x');

    private.filebutton := widgetset.button(private.menubar, 'File', relief='flat',
				    type='menu');
    private.filebutton.shorthelp := '';

    private.filemenu := [=];
    private.filemenu['save'] := widgetset.button(private.filebutton, 'Save');
    private.filemenu['dismiss'] := widgetset.button(private.filebutton,
						    'Dismiss window');
      
    private.rightmenubar := widgetset.frame(private.menubar,side='right');

    private.helpmenu := widgetset.helpmenu(private.rightmenubar,
					   ['aipsrcedit', 'About aipsrc'],
					   ['Refman:aipsrcedit', 'Refman:aipsrcdata']);
    
    note('Assembling GUI for aipsrcedit...');

    private.autogui := autogui(private.ui, title='aipsrcedit',
			       toplevel=private.topframe,
			       actionlabel='Save',
			       autoapply=F);

    if(is_fail(private.autogui)) fail;
    if(!is_agent(private.autogui)) fail "Could not create autogui";

    private.bottomrightframe := widgetset.frame(private.topframe, side='right',
					     expand='x');
    private.dismissframe := widgetset.frame(private.bottomrightframe, side='right');
    private.dismiss := widgetset.button(private.dismissframe, 'Dismiss',
				     type='dismiss');
    private.dismiss.shorthelp := 'Dismiss this GUI (but the tool keeps running)';
    widgetset.tk_release();

    whenever private.dismiss->press, private.filemenu['dismiss']->press,
      private.topframe->killed do {
      private.topframe->unmap();
    } 

    whenever private.autogui->select do {
      data := $value;
      private.save(data);
    }

# Save file
    whenever private.filemenu['save']->press do {
      data := private.autogui.get();
      private.save(data);
    }
    
    whenever private.filemenu['dismiss']->press do {
      private.topframe->unmap();
    }

  }

  const public.done := function() {
    wider private, public;
    private.topframe->unmap();
    private.topframe := F;
    val private := F;
    val public := F;
    return T;
  }

  const public.type := function() {
    return 'aipsrcedit';
  }

  const public.usegui := function(usegui=T) {
    wider private;
    private.prefergui := usegui;
    return T;
  }
  
  const public.usecli := function(usecli=T) {
    wider private;
    private.prefergui := !usecli;
    return T;
  }
  
  return ref public;
}

const defaultaipsrcedit := aipsrcedit();
const dae := const defaultaipsrcedit;



