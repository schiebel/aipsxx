
// -----------------------------------------------------------------------------

/*

Cuttlefish.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the include information for the Cuttlefish.cc file.

Modification history:
---------------------
1999 Jan 28 - Nicholas Elias, USNO/NPOI
              Function created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_CUTTLEFISH_H
#define NPOI_CUTTLEFISH_H


// Includes

#include <casa/aips.h>                 // aips++
#include <tasking/Tasking.h>             // aips++ tasking

#include "DelayJitterFactory.h"        // aips++ DelayJitter factory
#include "DryDelayFactory.h"           // aips++ DryDelayJitter factory
#include "FDLPosFactory.h"             // aips++ FDLPos factory
#include "GeoParmsFactory.h"           // aips++ GeoParms factory
#include "GrpDelayFactory.h"           // aips++ GrpDelayJitter factory
#include "IBConfigFactory.h"           // aips++ IBConfig factory
#include "LogInfoFactory.h"            // aips++ LogInfo factory
#include "NATJitterFactory.h"          // aips++ NatJitter factory
#include "OBConfigFactory.h"           // aips++ OBConfig factory
#include "ScanInfoFactory.h"           // aips++ ScanInfo factory
#include "SysConfigFactory.h"          // aips++ SysConfig factory
#include "WetDelayFactory.h"           // aips++ WetDelayJitter factory

#include <npoi/Cuttlefish/DelayJitter.h> // DelayJitter
#include <npoi/Cuttlefish/DryDelay.h>    // DryDelay
#include <npoi/Cuttlefish/FDLPos.h>      // FDLPos
#include <npoi/Cuttlefish/GeoParms.h>    // GeoParms
#include <npoi/Cuttlefish/GrpDelay.h>    // GrpDelay
#include <npoi/Cuttlefish/IBConfig.h>    // IBConfig
#include <npoi/Cuttlefish/LogInfo.h>     // LogInfo
#include <npoi/Cuttlefish/NATJitter.h>   // NATJitter
#include <npoi/Cuttlefish/OBConfig.h>    // OBConfig
#include <npoi/Cuttlefish/ScanInfo.h>    // ScanInfo
#include <npoi/Cuttlefish/SysConfig.h>   // SysConfig
#include <npoi/Cuttlefish/WetDelay.h>    // WetDelay


#include <casa/namespace.h>
// #endif (Include file?)

#endif // __CUTTLEFISH_H

