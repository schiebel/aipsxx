// ASDM2MSFiller.h: implementation of a MeasurementSet's filler
// for Francois Viallefond & Frederic Badia ALMA Simulator
//
//  Copyright (C) 2001
//  OBSERVATOIRE DE PARIS - DEMIRM
//  Avenue Denfert Rochereau - 75014 - PARIS
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
#if !defined(ALMA_ASDM2MSFILLER_H)
#define ALMA_ASDM2MSFILLER_H
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
#include <measures/Measures/MeasTable.h>
#include <measures/Measures/Stokes.h>
#include <measures/Measures/MeasConvert.h>
#include <casa/BasicSL/Constants.h>
#include <casa/OS/File.h>
#include <casa/OS/Path.h>
#include <complex>

#include <vector>


using namespace casa;
using namespace std;

//# Forward Declarations

class TimeRange;
class MPosition;
class MeasFrame;
class MeasurementSet;
class MSMainColumns;

// Class timeMgr is a utility to help for the management
// of time in tables with TIME and INTERVAL columns
class timeMgr {
 private:
  int index;
  double startTime;

 public:
  timeMgr();
  timeMgr(int i, double t);
  void   setIndex(int i);
  void   setStartTime(double t);
  int    getIndex();
  double getStartTime();
};


// Class ddMgr is a utility to help for the management
// of DataDescription, SpectralWindow and Polarization ids.
// Here we provide enough space to store 100 values for 
// each quantity; this is very likeky far beyond the actual
// needs.
class ddMgr {
 private:
  int     numCorr[100];
  int     numChan[100];
  struct  {
    int polId;
    int swId;
  } dd[100];
  
 public:

  ddMgr();

  int setNumCorr(int i, int numChan);
  int setNumChan(int i, int numCorr);

  int getNumCorr(int i);
  int getNumChan(int i);

  int setDD(int i, int polId, int swId); 

  int getPolId(int i);
  int getSwId(int i);
};


 
// Class ASDM2MSFiller
class ASDM2MSFiller
{
 private:
  double         itsCreationTime;
  const char*    itsName;
  int            itsNumAntenna;
  int            itsNumChan;
  int            itsNumCorr;
  casa::MeasurementSet *itsMS;
  casa::MSMainColumns  *itsMSCol;
  /*
    Block<timeMgr> itsFeedTimeMgr;
    Block<timeMgr> itsPointingTimeMgr;
    Block<timeMgr> itsSyscalTimeMgr;
    Block<timeMgr> itsWeatherTimeMgr;
    Block<timeMgr> itsObservationTimeMgr;
  */
    
  String     itsMSPath;
  timeMgr* itsFeedTimeMgr;
  timeMgr* itsFieldTimeMgr;
  timeMgr* itsObservationTimeMgr;
  timeMgr* itsPointingTimeMgr;
  //OrderedMap<int, timeMgr> itsSourceTimeMgr;
  timeMgr* itsSourceTimeMgr;
  timeMgr* itsSyscalTimeMgr;
  timeMgr* itsWeatherTimeMgr;
    
  Bool     itsWithRadioMeters;     /* Are we building an ALMA MS ?*/
  Bool     itsFirstScan;
  uInt     itsMSMainRow;
  /*TiledDataStManAccessor itsImWgtAcc;*/
  Block<IPosition> itsDataShapes;

  int itsScanNumber;
  int itsNCat;
    
  ddMgr    itsDDMgr;

         
  int createMS(const char* msName, Bool complexData);

  const char** getPolCombinations(int numCorr);
    
   
 public:
  // Construct the MS with a given name, a given number of antennas
  // a given number of channels and a given number of polarizations.
  
  ASDM2MSFiller (const char* name_,
	      double      creation_time_,
	      Bool        withRadioMeters,
	      Bool        complexData);
  
  // Destructor
  ~ASDM2MSFiller();

  int addAntenna(
		 const char   *name_,
		 const char   *station_,
		 double lx_,
		 double ly_,
		 double lz_,
		 double offset_x_,
		 double offset_y_,
		 double offset_z_,
		 float  dish_diam_);

  void addData(double time_,
	       double interval_,
	       double exposure_,
	       double time_centroid_,
	       int    nb_antenna_feed_,
	       int    antenna_id_[],
	       int    feed_id_[],
	       int    data_desc_id_,
	       int    field_id_,
	       double uvw_[],
	       float  vis_r_[],
	       float  vis_i_[],
	       float  sigma_[],
	       float  weight_[],
	       const char   flag_[]);

  void addData (bool                      complexData,
		double                    time_,
		vector<int>               &antennaId1_,
		vector<int>               &antennaId2_,
		vector<int>               &feed1_,
		vector<int>               &feed2_,
		vector<int>               &dataDescId_,
		int                       processorId_,
		int                       fieldId_,
		double                    interval_,
		vector<double>            &exposure_,
		vector<double>            &timeCentroid_,
		int                       scanNumber_,
		int                       arrayId_,
		int                       observationId_,
		vector<int>               &stateId_,
		vector <double*>          &uvw_,
		vector<vector<int> >      &dataShape_,
		vector<float *>           &data_,
		vector<unsigned int>      &flag_);


  void addRCData(double time_,
		 double interval_,
		 double exposure_,
		 double time_centroid_,
		 int    nb_antenna_feed_,
		 int    antenna_id_[],
		 int    feed_id_[],
		 int    data_desc_id_,
		 int    field_id_,
		 double uvw_[],
		 float  rvis_r_[],
		 float  rvis_i_[],
		 float  cvis_r_[],
		 float  cvis_i_[],
		 float  sigma_[],
		 float  weight_[],
		 const char   flag_[]);
	       
  int  addDataDescription(int spectral_window_id_,
			  int polarizarion_id_);

  int  addUniqueDataDescription(int spectral_window_id_,
				int polarizarion_id_);

  int  exists(char *path);
  String msPath();


  void addFeed(int      antenna_id_,
	       int      feed_id_,
	       int      spectral_window_id_,
	       double   time_,
	       double   interval_,
	       int      num_receptors_,
	       int      beam_id_,
	       double   beam_offset_[],
	       const  char     *pol_type_,
	       double   polarization_responseR_[],
	       double   polarization_responseI_[],
	       double   position_[3],
	       double   receptor_angle_[]);
  
  void addField( const char   *name_,
		 const char   *code_,
		 double time_,
		 double delay_dir_[2],
		 double phase_dir_[2],
		 double reference_dir_[2],
		 int     source_id_);

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

  void addObservation(const char   *telescopeName_,
		      double startTime_,
		      double endTime_,
		      const char  *observer_,
		      const char  **log_,
		      const char  *schedule_type_,
		      const char  **schedule_,
		      const char  *project_,
		      double release_date_);


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

  int addUniquePolarization(int num_corr_,
		       int corr_type_[],
		       int corr_product_[]);

  void addProcessor(const char *type_,
		    const char*sub_type_,
		    int  type_id_,
		    int  mode_id_);

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
		 

  int  addSpectralWindow(int    num_chan_,
			 const char  *name_,
			 double ref_frequency_,
			 double chan_freq_[],
			 double chan_width_[],
			 int    meas_freq_ref_,
			 double effective_bw_[],
			 double resolution_[],
			 double total_bandwidth_,
			 int    net_sideband_,
			 int    if_conv_chain_,
			 int    freq_group_,
			 const char  *freq_group_name_,
			 int    num_assoc_,
			 int    assoc_spectral_window_[],
			 char** assoc_nature_);

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

  void end(double time_);
};
#endif
  
