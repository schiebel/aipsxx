// Copyright (c) 1997 Associated Universities Inc.
#include <stdio.h>
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
// g++ -I../.. -I../../include -o in in.cc ../../convert.cc ../../header.cc ../../io.cc ../../longint.cc ../../types.cc ../../str.cc
//
//	note: str.cc is not needed if 'ENABLE_STR' is not defined
//
#define I_PERLINE 15
#define C_PERLINE 30
#define F_PERLINE 10
#define D_PERLINE 7
main(int argc, char **argv)
	{
	char *file = "t.out";
	if ( argc > 1 ) file = argv[1];
	sos_fd_source SI( open(file,O_RDONLY,0644) );
#if defined(ENABLE_STR)
	sos_in si( SI, 1, 1 );
	str *S;
#else
	sos_in si( SI, 0, 1 );
	char **S;
#endif

	void *iptr = 0;
	sos_code type = SOS_UNKNOWN;
	unsigned int len;
	int *i,x; short *s; byte *b; float *f; double *d;
	sos_header head;

	while ( iptr = si.get( len, type, head ) )
		{
		cerr << head << endl;
		switch ( type ) {
		    case SOS_INT:
			cout << "---- ---- ---- ---- ----" << endl;
		        i = (int*) (((char*)iptr) + sos_header::iSize());
			for (x = 0; x < len; x++) { cout << i[x] << (((x+1) % I_PERLINE) ? " " : "\n"); }
			break;
		    case SOS_BYTE:
			cout << "---- ---- ---- ---- ----" << endl;
		        b = (byte*) (((char*)iptr) + sos_header::iSize());
			for (x = 0; x < len; x++) { cout << b[x] << (((x+1) % C_PERLINE) ? " " : "\n"); }
			break;
		    case SOS_SHORT:
			cout << "---- ---- ---- ---- ----" << endl;
		        s = (short*) (((char*)iptr) + sos_header::iSize());
			for (x = 0; x < len; x++) { cout << s[x] << (((x+1) % I_PERLINE) ? " " : "\n"); }
			break;
		    case SOS_FLOAT:
			cout << "---- ---- ---- ---- ----" << endl;
		        f = (float*) (((char*)iptr) + sos_header::iSize());
			for (x = 0; x < len; x++) { printf("%.4g%s",f[x],(((x+1) % F_PERLINE) ? " " : "\n")); }
			break;
		    case SOS_DOUBLE:
			cout << "---- ---- ---- ---- ----" << endl;
		        d = (double*) (((char*)iptr) + sos_header::iSize());
			for (x = 0; x < len; x++) { printf("%.4g%s",d[x],(((x+1) % D_PERLINE) ? " " : "\n")); }
			break;
		    case SOS_STRING:
			cout << "---- ---- ---- ---- ----" << endl;
#if defined(ENABLE_STR)
		    	S = (str*) iptr;
			for ( x = 0; x < S->length(); x++ ) { printf("%d: %s\n",x,S->get(x)); }
#else
			S = (char**) iptr;
			for ( x = 0; x < len; x++ ) { printf("%d: %s\n",x,S[x]); }
#endif
			break;
		    default:
			continue;
		}
		cout << endl;
		}
	}
