/*  $Id: editline.h,v 19.0 2003/07/16 05:17:03 aips2adm Exp $
**
**  Internal header file for editline library.
**
** Copyright (c) 1992,1993 Simmule Turner and Rich Salz.  All rights reserved.
** Copyright (c) 1997 Associated Universities Inc.    All rights reserved.
*/
#include "sos/alloc.h"
#include <stdio.h>
#if	defined(HAVE_STDLIB_H)
#include <stdlib.h>
#include <string.h>
#endif	/* defined(HAVE_STDLIB_H) */
#if	defined(SYS_UNIX)
#include "unix.h"
#endif	/* defined(SYS_UNIX) */
#if	defined(SYS_OS9)
#include "os9.h"
#endif	/* defined(SYS_OS9) */

typedef unsigned char	CHAR;

#if	defined(HIDE)
#define STATIC	static
#else
#define STATIC	/* NULL */
#endif	/* !defined(HIDE) */

#define MEM_INC		64
#define SCREEN_INC	256

#define COPYFROMTO(new, p, len)	\
	(void)memcpy((char *)(new), (char *)(p), (int)(len))


/*
**  Variables and routines internal to this package.
*/
extern int	rl_eof;
extern int	rl_erase;
extern int	rl_intr;
extern int	rl_kill;
extern int	rl_quit;
#if	defined(DO_SIGTSTP)
extern int	rl_susp;
#endif	/* defined(DO_SIGTSTP) */
extern char	*rl_complete();
extern int	rl_list_possib();
extern void	rl_ttyset();
extern void	rl_add_slash();
extern void	rl_initialize();

#if	!defined(HAVE_STDLIB_H)
extern char	*getenv();
extern char	*malloc();
extern char	*realloc();
extern char	*memcpy();
extern char	*strcat();
extern char	*strchr();
extern char	*strrchr();
extern char	*strcpy();
extern char	*strdup();
extern int	strcmp();
extern int	strlen();
extern int	strncmp();
#endif	/* !defined(HAVE_STDLIB_H) */

#if ! defined(RCSID)
#if ! defined(NO_RCSID)
#if defined(__STDC__) || defined(__ANSI_CPP__)
#define UsE_PaStE(b) UsE__##b##_
#else
#define UsE_PaStE(b) UsE__/**/b/**/_
#endif
#if defined(__cplusplus)
#define UsE(x) inline void UsE_PaStE(x)(const char *) { UsE_PaStE(x)(x); }
#else
#define UsE(x) static void UsE_PaStE(x)(const char *d) { UsE_PaStE(x)(x); }
#endif
#define RCSID(str)				\
	static const char *rcsid_ = str;	\
	UsE(rcsid_)
#else
#define RCSID(str)
#endif
#endif
