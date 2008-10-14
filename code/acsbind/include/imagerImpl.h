#ifndef _ACSimager_H_
#define _ACSimager_H_

#include <imagerS.h>
#include <corba.h>
NAMESPACE_USE(baci);
NAMESPACE_USE(acscomponent);
#include<synthesis/MeasurementEquations/RDOimager.h>

class acsimager : public ACSComponentImpl,
                                          public virtual POA_CASA::acsimager {
    public :
                       acsimager(PortableServer::POA_ptr poa, const ACE_CString &name);
                       acsimager(PortableServer::POA_ptr poa, const ACE_CString &name, bool baseClass);
           virtual ~acsimager();
                    bool advise()
                             throw (CORBA::SystemException);
                       bool approximatepsf()
                             throw (CORBA::SystemException);
                       bool boxmask()
                             throw (CORBA::SystemException);
                       bool clean(const char * , int , float , float , bool , const char * , bool , const char * , const CASA::StringVec &, const CASA::StringVec &, const CASA::StringVec &, bool , int , const char * , bool )
                             throw (CORBA::SystemException);
                       bool clipimage()
                             throw (CORBA::SystemException);
                       bool clipvis()
                             throw (CORBA::SystemException);
                       bool close()
                             throw (CORBA::SystemException);
                       bool correct()
                             throw (CORBA::SystemException);
                       bool done()
                             throw (CORBA::SystemException);
                       bool exprmask()
                             throw (CORBA::SystemException);
                       bool feather()
                             throw (CORBA::SystemException);
                       bool filter()
                             throw (CORBA::SystemException);
                       bool fitpsf()
                             throw (CORBA::SystemException);
                       bool ft()
                             throw (CORBA::SystemException);
                       bool linearmosaic()
                             throw (CORBA::SystemException);
                       bool make()
                             throw (CORBA::SystemException);
                       bool makeimage(const char * , const char * , const char * , bool )
                             throw (CORBA::SystemException);
                       bool modemodelfromsd()
                             throw (CORBA::SystemException);
                       bool mask()
                             throw (CORBA::SystemException);
                       bool mem(const char * , int , double , double , bool , bool , const CASA::StringVec &, const CASA::BoolVec &, const char * , const CASA::StringVec &, const CASA::StringVec &, const CASA::StringVec &, const CASA::StringVec &, bool )
                             throw (CORBA::SystemException);
                       bool nnls()
                             throw (CORBA::SystemException);
                       bool open(const char * , bool )
                             throw (CORBA::SystemException);
                       bool pixon()
                             throw (CORBA::SystemException);
                       bool plotsummary()
                             throw (CORBA::SystemException);
                       bool plotuv()
                             throw (CORBA::SystemException);
                       bool plotvis()
                             throw (CORBA::SystemException);
                       bool plotweights()
                             throw (CORBA::SystemException);
                       bool regionmask()
                             throw (CORBA::SystemException);
                       bool residual()
                             throw (CORBA::SystemException);
                       bool restore()
                             throw (CORBA::SystemException);
                       bool selfcal()
                             throw (CORBA::SystemException);
                       bool sensitivity()
                             throw (CORBA::SystemException);
                       bool setbeam()
                             throw (CORBA::SystemException);
                       bool setjy()
                             throw (CORBA::SystemException);
                       bool setmfcontrol()
                             throw (CORBA::SystemException);
                       bool setdata(const char * , const CASA::IntVec &, const CASA::IntVec &, const CASA::IntVec &, double , double , const CASA::IntVec &, const CASA::IntVec &, const char * , bool )
                             throw (CORBA::SystemException);
                       bool setimage(int , int , double , double , const char * , bool , const char * , double , double , const char * , int , int , int , const char * , const char * , const CASA::IntVec &, int , int , double )
                             throw (CORBA::SystemException);
                       bool setoptions(const char * , int , int , const char * , const char * , double , bool )
                             throw (CORBA::SystemException);
                       bool setscales()
                             throw (CORBA::SystemException);
                       bool setsdoptions()
                             throw (CORBA::SystemException);
                       bool setvp()
                             throw (CORBA::SystemException);
                       bool smooth(CASA::StringVec_out, const CASA::StringVec &, bool , double , double , double , bool , bool )
                             throw (CORBA::SystemException);
                       bool stop()
                             throw (CORBA::SystemException);
                       bool summary()
                             throw (CORBA::SystemException);
                       bool uvrange(double , double )
                             throw (CORBA::SystemException);
                       bool weight(const char * , const char * , double , double , double , int , bool , bool )
                             throw (CORBA::SystemException);
              
            private :
                 casa::RDOimager myRdo;
}; 
#endif
  
