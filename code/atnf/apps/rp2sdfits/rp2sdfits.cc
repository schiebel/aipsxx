//#---------------------------------------------------------------------------
//# rp2sdfits.cc: RPFITS to SDFITS translator.
//#---------------------------------------------------------------------------
//# Copyright (C) 2000-2006
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
//# $Id: rp2sdfits.cc,v 19.5 2006/06/20 02:13:31 mcalabre Exp $
//#---------------------------------------------------------------------------
//# This program translates single dish RPFITS files (such as Parkes Multibeam
//# MBFITS files) into Single Dish FITS (SDFITS) format.
//#
//# Original: 2000/04/27 Mark Calabretta
//#---------------------------------------------------------------------------

#include <atnf/PKSIO/MBFITSreader.h>
#include <atnf/PKSIO/PKSMBrecord.h>
#include <atnf/PKSIO/SDFITSwriter.h>

#include <casa/iostream.h>

#include <casa/namespace.h>

int  copy(void);
void close(void);

// MBFITS reader.
MBFITSreader *gReader;

// SDFITS writer.
SDFITSwriter *gWriter;

//----------------------------------------------------------------------- main

int main(int argc, char **argv)
{
  // Parse arguments.
  if (argc < 3 || argc > 4) {
    cerr << "Usage: rp2sdfits [-n] <infile> <outfile>" << endl;
    return 1;
  }

  int interpolate = 1;
  if (argc > 3) {
    if (strcmp(argv[1], "-n") == 0) {
      interpolate = 0;
    } else {
      cerr << "Usage: rp2sdfits [-n] <infile> <outfile>" << endl;
      return 1;
    }
  }

  char *rpname = argv[argc-2];
  char *sdname = argv[argc-1];

  // Create reader and writer.
  gReader = new MBFITSreader(0, interpolate);
  gWriter = new SDFITSwriter();

  // Open input RPFITS file.
  int    *beams, extraSysCal, haveBase, haveSpectra, *haveXPol, *IFs, nBeam,
         *nChan, nIF, *nPol;
  if (gReader->open(rpname, nBeam, beams, nIF, IFs, nChan, nPol, haveXPol,
                    haveBase, haveSpectra, extraSysCal)) {
    return 1;
  }

  // Get header items.
  char   datobs[32], freqRef[32], observer[32], obsType[32], project[32],
         radecsys[32], telescope[32];
  float  equinox;
  double antPos[3], bandwidth, refFreq, utc;

  if (gReader->getHeader(observer, project, telescope, antPos, obsType,
                         equinox, radecsys, freqRef, datobs, utc, refFreq,
                         bandwidth)) {
    return 1;
  }


  // Create the output SDFITS file.
  if (gWriter->create(sdname, observer, project, telescope, antPos, obsType,
                      equinox, freqRef, nIF, nChan, nPol, haveXPol, haveBase,
                      extraSysCal)) {
    gWriter->reportError();
    gWriter->deleteFile();
    close();
    return 1;
  }

  // Copy RPFITS to SDFITS.
  if (copy()) {
    gWriter->deleteFile();
    close();
    return 1;
  }

  close();

  return 0;
}

//----------------------------------------------------------------------- copy

// Copy records from RPFITS to SDFITS.

int copy(void)
{
  int    status;
  PKSMBrecord mbrec(1);

  while ((status = gReader->read(mbrec)) == 0) {
    status = gWriter->write(mbrec);
    if (status) {
      gWriter->reportError();
      return 1;
    }
  }

  if (status != -1) {
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
