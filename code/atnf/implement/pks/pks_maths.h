//----------------------------------------------------------------------------
//# pks_maths.h: Mathematical functions for Parkes single dish data reduction
//----------------------------------------------------------------------------
//# Copyright (C) 1994-2006
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# Original: Mark Calabretta
//# $Id: pks_maths.h,v 1.6 2006/05/19 00:12:06 mcalabre Exp $
//----------------------------------------------------------------------------
#ifndef ATNF_PKS_MATHS_H
#define ATNF_PKS_MATHS_H

// AIPS++ includes.
#include <casa/aips.h>
#include <casa/Arrays/Vector.h>


#include <casa/namespace.h>

// Global mathematical functions for single-dish data reduction.

// Nearest integral value.
Int nint(Double v);
Double anint(Double v);

// Round value v to the nearest integral multiple of precision p.
Double round(Double v, Double p);

// Compute the weighted median value of an array.
Float  median(const Vector<Float> &v, const Vector<Float> &wgt);

// Angular distance between two directions (angles in radian).
Double angularDist(Double lng1, Double lat1, Double lng2, Double lat2);

// Generalized position angle of the field point (lng,lat) from reference
// point (lng0,lat0) and the angular distance between them (angles in radian).
void distPA(Double lng0, Double lat0, Double lng, Double lat, Double &dist,
            Double &pa);

// Euler angle based transformation of spherical coordinates (radian).
void eulerx(Double lng0, Double lat0, Double phi0, Double theta, Double phi,
            Double &lng1, Double &lat1);

// Low precision coordinates of the sun.
void sol(Double mjd, Double &elng, Double &ra, Double &dec);

// Low precision Greenwich mean and apparent sidereal time (radian); UT1 is
// given in MJD form.
void gst(Double ut1, Double &gmst, Double &gast);

// Convert (ra,dec) to (az,el).  Position as a Cartesian triplet (m), UT1 in
// MJD form, and all angles in radian.
void azel(const Vector<Double> position, Double ut1, Double ra, Double dec,
          Double &az, Double &el);

// Compute the Solar elevation (radian) using the above functions.
Double solel(const Vector<Double> position, Double ut1);

#endif
