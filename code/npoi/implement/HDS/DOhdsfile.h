//# DOhdsfile.h: A simplified class for accessing a HDS file
//# Copyright (C) 1998,1999,2000
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
//# $Id: DOhdsfile.h,v 19.3 2004/11/30 17:50:40 ddebonis Exp $
#if defined(HAVE_HDS)

#ifndef NPOI_DOHDSFILE_H
#define NPOI_DOHDSFILE_H

#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <npoi/HDS/HDSDataFile.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class String;
class MethodResult;
class ParameterSet;
class Index;
class IPosition;
template <class T> class Vector;
template <class T> class Array;
template <class T> class Block;
} //# NAMESPACE CASA - END


// <summary>A simplified class for accessing a HDS file</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> Chapters 1 and 2 of the HDS manual (Introduction and Objects)
//   <li> The <linkto module="Arrays">Arrays</linkto> module
// </prerequisite>

// <etymology>
// The name MUST have the 'DO' prefix as this class is derived from
// ApplicationObject, and hence is classified as a distributed object. For the
// same reason the rest of its name must be in lower case. This class is a
// simplified version of the HDSFile class.
// </etymology>
//
// <synopsis>
// This class provides functions that allow the user the manipulate the data in
// a file stored in hds format.  In this respect this class is identical to the
// <linkto class="HDSFile">HDSFile</linkto> class. The user is encouraged to
// read the synopsis of that class for a general description of the
// capabilities and structure of a HDS file.
//
// This class is differs from the HDSFile class in the following ways:
// <ul>
// <li> You can only retrieve the data as strings or double precision numbers.
// </ul>
//
// There is a one-to-one correspondence between the functions in the glish
// hdsfile object (see the AIPS++ User Reference manual) and functions in
// this class. This is to simplify the porting from glish to C++ of a glish
// script using the hdsfile distributed object.
// </synopsis>
//
// <example>
// These examples are coded in the tDOhdsfile.h file.
// <h4>Example 1:</h4>
// In this example a file is opened and some data is extracted.
// ...
// <srcblock>
// </srcblock>
// </example>
//
// <motivation> 
// This class was written to make the HDSFile class usable from glish
// </motivation>
//
// <thrown>
// Errors are not thrown directly by this class. This class will try to detect
// bad input arguments to prevent the HDSFile class from throwing exceptions.
// </thrown>
//
// <todo asof="1998/10/16">
//   <li> See the list for the HDSFile class
// </todo>

class hdsfile: public ApplicationObject
{
public:
  // Open a existing HDS file. By default the file is opened read-write. It is
  // recommended that you create a const hdsfile if you open the file
  // read-only. This is so you can determine at compile time that you are only
  // using functions which do not modify the file. This prevents a runtime
  // exception for being thrown.
  hdsfile(const String& filename, const Bool& readonly=False);

  // The destructor saves the file to disk and closes it.
  virtual ~hdsfile();

  // returns a string containing all the sub-nodes of the current node.
  Vector<String> ls();

  // replaces the current node with the specified sub-node. Can move to a
  // sub-sub-node with the syntax cd("scandata.inputbeam(1).fdlpos"). ie., the
  // 'dot' is used to seperate nodes and elements of a vector structure are
  // one-relative and enclosed within a pair of brackets. Throws an exception
  // if it cannot move to the specified node.
  void cd(const String& node);

  // Moves to the parent node of the current one. Throws and exception
  // (AipsError) if we are at the top node.
  void cdup();

  // Moves to the top node of the current file. 
  void cdtop();

  // returns the name of the current node. 
  String name();

  // returns the full-name (ie., including parent nodes) of the current node. 
  String fullname();

  // returns the type of the current node. 
  String type();

  // returns the shape of the current node. Returns a Vector with no elements
  // if the node is a scalar.
  Vector<Index> shape();

  // Returns the numerical data at the current node as an Array of double
  // precision Floating point numbers.
  Array<Double> get();
  
  // Returns the character data at the current node as an Array of strings
  Array<String> getstring();
  
//#   // Function which checks the internal data of this class for consistant
//#   // values. Returns True if everything is fine otherwise returns False.
//#   Bool DOok() const;

  // return the name of this object type the distributed object system.
  // This function is required as part of the DO system
  virtual String className() const;

  // the returned vector contains the names of all the methods which may be
  // used via the distributed object system.
  // This function is required as part of the DO system
  virtual Vector<String> methods() const;

  // the returned vector contains the names of all the methods which are to
  // trivial to warrent automatic logging.
  // This function is required as part of the DO system
  virtual Vector<String> noTraceMethods() const;

  // Run the specified method. This is the function used by the distributed
  // object system to invoke any of the specified member functions in thios
  // class.
  // This function is required as part of the DO system
  virtual MethodResult runMethod(uInt which, ParameterSet& parameters, 
				 Bool runMethod);
private:
  //# The following functions are defined to avoid default versions being
  //# generated by the compiler. They are made private to prevent users from
  //# using them.
  hdsfile& operator= (const hdsfile& other);
  hdsfile(const hdsfile& other);
  // Parse a string of the format 'scandata.inputbeam(2).fdlpos'
  Bool parseNodeString(Block<String>& nodeNames, 
		       Block<IPosition>& nodeElements,
		       String fullNode);
  //# All the work is done by this class.
  HDSDataFile itsFile;
};

#endif
#endif
