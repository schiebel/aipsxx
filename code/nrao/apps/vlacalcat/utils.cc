//# utils.cc: Contains utilities for turning strings into doubles for searches
//# Copyright (C) 1999,2001,2002
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
//# $Id: utils.cc,v 19.4 2004/11/30 17:50:40 ddebonis Exp $

//# Includes
// gcoords.cc -- glish client to take strings and turn them into Doubles
//
//#--------------------------------------------------------------------------
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayIO.h>
//#----------------------------------------------------------------------------
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <unistd.h>
#include <casa/iostream.h>
#include <casa/sstream.h>
#include <math.h>
#include <casa/namespace.h>
//#---------------------------------------------------------------------------

Vector<Double> string2Ra(Vector<String> &angle);
Vector<String> ra2String(Vector<Double> &angle);
Double string2Ra(String &angle);
String ra2String(Double &angle);

Vector<Double> string2Dec(Vector<String> &angle);
Vector<String> dec2String(Vector<Double> &angle);
Double string2Dec(String &angle);
String dec2String(Double &angle);

Vector<Double> string2Deg(Vector<String> &angle);
Vector<String> deg2String(Vector<Double> &angle);
Double string2Deg(String &angle);
String deg2String(Double &angle);

static String cleanString(const String &input, const String &remove)
{  String cleaned(input);
   for(uInt i=0;i<input.length();i++){
      if(remove.contains(input[i]))
         cleaned[i] = ' ';
   }
   return cleaned;
}

//

Vector<Double> string2Ra(Vector<String> &angle){
   Vector<Double> result(angle.nelements());
   for(uInt i=0;i<angle.nelements();i++){
      result(i) = string2Ra(angle(i));
   }
   return result;
}

Vector<String> ra2String(Vector<Double> &angle){
   Vector<String> output(angle.nelements());
   for(uInt i=0;i<angle.nelements();i++){
      output(i) = ra2String(angle(i));
   }
   return output;
}



String ra2String(Double &angle)
{  angle = fmod(angle, 2.0*M_PI); // Need to modulo TwoPI  -- always positive
   if(angle < 0.0)
      angle += 2.0*M_PI;
   Double sec(12.0*angle/M_PI);  // Hours
   Int hr = static_cast<Int>(sec);
   sec -= hr;
   sec *= 60.0; // Minutes
   Int min = static_cast<Int>(sec);
   sec -= min;
   sec *=60.0;
//   
   ostringstream oss;         // Output formatting;
   oss.fill('0');
   oss.width(2);
   oss << hr << ":"; 
   oss.width(2);
   oss << min << ":";
   oss.setf(ios::showpoint); oss.setf(ios::fixed); oss.width(8); oss.precision(5);
   oss << sec;
//
   return String(oss.str());
}

Double string2Ra(String &angle)
{  String cleanedString = cleanString(angle, "DdhHmMsS:'\"");
   Int hr, min;
   Double sec;
   istringstream(cleanedString.chars()) >> dec >> hr >> min >> sec;
   sec /=60;
   sec += min;
   sec /= 60.0;
   sec += hr;
   sec *= M_PI/12.0;
   return sec;
}

//

Vector<Double> string2Dec(Vector<String> &angle){
   Vector<Double> result(angle.nelements());
   for(uInt i=0;i<angle.nelements();i++){
      result(i) = string2Dec(angle(i));
   }
   return result;
}

Vector<String> dec2String(Vector<Double> &angle){
   Vector<String> output(angle.nelements());
   for(uInt i=0;i<angle.nelements();i++){
      output(i) = dec2String(angle(i));
   }
   return output;
}

//  Need to handle deg < 0 and modulo +/-90deg

String dec2String(Double &angle)
{  angle = fmod(angle, 2.0*M_PI);
   if(angle < 0.0)
     angle += 2.0*M_PI;             // Normalized 0-2PI
   if(angle > M_PI/2.0 && angle < 1.5*M_PI)
     angle = M_PI - angle;
   if(angle >= 1.5*M_PI)
     angle = 2.0*M_PI -angle;
   return String(deg2String(angle));
}

//Need to handle deg < 0 properly

Double string2Dec(String &angle)
{  String cleanedString = cleanString(angle, "DdHhMmSs:'\"");
   Int deg, min(0);
   Double sec(0.0);
   istringstream(cleanedString.chars()) >> dec >> deg >> min >> sec;
   Int signBit(1);
   if(deg < 0){
      signBit = -1;
      deg *= -1;
   }
   sec /=60;
   sec += min;
   sec /= 60.0;
   sec += deg;
   sec *= signBit*M_PI/180.0;
   return sec;
}

//

Vector<Double> string2Deg(Vector<String> &angle){
   Vector<Double> result(angle.nelements());
   for(uInt i=0;i<angle.nelements();i++){
      result(i) = string2Deg(angle(i));
   }
   return result;
}

Vector<String> deg2String(Vector<Double> &angle){
   Vector<String> output(angle.nelements());
   for(uInt i=0;i<angle.nelements();i++){
      output(i) = deg2String(angle(i));
   }
   return output;
}

String deg2String(Double &angle)
{  Int signBit(1);
   if(angle < 0.0){
      signBit = -1;
      angle *= -1.0;
   }
   Double sec(180.0*angle/M_PI);  // Hours
   Int deg = static_cast<Int>(sec);
   sec -= deg;
   sec *= 60.0; // Minutes
   Int min = static_cast<Int>(sec);
   sec -= min;
   sec *=60.0;
//   
   ostringstream oss;         // Output formatting;
   oss.fill('0');
   oss.width(2);
   oss << signBit*deg << "d"; 
   oss.width(2);
   oss << min << "m";
   oss.setf(ios::showpoint); oss.setf(ios::fixed); oss.width(8); oss.precision(5);
   oss << sec;
//
   return String(oss.str());
}

Double string2Deg(String &angle)
{  String cleanedString = cleanString(angle, "DdHhMmSs:");
   Int deg, min(0);
   Double sec(0.0);
   istringstream(cleanedString.chars()) >> dec >> deg >> min >> sec;
   Int signBit(1);
   if(deg < 0){
      signBit = -1;
      deg *= -1;
   }
   sec /=60;
   sec += min;
   sec /= 60.0;
   sec += deg;
   sec *= M_PI/180.0;
   return sec;
}
