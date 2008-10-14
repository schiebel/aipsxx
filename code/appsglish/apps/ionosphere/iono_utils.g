# iono_utils.g: Various helper function for ionosphere and rinex
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
#   $Id: iono_utils.g,v 19.2 2004/08/25 01:21:56 cvsmgr Exp $

pragma include once
include "quanta.g"
include "measures.g"

#---------------------------------------------------------------
# epoch_to_mjd(date)
# epochs_to_mjd(dates)
#
# Resolves any epoch specification(s) to a numeric MJD.
# 
# Recognized epoch specifications are:
#   (a) a numeric MJD (returned as is)
#   (b) a string (UTC assumed, passed to dq.quantity() to convert to MJD)
#   (c) a time quantity (UTC assumed, converted to days)
#   (d) an epoch measure (converted to UTC, and the value is returned)
#
# epoch_to_mjd accepts a single epoch, and returns the MJD.
# epochs_to_mjd accepts a vector or record of epochs, and returns a vector of MJDs.
const epoch_to_mjd  := function(date) {
  if( is_numeric(date) ) {
    return date;
  }
  else if( is_quantity(date) ) {
    if( date.unit == 'd' )
      return date.value;
    else
      return dq.convert( date,'1.d' );
  }
  else if( is_string(date) ) {
    return dq.quantity(date).value;
  }
  else if( is_measure(date) ) { # is this a measure?
    if( date.type != 'epoch' )
      fail 'date measure must of type epoch'
    if( date.refer != 'UTC'  )  # convert to UTC if needed
      date := dm.measure(date,'utc')
    return date.m0.value;
  }
  else
    fail paste('this does not look like a date:',date)
}
const epochs_to_mjd := function(dates) {
  # build up vector of MJDs
  if( is_measure(dates) || is_quantity(dates) ) {  # is it a single measure/quantity?
    return epoch_to_mjd(dates)
  } 
  n := len(dates)
  mjd := array(0.0,n)
  for( i in 1:n ) {
    d := epoch_to_mjd(dates[i])
    if( is_fail(d) ) fail 
    mjd[i] := d
  }
  return mjd
}

const time_to_hours := function (time) 
{
  if( is_numeric(time) )
    return time;
  if( is_quantity(time) )
    return dq.getvalue(dq.convert(time,'h'));
  if( is_string(dur) );
    return dq.getvalue(dq.convert(dq.quantity(dur),'h'));
  fail 'Illegal time specification';
}

const resolve_position := function(pos,refer=F) {
  # (a) pos is a measure: verify
  if( is_measure(pos) ) {
    if( pos.type != 'position' ) # check that its a position
      fail paste('this does not look like a position measure:',pos)
  }
  # (b) pos is a single string: observatory name
  else if( is_string(pos) && len(pos)==1 ) { # one string -- observatory name
    pos := dm.observatory(pos); 
  }
  # (c) pos is a vector of strings or numerics...
  else if( len(pos)>1 ) {
    alt := '0m';
    if( is_numeric(pos) ) {  # numeric values: assume degrees & meters
      lon := spaste(pos[1],'deg');
      lat := spaste(pos[2],'deg');
      if( len(pos)>2 ) 
        alt := spaste(pos[3],'m');
    } else if( is_string(pos) ) {
      lon := pos[1];
      lat := pos[2];
      if( len(pos)>2 ) 
        alt := pos[3];
    } else {
      fail paste('unable to parse this position:',pos);
    }
    pos := dm.position('wgs84',lon,lat,alt);
  }
  else
    fail paste('unable to parse this position:',pos);

# if a reference code is specified and ours is different, convert
  if( is_string(refer) && to_upper(pos.refer) != to_upper(refer) ) 
    return dm.measure(pos,refer);
  return pos;
}

const resolve_direction := function(dir) {
  # (a) dir is a measure: verify
  if( is_measure(dir) ) {
    if( dir.type != 'direction' ) # check that its a position
      fail paste('this does not look like a direction measure:',dir)
    # if reference frame is specified, convert to it
  }
  # (b) dir is a single string: source name
  else if( is_string(dir) && len(dir)==1 ) { # one string -- source name
    dir := dm.source(dir); 
  }
  # (c) dir is a 2-element string or numeric vector
  else if( len(dir)==2 ) {
    if( is_numeric(dir) ) {  # numeric values: assume degrees & meters
      d := [ spaste(dir[1],'deg'),
             spaste(dir[2],'deg') ];
    } else if( is_string(dir) ) {
      d := dir;
    } else {
      fail paste('unable to parse this direction:',dir);
    }
    dir := dm.direction('azel',d[1],d[2]);
  }
  else
    fail paste('unable to parse this direction:',dir);
    
  return dir;
}

# where(boolean mask)
# Returns vector of indices corresponding to T values in mask
# (i.e. works like IDL's WHERE)
#
const where := function (mask) 
{
  return ind(mask)[mask];
}

# exam(variable)
# pretty-prints the contents of a variable
#   nel is the max # of array elements printed
const exam := function( var,nel=2,indent=0 )
{
  desc := '';
  if( is_record(var) )
  {
    fields := field_names(var);
    maxlen := max(strlen(fields))+2;
    format := spaste('%-',maxlen,'s%s');
    fd := array('',len(fields));
    offset := '';
    for( i in 1:len(var) ) 
    {
      d1 := exam(var[i],indent=indent+maxlen);
      fd[i] := spaste(offset,sprintf(format,spaste(fields[i],':'),d1))
      if( i==1 )
        offset := sprintf(spaste('%',indent,'s'),'');
    }
    return paste(fd,sep='\n');
  }
  if( len(var)>1 )
  {
    desc := spaste(type_name(var),' [',as_string(shape(var)),']');
    if( nel )
    {
      for( i in 1:min(nel,len(var)) )
        desc := paste(desc,var[i])
      if( len(var)>nel )
        desc := paste(desc,'...');
    }
    return desc;
  }
  if( is_string(var) )
  {
    return spaste("'",var,"'");
  }
  return spaste(as_string(var),' (',type_name(var),')');
}
