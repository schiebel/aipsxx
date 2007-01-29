# e2epipeline: e2e pipeline for processing projects end to end
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
#   $Id: e2epipeline.g,v 19.0 2003/07/16 03:44:47 aips2adm Exp $
#

pragma include once;

e2epipeline := function(e2edir=F) {

  include 'unset.g';

  public := [=];
  private := [=];
  
  if(is_boolean(e2edir)) {
    if(is_string(environ.E2EROOT)) {
      private.e2edir := spaste(environ.E2EROOT, '/');
    }
    else {
      private.e2edir := './'
    }
  }
  else {
    private.e2edir := e2edir;
  }

  include 'e2epipelinequery.g';
  private.e2epq := e2epipelinequery();
#
# Look up project details to determine a suitable makefile
#
  public.makefile := function(project) {
    wider private, public;
    context := private.e2epq.getcontext(project);
    if(any(context=="continuum")) {
      return which_include('continuum.gm');
    }
    else if(any(context=="spectralline")) {
      return which_include('spectralline.gm');
    }
    else {
      return which_include('continuum.gm');
    }
  }
#
# Process a project
#
  public.project := function(project, telescope=unset, tbeg=unset, tend=unset, execute=T, target='all') {
    wider private, public;
#
# Define the script
#
    script     := spaste(private.e2edir, '/archive/results/projects/', project, '/', project, '.g');
    initscript := spaste(private.e2edir, '/archive/results/projects/', project, '/', project, '_init.g');
    makescript := spaste(private.e2edir, '/archive/results/projects/', project, '/', project, '_make.g');
    archive    := spaste(private.e2edir, '/archive/results/projects/', project) ~ s!//!/!g;
#
# Ensure that the directory exists
#
    shell('mkdir -p ', spaste(private.e2edir, '/archive/results/projects/', project));
#
    f:=open(spaste('> ', initscript));
    include 'sysinfo.g';
    sys := F;
    sysinfo().version(formatted=sys);
    fprintf(f, '%s\n', spaste('# Script automatically generated. AIPS++ version ', sys));
    fprintf(f, '%s\n', '# Project specific global definitions');
    fprintf(f, '%s\n', 'include \'unset.g\';');
    fprintf(f, '%s\n', 'include \'note.g\';');
    fprintf(f, '%s\n', spaste('archive := ', as_evalstr(archive)));
#
    include 'e2epipelinequery.g'
    mypq := e2epipelinequery();
    if(is_fail(mypq)) fail;
    archfiles := mypq.getarchfiles(project, telescope, tbeg, tend);
    if(is_fail(archfiles)) fail;

    msname := spaste(project, '.ms');

    fprintf(f, '%s\n', spaste('archfiles := ', as_evalstr(archfiles)));
    fprintf(f, '%s\n', spaste('tbeg      := ', as_evalstr(tbeg)));
    fprintf(f, '%s\n', spaste('tend      := ', as_evalstr(tend)));
    fprintf(f, '%s\n', spaste('msname    := ', as_evalstr(msname)));
    fprintf(f, '%s\n', spaste('calonly   := F;'));
    fprintf(f, '%s\n', spaste('pname     := ', as_evalstr(project)));
    fprintf(f, '%s\n', spaste('ptype     := \'project\';'));
    fprintf(f, '%s\n', spaste('project   := ', as_evalstr(project)));
    fprintf(f, '%s\n', 'note(\'Defined project specific global variables\')');
    fprintf(f, '%s\n', '# End of project specific global definitions');

    f := F;
#
# Find the name of the makefile to use
#
    makefile := public.makefile(project);
    note('Using makefile ', makefile);
#
# Now launch the make
#
    include 'make.g';
    result := make(target, makefile=makefile, script=makescript);
    if(result) {
      shell(spaste('cat ', initscript, ' ', makescript, ' > ', script));
      include 'catalog.g';
      dc.delete(initscript, confirm=F);
      dc.delete(makescript, confirm=F);
      note('Written pipeline script ', script);
      if(execute) {
	note('Executing pipeline script ', script);
	include script;
      }
      return T;
    }
    else {
      return result;
    }
  }
#
# Process calibrators
#
  public.tape := function(tape, telescope, tbeg=unset, tend=unset, execute=T, target='all') {
    wider private, public;
#
# Define the script
#
    private.root := spaste(private.e2edir, '/archive/results/telescopes/', telescope, '/tapes/', tape) ~ s!//!/!g;
    private.scriptroot := '.';
    script     := spaste(private.scriptroot, '/', tape, '.g');
    initscript := spaste(private.scriptroot, '/', tape, '_init.g');
    makescript := spaste(private.scriptroot, '/', tape, '_make.g');
    archive    := spaste(private.root) ~ s!//!/!g;
#
# Ensure that the directory exists
#
    shell('mkdir -p ', private.root);
#
    f:=open(spaste('> ', initscript));
    include 'sysinfo.g';
    sys := F;
    sysinfo().version(formatted=sys);
    fprintf(f, '%s\n', spaste('# Script automatically generated. AIPS++ version ', sys));
    fprintf(f, '%s\n', '# Tape specific global definitions');
    fprintf(f, '%s\n', 'include \'unset.g\';');
    fprintf(f, '%s\n', 'include \'note.g\';');
    fprintf(f, '%s\n', spaste('tape := ', as_evalstr(tape)));
    fprintf(f, '%s\n', spaste('archive := ', as_evalstr(archive)));
    fprintf(f, '%s\n', spaste('pname   := ', as_evalstr(tape)));
    fprintf(f, '%s\n', 'project := unset');
#
# Work directly from the directory
#
    private.dir := spaste(private.e2edir, '/archive/data/', telescope, '/tapes/', tape) ~ s!//!/!g;
    include 'catalog.g';
    files := dc.list(private.dir);
    tags := as_string(sort(as_float(files ~ s/file_//g)));
    files := tags ~ s/^/file_/g;
    if(files=='') {
      return throw('No archive files found in ', private.dir);
    }
    archfiles := files;
    for (i in 1:len(archfiles)) {
      archfiles[i] := spaste(private.dir, '/', files[i]) ~ s!//!/!g;
    }
    
    msname := spaste(tape, '.ms');

    fprintf(f, '%s\n', spaste('archfiles := ', as_evalstr(archfiles)));
    fprintf(f, '%s\n', spaste('tbeg      := ', as_evalstr(tbeg)));
    fprintf(f, '%s\n', spaste('tend      := ', as_evalstr(tend)));
    fprintf(f, '%s\n', spaste('msname    := ', as_evalstr(msname)));
    fprintf(f, '%s\n', spaste('calonly   := T;'));
    fprintf(f, '%s\n', spaste('ptype     := \'tape\';'));
    fprintf(f, '%s\n', 'note(\'Defined tape specific global variables\')');
    fprintf(f, '%s\n', '# End of tape specific global definitions');

    f := F;
#
# Find the name of the makefile to use
#
    makefile := 'continuum.gm';
    note('Using makefile ', makefile);
#
# Now launch the make
#
    include 'make.g';
    result := make(target, makefile=makefile, script=makescript);
    if(result) {
      shell(spaste('cat ', initscript, ' ', makescript, ' > ', script));
      dc.delete(initscript, confirm=F);
      dc.delete(makescript, confirm=F);
      note('Written pipeline script ', script);
      if(execute) {
	note('Executing pipeline script ', script);
	include script;
      }
      return T;
    }
    else {
      return result;
    }
  }

  public.type := function() {
    return "e2epipeline";
  }

  public.done := function() {
    wider private, public;
    private.e2epq.done();
  }
  return ref public;
}
