#ifndef _FEATHER_IMPL_H
#define _FEATHER_IMPL_H
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
* "@(#) $Id: featherImpl.h,v 1.3 2005/04/28 03:56:57 ddebonis Exp $"
*
* who       when      what
* --------  --------  ----------------------------------------------
* ddebonis  2005-03-14  created
*/

/************************************************************************
 *
 *----------------------------------------------------------------------
 */

#ifndef __cplusplus
#error This is a C++ include file and cannot be used from plain C
#endif

#include <parameterTask.h>

using ACS::parameterTask;

class featherImpl: public parameterTask 
{    
  public:
    featherImpl(const ACE_CString& name,
                maci::ContainerServices* containerServices);
    virtual ~featherImpl();
    
    virtual void go(ParameterSet& pset);
};

#endif /*!_H*/
