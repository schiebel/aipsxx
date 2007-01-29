# coordsyssupport.g: Support functions for coordsys and image tools
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
#   $Id: coordsyssupport.g,v 19.2 2004/08/25 00:56:21 cvsmgr Exp $
#

pragma include once

include 'misc.g'
include 'serverexists.g'
include 'quanta.g'
include 'note.g'

const coordsyssupport := subsequence ()
{
    if (!serverexists('dms', 'misc', dms)) {
       return throw('The misc server "dms" is not running',
                     origin='coordsyssupport.g');
    }
    if (!serverexists('dq', 'quanta', dq)) {
       return throw('The quanta server "dq" is not running',
                     origin='coordsyssupport.g');
    }
#
    its := [=]


### Private methods

### Public methods

   const self.isquantumvector := function (q)
#
# True for single quantum 
#
   {
      return is_quantity(q) && 
             has_field(q, 'value') &&
             has_field(q, 'unit') &&
             length(q.unit)==1;
   }

###
   const self.isvectorquantum := function (q)
#
#  False for single quantum 
#  False for quantum of vector
#  True otherwise
#
   {
      return is_quantity(q) && !has_field(q, 'value') &&
             !has_field(q, 'unit');
   }

###
   const self.lengthofquantum := function (q)
#
# Single quantum     - returns 1
# Vector of quantum  - returns length of vector
# Quantum of vector  - returns length of value vector
#
   {
      if (self.isquantumvector(q)) {              # T for single quantum
         return length(q.value);
      } else if (self.isvectorquantum(q)) {
         return length(q);
      } else {
         return throw('Variable is not a quantum',
                      origin='coordsyssupport.lengthofquantum');
      }
   }


###
   const self.valuetoquantum := function (value, unit=unset, orig=T)
#
# Convert a value to a quantum or quantum vector.  does not handle
# vector of quantum.  the inputs are not checked exhaustively 
# so you have to call this with known correct inputs
#
# Input:
#   value   Quantum - returned directly (could be any kind)
#           Numeric - 1
#           vector numeric [1,2,3]
#           string holding numeric  '1' "2"
#           string holding vector numeric  '1 2 3' or "1 2 3"
#           string holding quantum '1km'
#   unit    Unit to use when value is not a quantum (or string holding quantum)
#   orig    If 'value' is a complete quantum string, add orig field
#
   {
      local q;
      if (is_quantity(value)) {
         q := value;
      } else {
         more := T;
         if (is_string(value)) {
            q := dq.quantity(value);
            if (!is_fail(q)) {
               ok := self.isquantumvector(q);
               if (is_fail(ok)) fail;
               if (ok && strlen(q.unit)>0) {

# Valid string (e.g. '1km')

                  more := F;
                  if (orig) q.orig := value;
               }
            }
         }
#
         if (more) {

# Needs units added. Value might be a string or numeric
# Can't add orig value under these conditions

            v := dms.tovector(value, 'double');
            if (is_fail(v)) fail;
            q := dq.quantity (v, unit);
         }
      }
#
      return q;
   }



###
   const self.valuetovectorquantum := function (value, unit=unset, 
                                                orig=T, singlevector=F)
#
# Convert a value which might be a double, string, vector of strings,
# or quantum and convert to a quantum or vector of quantities
# units give the units to go with the values
#
# Input
#   value   input
#   unit    can be a vector or single value (gets replicated)
#   singlevector
#           if T a single quantity is put into a vector of length 1
#           if F a single quantity is returned as a single quantity
#           This is used in passing information to the DO.  SOmetimes
#           a record holding the quantity is passed over (use T),
#           othertimes a Vector if quantityes is passed over (use F)
# Return:
#         quantum or vector of quantum
#
   {
      local q;
      if (is_quantity(value)) {
        n := self.lengthofquantum(value);       # 1 for single quantum, n for vector<q> or q<vector>
        if (is_fail(n)) fail;
#
        ok := self.isvectorquantum(value);     # F for single q, F for q<vec>, T for vec<q>
        if (is_fail(ok)) fail;
        if (ok) {  
          q := value;
        } else {
          if (n==1) {
             q := dq.quantity(dq.getvalue(value), dq.getunit(value));
          } else {
             q := r_array(dq.quantity(0.0,'m'), n, id='quant'); 
             for (i in 1:n) {
               q[i] := dq.quantity(dq.getvalue(value)[i], dq.getunit(value));
               if (is_fail(q[i])) fail;
             }
          }
        }
      } else {
         local v, u;
         hasUnits := F;
         nUnits := 0;
         if (!is_unset(unit)) {
            u := dms.tovector(unit, 'string');
            if (!is_fail(u)) {
               hasUnits := T;
               nUnits := length(u);
            }
         }
#
         if (is_string(value)) {
            v := dms.tovector(value, 'string');
            if (is_fail(v)) fail;
            n := length(v);
            if (n==0) fail 'No values in string';
#
# Add missing units and prepare vector quantum string e.g. "1km 2Hz"
#
            s := [''];
            for (i in 1:n) {
               qi := dq.quantity(v[i]);
               if (is_fail(qi)) fail;
               if (strlen(qi.unit)==0) {
                  if (hasUnits && (nUnits==1 || nUnits>=n)) {      
                     if (nUnits==1) {
                        qi.unit := u[1];
                     } else {
                        qi.unit := u[i];
                     }
                  } else {
                     fail 'Invalid number of units'
                  }
               }
               s[i] := spaste(qi.value, qi.unit);
            }
            q := dq.quantity(s);
            if (is_fail(q)) fail;
#
            if (orig) {
               n := self.lengthofquantum(q);
               if (is_fail(n)) fail;
               if (n==1) {
                  q.orig := s[1];
               } else {
                  for (i in 1:n) {
                     q[i].orig := s[i];
                  }
               }
            }
         } else {
#
# OK just a numeric vector.
#
            if (!hasUnits) fail 'Units not given';
#
            v := dms.tovector(value, 'double');
            if (is_fail(v)) fail;
            nValues := length(v);
            if (nValues==0) fail 'Zero length vector given';
            if (nUnits!=1 && nValues!=nUnits) fail 'Units is wrong length';
#
# Make vector of quantum 
#
            if (nValues==1) {
               q := dq.quantity(v, u);
               if (is_fail(q)) fail;
            } else {
               q := r_array(dq.quantity(0.0,'m'), nValues, id='quant');
               for (i in 1:nValues) {
                  if (nUnits==1) {
                     q[i] := dq.quantity(v[i], u[1]);
                  } else {
                     q[i] := dq.quantity(v[i], u[i]);
                  }
                  if (is_fail(q[i])) fail;
               }
            }
         }
      }
#
      n := self.lengthofquantum(q); 
      if (is_fail(n)) fail;
      if (singlevector && n==1) {
         q2 := [=];
         q2[1] := q;
         q := q2;
      }
#
      return q;
   }



###
   const self.vectorquantumtodouble := function (value) 
#
# Take a vector of quantities or quantum and return a vector
# of doubles discarding the units
# 
# Input:
#   value    Vector of quantum
# Return:
#            Vector double
#
   {
      if (!is_quantity(value)) fail 'Not a quantum';
#
      x := [];
      if (has_field(value, 'value') && has_field(value, 'unit')) {
         x[1] := value.value;
      } else {
         n := length(value);
         for (i in 1:n) x[i] := value[i].value;
      }
      return x;
   }


###
   const self.selectquantordouble := function (values, quant, worldaxes=unset)
#
# From the values variable, fish out the answer as a {vector} quantum 
# or double as requested
#
#   Input:
#      values     double or quantity for all world axes in CS
#                 May be a vector or a single thing
#      quant      T or F
#      worldaxes  Which world axes do you want the answer for ?
#   Return:
#                 The result
#
   {
      local v;
#
# Convert vector quantum or vector double
#
      if (quant) {
         v := values;
      } else {
         v := self.vectorquantumtodouble(values);
         if (is_fail(v)) fail;
      }
#
      if (is_unset(worldaxes)) {
#
# Return all
#
         return v;
      } else {
#
# User wants values for specific axes.    
#
        if (quant) {
           x := [];
           u := "";
           if (has_field(values::, 'shape') && values::shape>1) {
#
# Vector quantity.  Deconstruct into doubles.  Select the
# desired ones, and remake the vector (possibly) quantum
#
              n := length(values);
              for (i in 1:n) {
                 x[i] := values[i].value;
                 u[i] := values[i].unit;
              }
              x := x[worldaxes];
              u := u[worldaxes];
              return self.valuetovectorquantum (x, u);
           } else {
#
# The input values have shape=1.  Therefore there is only
# one thing to return, itself.
#
              return values;
           }
        } else {
#
# Just return selected doubles
#
           return v[worldaxes];
        }
      }
   }

###
   self.done := function ()
   {
      wider self, its;
      its := F;
      self := F;
      return T;
   }

###
   const self.type := function ()
   {
      return 'coordsyssupport';
   }

}
const defaultcoordsyssupport := coordsyssupport();
