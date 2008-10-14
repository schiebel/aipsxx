# dishdemodata.g: Functions to initialize the dish demo data
#------------------------------------------------------------------------------
#   Copyright (C) 1997-1998,1999,2000,2002
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
#    $Id: dishdemodata.g,v 19.1 2004/08/25 01:09:39 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include "os.g";
include "note.g";
include "sysinfo.g";
include "misc.g";

# This first makes sure that the demo data exists in 
# the users directory (fits2table is used to make it if not present
# from the master copy in the installation)
# datapath is a colon separated list of directories in which to look
# for demoFITS
const dishdemoinit := function(demofits, demotable, datapath) {
    # look for the demo data in the current directory
    tabTime := -1.0;
    if (dos.fileexists(demotable)) tabTime := dos.filetime(demotable);

    fitsTime := -1.0;
    fitsfile := F;
    for (path in split(datapath,':')) {
	fitsfile := spaste(path,'/',demofits);
	if (dos.fileexists(fitsfile)) {
	    fitsTime := dos.filetime(fitsfile);
	    break;
	}
    }
    if (fitsTime <= 0) {
	note(paste('The required FITS file was not found :',demofits),
	     priority='SEVERE',
	     origin='dishdemodata');
	return F;
    }
    
    if (tabTime >= fitsTime) {
	note(paste('The demo table', demotable,
		   'already exists and is up to date'),
	     origin='dishdemodata');
    } else {
	if (tabTime > 0) {
	    okToDelete := F;
	    q := spaste('The demo table, ',demotable,', already exists but appears to be out of date.');
	    note(q,origin='dishdemodata',priority='WARN');
	    if (have_gui()) {
		note('Asking user if it is okay to delete apparently obsolete data table.',
		     priority='WARN',origin='dishdemodata');
		ans := choice(paste(q, '\nIs it okay to delete this file and make a new one?'),
			      "No Yes");
		okToDelete := ans == 'Yes';
	    } else {
		note(paste(q,'No GUI is available and the user can not be asked if it is okay to delete this data table.'),
		     priority='WARN',origin='dishdemodata');
		note('If you want to re-created this demo data table, please remove the existing file and re-enter this command',
		     priority='WARN',origin='dishdemodata');
	    }
	    if (okToDelete) { 
		dos.remove(demotable);
		if (dos.fileexists(demotable)) {
		    note(paste('Unable to remove existing demo table.'),
			 priority='SEVERE', origin='dishdemodata');
		    return F;;
		}
	    } else {
		note('User has choosen not to remove the existing data table.',
		     priority='WARN',origin='dishdemodata');
		return F;
	    }
	}
	# one final check, don't say anything if it still exists as thats already been covered
	if (!dos.fileexists(demotable)) {
	    note(paste('Creating demo table :',demotable), origin='dishdemodata');
	    note(paste('FITS file found :',fitsfile),
		 origin='dishdemodata');
	    note(spaste('Begin converting it to an aips++ table ...'),
		 origin='dishdemodata');
	    cmd := shell(spaste('fits2table input=',fitsfile,
				' output=',demotable));
	    if (!dms.fileexists(demotable)) {
		note('Unable to make the demo data table',
		     priority='SEVERE',origin='dishdemodata');
		note(cmd,priority='SEVERE',origin='dishdemodata');
		return F;
	    } 
	    note(paste('Demo table created :',demotable),origin='dishdemodata');
	}
    }
    return T;
}

const dishdemodata := function(mypath='.',myoutdir='.') {
    note('dishdemodata starts',origin='dishdemodata');
    aipsroot := sysinfo().root();
    searchpath := spaste(mypath,':',aipsroot,'/data/demo/dishdemo');
    names := "dishdemo1 dishdemo2 dishmopra dishparkes dishspecproc";
    oknames := as_string([]);
    badnames := as_string([]);
    for (name in names) {
	if (dishdemoinit(spaste(name,'.fits'),spaste(myoutdir,'/',name),searchpath)) {
	    oknames[len(oknames)+1] := name;
	} else {
	    badnames[len(badnames)+1] := name;
	}
    }
    if (len(oknames)>0) {
	note(spaste('The single dish demo tables are: ', oknames), origin='dishdemodata');
    }
    if (len(badnames)>0) {
	note(spaste('There were problems constructing these single dish demo tables : ', badnames),
		    origin='dishdemodata', priority='WARN');
    }
    return T;
}
