//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1998,1999
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
//# $Id: HDSDataFile.h,v 19.3 2004/11/30 17:50:40 ddebonis Exp $

#if defined(HAVE_HDS)

#ifndef NPOI_HDSDATAFILE_H
#define NPOI_HDSDATAFILE_H

#include <casa/aips.h>
#include <npoi/HDS/HDSNode.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class IPosition;
class Slicer;
class String;
template <class T> class Vector;
template <class T> class Array;
} //# NAMESPACE CASA - END


// <summary>An class for accessing the data in a HDS format file</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> Chapters 1 and 2 of the HDS manual (Introduction and Objects)
//   <li> The <linkto module="Arrays">Arrays</linkto> module
// </prerequisite>
//
// <etymology> This class allows you manipulate a file stored in Hierarchical
// Data System format.  
// </etymology>
//
// <synopsis>
// The Heirarchical Data System is a file storage format developed by the
// Starlink project in the UK. It is described in Starlink usernote 92.10,
// which can found at the website http://star-www.rl.ac.uk/.

// The essential features of HDS are that it allows hetrogenious data types to
// be stored in a heirarchical structure. A HDS file consists of a number of
// "nodes". A node may contain any number of arrays of data (of differing
// types) or other nodes.  The analogy with the unix file system is very strong
// and has been exploited in the naming of members functions in this class.
// <note role=tip> 
// The HDS documentation uses the term objects rather than nodes when
// discussing HDS. I have avoided using this term as object has a different,
// more technical meaning in C++.
// </note>

// The fundamental data types supported by HDS are, Int, Float, Double, Bool,
// and String. All but the last of these are numeric data types. An element of
// a node can contain a scalar or Array of these types.  Each element of a node
// is identified by a name that must be a unique string within that node. Each
// element of a node also has a type. This is either, '_INTEGER', '_REAL',
// '_DOUBLE', '_LOGICAL', 'CHAR[*n]', for the types listed above or a string
// that does not begin with an underscore for user defined types.  User defined
// types indicate that the element is a sub-node of the current node and that
// may contain other data or nodes.

// There is a strong analogy with the unix filesystem. The top node is the file
// itself and corresponds to the root directory (/). Within the root directory
// there are files containing data. Each file has a name. Within the root
// directory there are also other directories, these correspond to sub-nodes.

// All the functions in this class operate on the HDS file with respect to the
// current node. The current node is initially the top of the HDS file when the
// file is opened and may by changed to other nodes within the HDS file using
// the cd member function. The current node in conceptially equivalent to the
// current directory in unix.

// Unlike unix the filenames (ie node names) in HDS are case
// insensitive. Because of its Fortran/VMS heritage the HDS library will
// convert all strings to upper case. 

// The get member functions are used to access the numeric data within the
// current node. The versions which take Array arguments will always resize the
// supplied Array to the required size (if necessary). The versions which take
// scalar arguements will return the first element of an array if the data is
// an Array.

// </synopsis>
//
// <example>
// These examples are coded in the dHDSFile.cc file.
// <h4>Example 1:</h4>
// In this example a file is opened and some data is extracted.
// <srcblock>
// HDSDataFile betelgeuse("betelgeuse.sdf");
// // Get the observing time
// betelgeuse.cd("OBS-TIME");
// const String obsTime;
// betelgeuse.get(obsTime);
// betelgeuse.cd("..");
// // get the visibility amplitude
// betelgeuse.cd("visibility");
// Vector<Double> visAmp;
// betelgeuse.get(visAmp);
// betelgeuse.cd("..");
// // get the real and imaginary parts of the triple product and put them in a
// // Vector<Complex>
// betelgeuse.cd("triple_product");
// betelgeuse.cd("real");
// // ...you get the idea...
// </srcblock>
// </example>
//
// <motivation>
// To access the data in HDS files from the NPOI in a simpler (and object
// oriented!) way.
// </motivation>
//
// <thrown>
//    <li> AipsError - Whenever the HDS library returns an error status this
//    class will throw an exception.
// </thrown>
//
// <todo asof="1998/10/16">
//   <li> Add the ability to access sub-nodes of a vector structure
//   <li> Add the ability to access slices of large arrays.
//   <li> Fill out the get/put functions for all data types.
//   <li> Add the ability to write to the file.
// </todo>

class HDSDataFile
{
public:
  // Open the specified file for reading. The filename suffix of .sdf is
  // optional. By default the file is opened for read access only. Set the
  // readonly argument to False to open the file for reading and writing. The
  // current node is initialised to the top of the file.
  HDSDataFile(const String& filename, const Bool readonly=True);

  // The destructor closes the file
  ~HDSDataFile();

  // Returns the names of all the nodes that are contained within the current
  // node. Returns a zero length vector if the current node is a primitive
  // type. 
  Vector<String> ls() const;

  // Returns the shape of the current node. If the current node is a scalar or
  // a structure type then this function returns an IPosition with zero
  // dimensions.
  IPosition shape() const;

  // returns the name of the current node.
  String name() const;

  // returns the name of the current node and any parent nodes seperated by
  // dots. eg. grandparent.parent.name
  String fullname() const;

  // returns the type of the current node. Primitive nodes have a type that
  // begins with an underscore. Structure nodes can have any other string as a
  // type. 
  String type() const;

  // change to the specified node. The node must be a sub-node of the current
  // node. To change to the parent node of the current node use the string 
  // "..". 
  // <note role=warning>   
  // Currently you cannot change to a sub node directly eg.,
  // cd("node.subnode.subsubnode"). Instead you need to call this function
  // twice.
  // </note>

  // Using the second of these functions you can change into and element of a
  // structure node. If the stucture node is N-dimensional it is treated as if
  // it where one-dimensional. For example for a structure node with a shape of
  // (3,3) you cd into elements one to nine. The third of these functiuons does
  // the same as secoind except that the dimensionality is checked.
  void cd(const String& newNode);
  void cd(const String& newNode, uInt element);
  void cd(const String& newNode, const IPosition& element);

  // move to the parent node of the current one.
  void cdUp();

  // move to the top node in the file
  void cdTop();

  //#   String cwd();
  
  // Routines for retreiving numeric data from the current node as single
  // precision values. All numeric data types will be converted to single
  // precision.
  // <thrown>
  //    <li> AipsError - if the current node is not a primitive numeric type.
  // </thrown>
  // <group>
  void get(Array<Float>& data) const;
  //#   void get(Float& data, const IPosition& element)
  //#   void get(Array<Float>& data, const Slicer& section)
  void get(Float& data) const;
  //#   Array<Float> getFloat()
  //#   Float getFloat(const IPosition& element)
  //#   Array<Float> getFloat(const Slicer& section)
  // </group>
  
  // Routines for retreiving numeric data from the current node as double
  // precision values. All numeric data types will be converted to double
  // precision.
  // <thrown>
  //    <li> AipsError - if the current node is not a primitive numeric type.
  // </thrown>
  // <group>
  void get(Array<Double>& data) const;
  void get(Double& data) const;
  // </group>

  // Routines for retreiving character data from the current node. Numeric data
  // will be converted to a string. 
  // <thrown>
  //    <li> AipsError - if the current node is not a primitive type.
  // </thrown>
  // <group>
  void get(Array<String>& data) const;
  void get(String& data) const;
  // </group>

//#   void put(const Array<Float>& data);
//#   void put(const Float data, const IPosition& element);
//#   void put(const Array<Float>& data, const Slicer& element);

  // Returns True if the supplied node name is a sub-node of the current one.
  // Using the second of these functions you check one the existance of an
  // element of a structure node. If the structure node is N-dimensional it is
  // treated as if it where one-dimensional. For example for a structure node
  // with a shape of (3,3) the function will return True if whichElem is less
  // than or equal to eight. The third of these functions does the same thing
  // except that the dimensionality is also checked.
  // <group>
  Bool exists(const String& nodeName) const;
  Bool exists(const String& nodeName, uInt whichElem) const;
  Bool exists(const String& nodeName, const IPosition& whichElem) const;
  // </group>

private:
  //# The following functions are defined to avoid default versions being
  //# generated by the compiler. They are made private to prevent users from
  //# using them.
  HDSDataFile& operator= (const HDSDataFile& other);
  //# Put the top locator second so that it gets destroyed second.
  HDSNode itsCurLoc;
  HDSNode itsTopLoc;
};

#endif
#endif


