//# DOflagger.h: this defines DOflagger
//# Copyright (C) 2000,2001
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
//# $Id: DOflagger.h,v 19.5 2004/11/30 17:50:06 ddebonis Exp $
#ifndef APPSGLISH_DOFLAGGER_H
#define APPSGLISH_DOFLAGGER_H

#include <casa/aips.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Tasking.h>                                          
#include <flagging/Flagging/RedFlagger.h>

    
#include <casa/namespace.h>
// <summary>
// Implements the redflagger DO
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> everything in implement/RedFlagger
// </prerequisite>
//
// <todo asof="2001/04/16">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>

class flagger : public ApplicationObject                         
{
public:
  flagger();
  ~flagger();

  virtual String className() const;                              
  virtual Vector<String> methods() const;                        
  virtual Vector<String> noTraceMethods() const;                        
  virtual MethodResult runMethod(uInt which,                     
                                ParameterSet &parameters,
                                Bool runMethod);
  
private:
  RedFlagger redflagger;
};


#endif
