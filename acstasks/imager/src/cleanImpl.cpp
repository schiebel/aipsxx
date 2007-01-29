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
* "@(#) $Id: cleanImpl.cpp,v 1.10 2005/05/13 18:56:04 ddebonis Exp $"
*
* who       when      what
* --------  --------  ----------------------------------------------
* ddebonis  2005-03-14  created 
*/

#include <cleanImpl.h>
#include "taskErrType.h"
#include "ParameterSet.h"
#include "psetConverter.h"
#include <iostream>

#include <synthesis/MeasurementEquations/ImagerTask.h>
#include <casa/namespace.h>

/* ----------------------------------------------------------------*/
cleanImpl::cleanImpl(const ACE_CString &name,
                     maci::ContainerServices *containerServices)
  : acscomponent::ACSComponentImpl(name, containerServices),
    parameterTask(name, containerServices)
{
    ACS_TRACE("::cleanImpl::cleanImpl");
}
/* ----------------------------------------------------------------*/
cleanImpl::~cleanImpl()
{
    ACS_TRACE("::cleanImpl::~cleanImpl");
    ACS_DEBUG_PARAM("::cleanImpl::~cleanImpl", "Destroying %s...", name());
}
/* --------------------- [ CORBA interface ] ----------------------*/
void cleanImpl::go(ParameterSet& tpset)
{
   ImagerTask task;
   psetConverter converter(tpset);
   
   task.setParams(converter.getRecord());
   task.clean();
}

/* --------------- [ MACI DLL support functions ] -----------------*/
#include <maciACSComponentDefines.h>
//#define ACS_DLL_UNMANGLED_EXPORT extern;
MACI_DLL_SUPPORT_FUNCTIONS(cleanImpl)
/* ----------------------------------------------------------------*/


/*___oOo___*/
