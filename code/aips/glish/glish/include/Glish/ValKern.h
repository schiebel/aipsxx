// $Id: ValKern.h,v 19.0 2003/07/16 05:15:51 aips2adm Exp $
// Copyright (c) 1997,1998,2000 Associated Universities Inc.
//
#ifndef valkern_h
#define valkern_h
#include "Glish/GlishType.h"
#include "Glish/Dict.h"
#include "Glish/Complex.h"

class Value;
class VecRef;

glish_declare(PDict,Value);
typedef PDict(Value)* recordptr;

typedef recordptr attributeptr;
typedef void* voidptr;

extern recordptr copy_record_dict( recordptr, int deep=0 );
extern recordptr create_record_dict();
void delete_record( recordptr r );

typedef void (*KernelCopyFunc)( void *, void *, size_t len );
typedef void (*KernelZeroFunc)( void *, size_t len );
typedef void (*KernelDeleteFunc)( void *, size_t len );
typedef void *(*KernelAllocateFunc)( size_t len );
typedef void *(*KernelReallocateFunc)( void *, size_t len );

typedef unsigned short vkmode_t;

extern void glish_copy_strings( void *, void *, size_t len );
#if ! defined(ENABLE_GC)
extern void glish_delete_strings( void *, size_t len );
#else
#define glish_delete_strings 0
#endif

struct glish_typeinfo_t {
	unsigned short bytes;
	KernelCopyFunc copy;
	KernelDeleteFunc final;
	KernelZeroFunc zero;
	KernelAllocateFunc allocate;
	KernelReallocateFunc reallocate;
};

extern glish_typeinfo_t glish_typeinfo[];
extern void register_type_funcs( glish_type, KernelCopyFunc c=0,
				 KernelDeleteFunc d=0, KernelZeroFunc z=0 );
//
// Copy-on-write semantics
//
class ValueKernel GC_FINAL_CLASS {

    public:

	//
	// These structures need to be public for some compilers, e.g.
	// Sun's native compiler
	//
	class array_t GC_FINAL_CLASS {
	    public:
		glish_type type;

		unsigned int length;
		unsigned int alloc_bytes;

		unsigned long ref_count;

		void* values;

		unsigned short type_bytes() { return glish_typeinfo[type].bytes; }
		KernelCopyFunc copy() { return glish_typeinfo[type].copy; }
		KernelDeleteFunc final() { return glish_typeinfo[type].final; }
		KernelZeroFunc zero() { return glish_typeinfo[type].zero; }
		KernelAllocateFunc allocate() { return glish_typeinfo[type].allocate; }
		KernelReallocateFunc reallocate() { return glish_typeinfo[type].reallocate; }

		unsigned int bytes() { return type_bytes()*length; }

		void SetType( glish_type t ) { type = t; }

		void Grow( unsigned int len, int do_zero = 1 );
		void SetStorage( void *storage, unsigned int len )
			{
			values = storage;
			length = len;
			alloc_bytes = length*type_bytes();
			}
		void clear();

		array_t() : type(TYPE_ERROR), length(0),
				alloc_bytes(0), ref_count(1), values(0)
				{ DIAG2((void*)this,"\t\tarray_t alloc") }
		~array_t();

	};

	class record_t GC_FINAL_CLASS {
	    public:
		recordptr record;
		unsigned long ref_count;
		void clear();
		record_t() : record(0), ref_count(1) { DIAG2((void*)this,"\t\trecord_t alloc") }
		~record_t() { clear(); }
		int bytes( int AddPerValue = 0 ) const;
		int Sizeof( int verbose=0, const char *id=0, int tab_count=0, const char *tab=0, int skip_first=0 ) const;
	};

    protected:

	inline vkmode_t mARRAY( vkmode_t mask=~((vkmode_t) 0) ) const { return mask & 1<<0; }
	inline vkmode_t mRECORD( vkmode_t mask=~((vkmode_t) 0) ) const { return mask & 1<<1; }
	inline vkmode_t mVALUE( vkmode_t mask=~((vkmode_t) 0) ) const { return mask & 1<<2; }
	inline vkmode_t mREF( vkmode_t mask=~((vkmode_t) 0) ) const { return mask & 1<<3; }
	inline vkmode_t mCONST( vkmode_t mask=~((vkmode_t) 0) ) const { return mask & 1<<4; }
	inline vkmode_t mMOD_CONST( vkmode_t mask=~((vkmode_t) 0) ) const { return mask & 1<<5; }
	inline vkmode_t mFAIL( vkmode_t mask=~((vkmode_t) 0) ) const { return mask & 1<<6; }
	inline vkmode_t mUNINITIALIZED( vkmode_t mask=~((vkmode_t) 0) ) const { return mask & 1<<7; }

	vkmode_t mode;

	union {
		array_t *array;
		record_t *record;
		Value *value;
		VecRef *vecref;
	};

	glish_type otherType() const;
	unsigned int otherLength() const;
	unsigned int otherBytes( int addPerValue = 0 ) const;
	int otherSizeof( ) const;

	void unrefArray(int del=0);
	void unrefRecord(int del=0);
	void unrefOthers();

	void refArray() { if ( array ) ++array->ref_count; }
	void refRecord() { if ( record ) ++record->ref_count; }
	void refOthers();
	void ref()
		{ 
		if ( mARRAY(mode) ) refArray();
		else if ( mRECORD(mode) || mFAIL(mode) ) refRecord();
		else refOthers();
		}

    public:

	struct header {
		glish_type 	type;
		int 		len;
		char 		have_attr;
	};

	void MakeConst() { mode |= mCONST(); }
	void MakeModConst() { mode |= mMOD_CONST(); }
	int IsConst() const { return mCONST(mode); }
	int IsModConst() const { return mMOD_CONST(mode); }

	void MarkUninitialized() { mode |= mUNINITIALIZED( ); }
	void ClearUninitialized() { mode &= ~mUNINITIALIZED( ); }
	int IsUninitialized() const { return mUNINITIALIZED(mode); }

	ValueKernel() : mode(0), array(0) { }
	ValueKernel( const ValueKernel &v ) : mode( v.mode & ~ mCONST() ),
					      array(v.array) { ref(); }

	ValueKernel &operator=( const ValueKernel &v );

	ValueKernel( glish_type t, unsigned int len );

	void SetType( glish_type t, unsigned int l );
	// This function should be used with caution. It assumes 
	// sizeof(int) == sizeof(glish_type).
	void BoolToInt();
// 	void SetArray( void *storage, unsigned int len, glish_type t, int copy = 0 );
	void SetArray( glish_bool vec[], unsigned int len, int copy = 0 );
	void SetArray( byte vec[], unsigned int len, int copy = 0 );
	void SetArray( short vec[], unsigned int len, int copy = 0 );
	void SetArray( int vec[], unsigned int len, int copy = 0 );
	void SetArray( float vec[], unsigned int len, int copy = 0 );
	void SetArray( double vec[], unsigned int len, int copy = 0 );
	void SetArray( glish_complex vec[], unsigned int len, int copy = 0 );
	void SetArray( glish_dcomplex vec[], unsigned int len, int copy = 0 );
	void SetArray( const char* vec[], unsigned int len, int copy = 0 );
	void SetArray( voidptr vec[], unsigned int len, glish_type t, int copy = 0 );

	void Replace( const char* vec[], unsigned int len );

	void Grow( unsigned int len );

	// May return 0 if Type() == TYPE_ERROR
	void *constArray() const { return array->values; }
	// Shouldn't return 0
	void *modArray();
	void *modArray() const { return (((ValueKernel*)this)->modArray()); }

	void SetRecord( recordptr r );
	// May return 0
	recordptr constRecord() const { return record ? record->record : 0; }
	// Shouldn't return 0
	recordptr modRecord();
	recordptr modRecord() const { return (((ValueKernel*)this)->modRecord()); }

	void SetFail( recordptr r );

	void SetValue( Value *v );
	Value *GetValue() const { return value; }

	void SetVecRef( VecRef *v );
	VecRef *GetVecRef() const { return vecref; }

	unsigned long RefCount( ) const;

	glish_type Type() const
		{
		return ! array ? TYPE_ERROR :
		       mARRAY(mode) ? array->type :
		       mRECORD(mode) ? TYPE_RECORD :
		       otherType();
		}
	int Length() const
		{
		return mARRAY(mode) ? (int) array->length :
		       mRECORD(mode) || mFAIL(mode) ? record->record->Length() :
		       otherLength();
		}

	int Sizeof( int verbose=0, const char *id=0, int tab_count=0, const char *tab=0, int skip_first=0 ) const;
	int Bytes( int addPerValue = 0 ) const;
	int ToMemBlock(char *memory, int offset = 0, int have_attributes = 0) const;

	void unref( int del=0 )
		{
		if ( mARRAY(mode) ) unrefArray(del);
		else if ( mRECORD(mode) || mFAIL(mode) ) unrefRecord(del);
		else unrefOthers();
		}

	~ValueKernel( ) { unref(1); }
};

#endif
