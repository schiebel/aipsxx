// Plot1dData.cc
//#---------------------------------------------------------------------------
//# Copyright (C) 1995,2001
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
//# $Id: Plot1dData.cc,v 19.3 2004/11/30 17:50:25 ddebonis Exp $
//#---------------------------------------------------------------------------
#include <graphics/Graphics/Plot1dData.h>
#include <casa/iostream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//#---------------------------------------------------------------------------
Plot1dData::Plot1dData ():
            x_ (NULL), y_ (NULL), name_ (""), id_ (-1),
            whichYAxis_ (Y1Axis)
{
    //cout << "Plot1dData default ctor" << endl;
}
//#---------------------------------------------------------------------------
Plot1dData::Plot1dData (const Vector <Double> &x, const Vector <Double> &y, 
                        const String &name, Int id,
                        AssociatedYAxis whichYAxis):
            x_ (NULL), y_ (NULL), name_ (name), 
            id_ (id), whichYAxis_ (whichYAxis)

{
    //cout << "Plot1dData ctor: " << name << ", " << number << endl;

  // force copy semantics
  x_ = new Vector <Double> (x.copy());
  y_ = new Vector <Double> (y.copy());
}
//#---------------------------------------------------------------------------
Plot1dData::~Plot1dData ()
{
  // todo: (oct 95) this gets called too often:  unnecessary temporaries?
  //cout << "Plot1dData dtor: " << name_ << ", " << number_ << endl;

  if (x_) {
     delete x_;
     x_ = NULL;
     }
   if (y_) {
     delete y_;
     y_ = NULL;
     }
}
//#---------------------------------------------------------------------------
Plot1dData::Plot1dData (const Plot1dData &other)
{
    //cout << "Plot1dData copy ctor: " << other.name_ << ", " << other.number_
    // << endl;
  x_ = new Vector <Double> (*(other.x_));
  y_ = new Vector <Double> (*(other.y_));
  name_ = other.name_;
  id_ = other.id_;
  whichYAxis_ = other.whichYAxis_;
}
//#---------------------------------------------------------------------------
const Plot1dData &Plot1dData::operator = (const Plot1dData &other)
{
    //cout << "Plot1dData op = " << endl;

  if (this != &other) 
    { // prexvent assignment to self
      if (x_) delete x_;
      if (y_) delete y_;
      x_ = new Vector <Double> (*(other.x_));
      y_ = new Vector <Double> (*(other.y_));
      name_ = other.name_;
      id_ = other.id_;
      whichYAxis_ = other.whichYAxis_;
     }

  return *this;
}
//#---------------------------------------------------------------------------
Bool Plot1dData::ok () const
{
    // both vectors should be null, or both should be valid
  Int okay = ((x_ == NULL && y_ == NULL) || (x_ && y_));

    // if valid, they should both have the same number of elements
  if (x_)
     okay = okay && (x_->nelements () == y_->nelements ());

  if (okay)
    return True;
  else
    return False;
}
//#---------------------------------------------------------------------------


} //# NAMESPACE CASA - END

