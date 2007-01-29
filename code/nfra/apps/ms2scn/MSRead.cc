//# MSRead.cc : class for reading a MeasurementSet 
//# Copyright (C) 1997,1998,1999,2000,2002
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
//# $Id: MSRead.cc,v 19.1 2004/08/25 05:49:25 gvandiep Exp $
 

#include <MSRead.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <casa/Arrays.h>
#include <casa/Arrays/Slicer.h>
#include <scimath/Mathematics.h>
#include <measures/Measures/Stokes.h>
#include <casa/iostream.h>


MSRead::MSRead (MeasurementSet* pms)
: itspMS (pms)
{
}

MSRead::~MSRead ()
{
}

void MSRead::read(MeasurementSet& ms, uInt row)
{
    cout << " " << endl;
    cout << " Main table " << endl;
    cout << " ---------- " << endl;
    cout << "MSRead: reading " << ms.tableName() << endl;

    // Instantiate the column objects we need.
    // This gets us all the required columns
    ROMSColumns msc(ms); 

    // == Read the MeasurementSet row
    cout << "Total # of Rows = " << ms.nrow() << endl;
    cout << "Processing Rows = " << row << endl;

    // Get the values that are constant for the whole dataset (for now,
    //most of them are hardcoded values, but at some time they may be
    //read from the dataset's observation header) and put them in the
    //first row.
    // (WSRT single OH block)

    cout << "antenna1, antenna2 : " << msc.antenna1()(row) 
         << ", " << msc.antenna2()(row) << endl;
    cout << "arrayId            : " << msc.arrayId()(row) << endl;
    cout << "exposure           : " << msc.exposure()(row) << " s" << endl;
    cout << "feed1, feed2       : " << msc.feed1()(row)
	 <<  ", " << msc.feed2()(row) << endl;
    cout << "fieldId            : " << msc.fieldId()(row) << endl;
    cout << "flag               : " << msc.flag()(row) << endl;
//    cout << "flagHistory        : " << msc.flagHistory()(row) << endl;
    cout << "flagRow            : " << msc.flagRow()(row) << endl;
    cout << "interval           : " << msc.interval()(row) << " s" << endl;
    cout << "observationId      : " << msc.observationId()(row) << endl;
    cout << "pulsarBin          : " << msc.pulsarBin()(row) << endl;
//    cout << "pulsarGateId       : " << msc.pulsarGateId()(row) << endl;
    cout << "scanNumber         : " << msc.scanNumber()(row) << endl;
    cout << "sigma              : " << msc.sigma()(row) << endl;
//    cout << "sourceId          : " << msc.sourceId()(row) << endl;
    cout << "dataDescription Id : " << msc.dataDescId()(row) << endl;
    cout << "time               : " << msc.time()(row) << " s" << endl;
    cout << "uvw                : " << msc.uvw()(row) << " m" << endl;
    cout << "weight             : " << msc.weight()(row) << endl;
//    cout << "floatData          : " << msc.floatData()(row) << endl;
//    cout << "sigmaSpectrum      : " << msc.sigmaSpectrum()(row) << endl;
//    cout << "timeExtraPrec      : " << msc.timeExtraPrec()(row) << " s" << endl;
//    cout << "weightSpectrum     : " << msc.weightSpectrum()(row) << endl;
    cout << "Data               : " << msc.data()(row) << endl;

    cout << "MSRead: ready " << endl;
}

void MSRead::read(MSAntenna& msant)
{
    cout << " " << endl;
    cout << " Antenna subtable " << endl;
    cout << " ---------------- " << endl;
    cout << "MSRead: reading " << msant.tableName() << endl;

    // Get access to the columns of the subtable
    ROMSAntennaColumns antc(msant);

    // Number of antennas
    Int nAnt = msant.nrow();
    cout << "Total # of Antenna's = " << msant.nrow() << endl;

    // Show the result
    cout << " dish diameter : " << antc.dishDiameter()(0) << " m" << endl;
    cout << " mount type : " << antc.mount()(0) << endl;
    cout << " axes offset of mount : " << antc.offset()(0) << " m" << endl;
    cout << " orbit id : " << antc.orbitId()(0) << endl;
    cout << " phased array id : " << antc.phasedArrayId()(0) << endl;
    cout << " station : " << antc.station()(0) << endl;
    for (Int j=0; j<nAnt; j++) {
	cout << " Antenna " << antc.name()(j)
	     << " : id = " << j
	     << ", position = " << antc.position()(j) << " m" << endl;
    }
}

void MSRead::read(MSFeed& msfeed) 
{
    cout << " " << endl;
    cout << " Feed subtable " << endl;
    cout << " ------------- " << endl;
    cout << "MSRead: reading " << msfeed.tableName() << endl;

    // Get access to the columns of the subtable
    ROMSFeedColumns feedc(msfeed);

    // Number of feeds
    cout << "Total # of Feed's = " << msfeed.nrow() << endl;

    // Show the result for the first row
    cout << " --SHOW FIRST ROW ONLY:-- " << endl;
    cout << " antenna id : " << feedc.antennaId()(0) << endl;
    cout << " beam id : " << feedc.beamId()(0) << endl;
    cout << " beam offset : " << feedc.beamOffset()(0) << " rad" << endl;
    cout << " feed id : " << feedc.feedId()(0) << endl; 
    cout << " time interval : " << feedc.interval()(0) << " s" << endl;
    cout << " nr of receptors : " << feedc.numReceptors()(0) << endl;
    cout << " phased feed id : " << feedc.phasedFeedId()(0) << endl;
    cout << " polarization response : " << feedc.polResponse()(0) << endl;
    cout << " polarization type : " << feedc.polarizationType()(0) << endl;
    cout << " relative position : " << feedc.position()(0) << " m" << endl;
    cout << " receptor angle : " << feedc.receptorAngle()(0) << " rad" << endl;
    cout << " spectral window id : " << feedc.spectralWindowId()(0) << endl;
    cout << " time (midpoint) : " << feedc.time()(0) << " s" << endl;
}

void MSRead::read(MSField& msfield)
{
    cout << " " << endl;
    cout << " Field subtable " << endl;
    cout << " -------------- " << endl;
    cout << "MSRead: reading " << msfield.tableName() << endl;

    // Get access to the columns of the subtable
    ROMSFieldColumns fieldc(msfield);

    // Show the result
    cout << " special characteristics : " << fieldc.code()(0) << endl;
    cout << " delay direction : " << fieldc.delayDir()(0) << " rad" << endl;
    cout << " field id   : " << 0 << endl;
    cout << " field name : " << fieldc.name()(0) << endl;
    cout << " num poly   : " << fieldc.numPoly()(0) << endl;
    cout << " phase direction : " << fieldc.phaseDir()(0) << " rad" << endl;
    cout << " reference direction : " << fieldc.referenceDir()(0) << " rad" << endl;
    cout << " source id  : " << fieldc.sourceId()(0) << endl;
    cout << " time (midpoint) : " << fieldc.time()(0) << " s" << endl;

    // Read source table (if present)
    if (fieldc.sourceId()(0) != -1) {
       read(itspMS->source());
       cout << "MSRead: source table read" << endl;
    } else {
       cout << " No corresponding source defined, Source subtable NOT read" << endl;
    }

}

void MSRead::read(MSObservation& msobs)
{
    cout << " " << endl;
    cout << " Observation subtable " << endl;
    cout << " -------------------- " << endl;
    cout << "MSRead: reading " << msobs.tableName() << endl;

    // Get access to the columns of the subtable
    ROMSObservationColumns obsc(msobs);

    // Show the result
    cout << " Telescope name     : " << obsc.telescopeName()(0) << endl;
    cout << " Schedule type      : " << obsc.scheduleType()(0) << endl;
    cout << " Project schedule   : " << obsc.schedule()(0) << endl;
    cout << " Name of observer(s): " << obsc.observer()(0) << endl;
    cout << " Observing log      : " << obsc.log()(0) << endl;
    cout << " Project identification string : " << obsc.project()(0) << endl;
}

void MSRead::read(MSSource& mssrc)
{
    cout << " " << endl;
    cout << " Source subtable " << endl;
    cout << " --------------- " << endl;
    cout << "MSRead: reading " << mssrc.tableName() << endl;

    // Get access to the columns of the subtable
    ROMSSourceColumns srcc(mssrc);

    // Show the result
    cout << " calibration group : " << srcc.calibrationGroup()(0) << endl;
    cout << " special characteristics : " << srcc.code()(0) << endl;
    cout << " direction         : " << srcc.direction()(0) << " rad" << endl;
    cout << " time interval     : " << srcc.interval()(0) << " s" << endl;
    cout << " source            : " << srcc.name()(0) << endl;
    cout << " position          : " << srcc.position()(0) << " m" << endl;
    cout << " proper motion     : " << srcc.properMotion()(0) << " rad/s" <<  endl;
    cout << " source id         : " << srcc.sourceId()(0) << endl;
    cout << " spectral window id: " << srcc.spectralWindowId()(0) << endl;
    cout << " rest frequency    : " << srcc.restFrequency()(0) << " Hz" << endl;
    cout << " systemic velocity : " << srcc.sysvel()(0) << " m/s" << endl;
    cout << " time (midpoint)   : " << srcc.time()(0) << " s" << endl;
}

void MSRead::read(MSPolarization& mspol)
{
    cout << " " << endl;
    cout << " Polarization subtable " << endl;
    cout << " --------------------- " << endl;
    cout << "MSRead: reading " << mspol.tableName() << endl;

    // Get access to the columns of the subtable
    ROMSPolarizationColumns polc(mspol);

    // Show the result
    cout << " correlation product = " << polc.corrProduct()(0) << endl;
    cout << " correlation type    = " << polc.corrType()(0) << endl;
    cout << " nr of correlations  = " << polc.numCorr()(0) << endl;
}

void MSRead::read(MSSpectralWindow& msspwin)
{
    cout << " " << endl;
    cout << " SpectralWindow subtable " << endl;
    cout << " ----------------------- " << endl;
    cout << "MSRead: reading " << msspwin.tableName() << endl;

    // Get access to the columns of the subtable
    ROMSSpWindowColumns spwinc(msspwin);

    // Show the result
    cout << " channel frequencies = " << spwinc.chanFreq()(0) << " Hz" << endl;
    cout << " IF conversion chain = " << spwinc.ifConvChain()(0) << endl;
    cout << " nr of channels      = " << spwinc.numChan()(0) << endl;
    cout << " reference frequency = " << spwinc.refFrequency()(0) << " Hz" << endl;
    cout << " resolution          = " << spwinc.resolution()(0) << " Hz" << endl;
    cout << " total bandwidth     = " << spwinc.totalBandwidth()(0) << " Hz" << endl;
}

void MSRead::read(MSSysCal& mssyscal)
{
    cout << " " << endl;
    cout << " SysCal subtable " << endl;
    cout << " -------------- " << endl;
    cout << "MSRead: reading " << mssyscal.tableName() << endl;

    // Get access to the columns of the subtable
    ROMSSysCalColumns syscalc(mssyscal);

    // Show the result
    cout << " --SHOW FIRST ROW ONLY:-- " << endl;
    cout << " antenna id        : " << syscalc.antennaId()(0) << endl;
    cout << " feed id           : " << syscalc.feedId()(0) << endl;
    cout << " time interval     : " << syscalc.interval()(0) << " s" << endl;
    cout << " phase difference  : " << syscalc.phaseDiff()(0) << " rad" << endl;
    cout << " phase diff flag   : " << syscalc.phaseDiffFlag()(0) << endl;
    cout << " spectral window id: " << syscalc.spectralWindowId()(0) << endl;
    cout << " receptor temp     : " << syscalc.tcal()(0) << " K" << endl;
    cout << " receptor temp flag: " << syscalc.tcalFlag()(0) << endl;
    cout << " time (midpoint)   : " << syscalc.time()(0) << " s" << endl;
    cout << " receiver temp     : " << syscalc.trx()(0) << " K" << endl;
    cout << " rec temp flag     : " << syscalc.trxFlag()(0) << endl;
    cout << " system temp       : " << syscalc.tsys()(0) << " K" << endl;
    cout << " system temp flag  : " << syscalc.tsysFlag()(0) << " " << endl;

}

void MSRead::read(MSWeather& msweather)
{
    cout << " " << endl;
    cout << " Weather subtable " << endl;
    cout << " ---------------- " << endl;
    cout << "MSRead: reading " << msweather.tableName() << endl;

    // Get access to the columns of the subtable
    ROMSWeatherColumns weathc(msweather);

    // Show the result
    cout << " --SHOW FIRST ROW ONLY:-- " << endl;
    cout << " antenna id        : " << weathc.antennaId()(0) << endl;
    cout << " water column dens : " << weathc.H2O()(0) << " m^-2" << endl;
    cout << " time interval     : " << weathc.interval()(0) << " s" << endl;
    cout << " electron col dens : " << weathc.ionosElectron()(0) << " m^-2" << endl;
    cout << " presssure         : " << weathc.pressure()(0) << " Pa" << endl;
    cout << " relative humidity : " << weathc.relHumidity()(0) << endl;
    cout << " air temperature   : " << weathc.temperature()(0) << " K" << endl;
    cout << " time (midpoint)   : " << weathc.time()(0) << " s" << endl;
    cout << " wind direction    : " << weathc.windDirection()(0) << " rad" << endl;
    cout << " wind speed        : " << weathc.windSpeed()(0) << " m/s" << endl;
}

void MSRead::run(uInt row)
{
    cout << "MSRead: read MS row " << row << " straight-away " << endl;

    // read the main table
    read(*itspMS,row);
    cout << "MSRead: main table read" << endl;

    // read the subtables
    read(itspMS->antenna());
    cout << "MSRead: antenna table read" << endl;
    read(itspMS->feed());
    cout << "MSRead: feed table read" << endl;
    read(itspMS->field());
    cout << "MSRead: field table read" << endl;
    read(itspMS->observation());
    cout << "MSRead: observation table read" << endl;
    read(itspMS->polarization());
    cout << "MSRead: polarization table read" << endl;
    read(itspMS->spectralWindow());
    cout << "MSRead: spectralWindow table read" << endl;
    read(itspMS->sysCal());
    cout << "MSRead: sysCal table read" << endl;
    read(itspMS->weather());
    cout << "MSRead: weather table read" << endl;
}
