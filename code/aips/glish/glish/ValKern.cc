// $Id: ValKern.cc,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1997,1998,2000 Associated Universities Inc.
//

#include "Glish/glish.h"
RCSID("@(#) $Id: ValKern.cc,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $")

#include "system.h"
#include "Glish/Value.h"
#include "Glish/VecRef.h"
#include "Glish/List.h"
#include <string.h>
#include <stdlib.h>

typedef ValueKernel::record_t our_recordptr;
glish_declare(PList,our_recordptr);
typedef PList(our_recordptr) recordptr_list;

glish_typeinfo_t glish_typeinfo[NUM_GLISH_TYPES] =
	{ { 0, 0, 0, 0, 0, 0 },							/* TYPE_ERROR */
	  { 0, 0, 0, 0, 0, 0 },							/* TYPE_REF */
	  { 0, 0, 0, 0, 0, 0 },  						/* TYPE_SUBVEC_REF */
	  { sizeof(glish_bool), 0, 0, 0, alloc_memory_atomic_func, 0 },		/* TYPE_BOOL */
	  { sizeof(byte), 0, 0, 0, alloc_memory_atomic_func, 0 },		/* TYPE_BYTE */
	  { sizeof(short), 0, 0, 0, alloc_memory_atomic_func, 0 },		/* TYPE_SHORT */
	  { sizeof(int), 0, 0, 0, alloc_memory_atomic_func, 0 },		/* TYPE_INT */
	  { sizeof(float), 0, 0, 0, alloc_memory_atomic_func, 0 },		/* TYPE_FLOAT */
	  { sizeof(double), 0, 0, 0, alloc_memory_atomic_func, 0 },		/* TYPE_DOUBLE */
	  { sizeof(charptr), glish_copy_strings, glish_delete_strings, 0, alloc_memory_func, 0 },
										/* TYPE_STRING */
	  { sizeof(void*), 0, 0, 0, 0, 0 },					/* TYPE_AGENT */
	  { sizeof(void*), 0, 0, 0, 0, 0 },					/* TYPE_FUNC */
	  { 0, 0, 0, 0, 0, 0 },							/* TYPE_RECORD */
	  { sizeof(glish_complex), 0, 0, 0, alloc_memory_atomic_func, 0 },	/* TYPE_COMPLEX */
	  { sizeof(glish_dcomplex), 0, 0, 0, alloc_memory_atomic_func, 0 },	/* TYPE_DCOMPLEX */
	  { 0, 0, 0, 0, 0, 0 },							/* TYPE_FAIL */
	  { sizeof(void*), 0, 0, 0, 0, 0 }					/* TYPE_REGEX */
	};

void register_type_funcs( glish_type t, KernelCopyFunc c,
			  KernelDeleteFunc d, KernelZeroFunc z )
	{
	glish_typeinfo[t].copy = c;
	glish_typeinfo[t].final = d;
	glish_typeinfo[t].zero = z;
	}

void ValueKernel::record_t::clear()
	{
	if (record) delete_record(record);
	record = 0;
	ref_count = 1;
	}

int ValueKernel::record_t::Sizeof( int verbose, const char *id, int tab_count, const char *tab, int skip_first ) const
	{
	int size = 0;
	IterCookie* c = record->InitForIteration();

	Value* member;
	const char* key;

	if ( verbose )
		{
		if ( ! skip_first ) for (int i=0; i < tab_count; ++i) fprintf(stdout,"%s",tab?tab:"\t");
		fprintf( stdout, " + " );
		record->Sizeof( verbose, "Dict(Value)" );
		fprintf( stdout, " + %d {ValueKernel}\n", sizeof(ValueKernel) );
		}

	while ( (member = record->NextEntry( key, c )) )
		{
		if ( verbose )
			{
			for (int i=0; i < tab_count; ++i) fprintf(stdout,tab?tab:"\t");
			int keysize = strlen(key) + 1;
			fprintf(stdout, "<%s> %d {key}", key, keysize);
			size += keysize + member->Sizeof( verbose, key, tab_count+1, tab, 1 );
			}
		else
			size += strlen(key) + 1 + member->Sizeof( );
		}
	return size + record->Sizeof() + sizeof(ValueKernel);
	}

int ValueKernel::record_t::bytes( int addPerValue ) const
	{
	int size = addPerValue;
	IterCookie* c = record->InitForIteration();

	Value* member;
	const char* key;

	while ( (member = record->NextEntry( key, c )) )
		size += strlen(key) + 1 + member->Bytes(addPerValue);
	return size;
	}

ValueKernel::array_t::~array_t()
	{
	if ( values ) 
		{
		if ( final() )
			(*final())( values, length );

		free_memory( values );
		}
	}

void ValueKernel::array_t::clear()
	{
	type = TYPE_ERROR;
	length = 0;
	ref_count = 1;
	}

void ValueKernel::SetValue( Value *v )
	{
	unref(1);
	mode = mVALUE();
	value = v;
	refOthers();
	}

void ValueKernel::SetFail( recordptr r )
	{
	DIAG2( (void*) this, "\tValueKernel::SetFail recordptr")
	unref( mRECORD(mode) || mFAIL(mode) ? 0 : 1 );
	mode = mFAIL();
	if ( ! record ) record = new record_t();
	record->record = r;
	}

void ValueKernel::SetVecRef( VecRef *v )
	{
	unref(1);
	mode = mREF();
	vecref = v;
	refOthers();
	}

glish_type ValueKernel::otherType() const
	{
	if ( mVALUE(mode) )
		return TYPE_REF;
	else if ( mREF(mode) )
		return TYPE_SUBVEC_REF;
	else if ( mFAIL(mode) )
		return TYPE_FAIL;
	else
		return TYPE_ERROR;
	}

unsigned int ValueKernel::otherLength() const
	{
	if ( mVALUE(mode) )
		return value->Length();
	else if ( mREF(mode) )
		return vecref->Length();
	else
		return 0;
	}

int ValueKernel::otherSizeof( ) const
	{
	if ( mVALUE(mode) )
		return sizeof(ValueKernel) + value->Sizeof( );
	else if ( mREF(mode) )
		return sizeof(ValueKernel) + vecref->Sizeof( );
	else
		return 0;
	}


unsigned int ValueKernel::otherBytes(int addPerValue) const
	{
	if ( mVALUE(mode) )
		return value->Bytes(addPerValue);
	else if ( mREF(mode) )
		return vecref->Bytes() + addPerValue;
	else
		return 0;
	}

void ValueKernel::SetRecord( recordptr r )
	{
	DIAG2( (void*) this, "\tValueKernel::SetRecord recordptr")
	unref( mRECORD(mode) || mFAIL(mode) ? 0 : 1 );
	mode = mRECORD();
	if ( ! record ) record = new record_t();
	record->record = r;
	}

void ValueKernel::array_t::Grow( unsigned int len, int do_zero )
	{
	unsigned int alen = len ? len : 1;

	if ( len && len == length )
		return;

	if ( len < length )
		{
		if ( final() )
			(*final())( &(((char *)values)[len*type_bytes()]), length-len );
		}
	else
		{
		if ( values == 0 || alloc_bytes == 0 )
			{
			alloc_bytes = alen*type_bytes();
			if ( allocate() )
				values = (*allocate())( alloc_bytes );
			else
				values = alloc_memory( alloc_bytes );
			}
		else if ( len*type_bytes() > alloc_bytes )
		  	{
			alloc_bytes = len*type_bytes();
			if ( reallocate() )
				values = (*reallocate())( values, alloc_bytes );
			else
				values = realloc_memory( values, alloc_bytes );
			}

		if ( do_zero || ! len )
			{
			if ( zero()  )
				(*zero())( &(((char *)values)[length*type_bytes()]), alen-length );
			else
				memset( &((char *)values)[length*type_bytes()], 0, (alen-length)*type_bytes() );
			}
		}

	length = len;
	}


void ValueKernel::unrefArray(int del)
	{
	DIAG7((void*) this, "\t\tarray unref c:",array->ref_count,"a:",(void*)array,"d:",del)
	if ( array && --(array->ref_count) == 0 )
		if ( del )
			{
			delete array;
			array = 0;
			}
		else
			array->clear();
	else
		if ( del )
			array = 0;
		else
			array = new array_t();
	}

void ValueKernel::unrefRecord(int del)
	{
	DIAG7((void*) this, "\t\trecord unref c:",record->ref_count,"r:",(void*)record,"d:",del)

	if ( record )
		{
		if ( --record->ref_count == 0 )
			if ( del )
				{
				delete record;
				record = 0;
				}
			else
				record->clear();
		else
			if ( del )
				record = 0;
			else
				record = new record_t();
		}
	}

ValueKernel::ValueKernel( glish_type t, unsigned int len ) : mode(mARRAY()), array(new array_t())
	{
	array->SetType( t );
	array->Grow( len );
	}

void ValueKernel::SetType( glish_type t, unsigned int l )
	{
	unref( mARRAY(mode) ? 0 : 1 );
	mode = mARRAY();
	if ( ! array ) array = new array_t();
	array->SetType( t );
	array->Grow( l );
	}

void ValueKernel::BoolToInt()
	{
	if ( Type() != TYPE_BOOL ) return;
	modArray();
	array->type = TYPE_INT;
	}

ValueKernel &ValueKernel::operator=( const ValueKernel &v )
	{
	unref(1);
	array = v.array;
	mode = v.mode;
	ref();
	return *this;
	}


#define ARRAY_SET_BODY(GLISH_TYPE)						\
	unref( mARRAY(mode) && copy ? 0 : 1 );					\
	mode = mARRAY();								\
	if ( ! array ) array = new array_t();					\
	array->SetType( GLISH_TYPE );						\
	if ( copy )								\
		{								\
		array->Grow( len, 0 );						\
		if ( array->copy() )						\
			(*array->copy())(array->values, vec, array->length);	\
		else								\
			memcpy(array->values, vec, array->bytes());		\
		}								\
	else									\
		array->SetStorage( vec, len );

#define DEFINE_ARRAY_SET(TYPE, GLISH_TYPE)					\
void ValueKernel::SetArray( TYPE vec[], unsigned int len, int copy )		\
	{									\
	DIAG4( (void*) this, "\tValueKernel::SetArray ", #TYPE, "[]" )		\
	ARRAY_SET_BODY(GLISH_TYPE)						\
	}

DEFINE_ARRAY_SET(glish_bool,TYPE_BOOL)
DEFINE_ARRAY_SET(byte,TYPE_BYTE)
DEFINE_ARRAY_SET(short,TYPE_SHORT)
DEFINE_ARRAY_SET(int,TYPE_INT)
DEFINE_ARRAY_SET(float,TYPE_FLOAT)
DEFINE_ARRAY_SET(double,TYPE_DOUBLE)
DEFINE_ARRAY_SET(glish_complex,TYPE_COMPLEX)
DEFINE_ARRAY_SET(glish_dcomplex,TYPE_DCOMPLEX)
DEFINE_ARRAY_SET(charptr,TYPE_STRING)

void ValueKernel::Replace( charptr vec[], unsigned int len )
	{
	array->SetStorage( vec, len );
	}

void ValueKernel::SetArray( voidptr vec[], unsigned int len, glish_type t, int copy )
	{
	DIAG2( (void*) this, "\tValueKernel::SetArray void*")
	ARRAY_SET_BODY(t)
	}

void ValueKernel::Grow( unsigned int len )
	{
	if ( ! mARRAY(mode) || ! array || len == array->length || array->ref_count < 1 )
		return;
	if ( array->ref_count == 1 )
		array->Grow( len );
	else
		{
		unsigned int minlen = len > array->length ? array->length : len;
		array_t *k = array;
		unrefArray();
		vkmode_t m = mode;
		array->SetType( k->type );
		mode = m;
		array->Grow( len, 0 );

		if ( array->copy() )
			(*array->copy())(array->values, k->values, minlen);
		else
			memcpy(array->values, k->values, minlen*array->type_bytes());

		if ( len > minlen )
			{
			if ( array->zero() )
				(*array->zero())( &((char*)array->values)[k->bytes()],len - k->length );
			else
				memset( &((char*)array->values)[k->bytes()], 0,
					(len-k->length)*array->type_bytes() );
			}
		}
	}

void *ValueKernel::modArray( )
	{
	if ( ! mARRAY(mode) || ! array || array->ref_count < 1 )
		return 0;
	if ( array->ref_count == 1 )
		return array->values;
	else
		{
		DIAG5((void*) this, "\t\tarray copy c:",array->ref_count,"a:",(void*)array)
		array_t *k = array;
		unrefArray();
		vkmode_t m = mode;
		array->SetType( k->type );
		mode = m;
		array->Grow( k->length, 0 );
		if ( array->copy() )
			(*array->copy())(array->values, k->values, array->length);
		else
			memcpy(array->values, k->values, array->bytes());
		}
	return array->values;
	}


recordptr ValueKernel::modRecord( )
	{
	if ( ! mRECORD(mode) && ! mFAIL(mode) || ! record || record->ref_count < 1 )
		return 0;
	if ( record->ref_count == 1 )
		return record->record;
	else
		{
		DIAG5((void*) this, "\t\trecord copy c:",record->ref_count,"r:",(void*)record)
		record_t *a = record;
		unrefRecord();
		vkmode_t m = mode;
		SetRecord(copy_record_dict(a->record));
		mode = m;
		}
	return record->record;
	}

unsigned long ValueKernel::RefCount( ) const
	{
	if ( mARRAY(mode) ) return array->ref_count;
	if ( mRECORD(mode) || mFAIL(mode) ) return record->ref_count;
	if ( mVALUE(mode) ) return (unsigned long) value->RefCount();
	if ( mREF(mode) ) return (unsigned long) vecref->RefCount();
	return 0;
	}

void ValueKernel::refOthers()
	{
	if ( mVALUE(mode) )
		Ref( value );
	else if ( mREF(mode) )
		Ref( vecref );
	}

void ValueKernel::unrefOthers()
	{
	if ( mVALUE(mode) )
		Unref( value );
	else if ( mREF(mode) )
		Unref( vecref );
	}

int ValueKernel::Sizeof( int verbose, const char *id, int tab_count, const char *tab, int skip_first ) const
	{
	if ( verbose && ! skip_first ) for (int i=0; i < tab_count; ++i) fprintf(stdout,tab?tab:"\t");
	if ( mARRAY(mode) )
		{
		if ( Type() != TYPE_STRING )
			{
			if ( verbose ) fprintf( stdout, " + %d {array_t} + %d {ValueKernel} + %d {vector}\n",
						sizeof(array_t), sizeof(ValueKernel), array->bytes() );
			return (int) array->bytes() + sizeof(array_t) + sizeof(ValueKernel);
			}
		else
			{
			int cnt = 0;
			for ( unsigned int i = 0; i < array->length; i++ )
				cnt += strlen(((char**)array->values)[i])+1;
			if ( verbose ) fprintf( stdout, " + %d {array_t} + %d {ValueKernel} + %d {vector}\n",
						 sizeof(array_t), sizeof(ValueKernel), cnt + array->bytes() );
			return cnt + array->bytes() + sizeof(array_t) + sizeof(ValueKernel);
			}
		}
	else if ( mRECORD(mode) || mFAIL(mode) )
		{
		if ( verbose ) fprintf( stdout, " + %d {record_t}", sizeof(record_t) );
		return sizeof(record_t) + record->Sizeof( verbose, 0, tab_count+1, tab, 1 );
		}
	else
		return otherSizeof();
	}


int ValueKernel::Bytes( int addPerValue ) const
	{
	if ( mARRAY(mode) )
		{
		if ( Type() != TYPE_STRING )
			return (int) array->bytes() + addPerValue;
		else
			{
			int cnt = addPerValue;
			for ( unsigned int i = 0; i < array->length; i++ )
				cnt += strlen(((char**)array->values)[i])+1;
			return cnt;
			}
		}
	else if ( mRECORD(mode) || mFAIL(mode) )
		return record->bytes( addPerValue );
	else
		return otherBytes();
	}


int ValueKernel::ToMemBlock(char *memory, int offset, int have_attributes) const
	{
	header h;
	glish_type type = Type();
	if ( mARRAY(mode) )
		{
		h.type = type;
		h.have_attr = have_attributes ? 1 : 0;

		if ( type != TYPE_STRING )
			{
			h.len = array->bytes();
			memcpy(&memory[offset],&h,sizeof(h));
			offset += sizeof(h);

			memcpy(&memory[offset],array->values,h.len);
			offset += h.len;
			}
		else
			{
			h.len = array->length;
			memcpy(&memory[offset],&h,sizeof(h));
			offset += sizeof(h);

			for (int i=0; i < h.len; i++)
				{
				int l = strlen(((char**)array->values)[i]);
				memcpy(&memory[offset],((char**)array->values)[i],l+1);
				offset += l+1;
				}
			}
		}
	else if ( mRECORD(mode) || mFAIL(mode) )
		{
		h.type = type;
		h.len = record->record->Length();
		h.have_attr = have_attributes ? 1 : 0;

		memcpy(&memory[offset],&h,sizeof(h));
		offset += sizeof(h);

		IterCookie* c = record->record->InitForIteration();

		Value* member;
		const char* key;

		while ( (member = record->record->NextEntry( key, c )) )
			{
			int l = strlen(key);
			memcpy(&memory[offset],key,l+1);
			offset += l+1;
			offset = member->ToMemBlock(memory, offset);
			}
		}

	else
		return -1;

	return offset;
	}


recordptr create_record_dict()
	{
	return new PDict(Value)( ORDERED );
	}

void delete_record( recordptr r )
	{
// 	hold_garbage( );

	if ( r )
		{
		IterCookie* c = r->InitForIteration();

		Value* member;
		const char* key;

		while ( (member = r->NextEntry( key, c )) )
			{
			free_memory( (void*) key );
			Unref( member );
			}

		delete r;
		}

// 	release_garbage( );
	}

recordptr copy_record_dict( recordptr rptr, int deep )
	{
	int ordered = rptr->IsOrdered();
	recordptr new_record = new PDict(Value)( ordered ? ORDERED : UNORDERED );

	const char* key;
	const Value* member;
	Value* new_member;

	if ( ordered )
		{
		for ( int i = 0; i < rptr->Length(); i++ )
			{
			member = rptr->NthEntry(i,key);
			new_member = deep ? deep_copy_value( member ) : copy_value( member );
			if ( member->IsConst() )
				new_member->MakeConst();
			if ( member->IsModConst() )
				new_member->MakeModConst();
			new_record->Insert( string_dup(key), new_member );
			}
		}
	else
		{
		IterCookie *c = rptr->InitForIteration();
		while ( (member = rptr->NextEntry( key, c )) ) 
			new_record->Insert( string_dup( key ), deep ? deep_copy_value( member ) : copy_value( member ) );
		}

	return new_record;
	}

void glish_copy_strings(void *tgt, void *src, size_t len)
	{
	charptr *from = (charptr*)src;
	charptr *to = (charptr*)tgt;
	for ( unsigned int i=0; i < len; i++ )
		*to++ = string_dup(*from++);
	}

#if ! defined(ENABLE_GC)
void glish_delete_strings(void *src, size_t len)
	{
	char **ary = (char**)src;
	for ( unsigned int i=0; i < len; i++ )
		free_memory( *ary++ );
	}
#endif
