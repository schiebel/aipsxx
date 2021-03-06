//# Error.h: Base class for all AIPS++ errors
//# Copyright (C) 1993,1994,1995,1999,2000,2001
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
//# $Id: Error.h,v 19.9 2005/06/18 21:19:15 ddebonis Exp $

#ifndef CASA_ERROR_H
#define CASA_ERROR_H



#include <sys/types.h>
#include <casa/aips.h>
#include <casa/BasicSL/String.h>
#include <exception>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>Base class for all AIPS++ library errors</summary>
// <use visibility=export>
//
// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>
//
// <prerequisite>
//   <li> ExcpError
// </prerequisite>
//
// <synopsis>
//  This is the base class for all of the AIPS++ error classes. Because
//  all of the errors have a common base class, any error can be caught
//  with a single catch statement.
//
//  This class has a string which allows error messages to be propagated.
//
//  <note role=tip> The string member must be handled very carefully because
//        string is also derived from cleanup, thus the 
//        <src>message.makePermanent()</src> call in the implementation of
//        the constructors. This prevents the String from being cleaned up
//        in the middle of an exception.
//
// </synopsis>
//
// <example>
// <srcblock>
//      throw(AipsError("SOME STRING"));
// </srcblock>
// </example>
//
// <todo asof="">
// </todo>

class AipsError: public std::exception
{
public:

  enum Category {
    BOUNDARY, INITIALIZATION, INVALID_ARGUMENT, CONFORMANCE,
    ENVIRONMENT, SYSTEM, PERMISSION, GENERAL
  };

  //
  // Simply returns the stored error message.
  //
  virtual const char* what() const throw()
  { return(message.c_str()); }
  const String &getMesg() const
    { return(message); }
  const AipsError::Category getCategory( ) const
    { return(category); }

  //
  // Creates an AipsError and initializes the error message from
  // the parameter
  // <group>
  AipsError (const Char *str, Category c = GENERAL);
  AipsError (const String &str, Category c = GENERAL);
  AipsError (Category c = GENERAL) : message(), category(c) {};
  // </group>

  //
  // Destructor which does nothing.
  //
  ~AipsError() throw();

protected:
  String message;
  Category category;

};


// <summary>Allocation errors</summary>
// <use visibility=export>
//
// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>
//
// <synopsis>
//
// This class is used for allocation errors. It adds an extra
// data item, the failed allocation size. Otherwise much the
// same as <src>AipsError</src>.
//
// </synopsis>
//
// <example>
// <srcblock>
//     throw(AllocError("ANY STRING",1024));
// </srcblock>
// </example>
//
// <todo asof="">
// </todo>

class AllocError : public AipsError {
protected:
  size_t Size;
public:
  //
  // This constructor takes the error message and the failed
  // allocation size.
  //
  // <group>
  AllocError(const Char *str, uInt sze) : AipsError(str,SYSTEM), Size(sze) {}
  AllocError(const String &str, uInt sze) : AipsError(str,SYSTEM), Size(sze)  {}
  // </group>

  //
  // This function returns the failed allocation size.
  //
  size_t size() {return(Size);}

  //
  // Destructor which does nothing.
  //
  ~AllocError() throw();

};


// <summary>Base class for all indexing errors</summary>
// <use visibility=export>
//
// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>
//
// <synopsis>
// This class is the base class of all <src>IndexError</src>s. It is
// defined to allow the user to catch any of the many kinds of IndexErrors
// which may be thrown. It can also be thrown itself if returning
// the illegal index value is unimportant.
// </synopsis>
//
// <example>
// <srcblock>
//     throw(IndexError("ANY STRING"));
// </srcblock>
// </example>
//
// <todo asof="">
// </todo>

class IndexError : public AipsError {
public:
  //
  // Creates an GeneralIndexError and initializes the error message from
  // the parameter
  // <group>
  IndexError(const Char *str,Category c=BOUNDARY) : AipsError(str,c) {}
  IndexError(const String &str,Category c=BOUNDARY) : AipsError(str,c) {}
  IndexError(Category c=BOUNDARY) : AipsError(c) {}
  // </group>

  //
  // Destructor which does nothing.
  //
  ~IndexError() throw();
};


// <summary>Index errors returning the bad index</summary>
// <use visibility=export>
//
// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>
//
// <synopsis>
// This class is templated to allow generalalized indexes to be returned
// with the error message i.e. the class is templated on the index type.
//
// </synopsis>
//
// <example>
// <srcblock>
//     throw(indexError<int>(3,"ANY STRING"));/
// </srcblock>
// </example>
//
// <todo asof="">
// </todo>

template<class t> class indexError : public IndexError {
protected:
  t oIndex;                 // Offending Index
public:
  //
  // This constructor takes the error message and the index
  // which cause the error to occur.
  //
  // <group>
  indexError(t oI, const Char *str, Category c=BOUNDARY);
  indexError(t oI, const String &str, Category c=BOUNDARY);
  indexError(t oI, Category c=BOUNDARY) : IndexError(c), oIndex(oI) {};
  // </group>

  //
  // Destructor which does nothing.
  //
  ~indexError() throw();
};


// <summary>Duplicate key errors</summary>
// <use visibility=export>
//
// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>
//
// <synopsis>
// This class is the base class of all duplicate key errors. It is
// defined to allow the user to catch any of the many kinds of DuplErrors
// which may be thrown. It can also be thrown itself if returning
// the illegal key is unimportant.
// </synopsis>
//
// <example>
// <srcblock>
//    throw(DuplError("ANY STRING"));
// </srcblock>
// </example>
//
// <todo asof="">
// </todo>

class DuplError : public AipsError {
public:
  //
  // Creates an DuplError and initializes the error message from
  // the parameter
  // <group>
  DuplError(Category c=BOUNDARY) : AipsError(c) {}
  DuplError(const Char *str,Category c=BOUNDARY) : AipsError(str,c) {}
  DuplError(const String &str,Category c=BOUNDARY) : AipsError(str,c) {}
  // </group>

  //
  // Destructor which does nothing.
  //
  ~DuplError() throw();
};


// <summary>Duplicate key errors where the bad key is returned</summary>
// <use visibility=export>
//
// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>
//
// <synopsis>
//  This template is for generalized duplicate key errors where the template
//  type parameter is the type of the key which caused the error. Because this
//  class is derived from <linkto class=DuplError><src>DuplError</src>
//  </linkto>, the user to catch all duplicate key errors with one catch
//  statement. 
//
// </synopsis>
//
// <example>
//     throw(duplError<int>(4,"ANY STRING"));
// </example>
//
// <todo asof="">
// </todo>

template<class t> class duplError : public DuplError {
protected:
  t oKey;                   // Offending Key
public:
  //
  // This constructs a "duplError" for the offending key, and an
  // optional character string.
  //
  // <group>
  duplError(t oI, const Char *str,Category c=BOUNDARY);
  duplError(t oI, const String &str,Category c=BOUNDARY);
  duplError(t oI,Category c=BOUNDARY) : DuplError(c), oKey(oI) {};
  // </group>

  //
  // Destructor which does nothing.
  //
  ~duplError() throw();
};


// <summary>Exception which halts execution</summary>
// <use visibility=export>
//
// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>
//
// <synopsis>
// This error causes an execution to halt regardless. It
// causes execution to halt before the exception can be caught.
// </synopsis>
//
// <example>
// <srcblock>
//     throw(AbortError("ANY STRING"));
// </srcblock>
// </example>
//
// <todo asof="">
// </todo>

class AbortError : public AipsError {
public:
  //
  // This constructs a "AbortError" from the error message.
  //
  // <group>
  AbortError(const Char *str,Category c=GENERAL);
  AbortError(const String &str,Category c=GENERAL);
  // </group>

  //
  // Destructor which does nothing.
  //
  ~AbortError() throw();
};



} //# NAMESPACE CASA - END

#ifndef AIPS_NO_TEMPLATE_SRC
#include <casa/Exceptions/Error.cc>
#include <casa/Exceptions/Error2.cc>
#endif //# AIPS_NO_TEMPLATE_SRC
#endif
