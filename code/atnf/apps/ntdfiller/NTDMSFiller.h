// NTDMSFiller.h: implementation of a MeasurementSet's filler
//
//  Copyright (C) 2005, 2006
//# Associated Universities, Inc. Washington DC, USA.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
//
//
//////////////////////////////////////////////////////////////////////
#if !defined(ATNF_NTDMSFILLER_H)
#define ATNF_NTDMSFILLER_H
//# Includes

#include <casa/aips.h>
#include <casa/Utilities/Assert.h>
#include <tables/Tables.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSAntennaColumns.h>
#include <ms/MeasurementSets/MSDataDescColumns.h>
#include <ms/MeasurementSets/MSFeedColumns.h>
#include <ms/MeasurementSets/MSFieldColumns.h>
#include <ms/MeasurementSets/MSFlagCmdColumns.h>
#include <ms/MeasurementSets/MSHistoryColumns.h>
#include <ms/MeasurementSets/MSMainColumns.h>

#include <ms/MeasurementSets/MSObsColumns.h>
#include <ms/MeasurementSets/MSPointingColumns.h>
#include <ms/MeasurementSets/MSPolColumns.h>
#include <ms/MeasurementSets/MSProcessorColumns.h>
#include <ms/MeasurementSets/MSSourceColumns.h>
#include <ms/MeasurementSets/MSStateColumns.h>
#include <ms/MeasurementSets/MSSpWindowColumns.h>

#include <ms/MeasurementSets/MSWeatherColumns.h>

#include <tables/Tables/StandardStMan.h>
#include <tables/Tables/TiledShapeStMan.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/TableRecord.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayUtil.h>
#include <casa/Containers/Block.h>
#include <casa/Containers/OrderedMap.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MBaseline.h>
#include <measures/Measures/Muvw.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MeasTable.h>
#include <measures/Measures/Stokes.h>
#include <measures/Measures/MeasConvert.h>
#include <casa/BasicSL/Constants.h>
#include <casa/OS/File.h>
#include <casa/OS/Path.h>
#include <casa/OS/Time.h> 
#include <complex>

#include <vector>

#include "NTDDataSource.h"
#include "NTDCoordinates.h"

using namespace casa;
using namespace std;

//# Forward Declarations

class TimeRange;
class MeasFrame;
class MeasurementSet;
class MSMainColumns;

// Class NTDMSFiller
class NTDMSFiller
{
 public:
  // Construct the MS with a given name
  
  NTDMSFiller (const String& name_, const String& observername_,
	       const String& projectCode_, const Bool stopFringes_);
  
  // Destructor
  ~NTDMSFiller();

  Bool fill(NTDDataSource& ds);

private:
  int  addDataDescription(int spectral_window_id_,
			  int polarizarion_id_);

  int  exists(char *path);
  String msPath();

  void addFeed(Int spectral_window_id_);
  
  uInt addField(const String name_,
		const String code_,
		MEpoch time_,
		MDirection dir_);

  void addFlagCmd(double    time_,
		  double    interval_,
		  const char     *type_,
		  const char     *reason_,
		  int       level_,
		  int       severity_,
		  int       applied_,
		  const char     *command_);

  void addHistory( double time_,
		   int    observation_id_,
		   const char  *message_,
		   const char  *priority_,
		   const char  *origin_,
		   int    object_id_,
		   const char  *application_,
		   const char  *cli_command_,
		   const char  *app_parms_ );

  void addObservation(double startTime,
		      const char  *observer,
		      const char  *log,
		      const char  *schedule_type,
		      const char  *schedule,
		      const char  *project,
		      double release_date);

  void addPointing(int     antenna_id_,
		   double  time_,
		   double  interval_,
		   const char   *name_,
		   double  direction_[2],
		   double  target_[2],
		   double  pointing_offset_[2],
		   double  encoder_[2],
		   int     tracking_);

  int  addPolarization(int num_corr_,
		       int corr_type_[],
		       int corr_product_[]);

  void addSource(int    source_id_,
		 double time_,
		 double interval_,
		 int    spectral_window_id_,
		 int    num_lines_,
		 const char  *name_,
		 int    calibration_group_,
		 const char  *code_,
		 double direction_[2],
		 double position_[2],
		 double proper_motion_[2],
		 const char  *transition_[],
		 double rest_frequency_[],
		 double sysvel_[]);
		 

  Int addSpectralWindow(const String& name, const Vector<Double>& freq);

int  addUniqueState(Bool sig_,
		    Bool ref_,
		    double cal_,
		    double load_,
		    int sub_scan_,
		    const char* obs_mode_,
		    Bool flag_row_);


  void addState(Bool   sig_,
		Bool   ref_,
		double cal_,
		double load_,
		int    sub_scan_,
		const char   *obs_mode_);

  void addWeather(int    antennaId_,
		  double time_,
		  double interval_,
		  float  h2o_,
		  float  rms_h2o_,
		  float  rms_h2o_flag_,
		  float  pressure_,
		  float  rel_humidity_,
		  float  temperature_,
		  float  dew_point_,
		  float  wind_direction_,
		  float  wind_speed_);

  // Take out the known fringe rotation
  Bool stopFringes(const Muvw& muvw,
		   const Vector<Double>& freq,
		   Matrix<Complex>& data);

  void end(double time_);

  const String itsName;
  const String itsObserverName;
  const String itsProjectCode;
  const String itsFillerVersion;
  uInt            itsNumAntenna;
  uInt            itsNumChan;
  uInt            itsNumCorr;
  Int            itsFieldID;
  Int            itsSpWinID;
  Int            itsDDID;
  Int            itsPolID;
  casa::MeasurementSet *itsMS;
  casa::MSMainColumns  *itsMSCol;

  String     itsMSPath;
    
  Bool     itsFirstScan;
  uInt     itsMSMainRow;
  Block<IPosition> itsDataShapes;

  NTDCoordinates itsNTDCoordinates;
    

  int itsScanNumber;
  int itsNCat;

  Bool itsStopFringes;
    
  Bool readData(NTDDataSource& ds);

  int createMS(const String msName);

  const char** getPolCombinations(int numCorr);

};
#endif
  
