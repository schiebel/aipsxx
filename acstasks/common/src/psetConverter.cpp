/*******************************************************************************
* ALMA - Atacama Large Millimiter Array
* (c) European Southern Observatory, 2004 
*
*This library is free software; you can redistribute it and/or
*modify it under the terms of the GNU Lesser General Public
*License as published by the Free Software Foundation; either
*version 2.1 of the License, or (at your option) any later version.
*
*This library is distributed in the hope that it will be useful,
*but WITHOUT ANY WARRANTY; without even the implied warranty of
*MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
*Lesser General Public License for more details.
*
*You should have received a copy of the GNU Lesser General Public
*License along with this library; if not, write to the Free Software
*Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
*
* "@(#) $"
*
* who       when      what
* --------  --------  ----------------------------------------------
* ddebonis  2005-03-23  created 
*/

#include <psetConverter.h>
#include <iostream>

#include <casa/Containers/RecordField.h>
#include <casa/namespace.h>

using namespace parameterSet;

psetConverter::psetConverter(ParameterSet &paramSet)
 : tpset(paramSet)
{
   createRecord();
}

void psetConverter::setBoolParam(const String &name)
{
   RecordFieldPtr<Bool> param(pset, RecordFieldId(name));
   param.define((tpset.getBoolParam(name)).getValue());
}

void psetConverter::setIntParam(const String &name)
{
   RecordFieldPtr<Int> param(pset, RecordFieldId(name));
   param.define((tpset.getIntParam(name)).getValue());
}

void psetConverter::setDoubleParam(const String &name)
{
   RecordFieldPtr<Double> param(pset, RecordFieldId(name));
   param.define((tpset.getDoubleParam(name)).getValue());
}

void psetConverter::setStringParam(const String &name)
{
   RecordFieldPtr<String> param(pset, RecordFieldId(name));
   param.define((tpset.getStringParam(name)).getValue());
}

void psetConverter::setIntArrayParam(const String &name)
{
   RecordFieldPtr< Array<Int> > param(pset, RecordFieldId(name));
   vector<int> v((tpset.getIntArrayParam(name)).getValues());
   Array<Int> a(IPosition(1, v.size()));

   for(uInt i=0; i<v.size(); i++)
      a(IPosition(1, i)) = v[i];

   param.define(a);
}

void psetConverter::setDoubleArrayParam(const String &name)
{
   RecordFieldPtr< Array<Double> > param(pset, RecordFieldId(name));
   vector<double> v((tpset.getDoubleArrayParam(name)).getValues());
   Array<Double> a(IPosition(1, v.size()));

   for(uInt i=0; i<v.size(); i++)
      a(IPosition(1, i)) = v[i];

   param.define(a);
}

void psetConverter::setStringArrayParam(const String &name)
{
   RecordFieldPtr< Array<String> > param(pset, RecordFieldId(name));
   vector<string> v((tpset.getStringArrayParam(name)).getValues());
   Array<String> a(IPosition(1, v.size()));

   for(uInt i=0; i<v.size(); i++)
      a(IPosition(1, i)) = v[i];

   param.define(a);
}

void psetConverter::createRecord()
{
   uInt i;
   RecordDesc recordDesc;
   ParamSetDef *psetdef = tpset.getParamSetDef();

   // get all the bool params for this psetdef
   auto_ptr< vector<BoolParamDef> > boolParams
      = psetdef->getBoolParamDefs();
   for (i=0; i<boolParams->size(); i++)
      recordDesc.addField(boolParams->operator[](i).getName(), TpBool);

   // get all the int param defs for this psetdef
   auto_ptr< vector<IntParamDef> > intParams
      = psetdef->getIntParamDefs();
   for (i=0; i<intParams->size(); i++)
      recordDesc.addField(intParams->operator[](i).getName(), TpInt);

   // get all the string param defs for this psetdef
   auto_ptr< vector<StringParamDef> > stringParams
      = psetdef->getStringParamDefs();
   for (i=0; i<stringParams->size(); i++)
      recordDesc.addField(stringParams->operator[](i).getName(), TpString);

   // get all the double param defs for this psetdef
   auto_ptr< vector<DoubleParamDef> > doubleParams
      = psetdef->getDoubleParamDefs();
   for (i=0; i<doubleParams->size(); i++)
      recordDesc.addField(doubleParams->operator[](i).getName(), TpDouble);

   // get all the int array param defs for this psetdef
   auto_ptr< vector<IntArrayParamDef> > intArrayParams
      = psetdef->getIntArrayParamDefs();
   for (i=0; i<intArrayParams->size(); i++)
      recordDesc.addField(intArrayParams->operator[](i).getName(), TpArrayInt);

   // get all the double array param defs for this psetdef
   auto_ptr< vector<DoubleArrayParamDef> > doubleArrayParams
      = psetdef->getDoubleArrayParamDefs();
   for (i=0; i<doubleArrayParams->size(); i++)
      recordDesc.addField(doubleArrayParams->operator[](i).getName(), TpArrayDouble);

   // get all the string array param defs for this psetdef
   auto_ptr< vector<StringArrayParamDef> > stringArrayParams
      = psetdef->getStringArrayParamDefs();
   for (i=0; i<stringArrayParams->size(); i++)
      recordDesc.addField(stringArrayParams->operator[](i).getName(), TpArrayString);

   pset = Record(recordDesc);

   try {

      // set all the bool params for this pset
      for (i=0; i<boolParams->size(); i++)
         setBoolParam(boolParams->operator[](i).getName());

      // set all the int param defs for this pset
      for (i=0; i<intParams->size(); i++)
         setIntParam(intParams->operator[](i).getName());

      // set all the string param defs for this pset
      for (i=0; i<stringParams->size(); i++)
         setStringParam(stringParams->operator[](i).getName());

      // set all the double param defs for this pset
      for (i=0; i<doubleParams->size(); i++)
         setDoubleParam(doubleParams->operator[](i).getName());

      // set all the int array param defs for this pset
      for (i=0; i<intArrayParams->size(); i++)
         setIntArrayParam(intArrayParams->operator[](i).getName());

      // set all the double array param defs for this pset
      for (i=0; i<doubleArrayParams->size(); i++)
         setDoubleArrayParam(doubleArrayParams->operator[](i).getName());

      // set all the string array param defs for this pset
      for (i=0; i<stringArrayParams->size(); i++)
         setStringArrayParam(stringArrayParams->operator[](i).getName());

   } catch(std::domain_error exObj) {
        // NOTE: the error handling here is just for testing.
        // In the actual implementation you would not use cout,
        // but would instead probably rethrow a CORBA exception
        // (e.g. taskErrType::TaskRunFailureEx) with the details
        // of the local exception added.
        std::cout << "Exception caught!" <<  std::endl << exObj.what() << std::endl << std::endl;
        std::cout << std::endl;
        std::cout.flush();
   } catch(...) {
     std::cerr << "Something really bad has happened" << endl;
   }
}
