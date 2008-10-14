static char rcsid[]  = "$Id: vaxf.cc,v 19.0 2003/07/16 05:17:45 aips2adm Exp $";
//======================================================================
// longint.cc
//
// $Id: vaxf.cc,v 19.0 2003/07/16 05:17:45 aips2adm Exp $
//
// Copyright (c) 1997 Associated Universities Inc.
//
//======================================================================
//
//  compile line goes something like:
//
//	g++ -I../.. -I../../include -o vaxf vaxf.cc -lm
//
//	NOTE: this only works on DEC machines which have the
//		"cvt_ftof" function in libm.a
//
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/time.h>
#include <unistd.h>

#include <cvt.h>

int do_conversion(char type, void *in, void *out)
	{
	int out_type = 0;
	int in_type = 0;

	switch ( type )
	    {
	    case 'F': out_type = CVT_VAX_F; in_type = CVT_IEEE_S; break;
	    case 'D': out_type = CVT_VAX_D; in_type = CVT_IEEE_T; break;
	    case 'G': out_type = CVT_VAX_G; in_type = CVT_IEEE_T; break;
	    default: return 0;
	    }

	switch ( cvt_ftof( in, in_type, out, out_type, CVT_REPORT_ALL ) )
	    {
	    case CVT_NORMAL: printf("Normal successful conversion\n"); return 1;
	    case CVT_INVALID_INPUT_TYPE: printf("Invalid input_type code\n"); return 0;
	    case CVT_INVALID_OUTPUT_TYPE: printf("Invalid output_type code\n"); return 0;
	    case CVT_INVALID_OPTION: printf("Invalid option argument\n"); return 0;
	    case CVT_RESULT_INFINITE: printf("Conversion produced an infinite result\n"); return 0;
	    case CVT_RESULT_DENORMALIZED: printf("Conversion produced a denormalized result\n"); return 0;
	    case CVT_RESULT_OVERFLOW_RANGE: printf("Conversion yielded an exponent > 60000 (8)\n"); return 0;
	    case CVT_RESULT_UNDERFLOW_RANGE: printf("Conversion yielded an exponent < 20000 (8)\n"); return 0;
	    case CVT_RESULT_UNNORMALIZED: printf("Conversion produced an unnormalized result\n"); return 0;
	    case CVT_RESULT_INVALID: printf("Conversion result is ROP, NaN or closest equivalent (Cray & IBM types return 0)\n"); return 0;
	    case CVT_RESULT_OVERFLOW: printf("Conversion resulted in overflow\n"); return 0;
	    case CVT_RESULT_UNDERFLOW: printf("Conversion resulted in underflow\n"); return 0;
	    case CVT_RESULT_INEXACT: printf("Conversion resulted in a loss of precision\n"); return 0;
	    default: printf("Unknown exit status\n");
	    }
	}

main(int argc, char **argv)
	{
        char file[32];

	float f = 0.75;
	float vaxf = 0;
	double d = 0.75;
	double vaxd = 0;

	float tf = 0;
	char type = 'F';

	int fd = -1;
        if ( argc > 1 ) type = argv[1][0];
	if ( type != 'F' && type != 'G' && type != 'D' )
		return (1);
	sprintf(file,"75%c",type);

	fd = open(file,O_WRONLY|O_CREAT,0644);
	switch ( type )
		{
		case 'F':
			if ( ! do_conversion(type, &f, &vaxf) ) exit(1);
			write(fd,&vaxf,sizeof(vaxf));
			break;
		case 'G':
		case 'D':
			if ( ! do_conversion(type, &d, &vaxd) ) exit(1);
			write(fd,&vaxd,sizeof(vaxd));
			break;
		}

	close(fd);
	}
