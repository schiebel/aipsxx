# imager.g: Make images from AIPS++ MeasurementSets
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2003
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
#   $Id: vpmanager.g,v 19.5 2006/04/20 03:19:29 mvoronko Exp $
#

# pragma include once

include "note.g"
include 'itemcontainer.g'
include 'quanta.g'
include 'serverexists.g'
include 'table.g'
include 'measures.g'

#defaultservers.suspend(T)
#defaultservers.trace(T)


const isvp:=function(const thing)
#
# Is this variable a valid vp ?
#
{
   if (!is_itemcontainer(thing)) return F;
   if (!thing.has_item('isVP')) return F;
   item := thing.get('isVP');
   if (is_fail(item)) return F;
   return T;
}


const isvpr:=function(const thing)
#
# Is this variable a valid vp record ?
#
{
   item := thing.isVP;
   if (is_fail(item)) return F;
   return T;
}


vpmanager := subsequence ()
#
# Constructor.  
#
{
   private := [=];
   private.recs := [=];


#------------------------------------------------------------------------
# Private functions 
#
const private.printitems := function (const vpd1)
#
# print the items
#
{
  nitems := vpd1.length();
  for (i in 1:nitems) {
    note( vpd1.get(i));
  }
}

private.addtorecs := function(const vpitem)
#
# add vpitem to recs
#
{
  wider private;

  nVPs := length(private.recs);
  if (!isvp(vpitem)) {
    msg := spaste('Given vp is not valid');
    return throw(msg, origin='vpmanager.addtorecs');
  } else {
    private.recs[as_integer(nVPs+1)] := vpitem.torecord();
  }
}

const private.vpvalue := function(const vpType)
#
# VPs come in some different flavours.  This
# must match the Type enum in the file
# Lattices/RegionType.h 
# 
#  Type          Value
#  -----------------
#  invalid          -1
#  other             0  NONE
#  CommonPB          1  COMMONPB
#  Airy Disk         2  AIRY
#  slicer            3  GAUSS
#  MAX               4  POLY
#  InversePolynomial 5  IPOLY
#  Polynomial        6  COSPOLY
#  Numeric Vector    7  NUMERIC
#  Image             8  IMAGE
#  ZernikePoly       9  ZERNIKE
#  MAX               9  MAX
{
   if (!is_string(vpType)) {
      return throw ('Argument must be a string', origin='vpmanager.vpvalue');
   }
   tmp := to_upper(vpType);
   if (tmp == 'NONE') {
      return as_integer(0);
   } else if (tmp == 'COMMONPB') {
      return as_integer(1);
   } else if (tmp == 'AIRY') {
      return as_integer(2);
   } else if (tmp == 'GAUSS') {
      return as_integer(3);
   } else if (tmp == 'POLY') {
      return as_integer(4);
   } else if (tmp == 'IPOLY') {
      return as_integer(5);
   } else if (tmp == 'COSPOLY') {
      return as_integer(6);
   } else if (tmp == 'NUMERIC') {
      return as_integer(7);
   } else if (tmp == 'IMAGE') {
      return as_integer(8);
   } else if (tmp == 'ZERNIKE') {
      return as_integer(9);
   } else if (tmp == 'MAX') {
      return as_integer(9);
   } else {
      msg := spaste ('Unrecognized vp type (', vpType, ')');
      return throw (msg, origin='vpmanager.vpvalue');
   }
}


const private.opentable := function (ref opened, const tablename, 
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
        return throw (msg, origin='vpmanager.opentable');
      }   
      t:= ref tablename;
   } else {
      okinc := eval('include \'image.g\'');
      if (is_fail(okinc)) {
         msg := paste('Failed to include "image.g"');
         return throw (msg, origin='vpmanager.opentable');
      }
#
      if (is_image(tablename)) {
#
# Is a Glish image object, which underneath is a table
#

         t := table(tablename.name(F), readonly=readOnly, ack=T);
         if (is_fail(t)) {
            msg := spaste('Could not open table of name "', tablename.name(), '"');
            return throw (msg, origin='vpmanager.opentable');
         }
         opened := T;
      } else if (is_string(tablename)) {

# Is just a string.  Maybe its the name of a table ?
#
         if (tableexists(tablename)) {
            t := table(tablename, readonly=readOnly, ack=T);
            if (is_fail(t)) {
               msg := spaste('Could not open table of name "', tablename, '"');
               return throw (msg, origin='vpmanager.opentable');
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
                  return throw (msg, origin='vpmanager.opentable');
               }
               opened := T;
            } else {
               msg := paste('Table of given name does not exist');
               return throw (msg, origin='vpmanager.opentable');
            }
         }
      } else {
        msg := paste('Given table is neither a table',
                     'object nor a table name');
        return throw (msg, origin='vpmanager.opentable');
      }
   }
   return t;
}


#------------------------------------------------------------------------
# Public functions 
#
 self.type := function() {
   return 'vpmanager';
 }

self.done := function(){
  wider private, self;
  private.recs:=F;
  private:=F;
  val self:=F;
  return T;
}

const self.setcannedpb := function(telescope='VLA', othertelescope='', dopb=T, 
commonpb='DEFAULT', dosquint=F, paincrement='720deg', usesymmetricbeam=F)
{
  wider private;
  vpd1 := itemcontainer();
  vpd1.set('name', 'COMMONPB');
  vpd1.set('isVP', private.vpvalue('COMMONPB'));
  if (telescope=="OTHER") {
    vpd1.set('telescope', othertelescope);
  } else {
    vpd1.set('telescope', telescope);
  }
  vpd1.set('dopb', dopb);
  vpd1.set('commonpb', commonpb);
  vpd1.set('dosquint', dosquint);
  vpd1.set('paincrement',  dq.quantity(paincrement));
  vpd1.set('usesymmetricbeam', usesymmetricbeam);
  private.addtorecs(vpd1);
  return vpd1;
}


self.setpbairy := 
function(telescope='VLA', othertelescope='', dopb=T, dishdiam='25.0m', 
	 blockagediam='2.5m', maxrad='0.8deg',reffreq='1.0GHz',
	 squintdir=F,squintreffreq='1GHz', dosquint=F,
	 paincrement='720deg',  usesymmetricbeam=F)
{
  wider private;
  vpd1 := itemcontainer();
  vpd1.set('name', 'AIRY');
  vpd1.set('isVP', private.vpvalue('AIRY'));
  if (telescope=="OTHER") {
    vpd1.set('telescope', othertelescope);
  } else {
    vpd1.set('telescope', telescope);
  }
  if (squintdir==F) {
    squintdir := dm.direction('azel', '0.0rad', '0.0rad')
  }
  vpd1.set('dopb', dopb);
  vpd1.set('dishdiam', dq.quantity(dishdiam));
  vpd1.set('blockagediam', dq.quantity(blockagediam));
  vpd1.set('maxrad', dq.quantity(maxrad));
  vpd1.set('reffreq', dq.quantity(reffreq));
  vpd1.set('squintdir', squintdir);
  vpd1.set('squintreffreq', dq.quantity(squintreffreq));
  vpd1.set('dosquint', dosquint);
  vpd1.set('paincrement', dq.quantity(paincrement));
  vpd1.set('usesymmetricbeam', usesymmetricbeam);
  private.addtorecs(vpd1);
  return vpd1;

}


self.setpbgauss := function(telescope='VLA', othertelescope='', dopb=T, halfwidth='0.5deg',
	maxrad='0.8deg',reffreq='1.0GHz',isthispb='PB',squintdir=F,squintreffreq='1GHz',
        dosquint=F,paincrement='720deg',  usesymmetricbeam=F)
{
  wider private;
  vpd1 := itemcontainer();
  vpd1.set('name', 'GAUSS');
  vpd1.set('isVP', private.vpvalue('GAUSS'));
  if (telescope=="OTHER") {
    vpd1.set('telescope', othertelescope);
  } else {
    vpd1.set('telescope', telescope);
  }
  vpd1.set('dopb', dopb);
  hpw:=dq.quantity(halfwidth);
  if(isthispb=='PB' || isthispb=='pb'){
    hpw.value:=hpw.value/2.0;
  }
  vpd1.set('halfwidth', hpw);
  vpd1.set('maxrad', dq.quantity(maxrad));
  vpd1.set('reffreq', dq.quantity(reffreq));
  if (isthispb=='PB' || isthispb=='pb') {
     vpd1.set('isthisvp', F);
  } else if (isthispb=='VP' || isthispb=='vp') {
     vpd1.set('isthisvp', T);
  }     
  if (squintdir==F) {
    squintdir := dm.direction('azel', '0.0rad', '0.0rad')
  }
  vpd1.set('squintdir', squintdir);
  vpd1.set('squintreffreq', dq.quantity(squintreffreq));
  vpd1.set('dosquint', dosquint);
  vpd1.set('paincrement', dq.quantity(paincrement));
  vpd1.set('usesymmetricbeam', usesymmetricbeam);
  private.addtorecs(vpd1);
  return vpd1;
}



self.setpbcospoly := function(telescope='VLA', othertelescope='', dopb=T, coeff=[], scale=[],
	maxrad='0.8deg',reffreq='1.0GHz',isthispb='PB',squintdir=F,squintreffreq='1GHz',
        dosquint=F,paincrement='720deg',  usesymmetricbeam=F)
{
  wider private;
  vpd1 := itemcontainer();
  vpd1.set('name', 'COSPOLY');
  vpd1.set('isVP', private.vpvalue('COSPOLY'));
  if (telescope=="OTHER") {
    vpd1.set('telescope', othertelescope);
  } else {
    vpd1.set('telescope', telescope);
  }
  vpd1.set('dopb', dopb);
  vpd1.set('coeff', coeff);
  vpd1.set('scale', scale);
  vpd1.set('maxrad', dq.quantity(maxrad));
  vpd1.set('reffreq', dq.quantity(reffreq));
  if (isthispb=='PB'|| isthispb=='pb') {
     vpd1.set('isthisvp', F);
  } else if (isthispb=='VP' || isthispb=='vp') {
     vpd1.set('isthisvp', T);
  }     
  if (squintdir==F) {
    squintdir := dm.direction('azel', '0.0rad', '0.0rad')
  }
  vpd1.set('squintdir', squintdir);
  vpd1.set('squintreffreq', dq.quantity(squintreffreq));
  vpd1.set('dosquint', dosquint);
  vpd1.set('paincrement', dq.quantity(paincrement));
  vpd1.set('usesymmetricbeam', usesymmetricbeam);
  private.addtorecs(vpd1);
  return vpd1;

}



self.setpbinvpoly := function(telescope='VLA', othertelescope='',dopb=T, coeff=[], 
	maxrad='0.8deg',reffreq='1.0GHz',isthispb='PB',squintdir=F,squintreffreq='1GHz',
        dosquint=F,paincrement='720deg',  usesymmetricbeam=F)
{
  wider private;
  vpd1 := itemcontainer();
  vpd1.set('name', 'IPOLY');
  vpd1.set('isVP', private.vpvalue('IPOLY'));
  if (telescope=="OTHER") {
    vpd1.set('telescope', othertelescope);
  } else {
    vpd1.set('telescope', telescope);
  }
  vpd1.set('dopb', dopb);
  vpd1.set('coeff', coeff);
  vpd1.set('maxrad', dq.quantity(maxrad));
  vpd1.set('reffreq', dq.quantity(reffreq));
  if (isthispb=='PB' || isthispb=='pb') {
     vpd1.set('isthisvp', F);
  } else if (isthispb=='VP' || isthispb=='vp') {
     vpd1.set('isthisvp', T);
  }     
  if (squintdir==F) {
    squintdir := dm.direction('azel', '0.0rad', '0.0rad')
  }
  vpd1.set('squintdir', squintdir);
  vpd1.set('squintreffreq', dq.quantity(squintreffreq));
  vpd1.set('dosquint', dosquint);
  vpd1.set('paincrement', dq.quantity(paincrement));
  vpd1.set('usesymmetricbeam', usesymmetricbeam);
  private.addtorecs(vpd1);
  return vpd1;

}



self.setpbpoly := function(telescope='VLA', othertelescope='',dopb=T, coeff=[], 
	maxrad='0.8deg',reffreq='1.0GHz',isthispb='PB',squintdir=F,squintreffreq='1GHz',
        dosquint=F,paincrement='720deg',  usesymmetricbeam=F)
{
  wider private;
  vpd1 := itemcontainer();
  vpd1.set('name', 'POLY');
  vpd1.set('isVP', private.vpvalue('POLY'));
  if (telescope=="OTHER") {
    vpd1.set('telescope', othertelescope);
  } else {
    vpd1.set('telescope', telescope);
  }
  vpd1.set('dopb', dopb);
  vpd1.set('coeff', coeff);
  vpd1.set('maxrad', dq.quantity(maxrad));
  vpd1.set('reffreq', dq.quantity(reffreq));
  if (isthispb=='PB' || isthispb=='pb') {
     vpd1.set('isthisvp', F);
  } else if (isthispb=='VP' || isthispb=='vp') {
     vpd1.set('isthisvp', T);
  }     
  if (squintdir==F) {
    squintdir := dm.direction('azel', '0.0rad', '0.0rad')
  }
  vpd1.set('squintdir', squintdir);
  vpd1.set('squintreffreq', dq.quantity(squintreffreq));
  vpd1.set('dosquint', dosquint);
  vpd1.set('paincrement', dq.quantity(paincrement));
  vpd1.set('usesymmetricbeam', usesymmetricbeam);
  private.addtorecs(vpd1);
  return vpd1;

}



self.setpbnumeric := function(telescope='VLA', othertelescope='',dopb=T, vect=[], 
	maxrad='0.8deg',reffreq='1.0GHz',isthispb='PB',squintdir=F,squintreffreq='1GHz',
        dosquint=F,paincrement='720deg',  usesymmetricbeam=F)
{
  wider private;
  vpd1 := itemcontainer();
  vpd1.set('name', 'NUMERIC');
  vpd1.set('isVP', private.vpvalue('NUMERIC'));
  if (telescope=="OTHER") {
    vpd1.set('telescope', othertelescope);
  } else {
    vpd1.set('telescope', telescope);
  }
  vpd1.set('dopb', dopb);
  vpd1.set('vect', vect);
  vpd1.set('maxrad', dq.quantity(maxrad));
  vpd1.set('reffreq', dq.quantity(reffreq));
  if (isthispb=='PB' || isthispb=='pb') {
     vpd1.set('isthisvp', F);
  } else if (isthispb=='VP' || isthisvp=='vp') {
     vpd1.set('isthisvp', T);
  }     
  if (squintdir==F) {
    squintdir := dm.direction('azel', '0.0rad', '0.0rad')
  }
  vpd1.set('squintdir', squintdir);
  vpd1.set('squintreffreq', dq.quantity(squintreffreq));
  vpd1.set('dosquint', dosquint);
  vpd1.set('paincrement', dq.quantity(paincrement));
  vpd1.set('usesymmetricbeam', usesymmetricbeam);
  private.addtorecs(vpd1);
  return vpd1;

}

self.setpbimage := function(telescope='VLA', othertelescope='', dopb=T,
	realimage='', imagimage='')
{
  wider private;
  vpd1 := itemcontainer();
  vpd1.set('name', 'IMAGE');
  vpd1.set('isVP', private.vpvalue('IMAGE'));
  if (telescope=="OTHER") {
    vpd1.set('telescope', othertelescope);
  } else {
    vpd1.set('telescope', telescope);
  }
  vpd1.set('dopb', dopb);
  vpd1.set('realimage', as_string(realimage));
  vpd1.set('imagimage', as_string(imagimage));
  private.addtorecs(vpd1);
  return vpd1;

}


self.summarizevps := function(verbose=F)
{
  nVPs := length(private.recs);
  if (nVPs > 0) {
    note( 'VP#  Tel    VP Type');
    for (i in 1:nVPs) {
      if (!isvpr(private.recs[i])) {
	msg := spaste('Given vp # ',i,' is not valid');
	return throw(msg, origin='vpmanager.summarizevps');
      } else {
	note( i,'    ', private.recs[i].telescope,'    ',private.recs[i].name);
	if (verbose) {
	   note( private.recs[i] );
	}
      }     
    }
  } else {
    note('There are no VPs defined');
  }
}


self.saveastable := function(ref tablename)
{ 
  wider private;
  nVPs := length(private.recs);

  cd1 := tablecreatescalarcoldesc('telescope','');
  cd2 := tablecreatescalarcoldesc('antenna',-1);
  cd3 := tablecreatescalarcoldesc('pbdescription',[=]);
  td :=  tablecreatedesc(cd1, cd2, cd3); 
  t :=  table(tablename, td, nVPs);

  for (i in 1:nVPs) {
    if (is_fail(t.putcell('telescope', i, private.recs[i].telescope)))
        fail;
    if (is_fail(t.putcell('antenna', i, -1))) fail;
    if (is_fail(t.putcell( 'pbdescription', i, private.recs[i]))) fail; 
  }
  t.flush();
  t.close();
  return T;
}

}


