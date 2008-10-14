// $Id: VecRef.h,v 19.1 2004/07/13 22:37:01 dschieb Exp $
// Copyright (c) 1997,1998 Associated Universities Inc.
//
#ifndef subvecref_h
#define subvecref_h
#include "Glish/glish.h"

class VecRef : public GlishObject {
    public:
	VecRef( Value* value, int arg_indices[], int num, int Max_Index,
		int take_indicies = 0);
	virtual ~VecRef();

	Value* Val()		{ return val; }
	int Length() const 	{ return len; }
	int &Length()		{ return len; }

	int *&Indices()		{ return indices; }
	int *Indices() const	{ return indices; }

	void IndexUpdate( );

	glish_type Type() const		// SGI's DCC thinks the type of
					// this ternary expression is int
		{ return glish_type(is_subvec_ref ? subtype : val->Type()); }

	// In: Zero Based
	// Out: Zero Based
	int TranslateIndex( int index, int* error = 0 ) const;

	glish_boolref* BoolRef();
	byteref* ByteRef();
	shortref* ShortRef();
	intref* IntRef();
	floatref* FloatRef();
	doubleref* DoubleRef();
	complexref* ComplexRef();
	dcomplexref* DcomplexRef();
	charptrref* StringRef();

	int Bytes() const { return val->Bytes() / val->Length() * len; }
	int Sizeof() const { return len * sizeof(int) + sizeof(VecRef); }

	const char *Description() const;

    protected:
	// Constructor used by SubVecRef classes.
	VecRef( Value* ref_value, int* index, int num, int arg_max_index,
		void* values, glish_type t );

	Value* FindIndices( Value* value, int* Indices, int num );

	Value* val;	// the value we're sub'refing
	int* indices;	// our indices into that value
	int len;	// the length of the indices
	int max_index;	// maximum possible index value
	void* vec;	// the underlying C++ vector that we're subref'ing
	glish_type subtype;	// our Glish type
	int is_subvec_ref;	// whether we're a SubVecRef or a VecRef
	VecRef* ref;	// our corresponding SubVecRef, or nil if we haven't
			// created it yet
	};

#define SubVecRefdeclare(type)						\
class SubVecRef(type) : public VecRef {					\
    public:								\
	type& operator[]( int index );					\
	type* DupVec( type *ret = 0 ) const;				\
									\
    protected:								\
	friend class VecRef;						\
	SubVecRef(type)( Value* ref_value, int* index, int num, 	\
			int arg_max_index, void* values, glish_type t )	\
			: VecRef( ref_value, index, num, arg_max_index,	\
				  values, t )				\
		{							\
		}							\
	}

#define SubVecRefimplement2(type,func)					\
type* SubVecRef(type)::DupVec( type *ret ) const			\
	{								\
	if ( ! ret )							\
		ret = (type*) alloc_memory( sizeof(type)*Length() );	\
									\
	for ( int i = 0; i < Length(); ++i )				\
		{							\
		int err;						\
		int off = TranslateIndex( i, &err );			\
		if ( err )						\
			{						\
			glish_error->Report( "invalid subscript (", i+1,\
			"), sub-vector reference is probably invalid" );\
			break;						\
			}						\
		ret[i] = func( ((type*) vec)[off] );			\
		}							\
	return ret;							\
	}								\
type& SubVecRef(type)::operator[]( int index )				\
	{ 								\
	int err;							\
	int off = TranslateIndex( index, &err );			\
	if ( err )							\
		{							\
		glish_error->Report("invalid subscript (", index+1,	\
			"), sub-vector reference is probably invalid");	\
		static type error_value;				\
		return error_value;					\
		}							\
	return ((type*) vec)[off]; 					\
	}								\



#define SubVecRefimplement(type) SubVecRefimplement2(type,)

glish_declare(SubVecRef,glish_bool);
glish_declare(SubVecRef,byte);
glish_declare(SubVecRef,short);
glish_declare(SubVecRef,int);
glish_declare(SubVecRef,float);
glish_declare(SubVecRef,double);
glish_declare(SubVecRef,glish_complex);
glish_declare(SubVecRef,glish_dcomplex);
glish_declare(SubVecRef,charptr);

#endif
