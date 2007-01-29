# tcomponentlist.g:
# Copyright (C) 1999,2000
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
# $Id: tcomponentlist.g,v 19.2 2004/08/25 01:07:19 cvsmgr Exp $

pragma include once
include 'componentlist.g'
include 'os.g'

componentlisttest := function(filename='tcomponentlist_tmp.cl') {
  dos.remove(filename, recursive=T, mustexist=F, follow=F);
  cl := emptycomponentlist();
  if (is_fail(cl)) {
    return throw('cannot create an empty list');
  }
  if (!is_componentlist(cl)) {
    return throw('cannot create a valid empty list');
  }
  if (cl.type() != 'componentlist') {
    return throw('the list type is bad');
  } 
  if (cl.length() != 0) {
    return throw('Cannot determine the length of an empty list');
  }
  if (cl.simulate(1) != T) {
    return throw('Cannot simulate a component');
  } 
  if (cl.length() != 1) {
    return throw('Cannot add a component to an empty list');
  }
  if (cl.simulate(2) != T) {
    return throw('Cannot simulate two components');
  } 
  if (cl.length() != 3) {
    return throw('Cannot add two components to an empty list');
  }
  if (cl.setshape(2:3, 'Gaussian') != T) {
    return throw('Cannot change the shape to Gaussian');
  }
  if (cl.shapetype(2) != 'Gaussian') {
    return throw('Cannot verify the shape of component 2 is Gaussian');
  }
  if (cl.shapetype(3) != 'Gaussian') {
    return throw('Cannot verify the shape of component 3 is Gaussian');
  }
  if (cl.setshape([1,3], 'Disk', majoraxis='2arcmin', 
		  minoraxis='3mas', positionangle='12deg') != T) {
    return throw('Cannot change the shape to Disk');
  }
  if (cl.shapetype(1) != 'Disk') {
    return throw('Cannot verify the shape of component 1 is disk');
  }
  if (cl.shapetype(3) != 'Disk') {
    return throw('Cannot verify the shape of component 3 is disk');
  }
  if (cl.setshape(1, 'Point') != T) {
    return throw('Cannot change the shape to Point');
  }
  if (cl.convertshape(2, majoraxis='arcmin', 
		  minoraxis='arcsec', positionangle='rad') != T) {
    return throw('Cannot change the shape of component 2 to Gaussian');
  }

  if (cl.shapetype(1) != 'Point') {
    return throw('Cannot verify the shape of component 1 is a point');
  }

  if (cl.shapetype(2) != 'Gaussian') {
    return throw('Cannot verify the shape of component 2 is a Gaussian');
  }
  if (cl.getshape(2).majoraxis.value != 1) {
    return throw('Component 2 has the wrong major axis size');
  }
  if (cl.getshape(2).majoraxis.unit != 'arcmin') {
    return throw('Component 2 has the wrong major axis unit');
  }
  if (cl.getshape(2).minoraxis.value != 60) {
    return throw('Component 2 has the wrong minor axis size');
  }
  if (cl.getshape(2).minoraxis.unit != 'arcsec') {
    return throw('Component 2 has the wrong minor axis unit');
  }
  if (cl.getshape(2).positionangle.value != 0) {
    return throw('Component 2 has the wrong position angle size');
  }
  if (cl.getshape(2).positionangle.unit != 'rad') {
    return throw('Component 2 has the wrong position angle unit');
  }

  if (cl.shapetype(3) != 'Disk') {
    return throw('Cannot verify the shape of component 3 is a Disk');
  }
  if (cl.getshape(3).majoraxis.value != 2) {
    return throw('Component 3 has the wrong major axis size');
  }
  if (cl.getshape(3).majoraxis.unit != 'arcmin') {
    return throw('Component 3 has the wrong major axis unit');
  }
  if (cl.getshape(3).minoraxis.value != 3) {
    return throw('Component 3 has the wrong minor axis size');
  }
  if (cl.getshape(3).minoraxis.unit != 'mas') {
    return throw('Component 3 has the wrong minor axis unit');
  }
  if (cl.getshape(3).positionangle.value != 12) {
    return throw('Component 3 has the wrong position angle size');
  }
  if (cl.getshape(3).positionangle.unit != 'deg') {
    return throw('Component 3 has the wrong position angle unit');
  }

  if (cl.rename('tcomponentlist_tmp.cl') != T) {
    return throw('Cannot rename the list.');
  }
  if (cl.close() != T) {
    return throw('Cannot close the list.');
  }
  if (cl.done() != T) {
    return throw('Cannot remove the componentlist tool.');
  }
  if (cl != F) {
    return throw('The componentlist tool did not get deleted.');
  }

  cl := componentlist(filename, readonly=F);
  if (is_fail(cl)) {
    return throw('cannot create read a component list table');
  }
  if (!is_componentlist(cl)) {
    return throw('cannot create a componentlist list tool from a table.');
  }
  if (cl.indices() != [1,2,3]) {
    return throw('Cannot get the indices of the componentlist.');
  }
  if (cl.remove([1,3]) != T) {
    return throw('Cannot remove components.');
  }
  if (cl.indices() != [1]) {
    return throw('Cannot get the indices of the componentlist.');
  }
  if (cl.simulate(1) != T) {
    return throw('Cannot simulate another component');
  } 
  if (cl.recover() != T) {
    return throw('Cannot recover components.');
  }
  if (cl.length() != 4) {
    return throw('Cannot recover deleted components ');
  }
  if (cl.remove(3) != T) {
    return throw('Cannot remove a component.');
  }
  if (cl.purge() != T) {
    return throw('Cannot purge componenta.');
  }
  if (cl.recover() != T) {
    return throw('Cannot recover components.');
  }
  if (cl.length() != 3) {
    return throw('Cannot recover deleted components ');
  }
  
  if (cl.shapetype(1) != 'Gaussian') {
    return throw('Cannot verify the shape of component 1 is a Gaussian');
  }
  if (cl.shapetype(3) != 'Point') {
    return throw('Cannot verify the shape of component 2 is a Point');
  }

  if (cl.done() != T) {
    return throw('Cannot remove the componentlist tool.');
  }
  if (cl != F) {
    return throw('The componentlist tool did not get deleted.');
  }
  dos.remove(filename, recursive=T, mustexist=T, follow=T);
}
#   private.removeRec := [_method = 'remove',
# 			_sequence = private.id._sequence];
#   public.sort := function(criteria='flux') {
#   public.sample := function(direction, pixelsize, frequency) {
#   public.rename := function(filename) {
#   public.edit := function(which) {
#   public.select := function(which) {
#   public.deselect := function(which) {
#   public.selected := function() {
#   public.getlabel := function(which) {
#   public.setlabel := function(which, value) {
#   public.getfluxvalue := function(which) {
#   public.getfluxunit := function(which) {
#   public.getfluxpol := function(which) {
#   public.setflux := function(which, value, unit='Jy', polarization='stokes') {
#   public.convertfluxunit := function(which, unit='Jy') {
#   public.convertfluxpol := function(which, polarization = 'Stokes') {
#   public.getrefdir := function(which) {
#   public.getrefdirra := function(which, unit='deg', precision=6) {
#   public.getrefdirdec := function(which, unit='deg', precision=6) {
#   public.getrefdirframe := function(which) {
#   public.setrefdir := function(which, ra, raunit, dec, decunit) {
#   public.setrefdirframe := function(which, frame) {
#   public.convertrefdir := function(which, frame) {
#   public.spectrumtype := function(which) {
#   public.getspectrum := function(which) {
#   public.setspectrum := function(which, type='Constant', index=[1,0,0,0]) {
#   public.convertspectrum := function(which, index='') {
#   public.getfreq := function(which) {
#   public.getfreqvalue := function(which) {
#   public.getfrequnit := function(which) {
#   public.getfreqframe := function(which) {
#   public.setfreq := function(which, value, unit='GHz') {
#   public.setfreqframe := function(which, frame) {
#   public.convertfrequnit := function(which, unit) {
# const asciitocomponentlist := function(filename, asciifile,
# 				       refer='J2000', format='ST',
# 				       flux=F, direction=F, spectrum=F,
# 				       readonly=F,
# 				       host='', forcenewserver=F) {
