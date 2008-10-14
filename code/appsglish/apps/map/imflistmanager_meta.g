# imflistmanager_meta.g: Standard meta information for imagingfieldlistmanager
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: imflistmanager_meta.g,v 19.1 2004/08/25 01:24:20 cvsmgr Exp $
#

pragma include once;

include 'types.g';

types.class('imagingfieldlistmanager').
   includefile('imflistmanager.g');

# Constructors
types.method('ctor_imagingfieldlistmanager');

# Methods
types.method('imagingfieldlist').
   string('model1').
   imagingfield('imagingfield1').
   string('model2').
   imagingfield('imagingfield2').
   string('model3').
   imagingfield('imagingfield3').
   string('model4').
   imagingfield('imagingfield4').
   string('model5').
   imagingfield('imagingfield5').
   string('model6').
   imagingfield('imagingfield6').
   string('model7').
   imagingfield('imagingfield7').
   string('model8').
   imagingfield('imagingfield8').
   string('model9').
   imagingfield('imagingfield9').
   imagingfieldlist('return', 'myimagingfieldlist', dir='inout');

