# setupwizard.g: setup AIPS++ aipsrc values
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: setupwizard.g,v 19.1 2004/08/25 01:35:11 cvsmgr Exp $
#

pragma include once

include 'note.g';
include 'aipsrc.g'
include 'os.g';
include 'wizard.g';

setupwizard := function(widgetset=dws)
{
    note('Starting setupwizard');

    private := [=];

    private.wizard := wizard('setupwizard', writetoscripter=F,
			     widgetset=widgetset);
    if(is_fail(private.wizard)) {
      return throw(paste('Failed to create wizard', private.wizard::message));
    }

    private.arc := drc;

    private.stopnow := F;

    private.data := [=];

    private.whenevers := [=];
    private.pushwhenever := function() {
      wider private;
      private.whenevers[len(private.whenevers) + 1] := last_whenever_executed();
    }

    private.getparameters := function(title, explanation, ui) {
      wider private;
      
      private.initvalues(ui);

      data := private.wizard.getparameters(title, explanation, ui);
      
      if(is_record(data)) {
	private.save(data);
	return T;
      }
      else {
        return data;
      }
    }

    private.save := function(data) {
      wider private; 
      for (i in field_names(data)) {
	if(!is_unset(data[i])) {
	  s:=spaste(i,':	',data[i]);
	  if(has_field(data[i], 'help')) {
	    private.data[i]:=paste(s,'#',data[i].help);
	  }
	  else {
	    private.data[i]:=s;
	  }
	}
      }
    }

    private.initvalues := function(ref data) {
      wider private;
      for (arg in field_names(data)) {
        if(has_field(data[arg], 'dlformat')) {
	  found := private.arc.find(desired, data[arg].dlformat);
	  
	  if(found) {
	    data[arg].value := desired;
	  }
	  else {
	    if(has_field(data[arg], 'default')) {
	      data[arg].value := data[arg].default;
	    }
	    else {
	      data[arg].value := unset;
	      data[arg].allowunset := T;
	    }
	  }
	}
      }
    }

    private.writevalues := function() {
      wider private;

      note('Writing updated .aipsrc file');

      filename := '~/.aipsrc';
      newfilename := '~/.aipsrc.new';
      bakfilename := '~/.aipsrc.bak';

      include 'os.g';
      filename := dos.fullname(filename);

      newfilename := dos.fullname(newfilename);
      bakfilename := dos.fullname(bakfilename);

      newf := open(spaste('> ', newfilename));
      if(is_fail(newf)){
	return throw('setupwizard.save: can\'t write to .aipsrc.new file');
      }

# These are the new/changed field names to write:
      lines := field_names(private.data);

# If .aipsrc already exists

      if (dos.fileexists(filename)) {

#   Back it up (must force overwrite in dos; user already 
#   had chance to abort):
        dos.copy(filename, bakfilename, overwrite=T);

#   Open it (can fail only if no read permission):
        f := open(spaste('< ', filename));
        if(is_fail(f)){
          return throw('setupwizard.save: can\'t read from .aipsrc file');
        }	

#   Write all fields from old file to new file, updating info where necessary:
        while(T) {
          line := read(f);
          if(strlen(line)==0) break;
          key := split(line, ':')[1];
          if(any(lines==key)) {
            line := spaste(private.data[key], '\n');
            private.data[key] := unset;
	  }
	  fprintf(newf, '%s', line);
        }
      }  # if (dos.fileexists(filename))

# Now write entirely new fields to the new file
      for (key in lines) {
        if(!is_unset(private.data[key])) {
	  line := spaste(private.data[key], '\n');
          private.data[key] := unset;
	  fprintf(newf, '%s', line);
	}
      }
      
      f := F;
      newf := F;

# Move new file to the file (must force overwrite)
      dos.move(newfilename, filename, overwrite=T);

      return T;
    }

    private.abortsetupwizard := function() {
      wider private;
      note('Setupwizard cancelled, changes to .aipsrc file aborted', origin='setupwizard');
      private.wizard.done();
      return F;
    }

    private.failsetupwizard := function(msg) {
	wider private;
	note('Internal error: ', msg, priority='SEVERE', origin='setupwizard');
	return private.abortsetupwizard();
    }

    private.font     := '-*-courier-medium-r-normal--12-*';
    private.boldfont := '-*-courier-bold-r-normal--12-*';
    
    ##### Step 1 - get name and address, etc.

    ui := [=];
    ui['Name'] := [listname='Name',
			   dlformat='userinfo.name',
			   ptype='string',
			   help='Name for email',
			   allowunset=T,
			   value=unset,
			   default=unset,
			   dir='in'];
    ui['Email address'] := [listname='Email address',
			   dlformat='userinfo.email',
			   ptype='string',
			   help='Email address',
			   allowunset=T,
			   value=unset,
			   default=unset,
			   dir='in'];
    ui['Organization name'] := [listname='Organization name',
			   dlformat='userinfo.org',
			   ptype='string',
			   help='Name of organization',
			   allowunset=T,
			   value=unset,
			   default=unset,
			   dir='in'];
    ui['AIPS++ center'] := [listname='AIPS++ center',
			    dlformat='system.aipscenter',
			    ptype='choice',
			    help='Location of nearest AIPS++ center',
			    popt="NorthAmerica Australia Europe",
			    value='NorthAmerica',
			    default='NorthAmerica',
			    dir='in'];

    result := private.getparameters('1. Personal information',
				    'First we need some personal information for bug reports, questions, etc.', ui);
    if(is_fail(result)) {
	private.failsetupwizard(result::message);
	return result;
    }
    if(is_boolean(result)&&!result) {
	private.abortsetupwizard();
	return F;
    }
    ##### Step 2 - user environment

    ui := [=];
    ui['Cache for various small files'] :=
	[listname='Cache for various small files',
	 dlformat='user.cache',
	 ptype='string',
	 help='Directory for locating cache of small files',
	 allowunset=T,
	 value=unset,
	 default='$HOME/aips++/cache',
	 dir='in'];
    ui['Working Directory'] :=
	[listname='Working directory',
	 dlformat='user.aipsdir',
	 ptype='string',
	 help='Directory location for working files',
	 allowunset=T,
	 value=unset,
	 default='.',
	 dir='in'];
    ui['Scratch directories'] :=
	[listname='Scratch directories',
	 dlformat='user.directories.work',
	 ptype='string',
	 help='List of directories to put scratch files',
	 allowunset=T,
	 value=unset,
	 default='.',
	 dir='in'];

    result := private.getparameters('2. User environment', 'Next we need some information on the location of various files, etc.', ui);
    if(is_fail(result)) {
	private.failsetupwizard(result::message);
	return result;
    }
    if(is_boolean(result)&&!result) {
	private.abortsetupwizard();
	return F;
    }

    ##### Step 3 - logger
    ui := [=];
    ui['Name of log file'] :=
	[listname='Name of log file',
	 dlformat='logger.file',
	 ptype='string',
	 help='Name of log file',
	 allowunset=T,
	 value=unset,
	 default='aips++.log',
	 dir='in'];
    ui['Number of lines in logger GUI'] :=
	[listname='Number of lines in logger GUI',
	 dlformat='logger.height',
	 ptype='string',
	 help='Number of lines in logger GUI',
	 allowunset=T,
	 value=unset,
	 default='8',
	 dir='in'];

    result :=
	private.getparameters('3. Logger',
			      'Now we need some information on the operation of the log.  The working directory specified on the previous page will be prepended to the log file name, unless it is an absolute path (begins with "/").  If non-trivial relative or absolute paths are used, the directory structure must already exist.',ui);

    if(is_fail(result)) {
	private.failsetupwizard(result::message);
	return result;
    }
    if(is_boolean(result)&&!result) {
	private.abortsetupwizard();
	return F;
    }

    ##### Step 4 - catalog
    ui := [=];

    ui['Use GUI for catalog?'] :=
	[listname='Use GUI for catalog?',
	 dlformat=['catalog.gui.auto'],
	 ptype='boolean',
	 help='Use a GUI for catalog displays?', 
	 default=T,
	 dir='inout'];
    ui['Confirm catalog operations'] :=
	[listname='Confirm catalog operations?',
	 dlformat='catalog.confirm',
	 ptype='boolean',
	 help='Confirm operations such as delete and rename?',
	 default=T,
	 dir='inout'];
    ui['Glish viewer'] := 
	[listname='Glish viewer',
	 dlformat='catalog.view.Glish',
	 ptype='string',
	 help='Viewer for Glish files',
	 allowunset=T,
	 default=unset, dir='inout'];
    ui['PostScript viewer'] :=
	[listname='PostScript viewer',
	 dlformat='catalog.view.PostScript',
	 ptype='string',
	 help='Viewer for PostScript files',
	 default='ghostview',
	 allowunset=T,
	 dir='inout'];
    ui['ASCII viewer'] :=
	[listname='ASCII viewer',
	 dlformat='catalog.view.ascii',
#	 context='catalog',
	 ptype='string',
	 help='Viewer for ascii files',
	 allowunset=T,
	 default=unset, dir='inout'];
    
    result := private.getparameters('4. Catalog information', 
				    'Now we need to know defaults for the catalog',
				    ui);

    if(is_fail(result)) {
	private.failsetupwizard(result::message);
	return result;
    }
    if(is_boolean(result)&&!result) {
	private.abortsetupwizard();
	return F;
    }

    ##### Step 5 - toolmanager ###


    ui := [=];
    ui['Tool manager display mode'] :=
	[listname='Tool manager display mode',
	 dlformat='toolmanager.gui.auto',
	 ptype='boolean',
	 help='Use GUI for toolmanager?',
	 default=T,
	 allowunset=T,
	 dir='inout'];
    ui['Tool manager refresh interval'] := 
	[listname='Tool manager refresh interval', 
	 dlformat='toolmanager.refresh',
	 ptype='choice',
	 help='Default refresh interval (s)',
	 default='10s',
	 popt=['No-refresh', '10s', '30s', '60s'],
	 allowunset=T,
	 dir='inout'];

    result := private.getparameters('5. Toolmanager information', 
				    'Now we need to know defaults for the toolmanager',
				    ui);

    if(is_fail(result)) {
	private.failsetupwizard(result::message);
	return result;
    }
    if(is_boolean(result)&&!result) {
	private.abortsetupwizard();
	return F;
    }

# Now finish up

    private.wizard.writestep('Finish. Write results to ~/.aipsrc file');

    private.wizard.writeinfo('Press "Next ->" and we will write the results to the .aipsrc in your ',
			     'home directory. You will need to restart AIPS++ for ',
                             'these changes to take effect.\n\n',
                             'If you wish to abort these changes to your .aipsrc file, ',
                             'please press "Cancel" now. ');

    if (!private.wizard.waitfornext()) {
	private.abortsetupwizard();
        return F;
    }
      
    private.writevalues();

    private.wizard.message('That\'s it!');
    note('Setupwizard finished');
    private.wizard.done();
    return T;
}


