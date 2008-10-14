// NTDMSDataSource.h: implementation of an NTD Data source
//
//  Copyright (C) 2005, 2006
//# Associated Universities, Inc. Washington DC, USA.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
//
//
//////////////////////////////////////////////////////////////////////
#if !defined(ATNF_NTDDATASOURCE_H)
#define ATNF_NTDDATASOURCE_H
//# Includes

#include <casa/aips.h>
#include <casa/Utilities/Assert.h>
#include <casa/BasicSL/Constants.h>
#include <casa/Arrays/Matrix.h>
#include <casa/OS/File.h>
#include <casa/OS/Path.h>
#include <casa/OS/Time.h> 
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MDirection.h>
#include <complex>

using namespace casa;

// Abstract Base Class for an NTD Data Source
class NTDDataSource
{
public:
  
  // Destructor
  virtual ~NTDDataSource() {};

  // Any more data?
  virtual Bool more()=0;

  // Get the data
  virtual Matrix<Complex> getData()=0;

  // Current data time
  virtual MEpoch getEpoch()=0;

  // Get current source
  virtual MDirection getSource()=0;

  // Get frequencies
  virtual Vector<Double> getFrequency()=0;

  // Source has changed
  virtual Bool sourceChanged()=0;

  // Frequency has changed
  virtual Bool freqChanged()=0;

protected:
  NTDDataSource (){};
};

#endif
  
