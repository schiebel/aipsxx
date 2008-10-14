//======================================================================
// longint.cc
//
// $Id: longint.cc,v 19.1 2004/07/13 22:37:02 dschieb Exp $
//
// Copyright (c) 1997 Associated Universities Inc.
//
//======================================================================
#include "sos/sos.h"
RCSID("@(#) $Id: longint.cc,v 19.1 2004/07/13 22:37:02 dschieb Exp $")
#include "config.h"
#include "longint.h"
#include <stdio.h>

int sos_big_endian = 1;
int long_int::LOW = 0;
int long_int::HIGH = 1;

int long_int_init::initialized = 0;

long_int_init::long_int_init()
	{
	if ( ! initialized )
		{
		//
		// are we dealing with little endian, e.g. alpha, pc, etc.
		//
		union { long l;
			char c[sizeof (long)];
		} u;
		u.l = 1;

		if ( u.c[sizeof (long) - 1] != 1 )
			{
			long_int::LOW = 1;
			long_int::HIGH = 0;
			sos_big_endian = 0;
			}
		initialized = 1;
		}
        }

std::ostream &operator<<(std::ostream &ios, const long_int &li)
	{
	static char buf[32];
	sprintf(buf,"0x%08x%08x",li[1],li[0]);
	ios << buf;
	return ios;
	}
