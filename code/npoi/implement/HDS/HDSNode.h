//# HDSNode.h:
//# Copyright (C) 1997,1999
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
//# $Id: HDSNode.h,v 19.3 2004/11/30 17:50:40 ddebonis Exp $

#if defined(HAVE_HDS)

#ifndef NPOI_HDSNODE_H
#define NPOI_HDSNODE_H


#include <casa/aips.h>
#include <casa/Containers/Block.h>

#include <casa/namespace.h>
// <summary>A HDSNode object points to a node in a HDS strucure</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> Hierarchical Data System documentation (available from STARLINK)
// </prerequisite>
//
// <etymology> The term "Locator" is used extensively in the HDS
// documentation. As this name may conflict with another usage of this term the
// prefix HDS was added. 
// </etymology>
//
// <synopsis>
// A HDSNode is used to point to a node on a HDS data file. Many of the
// functions in the HDS library require a locator as an argument to indicate
// which node they should operate on. 
// </synopsis>
//
// <example>
//#! One or two concise (~10-20 lines) examples, with a modest amount of
//#! text to support code fragments.  Use <srcblock> and </srcblock> to
//#! delimit example code.
// </example>
//
// <motivation>
// The HDS documenation uses the concept of a Locator in a very object
// oriented way. Hence it seemed natural to formalise this by turning it into a
// class.
// </motivation>
//
// <thrown>
//    <li> AipsError
// </thrown>
//
// <todo asof="1997/11/04">
// Only the documentation
// </todo>

class HDSNode
{
public: 
  // The functions in the HDSLib class are the only way to create a valid
  // HDSNode.
  friend class HDSLib;

  // Create a HDSNode that does not point to anything (ie., is invalid). Use
  // the functions in the HDSLib class to make the locator valid.
  HDSNode();

  // The destructor annul's the HDSNode, ie it frees resources associated
  // with the Locator
  ~HDSNode();

  // The copy constructor "clones" (in the HDS sense) the HDSNode
  HDSNode(const HDSNode& other);

  // The assignment operator also "clones" the HDSNode
  HDSNode& operator=(const HDSNode& other);

  // This function returns True if the locator is valid.
  Bool isValid() const;

  // This function returns True if the HDSNode is a primary one. Throws an
  // AipsError if the HDSNode is not valid.

  Bool isPrimary() const;

  // A function for printing the contents of this HDSNode to cout. 
  // Useful for debugging 
  void print() const; 
private:
  //# Functions which actually reset, annul or copy a HDSNode
  // <group>
  void reset();
  void annul();
  void clone(const HDSNode& other);
  // </group>

  //# I use a block of characters in preference to a String for the
  //# Locator. There was a reason why but I now cannot remember it.
  Block<Char> itsLoc;
};

#endif
#endif
