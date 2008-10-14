// $Id: Garbage.h,v 19.12 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1997 Associated Universities Inc.
#ifndef garbage_h_
#define garbage_h_
#ifdef GGC
#include "Glish/Value.h"

class Garbage;
glish_declare(PList,Garbage);
typedef PList(Garbage) garbage_list;

extern int glish_collecting_garbage;

class Garbage {
public:
	Garbage( Value *v ) : value(v), mark(0)
		{ values->append( this ); }
	~Garbage( ) { values->remove( this ); }

	static void init();
	static void finalize();

	static void collect( int report = 0 );
	void tag( ) { mark = 1; }
	void clear( ) { mark = 0; }
	int isTaged( ) { return (int) mark; }

protected:
	static garbage_list *values;
	Value *value;
	char mark;
private:
	void *operator new( size_t ) { return 0; }
	Garbage( const Garbage & ) { }
};
#endif
#endif
