# DISH tool script for use with unix initiation of DISH
#------------------------------------------------------------------------------
#   Copyright (C) 1997,1998,1999,2000,2001,2002
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
#
#------------------------------------------------------------------------------

pragma include once;
include 'logger.g';
include 'dish.g';

const d := dish();
dl.note('*******************************************************');
dl.note('DISH enabled. All commands are accessed by typing: ');
dl.note('     d.functionname(...)');
dl.note('Type: ');
dl.note('     d.info()');
dl.note('     for an alphabetical listing of commands');
dl.note('Type: ');
dl.note('     d.help("function_name")');
dl.note('     for succinct help on a particular function ');
dl.note('     e.g., d.help("help",driveweb=T)');
dl.note('  ');
dl.note('Type "d.news()" for recent information');
dl.note('*******************************************************');

