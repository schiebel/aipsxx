static char rcsid[]  = "$Id: dvaxf.cc,v 19.0 2003/07/16 05:17:45 aips2adm Exp $";
//======================================================================
// longint.cc
//
// $Id: dvaxf.cc,v 19.0 2003/07/16 05:17:45 aips2adm Exp $
//
// Copyright (c) 1997 Associated Universities Inc.
//
//======================================================================
//
//  compile line goes something like:
//
//	g++ -I../.. -I../../include -o dvaxf dvaxf.cc ../../convert.cc ../../longint.cc
//
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/time.h>
#include <unistd.h>

#include "convert.h"

void dumpfloat(float,int);
void dumpdouble(double,int);

main(int argc, char **argv) {
        char *file = "75F";

	float f = 0;
	float xf = 0;
	double d = 0;
	double xd = 0;

	char type = 'F';

	int fd = -1;
        if ( argc > 1 ) file = argv[1];

	int len = strlen(file);
	if ( file[len-1] == 'G' ) type = 'G';
	else if ( file[len-1] == 'D' ) type = 'D';

	fd = open(file,O_RDONLY,0644);
	switch ( type )
		{
		case 'F':
			if ( read(fd,&f,sizeof(f)) <= 0 )
				printf("oops!!\n");
#if defined(sun) || defined(__sun__)
			swap_abcd_dcba((char*)&f,1);
#endif
			dumpfloat(f,1);
			xf = f;
			vax2ieee_single(&xf,1);
			dumpfloat(xf,0);
			dumpfloat(0.75,0);
			printf("%g\n",xf);
			break;
		case 'G':
		case 'D':
			if ( read(fd,&d,sizeof(d)) <= 0 )
				printf("oops!!\n");
#if defined(sun) || defined(__sun__)
			swap_abcd_dcba((char*)&d,2);
#endif
#if defined(__alpha__)
			swap_abcdefgh_efghabcd((char*)&d,1);
#endif
			dumpdouble(d,1);
			xd = d;
			vax2ieee_double(&xd,1,type);
			dumpdouble(xd,0);
			dumpdouble(0.75,0);
			printf("%g\n",xd);
			break;
		}

	close(fd);
}

void dumpfloat(float f,int dointro) {
	int i = 0;
	unsigned char x = 0;
	int j = 0;
	if (dointro) {
	for (i=0; i < sizeof(f)*8; i++)
		{
		if ( i && !(i % 8) ) { printf(" | "); }
		printf("%s%d ",(i<10?" ":""),i);
		}
	printf("\n");}
	for (i=0; i < sizeof(f); i++)
		{
		if ( i ) { printf(" | "); }
		unsigned char x = ((unsigned char*)&f)[i];
		for (j=7; j >= 0; --j)
			printf(" %d ",(x&(1<<j))?1:0);
		}
	printf("\n");
}

void dumpdouble(double f,int dointro) {
	int i = 0;
	unsigned char x = 0;
	int j = 0;
	if (dointro) {
	for (i=0; i < sizeof(f)*8; i++)
		{
		if ( i && !(i % 8) ) { printf(" | "); }
		printf("%s%d ",(i<10?" ":""),i);
		}
	printf("\n");}
	for (i=0; i < sizeof(f); i++)
		{
		if ( i ) { printf(" | "); }
		unsigned char x = ((unsigned char*)&f)[i];
		for (j=7; j >= 0; --j)
			printf(" %d ",(x&(1<<j))?1:0);
		}
	printf("\n");
}
