// NTDDataSource.h: Definition of an NTD Data source
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
#if !defined(ATNF_SIMULATEDNTDDATASOURCE_H)
#define ATNF_SIMULATEDNTDDATASOURCE_H
//# Includes

#include <casa/aips.h>
#include "NTDDataSource.h"
#include "NTDCoordinates.h"

using namespace casa;

class SimulatedNTDDataSource : public NTDDataSource 
{
public:
  // Simulated data source  
  SimulatedNTDDataSource (const Double Interval, const Int n,
			  const Quantity& delay);

  // Any more data?
  Bool more();

  // Get the data
  Matrix<Complex> getData();

  // Current data time
  MEpoch getEpoch();

  // Get current source
  MDirection getSource();

  // Get frequencies
  Vector<Double> getFrequency();

  // Source has changed
  Bool sourceChanged();

  // Frequency has changed
  Bool freqChanged();

  ~SimulatedNTDDataSource();
private:
  MVEpoch itsEpoch;
  MVEpoch itsInterval;
  Int itsCycles;
  Int itsCycle;
  NTDCoordinates itsNTDCoordinates;
  String itsThisSource;
  String itsLastSource;
  MFrequency itsThisFreq;
  MFrequency itsLastFreq;
  Quantity itsDelayError;
};
#endif
  
