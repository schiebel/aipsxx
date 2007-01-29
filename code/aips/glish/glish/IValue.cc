// $Id: IValue.cc,v 19.14 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000,2004 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: IValue.cc,v 19.14 2004/11/03 20:38:58 cvsmgr Exp $")
#include "system.h"
#include "input.h"
#include <string.h>
#include <stdlib.h>

#include "IValue.h"
#include "glish_event.h"
#include "BinOpExpr.h"
#include "Func.h"
#include "Glish/Reporter.h"
#include "Sequencer.h"
#include "Agent.h"
#include "Regex.h"
#include "File.h"

#define AGENT_MEMBER_NAME "*agent*"

#define move_ptrs(to,from,count)					\
{for( int XIX=count-1; XIX>=0; --XIX ) (to)[XIX]=(from)[XIX];}

const char *glish_charptrdummy = 0;

void copy_agents( void *to_, void *from_, size_t len )
	{
	agentptr *to = (agentptr*) to_;
	agentptr *from = (agentptr*) from_;
	copy_array(from,to,(int)len,agentptr);
	for (unsigned int i = 0; i < len; i++)
		Ref(to[i]);
	}
void delete_agents( void *ary_, size_t len )
	{
	agentptr *ary = (agentptr*) ary_;
	for (unsigned int i = 0; i < len; i++)
		if ( (*agents).is_member( ary[i] ) )
			Unref( ary[i] );
	}

void copy_funcs( void *to_, void *from_, size_t len )
	{
	funcptr *to = (funcptr*) to_;
	funcptr *from = (funcptr*) from_;
	copy_array(from,to,(int)len,funcptr);
	for (unsigned int i = 0; i < len; i++)
		if ( to[i] ) Ref(to[i]);
	}
void delete_funcs( void *ary_, size_t len )
	{
	funcptr *ary = (funcptr*) ary_;
	for (unsigned int i = 0; i < len; i++)
		if ( ary[i] ) Unref(ary[i]);
	}

void copy_regexs( void *to_, void *from_, size_t len )
	{
	regexptr *to = (regexptr*) to_;
	regexptr *from = (regexptr*) from_;
	copy_array(from,to,(int)len,regexptr);
	for (unsigned int i = 0; i < len; i++)
		Ref(to[i]);
	}
void delete_regexs( void *ary_, size_t len )
	{
	regexptr *ary = (regexptr*) ary_;
	for (unsigned int i = 0; i < len; i++)
		Unref(ary[i]);
	}

void copy_files( void *to_, void *from_, size_t len )
	{
	fileptr *to = (fileptr*) to_;
	fileptr *from = (fileptr*) from_;
	copy_array(from,to,(int)len,fileptr);
	for (unsigned int i = 0; i < len; i++)
		Ref(to[i]);
	}
void delete_files( void *ary_, size_t len )
	{
	fileptr *ary = (fileptr*) ary_;
	for (unsigned int i = 0; i < len; i++)
		Unref(ary[i]);
	}

void IValue::MarkFail()
	{
	if ( Type() == TYPE_FAIL )
		{
		recordptr rptr = kernel.constRecord();
		rptr->Insert(string_dup("HANDLED"), new IValue( glish_true ));
		}
	}

int IValue::FailMarked( ) const
	{
	if ( Type() != TYPE_FAIL ) return 1;
	recordptr rptr = kernel.constRecord();
	return rptr->Lookup("HANDLED") ? 1 : 0;
	}

IValue::IValue( ) : unref(0), Value( )
	{
	const IValue *other = 0;
	attributeptr attr = ModAttributePtr();
	if ( (other = FailStmt::GetFail()) && other->Type()  == TYPE_FAIL )
		{
		kernel = other->kernel;
		Value *v = 0;
		recordptr rptr = kernel.constRecord();
		if ( (v=(*rptr)["file"]) )
			Unref((IValue*)attr->Insert( string_dup("file"), copy_value(v) ));
		if ( (v=(*rptr)["line"]) )
			Unref((IValue*)attr->Insert( string_dup("line"), copy_value(v) ));
		if ( (v=(*rptr)["message"]) )
			Unref((IValue*)attr->Insert( string_dup("message"), copy_value(v) ));
		if ( (v=(*rptr)["stack"]) )
			Unref((IValue*)attr->Insert( string_dup("stack"), copy_value(v) ));
		}
	else
		{
		recordptr rptr = kernel.modRecord();
		if ( file_name && ! interactive( ) && glish_files )
			{
			rptr->Insert( string_dup("file"), new IValue( (*glish_files)[file_name] ) );
			Unref((IValue*)attr->Insert( string_dup("file" ),new IValue( (*glish_files)[file_name] )));
			if ( line_num > 0 )
				{
				rptr->Insert( string_dup("line"), new IValue( (int) line_num ));
				Unref((IValue*)attr->Insert( string_dup("line" ),new IValue( (int) line_num )));
				}
			}

		IValue *stack = Sequencer::FuncNameStack();
		if ( stack )
			{
			rptr->Insert( string_dup("stack"), stack );
			Unref((IValue*)attr->Insert( string_dup("stack" ), copy_value(stack) ));
			}

		FailStmt::SetFail( this );
		}

	//
	// Sequencer keeps a stack (of stacks) of fail statements
	// in order to automatically propagate unhandled fails.
	//
	Sequencer::FailCreated( this );
	}

IValue::IValue( const char *message, const char *fle, int lne, int auto_fail ) : unref(0), Value( message, fle, lne )
	{
	const IValue *other = 0;
	attributeptr attr = ModAttributePtr();
	if ( !message && (other = FailStmt::GetFail()) )
		{
		kernel = other->kernel;
		Value *v = 0;
		recordptr rptr = kernel.constRecord();
		if ( (v=(*rptr)["file"]) )
			Unref((IValue*)attr->Insert( string_dup("file"), copy_value(v) ));
		if ( (v=(*rptr)["line"]) )
			Unref((IValue*)attr->Insert( string_dup("line"), copy_value(v) ));
		if ( (v=(*rptr)["message"]) )
			Unref((IValue*)attr->Insert( string_dup("message"), copy_value(v) ));
		if ( (v=(*rptr)["stack"]) )
			Unref((IValue*)attr->Insert( string_dup("stack"), copy_value(v) ));
		}
	else
		{
		recordptr rptr = kernel.modRecord();
		if ( ! fle && file_name && ! interactive( ) && glish_files )
			{
			rptr->Insert( string_dup("file"), new IValue( (*glish_files)[file_name] ) );
			Unref((IValue*)attr->Insert( string_dup("file" ),new IValue( (*glish_files)[file_name] )));
			if ( lne <= 0 && line_num > 0 )
				{
				rptr->Insert( string_dup("line"), new IValue( (int) line_num ) );
				Unref((IValue*)attr->Insert( string_dup("line" ),new IValue( (int) line_num )));
				}
			}

		IValue *stack = Sequencer::FuncNameStack();
		if ( stack  )
			{
			rptr->Insert( string_dup("stack"), stack );
			Unref((IValue*)attr->Insert( string_dup("stack" ), copy_value(stack) ));
			}

		FailStmt::SetFail( this );
		}

	//
	// Sequencer keeps a stack (of stacks) of fail statements
	// in order to automatically propagate unhandled fails.
	//
	if ( auto_fail )
		Sequencer::FailCreated( this );
	}

IValue::IValue( funcptr value ) : unref(0), Value(TYPE_FUNC)
	{
	funcptr *ary = alloc_funcptr( 1 );
	copy_array(&value,ary,1,funcptr);
	kernel.SetArray( (voidptr*) ary, 1, TYPE_FUNC, 0 );
	}

IValue::IValue( funcptr value[], int len, array_storage_type s ) : unref(0), Value(TYPE_FUNC)
	{
	kernel.SetArray( (voidptr*) value, len, TYPE_FUNC, s == COPY_ARRAY || s == PRESERVE_ARRAY );
	}


IValue::IValue( regexptr value ) : unref(0), Value(TYPE_REGEX)
	{
	regexptr *ary = alloc_regexptr( 1 );
	copy_array(&value,ary,1,regexptr);
	kernel.SetArray( (voidptr*) ary, 1, TYPE_REGEX, 0 );
	}

IValue::IValue( regexptr value[], int len, array_storage_type s ) : unref(0), Value(TYPE_REGEX)
	{
	kernel.SetArray( (voidptr*) value, len, TYPE_REGEX, s == COPY_ARRAY || s == PRESERVE_ARRAY );
	}


IValue::IValue( fileptr value ) : unref(0), Value(TYPE_FILE)
	{
	fileptr *ary = alloc_fileptr( 1 );
	copy_array(&value,ary,1,fileptr);
	kernel.SetArray( (voidptr*) ary, 1, TYPE_FILE, 0 );
	}

IValue::IValue( fileptr value[], int len, array_storage_type s ) : unref(0), Value(TYPE_FILE)
	{
	kernel.SetArray( (voidptr*) value, len, TYPE_FILE, s == COPY_ARRAY || s == PRESERVE_ARRAY );
	}


IValue::IValue( agentptr value, array_storage_type storage ) : unref(0), Value(TYPE_AGENT)
	{
	if ( storage != COPY_ARRAY && storage != PRESERVE_ARRAY )
		{
		agentptr *ary = alloc_agentptr( 1 );
		copy_array(&value,ary,1,agentptr);
		kernel.SetArray( (voidptr*) ary, 1, TYPE_AGENT, 0 );
		}
	else
		kernel.SetArray( (voidptr*) &value, 1, TYPE_AGENT, 1 );
	}

IValue::IValue( recordptr value, Agent* agent ) : unref(0), Value(TYPE_AGENT)
	{
	value->Insert( string_dup( AGENT_MEMBER_NAME ),
		       new IValue( agent, TAKE_OVER_ARRAY ) );

	kernel.SetRecord( value );
	}


void IValue::DeleteValue()
	{
	if ( ( Type() == TYPE_AGENT || IsAgentRecord() ) &&
	     (*agents).is_member(AgentVal()) )
		AgentVal()->WrapperGone(this);
	}

IValue::~IValue()
	{
	if ( Type() == TYPE_FAIL &&
	     kernel.RefCount() == 1 && 
	     ! FailMarked( ) )
		{
		Sequencer::UnhandledFail(this);
		MarkFail( );
		}
	DeleteValue();
	}

int IValue::IsAgentRecord( int inc_proxy ) const
	{
	if ( Type() == TYPE_REF )
		return Deref()->IsAgentRecord(inc_proxy);

	IValue *v = 0;
	if ( Type() == TYPE_RECORD && (v = (IValue*) (*RecordPtr(0))[AGENT_MEMBER_NAME]) )
		{
		v = (IValue*) v->Deref( );
		if ( v->Type() == TYPE_AGENT || inc_proxy &&
		     v->Type() == TYPE_INT && v->Length() == ProxyId::len() )
			return 1;
		else
			return 0;
		}

	return 0;
	}

const ProxyId *IValue::GetProxyId( ) const
	{
	if ( ! IsAgentRecord( ) ) return 0;
	Agent *agent = AgentVal( );
	if ( ! agent->IsProxy( ) ) return 0;
	const ProxyId &f = ((ProxyTask*)agent)->Id( );
	return &f;
	}

#define DEFINE_CONST_ACCESSOR(name,tag,type)				\
type IValue::name( int modify ) const					\
	{								\
	if ( IsVecRef() ) 						\
		return ((const IValue*) VecRefPtr()->Val())->name();	\
	else if ( Type() != tag )					\
		glish_fatal->Report( "bad use of const accessor" );		\
									\
	return (type) ( modify ? kernel.modArray() : kernel.constArray() );\
	}

DEFINE_CONST_ACCESSOR(FuncPtr,TYPE_FUNC,funcptr*)
DEFINE_CONST_ACCESSOR(RegexPtr,TYPE_REGEX,regexptr*)
DEFINE_CONST_ACCESSOR(FilePtr,TYPE_FILE,fileptr*)
DEFINE_CONST_ACCESSOR(AgentPtr,TYPE_AGENT,agentptr*)


#define DEFINE_ACCESSOR(name,tag,type)					\
type IValue::name( int modify )						\
	{								\
	if ( IsVecRef() ) 						\
		return ((IValue*)VecRefPtr()->Val())->name();		\
	if ( Type() != tag )						\
		Polymorph( tag );					\
									\
	return (type) ( modify ? kernel.modArray() : kernel.constArray() );\
	}

DEFINE_ACCESSOR(FuncPtr,TYPE_FUNC,funcptr*)
DEFINE_ACCESSOR(RegexPtr,TYPE_REGEX,regexptr*)
DEFINE_ACCESSOR(FilePtr,TYPE_FILE,fileptr*)
DEFINE_ACCESSOR(AgentPtr,TYPE_AGENT,agentptr*)

Agent* IValue::AgentVal() const
	{
	if ( Type() == TYPE_AGENT )
		return AgentPtr(0)[0];

	if ( VecRefDeref()->Type() == TYPE_RECORD )
		{
		Value* member = (*VecRefDeref()->RecordPtr(0))[AGENT_MEMBER_NAME];

		if ( member )
			return ((IValue*)member)->AgentVal();
		}

	glish_error->Report( this, " is not an agent value" );
	return 0;
	}

Func* IValue::FuncVal() const
	{
	if ( Type() != TYPE_FUNC )
		{
		glish_error->Report( this, " is not a function value" );
		return 0;
		}

	if ( Length() == 0 )
		{
		glish_error->Report( "empty function array" );
		return 0;
		}

	if ( Length() > 1 )
		glish_warn->Report( "more than one function element in", this,
				", excess ignored" );

	return FuncPtr(0)[0];
	}


Regex* IValue::RegexVal() const
	{
	if ( Type() != TYPE_REGEX )
		{
		glish_error->Report( this, " is not a regular expression value" );
		return 0;
		}

	if ( Length() == 0 )
		{
		glish_error->Report( "empty regular expression array" );
		return 0;
		}

	if ( Length() > 1 )
		glish_warn->Report( "more than one regular expression element in", this,
				", excess ignored" );

	return RegexPtr(0)[0];
	}


File* IValue::FileVal() const
	{
	if ( Type() != TYPE_FILE )
		{
		glish_error->Report( this, " is not a file value" );
		return 0;
		}

	if ( Length() == 0 )
		{
		glish_error->Report( "empty file array" );
		return 0;
		}

	if ( Length() > 1 )
		glish_warn->Report( "more than one file element in", this,
				", excess ignored" );

	return FilePtr(0)[0];
	}


funcptr* IValue::CoerceToFuncArray( int& is_copy, int size, funcptr* result ) const
	{
	if ( Type() != TYPE_FUNC )
		glish_fatal->Report( "non-func type in CoerceToFuncArray()" );

	if ( size != Length() )
		glish_fatal->Report( "size != length in CoerceToFuncArray()" );

	if ( result )
		glish_fatal->Report( "prespecified result in CoerceToFuncArray()" );

	is_copy = 0;
	return FuncPtr(0);
	}

regexptr* IValue::CoerceToRegexArray( int& is_copy, int size, regexptr* result ) const
	{
	if ( Type() != TYPE_REGEX )
		glish_fatal->Report( "non regular expression type in CoerceToRegexArray()" );

	if ( size != Length() )
		glish_fatal->Report( "size != length in CoerceToRegexArray()" );

	if ( result )
		glish_fatal->Report( "prespecified result in CoerceToRegexArray()" );

	is_copy = 0;
	return RegexPtr(0);
	}

fileptr* IValue::CoerceToFileArray( int& is_copy, int size, fileptr* result ) const
	{
	if ( Type() != TYPE_FILE )
		glish_fatal->Report( "non file type in CoerceToFileArray()" );

	if ( size != Length() )
		glish_fatal->Report( "size != length in CoerceToFileArray()" );

	if ( result )
		glish_fatal->Report( "prespecified result in CoerceToFileArray()" );

	is_copy = 0;
	return FilePtr(0);
	}


IValue* IValue::subscript( const IValue* index, int always_preserve_fields ) const
	{
	if ( index->Type() == TYPE_STRING )
		return (IValue*) RecordRef( index );

	int indices_are_copy;
	int num_indices;
	int* indices = GenerateIndices( index, num_indices, indices_are_copy );

	if ( indices )
		{
		IValue* result = ArrayRef( indices, num_indices, always_preserve_fields );

		if ( indices_are_copy )
			free_memory( indices );

		return result;
		}

	else
		return error_ivalue();
	}


IValue* IValue::operator []( const_value_list* args_val ) const
	{

// These are a bunch of macros for cleaning up the dynamic memory used
// by this routine (and Value::SubRef) prior to exit.
#define SUBOP_CLEANUP_1							\
	if ( shape_is_copy )						\
		free_memory( shape );					\
	free_memory( factor );

#define SUBOP_CLEANUP_2(length)						\
	{								\
	SUBOP_CLEANUP_1							\
	for ( int x = 0; x < length; ++x )				\
		if ( index_is_copy[x] )					\
			free_memory( index[x] );			\
									\
	free_memory( index );						\
	free_memory( index_is_copy );					\
	free_memory( cur );						\
	}

#define SUBOP_CLEANUP(length)						\
	SUBOP_CLEANUP_2(length)						\
	free_memory( len );

	if ( ! IsNumeric() && VecRefDeref()->Type() != TYPE_STRING )
		return (IValue*) Fail( "invalid type in n-D array operation:", this );

	// Collect attributes.
	int args_len = args_val->length();
	const attributeptr ptr = AttributePtr();
	const Value* shape_val = ptr ? (*ptr)["shape"] : 0;
	if ( ! shape_val || ! shape_val->IsNumeric() )
		{
		glish_warn->Report( "invalid or non-existant \"shape\" attribute" );

		if ( args_len >= 1 )
			return operator[]( (IValue*) (*args_val)[0] );
		else
			return copy_value( this );
		}

	int shape_len = shape_val->Length();
	if ( shape_len != args_len )
		return (IValue*) Fail( "invalid number of indexes for:", this );

	int shape_is_copy;
	int* shape = shape_val->CoerceToIntArray( shape_is_copy, shape_len );

	int* factor = alloc_int( shape_len );
	int cur_factor = 1;
	int offset = 0;
	int max_len = 0;
	for ( int i = 0; i < args_len; ++i )
		{
		const Value* arg = (*args_val)[i];

		if ( arg )
			{
			if ( ! arg->IsNumeric() )
				{
				SUBOP_CLEANUP_1
				return (IValue*) Fail( "index #", i+1, "into", this,
						       "is not numeric");
				}

			if ( arg->Length() > max_len )
				max_len = arg->Length();

			if ( max_len == 1 )
				{
				int ind = arg->IntVal();
				if ( ind < 1 || ind > shape[i] )
					{
					SUBOP_CLEANUP_1
					return (IValue*) Fail( "index #", i+1,
						"into", this, "is out of range");
					}

				offset += cur_factor * (ind - 1);
				}
			}
		else
			{ // Missing subscript.
			if ( shape[i] > max_len )
				max_len = shape[i];

			if ( max_len == 1 )
				offset += cur_factor * (shape[i] - 1);
			}

		factor[i] = cur_factor;
		cur_factor *= shape[i];
		}

	// Check to see if we're valid.
	if ( cur_factor > Length() )
		{
		SUBOP_CLEANUP_1
		return (IValue*) Fail( "\"::shape\"/length mismatch" );
		}

	if ( max_len == 1 ) 
		{
		SUBOP_CLEANUP_1
		++offset;
		// Should separate ArrayRef to get a single value??
		return ArrayRef( &offset, 1 );
		}

	int* index_is_copy = alloc_int( shape_len );
	int** index = alloc_intptr( shape_len );
	int* cur = alloc_int( shape_len );
	int* len = alloc_int( shape_len );
	int vecsize = 1;
	int is_element = 1;
	int spoof_dimension = 0;
	for ( LOOPDECL i = 0; i < args_len; ++i )
		{
		const Value* arg = (*args_val)[i];
		if ( arg )
			{
			index[i] = GenerateIndices( arg, len[i],
						index_is_copy[i], 0 );
			spoof_dimension = 0;
			}

		else
			{ // Spoof entire dimension.
			len[i] = shape[i];
			index[i] = alloc_int( len[i] );
			for ( int j = 0; j < len[i]; j++ )
				index[i][j] = j+1;
			index_is_copy[i] = 1;
			spoof_dimension = 1;
			}

		if ( is_element && len[i] > 1 )
			is_element = 0;

		vecsize *= len[i];
		cur[i] = 0;

		if ( ! spoof_dimension )
			{
			for ( int j = 0; j < len[i]; ++j )
				{
				if ( index[i][j] >= 1 &&
				     index[i][j] <= shape[i] )
					continue;

				SUBOP_CLEANUP(i)
				if ( len[i] > 1 )
					return (IValue*) Fail( "index #", i+1, ",",
							j+1, " into ", this, 
							"is out of range.");
				else
					return (IValue*) Fail( "index #", i+1, "into",
						this, "is out of range.");

				}
			}
		}

	// Loop through filling resultant vector.
	IValue* result;
	switch ( Type() )
		{
#define SUBSCRIPT_OP_ACTION(tag,type,accessor,LEN,OFFSET,copy_func,ERROR)	\
	case tag:								\
		{								\
		type* vec = accessor;						\
		type* ret = (type*) alloc_##type( vecsize );			\
										\
		for ( int v = 0; v < vecsize; ++v )				\
			{							\
			/**** Calculate offset ****/				\
			offset = 0;						\
			for ( LOOPDECL i = 0; i < shape_len; ++i )		\
				offset += factor[i] *				\
						(index[i][cur[i]]-1);		\
			/**** Set Value ****/					\
			ERROR							\
			ret[v] = copy_func( vec[OFFSET] );			\
			/****  Advance counters ****/				\
			for ( LOOPDECL i = 0; i < shape_len; ++i )		\
				if ( ++cur[i] < len[i] )			\
					break;					\
				else						\
					cur[i] = 0;				\
			}							\
										\
		result = new IValue( ret, vecsize );				\
		result->CopyAttributes( this );					\
										\
		if ( ! is_element )						\
			{							\
			int z = 0;						\
			for ( int x = 0; x < shape_len; ++x )			\
				if ( len[x] > 1 )				\
					len[z++] = len[x];			\
										\
			IValue *shape = new IValue( len, z );			\
			result->AssignAttribute( "shape", shape );		\
			Unref( shape );						\
			}							\
		else								\
			free_memory( len );					\
		}								\
		break;

SUBSCRIPT_OP_ACTION(TYPE_BOOL,glish_bool,BoolPtr(),length,offset,,)
SUBSCRIPT_OP_ACTION(TYPE_BYTE,byte,BytePtr(),length,offset,,)
SUBSCRIPT_OP_ACTION(TYPE_SHORT,short,ShortPtr(),length,offset,,)
SUBSCRIPT_OP_ACTION(TYPE_INT,int,IntPtr(),length,offset,,)
SUBSCRIPT_OP_ACTION(TYPE_FLOAT,float,FloatPtr(),length,offset,,)
SUBSCRIPT_OP_ACTION(TYPE_DOUBLE,double,DoublePtr(),length,offset,,)
SUBSCRIPT_OP_ACTION(TYPE_COMPLEX,glish_complex,ComplexPtr(),length,offset,,)
SUBSCRIPT_OP_ACTION(TYPE_DCOMPLEX,glish_dcomplex,DcomplexPtr(),length,offset,,)
SUBSCRIPT_OP_ACTION(TYPE_STRING,charptr,StringPtr(),length,offset,string_dup,)

		case TYPE_SUBVEC_REF:
			{
			VecRef* ref = VecRefPtr();
			Value* theVal = ref->Val();

			switch ( theVal->Type() )
				{

#define SUBSCRIPT_OP_ACTION_XLATE(EXTRA_ERROR)		\
	int err;					\
	int off = ref->TranslateIndex( offset, &err );	\
	if ( err )					\
		{					\
		EXTRA_ERROR				\
		free_memory( ret );			\
		SUBOP_CLEANUP(shape_len)		\
		return error_ivalue();			\
		}

SUBSCRIPT_OP_ACTION(TYPE_BOOL, glish_bool, theVal->BoolPtr(),
	theLen, off,,SUBSCRIPT_OP_ACTION_XLATE(;))
SUBSCRIPT_OP_ACTION(TYPE_BYTE, byte, theVal->BytePtr(),
	theLen, off,,SUBSCRIPT_OP_ACTION_XLATE(;))
SUBSCRIPT_OP_ACTION(TYPE_SHORT, short, theVal->ShortPtr(),
	theLen, off,,SUBSCRIPT_OP_ACTION_XLATE(;))
SUBSCRIPT_OP_ACTION(TYPE_INT, int, theVal->IntPtr(),
	theLen, off,,SUBSCRIPT_OP_ACTION_XLATE(;))
SUBSCRIPT_OP_ACTION(TYPE_FLOAT, float, theVal->FloatPtr(),
	theLen, off,,SUBSCRIPT_OP_ACTION_XLATE(;))
SUBSCRIPT_OP_ACTION(TYPE_DOUBLE, double, theVal->DoublePtr(),
	theLen, off,,SUBSCRIPT_OP_ACTION_XLATE(;))
SUBSCRIPT_OP_ACTION(TYPE_COMPLEX, glish_complex, theVal->ComplexPtr(),
	theLen, off,,SUBSCRIPT_OP_ACTION_XLATE(;))
SUBSCRIPT_OP_ACTION(TYPE_DCOMPLEX, glish_dcomplex, theVal->DcomplexPtr(),
	theLen, off,,SUBSCRIPT_OP_ACTION_XLATE(;))
SUBSCRIPT_OP_ACTION(TYPE_STRING, charptr, theVal->StringPtr(),
	theLen, off,string_dup,SUBSCRIPT_OP_ACTION_XLATE(for(int X=0;X<v;X++) free_memory((void*)ret[X]);))

				default:
					glish_fatal->Report(
				"bad subref type in Value::operator[]" );
				}
			}
			break;

		default:
			glish_fatal->Report( "bad type in Value::operator[]" );
		}

	SUBOP_CLEANUP_2(shape_len)
	return result;
	}

IValue *IValue::ApplyRegx( regexptr *rptr, int rlen, RegexMatch &match )
	{

	// Here we assume everything has been checked out by
	// ApplyRegExpr::Eval before we were ever called...

	if ( Type() == TYPE_FAIL )
		return (IValue*) Fail( );

	if ( Type() != TYPE_STRING )
		return (IValue*) Fail( "bad type for regular expression application" );

	charptr *strs = StringPtr();
	int len = Length();

	int global = rptr[0]->Global();
	IValue *result = 0;

	if ( global )
		{
		int *match_count = alloc_int( rlen );

		for ( int j=0; j < rlen; ++j )
			{
			int tlen = len;
			IValue *err = 0;
			rptr[j]->Eval( (char**&) strs, len, &match, 0, tlen, &err, 1 );
			match_count[j] = rptr[j]->matchCount();
			}

		result = new IValue( match_count, rlen );
		}
	else
		{
		glish_bool *match_count = alloc_glish_bool( rlen );

		for ( int j=0; j < rlen; ++j )
			{
			int tlen = len;
			IValue *err = 0;
			rptr[j]->Eval( (char**&) strs, len, &match, 0, tlen, &err, 1 );
			match_count[j] = rptr[j]->matchCount() ? glish_true : glish_false;
			}

		result = new IValue( match_count, rlen );
		}


	kernel.Replace( strs, len );
	return result;
	}

IValue *IValue::ApplyRegx( regexptr *rptr, int rlen, RegexMatch &match, int *&indices, int &ilen )
	{

	// Here we assume everything has been checked out by
	// ApplyRegExpr::Eval before we were ever called...

	if ( Type() == TYPE_FAIL )
		return (IValue*) Fail( );

	if ( Type() != TYPE_STRING || ilen <= 0 )
		return (IValue*) Fail( "bad type for regular expression application" );

	charptr *strs = StringPtr();
	int len = Length();

	int global = rptr[0]->Global();
	IValue *result = 0;

	if ( global )
		{
		int *match_count = alloc_int( rlen );
		for ( int j=0; j < rlen; ++j )
			{
			int count = 0;
			for ( int k=0; k < ilen; ++k )
				{
				int tlen = 1;
				IValue *err = 0;
				rptr[j]->Eval( (char**&) strs, len, &match, indices[k]-1, tlen, &err, 1 );
				count += rptr[j]->matchCount();
				if ( tlen > 1 )
					{
					indices = realloc_int( indices, ilen+tlen-1 );
					move_ptrs( &indices[k+tlen], &indices[k+1], ilen-k-1 );
					for ( int X=1; X<tlen; ++X ) indices[k+X] = indices[k] + X;
					ilen += tlen-1;
					k += tlen-1;
					for ( int Y=k+1; Y < ilen; ++Y ) indices[Y] += tlen-1;
					}
				}
			match_count[j] = count;
			}

		result = new IValue( match_count, rlen );
		}
	else
		{
		glish_bool *match_count = alloc_glish_bool( rlen );
		for ( int j=0; j < rlen; ++j )
			{
			int count = 0;
			for ( int k=0; k < ilen; ++k )
				{
				int tlen = 1;
				IValue *err = 0;
				rptr[j]->Eval( (char**&) strs, len, &match, indices[k]-1, tlen, &err, 1 );
				count += rptr[j]->matchCount();
				if ( tlen > 1 )
					{
					indices = realloc_int( indices, ilen+tlen-1 );
					move_ptrs( &indices[k+tlen], &indices[k+1], ilen-k-1 );
					for ( int X=1; X<tlen; ++X ) indices[k+X] = indices[k] + X;
					ilen += tlen-1;
					k += tlen-1;
					for ( int Y=k+1; Y < ilen; ++Y ) indices[Y] += tlen-1;
					}
				}
			match_count[j] = count ? glish_true : glish_false;
			}

		result = new IValue( match_count, rlen );
		}

	kernel.Replace( strs, len );
	return result;
	}


IValue* IValue::ArrayRef( int* indices, int num_indices, int always_preserve_fields )
		const
	{

	if ( IsRef() )
		return ((IValue*) Deref())->ArrayRef( indices, num_indices );

	if ( Type() == TYPE_FAIL )
		return (IValue*) Fail( );

	if ( Type() == TYPE_FUNC )
		return (IValue*) Fail( "arrays of functions are not currently supported" );

	if ( Type() == TYPE_AGENT )
		return (IValue*) Fail( "arrays of agents are not currently supported" );

	if ( Type() == TYPE_RECORD )
		return (IValue*) RecordSlice( indices, num_indices, always_preserve_fields );

	for ( int i = 0; i < num_indices; ++i )
		if ( indices[i] < 1 || indices[i] > kernel.Length() )
			return (IValue*) Fail( "index (=", indices[i],
				") out of range, array length =", kernel.Length() );

	IValue *ret = 0;
	switch ( Type() )
		{

#define ARRAY_REF_ACTION(tag,type,accessor,copy_func,OFFSET,XLATE,REF)	\
	case tag:							\
		{							\
		type* source_ptr = accessor(0);				\
		type* new_values = (type*) alloc_##type( num_indices );	\
									\
		for ( LOOPDECL i = 0; i < num_indices; ++i )		\
			{						\
			XLATE						\
			new_values[i] = copy_func(source_ptr[OFFSET]);	\
			REF						\
			}						\
		ret = new IValue( new_values, num_indices );		\
		}							\
		break;

ARRAY_REF_ACTION(TYPE_BOOL,glish_bool,BoolPtr,,indices[i]-1,,)
ARRAY_REF_ACTION(TYPE_BYTE,byte,BytePtr,,indices[i]-1,,)
ARRAY_REF_ACTION(TYPE_SHORT,short,ShortPtr,,indices[i]-1,,)
ARRAY_REF_ACTION(TYPE_INT,int,IntPtr,,indices[i]-1,,)
ARRAY_REF_ACTION(TYPE_FLOAT,float,FloatPtr,,indices[i]-1,,)
ARRAY_REF_ACTION(TYPE_DOUBLE,double,DoublePtr,,indices[i]-1,,)
ARRAY_REF_ACTION(TYPE_COMPLEX,glish_complex,ComplexPtr,,indices[i]-1,,)
ARRAY_REF_ACTION(TYPE_DCOMPLEX,glish_dcomplex,DcomplexPtr,,indices[i]-1,,)
ARRAY_REF_ACTION(TYPE_STRING,charptr,StringPtr,string_dup,indices[i]-1,,)
ARRAY_REF_ACTION(TYPE_REGEX,regexptr,RegexPtr,,indices[i]-1,,Ref(new_values[i]);)
ARRAY_REF_ACTION(TYPE_FILE,fileptr,FilePtr,,indices[i]-1,,Ref(new_values[i]);)

		case TYPE_SUBVEC_REF:
			{
			VecRef *ref = VecRefPtr();
			switch ( ref->Type() )
				{
#define ARRAY_REF_ACTION_XLATE(EXTRA_ERROR)		\
	int err;					\
	int off = ref->TranslateIndex( indices[i]-1, &err );\
	if ( err )					\
		{					\
		EXTRA_ERROR				\
		free_memory( new_values );		\
		return (IValue*) Fail("invalid index (=",indices[i],"), sub-vector reference may be bad");\
		}

ARRAY_REF_ACTION(TYPE_BOOL,glish_bool,BoolPtr,,off,ARRAY_REF_ACTION_XLATE(;),)
ARRAY_REF_ACTION(TYPE_BYTE,byte,BytePtr,,off,ARRAY_REF_ACTION_XLATE(;),)
ARRAY_REF_ACTION(TYPE_SHORT,short,ShortPtr,,off,ARRAY_REF_ACTION_XLATE(;),)
ARRAY_REF_ACTION(TYPE_INT,int,IntPtr,,off,ARRAY_REF_ACTION_XLATE(;),)
ARRAY_REF_ACTION(TYPE_FLOAT,float,FloatPtr,,off,ARRAY_REF_ACTION_XLATE(;),)
ARRAY_REF_ACTION(TYPE_DOUBLE,double,DoublePtr,,off,ARRAY_REF_ACTION_XLATE(;),)
ARRAY_REF_ACTION(TYPE_COMPLEX,glish_complex,ComplexPtr,,off,ARRAY_REF_ACTION_XLATE(;),)
ARRAY_REF_ACTION(TYPE_DCOMPLEX,glish_dcomplex,DcomplexPtr,,off,ARRAY_REF_ACTION_XLATE(;),)
ARRAY_REF_ACTION(TYPE_STRING,charptr,StringPtr,string_dup,off,ARRAY_REF_ACTION_XLATE(for(int X=0; X<i; X++) free_memory( (void*) new_values[X] );),)
ARRAY_REF_ACTION(TYPE_REGEX,regexptr,RegexPtr,,off,ARRAY_REF_ACTION_XLATE(;),Ref(new_values[i]);)
ARRAY_REF_ACTION(TYPE_FILE,fileptr,FilePtr,,off,ARRAY_REF_ACTION_XLATE(;),Ref(new_values[i]);)

		default:
			glish_fatal->Report( "bad type in Value::ArrayRef()" );
			return 0;
		}
	}
			break;

		default:
			glish_fatal->Report( "bad type in Value::ArrayRef()" );
			return 0;
		}

	Value *print = 0;
	if ( ret && attributes && (print = attributes->Field( "print" )) &&
	     print->Type() == TYPE_RECORD && (print = print->Field("precision")) )
		{
		recordptr rptr = create_record_dict( );
		rptr->Insert( string_dup( "precision" ), copy_value(print) ), 
		ret->AssignAttribute( "print", new IValue( rptr ) );
		}

	return ret;
	}


IValue* IValue::TrueArrayRef( int* indices, int num_indices, int take_indices,
			      value_reftype vtype ) const
	{
	if ( IsRef() )
		return ((IValue*) Deref())->TrueArrayRef( indices, num_indices,
							  take_indices, vtype );

	if ( VecRefDeref()->Type() == TYPE_RECORD )
		return (IValue*) RecordSlice( indices, num_indices );

	for ( int i = 0; i < num_indices; ++i )
		if ( indices[i] < 1 || indices[i] > kernel.Length() )
			{
			if ( take_indices )
				free_memory( indices );

			return (IValue*) Fail( "index (=", indices[i],
				") out of range, array length =", kernel.Length() );
			}

	return new IValue( (IValue*) this, indices, num_indices, vtype, take_indices );
	}



IValue* IValue::Pick( const IValue *index ) const
	{
#define PICK_CLEANUP				\
	if ( shape_is_copy )			\
		free_memory( shape );		\
	if ( ishape_is_copy )			\
		free_memory( ishape );		\
	if ( indx_is_copy )			\
		free_memory( indx );		\
	free_memory( factor );

#define PICK_INITIALIZE(ERR_RET,SHORT)					\
	const attributeptr attr = AttributePtr();			\
	const attributeptr iattr = index->AttributePtr();		\
	const IValue* shape_val = 0;					\
	const IValue* ishape_val = 0;					\
	int shape_len = 0;						\
	int ishape_len = 0;						\
									\
	if ( attr && (shape_val = (IValue*) (*attr)["shape"]) &&	\
	     shape_val->IsNumeric() )					\
		shape_len = shape_val->Length();			\
	if ( iattr && (ishape_val = (IValue*) (*iattr)["shape"]) &&	\
	     ishape_val->IsNumeric() )					\
		ishape_len = ishape_val->Length();			\
									\
	/* Neither has a shape so pick from the vector. */		\
	if ( ishape_len <= 1 && shape_len <= 1 )			\
		{							\
		SHORT							\
		}							\
									\
	if ( ! ishape_len )						\
		{							\
		if ( ishape_val )					\
			ERR_RET(("error in the array \"::shape\": ",	\
				ishape_val))				\
		else							\
			ERR_RET(("no \"::shape\" for ", index,		\
				" but the array has \"::shape\""))	\
		}							\
	if ( ! shape_len )						\
		{							\
		if ( shape_val )					\
			ERR_RET(("error in the array \"::shape\": ",	\
				shape_val))				\
		else							\
			ERR_RET(("no \"::shape\" for ", this,		\
				" but the index has \"::shape\""))	\
		}							\
									\
	if ( ishape_len > 2 )						\
		ERR_RET(("invalid index of dimension (=", ishape_len,	\
				") greater than 2"))			\
									\
	int shape_is_copy = 0;						\
	int ishape_is_copy = 0;						\
	int indx_is_copy = 0;						\
	int* shape = shape_val->CoerceToIntArray( shape_is_copy, shape_len );\
	int* ishape =							\
		ishape_val->CoerceToIntArray( ishape_is_copy, ishape_len );\
	int ilen = index->Length();					\
	int len = Length();						\
	int* factor = alloc_int( shape_len );				\
	int offset = 1;							\
	int* indx = index->CoerceToIntArray( indx_is_copy, ilen );	\
	IValue* result = 0;						\
									\
	if ( ishape[1] != shape_len )					\
		{							\
		PICK_CLEANUP						\
		ERR_RET(("wrong number of columns in index (=",		\
			ishape[1], ") expected ", shape_len))		\
		}							\
	if ( ilen < ishape[0] * ishape[1] )				\
		{							\
		PICK_CLEANUP						\
		ERR_RET(("Index \"::shape\"/length mismatch"))		\
		}							\
	for ( int i = 0; i < shape_len; ++i )				\
		{							\
		factor[i] = offset;					\
		offset *= shape[i];					\
		}							\
									\
	if ( len < offset )						\
		{							\
		PICK_CLEANUP						\
		ERR_RET(("Array \"::shape\"/length mismatch"))		\
		}

#define PICK_FAIL_IVAL(x) return (IValue*) Fail x;
#define PICK_FAIL_VOID(x) { glish_error->Report x; return; }

	PICK_INITIALIZE( PICK_FAIL_IVAL, return this->operator[]( index );)

	switch ( Type() )
		{
#define PICK_ACTION_CLEANUP for(int X=0;X<i;X++) free_memory((void*)ret[X]);
#define PICK_ACTION(tag,type,accessor,OFFSET,COPY_FUNC,XLATE,CLEANUP)	\
	case tag:							\
		{							\
		type* ptr = accessor();					\
		type* ret = (type*) alloc_##type( ishape[0] );		\
		int cur = 0;						\
		for ( LOOPDECL i = 0; i < ishape[0]; ++i )		\
			{						\
			offset = 0;					\
			int j = 0;					\
			for ( ; j < ishape[1]; ++j )			\
				{					\
				cur = indx[i + j * ishape[0]];		\
				if ( cur < 1 || cur > shape[j] )	\
					{				\
					PICK_CLEANUP			\
					CLEANUP				\
					free_memory( ret );		\
					return (IValue*) Fail( "index number ", j,\
					" (=", cur, ") is out of range" );\
					}				\
				offset += factor[j] * (cur-1);		\
				}					\
			XLATE						\
			ret[i] = COPY_FUNC( ptr[ OFFSET ] );		\
			}						\
		result = new IValue( ret, ishape[0] );			\
		}							\
		break;

		PICK_ACTION(TYPE_BOOL,glish_bool,BoolPtr,offset,,,)
		PICK_ACTION(TYPE_BYTE,byte,BytePtr,offset,,,)
		PICK_ACTION(TYPE_SHORT,short,ShortPtr,offset,,,)
		PICK_ACTION(TYPE_INT,int,IntPtr,offset,,,)
		PICK_ACTION(TYPE_FLOAT,float,FloatPtr,offset,,,)
		PICK_ACTION(TYPE_DOUBLE,double,DoublePtr,offset,,,)
		PICK_ACTION(TYPE_COMPLEX,glish_complex,ComplexPtr,offset,,,)
		PICK_ACTION(TYPE_DCOMPLEX,glish_dcomplex,DcomplexPtr,offset,,,)
		PICK_ACTION(TYPE_STRING,charptr,StringPtr,offset,string_dup,,
			PICK_ACTION_CLEANUP)

		case TYPE_SUBVEC_REF:
			{
			VecRef* ref = VecRefPtr();
			IValue* theVal = (IValue*) ref->Val();

			switch ( theVal->Type() )
				{

#define PICK_ACTION_XLATE(CLEANUP)					\
	int err;							\
	int off = ref->TranslateIndex( offset, &err );			\
	if ( err )							\
		{							\
		CLEANUP							\
		free_memory( ret );					\
		return (IValue*) Fail( "index number ", j, " (=",cur,	\
			") is out of range. Sub-vector reference may be invalid" );\
		}

PICK_ACTION(TYPE_BOOL,glish_bool,theVal->BoolPtr,off,,PICK_ACTION_XLATE(;),)
PICK_ACTION(TYPE_BYTE,byte,theVal->BytePtr,off,,PICK_ACTION_XLATE(;),)
PICK_ACTION(TYPE_SHORT,short,theVal->ShortPtr,off,,PICK_ACTION_XLATE(;),)
PICK_ACTION(TYPE_INT,int,theVal->IntPtr,off,,PICK_ACTION_XLATE(;),)
PICK_ACTION(TYPE_FLOAT,float,theVal->FloatPtr,off,,PICK_ACTION_XLATE(;),)
PICK_ACTION(TYPE_DOUBLE,double,theVal->DoublePtr,off,,PICK_ACTION_XLATE(;),)
PICK_ACTION(TYPE_COMPLEX,glish_complex,theVal->ComplexPtr,off,,PICK_ACTION_XLATE(;),)
PICK_ACTION(TYPE_DCOMPLEX,glish_dcomplex,theVal->DcomplexPtr,off,,PICK_ACTION_XLATE(;),)
PICK_ACTION(TYPE_STRING,charptr,theVal->StringPtr,off,string_dup,
	PICK_ACTION_XLATE(PICK_ACTION_CLEANUP),PICK_ACTION_CLEANUP)

				default:
					glish_fatal->Report(
					"bad subref type in Value::Pick" );
				}
			}
			break;

		default:
			glish_fatal->Report( "bad subref type in Value::Pick" );
		}

	PICK_CLEANUP
	return result;
	}

#define PICK_FAIL_IVAL_ERR(x) {err = 1; return (IValue*) Fail x;}
IValue* IValue::PickRef( const IValue *index, int &err )
	{
	err = 0;
	if ( ! IsNumeric() && Type() != TYPE_STRING )
		{
		err = 1;
		return (IValue*) Fail( "non-numeric type in subreference operation:",
				this );
		}

	PICK_INITIALIZE(PICK_FAIL_IVAL_ERR, return this->operator[]( index );)

	int* ret = alloc_int( ishape[0] );
	int cur = 0;
	for ( LOOPDECL i = 0; i < ishape[0]; ++i )
		{
		offset = 0;
		for ( int j = 0; j < ishape[1]; ++j )
			{
			cur = indx[i + j * ishape[0]];
			if ( cur < 1 || cur > shape[j] )
				{
				err = 1;
				PICK_CLEANUP
				free_memory( ret );
				return (IValue*) Fail( "index number ", j, " (=",cur,
						") is out of range" );
				}
			offset += factor[j] * (cur-1);
			}
		ret[i] = offset + 1;
		}

	result = new IValue((IValue*)this,ret,ishape[0],VAL_REF,1);

	const attributeptr cap = result->AttributePtr();
	if ( (*cap)["shape"] )
		{
		if ( cap->Length() == 1 )
			result->DeleteAttributes();
		else
			{
			attributeptr ap = result->ModAttributePtr();
			delete ap->Remove( "shape" );
			}
		}

	PICK_CLEANUP
	return result;
	}

void IValue::PickAssign( const IValue* index, IValue* value )
	{
#define PICKASSIGN_SHORT		\
	AssignElements( index, value );	\
	return;

	PICK_INITIALIZE(PICK_FAIL_VOID, PICKASSIGN_SHORT)

	switch ( Type() )
		{
#define PICKASSIGN_ACTION(tag,type,to_accessor,from_accessor,COPY_FUNC,XLATE)\
	case tag:							\
		{							\
		int cur = 0;						\
		int* offset_vec = alloc_int( ishape[0] );		\
		for ( LOOPDECL i = 0; i < ishape[0]; ++i )		\
			{						\
			offset_vec[i] = 0;				\
			int j = 0;					\
			for ( ; j < ishape[1]; ++j )			\
				{					\
				cur = indx[i + j * ishape[0]];		\
				if ( cur < 1 || cur > shape[j] )	\
					{				\
					PICK_CLEANUP			\
					free_memory( offset_vec );	\
					glish_error->Report("index number ", i,\
							" (=", cur,	\
							") is out of range");\
					return;				\
					}				\
				offset_vec[i] += factor[j] * (cur-1);	\
				}					\
			XLATE						\
			}						\
									\
		int is_copy;						\
		type* vec = value->from_accessor( is_copy, ishape[0] );	\
		type* ret = to_accessor();				\
		for ( LOOPDECL i = 0; i < ishape[0]; ++i )		\
			ret[ offset_vec[i] ] = COPY_FUNC( vec[i] );	\
		free_memory( offset_vec );				\
		if ( is_copy )						\
			free_memory( vec );				\
		}							\
		break;

PICKASSIGN_ACTION(TYPE_BOOL,glish_bool,BoolPtr,CoerceToBoolArray,,)
PICKASSIGN_ACTION(TYPE_BYTE,byte,BytePtr,CoerceToByteArray,,)
PICKASSIGN_ACTION(TYPE_SHORT,short,ShortPtr,CoerceToShortArray,,)
PICKASSIGN_ACTION(TYPE_INT,int,IntPtr,CoerceToIntArray,,)
PICKASSIGN_ACTION(TYPE_FLOAT,float,FloatPtr,CoerceToFloatArray,,)
PICKASSIGN_ACTION(TYPE_DOUBLE,double,DoublePtr,CoerceToDoubleArray,,)
PICKASSIGN_ACTION(TYPE_COMPLEX,glish_complex,ComplexPtr,CoerceToComplexArray,,)
PICKASSIGN_ACTION(TYPE_DCOMPLEX,glish_dcomplex,DcomplexPtr,CoerceToDcomplexArray,,)
PICKASSIGN_ACTION(TYPE_STRING,charptr,StringPtr,CoerceToStringArray,string_dup,)

		case TYPE_SUBVEC_REF:
			{
			VecRef* ref = VecRefPtr();
			Value* theVal = ref->Val();

			switch ( theVal->Type() )
				{

#define PICKASSIGN_ACTION_XLATE						\
	int err;							\
	offset_vec[i] = ref->TranslateIndex( offset_vec[i], &err );	\
	if ( err )							\
		{							\
		PICK_CLEANUP						\
		free_memory( offset_vec );				\
		glish_error->Report( "index number ", j, " (=",cur,		\
			") is out of range. Sub-vector reference may be invalid" );\
		return;							\
		}


PICKASSIGN_ACTION(TYPE_BOOL,glish_bool,BoolPtr,CoerceToBoolArray,,
	PICKASSIGN_ACTION_XLATE)
PICKASSIGN_ACTION(TYPE_BYTE,byte,BytePtr,CoerceToByteArray,,
	PICKASSIGN_ACTION_XLATE)
PICKASSIGN_ACTION(TYPE_SHORT,short,ShortPtr,CoerceToShortArray,,
	PICKASSIGN_ACTION_XLATE)
PICKASSIGN_ACTION(TYPE_INT,int,IntPtr,CoerceToIntArray,,
	PICKASSIGN_ACTION_XLATE)
PICKASSIGN_ACTION(TYPE_FLOAT,float,FloatPtr,CoerceToFloatArray,,
	PICKASSIGN_ACTION_XLATE)
PICKASSIGN_ACTION(TYPE_DOUBLE,double,DoublePtr,CoerceToDoubleArray,,
	PICKASSIGN_ACTION_XLATE)
PICKASSIGN_ACTION(TYPE_COMPLEX,glish_complex,ComplexPtr,CoerceToComplexArray,,
	PICKASSIGN_ACTION_XLATE)
PICKASSIGN_ACTION(TYPE_DCOMPLEX,glish_dcomplex,DcomplexPtr,CoerceToDcomplexArray,,
	PICKASSIGN_ACTION_XLATE)
PICKASSIGN_ACTION(TYPE_STRING,charptr,StringPtr,CoerceToStringArray,string_dup,
	PICKASSIGN_ACTION_XLATE)

				default:
					glish_fatal->Report(
					"bad type in Value::PickAssign" );
				}
			}
			break;

		default:
			glish_fatal->Report( "bad type in Value::PickAssign" );
		}

	PICK_CLEANUP
	return;
	}

IValue* IValue::SubRef( const IValue* index, int &err, value_reftype vtype )
	{
	err = 0;
	if ( VecRefDeref()->Type() == TYPE_RECORD )
		{
		if ( index->Type() == TYPE_STRING )
			return (IValue*) GetOrCreateRecordElement( index );

		IValue *ret = 0;
		int i = index->IntVal( );
		if ( i == Length( ) + 1 )
			{
			ret = (IValue*) ValCtor::create( glish_false );
			ret->MarkUninitialized( );
			AssignRecordElement( NewFieldName(0), ret );
			}
		else
			ret = (IValue*) NthField( index->IntVal() );

		if ( ! ret )
			{
			err = 1;
			return (IValue*) Fail( "record index (=", index->IntVal(),
				") out of range (> ", Length(), ")" );
			}

		return ret;
		}

	int indices_are_copy;
	int num_indices;
	int* indices = GenerateIndices( index, num_indices, indices_are_copy );

	if ( indices )
		return TrueArrayRef( indices, num_indices, indices_are_copy, vtype );
	else
		return error_ivalue();
	}

IValue* IValue::SubRef( const_value_list *args_val, int &err, value_reftype VT )
	{
	err = 0;
	if ( ! IsNumeric() && VecRefDeref()->Type() != TYPE_STRING )
		{
		err = 1;
		return (IValue*) Fail( "invalid type in subreference operation:",
				this );
		}

	// Collect attributes.
	const attributeptr ptr = AttributePtr();
	const Value* shape_val = ptr ? (*ptr)["shape"] : 0;
	if ( ! shape_val || ! shape_val->IsNumeric() )
		{
		glish_warn->Report( "invalid or non-existant \"shape\" attribute" );

		const IValue* arg = (IValue*) (*args_val)[0];
		if ( arg )
			return SubRef( arg, err, VT );
		else
			{
			err = 1;
			return (IValue*) Fail( "invalid missing argument" );
			}
		}

	int shape_len = shape_val->Length();
	int args_len = (*args_val).length();
	if ( shape_len != args_len )
		{
		err = 1;
		return (IValue*) Fail( "invalid number of indexes for:", this );
		}

	int shape_is_copy;
	int* shape = shape_val->CoerceToIntArray( shape_is_copy, shape_len );

	int* factor = alloc_int( shape_len );
	int cur_factor = 1;
	int offset = 0;
	int max_len = 0;
	for ( int i = 0; i < args_len; ++i )
		{
		const Value* arg = (*args_val)[i];

		if ( arg )
			{
			if ( ! arg->IsNumeric() )
				{
				err = 1;
				SUBOP_CLEANUP_1
				return (IValue*) Fail( "index #", i+1, "into", this,
						"is not numeric");
				}

			if ( arg->Length() > max_len )
				max_len = arg->Length();

			if ( max_len == 1 )
				{
				int ind = arg->IntVal();
				if ( ind < 1 || ind > shape[i] )
					{
					err = 1;
					SUBOP_CLEANUP_1
					return (IValue*) Fail( "index #", i+1, "into",
						this, "is out of range");
					}

				offset += cur_factor * (ind - 1);
				}
			}

		else
			{ // Missing subscript.
			if ( shape[i] > max_len )
				max_len = shape[i];

			if ( max_len == 1 )
				offset += cur_factor * (shape[i] - 1);
			}

		factor[i] = cur_factor;
		cur_factor *= shape[i];
		}

	// Check to see if we're valid.
	if ( cur_factor > Length() )
		{
		err = 1;
		SUBOP_CLEANUP_1
		return (IValue*) Fail( "\"::shape\"/length mismatch" );
		}

	if ( max_len == 1 ) 
		{
		SUBOP_CLEANUP_1
		++offset;
		return new IValue( (IValue*) this, &offset, 1, VAL_REF );
		}

	int* index_is_copy = alloc_int( shape_len );
	int** index = alloc_intptr( shape_len );
	int* cur = alloc_int( shape_len );
	int* len = alloc_int( shape_len );
	int vecsize = 1;
	int is_element = 1;
	int spoof_dimension = 0;
	for ( LOOPDECL i = 0; i < args_len; ++i )
		{
		const Value* arg = (*args_val)[i];
		if ( arg )
			{
			index[i] = GenerateIndices( arg, len[i],
						index_is_copy[i], 0 );
			spoof_dimension = 0;
			}

		else
			{ // Spoof entire dimension.
			len[i] = shape[i];
			index[i] = alloc_int( len[i] );
			for ( int j = 0; j < len[i]; j++ )
				index[i][j] = j+1;
			index_is_copy[i] = 1;
			spoof_dimension = 1;
			}

		if ( is_element && len[i] > 1 )
			is_element = 0;

		vecsize *= len[i];
		cur[i] = 0;

		if ( ! spoof_dimension )
			{
			for ( int j = 0; j < len[i]; ++j )
				{
				if ( index[i][j] >= 1 &&
				     index[i][j] <= shape[i] )
					continue;

				SUBOP_CLEANUP(i)
				if ( len[i] > 1 )
					{
					err = 1;
					return (IValue*) Fail( "index #", i+1, ",",
							j+1, " into ", this, 
							"is out of range.");
					}
				else
					{
					err = 1;
					return (IValue*) Fail( "index #", i+1, "into",
						this, "is out of range.");
					}
				}
			}
		}

	// Loop through filling resultant vector.

	int* ret = alloc_int( vecsize );
	for ( int v = 0; v < vecsize; ++v )
		{
		// Calculate offset.
		offset = 0;
		for ( LOOPDECL i = 0; i < shape_len; ++i )
			offset += factor[i] * (index[i][cur[i]] - 1);

		// Set value.
		ret[v] = offset + 1;

		// Advance counters.
		for ( LOOPDECL i = 0; i < shape_len; ++i )
			if ( ++cur[i] < len[i] )
				break;
			else
				cur[i] = 0;
		}

	IValue* result = new IValue((IValue*) this, ret, vecsize, VAL_REF, 1 );
	result->CopyAttributes( this );

	if ( ! is_element )
		{
		int z = 0;
		for ( int x = 0; x < shape_len; ++x )
			if ( len[x] > 1 )
				len[z++] = len[x];

		Value* len_v = ValCtor::create( len, z );
		result->AssignAttribute( "shape", len_v );
		Unref( len_v );
		}
	else
		free_memory( len );

	SUBOP_CLEANUP_2(shape_len)
	return result;
	}


void IValue::AssignArrayElements( int* indices, int num_indices, Value* value,
				int rhs_len )
	{
	if ( IsRef() )
		{
		Deref()->AssignArrayElements(indices,num_indices,value,rhs_len);
		return;
		}

	int max_index, min_index;
	const char *err = IndexRange( indices, num_indices, max_index, min_index );
	if ( err )
		{
		glish_error->Report( err );
		return;
		}

	int orig_len = Length();
	if ( max_index > Length() )
		if ( ! Grow( (unsigned int) max_index ) )
			return;

	if ( Type() == TYPE_STRING && min_index > orig_len )
		{
		char **ary = (char**) StringPtr();
		for ( int x=orig_len; x < min_index; ++x )
			{
			ary[x] = alloc_char(1);
			ary[x][0] = '\0';
			}
		}

	switch ( Type() )
		{
#define ASSIGN_ARRAY_ELEMENTS_ACTION(tag,lhs_type,rhs_type,accessor,coerce_func,copy_func,delete_old_value)		\
	case tag:							\
		{							\
		int rhs_copy;						\
		rhs_type rhs_array = ((IValue*)value)->coerce_func( rhs_copy,	\
							rhs_len );	\
		lhs_type lhs = accessor();				\
		for ( int i = 0; i < num_indices; ++i )			\
			{						\
			delete_old_value				\
			lhs[indices[i]-1] = copy_func(rhs_array[i]);	\
			}						\
									\
		if ( rhs_copy )						\
			free_memory( rhs_array );			\
									\
		break;							\
		}

ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_BOOL,glish_bool*,glish_bool*,BoolPtr,
	CoerceToBoolArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_BYTE,byte*,byte*,BytePtr,
	CoerceToByteArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_SHORT,short*,short*,ShortPtr,
	CoerceToShortArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_INT,int*,int*,IntPtr,
	CoerceToIntArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_FLOAT,float*,float*,FloatPtr,
	CoerceToFloatArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_DOUBLE,double*,double*,DoublePtr,
	CoerceToDoubleArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_COMPLEX,glish_complex*,glish_complex*,ComplexPtr,
	CoerceToComplexArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_DCOMPLEX,glish_dcomplex*,glish_dcomplex*,DcomplexPtr,
	CoerceToDcomplexArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_STRING,charptr*,charptr*,StringPtr,
	CoerceToStringArray, string_dup, free_memory( (void*) lhs[indices[i]-1] );)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_FUNC,funcptr*,funcptr*,FuncPtr,
	CoerceToFuncArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_REGEX,regexptr*,regexptr*,RegexPtr,
	CoerceToRegexArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_FILE,fileptr*,fileptr*,FilePtr,
	CoerceToFileArray,,)

		case TYPE_SUBVEC_REF:
			switch ( VecRefPtr()->Type() )
				{
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_BOOL,glish_boolref&,glish_bool*,BoolRef,
	CoerceToBoolArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_BYTE,byteref&,byte*,ByteRef,
	CoerceToByteArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_SHORT,shortref&,short*,ShortRef,
	CoerceToShortArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_INT,intref&,int*,IntRef,
	CoerceToIntArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_FLOAT,floatref&,float*,FloatRef,
	CoerceToFloatArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_DOUBLE,doubleref&,double*,DoubleRef,
	CoerceToDoubleArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_COMPLEX,complexref&,glish_complex*,ComplexRef,
	CoerceToComplexArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_DCOMPLEX,dcomplexref&,glish_dcomplex*,DcomplexRef,
	CoerceToDcomplexArray,,)
ASSIGN_ARRAY_ELEMENTS_ACTION(TYPE_STRING,charptrref&,charptr*,StringRef,
	CoerceToStringArray, string_dup, free_memory( (void*) lhs[indices[i]-1] );)

				default:
					glish_fatal->Report(
			"bad subvec type in IValue::AssignArrayElements()" );
				}
			break;

		default:
			glish_fatal->Report(
				"bad type in IValue::AssignArrayElements()" );
		}
	}

void IValue::AssignArrayElements( Value* value )
	{
	if ( IsRef() )
		{
		Deref()->AssignArrayElements(value);
		return;
		}

	int max_index = Length();
	int val_len = value->Length();

	if ( Length() > val_len )
		{
		glish_warn->Report( "partial assignment to \"",this,"\"" );
		max_index = val_len;
		}

	else if ( Length() < val_len )
		if ( ! Grow( (unsigned int) val_len ) )
			glish_warn->Report( "partial assignment from \"",value,"\"" );

	switch ( Type() )
		{
#define ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(tag,type_lhs,type_rhs,accessor,coerce_func,copy_func,delete_old_value)	\
	case tag:							\
		{							\
		int rhs_copy;						\
		type_rhs rhs_array = ((IValue*)value->Deref())->coerce_func(	\
						rhs_copy, max_index );	\
		type_lhs lhs = accessor();				\
		for ( int i = 0; i < max_index; ++i )			\
			{						\
			delete_old_value				\
			lhs[i] = copy_func( rhs_array[i] );		\
			}						\
									\
		if ( rhs_copy )						\
			free_memory( rhs_array );			\
									\
		break;							\
		}

ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_BOOL,glish_bool*,glish_bool*,BoolPtr,
	CoerceToBoolArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_BYTE,byte*,byte*,BytePtr,
	CoerceToByteArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_SHORT,short*,short*,ShortPtr,
	CoerceToShortArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_INT,int*,int*,IntPtr,
	CoerceToIntArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_FLOAT,float*,float*,FloatPtr,
	CoerceToFloatArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_DOUBLE,double*,double*,DoublePtr,
	CoerceToDoubleArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_COMPLEX,glish_complex*,glish_complex*,
	ComplexPtr,CoerceToComplexArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_DCOMPLEX,glish_dcomplex*,glish_dcomplex*,
	DcomplexPtr,CoerceToDcomplexArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_STRING,charptr*,charptr*,StringPtr,
	CoerceToStringArray,string_dup, free_memory( (void*) lhs[i] );)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_FUNC,funcptr*,funcptr*,FuncPtr,
	CoerceToFuncArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_REGEX,regexptr*,regexptr*,RegexPtr,
	CoerceToRegexArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_FILE,fileptr*,fileptr*,FilePtr,
	CoerceToFileArray,,)

		case TYPE_SUBVEC_REF:
			switch ( VecRefPtr()->Type() )
				{
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_BOOL,glish_boolref&,glish_bool*,
	BoolRef, CoerceToBoolArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_BYTE,byteref&,byte*,ByteRef,
	CoerceToByteArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_SHORT,shortref&,short*,ShortRef,
	CoerceToShortArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_INT,intref&,int*,IntRef,
	CoerceToIntArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_FLOAT,floatref&,float*,FloatRef,
	CoerceToFloatArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_DOUBLE,doubleref&,double*,DoubleRef,
	CoerceToDoubleArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_COMPLEX,complexref&,glish_complex*,
	ComplexRef,CoerceToComplexArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_DCOMPLEX,dcomplexref&,glish_dcomplex*,
	DcomplexRef, CoerceToDcomplexArray,,)
ASSIGN_ARRAY_VALUE_ELEMENTS_ACTION(TYPE_STRING,charptrref&,charptr*,StringRef,
	CoerceToStringArray, string_dup, free_memory( (void*) lhs[i] );)

				default:
					glish_fatal->Report(
		"bad sub-array reference in IValue::AssignArrayElements()" );
				}
			break;
		default:
			glish_fatal->Report(
				"bad type in IValue::AssignArrayElements()" );
		}
	}

#define DEFINE_XXX_ARITH_OP_COMPUTE(name,type,coerce_func,access_func)	\
void IValue::name( const IValue* value, int lhs_len, ArithExpr* expr,	\
		   const char *&err )					\
	{								\
	int lhs_copy, rhs_copy;						\
	type* lhs_array = coerce_func( lhs_copy, lhs_len );		\
	type* rhs_array = ((IValue*)value)->coerce_func( rhs_copy, value->Length() );\
									\
	int rhs_incr = value->Length() == 1 ? 0 : 1;			\
									\
	if ( ! lhs_copy )						\
		lhs_array = access_func();				\
									\
	expr->Compute( lhs_array, rhs_array, lhs_len, rhs_incr, err );	\
									\
	if ( lhs_copy )							\
		{							\
		/* Change our value to the new result. */		\
		kernel.SetArray( lhs_array, lhs_len );			\
		if ( ! AttributePtr() )					\
			CopyAttributes( value );			\
		}							\
									\
	if ( rhs_copy )							\
		free_memory( rhs_array );				\
	}


DEFINE_XXX_ARITH_OP_COMPUTE(ByteOpCompute,byte,CoerceToByteArray,BytePtr)
DEFINE_XXX_ARITH_OP_COMPUTE(ShortOpCompute,short,CoerceToShortArray,ShortPtr)
DEFINE_XXX_ARITH_OP_COMPUTE(IntOpCompute,int,CoerceToIntArray,IntPtr)
DEFINE_XXX_ARITH_OP_COMPUTE(FloatOpCompute,float,CoerceToFloatArray,FloatPtr)
DEFINE_XXX_ARITH_OP_COMPUTE(DoubleOpCompute,double,CoerceToDoubleArray,DoublePtr)
DEFINE_XXX_ARITH_OP_COMPUTE(ComplexOpCompute,glish_complex,CoerceToComplexArray,ComplexPtr)
DEFINE_XXX_ARITH_OP_COMPUTE(DcomplexOpCompute,glish_dcomplex,CoerceToDcomplexArray,DcomplexPtr)

//
// If you change this function check Value::Polymorph
//
void IValue::Polymorph( glish_type new_type )
	{
	glish_type type = Type();
	int length = kernel.Length();

	if ( type == new_type )
		return;

	if ( IsVecRef() )
		{
		// ### hmmm, seems polymorphing a const subvec should be an
		// error ...
		VecRefPtr()->Val()->Polymorph( new_type );
		return;
		}

	if ( new_type == TYPE_INT && type == TYPE_BOOL )
		{
		// ### We do bool -> int conversions in place, relying on
		// the fact that bools are actually implemented as int's
		// with a value of either 0 (F) or 1 (T).  Note that this
		// is probably *buggy* since presently the internal "bool"
		// type is defined using an enumeration instead of as "int",
		// so a compiler might choose a smaller type.  Fixing this
		// is on the to-do list.
		kernel.BoolToInt();
		return;
		}

	switch ( new_type )
		{
#define POLYMORPH_ACTION(tag,type,coerce_func)				\
	case tag:							\
		{							\
		int is_copy;						\
		type* new_val = coerce_func( is_copy, length );		\
		if ( is_copy )						\
			kernel.SetArray( new_val, length );		\
		break;							\
		}

POLYMORPH_ACTION(TYPE_BOOL,glish_bool,CoerceToBoolArray)
POLYMORPH_ACTION(TYPE_BYTE,byte,CoerceToByteArray)
POLYMORPH_ACTION(TYPE_SHORT,short,CoerceToShortArray)
POLYMORPH_ACTION(TYPE_INT,int,CoerceToIntArray)
POLYMORPH_ACTION(TYPE_FLOAT,float,CoerceToFloatArray)
POLYMORPH_ACTION(TYPE_DOUBLE,double,CoerceToDoubleArray)
POLYMORPH_ACTION(TYPE_COMPLEX,glish_complex,CoerceToComplexArray)
POLYMORPH_ACTION(TYPE_DCOMPLEX,glish_dcomplex,CoerceToDcomplexArray)
POLYMORPH_ACTION(TYPE_STRING,charptr,CoerceToStringArray)

		case TYPE_FUNC:
			{
			int is_copy;
			funcptr* new_val = CoerceToFuncArray( is_copy, length );
			if ( is_copy )
				kernel.SetArray( (voidptr*) new_val, length, TYPE_FUNC );
			break;
			}
		case TYPE_REGEX:
			{
			int is_copy;
			regexptr* new_val = CoerceToRegexArray( is_copy, length );
			if ( is_copy )
				kernel.SetArray( (voidptr*) new_val, length, TYPE_REGEX );
			break;
			}
		case TYPE_FILE:
			{
			int is_copy;
			fileptr* new_val = CoerceToFileArray( is_copy, length );
			if ( is_copy )
				kernel.SetArray( (voidptr*) new_val, length, TYPE_FILE );
			break;
			}
		case TYPE_RECORD:
			if ( length > 1 && ! IsUninitialized( ) )
				glish_warn->Report( "array values lost due to conversion to record type" );

			kernel.SetRecord( create_record_dict() );

			break;

		default:
			glish_fatal->Report( "bad type in IValue::Polymorph()" );
		}
	}

int IValue::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( Type() == TYPE_FUNC )
		{
		// ### what if we're an array of functions?
		if ( opt.prefix() ) s << opt.prefix();
		FuncVal()->Describe( s, ioOpt(opt.flags(),opt.sep()) );
		}
	else
		return Value::Describe( s, opt );

	return 1;
	}


char *IValue::GetNSDesc( int evalable ) const
	{
	glish_type type = Type();

	if ( type == TYPE_AGENT )
		{
		if ( evalable )
			{
			char *buf = alloc_char(strlen(AgentVal()->AgentID())+3);
			sprintf(buf,"'%s'",AgentVal()->AgentID());
			return buf;
			}
		else
			return string_dup( AgentVal()->AgentID() );
		}

	if ( type == TYPE_FUNC )
		{
		if ( evalable )
			{
			static SOStream *srpt = new SOStream;
			srpt->reset();
			Describe( *srpt );
			return string_dup( srpt->str() );
			}
		else
			return string_dup( "<function>" );
		}

	return 0;
	}

int IValue::PropagateCycles( NodeList *cyc, int prune )
	{
	static value_list been_there;
	int ret = 0;

	if ( been_there.is_member( this ) ) return 0;
	been_there.append( (IValue*) this );

	glish_type type = Type();

	if ( type == TYPE_FUNC && cyc->is_member( FuncVal() ) )
		{
		ret += SetUnref( cyc, 1 );
		if ( prune )
			{
			cyc->prune( FuncVal() );
			}
		}
	else if ( type == TYPE_RECORD )
		{
		recordptr r = RecordPtr(0);
		IterCookie* c = r->InitForIteration();
		IValue* member;
		const char* key;
		while ( (member = (IValue*) r->NextEntry( key, c )) )
			{
			int mret = member->PropagateCycles( cyc, prune );
			if ( mret > 0 ) member->SetUnref( cyc, 1 );
			ret += mret;
			}
		if ( ret > 0 ) SetUnref( cyc, 1 );
		}
	else if ( type == TYPE_REF )
		{
		ret = ((IValue*)Deref())->PropagateCycles( cyc, prune );
		if ( ret > 0 ) SetUnref( cyc, 1 );
		}

	been_there.remove( (IValue*) this );
	return ret;
	}

int IValue::SoftDelete( )
	{
	if ( Type() == TYPE_RECORD )
		{
		recordptr r = RecordPtr();
		IterCookie* c = r->InitForIteration();

		Value* member;
		const char* key;
		while ( (member = r->NextEntry( key, c )) )
			{
			free_memory( (void*) key );
			Unref( member );
			}

		r->Clear();
		}

	else
		fprintf( stderr, "\nSOFT DELETE (%s) REQUIRED\n", type_names[Type()] );

	return 0;
	}

void IValue::PreDelete( )
	{
	unref.unref( );
	}


int IValue::SetUnref( NodeList *r, int propagate_only )
	{
	int not_same = 0;
	if ( r )
		{
		if ( (not_same = r != unref.ptr()) && unref.ptr() )
 			{
			// There may be residual problems here, previously before
			// the transition to "reflexive pointers" we handled (well
			// we actually just threw up our hands) the cases of
			// "mUNREF(mask) && propagate_only" and
			// "! mUNREF(mask) && ! propagate_only" specially.
			if ( ! propagate_only && ! mUNREF(mask) )
				mask |=  mUNREF();
			unref->append( r );
			return 1;
			}

		if ( unref.ptr() && unref.key() != ReflexPtrBase::current_key() )
			{
			// OK, so the keys differ here but the pointers are the same,
			// This means that this unref value was tagged during a
			// previous reference cycle cleanup
			not_same = 1;
			}

		unref = r;

		mask |=  mPROPAGATE();

		if ( ! propagate_only && ! mUNREF(mask) )
			{
			mask |=  mUNREF();
			Ref( unref );
			}
		}

	return not_same;
	}

void IValue::ClearUnref( )
	{
	if ( (NodeList*) unref )
		{
		if ( mUNREF(mask) ) Unref( unref );
		mask &= ~ (mUNREF() | mPROPAGATE());
		unref = 0;
		}
	}

void IValue::TakeValue( Value* new_value, Str &err )
	{
	IValue *nv = (IValue*) new_value->Deref();

	if ( nv == this )
		{
		err = strFail( "reference loop created" );
		return;
		}

	nv = copy_value( nv );

	//
	// Value::TakeValue() Unref()s nv...
	//
	Value::TakeValue( nv, err );
	//
	// It is assumed (everywhere?) that we will
	// Unref() new_value...
	//
	Unref( new_value );
	}

void init_ivalues( )
	{
	init_values( );
	register_type_funcs( TYPE_FUNC, copy_funcs, delete_funcs );
	register_type_funcs( TYPE_REGEX, copy_regexs, delete_regexs );
	register_type_funcs( TYPE_FILE, copy_files, delete_files );
	register_type_funcs( TYPE_AGENT, copy_agents, delete_agents );
	}

#define DEFINE_XXX_REL_OP_COMPUTE(name,type,coerce_func)		\
IValue* name( const IValue* lhs, const IValue* rhs, int lhs_len, RelExpr* expr )\
	{								\
	int lhs_copy, rhs_copy;						\
	type* lhs_array = lhs->coerce_func( lhs_copy, lhs_len );	\
	type* rhs_array = rhs->coerce_func( rhs_copy, rhs->Length() );	\
									\
	if ( ! lhs_array || ! rhs_array )				\
		{							\
		if ( lhs_array && lhs_copy ) free_memory( lhs_array );	\
		if ( rhs_array && rhs_copy ) free_memory( rhs_array );	\
		return new IValue( #name " failed", (const char*)0, 0 );\
		}							\
									\
	glish_bool* result = alloc_glish_bool( lhs_len );		\
									\
	int rhs_incr = rhs->Length() == 1 ? 0 : 1;			\
									\
	expr->Compute( lhs_array, rhs_array, result, lhs_len, rhs_incr );\
									\
	if ( lhs_copy )							\
		free_memory( lhs_array );				\
									\
	if ( rhs_copy )							\
		free_memory( rhs_array );				\
									\
	IValue* answer = new IValue( result, lhs_len );			\
	answer->CopyAttributes( lhs->AttributePtr() ? lhs : rhs );	\
	return answer;							\
	}


DEFINE_XXX_REL_OP_COMPUTE(bool_rel_op_compute,glish_bool,CoerceToBoolArray)
DEFINE_XXX_REL_OP_COMPUTE(byte_rel_op_compute,byte,CoerceToByteArray)
DEFINE_XXX_REL_OP_COMPUTE(short_rel_op_compute,short,CoerceToShortArray)
DEFINE_XXX_REL_OP_COMPUTE(int_rel_op_compute,int,CoerceToIntArray)
DEFINE_XXX_REL_OP_COMPUTE(float_rel_op_compute,float,CoerceToFloatArray)
DEFINE_XXX_REL_OP_COMPUTE(double_rel_op_compute,double,CoerceToDoubleArray)
DEFINE_XXX_REL_OP_COMPUTE(complex_rel_op_compute,glish_complex,CoerceToComplexArray)
DEFINE_XXX_REL_OP_COMPUTE(dcomplex_rel_op_compute,glish_dcomplex,
	CoerceToDcomplexArray)
DEFINE_XXX_REL_OP_COMPUTE(string_rel_op_compute,charptr,CoerceToStringArray)

#ifdef CLASS
#undef CLASS
#endif
#ifdef DOIVAL
#undef DOIVAL
#endif
#define CLASS IValue
#define DOIVAL 1
// This is also included by <Value.cc>
#include "StringVal"
