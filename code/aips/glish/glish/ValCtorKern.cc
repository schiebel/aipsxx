// $Id: ValCtorKern.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 2004 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: ValCtorKern.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $")
#include "Glish/Value.h"
#include "Glish/Reporter.h"
#include "ValCtorKernDefs.h"

DEFINE_CREATE_VALUE(ValCtorKern,Value);

Value *ValCtorKern::copy( const Value *value )
	{
	if ( value->IsRef() )
		return copy_value( value->RefPtr() );

	Value *copy = 0;
	switch( value->Type() )
		{
		case TYPE_BOOL:
		case TYPE_BYTE:
		case TYPE_SHORT:
		case TYPE_INT:
		case TYPE_FLOAT:
		case TYPE_DOUBLE:
		case TYPE_COMPLEX:
		case TYPE_DCOMPLEX:
		case TYPE_STRING:
		case TYPE_RECORD:
		case TYPE_FAIL:
			copy = ValCtor::create( *value );
			break;

		case TYPE_SUBVEC_REF:
			switch ( value->VecRefPtr()->Type() )
				{
#define COPY_REF(tag,accessor)						\
	case tag:							\
		copy = ValCtor::create( value->accessor ); 		\
		copy->CopyAttributes( value );				\
		break;

				COPY_REF(TYPE_BOOL,BoolRef())
				COPY_REF(TYPE_BYTE,ByteRef())
				COPY_REF(TYPE_SHORT,ShortRef())
				COPY_REF(TYPE_INT,IntRef())
				COPY_REF(TYPE_FLOAT,FloatRef())
				COPY_REF(TYPE_DOUBLE,DoubleRef())
				COPY_REF(TYPE_COMPLEX,ComplexRef())
				COPY_REF(TYPE_DCOMPLEX,DcomplexRef())
				COPY_REF(TYPE_STRING,StringRef())

				default:
					glish_fatal->Report( "bad type in copy_value(Value*) [",
						       value->VecRefPtr()->Type(), "]" );
				}
			break;

		default:
			glish_fatal->Report( "bad type in copy_value(Value*) [", value->Type(), "]" );
		}

	return copy;
	}

Value *ValCtorKern::deep_copy( const Value *value ) { return copy(value); }


Value *ValCtorKern::error( int, const RMessage& m0,
			   const RMessage& m1, const RMessage& m2,
			   const RMessage& m3, const RMessage& m4,
			   const RMessage& m5, const RMessage& m6,
			   const RMessage& m7, const RMessage& m8,
			   const RMessage& m9, const RMessage& m10,
			   const RMessage& m11, const RMessage& m12,
			   const RMessage& m13, const RMessage& m14,
			   const RMessage& m15, const RMessage& m16 )
	{
	glish_error->Report(m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16);
	return error_value();
	}

Value *ValCtorKern::error( int, const char * /*file*/, int /*line*/,
			   const RMessage& m0,
			   const RMessage& m1, const RMessage& m2,
			   const RMessage& m3, const RMessage& m4,
			   const RMessage& m5, const RMessage& m6,
			   const RMessage& m7, const RMessage& m8,
			   const RMessage& m9, const RMessage& m10,
			   const RMessage& m11, const RMessage& m12,
			   const RMessage& m13, const RMessage& m14,
			   const RMessage& m15, const RMessage& m16 )
	{
	glish_error->Report(m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16);
	return error_value();
	}

const Str ValCtorKern::error_str( const RMessage& m0,
				  const RMessage& m1, const RMessage& m2,
				  const RMessage& m3, const RMessage& m4,
				  const RMessage& m5, const RMessage& m6,
				  const RMessage& m7, const RMessage& m8,
				  const RMessage& m9, const RMessage& m10,
				  const RMessage& m11, const RMessage& m12,
				  const RMessage& m13, const RMessage& m14,
				  const RMessage& m15, const RMessage& m16 )
	{
	glish_error->Report(m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16);
	return Str();
	}

void ValCtorKern::report( const RMessage& m0,
			  const RMessage& m1, const RMessage& m2,
			  const RMessage& m3, const RMessage& m4,
			  const RMessage& m5, const RMessage& m6,
			  const RMessage& m7, const RMessage& m8,
			  const RMessage& m9, const RMessage& m10,
			  const RMessage& m11, const RMessage& m12,
			  const RMessage& m13, const RMessage& m14,
			  const RMessage& m15, const RMessage& m16 )
	{
	glish_error->Report(m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16);
	}

void ValCtorKern::report( const char * /*file*/, int /*line*/,
			  const RMessage& m0,
			  const RMessage& m1, const RMessage& m2,
			  const RMessage& m3, const RMessage& m4,
			  const RMessage& m5, const RMessage& m6,
			  const RMessage& m7, const RMessage& m8,
			  const RMessage& m9, const RMessage& m10,
			  const RMessage& m11, const RMessage& m12,
			  const RMessage& m13, const RMessage& m14,
			  const RMessage& m15, const RMessage& m16 )
	{
	glish_error->Report(m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16);
	}

int ValCtorKern::print_precision( )
	{ return -1; }
int ValCtorKern::print_limit( )
	{ return 0; }
int ValCtorKern::silent( )
	{ return 0; }
int ValCtorKern::collecting_garbage( )
	{ return collecting_garbage_; }
void ValCtorKern::collecting_garbage( int v )
	{ collecting_garbage_ = v ? 1 : 0; }
void ValCtorKern::log( const char * )
	{ }
int ValCtorKern::do_log( )
	{ return 0; }
void ValCtorKern::show_stack( OStream & )
	{ }
int ValCtorKern::write_agent( sos_out &, Value *, sos_header &, const ProxyId & )
	{ return 0; }
void ValCtorKern::cleanup( )
	{ }
