//# if_full.h: structure for ACSIS IF data
//# Copyright (C) 1994,1995,1997,1998,1999,2001
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

#if !defined IF_FULL_H
#define IF_FULL_H   

#define DCM 32                  /* Size of DCMAddr              */ 
#define DCMP1 33                /* Size of DCMAddr + 1          */ 
#define CHARLEN 10              /* Size of DCM detector name */
#define CHARLEN1 16             /* for status types */

#include <casa/namespace.h>
typedef struct {
    double	SECOND_LO_FREQS[4];
    float 	DCM_TP_IN[DCM];
    float 	DCM_TP_OUT[DCM];
    float 	DCM_CFREQ[DCM];
    float 	DCM_TEMP[DCM];
    float 	INLET_TEMP[2];
    float 	EXHAUST_TEMP[2];
    unsigned long DCM_BW[DCM];
    unsigned long SEQ_NUM;
    unsigned char DCM_SN[DCM];
    unsigned char NSMYTH_SW[4];
    unsigned char CASS_SW[2];
    char 	DCM_DET_NAME[DCM][CHARLEN];
    char 	DCM_STATUS[DCMP1];
    char	SEQ_STATE[CHARLEN1];
    char 	STATUS[CHARLEN1];
} IF_MONITOR_DATA;

#endif  // if !defined IF_FULL_H 
