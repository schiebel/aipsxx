#ifndef APPSGLISH_DORINEX_H
#define APPSGLISH_DORINEX_H

#include <casa/aips.h>
#include <tasking/Tasking.h>                                          
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>
#include <ionosphere/Ionosphere/RINEX.h>
#include <ionosphere/Ionosphere/GPSDCB.h>
    
#include <casa/namespace.h>
class rinexchunk;
class ephchunk;
    
// <summary>
// Implements the rinex DO
// </summary>
class rinex : public ApplicationObject                         
{
public:

  rinex();
  ~rinex();

  virtual String className() const;                              
  virtual Vector<String> methods() const;                        
  virtual Vector<String> noTraceMethods() const;                        
  virtual MethodResult runMethod(uInt which,                     
                                ParameterSet &parameters,
                                Bool runMethod);
  
// returns group delay data for a given date, or throws
// exception if none is available
  GPSDCB * getDCB () const;
      
private:
  // imports rinexchunk from RINEX file
  MethodResult import_rinex( ObjectID &oid,GlishRecord &stats,const String &filename );
  // imports and attaches ep3chunk from IGS-SP3 file
  MethodResult import_sp3  ( ObjectID &oid,const String &filename );
  // imports and attaches group delays from DCB table
  MethodResult import_dcb  ( GlishRecord &tgdrec,const String &tablename );

  // adds a new subobject
  ObjectID     addObject( ApplicationObject *subobject );
  
  GPSDCB        *dcb;
};

inline GPSDCB * rinex::getDCB () const 
{ return dcb; }

// <summary>
// Implements the rinexchunk DO
// </summary>
class rinexchunk : public ApplicationObject                         
{
public:

  rinexchunk( const rinex &parent );
  ~rinexchunk();

  virtual String className() const;                              
  virtual Vector<String> methods() const;                        
  virtual MethodResult runMethod(uInt which,                     
                                ParameterSet &parameters,
                                      Bool runMethod);
  
  MethodResult import ( GlishRecord &stats,const String &filename );
  
private:

// gets TEC samples
  Int getTEC ( Vector<Double> &mjd,         // epochs
               Vector<Int>   &svn,        // SVNs
               Vector<Double> &tec,        // TEC
               Vector<Double> &sigTec,     // sigma TEC
               Vector<Double> &sigTec30,   // 30-minute mean sigma TEC
               Vector<Double> &az,         // az/el
               Vector<Double> &el );
  
  RINEX rnx;
  const rinex &parent;
};

// <summary>
// Implements the ephchunk DO
// </summary>
class ephchunk : public ApplicationObject                         
{
public:

  ephchunk( const rinex &parent );
  ~ephchunk();

  virtual String className() const;                              
  virtual Vector<String> methods() const;                        
  virtual Vector<String> noTraceMethods() const;                        
  virtual MethodResult runMethod(uInt which,ParameterSet &parameters,Bool runMethod);
  
  MethodResult import_sp3 ( const String &filename );
  
  Int spline_azel ( Vector<Double> &az,Vector<Double> &el,Int svn,
                   const Vector<Double> &mjd,const MVPosition &pos);
  
private:

  GPSEphemeris eph;
  const rinex &parent;
};


#endif
