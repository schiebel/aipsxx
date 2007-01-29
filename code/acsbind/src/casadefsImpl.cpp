/*******************************************************************************
*    ALMA - Atacama Large Millimiter Array
*    (c) European Southern Observatory, 2002
*    Copyright by ESO (in the framework of the ALMA collaboration)
*    and Cosylab 2002, All rights reserved
*
*    This library is free software; you can redistribute it and/or
*    modify it under the terms of the GNU Lesser General Public
*    License as published by the Free Software Foundation; either
*    version 2.1 of the License, or (at your option) any later version.
*
*    This library is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
*    Lesser General Public License for more details.
*
*    You should have received a copy of the GNU Lesser General Public
*    License along with this library; if not, write to the Free Software
*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
*/

// work around symbol clash in /alma/ACS-2.1/ACSSW/include/cdbData_Types.h

#include <vltPort.h>
#include <maciACSComponentDefines.h>
#include <maciContainerImpl.h>

static char *rcsId="@(#) $Id: casadefsImpl.cpp,v 1.1 2005/05/27 22:51:08 wyoung Exp $";
static void *use_rcsId = ((void)&use_rcsId,(void *) &rcsId);

#include <casadefsImpl.h>

// #include <casaAutoFlagImpl.h>

//This must be used instead of "using ...." because of VxWorks
NAMESPACE_USE(baci);

/////////////////////////////////////////////////
// CasaRecord
/////////////////////////////////////////////////


CasaRecord::CasaRecord(PortableServer::POA_ptr poa, const ACE_CString &name) :
    ACSComponentImpl(poa, name)
{
    ACS_TRACE("::CasaRecord::CasaRecord");
}

CasaRecord::~CasaRecord()
{
    ACS_TRACE("::CasaRecord::~CasaRecord");
    // stop threads
    ACS_DEBUG("::CasaRecord::~CasaRecord", "Properties destroyed");
}

void CasaRecord::setFields(CASA::CasaFieldVec *theFields)
           throw(CORBA::SystemException){
      itsFields = new CASA::CasaFieldVec(theFields->length(), theFields->length(),
                                         theFields->get_buffer(), 1);
/*
       itsFields->length(theFields->length());
   //   *itsFields = *theFields;
   for(unsigned int  i=1; i<itsFields->length();i++){
       itsFields[i] = (*theFields)[i];
   }
*/
}

void CasaRecord::setFields(const CASA::CasaFieldVec &theFields)
           throw(CORBA::SystemException){
         itsFields = new CASA::CasaFieldVec(theFields.length(), theFields.length(),
                                         theFields.get_buffer(), 1);
         std::cerr << "CasaRecord::setFields needs completion" << std::endl;
/*
         itsFields->length(theFields.length());
   for(unsigned int  i=1; i<itsFields->length();i++){
       itsFields[i] = theFields[i];
   }
*/
 }

CASA::CasaFieldVec *CasaRecord::getFields()
           throw(CORBA::SystemException)
{
   int j(0);
   std::cerr << itsFields->length() << std::endl;
   std::cerr << j++ << std::endl;
   CASA::CasaFieldVec_var theFields = new CASA::CasaFieldVec(itsFields->length());
   std::cerr << j++ << std::endl;
   theFields->length(itsFields->length());
   std::cerr << j++ << std::endl;
   // *theFields = *itsFields;

   for(unsigned int  i=0; i<itsFields->length();i++){
       std::cerr << i << std::endl;
       theFields[i] = *(new CASA::CasaField());
       theFields[i].fieldname = CORBA::string_dup(itsFields[i].fieldname);
       std::cerr << theFields[i].fieldname << " ";
       theFields[i].comment = CORBA::string_dup(itsFields[i].comment);
       theFields[i].value = *(new CASA::CasaValue());
       theFields[i].value.type = itsFields[i].value.type;
       theFields[i].value.shape = *(new CASA::IntVec(itsFields[i].value.shape));
       theFields[i].value.value = CASA::CasaData(itsFields[i].value.value);
       debugOut(theFields[i].value);
   }
   std::cerr << j++ << std::endl;
/*
   CASA::CasaField_var theField = new CASA::CasaField;
   CASA::CasaValue_var theVal = new CASA::CasaValue;
   theVal->type = CASA::ATYPE_Float;
   int dummy(1);
   theVal->shape = CASA::IntVec(1,1,&dummy,0);

   float aTmp(5.0);
   CASA::CasaDatum_var theData = new CASA::CasaDatum;
   casa_wrappers::assignData(theData, aTmp);
   theVal->value = *theData;
   theField->fieldname = strdup("myfieldname");
   theField->comment = strdup("no comment");
   theField->value = *theVal;
   theFields[0] = *theField;


   CASA::CasaFieldVec *myDeref = itsFields->get_buffer();
   std::cerr << "Been derefed" << std::endl;
*/
   std::cerr << theFields->length()  << " copied"<< std::endl;
   return theFields._retn();
}
int CasaRecord::nelements()
           throw(CORBA::SystemException)
{
   return itsFields->length();
}
CASA::CasaValue  *CasaRecord::getField(int i)
           throw(CORBA::SystemException)
{
   CASA::CasaValue *dummy = new CASA::CasaValue;
   *dummy = itsFields[i].value;
   return dummy;
}
CASA::CasaValue  *CasaRecord::getFieldFromName(const char *afield)
           throw(CORBA::SystemException)
{
   // OK loop through the field vects until we find it.
   // throw an exception if it the field doesn't exist.
   CASA::CasaValue *dummy = new CASA::CasaValue;
   for(unsigned int i=0;i<itsFields->length();i++){
      if( String(afield) == String(itsFields[i].fieldname)){
	  *dummy = itsFields[i].value;
	  break;
      }
   }
   return dummy;
}

void CasaRecord::addField(const CASA::CasaField &afield)
           throw(CORBA::SystemException)
{
   // Resize and Add the new element.
   itsFields->length(itsFields->length()+1);
   itsFields[itsFields->length()-1] = afield;
   return;
}
void CasaRecord::debugOut(CASA::CasaValue &aval){
   switch(aval.type){
      case CASA::ATYPE_Bool :
        std::cerr << "Bool: " << aval.value[0].boolVal();
        break;
      case CASA::ATYPE_Char :
        std::cerr << "Char: " << aval.value[0].charVal();
        break;
      case CASA::ATYPE_UChar :
        std::cerr << "UChar: " << aval.value[0].ucharVal();
        break;
      case CASA::ATYPE_Short :
        std::cerr << "Short: " << aval.value[0].shortVal();
        break;
      case CASA::ATYPE_UShort :
        std::cerr << "UShort: " << aval.value[0].ushortVal();
        break;
      case CASA::ATYPE_Int :
      case CASA::ATYPE_Long :
        std::cerr << "Int: " << aval.value[0].intVal();
        break;
      case CASA::ATYPE_UInt :
      case CASA::ATYPE_ULong :
        std::cerr << "UInt: " << aval.value[0].uintVal();
        break;
      case CASA::ATYPE_Float :
        std::cerr << "Float: " << aval.value[0].floatVal();
        break;
      case CASA::ATYPE_Double :
        std::cerr << "Double: " << aval.value[0].doubleVal();
        break;
      case CASA::ATYPE_Complex :
        // std::cerr << "Complex: " << aval.value.complexVal();
        break;
      case CASA::ATYPE_DComplex :
        // std::cerr << "DComplex: " << aval.value.dcomplexVal();
        break;
      case CASA::ATYPE_String :
        std::cerr << "String: " << aval.value[0].stringVal();
        break;
      case CASA::ATYPE_Table :
        std::cerr << "Table: " << aval.value[0].tableVal();
        break;
      case CASA::ATYPE_ARR_Bool :
        std::cerr << "ARR_Bool: " << aval.value[0].boolVal();
        break;
      case CASA::ATYPE_ARR_Char :
        std::cerr << "ARR_Char: " << aval.value[0].boolVal();
        break;
      case CASA::ATYPE_ARR_UChar :
        std::cerr << "ARR_UChar: " << aval.value[0].boolVal();
        break;
      case CASA::ATYPE_ARR_Short :
        std::cerr << "ARR_Short: " << aval.value[0].boolVal();
        break;
      case CASA::ATYPE_ARR_UShort :
        std::cerr << "ARR_Short: " << aval.value[0].boolVal();
        break;
      case CASA::ATYPE_ARR_Int :
      case CASA::ATYPE_ARR_Long :
        std::cerr << "ARR_Long: " << aval.value[0].boolVal();
        break;
      case CASA::ATYPE_ARR_UInt :
      case CASA::ATYPE_ARR_ULong :
        std::cerr << "ARR_UInt: " << aval.value[0].boolVal();
        break;
      case CASA::ATYPE_ARR_Float :
        std::cerr << "ARR_float: " << aval.value[0].boolVal();
        break;
      case CASA::ATYPE_ARR_Double :
        std::cerr << "ARR_Double: " << aval.value[0].boolVal();
        break;
      case CASA::ATYPE_ARR_Complex :
        std::cerr << "ARR_Complex: " << aval.value[0].boolVal();
        break;
      case CASA::ATYPE_ARR_DComplex :
        std::cerr << "ARR_DComplex: " << aval.value[0].boolVal();
        break;
      case CASA::ATYPE_ARR_String :
        std::cerr << "ARR String: " ; // << aval.value.stringArr();
        break;
      case CASA::ATYPE_Record :
        std::cerr << "Record: " << aval.value[0].boolVal();
        break;
      case CASA::ATYPE_Other :
        std::cerr << "Other: " << aval.value[0].boolVal();
        break;
      default :
        std::cerr << aval.value[0].stringVal();
        break;
   }
   std::cerr << std::endl;
}

/* --------------------- [ CORBA interface ] ----------------------*/

/* --------------- [ MACI DLL support functions ] -----------------*/
#include <maciACSComponentDefines.h>
//MACI_DLL_SUPPORT_FUNCTIONS(CasaField)
// OK this needs to be in a seperate file so we can load the goodies, sigh.
MACI_DLL_SUPPORT_FUNCTIONS(CasaRecord)

/* ----------------------------------------------------------------*/

// Implementation file for the acsVLAfiller class
//
