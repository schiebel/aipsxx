//# GSDspectralWindow.cc
//# Copyright (C) 1996,1997,1998,2002
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
//# $Id: GSDspectralWindow.cc,v 19.1 2004/08/25 05:49:10 gvandiep Exp $

#include <hia/GSDDataSource/GSDspectralWindow.h>
#include <casa/Exceptions/Error.h>

GSDspectralWindow::GSDspectralWindow () 
{}


GSDspectralWindow::GSDspectralWindow (const Int nchan, 
 const Quantum<Double> centreFreq,
 const Quantum<Double> channelWidth,
 const Quantum<Double> restFreq,
 const Quantum<Double> bandwidth,
 const Quantum<Double> loFreq,
 const Quantum<Double> ifFreq,
 const Int sideband) :
  _bandwidth (bandwidth),
  _centreFreq (centreFreq),
  _channelWidth (channelWidth),
  _ifFreq (ifFreq),
  _loFreq (loFreq),
  _nchan (nchan),
  _restFreq (restFreq),
  _sideband (sideband)
{}



GSDspectralWindow::~GSDspectralWindow () 
{}


Bool GSDspectralWindow::operator== (const GSDspectralWindow &spw2) {
  Bool result = False;
  try {
    result = (_bandwidth == spw2._bandwidth) &&
             (_centreFreq == spw2._centreFreq) &&
             (_channelWidth == spw2._channelWidth) &&
             (_ifFreq == spw2._ifFreq) &&
             (_loFreq == spw2._loFreq) &&
             (_nchan == spw2._nchan) &&
             (_restFreq == spw2._restFreq) &&
             (_sideband == spw2._sideband);
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDspectralWindow::operator==|");
    throw (AipsError (message));
  }
  return result;
}


Quantum<Double> GSDspectralWindow::bandwidth () const {
  return _bandwidth;
}


Quantum<Double> GSDspectralWindow::centreFreq () const {
  return _centreFreq;
}


Quantum<Double> GSDspectralWindow::channelWidth () const {
  return _channelWidth;
}


Int GSDspectralWindow::nchan () const {
  return _nchan;
}


Quantum<Double> GSDspectralWindow::restFreq () const {
  return _restFreq;
}


Int GSDspectralWindow::sideband () const {
  return _sideband;
}




