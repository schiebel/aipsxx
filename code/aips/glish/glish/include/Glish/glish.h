/* $Id: glish.h,v 19.1 2004/07/13 22:37:01 dschieb Exp $
** Copyright (c) 1993 The Regents of the University of California.
** Copyright (c) 1997,2000 Associated Universities Inc.
*/
#ifndef glish_h
#define glish_h

// Different types of values: constant references, references, and
// ordinary (non-indirect) values.
typedef enum { VAL_CONST, VAL_REF, VAL_VAL } value_reftype;

// Different types of storage for an array used to construct a Value.
typedef enum {
	COPY_ARRAY,		// copy the array
	TAKE_OVER_ARRAY,	// use the array, delete it when done with it
	PRESERVE_ARRAY		// use the array, don't delete it or grow it
	} array_storage_type;

/*
** use the allocation routines declared here
*/
#include "sos/alloc.h"
#include "sos/generic.h"
#define glish_name2		sos_name2
#define glish_name3		sos_name3
#define glish_name4		sos_name4
#define glish_declare		sos_declare
#define glish_declare2		sos_declare2
#define glish_implement		sos_implement
#define glish_implement2	sos_implement2

typedef enum { glish_false, glish_true } glish_bool;

typedef unsigned char byte;

#define alloc_glish_bool( num ) (glish_bool*) alloc_memory_atomic( sizeof(glish_bool) * num )
#define alloc_glish_boolptr( num ) (glish_bool**) alloc_memory( sizeof(glish_bool*) * num )
#define alloc_byte( num ) (byte*) alloc_memory_atomic( sizeof(byte) * num )
#define alloc_byteptr( num ) (byte**) alloc_memory( sizeof(byte*) * num )

#define realloc_glish_bool( ptr, num ) (glish_bool*) realloc_memory( ptr, sizeof(glish_bool) * num )
#define realloc_glish_boolptr( ptr, num ) (glish_bool**) realloc_memory( ptr, sizeof(glish_bool*) * num )
#define realloc_byte( ptr, num ) (byte*) realloc_memory( ptr, sizeof(byte) * num )
#define realloc_byteptr( ptr, num ) (byte**) realloc_memory( ptr, sizeof(byte*) * num )


#define loop_over_list(list, iterator)	\
	for ( int iterator = 0; iterator < (list).length(); ++iterator )
#define loop_over_list_nodecl(list, iterator)	\
	for ( iterator = 0; iterator < (list).length(); ++iterator )

typedef void (*glish_signal_handler)( );

#if ! defined(DIAG) && defined(__cplusplus)
#if defined(DO_DIAG)
#include "Glish/Reporter.h"
#define DiAg_LiSt_hdn2(w,x) w,x
#define DiAg_LiSt_hdn3(w,x,y) w,x,y
#define DiAg_LiSt_hdn4(w,x,y,z) w,x,y,z
#define DiAg_LiSt_hdn5(w,x,y,z,a) w,x,y,z,a
#define DiAg_LiSt_hdn6(w,x,y,z,a,b) w,x,y,z,a,b
#define DiAg_LiSt_hdn7(w,x,y,z,a,b,c) w,x,y,z,a,b,c
#define DiAg_LiSt_hdn8(w,x,y,z,a,b,c,d) w,x,y,z,a,b,c,d
#define DiAg_LiSt_hdn9(w,x,y,z,a,b,c,d,e) w,x,y,z,a,b,c,d,e
#define DiAg_LiSt_hdn10(w,x,y,z,a,b,c,d,e,f) w,x,y,z,a,b,c,d,e,f
#define DiAg_LiSt_hdn11(w,x,y,z,a,b,c,d,e,f,g) w,x,y,z,a,b,c,d,e,f,g
#define DiAg_LiSt_hdn12(w,x,y,z,a,b,c,d,e,f,g,h) w,x,y,z,a,b,c,d,e,f,g,h
#define DIAG(MESSAGE) message->Report(MESSAGE,": ", __FILE__, ", ", __LINE__);
#define DIAG2(w,x) DIAG(DiAg_LiSt_hdn2(w,x))
#define DIAG3(w,x,y) DIAG(DiAg_LiSt_hdn3(w,x,y))
#define DIAG4(w,x,y,z) DIAG(DiAg_LiSt_hdn4(w,x,y,z))
#define DIAG5(w,x,y,z,a) DIAG(DiAg_LiSt_hdn5(w,x,y,z,a))
#define DIAG6(w,x,y,z,a,b) DIAG(DiAg_LiSt_hdn6(w,x,y,z,a,b))
#define DIAG7(w,x,y,z,a,b,c) DIAG(DiAg_LiSt_hdn7(w,x,y,z,a,b,c))
#define DIAG8(w,x,y,z,a,b,c,d) DIAG(DiAg_LiSt_hdn8(w,x,y,z,a,b,c,d))
#define DIAG9(w,x,y,z,a,b,c,d,e) DIAG(DiAg_LiSt_hdn9(w,x,y,z,a,b,c,d,e))
#define DIAG10(w,x,y,z,a,b,c,d,e,f) DIAG(DiAg_LiSt_hdn10(w,x,y,z,a,b,c,d,e,f))
#define DIAG11(w,x,y,z,a,b,c,d,e,f,g) DIAG(DiAg_LiSt_hdn11(w,x,y,z,a,b,c,d,e,f,g))
#define DIAG12(w,x,y,z,a,b,c,d,e,f,g,h) DIAG(DiAg_LiSt_hdn9(w,x,y,z,a,b,c,d,e,f,g,h))
#else
#define DIAG(MESSAGE)
#define DIAG2(w,x)
#define DIAG3(w,x,y)
#define DIAG4(w,x,y,z)
#define DIAG5(w,x,y,z,a)
#define DIAG6(w,x,y,z,a,b)
#define DIAG7(w,x,y,z,a,b,c)
#define DIAG8(w,x,y,z,a,b,c,d)
#define DIAG9(w,x,y,z,a,b,c,d,e)
#define DIAG10(w,x,y,z,a,b,c,d,e,f)
#define DIAG11(w,x,y,z,a,b,c,d,e,f,g)
#define DIAG12(w,x,y,z,a,b,c,d,e,f,g,h)
#endif
#endif

#if defined(__STDC__) || defined(__ANSI_CPP__) || defined(__hpux)
#define UsE_PaStE(b) UsE__##b##_
#define PASTE(a,b) a##b
#else
#define UsE_PaStE(b) UsE__/**/b/**/_
#define PASTE(a,b) a/**/b
#endif
#if defined(__cplusplus)
#define UsE(x) inline void UsE_PaStE(x)(const char *) { UsE_PaStE(x)(x); }
#else
#define UsE(x) static void UsE_PaStE(x)(const char *d) { UsE_PaStE(x)(x); }
#endif

#if ! defined(RCSID)
#if ! defined(NO_RCSID)
#define RCSID(str)				\
	static const char *rcsid_ = str;	\
	UsE(rcsid_)
#else
#define RCSID(str)
#endif
#endif

#if defined(__cplusplus)
// Classes for subvector references.
class VecRef;
#define SubVecRef(type) glish_name2(type,SubVecRef)
class SubVecRef(glish_bool);
class SubVecRef(byte);
class SubVecRef(short);
class SubVecRef(int);
class SubVecRef(float);
class SubVecRef(double);
class SubVecRef(glish_complex);
class SubVecRef(glish_dcomplex);
class SubVecRef(charptr);

typedef SubVecRef(glish_bool) glish_boolref;
typedef SubVecRef(byte) byteref;
typedef SubVecRef(short) shortref;
typedef SubVecRef(int) intref;
typedef SubVecRef(float) floatref;
typedef SubVecRef(double) doubleref;
typedef SubVecRef(glish_complex) complexref;
typedef SubVecRef(glish_dcomplex) dcomplexref;
typedef SubVecRef(charptr) charptrref;
#endif

#endif
