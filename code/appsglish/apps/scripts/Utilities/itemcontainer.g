#   itemcontainer.g: A Glish object to contain items in a Glish record
#
#   Copyright (C) 1996,1997,1998,2000,2001
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
#   $Id: itemcontainer.g,v 19.2 2004/08/25 02:08:56 cvsmgr Exp $

pragma include once
include 'note.g'
include 'illegal.g'

const is_itemcontainer := function(const container)
#
# Is this variable a valid itemcontainer object ?  
#
{
   if (!is_record(container)) return F;
   if (!has_field(container, 'type')) return F;
   if (!is_function(container.type)) return F;
   if (container.type() == 'itemcontainer') return T;
   return F;
}


const itemcontainer := function()
#
# Constructor
#
{
   private :=[=];
   private.const := F;
   private.holes := [];

#------------------------------------------------------------------------
# Private functions
#
# Utility functions for a vector of holes, which contains indices of
# elements deleted from the itemcontainer. The deleted fields are still
# part of the container but the values are 'illegal'
# If a new item is added or set holes are _plugged_ in order of 
# index.
#
const private.addhole := function(const value) {
    wider private;
    local n := length(private.holes);
    private.holes[n+1]:= value;
    private.holes := sort(private.holes);
    return min(private.holes);
}

const private.removehole := function() {    
    wider private;
    local n := length(private.holes);
    # is this the last hole in vector
    if ( n > 1 ) {
	private.holes := private.holes[2:n];
    } else {
	# empty
	private.holes := [];
    }
    return min(private.holes);
}
const private.hashole := function() {
    wider private;
    if (length(private.holes) > 0) {
	return T;
    } else {
	return F;
    }
}

const private.plughole := function(const index, const item, const value) {
    wider private;
    itemscopy := [=];
    k:=1;
    for (str in field_names(private.items)) {	
#    for (k in 1:length(private.items)) {
	if ( k == index ) {
	    itemscopy[item] := value;	    
	} else {
	    itemscopy[str] := private.items[str];
	}
	k +:=1;
    }
    private.items := itemscopy;
    return T;
} 


#-----------------------------------------------------------------------
# Public functions
#
   public :=[=];


const public.gui := function ()
{
# shut object catalog up
return T;
}


const public.done := function()
{
   wider public;
   wider private;
   private := F;
   val public := F
   return T;
}


const public.get := function (const item)
#
# Get the value of the specified item.
# If the type of item is an integer, then
# the numbered field will be recovered.
# If its not present, you get a fail
#
{
   if (is_integer(item)) {
      if (item > 0 && item <= public.length() && 
	  (!is_illegal(private.items[item])) ) {
         return const ref private.items[item];
      }
   } else if (is_string(item)) {
      if (public.has_item(item)) {
         return const ref private.items[item];
      }
   } else {
      fail 'the given item was neither an integer nor a string'
   }
   msg := spaste('Requested item "', item, '" is not present');
   fail msg;
}

const public.has_item := function (const item)
#
# See if the specified item exists and is not illegal
#
{
   if (has_field(private, 'items') && has_field(private.items, item)) {
       if ( is_illegal(private.items[item]) ) {
	   return F;
       } else {
	   return T;
       }
   }
   return F;
}


const public.makeconst := function()
#
# Make this object non-writable
#
{
   wider private;
   private.const := T;
   return T;
}

const public.makeunconst := function()
#
# Make this object writable again
#
{
   wider private;
   private.const := F;
   return T;
}

const public.length := function(showdeleted=F)
{
    if (type_name(showdeleted) != 'boolean') {
	fail 'flag must be a boolean';
    }
    if (has_field(private, 'items')) {
	if (showdeleted) {
	    return length(private.items);
	} else {
	    return (length(private.items)-length(private.holes));
	}
    } else {
	return 0;
    }
}

const public.names := function()
{
    fnames := [''];
    if (has_field(private, 'items')) {
	count :=1;
	for (str in field_names(private.items) ) {
	    if (!is_illegal(private.items[str])) {
		fnames[count] := str;
		count +:=1;
	    }
	}
       return fnames;
    } else {
	return '';
    }
}

const public.set := function(const item, const value) 
#
# Make a record in the private data whose field name
# is the value of "item", and whose value is the
# value of "value".  You can make anything you
# like !  
#
# Returns a fail if the object is const or the item
# name is not a string.  
#
{
   wider private;
   if (private.const == T) {
      fail 'This is a const object, you cannot write to it';
   }
   if (!is_string(item)) {
      fail 'Item must be a string';
  }
   if ( (private.hashole()) && (!public.has_item(item)) ) {
       private.plughole(private.holes[1],item,value);
       private.removehole();
   } else {
       private.items[item] := value;
   }
   return T;
}

const public.add := function(const value) 
#
# Make the next record in the private data whose 
# value is the value of "value".  
#
# Returns a fail if the object is const 
#
{
   wider private;
   if (private.const == T) {
      fail 'This is a const object, you cannot write to it';
   }
   if (!has_field(private, 'items')) private.items := [=];
   if (private.hashole()) {
       n := private.holes[1];
       private.removehole();
   } else {
       n := length(private.items)+1;
   }
   private.items[n] := value;
   return n;
}

const public.delete := function(const item)
{
#
# Delete a record in the private data whose field name
# is "item".
#
# Returns a fail if the object is const or the item
# name is not a string/integer or the field doesn't exist
#    
    wider private;
    if (!has_field(private, 'items')) {
	fail 'Container is empty';
    }
    if ( (!is_string(item)) && (!is_integer(item)) ) {
	fail 'Item must be string or integer';
    }
    if (private.const == T) {
	fail 'This is a const object, you cannot delete from it';
    }
    count := 1;
    if (is_string(item)) {
	if (!public.has_item(item)) {
	    fail 'The specified item is not in the container';
	}	
	n := field_names(private.items);
    } else {
	if (is_illegal(private.items[item])) {
	    fail 'The specified item is not in the container';	
	}
	n := [1:length(private.items)];
    }
    for ( i in n ) {
	if ( i == item ) {
	    private.items[i] := illegal;
	    private.addhole(count);
	}
	count +:=1;
    }
    return T;
}        

const public.fromrecord := function (rec=[=]) 
{
   nfields := length(rec);
   if (nfields > 0) {
      names := field_names(rec);
      for (i in 1:nfields) {
         ok := public.set(names[i], rec[names[i]]);
         if (is_fail(ok)) fail;
      }
   }
   return T;
}

const public.torecord := function(showdeleted=F)
{
    if (type_name(showdeleted) != 'boolean') {
	fail 'showdeleted must be a boolean'
    }
    if (has_field(private, 'items')) {
	if (!showdeleted) {
	    outrecord := [=];
	    for ( str in split(public.names()) ) {
		if (!is_illegal(private.items[str])) {
                    if (is_itemcontainer(private.items[str])) {
                        outrecord[str] := private.items[str].torecord();
                    } else {
		        outrecord[str] := private.items[str];
                    }
		}
	    }
	    return outrecord;
	} else {
	    return private.items;
	}
    } else {
	return [=];
    }
}

const public.type := function()
{
   return 'itemcontainer';
}



   return const ref public;
}
