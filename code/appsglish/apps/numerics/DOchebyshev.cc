//# Chebyshev.h  a function class that defines a Chebyshev polynomial
//# Copyright (C) 2000,2001,2002
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
//# $Id: DOchebyshev.cc,v 19.9 2005/11/07 21:17:04 wyoung Exp $

#include <appsglish/numerics/DOchebyshev.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayUtil.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Tasking.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
const String chebyshev::modenames[] = 
        { "default", "zeroth", "extrapolate", "cyclic", "edge" };

chebyshev::chebyshev() : cheb() { }
chebyshev::~chebyshev() { }

Vector<String> chebyshev::methods() const {
    return stringToVector(
        String("setcoeffs,setdefault,setinterval,eval,summary,derivative"));
}

String chebyshev::className() const { return String("chebyshev"); }

MethodResult chebyshev::runMethod(uInt which,     
                                  ParameterSet &parameters,
                                  Bool runMethod) 
{
    static String coeffs = "coeffs";
    static String val = "val";
    static String min = "min";
    static String max = "max";
    static String header = "hdr";
    static String verbose = "verbose";
    static String mode = "mode";
    enum methodnames { SETCOEFFS, SETDEF, SETINTERVAL, EVAL, SUM, DERIV };

    switch (which) {
    case SETCOEFFS: {
	Parameter<Vector<Double> > ce(parameters, coeffs, ParameterSet::In);
	if (runMethod) {
	    cheb.setCoefficients(ce());
	}
	break;
    }

    case SETDEF: {
	Parameter<String> mod(parameters, mode, ParameterSet::In);
	Parameter<Double> def(parameters, val, ParameterSet::InOut);
	if (runMethod) {

	    // do minimum match to mode name
	    mod().downcase();
	    uInt i;
	    for(i=0; i < 5; i++) {
		if (modenames[i].matches(mod(),0)) break;
	    }
	    if (i >= 5) 
		return error(String("unrecognized out-of-interval mode: ") + 
			     mod());

	    cheb.
	      setOutOfIntervalMode(ChebyshevEnums::OutOfIntervalMode(i));
	    if (i == ChebyshevEnums::CONSTANT) cheb.setDefault(def());
	    def() = cheb.getDefault();
	}
	break;
    }

    case SETINTERVAL: {
	Parameter<Double> xmin(parameters, min, ParameterSet::In);
	Parameter<Double> xmax(parameters, max, ParameterSet::In);
	if (runMethod) {
	    cheb.setInterval(xmin(), xmax());
	}
	break;
    }

    case EVAL: {
	Parameter<Array<Double> > in(parameters, val, ParameterSet::InOut);
	if (runMethod) {
	    Bool dodel;
	    uInt n = in().nelements();
	    Double *data = in().getStorage(dodel);
	    Double *dp = data;
	    while (n--) *dp++ = cheb(*dp);
	    in().putStorage(data, dodel);
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
	    cheb.store(tmpRec);
	    if (verb()) logSummary();
	}
	break;
    }

    case DERIV: {
	Parameter<GlishRecord> hdr(parameters, header, ParameterSet::Out);
	if (runMethod) {
	    MarshallableChebyshev<Double> deriv = cheb.derivative();
            Record tmpRec;
            hdr().toRecord(tmpRec);
	    deriv.store(tmpRec);
	}
	break;
    }

    default:
        return error("Unknown method requested");
        break;
    }

    return ok();
}

Vector<String> chebyshev::noTraceMethods() const {
    return stringToVector(
	String("setcoeffs,setdefault,setinterval,summary,derivative,eval"));
}

   // Kludge to get around an SGI compiler problem with
   // enums in templated classes
#if defined(AIPS_SGI)
   enum {chebCONSTANT, chebZEROTH, chebEXTRAPOLATE, chebCYCLIC, chebEDGE};
#else
   #define chebCONSTANT ChebyshevEnums::CONSTANT
   #define chebZEROTH ChebyshevEnums::ZEROTH
   #define chebEXTRAPOLATE ChebyshevEnums::EXTRAPOLATE
   #define chebCYCLIC ChebyshevEnums::CYCLIC
   #define chebEDGE ChebyshevEnums::EDGE
#endif

void chebyshev::logSummary() {
    log_p << LogIO::NORMAL << replicate("=",80) << endl
	  << "Chebyshev function state: " << endl
	  << "  coefficients: " << cheb.getCoefficients() << endl
	  << "  valid interval: [" << cheb.getIntervalMin() << ", "
	  << cheb.getIntervalMax() << "]" << endl
	  << "  Out-of-interval mode: ";
    switch (cheb.getOutOfIntervalMode()) {
    case chebCONSTANT:
	log_p << "'default' -- default value, " << cheb.getDefault() 
	      << ", will be returned.";
	break;

    case chebZEROTH:
	log_p << "'zeroth' -- zero-th order coefficient, " 
	      << cheb.getCoefficient(0) << ", will be returned.";
	break;

    case chebCYCLIC:
	log_p << "'cyclic' -- input value will be shifted into interval "
	      << "before evaluation";
	break;

    case chebEDGE:
	log_p << "'edge' -- value of the nearest interval edge returned";
	break;

    default:
	log_p << "'extrapolate' -- function will be evaluated using "
	      << "out-of-interval value";
    }
    log_p << LogIO::POST;
}

//  GlishRecord chebyshev::marshall() { return marshall(cheb); }
 
//  GlishRecord chebyshev::marshall(Chebyshev<Double> &cheb) {
//      GlishRecord out;

//      out.add(String("coeffs"), GlishArray(cheb.getCoefficients()));
//      out.add(String("mode"), GlishArray(modenames[cheb.getOutOfIntervalMode()]));
//      out.add(String("def"), GlishArray(cheb.getDefault()));

//      Vector<Double> intv(2);
//      intv(0) = cheb.getIntervalMin();
//      intv(1) = cheb.getIntervalMax();
//      out.add(String("interval"), GlishArray(intv));

//      return out;
//  }
