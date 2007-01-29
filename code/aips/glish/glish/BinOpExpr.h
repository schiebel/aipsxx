// $Id: BinOpExpr.h,v 19.12 2004/11/03 20:38:57 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.
#ifndef binopexpr_h
#define binopexpr_h

// Definitions for arithmetic and relational Expr classes

#include "Expr.h"

// Arithmetic operations supported on values.
typedef enum {
	OP_ADD, OP_SUBTRACT, OP_MULTIPLY, OP_DIVIDE, OP_MODULO, OP_POWER,
	OP_AND, OP_OR,
	OP_EQ, OP_NE, OP_LE, OP_GE, OP_LT, OP_GT
	} binop;


// An BinOpExpr is a binary expression which performs some arithmetic
// or relational operation.

class BinOpExpr : public BinaryExpr {
    public:
	BinOpExpr( binop op, Expr* op1, Expr* op2 );

	IValue* Eval( evalOpt &opt ) = 0;

    protected:
	// Returns 0 if the expression's operands type-check, otherwise
	// returns a error value.  The default TypeCheck implements
	// arithmetic type-checking (operands must be numeric).
	//
	// The third argument is set to true if this expression operates
	// element-by-element on arrays, false otherwise.
	virtual IValue *TypeCheck( const IValue* lhs, const IValue* rhs,
				int& element_by_element ) const;

	// What type the BinOpExpr's operands should be promoted to.  The
	// default OperandsType implements numeric promotion (higher operand
	// type is used, where the hierarchy is double, float, int, and
	// bool is promoted to int).
	virtual glish_type OperandsType( const IValue* lhs, const IValue* rhs )
			const;

	// Called after type-checking is done.  Checks array lengths
	// for compatibility and promotes scalars to arrays as necessary.
	// Returns in lhs_len the array length at which lhs should be
	// used (if lhs is a scalar and rhs is an array then this will be
	// the length of rhs, otherwise the length of lhs).  Returns 0
	// all checking was okay, otherwise an error message (in which case
	// lhs_len may not have been set).
	IValue *Compute( const IValue* lhs, const IValue* rhs, int& lhs_len ) const;

	binop op;
	};


// A BinOp expression that performs an arithmetic operation: i.e., one
// in which the operands are of numeric type and the result is the same
// type as the operands.
class ArithExpr : public BinOpExpr {
    public:
	ArithExpr( binop op_, Expr* op1, Expr* op2 ) : BinOpExpr(op_, op1, op2)
		{ }

	IValue* Eval( evalOpt &opt );

	IValue *Compute( const IValue* lhs, const IValue* rhs, int& lhs_len ) const
			{ return BinOpExpr::Compute( lhs, rhs, lhs_len ); }

	virtual void Compute( byte lhs[], byte rhs[], int lhs_len,
			      int rhs_incr, const char *&err = glish_charptrdummy ) = 0;
	virtual void Compute( short lhs[], short rhs[], int lhs_len,
			      int rhs_incr, const char *&err = glish_charptrdummy ) = 0;
	virtual void Compute( int lhs[], int rhs[], int lhs_len,
			      int rhs_incr, const char *&err = glish_charptrdummy ) = 0;
	virtual void Compute( float lhs[], float rhs[], int lhs_len,
			      int rhs_incr, const char *&err = glish_charptrdummy ) = 0;
	virtual void Compute( double lhs[], double rhs[], int lhs_len,
			      int rhs_incr, const char *&err = glish_charptrdummy ) = 0;
	virtual void Compute( glish_complex lhs[], glish_complex rhs[], int lhs_len,
			      int rhs_incr, const char *&err = glish_charptrdummy ) = 0;
	virtual void Compute( glish_dcomplex lhs[], glish_dcomplex rhs[], int lhs_len,
			      int rhs_incr, const char *&err = glish_charptrdummy ) = 0;

    protected:
	IValue* OpCompute( IValue* lhs, const IValue* rhs, int lhs_len,
			   const char *&err = glish_charptrdummy );
	};

#define DECLARE_ARITH_EXPR(name, op, op_name, overloads)			\
class name : public ArithExpr {							\
    public:									\
	name( Expr* op1, Expr* op2 )						\
		: ArithExpr(op, op1, op2)	{ }				\
	overloads								\
										\
	const char *Description() const { return op_name; }			\
										\
	IValue *Compute( const IValue* lhs, const IValue* rhs, int& lhs_len ) const \
			{ return BinOpExpr::Compute( lhs, rhs, lhs_len ); }	\
										\
	void Compute( byte lhs[], byte rhs[], int lhs_len,			\
		      int rhs_incr, const char *&err = glish_charptrdummy );	\
	void Compute( short lhs[], short rhs[], int lhs_len,			\
		      int rhs_incr, const char *&err = glish_charptrdummy );	\
	void Compute( int lhs[], int rhs[], int lhs_len,			\
		      int rhs_incr, const char *&err = glish_charptrdummy );	\
	void Compute( float lhs[], float rhs[], int lhs_len,			\
		      int rhs_incr, const char *&err = glish_charptrdummy );	\
	void Compute( double lhs[], double rhs[], int lhs_len,			\
		      int rhs_incr, const char *&err = glish_charptrdummy );	\
	void Compute( glish_complex lhs[], glish_complex rhs[], int lhs_len,	\
			int rhs_incr, const char *&err = glish_charptrdummy );	\
	void Compute( glish_dcomplex lhs[], glish_dcomplex rhs[], int lhs_len,	\
			int rhs_incr, const char *&err = glish_charptrdummy );	\
	};

DECLARE_ARITH_EXPR(AddExpr, OP_ADD, "+",)
DECLARE_ARITH_EXPR(SubtractExpr, OP_SUBTRACT, "-",)
DECLARE_ARITH_EXPR(MultiplyExpr, OP_MULTIPLY, "*",)
DECLARE_ARITH_EXPR(DivideExpr, OP_DIVIDE, "/",
	glish_type OperandsType( const IValue* lhs, const IValue* rhs ) const;)
DECLARE_ARITH_EXPR(ModuloExpr, OP_MODULO, "/",
	glish_type OperandsType( const IValue* lhs, const IValue* rhs ) const;)
DECLARE_ARITH_EXPR(PowerExpr, OP_POWER, "^",
	glish_type OperandsType( const IValue* lhs, const IValue* rhs ) const;)


// A BinOpExpr that performs a relational operation; i.e., an operation with
// a boolean result value.
class RelExpr : public BinOpExpr {
    public:
	RelExpr( binop op_, Expr* op1, Expr* op2 )
			: BinOpExpr(op_, op1, op2) { }

	IValue* Eval( evalOpt &opt );

	IValue *Compute( const IValue* lhs, const IValue* rhs, int& lhs_len ) const
			{ return BinOpExpr::Compute( lhs, rhs, lhs_len ); }

	virtual void Compute( glish_bool lhs[], glish_bool rhs[],
				glish_bool result[],
				int lhs_len, int rhs_incr ) = 0;
	virtual void Compute( byte lhs[], byte rhs[], glish_bool result[],
				int lhs_len, int rhs_incr ) = 0;
	virtual void Compute( short lhs[], short rhs[], glish_bool result[],
				int lhs_len, int rhs_incr ) = 0;
	virtual void Compute( int lhs[], int rhs[], glish_bool result[],
				int lhs_len, int rhs_incr ) = 0;
	virtual void Compute( float lhs[], float rhs[], glish_bool result[],
				int lhs_len, int rhs_incr ) = 0;
	virtual void Compute( double lhs[], double rhs[], glish_bool result[],
				int lhs_len, int rhs_incr ) = 0;
	virtual void Compute( glish_complex lhs[], glish_complex rhs[], glish_bool result[],
				int lhs_len, int rhs_incr ) = 0;
	virtual void Compute( glish_dcomplex lhs[], glish_dcomplex rhs[],
				glish_bool result[],
				int lhs_len, int rhs_incr ) = 0;
	virtual void Compute( charptr lhs[], charptr rhs[], glish_bool result[],
				int lhs_len, int rhs_incr ) = 0;

    protected:
	IValue *TypeCheck( const IValue* lhs, const IValue* rhs,
			int& element_by_element ) const;
	glish_type OperandsType( const IValue* lhs, const IValue* rhs ) const;
	IValue* OpCompute( const IValue* lhs, const IValue* rhs, int lhs_len );
	};


#define DECLARE_REL_EXPR(name, op, op_name)				\
class name : public RelExpr {						\
    public:								\
	name( Expr* op1, Expr* op2 )					\
		: RelExpr(op, op1, op2)	{ }				\
									\
	const char *Description() const { return op_name; }		\
									\
	IValue *Compute( const IValue* lhs, const IValue* rhs, int& lhs_len ) const \
			{ return BinOpExpr::Compute( lhs, rhs, lhs_len ); } \
									\
	void Compute( glish_bool lhs[], glish_bool rhs[],		\
			glish_bool result[],				\
			int lhs_len, int rhs_incr );			\
	void Compute( byte lhs[], byte rhs[], glish_bool result[],	\
			int lhs_len, int rhs_incr );			\
	void Compute( short lhs[], short rhs[], glish_bool result[],	\
			int lhs_len, int rhs_incr );			\
	void Compute( int lhs[], int rhs[], glish_bool result[],	\
			int lhs_len, int rhs_incr );			\
	void Compute( float lhs[], float rhs[], glish_bool result[],	\
			int lhs_len, int rhs_incr );			\
	void Compute( double lhs[], double rhs[], glish_bool result[],	\
			int lhs_len, int rhs_incr );			\
	void Compute( glish_complex lhs[], glish_complex rhs[],		\
			glish_bool result[], int lhs_len, int rhs_incr ); \
	void Compute( glish_dcomplex lhs[], glish_dcomplex rhs[],	\
			glish_bool result[], int lhs_len, int rhs_incr ); \
	void Compute( charptr lhs[], charptr rhs[], glish_bool result[],\
			int lhs_len, int rhs_incr );			\
	};

DECLARE_REL_EXPR(EQ_Expr, OP_EQ, "==")
DECLARE_REL_EXPR(NE_Expr, OP_NE, "!=")
DECLARE_REL_EXPR(LE_Expr, OP_LE, "<=")
DECLARE_REL_EXPR(GE_Expr, OP_GE, ">=")
DECLARE_REL_EXPR(LT_Expr, OP_LT, "<")
DECLARE_REL_EXPR(GT_Expr, OP_GT, ">")


// A RelExpr that performs a logical operation; i.e., boolean operands with
// a boolean result value.
class LogExpr : public RelExpr {
    public:
	LogExpr( binop op_, Expr* op1, Expr* op2 )
			: RelExpr(op_, op1, op2)	{ }

	IValue *Compute( const IValue* lhs, const IValue* rhs, int& lhs_len ) const
			{ return BinOpExpr::Compute( lhs, rhs, lhs_len ); }

	void Compute( glish_bool lhs[], glish_bool rhs[], glish_bool result[],
			int lhs_len, int rhs_incr );
	void Compute( byte lhs[], byte rhs[], glish_bool result[],
			int lhs_len, int rhs_incr );
	void Compute( short lhs[], short rhs[], glish_bool result[],
			int lhs_len, int rhs_incr );
	void Compute( int lhs[], int rhs[], glish_bool result[],
			int lhs_len, int rhs_incr );
	void Compute( float lhs[], float rhs[], glish_bool result[],
			int lhs_len, int rhs_incr );
	void Compute( double lhs[], double rhs[], glish_bool result[],
			int lhs_len, int rhs_incr );
	void Compute( glish_complex lhs[], glish_complex rhs[], glish_bool result[],
			int lhs_len, int rhs_incr );
	void Compute( glish_dcomplex lhs[], glish_dcomplex rhs[], glish_bool result[],
			int lhs_len, int rhs_incr );
	void Compute( charptr lhs[], charptr rhs[], glish_bool result[],
			int lhs_len, int rhs_incr );

    protected:
	IValue *TypeCheck( const IValue* lhs, const IValue* rhs,
			int& element_by_element ) const;
	glish_type OperandsType( const IValue* lhs, const IValue* rhs ) const;
	};


#define DECLARE_LOG_EXPR(name, op, op_name)				\
class name : public LogExpr {						\
    public:								\
	name( Expr* op1, Expr* op2 )					\
		: LogExpr(op, op1, op2)	{ }				\
									\
	const char *Description() const { return op_name; }		\
									\
	IValue *Compute( const IValue* lhs, const IValue* rhs, int& lhs_len ) const \
			{ return BinOpExpr::Compute( lhs, rhs, lhs_len ); } \
									\
	void Compute( glish_bool lhs[], glish_bool rhs[],		\
			glish_bool result[], int lhs_len, int rhs_incr );\
									\
	void Compute( int lhs[], int rhs[], glish_bool result[],	\
			int lhs_len, int rhs_incr )			\
		{ LogExpr::Compute(lhs,rhs,result,lhs_len,rhs_incr); }	\
	void Compute( float lhs[], float rhs[], glish_bool result[],	\
			int lhs_len, int rhs_incr )			\
		{ LogExpr::Compute(lhs,rhs,result,lhs_len,rhs_incr); }	\
	void Compute( double lhs[], double rhs[], glish_bool result[],	\
			int lhs_len, int rhs_incr )			\
		{ LogExpr::Compute(lhs,rhs,result,lhs_len,rhs_incr); }	\
	void Compute( glish_complex lhs[], glish_complex rhs[],		\
			glish_bool result[], int lhs_len, int rhs_incr ) \
		{ LogExpr::Compute(lhs,rhs,result,lhs_len,rhs_incr); }	\
	void Compute( glish_dcomplex lhs[], glish_dcomplex rhs[],	\
			glish_bool result[], int lhs_len, int rhs_incr ) \
		{ LogExpr::Compute(lhs,rhs,result,lhs_len,rhs_incr); }	\
	void Compute( charptr lhs[], charptr rhs[], glish_bool result[],\
			int lhs_len, int rhs_incr )			\
		{ LogExpr::Compute(lhs,rhs,result,lhs_len,rhs_incr); }	\
	void Compute( byte lhs[], byte rhs[], glish_bool result[],	\
			int lhs_len, int rhs_incr )			\
		{ LogExpr::Compute(lhs,rhs,result,lhs_len,rhs_incr); }	\
	void Compute( short lhs[], short rhs[], glish_bool result[],	\
			int lhs_len, int rhs_incr )			\
		{ LogExpr::Compute(lhs,rhs,result,lhs_len,rhs_incr); }	\
	};

DECLARE_LOG_EXPR(LogAndExpr, OP_AND, "&")
DECLARE_LOG_EXPR(LogOrExpr, OP_OR, "|")

#endif /* binopexpr_h */
