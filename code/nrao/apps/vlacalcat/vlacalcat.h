//# Vlacalcat.h: defines the VLA calibrator information
//# Copyright (C) 1999,2001
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
//# $Id: vlacalcat.h,v 19.4 2004/11/30 17:50:41 ddebonis Exp $
//#! ========================================================================
#ifndef NRAO_VLACALCAT_H
#define NRAO_VLACALCAT_H
//
////# Forward Declarations
//
// <summary>
// </summary>
//
// <use visibility=local>   or   <use visibility=export>
//
// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>
//
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
//
//class ClassName
//{
//public:
//
//protected:
//
//private:
//
//};
//
//
#include <casa/BasicSL/String.h>
#include <tables/Tables/Table.h>
#include <casa/iosfwd.h>

#include <casa/namespace.h>
class BandInfo {
   private :
    String j2000Name;
    String b1950Name;
    String receiverName;
    String band;
    String flux;
    String aCal;               // A configuration calibrator code
    String bCal;               // B
    String cCal;               // C
    String dCal;               // D
    String uvMin;
    String uvMax;
   public :
      BandInfo(){}
      BandInfo(const BandInfo &a){ j2000Name = a.j2000Name;
                                   b1950Name = a.b1950Name;
                                   receiverName = a.receiverName;
                                   band = a.band;
                                   flux = a.flux;
                                   aCal = a.aCal;
                                   bCal = a.bCal;
                                   cCal = a.cCal;
                                   dCal = a.dCal;
                                   uvMin= a.uvMin;
                                   uvMax= a.uvMax; }
      BandInfo &operator=(const BandInfo &a){ j2000Name = a.j2000Name;
                                              b1950Name = a.b1950Name;
                                              receiverName = a.receiverName;
                                              band = a.band;
                                              flux = a.flux;
                                              aCal = a.aCal;
                                              bCal = a.bCal;
                                              cCal = a.cCal;
                                              dCal = a.dCal;
                                              uvMin= a.uvMin;
                                              uvMax= a.uvMax; 
                                              return *this;}
      int operator==(const BandInfo &a){return ((j2000Name == a.j2000Name) && (receiverName == a.receiverName));}
      void writeObsCal(ostream &);
      void writeAips2Table(Table &);
      void readTable(char *);
      friend ostream& operator << (ostream &, const BandInfo&);
      void setJ2000Name(String &a){j2000Name = a;}
      void setB1950Name(String &a){b1950Name = a;}
};
#endif
