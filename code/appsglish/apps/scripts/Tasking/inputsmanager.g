# inputsmanager.g: Maintain a list of AIPS++ tools
#
#   Copyright (C) 1998,1999,2000,2001,2002
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
#   $Id: inputsmanager.g,v 19.2 2004/08/25 02:02:52 cvsmgr Exp $
#

pragma include once;

include 'note.g';

inputsmanager := function() {
  
  private := [=];
  public  := [=];
  
  private.values := [=];
  private.readonce := [=];

  include 'aipsrc.g';
  private.valuesfile := 'aips++.inputsv2.table';
  if (!drc.find(private.valuesfile, 'inputsmanager.file')) {
    private.valuesfile := 'aips++.inputsv2.table';
  }
#
# Maximum size for any one item stored in the inputs
#
  private.maxsize := 16384;
  if (!drc.find(private.maxsize, 'inputsmanager.maxsize')) {
    private.maxsize := 16384;
  }
  note ('Maximum size of any item saved to inputs table = ',
	private.maxsize, ' bytes', origin='inputsmanager')

#
#########################################################################

#########################################################################
# Public functions
#
  # Save the values for a tool type and method. A keyword may be
  # attached as well.
  const public.savevalues := function(type, method, values,
				      keyword='lastsave', dosave=F)
  {
    wider private;

    # Read and write at least once!
    if(!has_field(private.readonce, keyword)) {
      if(private.rcm.contains(keyword)) {
	result := private.rcm.getrecord(keyword);
	if(!is_fail(result)) {
	  private.values[keyword] := result;
	}
	else {
	  private.values[keyword] := [=];
	  private.rcm.saverecord(keyword, private.values[keyword], ack=F);
	}
      }
      else {
	private.values[keyword] := [=];
	private.rcm.saverecord(keyword, private.values[keyword], ack=F);
      }
      private.readonce[keyword] := T;
    }

    if(!has_field(private.values, keyword)) {
      private.values[keyword]:=[=];
    }
    if(!has_field(private.values[keyword], type)) {
      private.values[keyword][type] := [=];
    }
    if(!has_field(private.values[keyword][type], method)) {
      private.values[keyword][type][method] := [=];
    }

    # Now fill in the values
    values := private.rcm.torecord(values);

    for (arg in field_names(values)) {
      private.values[keyword][type][method][arg] := values[arg];
    }
    private.values[keyword][type][method]:: := values::;

    # Save in two places
    if(has_field(private.values, keyword)) {
      private.rcm.saverecord(keyword,  private.values[keyword],
			     dms.timetostring(time()), dosave, F);
      private.rcm.saverecord('lastsave', private.values[keyword], 
			     dms.timetostring(time()), dosave, F);
    }
    return T;
  }

  # Get the values for a tool type and method. A keyword may be
  # specified as well.
  const public.getvalues := function(type, method, keyword='lastsave')
  {
    wider private, public;

    if(!has_field(private.readonce, keyword)) {
      if(private.rcm.contains(keyword)) {
	result := private.rcm.getrecord(keyword);
	if(!is_fail(result)) {
	  private.values[keyword] := result;
	}
	else {
	  private.values[keyword] := [=];
	  private.rcm.saverecord(keyword, private.values[keyword], ack=F);
	}
      }
      else {
	private.values[keyword] := [=];
	private.rcm.saverecord(keyword, private.values[keyword], ack=F);
      }
      private.readonce[keyword] := T;
    }

    if(!has_field(private.values, keyword)) {
      private.values[keyword]:=[=];
    }
    if(!has_field(private.values[keyword], type)) {
      private.values[keyword][type] := [=];
    }
    if(!has_field(private.values[keyword][type], method)) {
      private.values[keyword][type][method] := [=];
    }

    return private.values[keyword][type][method];

  }

  # Save the internally stored inputs to the table
  const public.save := function(keyword='lastsave')
  {
    wider private;
    if(!has_field(private.values, keyword)) return F;
    return private.rcm.saverecord(keyword, private.values[keyword],
				  dms.timetostring(time()), T, T);
  }

  # Get the internally stored inputs from the table
  const public.get := function(keyword='lastsave') 
  {
    wider private;
    if(private.rcm.contains(keyword)) {
      result :=private.rcm.getrecord(keyword);
      if(!is_fail(result)) {
	private.values[keyword] := result;
      }
      else {
	private.values[keyword] := [=];
	private.rcm.saverecord(keyword, private.values[keyword], ack=F);
      }
    }
    else {
      private.values[keyword] := [=];
      private.rcm.saverecord(keyword, private.values[keyword], ack=F);
    }
    private.readonce[keyword] := T;
    return private.values[keyword];
  }

  const public.delete := function (rows) 
  {
    wider private;
    return private.rcm.delete(rows);
  }

  const public.deletetable := function() 
  {
    wider private;
    return private.rcm.deletetable();
  }

  const public.show := function() 
  {
    wider private;
    return private.rcm.show();
  }

  const public.list := function() 
  {
    wider private;
    return private.rcm.list();
  }

  const public.type := function() {
    return 'inputsmanager';
  }

  const public.done := function() {
    return public.save();
  }

  include 'recordmanager.g';
  private.rcm:=recordmanager(private.valuesfile, private.maxsize);
  private.rcm.save();

  return ref public;
}

# Make a singleton
const inputs := inputsmanager();

inputsmanagertest := function() {
  include 'selectmanager.g';
  global selection;
  selection := dsm.selection();
  inputs.savevalues('selection', 'record', selection);
  inputs.save();
  newselection := inputs.getvalues('selection', 'record');
  print "Original was     ", selection;
  print "Reconstructed is ", newselection;
}

