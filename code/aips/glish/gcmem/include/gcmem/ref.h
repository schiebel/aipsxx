//======================================================================
// gcmem/ref.h
//
// $Id: ref.h,v 19.0 2003/07/16 05:17:15 aips2adm Exp $
//
// Copyright (c) 1997,1998 Associated Universities Inc.
//
//======================================================================
#ifndef gcmem_ref_h_
#define gcmem_ref_h_

#if defined(ENABLE_GC)
#include <gcmem/gc_cpp.h>
#endif

class GcRef GC_FINAL_CLASS {
    public:
	GcRef() : ref_count(1), flags(0)	{ }
	virtual ~GcRef()			{ }

	// Return the ref count so other classes can do intelligent copying.
	unsigned short RefCount() const		{ return ref_count; }

    protected:
	friend inline void Ref( GcRef* object );
	friend inline void Unref( GcRef* object );

	unsigned short ref_count;
	unsigned short flags;
};

inline void Ref( GcRef* object )
	{
	++object->ref_count;
	}

inline void Unref( GcRef* object )
	{
	if ( object && --object->ref_count == 0 )
#ifdef MEMFREE
		if ( ! object->doFinal( ) || object->Finalize( ) )
#endif
			delete object;
	}


#endif
