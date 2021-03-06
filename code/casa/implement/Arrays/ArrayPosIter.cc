//# ArrayPosIter.cc: Iterate an IPosition through the shape of an Array
//# Copyright (C) 1993,1994,1995,1999,2004
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
//# $Id: ArrayPosIter.cc,v 19.4 2004/12/06 07:15:42 gvandiep Exp $

#include <casa/Arrays/ArrayPosIter.h>
#include <casa/Arrays/ArrayError.h>

namespace casa { //# NAMESPACE CASA - BEGIN

ArrayPositionIterator::ArrayPositionIterator(const IPosition &shape, 
					     const IPosition &origin,
					     uInt byDim)
: Start(origin),
  Shape(shape),
  atOrBeyondEnd(False)
{
    setup(byDim);
}

ArrayPositionIterator::ArrayPositionIterator(const IPosition &shape, 
					     uInt byDim)
: Start(shape.nelements(), 0),
  Shape(shape),
  atOrBeyondEnd(False)
{
    setup(byDim);
}

ArrayPositionIterator::ArrayPositionIterator(const IPosition &shape, 
					     const IPosition &iterAxes,
					     Bool axesAreCursor)
: Start(shape.nelements(), 0),
  Shape(shape),
  atOrBeyondEnd(False)
{
    setup(iterAxes, axesAreCursor);
}

// <thrown>
//     <item> ArrayIteratorError
// </thrown>
void ArrayPositionIterator::setup(uint byDim)
{
    if (byDim > ndim()) {
	throw(ArrayIteratorError("ArrayPositionIterator::ArrayPositionIterator"
	    " - Stepping by dimension > Array dimension"));
    }
    IPosition cursorAxes(byDim);
    for (uInt i=0; i<byDim; i++) {
      cursorAxes(i) = i;
    }
    setup (cursorAxes, True);
}

void ArrayPositionIterator::setup(const IPosition &axes,
				  Bool axesAreCursor)
{
    // Note that IPosition::otherAxes checks if axes are unique.
    // Get the iteration axes.
    if (axesAreCursor) {
        iterationAxes = IPosition::otherAxes (ndim(), axes);
    } else {
        iterationAxes = axes;
    }
    // Get the cursorAxes.
    // Do this also if axesAreCursor=True, so we are sure they are
    // in the correct order.
    cursAxes = IPosition::otherAxes (ndim(), iterationAxes);
    // Check shape.
    if (Start.nelements() != Shape.nelements()) {
	throw(ArrayIteratorError("ArrayPositionIterator::ArrayPositionIterator"
				 " - ndim of origin and shape differ"));
    }
    for (uInt i=0; i < ndim(); i++) {
	if (Shape(i) < 0)
         throw(ArrayIteratorError("ArrayPositionIterator::ArrayPositionIterator"
				     " - Shape(i) < 0"));
    }
    Cursor = Start;
    End = Start + Shape - 1;
}

void ArrayPositionIterator::reset()
{
    Cursor = Start;
    atOrBeyondEnd = False;
}

Bool ArrayPositionIterator::atStart() const
{
    // Too expensive - we should set variables in next/previous
    return Cursor == Start;
}

// <thrown>
//     <item> ArrayIteratorError
// </thrown>
void ArrayPositionIterator::next()
{
    nextStep();
}

uInt ArrayPositionIterator::nextStep()
{
    // This could and should be made more efficient. 
    // next will step past the end (as it needs to for pastEnd to trigger).

    // Short circuit if we are iterating by the same dimensionality
    // as the array.
    if (iterationAxes.nelements() == 0){
        atOrBeyondEnd = True;
        Cursor = End;
	return ndim();
    }

    if (aips_debug) {
	// We can go past the end, but we should never be before the
	// start!
	if ((Start <= Cursor) == False)
	    throw(ArrayIteratorError("ArrayPositionIterator::next()"
				     " - Cursor before array start"));
    }

    // Increment the cursor.
    Int axis = 0;
    for (uInt i=0; i<iterationAxes.nelements(); i++) {
        axis = iterationAxes(i);
	Cursor(axis)++;
	if (Cursor(axis) <= End(axis)) {
	    break;
	}
	// Exceeded the axis. Reset it if not the last one.
	if (i < iterationAxes.nelements()-1) {
	    Cursor(axis) = Start(axis);
	} else {
	    atOrBeyondEnd = True;
	}
    }
    return axis;
}

IPosition ArrayPositionIterator::endPos() const
{
  IPosition endp = pos();
  for (uInt i=0; i<cursAxes.nelements(); i++) {
    uInt axis = cursAxes(i);
    endp(axis) = Shape(axis)-1;
  }
  return endp;
}

} //# NAMESPACE CASA - END
