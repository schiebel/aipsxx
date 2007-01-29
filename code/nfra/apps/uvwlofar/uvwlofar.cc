//# uvwlofar.cc: This program creates correct uvw for LOFAR datasets
//# Copyright (C) 1998,1999,2000,2001,2002,2003,2007
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
//# $Id: uvwlofar.cc,v 1.3 2007/01/25 11:04:35 wbrouw Exp $

//# Includes
#include <measures/Measures/Muvw.h>
#include <measures/Measures/MBaseline.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MeasFrame.h>
#include <measures/Measures/MeasTable.h>
#include <measures/Measures/MeasConvert.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Quanta/MVBaseline.h>
#include <casa/Quanta/MVuvw.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <ms/MeasurementSets/MSField.h>
#include <ms/MeasurementSets/MSFieldColumns.h>
#include <ms/MeasurementSets/MSAntenna.h>
#include <ms/MeasurementSets/MSAntennaColumns.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/ArrayColumn.h>
#include <tables/Tables/TableRecord.h>
#include <tables/Tables/ExprNode.h>
#include <tables/Tables/ColumnDesc.h>
#include <tables/Tables/ArrColDesc.h>
#include <measures/TableMeasures/ArrayMeasColumn.h>
#include <measures/TableMeasures/TableMeasDesc.h>
#include <measures/TableMeasures/TableMeasValueDesc.h>
#include <measures/TableMeasures/TableMeasRefDesc.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayIO.h>
#include <casa/Arrays/MatrixMath.h>
#include <casa/System/ProgressMeter.h>
#include <casa/Inputs.h>
#include <casa/OS/Path.h>
#include <casa/OS/File.h>
#include <casa/BasicMath/Math.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>
#include <casa/iostream.h>
#include <casa/iomanip.h>


#include <casa/namespace.h>
// Get baseline lengths and antenna mapping.
// For WSRT observations an antenna may be split into 2 id's
// to cope with the double frequency band.
void fillBaseLength (Bool fillpos,
		     const MeasurementSet& ms,
		     Double wsrtLong,
		     Vector<Double>& baseLength,
		     Block<MBaseline>& antbl,
		     Vector<Int>& antMap)
{
    MSAntenna msan(ms.antenna());
    MSAntennaColumns msanc(msan);
    uInt nr = msanc.nrow();
    baseLength.resize (nr);
    baseLength = 0;
    // Get the position of the first telescope.
    MPosition mpos(msanc.positionMeas()(0));
    mpos = MPosition::Convert(mpos, MPosition::ITRF)();
    Vector<Double> firstPos;
    firstPos = mpos.getValue().getValue();
    // Calculate baseline length from first telescope.
    antMap.resize (nr);
    antbl.resize (nr);
    antMap = -1;
    for (uInt j=0; j<nr; j++) {
	Int tel = j;
	mpos = msanc.positionMeas()(j);
	mpos = MPosition::Convert(mpos, MPosition::ITRF)();
	antMap(j) = tel;
	Vector<Double> antpos;
	antpos = mpos.getValue().getValue();
	Vector<Double> newpos = antpos.copy();
	if (tel >= 0) {
	    Vector<Double> pos(antpos-firstPos);
	    baseLength(tel) = norm(pos);
	}
	MVPosition blpos(newpos(0), newpos(1), newpos(2));
	antbl[tel] = MBaseline (MVBaseline(blpos), MBaseline::ITRF);
    }
}

void changeDir (Vector<MDirection>& vdir, Vector<MDirection>& vdirj,
		Table& tab, const String& colName, MeasFrame& frame,
		const ROScalarColumn<Double> &timeCol,
		const ROScalarColumn<String> &nameCol,
		MDirection::Types newType, Bool show, Bool swput)
{
    if (tab.nrow() == 0) {
        return;
    }
    ArrayMeasColumn<MDirection> dirCol (tab, colName);
    ROArrayColumn<Double> dcol (tab, colName);
    Vector<MDirection> dirnew(tab.nrow());
    MDirection::Types oldType;
    MDirection::Ref rinj(newType, frame);
    MDirection::Ref rinb(MDirection::B1950, frame);
    MDirection::Ref rina(MDirection::APP, frame);
    // Loop through all rows.
    // Determine old type when doing the first row.
    Bool first = True;
    for (uInt i=0; i<tab.nrow(); i++) {
      if (dcol.isDefined(i)) {
        Vector<MDirection> dirs = dirCol(i);
	if (first) {
	  first = False;
	  oldType = MDirection::Types(dirs(0).getRef().getType());
	  if (oldType != newType) {
	    cout << "Reference type of column " << colName
		 << " will be changed from "
		 << MDirection::showType (oldType) << " to "
		 << MDirection::showType (newType) << endl;
	  }
	}
	// Get the epoch and put it into the frame.
	Double vep = Quantum<Double>(timeCol(i), "s").get("d").getValue();
	frame.set(MEpoch(MVEpoch(vep), MEpoch::UTC));
	// Convert to  J2000.
	// Note the the column contains vectors of directions.
	// Only the first one is converted. The others are second order terms.
	// The original and J2000 direction are returned.
	MDirection vdira, vdirb;
	vdir(i) = dirs(0);
	vdirb = MDirection::Convert(vdir(i), rinb)();
	MDirection tmpb(vdirb.getValue(), rinb);
	vdirj(i) = MDirection::Convert(tmpb, rinj)();
	MDirection tmpa(MDirection::Convert(tmpb, rina)());
	vdira = MDirection(tmpa.getValue(), rina);
	dirnew(i) = MDirection::Convert(tmpb, rinj)();
	if (show) {
	  if (swput) {
	    cout << nameCol(i) << " at " << 
	      MVTime(vep).string(MVTime::YMD) << " (UTC) " <<
	      vdir(i).getAngle("deg") <<
	      " (" << MDirection::showType (oldType) << ")" << endl;
	    cout << nameCol(i) << " at " << 
	      MVTime(vep).string(MVTime::YMD) << " (UTC) " <<
	      vdirj(i).getAngle("deg") <<
	      " (J2000)" << endl;
	    cout << nameCol(i) << " at " << 
	      MVTime(vep).string(MVTime::YMD) << " (UTC) " <<
	      vdirb.getAngle("deg") <<
	      " (B1950)" << endl;
	  }
	  cout << nameCol(i) << " at " << 
	    MVTime(vep).string(MVTime::YMD) << " (UTC) " <<
	    vdira.getAngle("deg") <<
	    " (APP)" << endl;
	  if (swput) {
	  cout << nameCol(i) << " at " << 
	    MVTime(vep).string(MVTime::YMD) << " (UTC) " <<
	    dirnew(i).getAngle("deg") <<
	    " (requested)" << endl;
	  }
	}
      }
    }
    if (newType != oldType) {
	dirCol.setDescRefCode (newType, False);
	for (uInt i=0; i<tab.nrow(); i++) {
	  if (dcol.isDefined(i)) {
	    Vector<MDirection> dirs = dirCol(i);
	    dirs(0) = dirnew(i);
	    dirCol.put (i, dirs);
	  }
	}
    }
}

void doUVW (MDirection::Types mtp, Muvw::Types utp,
	    Bool fillpos, MeasurementSet& ms)
{
    // Create the column access objects for main table and subtables
    MSColumns msc(ms);
    String arrName;
    {
      MSObservation msobs(ms.observation());
      ROMSObservationColumns msobsc(msobs);
      arrName = msobsc.telescopeName()(0);
    }
    // Always assume for now that LOFAR uses WSRT as centre
    arrName = "WSRT";
    MPosition mpobs;
    AlwaysAssert (MeasTable::Observatory(mpobs, arrName), AipsError);
    cout << "....used:    " << mpobs.getValue().getAngle("deg")
	 << "  " << mpobs.getValue().getLength("m") << endl;
    Double wsrtLong = mpobs.getValue().getAngle("rad").getValue()(0);
    mpobs = MPosition::Convert(mpobs, MPosition::ITRF)();
    cout << "    ITRF:    " << mpobs.getValue().getValue() << endl;
    MeasFrame frame(mpobs);

    MSField msfld(ms.field());
    MSFieldColumns msfldc(msfld);
    Vector<Double> baseLength;
    Vector<Int> antMap;
    Block<MBaseline> antbl;
    fillBaseLength (fillpos, ms, wsrtLong, baseLength, antbl, antMap);
    cout << "Baseline lengths:" << endl;
    for (uInt i=0; i<baseLength.nelements(); i++) {
      cout << i << "\t" << baseLength(i) << endl;
    }
    cout << "Id-Antenna map " << antMap << endl;

    cout << msfld.nrow() << " fields specified: " << endl;
    Vector<MDirection> vdir(msfld.nrow());
    Vector<MDirection> vdirj(msfld.nrow());
    Bool swput = True;
    changeDir (vdir, vdirj, msfld,
	       MSField::columnName(MSField::REFERENCE_DIR),
	       frame, msfldc.time(), msfldc.name(), mtp, False, swput);
    changeDir (vdir, vdirj, msfld,
	       MSField::columnName(MSField::DELAY_DIR),
	       frame, msfldc.time(), msfldc.name(), mtp, False, swput);
    changeDir (vdir, vdirj, msfld,
	       MSField::columnName(MSField::PHASE_DIR),
	       frame, msfldc.time(), msfldc.name(), mtp, True, swput);

    // Convert the pointings.
    {
      MSPointing mspoint(ms.pointing());
      MSPointingColumns mspointc(mspoint);
      cout << mspoint.nrow() << " pointings specified: " << endl;
      Vector<MDirection> vpt(mspoint.nrow());
      Vector<MDirection> vptj(mspoint.nrow());
      changeDir (vpt, vptj, mspoint,
		 MSPointing::columnName(MSPointing::DIRECTION),
		 frame, mspointc.timeOrigin(), mspointc.name(),
		 mtp, False, swput);
      changeDir (vpt, vptj, mspoint,
		 MSPointing::columnName(MSPointing::TARGET),
		 frame, mspointc.timeOrigin(), mspointc.name(),
		 mtp, False, swput);
    }

    // Now convert the UVW.
    Double lastTime = msc.time()(0) - 100;
    Int lastFld = -100;
    Vector<Double> myuvw(3);
    uInt nrrow = ms.nrow();
    cout << endl << "Recalculating UVW ..." << endl;
    ProgressMeter progressMeter (0, nrrow, "", "", "", "");

    // Calculate per time the J2000 UVW and convert to requested type (utp).
    msc.uvw().rwKeywordSet().define("MEASURE_REFERENCE",
				    MDirection::showType (utp));
    // It is calculated per antenna. The uvw of a baseline is the difference.
    Block<Vector<double> > antuvw(antbl.nelements());
    for (uInt j=0; j<nrrow; j++) {
	Double tm = msc.time()(j);
	Int tfld = msc.fieldId()(j);
	if (tm != lastTime  ||  tfld != lastFld) {
	  lastTime = tm;
	  lastFld = tfld;
	  tm = Quantum<Double>(tm, "s").get("d").getValue();
	  frame.set(MEpoch(MVEpoch(tm), MEpoch::UTC));
	  frame.set(vdirj(tfld));
	  // Calculate UVW for each antenna.
	  for (uInt i=0; i<antuvw.nelements(); i++) {
	    antbl[i].getRefPtr()->set(frame);
	    MBaseline::Convert mcvt(antbl[i], MBaseline::J2000);
	    MVBaseline bas = mcvt().getValue();
	    MVuvw jvguvw(bas, vdirj[tfld].getValue());
	    Muvw jguvw(jvguvw, Muvw::J2000);
	    antuvw[i] = Muvw::Convert(jguvw, Muvw::Ref (utp, frame))().
	      getValue().getVector();
	    progressMeter.update (j);
	  }
	}
	Int an1, an2;
	an1 = antMap(msc.antenna1()(j));
	an2 = antMap(msc.antenna2()(j));
	AlwaysAssert (an1>=0 && an2>=0, AipsError);
	myuvw = antuvw[an2] - antuvw[an1];
	msc.uvw().put (j, myuvw);
    }
}

void doData (Bool swapsincos, Float sinfact, Float cosfact,
	     MeasurementSet& ms)
{
    if (!swapsincos && sinfact==1 && cosfact == 1) return;

    MSColumns msc(ms);
    uInt nrrow = ms.nrow();
    cout << endl << "Fixing sin/cos data ..." << endl;
    ProgressMeter progressMeter (0, nrrow, "", "", "", "");

    // Fix the data as needed.
    for (uInt j=0; j<nrrow; j++) {
      Array<Complex> data = msc.data()(j);
      uInt n = data.nelements();
      Bool deleteIt;
      Complex* dataPtr = data.getStorage (deleteIt);
      for (uInt i=0; i<n; i++) {
	if (swapsincos) {
	  dataPtr[i] = Complex(dataPtr[i].imag(), dataPtr[i].real());
	}
	dataPtr[i] = Complex(dataPtr[i].real() * cosfact,
			     dataPtr[i].imag() * sinfact);
      }
      data.putStorage (dataPtr, deleteIt);
      msc.data().put (j, data);
      progressMeter.update (j);
    }
}

void doUnflag (MeasurementSet& ms)
{
  MSColumns msc (ms);
  uInt nrrow = ms.nrow();
  cout << endl << "Unflagging data ..." << endl;
  ProgressMeter progressMeter (0, nrrow, "", "", "", "");
  for (uInt i=0; i<nrrow; i++) {
    msc.flagRow().put (i, False);
    Array<Bool> flags (msc.flag().shape(i));
    flags = False;
    msc.flag().put (i, flags);
    progressMeter.update (i);
  }
}

int main (Int argc, char** argv)
{
    try {
	cout << " " << endl;
	cout << "uvwlofar recalculates UVW coordinates for WSRT" << endl;
	cout << "-----------------------------------------------" << endl;
	
	cout << setprecision(8);

	Vector<String> syscmd(argc);
	for (int i = 0; i < argc; i++){
	  syscmd(i) = argv[i];
	}

	// enable input in no-prompt mode
	Input inputs(1);

	// define the input structure
        String appVersion = "20070125wnb";
	inputs.version(appVersion);
	inputs.create ("msin", "",
		       "Name of input MeasurementSet", "string");
	inputs.create ("in", "",
		       "Name of input MeasurementSet (synonym of msin)",
		       "string");
	inputs.create ("type", "J2000",
		       "Specify output type [J2000]", "string");
	//	inputs.create ("fillpos", "F",
	//       "Fill array and antenna position", "bool");
	inputs.create ("swapsincos", "F",
		       "Swap sin and cos [F]", "bool");
	inputs.create ("sinfactor", "1",
		       "sin factor [1]", "float");
	inputs.create ("cosfactor", "1",
		       "cos factor [1]", "float");
	inputs.create ("timeadd", "0",
		       "seconds to add to the time column [0]", "double");
	//	inputs.create ("unflag", "False",
	//	       "unflag all the data [F]", "bool");
	inputs.create ("force", "False",
		       "force uvwlofar to operate multiple times on MS [F]",
		       "bool");

	// Fill the input structure from the command line.
	inputs.readArguments (argc, argv);

	// get and check the input file specification
	String msin (inputs.getString("msin"));
	if (msin == "") {
	    msin = inputs.getString("in");
	}
	if (msin == "") {
	    throw (AipsError(" The MeasurementSet must be given"));
	}
        Path measurementSet (msin);
	cout << "The input MeasurementSet is: " 
	    << measurementSet.absoluteName() << endl;
	if (!measurementSet.isValid()) {
	    throw (AipsError(" The MeasurementSet path is not valid"));
	}
	if (!File(measurementSet).exists()) {
	    throw (AipsError(" The MeasurementSet file does not exist"));
	}
	if (!File(measurementSet).isWritable()) {
	    throw (AipsError(" The MeasurementSet file is not writable"));
	}

	// Get and check the output type
	String tpout(inputs.getString("type"));
	// Get swap argument and factors.
	Bool fillpos = False; //inputs.getBool("fillpos");
	Bool swapsincos = inputs.getBool("swapsincos");
	Float sinfact = inputs.getDouble("sinfactor");
	Float cosfact = inputs.getDouble("cosfactor");
	Double timeadd = inputs.getDouble("timeadd");
	Bool unflag = False; //inputs.getBool("unflag");
	Bool force = inputs.getBool("force");

	MDirection::Types mtp;
	Muvw::Types utp;
	if (!MDirection::getType(mtp, tpout)
	||  !Muvw::getType(utp, tpout)) {
	    throw (AipsError (tpout + " is an invalid output type"));
	}
	
	cout.precision(12);
	cout << "Selected output type: " << MDirection::showType(mtp) << endl;
	//cout << "Array and antenna positions will ";
	//if (! fillpos) cout << "not ";
	//cout << "be filled" << endl;
	cout << "Sin and cos will ";
	if (! swapsincos) cout << "not ";
	cout << "be swapped" << endl;
	cout << "Sin factor: " << sinfact << endl;
	cout << "Cos factor: " << cosfact << endl;
	cout << "Add " << timeadd << " seconds to the TIME column" << endl;
	//cout << "Data will ";
	//if (! unflag) cout << "not ";
	//cout << "be unflagged" << endl;
	cout << endl;
	
	MeasurementSet ms(msin, Table::Update);

        Table histTbl = ms.keywordSet().asTable("HISTORY");
        Table sel = histTbl(histTbl.col("APPLICATION") == "uvwlofar");
        if (sel.nrow() != 0){
	  cout << " The MeasurementSet is already processed using uvwlofar.\n";
          if (!force){
	    throw (AipsError(" Try uvwlofar .... force=T"));
	  }
	}

	doUVW (mtp, utp, fillpos, ms);
       	doData (swapsincos, sinfact, cosfact, ms);
	if (timeadd != 0) {
	  cout << endl << "Adding " << timeadd << " seconds to TIME ..."
	       << endl;
	  MSColumns msc (ms);
	  msc.time().putColumn (msc.time().getColumn() + timeadd);
	}
	if (unflag) doUnflag (ms);

	MSHistoryColumns histc (ms.history());
        ms.history().addRow();
        int rownr = ms.history().nrow()-1;
        histc.origin().put(rownr, getenv("USER"));
        String msg = "Executed uvwlofar, version=" + appVersion;
        histc.message().put(rownr, msg);
        Quantity t0;
	MVTime::read(t0, "today");
	Double t00 = t0.getValue("s");
        histc.time().put(rownr, t00);
	histc.application().put(rownr, "uvwlofar");
	histc.cliCommand().put(rownr, syscmd);
        ms.history().flush(True);

    } catch (AipsError x) {
	cout << x.getMesg() << endl;
	exit(1);
    } 

    cout << "uvwlofar normally ended" << endl;
    exit(0);
}
