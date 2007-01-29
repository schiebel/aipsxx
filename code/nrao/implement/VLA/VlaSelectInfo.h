//# <VlaSelectInfo.h>: this defines <VlaSelectInfo>, which ...
//# Copyright (C) 1997,1999,2001
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
//# $Id: VlaSelectInfo.h,v 19.3 2004/11/30 17:50:43 ddebonis Exp $
//#! ========================================================================
//#!                Attention!  Programmers read this!
//#!
//#! This file is a template to guide you in creating a header file
//#! for your new class.   By following this template, you will create
//#! a permanent reference document for your class, suitable for both
//#! the novice client programmer, the seasoned veteran, and anyone in 
//#! between.  It is essential that you write the documentation portions 
//#! of this file with as much care as you do the source code.
//#!
//#! If you are unfamilar with the AIPS++ header style please refer to
//#! template-class-h.
//#!
//#!                         Replacement Tokens
//#!                         ------------------
//#!
//#! These are character strings enclosed in angle brackets, on a commented
//#! line.  Two are found on the first line of this file:
//#!
//#!   <ClassFileName.h> <ClassName>
//#!
//#! You should remove the angle brackets, and replace the characters within
//#! the brackets with names specific to your class.  Mimic the capitalization
//#! and punctuation of the original.  For example, you would change
//#!
//#!   <ClassFileName.h>  to   LatticeIter.h
//#!   <ClassName>        to   LatticeIterator
//#!
//#! Another replacement token will be found in the "include guard" just
//#! a few lines below.
//#!
//#!  #define <AIPS_CLASSFILENAME_H>  to  #define AIPS_LATTICEITER_H
//#!

#ifndef NRAO_VLASELECTINFO_H
#define NRAO_VLASELECTINFO_H

//# Forward Declarations

// <summary>
// </summary>

// <use visibility=local>   or   <use visibility=export>

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
// <templating arg=T>
//    <li>
//    <li>
// </templating>
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


#include <casa/aips.h>

#include <casa/namespace.h>
// Helper class for setting selection criteria
class VlaSelectInfo {
   private : 
      Double startTime;
      Double stopTime;
      Int    antennaCount;
      Int   *antennas;
      Int    subarrayCount;
      Int   *subarrays;
      Int    modeCount;
      Char  *modes;
      Int    sourceCount;
      Char  *sources;
      Char  *programs;
   public :
      VlaSelectInfo() : startTime(0.0),   stopTime(0.0),
                        antennaCount(0),  antennas(0),
                        subarrayCount(0), subarrays(0),
                        modeCount(0),     modes(0),
                        sourceCount(0),   sources(0),
                        programs(0){}
     ~VlaSelectInfo() { if(antennas)delete [] antennas;
                        if(subarrays) delete [] subarrays;
                        if(modes) delete [] modes;
                        if(sources) delete [] sources;
                        if(programs) delete [] programs; }

     Int  *antennasOK(Int, Int *, Int *);
     Int   timeRangeOK(Double);
     Int   subarrayOK(Int);
     Int   observingModeOK(const Char *);
     Int   programIDOK(const Char *);
     Int   sourceOK(const Char *);
     void  setValues(const Char *);
};

#endif
