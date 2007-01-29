//# GSDspectralWindow.h
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
//# $Id: GSDspectralWindow.h,v 19.2 2004/11/30 17:50:25 ddebonis Exp $

#if !defined(AIPS_GSDSPECTRALWINDOW_H)
#define AIPS_GSDSPECTRALWINDOW_H

#include <casa/aips.h>
#include <casa/Quanta.h>

#include <casa/namespace.h>
class GSDspectralWindow
{
public:
    GSDspectralWindow ();

    GSDspectralWindow (const Int nchan, 
     const Quantum<Double> centreFreq,
     const Quantum<Double> channelWidth, 
     const Quantum<Double> restFreq,
     const Quantum<Double> bandwidth,
     const Quantum<Double> loFreq,
     const Quantum<Double> ifFreq,
     const Int sideband);

    ~GSDspectralWindow();

    Bool operator== (const GSDspectralWindow &spw2);

    Quantum<Double> bandwidth () const;

    Quantum<Double> centreFreq () const;

    Quantum<Double> channelWidth () const;

    Quantum<Double> ifFreq () const;

    Quantum<Double> loFreq () const;

    Int nchan () const ;

    Quantum<Double> restFreq () const;

    Int sideband () const;

private:
    
    Quantum<Double> _bandwidth;

    Quantum<Double> _centreFreq;

    Quantum<Double> _channelWidth;

    Quantum<Double> _ifFreq;

    Quantum<Double> _loFreq;

    Int _nchan;

    Quantum<Double> _restFreq;

    Int _sideband;

};

#endif
