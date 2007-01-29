#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>
#include <appsglish/ionosphere/DOrinex.h>
#include <ionosphere/Ionosphere/RINEX.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>
#include <casa/Quanta/MVTime.h>
    
#include <casa/namespace.h>
// -----------------------------------------------------------------------
// ##### rinex ###########################################################
//
// The rinex DO provides services for reading and processing
// sattelite-related data (RINEX, IGS/SP3, etc.)
//
// NB: Gotta think of a better name... "gps" is bad because
// RINEX is more than just GPS (GLONASS, etc.)
// -----------------------------------------------------------------------
   
        
// -----------------------------------------------------------------------
// Default constructor and destructor, 
// plus standard ApplicationObject methods
// -----------------------------------------------------------------------
rinex::rinex () 
{
// enable debug messages
  RINEX::debug_level=1;
  RINEXSat::debug_level=2;
  GPSEphemeris::debug_level=1;
//  GPSGroupDelay::debug_level=1;
  dcb=NULL;
}

rinex::~rinex()
{
  if( dcb ) delete dcb;
}

String rinex::className() const
{
  return "rinex";
};

Vector<String> rinex::methods() const
{
  const char *method_names[] = {
        "import_rinex",
        "import_sp3",
        "import_dcb", 
        "split_mjd",
        "get_dcb"
      };
  const uInt nm = sizeof(method_names)/sizeof(method_names[0]);
  Vector <String> method(nm);
  for( uInt i=0; i<nm; i++ )
    method(i) = method_names[i];
  return method;
};

Vector<String> rinex::noTraceMethods() const
{
  Vector<String> nm(1);
  nm(0) = "split_mjd";
  return nm;
} 

// -----------------------------------------------------------------------
// rinex::addObject
// registers a new application subobject
// -----------------------------------------------------------------------
ObjectID rinex::addObject ( ApplicationObject *subobject )
{
  ObjectID oid(True);
  ObjectController *controller = ApplicationEnvironment::objectController();
  if (controller) {
// We have a controller, so we can return a valid object id after we
// register the new object
    oid = controller->addObject(subobject);
  } 
  return oid;
}  

// -----------------------------------------------------------------------
// rinex::import_rinex
// Imports RINEX file into a rinexchunk object
//
// Inputs: filename: name of RINEX file
//
// Outputs: oid:   ObjectID of new rinexchunk object
//          stats: A GlishRecord with stats for the chunk
// 
// Return value:   ok() or error("")
// -----------------------------------------------------------------------
MethodResult rinex::import_rinex ( ObjectID &oid,GlishRecord &stats,const String &filename )
{
// create rinexchunk and call its import function
  rinexchunk *chunk = new rinexchunk(*this);
  AlwaysAssert(chunk, AipsError);
  MethodResult result = chunk->import( stats,filename );
  if( !result.ok() ) {
//    cerr<<"import failed\n";
    delete chunk;
    return result;  
  }
// register the object
//  cerr<<"import OK\n";
  oid = addObject(chunk);
  if( oid.isNull() )
  {
//    cerr<<"OID invalid\n";
    delete chunk;
    return error("Failed to add rinexchunk object");
  }
//  cerr<<"OID seems valid: "<<oid<<"\n";
  return result;
}  

// -----------------------------------------------------------------------
// rinex::import_sp3
// Imports IGS/SP3 file into an ephchunk object
//
// Inputs: filename: name of SP3 file
//
// Outputs: oid:   ObjectID of new rinexchunk object
//          stats: A GlishRecord with stats for the chunk
// 
// Return value:   ok() or error("")
// -----------------------------------------------------------------------
MethodResult rinex::import_sp3 ( ObjectID &oid,const String &filename )
{
// create rinexchunk and call its import function
  ephchunk *chunk = new ephchunk(*this);
  AlwaysAssert(chunk, AipsError);
  MethodResult result = chunk->import_sp3( filename );
  if( !result.ok() ) {
    delete chunk;
    return result;  
  }
// register the object
  oid = addObject(chunk);
  if( oid.isNull() )
  {
    delete chunk;
    return error("Failed to add ephchunk object");
  }
  return result;
}  

// -----------------------------------------------------------------------
// rinex::import_dcb
// Imports DCB table into a DCB record
//
// Inputs: filename: name of DCB table, or empty for default
//
// Outputs: tgdrec: a GlishRecord of the form [mjd1,mjd2,valid,tgd],
//          where Double mjd1/2 are the starting and ending epochs,
//          valid is a boolean array of validity flags, and 
//          tgd is an array giving the Tgd for each SVN.
// 
// Return value:   ok() or error("")
// -----------------------------------------------------------------------
MethodResult rinex::import_dcb ( GlishRecord &dcbrec,const String &tablename )
{
// create TGD object
  GPSDCB *dcb1 = new GPSDCB(tablename.chars());
// no error checkingL only exceptions are thrown
  if( dcb )
    delete dcb;
  dcb = dcb1;
// copy out results  
  dcbrec = GlishRecord();
  dcbrec.add("mjd",dcb->rawMjd())
        .add("dcb",dcb->rawDcb())
        .add("dcbrms",dcb->rawDcbRms())
        .add("staids" ,dcb->rawStIDs())
        .add("stadcb" ,dcb->rawStDcb())
        .add("starms" ,dcb->rawStDcbRms());
  return ok();
}  

// -----------------------------------------------------------------------
// rinex::runMethod
// Mechanism to allow execution of class methods from the 
// aips++ DO system.
// Inputs:
//    which        uInt               Selected method
//    inpRec       ParameterSet       Associated input parameters
//    runMethod    Bool               Execute method ?
// -----------------------------------------------------------------------
MethodResult rinex::runMethod (uInt which, ParameterSet& inpRec, 
                                    Bool runMethod)
{
  try {
    switch( which ) 
    {
      case 0: // import_rinex -- imports RINEX file and returns rinexchunk object
      {
        Parameter<String> filename(inpRec,"filename", ParameterSet::In);
        Parameter<ObjectID> oid(inpRec,"returnval", ParameterSet::Out);
        Parameter<GlishRecord> stats(inpRec,"stats", ParameterSet::Out);
        if( runMethod ) {
          return import_rinex(oid(),stats(),filename());
        }
        break;
      }
      case 1: // import_sp3 -- imports IGS/SP3 file and returns ephchunk object
      {
        Parameter<String> filename(inpRec,"filename", ParameterSet::In);
        Parameter<ObjectID> oid(inpRec,"returnval", ParameterSet::Out);
//        Parameter<GlishRecord> stats(inpRec,"stats", ParameterSet::Out);
        if( runMethod ) {
          return import_sp3(oid(),filename());
        }
        break;
      }
      case 2: // import_dcb -- imports DCB table and returns dcb record
      {
        Parameter<String> tablename(inpRec,"tablename", ParameterSet::In);
        Parameter<GlishRecord> dcbrec(inpRec,"returnval", ParameterSet::Out);
//        Parameter<GlishRecord> stats(inpRec,"stats", ParameterSet::Out);
        if( runMethod ) {
          return import_dcb(dcbrec(),tablename());
        }
        break;
      }
      case 3: // split_mjd -- splits an MJD into a [y,m,d,doy] record
      {
        Parameter<Double> mjd(inpRec,"mjd", ParameterSet::In);
        Parameter<GlishRecord> rec(inpRec,"returnval", ParameterSet::Out);
//        Parameter<GlishRecord> stats(inpRec,"stats", ParameterSet::Out);
        if( runMethod ) {
          MVTime t(mjd());
          rec() = GlishRecord();
          rec().add("year",(int)t.year())
               .add("month",(int)t.month())
               .add("day",(int)t.monthday())
               .add("yearday",(int)t.yearday())
               .add("yearweek",(int)t.yearweek())
               .add("weekday",(int)t.weekday());
          return ok();
        }
        break;
      }
      case 4: // get_dcb -- fetches DCB data interpolated to given MJD
      {
        Parameter< Vector<Float> > rms(inpRec,"rms", ParameterSet::Out);
        Parameter< Vector<Float> > result(inpRec,"returnval", ParameterSet::Out);
        Parameter<Int> svn(inpRec,"svn",ParameterSet::In);
        Parameter< Vector<Float> > mjd(inpRec,"mjd",ParameterSet::In);
        Parameter<Bool> p1c1(inpRec,"p1c1",ParameterSet::In);
        if( runMethod ) 
        {
          if( !dcb ) 
            return error("No DCB table loaded. Please call import_dcb() first.");
          result() = dcb->getDcb(rms(),p1c1()?GPSDCB::P1_C1:GPSDCB::P1_P2,
                      mjd(),svn());
          return ok();
        }
        break;
      }
      default: 
        return error("No such method");
    }
  } catch( AipsError err ) {
    return error( err.getMesg() );
  }
  return ok();
}


// -----------------------------------------------------------------------
// ##### rinexchunk ######################################################
// rinexchunk represents one chunk of RINEX data
//
// -----------------------------------------------------------------------


// -----------------------------------------------------------------------
// Default constructor and destructor, 
// plus standard ApplicationObject methods
// -----------------------------------------------------------------------
rinexchunk::rinexchunk( const rinex &par ) 
  : rnx(),parent(par)
{}

rinexchunk::~rinexchunk()
{}

String rinexchunk::className() const
{
  return "rinexchunk";
};

Vector<String> rinexchunk::methods() const
{
  const char *method_names[] = {
        "get_tec",
      };
  const uInt nm = sizeof(method_names)/sizeof(method_names[0]);
  Vector <String> method(nm);
  for( uInt i=0; i<nm; i++ )
    method(i) = method_names[i];
  return method;
};

// -----------------------------------------------------------------------
// rinexchunk::import
// Imports chuck from RINEX2 file
// -----------------------------------------------------------------------
MethodResult rinexchunk::import ( GlishRecord &stats,const String &filename )
{
  Int result = rnx.import( filename.chars() );
  if( result )
  {
    Vector<Int> sat_counts(NUM_GPS);
    for( uInt i=0; i<NUM_GPS; i++ )
      sat_counts(i) = rnx.sdata(i).nelements();

    stats = GlishRecord();
    stats.add("rcv_pos"    ,rnx.header().pos.getValue())
         .add("interval"   ,rnx.header().tsmp)
         .add("num_epochs" ,(Int)rnx.header().nep)
         .add("epoch_begin",rnx.header().ep_first)
         .add("epoch_end"  ,rnx.header().ep_last)
         .add("sat_counts" ,sat_counts);
    return ok();
  }
  else
    return error("RINEX::import failed");
}  


// -----------------------------------------------------------------------
// rinexchunk::runMethod
// Mechanism to allow execution of class methods from the 
// aips++ DO system.
// Inputs:
//    which        uInt               Selected method
//    inpRec       ParameterSet       Associated input parameters
//    runMethod    Bool               Execute method ?
// -----------------------------------------------------------------------
MethodResult rinexchunk::runMethod (uInt which, ParameterSet& inpRec, 
                                    Bool runMethod)
{
  try {
    switch( which ) 
    {
      case 0: { // get_tec 
        Parameter<Vector<Double> > mjd(inpRec,"mjd",ParameterSet::Out);
        Parameter<Vector<Int> >    svn(inpRec,"svn",ParameterSet::Out);
        Parameter<Vector<Double> > tec(inpRec,"tec",ParameterSet::Out);
        Parameter<Vector<Double> > stec(inpRec,"stec",ParameterSet::Out);
        Parameter<Vector<Double> > stec30(inpRec,"stec30",ParameterSet::Out);
        Parameter<Vector<Int> >    domain(inpRec,"domain",ParameterSet::Out);
        Parameter<Int> count(inpRec,"returnval", ParameterSet::Out);
        if( runMethod ) 
        {
          GPSDCB *dcb = parent.getDCB();
          if( !dcb )
            return error("No DCB table loaded. Please call import_dcb() first.");
          count() = rnx.getTEC(mjd(),svn(),tec(),stec(),stec30(),domain(),*dcb);
        }
        break;
      }
      default: 
        return error("No such method");
    }
  } catch( AipsError err ) {
    return error( err.getMesg() );
  }
  return ok();
}

// -----------------------------------------------------------------------
// ##### ephchunk ######################################################
// ephchunk represents one chunk of RINEX data
//
// -----------------------------------------------------------------------


// -----------------------------------------------------------------------
// Default constructor and destructor, 
// plus standard ApplicationObject methods
// -----------------------------------------------------------------------
ephchunk::ephchunk( const rinex &par ) 
  : eph(),parent(par)
{}

ephchunk::~ephchunk()
{}

String ephchunk::className() const
{
  return "ephchunk";
};

Vector<String> ephchunk::methods() const
{
  const char *method_names[] = {
        "get_eph",
        "spline_eph",
        "spline_azel"
      };
  const uInt nm = sizeof(method_names)/sizeof(method_names[0]);
  Vector <String> method(nm);
  for( uInt i=0; i<nm; i++ )
    method(i) = method_names[i];
  return method;
};

Vector<String> ephchunk::noTraceMethods() const
{
  Vector<String> nm(2);
  nm(0) = "spline_eph";
  nm(1) = "spline_azel";
  return nm;
} 

// -----------------------------------------------------------------------
// ephchunk::importSP3
// Imports a chunck of ephemeris from IGS-SP3 file
// -----------------------------------------------------------------------
MethodResult ephchunk::import_sp3 ( const String &filename )
{
  if( eph.importIGS( filename.chars() ) )
    return ok();
  return error("GPSEphemeris::importIGS failed");
}  

// -----------------------------------------------------------------------
// ephchunk::spline_azel 
// Given a position, splines az/el of given SVN to given time grid
// Returns (N,2) matrix. First column is az, second is el
// -----------------------------------------------------------------------
Int ephchunk::spline_azel ( Vector<Double> &az,Vector<Double> &el,Int svn,
        const Vector<Double> &mjd,const MVPosition &pos)
{
  if( !eph.svnValid(svn) )
    throw( AipsError("spline_azel: invalid SVN") );
// call GPSEphemeris to do the spline
  Vector<MVDirection> azel( eph.splineAzEl(svn,mjd,pos) ); 

// copy angles into output arrays
  uInt n = mjd.nelements();
  az.resize(n); el.resize(n);
  for( uInt i=0; i<n; i++ ) {
    az(i) = azel(i).getLong();
    el(i) = azel(i).getLat();
  }
  return n;
}


// -----------------------------------------------------------------------
// ephchunk::runMethod
// Mechanism to allow execution of class methods from the 
// aips++ DO system.
// Inputs:
//    which        uInt               Selected method
//    inpRec       ParameterSet       Associated input parameters
//    runMethod    Bool               Execute method ?
// -----------------------------------------------------------------------
MethodResult ephchunk::runMethod (uInt which, ParameterSet& inpRec, 
                                    Bool runMethod)
{
  try {
    switch( which ) 
    {
      case 0: { // get_eph
        Parameter<Int> svn(inpRec,"svn",ParameterSet::In);
        Parameter<Vector<Double> > mjd(inpRec,"returnval",ParameterSet::Out);
        Parameter<Vector<Double> > ex(inpRec,"ex",ParameterSet::Out);
        Parameter<Vector<Double> > ey(inpRec,"ey",ParameterSet::Out);
        Parameter<Vector<Double> > ez(inpRec,"ez",ParameterSet::Out);
        if( runMethod ) {
          if( !eph.svnValid(svn()) )
            return error("get_eph: invalid SVN");
          mjd() = eph.getEpochs();
          const Matrix<Double> &em = eph.getEph(svn());
          ex() = em.column(GPSEphemeris::EX);
          ey() = em.column(GPSEphemeris::EY);
          ez() = em.column(GPSEphemeris::EZ);
        }
        break;
      }
      case 1: { // spline_eph
        Parameter<Int> svn(inpRec,"svn",ParameterSet::In);
        Parameter<Vector<Double> > mjd(inpRec,"mjd",ParameterSet::In);
        Parameter<Vector<Double> > ex(inpRec,"ex",ParameterSet::Out);
        Parameter<Vector<Double> > ey(inpRec,"ey",ParameterSet::Out);
        Parameter<Vector<Double> > ez(inpRec,"ez",ParameterSet::Out);
        Parameter<Int>            count(inpRec,"returnval",ParameterSet::Out);
        if( runMethod ) {
          if( !eph.svnValid(svn()) )
            return error("spline_eph: invalid SVN");
          // spline ephemeris and assign them to return value
          Matrix<Double> em( eph.splineEph(svn(),mjd()) );
          ex() = em.column(GPSEphemeris::EX);
          ey() = em.column(GPSEphemeris::EY);
          ez() = em.column(GPSEphemeris::EZ);
          count() = ex().nelements();
        }
        break;
      }
      case 2: { // spline_azel
        Parameter<Int> svn(inpRec,"svn",ParameterSet::In);
        Parameter<Vector<Double> > mjd(inpRec,"mjd",ParameterSet::In);
        Parameter<Vector<Double> > pos(inpRec,"pos",ParameterSet::In);
        Parameter<Vector<Double> > az(inpRec,"az",ParameterSet::Out);
        Parameter<Vector<Double> > el(inpRec,"el",ParameterSet::Out);
        Parameter<Int>            count(inpRec,"returnval",ParameterSet::Out);
        if( runMethod ) {
          if( !eph.svnValid(svn()) )
            return error("spline_eph: invalid SVN");
          // spline az/el and assign them to return value
          if( !spline_azel(az(),el(),svn(),mjd(),MVPosition(pos())) )
            return error("spline_eph: failed");
          count() = az().nelements();
        }
        break;
      }
      default: 
        return error("No such method");
    }
  } catch( AipsError err ) {
    return error( err.getMesg() );
  }
  return ok();
}

