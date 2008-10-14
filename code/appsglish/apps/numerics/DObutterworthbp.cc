//# DObutterworthbp.cc
//# Copyright (C) 2001,2002
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
//#! ========================================================================
//# $Id: DObutterworthbp.cc,v 19.8 2005/11/07 21:17:04 wyoung Exp $

#include <appsglish/numerics/DObutterworthbp.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayUtil.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Tasking.h>
#include <casa/Utilities/Assert.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
butterworthbp::butterworthbp() : butt() { }
butterworthbp::~butterworthbp() { }

Vector<String> butterworthbp::methods() const {
    return stringToVector(String("set,eval,summary"));
}

String butterworthbp::className() const { return String("butterworthbp"); }

MethodResult butterworthbp::runMethod(uInt which,     
				      ParameterSet &parameters,
				      Bool runMethod) 
{
    static String peak = "peak";
    static String order = "order";
    static String bpass = "bpass";
    static String header = "hdr";
    static String verbose = "verbose";
    static String x = "x";

    enum methodids { SET, EVAL, SUM };
    switch (which) {
    case SET: {
	Parameter<Vector<Int> > ord(parameters, order, ParameterSet::In);
	Parameter<Vector<Double> > bp(parameters, bpass, ParameterSet::In);
	Parameter<Double> pk(parameters, peak, ParameterSet::In);

	if (runMethod) {
	    // should be trapped by glish, but just in case...
	    AlwaysAssert(ord()(0) >= 0 && ord()(1) >= 0, AipsError);

	    butt.setMinOrder(uInt(ord()(0)));
	    butt.setMaxOrder(uInt(ord()(1)));
	    butt.setMinCutoff(bp()(0));
	    butt.setCenter(bp()(1));
	    butt.setMaxCutoff(bp()(2));
	    butt.setPeak(pk());
	}
	break;
    }

    case SUM: {
        Parameter<GlishRecord> hdr(parameters, header, ParameterSet::Out);
        Parameter<Bool> verb(parameters, verbose, ParameterSet::In);
	if (runMethod) {
//	    hdr() = marshall();
            Record tmpRec;
            hdr().toRecord(tmpRec);
	    butt.store(tmpRec);
	    if (verb()) logSummary();
	}
	break;
    }

    case EVAL: {
	Parameter<Array<Double> > in(parameters, x, ParameterSet::InOut);
	if (runMethod) {
	    Bool dodel;
	    uInt n = in().nelements();
	    Double *data = in().getStorage(dodel);
	    Double *dp = data;
	    while (n--) *dp++ = butt(*dp);
	    in().putStorage(data, dodel);
	}
	break;
    }

    default:
        return error("Unknown method requested");
        break;
    }

    return ok();
}

Vector<String> butterworthbp::noTraceMethods() const {
    return stringToVector(String("set,eval,summary"));
//    return stringToVector(String("set,summary"));
//    return stringToVector(String(""));
}

void butterworthbp::logSummary() {
    log_p << LogIO::NORMAL << replicate("=",80) << endl
	  << "Butterworth bandpass function state: " << endl
	  << "  Cutoffs (low, high): " << butt.getMinCutoff() << ", "
	  << butt.getMaxCutoff() << endl
	  << "  Butterworth orders (low, high): " << butt.getMinOrder() << ", "
	  << butt.getMaxOrder() << endl
	  << "  Bandpass center: " << butt.getCenter() << endl
	  << "  Bandpass peak: " << butt.getPeak() << endl
	  << LogIO::POST;
}

//  GlishRecord butterworthbp::marshall() { 
//      GlishRecord out;

//      Vector<Double> bpass(3);
//      bpass(0) = butt.getMinCutoff();
//      bpass(1) = butt.getCenter();
//      bpass(2) = butt.getMaxCutoff();
//      out.add(String("bpass"), GlishArray(bpass));

//      Vector<Double> order(2);
//      order(0) = butt.getMinOrder();
//      order(1) = butt.getMaxOrder();
//      out.add(String("order"), GlishArray(order));

//      out.add(String("peak"), GlishArray(butt.getPeak()));

//  //    addInvokeRecord(out);

//      return out;
//  }

