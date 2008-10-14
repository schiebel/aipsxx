# clientry: Cli for input and output of parameters
# Copyright (C) 1996,1997,1998,1999,2000
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
# $Id: clientry.g,v 19.2 2004/08/25 02:12:22 cvsmgr Exp $


pragma include once
    
include 'unset.g';
include 'clipboard.g';
include 'entryparser.g';
    
const clientry := function()
{
  
  public := [=];
  private := [=];

  private.unset := '<unset>';

  private["measure"].default := 'dm.direction(\'b1950\', \'0deg\', \'0deg\');';
  private["quantity"].default := '0deg';
  private["region"].default := [=];
  private["record"].default := [=];
  private["scalar"].default := 0.0;
  private["string"].default := '';
  private["array"].default := [];
  private["untyped"].default := F;

  private.quantity.types:=[=];
  private.quantity.types['freq']:="Hz kHz";
  private.quantity.types['angle']:="marcsec arcsec arcmin deg rad";
  private.quantity.types['time']:="s min h d a";
  private.quantity.types['flux']:="Jy uJy mJy kJy WU";
# We put the types that we will get from quanta LAST so
# that the prior ones will default in the case of
# ambiguity
  private.quantity.types['vel'] :="";
  private.quantity.types['long']:="";
  private.quantity.types['lat']:="";
  private.quantity.types['len']:="";
  
  tmp := eval('include \'quanta.g\'');
  if(!is_fail(tmp)&&(is_boolean(tmp)&&!tmp)) fail "Cannot include quanta.g";
  
  if(!is_defined('dq')) fail "defaultquanta does not exist";

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
      private.quantity.dimension[tp] := dq.quantity(private.quantity.types[tp][1]);
    } else {
      # Assume long or lat
      private.quantity.dimension[tp] := dq.quantity('0deg');
    };
  };
  
#########################################################################
#
# Start of public functions

  const public.boolean := subsequence(value=T, default=T,
				      allowunset=T,
				      editable=T)
  {
    
    #####################################################################
    # Setup initial values
    its := [=];
    
    its.allowunset := allowunset;
    its.editable := editable;

    its.values := ['True', 'False'];
    its.originalvalue := value;
    
    its.defaultvalue := default;
    
    its.actualvalue := unset;
    its.displayvalue := unset;
    
    #####################################################################
    # Public interface
    
    # Try to insert this value: it could be a string, a record,
    # an unset or a string which is an unset. 
    self.insert := function(rec) {
      if(!dep.boolean(rec, its.allowunset, its.actualvalue,
			 its.displayvalue)) {
	print "Cannot convert to a boolean";
	return F;
      };
      return T;
    }
    
    # Now the function that is called externally to determine the
    # current value. We always return as the specified type.
    self.get := function() {
      wider its, private;
      return its.actualvalue;
    }
    self.display := function() {
      wider its, private;
      return its.displayvalue;
    }
    
    if(is_fail(self.insert(its.originalvalue))) fail;
  }
  
  const public.check := subsequence(value="", default="",
				    options="", allowunset=T,
				    editable=T)
  {
    
    wider private;

    #####################################################################
    # Setup initial values
    its := [=];
    
    its.allowunset := allowunset;
    its.editable := editable;

    its.values := options;
    for (i in 1:length[its.values]) {
      its.values[i]~:=s/^ //g;
      its.values[i]~:=s/ $//g;
    }
    value~:=s/^ //g;
    value~:=s/ $//g;
    its.originalvalue := value;
    
    default~:=s/^ //g;
    default~:=s/ $//g;
    its.defaultvalue := default;
    
    its.actualvalue := value;
    its.displayvalue := value;
    
    #####################################################################
    # Public interface
    
    self.insert := function(rec) {
      if(!dep.check(rec, its.allowunset, its.values, its.actualvalue,
		       its.displayvalue)) {
	print "Allowed values are :", its.values;
	return F;
      }
      return T;
    }
    
    # Now the function that is called externally to determine the
    # current value. We always return as the specified type.
    self.get := function() {
      return its.actualvalue;
    }
    self.display := function() {
      return its.displayvalue;
    }
    if(is_fail(self.insert(its.originalvalue))) fail;
  }
  
  const public.choice := subsequence(value="", default="",
				     options="", allowunset=T,
				     editable=T)
  {
    
    #####################################################################
    # Setup initial values
    its := [=];
    
    its.allowunset := allowunset;
    its.editable := editable;

    its.values := options;
    for (i in 1:length[its.values]) {
      its.values[i]~:=s/^ //g;
      its.values[i]~:=s/ $//g;
    }
    value~:=s/^ //g;
    value~:=s/ $//g;
    default~:=s/^ //g;
    default~:=s/ $//g;
    if(is_unset(value)) {
      its.originalvalue := its.values[1];
    }
    else {
      its.originalvalue := value;
    }
    if(is_unset(default)) {
      its.defaultvalue := its.values[1];
    }
    else {
      its.defaultvalue := value;
    }
    its.defaultvalue := default;
    
    its.actualvalue := unset;
    its.displayvalue := unset;
    
    #####################################################################
    # Public interface
    
    # Try to insert this value
    self.insert := function(rec) {
      if(!dep.choice(rec, its.allowunset, its.values, its.actualvalue,
		     its.displayvalue)) {
        print "Allowed values are : ", its.values;
	return F;
      }
      return T;
    }
    
    # Now the function that is called externally to determine the
    # current value. We always return as the specified type.
    self.get := function() {
      wider its, private;
      return its.actualvalue[1];
    }
    self.display := function() {
      wider its, private;
      return its.displayvalue;
    }
    
    #####################################################################
    # Finish the setup
    
    # Now insert the original and default value. This does two
    # things: converts these to actual values, and also determines
    # the type of the widget
    if(is_fail(self.insert(its.originalvalue))) fail;
    
  }

  const public['measure'] := subsequence(value=unset, default=unset,
					 allowunset=T, editable=T)
  {
    wider private;
    
    #####################################################################
    # Setup initial values
    its := [=];
    
    its.allowunset := allowunset;
    its.editable := editable;
    
    if(is_unset(value)) {
      its.originalvalue := private['measure'].default;
    }
    else {
      its.originalvalue := value;
    }
    if(is_unset(default)) {
      its.defaultvalue := private['measure'].default;
    }
    else {
      its.defaultvalue := value;
    }
    its.defaultvalue := default;
    
    its.type := unset;
    its.actualvalue := unset;
    
    #####################################################################
    # Public interface
    
    self.insert := function(rec) {
      if(!dep.measure(rec, its.allowunset, its.actualvalue,
		      its.displayvalue, its.type)) {
	print "Not a valid measure";
	return F;
      }
      return T;
    }
    
    # Now the function that is called externally to determine the
    # current value. We always return as the specified type.
    self.get := function() {
      # WYSIWYG
      wider its, private;
      return its.actualvalue;
    }
    self.display := function() {
      # WYSIWYG
      wider its, private;
      return its.displayvalue;
    }
    
    #####################################################################
    # Finish the setup
    
    # Now insert the original and default value. This does two
    # things: converts these to actual values, and also determines
    # the type of the widget
    if(is_fail(self.insert(its.defaultvalue))) fail;
  }
  
  const public['quantity'] := subsequence(value=unset, default=unset,
					  allowunset=T, editable=T)
  {
    wider private;
    
    #####################################################################
    # Setup initial values
    its := [=];
    
    its.allowunset := allowunset;
    its.editable := editable;
    
    if(is_unset(value)) {
      its.originalvalue := private['quantity'].default;
    }
    else {
      its.originalvalue := value;
    }
    if(is_unset(default)) {
      its.defaultvalue := private['quantity'].default;
    }
    else {
      its.defaultvalue := value;
    }
    its.defaultvalue := default;
    
    its.type := unset;
    its.actualvalue := unset;
    its.displayvalue := unset;
    its.unit := unset;
    
    if (is_fail(dep.quantity.findtype(its.originalvalue, its.defaultvalue,
				      its.type))) fail;
    
    #####################################################################
    # Public interface
    
    self.insert := function(rec) {
      if(!dep.quantity.parse(rec, its.allowunset, its.actualvalue,
			     its.displayvalue, its.type, its.unit)) {
	print "Not a valid quantity";
        return F;
      }
      return T;
    }
    
    # Now the function that is called externally to determine the
    # current value. We always return as the specified type.
    self.get := function() {
      # WYSIWYG
      wider its, private;
      return its.actualvalue;
    }
    self.display := function() {
      # WYSIWYG
      wider its, private;
      if(is_quantity(its.actualvalue)) {
        return spaste(its.actualvalue.value, its.actualvalue.unit);
      }
      else {
	return its.displayvalue;
      }
    }
    
    #####################################################################
    # Finish the setup
    
    # Now insert the original and default value. This does two
    # things: converts these to actual values, and also determines
    # the type of the widget
    if(is_fail(self.insert(its.defaultvalue))) fail;
    its.defaultvalue := its.actualvalue;
    if(is_fail(self.insert(its.originalvalue))) fail;
    its.originalvalue := its.actualvalue;
    
  }
  const public.scalar := subsequence(value=unset, default=unset,
				     allowunset=T, editable=T)
  {
    wider private;
    
    #####################################################################
    # Setup initial values
    its := [=];
    
    its.allowunset := allowunset;
    its.editable := editable;
    
    if(is_unset(value)) {
      its.originalvalue := private['scalar'].default;
    }
    else {
      its.originalvalue := value;
    }
    if(is_unset(default)) {
      its.defaultvalue := private['scalar'].default;
    }
    else {
      its.defaultvalue := value;
    }
    its.defaultvalue := default;
    
    its.type := unset;
    its.actualvalue := unset;
    its.displayvalue := unset;
    its.unit := unset;
    
    #####################################################################
    # Public interface
    
    self.insert := function(rec) {
      wider its;
      if(!dep.scalar(rec, its.allowunset, its.actualvalue,
		     its.displayvalue)) {
	print "Not a valid record";
	return F;
      };
      return T;
    }
    
    # Now the function that is called externally to determine the
    # current value. We always return as the specified type.
    self.get := function() {
      # WYSIWYG
      wider its, private;
      return its.actualvalue;
    }
    self.display := function() {
      # WYSIWYG
      wider its, private;
      return its.displayvalue;
    }
    
    #####################################################################
    # Finish the setup
    
    # Now insert the original and default value. This does two
    # things: converts these to actual values, and also determines
    # the type of the widget
    if(is_fail(self.insert(its.defaultvalue))) fail;
    its.defaultvalue := its.actualvalue;
    if(is_fail(self.insert(its.originalvalue))) fail;
    its.originalvalue := its.actualvalue;
    
  }
  
  const public['file'] := subsequence(value=unset, default=unset,
				      allowunset=T, editable=T)
  {
    wider private;
    private.file.default := '';
    
    #####################################################################
    # Setup initial values
    its := [=];
    
    its.allowunset := allowunset;
    its.editable := editable;
    
    if(is_unset(value)) {
      its.originalvalue := private['file'].default;
    }
    else {
      its.originalvalue := value;
    }
    if(is_unset(default)) {
      its.defaultvalue := private['file'].default;
    }
    else {
      its.defaultvalue := value;
    }
    its.defaultvalue := default;
    
    its.type := unset;
    its.actualvalue := unset;
    its.displayvalue := unset;
    
    #####################################################################
    # Public interface
    
    self.insert := function(ref rec) {
      if(!dep['file'](rec, its.allowunset, its.actualvalue,
			its.displayvalue)) {
	print "Not a valid file";
	return F;
      };
      return T;
    }
    
    # Now the function that is called externally to determine the
    # current value. We always return as the specified type.
    self.get := function() {
      # WYSIWYG
      wider its, private;
      return its.actualvalue;
    }
    self.display := function() {
      # WYSIWYG
      wider its, private;
      return its.displayvalue;
    }
  }
  
  const public['record'] := subsequence(value=unset, default=unset,
				   allowunset=T, editable=T)
  {
    wider private;
    
    #####################################################################
    # Setup initial values
    its := [=];
    
    its.allowunset := allowunset;
    its.editable := editable;
    
    if(is_unset(value)) {
      its.originalvalue := private['record'].default;
    }
    else {
      its.originalvalue := value;
    }
    if(is_unset(default)) {
      its.defaultvalue := private['record'].default;
    }
    else {
      its.defaultvalue := value;
    }
    its.defaultvalue := default;
    
    its.type := unset;
    its.actualvalue := unset;
    its.displayvalue := unset;
    
    #####################################################################
    # Public interface
    
    self.insert := function(ref rec) {
      if(!dep['record'](rec, its.allowunset, its.actualvalue,
			its.displayvalue)) {
	print "Not a valid record";
	return F;
      };
      return T;
    }
    
    # Now the function that is called externally to determine the
    # current value. We always return as the specified type.
    self.get := function() {
      # WYSIWYG
      wider its, private;
      return its.actualvalue;
    }
    self.display := function() {
      # WYSIWYG
      wider its, private;
      return its.displayvalue;
    }
  }
  
  const public['region'] := subsequence(value=unset, default=unset,
				   allowunset=T, editable=T)
  {
    wider private;
    
    #####################################################################
    # Setup initial values
    its := [=];
    
    its.allowunset := allowunset;
    its.editable := editable;
    
    if(is_unset(value)) {
      its.originalvalue := private['region'].default;
    }
    else {
      its.originalvalue := value;
    }
    if(is_unset(default)) {
      its.defaultvalue := private['region'].default;
    }
    else {
      its.defaultvalue := value;
    }
    its.defaultvalue := default;
    
    its.type := unset;
    its.actualvalue := unset;
    its.displayvalue := unset;
    
    #####################################################################
    # Public interface
    
    self.insert := function(ref rec) {
      if(!dep['region'](rec, its.allowunset, its.actualvalue,
			its.displayvalue)) {
	print "Not a valid region";
	return F;
      };
      return T;
    }
    
    # Now the function that is called externally to determine the
    # current value. We always return as the specified type.
    self.get := function() {
      # WYSIWYG
      wider its, private;
      return its.actualvalue;
    }
    self.display := function() {
      # WYSIWYG
      wider its, private;
      return its.displayvalue;
    }
  }
  
  const public['string'] := subsequence(value=unset, default=unset,
				   allowunset=T, editable=T)
  {
    wider private;
    
    #####################################################################
    # Setup initial values
    its := [=];
    
    its.allowunset := allowunset;
    its.editable := editable;
    
    if(is_unset(value)) {
      its.originalvalue := private['string'].default;
    }
    else {
      its.originalvalue := value;
    }
    if(is_unset(default)) {
      its.defaultvalue := private['string'].default;
    }
    else {
      its.defaultvalue := value;
    }
    its.defaultvalue := default;
    
    its.type := unset;
    its.actualvalue := unset;
    its.displayvalue := unset;
    
    #####################################################################
    # Public interface
    
    self.insert := function(ref rec) {
      if(!dep['string'](rec, its.allowunset, its.actualvalue,
			its.displayvalue)) {
	print "Not a valid string";
	return F;
      };
      return T;
    }
    
    # Now the function that is called externally to determine the
    # current value. We always return as the specified type.
    self.get := function() {
      # WYSIWYG
      wider its, private;
      return its.actualvalue;
    }
    self.display := function() {
      # WYSIWYG
      wider its, private;
      return its.displayvalue;
    }
  }
  
  const public['array'] := subsequence(value=unset, default=unset,
				   allowunset=T, editable=T)
  {
    wider private;
    
    #####################################################################
    # Setup initial values
    its := [=];
    
    its.allowunset := allowunset;
    its.editable := editable;
    
    if(is_unset(value)) {
      its.originalvalue := private['array'].default;
    }
    else {
      its.originalvalue := value;
    }
    if(is_unset(default)) {
      its.defaultvalue := private['array'].default;
    }
    else {
      its.defaultvalue := value;
    }
    its.defaultvalue := default;
    
    its.type := unset;
    its.actualvalue := unset;
    its.displayvalue := unset;
    
    #####################################################################
    # Public interface
    
    self.insert := function(ref rec) {
      if(!dep['array'](rec, its.allowunset, its.actualvalue,
			its.displayvalue)) {
	print "Not a valid array";
	return F;
      };
      return T;
    }
    
    # Now the function that is called externally to determine the
    # current value. We always return as the specified type.
    self.get := function() {
      # WYSIWYG
      wider its, private;
      return its.actualvalue;
    }
    self.display := function() {
      # WYSIWYG
      wider its, private;
      return its.displayvalue;
    }
  }
  const public['booleanarray'] := subsequence(value=unset, default=unset,
					      allowunset=T, editable=T)
  {
    wider private;
    
    #####################################################################
    # Setup initial values
    its := [=];
    
    its.allowunset := allowunset;
    its.editable := editable;
    
    if(is_unset(value)) {
      its.originalvalue := private['array'].default;
    }
    else {
      its.originalvalue := value;
    }
    if(is_unset(default)) {
      its.defaultvalue := private['array'].default;
    }
    else {
      its.defaultvalue := value;
    }
    its.defaultvalue := default;
    
    its.type := unset;
    its.actualvalue := unset;
    its.displayvalue := unset;
    
    #####################################################################
    # Public interface
    
    self.insert := function(ref rec) {
      if(!dep['booleanarray'](rec, its.allowunset, its.actualvalue,
			      its.displayvalue)) {
	print "Not a valid array";
	return F;
      };
      return T;
    }
    
    # Now the function that is called externally to determine the
    # current value. We always return as the specified type.
    self.get := function() {
      # WYSIWYG
      wider its, private;
      return its.actualvalue;
    }
    self.display := function() {
      # WYSIWYG
      wider its, private;
      return its.displayvalue;
    }
  }
  
  const public.untyped := subsequence(value=unset, default=unset,
				     allowunset=T, editable=T)
  {
    wider private;
    
    #####################################################################
    # Setup initial values
    its := [=];
    
    its.allowunset := allowunset;
    its.editable := editable;
    
    if(is_unset(value)) {
      its.originalvalue := private['untyped'].default;
    }
    else {
      its.originalvalue := value;
    }
    if(is_unset(default)) {
      its.defaultvalue := private['untyped'].default;
    }
    else {
      its.defaultvalue := value;
    }
    its.defaultvalue := default;
    
    its.type := unset;
    its.actualvalue := unset;
    its.displayvalue := unset;
    its.unit := unset;
    
    #####################################################################
    # Public interface
    
    self.insert := function(rec) {
      wider its;
      if(!dep.untyped(rec, its.allowunset, its.actualvalue,
		     its.displayvalue)) {
	print "Not a valid record";
	return F;
      };
      return T;
    }
    
    # Now the function that is called externally to determine the
    # current value. We always return as the specified type.
    self.get := function() {
      # WYSIWYG
      wider its, private;
      return its.actualvalue;
    }
    self.display := function() {
      # WYSIWYG
      wider its, private;
      return its.displayvalue;
    }
    
    #####################################################################
    # Finish the setup
    
    # Now insert the original and default value. This does two
    # things: converts these to actual values, and also determines
    # the type of the widget
    if(is_fail(self.insert(its.defaultvalue))) fail;
    its.defaultvalue := its.actualvalue;
    if(is_fail(self.insert(its.originalvalue))) fail;
    its.originalvalue := its.actualvalue;
    
  }

  const public['range'] := subsequence(parent=unset, value=unset,
				       default=unset,
				       allowunset=F,
				       editable=T) {
    self := public.scalar(parent, value,
			  default, options,
			  allowunset,
			  editable);
  }

  return ref public;

}

const defaultclientry := clientry();
const dce := ref defaultclientry;

  note('defaultclientry (dce) ready', priority='NORMAL', 
       origin='clientry.g');
  
