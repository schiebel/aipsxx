# gaussian.g: Gaussians in 1 and 2 dimensions
# Copyright (C) 1996,1997,1999,2000
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
# $Id: gaussian.g,v 19.2 2004/08/25 01:44:06 cvsmgr Exp $

pragma include once;

include 'note.g';

# summary:
# Given a FWHM, you can convert it to a "natural" width using the constant
# fwhm_to_natural: width = fwhm_to_natural * 1
# y := gaussian1d(x, height=1, center=0, fwhm=1/fwhm_to_natural)
# z := gaussian2d(x, y, height=1, center=[0,0], fwhm=[1,1]/fwhm_to_natural,
#                 pa = 0);
# Input x (and y for 2d) can be arrays
#
# For gaussian2d, fwhm gives the width of the major and minor axes. By
# convention then, fwhm[1] should be greater than fwhm[2], however this
# is not enforced. The position angle is measured counter clockwise from
# the y axis to the major axis of the gaussian.

const fwhm_to_natural := 1.0/sqrt(ln(16));

const gaussian1d := function(x, height=1, center=0, fwhm=1.0/fwhm_to_natural)
{
    if (!is_numeric(x) || !is_numeric(height) || !is_numeric(center) ||
	!is_numeric(fwhm)) {
	return throw('gaussian1d - x, height, center, fwhm must be numeric');
    }
    if (length(height) != 1 || length(center) != 1 || length(fwhm) != 1) {
	return throw('gaussian1d - height, center, fwhm must be scalar');
    }
    if (fwhm == 0) {
	return throw('gaussian1d - fwhm must be nonzero');
    }


    if (center != 0) x -:= center;
    width := fwhm * fwhm_to_natural;
    if (width != 1) x /:= width;
    x *:= -x;
    return height * exp(x);
}

const gaussian2d := function(x, y, height=1, center=[0,0], 
			     fwhm=[1,1]/fwhm_to_natural, pa=0)
{
    if (!is_numeric(x) || !is_numeric(height) || !is_numeric(center) ||
	!is_numeric(fwhm) || !is_numeric(pa)) {
	return throw('gaussian2d - x, height, center, fwhm, pa ', 
		     'must be numeric');
    }
    if (length(center) != 2 || length(fwhm) != 2) {
	return throw('gaussian2d - center, fwhm must be length 2');
    }
    if (length(pa) != 1 || length(height) != 1) {
	return throw('gaussian2d - height, pa must be scalar');
    }
    if (any(fwhm == 0)) {
	return throw('gaussian2d - fwhm must be nonzero');
    }
    if (length(x) != length(y)) {
	return throw('gaussian2d - length of x and y must be identical');
    }

    if (center[1] != 0) x -:= center[1];
    if (center[2] != 0) y -:= center[2];

    # Rotate if necessary
    cpa := cos(pa);
    spa := sin(pa);
    if (cpa != 1) {
	tmp := x;
	x :=  cpa*tmp + spa*y;
	y := -spa*tmp + cpa*y;
    }

    width := fwhm * fwhm_to_natural;
    if (width[1] != 1) x /:= width[1];
    if (width[2] != 1) y /:= width[2];

    x *:= x;
    y *:= y;
    x +:= y;
    
    return height * exp(-x);
}
