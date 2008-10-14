/*======================================================================
** gcmem/alloc.h
**
** $Id: alloc.h,v 19.0 2003/07/16 05:17:13 aips2adm Exp $
**
** Copyright (c) 1997 Associated Universities Inc.
**
**======================================================================
*/
#ifndef gcmem_gcmem_h
#define gcmem_gcmem_h
#include <string.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>

#if defined(ENABLE_GC)
#if defined(__cplusplus)
#include "gcmem/gc_cpp.h"
#else
#include "gcmem/gc.h"
#endif
#endif

/*
** Force insertion of rcsid
*/
#if ! defined(RCSID)
#if ! defined(NO_RCSID)
#if defined(__STDC__) || defined(__ANSI_CPP__) || defined(__hpux)
#define UsE_PaStE(b) UsE__##b##_
#define PASTE(a,b) a##b
#else
#define UsE_PaStE(b) UsE__/**/b/**/_
#define PASTE(a,b) a/**/b
#endif
#if defined(__cplusplus)
#define UsE(x) inline void UsE_PaStE(x)(char *) { UsE_PaStE(x)(x); }
#else
#define UsE(x) static void UsE_PaStE(x)(char *d) { UsE_PaStE(x)(x); }
#endif
#define RCSID(str)                      \
        static char *rcsid_ = str;      \
        UsE(rcsid_)
#else
#define RCSID(str)
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

#if defined(ENABLE_GC)
#define alloc_memory( size ) GC_malloc( (size) )
#define alloc_memory_atomic( size ) GC_malloc_atomic( (size) )
#define realloc_memory( ptr, new_size ) GC_realloc( (ptr), (new_size) )
#define alloc_zero_memory( size ) alloc_memory( (size) )
#define alloc_zero_memory_atomic( size ) alloc_memory_atomic( (size) )
#define free_memory( ptr )

#define alloc_memory_func GC_malloc
#define alloc_memory_atomic_func GC_malloc_atomic

#define GC_FINAL_CLASS		: public gc_cleanup
#define GC_FREE_CLASS		: public gc

#define hold_garbage( )		++GC_dont_gc
#define release_garbage( )	--GC_dont_gc

char *string_dup( const char *str );

/*
** dump collector state information
*/
void GC_dump();

/*
** tries to do garbage while waiting for some activity
*/
int  gc_select(int /*n*/, fd_set */*readfds*/,  fd_set  */*writefds*/,
	       fd_set */*exceptfds*/, struct timeval */*timeout*/);
#else
#ifdef __cplusplus
extern "C" {
#endif
	void *npd_malloc( size_t );
	void npd_free( void * );
#ifdef __cplusplus
	}
#endif

#define alloc_memory( size ) npd_malloc( (size) )
#define alloc_memory_atomic( size ) npd_malloc( (size) )
#define realloc_memory( ptr, new_size ) realloc( (ptr), (new_size) )
#define alloc_zero_memory( size ) calloc( (size), 1 )
#define alloc_zero_memory_atomic( size ) calloc( (size), 1 )
#define free_memory( ptr ) npd_free( (ptr) )

#define alloc_memory_func npd_malloc
#define alloc_memory_atomic_func npd_malloc

#define GC_FINAL_CLASS
#define GC_FREE_CLASS

#define hold_garbage( )
#define release_garbage( )

#define string_dup( str ) strdup( (str) )
#define gc_select( n, readfds, writefds, exceptfds, timeout )	\
		select( (n), (readfds), (writefds), (exceptfds), (timeout) )
#endif

#define alloc_char( num ) (char*) alloc_memory_atomic( sizeof(char) * (num) )
#define alloc_charptr( num ) (char**) alloc_memory( sizeof(char*) * (num) )
#define alloc_short( num ) (short*) alloc_memory_atomic( sizeof(short) * (num) )
#define alloc_shortptr( num ) (short**) alloc_memory( sizeof(short*) * (num) )
#define alloc_int( num ) (int*) alloc_memory_atomic( sizeof(int) * (num) )
#define alloc_intptr( num ) (int**) alloc_memory( sizeof(int*) * (num) )
#define alloc_long( num ) (long*) alloc_memory_atomic( sizeof(long) * (num) )
#define alloc_longptr( num ) (long**) alloc_memory( sizeof(long*) * (num) )
#define alloc_float( num ) (float*) alloc_memory_atomic( sizeof(float) * (num) )
#define alloc_floatptr( num ) (float**) alloc_memory( sizeof(float*) * (num) )
#define alloc_double( num ) (double*) alloc_memory_atomic( sizeof(double) * (num) )
#define alloc_doubleptr( num ) (doublet**) alloc_memory( sizeof(double*) * (num) )

#define realloc_char( ptr, num ) (char*) realloc_memory( ptr, sizeof(char) * (num) )
#define realloc_charptr( ptr, num ) (char**) realloc_memory( ptr, sizeof(char*) * (num) )
#define realloc_short( ptr, num ) (short*) realloc_memory( ptr, sizeof(short) * (num) )
#define realloc_shortptr( ptr, num ) (short**) realloc_memory( ptr, sizeof(short*) * (num) )
#define realloc_int( ptr, num ) (int*) realloc_memory( ptr, sizeof(int) * (num) )
#define realloc_intptr( ptr, num ) (int**) realloc_memory( ptr, sizeof(int*) * (num) )
#define realloc_long( ptr, num ) (long*) realloc_memory( ptr, sizeof(long) * (num) )
#define realloc_longptr( ptr, num ) (long**) realloc_memory( ptr, sizeof(long*) * (num) )
#define realloc_float( ptr, num ) (float*) realloc_memory( ptr, sizeof(float) * (num) )
#define realloc_floatptr( ptr, num ) (float**) realloc_memory( ptr, sizeof(float*) * (num) )
#define realloc_double( ptr, num ) (double*) realloc_memory( ptr, sizeof(double) * (num) )
#define realloc_doubleptr( ptr, num ) (doublet**) realloc_memory( ptr, sizeof(double*) * (num) )

#ifdef __cplusplus
	}
#endif

#endif
