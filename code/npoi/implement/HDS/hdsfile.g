# hdsfile.g:
# Copyright (C) 1998,1999,2000
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
# $Id: hdsfile.g,v 19.0 2003/07/16 06:02:52 aips2adm Exp $

pragma include once

const _define_hdsfile := function(ref agent, id) {
  private := [=];
  public := [=];
  private.agent := ref agent;
  private.id := id;

  private.lsRec := [_method = 'ls',
		    _sequence = private.id._sequence];
  public.ls := function() {
    wider private;
    return defaultservers.run(private.agent, private.lsRec);
  }

  private.cdRec := [_method = 'cd',
		    _sequence = private.id._sequence];
  public.cd := function(node=".") {
    wider private;
    private.cdRec.node := as_string(node);
    ok :=  defaultservers.run(private.agent, private.cdRec);
    return ok;
  }

  private.cdupRec := [_method = 'cdup',
		    _sequence = private.id._sequence];
  public.cdup := function() {
    wider private;
    return defaultservers.run(private.agent, private.cdupRec);
  }

  private.cdtopRec := [_method = 'cdtop',
		    _sequence = private.id._sequence];
  public.cdtop := function() {
    wider private;
    return defaultservers.run(private.agent, private.cdtopRec);
  }

  private.nameRec := [_method = 'name',
		      _sequence = private.id._sequence];
  public.name := function() {
    wider private;
    return defaultservers.run(private.agent, private.nameRec);
  }

  private.fullnameRec := [_method = 'fullname',
			  _sequence = private.id._sequence];
  public.fullname := function() {
    wider private;
    return defaultservers.run(private.agent, private.fullnameRec);
  }

  private.typeRec := [_method = 'type',
		      _sequence = private.id._sequence];
  public.type := function() {
    wider private;
    return defaultservers.run(private.agent, private.typeRec);
  }

  private.shapeRec := [_method = 'shape',
		       _sequence = private.id._sequence];
  public.shape := function() {
    wider private;
    return defaultservers.run(private.agent, private.shapeRec);
  }

  private.getRec := [_method = 'get',
		       _sequence = private.id._sequence];
  public.get := function() {
    wider private;
    return defaultservers.run(private.agent, private.getRec);
  }

  private.getstringRec := [_method = 'getstring',
			   _sequence = private.id._sequence];
  public.getstring := function() {
    wider private;
    return defaultservers.run(private.agent, private.getstringRec);
  }

  public.done  := function() {
    wider public, private;
    ok := defaultservers.done(private.agent, private.id.objectid);
    if (ok) {
      private := F;
      val public := F;
    }
    return ok;
  }

  public.structure := function () {
    ok := eval('include \'note.g\''); if (is_fail(ok)) fail;
    wider private, public;
    private.ilevel := 0;
    message := spaste('Structure below node: ', public.fullname(), '\n', 
			private.lsnode())
    note(message, priority='NORMAL');
  }

  const private.maxindent := sprintf('%50s', ''); # 50 blank spaces
  private.lsnode := function() { # Warning this function is recursive!
    wider public;
    wider private;
    retval := '';
    for (node in public.ls()) {
      public.cd(node);
      type := public.type();
      shape := public.shape();
      ndim := len(shape);
      line := '';
      if (ndim == 0) {
	format := spaste('%.', private.ilevel, 's%s <%s>\n');
	line := sprintf(format,  private.maxindent, node, type);
      } else {
	shapestring := paste(sprintf('%d', shape), sep=',');
	format := spaste('%.', private.ilevel, 's%s[%s] <%s>\n');
	line := sprintf(format,  private.maxindent, node, shapestring, type);
      }
      retval := spaste(retval, line);
      if (strlen(type) == 0 || split(type,'')[1] != '_') {
	private.ilevel +:= 2;
	if (ndim == 1) {
	  public.cdup();
	  public.cd(spaste(node,'(1)'));
	} else if (ndim == 2) {
	  public.cdup();
	  public.cd(spaste(node,'(1,1)'));
	} else if (ndim == 3) {
	  public.cdup();
	  public.cd(spaste(node,'(1,1,1)'));
	} else if (ndim == 4) {
	  public.cdup();
	  public.cd(spaste(node,'(1,1,1,1)'));
	}
	if (ndim < 5) {
	  retval := spaste(retval, private.lsnode());
	} else {
	  note(spaste('Cannot handle ', ndim, 
		      '-D structure nodes...Skipping node ', 
		      public.fullname()), priority='WARN');
	} 
	private.ilevel -:= 2;
      }
      public.cdup();
    }
    return retval;
  }
  return ref public;
}

const hdsfile := function(filename='', readonly=F,
			  host='', forcenewserver=F) {
  ok := eval('include \'servers.g\''); if (is_fail(ok)) fail;
  agent := defaultservers.activate('hds', host, forcenewserver);
  id := defaultservers.create(agent, 'hds',
                              'hdsfile', 
                              [filename=filename, readonly=readonly]);
  return ref _define_hdsfile(agent, id);
};
