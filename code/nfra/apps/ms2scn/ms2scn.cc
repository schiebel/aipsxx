//# ms2scn.cc : this program will fill a SCN-file from a MS-file
//# Copyright (C) 1997,1998,1999,2000,2001,2002,2003
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
//# $Id: ms2scn.cc,v 19.6 2006/03/06 10:37:30 rassendo Exp $

#define VERSION "20060227RA"

#include <casa/Inputs.h>
#include <MSRead.h>
#include <ConvertToSCN.h>
#include <casa/Utilities/Regex.h>
#include <tables/Tables/Table.h>
#include <casa/iostream.h>

int main(int argc, char* argv[])
{
    Table tab;
    try {
	cout << endl;
	cout << " ms2scn converts MeasurementSets to Newstar SCN files"<<endl;
	cout << " ----------------------------------------------------" << endl;

	// enable input in no-prompt mode
	Input inputs(1);

	// define the input structure
	inputs.version(VERSION);
	inputs.create ("msin", "",
		       "Name of input MeasurementSet", "string");
	inputs.create ("in", "",
		       "Name of input MeasurementSet (synonym of msin)",
		       "string");
	inputs.create ("dsout", "",
		       "Name of output dataset file", "string");
	inputs.create ("out", "",
		       "Name of output dataset file (synonym of dsout)",
		       "string");
	inputs.create ("row", "-1",
		       "MS row to display (<0: none)", "uInt");
	inputs.create ("haincr", "0",
		       "Increment for hourangle start (deg)", "double");
        inputs.create ("spwid","-1",
		       "Single spectral window id to read (<0: all)", "int");
        inputs.create ("channel","-1",
		       "Single channel to read (<0: all)", "int");
	inputs.create ("factor","1","Tsys correction factor", "double");
	inputs.create ("applytrx","1","Apply TRX factors", "int");
	inputs.create ("autocorr","0","Select autocorrelations", "int");
	inputs.create ("showcache","0","Show cache statistics", "int");
	inputs.create ("writeIF","0","Write IF table", "int");


	// fill the input structure from the command line
	inputs.readArguments (argc, argv);

	// get and check the input file specification
	String inName = inputs.getString("msin");
	if (inName == "") {
	  inName = inputs.getString("in");
	}
	if (inName == "") {
	    throw (AipsError
               (" the input MeasurementSet msin (or in) must be given"));
	}
        Path measurementSet(inName);
	cout << "The input MeasurementSet is: " 
	    << measurementSet.absoluteName() << endl;
	if (!measurementSet.isValid()) {
	    throw (AipsError(" The MeasurementSet path is not valid"));
	}
	if (!File(measurementSet).exists()) {
	    throw (AipsError(" The MeasurementSet file does not exist"));
	}
	if (!File(measurementSet).isReadable()) {
	    throw (AipsError(" The MeasurementSet file is not readable"));
	}

	// get and check the outputfile specification
	String outName(inputs.getString("dsout"));
	if (outName == "") {
	  outName = inputs.getString("out");
	}
	if (outName == "") {
	    outName = inName;
	    outName = outName.before(Regex("\\.MS$")) + ".SCN";
	}
	Path dataset(outName);
        if (!File(dataset).canCreate()) {
            throw (AipsError(" The dataset-file cannot be created"));
        }
	cout << "The output SCN file is: "
	     << dataset.absoluteName() << endl;

	Double haIncr(inputs.getDouble ("haincr"));
	cout << haIncr << " deg is added to the start hourangles" << endl;
	haIncr /= 360;

	// apply TRX factors?
	Bool applyTRX =  (inputs.getInt("applytrx"));
	cout << "TRX factors from the SYSCAL subtable will ";
	if (!applyTRX) {
	    cout << "NOT ";
	}
	cout << "be applied" << endl;

	Double tsysFactor(inputs.getDouble ("factor"));
	cout << "Tsys correction factor " << tsysFactor << " is used" << endl;

	// get and check the selection argument
 	int row(inputs.getInt("row"));

        // get selected spectral window.
        int spwid = inputs.getInt("spwid");
	if (spwid >= 0) {
	    cout << "Spectral window id " << spwid << " is selected" << endl;
	}

        // get selected channel
        int reqChannel = inputs.getInt("channel");
	if (reqChannel >= 0) {
	    cout << "Frequency channel " << reqChannel << " is selected"
		 << endl;
	}

	// select autocorrelations?
	Bool autoCorr =  (inputs.getInt("autocorr"));

	// show cache statistics?
	Bool showCache =  (inputs.getInt("showcache"));

	// add syscal table?
	Bool addSysCal =  (inputs.getInt("writeIF"));
	cout << "The IF table will ";
	if (!addSysCal) {
	    cout << "NOT ";
	}
	cout << "written" << endl;

	cout << "Open the MeasurementSet ";
	MeasurementSet ms(measurementSet.absoluteName(), Table::Old);
	ROMSColumns msc(ms);
  	MSRead msf(&ms);
	cout << "OK" <<endl;
	if (row>=0) {
	   msf.run(row);				// Show specified row
	}

        if (ms.nrow()<2) {
            throw (AipsError(" The measurement set contains no data"));
	}

	// Write NStarFile
	ConvertToSCN aConvertor(ms, dataset);

	if (aConvertor.prepare (applyTRX, autoCorr, spwid)) {
	  if (reqChannel>=0) {
	    aConvertor.setChannel(reqChannel);
	  }

	  if (aConvertor.convert (haIncr, tsysFactor, applyTRX, 
				  showCache, addSysCal, autoCorr)) {
	    aConvertor.write();
	    cout << "OK" << endl;
	  }
	} else {
	  cerr << "\nms2scn ended with error ...\n";
	  return 1;
	}

    } catch (AipsError x) {
	cout << "Exception thrown: \"" << x.getMesg() << "\"" << endl;
	return 1;
    }
    cout << "ms2scn normally ended" << endl;
    return 0;
}

