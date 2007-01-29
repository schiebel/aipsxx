/*  $Id: unix.h,v 19.0 2003/07/16 05:17:04 aips2adm Exp $
**
**  Editline system header file for Unix.
**
** Copyright (c) 1992,1993 Simmule Turner and Rich Salz.  All rights reserved.
** Copyright (c) 1997 Associated Universities Inc.    All rights reserved.
*/

#define CRLF		"\r\n"
#define FORWARD		STATIC

#include <sys/types.h>
#include <sys/stat.h>

#if	defined(HAVE_DIRENT_H)
#include <dirent.h>
typedef struct dirent	DIRENTRY;
#else
#include <sys/dir.h>
typedef struct direct	DIRENTRY;
#endif	/* defined(HAVE_DIRENT_H) */

#if	!defined(S_ISDIR)
#define S_ISDIR(m)		(((m) & S_IFMT) == S_IFDIR)
#endif	/* !defined(S_ISDIR) */
