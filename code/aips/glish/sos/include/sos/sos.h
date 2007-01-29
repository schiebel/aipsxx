/*======================================================================
** sos/sos.h
**
** $Id: sos.h,v 19.0 2003/07/16 05:17:39 aips2adm Exp $
**
** Copyright (c) 1997,2000 Associated Universities Inc.
**
**======================================================================
*/
#ifndef sos_sos_h
#define sos_sos_h
#include "sos/alloc.h"
typedef unsigned char byte;

/*
** Force insertion of rcsid
*/
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
#define RCSID(str)                      \
        static const char *rcsid_ = str;      \
        UsE(rcsid_)
#else
#define RCSID(str)
#endif
#endif

#endif
