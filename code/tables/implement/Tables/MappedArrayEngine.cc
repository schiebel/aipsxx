//# MappedArrayEngine.cc: Templated virtual column engine to map a table array
//# Copyright (C) 2005
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
//# $Id: MappedArrayEngine.cc,v 19.1 2005/05/19 07:26:10 gvandiep Exp $

//# Includes
#include <tables/Tables/MappedArrayEngine.h>
#include <tables/Tables/TableRecord.h>
#include <tables/Tables/DataManError.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Containers/Record.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/ValTypeId.h>


namespace casa { //# NAMESPACE CASA - BEGIN

template<class S, class T>
MappedArrayEngine<S,T>::MappedArrayEngine (const String& virtualColumnName,
					   const String& storedColumnName)
: BaseMappedArrayEngine<S,T> (virtualColumnName, storedColumnName)
{}

template<class S, class T>
MappedArrayEngine<S,T>::MappedArrayEngine (const Record& spec)
: BaseMappedArrayEngine<S,T> ()
{
  if (spec.isDefined("SOURCENAME")  &&  spec.isDefined("TARGETNAME")) {
    setNames (spec.asString("SOURCENAME"), spec.asString("TARGETNAME"));
  }
}

template<class S, class T>
MappedArrayEngine<S,T>::MappedArrayEngine (const MappedArrayEngine<S,T>& that)
: BaseMappedArrayEngine<S,T> (that)
{}

template<class S, class T>
MappedArrayEngine<S,T>::~MappedArrayEngine()
{}

//# Clone the engine object.
template<class S, class T>
DataManager* MappedArrayEngine<S,T>::clone() const
{
  DataManager* dmPtr = new MappedArrayEngine<S,T> (*this);
  return dmPtr;
}


//# Return the type name of the engine (i.e. its class name).
template<class S, class T>
String MappedArrayEngine<S,T>::dataManagerType() const
{
  return className();
}
//# Return the class name.
//# Get the data type names using class ValType.
template<class S, class T>
String MappedArrayEngine<S,T>::className()
{
  return "MappedArrayEngine<" + valDataTypeId (static_cast<S*>(0)) + ","
                              + valDataTypeId (static_cast<T*>(0)) + ">";
}

template<class S, class T>
String MappedArrayEngine<S,T>::dataManagerName() const
{
  return virtualName();
}

template<class S, class T>
Record MappedArrayEngine<S,T>::dataManagerSpec() const
{
  Record spec;
  spec.define ("SOURCENAME", virtualName());
  spec.define ("TARGETNAME", storedName());
  return spec;
}

template<class S, class T>
DataManager* MappedArrayEngine<S,T>::makeObject (const String&,
						 const Record& spec)
{
  DataManager* dmPtr = new MappedArrayEngine<S,T>(spec);
  return dmPtr;
}
template<class S, class T>
void MappedArrayEngine<S,T>::registerClass()
{
  DataManager::registerCtor (className(), makeObject);
}


template<class S, class T>
void MappedArrayEngine<S,T>::getArray (uInt rownr, Array<S>& array)
{
  Array<T> target(array.shape());
  roColumn().get (rownr, target);
  convertArray (array, target);  
}
template<class S, class T>
void MappedArrayEngine<S,T>::putArray (uInt rownr, const Array<S>& array)
{
  Array<T> target(array.shape());
  convertArray (target, array);
  rwColumn().put (rownr, target);
}

template<class S, class T>
void MappedArrayEngine<S,T>::getSlice (uInt rownr, const Slicer& slicer,
				       Array<S>& array)
{
  Array<T> target(array.shape());
  roColumn().getSlice (rownr, slicer, target);
  convertArray (array, target);  
}
template<class S, class T>
void MappedArrayEngine<S,T>::putSlice (uInt rownr, const Slicer& slicer,
				       const Array<S>& array)
{
  Array<T> target(array.shape());
  convertArray (target, array);
  rwColumn().putSlice (rownr, slicer, target);
}

template<class S, class T>
void MappedArrayEngine<S,T>::getArrayColumn (Array<S>& array)
{
  Array<T> target(array.shape());
  roColumn().getColumn (target);
  convertArray (array, target);  
}
template<class S, class T>
void MappedArrayEngine<S,T>::putArrayColumn (const Array<S>& array)
{
  Array<T> target(array.shape());
  convertArray (target, array);
  rwColumn().putColumn (target);
}

template<class S, class T>
void MappedArrayEngine<S,T>::getColumnSlice (const Slicer& slicer,
					     Array<S>& array)
{
  Array<T> target(array.shape());
  roColumn().getColumn (slicer, target);
  convertArray (array, target);  
}
template<class S, class T>
void MappedArrayEngine<S,T>::putColumnSlice (const Slicer& slicer,
					     const Array<S>& array)
{
  Array<T> target(array.shape());
  convertArray (target, array);
  rwColumn().putColumn (slicer, target);
}

} //# NAMESPACE CASA - END

