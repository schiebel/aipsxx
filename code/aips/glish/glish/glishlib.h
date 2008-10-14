// $Id: glishlib.h,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998 Associated Universities Inc.
#ifndef glishlib_h
#define glishlib_h
#include "Glish/glish.h"

extern int glish_abort_on_fpe;
extern int glish_sigfpe_trap;
#if defined(__alpha) || defined(__alpha__) || 1
#define glish_fpe_enter()	glish_abort_on_fpe = glish_sigfpe_trap = 0;
#define glish_fpe_exit()	((glish_abort_on_fpe = 1) && glish_sigfpe_trap)
#else
#define glish_fpe_enter()
#define glish_fpe_exit()	0
#endif

#endif	/* glishlib_h */
