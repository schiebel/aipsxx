/*    common.c
 *
 *    $Id: common.c,v 19.0 2003/07/16 05:18:01 aips2adm Exp $
 *    Copyright (c) 1991-1997, Larry Wall
 *    Copyright (c) 1998,1999,2002 Associated Universities Inc.
 *
 *    Scavanged from Perl distribution needed for regex closure...
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#include "config.h"
#include <stdarg.h>
#include <string.h>
#include <stdio.h>
#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif
#include <stdlib.h>
#include <unistd.h>
#include "commonp.h"
#include "sv.h"

char *regprecomp = 0;		/* uncompiled string. */
char *regparse = 0;		/* Input-scan pointer. */
char *regxend = 0;		/* End of input for compile */
char *regcode = 0;		/* Code-emit pointer; &regdummy = don't. */
U16 regflags = 0;		/* are we folding, multilining? */
I32 regsawback = 0;		/* Did we see \1, ...? */
I32 regnaughty = 0;		/* How bad is this pattern? */
I32 regnpar = 0;		/* () count. */
I32 regsize = 0;		/* Code size. */
char regdummy = '\0';
bool sawstudy = FALSE;		/* do fbm_instr on all strings */
bool dowarn = FALSE;

I32 savestack_ix = 0;
char **regstartp = 0;		/* Pointer to startp array. */
char **regendp = 0;		/* Ditto for endp. */
U32 *reglastparen = 0;		/* Similarly for lastparen. */
char *reginput = 0;		/* String-input pointer. */
char regprev ='\n';		/* char before regbol, \n if none */
int multiline = 0;		/* $*--do strings hold >1 line? */
I32 *screamfirst = 0;
I32 *screamnext = 0;
char *regbol = 0;		/* Beginning of input, for ^ check. */
char *regeol = 0;		/* End of input, for $ check. */
char *regtill = 0;		/* How far we are required to go. */

/* fast case folding tables */

unsigned char fold[] = {
	0,	1,	2,	3,	4,	5,	6,	7,
	8,	9,	10,	11,	12,	13,	14,	15,
	16,	17,	18,	19,	20,	21,	22,	23,
	24,	25,	26,	27,	28,	29,	30,	31,
	32,	33,	34,	35,	36,	37,	38,	39,
	40,	41,	42,	43,	44,	45,	46,	47,
	48,	49,	50,	51,	52,	53,	54,	55,
	56,	57,	58,	59,	60,	61,	62,	63,
	64,	'a',	'b',	'c',	'd',	'e',	'f',	'g',
	'h',	'i',	'j',	'k',	'l',	'm',	'n',	'o',
	'p',	'q',	'r',	's',	't',	'u',	'v',	'w',
	'x',	'y',	'z',	91,	92,	93,	94,	95,
	96,	'A',	'B',	'C',	'D',	'E',	'F',	'G',
	'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O',
	'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W',
	'X',	'Y',	'Z',	123,	124,	125,	126,	127,
	128,	129,	130,	131,	132,	133,	134,	135,
	136,	137,	138,	139,	140,	141,	142,	143,
	144,	145,	146,	147,	148,	149,	150,	151,
	152,	153,	154,	155,	156,	157,	158,	159,
	160,	161,	162,	163,	164,	165,	166,	167,
	168,	169,	170,	171,	172,	173,	174,	175,
	176,	177,	178,	179,	180,	181,	182,	183,
	184,	185,	186,	187,	188,	189,	190,	191,
	192,	193,	194,	195,	196,	197,	198,	199,
	200,	201,	202,	203,	204,	205,	206,	207,
	208,	209,	210,	211,	212,	213,	214,	215,
	216,	217,	218,	219,	220,	221,	222,	223,	
	224,	225,	226,	227,	228,	229,	230,	231,
	232,	233,	234,	235,	236,	237,	238,	239,
	240,	241,	242,	243,	244,	245,	246,	247,
	248,	249,	250,	251,	252,	253,	254,	255
};

unsigned char fold_locale[] = {
	0,	1,	2,	3,	4,	5,	6,	7,
	8,	9,	10,	11,	12,	13,	14,	15,
	16,	17,	18,	19,	20,	21,	22,	23,
	24,	25,	26,	27,	28,	29,	30,	31,
	32,	33,	34,	35,	36,	37,	38,	39,
	40,	41,	42,	43,	44,	45,	46,	47,
	48,	49,	50,	51,	52,	53,	54,	55,
	56,	57,	58,	59,	60,	61,	62,	63,
	64,	'a',	'b',	'c',	'd',	'e',	'f',	'g',
	'h',	'i',	'j',	'k',	'l',	'm',	'n',	'o',
	'p',	'q',	'r',	's',	't',	'u',	'v',	'w',
	'x',	'y',	'z',	91,	92,	93,	94,	95,
	96,	'A',	'B',	'C',	'D',	'E',	'F',	'G',
	'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O',
	'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W',
	'X',	'Y',	'Z',	123,	124,	125,	126,	127,
	128,	129,	130,	131,	132,	133,	134,	135,
	136,	137,	138,	139,	140,	141,	142,	143,
	144,	145,	146,	147,	148,	149,	150,	151,
	152,	153,	154,	155,	156,	157,	158,	159,
	160,	161,	162,	163,	164,	165,	166,	167,
	168,	169,	170,	171,	172,	173,	174,	175,
	176,	177,	178,	179,	180,	181,	182,	183,
	184,	185,	186,	187,	188,	189,	190,	191,
	192,	193,	194,	195,	196,	197,	198,	199,
	200,	201,	202,	203,	204,	205,	206,	207,
	208,	209,	210,	211,	212,	213,	214,	215,
	216,	217,	218,	219,	220,	221,	222,	223,	
	224,	225,	226,	227,	228,	229,	230,	231,
	232,	233,	234,	235,	236,	237,	238,	239,
	240,	241,	242,	243,	244,	245,	246,	247,
	248,	249,	250,	251,	252,	253,	254,	255
};

static unsigned char freq[] = {       /* letter frequencies for mixed English/C */
        1,      2,      84,     151,    154,    155,    156,    157,
        165,    246,    250,    3,      158,    7,      18,     29,
        40,     51,     62,     73,     85,     96,     107,    118,
        129,    140,    147,    148,    149,    150,    152,    153,
        255,    182,    224,    205,    174,    176,    180,    217,
        233,    232,    236,    187,    235,    228,    234,    226,
        222,    219,    211,    195,    188,    193,    185,    184,
        191,    183,    201,    229,    181,    220,    194,    162,
        163,    208,    186,    202,    200,    218,    198,    179,
        178,    214,    166,    170,    207,    199,    209,    206,
        204,    160,    212,    216,    215,    192,    175,    173,
        243,    172,    161,    190,    203,    189,    164,    230,
        167,    248,    227,    244,    242,    255,    241,    231,
        240,    253,    169,    210,    245,    237,    249,    247,
        239,    168,    252,    251,    254,    238,    223,    221,
        213,    225,    177,    197,    171,    196,    159,    4,
        5,      6,      8,      9,      10,     11,     12,     13,
        14,     15,     16,     17,     19,     20,     21,     22,
        23,     24,     25,     26,     27,     28,     30,     31,
        32,     33,     34,     35,     36,     37,     38,     39,
        41,     42,     43,     44,     45,     46,     47,     48,
        49,     50,     52,     53,     54,     55,     56,     57,
        58,     59,     60,     61,     63,     64,     65,     66,
        67,     68,     69,     70,     71,     72,     74,     75,
        76,     77,     78,     79,     80,     81,     82,     83,
        86,     87,     88,     89,     90,     91,     92,     93,
        94,     95,     97,     98,     99,     100,    101,    102,
        103,    104,    105,    106,    108,    109,    110,    111,
        112,    113,    114,    115,    116,    117,    119,    120,
        121,    122,    123,    124,    125,    126,    127,    128,
        130,    131,    132,    133,    134,    135,    136,    137,
        138,    139,    141,    142,    143,    144,    145,    146
};

void pmflag(pmfl,ch)
U16* pmfl;
int ch;
{
    if (ch == 'i')
        *pmfl |= PMf_FOLD;
    else if (ch == 'g')
        *pmfl |= PMf_GLOBAL;
    else if (ch == 'c')
        *pmfl |= PMf_CONTINUE;
    else if (ch == 'o')
        *pmfl |= PMf_KEEP;
    else if (ch == 'm')
        *pmfl |= PMf_MULTILINE;
    else if (ch == 's')
        *pmfl |= PMf_SINGLELINE;
    else if (ch == 'x')
        *pmfl |= PMf_EXTENDED;
}

I32 savestack_max = 0;
any_value *savestack = 0;
void savestack_grow()
{
    savestack_max = savestack_max * 3 / 2;
    Renew(savestack, savestack_max, any_value);
}

char *savepvn( char *sv, I32 len) {
    register char *newaddr;

    New(903,newaddr,len+1,char);
    Copy(sv,newaddr,len,char);          /* might not be null terminated */
    newaddr[len] = '\0';                /* is now */
    return newaddr;
}

static void (*regx_error_handler)( const char*, va_list) = 0;

void regxseterror( void (*hdlr)( const char*, va_list ) )
	{
	regx_error_handler = hdlr;
	}

void
croak( const char* pat, ... )
{
    va_list ap;
    va_start(ap, pat);

    if ( regx_error_handler )
	(*regx_error_handler)( pat, ap );

    vprintf(pat,ap);
    printf("\nno handler installed (or handler returned)\n");
    exit(1);
}

char *
ninstr(big, bigend, little, lend)
register char *big;
register char *bigend;
char *little;
char *lend;
{
    register char *s, *x;
    register I32 first = *little;
    register char *littleend = lend;

    if (!first && little >= littleend)
	return big;
    if (bigend - big < littleend - little)
	return Nullch;
    bigend -= littleend - little++;
    while (big <= bigend) {
	if (*big++ != first)
	    continue;
	for (x=big,s=little; s < littleend; /**/ ) {
	    if (*s++ != *x++) {
		s--;
		break;
	    }
	}
	if (s >= littleend)
	    return big-1;
    }
    return Nullch;
}

void
fbm_compile(sv)
SV *sv;
{
    register unsigned char *s;
    register unsigned char *table;
    register U32 i;
    register U32 len = SvCUR(sv);
    I32 rarest = 0;
    U32 frequency = 256;

    if (len > 255)
	return;			/* can't have offsets that big */
    Sv_Grow(sv,len+258);
    table = (unsigned char*)(SvPVX(sv) + len + 1);
    s = table - 2;
    for (i = 0; i < 256; i++) {
	table[i] = len;
    }
    i = 0;
    while (s >= (unsigned char*)(SvPVX(sv)))
    {
	if (table[*s] == len)
	    table[*s] = i;
	s--,i++;
    }
    sv_upgrade(sv, SVt_PVBM);
    sv_magic(sv, Nullsv, 'B', Nullch, 0);	/* deep magic */
    SvVALID_on(sv);

    s = (unsigned char*)(SvPVX(sv));		/* deeper magic */
    for (i = 0; i < len; i++) {
	if (freq[s[i]] < frequency) {
	    rarest = i;
	    frequency = freq[s[i]];
	}
    }
    BmRARE(sv) = s[rarest];
    BmPREVIOUS(sv) = rarest;
    DEBUG_r(PerlIO_printf(Perl_debug_log, "rarest char %c at %d\n",BmRARE(sv),BmPREVIOUS(sv)));
}

char *
fbm_instr(big, bigend, littlestr)
unsigned char *big;
register unsigned char *bigend;
SV *littlestr;
{
    register unsigned char *s;
    register I32 tmp;
    register I32 littlelen;
    register unsigned char *little;
    register unsigned char *table;
    register unsigned char *olds;
    register unsigned char *oldlittle;

    if (SvTYPE(littlestr) != SVt_PVBM || !SvVALID(littlestr)) {
	STRLEN len;
	char *l = SvPV(littlestr,len);
	if (!len)
	    return (char*)big;
	return ninstr((char*)big,(char*)bigend, l, l + len);
    }

    littlelen = SvCUR(littlestr);
    if (SvTAIL(littlestr) && !multiline) {	/* tail anchored? */
	if (littlelen > bigend - big)
	    return Nullch;
	little = (unsigned char*)SvPVX(littlestr);
	s = bigend - littlelen;
	if (*s == *little && memEQ((char*)s,(char*)little,littlelen))
	    return (char*)s;		/* how sweet it is */
	else if (bigend[-1] == '\n' && little[littlelen-1] != '\n'
		 && s > big) {
	    s--;
	    if (*s == *little && memEQ((char*)s,(char*)little,littlelen))
		return (char*)s;
	}
	return Nullch;
    }
    table = (unsigned char*)(SvPVX(littlestr) + littlelen + 1);
    if (--littlelen >= bigend - big)
	return Nullch;
    s = big + littlelen;
    oldlittle = little = table - 2;
    if (s < bigend) {
      top2:
	/*SUPPRESS 560*/
	if (tmp = table[*s]) {
#ifdef POINTERRIGOR
	    if (bigend - s > tmp) {
		s += tmp;
		goto top2;
	    }
#else
	    if ((s += tmp) < bigend)
		goto top2;
#endif
	    return Nullch;
	}
	else {
	    tmp = littlelen;	/* less expensive than calling strncmp() */
	    olds = s;
	    while (tmp--) {
		if (*--s == *--little)
		    continue;
		s = olds + 1;	/* here we pay the price for failure */
		little = oldlittle;
		if (s < bigend)	/* fake up continue to outer loop */
		    goto top2;
		return Nullch;
	    }
	    return (char *)s;
	}
    }
    return Nullch;
}


char *
screaminstr(bigstr, littlestr)
SV *bigstr;
SV *littlestr;
{
    register unsigned char *s, *x;
    register unsigned char *big;
    register I32 pos;
    register I32 previous;
    register I32 first;
    register unsigned char *little;
    register unsigned char *bigend;
    register unsigned char *littleend;

    if ((pos = screamfirst[BmRARE(littlestr)]) < 0) 
	return Nullch;
    little = (unsigned char *)(SvPVX(littlestr));
    littleend = little + SvCUR(littlestr);
    first = *little++;
    previous = BmPREVIOUS(littlestr);
    big = (unsigned char *)(SvPVX(bigstr));
    bigend = big + SvCUR(bigstr);
    while (pos < previous) {
	if (!(pos += screamnext[pos]))
	    return Nullch;
    }
#ifdef POINTERRIGOR
    do {
	if (big[pos-previous] != first)
	    continue;
	for (x=big+pos+1-previous,s=little; s < littleend; /**/ ) {
	    if (x >= bigend)
		return Nullch;
	    if (*s++ != *x++) {
		s--;
		break;
	    }
	}
	if (s == littleend)
	    return (char *)(big+pos-previous);
    } while ( pos += screamnext[pos] );
#else /* !POINTERRIGOR */
    big -= previous;
    do {
	if (big[pos] != first)
	    continue;
	for (x=big+pos+1,s=little; s < littleend; /**/ ) {
	    if (x >= bigend)
		return Nullch;
	    if (*s++ != *x++) {
		s--;
		break;
	    }
	}
	if (s == littleend)
	    return (char *)(big+pos);
    } while ( pos += screamnext[pos] );
#endif /* POINTERRIGOR */
    return Nullch;
}
