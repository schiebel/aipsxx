# regionmanager.g: Manipulate AIPS++ Glish region objects.
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
#   $Id: regionmanager.g,v 19.3 2004/08/25 01:00:39 cvsmgr Exp $
#
 
pragma include once
include 'coordsyssupport.g'
include 'coordsys.g'
include 'itemcontainer.g'
include 'quanta.g'
include 'misc.g'
include 'note.g'
include 'serverexists.g'
include 'table.g'


const is_region:=function(const thing)
#
# Is this variable a valid region ?
#
{
   if (!is_itemcontainer(thing)) return F;
   if (!thing.has_item('isRegion')) return F;
   item := thing.get('isRegion');
   if (is_fail(item)) return F;
   return T;
}


const regionmanager := subsequence ()
{
   if (!serverexists('dq', 'quanta', dq)) {
      return throw('The quanta server "dq" is either not running or not valid', 
                    origin='regionmanager.g');
   }
   if (!serverexists('dms', 'misc', dms)) {
      return throw('The misc server "dms" is either not running or not valid', 
                    origin='regionmanager.g');
   }
   if (!serverexists('defaultcoordsyssupport', 'coordsyssupport', defaultcoordsyssupport)) {
      return throw('The coordsyssupport server "defaultcoordsyssupport" is not running',
                   origin='regionmanager.g');
   }
#
   private := [=];
   private.default := -2147483646;
   private.guiDone := F;
   private.verbose := T;
   private.selectcallback  := 0;
   private.coordinatestool := unset;         # Coordinate SYstem tool
   private.coordinates := unset;             # and its naked record
# 
   dq.define('pix', "100%");
   dq.define('frac', "100%");
   dq.define('def', "100%");
   dq.define('default', "100%");
#
# The rest of the constructor is at the end of the file
# so it can use regionmanager.g methods 

#------------------------------------------------------------------------
# Private functions 


###
const private.absrel_value := function(const absreltype)
#
# The coordinates of regions come in some different flavours
# 
#  Type       Value 
#  -------------------
#  abs         1
#  relref      2
#  relcen      3  
#  reldir      4
#
{
   if (!is_string(absreltype)) {
      return throw ('Argument must be a string', origin='regionmanager.absrel_value');
   }
   tmp := to_upper(absreltype);
   if (tmp == 'ABS') {
      return as_integer(1);
   } else if (tmp == 'RELREF') {
      return as_integer(2);
   } else if (tmp == 'RELCEN') {
      return as_integer(3);
#   } else if (tmp == 'RELDIR') {
#      return as_integer(4);
   } else {
      msg := spaste ('Unrecognized absrel type (', absreltype, 
                     ') - choose from "abs", "relref", "relcen"');
      return throw (msg, origin='regionmanager.absrel_value');
   }
}

###
const private.extractsimpleregions := function (ref recout, recin)
{
   if (!is_record(recin)) {
      return throw ('Input is not a record', origin='regionmanager.findregions');
   }
#
   if (has_field(recin, 'regions')) {
      if (!has_field(recin.regions, 'nr')) {
         return throw ('The "regions" record does not contain the "nr" field',
                       origin='regionmanager.extractsimpleregions');
      }
#
      nr := recin.regions.nr;
      for (i in 1:nr) {
         fn := spaste('r', i);
         ok := private.extractsimpleregions(recout, recin.regions[fn]);
         if (is_fail(ok)) fail;
      }
   } else if (has_field(recin, 'name')) {
      if (private.issimple(recin.name)) {
         idx := length(recout) + 1;
         val recout[idx] := recin;
      } else {
         return throw ('Internal logic error', 
                       origin='regionmanager.extractsimpleregions');
      }
   }
#
  return T;
}

###
const private.find_regions := function (ref comment, ref nRegions, 
                                        const nMinRegions, ...) 
{
   val nRegions := 0;
   val comment := '';
   lrec := [=];
   commentIdx := 0;
#
   nArgs := num_args(...);
   j := 0;
   if (nArgs > 0) {
      first := nth_arg(1, ...);
      local second;
      if (nArgs>1) second := nth_arg(2, ...);
#
      if ( (nArgs==1 && is_record(first) && is_region(first[1])) ||
           (nArgs==2 && is_record(first) && is_region(first[1]) && is_string(second)) ||
           (nArgs==2 && is_record(second) && is_region(second[1]) && is_string(first)) ) {

# The '...' is one or two arguments.  A record (holding 1 or more regions) and 
# an optional comment string

         for (i in 1:nArgs) {
            if (is_string(nth_arg(i, ...))) {
               if (commentIdx != 0) {
                  return throw('You can only give one comment', 
                                origin='regionmanager.find_regions');
               }
#
               val comment := nth_arg(i, ...);
               commentIdx := i;
            } else {
               thing := nth_arg(i, ...);
               val nRegions := length(thing);
               for (j in 1:nRegions) {
                  fn := spaste('r',j);
                  if (!is_region(thing[j])) {
                     msg := spaste('Given region # ', j, ' in record is not valid');
                     return throw(msg, origin='regionmanager.find_regions');
                  }
                  if (!self.isworldregion(thing[j])) {
                     msg := spaste('Given region # ', j, ' in record is not a world region');
                     return throw(msg, origin='regionmanager.find_regions');
                  }
                  lrec[fn] := thing[j].torecord();
               }
            }
         }
      } else {

# The '...' is a list of region tools

         for (i in 1:nArgs) {
            if (is_string(nth_arg(i, ...))) {
               if (commentIdx != 0) {
                  return throw('You can only give one comment', 
                                origin='regionmanager.find_regions');
               }
#
               val comment := nth_arg(i, ...);
               commentIdx := i;
            } else {
               j +:= 1;
               if (!is_region(nth_arg(i, ...))) {
                  msg := spaste('Given region # ', j, ' is not valid');
                  return throw(msg, origin='regionmanager.find_regions');
               }
               if (!self.isworldregion(nth_arg(i, ...))) {
                  msg := spaste('Given region # ', j, ' is not a world region');
                  return throw(msg, origin='regionmanager.find_regions');
               }
               fn := spaste('r', j);
               lrec[fn] := nth_arg(i, ...).torecord();
            }
         }
         val nRegions := j;
      }
   }
#
   if (nRegions < nMinRegions) {
      return throw ('You must give at least two regions',
                    origin='regionmanager.find_regions');
   }
#
   lrec.nr := as_integer(nRegions);
   return lrec;
}

###
const private.findString := function (list, item)
{
   const n := length(list);
   found := F;
   if (n > 0) {
      for (i in 1:n) {
         if (item==list[i]) {
            found := T;
            break;
         }
      }
   }
   return found;
}

###
const private.issimple := function (name)
#
# Figure out if this is a simple region. All
# others are compound, except maybe WCLELMASK 
# which i don't know what to do with.
#
{
   name2 := to_upper(name);
   return name2=='LCSLICER' || name2=='LCPOLYGON' ||
          name2=='WCBOX' || name2=='WCPOLYGON';
}

###
const private.make_array := function(ref vector)
#
# [1] is treated by Glish as a single Int, not
# as an array [1].  This means that it goes into
# the record structure as an Int not an ArrayInt and
# then the C++ classes fall over because they are
# looking for an ArrayInt record.  By setting the
# shape attribute, I convince Glish that this is
# truly an array
#
{
   vector::shape := length(vector);
}


const private.open_table := function (ref opened, const tablename, 
                                      const openNew=F, const readOnly=F)
{
   local t;
   val opened := F;
   if (is_table(tablename)) {
#
# Is a Glish table object
#
      if (!readOnly && !tablename.iswritable()) {
        msg := spaste('Given table "', tablename.name(), '" is not writable');
        return throw (msg, origin='regionmanager.open_table');
      }   
      t:= ref tablename;
   } else {
      include 'image.g';
#
      if (is_image(tablename)) {
#
# Is a Glish image object, which underneath is a table
#

         t := table(tablename.name(F), readonly=readOnly, ack=F);
         if (is_fail(t)) {
            msg := spaste('Could not open table of name "', tablename.name(), '"');
            return throw (msg, origin='regionmanager.open_table');
         }
         opened := T;
      } else if (is_string(tablename)) {

# Is just a string.  Maybe its the name of a table ?
#
         if (tableexists(tablename)) {
            t := table(tablename, readonly=readOnly, ack=F);
            if (is_fail(t)) {
               msg := spaste('Could not open table of name "', tablename, '"');
               return throw (msg, origin='regionmanager.open_table');
            }
            opened := T;
         } else {
            if (openNew) {
#
# Create new table
#
               c := tablecreatescalarcoldesc('c1',1);
               td := tablecreatedesc(c);     
               t := table(tablename, tabledesc=td, readonly=F, ack=F);
               if (is_fail(t)) {
                  msg := paste('Could not create new table of name', tablename);
                  return throw (msg, origin='regionmanager.open_table');
               }
               opened := T;
            } else {
               msg := paste('Table of given name does not exist');
               return throw (msg, origin='regionmanager.open_table');
            }
         }
      } else {
        msg := paste('Given table is neither a table',
                     'object nor a table name');
        return throw (msg, origin='regionmanager.open_table');
      }
   }
   return t;
}


const private.pixeltoworldbox := function (csys, imshape=unset, box)
{
#
# Can't handle strided boxes
#
   inc := box.get('inc');
   n := length(inc); 
   if (n>0) {
      for (i in 1:n) {
         if (inc[i]!=1) {
            return throw ('Cannot convert a strided pixel box to a world box',
                          origin='regionmanager.pixeltoworldbox');
         }
      }
   }
#
# Convert to absolute pixels
#
   blc := box.get('blc');
   fracblc := box.get('fracblc');
   arblc := box.get('arblc');
   if (length(blc)!=length(fracblc) ||
       length(blc)!=length(arblc)) {
      return throw('Inconsistent lengths for blc, fracblc & arblc fields',
                    origin='regionmanager.pixeltoworldbox');
   }
   trc := box.get('trc');
   fractrc := box.get('fractrc');
   artrc := box.get('artrc');
   if (length(trc)!=length(fractrc) ||
       length(trc)!=length(artrc)) {
      return throw('Inconsistent lengths for trc, fractrc & artrc fields',
                    origin='regionmanager.pixeltoworldbox');
   }
   oneRel := box.get('oneRel');
#
   refpix := csys.referencepixel();
   local cen, dimshape;
   if (!is_unset(imshape)) {
      cen := as_float(imshape)/2.0;
      dimshape := length(imshape);
   }
#
# Use the same algorithm as in LCSLicer C++ class.
# So make 0-relative until the end.
#
   off := 0;
   if (oneRel) off := -1;
   refpix +:= off;
#
   n := length(blc);   
   blc2 := [];
   if (n>0) {
     for (i in 1:n) {
        t := blc[i];
        if (t==self.def()) {
           blc2[i] := refpix[i];      # Will be set back to default later
        } else {
           if (fracblc[i]) {
              if (!is_unset(imshape)) {
                 if (i >= dimshape) {
                    return throw ('shape is not long enough for blc',
                               origin='regionmanager.pixeltoworldbox');
                 }
                 t *:= imshape[i];
              } else {
                 return throw ('You must supply the shape for fractional coordinates',
                               origin='regionmanager.pixeltoworldbox');
              }
           }
           ar := self.absreltype(arblc[i]);
           if (ar=='abs' && !fracblc[i]) {
              t := t + off;                 # Make 0 rel
           } else if (ar=='relref') {
              t +:= refpix[i];
           } else if (ar=='relcen') {
              t +:= cen[i];
           }
           blc2[i] := floor(t + 0.5);
        }
        blc2[i] -:= off;                    # Make 0 or 1 rel
     }
   }
#
   n := length(trc);   
   trc2 := [];
   if (n>0) {
     for (i in 1:n) {
        t := trc[i];
        if (t==self.def()) {
           trc2[i] := refpix[i];             # Will be set back to default later
        } else {
           if (fractrc[i]) {
              if (!is_unset(imshape)) {
                 if (i >= dimshape) {
                    return throw ('shape is not long enough for trc',
                               origin='regionmanager.pixeltoworldbox');
                 }
                 t := t * imshape[i];
                 t -:= 1.0;
              } else {
                 return throw ('You must supply the shape for fractional coordinates',
                               origin='regionmanager.pixeltoworldbox');
              }
           }
           ar := self.absreltype(artrc[i]);
           if (ar=='abs' && !fractrc[i]) {
              t := t + off;              # Make 0 rel
           } else if (ar=='relref') {
              t +:= refpix[i];
           } else if (ar=='relcen') {
              t +:= cen[i];
           }
           trc2[i] := floor(t + 0.5);
        }
        trc2[i] -:= off;                # Make 0 or 1 rel
     }
   }
#
# Convert absolute pixels to world.    toworld will
# add missing axes to pixel vectors
#
   wBlc2 := csys.toworld(blc2, 'n');
   if (is_fail(wBlc2)) fail;
   wTrc2 := csys.toworld(trc2, 'n');
   if (is_fail(wTrc2)) fail;
#
# These world vectors come out in WORLD axis order so we 
# must convert them to pixel axis order as that is 
# what the world box function  wants.  God I hate this.
# Perhaps I should abandon this madness...
# Every pixel axis has a world axis
#
   p2w := csys.axesmap(toworld=T);
   wBlc := wBlc2[p2w];
   wTrc := wTrc2[p2w];
   units := csys.units()[p2w];
# 
# Make blc and trc quanta vectors, reinsert default values.
#
   n := length(blc);
   wblcq := r_array(id='quant');
   for (i in 1:n) {
      if (blc[i] == private.default) {
         wblcq[i] := dq.quantity('0default');
      } else {
         wblcq[i] := dq.quantity(wBlc[i], units[i]);
      }
      if (is_fail(wblcq[i])) fail;
   }
#
   n := length(trc);
   wtrcq := r_array(id='quant');
   for (i in 1:n) {
      if (trc[i] == private.default) {
         wtrcq[i] := dq.quantity('0default');
      } else {
         wtrcq[i] := dq.quantity(wTrc[i], units[i]);
      }
      if (is_fail(wtrcq[i])) fail;
   }
#
# Return the region
#
   comment := box.get('comment');
   return drm.wbox(blc=wblcq, trc=wtrcq, csys=csys, comment=comment);
}



const private.region_value := function(const regionType)
#
# Regions come in some different flavours.  This
# must match the Type enum in the file
# Lattices/RegionType.h 
# 
#  Type          Value
#  -----------------
#  invalid         -1
#  other            0  OTHER
#  pixel regions    1  PIXEL
#  world regions    2  WORLD
#  slicer           3  SLICER
#  MAX              4  MAX
#            
{
   if (!is_string(regionType)) {
      return throw ('Argument must be a string', origin='regionmanager.region_value');
   }
   tmp := to_upper(regionType);
   if (tmp == 'OTHER') {
      return as_integer(0);
   } else if (tmp == 'PIXEL') {
      return as_integer(1);
   } else if (tmp == 'WORLD') {
      return as_integer(2);
   } else if (tmp == 'SLICER') {
      return as_integer(3);
   } else if (tmp == 'MAX') {
      return as_integer(3);
   } else {
      msg := spaste ('Unrecognized region type (', regionType, ')');
      return throw (msg, origin='regionmanager.region_value');
   }
}

const private.select_region := function (ref overWrite, ref abort, 
                                         currentNames,
                                         regionName, confirm)
{
   val abort := F;
   found := private.findString(currentNames, regionName);
#
   newName := regionName;
   val overWrite := F;
   if (found) {
      if (confirm) {
         while (T) {
            include 'choice.g';
            msg := spaste('The region "', regionName, '" exists, overwrite it ?');
            ok := choice(msg, "yes no rename");
            if (ok=='no') {
               note ('Save aborted', priority='WARN',  
                      origin='regionmanager.select_region');
               val abort := T;
               return T;
            } else if (ok=='rename') {
               include 'widgetserver.g';
               newName := dws.dialogbox(label=regionName, title='Enter new name <CR>',
                                        type='string', value='');
               if (is_fail(newName)) {
                  note ('Save aborted', priority='WARN',  
                         origin='regionmanager.select_region');
                  val abort := T;
                  return T;
               } else {
                  if (strlen(newName)==0) {
                     note ('Empty string, try again',  priority='WARN',
                           origin='regionmanager.select_region');
                  } else if (private.findString(currentNames, regionName)) {
                     ;
                  } else {
                    break;
                  }
               }
            } else {
               break;
            }
         }
      } else {
         val overWrite := T;
      }
   }
   return newName;
}



#
#-----------------------------------------------------------------------
# Public functions
#


const self.absreltype := function(const absrelvalue)
#
# Relative regions can come in some different flavours
# 
#  Type       Value 
#  -------------------
#  abs         1
#  relref      2
#  relcen      3  
#  reldir      4
#
{
   if (!is_numeric(absrelvalue)) {
      return throw ('Argument must be numeric', origin='regionmanager.absreltype');
   }
   if (absrelvalue == private.absrel_value('ABS')) {
      return 'abs';
   } else if (absrelvalue == private.absrel_value('RELREF')) {
      return 'relref';
   } else if (absrelvalue == private.absrel_value('RELCEN')) {
      return 'relcen';
#   } else if (absrelvalue == private.absrel_value('RELDIR')) {
#      return 'reldir';
   } else {
      msg := spaste ('Unrecognized absrel value (', absrelvalue, ')');
      return throw (msg, origin='regionmanager.absreltype');
   }
}



const self.box := function(blc=[], trc=[], inc=[], absrel='abs', frac=F,  comment='')
{
   blc2 := dms.tovector(blc, 'float');
   if (is_fail(blc2)) fail;
   trc2 := dms.tovector(trc, 'float');
   if (is_fail(trc2)) fail;
   inc2 := dms.tovector(inc, 'float');
   if (is_fail(inc2)) fail;
#
   if (!is_string(absrel)) {
      return throw ('Variable "absrel" is not a string',  origin='regionmanager.box');
   }
   ok := private.absrel_value(absrel);
   if (is_fail(ok)) fail;
   if (!is_boolean(frac)) {
      return throw ('Variable "frac" is not boolean',  origin='regionmanager.box');
   }
#
   n := min(length(blc2,trc2));
   if (n > 0) {
      for (i in 1:n) {
         if (blc2[i] != self.def() && trc2[i] != self.def()) {
            if (trc2[i] < blc2[i]) {
               msg := spaste('trc (', trc2[i], ') for axis ', i, 
                             ' < blc (', blc2[i], ')');
               return throw (msg, origin='regionmanager.box');
            }
            if (absrel=='abs') {
               if (!frac) {
                  if (blc2[i]<1) {
                     msg := spaste('blc(', blc2[i], ') for axis ', i, 
                                   ' is negative, but absolute pixels specified');
                     return throw (msg, origin='regionmanager.box');
                  }
                  if (trc2[i]<1) {
                     msg := spaste('trc(', trc2[i], ') for axis ', i, 
                                   ' is negative, but absolute pixels specified');
                     return throw (msg, origin='regionmanager.box');
                  }
               } else {
                  if (blc2[i]<0) {
                     msg := spaste('blc(', blc2[i], ') for axis ', i, 
                                   ' is negative, but absolute fractions specified');
                     return throw (msg, origin='regionmanager.box');   
                  }
                  if (trc2[i]<0) {
                     msg := spaste('trc(', trc2[i], ') for axis ', i, 
                                   ' is negative, but absolute fractions specified');
                     return throw (msg, origin='regionmanager.box');
                  }
               } 
            }
         }
      }
   }
   n := length(blc2);
   if (n > 0) {
      for (i in 1:n) {
         if (blc2[i] != self.def() && absrel=='abs') {
            if (!frac) {
               if (blc2[i]<1) {
                  msg := spaste('blc(', blc2[i], ') for axis ', i, 
                                ' is negative, but absolute pixels specified');
                  return throw (msg, origin='regionmanager.box');
               }
            } else {
               if (blc2[i]<0) {
                  msg := spaste('blc(', blc2[i], ') for axis ', i, 
                                ' is negative, but absolute fractions specified');
                  return throw (msg, origin='regionmanager.box');   
               }
            }
         }
      }
   }
   n := length(trc2);
   if (n > 0) {
      for (i in 1:n) {
         if (trc2[i] != self.def() && absrel=='abs') {
            if (!frac) {
               if (trc2[i]<1) {
                  msg := spaste('trc(', trc2[i], ') for axis ', i, 
                                ' is negative, but absolute pixels specified');
                  return throw (msg, origin='regionmanager.box');
               }
            } else {
               if (trc2[i]<0) {
                  msg := spaste('trc(', trc2[i], ') for axis ', i, 
                                ' is negative, but absolute fractions specified');
                  return throw (msg, origin='regionmanager.box');   
               }
            }
         }
      }
   }
   private.make_array(blc2);
   private.make_array(trc2);
   private.make_array(inc2);
#
   fracBlc := [];
   absRelBlc := [];
   if (length(blc2) > 0) {
      fracBlc := array(frac, length(blc2));
      absRelBlc := array(private.absrel_value(absrel), length(blc2));
   }
   private.make_array(fracBlc);
   private.make_array(absRelBlc);
#
   fracTrc := [];
   absRelTrc := [];
   if (length(trc2) > 0) {
      fracTrc := array(frac, length(trc2));
      absRelTrc := array(private.absrel_value(absrel), length(trc2));   
   }
   private.make_array(fracTrc);
   private.make_array(absRelTrc);
#
   fracStride := [];
   if(length(inc2) > 0) fracStride := array(frac, length(inc2));
   private.make_array(fracStride);
#
   r1 := itemcontainer();
   r1.set('name','LCSlicer');
   r1.set('isRegion', private.region_value('SLICER'));
   r1.set('blc', blc2);
   r1.set('trc', trc2);
   r1.set('inc', inc2);
   r1.set('fracblc', as_boolean(fracBlc));
   r1.set('fractrc', as_boolean(fracTrc));
   r1.set('fracinc', as_boolean(fracStride));
   r1.set('arblc', as_integer(absRelBlc));
   r1.set('artrc', as_integer(absRelTrc));
   r1.set('oneRel', T);
   r1.set('comment', as_string(comment));
   r1.makeconst();
   return ref r1;
}    


const self.complement :=  function(region, comment='')
#
# Create a Glish region object for a WCComplement object
#
{
   if (!is_region(region)) {
      return throw ('Given region is not valid', 
                    origin='regionmanager.complement');
   }
# 
   r1 := itemcontainer();
   r1.set('name', 'WCComplement');
   r1.set('isRegion', private.region_value('WORLD'));
   rec := [=];
   rec.r0 := region.torecord();
   rec.nr := as_integer(1);
   r1.set('regions', rec);
   r1.set('comment', as_string(comment)):
   r1.makeconst();
   return ref r1;
}
const self.comp :=  ref self.complement;


const self.concatenation := function (box, regions, comment='')
#
# Create a Glish region object for a WCConcatenate object
#
{
   if (!self.isworldregion(box)) {
      return throw ('Extension box is not a valid world region', 
                    origin='regionmanager.concatenation');
  }
   name := box.get('name');
   if (name != 'WCBox') {
      return throw ('Given extension box is not a world box', 
                    origin='regionmanager.concatenation');
   }
   pixelAxes := box.get('pixelAxes');
   if (length(pixelAxes) != 1) {
      return throw ('Given extension box must be 1 dimensional', 
                    origin='regionmanager.concatenation');
   }
#
   nRegions := length(regions);
   lrec := [=];
   if (nRegions > 0) {
      for (i in 1:nRegions) {
         if (!is_region(regions[i])) {
            msg := spaste('Given region # ', i, ' is not valid');
            return throw(msg, origin='regionmanager.concatenation');
         } else {
            lrec[sprintf('r%d',i)] := regions[i].torecord();
         }
      }
   } else {
      throw('There are no regions contained in the variable "regions"',
            origin='regionmanager.concatenation');
   }
   lrec.nr := as_integer(nRegions);
#
   r1 := itemcontainer();
   r1.set('name', 'WCConcatenation');
   r1.set('isRegion', private.region_value('WORLD'));
   r1.set('regions', lrec);
   r1.set('box', box.torecord());
   r1.set('comment', as_string(comment));
   r1.makeconst();
   return ref r1;
}
const self.concat := ref self.concatenation;


const self.copyregions := function (tableout, tablein, confirm=F)
{
   names := self.namesintable(tablein);
   if (is_fail(names)) fail;
#
   const n := length(names);
   if (n >0) {
      r := self.fromtabletorecord(tablein);
      if (is_fail(r)) fail;
      if (is_fail(self.fromrecordtotable(tableout, F, T, names, r))) fail;
   } else {
      note('There are no regions to copy', priority='WARN',
          origin='regionmanager.copyregions');
   }
   return T;
}



const self.def := function() 
{
   return private.default;
}



const self.deletefromtable := function (ref tablename, confirm=F, const regionname)
{
   if (!is_boolean(confirm)) {
      msg := spaste('Given variable "confirm" is not boolean');
      return throw (msg, origin='regionmanager.deletefromtable');
   }
   if (!is_string(regionname)) {
      msg := spaste('Given variable "regionname" is not a string');
      return throw (msg, origin='regionmanager.deletefromtable');
   }
#
   deleteNames := regionname;
   nDelete := 0;
   doAll := F;
   if (deleteNames == 'all') {
      doAll := T;
   } else {
      nDelete := length(deleteNames);
      if (nDelete > 0) {
         for (i in 1:nDelete) {
            if (strlen(deleteNames[i])==0) {
               msg := spaste('Given variable "regionname" is invalid');
               return throw (msg, origin='regionmanager.deletefromtable');
            }
         }
      } else {
         msg := spaste('Given variable "regionname" is empty');
         return throw (msg, origin='regionmanager.deletefromtable');
      }
   }
   deleteMask := array(F, nDelete);
#
   opened := F;
   t := private.open_table(opened, tablename, openNew=F, readOnly=F);
   if (is_fail(t)) fail;
#
   currentNames := t.fieldnames('regions');
   if (is_fail(currentNames)) {
     msg := paste('There are no regions in this table');
     note(msg, priority='WARN', origin='regionmanager.deletefromtable');
     if (opened) t.close();
     return T;
   }
#
   nCurrent := length(currentNames);
   if (doAll) {
      deleteNames := currentNames;
      nDelete := nCurrent;
      for (i in 1:nDelete) deleteMask[i] := T;
   } else {
      for (i in 1:nDelete) {
         if (!private.findString(currentNames, deleteNames[i])) {
            msg := spaste('Region ', deleteNames[i], ' does not exist');
            note(msg, priority='WARN', origin='regionmanager.deletefromtable');
         } else {
             deleteMask[i] := T;
         }
      }
   }
#
   for (i in 1:nDelete) {
      if (deleteMask[i]) {
         if (confirm) {
            include 'choice.g';
            msg := spaste('Delete the region "', deleteNames[i], '" ?');
            ok := choice(msg, "yes no");
            if (ok=='no') {
               msg := spaste('Region ', deleteNames[i], ' not deleted');
               note (msg, priority='WARN', origin='regionmanager.deletefromtable');
               deleteMask[i] := F;
            } 
         }
#
         if (deleteMask[i]) {
            keyword := spaste('regions.', deleteNames[i]);
            if (t.removekeyword(keyword)) {
               msg := paste('Successful delete of region', deleteNames[i]);
               note(msg, priority='NORMAL', origin='regionmanager.deletefromtable');
            } else {
               msg := paste('Error deleting region', deleteNames[i]);
               note(msg, priority='SEVERE', origin='regionmanager.deletefromtable');
            }
         }
      }
   }
#
   t.flush();
   if (opened) t.close();
#
   return deleteMask;
}




const self.difference :=  function(region1, region2, comment='')
#
# Create a Glish region object for an WCDifference object
# 
{
   if (!is_region(region1)) {
      return throw ('First given region is not valid', 
                    origin='regionmanager.difference');
   }
   if (!is_region(region2)) {
      return throw ('Second given region is not valid', 
                    origin='regionmanager.difference');
   }
# 
   r1 := itemcontainer();
   r1.set('name', 'WCDifference');
   r1.set('isRegion', private.region_value('WORLD'));
   rec := [=];
   rec.r0 := region1.torecord();
   rec.r1 := region2.torecord();
   rec.nr := as_integer(2);
   r1.set('regions', rec);
   r1.set('comment', as_string(comment));
   r1.makeconst();
   return ref r1;
}
const self.diff :=  self.difference;


const self.displayedplane := function (image, ddoptions, zaxispixel=unset, asworld=T)
#
# Find the plane which is currently being displayed by the viewer,
# and return it as a world box. If zaxispixel is unset then we 
# take the full range for the z axis
{
   if (!is_image(image)) {
      return throw ('Variable "image" is not a valid image object', 
                    origin='regionmanager.displayedplane');
   }
#
# Construct a pixel box for the plane we are displaying.  We fish
# out from the display data options record what is where
#
   cs := image.coordsys();
   if (is_fail(cs)) fail;
   p2w := cs.axesmap(toworld=T);
   if (is_fail(p2w)) fail;
#
   const axisNames := cs.names()[p2w];
   const n := length(axisNames);
   blc := array(1,n);
   trc := image.shape();
   imageName := image.name(strippath=T);
#
# Find out which is the z-axis (movie) axis is and what its pixel value is
#
   if (has_field(ddoptions, 'zaxis')) {
      zAxisName := ddoptions.zaxis.value;
      j := 1;
      for (i in axisNames) {
         if (i==zAxisName) {
            if (!is_unset(zaxispixel)) {
               blc[j] := zaxispixel;
               trc[j] := zaxispixel;
               break;
            }
         }
         j +:= 1;
      }
#
# There may be hidden axes too.  FInd them and their pixel values
#
      const nHidden := n - 3; 
      if (nHidden>0) {
         for (k in 1:nHidden) {
            fn := spaste('haxis', k);
            hop := ddoptions[fn];
#
            j := 1;
            for (i in axisNames) {
               if (i==hop.listname) {
                  blc[j] := hop.value;
                  trc[j] := hop.value;
                  break;
               }
               j +:= 1;
            }
         }
      }
   }
#
# Make a pixel box.  Its really just a plane from the nD image
#
   absrel := array('abs', n);
   comment := spaste('From ', imageName);
   pbox := self.box(blc=blc, trc=trc, absrel=absrel, frac=F,
                    comment=comment);
   if (is_fail(pbox)) pbox;
   if (asworld) {
#
# Now convert it to a world box if desired
#
      wr := self.pixeltoworldregion(cs, image.shape(), pbox);
      if (is_fail(cs.done())) fail;
      return ref wr;
   } else {
      if (is_fail(cs.done())) fail;
      return ref pbox;
   }
}


const self.done := function ()
{
   wider self, private;
#

   val self := F;
   if (has_field(private,'gui')) {
      ok := private.gui.done(T);
      if (is_fail(ok)) fail;
   }
   private := F;
   return T; 
}



const self.ellipsoid :=  function(center, radius, shape, absrel='abs', 
                                  frac=F, comment='')
#
# Create a Glish region object for an LCEllipsoid object
#
{   
   center2 := dms.tovector(center, 'float');
   if (is_fail(center2)) fail;
   radius2 := dms.tovector(radius, 'float');
   if (is_fail(radius2)) fail;
   shape2 := dms.tovector(shape, 'integer');
   if (is_fail(shape2)) fail;
#
   if (length(center2) != length(radius2)) {
      return throw ('Center and radius vectors must be the same length');
   }
   if (length(shape2) != length(radius2)) {
      return throw ('Shape, center and radius vectors must be the same length');
   }
#
   r1 := itemcontainer();
   r1.set('name', 'LCEllipsoid');
   r1.set('isRegion', private.region_value('PIXEL'));
   r1.set('oneRel', T);
   r1.set('absrel', private.absrel_value(as_string(absrel)));
   r1.set('frac', as_boolean(frac));
   r1.set('center', center2);
   r1.set('radii', radius2);
   r1.set('shape', shape2);
   r1.set('comment', as_string(comment));
   r1.makeconst();
   return ref r1;
}
const self.ellipse :=  self.ellipsoid;

###
const self.extension := function(box, region, comment='')
#
# Create a Glish region object for an WCExtension object
#
{
   if (!is_region(region)) {
      return throw ('Given region is not valid', 
                    origin='regionmanager.extension');
   }
   if (!self.isworldregion(box)) {
      return throw ('Given extension box is not a valid world region', 
                    origin='regionmanager.extension');
   }
   name := box.get('name');
   if (name != 'WCBox') {
      return throw ('Given extension box is not a world box', 
                    origin='regionmanager.extension');
   }
#
   r1 := itemcontainer();
   r1.set('name', 'WCExtension');
   r1.set('isRegion', private.region_value('WORLD'));
   rec.r0 := region.torecord();
   rec.r1 := box.torecord();
   rec.nr := as_integer(2);
   r1.set('regions', rec);
   r1.set('comment', as_string(comment));
   r1.makeconst();
   return ref r1;
}
const self.ext := self.extension;


###
const self.extractsimpleregions := function (region)
{
   if (!is_region(region)) {
      return throw ('Given variable is not a region tool',
                    origin='regionmanager.extractsimpleregions');
   }
#
# Recursively work down the region to the bottom of
# branches where the simple regions should live.
#
   recin := region.torecord();
   if (is_fail(recin)) fail;
   recout := [=];
   ok := private.extractsimpleregions(recout, recin);
   if (is_fail(ok)) fail;

# Now turn them into true regions from their records

   rec := [=];
   for (i in 1:length(recout)) {
      rec[i] := itemcontainer();
      if (is_fail(rec[i])) fail;
      ok := rec[i].fromrecord(recout[i]);
      if (is_fail(ok)) fail;
   }
   return rec;
}
const self.esr := self.extractsimpleregions;





###
const self.fromglobaltotable := function (ref tablename, confirm=F, 
                                          verbose=T, regionname="", ...)
#
# Save many regions into a table.  The region is placed in a table 
# in a record field called  "regions[regionname[i]]". If table
# does not exist, it is created.
#
{
   if (!is_string(regionname)) {
      msg := spaste('Given variable "regionname" is not a string');
      return throw (msg, origin='regionmanagerfromglobaltotable');
   }
#
   if (!is_boolean(confirm)) {
      msg := spaste('Given variable "confirm" is not boolean');
      return throw (msg, origin='regionmanagerfromglobaltotable');
   }
   nInRegions := num_args(...);
   if (nInRegions == 0) {
      msg := spaste('You have not specified any regions');
      return throw (msg, origin='regionmanagerfromglobaltotable');
   }
#
   for (i in 1:nInRegions) {
      if (!is_region(nth_arg(i, ...))) {
         msg := spaste('Region # ', i, ' is not a valid region');
         return throw (msg, origin='regionmanagerfromglobaltotable');
      }
   }
#
   nInNames := length(regionname);
   regionname2 := regionname;
   if (nInNames != nInRegions) {
      for (i in 1:nInRegions) {
         if (i > nInNames) {
            regionname2[i] := spaste('region', i);
         }
      }
   }
#
   rec := [=];
   for (i in 1:nInRegions) {
      rec[regionname2[i]] := nth_arg(i,...);
   }
   ok := self.fromrecordtotable(tablename, confirm, verbose, regionname2, rec);
   if (is_fail(ok)) fail;
   return T;
}


const self.fromrecordtotable := function (ref tablename, confirm=F, 
                                          verbose=T, regionname="", regionrec)
#
# Save many regions stored in a record into a table.  The region is placed 
# in a table keyword in a record field called  "regions[regionname[i]]". 
# If table does not exist, it is created.
#
{
   if (!is_string(regionname)) {
      msg := spaste('Given variable "regionname" is not a string');
      return throw (msg, origin='regionmanager.fromrecordtotable');
   }
   if (!is_boolean(confirm)) {
      msg := spaste('Given variable "confirm" is not boolean');
      return throw (msg, origin='regionmanager.fromrecordtotable');
   }
#
   nInNames := length(regionname);
   regionname2 := regionname;
   nInRegions := length(regionrec);
#
   if (nInRegions == 0) {
      msg := spaste('You have not specified any regions');
      return throw (msg, origin='regionmanager.fromrecordtotable');
   } else {
      for (i in 1:nInRegions) {
         if (!is_region(regionrec[i])) {
            msg := spaste('Region # ', i, ' is not a valid region');
            return throw (msg, origin='regionmanager.fromrecordtotable');
         }
      }
#
      if (nInNames != nInRegions) {
         fieldNames := field_names(regionrec);
         for (i in 1:nInRegions) {
            if (i > nInNames) {
               regionname2[i] := fieldNames[i];
            }
         }
      }
   }
#
   opened := F;
   t := private.open_table(opened, tablename, openNew=T, readOnly=F)
   if (is_fail(t)) fail;
#
   currentNames := t.fieldnames('regions');
   if (is_fail(currentNames)) currentNames := "";
   local overWrite, abort;
#
   for (i in 1:nInRegions) {
      newName := private.select_region(overWrite, abort, currentNames, 
                                       regionname2[i], confirm);
      if (is_fail(newName)) fail;
      if (!abort) {
         if (verbose) {
            if (overWrite) {
               note (spaste('Overwriting region "', newName, '"'),
                     priority='WARN',  origin='regionmanager.fromrecordtotable');
            } else {
               note (spaste('Saving region "', newName, '"'), 
                     origin='regionmanager.fromrecordtotable');
            }
         }
#
         keyname := spaste('regions.', newName);
         ok := t.putkeyword(keyname, regionrec[i].torecord(), T);
         if (is_fail(ok) || !ok) {
            if (opened) t.close();
            msg := spaste('Failed to write region ', newName,
                          ' into table ', t.name());
            return throw (msg, origin='regionmanager.fromrecordtotable');
         }
      }
   }
#
   t.flush();
   if (opened) t.close();
   return T;
}




const self.fromtabletoglobal := function (ref tablename, verbose=T, const regionname)
{
   if (!is_string(regionname)) {
     msg := paste('Given variable "regionname" is not a string');
     return throw (msg, origin='regionmanager.fromtabletoglobal');
   }
   if (!is_boolean(verbose)) {
     msg := paste('Given variable "verbose" is not boolean');
     return throw (msg, origin='regionmanager.fromtabletoglobal');
   }
#
   opened := F;
   t := private.open_table(opened, tablename, openNew=F, readOnly=T);
   if (is_fail(t)) fail;
#
   regions := t.fieldnames('regions');
   if (is_fail(regions)) {
     msg := paste('There are no regions in this table');
     note(msg, priority='WARN', origin='regionmanager.fromtabletoglobal');
     if (opened) t.close();
     return T;
   }
   if (private.findString(regions, regionname)) {
      keyword := spaste('regions.', regionname);
      region := t.getkeyword(keyword);
      r := itemcontainer();
      r.fromrecord(region);
      r.makeconst();
      if (is_region(r)) {
         if (verbose) { 
            msg := spaste('Successful restore of region ', regionname);
            note (msg, origin='regionmanager.fromtabletoglobal');
         }
         if (opened) t.close();
         return ref r;
      } else {
         if (opened) t.close();
         return throw (paste('Restored region', regionname, ' is invalid'),
                       origin='regionmanager.fromtabletoglobal');   
      }
   } else {
      if (opened) t.close();
      return throw (paste('Region', regionname, ' does not exist'),
                    origin='regionmanager.fromtabletoglobal');   
   }
}


const self.fromtabletonakedrecord := function (ref tablename)

{
   opened := F;
   t := private.open_table(opened, tablename, openNew=F, readOnly=T);
   if (is_fail(t)) fail;
#
   rec := t.getkeywords();
   regions := [=];
   if (has_field(rec, 'regions')) regions := rec.regions;
#
   if (opened) t.close();
   return regions;
}


const self.fromtabletorecord := function (ref tablename, verbose=T,
                                          const regionname="", numberfields=T)
{
   if (!is_boolean(verbose)) {
     msg := paste('Given variable "verbose" is not boolean');
     return throw (msg, origin='regionmanager.fromtabletorecord');
   }
   if (!is_boolean(numberfields)) {
     msg := paste('Given variable "numberfields" is not boolean');
     return throw (msg, origin='regionmanager.fromtabletorecord');
   }
   if (!is_string(regionname)) {
     msg := paste('Given variable "regionname" is not a string');
     return throw (msg, origin='regionmanager.fromtabletorecord');
   }
#
   opened := F;
   t := private.open_table(opened, tablename, openNew=F, readOnly=T);
   if (is_fail(t)) fail;
#
   currentNames := t.fieldnames('regions');
   if (is_fail(currentNames)) {
     msg := paste('There are no regions in this table');
     note(msg, priority='WARN', origin='regionmanager.fromtabletorecord');
     if (opened) t.close();
     return [=];
   }
#
   restoreNames := regionname;
   if (length(restoreNames)==0) restoreNames := currentNames;
#
   rec := [=];
   const nRestoreNames := length(restoreNames);
   j := 1;
   for (i in 1:nRestoreNames) {
      if (private.findString(currentNames, restoreNames[i])) {
         keyword := spaste('regions.', restoreNames[i]);
         region := t.getkeyword(keyword);
         local ok;
         if (numberfields) {
            rec[j] := itemcontainer();
            rec[j].fromrecord(region);
            rec[j].makeconst();
            ok := is_region(rec[j]);
         } else {
            fld := restoreNames[i];
            rec[fld] := itemcontainer();
            rec[fld].fromrecord(region);
            rec[fld].makeconst();
            ok := is_region(rec[fld]);
         }
         if (ok) {
            if (verbose) {
               msg := spaste('Successful restore of region ', restoreNames[i]);
               note (msg, origin='regionmanager.fromtabletorecord');
            }
            j +:= 1;
         } else {
            if (opened) t.close();
            return throw (paste('Region', restoreNames[i], ' is invalid'),
                          origin='regionmanager.fromtabletorecord');   
         }
      }
   }
   if (opened) t.close();
   return rec;
}


const self.getselectcallback := function ()
{
   return private.selectcallback;
}



const self.gui := function(parent=F, tlead=F, tpos='sw')
{
   wider private;
   if (private.guiDone==F) {
      include 'regionmanagergui.g';
      private.guiDone := T;
#
      private.gui := regionmanagergui(which=self);
      if (is_fail(private.gui)) fail;
      private.gui.gui(parent=parent, tlead=tlead, tpos=tpos);
      whenever private.gui->dismissed do {
         self.setselectcallback(0);
      }
      whenever private.gui->closed do {
         self.setselectcallback(0);
      }
      whenever private.gui->sent do {
         if (is_function(private.selectcallback)) {
            private.selectcallback($value[1]);
         }
      }
   } else {
      private.gui.gui(parent=parent, tlead=tlead, tpos=tpos);
   }
   return T;
}


const self.intersection := function(...)
#
# Create a Glish region object for an WCIntersection
#
# Must have at least two arguments
#
{
   local comment, nRegions;
   lrec := private.find_regions(comment, nRegions, 2, ...);
   if (is_fail(lrec)) fail;
# 
   r1 := itemcontainer();
   r1.set('name', 'WCIntersection');
   r1.set('isRegion', private.region_value('WORLD'));
   r1.set('regions', lrec);
   r1.set('comment', as_string(comment));
   r1.makeconst();
   return ref r1;
}
const self.int := self.intersection;



const self.ispixelregion := function (const region)
#
# Does this region (itemcontainer.g) object think it is 
# a pixel region ?
#
{
   if (!is_region(region)) return F;
   rType := as_integer(region.get('isRegion'));
   rValue1 := as_integer(private.region_value('PIXEL'));
   rValue2 := as_integer(private.region_value('SLICER'));
   return (rType==rValue1 || rType==rValue2);
}   



const self.isworldregion := function (region)
{
   if (!is_region(region)) return F;
   rType := as_integer(region.get('isRegion'));
   rValue := as_integer(private.region_value('WORLD'));
   if (rType != rValue) return F;
   return T;
}


const self.namesintable := function (ref tablename) 
{
   opened := F;
   t := private.open_table(opened, tablename, openNew=F, readOnly=T);
   if (is_fail(t)) fail;
#
   rec := t.getkeywords();
   if (opened) t.close();
   if (has_field(rec,'regions')) {
      return field_names(rec.regions);
   } else {
      return [];
   }
}


const self.pixeltoworldregion := function (csys, shape=unset, region)
{
   if (!self.ispixelregion(region)) {
      return throw('The given variable "region" is not a pixel region',
                   origin='regionmanager.pixeltoworldregion');
   }
   if (!is_coordsys(csys)) {
      return throw ('Variable "csys" is not a valid Coordinate System', 
                    origin='regionmanager.pixeltoworldregion');
   }
#
   name := region.get('name');
   if (name=='LCSlicer') {
      return ref private.pixeltoworldbox(csys, shape, region);
   } else {
      txt := spaste('Cannot convert regions of type ', name,
                    ' to world a region yet');
      return throw(txt, origin='regionmanager.pixeltoworldregion');
   }
}


const self.polygon := function(x, y, shape, absrel='abs',  frac=F, comment='')
#
# Create a Glish region object for an LCPolygon object
# 
{
   x2 := dms.tovector(x, 'float');
   if (is_fail(x2)) fail;
   y2 := dms.tovector(y, 'float');
   if (is_fail(y2)) fail;
   shape2 := dms.tovector(shape, 'integer');
   if (is_fail(shape2)) fail;
#
   if (!is_boolean(frac)) {
      return throw ('Variable "frac" is not boolean',  origin='regionmanager.polygon');
   }
#
   if (length(x2)==0 || length(y2)==0) {
      return throw ('Zero length vectors given', 
                    origin='regionmanager.polygon');
   }
   if (length(x2) != length(y2)) {
      return throw ('x and y vectors are of different lengths', 
                    origin='regionmanager.polygon');
   }
   private.make_array(x2);
   private.make_array(y2);
   r1 := itemcontainer();
   r1.set('name', 'LCPolygon');
   r1.set('isRegion', private.region_value('PIXEL'));
   r1.set('absrel', private.absrel_value(as_string(absrel)));
   r1.set('oneRel', T);
   r1.set('frac', as_boolean(frac));
   r1.set('x', x2);
   r1.set('y', y2);
   r1.set('shape', shape2);
   r1.set('comment', as_string(comment));
   r1.makeconst();
   return ref r1;
}
const self.poly := self.polygon;


const self.pseudotoworldregion := function (image, pseudoregionvalue, ddoptions, intersect=T)
#
# Convert a peudoregion, produced by the viewer to a real
# world region.  The pseudoregion may be an empty record
# (which the viewer won't make, but imagefitter will)
# and this means the full image
#
{
   csys := image.coordsys();
   if (is_fail(csys)) fail;
   local wbox;
   if (intersect) {
#
# Find the displayed plane (movie axis + hidden axis pixel values)
#
     zaxispixel := pseudoregionvalue.zindex;
     wbox := self.displayedplane(image, ddoptions, zaxispixel);
     wbox.makeunconst();
     wbox.set('display', F);            # Tells Viewerimageregions not to draw this region
     wbox.makeconst();
   } else {
#
# Find the displayed plane (hidden axis pixel values but not the
# movie axis over which we extend automatically)
#
     wbox := self.displayedplane(image, ddoptions);
   }
   if (is_fail(wbox)) fail;
#
# Find out which pixel axes the x and y axes are. These
# are the axes we are actually seeing in the display
#
   p2w := csys.axesmap(toworld=T);
   if (is_fail(p2w)) fail;
   const axisNames := csys.names()[p2w];
#
   j := 1;
   xAxisName := ddoptions.xaxis.value;
   yAxisName := ddoptions.yaxis.value;
   pixelAxes := [0,0];
   for (i in axisNames) {
      if (i==xAxisName) {
         pixelAxes[1] := j;
      } else if (i==yAxisName) {
         pixelAxes[2] := j;
      }
      j +:= 1;
   }
#
# Generate the 2D region that the user made with the viewer
#
   local xq, yq, region2D, interRegion;
   comment := spaste('From ', image.name(T));
   if (length(pseudoregionvalue)==0) {
#
# The pseudoregion is empty. Just return the world box
# for the displayed plane or full image 
#
      if (is_fail(csys.done())) fail;
      return ref wbox;
    } else {
      if (pseudoregionvalue.type=='polygon') {
         xq := 
           defaultcoordsyssupport.valuetoquantum(pseudoregionvalue.world.x, 
                                                 pseudoregionvalue.units[1]);
         if (is_fail(xq)) fail;
         yq := 
           defaultcoordsyssupport.valuetoquantum(pseudoregionvalue.world.y,
                                                 pseudoregionvalue.units[2]);
         if (is_fail(yq)) fail;
         region2D := self.wpolygon(x=xq, y=yq, pixelaxes=pixelAxes, 
                                   csys=csys, comment=comment);
         if (is_fail(region2D)) fail;
       } else if (pseudoregionvalue.type=='box') {
#
# Note that the blc/trc vectors may come out with a length greater than that
# of units (after reordering).  So just pick out the first 2 which are appropriate
# to the plane being displayed.
#
         blcq := defaultcoordsyssupport.valuetovectorquantum(pseudoregionvalue.world.blc[1:2], 
                                                             pseudoregionvalue.units[1:2]);
         if (is_fail(blcq)) fail;
         trcq := defaultcoordsyssupport.valuetovectorquantum(pseudoregionvalue.world.trc[1:2], 
                                                             pseudoregionvalue.units[1:2]);
         if (is_fail(trcq)) fail;
         region2D := self.wbox(blc=blcq, trc=trcq, pixelaxes=pixelAxes, 
                               csys=csys, comment=comment);
         if (is_fail(region2D)) fail;
       } else {
          msg := spaste('Pseudo region of type ', pseudoregionvalue.type, 
                        ' is unknown');
          return throw (msg, origin='regionmanager.pseudotoworldregion');
       }
       if (is_fail(csys.done())) fail;
#
# Now intersect the 2D region with the world box (really a plane)
# if needed.  If the user does not request intersection, the 2D
# region will autoextend on usage.
#
       if (length(image.shape())==2 || !intersect) {
          return ref region2D;
       } else {
          return ref self.intersection(wbox, region2D, comment);
       } 
   }
}


const self.quarter := function(comment='')
#
# Create a Glish region object to access the central
# quarter (area) of the first 2 dimensions of a lattice.  
#
{
   return ref self.box(blc=[0.25,0.25], trc=[0.75,0.75], absrel='abs', 
                       frac=T, comment=comment);
}


const self.setcoordinates := function (const csys, verbose=T)
#
# Set private data with given coordinates tool
# 
# Returns a fail if the object is const or the
# provided CoordinateSystem is invalid
#
{
   if (!is_coordsys(csys)) {
      return throw ('Variable "csys" is not a valid CoordinateSystem object', 
                    origin='regionmanager.setcoordinates');
   }
   wider private;
#
   private.coordinatestool := csys.copy();
   if (is_fail(private.coordinatestool)) fail;
#
   private.coordinates := csys.torecord();
   if (is_fail(private.coordinates)) fail;
   private.verbose := verbose;
#
   return T;
}
  


const self.setselectcallback := function (ref callbackFunction)
{
   wider private;
   private.selectcallback := callbackFunction;
#
# Turn on or off the send/break buttons on the GUI
#
   if (is_function(callbackFunction)) {
      private.gui.setsendbreakstate(enable=T);
   } else {
      private.gui.setsendbreakstate(enable=F);
   }
   return T;
}


const self.type := function ()
{
   return 'regionmanager';
}


const self.union := function(...)
#
# Create a Glish region object for an WCUnion
#
# Must have at least two arguments
#
{
   local comment, nRegions;
   lrec := private.find_regions(comment, nRegions, 2, ...);
   if (is_fail(lrec)) fail;
# 
   r1 := itemcontainer();
   r1.set('name', 'WCUnion');
   r1.set('isRegion', private.region_value('WORLD'));
   r1.set('regions', lrec);
   r1.set('comment', as_string(comment));
   r1.makeconst();
   return ref r1;
}

const self.wbox := function(blc=unset, trc=unset, pixelaxes=[],
                            csys=unset, absrel="", comment='')
#
# Create a Glish region object for a WCBox object
# with Quantities
#
{
#
# Convert quantity of vector (drm.quant([1,2,3], 'pix')) to vector of
# quantities (drm.quant("1pix 2pix 3pix").
# Current interface insists blc/trc is a vector quanta.
# Single quantum comes out in a record r[1]
#
   local blc2, nBlc;
   if (is_unset(blc) || length(blc)==0) {
      blc2 := [=];
      nBlc := 0;
   } else {
      blc2 := defaultcoordsyssupport.valuetovectorquantum(blc);
      if (is_fail(blc2)) fail;
      nBlc := defaultcoordsyssupport.lengthofquantum(blc2);
      if (is_fail(nBlc)) fail;
   }
#
   local trc2, nTrc;
   if (is_unset(trc) || length(trc)==0) {
      trc2 := [=];
      nTrc := 0;
   } else {
      trc2 := defaultcoordsyssupport.valuetovectorquantum(trc);
      if (is_fail(trc2)) fail;
      nTrc := defaultcoordsyssupport.lengthofquantum(trc2);
      if (is_fail(nTrc)) fail;
   }
#
   pixelaxes2 := dms.tovector(pixelaxes, 'integer');
   if (is_fail(pixelaxes2)) fail;
   if (length(pixelaxes2) > 0) {
      if (!is_integer(pixelaxes2)) {
         msg := 'Variable "pixelaxes" must be integer valued'
         return throw(msg, origin='regionmanager.wbox');
      }
      if (nBlc != nTrc || nBlc != length(pixelaxes2)) {
         msg := 'Variables blc & trc must be the same length as pixelaxes'
         return throw(msg, origin='regionmanager.wbox');
      }
   }
   if (!is_unset(csys) && !is_coordsys(csys)) {
      return throw ('Variable "csys" is not a valid CoordinateSystem object', 
                    origin='regionmanager.wbox');
   }
   absrel := dms.tovector(absrel, 'string');
#
   r1 := itemcontainer();
   r1.set('name', 'WCBox');
   r1.set('isRegion', private.region_value('WORLD'));
   nPixelAxes := -1;
#
   if (is_unset(csys)) {
#
# Fish out the private data CoordinateSystem
#
      if (!is_unset(private.coordinates)) {
         r1.set('coordinates', private.coordinates);
         if (private.verbose) {
            msg := spaste ('Using private CoordinateSystem from image "',
                            private.coordinates.parentName, '"');
            note (msg, priority='NORMAL', 
                  origin='regionmanager.wbox');
         }
         nPixelAxes := private.coordinatestool.naxes(F);
         if (is_fail(nPixelAxes)) fail;
       } else {
         return throw ('Private CoordinateSystem data has not been set',
                       origin='regionmanager.wbox>');
      }
   } else {
#
# Use given CoordinateSystem
#
      r1.set('coordinates', csys.torecord());
      nPixelAxes := csys.naxes(F);
      if (is_fail(nPixelAxes)) fail;
   }
#
# Make blc and trc the same length, filling in defaults. This is a 
# pain in the ass because of the scalar/vector crap.
#
   nBlcTrc := max(nBlc, nTrc);
   if (nBlcTrc > nPixelAxes) {
      msg := spaste('You have given more blc/trc values (', nBlcTrc, 
                    ') than there are pixel axes in the CoordinateSystem (',
                    nPixelAxes, ')');
      return throw (msg, origin='regionmanager.wbox>');
   }
#
   blcRec := r_array(id='quant');
   trcRec := r_array(id='quant');
   if (nBlcTrc > 0) {
      for (i in 1:nBlcTrc) {
         if (nBlc == 0) {
            blcRec[i] := dq.quantity('0default');
         } else if (nBlc == 1) {
            if (i == 1) {
               blcRec[i] := blc2;
            } else {
               blcRec[i] := dq.quantity('0default');
            }
         } else {
            if (i <= nBlc) {
               blcRec[i] := blc2[i];
            } else {
               blcRec[i] := dq.quantity('0default');
            }
         }
#
         if (nTrc == 0) {
            trcRec[i] := dq.quantity('0default');
         } else if (nTrc == 1) {
            if (i == 1) {
               trcRec[i] := trc2;
            } else {
               trcRec[i] := dq.quantity('0default');
            }
         } else {
            if (i <= nTrc) {
               trcRec[i] := trc2[i];
            } else {
               trcRec[i] := dq.quantity('0default');
            }
         }
      }
   }
   r1.set('blc', blcRec);
   r1.set('trc', trcRec);
#
# If pixelaxes not given, make them 1,2,3...
# 
   pa := pixelaxes2;
   n := length(pa);
   if (n == 0) {
      if (nBlcTrc > 0) {
         for (i in 1:nBlcTrc) pa[i] := i;
      }
   } else {
      for (i in 1:n) {
         if (!is_integer(pa[i]) || pa[i] > nPixelAxes) {
            return throw ('Variable "pixelaxes" contains illegal values',  
                          origin='regionmanager.wbox');
         }
      }
   }
   private.make_array(pa);
   r1.set('pixelAxes', as_integer(pa));
#
# make absrel the same length as pixelAxes
#
   nPixelAxes := length(pa);
   nAbsRel := length(absrel);
   ar := [];
   if (nPixelAxes > 0) {
      for (i in 1:nPixelAxes) {
         if (i > nAbsRel) {
            if (nAbsRel==0) {
               ar[i] := private.absrel_value('abs');
            } else {
               ar[i] := ar[nAbsRel];            # Defaults to last given
            }
         } else {
            ar[i] := private.absrel_value(absrel[i]);
         }
      }
   }
   private.make_array(ar);
   r1.set('absrel', ar);
#
   r1.set('oneRel', T);
   r1.set('comment', as_string(comment));
   r1.makeconst();
   return ref r1;
}  

const self.wdbox := function(blc=[], trc=[], csys=unset, absrel="", comment='')
#
# Create a Glish region object for a WCBox object
# 
{
   if (!is_itemcontainer(csys)) {
      return throw ('Variable "csys" is not a valid CoordinateSystem object', 
                    origin='regionmanager.wdbox');
   }
#
#   
# Fish out the axis units in pixel axis order
#
   units := "";
   nPixelAxes := -1;    
   if (is_unset(csys)) {
      if (!is_unset(private.coordinates)) {
         p2w := private.coordinatestool.axesmap(toworld=T);
         if (is_fail(p2w)) fail;
         units := private.coordinatestool.units()[p2w];
         if (is_fail(units)) fail;
         nPixelAxes := private.coordinatestool.naxes(F);
         if (is_fail(nPixelAxes)) fail;
      } else {             
         return throw ('Private CoordinateSystem data has not been set',
                       origin='regionmanager.wdbox');
      }
   } else {
      p2w := csys.axesmap(toworld=T);
      if (is_fail(p2w)) fail;
      units := csys.units()[p2w];
      if (is_fail(units)) fail;
      nPixelAxes := private.coordinatestool.naxes(F);
      if (is_fail(nPixelAxes)) fail;
   }
#
   blc2 := dms.tovector(blc, 'double');
   if (is_fail(blc2)) fail;
   n := length(blc2);
   if (n > nPixelAxes) {
      return throw ('There are more values in the "blc" than axes in the CoordinateSystem',
                    origin='regionmanager.wdbox');
   }
   blcq := [=];
   if (n>0) {
      blcq := r_array(id='quant');
      for (i in 1:n) {
         blcq[i] := dq.quantity(blc2[i], units[i]);
         if (is_fail(blcq[i])) fail;
      }
   }
#
   trc2 := dms.tovector(trc, 'double');
   if (is_fail(trc2)) fail;
   n := length(trc2);
   if (n > nPixelAxes) {
      return throw ('There are more values in the "trc" than axes in the CoordinateSystem',
                    origin='regionmanager.wdbox');
   }
   trcq := [=];
   if (n>0) {
      trcq := r_array(id='quant')
      for (i in 1:n) {
         trcq[i] := dq.quantity(trc2[i], units[i]);
         if (is_fail(trcq[i])) fail;
      }
   }
#
# Create box
#
   return ref self.wbox(blc=blcq, trc=trcq, csys=csys, absrel=absrel, 
                        comment=as_string(comment));
}  



const self.wpolygon := function(x, y, pixelaxes=[], csys=unset, 
                                absrel='abs', comment='')
#
# Create a Glish region object for a WCPolygon object
# with Quantities
#
{
   if (!defaultcoordsyssupport.isquantumvector(x)) {
      return throw('Variable "x" is not a quantity vector',
                   origin='regionmanager.wpolygon');
   }
   nx := defaultcoordsyssupport.lengthofquantum(x);
   if (nx<3) {
      return throw ('Variable "x" must have at least 3 vertices',  
                    origin='regionmanager.wpolygon');
   }
   if (!defaultcoordsyssupport.isquantumvector(y)) {
      return throw('Variable "y" is not a quantity vector',
                   origin='regionmanager.wpolygon');
   }
   ny := defaultcoordsyssupport.lengthofquantum(y);
   if (ny<3) {
      return throw ('Variable "y" must have at least 3 vertices',  
                    origin='regionmanager.wpolygon');
   }
   if (nx != ny) {
      return throw ('Variables "x" and "y" must have the same number of vertices',  
                    origin='regionmanager.wpolygon');
   }
#
   pixelaxes2 := dms.tovector(pixelaxes, 'integer');
   if (is_fail(pixelaxes2)) fail;
#
   if (length(pixelaxes2) > 0) {   
      if (!is_integer(pixelaxes2)) {
         msg := 'Variable "pixelaxes" must be integer valued'
         return throw(msg, origin='regionmanager.wpolygon');
      }
   } else {
      pixelaxes2[1] := 1;
      pixelaxes2[2] := 2;
   }
   if (!is_unset(csys) && !is_coordsys(csys)) {
      return throw ('Variable "csys" is not a valid CoordinateSystem object', 
                    origin='regionmanager.wpolygon');
   }
#
   r1 := itemcontainer();
   r1.set('name', 'WCPolygon');
   r1.set('isRegion', private.region_value('WORLD'));
#
   if (is_unset(csys)) {
#
# Fish out the private data CoordinateSystem
#
      if (!is_unset(private.coordinates)) {
         r1.set('coordinates', private.coordinates);
         if (private.verbose) {
            msg := spaste ('Using private CoordinateSystem from image "',
                            private.coordinates.parentName, '"');
            note (msg, priority='NORMAL',
                  origin='regionmanager.wpolygon');
         }
      } else {
         return throw ('Private CoordinateSystem data has not been set',
                       origin='regionmanager.wpolygon');
      }
   } else {
#
# Use given CoordinateSystem
#
      r1.set('coordinates', csys.torecord());
   }
#
   r1.set('x', x);
   r1.set('y', y);
   r1.set('pixelAxes', as_integer(pixelaxes2));
   r1.set('absrel', private.absrel_value(as_string(absrel)));
   r1.set('oneRel', T);
   r1.set('comment', as_string(comment));
   r1.makeconst();
   return ref r1;
}
const self.wpoly := self.wpolygon;



const self.wdpolygon := function(x, y, pixelaxes=[], csys=unset,
                                 absrel='abs', comment='')
#
# Create a Glish region object for a WCPolygon object
#
{
   if (!is_itemcontainer(csys)) {
      return throw ('Variable "csys" is not a valid CoordinateSystem object',
                    origin='regionmanager.wdpolygon');
   }
   pixelaxes2 := pixelaxes;
   if (is_string(pixelaxes)) pixelaxes2 := as_integer(pixelaxes);
   if (length(pixelaxes2) > 0) {   
      if (!is_integer(pixelaxes2)) {
         msg := 'Variable "pixelaxes" must be integer valued'
         return throw(msg, origin='regionmanager.wdpolygon');
      }
   } else {
      pixelaxes2[1] := 1;
      pixelaxes2[2] := 2;
   }
   n := length(x);
   if (n < 4) {
      return throw ('Variable "x" must be at least of length 3', 
                    origin='regionmanager.wdpolygon');
   }
   if (length(y) != n) {
      return throw ('Variables "x" and "y" must the same length', 
                    origin='regionmanager.wdpolygon');
   }
#
# Fish out the axis units in pixel axis order
#
   units := "";
   nPixelAxes := -1;    
   if (is_unset(csys)) {
      if (!is_unset(private.coordinates)) {
         p2w := private.coordinatestool.axesmap(toworld=T);
         if (is_fail(p2w)) fail;
         units := private.coordinatestool.units()[p2w];
         if (is_fail(units)) fail;
         nPixelAxes := private.coordinatestool.naxes(F);
         if (is_fail(nPixelAxes)) fail;
      } else {             
         return throw ('Private CoordinateSystem data has not been set',
                       origin='regionmanager.wdpolygon');
      }
   } else {
      p2w := csys.axesmap(toworld=T);
      if (is_fail(p2w)) fail;
      units := csys.units()[p2w];
      if (is_fail(units)) fail;
      nPixelAxes := private.coordinatestool.naxes(F);
      if (is_fail(nPixelAxes)) fail;
   }
#
   ip := pixelaxes2[1];
   if (ip > nPixelAxes) {
      return throw ('The specified X pixel axis is not in the CoordinateSystem',
                    origin='regionmanager.wdpolygon'); 
   }
   x2 := x;
   if (is_string(x)) x2 := as_double(x);
   xQ := dq.quantity(x2, units[ip]);
#
   ip := pixelaxes2[2];
   if (ip > nPixelAxes) {
      return throw ('The specified Y pixel axis is not in the CoordinateSystem',
                    origin='regionmanager.wdpolygon'); 
   }
   y2 := y;
   if (is_string(y)) y2 := as_double(y);
   yQ := dq.quantity(y2, units[ip]);
#
# Create polygon
#	
   return ref self.wpolygon(x=xQ, y=yQ, pixelaxes=pixelaxes2,
                            csys=csys, absrel=absrel, comment=comment);
}
const self.wdpoly := self.wdpolygon;


const self.wmask := function(expr, comment='')
#
# Create a Glish region object for a WCLELMask object
#
{
   r1 := itemcontainer();
   r1.set('name', 'WCLELMask');
   r1.set('isRegion', private.region_value('WORLD'));
   r1.set('expr', as_string(expr));
   r1.set('comment', as_string(comment));
   r1.makeconst();
   return ref r1;
}  

const self.wrange := function (range, pixelaxis, csys=unset,
                               absrel='abs', comment='')
{
   local blc, trc;
   lr := length(range);
   if (is_numeric(range)) {
#
# Handle just a numeric vector
#
     if (lr==1) {
        blc := dq.quantity(range[1], 'pix');
        trc := dq.quantity('0default');
     } else {
        blc := dq.quantity(range[1], 'pix');
        trc := dq.quantity(range[2], 'pix');
     }
   } else {
#
# Range given not as numeric (quantity or string ...)
#
      tmp := defaultcoordsyssupport.valuetovectorquantum(range);
      if (is_fail(tmp)) fail;
      const n := defaultcoordsyssupport.lengthofquantum(tmp);
      if (n==1) {
         blc := tmp;
         trc := dq.quantity('0default');
      } else {
         blc := tmp[1];
         trc := tmp[2];
      }
   }
   if (is_fail(blc)) fail;
   if (is_fail(trc)) fail;
#
   box := self.wbox(blc=blc, trc=trc, pixelaxes=pixelaxis,
                    absrel=absrel, csys=csys, comment=comment);
   box.makeunconst();
   box.set('display', F);                  # Tells the Viewerimageregions not to draw this region
   box.makeconst();
   return ref box;
}


#
# Different implementation based on a purely vector double range
# with full conversoin to world coordinates
#
const private.wrange := function (range, pixelaxis, csys=unset,
                                  absrel='abs', comment='')
{
   local csys2;
   if (is_unset(csys)) {
      if (!is_unset(private.coordinatestool)) {
         csys2 := private.coordinatestool;
      } else {
         return throw ('Private CoordinateSystem has not been set',
                       origin='regionmanager.wrange');
      }
   } else {  
      csys2 := csys;
   }
#
   blc := 1:pixelaxis-1;
   trc := 1:pixelaxis-1;
   for (i in 1:length(blc)) {
      blc[i] := private.default;
      trc[i] := private.default;
   }
#
   range2 := dms.tovector(range, 'float');
   if (length(range2)==1) {
      blc[pixelaxis] := range[1];
      trc[pixelaxis] := private.default;
   } else {
      blc[pixelaxis] := range[1];
      trc[pixelaxis] := range[2];
   }
   box := self.box(blc=blc, trc=trc, absrel=absrel, comment=comment);
   return ref private.pixeltoworldbox(csys=csys2, box=box);
}


};


# Default objects

const defaultregionmanager := regionmanager();
const drm := ref defaultregionmanager;
note ('defaultregionmanager (drm) ready for use', 
      priority='NORMAL', origin='regionmanager');

