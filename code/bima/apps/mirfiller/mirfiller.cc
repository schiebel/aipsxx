//# mirfiller.cc: This is the standalone version of the Miriad Filler application
//# Copyright (C) 2000,2001,2002
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
//# $Id: mirfiller.cc,v 19.3 2004/11/30 17:50:11 ddebonis Exp $

//# Includes
#include <bima/Filling/MirFiller.h>
#include <bima/Filling/DOmirfiller.h>
#include <mirfillerFactory.h>

#include <tasking/Tasking.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Vector.h>
#include <casa/Containers/Record.h>
#include <casa/Containers/RecordField.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Inputs/Input.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
int main(int argc, char **argv)
{
  Bool hasInterpreter = False;
  for(Int a=0; ! hasInterpreter && a < argc; a++) 
    hasInterpreter = String(argv[a]).matches(String("-interpreter"));

  if (hasInterpreter) {                        // distributed object
    ObjectController controller(argc, argv);
    controller.addMaker("mirfiller", new mirfillerFactory());
    controller.loop();
  }
  else {                                       // standalone application
    Int debug=0, i;

    try {
    
	// Define inputs
	Input inp(1);
	inp.version("1 - BIMA to MS2 filler (06-mar-01 RLP)");
	inp.create("mirfile", "3c273", "Name of Miriad dataset name", "string");
	inp.create("msfile", "junk.MS", "Name of MeasurementSet", "string");    
	inp.create("splwin","all",
		   "Which of the spectral line (narrow band) windows",
                   "string");
	inp.create("winav","all","Which of the spectral line window averages",
		   "string");
	inp.create("sbandav","all",
                   "Which of the sideband (wide band) averages","string");

//	inp.create("nosplit","False","seperate spectral windows?","bool");
	inp.create("verbose","False","log extra messages?","bool");
	inp.create("joinpol","False","join polarizations?","bool");
	inp.create("preview","True","Pre-scan the input dataset?","bool");
	inp.create("scanlim","5","scan cutoff limit (minutes)","int");
	inp.create("obslim","4","observation cutoff limit (hours)","int");
//	inp.create("histbl","","alternate history source table","string");
	inp.create("wideconv","none",
                   "wide channel convention (bima|miriad|none)","string");
	inp.create("tilesize","0",
                   "Tilesize for the TiledStorageManager (in channels)", 
                   "int");  

	inp.readArguments(argc, argv);

	String mirfile(inp.getString("mirfile"));;
	String msfile(inp.getString("msfile"));
	if(msfile.length()==0) msfile=mirfile.before('.') + ".ms";

	for (i=1; i<10 && inp.debug(i); i++)
	    debug = i;

	MirFiller filler(mirfile, False,debug);
        GlishRecord sum = filler.summary(inp.getBool("verbose"), 
                                         inp.getBool("preview"));
	Int nwide, nspect;
        ((GlishArray) sum.get("nwide")).get(nwide);
        ((GlishArray) sum.get("nspect")).get(nspect);

	Block<Int> narrow, ave, wide;

        if (nspect > 0) {
            if (inp.getString("splwin") == "all") {
                narrow.resize(nspect);
                for(i=0; i < nspect; i++) narrow[i] = i+1;
            } else if (inp.getString("splwin") != "none") {
                narrow = inp.getIntArray("splwin");
//                cout << "narrow=" << narrow << endl;
            }
        }

        if (nwide > 0) {
            if (inp.getString("sbandav") == "all" && nwide > 0) {
                Int nsbav = (nwide > 2) ? nwide : 2;
                wide.resize(nsbav);
                for(i=0; i < nsbav; i++) wide[i] = i+1;
            } else if (inp.getString("sbandav") != "none") {
                wide = inp.getIntArray("sbandav");
            }
        }

        if (nwide > 2) {
            if (inp.getString("winav") == "all" && nwide > 2) {
                wide.resize(nwide);
                for(i=2; i < nwide; i++) wide[i] = i+1;
            } else if (inp.getString("winav") != "none") {
                Block<Int> ave = inp.getIntArray("winav");
                wide.resize(2+ave.nelements());
                for(i=2; i < (Int) wide.nelements(); i++) wide[i] = ave[i-2];
            }
        }

        Vector<Int> wideChans(wide);
        Vector<Int> narrowWins(narrow);
	filler.selectSpectra(wideChans, narrowWins);

        // set the options
	Record opts = filler.getOptions();
//        RecordFieldPtr<Bool>(opts, "nosplit").define(inp.getBool("nosplit"));
        RecordFieldPtr<Bool>(opts, "verbose").define(inp.getBool("verbose"));
        RecordFieldPtr<Bool>(opts, "joinpol").define(inp.getBool("joinpol"));
        RecordFieldPtr<Double>(opts, "scanlim").define(
            inp.getDouble("scanlim")*60);
        RecordFieldPtr<Double>(opts, "obslim").define(
            inp.getDouble("obslim")*3600);
        RecordFieldPtr<Int>(opts, "tilesize").define(inp.getInt("tilesize"));
//        RecordFieldPtr<String>(opts, "histbl").define(inp.getString("histbl"));
        RecordFieldPtr<String>(opts, "wideconv").define(inp.getString("wideconv"));

        filler.setOptions(opts);

        filler.fill(msfile);
    }
    catch (AipsError x) {
        cerr << x.getMesg() << endl;
        return 1;
    } 
  }

  return 0;
}

