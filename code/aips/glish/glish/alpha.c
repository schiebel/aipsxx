/* $Id: alpha.c,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $
** Copyright (c) 1997 Associated Universities Inc.
*/

#include "Glish/glish.h"
RCSID("@(#) $Id: alpha.c,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $")

#ifdef __alpha
#include <stdlib.h>
#include <stdio.h>
#include <ucontext.h>
#include <machine/signal.h>
#include <machine/fpu.h>
#include <limits.h>
#include "system.h"

#define POS_INF 0x7ff0000000000000L
#define NEG_INF 0xfff0000000000000L
#define NAN	0x7fffffffffffffffL

typedef enum { INT, SHORT, BYTE, FLOAT, DOUBLE, UNKNOWN_R } result_type;
typedef enum { DIV, CAST, UNKNOWN_T } op_type;

static op_type glish_alpha_op = UNKNOWN_T;
static result_type glish_alpha_result = UNKNOWN_R;

#define DIV(NAME,TYPE,DEF)						\
void NAME( TYPE *lhs, TYPE *rhs, int lhs_len, int rhs_incr )		\
	{								\
	int i,j;							\
	glish_alpha_op = DIV;						\
	glish_alpha_result = DEF;					\
	for ( i = 0, j = 0; i < lhs_len; ++i, j += rhs_incr )		\
		lhs[i] /= rhs[j];					\
	}

DIV(glish_fdiv,float,FLOAT)
DIV(glish_ddiv,double,DOUBLE)

#define ARY_CAST(NAME,LTYPE,RTYPE,DEF)					\
void NAME( LTYPE *lhs, RTYPE *rhs, int lhs_len, int rhs_incr )		\
	{								\
	int i,j;							\
	glish_alpha_op = CAST;						\
	glish_alpha_result = DEF;					\
	for ( i = 0, j = 0; i < lhs_len; ++i, j += rhs_incr )		\
		lhs[i] = (LTYPE) rhs[j];				\
	}
#define ONE_CAST(NAME,LTYPE,RTYPE,DEF)					\
LTYPE NAME( RTYPE v )							\
	{								\
	glish_alpha_op = CAST;						\
	glish_alpha_result = DEF;					\
	return (LTYPE) v;						\
	}

#define DEFINE_CASTS(to,DEF)						\
	ONE_CAST( PASTE(glish_float_to_,to), to, float, DEF )		\
	ONE_CAST( PASTE(glish_double_to_,to), to, double, DEF )		\
	ARY_CAST( PASTE(glish_ary_float_to_,to), to, float, DEF )	\
	ARY_CAST( PASTE(glish_ary_double_to_,to), to, double, DEF )

DEFINE_CASTS(int,INT)
DEFINE_CASTS(short,SHORT)
DEFINE_CASTS(byte,BYTE)

void glish_func_loop( double (*fn)( double ), double *lhs, double *arg, int len )
	{
	int i;
	for ( i=0; i < len; i++ )
		lhs[i] = (*fn)( arg[i] );
	}


extern int glish_abort_on_fpe;
extern int glish_sigfpe_trap;
void glish_sigfpe (int signal, siginfo_t *sig_code , struct sigcontext *uc_ptr)
	{
	unsigned long result,op1,op2;

	glish_sigfpe_trap = 1;

	if ( glish_abort_on_fpe )
		{
		glish_cleanup( );
		fprintf(stderr,"\n[fatal error, 'floating point exception' (signal %d), exiting]\n", SIGFPE );
		install_signal_handler( SIGFPE, (signal_handler) SIG_DFL );
		kill( getpid(), SIGFPE );
		}

	if ( sig_code->si_code != FPE_FLTUND && sig_code->si_code == FPE_FLTINV )
		{
		/*
		** The format of fp operate instructions on the Alpha are:
		** |31       26|25    21|20    16|15          5|4    0|
		** |  Opcode   |   Fa   |   Fb   |   Function  |  Fc  |
		** Where operands are in Fa and Fb and result goes to Fc.
		*/
		result = uc_ptr->sc_fp_trigger_inst & 0x1fL; 
		op1 = (uc_ptr->sc_fp_trigger_inst & 0x1f0000L) >> 16; 

		if ( glish_alpha_op == CAST )
			{
			if ( uc_ptr->sc_fpregs[op1] == POS_INF )	/* check for +infinity */
				switch ( glish_alpha_result )
					{
				    case INT: uc_ptr->sc_fpregs[result] = INT_MAX; break;
				    case SHORT: uc_ptr->sc_fpregs[result] = SHRT_MAX; break;
				    case BYTE: uc_ptr->sc_fpregs[result] = UCHAR_MAX; break;
				    default: uc_ptr->sc_fpregs[result] = INT_MAX; break;
					}
			else if ( uc_ptr->sc_fpregs[op1] == NEG_INF )	/* check for -infinity */
				switch ( glish_alpha_result )
					{
				    case INT: uc_ptr->sc_fpregs[result] = INT_MIN; break;
				    case SHORT: uc_ptr->sc_fpregs[result] = SHRT_MIN; break;
				    case BYTE: uc_ptr->sc_fpregs[result] = 0; break;
				    default: uc_ptr->sc_fpregs[result] = INT_MIN; break;
					}
			else
				uc_ptr->sc_fpregs[result] = 0;
			}

		else
			uc_ptr->sc_fpregs[result] = NAN;		/* should only be for "0/0" */

		glish_sigfpe_trap = 0;
		}

	uc_ptr->sc_pc += 4;
	}

#endif
