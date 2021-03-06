//# Record2Interface.cc: Implementation of toArrayX functions
//# Copyright (C) 2001
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
//#
//# $Id: Record2Interface.cc,v 19.3 2004/11/30 17:50:15 ddebonis Exp $


#include <casa/Containers/RecordInterface.h>
#include <casa/Containers/RecordDesc.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Exceptions/Error.h>


namespace casa { //# NAMESPACE CASA - BEGIN

Array<Bool> RecordInterface::toArrayBool (const RecordFieldId& id) const
{
  return asArrayBool(id).copy();
}

Array<uChar> RecordInterface::toArrayuChar (const RecordFieldId& id) const
{
  return asArrayuChar(id).copy();
}

Array<Short> RecordInterface::toArrayShort (const RecordFieldId& id) const
{
  Array<Short> arr;
  Int whichField = idToNumber (id);
  switch (type(whichField)) {
  case TpUChar:
  case TpArrayUChar:
    {
      Array<uChar> tmp = asArrayuChar (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  default:
    arr = asArrayShort (id);
  }
  return arr;
}

Array<Int> RecordInterface::toArrayInt (const RecordFieldId& id) const
{
  Array<Int> arr;
  Int whichField = idToNumber (id);
  switch (type(whichField)) {
  case TpUChar:
  case TpArrayUChar:
    {
      Array<uChar> tmp = asArrayuChar (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpShort:
  case TpArrayShort:
    {
      Array<Short> tmp = asArrayShort (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  default:
    arr = asArrayInt (id);
  }
  return arr;
}

Array<uInt> RecordInterface::toArrayuInt (const RecordFieldId& id) const
{
  Array<uInt> arr;
  Int whichField = idToNumber (id);
  switch (type(whichField)) {
  case TpUChar:
  case TpArrayUChar:
    {
      Array<uChar> tmp = asArrayuChar (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpShort:
  case TpArrayShort:
    {
      Array<Short> tmp = asArrayShort (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  default:
    arr = asArrayuInt (id);
  }
  return arr;
}

Array<Float> RecordInterface::toArrayFloat (const RecordFieldId& id) const
{
  Array<Float> arr;
  Int whichField = idToNumber (id);
  switch (type(whichField)) {
  case TpUChar:
  case TpArrayUChar:
    {
      Array<uChar> tmp = asArrayuChar (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpShort:
  case TpArrayShort:
    {
      Array<Short> tmp = asArrayShort (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpInt:
  case TpArrayInt:
    {
      Array<Int> tmp = asArrayInt (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpUInt:
  case TpArrayUInt:
    {
      Array<uInt> tmp = asArrayuInt (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpDouble:
  case TpArrayDouble:
    {
      Array<Double> tmp = asArrayDouble (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  default:
    arr = asArrayFloat (id);
  }
  return arr;
}

Array<Double> RecordInterface::toArrayDouble (const RecordFieldId& id) const
{
  Array<Double> arr;
  Int whichField = idToNumber (id);
  switch (type(whichField)) {
  case TpUChar:
  case TpArrayUChar:
    {
      Array<uChar> tmp = asArrayuChar (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpShort:
  case TpArrayShort:
    {
      Array<Short> tmp = asArrayShort (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpInt:
  case TpArrayInt:
    {
      Array<Int> tmp = asArrayInt (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpUInt:
  case TpArrayUInt:
    {
      Array<uInt> tmp = asArrayuInt (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpFloat:
  case TpArrayFloat:
    {
      Array<Float> tmp = asArrayFloat (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  default:
    arr = asArrayDouble (id);
  }
  return arr;
}

Array<DComplex> RecordInterface::toArrayDComplex
                                          (const RecordFieldId& id) const
{
  Array<DComplex> arr;
  Int whichField = idToNumber (id);
  switch (type(whichField)) {
  case TpUChar:
  case TpArrayUChar:
    {
      Array<uChar> tmp = asArrayuChar (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpShort:
  case TpArrayShort:
    {
      Array<Short> tmp = asArrayShort (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpInt:
  case TpArrayInt:
    {
      Array<Int> tmp = asArrayInt (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpUInt:
  case TpArrayUInt:
    {
      Array<uInt> tmp = asArrayuInt (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpFloat:
  case TpArrayFloat:
    {
      Array<Float> tmp = asArrayFloat (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpDouble:
  case TpArrayDouble:
    {
      Array<Double> tmp = asArrayDouble (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpComplex:
  case TpArrayComplex:
    {
      Array<Complex> tmp = asArrayComplex (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  default:
    arr = asArrayDComplex (id);
  }
  return arr;
}

Array<Complex> RecordInterface::toArrayComplex
                                          (const RecordFieldId& id) const
{
  Array<Complex> arr;
  Int whichField = idToNumber (id);
  switch (type(whichField)) {
  case TpUChar:
  case TpArrayUChar:
    {
      Array<uChar> tmp = asArrayuChar (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpShort:
  case TpArrayShort:
    {
      Array<Short> tmp = asArrayShort (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpInt:
  case TpArrayInt:
    {
      Array<Int> tmp = asArrayInt (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpUInt:
  case TpArrayUInt:
    {
      Array<uInt> tmp = asArrayuInt (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpFloat:
  case TpArrayFloat:
    {
      Array<Float> tmp = asArrayFloat (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpDouble:
  case TpArrayDouble:
    {
      Array<Double> tmp = asArrayDouble (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  case TpDComplex:
  case TpArrayDComplex:
    {
      Array<DComplex> tmp = asArrayDComplex (id);
      arr.resize (tmp.shape());
      convertArray (arr, tmp);
      break;
    }
  default:
    arr = asArrayComplex (id);
  }
  return arr;
}

Array<String> RecordInterface::toArrayString (const RecordFieldId& id) const
{
  return asArrayString(id).copy();
}

} //# NAMESPACE CASA - END

