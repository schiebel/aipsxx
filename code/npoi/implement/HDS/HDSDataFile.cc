//# HDSDataFile.cc: A class that repesents a HDS file.
//# Copyright (C) 1998,1999,2002
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
//# $Id: HDSDataFile.cc,v 19.2 2004/08/25 05:49:26 gvandiep Exp $

#if defined(HAVE_HDS)
#include <npoi/HDS/HDSDataFile.h>
#include <npoi/HDS/HDSLib.h>
#include <npoi/HDS/HDSDef.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Vector.h>
#include <casa/Exceptions/Error.h>
#include <casa/Arrays/IPosition.h>
#include <casa/BasicSL/String.h>
#include <casa/iostream.h>

HDSDataFile::HDSDataFile(const String& filename, const Bool readonly)
  :itsCurLoc(),
   itsTopLoc()
{
  HDSDef::IOMode mode = HDSDef::UPDATE;
  if (readonly) mode = HDSDef::READ;
  Int status = HDSDef::SAI_OK;
  HDSLib::hds_open(filename, mode, itsTopLoc, status);
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::HDSDataFile - Could not open the file"));
  }
  itsCurLoc = itsTopLoc;
} 

HDSDataFile::~HDSDataFile() 
{
}

Vector<String> HDSDataFile::ls() const {
  Vector<String> retVal;
  Bool isAstructure = False;
  Int status = HDSDef::SAI_OK;
  HDSLib::dat_struc(itsCurLoc, isAstructure, status);
  if (isAstructure) {
    Int nComp = 0;
    HDSLib::dat_ncomp(itsCurLoc, nComp, status);
    retVal.resize(nComp);
    for (Int i = 0; i < nComp; i++) {
      HDSNode nodeLoc;
      HDSLib::dat_index(itsCurLoc, i+1, nodeLoc, status);
      HDSLib::dat_name(nodeLoc, retVal(i), status);
    }
  }
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::ls - "
		    "problem getting the elements of the specified node"));
  }
  return retVal;
}

String HDSDataFile::name() const {
  String retVal;
  Int status = HDSDef::SAI_OK;
  HDSLib::dat_name(itsCurLoc, retVal, status);
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::name - "
		    "problem getting the name of the current node"));
  }
  return retVal;
}

String HDSDataFile::fullname() const {
  String retVal;
  Int status = HDSDef::SAI_OK;
  String fileName;
  Int nLevels;
  HDSLib::hds_trace(itsCurLoc, nLevels, retVal, fileName, status);
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::name - "
		    "problem getting the name of the current node"));
  }
  return retVal;
}

String HDSDataFile::type() const {
  String retVal;
  Int status = HDSDef::SAI_OK;
  HDSLib::dat_type(itsCurLoc, retVal, status);
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::type - "
		    "problem getting the type of the current node"));
  }
  return retVal;
}

IPosition HDSDataFile::shape() const {
  IPosition retVal;
  Int status = HDSDef::SAI_OK;
  HDSLib::dat_shape(itsCurLoc, retVal, status);
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::shape - "
		    "problem getting the shape of the current node"));
  }
  return retVal;
}

void HDSDataFile::cd(const String& newNode) {
  Int status = HDSDef::SAI_OK;
  HDSNode newLoc;
  HDSLib::dat_find(itsCurLoc, newNode, newLoc, status);
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::cd - problem changing to node " + newNode));
  }
  itsCurLoc = newLoc;
}

void HDSDataFile::cd(const String& newNode, uInt whichElem) {
  cd(newNode);
  HDSNode newLoc;
  Int status = HDSDef::SAI_OK;
  const IPosition elem = toIPositionInArray(whichElem, shape());
  cout << "Getting element: " << elem << " from shape " << shape() << endl;
  HDSLib::dat_cell(itsCurLoc, elem, newLoc, status);
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::cd - problem changing the current node to "
		    "cell " + whichElem));
  }
  itsCurLoc = newLoc;
}

void HDSDataFile::cd(const String& newNode, const IPosition& element) {
  cd(newNode);
  HDSNode newLoc;
  Int status = HDSDef::SAI_OK;
  HDSLib::dat_cell(itsCurLoc, element, newLoc, status);
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::cd - problem changing the current node to "
		    "the specified element"));
  }
  itsCurLoc = newLoc;
}

void HDSDataFile::cdTop() {
  itsCurLoc = itsTopLoc;
}

void HDSDataFile::cdUp() {
  Int status = HDSDef::SAI_OK;
  HDSNode newLoc;
  HDSLib::dat_paren(itsCurLoc, newLoc, status);
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::cdUp - "
 		    "problem changing to the parent node"));
  }
  itsCurLoc = newLoc;
}

void HDSDataFile::get(Array<Float>& data) const {
  Int status = HDSDef::SAI_OK;
  const IPosition dShape = shape();
  const uInt ndim = dShape.nelements();
  if (ndim == 0) {
    Float scalar;
    HDSLib::dat_get0r(itsCurLoc, scalar, status);
    data.resize(IPosition(1,1));
    data(IPosition(1,0)) = scalar;
  } else if (ndim == 1) {
    data.resize(dShape);
    Vector<Float> vec(data); // data and vec share the same storage
    HDSLib::dat_get1r(itsCurLoc, vec, status);
  } else {
    data.resize(dShape);
    HDSLib::dat_getnr(itsCurLoc, data, status);
  }
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::get(Array<Float>) - "
		    "problem getting the data"));
  }
}

void HDSDataFile::get(Array<Double>& data) const {
  Int status = HDSDef::SAI_OK;
  const IPosition dShape = shape();
  const uInt ndim = dShape.nelements();
  if (ndim == 0) {
    Double scalar;
    HDSLib::dat_get0d(itsCurLoc, scalar, status);
    data.resize(IPosition(1,1));
    data(IPosition(1,0)) = scalar;
  } else if (ndim == 1) {
    data.resize(dShape);
    Vector<Double> vec(data);
    HDSLib::dat_get1d(itsCurLoc, vec, status);
  } else {
    data.resize(dShape);
    HDSLib::dat_getnd(itsCurLoc, data, status);
  }
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::get(Array<Double>) - "
		    "problem getting the data"));
  }
}

void HDSDataFile::get(Array<String>& data) const {
  Int status = HDSDef::SAI_OK;
  const IPosition dShape = shape();
  const uInt ndim = dShape.nelements();
  if (ndim == 0) {
    data.resize(IPosition(1,1));
    HDSLib::dat_get0c(itsCurLoc, data(IPosition(1,0)), status);
  } else if (ndim == 1) {
    data.resize(dShape);
    Vector<String> vec(data); // data and vec share the same storage
    HDSLib::dat_get1c(itsCurLoc, vec, status);
  } else {
    data.resize(dShape);
    HDSLib::dat_getnc(itsCurLoc, data, status);
  }
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::get(Array<String>) - "
		    "problem getting the data"));
  }
}

void HDSDataFile::get(Float& data) const {
  Int status = HDSDef::SAI_OK;
  const IPosition dShape = shape();
  const uInt ndim = dShape.nelements();
  if (ndim == 0) {
    HDSLib::dat_get0r(itsCurLoc, data, status);
  } else if (ndim == 1) {
    Vector<Float> vec(dShape);
    HDSLib::dat_get1r(itsCurLoc, vec, status);
    data = vec(0);
  } else {
    Array<Float> arr(dShape);
    HDSLib::dat_getnr(itsCurLoc, arr, status);
    data = arr(dShape*0);
  }
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::get(Float) - "
		    "problem getting the data"));
  }
}

void HDSDataFile::get(Double& data) const {
  Int status = HDSDef::SAI_OK;
  const IPosition dShape = shape();
  const uInt ndim = dShape.nelements();
  if (ndim == 0) {
    HDSLib::dat_get0d(itsCurLoc, data, status);
  } else if (ndim == 1) {
    Vector<Double> vec(dShape);
    HDSLib::dat_get1d(itsCurLoc, vec, status);
    data = vec(0);
  } else {
    Array<Double> arr(dShape);
    HDSLib::dat_getnd(itsCurLoc, arr, status);
    data = arr(dShape*0);
  }
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::get(Double) - "
		    "problem getting the data"));
  }
}

void HDSDataFile::get(String& data) const {
  Int status = HDSDef::SAI_OK;
  const IPosition dShape = shape();
  const uInt ndim = dShape.nelements();
  if (ndim == 0) {
    HDSLib::dat_get0c(itsCurLoc, data, status);
  } else if (ndim == 1) {
    Vector<String> vec(dShape);
    HDSLib::dat_get1c(itsCurLoc, vec, status);
    data = vec(0);
  } else {
    Array<String> arr(dShape);
    HDSLib::dat_getnc(itsCurLoc, arr, status);
    data = arr(dShape*0);
  }
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSDataFile::get(String) - problem getting the data"));
  }
}

Bool HDSDataFile::exists(const String& nodeName) const {
  Int status = HDSDef::SAI_OK;
  Bool retVal;
  HDSLib::dat_there(itsCurLoc, nodeName, retVal, status);
  if (status != HDSDef::SAI_OK) retVal = False;
  return retVal;
}


Bool HDSDataFile::exists(const String& nodeName, uInt whichElem) const {
  if (!exists(nodeName)) return False;
  Int status = HDSDef::SAI_OK;
  HDSNode loc;
  HDSLib::dat_find(itsCurLoc, nodeName, loc, status);
  IPosition nodeShape;
  HDSLib::dat_shape(loc, nodeShape, status);
  if (status != HDSDef::SAI_OK) return False;
  if (Int(whichElem) >= nodeShape.product()) return False;
  return True;
}

Bool HDSDataFile::exists(const String& nodeName,
		     const IPosition& whichElem) const {
  if (!exists(nodeName)) return False;
  Int status = HDSDef::SAI_OK;
  HDSNode loc;
  HDSLib::dat_find(itsCurLoc, nodeName, loc, status);
  IPosition nodeShape;
  HDSLib::dat_shape(loc, nodeShape, status);
  if (status != HDSDef::SAI_OK) return False;
  if (whichElem.nelements() != nodeShape.nelements()) return False;
  return isInsideArray(whichElem, nodeShape);  
}

HDSDataFile& HDSDataFile::operator=(const HDSDataFile& other) {
  if (this != &other) {
    itsCurLoc = other.itsCurLoc;
    itsTopLoc = other.itsTopLoc;
  }
  return *this;
}

#endif
// Local Variables: 
// compile-command: "gmake HDSDataFile"
// End: 
