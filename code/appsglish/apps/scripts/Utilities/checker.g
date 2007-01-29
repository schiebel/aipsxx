# checker.g: check the environment of AIPS++
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: checker.g,v 19.2 2004/08/25 02:07:35 cvsmgr Exp $
#

pragma include once

include 'note.g';

const checker := function() {

  private := [=];

  public.gui := function(verbose=T) {
    wider private;
    warnings := 0;
    if ( ! system.nogui && ! have_gui() ) {
      warnings +:= 1;
      note('Glish cannot display a GUI: no GUIs will be available', 
	   priority='WARN');
      note('Recommend checking value of environment variable DISPLAY',
	   priority='WARN');
      note('Also check if \'xhost +\' needs to be run', 
	   priority='WARN');
    }
    if(verbose&&(warnings==0)) {
      note('GUI suitable for use');
    }
    return warnings;
  }

  public.display := function(verbose=T) {

    wider private;
    warnings := 0;

    if ( have_gui() ) {
      if ( ! strlen(shell('xwininfo -root | grep TrueColor')) ) {
        warnings +:= 1;
        note('X server can now be run in TrueColor: display via aipsview or viewer will work correctly',
	     priority='WARN');
        note('Recommend restarting X server with TrueColor',
	     priority='WARN');
      }
      if ( verbose&&(warnings==0) ) {
        note('display suitable for use');
      }
    }
    return warnings;
  }
  
  public.plotter := function(verbose=T) {

    wider private;
    warnings := 0;
    if(0) {
      if(!(is_defined('pgplot')||!is_function(pgplot))) {
	warnings +:= 1;
	note('pgplot is not available: plotting will not work', priority='WARN');
      }
    }
    if( shell("pgpok")::status ) {
      warnings +:= 1;
      note('Neither pgplot environment variables PGPLOT_FONT, PGPLOT_DIR are not defined: labelling on plots will not be available', priority='WARN');
      note('Recommend setting PGPLOT_FONT to location of pgplot grfont.dat file',
	   priority='WARN');
    }
    if(verbose&&(warnings==0)) {
      note('plotting suitable for use');
    }
    return warnings;
  }
  
  public.memory := function(verbose=T) {
    wider private;
    include 'sysinfo.g';
    warnings := 0;
    if(sysinfo().memory()<63) {
      note('The physical memory on your system is too low for optimum performance of AIPS++',
	   priority='WARN');
      warnings +:= 1;
    }
    if(verbose&&(warnings==0)) {
      note('memory suitable for use');
    }
    return warnings;
  }

  public.perl := function(verbose=T) {
    warnings := 0;
    if(strlen(which_client('perl')) == 0){
      note('Perl is not in your path.  The AIPS++ help will not be available to you.',
           priority='WARN')
      warnings +:= 1;
    }
    if(verbose&&(warnings==0)) {
      note('perl available for use');
    }
    return warnings;
  }

  public.all := function(verbose=F) {
    wider public;
    warnings := public.gui(verbose) + public.display(verbose) +
	public.memory(verbose) + public.plotter(verbose) +
	    public.perl(verbose);
    if(warnings) {
      note('Environment is not optimum for AIPS++', priority='WARN');
    }
    else {
      note('Environment is suitable for AIPS++');
    }
    return warnings;
  }

  public.type := function() {
    return 'checker';
  }

  return public;
}

const defaultchecker := const checker();
const dch := const defaultchecker;
note('defaultchecker (dch) ready', priority='NORMAL', origin='checker.g');
