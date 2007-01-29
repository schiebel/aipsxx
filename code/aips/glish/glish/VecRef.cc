// $Id: VecRef.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1997,1998 Associated Universities Inc.
//

#include "config.h"
#include "Glish/glish.h"
RCSID("@(#) $Id: VecRef.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $")
#include <memory.h>
#include <string.h>

#include "Glish/Value.h"
#include "Glish/VecRef.h"
#include "Glish/Reporter.h"
#include "system.h"

glish_implement(SubVecRef,glish_bool)
glish_implement(SubVecRef,byte)
glish_implement(SubVecRef,short)
glish_implement(SubVecRef,int)
glish_implement(SubVecRef,float)
glish_implement(SubVecRef,double)
glish_implement(SubVecRef,glish_complex)
glish_implement(SubVecRef,glish_dcomplex)
glish_implement2(SubVecRef,charptr,string_dup)

const char *VecRef::Description() const
	{
	return "vecref";
	}

int VecRef::TranslateIndex( int index, int* error ) const 
	{
	if ( error )
		*error = 0;

	if ( Type() == TYPE_RECORD )
	    return index;

	int offset = indices[index];
	if ( error && offset > val->Length() )
		*error = 1;

	return offset - 1;
	}

VecRef::VecRef( Value* value, int arg_indices[], int num, int arg_max_index,
		int take_indices )
	{
	len = num;
	max_index = arg_max_index;
	ref = 0;
	vec = 0;
	is_subvec_ref = 0;

	Value* v = value->VecRefDeref();

	if ( ! v->IsNumeric() && v->Type() != TYPE_STRING)
		  glish_error->Report( "bad type in VecRef::VecRef()" );

	if ( ! take_indices )
		{
		indices = (int*) alloc_int( len );
		memcpy(indices, arg_indices, len * sizeof(int));
		}
	else
		indices = arg_indices;

	val = FindIndices( value, indices, num );
	Ref( val );
	}

VecRef::VecRef( Value* ref_value, int* index, int num, int arg_max_index,
		void* values, glish_type t )
	{
	val = ref_value;
	Ref( val );
	indices = index;
	is_subvec_ref = 1;
	len = num; 
	max_index = arg_max_index;
	vec = values;
	subtype = t;
	ref = 0;
	}

VecRef::~VecRef()
	{
	if ( ! is_subvec_ref )
		// We "own" the indices.
		free_memory( indices );

	Unref( ref );
	Unref( val );
	}

Value* VecRef::FindIndices( Value* value, int* Indices, int num )
	{
	if ( value->IsVecRef() )
		{
		VecRef* vecref = value->VecRefPtr();
		for ( int i = 0; i < num; ++i )
			Indices[i] = vecref->indices[Indices[i] - 1];
		return FindIndices( vecref->Val(), Indices, num );
		}

	else if ( value->IsRef() )
		return FindIndices( value->Deref(), Indices, num );

	else
		return value;
	}

#define SUBVEC_SUBSCRIPT_ACTION(name,type,tag,accessor)			\
SubVecRef(type)* VecRef::name()						\
	{								\
	if ( val->Type() != tag )					\
		glish_fatal->Report( "bad type in VecRef::name" );		\
									\
	if ( ref && ref->Type() == tag )				\
		/* We already have a suitable SubVecRef. */		\
		return (SubVecRef(type) *) ref;				\
									\
	vec = val->accessor();						\
	Unref( ref );							\
	ref = new SubVecRef(type)( val, indices, len,			\
					max_index, vec, tag );		\
	return (SubVecRef(type) *) ref;					\
	}

SUBVEC_SUBSCRIPT_ACTION(BoolRef,glish_bool,TYPE_BOOL,BoolPtr)
SUBVEC_SUBSCRIPT_ACTION(ByteRef,byte,TYPE_BYTE,BytePtr)
SUBVEC_SUBSCRIPT_ACTION(ShortRef,short,TYPE_SHORT,ShortPtr)
SUBVEC_SUBSCRIPT_ACTION(IntRef,int,TYPE_INT,IntPtr)
SUBVEC_SUBSCRIPT_ACTION(FloatRef,float,TYPE_FLOAT,FloatPtr)
SUBVEC_SUBSCRIPT_ACTION(DoubleRef,double,TYPE_DOUBLE,DoublePtr)
SUBVEC_SUBSCRIPT_ACTION(ComplexRef,glish_complex,TYPE_COMPLEX,ComplexPtr)
SUBVEC_SUBSCRIPT_ACTION(DcomplexRef,glish_dcomplex,TYPE_DCOMPLEX,DcomplexPtr)
SUBVEC_SUBSCRIPT_ACTION(StringRef,charptr,TYPE_STRING,StringPtr)

// Called after someone has twiddled with our indices
void VecRef::IndexUpdate( )
	{
	max_index = 0;
	for ( int i = 0; i < len; ++i )
		if ( indices[i] >= 1 && indices[i] > max_index )
			max_index = indices[i];
	}
