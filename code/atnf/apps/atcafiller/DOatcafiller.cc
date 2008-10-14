//# DOatcafiller.cc: DO for ATCA filler
//# Copyright (C) 1994-2000,2001,2002,2003
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
//# $Id: DOatcafiller.cc,v 19.13 2004/11/30 17:50:10 ddebonis Exp $

#include <DOatcafiller.h>

#include <casa/namespace.h>
atcafiller::atcafiller(const String& msName,
		       const Vector<String>& rpfitsFiles,
		       const Vector<String>& options,
		       Float shadow,
		       Bool online):
    itsATCAFiller(msName,rpfitsFiles,options,shadow,online)
{
}


atcafiller::~atcafiller() 
{
}

String atcafiller::className() const
{
  return "atcafiller";
}

Vector<String> atcafiller::methods() const
{
  Vector<String> method(3);
  Int i=0;
  method(i++) = "fill";
  method(i++) = "select";
  method(i++) = "close";
  
  return method;
}

MethodResult atcafiller::runMethod(uInt which, 
				     ParameterSet &inputRecord,
				     Bool runMethod)
{
  
  static String returnvalString = "returnval";

  switch (which) {
  case 0: // fill
    {
      Parameter<String>  returnval(inputRecord, returnvalString,
				   ParameterSet::Out);
      if (runMethod) {
	returnval() = itsATCAFiller.fill();
      }
    }
    break;
  case 1: //select
    {
      Parameter<Int> firstscan(inputRecord, "firstscan", ParameterSet::In);
      Parameter<Int> lastscan(inputRecord, "lastscan", ParameterSet::In);
      Parameter<Int> freqchain(inputRecord, "freqchain", ParameterSet::In);
      Parameter<Double> lowfreq(inputRecord, "lowfreq", ParameterSet::In);
      Parameter<Double> highfreq(inputRecord, "highfreq", ParameterSet::In);
      Parameter<Vector<String> > fieldList(inputRecord,"fields",ParameterSet::In);
      Parameter<Int> bw1(inputRecord, "bandwidth1", ParameterSet::In);
      Parameter<Int> nchan1(inputRecord, "numchan1", ParameterSet::In);
      Parameter<Bool> returnval(inputRecord, returnvalString,
				ParameterSet::Out);
      if (runMethod) {
	Bool ok=True;
	itsATCAFiller.scanRange(firstscan(),lastscan());
	itsATCAFiller.freqChain(freqchain());
	itsATCAFiller.freqRange(lowfreq()*1.E9, highfreq()*1.E9);
	itsATCAFiller.fields(fieldList());
        itsATCAFiller.bandwidth1(bw1());
        itsATCAFiller.numchan1(nchan1());
	returnval() = ok;
      }
      break;
    }
  case 2: // close
    {
      if (runMethod) {
	// this seems to cause a crash
	//	atms_p=Table();
	//	if (msc_p) delete msc_p; 
	//	msc_p=0;
      }
    }
    break;
  default:
    return error("No such method");
  }
  return ok();
}
