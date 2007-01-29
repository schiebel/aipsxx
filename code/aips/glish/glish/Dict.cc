// $Id: Dict.cc,v 19.12 2004/11/03 20:38:57 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.

#include "config.h"
#include "Glish/glish.h"
RCSID("@(#) $Id: Dict.cc,v 19.12 2004/11/03 20:38:57 cvsmgr Exp $")
#include <string.h>
#include <stdio.h>
#include "Glish/Dict.h"


// If the mean bucket length exceeds the following then Insert() will
// increase the size of the hash table.
#define TOO_CROWDED 4

// This determines how many slots buckets have initially
#define INITIAL_BUCKET_CHUNK  2

// The value of an iteration cookie is the bucket and offset within the
// bucket at which to start looking for the next value to return.
class IterCookie GC_FINAL_CLASS {
public:
	IterCookie( int b, int o ) : bucket(b), offset(o) { }
	void Set( int b, int o )
		{
		bucket = b;
		offset = o;
		}
	int bucket, offset;
	};


Dictionary::Dictionary( dict_order ordering, int initial_size )
	{
	Init( initial_size );

	if ( ordering == ORDERED )
		order = new PList(DictEntry)(INITIAL_BUCKET_CHUNK);
	else
		order = 0;

	stale_cookie = 0;
	}

Dictionary::~Dictionary()
	{
	Clear();
	free_memory(tbl);
	if ( order ) delete order;
	}


void* Dictionary::Insert( const char* key, void* value )
	{
	DictEntry* new_entry = new DictEntry( key, value );
	void* old_val = Insert( new_entry );

	if ( old_val )
		{
		// We didn't need the new DictEntry, the key was already
		// present.
		delete new_entry;
		}

	else if ( order )
		order->append( new_entry );

	if ( num_entries / num_buckets >= TOO_CROWDED )
		ChangeSize( num_buckets * 2 );

	return old_val;
	}


void* Dictionary::Lookup( const char* key ) const
	{
	int h = Hash( key, num_buckets );
	PList(DictEntry)* chain = tbl[h];

	if ( chain )
		{
		for ( int i = 0; i < chain->length(); ++i )
			{
			DictEntry* entry = (*chain)[i];

			if ( ! strcmp( key, entry->key ) )
				return entry->value;
			}
		}

	return NotFound;
	}

int Dictionary::Sizeof( int verbose, const char *id ) const
	{
	int size = 0;
	
	for ( int i = 0; i < num_buckets; ++i )
		{
		PList(DictEntry) *chain = tbl[i];
		if ( chain ) size += sizeof(BaseList) +
			       chain->curlen() * sizeof(void*) +
			       chain->length() * sizeof(DictEntry);
		}

	int total = sizeof(Dictionary) + (order ? sizeof(BaseList) + order->curlen() * sizeof(void*) : 0)
				  + num_buckets * sizeof(void*) + size;
	if ( verbose )
		{
		fprintf( stdout, "%d {%s size(%d)/buckets(%d", total, id?id:"Dict", Length(), num_buckets );
		for ( int i = 0; i < num_buckets; ++i )
			{
			PList(DictEntry) *chain = tbl[i];
			if ( chain ) fprintf( stdout, " %d:%d", chain->curlen(), chain->length() );
			}
		fprintf( stdout, ")" );
		if ( order ) fprintf( stdout, "/order(%d)", order->curlen() );
		fprintf( stdout, "}" );
		}

	return total;
	}


char* Dictionary::Remove( const char* key )
	{
	int h = Hash( key, num_buckets );
	PList(DictEntry)* chain = tbl[h];

	if ( chain )
		{
		for ( int i = 0; i < chain->length(); ++i )
			{
			DictEntry* entry = (*chain)[i];

			if ( ! strcmp( key, entry->key ) )
				{
				char* entry_key = (char*) entry->key;

				chain->remove( entry );

				if ( order )
					order->remove( entry );

				delete entry;
				--num_entries;
				return entry_key;
				}
			}
		}

	return 0;
	}


IterCookie* Dictionary::InitForIteration() const
	{
	IterCookie *ret = 0;
	if ( stale_cookie )
		{
		ret = stale_cookie;
		ret->Set(0,0);
		((Dictionary*)this)->stale_cookie = 0;
		}
	else
		ret = new IterCookie( 0, 0 );

	return ret;
	}

void* Dictionary::NextEntry( const char*& key, IterCookie*& cookie ) const
	{
	int b = cookie->bucket;
	int o = cookie->offset;
	DictEntry* entry;

	if ( tbl[b] && tbl[b]->length() > o )
		{
		entry = (*tbl[b])[o];
		++cookie->offset;
		key = entry->key;
		return entry->value;
		}

	++b;
	while ( b < num_buckets && (! tbl[b] || tbl[b]->length() == 0) )
		++b;

	if ( b >= num_buckets )
		{ // All done.
		if ( ! stale_cookie )
			((Dictionary*)this)->stale_cookie = cookie;
		else
			delete cookie;
		return 0;
		}

	entry = (*tbl[b])[0];
	key = entry->key;

	cookie->bucket = b;
	cookie->offset = 1;

	return entry->value;
	}


void Dictionary::Init( int size )
	{
	num_buckets = NextPrime( size );
	tbl = (PList(DictEntry)**) alloc_memory( sizeof(PList(DictEntry)*)*num_buckets );

	for ( int i = 0; i < num_buckets; ++i )
		tbl[i] = 0;

	num_entries = 0;
	}

void Dictionary::Clear( )
	{
	for ( int i = 0; i < num_buckets; ++i )
		if ( tbl[i] )
			{
			while ( tbl[i]->length() )
				delete tbl[i]->remove_nth( tbl[i]->length() - 1 );

			delete tbl[i];
			tbl[i] = 0;
			}

	if ( order ) order->clear();

	if ( stale_cookie ) delete stale_cookie;
	stale_cookie = 0;

	num_entries = 0;
	}

void* Dictionary::Insert( DictEntry* new_entry )
	{
	int h = Hash( new_entry->key, num_buckets );
	PList(DictEntry)* chain = tbl[h];

	if ( chain )
		{
		for ( int i = 0; i < chain->length(); ++i )
			{
			DictEntry* entry = (*chain)[i];

			if ( ! strcmp( new_entry->key, entry->key ) )
				{
				void* old_value = entry->value;
				entry->value = new_entry->value;
				return old_value;
				}
			}
		}

	else
		{ // Create new chain.
		chain = tbl[h] = new PList(DictEntry)(INITIAL_BUCKET_CHUNK);
		}

	// We happen to know (:-() that appending is more efficient
	// on lists than prepending.
	chain->append( new_entry );

	++num_entries;

	return 0;
	}

int Dictionary::Hash( const char* str_, int hash_size ) const
	{
	register unsigned int hashval = 1;
	register const unsigned char *str = (const unsigned char*) str_;
	static unsigned short char_hash[] = {
		55927, 27986, 22456, 45590, 1689, 59121, 18631, 63603, 40390,
		56613, 62650, 8113, 2737, 11977, 61089, 58842, 2410, 61547,
		41563, 2425, 20424, 37079, 57177, 43580, 2818, 31807, 3450,
		55588, 25693, 34820, 36374, 45670, 24319, 4387, 60183, 64226,
		32995, 22335, 38465, 56125, 55526, 15942, 6802, 62109, 5118,
		16579, 49603, 39680, 29578, 64704, 53231, 55609, 38595, 25942,
		38731, 4745, 10578, 17107, 50707, 16854, 43260, 19334, 28806,
		1674, 38008, 48937, 30983, 34571, 30050, 3819, 6245, 49362,
		22343, 48154, 26676, 32810, 24032, 14186, 61786, 55688, 19548,
		10980, 24742, 40577, 61398, 14446, 41882, 59500, 32486, 55027,
		53065, 29332, 8275, 38959, 21339, 7706, 60134, 49432, 6958,
		39270, 53338, 48876, 24343, 50503, 1391, 41684, 1990, 4527,
		39197, 28210, 42439, 44036, 3302, 39308, 7973, 63780, 57413,
		57364, 21801, 29944, 8514, 63955, 9280, 45491, 13351, 36466,
		16378, 53416, 9293, 19109, 36143, 28358, 61455, 41524, 48188,
		40625, 25056, 26791, 1387, 10877, 10361, 2702, 2417, 63241,
		42, 53610, 63504, 758, 57170, 15420, 16093, 6979, 14314, 5799,
		8732, 65415, 32827, 39108, 49607, 20425, 21680, 31107, 11438,
		15871, 42182, 32184, 17336, 40226, 32031, 44490, 20295, 34794,
		8374, 64499, 18618, 31019, 17198, 50484, 64011, 20428, 22083,
		14041, 13721, 22623, 64609, 17060, 34817, 5730, 53843, 27545,
		58917, 10002, 57876, 21861, 63822, 14310, 12482, 41068, 52078,
		43695, 63920, 15470, 46462, 8522, 18586, 64469, 37382, 51966,
		50419, 53661, 21947, 60793, 41051, 50144, 20546, 50018, 47661,
		15613, 30483, 27290, 10804, 1380, 15481, 15381, 33917, 53249,
		38069, 34638, 18503, 58179, 60226, 19308, 3095, 2248, 59956,
		10223, 6376, 36263, 5562, 24342, 18048, 48473, 24002, 25553,
		2782, 57668, 59323, 3422, 52944, 28390, 29302, 10883, 47521,
		44699, 54822, 52838 };

#define HASH( action )						\
	if ( *str )						\
		{						\
		hashval = (hashval << 2) + char_hash[*str++];	\
		action						\
		}

	HASH(HASH(HASH(HASH(HASH(HASH(HASH(HASH(HASH(HASH(HASH(HASH(HASH(HASH(HASH(HASH(;))))))))))))))))

	return (int)(hashval % (unsigned int) hash_size);
	}

int Dictionary::NextPrime( int n ) const
	{
	while ( ! IsPrime( n ) )
		++n;
	return n;
	}

int Dictionary::IsPrime( int n ) const
	{
	if ( (n & 0x1) == 0 )
		// Even.
		return 0;

	for ( int j = 3; j * j <= n; ++j )
		if ( n % j == 0 )
			return 0;

	return 1;
	}

void Dictionary::ChangeSize( int new_size )
	{
	// First collect the current contents into a list.
	PList(DictEntry)* current;

	if ( order )
		current = order;
	else
		current = new PList(DictEntry)(INITIAL_BUCKET_CHUNK);

	for ( int i = 0; i < num_buckets; ++i )
		{
		PList(DictEntry)* chain = tbl[i];

		if ( chain )
			{
			if ( ! order )
				{
				for ( int j = 0; j < chain->length(); ++j )
					current->append( (*chain)[j] );
				}

			delete chain;
			}
		}

	free_memory(tbl);
	Init( new_size );

	for ( LOOPDECL i = 0; i < current->length(); ++i )
		Insert( (*current)[i] );

	if ( ! order )
		delete current;
	}
