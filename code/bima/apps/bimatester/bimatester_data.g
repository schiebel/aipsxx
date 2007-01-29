# bimatester_data: data for bimatester
# Copyright (C) 1999,2000,2001
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
# $Id: bimatester_data.g,v 19.0 2003/07/16 03:35:43 aips2adm Exp $

# Include guard
pragma include once
 
const _define_bimatester_data := function(id) {
#

    public := [=];

    vals := [=];

######## Begin definitions for individual datasets #########

####### t001/c109.sgb2n/97nov08.raw ############
    tid := 't001/c109.sgb2n/97nov08.raw';

    vals[tid] := [=];
    vals[tid].image := [=];
    vals[tid].image.restored := [=];

    vals[tid].phcal := '1733-130.wide.lsb';

    vals[tid].uvw.indices := [1126, 1483, 3220, 5602, 7012, 7417, 8091, 8169, 8211, 8747, 9857, 10265, 10695, 12093, 12524, 12592, 13297, 13365, 13820, 13893];

   vals[tid].ant1.indices := [107, 205, 298, 1379, 1388, 1689, 1756, 1789, 1829, 1991, 2155, 2483, 2753, 2953, 3409, 3680, 3719, 4078, 4501, 4769];

   vals[tid].ant2.indices := [496, 604, 1301, 1328, 2030, 2519, 2990, 3079, 3105, 3207, 3496, 3707, 3833, 3943, 4290, 4434, 4630, 4805, 4834, 4925];

   vals[tid].exp.indices := [11, 538, 787, 820, 860, 1244, 1473, 2274, 2652, 2722, 2832, 2959, 3101, 3216, 3324, 3800, 3931, 4159, 4250, 4608];

   vals[tid].flag.indices := [211, 235, 368, 884, 938, 2012, 2283, 2563, 2635, 2751, 2969, 3002, 3076, 3729, 3730, 3900, 4294, 4326, 4700, 4808];

   vals[tid].time.indices := [113, 427, 589, 1170, 2061, 2262, 2430, 2634, 2856, 3408, 3666, 4334, 4461, 4489, 4500, 4541, 4733, 4762, 4800, 4832];

   vals[tid].data.indices := [1, 28, 405, 799, 1355, 1432, 2037, 2051, 2139, 2172, 2241, 2668, 3118, 3429, 3475, 3504, 3859, 4402, 4443, 4491];

   vals[tid].wtspec.indices := [227, 575, 918, 1094, 1113, 1409, 1417, 1452, 1644, 1796, 1869, 2837, 3585, 3622, 3739, 3761, 3792, 3818, 4244, 4375];

    vals[tid].beam.bmaj := 10.52;
    vals[tid].beam.bmin := 5.47;
    vals[tid].beam.bpa := 9.3;

    # clean box
    vals[tid].clean := [=];
    vals[tid].clean.box.blc := [120,120,1,1];
    vals[tid].clean.box.trc := [136,136,1,1];


    # box for noise
    vals[tid].image.restored.reg1.blc := [70, 70];
    vals[tid].image.restored.reg1.trc := [190, 120];

    # box around source
    vals[tid].image.restored.reg2.blc := [120,120];
    vals[tid].image.restored.reg2.trc := [136,136]; 


    if(! any(id == field_names(vals))) {
	fail(spaste(id,' is not in the recognized list of ids'));
    }
#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
    #


    const public.getStandard := function() {
	wider vals,id;
	return vals[id];
    }


   const public.type := function() {
      return 'bimatester_data';
   }
   plugins.attach('bimatester', public);
   return ref public;
}
#
##
## Constructor
## @param id the BIMA trial id from which the standard data will be
#         gotten
const bimatester_data := function(id) {
#   
    b := _define_bimatester_data(id);
    if(is_fail(b)) return throw(b::message);
    return ref b;
} 
