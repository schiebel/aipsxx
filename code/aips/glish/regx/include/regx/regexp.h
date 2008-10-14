/*    regexp.h
 */

/*
 * Definitions etc. for regexp(3) routines.
 *
 *    $Id: regexp.h,v 19.0 2003/07/16 05:17:58 aips2adm Exp $
 *    Copyright (c) 1991-1997, Larry Wall
 *
 * Caveat:  this is V8 regexp(3) [actually, a reimplementation thereof],
 * not the System V one.
 */
#ifndef regexp_h_
#define regexp_h_

#include <stdarg.h>
#include "regx/common.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct regexp {
	char **startp;
	char **endp;
	SV *regstart;		/* Internal use only. */
	char *regstclass;
	SV *regmust;		/* Internal use only. */
	I32 regback;		/* Can regmust locate first try? */
	I32 minlen;		/* mininum possible length of $& */
	I32 prelen;		/* length of precomp */
	U32 nparens;		/* number of parentheses */
	U32 lastparen;		/* last paren matched */
	char *precomp;		/* pre-compilation regular expression */
	char *subbase;		/* saved string so \digit works forever */
	char *subbeg;		/* same, but not responsible for allocation */
	char *subend;		/* end of subbase */
	U16 naughty;		/* how exponential is this pattern? */
	char reganch;		/* Internal use only. */
	char exec_tainted;	/* Tainted information used by regexec? */
	char *program;		/* Unwarranted chumminess with compiler. */
} regexp;

EXT regexp *regxcomp(char *exp, char *xend, PMOP *pm);
EXT I32 regxexec(regexp*, char *stringarg, char *strend, char *strbeg, I32 minend, SV *screamer, I32 safebase);
void regxseterror( void (*hdlr)(const char *, va_list) );

#ifdef __cplusplus
	}
#endif

#define ROPT_ANCH	3
#define ROPT_ANCH_BOL	1
#define ROPT_ANCH_GPOS	2
#define ROPT_SKIP	4
#define ROPT_IMPLICIT	8

#endif
