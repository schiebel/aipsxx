///////////////////////////////////////////////////////////////////////////////
//
//  MSWriter is a class to write uv-data into AIPS++ MeasurementSet file
//  Most of the code which performs real writting of the AIPS++ MeasurementSet
//  file was written using MSSimulator.cc and MSFitsInput.cc (parts of the
//  AIPS++)  as examples.
//

//# Copyright (C) 1999,2000
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
//# $Id: MSWriter.cc,v 1.3 2005/09/19 04:19:10 mvoronko Exp $


#include "MSWriter.h"

// AIPS++ stuff
#include <casa/aips.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/MatrixMath.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayUtil.h>
#include <casa/Arrays/Cube.h>
#include <casa/Containers/Block.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSHistoryColumns.h>
#include <ms/MeasurementSets/MSObsColumns.h>
#include <ms/MeasurementSets/MSFieldColumns.h>
#include <ms/MeasurementSets/MSPointingColumns.h>
#include <ms/MeasurementSets/MSFeedColumns.h>
#include <ms/MeasurementSets/MSDataDescColumns.h>
#include <ms/MeasurementSets/MSPolColumns.h>
#include <ms/MeasurementSets/MSSpWindowColumns.h>

#include <casa/BasicSL/String.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MDirection.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/StandardStMan.h>
#include <tables/Tables/IncrementalStMan.h>
#include <tables/Tables/TiledShapeStMan.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/TableInfo.h>
#include <tables/Tables/TableLock.h>

#include <casa/Quanta/MVTime.h>

#include <casa/BasicSL/Constants.h>
#include <casa/BasicMath/Math.h>
#include <casa/BasicSL/Complex.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <casa/Utilities/Regex.h>
#include <ms/MeasurementSets/MSTileLayout.h>
#include <casa/Exceptions/Error.h>
#include <casa/Utilities/Assert.h>

using namespace casa;

// IMSOperations
// Dummy destructor, to execute actual one correctly from the derived
// classes
IMSOperations::~IMSOperations() throw() {}

//
// definition of the class, which do the job. Do it here to prevent
// AIPS++ definitions to spread over all source code making everything
// depending on everything
//

class MSOperations : public IMSOperations
{
  static const casa::uInt nCorr=2; // two polarizations. By now it is fixed
  static const casa::uInt nField=1; // Mosaicing is not yet supported
  static const casa::uInt nSpW=1; // Only one IF is now possible
  casa::uInt nChan;  // number of spectral channels

  casa::Quantity startfreq; //start frequency
  casa::Quantity chanwidth; // channel width  
public:
   // inChan - number of spectral channels
   MSOperations(casa::uInt inChan,const casa::Quantity &istartfreq,
                const casa::Quantity &ichanwidth) throw(casa::AipsError);

   // return data shape parameters
   casa::uInt getNCorr() const throw() {return nCorr;}
   casa::uInt getNField() const throw() {return nField;}
   casa::uInt getNSpW() const throw() {return nSpW;}
   casa::uInt getNChan() const throw() {return nChan;} 
  
   // set up the Measurement Set initially
   virtual void setupMeasurementSet(const casa::String &filename) throw(casa::AipsError);

   // fill the Observation and ObsLog tables
   virtual void fillObsTables() throw(casa::AipsError);
   // fill the main table. Now supports only one pointing & one IF
   virtual void fillMSMainTable() throw(casa::AipsError);
   // fill the spectral window table. Now supports only one FQ
   virtual void fillSpectralWindowTable() throw(casa::AipsError);
   // fill field table. Now supports only single source case
   virtual void fillFieldTable(const casa::MDirection &obsfield) throw(casa::AipsError);
   // fill the antenna table
   virtual void fillAntennaTable(const casa::Vector<casa::MPosition> &layout,
           const casa::Vector<casa::Quantity> &diam) throw(casa::AipsError);

   // fill the feed table. The observation and antenna tables should be
   // filled in first
   virtual void fillFeedTable() throw(casa::AipsError);
   // fill the Pointing table. Assume pointings to be the same as
   // phase centre for all antennas. The Field and Antenna Tables
   // should be filled in.
   virtual void fillPointingTable() throw(casa::AipsError);
   
   // write visibility
   void writevis(const casa::Vector<casa::Double> &uvw, casa::uInt ant1, casa::uInt ant2,
              const casa::MVEpoch &utctime, const casa::Matrix<casa::Complex> &vis) throw(casa::AipsError);

   // Close some temporary stuff.
   virtual ~MSOperations() throw();
private:
   casa::MeasurementSet ms;
   casa::MSColumns *msc_p;
   casa::Int row; // current row in MS (number of current visibility)
   casa::Double previous_time; // value for the time for a previous time slot
                         // needed to calculate the interval and exposure
			 // and to avoid writing a time for the same time
			 // visibility (from other baselines)
   casa::Double lastwrite_time; // the same for the last writevis call
                          // lastwrite_time!=previous_time if we have a
			  // number of baselines
   bool dofix;           // if true, we will fill interval and exposure for
                         // all rows before the current as soon as the time
			 // will change
   // additional stuff which is not changed after construction
   casa::Vector<casa::Float> sigma; // sigmas per correlation product
   casa::Matrix<casa::Float> weightSpec; // weights per correlation product and channel
   casa::Vector<casa::Float> weight; // total weights per correlation product
   casa::Cube<casa::Bool> flagCat;  // flag categories per product, channel and category
   casa::Matrix<casa::Bool> flag;   // slice of the first plane   
};

// MSOperations

MSOperations::MSOperations(casa::uInt inChan,const casa::Quantity &istartfreq,
            const casa::Quantity &ichanwidth) throw(casa::AipsError) :
	       nChan(inChan), startfreq(istartfreq),
       chanwidth(ichanwidth), msc_p(0), row(-1),
       previous_time(0.), lastwrite_time(0.), dofix(true),
       sigma(nCorr), weightSpec(nCorr,inChan),
       weight(nCorr), flagCat(nCorr,inChan,3,False),
       flag(flagCat.xyPlane(0))
{
  weight=Double(nChan); // each visibility has the weight 1.0, number of
                        // visibilities per polarization is nChan
  weightSpec=1.;
  flag=False;           // all data are unflagged
  sigma=sqrt(1./Double(nChan)); // sigma is an inverted weight
  startfreq.convert("Hz"); // to speed up following calculations
  chanwidth.convert("Hz");
}

// Close some temporary stuff.
MSOperations::~MSOperations() throw()
{
 if (msc_p) delete msc_p;
}

// set up the Measurement Set initially. nChan - number of frequency channels
void MSOperations::setupMeasurementSet(const casa::String &filename) throw(casa::AipsError)
{
  
  // Make the MS table
  casa::TableDesc td=MS::requiredTableDesc(); 

  // Variable shape column to make it possible to add data of different
  // shapes (using the same commands as in MSFitsInput & MSSimulator)
  MS::addColumnToDesc(td,MS::DATA,2);

  // Optional column, add it because we can generete a weight
  // Now, will store unit weight for all visibilities
  MS::addColumnToDesc(td,MS::WEIGHT_SPECTRUM,2);

  // use Tiled Storage Manager. Probably this step can be optional
  td.defineHypercolumn("TiledData",3,
                stringToVector(MS::columnName(MS::DATA)));
  td.defineHypercolumn("TiledFlag",3,
                stringToVector(MS::columnName(MS::FLAG)));
  td.defineHypercolumn("TiledFlagCategory",4,
                stringToVector(MS::columnName(MS::FLAG_CATEGORY)));
  td.defineHypercolumn("TiledWgtSpectrum",3,
                stringToVector(MS::columnName(MS::WEIGHT_SPECTRUM)));
  td.defineHypercolumn("TiledUVW",2,
                stringToVector(MS::columnName(MS::UVW)));
  td.defineHypercolumn("TiledWgt",2,
                stringToVector(MS::columnName(MS::WEIGHT)));
  td.defineHypercolumn("TiledSigma",2,
                stringToVector(MS::columnName(MS::SIGMA)));
    		
  // create a new table
  casa::SetupNewTable newtab(filename,td,Table::New);

  // Incremental Storage Manager will be a default one
  casa::IncrementalStMan incrStMan("ISMData");
  newtab.bindAll(incrStMan,True);

  // According to  MSFitsInput.cc and MSSimulator.cc
  // Bind ANTENNA1, ANTENNA2, DATA_DESC_ID to the standardStMan
  // as they may change sufficiently frequently to make the
  // incremental storage manager inefficient for these columns.
  casa::StandardStMan aipsStMan(32768);
  newtab.bindColumn(MS::columnName(MS::ANTENNA1), aipsStMan);
  newtab.bindColumn(MS::columnName(MS::ANTENNA2), aipsStMan);
  newtab.bindColumn(MS::columnName(MS::DATA_DESC_ID), aipsStMan);

  // use Tiled Storage Manager. Probably this step can be optional
  // choose an appropriate tileshape
  casa::IPosition dataShape(2,nCorr,nChan);
  casa::IPosition tileShape=MSTileLayout::tileShape(dataShape,
                      MSTileLayout::Standard,"SKA");
  casa::TiledShapeStMan tiledStMan1("TiledData",tileShape);
  casa::TiledShapeStMan tiledStMan1f("TiledFlag",tileShape);
  casa::TiledShapeStMan tiledStMan1fc("TiledFlagCategory",
                                IPosition(4,tileShape(0),tileShape(1),
				2,tileShape(2)));
  casa::TiledShapeStMan tiledStMan2("TiledWgtSpectrum",tileShape);
  casa::TiledShapeStMan tiledStMan3("TiledUVW",IPosition(2,3,1024));
  casa::TiledShapeStMan tiledStMan4("TiledWgt",IPosition(2,tileShape(0),
                               tileShape(2)));
  casa::TiledShapeStMan tiledStMan5("TiledSigma",IPosition(2,tileShape(0),
                               tileShape(2)));
  // Bind this stuff to the tiled storage manager
  newtab.bindColumn(MS::columnName(MS::DATA),tiledStMan1);
  newtab.bindColumn(MS::columnName(MS::FLAG),tiledStMan1f);
  newtab.bindColumn(MS::columnName(MS::FLAG_CATEGORY),tiledStMan1fc);
  newtab.bindColumn(MS::columnName(MS::WEIGHT_SPECTRUM),tiledStMan2);
  newtab.bindColumn(MS::columnName(MS::UVW),tiledStMan3);
  newtab.bindColumn(MS::columnName(MS::WEIGHT),tiledStMan4);
  newtab.bindColumn(MS::columnName(MS::SIGMA),tiledStMan5); 

  // locking the table permanently
  casa::TableLock lock(TableLock::PermanentLocking);
  ms=MeasurementSet(newtab,lock); // measurement set to work with

  // setup subtables making new tables which contain 0 rows
  Table::TableOption option=Table::New;
  ms.createDefaultSubtables(option);

/*
  // add optional Source subtable
  casa::TableDesc sourceTD=MSSource::requiredTableDesc();
  MSSource::addColumnToDesc(sourceTD, MSSource::REST_FREQUENCY);
  MSSource::addColumnToDesc(sourceTD, MSSource::SYSVEL);
  MSSource::addColumnToDesc(sourceTD, MSSource::TRANSITION);
  casa::SetupNewTable sourceSetup(ms.sourceTableName(),sourceTD,option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::SOURCE),
                                Table(sourceSetup,0));
*/

  // update the references to the subtable keywords
  ms.initRefs();

  { // set the TableInfo
    casa::TableInfo& info(ms.tableInfo());
    info.setType(TableInfo::type(TableInfo::MEASUREMENTSET));
    info.setSubType(String("UVFITS"));
    info.readmeAddLine("Generated by the SKA simulator (Maxim.Voronkov@csiro.au)");
  }
  msc_p=new MSColumns(ms);
}

// fill antenna table
void MSOperations::fillAntennaTable(const casa::Vector<casa::MPosition> &layout,
                                    const casa::Vector<casa::Quantity> &diam) throw(casa::AipsError)
{
  DebugAssert(layout.nelements(), casa::AipsError);
  DebugAssert(diam.nelements(), casa::AipsError);
  DebugAssert(layout.nelements()==diam.nelements(), casa::AipsError);
    
  ms.antenna().rwKeywordSet().define(String("RDATE"),String("2003-04-30T02:16:06.878995"));
  ms.antenna().rwKeywordSet().define(String("GSTIA0"),2.175293451574e2);
  ms.antenna().rwKeywordSet().define(String("DEGPDY"),3.609856473692e2);
  ms.antenna().rwKeywordSet().define(String("TIMSYS"),String("UTC"));

  casa::MSAntennaColumns& ant(msc_p->antenna());
  ant.setPositionRef(MPosition::Types(layout[0].getRef().getType()));
  casa::Int row=ms.antenna().nrow()-1; // row has different sense in this function
                                 // it is a row in the antenna table
  for (casa::uInt i=0;i<layout.nelements();++i) {
       // for each antenna
       ms.antenna().addRow(); row++;
       ant.dishDiameterQuant().put(row,diam[i]); 
       ant.flagRow().put(row,False);
       ant.mount().put(row,String("ALT-AZ"));
       ant.name().put(row,String::toString(0));
       casa::Vector<casa::Double> offsets(3); offsets=0;
       ant.offset().put(row,offsets);
       ant.station().put(row,String("SKA")+String::toString(i));
       ant.type().put(row,"GROUND-BASED");
       ant.positionMeas().put(row,layout[i]);       
  }
  casa::Vector<casa::Double> antxyz(3); antxyz=0;
  ant.name().rwKeywordSet().define("ARRAY_NAME",String("SKA"));
  ant.name().rwKeywordSet().define("ARRAY_POSITION",antxyz);
}

// fill the Observation and ObsLog tables
void MSOperations::fillObsTables() throw(casa::AipsError)
{
  ms.observation().addRow();
  casa::MSObservationColumns msObsCol(ms.observation());
  msObsCol.observer().put(0,"User S.K.A.");
  msObsCol.telescopeName().put(0,"SKA");
  msObsCol.scheduleType().put(0,"");
  msObsCol.project().put(0,"");
  // use dummy date 2003-04-30T02:16:06.878995
  casa::MVTime timeVal(3,4,30.+(2.+16./60.+6.878995/3600.)/24.);
  casa::Vector<casa::Double> times(2);
  times(0)=timeVal.second();
  times(1)=timeVal.second();
  msObsCol.timeRange().put(0,times);
  msObsCol.releaseDate().put(0,times(0));
  msObsCol.flagRow().put(0,False);

  // working with history
  casa::MSHistoryColumns msHisCol(ms.history());
  ms.history().addRow();
  msHisCol.observationId().put(0,0);
  msHisCol.time().put(0,times(0));
  msHisCol.priority().put(0,"NORMAL");
  msHisCol.origin().put(0,"M.A.Voronkov, SKA simulator");
  msHisCol.application().put(0,"ms");
  msHisCol.message().put(0,"SKA measurement set has been simulated");
}

// fill the feed table. The observation and antenna tables should be
// filled in first
void MSOperations::fillFeedTable() throw(casa::AipsError)
{
   casa::MSFeedColumns& msfc(msc_p->feed());
   // dummy polarization -> receptor type
   casa::Vector<casa::String> rec_type(2);
   rec_type(0)="R"; rec_type(1)="L";
   
   // pol. response matrix is a unit matrix
   casa::Matrix<casa::Complex> polResponse(2,2);
   polResponse=0.; polResponse(0,0)=polResponse(1,1)=1.;
   // offset & position are zeros
   casa::Matrix<casa::Double> offset(2,2); offset=0.;
   casa::Vector<casa::Double> position(3); position=0.;
   
   // get time range from the observation table
   const casa::Vector<casa::Double> obsTimes = msc_p->observation().timeRange()(0);
   // number of antennas
   casa::Int nAnt=msc_p->antenna().nrow();
   
   
   // actual fill of the feed table
   for (casa::Int ant=0;ant<nAnt; ++ant) {
        ms.feed().addRow();
        msfc.antennaId().put(ant,ant); // first parameter(row number) is ant
        msfc.beamId().put(ant,-1);
        msfc.feedId().put(ant,0);
        msfc.interval().put(ant,0);
        msfc.spectralWindowId().put(ant,-1); // all
        msfc.time().put(ant,obsTimes(0));
        msfc.numReceptors().put(ant,2);
        msfc.beamOffset().put(ant,offset);
        msfc.polarizationType().put(ant,rec_type);
        msfc.polResponse().put(ant,polResponse);
        msfc.position().put(ant,position);
        
        // dummy receptor angles
        casa::Vector<casa::Double> receptorAngle(2);
        receptorAngle=0; // 0 degrees for all receptors (2 per antenna)       
        msfc.receptorAngle().put(ant,receptorAngle);
   }  
}
   

// fill the main table. Now supports only one pointing & one IF
void MSOperations::fillMSMainTable() throw(casa::AipsError)
{
// only first part of the original code from MSFitsInput is retained
// the writting of actual visibilities, etc is migrated to writevis
 casa::Vector<casa::String> cat(3); // three initial categories
 cat(0)="FLAG_CMD";
 cat(1)="ORIGINAL";
 cat(2)="USER";
 msc_p->flagCategory().rwKeywordSet().define("CATEGORY",cat);
}

// fill the spectral window table. Now supports only one FQ
void MSOperations::fillSpectralWindowTable() throw(casa::AipsError)
{
  if (nCorr!=2) {
      cerr<<"Only LL+RR is supported"<<endl;
      throw -1; //something unpredictable
  }
  casa::MSSpWindowColumns& msSpW(msc_p->spectralWindow());
  casa::MSDataDescColumns& msDD(msc_p->dataDescription());
  casa::MSPolarizationColumns& msPol(msc_p->polarization());
 
  // fill out the polarization info
  ms.polarization().addRow();
  msPol.numCorr().put(0,nCorr);
  casa::Vector<casa::Int> corrType(2); // specify explicitly the type of correlation product
  corrType(0)=Stokes::LL;
  corrType(1)=Stokes::RR;
  msPol.corrType().put(0,corrType);
  
  casa::Matrix<casa::Int> corrProduct(2,nCorr);  
  corrProduct(0,0)=Stokes::receptor1(Stokes::type(corrType(0)));
  corrProduct(0,1)=Stokes::receptor1(Stokes::type(corrType(1)));
  corrProduct(1,0)=Stokes::receptor2(Stokes::type(corrType(0)));
  corrProduct(1,1)=Stokes::receptor2(Stokes::type(corrType(1)));
  
  msPol.corrProduct().put(0,corrProduct);
  msPol.flagRow().put(0,False);

  ms.spectralWindow().addRow();
  ms.dataDescription().addRow();

  msDD.spectralWindowId().put(0,0);
  msDD.polarizationId().put(0,0);
  msDD.flagRow().put(0,False); 

  msSpW.name().put(0,"none");
  msSpW.ifConvChain().put(0,0);
  msSpW.numChan().put(0,nChan);
  
  casa::Vector<casa::Quantity> chanFreq(nChan),resolution(nChan);
  for (casa::uInt i=0;i<nChan;++i) {
    chanFreq(i)=chanwidth;
    chanFreq(i)*=Double(i)+0.5;
    chanFreq(i)+=startfreq;
  }
  
  resolution=chanwidth;
  
  msSpW.chanFreqQuant().put(0,chanFreq);
  msSpW.chanWidthQuant().put(0,resolution);
  msSpW.effectiveBWQuant().put(0,resolution);
  msSpW.refFrequencyQuant().put(0,startfreq);
  msSpW.resolutionQuant().put(0,resolution);
  msSpW.totalBandwidthQuant().put(0,Quantity(nChan*chanwidth.getValue(),
                               chanwidth.getUnit()));
  msSpW.netSideband().put(0,1);
  msSpW.freqGroup().put(0,0);
  msSpW.freqGroupName().put(0,"none");
  msSpW.flagRow().put(0,False);
  // set the reference frames for frequency
  msSpW.measFreqRef().put(0,MFrequency::TOPO);
}

// fill field table. Now supports only single source case
void MSOperations::fillFieldTable(const casa::MDirection &obsfield) throw(casa::AipsError)
{
  // single source case for single pointing
  //MDirection::Types epochRef=MDirection::J2000; // treat positions as J2000. ones
  //msc_p->setDirectionRef(epochRef);

  casa::MSFieldColumns& msField(msc_p->field());
  ms.field().addRow();
  msField.sourceId().put(0,-1); // source table is not used
  msField.code().put(0," ");
  msField.name().put(0,"test");

  casa::Vector<casa::MDirection> radecMeas(1); // no mosaicing "Field" in AIPS++ means "source"
  radecMeas=obsfield; // setup the only pointing
    
  msField.numPoly().put(0,0);
  msField.delayDirMeasCol().put(0,radecMeas);
  msField.phaseDirMeasCol().put(0,radecMeas);
  msField.referenceDirMeasCol().put(0,radecMeas);

  // copy time from ObsTable
  const casa::Vector<casa::Double> obsTimes = msc_p->observation().timeRange()(0);
  msField.time().put(0,obsTimes(0));
}

// fill the Pointing table. Assume pointings to be the same as
// phase centre for all antennas. The Field and Antenna Tables
// should be filled in.
void MSOperations::fillPointingTable() throw(casa::AipsError)
{
  casa::MSPointingColumns& msPointing(msc_p->pointing());
  casa::Int nAnt=msc_p->antenna().nrow();
  casa::Int nrow=msc_p->nrow();

  casa::Double firsttime=0;
  if (nrow) firsttime=msc_p->time()(0);
  casa::Double lasttime=firsttime;
  // if there are already some data in the measurement set
  // time & interval will contain actual values  
  for (casa::Int i=1;i<nrow;++i) {
       casa::Double time=msc_p->time()(i);
       if (time>lasttime) lasttime=time;
       if (time<firsttime) firsttime=time;
  }
  casa::Int fieldId=msc_p->fieldId().getColumn()(0); // FieldId should exist for 0 row
  // fill pointing data for all antennae
  casa::Array<casa::Double> pointingDir=msc_p->field().phaseDir()(fieldId); 
  
  for (casa::Int i=0;i<nAnt;++i) {
       ms.pointing().addRow();
       msPointing.antennaId().put(i,i);
       msPointing.time().put(i,firsttime);
       msPointing.timeOrigin().put(i,firsttime);
       casa::Double interval=lasttime-firsttime;
       if (interval<1e-7) interval=10; // 10s - default scan duration
       msPointing.interval().put(i,interval);
       msPointing.name().put(i,msc_p->field().name()(fieldId));
       msPointing.numPoly().put(i,msc_p->field().numPoly()(fieldId)); 
       msPointing.direction().put(i,pointingDir);
       msPointing.target().put(i,pointingDir);
       msPointing.tracking().put(i,True);
  }  
}

// this function adds one more visibility row to the measurement set
// Here time is in radians
void MSOperations::writevis(const casa::Vector<casa::Double> &uvw, casa::uInt ant1, casa::uInt ant2,
              const casa::MVEpoch &utctime, const casa::Matrix<casa::Complex> &vis) throw(casa::AipsError)
{ 
   // add a new row to the measurement set
   ms.addRow();
   row++;

   // fill in values for all the unused columns
   if (row==0) {
       msc_p->feed1().put(row,0);
       msc_p->feed2().put(row,0);
       msc_p->flagRow().put(row,False);
       msc_p->processorId().put(row,-1);
       msc_p->observationId().put(row,0);
       msc_p->stateId().put(row,-1);

       // additional stuff from other parts of the code but related to
       // the first data row
       msc_p->scanNumber().put(row,1);
       msc_p->arrayId().put(row,1);
       msc_p->fieldId().put(row,0); // FieldId is always 0
   }
   
   // weight and flag buffers code is moved to constructor as it is
   // not changed. All faked data have the same weight and are unflagged
   /*
   casa::Double ctime=time/2./M_PI+52755.; // in AIPS++ time is in seconds from JD=2400000.5;
                             // adding some dummy date to the time which is
			     // GST in seconds (should be UT, but it does not
			     // matter at now). Should be fixed in future if
			     // the real simulator is a goal
   */
   casa::Double ctime=utctime.get(); // time in days
   ctime*=C::day; // in seconds;
   casa::Double interval=ctime-previous_time; // to fill interval & exposure

   if (dofix) interval=0.; // dummy value for the first time slots
   msc_p->interval().put(row,interval);
   msc_p->exposure().put(row,interval); // exposure=interval
                                        // we're not considering the
  			                // case with pulsar gating

   // it is bad to compare floats but here it should work because we
   // compare it with an assignment we've made before
   if (lastwrite_time!=ctime)  {
        previous_time=lastwrite_time; // for future time slots
	
       // lastwrite_time=ctime; will be done later when actual time will
       // be written

       // there was no interval & exposure for a first time slot,
       // fix it now
       if (dofix && row) {
           dofix=false; // fixing previous rows is no longer needed
	                // one time is enough
	   interval=ctime-previous_time; // need to recompute, as previous_time
	                                 // has been changed
	   for (casa::Int i=0;i<=row;++i) {
                msc_p->interval().put(i,interval); // fix for row=0
                msc_p->exposure().put(i,interval); // exposure=interval
                                                   // we're not considering the
		                                   // case with pulsar gating
           }
       }
   }
   msc_p->data().put(row,vis);  // write visibilities
   msc_p->weight().put(row,weight);
   msc_p->sigma().put(row,sigma);
   msc_p->weightSpectrum().put(row,weightSpec);
   msc_p->flag().put(row,flag);
   msc_p->flagCategory().put(row,flagCat);
   // flagRow is always false, we do not need to change it here
   msc_p->antenna1().put(row,ant1);
   msc_p->antenna2().put(row,ant2);
   if (ctime!=lastwrite_time) {
       lastwrite_time=ctime;
       msc_p->time().put(row,ctime);
       msc_p->timeCentroid().put(row,ctime);
   }
   msc_p->uvw().put(row,uvw);
   msc_p->dataDescId().put(row,0); // Spectral Window is always 0    
}


// MSWriter

void MSWriter::writeANtable(const casa::Vector<casa::MPosition> &layout,
               const casa::Vector<casa::Quantity> &diam)
               const throw(casa::AipsError)
{
   MSOperations *msop_p=dynamic_cast<MSOperations*>(msop);
   DebugAssert(msop_p!=NULL, casa::AipsError); // otherwise it's a strange case
   
   msop_p->fillAntennaTable(layout,diam);
   // fill the feed table, observation table should already be filled in
   msop_p->fillFeedTable();
   // fill the Pointing table. Assume pointings to be the same as
   // phase centre for all antennas. The Field and Antenna Tables
   // should be filled in.
   msop_p->fillPointingTable();
}

void MSWriter::writevis(const casa::Vector<casa::Double> &uvw, casa::uInt ant1, casa::uInt ant2,
              const casa::MVEpoch &utctime, const casa::Matrix<casa::Complex> &vis)
	             throw(casa::AipsError)
{
  MSOperations *msop_p=dynamic_cast<MSOperations*>(msop);
  DebugAssert(msop_p, casa::AipsError); // strange case if it is not true
  if (vis.nrow()!=msop_p->getNCorr())
      throw AipsError("Number of polarizations is different in writevis");
  if (vis.ncolumn()!=msop_p->getNChan())
      throw AipsError("Number of channels is different in writevis");

  msop_p->writevis(uvw,ant1,ant2,utctime,vis);  
}

// ra, dec in radians; istartfreq, ichanwidth in Hz
MSWriter::MSWriter(const casa::String &fname, const casa::MDirection &field,
    const casa::Quantity &istartfreq,
    casa::uInt infreqchan, const casa::Quantity &ichanwidth)  throw(casa::AipsError) :
          msop(NULL)
{
  try {
      msop=new MSOperations(infreqchan,istartfreq,ichanwidth);
      msop->setupMeasurementSet(fname);
      msop->fillObsTables(); // should be before fillFieldTable
      msop->fillMSMainTable();
      msop->fillFieldTable(field); // write pointing information
      msop->fillSpectralWindowTable();  
  }
  catch (const std::bad_alloc &ba) {
      throw AipsError("The new operator has failed");
  } 
}

MSWriter::~MSWriter() throw()
{
  // Release the MSOperations object
  if (msop) delete msop;
}

// some data shape parameters for the vis matrix used in writevis
uInt MSWriter::getNCorr() const throw(casa::AipsError)
{
  MSOperations *msop_p=dynamic_cast<MSOperations*>(msop);
  DebugAssert(msop_p, casa::AipsError); // strange case if it is not true
  return msop_p->getNCorr();
}

uInt MSWriter::getNChan() const throw(casa::AipsError)
{
  MSOperations *msop_p=dynamic_cast<MSOperations*>(msop);
  DebugAssert(msop_p, casa::AipsError); // strange case if it is not true
  return msop_p->getNChan();
}
