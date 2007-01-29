//# MSRead.h : class for reading a MeasurementSet
//# Copyright (C) 1997,1998,2000
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
//# $Id: MSRead.h,v 19.3 2004/11/30 17:50:39 ddebonis Exp $


#ifndef NFRA_MSREAD_H
#define NFRA_MSREAD_H
 
 
//# Includes
#include <ms/MeasurementSets/MeasurementSet.h>
#include <casa/namespace.h>

class MSRead
{
public:
    // Constructor: remember MeasurementSet
    MSRead (MeasurementSet* pms);

    // Destructor
    ~MSRead ();

    // Return name of class
    inline String className() const;
 
    // Do read the MeasurementSet
    void run(uInt row);

private:
    MeasurementSet* itspMS;

    // Read the main table; called by run()
    void read(MeasurementSet&,uInt);

    // Read the subtables; called by run()
    void read(MSAntenna&);
    void read(MSFeed&); 
    void read(MSField&); 
    void read(MSObservation&); 
    void read(MSSource&); 
    void read(MSPolarization&); 
    void read(MSSpectralWindow&); 
    void read(MSSysCal&); 
    void read(MSWeather&); 

};

inline String MSRead::className() const
{
    return "MSRead";
}
 
#endif
