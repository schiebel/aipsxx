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
#if !defined(ATNF_REALDATASOURCE_H)
#define ATNF_REALNTDDATASOURCE_H
//# Includes

#include <casa/aips.h>
#include "NTDDataSource.h"

using namespace casa;

class RealNTDDataSource : public NTDDataSource 
{
public:
  // Real data source  
  RealNTDDataSource (const String& corrdevice_,
		     const String& obslog_,
		     const Double interval);
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

  ~RealNTDDataSource ();
protected:
private:
  String itsCorrDevice;
  String itsObsLog;
  Double itsInterval;
};
#endif
