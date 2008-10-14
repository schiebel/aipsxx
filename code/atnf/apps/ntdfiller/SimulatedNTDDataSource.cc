// SimulatedNTDDataSource.cc: implementation of NTD Data source
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
#include <casa/Quanta/MVTime.h>

#include "SimulatedNTDDataSource.h"

using namespace casa;

// Attach to simulated data sources
SimulatedNTDDataSource::SimulatedNTDDataSource(const Double interval,
					       const Int n,
					       const Quantity& delayError) :
  itsInterval(Quantity(interval, "s")), itsCycles(n),
  itsThisSource("UNKNOWN"), itsLastSource(""),
  itsThisFreq(Quantity(1.55, "GHz"), MFrequency::TOPO),
  itsLastFreq(Quantity(0.00, "GHz"), MFrequency::TOPO),
  itsDelayError(delayError)
{
  itsCycle=0;
  Quantity today;
  MVTime::read(today, "today");
  MEpoch now(today, MEpoch::UTC);
  itsEpoch=now.getValue();
}

SimulatedNTDDataSource::~SimulatedNTDDataSource() {
}

Bool SimulatedNTDDataSource::more() {
  itsCycle++;
  itsEpoch+=itsInterval;
  return (itsCycle<=itsCycles);
}

MEpoch SimulatedNTDDataSource::getEpoch() {
  MEpoch epoch(itsEpoch, MEpoch::UTC);
  return epoch;
}

Matrix<Complex> SimulatedNTDDataSource::getData() {
  Matrix<Complex> data(1, 1024);
  MDirection source(getSource());
  MEpoch epoch(itsEpoch, MEpoch::UTC);
  Muvw uvw(itsNTDCoordinates.calcUVW(epoch, source));
  Double delay=uvw.getValue()(2);
  delay+=itsDelayError.getValue("m");
  Vector<Double> freq(getFrequency());
  for(uInt i=0;i<1024;i++) {
    Double phase=2.0*C::pi*freq(i)*delay/C::c;
    data(0,i)=Complex(cos(phase), sin(phase));
  }
  return data;
}

MDirection SimulatedNTDDataSource::getSource() {
  MDirection source(Quantity(60.0, "deg"), Quantity(-60, "deg"),
		    MDirection::J2000);
  return source;
}

Vector<Double> SimulatedNTDDataSource::getFrequency() {
  Vector<Double> freq(1024);
  for(uInt i=0;i<1024;i++) {
    freq(i)=1.55e9+24e3*i;
  }
  return freq;
}

Bool SimulatedNTDDataSource::freqChanged() {
  if(itsThisFreq.getValue()!=itsLastFreq.getValue()) {
    itsLastFreq=itsThisFreq;
    return True;
  }
  else {
    return False;
  }
}

Bool SimulatedNTDDataSource::sourceChanged() {
  if(itsThisSource!=itsLastSource) {
    itsLastSource=itsThisSource;
    return True;
  }
  else {
    return False;
  }
}
