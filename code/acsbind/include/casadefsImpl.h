#ifndef CasaDefsImpl_h
#define CasaDefsImpl_h
/*******************************************************************************
*    ALMA - Atacama Large Millimiter Array
*/
/************************************************************************
 *
 *----------------------------------------------------------------------
 */

#ifndef __cplusplus
#error This is a C++ include file and cannot be used from plain C
#endif

#include <string>
using std::string;

#include <acscomponentImpl.h>
#include <baciCharacteristicComponentImpl.h>


#include <casadefsS.h>
// #include <CasaDefsC.h>
#include <baciROdouble.h>
#include <acsncSimpleSupplier.h>

NAMESPACE_USE(baci);
NAMESPACE_USE(acscomponent);

class RecordInterface;

/** @file CasaDefsImpl.h
 *  Header file for CasaDefs example.
 *
 *
 */

class CasaRecord: public ACSComponentImpl,
		public virtual POA_CASA::CasaRecord
{

  private :
      char *itsName;
      char *itsComment;
      CASA::CasaFieldVec_var itsFields;
  public:
    /**
     * Constructor
     * @param poa poa which will activate this and also all other COBs
     * @param name DO name
     */
    CasaRecord(PortableServer::POA_ptr poa, const ACE_CString &name);
    CasaRecord(PortableServer::POA_ptr poa, const ACE_CString &name, bool baseClass);

    /**
     * Destructor
     */
    virtual ~CasaRecord();
//
    void setName(const char *theName)throw(CORBA::SystemException){itsName = CORBA::string_dup(theName);}
    char *getName()throw(CORBA::SystemException){return itsName;}
    void setComment(const char *theComment)throw(CORBA::SystemException){itsComment = CORBA::string_dup(theComment);}
    char *getComment()throw(CORBA::SystemException){return itsComment;}
    void setFields(const CASA::CasaFieldVec &theFields)throw(CORBA::SystemException);
    void setFields(CASA::CasaFieldVec *theFields)throw(CORBA::SystemException);
//
     void		addField(const CASA::CasaField&)
          throw(CORBA::SystemException);
     int nelements()
           throw(CORBA::SystemException);
     CASA::CasaValue	*getField(int)
           throw(CORBA::SystemException);
     CASA::CasaValue	*getFieldFromName(const char *)
           throw(CORBA::SystemException);
     CASA::CasaFieldVec	*getFields()
           throw(CORBA::SystemException);
     void debugOut(CASA::CasaValue &);
};

#endif   /* casaDefImpl_h */

