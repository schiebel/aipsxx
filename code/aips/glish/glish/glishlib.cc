// $Id: glishlib.cc,v 19.14 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000,2004 Associated Universities Inc.

#include "config.h"
#include "Glish/glish.h"
RCSID("@(#) $Id: glishlib.cc,v 19.14 2004/11/03 20:38:59 cvsmgr Exp $")

#include "Glish/Value.h"
#include "Glish/Reporter.h"
#include "glishlib.h"
#include "system.h"

class sos_out;
class sos_header;
class ProxyId;

#if defined(__alpha) || defined(__alpha__)
extern "C" int glish_abort_on_fpe( );
int glish_sigfpe_trap = 0;
int glish_alpha_sigfpe_init = 0;
#endif

//
// this macro is currently NOT USED
//
#define COPY_VECREF(tag,type,accessor,COPY,CLEANUP)			\
	case tag:							\
		{							\
		int len = value->Length( );				\
		type *ptr = value->accessor(0);				\
		type *cvec = (type*) alloc_##type( len );		\
		VecRef *ref = value->VecRefPtr( );			\
									\
		for ( int i = 0; i < len; ++i )				\
			{						\
			int erri = 0;					\
			int index = ref->TranslateIndex( i, &erri );	\
			if ( erri )					\
				{					\
				CLEANUP					\
				free_memory( cvec );			\
				return (Value*) ValCtor::error( "invalid sub-vector" ); \
				}					\
			cvec[i] = COPY(ptr[index]);			\
			}						\
									\
		copy = new Value( cvec, len );				\
		copy->CopyAttributes( value );				\
		}							\
		break;

