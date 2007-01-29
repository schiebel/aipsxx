//# DOwnbt.h: This class gives Glish to wnb test connection
//# Copyright (C) 2000
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: DOwnbt.h,v 19.5 2004/11/30 17:50:09 ddebonis Exp $

#ifndef APPSGLISH_DOWNBT_H
#define APPSGLISH_DOWNBT_H

//# Includes

#include <casa/aips.h>
#include <tasking/Tasking.h>
#include <images/Images/ImageInterface.h>

#include <casa/namespace.h>
//# Forward declarations
namespace casa { //# NAMESPACE CASA - BEGIN
class String;
class ComponentUpdate;
class GlishRecord;
template <class T> class Vector;
template <class T> class Matrix;
} //# NAMESPACE CASA - END


// <summary> This class gives Glish to wnb test connection</summary>

// <use visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto module=Tasking>Tasking</linkto>
// </prerequisite>

// <etymology>
// Distributed Object and wnb and test
// </etymology>

// <synopsis>
// The class makes the connection between wnb test programs and Glish
// </synopsis>


// <motivation>
// To provide a direct user interface between the user and some tests
// </motivation>

// <todo asof="2000/06/23">
//  <li>
// </todo>

class wnbt : public ApplicationObject {

public:
  //# Standard constructors/destructors

  wnbt();
  wnbt(const wnbt &other);
  wnbt &operator=(const wnbt &other);
  ~wnbt();

  // Required Tasking methods
  // <group>
  virtual String className() const;
  virtual Vector<String> methods() const;
  virtual MethodResult runMethod(uInt which,
				 ParameterSet &parameters,
				 Bool runMethod);
  // </group>

  // Stop tracing
  virtual Vector<String> noTraceMethods() const;

private:
  //# Data
  // Image to find sources in
  ImageInterface<Float> *imptr_p;
  // A component update object
  ComponentUpdate *cupptr_p;
  //# Member functions
  // Find a set of stringest sources. Sources found must be positive amplitude
  // unless the afind (absolute find) switch is set. Only sources stronger than
  // mapLim * strongest source in list will be found. Returned is the number
  // of sources found.
  Int find(Array<Double> &rsa, Double mapLim=0.1, Bool afind=False);
};

#endif
