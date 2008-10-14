# entryparser: Gui for input and output of parameters
# Copyright (C) 1996,1997,1998,1999,2000,2001
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
# $Id: entryparser.g,v 19.2 2004/08/25 02:02:37 cvsmgr Exp $


pragma include once
    
include 'unset.g';
include 'illegal.g';
    
# Entry parser is the central location for parsers of entries
# into the system
const entryparser := function() 
{
  
  public := [=];
  private := [=];

#########################################################################
#
# Type specific functions and data

  private.array := [=];
  private.array.nodisplay := '<array>';
  private.array.null := '[]';
  private.array.check := function (ref txt, isNumeric=T, embedQuotes=T)
#
# This function is for input from entry boxes which is expected to be 
# a symbol, or a vector (numeric or string). Symbols
# are not expanded.  This parser will fail if you
# put a function call like  myfun([10,10,20])
#
# Convert a string, expected to contain vector input,
# so that it looks like [x1,x2,x3] on output
# E.g. '10 20'      -> '[10,20]'
#      '[10,  20  ' -> '[10,20]'
#
  {
    if (embedQuotes && isNumeric) {
      msg := 'Cannot have both isNumeric and embedQuotes True';
      note(msg, priority='WARN', origin='entryparser.array.check');
      return F;
    }
#
# If it's a symbol it is assumed correct.  
#
    if (is_defined(txt)) return T;
#
# Now continue on, and parse the string to see if 
# it's numeric and format it if so. 
#
    txt2 := txt;
    txt2~:= s/^\s*//;              # remove leading blanks
    txt2~:= s/\s*$//;              # remove trailing blanks
    txt2~:= s/\[//g;               # remove leading "["
    txt2~:= s/\]//g;               # remove trailing "]"
    txt2~:= s/^\s*//;              # remove leading blanks
    txt2~:= s/\s*$//;              # remove trailing blanks
    txt2~:= s/,/ /g;               # replace commas by 1 space
    txt2~:= s/\s */ /g;            # replace white space by 1 space
    txt2~:= s/\n//g;               # replace newlines
#
    txt3 := split(txt2);           # split into vector
    if (isNumeric) {
      for (i in 1:length(txt3)) {
#
# This piece of regex wonder checks to see if the string houses
# a numeric value or not (handles exponential and floating
# point.  This is courtesy of Darrell.
	
	if ( !(txt3[i] ~ m/^([-+]?(?:(?:\d*\.?\d+)|(?:\d+\.?\d*))(?:[eE][-+]?\d+)?)$/)) {
	  return F;
	}
      }
    }
#                                    
    
    if (isNumeric) {
      txt4 := paste(txt3, sep=',');
    } else {
#
# We embed the quotes so that when we paste the final result into
# some command, it looks like  ..., absrel=['abs', 'relref', 'relcen']
#
      if (embedQuotes) {
	for (i in 1:length(txt3)) {              
	  txt3[i] := spaste('\'', txt3[i], '\'');
	}
	txt4 := paste(txt3, sep=',');
      } else {
	txt4 := paste(txt3, sep=',');
      }
    }
    val txt := spaste('[', txt4, ']');         # Add start/end vector brackets
    return T;
  }
  
  
  private.array.strip := function (ref txt) 
  {
    txt2 := txt;
    txt2~:= s/\[//g;               # remove leading "["
    txt2~:= s/\]//g;               # remove trailing "["
    txt2~:= s/,/ /g;               # replace commas by 1 space
    val txt := txt2;
    return T;
  }
  
  
  private.array.input_check := function (ref thing, const thingName, 
					  const canBeEmpty=F, const warn=F,
					 const isNumeric=T)
  {
    if (!is_string(thing)) {
      if(warn) {
	msg := spaste('Input for "', thingName, '" is not a string');
	note(msg, priority='WARN', origin='entryparser.array.input_check');
      }
      return F;
    }
    if (sum(strlen(thing))==0) {
      if (!canBeEmpty) {
	if(warn) {
	  msg := spaste('Input for "', thingName, '" is empty');
	  note(msg, priority='WARN', origin='entryparser.array.input_check');
	}
	return F;
      } else {
	val thing := '[]';         
	return T;
      }
    } else {
      embedQuotes := F;
      if (!private.array.check(thing, isNumeric, embedQuotes)) {
	if(warn) {
	  msg := spaste('Input for "', thingName,
			'" is either non-numeric or not a known symbol');
	  note(msg, priority='WARN', origin='entryparser.array.input_check');
	}
	return F;
      } 
    }
    return T;
  }
  
  private.array.display := function(actual) {
    
    if(length(actual)==0) {
      return private.array.null;
    }
    else if(length(actual)>100) {
      return private.array.nodisplay;
    }
    else {
      if(is_string(actual)) {
	return actual;
      }
      else {
	return as_evalstr(actual);
      }
    }
  }
    
  private.measure := [=];
  private.measure.nodisplay := '<measure>';

  private.measure.strip := function(ref rec) {
 
    if(is_string(rec)) {
      rec2 := rec;
      rec2 ~:= s/^\s*//;              # remove leading blanks
      rec2 ~:= s/\s*$//;              # remove trailing blanks
      rec2 ~:= s/\s */ /g;            # replace white space by 1 space
      rec2 ~:= s/\n//g;               # replace newlines
      val rec := rec2;
    }
  }

  private.quantity := [=];
  private.quantity.types:=[=];
  private.quantity.types['angle']:="arcsec marcsec arcmin deg rad \" '";
  private.quantity.types['time']:="s min h d a";
  private.quantity.types['flux']:="Jy uJy mJy kJy WU";
  private.quantity.types['unnormalizedfluxdensity']:="Jy/beam uJy/beam mJy/beam kJy/beam WU/beam";
# We put the types that we will get from quanta LAST so
# that the prior ones will default in the case of
# ambiguity
  private.quantity.types['vel'] :="";
  private.quantity.types['long']:="";
  private.quantity.types['lat']:="";
  private.quantity.types['len']:="";
  private.quantity.types['temp']:="K mK"
# Put freq last since it is overloaded
  private.quantity.types['freq']:="Hz kHz MHz GHz";
  
  include 'quanta.g';
  include 'serverexists.g';
  
  if (!serverexists('dq', 'quanta', dq)) {
    fail "The quanta server dq is not running";
  };

  quantalist := dq.getformat('lst');
  for (tp in field_names(private.quantity.types)) {
    if(has_field(quantalist, tp)) {
      stripped := quantalist[tp] ~s/\.\.\.//g;
      private.quantity.types[tp]:=paste(private.quantity.types[tp], stripped);
      private.quantity.types[tp]~:=s/\%//g;
      private.quantity.types[tp]~:=s/\_//g;
      private.quantity.types[tp]~:=s/^ //g;
      private.quantity.types[tp]~:=s/ &//g;
      private.quantity.types[tp]:=split(private.quantity.types[tp]);
    }
  }
  
  private.quantity.dimension := [=];
  for (tp in field_names(private.quantity.types)) {
    if (dq.check(private.quantity.types[tp][1])) {
      private.quantity.dimension[tp] :=
	  dq.quantity(private.quantity.types[tp][1]);
    } else {
      # Assume long or lat
      private.quantity.dimension[tp] := dq.quantity('0deg');
    };
  };
  
  private.record := [=];
  private.record.regex := m/^\[.*\]$/;
  private.record.nodisplay := '<record>';

  private.region := [=];
  private.region.nodisplay := '<region>';

  private.coordinates := [=];
  private.coordinates.nodisplay := '<coordinates>';

  private.model := [=];
  private.model.nodisplay := '<model>';

  private.modellist := [=];
  private.modellist.nodisplay := '<modellist>';

  private.selection := [=];
  private.selection.nodisplay := '<selection>';

  private.calibration := [=];
  private.calibration.nodisplay := '<calibration>';

  private.calibrationlist := [=];
  private.calibrationlist.nodisplay := '<calibrationlist>';

  private.solver := [=];
  private.solver.nodisplay := '<solver>';

  private.solverlist := [=];
  private.solverlist.nodisplay := '<solverlist>';

  private.freqsel := [=];
  private.freqsel.nodisplay := '<freqsel>';

  private.restoringbeam := [=];
  private.restoringbeam.nodisplay := '<restoringbeam>';

  private.deconvolution := [=];
  private.deconvolution.nodisplay := '<deconvolution>';

  private.imagingcoord := [=];
  private.imagingcoord.nodisplay := '<imagingcoord>';

  private.imagingfield := [=];
  private.imagingfield.nodisplay := '<imagingfield>';

  private.imagingfieldlist := [=];
  private.imagingfieldlist.nodisplay := '<imagingfieldlist>';

  private.imagingweight := [=];
  private.imagingweight.nodisplay := '<imagingweight>';

  private.mask := [=];
  private.mask.nodisplay := '<mask>';

  private.transform := [=];
  private.transform.nodisplay := '<transform>';


  private.scalar := [=];
  private.scalar.regex := m/^([-+]?(?:(?:\d*\.?\d+)|(?:\d+\.?\d*))(?:[eE][-+]?\d+)?)$/;
    
#########################################################################
#
# General private data

  private.strip := function(ref rec) {

    rec2 := rec 
    if(is_string(rec2)) {
      rec2~:= s/^\s*//;              # remove leading blanks
      rec2~:= s/\s*$//;              # remove trailing blanks
      rec2~:= s/\s */ /g;            # replace white space by 1 space
      rec2~:= s/\n//g;               # replace newlines
      val rec:=rec2;
    }
  }

  private.isunset := function(s, allowunset, ref actual, ref display) {
    if(is_unset(s)) {
      val actual := unset;
      val display := '';
      return T;
    }
    else {
      return F;
    }
  }

  # Protection against eval bugs
  private.checkevalable := function(s) {
    if((s ~ m/\(/g) != (s ~ m/\)/g)) return F;
    if((s ~ m/\</g) != (s ~ m/\>/g)) return F;
    if((s ~ m/\[/g) != (s ~ m/\]/g)) return F;
    if(s~m/\\/) return F;            # \ is bad news
    if((s ~ m/[ ]*exit[ ]*/)) {
      note('You cannot use the string \'exit\' in an entry', priority='SEVERE',
	   origin='entryparser.checkevalable');
      return F;
    }
    return T;
  }

  const private.genericitem := function (ref istype, type, rec, allowunset, 
                                         ref actual, ref display)
  {
    wider private;

    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin=spaste('entryparser.', type));
      }
    }

    val actual := rec;
    if(is_string(rec)) {
      private.strip(rec);
      if(rec=='') {
	val actual := illegal;
	val display := '';
	return throw('Item name cannot be empty');
      }
      val actual := rec;
      val display := rec;
    }
    else {
      val display := as_evalstr(rec);
    }
    return T;
  }
#########################################################################
#
# Start of public functions

#####
#
  const public.array := function(rec, allowunset, ref actual, ref display) {

    wider private;
    
    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.array');
      }
    }

    if(is_string(rec)) {
      if (rec==private.array.nodisplay) {
        val display:=private.array.display;
#
# This means someone hit <CR> again after pasting in
# from the clip-board, or perversely, typed in <array>
	return T;
      }
      if(sum(strlen(rec))==0) {
	val actual := illegal;
	val display := '';
        return F;
      }
      processed := rec;
      if(private.array.input_check(processed, 'value', T)) {
        if(private.checkevalable(processed)) {
	  val display := processed;
	  val actual  := eval(processed);
	  if(is_boolean(actual)) {
	    val actual := illegal;
	    val display := '';
	    return F;
	  }
	  else {
	    return T;
	  }
	}
      }
      if(private.checkevalable(rec)) {
	erec := eval(rec);
	if(is_numeric(erec)&&!is_boolean(erec)) {
	  val actual := erec;
	  val display := private.array.display(rec);
	  return T;
	}
      }
    }
    # Perhaps it's a variable e.g. xinc or 1.233
    else if(is_numeric(rec)&&!is_boolean(rec)) {
      val actual := rec;
      val display := private.array.display(rec);
      return T;
    }
    val actual := illegal;
    val display := '';
    return F;
  }

#####
#
  const public.booleanarray := function(rec, allowunset, ref actual,
					ref display) {

    wider private;
    
    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.booleanarray');
      }
    }

    if(is_string(rec)) {
      if (rec==private.array.nodisplay) {
        val display:=private.array.display;
#
# This means someone hit <CR> again after pasting in
# from the clip-board, or perversely, typed in <array>
	return T;
      }
      else if(sum(strlen(rec))==0) {
	val actual := illegal;
	val display := '';
        return F;
      }
      processed := to_upper(rec);
      if(private.array.input_check(processed, 'value', T, isNumeric=F)) {
        if(private.checkevalable(processed)) {
	  val display := processed;
	  val actual  := eval(processed);
	  return T;
	}
      }
      if(private.checkevalable(rec)) {
	erec := eval(rec);
	if(is_numeric(erec)&&!is_boolean(erec)) {
	  val actual := erec;
	  val display := private.array.display(rec);
	  return T;
	}
      }
    }
    # Perhaps it's a variable e.g. xinc or 1.233
    else if(is_numeric(rec)) {
      val actual := rec;
      val display := private.array.display(rec);
      return T;
    }
    val actual := illegal;
    val display := '';
    return F;
  }

#####
#
  const public.boolean := function(rec, allowunset, ref actual, ref display) {

    wider private;

    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.boolean');
      }
    }

    if(is_boolean(rec)) {
      if(rec) {
	val actual := T;
	val display := 'True';
      }
      else {
	val actual := F;
	val display := 'False';
      }
      return T;
    }
    else if(is_string(rec)) {            
      private.strip(rec);
      srec := to_lower(rec);
      if((srec=='true')||(srec=='t')) {
	val actual := T;
	val display := 'True';
	return T;
      }
      else if((srec=='false')||(srec=='f')) {
	val actual := F;
	val display := 'False';
	return T;
      }
      # Just convert to boolean and try again
      return public.boolean(as_boolean(rec), allowunset, actual, display);
    }
    val actual := illegal;
    val display := '';
    return F;
  }
    
#####
#
  const public.check :=  function(rec, allowunset, options, ref actual,
				  ref display) {
    wider private;

    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.check');
      }
    }

    if(is_string(rec)) {
      private.strip(rec);
      srec := to_lower(rec);
      pactual := [''];
      pdisplay := [''];
      j := 0;
      poptions := to_lower(options);
      for (i in 1:length(srec)) {
	if(any(poptions==srec[i])) {
	  j+:=1;
	  pactual[j] := rec[i];
	  pdisplay[j] := rec[i];
	}
      }
      if(j>0) {
        val actual := pactual;
        val display := pdisplay;
	return T;
      }
      # Try an eval: don't to_lower beforehand!
      if(is_defined(rec)) {
        if(private.checkevalable(rec)) {
	  erec := eval(rec);
	  if(is_string(erec)) {
	    private.strip(erec);
	    if(sum(strlen(erec))==0) {
	      val actual := illegal;
	      val display := '';
	      return F;
	    }
	    srec := to_lower(erec);
	    pactual := [''];
	    pdisplay := [''];
	    j := 0;
	    poptions := to_lower(options);
	    for (i in 1:length(srec)) {
	      if(any(poptions==srec[i])) {
		j+:=1;
		pactual[j] := erec[i];
		pdisplay[j] := erec[i];
	      }
	    }
	    if(j>0) {
	      val actual := pactual;
	      val display := pdisplay;
	      return T;
	    }
	  }
	}
      }
    }
    val actual := illegal;
    val display := '';
    return F;
  }
  
#####
#
  const public.choice := function(rec, allowunset, options, ref actual,
				  ref display) {
    wider private;

    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.choice');
      }
    }

   if(is_string(rec)) {
     private.strip(rec);
      srec := to_lower(rec);
      val actual := illegal;
      val display := '';
      if(length(srec)>1) return F;
      val actual := '';
      val display := '';
      poptions := to_lower(options);
      for (i in 1:length(srec)) {
	if(any(poptions==srec[i])) {
	  val actual := rec[i];
	  val display := rec[i];
          return T;
	}
      }
      # Try an eval
      if(is_defined(rec)) {
        if(private.checkevalable(rec)) {
	  erec := eval(rec);
	  if(is_string(erec)) {
	    private.strip(erec);
	    if(sum(strlen(erec))==0) {
	      val actual := illegal;
	      val display := '';
	      return F;
	    }
	    srec := to_lower(erec);
	    val actual := illegal;
	    val display := '';
	    if(length(srec)>1) return F;
	    val actual := '';
	    val display := '';
	    poptions := to_lower(options);
	    for (i in 1:length(srec)) {
	      if(any(poptions==srec[i])) {
		val actual := erec[i];
		val display := erec[i];
		return T;
	      }
	    }
	  }
	}
      }
    }
    val actual := illegal;
    val display := '';
    return F;
  }

#####
#
  const public.measure := function(rec, allowunset, ref actual, ref display,
				   ref type = unset) {

    wider private;
    
    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.measure');
      }
    }

    if(is_string(rec)) {
      if (rec==private.measure.nodisplay) {
#
# This means someone hit <CR> again after pasting in
# from the clip-board, or perversely, typed in 
# pasted_region.  So the current region value
# should be ok.
#
	if (is_measure(actual)) return T;
      }
      if(sum(strlen(rec))==0) {
	val actual := illegal;
	val display := '';
	return F;
      }
      else if(private.checkevalable(rec)) {
	erec:=eval(rec);
	if(is_measure(erec)) {
	  if(is_unset(type)||(erec.type==type)) {
	    val actual := erec;
	    if(is_unset(type)) type :=actual.type;
	    val display := rec[1];
	    return T;
	  }
	}
      }
    }
    else if(is_measure(rec)) {
      if(is_unset(type)||(rec.type==type)) {
	val actual := rec;
	if(is_unset(type)) type :=actual.type;
	val display := private.measure.nodisplay;
	return T;
      }
    }
    val actual := illegal;
    val display := '';
    return F;
  }
    
  public.quantity := [=];

  public.quantity.type := function(i) {
    return ref private.quantity.types[i];
  }

  public.quantity.types := function() {
    return field_names(private.quantity.types);
  }

  public.quantity.findtype := function(originalvalue,
				       defaultvalue,
				       ref type) {
    wider private;
    # Type is unknown
    if (is_unset(type)) {
      if (!is_unset(originalvalue) && dq.check(originalvalue)) {
        # original value is a quantity
	x := dq.quantity(originalvalue).unit;
	for (tp in field_names(private.quantity.types)) {
	  if (any(private.quantity.types[tp] == x)) {
	    val type := tp;
	    return T;
	  };
	};
      }
      else if (!is_unset(defaultvalue) && dq.check(defaultvalue)) {
        # original value is NOT a quantity
        # but default value is.
	x := dq.quantity(defaultvalue).unit;
	for (tp in field_names(private.quantity.types)) {
	  if (any(private.quantity.types[tp] == x)) {
	    val type := tp;
	    return T;
	  };
	};
      }
      else {
	val type := unset;
	return throw('Cannot find type since neither original nor default values are valid');
      }
    }
    else {
      # Type is known but is it valid?
      if (any(field_names(private.quantity.types)==type)) {
	return T;
      }
      else {
	val type := unset;
	return throw(paste('Type ', type, 'is not valid for this quantity'));
      }
    };
  }
  
#####
#
  const public.quantity.parse := function(rec, allowunset, ref actual,
					  ref display, ref type='angle',
					  ref unit=F) {
    
    wider private;

    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.quantity');
      }
    }

    if(!is_string(type)) {
      return throw('Type is not a string : ', type);
    }

    if (is_numeric(rec)) rec := as_string(rec);

    # Trap null string
    if(is_string(rec)&&sum(strlen(rec))==0 || is_function(rec)) {
      val actual := illegal;
      val display := '';
      return F;
    };

    local x;
    # Make sure we have a unit
    if (!is_string(unit)) val unit := private.quantity.types[type][1];
    if (dq.check(rec)) {
      x := dq.quantity(rec);
      if (!dq.compare(x, private.quantity.dimension[type])) {
	# Try with units
	x := dq.mul(x, dq.quantity(1, unit));
	if (!dq.compare(x, private.quantity.dimension[type])) {
	  val actual := illegal;
	  val display := '';
	  return F;
	};
      };
    } else {
      val actual := illegal;
      val display := '';
      return F;
    };
    # Select new unit if possible
    if (any(private.quantity.types[type] == x.unit)) val unit := x.unit;
    # Convert to proper units
    if(is_string(unit)) {
      if(x.unit!=unit) x := dq.convert(x, unit);
      if(is_quantity(x)) {
	val display := as_string(x.value);
	val actual := x;
	return T;
      }
    }
    val actual := illegal;
    val display := '';
    return F;
  }
    
#####
#
  const public.record := function(rec, allowunset, ref actual, ref display) 
  {
    
    wider private;

    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.record');
      }
    }

    if(is_record(rec)) {
      val actual := rec;
      for (field in field_names(rec)) {
	if(is_function(rec[field])) {
	  val display := '<record>';
	  return T;
	}
      }
      val display := as_evalstr(actual);
      return T;
    }
    # Usual case: it probably came from the entry box and
    # it's a simple string '1.2434' or 'xinc', say
    else if(is_string(rec)) {
      private.measure.strip(rec);
      if(sum(strlen(rec))==0) {
	val actual := illegal;
	val display := '';
	return F;
      }
      if (rec==private.record.nodisplay) {
        val display:=private.record.nodisplay;
#
# This means someone hit <CR> again after pasting in
# from the clip-board, or perversely, typed in <array>
	return T;
      }
      if(rec~private.record.regex) {
	# It's a number as a string e.g. '1.2434' so we can eval it
        if(private.checkevalable(rec)) {
	  val actual := eval(rec);
	  for (field in field_names(actual)) {
	    if(is_function(actual[field])) {
	      val display := '<record>';
	      return T;
	    }
	  }
	  val display := as_evalstr(actual);
	  return T;
	}
      }
      # Could be the name of a variable e.g. 'xinc'
      else {
	# Yes, it is so we can eval it at the cost of
	# provoking an undefined variable snark from glish
        if(private.checkevalable(rec)) {
	  erec:=eval(rec);
	  # Now check to see if it is an allowed type. If so then
	  # we will keep it
	  if(is_record(erec)) {
	    val actual := erec;
	    val display := rec;
	    return T;
	  }
	}
      }
      val actual := illegal;
      val display := '';
      return F;
    }
    
  }
  
#####
#
  const public.region := function (rec, allowunset, ref actual, ref display)
  {
    wider private;

    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.region');
      }
    }

    include 'regionmanager.g';
    if (is_region(rec)) {
#
# If I am given the value only, I don't know
# the name of the region.  It probably been pasted
# from the clipboard.
#
      val actual := rec;
      val display := private.region.nodisplay;
      return T;
    } else if (is_defined(as_string(rec))) {
      private.region.tmp := symbol_value(rec);
      if (is_region(private.region.tmp)) {
#
# Make named regions conform with other items (AK 2001-11)
#	val actual := private.region.tmp;
	val actual := rec;
	val display := as_string(rec);
	return T;
      }
    } else if (is_string(rec)) {
      private.strip(rec);
      if(sum(strlen(rec))==0) {
	val actual := illegal;
	val display := '';
	return F;
      }
      if (rec==private.region.nodisplay) {
#
# This means someone hit <CR> again after pasting in
# from the clip-board, or perversely, typed in 
# pasted_region.  So the current region value
# should be ok.
#
	if (is_region(actual)) return T;
      } else {
	global __regionentry_region;
	__regionentry_region := [=];
	cmd := spaste('__regionentry_region := ', rec);
        if(private.checkevalable(cmd)) {
	  eval(cmd);
	  if (!is_fail(__regionentry_region)) {
	    if (is_region(__regionentry_region)) {
	      val actual := __regionentry_region;
	      val display := as_string(rec);   
	      return T;
	    }
	  }
	}
      }
      val actual := illegal;
      val display := '';
      return F;
    }
    val actual := illegal;
    val display := '';
    return F;
  }
  
#####
#
  const public.coordinates := function (rec, allowunset, ref actual,
					ref display)
  {
    include 'coordsys.g'
    wider private;

    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.coordinates');
      }
    }

    if (is_coordsys(rec)) {
#
# If I am given the value only, I don't know
# the name of the coordinates.  It probably been pasted
# from the clipboard.
#
      val actual := rec;
      val display := private.coordinates.nodisplay;
      return T;
    } else if (is_defined(rec)) {
      private.coordinates.tmp := symbol_value(rec);
      if (is_coordsys(private.coordinates.tmp)) {
	val actual := private.coordinates.tmp;
	val display := as_string(rec);
	return T;
      }
    } else if (is_string(rec)) {
      private.strip(rec);
      if(sum(strlen(rec))==0) {
	val actual := illegal;
	val display := '';
	return F;
      }
      if (rec==private.coordinates.nodisplay) {
#
# This means someone hit <CR> again after pasting in
# from the clip-board, or perversely, typed in 
# pasted_coordinates.  So the current coordinates value
# should be ok.
#
	if (is_coordsys(actual)) return T;
      } else {
	global __coordinatesentry_coordinates;
	__coordinatesentry_coordinates := [=];
	cmd := spaste('__coordinatesentry_coordinates := ', rec);
        if(private.checkevalable(cmd)) {
	  eval(cmd);
	  if (!is_fail(__coordinatesentry_coordinates)) {
	    if (is_coordsys(__coordinatesentry_coordinates)) {
	      val actual := __coordinatesentry_coordinates;
	      val display := as_string(rec);   
	      return T;
	    }
	  }
	}
      }
      val actual := illegal;
      val display := '';
      return F;
    }
    val actual := illegal;
    val display := '';
    return F;
  }
  
#####
#
  const public.model := function (rec, allowunset, ref actual, ref display)
  {
    wider private;
   
    include 'modelmanager.g';

    return private.genericitem(is_model, 'model', rec, allowunset, actual,
                               display);
  }

#####
#
  const public.modellist := function (rec, allowunset, ref actual, ref display)
  {
    wider private;
   
    include 'modlistmanager.g';

    return private.genericitem(is_modellist, 'modellist', rec, allowunset, 
                               actual, display);
  }

#####
#
  const public.selection := function (rec, allowunset, ref actual, ref display)
  {
    wider private;
   
    include 'selectmanager.g';

    return private.genericitem(is_selection, 'selection', rec, allowunset, 
                               actual, display);
  }

#####
#
  const public.calibration := function (rec, allowunset, ref actual, 
                                        ref display)
  {
    wider private;
   
    include 'calmanager.g';

    return private.genericitem(is_calibration, 'calibration', rec, allowunset, 
                               actual, display);
  }

#####
#
  const public.calibrationlist := function (rec, allowunset, ref actual, 
                                            ref display)
  {
    wider private;
   
    include 'callistmanager.g';

    return private.genericitem(is_calibrationlist, 'calibrationlist', rec, 
                               allowunset, actual, display);
  }

#####
#
  const public.solver := function (rec, allowunset, ref actual, ref display)
  {
    wider private;
   
    include 'solvermanager.g';

    return private.genericitem(is_solver, 'solver', rec, allowunset, actual,
                               display);
  }

#####
#
  const public.solverlist := function (rec, allowunset, ref actual, 
                                       ref display)
  {
    wider private;
   
    include 'slvlistmanager.g';

    return private.genericitem(is_solverlist, 'solverlist', rec, allowunset, 
                               actual, display);
  }

#####
#
  const public.freqsel := function (rec, allowunset, ref actual, 
                                    ref display)
  {
    wider private;
   
    include 'freqselmanager.g';

    return private.genericitem(is_freqsel, 'freqsel', rec, allowunset, 
                               actual, display);
  }

#####
#
  const public.restoringbeam := function (rec, allowunset, ref actual, 
                                          ref display)
  {
    wider private;
   
    include 'beammanager.g';

    return private.genericitem(is_restoringbeam, 'restoringbeam', rec, 
                               allowunset, actual, display);
  }

#####
#
  const public.deconvolution := function (rec, allowunset, ref actual, 
                                          ref display)
  {
    wider private;
   
    include 'deconvmanager.g';

    return private.genericitem(is_deconvolution, 'deconvolution', rec, 
                               allowunset, actual, display);
  }

#####
#
  const public.imagingcoord := function (rec, allowunset, ref actual, 
                                         ref display)
  {
    wider private;
   
    include 'imcoordmanager.g';

    return private.genericitem(is_imagingcoord, 'imagingcoord', rec, 
                               allowunset, actual, display);
  }

#####
#
  const public.imagingfield := function (rec, allowunset, ref actual, 
                                         ref display)
  {
    wider private;
   
    include 'imgfldmanager.g';

    return private.genericitem(is_imagingfield, 'imagingfield', rec, 
                               allowunset, actual, display);
  }

#####
#
  const public.imagingfieldlist := function (rec, allowunset, ref actual, 
                                             ref display)
  {
    wider private;
   
    include 'imflistmanager.g';

    return private.genericitem(is_imagingfieldlist, 'imagingfieldlist', rec, 
                               allowunset, actual, display);
  }

#####
#
  const public.imagingweight := function (rec, allowunset, ref actual, 
                                          ref display)
  {
    wider private;
   
    include 'imwgtmanager.g';

    return private.genericitem(is_imagingweight, 'imagingweight', rec, 
                               allowunset, actual, display);
  }

#####
#
  const public.mask := function (rec, allowunset, ref actual, 
                                 ref display)
  {
    wider private;
   
    include 'maskmanager.g';

    return private.genericitem(is_mask, 'mask', rec, 
                               allowunset, actual, display);
  }

#####
#
  const public.transform := function (rec, allowunset, ref actual, 
                                      ref display)
  {
    wider private;
   
    include 'transfmmanager.g';

    return private.genericitem(is_transform, 'transform', rec, 
                               allowunset, actual, display);
  }

#####
#
  const public.scalar := function(rec, allowunset, ref actual, ref display)
  {
    
    wider private;

    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.scalar');
      }
    }

    if(is_string(rec)) {
      private.strip(rec);
      if(sum(strlen(rec))==0) {
	val actual := illegal;
	val display := '';
	return F;
      }
      if((rec~private.scalar.regex)&&(length(split(rec))==1)) {
	# It's a number as a string e.g. '1.2434' so we can eval it
        if(private.checkevalable(rec)) {
	  val actual := eval(rec);
	  val display := rec;
	  return T;
	}
      }
      # Could be the name of a variable e.g. 'xinc'
      else {
	# Yes, it is so we can eval it at the cost of
	# provoking an undefined variable snark from glish
        if(private.checkevalable(rec)) {
 	  erec:=eval(rec);
	  if (is_fail(erec)) {
	    val actual := illegal;
	    val display := '';
	    return F;
	  }
	  if(is_numeric(erec)&&!is_boolean(erec)&&length(erec)==1) {
	    val actual := erec;
	    val display := rec;
	    return T;
	  }
 	}
      }
      val actual := illegal;
      val display := '';
      return F;
    }
    # It's a variable e.g. xinc or 1.233
    else if(is_numeric(rec)&&length(rec)==1) {
      val actual := rec;
      val display := as_evalstr(actual);
      return T;
    }
    val actual := illegal;
    val display := '';
    return F;
  }
    
#####
#
  const public.angle := function(rec, allowunset, ref actual, ref display)
  {
    
    wider private;

    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.angle');
      }
    }

    if(is_string(rec)) {
      private.strip(rec);
      if(sum(strlen(rec))==0) {
	val actual := illegal;
	val display := '';
	return F;
      }
      else if(dq.is_angle(rec)) {
	# It's a angle string
	val actual := dq.toangle(rec);
	val display := rec;
	return T;
      }
      # Could be the name of a variable e.g. 'xinc'
      else {
	# Yes, it is so we can eval it at the cost of
	# provoking an undefined variable snark from glish
        if(private.checkevalable(rec)) {
	  erec:=eval(rec);
	  if(is_string(erec)&&dq.is_angle(erec)) {
	    val actual := dq.toangle(erec);
	    val display := rec;
	    return T;
	  }
	}
      }
      val actual := illegal;
      val display := '';
      return F;
    }
    # It's a variable e.g. xinc or 1.233
    else if(is_numeric(rec)&&length(rec)==1) {
      val actual := rec;
      val display := as_evalstr(actual);
      return T;
    }
    else {
      val actual := illegal;
      val display := '';
      return F;
    }
  }
    
#####
#
  const public.string := function (rec, allowunset, ref actual, ref display)
  {
    wider private;

    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.string');
      }
    }

    if(is_string(rec)) {
      # Does it have embedded \n's?
      rec~:=s/\n\n/\n/g
      if(rec~m/\n/) {
	val actual := split(rec, '\n');
        val display := rec;
        return T;
      }
      else {
        val actual := rec;
        d:=rec;
        if(len(rec)>1) {
	  for (i in 1:(len(rec)-1)) {
            if(d[i]!='\n') d[i] := spaste(d[i], '\n');
	  }
	}
	val display := spaste(d);
	return T;
      }
    }
    else if(is_defined(rec)) {
      if(private.checkevalable(rec)) {
	erec := eval(rec);
	if(is_string(erec)) {
	  private.strip(erec);
	  val actual := split(erec, '\n');
	  val display := erec;
	}
	else {
	  val actual := illegal;
	  val display := '';
	  return F;
	}
	return T;
      }
    }
    val actual := illegal;
    val display := '';
    return F;
  }

  const public.file := function (rec, allowunset, ref actual, ref display)
  {
    wider private;

    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.file');
      }
    }

    if(is_string(rec)) {
      srec := as_string(split(paste(rec), ','));
      for (i in ind(srec)) {
	private.strip(srec[i]);
      }
      if(sum(strlen(srec))==0) {
	val actual := '';
	val display := '';
	return T;
      }
      else {
	val actual := split(srec);
	val display := rec;
	return T;
      }
    }
    else if(is_defined(as_string(rec))) {
      if(private.checkevalable(rec)) {
	erec := eval(rec);
	if(is_string(erec)) {
	  srec := as_string(split(erec), ',');
	  for (i in 1:length(srec)) {
	    private.strip(srec[i]);
	  }
	  if(sum(strlen(srec))==0) {
	    val actual := '';
	    val display := '';
	    return T;
	  }
	  else {
	    val actual := split(srec);
	    val display := erec;
	    return T;
	  }
	}
	else {
	  val actual := illegal;
	  val display := '';
	  return F;
	}
	return T;
      }
    }
    val actual := illegal;
    val display := '';
    return F;
  }

#####
#
  const public.tool := function(rec, allowunset, ref actual, ref display)
  {
    wider private;

    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.tool');
      }
    }

    val actual := rec;
    if(is_string(rec)) {
      private.strip(rec);
      if(rec=='') {
	val actual := illegal;
	val display := '';
	return throw('Tool name cannot be empty');
      }
      val actual := rec;
      val display := rec;
    }
    else {
      val display := as_evalstr(rec);
    }
    return T;
  }

  const public.untyped := function(rec, allowunset, ref actual, ref display)
  {
    wider private;
    if(private.isunset(rec, allowunset, actual, display)) {
      if(allowunset) {
	return T;
      }
      else {
	return throw('Unset values not allowed', priority='SEVERE',
		     origin='entryparser.untyped');
      }
    }

    val actual := rec;
    if(is_string(rec)) {
      if (rec==private.array.nodisplay) {
        val display:=private.array.display;
#
# This means someone hit <CR> again after pasting in
# from the clip-board, or perversely, typed in <array>
	return T;
      }
      private.strip(rec);
      val display := rec;
    }
    else {
      val display := as_evalstr(rec);
    }
    return T;
  }

  return ref public;  
}

const defaultentryparser := entryparser();
const dep := ref defaultentryparser;

note('defaultentryparser (dep) ready', priority='NORMAL', 
     origin='entryparser.g');

