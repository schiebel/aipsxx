//# HDSLib.h:
//# Copyright (C) 1997,1998,1999
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
//# $Id: HDSLib.h,v 19.3 2004/11/30 17:50:40 ddebonis Exp $

#if defined(HAVE_HDS)

#ifndef NPOI_HDSLIB_H
#define NPOI_HDSLIB_H

#include <casa/aips.h>
#include <npoi/HDS/HDSDef.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
template <class T> class Vector;
template <class T> class Array;
class IPosition;
class String;
} //# NAMESPACE CASA - END

class HDSNode;

// <summary>C++ wrappers to the Hierarchical Data System</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
//   <li> SomeOtherClass
//   <li> some concept
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>

class HDSLib
{
public: 
  // Open container file
  static void hds_open(const String& fileName, HDSDef::IOMode mode, 
 		       HDSNode& topNode, Int& status);
  // Create container file
  // <group>
  static void hds_new(const String& fileName, const String& nodeName, 
		      const String& nodeType, const IPosition& shape,
		      HDSNode& topNode, Int& status);
  static void hds_new(const String& fileName, const String& nodeName, 
		      const HDSDef::Type nodeType, const IPosition& shape,
		      HDSNode& topNode, Int& status);
  // </group>
  //# Copy an object to a new container file 
//#  static void hds_copy(const HDSNode& oldNode, const String & fileName, 
//#		   const String & newNode, Int & status);
  // Erase container file 
  static void hds_erase(const HDSNode& whichNode, Int& status);
  // Close down HDS
  static void hds_stop(Int& status);

//#  // Free container file 
//#  static void hds_free(const HDSNode& whichNode, Int & status);
//#  // Lock container file
//#  static void hds_lock(const HDSNode& node, Int & status);

  // Show HDS statistics
  static void hds_show(const HDSDef::showTypes topic, Int& status);
  // Enquire the current state of HDS
  static void hds_state(HDSDef::state& state, Int& status);
  // Trace object path
  static void hds_trace(const HDSNode& node, Int& nLevels, 
			String& nodePath, String& fileName, Int& status);

//#  // Link locator group
//#  static void hds_link(const HDSNode& node, const Group& thisGroup, 
//#		   Int& status);
//#  // Flush locator group
//#  static void hds_flush(const Group& thisGroup, Int& status);
//#  // Enquire locator group
//#  static void hds_group(const HDSNode& node, Group& thisGroup, Int& status);

//#  // Obtain tuning parameter value
//#  static void hds_gtune(const HDSDef::Tune whichParameter, Int& currentValue, 
//#		    Int& status);
//#  // Set HDS tuning parameter
//#  static void hds_tune(const HDSDef::Tune whichParameter, const String& newValue,
//#		   Int& status);

//#  // Perform a wild-card search for HDS container files
//#  static void hds_wild(const String& fileNameRegex, const HDSDef::IOMode
//#		   accessMode, Identifier& whichSearch, HDSNode& topNode,
//#		   Int& status);
//#  // End a wild-card search for HDS container files 
//#  static void hds_ewild(Identifier& thisSearch, Int& status);


  //#Alter object size
//#  static void dat_alter(const HDSNode& node, const IPosition& shape, 
//#		    Int& status);
  // Annul locator
  static void dat_annul(HDSNode& node, Int& status);
//#  // Map primitive as basic units
//#  static void dat_basic();
//#  // Copy one structure level
//#  static void dat_ccopy();
//#  // Create type string
//#  static void dat_cctyp();
  // Locate cell
  static void dat_cell(const HDSNode& arrLoc, const IPosition& whichElem,
		       HDSNode& cellLoc, Int& status);
//#  // Enquire character string length
//#  static void dat_clen();
  // Clone locator
  static void dat_clone(const HDSNode& oldNode, HDSNode& newNode,
		    Int& status);
//#  // Coerce object shape
//#  static void dat_coerc();
//#  // Copy object
//#  static void dat_copy();
//#  // Obtain primitive data representation information
//#  static void dat_drep();
//#  // Erase component
//#  static void dat_erase();
//#  // Translate error status
//#  static void dat_ermsg();
  // Find named component
  static void dat_find(const HDSNode& parentLoc, const String& compName,
		       HDSNode& compLoc, Int& status);

//# // Read primitive of the specified type. The dataPtr must point to an area of
//# // memory big enough to contain the data. ie., the user of this function is
//# // responsible for allocating and deallocating the dataPtr.
//# // <group>
//# static void dat_get(const HDSNode& loc, HDSDef::Type dataType,
//#	      const IPosition& shape, uChar * dataPtr, Int& status);
//# static void dat_get(const HDSNode& loc, const String& dataType,
//#	      const IPosition& shape, uChar * dataPtr, Int& status);
//# // </group>

//# // Read primitive of the appropriate type. The dataPtr must point to an area
//# // of memory big enough to contain the data. ie., the user of this function
//# // is responsible for allocating and deallocating the dataPtr.
//# // <group>
//# static void dat_getc(const HDSNode& loc, const IPosition& shape, 
//#	       Double * dataPtr, Int& status);
//# static void dat_getd(const HDSNode& loc, const IPosition& shape, 
//#	       Double * dataPtr, Int& status);
//# static void dat_geti(const HDSNode& loc, const IPosition& shape, 
//#	       Int * dataPtr, Int& status);
//# static void dat_getl(const HDSNode& loc, const IPosition& shape, 
//#	       Bool * dataPtr, Int& status);
//# static void dat_getr(const HDSNode& loc, const IPosition& shape, 
//#	       Float * dataPtr, Int& status);
//# // </group>

  // Read scalar primitive of type String, Double, Int, Bool or Float resp.
  // <group>
  static void dat_get0c(const HDSNode& loc, String& value, Int& status);
  static void dat_get0d(const HDSNode& loc, Double& value, Int& status);
  static void dat_get0i(const HDSNode& loc, Int& value, Int& status);
  static void dat_get0l(const HDSNode& loc, Bool& value, Int& status);
  static void dat_get0r(const HDSNode& loc, Float& value, Int& status);
  // </group>

  // Read vector primitive of type String, Double, Int, Bool or Float resp. The
  // Vector is always resized to fit the data.
  // <group>
  static void dat_get1c(const HDSNode& loc, Vector<String>& values, 
			Int& status);
  static void dat_get1d(const HDSNode& loc, Vector<Double>& values, 
			Int& status);
  static void dat_get1i(const HDSNode& loc, Vector<Int>& values, 
			Int& status);
  static void dat_get1l(const HDSNode& loc, Vector<Bool>& values, 
			Int& status);
  static void dat_get1r(const HDSNode& loc, Vector<Float>& values, 
			Int& status);
  // </group>

  // Read array primitive of type String, Double, Int, Bool or Float resp. The
  // Array is always resized to fit the data.
  // <group>
  static void dat_getnc(const HDSNode& loc, Array<String>& values, 
			Int& status);
  static void dat_getnd(const HDSNode& loc, Array<Double>& values, 
			Int& status);
  static void dat_getni(const HDSNode& loc, Array<Int>& values, 
			Int& status);
  static void dat_getnl(const HDSNode& loc, Array<Bool>& values, 
			Int& status);
  static void dat_getnr(const HDSNode& loc, Array<Float>& values, 
			Int& status);
  // </group>

//# //  Read vectorised primitive of type String, Double, Int, Bool or Float
//# //  resp. The Vector is always resized to fit the data.
//# // <group>
//# static void dat_getvc(const HDSNode& loc, Vector<String>& values, 
//#		Int& status);
//# static void dat_getvd(const HDSNode& loc, Vector<Double>& values, 
//#		Int& status);
//# static void dat_getvi(const HDSNode& loc, Vector<Int>& values, 
//#		Int& status);
//# static void dat_getvl(const HDSNode& loc, Vector<Bool>& values, 
//#		Int& status);
//# static void dat_getvr(const HDSNode& loc, Vector<Float>& values, 
//#		Int& status);
//# // </group>

  // Index into component list
  static void dat_index(const HDSNode& loc, Int index, 
			HDSNode& indexLoc, Int& status);

  // Enquire primitive precision
  static void dat_len(const HDSNode& loc, Int& bytes, Int& status);

//#  // Map primitive
//#  static void dat_map();
//#  // Map primitive
//#  static void dat_mapx();
//#  // Map array primitive
//#  static void dat_mapn();
//#  // Map vectorised primitive
//#  static void dat_mapv();
//#  // Alter object shape
//#  static void dat_mould();
//#  // Move object
//#  static void dat_move();
//#  // Assign object name to message token
//#  static void dat_msg();

  // Enquire object name
  static void dat_name(const HDSNode& loc, String& name, Int& status);

  // Enquire number of components
  static void dat_ncomp(const HDSNode& loc, Int& ncomp, Int& status);

  // Create a component of the specified type
  // <group>
  static void dat_new(const HDSNode& parentLoc,
		      const String& compName, const String& compType,
		      const IPosition& shape, Int& status);
  static void dat_new(const HDSNode& parentLoc,
		      const String& compName, const HDSDef::Type nodeType,
		      const IPosition& shape, Int& status);
  // </group>

  // Create a scalar component of type Double, Int, Bool or Float resp.
  // <group>
  static void dat_new0d(const HDSNode& parentLoc, 
			const String& compName, Int& status);
  static void dat_new0i(const HDSNode& parentLoc, 
			const String& compName, Int& status);
  static void dat_new0l(const HDSNode& parentLoc, 
			const String& compName, Int& status);
  static void dat_new0r(const HDSNode& parentLoc, 
			const String& compName, Int& status);
  // </group>

  // Create a scalar string component of specified length
  static void dat_new0c(const HDSNode& parentLoc, 
			const String& compName, const Int& stringLength,
			Int& status);

  // Create vector component of type Double, Int, Bool or Float resp.
  // <group>
  static void dat_new1d(const HDSNode& parentLoc, const String& compName, 
			const Int& length, Int& status);
  static void dat_new1i(const HDSNode& parentLoc, const String& compName, 
			const Int& length, Int& status);
  static void dat_new1l(const HDSNode& parentLoc, const String& compName, 
			const Int& length, Int& status);
  static void dat_new1r(const HDSNode& parentLoc, const String& compName, 
			const Int& length, Int& status);
  // </group>
  
  // Create vector string component of specified length
  static void dat_new1c(const HDSNode& parentLoc, 
			const String& compName, const Int& stringLength,
			const Int& length, Int& status);

//#  // Create string component
//#  static void dat_newc();

  // Find parent
  static void dat_paren(const HDSNode& childLoc, HDSNode& parentLoc,
			Int& status);

//#  // Enquire storage precision
//#  static void dat_prec();
//#  // Enquire object primitive
//#  static void dat_prim();
  // Set or enquire primary/secondary locator
  static void dat_prmry(const Bool& setGet, HDSNode& node, Bool& primary,
			Int& status);
//#  // Write primitive
//#  static void dat_put();
//#  // Write primitive
//#  static void dat_putx();
  // Write scalar primitive of type String, Double, Int, Bool or Float resp.
  // <group>
  static void dat_put0c(const HDSNode& loc, 
			const String& value, Int& status);
  static void dat_put0d(const HDSNode& loc, 
			const Double& value, Int& status);
  static void dat_put0i(const HDSNode& loc,
			const Int& value, Int& status);
  static void dat_put0l(const HDSNode& loc,
			const Bool& value, Int& status);
  static void dat_put0r(const HDSNode& loc,
			const Float& value, Int& status);
  // </group>

  // Write vector primitive of type String, Double, Int, Bool or Float resp.
  // <group>
  static void dat_put1c(const HDSNode& loc, const Vector<String>& values,
			Int& status);
  static void dat_put1d(const HDSNode& loc, const Vector<Double>& values,
			Int& status);
  static void dat_put1i(const HDSNode& loc, const Vector<Int>& values,
			Int& status);
  static void dat_put1l(const HDSNode& loc, const Vector<Bool>& values,
			Int& status);
  static void dat_put1r(const HDSNode& loc, const Vector<Float>& values,
			Int& status);
  // </group>

  // Write array primitive of type String, Double, Int, Bool or Float resp.
  // <group>
//#  static void dat_putnc(const HDSNode& loc, const Array<String>& values,
//#			Int& status);
//#  static void dat_putnd(const HDSNode& loc, const Array<Double>& values,
//#			Int& status);
//#  static void dat_putni(const HDSNode& loc, const Array<Int>& values,
//#			Int& status);
//#  static void dat_putnl(const HDSNode& loc, const Array<Bool>& values,
//#			Int& status);
  static void dat_putnr(const HDSNode& loc, const Array<Float>& values,
 			Int& status);
  // </group>

//#  static void dat_putnx();
//#  // Write vectorised primitive
//#  static void dat_putvx();

//#  // Obtain reference name for object
//#  static void dat_ref(const HDSNode& loc, String& refName, Int& status);

//#  // Enquire the reference count for a container file
//#  static void dat_refct();
//#  // Rename object
//#  static void dat_renam();
//#  // Reset object state
//#  static void dat_reset();
//#  // Change object type
//#  static void dat_retyp();

  // Enquire object shape
  static void dat_shape(const HDSNode& loc, IPosition& shape, 
			Int& status);

  // Enquire object size
  static void dat_size(const HDSNode& loc, Int& length, Int& status);

//#  // Locate slice
//#  static void dat_slice();

  // Enquire object state
  static void dat_state(const HDSNode& loc, 
			Bool& isDefined, Int& status);

  // Enquire object structure
  static void dat_struc(const HDSNode& loc, 
			Bool& isAStructure, Int& status);

//#  // Create temporary object
//#  static void dat_temp();

  // Enquire component existence
  static void dat_there(const HDSNode& loc, const String& name,
			Bool& exists, Int& status);

  // Enquire object type. Use the latter function only if the locator points to
  // a primitive type, otherwise an exception is thrown.
  // <group>
  static void dat_type(const HDSNode& loc, String& type, Int& status);
  static void dat_type(const HDSNode& loc, HDSDef::Type& type, 
		       Int& status);
  // </group>

//#  // Unmap object
//#  static void dat_unmap();

  // Enquire locator valid
  static void dat_valid(const HDSNode& node, Bool& isValid, Int& status);

  // Vectorise object
  static void dat_vec(const HDSNode& loc, HDSNode& vecLoc, Int& status);

//#  // Where is primitive data in file?
//#  static void dat_where();
};

#endif
#endif
