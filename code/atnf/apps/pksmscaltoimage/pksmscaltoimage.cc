//# pksmscaltoimage.cc: convert an mscal file into an image
//# Copyright (C) 1994,1995,1996,1997,1998,1999,2000,2001,2002
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: pksmscaltoimage.cc,v 19.3 2004/11/30 17:50:10 ddebonis Exp $

//
// Stand alone program to convert an mscal file into an image
// for visualisation purposes.
//
// This is pretty sloppily written and pretty light-on for error
// checking, aside from obvious stuff.
//
// David Barnes, August 1998
//


#include <casa/aips.h>
#include <casa/Exceptions/Error.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/BasicSL/String.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSMainColumns.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/ExprNode.h>
#include <tables/Tables/ArrayColumn.h>

#include <casa/Arrays/IPosition.h>
#include <lattices/Lattices/TiledShape.h>
#include <images/Images/PagedImage.h>
#include <coordinates/Coordinates/LinearCoordinate.h>
#include <coordinates/Coordinates/CoordinateSystem.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
int main(int argc, char **argv) {
  try {
    if ((argc != 3) && (argc != 4)) {
      cerr << "Sorry - you need to give an input mscal file name and" << endl;
      cerr << "one or two output image file names." << endl;
      exit(1);
    }
    String mscal = argv[1];

    String image1, image2;
    image1 = argv[2];
    if (argc == 4) {
      image2 = argv[3];
    }

    Table datatb(mscal);
    // count beams, pols, chans, rows...
    Bool ok = True;
    Int ibm = 0;
    Int g_nrows, g_nchans, g_npols;
    g_nrows = g_nchans = g_npols = 0;
    while (ok) {
      Table data = datatb(datatb.col("FEED1") == ibm);
      Int nrows = data.nrow();
      if (!nrows) {
	ok = False;
	break;
      }
      if (ibm == 0) {
	g_nrows = nrows;
      } else if (nrows != g_nrows) {
	cerr << "Number of rows different for different beams." << endl;
	exit(1);
      }
      ROArrayColumn<Float> datafloatcol(data, "FLOAT_DATA");
      Array<Float> datafloatdata;
      datafloatcol.getColumn(datafloatdata);
      
      Int npols = datafloatdata.shape()(0);
      Int nchans = datafloatdata.shape()(1);

      if (ibm == 0) {
	g_npols = npols;
	g_nchans = nchans;
      } else if ((npols != g_npols) || (nchans != g_nchans)) {
	cerr << "Number of pols/chans different for different beams." << endl;
	exit(1);
      }
      ibm++;
    }      

    Int g_nbeams = ibm;

    cerr << "Mscal has " << g_nbeams << " beams, "
	 << g_nrows << " integrations per beam, "
	 << g_npols << " polarizations per beam, and "
	 << g_nchans << " channels per spectrum." << endl;

    const MS lms(mscal);
    const ROMSMainColumns lmsc(lms);
    Vector<Double> timestamps;
    lmsc.time().getColumn(timestamps); 

    if (argc == 3) {

      // we have one output image - retain polarization data:

      // now construct the coordsys:
      CoordinateSystem csys;
      Vector<String> names(4);
      names(0) = "Beam";
      names(1) = "Polarization";
      names(2) = "Channel";
      names(3) = "Time";
      Vector<String> units(4);
      units = "_";
      units(3) = "s";
      Vector<Double> refVal(4);
      refVal = 1.0;
      refVal(3) = timestamps(0);
      //cerr << timestamps(0) << endl;
      Vector<Double> inc(4);
      inc = 1.0;
      inc(3) = (timestamps(timestamps.nelements() - 1) - timestamps(0)) /
	(Double)(g_nrows - 1);
      //cerr << timestamps(timestamps.nelements() - 1) << endl;
      //cerr << inc(3) << endl;
      Vector<Double> refPix(4);
      refPix = 0.0;
      Matrix<Double> xform(4, 4);
      xform = 0.0;
      xform.diagonal() = 1.0;
      csys.addCoordinate(LinearCoordinate(names, units, refVal, inc,
					  xform, refPix));
      
      // now make image
      PagedImage<Float> outim((TiledShape(IPosition(4, g_nbeams, g_npols,
						    g_nchans, g_nrows))),
			      csys, image1);
      outim.setUnits(Unit("Jy"));
      
      // now fill image with data
      for (ibm = 0; ibm < g_nbeams; ibm++) {
	cerr << "Writing beam " << ibm + 1 << endl;
	Table data = datatb(datatb.col("FEED1") == ibm);
	ROArrayColumn<Float> datafloatcol(data, "FLOAT_DATA");
	Array<Float> datafloatdata;
	datafloatcol.getColumn(datafloatdata);
	
	Array<Float> dataslab(IPosition(4, 1, g_npols, g_nchans, g_nrows));
	for (Int ipol = 0; ipol < g_npols; ipol++) {
	  for (Int ichan = 0; ichan < g_nchans; ichan++) {
	    for (Int irow = 0; irow < g_nrows; irow++) {
	      dataslab(IPosition(4, 1, ipol, ichan, irow)) =
		datafloatdata(IPosition(3, ipol, ichan, irow));
	    }
	  }
	}
	outim.doPutSlice(dataslab, IPosition(4, ibm, 0, 0, 0),
			 IPosition(4, 1, 1, 1, 1));
	
      }
      
    } else {

      // we have two output image file names, so split polarization data:
    
      // now construct the coordsys:
      CoordinateSystem csys;
      Vector<String> names(3);
      names(0) = "Beam";
      names(1) = "Channel";
      names(2) = "Time";
      Vector<String> units(3);
      units = "_";
      units(2) = "s";
      Vector<Double> refVal(3);
      refVal = 1.0;
      refVal(2) = timestamps(0);
      //cerr << timestamps(0) << endl;
      Vector<Double> inc(3);
      inc = 1.0;
      inc(2) = (timestamps(timestamps.nelements() - 1) - timestamps(0)) /
	(Double)(g_nrows - 1);
      //cerr << timestamps(timestamps.nelements() - 1) << endl;
      //cerr << inc(1) << endl;
      Vector<Double> refPix(3);
      refPix = 0.0;
      Matrix<Double> xform(3, 3);
      xform = 0.0;
      xform.diagonal() = 1.0;
      csys.addCoordinate(LinearCoordinate(names, units, refVal, inc,
					  xform, refPix));
      
      // now make image
      PagedImage<Float> outim1((TiledShape(IPosition(3, g_nbeams,
						     g_nchans, g_nrows))),
			       csys, image1);
      outim1.setUnits(Unit("Jy"));
      PagedImage<Float> outim2((TiledShape(IPosition(3, g_nbeams,
						     g_nchans, g_nrows))),
			       csys, image2);
      outim2.setUnits(Unit("Jy"));
      
      // now fill image with data
      for (ibm = 0; ibm < g_nbeams; ibm++) {
	cerr << "Writing beam " << ibm + 1 << endl;
	Table data = datatb(datatb.col("FEED1") == ibm);
	ROArrayColumn<Float> datafloatcol(data, "FLOAT_DATA");
	Array<Float> datafloatdata;
	datafloatcol.getColumn(datafloatdata);
	
	Array<Float> dataslab1(IPosition(3, 1, g_nchans, g_nrows));
	Array<Float> dataslab2(IPosition(3, 1, g_nchans, g_nrows));
	for (Int ichan = 0; ichan < g_nchans; ichan++) {
	  for (Int irow = 0; irow < g_nrows; irow++) {
	    dataslab1(IPosition(3, 1, ichan, irow)) =
	      datafloatdata(IPosition(3, 1, ichan, irow));
	    dataslab2(IPosition(3, 1, ichan, irow)) =
	      datafloatdata(IPosition(3, 2, ichan, irow));
	  }
	}
	outim1.doPutSlice(dataslab1, IPosition(3, ibm, 0, 0),
			  IPosition(3, 1, 1, 1));
	outim2.doPutSlice(dataslab2, IPosition(3, ibm, 0, 0),
			  IPosition(3, 1, 1, 1));
      }

    }      
  } catch (AipsError x) {
    cerr << "Exception caught: " << x.getMesg() << endl;
  } 

  return 0;
}
    
