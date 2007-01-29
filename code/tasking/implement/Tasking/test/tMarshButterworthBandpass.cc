//# tMarshButterworthBandpass: test the MarshButterworthBandpass class
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
//# $Id: tMarshButterworthBandpass.cc,v 19.5 2004/11/30 17:51:12 ddebonis Exp $

#ifdef DEBUG 
#define DIAGNOSTICS
#endif
// #define DIAGNOSTICS

#include <scimath/Functionals/MarshButterworthBandpass.h>
#include <casa/iostream.h>


#include <casa/namespace.h>
int main() {
    MarshButterworthBandpass<Double> butt1(2,3,1,5,3,2);

    Record gr(RecordInterface::Variable);
    butt1.store(gr);

#ifdef DIAGNOSTICS
    cout << "Butterworth bandpass freeze-dried as " << endl
	 << "    " << gr << endl;
#endif

    MarshButterworthBandpass<Double> butt2(gr);
    butt2.store(gr);

#ifdef DIAGNOSTICS
    cout << "...reconstituted as " << endl
	 << "    " << gr << endl;
#endif

    AlwaysAssertExit(butt1.getMinOrder() == butt2.getMinOrder() &&
		     butt1.getMaxOrder() == butt2.getMaxOrder());
    AlwaysAssertExit(butt1.getMinCutoff() == butt2.getMinCutoff() &&
		     butt1.getMaxCutoff() == butt2.getMaxCutoff());
    AlwaysAssertExit(butt1.getCenter() == butt2.getCenter());
    AlwaysAssertExit(butt1.getPeak() == butt2.getPeak());

    cout << "OK" << endl;
    return 0;
}
