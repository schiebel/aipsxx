//# tChebyshev: test the MarshallableChebyshev class
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
//# $Id: tMarshallableChebyshev.cc,v 19.6 2004/11/30 17:51:12 ddebonis Exp $

#ifdef DEBUG 
#define DIAGNOSTICS
#endif
// #define DIAGNOSTICS

#include <scimath/Functionals/MarshallableChebyshev.h>
#include <casa/iostream.h>


#include <casa/namespace.h>
int main() {
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

    MarshallableChebyshev<Double> cheb2(gr);
    cheb2.store(gr);

#ifdef DIAGNOSTICS
    cout << "...reconstituted as " << endl
	 << "    " << gr << endl;
#endif

    AlwaysAssertExit(cheb1.getCoefficient(0) == cheb2.getCoefficient(0) && 
		     cheb1.getCoefficient(1) == cheb2.getCoefficient(1) && 
		     cheb1.getCoefficient(2) == cheb2.getCoefficient(2) && 
		     cheb1.getCoefficient(3) == cheb2.getCoefficient(3));
    AlwaysAssertExit(cheb1.getDefault() == cheb2.getDefault());
    AlwaysAssertExit(cheb1.getOutOfIntervalMode() == 
		                              cheb2.getOutOfIntervalMode());
    AlwaysAssertExit(cheb1.getIntervalMin() == cheb2.getIntervalMin() &&
		     cheb1.getIntervalMax() == cheb2.getIntervalMax());

    MarshallableChebyshev<Double> *clone = 
	dynamic_cast<MarshallableChebyshev<Double>*>(cheb2.clone());
    AlwaysAssertExit(clone);
    clone->getCoefficient(0);

    cout << "OK" << endl;
    return 0;
}
