//======================================================================
// sos/ref.h
//
// $Id: ref.h,v 19.0 2003/07/16 05:17:37 aips2adm Exp $
//
// Copyright (c) 1997,1998,2000 Associated Universities Inc.
//
//======================================================================
#ifndef sos_ref_h_
#define sos_ref_h_

#include "sos/generic.h"
#include "sos/alloc.h"

class GcRef;
class sos_name2(GcRef,PList);
typedef sos_name2(GcRef,PList) ref_list;

typedef unsigned short refmode_t;

extern void sos_do_unref( GcRef * );

class GcRef GC_FINAL_CLASS {
    public:
	GcRef() : mask(0), ref_count(1) { }
	GcRef( const GcRef & ) : mask(0), ref_count(1)	{ }

	virtual ~GcRef();

	// Return the ref count so other classes can do intelligent copying.
	unsigned short RefCount() const		 { return ref_count; }

	// Used to give the object a chance to Unref() data which
	// needs to be deleted *before* the deletion of the object.
	virtual void PreDelete( );

	// Used to delete objects which are owned by some other
	// object, and can't be deleted outright but need to be
	// cleaned out, e.g. IValues which are members of a call
	// frame.
	virtual int SoftDelete( );

	// Hook through which deletion notification is sent to the
	// observer in an observer/observed paradigm
	virtual void ObservedGone( GcRef * );
	virtual int IsThisAnObservedList( );

	// Hook through which deletion notification is sent to the
	// observed in an observer/observed paradigm
	virtual void ObserverGone( GcRef * );
	virtual void ObserverChanged( GcRef *Old, GcRef *New );

	void MarkSoftDel( ) { mask |= mSOFTDELETE(); }
	void ClearSoftDel( ) { mask &= ~ mSOFTDELETE(); }

	void MarkGlobalValue( ) { mask |= mGLOBALVALUE(); }
	void ClearGlobalValue( ) { mask &= ~ mGLOBALVALUE(); }
	int IsGlobalValue( ) const { return mask & mGLOBALVALUE(); }

    protected:
	inline refmode_t mUNREF( refmode_t mask=~((refmode_t) 0) ) const { return mask & 1<<0; }
	inline refmode_t mUNREF_REVERT( refmode_t mask=~((refmode_t) 0) ) const { return mask & 1<<1; }
	inline refmode_t mPROPAGATE( refmode_t mask=~((refmode_t) 0) ) const { return mask & 1<<2; }
	inline refmode_t mSOFTDELETE( refmode_t mask=~((refmode_t) 0) ) const { return mask & 1<<3; }
	inline refmode_t mGLOBALVALUE( refmode_t mask=~((refmode_t) 0) ) const { return mask & 1<<4; }

	inline refmode_t get_revert_count( ) const { return mask>>5; }
	inline void set_revert_count( unsigned short value ) { mask = mask & 0x1F | value<<5; }

	friend inline void Ref( GcRef* object );
	friend inline void Unref( GcRef* object );
	friend void sos_do_unref( GcRef * );

	void unref_revert( );

	int doUnref( ) const { return mUNREF(mask) | mUNREF_REVERT(mask); }
	int doRevert( ) const { return mUNREF_REVERT(mask); }
	int doPropagate( ) const { return mPROPAGATE(mask); }
	int doSoftDelete( ) const { return mSOFTDELETE(mask); }

	refmode_t mask;
	unsigned int ref_count;
};

inline void Ref( GcRef* object )
	{
	++object->ref_count;
	if ( object->doPropagate() && ! object->doUnref() )
		object->unref_revert( );
	}

inline void Unref( GcRef* object )
	{
	if ( object && --object->ref_count == 0 )
		sos_do_unref( object );
	}

#include <sos/list.h>

sos_declare(PList,GcRef);

#endif
