#ifndef _VLAFILLER_IMPL_H
#define _VLAFILLER_IMPL_H
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
* "@(#) $Id: vlafillerImpl.h,v 1.5 2005/04/28 04:04:55 ddebonis Exp $"
*
* who       when      what
* --------  --------  ----------------------------------------------
* bjeram  2004-09-17  created
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

class vlafillerImpl: public parameterTask 
			    
{    
  public:
    vlafillerImpl(const ACE_CString& name,
                  maci::ContainerServices* containerServices);
    virtual ~vlafillerImpl();
    
    virtual void go(ParameterSet& pset);
};

#endif /*!_H*/
