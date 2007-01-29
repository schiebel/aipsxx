// NTDMSDataSource.cc: implementation of NTD MS filler
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
#include <casa/aips.h>
#include <casa/Utilities/Assert.h>
#include "RealNTDDataSource.h"

#include <unistd.h>
#include <signal.h>

using namespace casa;

void sigTermHandler(int);
Bool globalRealNTDDataSourceTerminate=False;

// Attach to real data sources
RealNTDDataSource::RealNTDDataSource(const String& device, const String& obsLog,
				     const Double interval=1) :
  itsCorrDevice(device), itsObsLog(obsLog), itsInterval(interval)
{
  signal(SIGINT, sigTermHandler);
  signal(SIGTSTP, sigTermHandler);
  signal(SIGTERM, sigTermHandler);
}

RealNTDDataSource::~RealNTDDataSource() {
}

Bool RealNTDDataSource::more() {
  if(globalRealNTDDataSourceTerminate) return False;
  usleep(uInt(1000000*itsInterval));
  return True;
}

Matrix<Complex> RealNTDDataSource::getData() {
  Matrix<Complex> data(1, 1024);
  data=Complex(1.0);
  return data;
}

MEpoch RealNTDDataSource::getEpoch() {
  MEpoch epoch;
  return epoch;
}

MDirection RealNTDDataSource::getSource() {
  MDirection source;
  return source;
}

Vector<Double> RealNTDDataSource::getFrequency() {
  Vector<Double> freq(1024);
  for(uInt i=0;i<1024;i++) {
    freq(i)=1.55e9+24e3*i;
  }
  return freq;
}

// Source has changed
Bool RealNTDDataSource::sourceChanged() {return False;};

// Frequency has changed
Bool RealNTDDataSource::freqChanged() {return False;};


void sigTermHandler(int sig) {
  cout << "Received interrupt - terminating at next opportunity" << endl;
  globalRealNTDDataSourceTerminate=True;
}


