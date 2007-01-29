//# DOpimager: defines classes for pimager DO.
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
//# $Id: DOpimager.h,v 19.7 2005/06/16 16:50:06 kgolap Exp $

#ifndef APPSGLISH_DOPIMAGER_H
#define APPSGLISH_DOPIMAGER_H

#include <../imager/DOimager.h>
#include <synthesis/MeasurementComponents/PClarkCleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/PWFCleanImageSkyModel.h>
#include <synthesis/MeasurementEquations/PSkyEquation.h>

#include <casa/namespace.h>
// <summary> Parallel version of imager </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class="MeasurementSet">MeasurementSet</linkto>
//   <li> <linkto class="SkyEquation">SkyEquation</linkto>
//   <li> <linkto class="SkyModel">SkyModel</linkto>
// </prerequisite>
//
// <etymology>
// DO interface to the pimager application
// </etymology>
//
// <synopsis>
// This class is a parallelized version of imager.
// </synopsis>
//
// <example>
// <srcblock>
// </srcblock>
// </example>
//
// <motivation> 
// </motivation>
//
// <thrown>
// </thrown>
//
// <todo asof="2000/10/12">
// </todo>

class pimager : public imager
{
public:
  // Construct a pimager from a MeasurementSet
  pimager(MeasurementSet &thems);
  

  /*
  // Trial parallel read test function
  Bool tryparread(const String& thems, const Int& numloops);

  // Methods required for the AIPS++ DO tasking system. Specialized
  // by pimager to support additional DO methods.
  virtual Vector<String> methods() const;
  virtual MethodResult runMethod(uInt which, ParameterSet &inputRecord, 
				 Bool runMethod);

 protected:
  // Virtual methods to set the ImageSkyModel and SkyEquation.
  // Class pimager sets parallelized specializations.
  //
  virtual void setWFCleanImageSkyModel() 
    { ms_p->unlock();
      sm_p = new PWFCleanImageSkyModel(facets_p); return;};

  virtual void setClarkCleanImageSkyModel()
    {sm_p = new PClarkCleanImageSkyModel(); return;};

  virtual void setSkyEquation()
    {se_p = new PSkyEquation(*sm_p, *vs_p, *ft_p, *cft_p); return;};

  */

};

#endif




