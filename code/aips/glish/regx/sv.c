/*    sv.c
 *
 *    $Id: sv.c,v 19.0 2003/07/16 05:18:04 aips2adm Exp $
 *    Copyright (c) 1991-1997, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * "I wonder what the Entish is for 'yes' and 'no'," he thought.
 */

#include "config.h"
#include <errno.h>
#include <stdio.h>
#include <stdarg.h>
#include <assert.h>
#include <string.h>
#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif
#include <stdlib.h>
#include <unistd.h>
#define I_STDARG
#include "commonp.h"
#include "sv.h"
#include "cop.h"

typedef struct xpviv XPVIV;
typedef struct xpvnv XPVNV;
typedef struct xrv XRV;
typedef struct xpvmg XPVMG;
typedef struct xpvlv XPVLV;
typedef struct xpvuv XPVUV;

#define warn printf
#define die(x) printf(x),exit(1)
#define cv_undef(x) die("cv_undef\n")
#define hv_undef(x) die("hv_undef\n")
#define av_undef(x) die("av_undef\n")
#define mg_get(x) die("mg_get\n")
#define mg_set(x) die("mg_set\n")
#define mg_free(x) die("mg_free\n")
#define gp_free(x) die("gp_free\n")
#define	Gconvert(w, x, y, z) die("Gconvert\n")
#define HvNAME(x) (0)
#define GvNAME(x) (0)
#define GvINTRO(x) (0)
#define GvGP(x) (0)
#define RsSNARF(x) (0)
#define RsPARA(x) (0)
#define strEQ(s1,s2) (0)
#define SAVEFREESV(x)
#define mg_len(x) (0)
#define I_32(what) ((I32)(what))
#define memzero(d,l) memset(d,0,l)
#define Zero(d,n,t)	(void)memzero((char*)(d), (n) * sizeof(t))
#define Move(s,d,n,t)	(void)memmove((char*)(d),(char*)(s), (n) * sizeof(t))
#define NEWSV(x,len)    newSV(len)
#define StructCopy(s,d,t) (*((t*)(d)) = *((t*)(s)))
#define dSP             register SV **sp = stack_sp
#define Nullcv Null(CV*)
#define Nullgv Null(GV*)
#define BIT_DIGITS(N)   (((N)*146)/485 + 1)  /* log2(10) =~ 146/485 */
#define TYPE_DIGITS(T)  BIT_DIGITS(sizeof(T) * 8)
#define TYPE_CHARS(T)   (TYPE_DIGITS(T) + 2) /* sign, NUL */

#define STDCHAR char
#define ENTER

SV *sv_arenaroot = 0;		/* list of areas for garbage collection */
SV *sv_root = 0;		/* storage for SVs belonging to interp */
char *nice_chunk = 0;		/* a nice chunk of memory to reuse */
U32 nice_chunk_size = 0;	/* how nice the chunk of memory is */
I32 sv_count = 0;		/* how many SV* are currently allocated */
IV **xiv_root = 0;		/* free xiv list--shared by interpreters */
XPV *xiv_arenaroot = 0;		/* list of allocated xiv areas */
double *xnv_root = 0;		/* free xnv list--shared by interpreters */
XRV *xrv_root = 0;		/* free xrv list--shared by interpreters */
XPV *xpv_root = 0;		/* free xpv list--shared by interpreters */
bool  tainted = FALSE;		/* using variables controlled by $< */
bool  tainting = FALSE;		/* doing taint checks */
OP *op = 0;			/* current op--oughta be in a global register */
U8 localizing = 0;		/* are we processing a local() list? */
AV *curstack = 0;		/* THE STACK */
AV *sortstack = 0;		/* temp stack during pp_sort() */
OP *sortcop = 0;		/* user defined sort routine */
STRLEN na = 0;			/* for use in SvPV when length is Not Applicable */
HV *defstash = 0;		/* main symbol table */
SV **stack_sp = 0;		/* stack pointer now */
I32 sv_objcount = 0;		/* how many objects are currently allocated */
SV *rs = 0;			/* $/ */

I32 tmps_max = 0;
SV **tmps_stack = 0;
I32 tmps_ix = -1;
SV *Sv = 0;
char tokenbuf[256];

SV sv_undef;
SV sv_yes;
SV sv_no;

#define DEBUG_D(x)
#define DEBUG_c(x)
#define DEBUG_P(x)
#define IV_MAX 2147483647L
#define IV_MIN (-IV_MAX - 1)
COP compiling;
COP *curcop = &compiling;
extern void sv_setpvn(SV *sv, const char *ptr, STRLEN len);
extern char *sv_grow(SV *sv, I32 newlen);
extern void sv_free( SV *sv );

static const char no_modify[] = "Modification of a read-only value attempted";
static const char warn_uninit[] = "Use of uninitialized value";

/*
 * STMT_START { statements; } STMT_END;
 * can be used as a single statement, as in
 * if (x) STMT_START { ... } STMT_END; else ...
 *
 * Trying to select a version that gives no warnings...
 */
#if !(defined(STMT_START) && defined(STMT_END))
# if defined(__GNUC__) && !defined(__STRICT_ANSI__) && !defined(__cplusplus)
#   define STMT_START   (void)( /* gcc supports ``({ STATEMENTS; })'' */
#   define STMT_END     )
# else
   /* Now which other defined()s do we need here ??? */
#  if (VOIDFLAGS) && (defined(sun) || defined(__sun__))
#   define STMT_START   if (1)
#   define STMT_END     else (void)0
#  else
#   define STMT_START   do
#   define STMT_END     while (0)
#  endif
# endif
#endif


#ifdef OVR_DBL_DIG
/* Use an overridden DBL_DIG */
# ifdef DBL_DIG
#  undef DBL_DIG
# endif
# define DBL_DIG OVR_DBL_DIG
#else
/* The following is all to get DBL_DIG, in order to pick a nice
   default value for printing floating point numbers in Gconvert.
   (see config.h)
*/
#ifdef I_LIMITS
#include <limits.h>
#endif
#ifdef I_FLOAT
#include <float.h>
#endif
#ifndef HAS_DBL_DIG
#define DBL_DIG	15   /* A guess that works lots of places */
#endif
#endif

#if defined(USE_STDIO_PTR) && defined(STDIO_PTR_LVALUE) && defined(STDIO_CNT_LVALUE) && !defined(__QNX__)
#  define FAST_SV_GETS
#endif

static SV *sv_newref( SV* sv );
static SV *newSV( STRLEN len );
static SV *newRV( SV *ref );
static UV sv_2uv( SV *sv );
static double sv_2nv( SV *sv );
static IV sv_2iv( SV *sv );
static void sv_catpv( SV *sv, char *ptr );
static int sv_unmagic( SV* sv, int type );
static I32 looks_like_number( SV *sv );
static int sv_backoff(SV *sv );
static void sv_unref( SV* sv );
static void sv_clear( SV *sv );
static void sv_setpv(SV *sv, const char *ptr);
static char *sv_pvn_force(SV *sv,STRLEN *lp);
static SV *sv_2mortal(SV *sv);
static void sv_setpviv( SV *sv, IV iv );
static void sv_taint( SV *sv );
static char *sv_reftype( SV* sv, int ob );
static IV asIV _((SV* sv));
static UV asUV _((SV* sv));
static SV *more_sv _((void));
static XPVIV *more_xiv _((void));
static XPVNV *more_xnv _((void));
static XPV *more_xpv _((void));
static XRV *more_xrv _((void));
static XPVIV *new_xiv _((void));
static XPVNV *new_xnv _((void));
static XPV *new_xpv _((void));
static XRV *new_xrv _((void));
static void del_xiv _((XPVIV* p));
static void del_xnv _((XPVNV* p));
static void del_xpv _((XPV* p));
static void del_xrv _((XRV* p));
static void sv_mortalgrow _((void));
static void sv_unglob _((SV* sv));

typedef void (*SVFUNC) _((SV*));

/*
 * "A time to plant, and a time to uproot what was planted..."
 */

#define plant_SV(p)			\
    do {				\
	SvANY(p) = (void *)sv_root;	\
	SvFLAGS(p) = SVTYPEMASK;	\
	sv_root = (p);			\
	--sv_count;			\
    } while (0)

#define uproot_SV(p)			\
    do {				\
	(p) = sv_root;			\
	sv_root = (SV*)SvANY(p);	\
	++sv_count;			\
    } while (0)

#define new_SV(p)			\
    if (sv_root)			\
	uproot_SV(p);			\
    else				\
	(p) = more_sv()

#ifdef DEBUGGING

#define del_SV(p)			\
    if (debug & 32768)			\
	del_sv(p);			\
    else				\
	plant_SV(p)

static void
del_sv(p)
SV* p;
{
    if (debug & 32768) {
	SV* sva;
	SV* sv;
	SV* svend;
	int ok = 0;
	for (sva = sv_arenaroot; sva; sva = (SV *) SvANY(sva)) {
	    sv = sva + 1;
	    svend = &sva[SvREFCNT(sva)];
	    if (p >= sv && p < svend)
		ok = 1;
	}
	if (!ok) {
	    warn("Attempt to free non-arena SV: 0x%lx", (unsigned long)p);
	    return;
	}
    }
    plant_SV(p);
}

#else /* ! DEBUGGING */

#define del_SV(p)   plant_SV(p)

#endif /* DEBUGGING */

static void
sv_add_arena(ptr, size, flags)
char* ptr;
U32 size;
U32 flags;
{
    SV* sva = (SV*)ptr;
    register SV* sv;
    register SV* svend;
    Zero(sva, size, char);

    /* The first SV in an arena isn't an SV. */
    SvANY(sva) = (void *) sv_arenaroot;		/* ptr to next arena */
    SvREFCNT(sva) = size / sizeof(SV);		/* number of SV slots */
    SvFLAGS(sva) = flags;			/* FAKE if not to be freed */

    sv_arenaroot = sva;
    sv_root = sva + 1;

    svend = &sva[SvREFCNT(sva) - 1];
    sv = sva + 1;
    while (sv < svend) {
	SvANY(sv) = (void *)(SV*)(sv + 1);
	SvFLAGS(sv) = SVTYPEMASK;
	sv++;
    }
    SvANY(sv) = 0;
    SvFLAGS(sv) = SVTYPEMASK;
}

static SV*
more_sv()
{
    register SV* sv;

    if (nice_chunk) {
	sv_add_arena(nice_chunk, nice_chunk_size, 0);
	nice_chunk = Nullch;
    }
    else {
	char *chunk;                /* must use New here to match call to */
	New(704,chunk,1008,char);   /* Safefree() in sv_free_arenas()     */
	sv_add_arena(chunk, 1008, 0);
    }
    uproot_SV(sv);
    return sv;
}

static XPVIV*
new_xiv()
{
    IV** xiv;
    if (xiv_root) {
	xiv = xiv_root;
	/*
	 * See comment in more_xiv() -- RAM.
	 */
	xiv_root = (IV**)*xiv;
	return (XPVIV*)((char*)xiv - sizeof(XPV));
    }
    return more_xiv();
}

static void
del_xiv(p)
XPVIV* p;
{
    IV** xiv = (IV**)((char*)(p) + sizeof(XPV));
    *xiv = (IV *)xiv_root;
    xiv_root = xiv;
}

static XPVIV*
more_xiv()
{
    register IV** xiv;
    register IV** xivend;
    XPV* ptr = (XPV*)safemalloc(1008);
    ptr->xpv_pv = (char*)xiv_arenaroot;		/* linked list of xiv arenas */
    xiv_arenaroot = ptr;			/* to keep Purify happy */

    xiv = (IV**) ptr;
    xivend = &xiv[1008 / sizeof(IV *) - 1];
    xiv += (sizeof(XPV) - 1) / sizeof(IV *) + 1;   /* fudge by size of XPV */
    xiv_root = xiv;
    while (xiv < xivend) {
	*xiv = (IV *)(xiv + 1);
	xiv++;
    }
    *xiv = 0;
    return new_xiv();
}

static XPVNV*
new_xnv()
{
    double* xnv;
    if (xnv_root) {
	xnv = xnv_root;
	xnv_root = *(double**)xnv;
	return (XPVNV*)((char*)xnv - sizeof(XPVIV));
    }
    return more_xnv();
}

static void
del_xnv(p)
XPVNV* p;
{
    double* xnv = (double*)((char*)(p) + sizeof(XPVIV));
    *(double**)xnv = xnv_root;
    xnv_root = xnv;
}

static XPVNV*
more_xnv()
{
    register double* xnv;
    register double* xnvend;
    xnv = (double*)safemalloc(1008);
    xnvend = &xnv[1008 / sizeof(double) - 1];
    xnv += (sizeof(XPVIV) - 1) / sizeof(double) + 1; /* fudge by sizeof XPVIV */
    xnv_root = xnv;
    while (xnv < xnvend) {
	*(double**)xnv = (double*)(xnv + 1);
	xnv++;
    }
    *(double**)xnv = 0;
    return new_xnv();
}

static XRV*
new_xrv()
{
    XRV* xrv;
    if (xrv_root) {
	xrv = xrv_root;
	xrv_root = (XRV*)xrv->xrv_rv;
	return xrv;
    }
    return more_xrv();
}

static void
del_xrv(p)
XRV* p;
{
    p->xrv_rv = (SV*)xrv_root;
    xrv_root = p;
}

static XRV*
more_xrv()
{
    register XRV* xrv;
    register XRV* xrvend;
    xrv_root = (XRV*)safemalloc(1008);
    xrv = xrv_root;
    xrvend = &xrv[1008 / sizeof(XRV) - 1];
    while (xrv < xrvend) {
	xrv->xrv_rv = (SV*)(xrv + 1);
	xrv++;
    }
    xrv->xrv_rv = 0;
    return new_xrv();
}

static XPV*
new_xpv()
{
    XPV* xpv;
    if (xpv_root) {
	xpv = xpv_root;
	xpv_root = (XPV*)xpv->xpv_pv;
	return xpv;
    }
    return more_xpv();
}

static void
del_xpv(p)
XPV* p;
{
    p->xpv_pv = (char*)xpv_root;
    xpv_root = p;
}

static XPV*
more_xpv()
{
    register XPV* xpv;
    register XPV* xpvend;
    xpv_root = (XPV*)safemalloc(1008);
    xpv = xpv_root;
    xpvend = &xpv[1008 / sizeof(XPV) - 1];
    while (xpv < xpvend) {
	xpv->xpv_pv = (char*)(xpv + 1);
	xpv++;
    }
    xpv->xpv_pv = 0;
    return new_xpv();
}

#define new_XIV() (void*)new_xiv()
#define del_XIV(p) del_xiv(p)

#define new_XNV() (void*)new_xnv()
#define del_XNV(p) del_xnv(p)

#define new_XRV() (void*)new_xrv()
#define del_XRV(p) del_xrv(p)

#define new_XPV() (void*)new_xpv()
#define del_XPV(p) del_xpv(p)

#define new_XPVIV() (void*)safemalloc(sizeof(XPVIV))
#define del_XPVIV(p) free_memory((char*)p)

#define new_XPVNV() (void*)safemalloc(sizeof(XPVNV))
#define del_XPVNV(p) free_memory((char*)p)

#define new_XPVMG() (void*)safemalloc(sizeof(XPVMG))
#define del_XPVMG(p) free_memory((char*)p)

#define new_XPVLV() (void*)safemalloc(sizeof(XPVLV))
#define del_XPVLV(p) free_memory((char*)p)

#define new_XPVAV() (void*)safemalloc(sizeof(XPVAV))
#define del_XPVAV(p) free_memory((char*)p)

#define new_XPVHV() (void*)safemalloc(sizeof(XPVHV))
#define del_XPVHV(p) free_memory((char*)p)

#define new_XPVCV() (void*)safemalloc(sizeof(XPVCV))
#define del_XPVCV(p) free_memory((char*)p)

#define new_XPVGV() (void*)safemalloc(sizeof(XPVGV))
#define del_XPVGV(p) free_memory((char*)p)

#define new_XPVBM() (void*)safemalloc(sizeof(XPVBM))
#define del_XPVBM(p) free_memory((char*)p)

#define new_XPVFM() (void*)safemalloc(sizeof(XPVFM))
#define del_XPVFM(p) free_memory((char*)p)

#define new_XPVIO() (void*)safemalloc(sizeof(XPVIO))
#define del_XPVIO(p) free_memory((char*)p)

bool
sv_upgrade(sv, mt)
register SV* sv;
U32 mt;
{
    char*	pv;
    U32		cur;
    U32		len;
    IV		iv;
    double	nv;
    MAGIC_T*	magic;
    HV*		stash;

    if (SvTYPE(sv) == mt)
	return TRUE;

    if (mt < SVt_PVIV)
	(void)SvOOK_off(sv);

    switch (SvTYPE(sv)) {
    case SVt_NULL:
	pv	= 0;
	cur	= 0;
	len	= 0;
	iv	= 0;
	nv	= 0.0;
	magic	= 0;
	stash	= 0;
	break;
    case SVt_IV:
	pv	= 0;
	cur	= 0;
	len	= 0;
	iv	= SvIVX(sv);
	nv	= (double)SvIVX(sv);
	del_XIV(SvANY(sv));
	magic	= 0;
	stash	= 0;
	if (mt == SVt_NV)
	    mt = SVt_PVNV;
	else if (mt < SVt_PVIV)
	    mt = SVt_PVIV;
	break;
    case SVt_NV:
	pv	= 0;
	cur	= 0;
	len	= 0;
	nv	= SvNVX(sv);
	iv	= I_32(nv);
	magic	= 0;
	stash	= 0;
	del_XNV(SvANY(sv));
	SvANY(sv) = 0;
	if (mt < SVt_PVNV)
	    mt = SVt_PVNV;
	break;
    case SVt_RV:
	pv	= (char*)SvRV(sv);
	cur	= 0;
	len	= 0;
	iv	= (IV)pv;
	nv	= (double)(unsigned long)pv;
	del_XRV(SvANY(sv));
	magic	= 0;
	stash	= 0;
	break;
    case SVt_PV:
	pv	= SvPVX(sv);
	cur	= SvCUR(sv);
	len	= SvLEN(sv);
	iv	= 0;
	nv	= 0.0;
	magic	= 0;
	stash	= 0;
	del_XPV(SvANY(sv));
	if (mt <= SVt_IV)
	    mt = SVt_PVIV;
	else if (mt == SVt_NV)
	    mt = SVt_PVNV;
	break;
    case SVt_PVIV:
	pv	= SvPVX(sv);
	cur	= SvCUR(sv);
	len	= SvLEN(sv);
	iv	= SvIVX(sv);
	nv	= 0.0;
	magic	= 0;
	stash	= 0;
	del_XPVIV(SvANY(sv));
	break;
    case SVt_PVNV:
	pv	= SvPVX(sv);
	cur	= SvCUR(sv);
	len	= SvLEN(sv);
	iv	= SvIVX(sv);
	nv	= SvNVX(sv);
	magic	= 0;
	stash	= 0;
	del_XPVNV(SvANY(sv));
	break;
    case SVt_PVMG:
	pv	= SvPVX(sv);
	cur	= SvCUR(sv);
	len	= SvLEN(sv);
	iv	= SvIVX(sv);
	nv	= SvNVX(sv);
	magic	= SvMAGIC(sv);
	stash	= SvSTASH(sv);
	del_XPVMG(SvANY(sv));
	break;
    default:
	croak("Can't upgrade that kind of scalar");
    }

    switch (mt) {
    case SVt_NULL:
	croak("Can't upgrade to undef");
    case SVt_IV:
	SvANY(sv) = new_XIV();
	SvIVX(sv)	= iv;
	break;
    case SVt_NV:
	SvANY(sv) = new_XNV();
	SvNVX(sv)	= nv;
	break;
    case SVt_RV:
	SvANY(sv) = new_XRV();
	SvRV(sv) = (SV*)pv;
	break;
    case SVt_PV:
	SvANY(sv) = new_XPV();
	SvPVX(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	break;
    case SVt_PVIV:
	SvANY(sv) = new_XPVIV();
	SvPVX(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIVX(sv)	= iv;
	if (SvNIOK(sv))
	    (void)SvIOK_on(sv);
	SvNOK_off(sv);
	break;
    case SVt_PVNV:
	SvANY(sv) = new_XPVNV();
	SvPVX(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIVX(sv)	= iv;
	SvNVX(sv)	= nv;
	break;
    case SVt_PVMG:
	SvANY(sv) = new_XPVMG();
	SvPVX(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIVX(sv)	= iv;
	SvNVX(sv)	= nv;
	SvMAGIC(sv)	= magic;
	SvSTASH(sv)	= stash;
	break;
    case SVt_PVLV:
	SvANY(sv) = new_XPVLV();
	SvPVX(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIVX(sv)	= iv;
	SvNVX(sv)	= nv;
	SvMAGIC(sv)	= magic;
	SvSTASH(sv)	= stash;
	LvTARGOFF(sv)	= 0;
	LvTARGLEN(sv)	= 0;
	LvTARG(sv)	= 0;
	LvTYPE(sv)	= 0;
	break;
    case SVt_PVAV:
/*++ 	SvANY(sv) = new_XPVAV(); */
/* 	if (pv) */
/* 	    Safefree(pv); */
/* 	SvPVX(sv)	= 0; */
/* 	AvMAX(sv)	= -1; */
/* 	AvFILL(sv)	= -1; */
/* 	SvIVX(sv)	= 0; */
/* 	SvNVX(sv)	= 0.0; */
/* 	SvMAGIC(sv)	= magic; */
/* 	SvSTASH(sv)	= stash; */
/* 	AvALLOC(sv)	= 0; */
/* 	AvARYLEN(sv)	= 0; */
/* 	AvFLAGS(sv)	= 0; */
	break;
    case SVt_PVHV:
/*++ 	SvANY(sv) = new_XPVHV(); */
/* 	if (pv) */
/* 	    Safefree(pv); */
/* 	SvPVX(sv)	= 0; */
/* 	HvFILL(sv)	= 0; */
/* 	HvMAX(sv)	= 0; */
/* 	HvKEYS(sv)	= 0; */
/* 	SvNVX(sv)	= 0.0; */
/* 	SvMAGIC(sv)	= magic; */
/* 	SvSTASH(sv)	= stash; */
/* 	HvRITER(sv)	= 0; */
/* 	HvEITER(sv)	= 0; */
/* 	HvPMROOT(sv)	= 0; */
/* 	HvNAME(sv)	= 0; */
	break;
    case SVt_PVCV:
/*++ 	SvANY(sv) = new_XPVCV(); */
/* 	Zero(SvANY(sv), 1, XPVCV); */
/* 	SvPVX(sv)	= pv; */
/* 	SvCUR(sv)	= cur; */
/* 	SvLEN(sv)	= len; */
/* 	SvIVX(sv)	= iv; */
/* 	SvNVX(sv)	= nv; */
/* 	SvMAGIC(sv)	= magic; */
/* 	SvSTASH(sv)	= stash; */
	break;
    case SVt_PVGV:
	SvANY(sv) = new_XPVGV();
	SvPVX(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIVX(sv)	= iv;
	SvNVX(sv)	= nv;
	SvMAGIC(sv)	= magic;
	SvSTASH(sv)	= stash;
/*++ 	GvGP(sv)	= 0; */
/* 	GvNAME(sv)	= 0; */
/* 	GvNAMELEN(sv)	= 0; */
/* 	GvSTASH(sv)	= 0; */
/* 	GvFLAGS(sv)	= 0; */
	break;
    case SVt_PVBM:
	SvANY(sv) = new_XPVBM();
	SvPVX(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIVX(sv)	= iv;
	SvNVX(sv)	= nv;
	SvMAGIC(sv)	= magic;
	SvSTASH(sv)	= stash;
	BmRARE(sv)	= 0;
	BmUSEFUL(sv)	= 0;
	BmPREVIOUS(sv)	= 0;
	break;
    case SVt_PVFM:
/*++ 	SvANY(sv) = new_XPVFM(); */
/* 	Zero(SvANY(sv), 1, XPVFM); */
/* 	SvPVX(sv)	= pv; */
/* 	SvCUR(sv)	= cur; */
/* 	SvLEN(sv)	= len; */
/* 	SvIVX(sv)	= iv; */
/* 	SvNVX(sv)	= nv; */
/* 	SvMAGIC(sv)	= magic; */
/* 	SvSTASH(sv)	= stash; */
	break;
    case SVt_PVIO:
	SvANY(sv) = new_XPVIO();
	Zero(SvANY(sv), 1, XPVIO);
	SvPVX(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIVX(sv)	= iv;
	SvNVX(sv)	= nv;
	SvMAGIC(sv)	= magic;
	SvSTASH(sv)	= stash;
	IoPAGE_LEN(sv)	= 60;
	break;
    }
    SvFLAGS(sv) &= ~SVTYPEMASK;
    SvFLAGS(sv) |= mt;
    return TRUE;
}

static int
sv_backoff(sv)
register SV *sv;
{
    assert(SvOOK(sv));
    if (SvIVX(sv)) {
	char *s = SvPVX(sv);
	SvLEN(sv) += SvIVX(sv);
	SvPVX(sv) -= SvIVX(sv);
	SvIV_set(sv, 0);
	Move(s, SvPVX(sv), SvCUR(sv)+1, char);
    }
    SvFLAGS(sv) &= ~SVf_OOK;
    return 0;
}

char *
sv_grow(sv,newlen)
register SV *sv;
#ifndef DOSISH
register I32 newlen;
#else
unsigned long newlen;
#endif
{
    register char *s;

#ifdef HAS_64K_LIMIT
    if (newlen >= 0x10000) {
	PerlIO_printf(Perl_debug_log, "Allocation too large: %lx\n", newlen);
	my_exit(1);
    }
#endif /* HAS_64K_LIMIT */
    if (SvROK(sv))
	sv_unref(sv);
    if (SvTYPE(sv) < SVt_PV) {
	sv_upgrade(sv, SVt_PV);
	s = SvPVX(sv);
    }
    else if (SvOOK(sv)) {	/* pv is offset? */
	sv_backoff(sv);
	s = SvPVX(sv);
	if (newlen > SvLEN(sv))
	    newlen += 10 * (newlen - SvCUR(sv)); /* avoid copy each time */
    }
    else
	s = SvPVX(sv);
    if (newlen > SvLEN(sv)) {		/* need more room? */
        if (SvLEN(sv) && s)
	    Renew(s,newlen,char);
        else
	    New(703,s,newlen,char);
	SvPV_set(sv, s);
        SvLEN_set(sv, newlen);
    }
    return s;
}

static void
not_a_number(sv)
SV *sv;
{
    char tmpbuf[64];
    char *d = tmpbuf;
    char *s;
    char *limit = tmpbuf + sizeof(tmpbuf) - 8;
                  /* each *s can expand to 4 chars + "...\0",
                     i.e. need room for 8 chars */

    for (s = SvPVX(sv); *s && d < limit; s++) {
	int ch = *s & 0xFF;
	if (ch & 128 && !isPRINT_LC(ch)) {
	    *d++ = 'M';
	    *d++ = '-';
	    ch &= 127;
	}
	if (ch == '\n') {
	    *d++ = '\\';
	    *d++ = 'n';
	}
	else if (ch == '\r') {
	    *d++ = '\\';
	    *d++ = 'r';
	}
	else if (ch == '\f') {
	    *d++ = '\\';
	    *d++ = 'f';
	}
	else if (ch == '\\') {
	    *d++ = '\\';
	    *d++ = '\\';
	}
	else if (isPRINT_LC(ch))
	    *d++ = ch;
	else {
	    *d++ = '^';
	    *d++ = toCTRL(ch);
	}
    }
    if (*s) {
	*d++ = '.';
	*d++ = '.';
	*d++ = '.';
    }
    *d = '\0';

    if (op)
	warn("Argument \"%s\" isn't numeric in [op #%u]", tmpbuf,
		op->op_type);
    else
	warn("Argument \"%s\" isn't numeric", tmpbuf);
}

static IV
sv_2iv(sv)
register SV *sv;
{
    if (!sv)
	return 0;
    if (SvGMAGICAL(sv)) {
	mg_get(sv);
	if (SvIOKp(sv))
	    return SvIVX(sv);
	if (SvNOKp(sv)) {
	    if (SvNVX(sv) < 0.0)
		return I_V(SvNVX(sv));
	    else
		return (IV) U_V(SvNVX(sv));
	}
	if (SvPOKp(sv) && SvLEN(sv))
	    return asIV(sv);
	if (!SvROK(sv)) {
	    if (dowarn && !localizing && !(SvFLAGS(sv) & SVs_PADTMP))
		warn(warn_uninit);
	    return 0;
	}
    }
    if (SvTHINKFIRST(sv)) {
	if (SvROK(sv)) {
#ifdef OVERLOAD
	  SV* tmpstr;
	  if (SvAMAGIC(sv) && (tmpstr=AMG_CALLun(sv, numer)))
	    return SvIV(tmpstr);
#endif /* OVERLOAD */
	  return (IV)SvRV(sv);
	}
	if (SvREADONLY(sv)) {
	    if (SvNOKp(sv)) {
		if (SvNVX(sv) < 0.0)
		    return I_V(SvNVX(sv));
		else
		    return (IV) U_V(SvNVX(sv));
	    }
	    if (SvPOKp(sv) && SvLEN(sv))
		return asIV(sv);
	    if (dowarn)
		warn(warn_uninit);
	    return 0;
	}
    }
    switch (SvTYPE(sv)) {
    case SVt_NULL:
	sv_upgrade(sv, SVt_IV);
	break;
    case SVt_PV:
	sv_upgrade(sv, SVt_PVIV);
	break;
    case SVt_NV:
	sv_upgrade(sv, SVt_PVNV);
	break;
    }
    if (SvNOKp(sv)) {
	(void)SvIOK_on(sv);
	if (SvNVX(sv) < 0.0)
	    SvIVX(sv) = I_V(SvNVX(sv));
	else
	    SvUVX(sv) = U_V(SvNVX(sv));
    }
    else if (SvPOKp(sv) && SvLEN(sv)) {
	(void)SvIOK_on(sv);
	SvIVX(sv) = asIV(sv);
    }
    else  {
	if (dowarn && !localizing && !(SvFLAGS(sv) & SVs_PADTMP))
	    warn(warn_uninit);
	return 0;
    }
    DEBUG_c(PerlIO_printf(Perl_debug_log, "0x%lx 2iv(%ld)\n",
	(unsigned long)sv,(long)SvIVX(sv)));
    return SvIVX(sv);
}

static UV
sv_2uv(sv)
register SV *sv;
{
    if (!sv)
	return 0;
    if (SvGMAGICAL(sv)) {
	mg_get(sv);
	if (SvIOKp(sv))
	    return SvUVX(sv);
	if (SvNOKp(sv))
	    return U_V(SvNVX(sv));
	if (SvPOKp(sv) && SvLEN(sv))
	    return asUV(sv);
	if (!SvROK(sv)) {
	    if (dowarn && !localizing && !(SvFLAGS(sv) & SVs_PADTMP))
		warn(warn_uninit);
	    return 0;
	}
    }
    if (SvTHINKFIRST(sv)) {
	if (SvROK(sv)) {
#ifdef OVERLOAD
	  SV* tmpstr;
	  if (SvAMAGIC(sv) && (tmpstr=AMG_CALLun(sv, numer)))
	    return SvUV(tmpstr);
#endif /* OVERLOAD */
	  return (UV)SvRV(sv);
	}
	if (SvREADONLY(sv)) {
	    if (SvNOKp(sv)) {
		return U_V(SvNVX(sv));
	    }
	    if (SvPOKp(sv) && SvLEN(sv))
		return asUV(sv);
	    if (dowarn)
		warn(warn_uninit);
	    return 0;
	}
    }
    switch (SvTYPE(sv)) {
    case SVt_NULL:
	sv_upgrade(sv, SVt_IV);
	break;
    case SVt_PV:
	sv_upgrade(sv, SVt_PVIV);
	break;
    case SVt_NV:
	sv_upgrade(sv, SVt_PVNV);
	break;
    }
    if (SvNOKp(sv)) {
	(void)SvIOK_on(sv);
	SvUVX(sv) = U_V(SvNVX(sv));
    }
    else if (SvPOKp(sv) && SvLEN(sv)) {
	(void)SvIOK_on(sv);
	SvUVX(sv) = asUV(sv);
    }
    else  {
	if (dowarn && !localizing && !(SvFLAGS(sv) & SVs_PADTMP))
	    warn(warn_uninit);
	return 0;
    }
    DEBUG_c(PerlIO_printf(Perl_debug_log, "0x%lx 2uv(%lu)\n",
	(unsigned long)sv,SvUVX(sv)));
    return SvUVX(sv);
}

static double
sv_2nv(sv)
register SV *sv;
{
    if (!sv)
	return 0.0;
    if (SvGMAGICAL(sv)) {
	mg_get(sv);
	if (SvNOKp(sv))
	    return SvNVX(sv);
	if (SvPOKp(sv) && SvLEN(sv)) {
	    if (dowarn && !SvIOKp(sv) && !looks_like_number(sv))
		not_a_number(sv);
	    SET_NUMERIC_STANDARD();
	    return atof(SvPVX(sv));
	}
	if (SvIOKp(sv))
	    return (double)SvIVX(sv);
        if (!SvROK(sv)) {
	    if (dowarn && !localizing && !(SvFLAGS(sv) & SVs_PADTMP))
		warn(warn_uninit);
            return 0;
        }
    }
    if (SvTHINKFIRST(sv)) {
	if (SvROK(sv)) {
#ifdef OVERLOAD
	  SV* tmpstr;
	  if (SvAMAGIC(sv) && (tmpstr=AMG_CALLun(sv,numer)))
	    return SvNV(tmpstr);
#endif /* OVERLOAD */
	  return (double)(unsigned long)SvRV(sv);
	}
	if (SvREADONLY(sv)) {
	    if (SvPOKp(sv) && SvLEN(sv)) {
		if (dowarn && !SvIOKp(sv) && !looks_like_number(sv))
		    not_a_number(sv);
		SET_NUMERIC_STANDARD();
		return atof(SvPVX(sv));
	    }
	    if (SvIOKp(sv))
		return (double)SvIVX(sv);
	    if (dowarn)
		warn(warn_uninit);
	    return 0.0;
	}
    }
    if (SvTYPE(sv) < SVt_NV) {
	if (SvTYPE(sv) == SVt_IV)
	    sv_upgrade(sv, SVt_PVNV);
	else
	    sv_upgrade(sv, SVt_NV);
	DEBUG_c(SET_NUMERIC_STANDARD());
	DEBUG_c(PerlIO_printf(Perl_debug_log,
			      "0x%lx num(%g)\n",(unsigned long)sv,SvNVX(sv)));
    }
    else if (SvTYPE(sv) < SVt_PVNV)
	sv_upgrade(sv, SVt_PVNV);
    if (SvIOKp(sv) &&
	    (!SvPOKp(sv) || !strchr(SvPVX(sv),'.') || !looks_like_number(sv)))
    {
	SvNVX(sv) = (double)SvIVX(sv);
    }
    else if (SvPOKp(sv) && SvLEN(sv)) {
	if (dowarn && !SvIOKp(sv) && !looks_like_number(sv))
	    not_a_number(sv);
	SET_NUMERIC_STANDARD();
	SvNVX(sv) = atof(SvPVX(sv));
    }
    else  {
	if (dowarn && !localizing && !(SvFLAGS(sv) & SVs_PADTMP))
	    warn(warn_uninit);
	return 0.0;
    }
    SvNOK_on(sv);
    DEBUG_c(SET_NUMERIC_STANDARD());
    DEBUG_c(PerlIO_printf(Perl_debug_log,
			  "0x%lx 2nv(%g)\n",(unsigned long)sv,SvNVX(sv)));
    return SvNVX(sv);
}

static IV
asIV(sv)
SV *sv;
{
    I32 numtype = looks_like_number(sv);
    double d;

    if (numtype == 1)
	return atol(SvPVX(sv));
    if (!numtype && dowarn)
	not_a_number(sv);
    SET_NUMERIC_STANDARD();
    d = atof(SvPVX(sv));
    if (d < 0.0)
	return I_V(d);
    else
	return (IV) U_V(d);
}

static UV
asUV(sv)
SV *sv;
{
    I32 numtype = looks_like_number(sv);

#ifdef HAS_STRTOUL
    if (numtype == 1)
	return strtoul(SvPVX(sv), Null(char**), 10);
#endif
    if (!numtype && dowarn)
	not_a_number(sv);
    SET_NUMERIC_STANDARD();
    return U_V(atof(SvPVX(sv)));
}

static I32
looks_like_number(sv)
SV *sv;
{
    register char *s;
    register char *send;
    register char *sbegin;
    I32 numtype;
    STRLEN len;

    if (SvPOK(sv)) {
	sbegin = SvPVX(sv); 
	len = SvCUR(sv);
    }
    else if (SvPOKp(sv))
	sbegin = SvPV(sv, len);
    else
	return 1;
    send = sbegin + len;

    s = sbegin;
    while (isSPACE(*s))
	s++;
    if (*s == '+' || *s == '-')
	s++;

    /* next must be digit or '.' */
    if (isDIGIT(*s)) {
        do {
	    s++;
        } while (isDIGIT(*s));
        if (*s == '.') {
	    s++;
            while (isDIGIT(*s))  /* optional digits after "." */
                s++;
        }
    }
    else if (*s == '.') {
        s++;
        /* no digits before '.' means we need digits after it */
        if (isDIGIT(*s)) {
	    do {
	        s++;
            } while (isDIGIT(*s));
        }
        else
	    return 0;
    }
    else
        return 0;

    /*
     * we return 1 if the number can be converted to _integer_ with atol()
     * and 2 if you need (int)atof().
     */
    numtype = 1;

    /* we can have an optional exponent part */
    if (*s == 'e' || *s == 'E') {
	numtype = 2;
	s++;
	if (*s == '+' || *s == '-')
	    s++;
        if (isDIGIT(*s)) {
            do {
                s++;
            } while (isDIGIT(*s));
        }
        else
            return 0;
    }
    while (isSPACE(*s))
	s++;
    if (s >= send)
	return numtype;
    if (len == 10 && memEQ(sbegin, "0 but true", 10))
	return 1;
    return 0;
}

char *
sv_2pv(sv, lp)
register SV *sv;
STRLEN *lp;
{
    register char *s;
    int olderrno;
    SV *tsv;

    if (!sv) {
	*lp = 0;
	return "";
    }
    if (SvGMAGICAL(sv)) {
	mg_get(sv);
	if (SvPOKp(sv)) {
	    *lp = SvCUR(sv);
	    return SvPVX(sv);
	}
	if (SvIOKp(sv)) {
	    (void)sprintf(tokenbuf,"%ld",(long)SvIVX(sv));
	    tsv = Nullsv;
	    goto tokensave;
	}
	if (SvNOKp(sv)) {
	    SET_NUMERIC_STANDARD();
	    Gconvert(SvNVX(sv), DBL_DIG, 0, tokenbuf);
	    tsv = Nullsv;
	    goto tokensave;
	}
        if (!SvROK(sv)) {
	    if (dowarn && !localizing && !(SvFLAGS(sv) & SVs_PADTMP))
		warn(warn_uninit);
            *lp = 0;
            return "";
        }
    }
    if (SvTHINKFIRST(sv)) {
	if (SvROK(sv)) {
#ifdef OVERLOAD
	    SV* tmpstr;
	    if (SvAMAGIC(sv) && (tmpstr=AMG_CALLun(sv,string)))
	      return SvPV(tmpstr,*lp);
#endif /* OVERLOAD */
	    sv = (SV*)SvRV(sv);
	    if (!sv)
		s = "NULLREF";
	    else {
		switch (SvTYPE(sv)) {
		case SVt_NULL:
		case SVt_IV:
		case SVt_NV:
		case SVt_RV:
		case SVt_PV:
		case SVt_PVIV:
		case SVt_PVNV:
		case SVt_PVBM:
		case SVt_PVMG:	s = "SCALAR";			break;
		case SVt_PVLV:	s = "LVALUE";			break;
		case SVt_PVAV:	s = "ARRAY";			break;
		case SVt_PVHV:	s = "HASH";			break;
		case SVt_PVCV:	s = "CODE";			break;
		case SVt_PVGV:	s = "GLOB";			break;
		case SVt_PVFM:	s = "FORMATLINE";		break;
		case SVt_PVIO:	s = "IO";			break;
		default:	s = "UNKNOWN";			break;
		}
		tsv = NEWSV(0,0);
		if (SvOBJECT(sv))
/* 		    sv_setpvf(tsv, "%s=%s", HvNAME(SvSTASH(sv)), s)*/;
		else
		    sv_setpv(tsv, s);
/* 		sv_catpvf(tsv, "(0x%lx)", (unsigned long)sv); */
		goto tokensaveref;
	    }
	    *lp = strlen(s);
	    return s;
	}
	if (SvREADONLY(sv)) {
	    if (SvNOKp(sv)) {
		SET_NUMERIC_STANDARD();
		Gconvert(SvNVX(sv), DBL_DIG, 0, tokenbuf);
		tsv = Nullsv;
		goto tokensave;
	    }
	    if (SvIOKp(sv)) {
		(void)sprintf(tokenbuf,"%ld",(long)SvIVX(sv));
		tsv = Nullsv;
		goto tokensave;
	    }
	    if (dowarn)
		warn(warn_uninit);
	    *lp = 0;
	    return "";
	}
    }
    if (!SvUPGRADE(sv, SVt_PV))
	return 0;
    if (SvNOKp(sv)) {
	if (SvTYPE(sv) < SVt_PVNV)
	    sv_upgrade(sv, SVt_PVNV);
	SvGROW(sv, 28);
	s = SvPVX(sv);
	olderrno = errno;	/* some Xenix systems wipe out errno here */
#ifdef apollo
	if (SvNVX(sv) == 0.0)
	    (void)strcpy(s,"0");
	else
#endif /*apollo*/
	{
	    SET_NUMERIC_STANDARD();
	    Gconvert(SvNVX(sv), DBL_DIG, 0, s);
	}
	errno = olderrno;
#ifdef FIXNEGATIVEZERO
        if (*s == '-' && s[1] == '0' && !s[2])
	    strcpy(s,"0");
#endif
	while (*s) s++;
#ifdef hcx
	if (s[-1] == '.')
	    *--s = '\0';
#endif
    }
    else if (SvIOKp(sv)) {
	U32 oldIOK = SvIOK(sv);
	if (SvTYPE(sv) < SVt_PVIV)
	    sv_upgrade(sv, SVt_PVIV);
	olderrno = errno;	/* some Xenix systems wipe out errno here */
	sv_setpviv(sv, SvIVX(sv));
	errno = olderrno;
	s = SvEND(sv);
	if (oldIOK)
	    SvIOK_on(sv);
	else
	    SvIOKp_on(sv);
    }
    else {
	if (dowarn && !localizing && !(SvFLAGS(sv) & SVs_PADTMP))
	    warn(warn_uninit);
	*lp = 0;
	return "";
    }
    *lp = s - SvPVX(sv);
    SvCUR_set(sv, *lp);
    SvPOK_on(sv);
    DEBUG_c(PerlIO_printf(Perl_debug_log, "0x%lx 2pv(%s)\n",(unsigned long)sv,SvPVX(sv)));
    return SvPVX(sv);

  tokensave:
    if (SvROK(sv)) {	/* XXX Skip this when sv_pvn_force calls */
	/* Sneaky stuff here */

      tokensaveref:
	if (!tsv)
	    tsv = newSVpv(tokenbuf, 0);
	sv_2mortal(tsv);
	*lp = SvCUR(tsv);
	return SvPVX(tsv);
    }
    else {
	STRLEN len;
	char *t;

	if (tsv) {
	    sv_2mortal(tsv);
	    t = SvPVX(tsv);
	    len = SvCUR(tsv);
	}
	else {
	    t = tokenbuf;
	    len = strlen(tokenbuf);
	}
#ifdef FIXNEGATIVEZERO
	if (len == 2 && t[0] == '-' && t[1] == '0') {
	    t = "0";
	    len = 1;
	}
#endif
	(void)SvUPGRADE(sv, SVt_PV);
	*lp = len;
	s = SvGROW(sv, len + 1);
	SvCUR_set(sv, len);
	(void)strcpy(s, t);
	SvPOKp_on(sv);
	return s;
    }
}


/* Note: sv_setsv() should not be called with a source string that needs
 * to be reused, since it may destroy the source string if it is marked
 * as temporary.
 */

void
sv_setsv(dstr,sstr)
SV *dstr;
register SV *sstr;
{
    register U32 sflags;
    register int dtype;
    register int stype;

    if (sstr == dstr)
	return;
    if (SvTHINKFIRST(dstr)) {
	if (SvREADONLY(dstr) && curcop != &compiling)
	    croak(no_modify);
	if (SvROK(dstr))
	    sv_unref(dstr);
    }
    if (!sstr)
	sstr = &sv_undef;
    stype = SvTYPE(sstr);
    dtype = SvTYPE(dstr);

    if (dtype == SVt_PVGV && (SvFLAGS(dstr) & SVf_FAKE)) {
        sv_unglob(dstr);     /* so fake GLOB won't perpetuate */
	sv_setpvn(dstr, "", 0);
        (void)SvPOK_only(dstr);
        dtype = SvTYPE(dstr);
    }

#ifdef OVERLOAD
    SvAMAGIC_off(dstr);
#endif /* OVERLOAD */
    /* There's a lot of redundancy below but we're going for speed here */

    switch (stype) {
    case SVt_NULL:
	(void)SvOK_off(dstr);
	return;
    case SVt_IV:
	if (dtype != SVt_IV && dtype < SVt_PVIV) {
	    if (dtype < SVt_IV)
		sv_upgrade(dstr, SVt_IV);
	    else if (dtype == SVt_NV)
		sv_upgrade(dstr, SVt_PVNV);
	    else
		sv_upgrade(dstr, SVt_PVIV);
	}
	break;
    case SVt_NV:
	if (dtype != SVt_NV && dtype < SVt_PVNV) {
	    if (dtype < SVt_NV)
		sv_upgrade(dstr, SVt_NV);
	    else
		sv_upgrade(dstr, SVt_PVNV);
	}
	break;
    case SVt_RV:
	if (dtype < SVt_RV)
	    sv_upgrade(dstr, SVt_RV);
	else if (dtype == SVt_PVGV &&
		 SvTYPE(SvRV(sstr)) == SVt_PVGV) {
	    sstr = SvRV(sstr);
	    if (sstr == dstr) {
/*++ 		if (curcop->cop_stash != GvSTASH(dstr)) */
/* 		    GvIMPORTED_on(dstr); */
/* 		GvMULTI_on(dstr); */
		return;
	    }
	    goto glob_assign;
	}
	break;
    case SVt_PV:
    case SVt_PVFM:
	if (dtype < SVt_PV)
	    sv_upgrade(dstr, SVt_PV);
	break;
    case SVt_PVIV:
	if (dtype < SVt_PVIV)
	    sv_upgrade(dstr, SVt_PVIV);
	break;
    case SVt_PVNV:
	if (dtype < SVt_PVNV)
	    sv_upgrade(dstr, SVt_PVNV);
	break;

    case SVt_PVLV:
	sv_upgrade(dstr, SVt_PVLV);
	break;

    case SVt_PVAV:
    case SVt_PVHV:
    case SVt_PVCV:
    case SVt_PVIO:
	if (op)
	    croak("Bizarre copy of %s in [op #%u]", sv_reftype(sstr, 0),
		op->op_type);
	else
	    croak("Bizarre copy of %s", sv_reftype(sstr, 0));
	break;

    case SVt_PVGV:
	if (dtype <= SVt_PVGV) {
  glob_assign:
	    if (dtype != SVt_PVGV) {
/*++ 		char *name = GvNAME(sstr); */
/* 		STRLEN len = GvNAMELEN(sstr); */
/* 		sv_upgrade(dstr, SVt_PVGV); */
/* 		sv_magic(dstr, dstr, '*', name, len); */
/* 		GvSTASH(dstr) = GvSTASH(sstr); */
/* 		GvNAME(dstr) = savepvn(name, len); */
/* 		GvNAMELEN(dstr) = len; */
/* 		SvFAKE_on(dstr); */	/* can coerce to non-glob */
	    }
	    /* ahem, death to those who redefine active sort subs */
	    else if (curstack == sortstack
		     /*++	&& GvCV(dstr) && sortcop == CvSTART(GvCV(dstr))		++*/	)
		croak("Can't redefine active sort subroutine %s"	/*++	,
		      GvNAME(dstr)	++*/	);
	    (void)SvOK_off(dstr);
/*++ 	    GvINTRO_off(dstr);	 ++*/	/* one-shot flag */
/* 	    gp_free((GV*)dstr); */
/* 	    GvGP(dstr) = gp_ref(GvGP(sstr)); */
/* 	    SvTAINT(dstr); */
/* 	    if (curcop->cop_stash != GvSTASH(dstr)) */
/* 		GvIMPORTED_on(dstr); */
/* 	    GvMULTI_on(dstr); */
	    return;
	}
	/* FALL THROUGH */

    default:
	if (SvGMAGICAL(sstr)) {
	    mg_get(sstr);
	    if (SvTYPE(sstr) != stype) {
		stype = SvTYPE(sstr);
		if (stype == SVt_PVGV && dtype <= SVt_PVGV)
		    goto glob_assign;
	    }
	}
	if (dtype < stype)
	    sv_upgrade(dstr, stype);
    }

    sflags = SvFLAGS(sstr);

    if (sflags & SVf_ROK) {
	if (dtype >= SVt_PV) {
	    if (dtype == SVt_PVGV) {
		SV *sref = SvREFCNT_inc(SvRV(sstr));
		SV *dref = 0;
		int intro = GvINTRO(dstr);

		if (intro) {
/*++ 		    GP *gp; */
/* 		    GvGP(dstr)->gp_refcnt--; */
/* 		    GvINTRO_off(dstr);	 */	/* one-shot flag */
/* 		    Newz(602,gp, 1, GP); */
/* 		    GvGP(dstr) = gp_ref(gp); */
/* 		    GvSV(dstr) = NEWSV(72,0); */
/* 		    GvLINE(dstr) = curcop->cop_line; */
/* 		    GvEGV(dstr) = (GV*)dstr; */
		}
/*++ 		GvMULTI_on(dstr); */
		switch (SvTYPE(sref)) {
		case SVt_PVAV:
/*++ 		    if (intro) */
/* 			SAVESPTR(GvAV(dstr)); */
/* 		    else */
/* 			dref = (SV*)GvAV(dstr); */
/* 		    GvAV(dstr) = (AV*)sref; */
/* 		    if (curcop->cop_stash != GvSTASH(dstr)) */
/* 			GvIMPORTED_AV_on(dstr); */
		    break;
		case SVt_PVHV:
/*++ 		    if (intro) */
/* 			SAVESPTR(GvHV(dstr)); */
/* 		    else */
/* 			dref = (SV*)GvHV(dstr); */
/* 		    GvHV(dstr) = (HV*)sref; */
/* 		    if (curcop->cop_stash != GvSTASH(dstr)) */
/* 			GvIMPORTED_HV_on(dstr); */
		    break;
		case SVt_PVCV:
/*++ 		    if (intro) { */
/* 			if (GvCVGEN(dstr) && GvCV(dstr) != (CV*)sref) { */
/* 			    SvREFCNT_dec(GvCV(dstr)); */
/* 			    GvCV(dstr) = Nullcv; */
/* 			    GvCVGEN(dstr) = 0; */	/* Switch off cacheness. */
/* 			    sub_generation++; */
/* 			} */
/* 			SAVESPTR(GvCV(dstr)); */
/* 		    } */
/* 		    else */
/* 			dref = (SV*)GvCV(dstr); */
/* 		    if (GvCV(dstr) != (CV*)sref) { */
/* 			CV* cv = GvCV(dstr); */
/* 			if (cv) { */
/* 			    if (!GvCVGEN((GV*)dstr) && */
/* 				(CvROOT(cv) || CvXSUB(cv))) */
/* 			    { */
				/* ahem, death to those who redefine
				 * active sort subs */
/* 				if (curstack == sortstack && */
/* 				      sortcop == CvSTART(cv)) */
/* 				    croak( */
/* 				    "Can't redefine active sort subroutine %s", */
/* 					  GvENAME((GV*)dstr)); */
/* 				if (cv_const_sv(cv)) */
/* 				    warn("Constant subroutine %s redefined", */
/* 					 GvENAME((GV*)dstr)); */
/* 				else if (dowarn) */
/* 				    warn("Subroutine %s redefined", */
/* 					 GvENAME((GV*)dstr)); */
/* 			    } */
/* 			    cv_ckproto(cv, (GV*)dstr, */
/* 				       SvPOK(sref) ? SvPVX(sref) : Nullch); */
/* 			} */
/* 			GvCV(dstr) = (CV*)sref; */
/* 			GvCVGEN(dstr) = 0; */ /* Switch off cacheness. */
/* 			GvASSUMECV_on(dstr); */
/* 			sub_generation++; */
/* 		    } */
/* 		    if (curcop->cop_stash != GvSTASH(dstr)) */
/* 			GvIMPORTED_CV_on(dstr); */
		    break;
		case SVt_PVIO:
/*++ 		    if (intro) */
/* 			SAVESPTR(GvIOp(dstr)); */
/* 		    else */
/* 			dref = (SV*)GvIOp(dstr); */
/* 		    GvIOp(dstr) = (IO*)sref; */
		    break;
		default:
/*++ 		    if (intro) */
/* 			SAVESPTR(GvSV(dstr)); */
/* 		    else */
/* 			dref = (SV*)GvSV(dstr); */
/* 		    GvSV(dstr) = sref; */
/* 		    if (curcop->cop_stash != GvSTASH(dstr)) */
/* 			GvIMPORTED_SV_on(dstr); */
		    break;
		}
		if (dref)
		    SvREFCNT_dec(dref);
		if (intro)
		    SAVEFREESV(sref);
		SvTAINT(dstr);
		return;
	    }
	    if (SvPVX(dstr)) {
		(void)SvOOK_off(dstr);		/* backoff */
		Safefree(SvPVX(dstr));
		SvLEN(dstr)=SvCUR(dstr)=0;
	    }
	}
	(void)SvOK_off(dstr);
	SvRV(dstr) = SvREFCNT_inc(SvRV(sstr));
	SvROK_on(dstr);
	if (sflags & SVp_NOK) {
	    SvNOK_on(dstr);
	    SvNVX(dstr) = SvNVX(sstr);
	}
	if (sflags & SVp_IOK) {
	    (void)SvIOK_on(dstr);
	    SvIVX(dstr) = SvIVX(sstr);
	}
#ifdef OVERLOAD
	if (SvAMAGIC(sstr)) {
	    SvAMAGIC_on(dstr);
	}
#endif /* OVERLOAD */
    }
    else if (sflags & SVp_POK) {

	/*
	 * Check to see if we can just swipe the string.  If so, it's a
	 * possible small lose on short strings, but a big win on long ones.
	 * It might even be a win on short strings if SvPVX(dstr)
	 * has to be allocated and SvPVX(sstr) has to be freed.
	 */

	if (SvTEMP(sstr) &&		/* slated for free anyway? */
	    !(sflags & SVf_OOK)) 	/* and not involved in OOK hack? */
	{
	    if (SvPVX(dstr)) {		/* we know that dtype >= SVt_PV */
		if (SvOOK(dstr)) {
		    SvFLAGS(dstr) &= ~SVf_OOK;
		    Safefree(SvPVX(dstr) - SvIVX(dstr));
		}
		else
		    Safefree(SvPVX(dstr));
	    }
	    (void)SvPOK_only(dstr);
	    SvPV_set(dstr, SvPVX(sstr));
	    SvLEN_set(dstr, SvLEN(sstr));
	    SvCUR_set(dstr, SvCUR(sstr));
	    SvTEMP_off(dstr);
	    (void)SvOK_off(sstr);
	    SvPV_set(sstr, Nullch);
	    SvLEN_set(sstr, 0);
	    SvCUR_set(sstr, 0);
	    SvTEMP_off(sstr);
	}
	else {					/* have to copy actual string */
	    STRLEN len = SvCUR(sstr);

	    SvGROW(dstr, len + 1);		/* inlined from sv_setpvn */
	    Move(SvPVX(sstr),SvPVX(dstr),len,char);
	    SvCUR_set(dstr, len);
	    *SvEND(dstr) = '\0';
	    (void)SvPOK_only(dstr);
	}
	/*SUPPRESS 560*/
	if (sflags & SVp_NOK) {
	    SvNOK_on(dstr);
	    SvNVX(dstr) = SvNVX(sstr);
	}
	if (sflags & SVp_IOK) {
	    (void)SvIOK_on(dstr);
	    SvIVX(dstr) = SvIVX(sstr);
	}
    }
    else if (sflags & SVp_NOK) {
	SvNVX(dstr) = SvNVX(sstr);
	(void)SvNOK_only(dstr);
	if (SvIOK(sstr)) {
	    (void)SvIOK_on(dstr);
	    SvIVX(dstr) = SvIVX(sstr);
	}
    }
    else if (sflags & SVp_IOK) {
	(void)SvIOK_only(dstr);
	SvIVX(dstr) = SvIVX(sstr);
    }
    else {
	(void)SvOK_off(dstr);
    }
    SvTAINT(dstr);
}

void
sv_setpvn(sv,ptr,len)
register SV *sv;
register const char *ptr;
register STRLEN len;
{
    assert(len >= 0);  /* STRLEN is probably unsigned, so this may
			  elicit a warning, but it won't hurt. */
    if (SvTHINKFIRST(sv)) {
	if (SvREADONLY(sv) && curcop != &compiling)
	    croak(no_modify);
	if (SvROK(sv))
	    sv_unref(sv);
    }
    if (!ptr) {
	(void)SvOK_off(sv);
	return;
    }
    if (SvTYPE(sv) >= SVt_PV) {
	if (SvFAKE(sv) && SvTYPE(sv) == SVt_PVGV)
	    sv_unglob(sv);
    }
    else if (!sv_upgrade(sv, SVt_PV))
	return;
    SvGROW(sv, len + 1);
    Move(ptr,SvPVX(sv),len,char);
    SvCUR_set(sv, len);
    *SvEND(sv) = '\0';
    (void)SvPOK_only(sv);		/* validate pointer */
    SvTAINT(sv);
}

void
sv_setpv(sv,ptr)
register SV *sv;
register const char *ptr;
{
    register STRLEN len;

    if (SvTHINKFIRST(sv)) {
	if (SvREADONLY(sv) && curcop != &compiling)
	    croak(no_modify);
	if (SvROK(sv))
	    sv_unref(sv);
    }
    if (!ptr) {
	(void)SvOK_off(sv);
	return;
    }
    len = strlen(ptr);
    if (SvTYPE(sv) >= SVt_PV) {
	if (SvFAKE(sv) && SvTYPE(sv) == SVt_PVGV)
	    sv_unglob(sv);
    }
    else if (!sv_upgrade(sv, SVt_PV))
	return;
    SvGROW(sv, len + 1);
    Move(ptr,SvPVX(sv),len+1,char);
    SvCUR_set(sv, len);
    (void)SvPOK_only(sv);		/* validate pointer */
    SvTAINT(sv);
}

void
sv_catpvn(sv,ptr,len)
register SV *sv;
register char *ptr;
register STRLEN len;
{
    STRLEN tlen;
    char *junk;

    junk = SvPV_force(sv, tlen);
    SvGROW(sv, tlen + len + 1);
    if (ptr == junk)
	ptr = SvPVX(sv);
    Move(ptr,SvPVX(sv)+tlen,len,char);
    SvCUR(sv) += len;
    *SvEND(sv) = '\0';
    (void)SvPOK_only(sv);		/* validate pointer */
    SvTAINT(sv);
}

static void
sv_catpv(sv,ptr)
register SV *sv;
register char *ptr;
{
    register STRLEN len;
    STRLEN tlen;
    char *junk;

    if (!ptr)
	return;
    junk = SvPV_force(sv, tlen);
    len = strlen(ptr);
    SvGROW(sv, tlen + len + 1);
    if (ptr == junk)
	ptr = SvPVX(sv);
    Move(ptr,SvPVX(sv)+tlen,len+1,char);
    SvCUR(sv) += len;
    (void)SvPOK_only(sv);		/* validate pointer */
    SvTAINT(sv);
}

static SV *
#ifdef LEAKTEST
newSV(x,len)
I32 x;
#else
newSV(len)
#endif
STRLEN len;
{
    register SV *sv;
    
    new_SV(sv);
    SvANY(sv) = 0;
    SvREFCNT(sv) = 1;
    SvFLAGS(sv) = 0;
    if (len) {
	sv_upgrade(sv, SVt_PV);
	SvGROW(sv, len + 1);
    }
    return sv;
}

/* name is assumed to contain an SV* if (name && namelen == HEf_SVKEY) */

void
sv_magic(sv, obj, how, name, namlen)
register SV *sv;
SV *obj;
int how;
char *name;
I32 namlen;
{
#if 0
    MAGIC_T* mg;
    
    if (SvREADONLY(sv) && curcop != &compiling && !strchr("gBf", how))
	croak(no_modify);
    if (SvMAGICAL(sv) || (how == 't' && SvTYPE(sv) >= SVt_PVMG)) {
	if (SvMAGIC(sv) && (mg = mg_find(sv, how))) {
	    if (how == 't')
		mg->mg_len |= 1;
	    return;
	}
    }
    else {
	if (!SvUPGRADE(sv, SVt_PVMG))
	    return;
    }
    Newz(702,mg, 1, MAGIC_T);
    mg->mg_moremagic = SvMAGIC(sv);

    SvMAGIC(sv) = mg;
    if (!obj || obj == sv || how == '#')
	mg->mg_obj = obj;
    else {
	mg->mg_obj = SvREFCNT_inc(obj);
	mg->mg_flags |= MGf_REFCOUNTED;
    }
    mg->mg_type = how;
    mg->mg_len = namlen;
    if (name)
	if (namlen >= 0)
	    mg->mg_ptr = savepvn(name, namlen);
	else if (namlen == HEf_SVKEY)
	    mg->mg_ptr = (char*)SvREFCNT_inc((SV*)name);
    
    switch (how) {
    case 0:
	mg->mg_virtual = &vtbl_sv;
	break;
#ifdef OVERLOAD
    case 'A':
        mg->mg_virtual = &vtbl_amagic;
        break;
    case 'a':
        mg->mg_virtual = &vtbl_amagicelem;
        break;
    case 'c':
        mg->mg_virtual = 0;
        break;
#endif /* OVERLOAD */
    case 'B':
	mg->mg_virtual = &vtbl_bm;
	break;
    case 'E':
	mg->mg_virtual = &vtbl_env;
	break;
    case 'f':
	mg->mg_virtual = &vtbl_fm;
	break;
    case 'e':
	mg->mg_virtual = &vtbl_envelem;
	break;
    case 'g':
	mg->mg_virtual = &vtbl_mglob;
	break;
    case 'I':
	mg->mg_virtual = &vtbl_isa;
	break;
    case 'i':
	mg->mg_virtual = &vtbl_isaelem;
	break;
    case 'k':
	mg->mg_virtual = &vtbl_nkeys;
	break;
    case 'L':
	SvRMAGICAL_on(sv);
	mg->mg_virtual = 0;
	break;
    case 'l':
	mg->mg_virtual = &vtbl_dbline;
	break;
#ifdef USE_LOCALE_COLLATE
    case 'o':
        mg->mg_virtual = &vtbl_collxfrm;
        break;
#endif /* USE_LOCALE_COLLATE */
    case 'P':
	mg->mg_virtual = &vtbl_pack;
	break;
    case 'p':
    case 'q':
	mg->mg_virtual = &vtbl_packelem;
	break;
    case 'S':
	mg->mg_virtual = &vtbl_sig;
	break;
    case 's':
	mg->mg_virtual = &vtbl_sigelem;
	break;
    case 't':
	mg->mg_virtual = &vtbl_taint;
	mg->mg_len = 1;
	break;
    case 'U':
	mg->mg_virtual = &vtbl_uvar;
	break;
    case 'v':
	mg->mg_virtual = &vtbl_vec;
	break;
    case 'x':
	mg->mg_virtual = &vtbl_substr;
	break;
    case 'y':
	mg->mg_virtual = &vtbl_defelem;
	break;
    case '*':
	mg->mg_virtual = &vtbl_glob;
	break;
    case '#':
	mg->mg_virtual = &vtbl_arylen;
	break;
    case '.':
	mg->mg_virtual = &vtbl_pos;
	break;
    case '~':	/* Reserved for use by extensions not perl internals.	*/
	/* Useful for attaching extension internal data to perl vars.	*/
	/* Note that multiple extensions may clash if magical scalars	*/
	/* etc holding private data from one are passed to another.	*/
	SvRMAGICAL_on(sv);
	break;
    default:
	croak("Don't know how to handle magic of type '%c'", how);
    }
    mg_magical(sv);
    if (SvGMAGICAL(sv))
	SvFLAGS(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);
#endif
}

static int
sv_unmagic(sv, type)
SV* sv;
int type;
{
#if 0
    MAGIC_T* mg;
    MAGIC_T** mgp;
    if (SvTYPE(sv) < SVt_PVMG || !SvMAGIC(sv))
	return 0;
    mgp = &SvMAGIC(sv);
    for (mg = *mgp; mg; mg = *mgp) {
	if (mg->mg_type == type) {
	    MGVTBL* vtbl = mg->mg_virtual;
	    *mgp = mg->mg_moremagic;
	    if (vtbl && vtbl->svt_free)
		(*vtbl->svt_free)(sv, mg);
	    if (mg->mg_ptr && mg->mg_type != 'g')
		if (mg->mg_len >= 0)
		    Safefree(mg->mg_ptr);
		else if (mg->mg_len == HEf_SVKEY)
		    SvREFCNT_dec((SV*)mg->mg_ptr);
	    if (mg->mg_flags & MGf_REFCOUNTED)
		SvREFCNT_dec(mg->mg_obj);
	    Safefree(mg);
	}
	else
	    mgp = &mg->mg_moremagic;
    }
    if (!SvMAGIC(sv)) {
	SvMAGICAL_off(sv);
	SvFLAGS(sv) |= (SvFLAGS(sv) & (SVp_IOK|SVp_NOK|SVp_POK)) >> PRIVSHIFT;
    }
#endif
    return 0;
}

static void
sv_clear(sv)
register SV *sv;
{

    assert(sv);
    assert(SvREFCNT(sv) == 0);

    if (SvOBJECT(sv)) {
	if (defstash) {		/* Still have a symbol table? */
	    dSP;
#if 0
	    GV* destructor;

	    ENTER;
	    SAVEFREESV(SvSTASH(sv));

	    destructor = gv_fetchmethod(SvSTASH(sv), "DESTROY");
	    if (destructor) {
		SV ref;

		Zero(&ref, 1, SV);
		sv_upgrade(&ref, SVt_RV);
		SvRV(&ref) = SvREFCNT_inc(sv);
		SvROK_on(&ref);
		SvREFCNT(&ref) = 1;	/* Fake, but otherwise
					   creating+destructing a ref
					   leads to disaster. */

		EXTEND(SP, 2);
		PUSHMARK(SP);
		PUSHs(&ref);
		PUTBACK;
		perl_call_sv((SV*)GvCV(destructor),
			     G_DISCARD|G_EVAL|G_KEEPERR);
		del_XRV(SvANY(&ref));
		SvREFCNT(sv)--;
	    }

	    LEAVE;
#endif
	}
	else
	    SvREFCNT_dec(SvSTASH(sv));
	if (SvOBJECT(sv)) {
	    SvOBJECT_off(sv);	/* Curse the object. */
	    if (SvTYPE(sv) != SVt_PVIO)
		--sv_objcount;	/* XXX Might want something more general */
	}
	if (SvREFCNT(sv)) {
		return;
	}
    }
    if (SvTYPE(sv) >= SVt_PVMG && SvMAGIC(sv))
	mg_free(sv);
    switch (SvTYPE(sv)) {
    case SVt_PVIO:
/*++ 	if (IoIFP(sv) != PerlIO_stdin() && */
/* 	    IoIFP(sv) != PerlIO_stdout() && */
/* 	    IoIFP(sv) != PerlIO_stderr()) */
/* 	  io_close((IO*)sv); */
/* 	Safefree(IoTOP_NAME(sv)); */
/* 	Safefree(IoFMT_NAME(sv)); */
/* 	Safefree(IoBOTTOM_NAME(sv)); */
	/* FALL THROUGH */
    case SVt_PVBM:
	goto freescalar;
    case SVt_PVCV:
    case SVt_PVFM:
	cv_undef((CV*)sv);
	goto freescalar;
    case SVt_PVHV:
	hv_undef((HV*)sv);
	break;
    case SVt_PVAV:
	av_undef((AV*)sv);
	break;
    case SVt_PVGV:
	gp_free((GV*)sv);
	Safefree(GvNAME(sv));
	/* FALL THROUGH */
    case SVt_PVLV:
    case SVt_PVMG:
    case SVt_PVNV:
    case SVt_PVIV:
      freescalar:
	(void)SvOOK_off(sv);
	/* FALL THROUGH */
    case SVt_PV:
    case SVt_RV:
	if (SvROK(sv))
	    SvREFCNT_dec(SvRV(sv));
	else if (SvPVX(sv) && SvLEN(sv))
	    Safefree(SvPVX(sv));
	break;
/*
    case SVt_NV:
    case SVt_IV:
    case SVt_NULL:
	break;
*/
    }

    switch (SvTYPE(sv)) {
    case SVt_NULL:
	break;
    case SVt_IV:
	del_XIV(SvANY(sv));
	break;
    case SVt_NV:
	del_XNV(SvANY(sv));
	break;
    case SVt_RV:
	del_XRV(SvANY(sv));
	break;
    case SVt_PV:
	del_XPV(SvANY(sv));
	break;
    case SVt_PVIV:
	del_XPVIV(SvANY(sv));
	break;
    case SVt_PVNV:
	del_XPVNV(SvANY(sv));
	break;
    case SVt_PVMG:
	del_XPVMG(SvANY(sv));
	break;
    case SVt_PVLV:
	del_XPVLV(SvANY(sv));
	break;
    case SVt_PVAV:
	del_XPVAV(SvANY(sv));
	break;
    case SVt_PVHV:
	del_XPVHV(SvANY(sv));
	break;
    case SVt_PVCV:
	del_XPVCV(SvANY(sv));
	break;
    case SVt_PVGV:
	del_XPVGV(SvANY(sv));
	break;
    case SVt_PVBM:
	del_XPVBM(SvANY(sv));
	break;
    case SVt_PVFM:
	del_XPVFM(SvANY(sv));
	break;
    case SVt_PVIO:
	del_XPVIO(SvANY(sv));
	break;
    }
    SvFLAGS(sv) &= SVf_BREAK;
    SvFLAGS(sv) |= SVTYPEMASK;
}

static SV *
sv_newref(sv)
SV* sv;
{
    if (sv)
	SvREFCNT(sv)++;
    return sv;
}

void
sv_free(sv)
SV *sv;
{
    if (!sv)
	return;
    if (SvREADONLY(sv)) {
	if (sv == &sv_undef || sv == &sv_yes || sv == &sv_no)
	    return;
    }
    if (SvREFCNT(sv) == 0) {
	if (SvFLAGS(sv) & SVf_BREAK)
	    return;
	warn("Attempt to free unreferenced scalar");
	return;
    }
    if (--SvREFCNT(sv) > 0)
	return;
#ifdef DEBUGGING
    if (SvTEMP(sv)) {
	warn("Attempt to free temp prematurely");
	return;
    }
#endif
    sv_clear(sv);
    if (! SvREFCNT(sv))
	del_SV(sv);
}

/* Make a string that will exist for the duration of the expression
 * evaluation.  Actually, it may have to last longer than that, but
 * hopefully we won't free it until it has been assigned to a
 * permanent location. */

static void
sv_mortalgrow()
{
    tmps_max += (tmps_max < 512) ? 128 : 512;
    Renew(tmps_stack, tmps_max, SV*);
}

SV *
sv_newmortal()
{
    register SV *sv;

    new_SV(sv);
    SvANY(sv) = 0;
    SvREFCNT(sv) = 1;
    SvFLAGS(sv) = SVs_TEMP;
    if (++tmps_ix >= tmps_max)
	sv_mortalgrow();
    tmps_stack[tmps_ix] = sv;
    return sv;
}

/* same thing without the copying */

static SV *
sv_2mortal(sv)
register SV *sv;
{
    if (!sv)
	return sv;
    if (SvREADONLY(sv) && curcop != &compiling)
	croak(no_modify);
    if (++tmps_ix >= tmps_max)
	sv_mortalgrow();
    tmps_stack[tmps_ix] = sv;
    SvTEMP_on(sv);
    return sv;
}

SV *
newSVpv(s,len)
char *s;
STRLEN len;
{
    register SV *sv;

    new_SV(sv);
    SvANY(sv) = 0;
    SvREFCNT(sv) = 1;
    SvFLAGS(sv) = 0;
    if (!len)
	len = strlen(s);
    sv_setpvn(sv,s,len);
    return sv;
}

static SV *
newRV(ref)
SV *ref;
{
    register SV *sv;

    new_SV(sv);
    SvANY(sv) = 0;
    SvREFCNT(sv) = 1;
    SvFLAGS(sv) = 0;
    sv_upgrade(sv, SVt_RV);
    SvTEMP_off(ref);
    SvRV(sv) = SvREFCNT_inc(ref);
    SvROK_on(sv);
    return sv;
}

#ifdef CRIPPLED_CC
SV *
newRV_noinc(ref)
SV *ref;
{
    register SV *sv;

    sv = newRV(ref);
    SvREFCNT_dec(ref);
    return sv;
}
#endif /* CRIPPLED_CC */


#ifndef SvIV
IV
SvIV(sv)
register SV *sv;
{
    if (SvIOK(sv))
	return SvIVX(sv);
    return sv_2iv(sv);
}
#endif /* !SvIV */

#ifndef SvUV
UV
SvUV(sv)
register SV *sv;
{
    if (SvIOK(sv))
	return SvUVX(sv);
    return sv_2uv(sv);
}
#endif /* !SvUV */

#ifndef SvNV
double
SvNV(sv)
register SV *sv;
{
    if (SvNOK(sv))
	return SvNVX(sv);
    return sv_2nv(sv);
}
#endif /* !SvNV */


static char *
sv_pvn_force(sv, lp)
SV *sv;
STRLEN *lp;
{
    char *s;

    if (SvREADONLY(sv) && curcop != &compiling)
	croak(no_modify);
    
    if (SvPOK(sv)) {
	*lp = SvCUR(sv);
    }
    else {
	if (SvTYPE(sv) > SVt_PVLV && SvTYPE(sv) != SVt_PVFM) {
	    if (SvFAKE(sv) && SvTYPE(sv) == SVt_PVGV) {
		sv_unglob(sv);
		s = SvPVX(sv);
		*lp = SvCUR(sv);
	    }
	    else
		croak("Can't coerce %s to string in [op #%u]", sv_reftype(sv,0),
		    op->op_type);
	}
	else
	    s = sv_2pv(sv, lp);
	if (s != SvPVX(sv)) {	/* Almost, but not quite, sv_setpvn() */
	    STRLEN len = *lp;
	    
	    if (SvROK(sv))
		sv_unref(sv);
	    (void)SvUPGRADE(sv, SVt_PV);		/* Never FALSE */
	    SvGROW(sv, len + 1);
	    Move(s,SvPVX(sv),len,char);
	    SvCUR_set(sv, len);
	    *SvEND(sv) = '\0';
	}
	if (!SvPOK(sv)) {
	    SvPOK_on(sv);		/* validate pointer */
	    SvTAINT(sv);
	    DEBUG_c(PerlIO_printf(Perl_debug_log, "0x%lx 2pv(%s)\n",
		(unsigned long)sv,SvPVX(sv)));
	}
    }
    return SvPVX(sv);
}

static char *
sv_reftype(sv, ob)
SV* sv;
int ob;
{
    if (ob && SvOBJECT(sv))
	return /*++	HvNAME(SvSTASH(sv))	++*/ (char*) 0;
    else {
	switch (SvTYPE(sv)) {
	case SVt_NULL:
	case SVt_IV:
	case SVt_NV:
	case SVt_RV:
	case SVt_PV:
	case SVt_PVIV:
	case SVt_PVNV:
	case SVt_PVMG:
	case SVt_PVBM:
				if (SvROK(sv))
				    return "REF";
				else
				    return "SCALAR";
	case SVt_PVLV:		return "LVALUE";
	case SVt_PVAV:		return "ARRAY";
	case SVt_PVHV:		return "HASH";
	case SVt_PVCV:		return "CODE";
	case SVt_PVGV:		return "GLOB";
	case SVt_PVFM:		return "FORMLINE";
	default:		return "UNKNOWN";
	}
    }
}

static void
sv_unglob(sv)
SV* sv;
{
    assert(SvTYPE(sv) == SVt_PVGV);
    SvFAKE_off(sv);
    if (GvGP(sv))
	gp_free((GV*)sv);
    sv_unmagic(sv, '*');
    Safefree(GvNAME(sv));
/*++	GvMULTI_off(sv); 	++*/
    SvFLAGS(sv) &= ~SVTYPEMASK;
    SvFLAGS(sv) |= SVt_PVMG;
}

static void
sv_unref(sv)
SV* sv;
{
    SV* rv = SvRV(sv);
    
    SvRV(sv) = 0;
    SvROK_off(sv);
    if (SvREFCNT(rv) != 1 || SvREADONLY(rv))
	SvREFCNT_dec(rv);
    else
	sv_2mortal(rv);		/* Schedule for freeing later */
}

static void
sv_taint(sv)
SV *sv;
{
    sv_magic((sv), Nullsv, 't', Nullch, 0);
}

static void
sv_setpviv(sv, iv)
SV *sv;
IV iv;
{
    STRLEN len;
    char buf[TYPE_DIGITS(UV)];
    char *ptr = buf + sizeof(buf);
    int sign;
    UV uv;
    char *p;
    int i;

    sv_setpvn(sv, "", 0);
    if (iv >= 0) {
	uv = iv;
	sign = 0;
    } else {
	uv = -iv;
	sign = 1;
    }
    do {
	*--ptr = '0' + (uv % 10);
    } while (uv /= 10);
    len = (buf + sizeof(buf)) - ptr;
    /* taking advantage of SvCUR(sv) == 0 */
    SvGROW(sv, sign + len + 1);
    p = SvPVX(sv);
    if (sign)
	*p++ = '-';
    memcpy(p, ptr, len);
    p += len;
    *p = '\0';
    SvCUR(sv) = p - SvPVX(sv);
}

