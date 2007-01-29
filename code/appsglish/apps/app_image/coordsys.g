# coordsys.g: Binding to Glish for coordinate system DO
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
#   $Id: coordsys.g,v 19.5 2004/08/25 00:55:56 cvsmgr Exp $
#

pragma include once

include 'coordsyssupport.g'
include 'servers.g'
include 'plugins.g'
include 'misc.g'
include 'serverexists.g'
include 'quanta.g'
include 'measures.g'

# Global functions

###
const is_coordsys := function (thing)
{
   if (!is_record(thing)) return F;
   if (!has_field(thing, 'type')) return F;
   if (!is_function(thing.type)) return F;
   if (!(thing.type() == 'coordsys')) return F;
   return T;
}

###
const coordsystools := function()
#
# Find all the Glish coordsys tools
#
{
   list := symbol_names(is_coordsys);
   if (length(list)==0) return [];
#
   list2 := "";
   j := 1;
   for (i in 1:length(list)) {
      if (!(list[i] ~ m/^_/)) {     # Strip anything with leading underscore
         list2[j] := list[i];  
         j +:= 1;
      }
   }
   if (length(list2)==0) return list2;
   return sort(list2);
}


const coordsystest := function (which=unset)
{
    eval('include \'coordsystest.g\'');
    return coordsysservertest(which);
}



# Users aren't to use this.
const _define_coordsys := function (ref agent, id)
{
    if (!serverexists('dms', 'misc', dms)) {
       return throw('The misc server "dms" is not running',
                     origin='coordsys.g');
    }
    if (!serverexists('dq', 'quanta', dq)) {
       return throw('The quanta server "dq" is not running',
                     origin='coordsys.g');
    }
    if (!serverexists('defaultcoordsyssupport', 'coordsyssupport', defaultcoordsyssupport)) {
       return throw('The coordsyssupport server "defaultcoordsyssupport" is not running',
                    origin='coordsys.g');
    }
#
    its := [=]
#
    its.agent := ref agent;
    its.id := id;
#
# Make this closure an agent so it can emit events.  This
# code should be consolidated within servers.g
#
    public := [=]
    public := defaultservers.init_object(its)
    x := create_agent();
    for (i in field_names(x)) {
       public[i] := x[i];
    }

### Private methods

###
   const its.checkAbsRel := function (value, shouldBeAbs) 
   {
      if (has_field(value::, 'ar_type')) {
         if (shouldBeAbs) {
            if (value::ar_type=='relative') {
               return throw ('The value is relative, not absolute', origin='coordsys.checkAbsRel');
            }
         } else {
            if (value::ar_type=='absolute') {
               return throw ('The value is absolute, not relative ', origin='coordsys.checkAbsRel');
            }
         }
      }
      return T;
   }

   const its.checkFrequency := function (value) 
   {

# If we have a string, first convert it to a quantity

      vin := value;
      if (is_string(vin)) {
         vin := dq.quantity(vin)
         if (is_fail(vin)) fail;
      }

# If a quantity, make this into a Quantum vector (one unit, vector of values)
# which the DO expects

      local vout;
      if (is_quantity(vin)) {
         vv := dq.getvalue(vin);
         uu := dq.getunit(vin);
#
         if (length(uu)==1) {
            vout := vin;
         } else if (length(vv)==length(uu)) {

# Convert all values to the same (first) unit

            uuu := uu[1];
            vvv := [];
            for (i in 1:length(uu)) {
               t := dq.convert(vin[i], uuu);            
               if (is_fail(t)) fail;
               vvv[i] := dq.getvalue(t);
            }

# Create quantum vector

            vout := dq.quantity(vvv, uuu);
            if (is_fail(vout)) fail;            
         } else {
            return throw ('Value is not a valid quantity', origin='coordsys.checkFrequency');
         }
      } else {

# Just doubles given

        rf := dms.tovector(value, 'double');
        units := public.restfrequency().unit;
        if (is_fail(units)) fail;
        vout := dq.quantity(rf, units);
        if (is_fail(vout)) fail;
      }
#
      if (!dq.checkfreq(vout)) {
         return throw ('Value is not a valid frequency', origin='coordsys.checkFrequency');
      }
#
      return vout;
   }


###
    const its.coordinateValueToRecord := function (value, isWorld, isAbs, first)
#
# This function looks at the type of value and fills a record
# holding 'numeric', 'string', 'quantity', 'measure' with that
# value.  The value may itself be a record holding any/all of these fields
# (they must all be representations of the same world coordinate)
#
# You can choose to return just the first value found (first=T) or all of them
# in the case that value is a record
#
# isWorld says the value has been checked to be a world value, or user over-ride
# specifies that it is world and can be converted to world 
#
# isAbs says the value is expected to be absolute, else relative.
#
# If value is unset, the reference pixel/value is used.  Otherwise, missing axes are 
# padded in the C++.  
#
# 
   {
        rec := [=];
        if (is_unset(value)) {
           if (isWorld) {
              if (isAbs) {
                 rec.numeric := public.referencevalue(format='n');
              } else {
                 rec.numeric := array(0.0, public.naxes(T));
              }
           } else {
              if (isAbs) {
                 rec.numeric := public.referencepixel();
              } else {
                 rec.numeric := array(0.0, public.naxes(F));
              }
           }
           return rec;
        }
#
        if (is_numeric(value)) {
           rec.numeric := as_double(value);
           return rec;
        }
#
        if (is_string(value)) {
           if (isWorld) {
              rec.string := value;        # Don't split e.g. '1 km 20 m' into a vector.
           } else {
#
# Convert to numeric e.g. "1 20" -> [1,20]
#
              rec.numeric := dms.tovector(value, 'double');
              if (is_fail(rec.numeric)) fail;
           }
           return rec;
        }
#
        if (is_quantity(value)) {
           if (!isWorld) {
              return throw ('Pixel coordinate must be numeric',
                             origin='coordsys.coordinateValueToRecord');
           }
           rec.quantity := 
               defaultcoordsyssupport.valuetovectorquantum(value, singlevector=T);
           if (is_fail(rec.quantity)) fail;
           return rec;
        }
#
        if (is_record(value)) {
#
# Catch r := cs.toworld (value, 'nqms') style where r is a record
# with fields including 'measure'
# 
           none := T;
           if (has_field(value, 'numeric')) {
              rec.numeric := value.numeric;
              if (first) return rec;
              none := F;
           }
           if (has_field(value, 'measure')) {
              rec.measure := value.measure;
              if (first) return rec;
              if (!isWorld) {
                 return throw ('Pixel coordinate must be numeric not a measure',
                                origin='coordsys.coordinateValueToRecord');
              }
              none := F;
           }
           if (has_field(value, 'quantity')) {
              rec.quantity := value.quantity;
              if (first) return rec;
              if (!isWorld) {
                 return throw ('Pixel coordinate must be numeric not a quantity',
                                origin='coordsys.coordinateValueToRecord');
              }
              none := F;
           }
           if (has_field(value, 'string')) {
              rec.string := value.string;
              if (first) return rec;
              if (!isWorld) {
                 rec.numeric := dms.tovector(value.string, 'double');
              }
              none := F;
           }
#
# Assumes the record is a measure...
#
           if (none) {
              if (!isWorld) {
                 return throw ('Pixel coordinate must be numeric not a measure',
                                origin='coordsys.coordinateValueToRecord');
              }
              rec.measure := value;       
           }
           return rec;
        }
   }

###
   const its.isValueWorld := function (value, shouldBeWorld, verbose=T)
#
# value          - the value, may have attribute 'pw_type' to tell us whether
#                  its world or pixel.  If not, we might be able to work
#                  it out from the type
# shouldBeWorld  - the value is expected to be a world value. if unset
#                  it means we rely on the attribute
#
   {
      if (is_unset(value)) {
         if (is_unset(shouldBeWorld)) {
              return throw ('Cannot discern whether value is pixel or world',
                            origin='coordsys.isValueWorld');
         } else {
            return as_boolean(shouldBeWorld)
         }
      }
#
      if (is_unset(shouldBeWorld)) {
        if (has_field(value::, 'pw_type')) {
           if (value::pw_type=='world') {
              return T;
           } else {
              return F;
           }
        } else {
           if (is_string(value) || is_quantity(value) || is_record(value)) {
              return T;
           } else {
              return throw ('Cannot discern whether value is pixel or world',
                            origin='coordsys.isValueWorld');
           }
        }
      } else {
        sbw := as_boolean(shouldBeWorld);
        if (has_field(value::, 'pw_type')) {
           if (sbw && value::pw_type!='world') {
              if (verbose) {
                 note ('Value appears to be pixel but world over-ride will be honoured',
                       priority='WARN', origin='coordsys.isValueWorld');
              }
           } else if (!sbw  && value::pw_type!='pixel') {
              if (is_string(value) || is_quantity(value) || is_record(value)) {
                 return throw ('Value must be of numeric type to be a pixel coordinate',
                               origin='coordsys.isValueWorld');
              } else {
                 note ('Value appears to be world but pixel over-ride will be honoured',
                       priority='WARN', origin='coordsys.isValueWorld');
              }
           }
        } else {
           if (!sbw) {
              if (is_string(value)) {
#
# We may be able to convert a string to numeric (as needed for pixel)
#
                 if (verbose) {
                    note ('Value appears to be world but pixel over-ride will be honoured',
                          priority='WARN', origin='coordsys.isValueWorld');
                 }
              } else if (is_quantity(value) || is_record(value)) {

#
# We can't convert these to numeric
#
                  return throw ('Value is a world coordinate (quantity/record), but pixel (numeric) expected',
                                 origin='coordsys.isValueWorld');
              }
           }
        }
        return sbw;
      }
   }


###
   const its.recordToCoordinateValue := function (rv) 
   {
      fn := field_names(rv);
      n := length(fn);
#
      if (has_field(rv, 'quantity')) {
 
# Length of vector of quantum 

         l := length(rv.quantity);

# Convert the record in the 'quantity' field to a true
# quantum (id & shape attributes needed).      This field
# ALWAYS holds a vector of quanta even if the length is 1
#
         q := r_array(rv.quantity[1], shape=l, id='quant')

# If l==1, q will now be a single quantum

         if (l>1) {
            for (i in 1:l) q[i] := rv.quantity[i];
         }
         rv.quantity := q;
      }

# Now fish out just the item if only one field in record

      if (n==1) {
         t := rv[fn[1]];                # Only one field in record
         return t;
      } else {
         return rv;
      }
   }


###
    const its.typeUnits := function (type) 
    {
       units := public.units();
       if (!is_unset(type)) {
          local pa, wa;
          ok := public.findcoordinate (pa, wa, type, 1);
          if (is_fail(ok)) fail;
          units := units[wa];
       }
       return units;
   }

### Public methods

    its.addcoordinateRec := [_method="addcoordinate", _sequence=its.id._sequence]
    const public.addcoordinate := function (direction=F, spectral=F, stokes="", linear=0,
                                            tabular=F)
    {
       wider its;
       its.addcoordinateRec.direction := as_boolean(direction);
       if (length(stokes) == 1 && strlen(stokes) == 0) {
	 stokes := "";               # Need zero length vector
       }
       its.addcoordinateRec.stokes := dms.tovector(stokes, 'string')
       its.addcoordinateRec.spectral := as_boolean(spectral);
       its.addcoordinateRec.linear := as_integer(linear);
       its.addcoordinateRec.tabular := as_boolean(tabular);
#
       return defaultservers.run(its.agent, its.addcoordinateRec, F);
    }


###
    its.axesmapRec := [_method="axesmap", _sequence=its.id._sequence]
    const public.axesmap := function(toworld=T)
    {
        wider its;
        its.axesmapRec.toworld := as_boolean(toworld);
        return defaultservers.run(its.agent, its.axesmapRec, F);
    }

###
    its.axiscoordinatetypesRec := [_method="axiscoordinatetypes", _sequence=its.id._sequence]
    const public.axiscoordinatetypes := function(world=T)
    {
       wider its;
       its.axiscoordinatetypesRec.world := world;
       return defaultservers.run(its.agent, its.axiscoordinatetypesRec, F);
    }
    const public.act := public.axiscoordinatetypes;


###
    its.conversiontypeRec := [_method="conversiontype", _sequence=its.id._sequence]
    const public.conversiontype := function (type)
    {
        wider its;
#
        its.conversiontypeRec.type := as_string(type);
        return defaultservers.run(its.agent, its.conversiontypeRec, F);
    }


###
    its.convertRec := [_method="convert", _sequence=its.id._sequence]
    const public.convert := function (coordin, 
                                      absin=unset, 
                                      dopplerin='radio', 
                                      unitsin=unset,
                                      absout=unset,
                                      dopplerout='radio',
                                      unitsout=unset,
                                      shape=unset)
    {
       wider its;
       its.convertRec.coordin := dms.tovector(coordin, 'double');
#
       if (is_unset(absin)) absin := array(T, public.naxes());
       its.convertRec.absin := dms.tovector(absin, 'boolean');
#
       if (is_unset(absout)) absout := array(T, public.naxes());
       its.convertRec.absout := dms.tovector(absout, 'boolean');
#
       its.convertRec.dopplerin := as_string(dopplerin);
       its.convertRec.dopplerout := as_string(dopplerout);
#
       if (is_unset(unitsin)) unitsin := public.units();
       its.convertRec.unitsin := dms.tovector(unitsin, 'string');
#
       if (is_unset(unitsout)) unitsout := public.units();
       its.convertRec.unitsout := dms.tovector(unitsout, 'string');
#
       if (is_unset(shape)) shape := [];
       its.convertRec.shape := dms.tovector(shape, 'integer');
#
       return defaultservers.run(its.agent, its.convertRec, F);
    }


###
    its.convertmanyRec := [_method="convertmany", _sequence=its.id._sequence]
    const public.convertmany := function (coordin, 
                                          absin=unset,
                                          dopplerin='radio',
                                          unitsin=unset, 
                                          absout=unset, 
                                          dopplerout='radio',
                                          unitsout=unset, 
                                          shape=unset)
    {
       wider its;
#
       its.convertmanyRec.coordin := coordin;
#
       if (is_unset(absin)) absin := array(T, public.naxes());
       its.convertmanyRec.absin := dms.tovector(absin, 'boolean');
#
       if (is_unset(absout)) absout := array(T, public.naxes());
       its.convertmanyRec.absout := dms.tovector(absout, 'boolean');
#
       its.convertmanyRec.dopplerin := as_string(dopplerin);
       its.convertmanyRec.dopplerout := as_string(dopplerout);
#
       if (is_unset(unitsin)) unitsin := public.units();
       its.convertmanyRec.unitsin := dms.tovector(unitsin, 'string');
       if (is_unset(unitsout)) unitsout := public.units();
       its.convertmanyRec.unitsout := dms.tovector(unitsout, 'string');
#
       if (is_unset(shape)) shape := [];
       its.convertmanyRec.shape := dms.tovector(shape, 'integer');
#
       return defaultservers.run(its.agent, its.convertmanyRec, F);
    }


###
    its.coordinatetypeRec := [_method="coordinatetype", _sequence=its.id._sequence]
    const public.coordinatetype := function(which=unset)
    {
       wider its;
       its.coordinatetypeRec.which := which;
       if (is_unset(which)) its.coordinatetypeRec.which := -1;
       return defaultservers.run(its.agent, its.coordinatetypeRec, F);
    }
    const public.ct := public.coordinatetype;


###
    const public.copy := function ()
    {
       cs := coordsys();
       if (is_fail(cs)) fail;
       r := public.torecord();
       if (is_fail(r)) fail;
       ok := cs.fromrecord(r);
       if (is_fail(ok)) fail;
       return cs;
    }


###
    const public.done := function()
    {
        wider its, public;
        ok := defaultservers.done(its.agent, public.id());
        if (is_fail(ok)) fail;
        val its := F;
        val public := F;
        return ok;
    }

###
    its.epochRec := [_method="epoch", _sequence=its.id._sequence]
    const public.epoch := function()
    {
       return defaultservers.run(its.agent, its.epochRec, F);
    }
    const public.e := public.epoch;


###
    its.findaxisRec := [_method="findaxis", _sequence=its.id._sequence]
    const public.findaxis := function(ref coordinate, ref axisincoordinate, world=T, axis=1)
    {
        wider its;
#   
        its.findaxisRec.axis := as_integer(axis);
        its.findaxisRec.world := as_boolean(world);
#
        id := defaultservers.run(its.agent, its.findaxisRec);
        if (is_fail(id)) {
           val coordinate := -1;
           val axisincoordinate := -1;
           fail;
        }
#
        val coordinate := its.findaxisRec.coordinate;
        val axisincoordinate := its.findaxisRec.axisincoordinate;
#
        return id;
    }
    const public.fa := public.findaxis;


###
    its.findcoordinateRec := [_method="findcoordinate", _sequence=its.id._sequence]
    const public.findcoordinate := function(ref pixel, ref world, type='direction', which=1)
    {
        wider its;
#   
        its.findcoordinateRec.type := type;
        its.findcoordinateRec.which := which;
#
        id := defaultservers.run(its.agent, its.findcoordinateRec);
        if (is_fail(id)) {
           val pixel := [];
           val world := [];
           fail;
        }
#
        val pixel := its.findcoordinateRec.pixel;
        val world := its.findcoordinateRec.world;
#
        return id;
    }
    const public.fc := public.findcoordinate;


###
    its.frequencytofrequencyRec := [_method="frequencytofrequency", _sequence=its.id._sequence]
    const public.frequencytofrequency := function(value, frequnit=unset, velocity, doppler='radio')
    {
        wider its;
        its.frequencytofrequencyRec.value := dms.tovector(value, 'double');
        if (is_unset(frequnit)) {
           its.frequencytofrequencyRec.frequnit := public.units('spectral');
           if (is_fail(its.frequencytofrequencyRec.frequnit)) fail;
        } else {
           its.frequencytofrequencyRec.frequnit := as_string(frequnit);
        }
        its.frequencytofrequencyRec.doppler := as_string(doppler);
        its.frequencytofrequencyRec.velocity := velocity;
#
        return defaultservers.run(its.agent, its.frequencytofrequencyRec);
    }
    const public.ftf := public.frequencytofrequency;


###
    its.frequencytovelocityRec := [_method="frequencytovelocity", _sequence=its.id._sequence]
    const public.frequencytovelocity := function(value, frequnit=unset, doppler='radio',
                                                 velunit='km/s')
    {
        wider its;
        its.frequencytovelocityRec.value := dms.tovector(value, 'double');
        if (is_unset(frequnit)) {
           its.frequencytovelocityRec.frequnit := public.units('spectral');
           if (is_fail(its.frequencytovelocityRec.frequnit)) fail;
        } else {
           its.frequencytovelocityRec.frequnit := as_string(frequnit);
        }
        its.frequencytovelocityRec.doppler := as_string(doppler);
        its.frequencytovelocityRec.velunit := as_string(velunit);
#
        return defaultservers.run(its.agent, its.frequencytovelocityRec);
    }
    const public.ftv := public.frequencytovelocity;


###
    its.fromrecordRec := [_method="fromrecord", _sequence=its.id._sequence]
    const public.fromrecord := function(record)
    {
        wider its;
        if (is_record(record)) {
           if (length(record)>0) {
              its.fromrecordRec.record := record;
           } else {
              return throw ('Record is empty', origin='coordsys.fromrecord');
           }
        } else {
           return throw ('Argument is not a record', origin='coordsys.fromrecord');
        }
        return defaultservers.run(its.agent, its.fromrecordRec, F);
    }


###
    const public.id := function()
    {
        wider its;
        if (!has_field(its.id, 'objectid')) {
#
# Add an objectid if necessary. This can happen if the object
# is the result of a method instead of a constructor, 
#
            id := its.id;
            id.objectid := [sequence=id._sequence,pid=id._pid,time=id._time,
                            host=id._host];
            its.id := id;
    
        }
        return its.id.objectid;
    }

###
    its.incrementRec := [_method="increment", _sequence=its.id._sequence]
    const public.increment := function(format='n', type=unset)
    {
        wider its;
#
        local wa := unset;
        local pa := unset;
        if (is_unset(type)) {
           type := '';
        } else { 
          ok := public.findcoordinate (pa, wa, type, 1);
          if (is_fail(ok)) fail;
          if (!ok) { 
             msg := spaste ('A coordinate of type ', type, ' does not exist');
             return throw (msg, origin='coordsys.increment');
          }
        }
        its.incrementRec.type := type;
#
# Paste so I can use 'check' in meta  file which results in an array
#
        its.incrementRec.format := spaste(format);
#
        rv := defaultservers.run(its.agent, its.incrementRec, F);
        if (is_fail(rv)) fail;
        rv2 := its.recordToCoordinateValue(rv);
#
        rv2::pw_type := 'world';
        rv2::ar_type := 'absolute';
#
        return rv2;
    }
    const public.i := public.increment;


###
    its.lineartransformRec := [_method="lineartransform", _sequence=its.id._sequence]
    const public.lineartransform := function(type)
    {
        wider its;
#
        its.lineartransformRec.type := type;
        return defaultservers.run(its.agent, its.lineartransformRec, F);
    }
    const public.lt := public.lineartransform;


###
    its.namesRec := [_method="names", _sequence=its.id._sequence]
    const public.names := function(type=unset)
    {
        wider its;
        names := defaultservers.run(its.agent, its.namesRec, F);
#
        if (is_unset(type)) {
           return names;
        } else {
           local pa, wa;
           ok := public.findcoordinate (pa, wa, type, 1);
           if (is_fail(ok)) fail;
           if (!ok) { 
              msg := spaste ('A coordinate of type ', type, ' does not exist');
              return throw (msg, origin='coordsys.names');
           }
           return names[pa];        
        }
    }

###
    its.naxesRec := [_method="naxes", _sequence=its.id._sequence]
    const public.naxes := function (world=T)
    {
        wider its;
        its.naxesRec.world := as_boolean(world);
        return defaultservers.run(its.agent, its.naxesRec, F);
    }

###
    its.ncoordinatesRec := [_method="ncoordinates", _sequence=its.id._sequence]
    const public.ncoordinates := function()
    {
        wider its;
        return defaultservers.run(its.agent, its.ncoordinatesRec, F);
    }
    const public.nc := public.ncoordinates;

###
    its.observerRec := [_method="observer", _sequence=its.id._sequence]
    const public.observer := function()
    {
        wider its;
        return defaultservers.run(its.agent, its.observerRec, F);
    }

###
    its.parentnameRec := [_method="parentname", _sequence=its.id._sequence]
    const public.parentname := function()
    {
        wider its;
        return defaultservers.run(its.agent, its.parentnameRec, F);
    }

###
    its.projectionRec := [_method="projection", _sequence=its.id._sequence]
    const public.projection := function(type=unset)
    {
        wider its;
        its.projectionRec.type := type;
        if (is_unset(type)) its.projectionRec.type := '';
        rec := defaultservers.run(its.agent, its.projectionRec, F);
        if (is_unset(type)) {
          return rec;
        } else { 
          if (has_field(rec, 'all')) {
             return rec.types;
          } else {
             return rec.nparameters;
          }
        }
    }
    const public.p := public.projection;


###
    its.referencecodeRec := [_method="referencecode", _sequence=its.id._sequence]
    const public.referencecode := function(type=unset, list=F)
    {
       wider its;
#
       if (!is_unset(type) && list==T) {
          type := to_upper(type);
          if (type~m/DI/) {
             d := dm.direction('J2000');
             return dm.listcodes(d);
          } else if (type~m/SP/) {
             d := dm.frequency('LSRK');
             return dm.listcodes(d);
          } else {
             return [=];
          }
       } else {
          if (is_unset(type)) {
             its.referencecodeRec.type := '';
          } else {
             its.referencecodeRec.type := dms.tovector(type, 'string');
          }
          return defaultservers.run(its.agent, its.referencecodeRec, F);
       }
    }
    const public.rc := public.referencecode;
 
###
    its.referencepixelRec := [_method="referencepixel", _sequence=its.id._sequence]
    const public.referencepixel := function(type=unset)
    {
        wider its;
        rp := defaultservers.run(its.agent, its.referencepixelRec, F);
#
        rp::pw_type := 'pixel';
        rp::ar_type := 'absolute';
#
        if (is_unset(type)) {
           return rp;
        } else {
           local pa, wa;
           ok := public.findcoordinate (pa, wa, type, 1);
           if (is_fail(ok)) fail;
           if (!ok) { 
              msg := spaste ('A coordinate of type ', type, ' does not exist');
              return throw (msg, origin='coordsys.referencepixel');
           }
           return rp[pa];        
        }
    }
    const public.rp := public.referencepixel;

###
    its.referencevalueRec := [_method="referencevalue", _sequence=its.id._sequence]
    const public.referencevalue := function(format='n', type=unset)
    {
        wider its;
#
        local wa := unset;
        local pa := unset;
        if (is_unset(type)) {
           type := '';
        } else { 
          ok := public.findcoordinate (pa, wa, type, 1);
          if (is_fail(ok)) fail;
          if (!ok) { 
             msg := spaste ('A coordinate of type ', type, ' does not exist');
             return throw (msg, origin='coordsys.referencevalue');
          }
        }
        its.referencevalueRec.type := type;
#
# Paste so I can use 'check' in meta  file which results in an array
#
        its.referencevalueRec.format := spaste(format);
#
        rv := defaultservers.run(its.agent, its.referencevalueRec, F);
        if (is_fail(rv)) fail;
        rv2 := its.recordToCoordinateValue(rv);
#
        rv2::pw_type := 'world';
        rv2::ar_type := 'absolute';
#
        return rv2;
    }
    const public.rv := public.referencevalue;


###
    its.reorderRec := [_method="reorder", _sequence=its.id._sequence]
    const public.reorder := function(order)
    {
        wider its;
        its.reorderRec.order := dms.tovector(order, 'integer');
        if (is_fail(its.reorderRec.order)) fail;
        return defaultservers.run(its.agent, its.reorderRec, F);
    }

###
    its.replaceRec := [_method="replace", _sequence=its.id._sequence]
    const public.replace := function(csys, whichin, whichout)
    {
        wider its;
#
        its.replaceRec.csys := csys.torecord();
        if (is_fail(its.replaceRec.csys)) ok := F;
        its.replaceRec.in := as_integer(whichin);
        its.replaceRec.out := as_integer(whichout);
#
        return defaultservers.run(its.agent, its.replaceRec, F);
    }

###
    its.restfrequencyRec := [_method="restfrequency", _sequence=its.id._sequence]
    const public.restfrequency := function()
    {
        wider its;
        return defaultservers.run(its.agent, its.restfrequencyRec, F);
    }
    const public.rf := public.restfrequency;

###
    its.setconversiontypeRec := [_method="setconversiontype", _sequence=its.id._sequence]
    const public.setconversiontype := function (direction=unset, spectral=unset)
    {
        wider its;
#
        if (is_unset(direction)) direction := '';
        its.setconversiontypeRec.direction := direction;
#
        if (is_unset(spectral)) spectral := '';
        its.setconversiontypeRec.spectral := spectral;
#
        return defaultservers.run(its.agent, its.setconversiontypeRec, F);
    }
    const public.sct := public.setconversiontype;

###
    its.setdirectionRec := [_method="setdirection", _sequence=its.id._sequence]
    const public.setdirection := function (refcode=unset, proj=unset, projpar=unset,
                                           refpix=unset, refval=unset,
                                           incr=unset, xform=unset, poles=unset)
    {
       wider its;
#
       its.setdirectionRec.ref := refcode;
       if (is_unset(refcode)) {
          its.setdirectionRec.ref := public.referencecode(type='direction');
          if (is_fail(its.setdirectionRec.ref)) fail;
       }
#
       pp := public.projection();
       if (is_fail(pp)) fail;
#
       its.setdirectionRec.proj := proj;
       if (is_unset(proj)) {
          its.setdirectionRec.proj := pp.type;
       }
       its.setdirectionRec.projpar := projpar;
       if (is_unset(projpar)) {
          its.setdirectionRec.projpar := pp.parameters;
       }
#
       its.setdirectionRec.refpix := refpix;
       if (is_unset(refpix)) {
          its.setdirectionRec.refpix := public.referencepixel (type='direction');
          if (is_fail(its.setdirectionRec.refpix)) fail;
       }
#
       rv := refval;
       if (is_unset(refval)) {
          rv := public.referencevalue (format='q', type='direction');
          if (is_fail(rv)) fail;
       }
       its.setdirectionRec.refval := 
           its.coordinateValueToRecord (value=rv, isWorld=T, isAbs=T, first=T);
        if (is_fail(its.setdirectionRec.refval)) fail;
#
       rv := incr;
       if (is_unset(incr)) {
          rv := public.increment (format='q', type='direction');
          if (is_fail(rv)) fail;
       }
       its.setdirectionRec.incr := 
           its.coordinateValueToRecord (value=rv, isWorld=T, isAbs=T, first=T);
        if (is_fail(its.setdirectionRec.incr)) fail;
#
       rv := poles;
       if (is_unset(poles)) {
          its.setdirectionRec.poles := dq.quantity([999.0, 999.0], 'deg');
       }
       its.setdirectionRec.poles := 
              its.coordinateValueToRecord (value=rv, isWorld=T, isAbs=T, first=T);
       if (is_fail(its.setdirectionRec.poles)) fail;
#
       its.setdirectionRec.xform := xform;
       if (is_unset(xform)) {
         xf := array(0.0, 2, 2);
         xf[1,1] := 1.0;
         xf[2,2] := 1.0;
         its.setdirectionRec.xform := xf;
       }
       return defaultservers.run(its.agent, its.setdirectionRec, F);
    }

###
    its.setepochRec := [_method="setepoch", _sequence=its.id._sequence]
    const public.setepoch := function (value)
    {
        wider its;
        if (!is_measure(value)) {
           return throw ('value is not a measure', origin='coordsys.setepoch');
        }
        its.setepochRec.value := value;
        return defaultservers.run(its.agent, its.setepochRec, F);
    }
    const public.se := public.setepoch;

###
    its.setincrementRec := [_method="setincrement", _sequence=its.id._sequence]
    const public.setincrement := function (value, type=unset)
    {
        wider its;
#         
        if (is_unset(type)) {
           its.setincrementRec.type := '';
        } else {
           its.setincrementRec.type := as_string(type);
        }
#
        isWorld := its.isValueWorld (value, shouldBeWorld=T, verbose=F);
        if (is_fail(isWorld)) fail;
#
        if (is_fail(its.checkAbsRel (value=value, shouldBeAbs=T))) fail;
#
        its.setincrementRec.value := 
           its.coordinateValueToRecord (value=value, isWorld=isWorld,
                                        isAbs=T, first=T);
        if (is_fail(its.setincrementRec.value)) fail;
#
        return defaultservers.run(its.agent, its.setincrementRec, F);
    }
    const public.si := public.setincrement;

###
    its.setlineartransformRec := [_method="setlineartransform", _sequence=its.id._sequence]
    const public.setlineartransform := function (value, type)
    {
        wider its;
#
        its.setlineartransformRec.type := as_string(type);
        its.setlineartransformRec.value := value;
#
        return defaultservers.run(its.agent, its.setlineartransformRec, F);
    }
    const public.slt  := public.setlineartransform;

###
    its.setnamesRec := [_method="setnames", _sequence=its.id._sequence]
    const public.setnames := function (value, type=unset)
    {
        wider its;
        its.setnamesRec.type := type;
        if (is_unset(type)) its.setnamesRec.type := '';
        its.setnamesRec.value := dms.tovector(value, 'string')
        return defaultservers.run(its.agent, its.setnamesRec, F);
    }
    const public.sn  := public.setnames;


###
    its.setobserverRec := [_method="setobserver", _sequence=its.id._sequence]
    const public.setobserver := function (value)
    {
        wider its;
        its.setobserverRec.value := as_string(value);
        return defaultservers.run(its.agent, its.setobserverRec, F);
    }
    const public.so  := public.setobserver;

###
    its.setparentnameRec := [_method="setparentname", _sequence=its.id._sequence]
    const public.setparentname := function (value)
    {
        wider its;
        its.setparentnameRec.value := as_string(value);
        return defaultservers.run(its.agent, its.setparentnameRec, F);
    }

###
    its.setprojectionRec := [_method="setprojection", _sequence=its.id._sequence]
    const public.setprojection := function(type, parameters=[])
    {
        wider its;
        its.setprojectionRec.type := type;
        its.setprojectionRec.parameters := dms.tovector(parameters, 'double');
        return defaultservers.run(its.agent, its.setprojectionRec, F);
    }
    const public.sp := public.setprojection;


###
    its.setreferencecodeRec := [_method="setreferencecode", _sequence=its.id._sequence]
    const public.setreferencecode := function (value, type, adjust=T)
    {
       wider its;
       its.setreferencecodeRec.type := as_string(type);
       its.setreferencecodeRec.value := as_string(value);
       its.setreferencecodeRec.adjust := as_boolean(adjust);
#
       return defaultservers.run(its.agent, its.setreferencecodeRec, F);
    }
    const public.src := public.setreferencecode;
 
###
    const public.setreferencelocation := function (pixel=unset, world=unset, mask=unset)
    {

# Checks

       if (is_unset(pixel)) pixel := public.referencepixel();
       const nPixelAxes := public.naxes(world=F);
       if (length(pixel) != nPixelAxes) {
          msg := spaste ('pixel must be of length ', nPixelAxes);
          return throw (msg, origin='coordsys.setreferencelocation');
       }
       if (is_unset(mask)) mask := array(T,nPixelAxes);
       if (length(mask) != length(pixel)) {
          return throw ('shape and mask must be the same length', 
                         origin='coordsys.setreferencelocation');
       }

# Convert world to numeric world format, adding/trimming 
# missing/extra axes in the process

       p := public.topixel(value=world);
       if (is_fail(p)) fail;
       w := public.toworld(value=p, format='n');     
       if (is_fail(w)) fail;

# Eliminate Stokes and masked values

       p2w := public.axesmap(toworld=T);
       rp := public.referencepixel();
       if (is_fail(rp)) fail;
       rv := public.referencevalue(format='n');
       if (is_fail(rv)) fail;
       types := public.axiscoordinatetypes(world=F);
       if (is_fail(types)) fail;
       p := pixel;
#
       for (i in 1:nPixelAxes) {
          if (mask[i] && types[i]=='Stokes') {
             note ('Cannot change Stokes reference pixel, setting mask to F',
                   origin='coordsys.setreferencelocation', priority='WARN');
             mask[i] := F;
          }
#
          if (!mask[i]) {
             p[i] := rp[i];             
             w[p2w[i]] := rv[p2w[i]];
          }
       }

# Set new values

       ok := public.setreferencepixel(value=p);       
       if (is_fail(ok)) fail;
       ok := public.setreferencevalue(value=w);       
       return ok;
    }
    const public.srl := public.setreferencelocation;

###
    its.setreferencepixelRec := [_method="setreferencepixel", _sequence=its.id._sequence]
    const public.setreferencepixel := function (value, type=unset)
    {
        wider its;
        its.setreferencepixelRec.type := type;
        if (is_unset(type)) its.setreferencepixelRec.type := '';
        its.setreferencepixelRec.value := dms.tovector(value, 'double')
        return defaultservers.run(its.agent, its.setreferencepixelRec, F);
    }
    const public.srp  := public.setreferencepixel;


###
    its.setreferencevalueRec := [_method="setreferencevalue", _sequence=its.id._sequence]
    const public.setreferencevalue := function (value, type=unset)
    {
        wider its;
#         
        if (is_unset(type)) {
           its.setreferencevalueRec.type := '';
        } else {
           its.setreferencevalueRec.type := as_string(type);
        }
#
        isWorld := its.isValueWorld (value, shouldBeWorld=T, verbose=F);
        if (is_fail(isWorld)) fail;
#
        if (is_fail(its.checkAbsRel (value=value, shouldBeAbs=T))) fail;
#
        its.setreferencevalueRec.value := 
           its.coordinateValueToRecord (value=value, isWorld=isWorld,
                                        isAbs=T, first=T);
        if (is_fail(its.setreferencevalueRec.value)) fail;
#
        return defaultservers.run(its.agent, its.setreferencevalueRec, F);
    }
    const public.srv  := public.setreferencevalue;


###
    its.setrestfrequencyRec := [_method="setrestfrequency", _sequence=its.id._sequence]
    const public.setrestfrequency := function (value, which=1, append=F)
    {
        wider its;
#
        its.setrestfrequencyRec.value := its.checkFrequency(value);
        its.setrestfrequencyRec.which := as_integer(which);
        its.setrestfrequencyRec.append := as_boolean(append);
        return defaultservers.run(its.agent, its.setrestfrequencyRec, F);
    }
    const public.srf := public.setrestfrequency;

###
    its.setspectralRec := [_method="setspectral", _sequence=its.id._sequence]
    const public.setspectral := function (refcode=unset,
                                          restfreq=unset,  
                                          frequencies=unset,
                                          doppler=unset,
                                          velocities=unset)
    {
        wider its;
#
        none := T;
        if (is_unset(refcode)) {
           its.setspectralRec.ref := '';
        } else {
           its.setspectralRec.ref := as_string(refcode);
           none := F;
        }
#
        if (is_unset(doppler)) {
           its.setspectralRec.doppler := '';
        } else {
           its.setspectralRec.doppler := as_string(doppler);
           none := F;
        }
#
        if (is_unset(restfreq)) {
           its.setspectralRec.restfreq := dq.quantity(-1.0, 'GHz');
        } else {
           its.setspectralRec.restfreq := its.checkFrequency(restfreq);
           none := F;
        }
#
        if (!is_unset(velocities) && !is_unset(frequencies)) {
           return throw ('You cannot give both frequencies and velocities',
                         origin='coordsys.setspectral');
        }

# Use the wrong unit (e.g. GHz for velocity) to indicate we 
# are not setting this one.

        its.setspectralRec.dovelocity := F;
        its.setspectralRec.velocities := dq.quantity('1km/s');
        if (!is_unset(velocities)) {
           its.setspectralRec.velocities := velocities;
           its.setspectralRec.dovelocity := T;
           none := F;
        }
#
        its.setspectralRec.dofrequency := F;
        its.setspectralRec.frequencies := dq.quantity('1GHz');
        if (!is_unset(frequencies)) {
           its.setspectralRec.frequencies := frequencies;
           its.setspectralRec.dofrequency := T;
           none := F;
        }
#
        if (none) {
           note('Nothing to do', priority='WARN', 
                origin='coordsys.setspectral');
           return T;
        }
#
        return defaultservers.run(its.agent, its.setspectralRec, F);
    }

###
    its.setstokesRec := [_method="setstokes", _sequence=its.id._sequence]
    const public.setstokes := function (stokes)
    {
        wider its;
        its.setstokesRec.value := dms.tovector(stokes, 'string')
        return defaultservers.run(its.agent, its.setstokesRec, F);
    }
    const public.ss := public.setstokes;

###
    its.settabularRec := [_method="settabular", _sequence=its.id._sequence]
    const public.settabular := function (pixel=unset, world=unset, which=1)
    {
        wider its;
        if (is_unset(pixel) && is_unset(world)) {     
           return throw ('Nothing to do', origin='coordsys.settabular');
        }
#
        if (is_unset(pixel)) {
           its.settabularRec.pixel := [];
        } else {
           its.settabularRec.pixel := as_double(pixel);
        }
#
        if (is_unset(world)) {
           its.settabularRec.world := [];
        } else {
           its.settabularRec.world := as_double(world);
        }
#
        its.settabularRec.which := as_integer(which);
#
        return defaultservers.run(its.agent, its.settabularRec, F);
    }

###
    its.settelescopeRec := [_method="settelescope", _sequence=its.id._sequence]
    const public.settelescope := function (value)
    {
        wider its;
        its.settelescopeRec.value := as_string(value);
        return defaultservers.run(its.agent, its.settelescopeRec, F);
    }
    const public.st := public.settelescope;

###
    its.stokesRec := [_method="stokes", _sequence=its.id._sequence]
    const public.stokes := function ()
    {
        return defaultservers.run(its.agent, its.stokesRec, F);
    }


###
    its.setunitsRec := [_method="setunits", _sequence=its.id._sequence]
    const public.setunits := function (value, type=unset, overwrite=F, which=unset)
    {
        wider its;
        its.setunitsRec.type := type;
        if (is_unset(type)) its.setunitsRec.type := '';
        its.setunitsRec.value := dms.tovector(value, 'string')
        its.setunitsRec.overwrite := as_boolean(overwrite);
#
        its.setunitsRec.which := which;
        if (is_unset(which)) its.setunitsRec.which := -10;
        return defaultservers.run(its.agent, its.setunitsRec, F);
    }
    const public.su := public.setunits;


###
    its.summaryRec := [_method="summary", _sequence=its.id._sequence]
    const public.summary := function (doppler="radio", list=T)
    {
        wider its;
        its.summaryRec.velocity := as_string(doppler);
        its.summaryRec.list := as_boolean(list);
        ret := defaultservers.run(its.agent, its.summaryRec, F);
        if (!is_boolean(ret)) {
          if (length(ret)==0) return T;
#
          return split(ret, '\n');
        } 
        return ret;
    }
    const public.s := public.summary;

###
    its.telescopeRec := [_method="telescope", _sequence=its.id._sequence]
    const public.telescope := function(measure=F)
    {
        wider its;
        t := defaultservers.run(its.agent, its.telescopeRec, F);
        if (measure) {
           return dm.observatory(t);
        } else {
           return t;
        }
    }
    const public.t := public.telescope;

###
    its.torecordRec := [_method="torecord", _sequence=its.id._sequence]
    const public.torecord := function()
    {
        wider its;
        return defaultservers.run(its.agent, its.torecordRec, F);
    }


###
    its.toAbsRec := [_method="toabs", _sequence=its.id._sequence]
    const public.toabs := function (value, isworld=unset)
    {
        wider its;
#
        its.toAbsRec.isworld := its.isValueWorld (value, shouldBeWorld=isworld, verbose=T);
        if (is_fail(its.toAbsRec.isworld)) fail;
#
        if (is_fail(its.checkAbsRel (value=value, shouldBeAbs=F))) fail;
#
        its.toAbsRec.value := 
               its.coordinateValueToRecord (value=value, isWorld=its.toAbsRec.isworld, 
                                            isAbs=F, first=F);
        if (is_fail(its.toAbsRec.value)) fail;
#
        rv := defaultservers.run(its.agent, its.toAbsRec, F);
        if (is_fail(rv)) fail;
#
        rv2 := its.recordToCoordinateValue(rv);
#
        if (its.toAbsRec.isworld) {
           rv2::pw_type := 'world';
        } else {
           rv2::pw_type := 'pixel';
        }
        rv2::ar_type := 'absolute';
#
        return rv2;
    }

###
    its.toAbsManyRec := [_method="toabsmany", _sequence=its.id._sequence]
    const public.toabsmany := function (value, isworld=unset)
    {
        wider its;
#
        its.toAbsManyRec.isworld := its.isValueWorld(value=value, shouldBeWorld=isworld, verbose=T);
        if (is_fail(its.toAbsManyRec.isworld)) fail;
#
        if (is_fail(its.checkAbsRel (value=value, shouldBeAbs=F))) fail;
#
        its.toAbsManyRec.value := value;
        rv := defaultservers.run(its.agent, its.toAbsManyRec, F);
        if (is_fail(rv)) fail;
#
        if (its.toAbsManyRec.isworld) {
           rv::pw_type := 'world';
        } else {
           rv::pw_type := 'pixel';
        }
        rv::ar_type := 'absolute';
#
        return rv;
    }


###
    its.toRelRec := [_method="torel", _sequence=its.id._sequence]
    const public.torel := function (value, isworld=unset)
    {
        wider its;
#
        its.toRelRec.isworld := its.isValueWorld (value, shouldBeWorld=isworld, verbose=T);
        if (is_fail(its.toRelRec.isworld)) fail;
#
        if (is_fail(its.checkAbsRel (value=value, shouldBeAbs=T))) fail;
#
        its.toRelRec.value  := its.coordinateValueToRecord (value=value, isWorld=its.toRelRec.isworld,
                                                            isAbs=T, first=F);
        if (is_fail(its.toRelRec)) fail;
#
        rv := defaultservers.run(its.agent, its.toRelRec, F);
        if (is_fail(rv)) fail;
#
        rv2 := its.recordToCoordinateValue(rv);
#
        if (its.toRelRec.isworld) {
           rv2::pw_type := 'world';
        } else {
           rv2::pw_type := 'pixel';

        }
        rv2::ar_type := 'relative';
#
        return rv2;
    }

###
    its.toRelManyRec := [_method="torelmany", _sequence=its.id._sequence]
    const public.torelmany := function (value, isworld=unset)
    {
        wider its;
#
        its.toRelManyRec.isworld := its.isValueWorld (value=value, shouldBeWorld=isworld, verbose=T);
        if (is_fail(its.toRelManyRec.isworld)) fail;
#
        if (is_fail(its.checkAbsRel (value=value, shouldBeAbs=T))) fail;
        its.toRelManyRec.value := value;
#
        rv := defaultservers.run(its.agent, its.toRelManyRec, F);
        if (is_fail(rv)) fail;
#
        if (its.toRelManyRec.isworld) {
           rv::pw_type := 'world';
        } else {
           rv::pw_type := 'pixel';
        }
        rv::ar_type := 'relative';
#
        return rv;
    }

###
    its.toPixelRec := [_method="topixel", _sequence=its.id._sequence]
    const public.topixel := function (value=unset)
    {
        wider its;
#
        isWorld := its.isValueWorld (value=value, shouldBeWorld=T, verbose=F);
        if (is_fail(isWorld)) fail;
        if (is_fail(its.checkAbsRel (value=value, shouldBeAbs=T))) fail;
#
        its.toPixelRec.world := 
           its.coordinateValueToRecord (value=value, isWorld=isWorld,
                                        isAbs=T, first=T);
        if (is_fail(its.toPixelRec.world)) fail;
#
        rv := defaultservers.run(its.agent, its.toPixelRec, F);
#
        rv::pw_type := 'pixel';
        rv::ar_type := 'absolute';
        return rv;
    }

###
    its.toPixelManyRec := [_method="topixelmany", _sequence=its.id._sequence]
    const public.topixelmany := function (value)
    {
        wider its;
#
        if (is_fail(its.isValueWorld (value=value, shouldBeWorld=T, verbose=F))) fail;
        if (is_fail(its.checkAbsRel (value=value, shouldBeAbs=T))) fail;
        its.toPixelManyRec.world := value;
#
        rv := defaultservers.run(its.agent, its.toPixelManyRec, F);
#
        rv::pw_type := 'pixel';
        rv::ar_type := 'absolute';
        return rv;
    }



###
    its.toWorldRec := [_method="toworld", _sequence=its.id._sequence]
    const public.toworld := function (value=unset, format='n')
    {
        wider its;
#
        isWorld := its.isValueWorld (value, shouldBeWorld=F, verbose=F);
        if (is_fail(isWorld)) fail;
#
        if (is_fail(its.checkAbsRel (value=value, shouldBeAbs=T))) fail;
#
        rec := its.coordinateValueToRecord (value=value, isWorld=isWorld,
                                            isAbs=T, first=T);
        if (is_fail(rec)) fail;
        if (has_field(rec, 'numeric')) {
           its.toWorldRec.pixel := rec.numeric;
        } else {
           return throw ('Catastrophic internal error', origin='coordsys.toworld');
        }
#
# Paste so I can use 'check' in meta which results in an array
#
        its.toWorldRec.format := spaste(format);
#
        rv := defaultservers.run(its.agent, its.toWorldRec, F);
        if (is_fail(rv)) fail;
        rv2 := its.recordToCoordinateValue(rv);
#
        rv2::pw_type := 'world';
        rv2::ar_type := 'absolute';
#
        return rv2;
    }

###
    its.toWorldManyRec := [_method="toworldmany", _sequence=its.id._sequence]
    const public.toworldmany := function (value)
    {
        wider its;
#
        if (is_fail(its.isValueWorld (value=value, shouldBeWorld=F, verbose=F))) fail;
        if (is_fail(its.checkAbsRel (value=value, shouldBeAbs=T))) fail;
#
        its.toWorldManyRec.pixel := value;
        rv := defaultservers.run(its.agent, its.toWorldManyRec, F);
        if (is_fail(rv)) fail;
#
        rv::pw_type := 'world';
        rv::ar_type := 'absolute';
#
        return rv;
    }

###
    const public.type := function ()
    {
       return 'coordsys';
    }

###
    its.unitsRec := [_method="units", _sequence=its.id._sequence]
    const public.units := function(type=unset)
    {
        wider its;
        units := defaultservers.run(its.agent, its.unitsRec, F);
#
        if (is_unset(type)) {
           return units;
        } else {
           local pa, wa;
           ok := public.findcoordinate (pa, wa, type, 1);
           if (is_fail(ok)) fail;
           if (!ok) { 
              msg := spaste ('A coordinate of type ', type, ' does not exist');
              return throw (msg, origin='coordsys.units');
           }
           return units[pa];        
        }
    }
    const public.u := public.units;

###
    its.velocitytofrequencyRec := [_method="velocitytofrequency", _sequence=its.id._sequence]
    const public.velocitytofrequency := function(value, frequnit=unset, doppler='radio',
                                                 velunit='km/s')
    {
        wider its;
        its.velocitytofrequencyRec.value := dms.tovector(value, 'double');
        if (is_unset(frequnit)) {
           its.velocitytofrequencyRec.frequnit := public.units('spectral');
           if (is_fail(its.velocitytofrequencyRec.frequnit)) fail;
        } else {
           its.velocitytofrequencyRec.frequnit := as_string(frequnit);
        }
        its.velocitytofrequencyRec.doppler := as_string(doppler);
        its.velocitytofrequencyRec.velunit := as_string(velunit);
#
        return defaultservers.run(its.agent, its.velocitytofrequencyRec);
    }
    const public.vtf := public.velocitytofrequency;


###
    plugins.attach('coordsys', public);
    return ref public;
} # _define_coordsys()



###  Constructors

const coordsys := function (direction=F, spectral=F, stokes="", linear=0,
                            tabular=F, host='', forcenewserver=F)
{
   agent := defaultservers.activate(server='app_image', host=host, 
                                    forcenewserver=forcenewserver, async=F,
                                    terminateonempty=F);
#
   rec := [=];
   rec.direction := as_boolean(direction);
#
   if (length(stokes)==0) stokes := "";             # Need zero length vector
   if (length(stokes)==1 && (stokes[1]=='' || stokes[1]==' ')) stokes := "";     # For toolamanager poblems
   rec.stokes := dms.tovector(stokes, 'string')
#
   rec.spectral := as_boolean(spectral);
#
   rec.linear := as_integer(linear);
   rec.tabular := as_boolean(tabular);
   id := defaultservers.create(id=agent, type='coordsys', 
                               creator='coordsys',
                               invokerecord=rec);
   if (is_fail(id)) fail;
   ok := ref _define_coordsys(agent,id);
   return ok;
}
