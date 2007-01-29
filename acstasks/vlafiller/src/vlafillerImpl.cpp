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
* "@(#) $Id: vlafillerImpl.cpp,v 1.15 2005/05/20 18:58:51 ddebonis Exp $"
*
* who       when      what
* --------  --------  ----------------------------------------------
* bjeram  2004-09-17  created 
*/

#include <vlafillerImpl.h>
#include "taskErrType.h"
#include "ParameterSet.h"
#include "psetConverter.h"
#include <iostream>

#include <nrao/VLA/VLAFillerTask.h>
#include <casa/namespace.h>

/* ----------------------------------------------------------------*/
vlafillerImpl::vlafillerImpl(const ACE_CString &name,
                             maci::ContainerServices* containerServices)
  : acscomponent::ACSComponentImpl(name, containerServices),
    parameterTask(name, containerServices)
{
    ACS_TRACE("::vlafillerImpl::vlafillerImpl");
}
/* ----------------------------------------------------------------*/
vlafillerImpl::~vlafillerImpl()
{
    ACS_TRACE("::vlafillerImpl::~vlafillerImpl");
    ACS_DEBUG_PARAM("::vlafillerImpl::~vlafillerImpl", "Destroying %s...", name());
}
/* --------------------- [ CORBA interface ] ----------------------*/
void
vlafillerImpl::go(ParameterSet& tpset)
{
   VLAFillerTask task;
   psetConverter converter(tpset);

   task.setParams(converter.getRecord());
   task.fill();
}

/* --------------- [ MACI DLL support functions ] -----------------*/
#include <maciACSComponentDefines.h>
//#define ACS_DLL_UNMANGLED_EXPORT extern;
MACI_DLL_SUPPORT_FUNCTIONS(vlafillerImpl)
/* ----------------------------------------------------------------*/

/*___oOo___*/
