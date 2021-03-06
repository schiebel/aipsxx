//# HostInfo.h: Information about the host that this process is running on.
//# Copyright (C) 1997-2006
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: HostInfo.cc,v 19.9 2006/05/22 05:11:40 mcalabre Exp $

#include <casa/BasicSL/String.h>
#include <casa/OS/HostInfo.h>
#include <casa/Utilities/Assert.h>

#include <unistd.h>
#include <sys/utsname.h>

// Time related includes
#if defined(AIPS_SOLARIS) || defined(_AIX) || defined(AIPS_IRIX) || defined(AIPS_DARWIN)
#include <sys/time.h>
#elif defined(AIPS_OSF)
#include <sys/timers.h>
#else
#include <sys/timeb.h>
#endif

#if defined(AIPS_SOLARIS) && !defined(__CLCC__)
extern "C" { int gettimeofday(struct timeval *tp, void*); };
#endif
#if defined(AIPS_OSF)
extern "C" { int getclock(int clock_type, struct timespec* tp); };
#endif

namespace casa { //# NAMESPACE CASA - BEGIN

String HostInfo::hostName()
{
    String retval;
#if defined(AIPS_IRIX)
      // This is a kludge to get around a problem with
      // losing environment variable names on some IRIX machines
      // at NCSA in Urbana IL.
    Char buf[65];
    if (gethostname(buf, 64) >= 0) {
	retval = String(buf);
    }
#else
    struct utsname name;
    if (uname(&name) >= 0) {
	retval = name.nodename;
    }
#endif
    return retval;
}

Int HostInfo::processID()
{
    return getpid();
}


#if defined(AIPS_SOLARIS) && defined(__CLCC__)
Double HostInfo::secondsFrom1970()
{
    struct timeval  tp;
    AlwaysAssert(gettimeofday(&tp) >= 0, AipsError);
    double total = tp.tv_sec;
    total += tp.tv_usec * 0.000001;
    return total;
}
#elif defined(AIPS_SOLARIS) || defined(_AIX) || defined(AIPS_IRIX) || defined(AIPS_DARWIN)
Double HostInfo::secondsFrom1970()
{
    struct timeval  tp;
    struct timezone tz;
    tz.tz_minuteswest = 0;
    AlwaysAssert(gettimeofday(&tp, &tz) >= 0, AipsError);
    double total = tp.tv_sec;
    total += tp.tv_usec * 0.000001;
    return total;
}
#elif defined(AIPS_OSF)
Double HostInfo::secondsFrom1970()
{
  struct timespec tp;
  AlwaysAssert(getclock(TIMEOFDAY,&tp) == 0, AipsError);
  double total = tp.tv_sec;
  total += tp.tv_nsec * 1.e-9;
  return total;
}
#else
Double HostInfo::secondsFrom1970()
{
    struct timeb ftm;
    AlwaysAssert(ftime(&ftm) >= 0, AipsError);
    double total = ftm.time;
    total += ftm.millitm*0.001;
    return total;
}
#endif

#define HOSTINFO_IMPLEMENT_MEMBERS			\
Int HostInfo::numCPUs( )				\
{							\
    if ( ! info ) info = new HostMachineInfo( );	\
    return info->valid ? info->cpus : 0;		\
}							\
							\
Int HostInfo::memoryTotal( ) 				\
{							\
    if ( ! info ) info = new HostMachineInfo( );	\
    return info->valid ? info->memory_total : -1;	\
}							\
							\
Int HostInfo::memoryUsed( )				\
{							\
    if ( ! info ) info = new HostMachineInfo( );	\
    info->update_info( );				\
    return info->valid ? info->memory_used : -1;	\
}							\
							\
Int HostInfo::memoryFree( )				\
{							\
    if ( ! info ) info = new HostMachineInfo( );	\
    info->update_info( );				\
    return info->valid ? info->memory_free : -1;	\
}							\
							\
Int HostInfo::swapTotal( )				\
{							\
    if ( ! info ) info = new HostMachineInfo( );	\
    info->update_info( );				\
    return info->valid ? info->swap_total : -1;		\
}							\
							\
int HostInfo::swapUsed( )				\
{							\
    if ( ! info ) info = new HostMachineInfo( );	\
    info->update_info( );				\
    return info->valid ? info->swap_used : -1;		\
}							\
							\
int HostInfo::swapFree( )				\
{							\
    if ( ! info ) info = new HostMachineInfo( );	\
    info->update_info( );				\
    return info->valid ? info->swap_free : -1;		\
}


} //# NAMESPACE CASA - END

#define HOSTINFO_DO_IMPLEMENT
#if defined(AIPS_LINUX)
#include <casa/OS/HostInfoLinux.h>
namespace casa { //# NAMESPACE CASA - BEGIN

HOSTINFO_IMPLEMENT_MEMBERS
} //# NAMESPACE CASA - END

#elif defined(AIPS_SOLARIS)
#include <casa/OS/HostInfoSolaris.h>
namespace casa { //# NAMESPACE CASA - BEGIN

HOSTINFO_IMPLEMENT_MEMBERS
} //# NAMESPACE CASA - END

#elif defined(AIPS_IRIX)
#include <casa/OS/HostInfoIrix.h>
HOSTINFO_IMPLEMENT_MEMBERS
} //# NAMESPACE CASA - END

#elif defined(AIPS_OSF)
#include <casa/OS/HostInfoOsf1.h>
namespace casa { //# NAMESPACE CASA - BEGIN

HOSTINFO_IMPLEMENT_MEMBERS
} //# NAMESPACE CASA - END

#elif defined(AIPS_HPUX)
#include <casa/OS/HostInfoHpux.h>
namespace casa { //# NAMESPACE CASA - BEGIN

HOSTINFO_IMPLEMENT_MEMBERS
} //# NAMESPACE CASA - END

#elif defined(__APPLE__)
#include <casa/OS/HostInfoDarwin.h>
namespace casa { //# NAMESPACE CASA - BEGIN

HOSTINFO_IMPLEMENT_MEMBERS
} //# NAMESPACE CASA - END

#else
namespace casa { //# NAMESPACE CASA - BEGIN

Int HostInfo::numCPUs( ) { return 0; }
Int HostInfo::memoryTotal( ) { return -1; }
Int HostInfo::memoryUsed( ) { return -1; }
Int HostInfo::memoryFree( ) { return -1; }
Int HostInfo::swapTotal( ) { return -1; }
int HostInfo::swapUsed( ) { return -1; }
int HostInfo::swapFree( ) { return -1; }

} //# NAMESPACE CASA - END

#endif

namespace casa { //# NAMESPACE CASA - BEGIN

HostMachineInfo *HostInfo::info = 0;

} //# NAMESPACE CASA - END
