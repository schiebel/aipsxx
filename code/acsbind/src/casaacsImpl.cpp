
#include <vltPort.h>
#include <maciACSComponentDefines.h>
#include <maciContainerImpl.h>
#include <acscomponentImpl.h>
#include <casadefsC.h>
#include <casadefsS.h>
#include <baciROdouble.h>
#include <acsncSimpleSupplier.h>

NAMESPACE_USE(baci);

namespace casa_wrappers {
   CASA::CasaRecord *newAR();
}

CASA::CasaRecord *casa_wrappers::newAR(){
  static int recCount = 0;
  ComponentSpec_var cSpec = new ComponentSpec();    //use _var type for automatic memory management
#include <sstream>
  std::ostringstream  aRecName;
  aRecName << "aRecord:" << ++recCount;
  cSpec->component_name = CORBA::string_dup(aRecName.str().data());
  cSpec->component_type = CORBA::string_dup("IDL:alma/CASA/CasaRecord:1.0");    //IDL interface implemented by the component
  cSpec->component_code = CORBA::string_dup("casadefs");     //executable code for the component (e.g. DLL)
  cSpec->container_name = CORBA::string_dup("cppProtopipe");     //container where the component is deployed
                                    
        //The IDL ComponentInfo structure returned by the get_dynamic_component method
        //contains tons of information about the newly created component and the most important
        //field is "reference" (i.e., the unnarrowed dynamic component).
  ComponentInfo_var cInfo  = ContainerImpl::getContainer()->getManager()->get_dynamic_component(ContainerImpl::getContainer()->getHandle(),    //Must pass the client's handle
                                                                          cSpec.in(),    //Pass the component specifications
                                                                                                                                                 false);    //Inform manager this component is NOT the default for it's type!                                                                               
  //As always, the reference must be CORBA casted to it's correct type.

  CASA::CasaRecord_var theRecord = CASA::CasaRecord::_narrow(cInfo->reference.in());

  return theRecord._retn();
}
