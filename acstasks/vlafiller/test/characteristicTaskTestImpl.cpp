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
* "@(#) $Id: characteristicTaskTestImpl.cpp,v 1.1.1.1 2005/01/21 04:14:19 wyoung Exp $"
*
* who       when      what
* --------  --------  ----------------------------------------------
* bjeram  2004-09-17  created 
*/

#include <characteristicTaskTestImpl.h>
#include "taskErrType.h"
#include <iostream>

/* ----------------------------------------------------------------*/
CharacteristicTaskTestImpl::CharacteristicTaskTestImpl(PortableServer::POA_ptr poa, const ACE_CString &name) :
    baci::CharacteristicComponentImpl(poa, name)
{
    ACS_TRACE("::CharacteristicTaskTestImpl::CharacteristicTaskTestImpl");
}
/* ----------------------------------------------------------------*/
CharacteristicTaskTestImpl::~CharacteristicTaskTestImpl()
{
    ACS_TRACE("::CharacteristicTaskTestImpl::~CharacteristicTaskTestImpl");
    ACS_DEBUG_PARAM("::CharacteristicTaskTestImpl::~CharacteristicTaskTestImpl", "Destroying %s...", name());
}
/* --------------------- [ CORBA interface ] ----------------------*/
void
CharacteristicTaskTestImpl::run (const char* s)
    throw (CORBA::SystemException, taskErrType::TaskRunFailureEx)
{
    if (strcmp(s, "throw") == 0)
	throw taskErrType::TaskRunFailureExImpl(__FILE__, __LINE__, "CharacteristicTaskTestImpl::run").getTaskRunFailureEx();
    std::cout << s << std::endl; 
}


/* --------------- [ MACI DLL support functions ] -----------------*/
#include <maciACSComponentDefines.h>
//#define ACS_DLL_UNMANGLED_EXPORT extern;
MACI_DLL_SUPPORT_FUNCTIONS(CharacteristicTaskTestImpl)
/* ----------------------------------------------------------------*/


/*___oOo___*/
