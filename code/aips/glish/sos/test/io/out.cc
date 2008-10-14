// Copyright (c) 1997 Associated Universities Inc.
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/time.h>
#include <unistd.h>
#include <iostream.h>
#include "sos/header.h"
#include "sos/mdep.h"
#include "sos/io.h"
#include "sos/str.h"

//
// g++ -I../.. -I../../include -o out out.cc ../../convert.cc ../../header.cc ../../io.cc ../../longint.cc ../../types.cc ../../str.cc
//
//	note: str.cc is not needed if 'ENABLE_STR' is not defined
//

#define WORDFILE "/usr/dict/words"
#if defined(VAX)
#include <cvt.h>
void to_vaxf(float*, unsigned int);
void to_vaxd(double*, unsigned int);
void to_vaxg(double*, unsigned int);
#endif

#define I_PERLINE 15
#define C_PERLINE 30
#define F_PERLINE 10
#define D_PERLINE 7

const char *words[80] = {
        "AA",           "abc",         "abhorred",     "abominate",
        "AAS",          "abdicate",    "abhorrent",    "aboriginal",
        "ardvark",      "abdomen",     "abide",        "aborigine",
        "arhus",        "abdominal",   "Abidjan",      "aborning",
        "aron",         "abduct",      "Abigail",      "abort",
        "BA",           "Abe",         "abject",       "abound",
        "baba",         "abed",        "abjure",       "about",
        "back",         "Abel",        "ablate",       "above",
        "bacus",        "Abelian",     "ablaze",       "aboveboard",
        "abalone",      "Abelson",     "able",         "aboveground",
        "abandon",      "Aberdeen",    "ablution",     "abovementioned",
        "abase",        "Abernathy",   "abnegation",   "abrade",
        "abash",        "aberrant",    "Abner",        "Abraham",
        "abate",        "aberrate",    "abnormal",     "Abram",
        "abbas",        "abet",        "Abo",          "Abramson",
        "abbe",         "abetted",     "aboard",       "abrasion",
        "abbey",        "abetting",    "abode",        "abrasive",
        "abbot",        "abeyance",    "abolish",      "abreact",
        "Abbott",       "abeyant",     "abolition",    "abreast",
        "abbreviate",   "abhor",       "abominable",   "abridge"
};

main(int argc, char **argv)
	{
	int x = 0;
	int il = 90;
	int *i_ = (int*) malloc(sos_header::iSize()+sizeof(int)*il);
	int *i = (int*)(((char*)i_) + sos_header::iSize());
	int sl = 256;
	short *s_ = (short*) malloc(sos_header::iSize()+sizeof(short)*sl);
	short *s = (short*)(((char*)s_) + sos_header::iSize());
	int bl = 128;
	byte *b_ = (byte*) malloc(sos_header::iSize()+sizeof(byte)*bl);
	byte *b = (byte*)((((char*)b_) + sos_header::iSize()));
	int fl = 53;
	float *f_ = (float*) malloc(sos_header::iSize()+sizeof(float)*fl);
	float *f = (float*)((((char*)f_) + sos_header::iSize()));
	int dl = 53;
	double *d_ = (double*) malloc(sos_header::iSize()+sizeof(double)*dl);
	double *d = (double*)((((char*)d_) + sos_header::iSize()));
	int dl1 = 41;
	double *d1_ = (double*) malloc(sos_header::iSize()+sizeof(double)*dl1);
	double *d1 = (double*)((((char*)d1_) + sos_header::iSize()));

	char *file = "t.out";
	if ( argc > 1 ) file = argv[1];

	cout << "---- ---- ---- ---- ----" << endl;
	for (x = 1; x <= il; x++) { i[x-1] = x * x; cout << i[x-1] << ((x % I_PERLINE) ? " " : "\n"); }
	cout << endl << "---- ---- ---- ---- ----" << endl;
	for (x = 1; x <= sl; x++) { s[x-1] = x + x; cout << s[x-1] << ((x % I_PERLINE) ? " " : "\n"); }
	cout << endl << "---- ---- ---- ---- ----" << endl;
	for (x = 1; x <= bl; x++) { b[x-1] = x; cout << b[x-1] << ((x % C_PERLINE) ? " " : "\n"); }
	cout << endl << "---- ---- ---- ---- ----" << endl;
	for (x = 1; x <= fl; x++) { f[x-1] = sin((double)x); printf("%.4g%s",f[x-1],((x % F_PERLINE) ? " " : "\n")); }
 	cout << endl << "---- ---- ---- ---- ----" << endl;
	for (x = 1; x <= dl; x++) { d[x-1] = exp((double)x); printf("%.4g%s",d[x-1],((x % D_PERLINE) ? " " : "\n")); }
	cout << endl << "---- ---- ---- ---- ----" << endl;
	for (x = 1; x <= dl1; x++) { d1[x-1] = cos((double)x); printf("%.4g%s",d1[x-1],((x % D_PERLINE) ? " " : "\n")); }

	cout << endl;

	sos_fd_sink SO( open(file,O_WRONLY|O_CREAT,0644) );
	sos_out so( SO, 1 );
	so.put(i_,il);
	so.put(s_,sl);
	so.put(b_,bl);

#if defined(VAX)
	to_vaxf(f,fl);
	so.put((char*)f_,fl,SOS_VFLOAT);
	to_vaxd(d,dl);
	so.put((char*)d_,dl,SOS_DVDOUBLE);
	to_vaxg(d1,dl1);
	so.put((char*)d1_,dl1,SOS_GVDOUBLE);
#else
	so.put(f_,fl);
	so.put(d_,dl);
	so.put(d1_,dl1);
#endif

	cout << "---- ---- ---- ---- ----" << endl;

#if defined(STR)
	str S(80);
	for ( int W = 0; W < S.length(); W++ )
		{
		S[W] = words[W];
		printf("%d: %s\n",W,S.get(W));
		}
	cout << endl;
	so.put(S);
#else
	char *S[80];
	for ( int W = 0; W < 80; W++ )
		{
		S[W] = strdup(words[W]);
		printf("%d: %s\n",W,S[W]);
		}
	cout << endl;
	so.put(S, 80);
#endif

	so.flush( );
	}

#if defined(VAX)
extern float *vax2ieee_single(float *, unsigned int len);
void to_vaxf(float *f, unsigned int l)
	{
	fprintf(stderr,"==============================\n");
	for ( int i=0; i < l; i++, f++ )
		{
		float tmp = *f;
		cvt_ftof( &tmp, CVT_IEEE_S, f, CVT_VAX_F, 0 );
		float tmp1 = 0;
		cvt_ftof( f, CVT_VAX_F, &tmp1, CVT_IEEE_S, 0 );
		float tmp2 = *f;
		vax2ieee_single(&tmp2,1);
		fprintf(stderr,"%.4g\t%.4g\t%.4g\n",tmp,tmp1,tmp2);
		}
	}
void to_vaxd(double *d, unsigned int l)
	{
	fprintf(stderr,"==============================\n");
	for ( int i=0; i < l; i++, d++ )
		{
		double tmp = *d;
		cvt_ftof( &tmp, CVT_IEEE_T, d, CVT_VAX_D, 0 );
		double tmp1 = 0;
		cvt_ftof( d, CVT_VAX_D, &tmp1, CVT_IEEE_T, 0 );
		fprintf(stderr,"%.4g\t%.4g\n",tmp,tmp1);
		}
	}
void to_vaxg(double *d, unsigned int l)
	{
	fprintf(stderr,"==============================\n");
	for ( int i=0; i < l; i++, d++ )
		{
		double tmp = *d;
		cvt_ftof( &tmp, CVT_IEEE_T, d, CVT_VAX_G, 0 );
		double tmp1 = 0;
		cvt_ftof( d, CVT_VAX_G, &tmp1, CVT_IEEE_T, 0 );
		fprintf(stderr,"%.4g\t%.4g\n",tmp,tmp1);
		
		}
	}
#endif
