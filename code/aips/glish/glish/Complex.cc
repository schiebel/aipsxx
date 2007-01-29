// $Id: Complex.cc,v 19.13 2004/11/03 20:38:57 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,2000 Associated Universities Inc.

#include "config.h"
#include "Glish/glish.h"
RCSID("@(#) $Id: Complex.cc,v 19.13 2004/11/03 20:38:57 cvsmgr Exp $")
#include "Glish/Complex.h"

//
// this because it's not defined in the HPUX11 includes
//
#if !defined(HUGE)
#if defined(HUGE_VAL)
#define HUGE HUGE_VAL
#else
#define HUGE (infinity())
#endif
#endif

// Defined in "Value.cc".
extern glish_dcomplex text_to_dcomplex( const char text[], int& successful );

glish_complex atocpx( const char text[] )
	{
	return glish_complex( atodcpx( text ) );
	}

glish_dcomplex atodcpx( const char text[] )
	{
	int successful;
	glish_dcomplex dr = text_to_dcomplex( text, successful );
	return successful ? dr : glish_dcomplex( 0.0, 0.0 );
	}

#define sqr(x) ((x) * (x))

#ifdef _AIX
static float local_zero = 0.0;
#define DIV_BY_ZERO (1.0/local_zero)
#else
#define DIV_BY_ZERO (1.0/0.0)
#endif
#define COMPLEX_DIV_OP(type,cast)					\
type div( const type divd, const type dsor )				\
	{								\
	double y = sqr( dsor.r ) + sqr( dsor.i );			\
	double p = divd.r * dsor.r + divd.i * dsor.i;			\
	double q = divd.i * dsor.r - divd.r * dsor.i;			\
									\
	if ( y < 1.0 )							\
		{							\
		double w = HUGE * y;					\
		/*** OVERFLOW ***/					\
		if ( fabs( p ) > w || fabs( q ) > w || y == 0.0 )	\
			return type( cast(DIV_BY_ZERO), cast(DIV_BY_ZERO) ); \
		}							\
	return type( cast( p / y ), cast( q / y ) );			\
	}

COMPLEX_DIV_OP(glish_dcomplex,double)
COMPLEX_DIV_OP(glish_complex,float)

glish_dcomplex exp( const glish_dcomplex v ) 
	{
	double r = exp( v.r );
	return glish_dcomplex( r * cos(v.i), r * sin(v.i) );
	}

glish_dcomplex log( const glish_dcomplex v )
	{
	double h = hypot( v.r, v.i );
	/* THROW EXCEPTION if h <= 0*/
	return glish_dcomplex( log(h), atan2(v.i, v.r) );
	}

glish_dcomplex log10( const glish_dcomplex v )
	{
	double log10e = 0.4342944819032518276511289;
	glish_dcomplex l = log(v);
	return glish_dcomplex( l.r * log10e, l.i * log10e );
	}

glish_dcomplex sin( const glish_dcomplex v )
	{
	return glish_dcomplex( sin(v.r) * cosh(v.i), cos(v.r) * sinh(v.i) );
	}

glish_dcomplex cos( const glish_dcomplex v )
	{
	return glish_dcomplex( cos(v.r) * cosh(v.i), -sin(v.r) * sinh(v.i) );
	}

glish_dcomplex sqrt( const glish_dcomplex v )
	{
	return v.r == 0 && v.i == 0 ? glish_dcomplex(0,0) : pow( v, glish_dcomplex( 0.5 ) );
	}

glish_dcomplex pow( const glish_dcomplex x, const glish_dcomplex y )
	{
	glish_dcomplex z = log( x );
	z = mul( z, y );
	return exp( z );
	}
