// $Id: Complex.h,v 19.0 2003/07/16 05:15:51 aips2adm Exp $
// Copyright (c) 1997 Associated Universities Inc.
//
#ifndef complex_h
#define complex_h

#include "Glish/Stream.h"
#include <math.h>

//
// Complex types
//

struct glish_complex;
struct glish_dcomplex;

struct glish_complex GC_FREE_CLASS {
	glish_complex() {}
	glish_complex( float rv, float iv ) : r(rv), i(iv) {}
	glish_complex( float rv ) : r(rv), i(float(0)) {}
	glish_complex( const glish_complex& cv ) : r(cv.r), i(cv.i) {}
	glish_complex( const glish_dcomplex& cv );

	float r;
	float i;
};

struct glish_dcomplex GC_FREE_CLASS {
	glish_dcomplex() {}
	glish_dcomplex( double rv, double iv ) : r(rv), i(iv) {}
	glish_dcomplex( double rv ) : r(rv), i(double(0)) {}
	glish_dcomplex( const glish_complex& cv ) : r(cv.r), i(cv.i) {}
	glish_dcomplex( const glish_dcomplex& cv ) : r(cv.r), i(cv.i) {}

	double r;
	double i;
};

#define alloc_glish_complex( num ) (glish_complex*) alloc_memory_atomic( sizeof(glish_complex) * num )
#define alloc_glish_complexptr( num ) (glish_complex**) alloc_memory( sizeof(glish_complex*) * num )
#define alloc_glish_dcomplex( num ) (glish_dcomplex*) alloc_memory_atomic( sizeof(glish_dcomplex) * num )
#define alloc_glish_dcomplexptr( num ) (glish_dcomplex**) alloc_memory( sizeof(glish_dcomplex*) * num )

inline glish_complex::glish_complex( const glish_dcomplex& cv )
	{
	r = cv.r;
	i = cv.i;
	}


inline float norm( const glish_complex x )
	{
	return x.r * x.r + x.i * x.i;
	}

inline double norm( const glish_dcomplex x )
	{
	return x.r * x.r + x.i * x.i;
	}

#define COMPLEX_INTEGRAL_FUNCS(type,func)	\
inline type func( const type x )		\
	{					\
	return type( func( x.r ), func( x.i ) );\
	}

COMPLEX_INTEGRAL_FUNCS(glish_dcomplex,floor)
COMPLEX_INTEGRAL_FUNCS(glish_dcomplex,ceil)

#define COMPLEX_CPX_BINOP(type,lhs_type,rhs_type,cast,op) 		\
inline type operator op( const lhs_type x, const rhs_type y ) 		\
	{								\
	return type((cast) x.r op (cast) y.r, (cast) x.r op (cast) y.r);\
	}

#define COMPLEX_CPX_ASGNOP(cpx_type,blt_type,cast,op)			\
inline void operator op( cpx_type &x, const blt_type y ) 		\
	{								\
	x.r op (cast) y.r;						\
	x.i op (cast) y.i;						\
	}

#define COMPLEX_BLT_BINOP(type,cpx_type,blt_type,cast,op)		\
inline type operator op( const cpx_type x, const blt_type y ) 		\
	{								\
	return type((cast) x.r op (cast) y, (cast) x.i);		\
	}								\
									\
inline type operator op( const blt_type y, const cpx_type x )		\
	{								\
	return type((cast) y op (cast) x.r, (cast) x.i);		\
	}

#define COMPLEX_BLT_ASGNOP( cpx_type,blt_type,cast,op )			\
inline void operator op (cpx_type &x, const blt_type y)			\
	{								\
	x.r op (cast) y;						\
	}								\
									\
inline void operator op( blt_type &y, const cpx_type x )		\
	{								\
	y op (blt_type) x.r;						\
	}

#define COMPLEX_OP(op)							\
COMPLEX_CPX_BINOP(glish_complex,glish_complex,glish_complex,float,op)	\
COMPLEX_CPX_BINOP(glish_dcomplex,glish_dcomplex,glish_complex,double,op) \
COMPLEX_CPX_BINOP(glish_dcomplex,glish_complex,glish_dcomplex,double,op) \
COMPLEX_CPX_BINOP(glish_dcomplex,glish_dcomplex,glish_dcomplex,double,op) \
COMPLEX_CPX_ASGNOP(glish_complex,glish_complex,float,op##=)		\
COMPLEX_CPX_ASGNOP(glish_dcomplex,glish_complex,double,op##=)		\
COMPLEX_CPX_ASGNOP(glish_complex,glish_dcomplex,float,op##=)		\
COMPLEX_CPX_ASGNOP(glish_dcomplex,glish_dcomplex,double,op##=)		\
COMPLEX_BLT_BINOP(glish_complex,glish_complex,float,float,op)		\
COMPLEX_BLT_BINOP(glish_dcomplex,glish_complex,double,float,op)		\
COMPLEX_BLT_BINOP(glish_dcomplex,glish_dcomplex,float,double,op)	\
COMPLEX_BLT_BINOP(glish_dcomplex,glish_dcomplex,double,double,op)	\
COMPLEX_BLT_ASGNOP(glish_complex,float,float,op##=)			\
COMPLEX_BLT_ASGNOP(glish_complex,double,float,op##=)			\
COMPLEX_BLT_ASGNOP(glish_dcomplex,float,double,op##=)			\
COMPLEX_BLT_ASGNOP(glish_dcomplex,double,double,op##=)

// COMPLEX_OP(+)
// COMPLEX_OP(-)

#define COMPLEX_CPX_ASSIGN(lhs_type,rhs_type,cast)		\
inline lhs_type operator=(lhs_type &x, const rhs_type y)	\
	{							\
	x.r = (cast) y.r;					\
	x.i = (cast) y.i;					\
	return x;						\
	}

#define COMPLEX_BLT_ASSIGN(lhs_type,rhs_type,cast)		\
inline lhs_type operator=(lhs_type &x, const rhs_type y)	\
	{							\
	x.r = (cast) y;						\
	x.i = (cast) 0;						\
	return x;						\
	}

#define BLT_COMPLEX_ASSIGN(lhs_type,rhs_type,cast)		\
inline lhs_type operator=(lhs_type &x, const rhs_type y)	\
	{							\
	x = (cast) y.r;						\
	return x;						\
	}
//
// COMPLEX_CPX_ASSIGN(glish_complex,glish_complex,float)
// COMPLEX_CPX_ASSIGN(glish_complex,glish_dcomplex,float)
// COMPLEX_CPX_ASSIGN(glish_dcomplex,glish_complex,double)
// COMPLEX_CPX_ASSIGN(glish_dcomplex,glish_dcomplex,double)
// COMPLEX_BLT_ASSIGN(glish_complex,float,float)
// COMPLEX_BLT_ASSIGN(glish_complex,double,float)
// COMPLEX_BLT_ASSIGN(glish_dcomplex,float,double)
// COMPLEX_BLT_ASSIGN(glish_dcomplex,double,double)
// BLT_COMPLEX_ASSIGN(float,glish_complex,float)
// BLT_COMPLEX_ASSIGN(float,glish_dcomplex,float)
// BLT_COMPLEX_ASSIGN(double,glish_complex,double)
// BLT_COMPLEX_ASSIGN(double,glish_dcomplex,double)
//

COMPLEX_CPX_ASGNOP(glish_dcomplex,glish_dcomplex,double,+=)
COMPLEX_CPX_ASGNOP(glish_dcomplex,glish_dcomplex,double,*=)


//
// Defined to be consistent with S
//
#define COMPLEX_LOGOP(type,op)					\
inline int operator op (type x, type y)				\
	{							\
	return ( x.r == y.r ? x.i op y.i : x.r op y.r );	\
	}

#define COMPLEX_LOGOP_SET(type)	\
COMPLEX_LOGOP(type,>)		\
COMPLEX_LOGOP(type,>=)		\
COMPLEX_LOGOP(type,<)		\
COMPLEX_LOGOP(type,<=)		\
COMPLEX_LOGOP(type,==)		\
COMPLEX_LOGOP(type,!=)

COMPLEX_LOGOP_SET(glish_complex)
COMPLEX_LOGOP_SET(glish_dcomplex)

inline glish_complex mul( const glish_complex x, const glish_complex y )
	{
	return glish_complex( x.r*y.r - x.i*y.i, x.r*y.i + x.i*y.r );
	}

inline glish_dcomplex mul( const glish_dcomplex x, const glish_dcomplex y )
	{
	return glish_dcomplex( x.r*y.r - x.i*y.i, x.r*y.i + x.i*y.r );
	}

extern glish_complex atocpx(const char text[]);
extern glish_dcomplex atodcpx(const char text[]);
extern glish_dcomplex mul(const glish_dcomplex x, const glish_dcomplex y );
extern glish_complex div(const glish_complex divd, const glish_complex dsor );
extern glish_dcomplex exp(const glish_dcomplex v);
extern glish_dcomplex log(const glish_dcomplex v);
extern glish_dcomplex log10(const glish_dcomplex v);
extern glish_dcomplex sin(const glish_dcomplex v);
extern glish_dcomplex cos(const glish_dcomplex v);
extern glish_dcomplex sqrt(const glish_dcomplex v);
extern glish_dcomplex pow(const glish_dcomplex x, const glish_dcomplex y);

inline glish_dcomplex tan(const glish_dcomplex v) {return div(sin(v),cos(v));}

inline OStream &operator<<(OStream &ios, glish_complex x) {
  ios << x.r << (x.i>=0?"+":"") << x.i << "i";
  return ios;
}

inline OStream &operator<<(OStream &ios, glish_dcomplex x) {
  ios << x.r << (x.i>=0?"+":"") << x.i << "i";
  return ios;
}

#endif
