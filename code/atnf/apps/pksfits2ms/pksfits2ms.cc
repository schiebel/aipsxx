//#---------------------------------------------------------------------------
//# pksfits2ms.cc: PKS RPFITS/SDFITS to MS2 translator.
//#---------------------------------------------------------------------------
//# Copyright (C) 2005-2006
//# Mark Calabretta, ATNF
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but
//# WITHOUT ANY WARRANTY; without even the implied warranty of
//# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
//# Public License for more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning this software should be addressed as follows:
//#        Internet email: mcalabre@atnf.csiro.au.
//#        Postal address: Dr. Mark Calabretta,
//#                        Australia Telescope National Facility,
//#                        P.O. Box 76,
//#                        Epping, NSW, 2121,
//#                        AUSTRALIA
//#
//# $Id: pksfits2ms.cc,v 1.3 2006/07/05 06:08:24 mcalabre Exp $
//#---------------------------------------------------------------------------
//# This program translates RPFITS or the SDFITS (Single Dish FITS) format
//# written by livedata into MS2 format.
//#
//# Original: 2005/02/14 Mark Calabretta
//#---------------------------------------------------------------------------

#include <casa/iostream.h>
#include <casa/namespace.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/Complex.h>
#include <casa/BasicSL/String.h>
#include <casa/Exceptions/Error.h>

#include <atnf/PKSIO/PKSFITSreader.h>
#include <atnf/PKSIO/PKSMS2writer.h>

int  copy(void);
void close(void);

// PKSFITS reader.
PKSreader *gReader;

// MS2 writer.
PKSMS2writer *gWriter;

//----------------------------------------------------------------------- main

int main(int argc, char **argv)
{
  try {
    // Parse arguments.
    if (argc != 3) {
      cerr << "Usage: pksfits2ms <infile> <outfile>" << endl;
      return 1;
    }

    // Open input PKS FITS file.
    Bool   haveBase, haveSpectra;
    String format;
    Vector<Bool> beams, haveXPol, IFs;
    Vector<uInt> nChan, nPol;
    if ((gReader = getPKSreader(argv[1], 0, 1, format, beams, IFs, nChan,
                     nPol, haveXPol, haveBase, haveSpectra)) == 0) {
      cerr << "Error opening input file." << endl;
      return 1;
    }

    // Select everything.
    uInt nIF = IFs.nelements();
    Vector<Bool> IFsel(nIF, True);
    Vector<Int> endChan(nIF,0), refChan, startChan(nIF,1);
    gReader->select(beams, IFsel, startChan, endChan, refChan, True, True);

    // Get header items.
    Double bandwidth, refFreq, utc;
    String antName, dopplerFrame, observer, obsType, project;
    Float  equinox;
    Vector<Double> antPos(3);
    if (gReader->getHeader(observer, project, antName, antPos, obsType,
                           equinox, dopplerFrame, utc, refFreq, bandwidth)) {
      cerr << "Error reading input header." << endl;
      return 1;
    }

    // Create the output measurementset.
    gWriter = new PKSMS2writer();
    if (gWriter->create(argv[2], observer, project, antName, antPos, obsType,
                        equinox, dopplerFrame, nChan, nPol, haveXPol,
                        haveBase)) {
      cerr << "Error creating output MS." << endl;
      close();
      return 1;
    }

    // Copy PKS FITS to MS2.
    if (copy()) {
      close();
      return 1;
    }

    close();

  } catch (AipsError err) {
    cerr << err.getMesg() << endl;
    return 1;
  }

  return 0;
}

//----------------------------------------------------------------------- copy

// Copy records from PKS FITS to MS2.

int copy(void)
{
  int    status;
  Int    beamNo, IFno, cycleNo, refBeam, scanNo;
  Float  azimuth, elevation, focusAxi, focusRot, focusTan, humidity, parAngle,
         pressure, temperature, windAz, windSpeed;
  Double bandwidth, freqInc, interval, mjd, refFreq, restFreq, srcVel;
  String          fieldName, obsType, srcName, tcalTime;
  Vector<Float>   calFctr, sigma, tcal, tsys;
  Matrix<Float>   baseLin, baseSub;
  Vector<Double>  direction(2), scanRate(2), srcDir(2), srcPM(2);
  Matrix<Float>   spectra;
  Matrix<uChar>   flagtra;
  Complex         xCalFctr;
  Vector<Complex> xPol;

  while ((status = gReader->read(scanNo, cycleNo, mjd, interval, fieldName,
                                 srcName, srcDir, srcPM, srcVel, obsType,
                                 IFno, refFreq, bandwidth, freqInc, restFreq,
                                 tcal, tcalTime, azimuth, elevation, parAngle,
                                 focusAxi, focusTan, focusRot, temperature,
                                 pressure, humidity, windSpeed, windAz,
                                 refBeam, beamNo, direction, scanRate, tsys,
                                 sigma, calFctr, baseLin, baseSub, spectra,
                                 flagtra, xCalFctr, xPol)) == 0) {

    status = gWriter->write(scanNo, cycleNo, mjd, interval, fieldName,
                            srcName, srcDir, srcPM, srcVel, obsType, IFno,
                            refFreq, bandwidth, freqInc, restFreq, tcal,
                            tcalTime, azimuth, elevation, parAngle,
                            focusAxi, focusTan, focusRot, temperature,
                            pressure, humidity, windSpeed, windAz,
                            refBeam, beamNo, direction, scanRate, tsys,
                            sigma, calFctr, baseLin, baseSub, spectra,
                            flagtra, xCalFctr, xPol);
    if (status) {
      cerr << "Error writing output MS." << endl;
      return 1;
    }
  }

  if (status != -1) {
    cerr << "Error " << status << " reading input file." << endl;
    return 1;
  }

  return 0;
}


//---------------------------------------------------------------------- close

// Close input and output.

void close(void)
{
  delete gReader;
  delete gWriter;
}
