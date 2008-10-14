/*    commonp.h
 *
 *    $Id: commonp.h,v 19.0 2003/07/16 05:18:01 aips2adm Exp $
 *    Copyright (c) 1991-1997, Larry Wall
 *    Copyright (c) 1998,1999,2000 Associated Universities Inc.
 *
 *    Scavenged from Perl distribution needed for regex closure...
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#ifndef commonp_h_
#define commonp_h_

#include <ctype.h>
#include <stdio.h>
#include "regx/common.h"
#include "sos/alloc.h"

#ifdef __cplusplus
extern "C" {
#endif

#define _(x) x
#undef NULL
#define NULL 0
#define Null(type)      ((type)NULL)
#define Nullch          ((char*)NULL)
#define Nullsv          ((SV*)NULL)
#define New(x,v,n,t)    (v = (t*)alloc_memory((n)*sizeof(t)))
#define Newc(x,v,n,t,c) (v = (c*)alloc_memory((n)*sizeof(t)))
#define memzero(d,l)    memset(d,0,l)
#define Newz(x,v,n,t)   (v = (t*)alloc_zero_memory((n)*sizeof(t)))
#define Renew(v,n,t) 	(v = (t*)realloc_memory((v),((n)*sizeof(t))))
#define Copy(s,d,n,t)   (void)memcpy((char*)(d),(char*)(s), (n) * sizeof(t))
#define memEQ(s1,s2,l)  (!memcmp(s1,s2,l))
#define memNE(s1,s2,l)  (memcmp(s1,s2,l))

#define isUPPER(c)      ((c) >= 'A' && (c) <= 'Z')
#define isLOWER(c)      ((c) >= 'a' && (c) <= 'z')
#define isALPHA(c)      (isUPPER(c) || isLOWER(c))
#define isDIGIT(c)      ((c) >= '0' && (c) <= '9')
#define isALNUM(c)      (isALPHA(c) || isDIGIT(c) || (c) == '_')
#define isSPACE(c)      ((c) == ' ' || (c) == '\t' || (c) == '\n' || (c) =='\r' || (c) == '\f')
#define isPRINT(c)      (((c) > 32 && (c) < 127) || isSPACE(c))
#define toCTRL(c)       (toUPPER(c) ^ 64)
#define toUPPER(c)      (isLOWER(c) ? (c) - ('a' - 'A') : (c))
#define toLOWER(c)      (isUPPER(c) ? (c) + ('a' - 'A') : (c))

#define isALPHA_LC(c)   isalpha((unsigned char)(c))
#define isSPACE_LC(c)   isspace((unsigned char)(c))
#define isPRINT_LC(c)   isprint((unsigned char)(c))
#define isALNUM_LC(c)   (isalpha((unsigned char)(c)) || isdigit((unsigned char)(c)) || (char)(c) == '_')

#define Safefree free_memory
#define safemalloc alloc_memory
#define STRLEN int
#define IV int
#define UV unsigned int
#define I_V(x) ((IV)(x))
#define U_V(x) ((UV)(x))

#define bool int
#define TRUE  1
#define FALSE 0

#define DEBUG_r(x)

EXT char *regprecomp;		/* uncompiled string. */
EXT char *regparse;		/* Input-scan pointer. */
EXT char *regxend;		/* End of input for compile */
EXT char *regcode;		/* Code-emit pointer; &regdummy = don't. */
EXT U16 regflags;		/* are we folding, multilining? */
EXT I32 regsawback;		/* Did we see \1, ...? */
EXT I32 regnaughty;		/* How bad is this pattern? */
EXT I32 regnpar;		/* () count. */
EXT I32 regsize;		/* Code size. */
EXT char regdummy;
EXT bool sawstudy;		/* do fbm_instr on all strings */
EXT bool dowarn;
EXT I32 *screamnext;

EXT char *savepvn(char *sv, I32 len);
EXT char *regnext(char *p);
EXT void croak(const char* pat, ...);

/*#define newSVpv(s,len) 0*/

/* --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- */
EXT I32 savestack_ix;
EXT char **regstartp;		/* Pointer to startp array. */
EXT char **regendp;		/* Ditto for endp. */
EXT U32 *reglastparen;		/* Similarly for lastparen. */
EXT char *reginput;		/* String-input pointer. */
EXT char regprev;		/* char before regbol, \n if none */
EXT I32 multiline;		/* $*--do strings hold >1 line? */
EXT char *regbol;		/* Beginning of input, for ^ check. */
EXT char *regeol;		/* End of input, for $ check. */
EXT char *regtill;		/* How far we are required to go. */
EXT unsigned char fold[];	/* fast case folding table */
EXT unsigned char fold_locale[];/* fast case folding table */

EXT I32 *screamfirst;

typedef union {
	I32   any_i32;
	void *any_ptr;
} any_value;

EXT I32 savestack_max;
any_value *savestack;	/* to save non-local values on */
#define INIT_SAVESTACK	{ savestack_max = 8;					\
			  savestack = (any_value*) alloc_memory(savestack_max*sizeof(any_value)); }
#define SAVEt_REGCONTEXT 21
#define SSPUSHINT(i) (savestack[savestack_ix++].any_i32 = (I32)(i))
#define SSPUSHPTR(p) (savestack[savestack_ix++].any_ptr = (void*)(p))
#define SSPOPINT (savestack[--savestack_ix].any_i32)
#define SSPOPPTR (savestack[--savestack_ix].any_ptr)
#define SSCHECK(need) if (savestack_ix + need > savestack_max) savestack_grow()
/* --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- */

typedef struct gv GV;
typedef struct xpvgv XPVGV;
typedef struct xpvcv XPVCV;
typedef struct xpvav XPVAV;
typedef struct xpvhv XPVHV;
typedef struct xpvio XPVIO;
typedef struct hv HV;
typedef struct gp GP;
typedef struct cv CV;
typedef struct av AV;
typedef struct xpv XPV;
typedef struct xpvbm XPVBM;

extern SV *newSVpv(char *s, STRLEN len);
extern char *screaminstr(SV *bigstr, SV *littlestr);
extern char *fbm_instr(unsigned char *big, unsigned char *bigend, SV *littlestr);
extern char *ninstr(char *big, char *bigend, char *little, char *lend);
extern char *sv_2pv(SV* sv, STRLEN* lp);
extern void savestack_grow(void);

#define PerlIO FILE
#define PerlIO_printf   fprintf
#define PerlIO_stderr() stderr
#define PerlIO_eof feof
#define PerlIO_getc fgetc
#define PerlIO_ungetc(F,c) ungetc(c,F)
#define PerlIO_read(F,buf,size) fread(buf,size,1,F)
#define PerlIO_get_cnt(x) (-1)
#define PerlIO_get_ptr(x) (0)
#define PerlIO_set_ptrcnt(x,y,z)
#define PerlIO_fast_gets(x) (0)

#define SET_NUMERIC_STANDARD()  /**/
#define SET_NUMERIC_LOCAL()     /**/

#ifdef __cplusplus
	}
#endif

#endif
