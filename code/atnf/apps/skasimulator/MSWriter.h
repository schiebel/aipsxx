///////////////////////////////////////////////////////////////////////////////
//
//  MSWriter is a class to write uv-data into AIPS++ MeasurementSet file
//
//

//# Copyright (C) 1999,2000
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
//# $Id: MSWriter.h,v 1.3 2005/09/19 04:19:10 mvoronko Exp $


#ifndef __MSWRITER_HPP
#define __MSWRITER_HPP

// AIPS++ stuff
#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>
#include <casa/BasicSL/Complex.h>
#include <casa/Exceptions/Error.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <casa/Quanta/MVFrequency.h>


//
// IMSOperations - interface class, originally was intended to split AIPS++
// includes from end-user program. Otherwise, it would be neccessary to
// know all AIPS++ types  everywhere, as they would be used in the main
// class definition. Now it simply decrease the size of AIPS++ stuff a
// user need to include
//

struct IMSOperations {
   // set up the Measurement Set initially.
   virtual void setupMeasurementSet(const casa::String &filename) throw(casa::AipsError) = 0;
   // fill the Observation and ObsLog tables
   virtual void fillObsTables() throw(casa::AipsError) = 0;
   // fill the main table. Now supports only one pointing & one IF
   virtual void fillMSMainTable()  throw(casa::AipsError) = 0;
   // fill the spectral window table. Now supports only one FQ
   virtual void fillSpectralWindowTable() throw(casa::AipsError) = 0;
   // fill field table. Now supports only single source case
   virtual void fillFieldTable(const casa::MDirection &obsfield)
                throw(casa::AipsError) = 0;
   // fill the feed table. The observation and antenna tables should be
   // filled in first
   virtual void fillFeedTable()  throw(casa::AipsError) = 0;
   
   // Dummy destructor, to execute actual one correctly from the derived
   // classes
   virtual ~IMSOperations() throw();
};

// MSWriter
class MSWriter {
public:
    MSWriter(const casa::String &fname, const casa::MDirection &field,
             const casa::Quantity &istartfreq, casa::uInt infreqchan,
	     const casa::Quantity &ichanwidth) throw(casa::AipsError);
    virtual ~MSWriter() throw();
    void writevis(const casa::Vector<casa::Double> &uvw, casa::uInt ant1, casa::uInt ant2,
                  const casa::MVEpoch &utctime,
                  const casa::Matrix<casa::Complex> &vis) throw(casa::AipsError) ;
    void writeANtable(const casa::Vector<casa::MPosition> &layout,
                      const casa::Vector<casa::Quantity> &diam) const throw(casa::AipsError);
    // some data shape parameters for the vis matrix used in writevis
    casa::uInt getNCorr() const throw(casa::AipsError);
    casa::uInt getNChan() const throw(casa::AipsError);
protected:
    IMSOperations *msop; // pointer to MSOperations class doing actual job
};


#endif // #ifndef __MSWRITER_HPP
