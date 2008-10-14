//# HDSDef.h:
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
//# $Id: HDSDef.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $

#if defined(HAVE_HDS)
#ifndef NPOI_HDSDEF_H
#define NPOI_HDSDEF_H

#include <casa/aips.h>
#include <casa/BasicSL/String.h>

#include <casa/namespace.h>
// <summary>Definitions and constants used in the HDS Module</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
//   <li> SomeOtherClass
//   <li> some concept
// </prerequisite>
//
// <synopsis>
//#! What does the class do?  How?  For whom?  This should include code
//#! fragments as appropriate to support text.  Code fragments shall be
//#! delimited by <srcblock> </srcblock> tags.  The synopsis section will
//#! usually be dozens of lines long.
// </synopsis>
//
// <example>
//#! One or two concise (~10-20 lines) examples, with a modest amount of
//#! text to support code fragments.  Use <srcblock> and </srcblock> to
//#! delimit example code.
// </example>
//
// <motivation>
// By putting these definitions in a separate file they can be used without the
// need to include other parts of the HDS module, in particular HDSLib.h
// </motivation>
//
// <thrown>
// This class does not throw any exceptions
// </thrown>
//
// <todo asof="1997/11/04">
//  Nothing I can think of. 
// </todo>

class HDSDef
{
public: 
  // This enumerator indicates how files should be "opened"
  enum IOMode {
    // Open a file for reading only
    READ,
    // Open a file for reading and writing
    UPDATE,
    // OPEN the file for writing only
    WRITE};

  // This enumerator lists the primitive types. The first five are standard
  // types and the other primitivetype are also supported on some systems.
  enum Type {
    // a signed 32-bit integer 
    INTEGER = 0,
    // a signed 32-bit floating point number
    REAL,
    // a signed 64-bit floating point number
    DOUBLE,
    // a Bool value (typically occupying 8-bits)
    LOGICAL,
    // a 8-bit character
    CHAR,
    // a signed 16-bit integer
    WORD,
    // a unsigned 16-bit integer
    UWORD,
    // a signed 8-bit integer
    BYTE,
    // a unsigned 8-bit integer
    UBYTE,
    // a non-primitive (ie a structure) type
    STRUCTURE,
    // The total number of types
    NUMBER_TYPES};
  
  // This enumerator lists the different things that can be obtained about the
  // current state of the HDS system
  enum showTypes {
    // display the primitive data implementation details
    DATA,
    // lists all open container files
    FILES,
    // lists all locators
    LOCATORS};

  // This enumerator lists the current state of the HDS system.
  enum state {
    // HDS is available for use
    ACTIVE,
    // HDS has been shut down or not started
    INACTIVE};

  static const Int SAI_OK;
  static const String DAT_NOLOC;
  static const uInt DAT_SZLOC;
  static const uInt DAT_SZNAM;
  static const uInt DAT_SZTYP;

  // Convert the Type enumerator to a string
  static String name(HDSDef::Type nodeType);

  // Case insensitive conversion of a string to a Type enumerator. Also
  // converts "CHAR*n" where n is any integer greater than zero to
  // HDSDef::CHAR.
  static HDSDef::Type type(const String & typeName);

  // Convert the IOMode enumerator to a string
  static String name(HDSDef::IOMode mode);
};

#endif
#endif
