// $Id: Dict.h,v 19.0 2003/07/16 05:15:53 aips2adm Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.
#ifndef dict_h
#define dict_h

#include "Glish/List.h"

class Dictionary;
class IterCookie;

class DictEntry GC_FINAL_CLASS {
public:
	DictEntry( const char* k, void* val )
		{ key = k; value = val; }

	const char* key;
	void* value;
	};

glish_declare(PList,DictEntry);

// Default number of hash buckets in dictionary.  The dictionary will
// increase the size of the hash table as needed.
#define DEFAULT_DICT_SIZE 5

// Type indicating whether the dictionary should keep track of the order
// of insertions.
typedef enum { ORDERED, UNORDERED } dict_order;

class Dictionary GC_FINAL_CLASS {
    public:
	Dictionary( dict_order ordering = UNORDERED,
		int initial_size = DEFAULT_DICT_SIZE );
	virtual ~Dictionary();

	// Returns the previous entry, or nil if none.
	void* Insert( const char* key, void* value );

	void* Lookup( const char* key ) const;
	void* operator[]( const char* key ) const
		{ return Lookup( key ); }

	// True if the dictionary is ordered, false otherwise.
	int IsOrdered()		{ return order != 0; }

	// If the dictionary is ordered then returns the n'th entry's value;
	// the second method also returns the key.  The first entry inserted
	// corresponds to n=0.
	//
	// Returns nil if the dictionary is not ordered or if "n" is out
	// of range.
	void* NthEntry( int n ) const
		{ return ! order || n < 0 || n >= num_entries ? 0 : (*order)[n]->value; }

	void* NthEntry( int n, const char*& key ) const
		{ DictEntry* entry = 0;
	  	  return ! order || n < 0 || n >= num_entries ? 0 :
		         (key = ((entry=(*order)[n])->key)), entry->value; }

	// Removes the given element.  Returns a (char*) version of the key
	// in case it needs to be deleted.  Returns 0 if no such entry exists.
	virtual char* Remove( const char* key );

	int Length() const
		{ return num_entries; }

	int Sizeof( int verbose=0, const char *id=0 ) const;

	// To iterate through the dictionary, first call InitForIteration()
	// to get an "iteration cookie".  The cookie can then be handed
	// to NextEntry() to get the next entry in the iteration and update
	// the cookie.  Unexpected results will occur if the elements of
	// the dictionary are changed between calls to NextEntry() without
	// first calling InitForIteration().
	IterCookie* InitForIteration() const;
	void* NextEntry( const char*& key, IterCookie*& cookie ) const;

	void Clear();		// remove all entries

    private:
	void Init( int size );

	// Internal version of Insert(); for use by ChangeSize().
	void* Insert( DictEntry* entry );

	int Hash( const char* str, int hash_size ) const;
	int NextPrime( int n ) const;
	int IsPrime( int n ) const;
	void ChangeSize( int new_size );

	PList(DictEntry)** tbl;
	PList(DictEntry)* order;
	int num_buckets;
	int num_entries;

	IterCookie *stale_cookie;
	};

#define NotFound ((void*) 0)


#define Dict(type) glish_name2(type,Dict)
#define PDict(type) glish_name2(type,PDict)

#define Dictdeclare(type)						\
class Dict(type) : public Dictionary {					\
    public:								\
	Dict(type)( dict_order ordering = UNORDERED,			\
			int initial_size = DEFAULT_DICT_SIZE ) :	\
		Dictionary( ordering, initial_size ) {}			\
	void* Insert( const char* key, type value )			\
		{ return Dictionary::Insert( key, PASTE(type,_to_void)(value) ); } \
	type Lookup( const char* key ) const				\
		{ return PASTE(void_to_,type)(Dictionary::Lookup( key )); } \
	type operator[]( const char* key ) const			\
		{ return Lookup( key ); }				\
	type NthEntry( int n ) const					\
		{ return PASTE(void_to_,type)(Dictionary::NthEntry( n )); } \
	type NthEntry( int n, const char*& key ) const			\
		{ return PASTE(void_to_,type)(Dictionary::NthEntry( n, key )); } \
	type NextEntry( const char*& key, IterCookie*& cookie )		\
		{ return PASTE(void_to_,type)(Dictionary::NextEntry( key, cookie )); } \
	}

#define PDictdeclare(type)						\
class PDict(type) : public Dictionary {					\
    public:								\
	PDict(type)( dict_order ordering = UNORDERED,			\
			int initial_size = DEFAULT_DICT_SIZE ) :	\
		Dictionary( ordering, initial_size ) {}			\
	void* Insert( const char* key, type* value )			\
		{ return Dictionary::Insert( key, (void*) value ); }	\
	type* Lookup( const char* key ) const				\
		{ return (type*) Dictionary::Lookup( key ); }		\
	type* operator[]( const char* key ) const			\
		{ return Lookup( key ); }				\
	type* NthEntry( int n ) const					\
		{ return (type*) Dictionary::NthEntry( n ); }		\
	type* NthEntry( int n, const char*& key ) const			\
		{ return (type*) Dictionary::NthEntry( n, key ); }	\
	type* NextEntry( const char*& key, IterCookie*& cookie )	\
		{ return (type*) Dictionary::NextEntry( key, cookie ); }\
	}

#endif
