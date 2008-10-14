//# tEclecticFunctionFactory: test the EclecticFunctionFactory class
//# Copyright (C) 2002,2003
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
//# $Id: tEclecticFunctionFactory.cc,v 19.6 2004/11/30 17:51:12 ddebonis Exp $

#ifdef DEBUG 
#define DIAGNOSTICS
#endif
// #define DIAGNOSTICS

#include <scimath/Functionals/EclecticFunctionFactory.h>
#include <tasking/Glish/GlishRecord.h>
#include <scimath/Functionals/SpecificFunctionFactory.h>
#include <scimath/Functionals/MarshallableChebyshev.h>
#include <scimath/Functionals/MarshButterworthBandpass.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
int main() {
    EclecticFunctionFactory<Double> lookup;
    lookup.addFactory(MarshallableChebyshev<Double>::FUNCTYPE,
        new SpecificFunctionFactory<Double, MarshallableChebyshev<Double> >);
    lookup.addFactory(MarshButterworthBandpass<Double>::FUNCTYPE,
        new SpecificFunctionFactory<Double, MarshButterworthBandpass<Double> >);

    AlwaysAssertExit(lookup.ndefined() == 2);
    AlwaysAssertExit(lookup.isDefined("chebyshev") &&
		     lookup.isDefined("butterworthbp"));

    MarshallableChebyshev<Double> cheb1;
    Vector<Double> coeffs(4, 0);
    coeffs(3) = 2.0;
    cheb1.setCoefficients(coeffs);
    cheb1.setInterval(0.0, 4.0);
    cheb1.setOutOfIntervalMode(ChebyshevEnums::CYCLIC);
    cheb1.setDefault(5.0);

    Record gr(RecordInterface::Variable);
    cheb1.store(gr);

#ifdef DIAGNOSTICS
    cout << "Chebyshev polynomial freeze-dried as " << endl
	 << "    " << gr << endl;
#endif

    MarshallableChebyshev<Double> *cheb2 = 
	dynamic_cast<MarshallableChebyshev<Double>*>(lookup.create(gr));
    AlwaysAssertExit(cheb2 != 0);

#ifdef DIAGNOSTICS
    cout << "...reconstituted as " << endl
	 << "    " << gr << endl;
#endif

    AlwaysAssertExit(cheb1.getCoefficient(0) == cheb2->getCoefficient(0) && 
		     cheb1.getCoefficient(1) == cheb2->getCoefficient(1) && 
		     cheb1.getCoefficient(2) == cheb2->getCoefficient(2) && 
		     cheb1.getCoefficient(3) == cheb2->getCoefficient(3));
    AlwaysAssertExit(cheb1.getDefault() == cheb2->getDefault());
    AlwaysAssertExit(cheb1.getOutOfIntervalMode() == 
		                              cheb2->getOutOfIntervalMode());
    AlwaysAssertExit(cheb1.getIntervalMin() == cheb2->getIntervalMin() &&
		     cheb1.getIntervalMax() == cheb2->getIntervalMax());

    cout << "OK" << endl;
    return 0;
}

