//# GSDDataSource.h : class for access to WSRT datasets
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
//# $Id: GSDDataSource.h,v 19.4 2005/06/18 21:19:15 ddebonis Exp $

#if !defined(AIPS_GSDDATASOURCE_H)
#define AIPS_GSDDATASOURCE_H

#include <vector>
#include <casa/Arrays.h>
#include <measures/Measures/MEpoch.h>
#include <ms/MeasurementSets.h>
#include <casa/BasicSL/String.h>
#include <hia/GSDDataSource/GSDspectralWindow.h>
 
#include <casa/namespace.h>
extern "C" {
  #include <gsdlib/gsd.h>
}

class GSDDataSource
{
public:
    GSDDataSource (const String gsdin);

    ~GSDDataSource();

    void fill (const String msout);

private:

    void copyData52 (MeasurementSet& measurementSet, Array<Float>& data,
     Array<Int>& c3lspc);

    void fillAntenna (MeasurementSet& measurementSet) const;

    void fillDataDescription (MeasurementSet& measurementSet) const;

    void fillDoppler (MeasurementSet& measurementSet) const;

    void fillFeed (MeasurementSet& measurementSet) const;

    void fillField (MeasurementSet& measurementSet) const;

    void fillObservation (MeasurementSet& measurementSet) const;

    void fillPointing (MeasurementSet& measurementSet) const;

    void fillPolarization (MeasurementSet& measurementSet) const;

    void fillProcessor (MeasurementSet& measurementSet) const;

    void fillRasterData (const String msname, MeasurementSet&
     measurementSet);

    void fillSampleData (const String msname, MeasurementSet&
     measurementSet);

    void fillSource (MeasurementSet& measurementSet) const;

    void fillSpectralWindow (MeasurementSet& measurementSet) const;

    void fillState (MeasurementSet& measurementSet) const;

    void fillSysCal (MeasurementSet& measurementSet) const;

    void fillWeather (MeasurementSet& measurementSet) const;

    void getConfiguration ();

    template <class T> void getItem (const String itemName, T& value,
     String &units) const;

    template <class T> void getArray (const String itemName, 
     Array<T>& data, vector<String>& dimNames) const;
    
    template <class T> int gsdGet (int itemno, T& value) const;

    template <class T> int gsdGet (int itemno, int& actDims, 
     int *dimVals, int *start, int *end, T *values, int& actVals) const;

    vector<uInt> _desc2Pol;

    vector<uInt> _desc2spwId;

    String _file;

    float _version;

    char _label [41];

    int _numItems;

    FILE *_filePtr;

    void *_fileDesc;

    MeasFrame _frame;

    void *_itemDesc;

    char *_dataPtr;

    String _obsType;

    int _nPol;

    int _MXP;

    int _NIS;

    int _numRows;

    MPosition _obsPosition;

    vector<uInt> _polVal;

    vector<MEpoch> _scanTime;

    vector<uInt> _section2DataDesc;

    MDirection _sourceDirection;

    MRadialVelocity _sourceVelocity;

    vector<GSDspectralWindow> _spectralWindow;

    mutable MEpoch _startEpoch;
};

#ifndef AIPS_NO_TEMPLATE_SRC
#include <hia/GSDDataSource/GSDDataSource.cc>
#endif //# AIPS_NO_TEMPLATE_SRC
#endif
