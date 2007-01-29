/*    common.h
 *
 *    $Id: common.h,v 19.0 2003/07/16 05:17:58 aips2adm Exp $
 *    Copyright (c) 1991-1997, Larry Wall
 *    Copyright (c) 1998,1999 Associated Universities Inc.
 *
 *    Scavenged from Perl distribution needed for regex closure...
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#ifndef common_h_
#define common_h_

#include <ctype.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

#define EXT extern
#define I32 int
#define U32 unsigned int
#define U16 unsigned short
#define U8 unsigned char

typedef struct sv SV;
typedef struct regexp REGEXP;
typedef struct pmop PMOP;
typedef struct op OP;

#ifdef __cplusplus
	}
#endif

#include "regx/op.h"

#endif
