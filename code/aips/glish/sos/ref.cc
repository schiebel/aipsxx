#include <sos/ref.h>
#include <stdio.h>

int GcRef::IsThisAnObservedList( )
	{
	return 0;
	}

void GcRef::unref_revert( )
	{
	if ( doPropagate() && ! doUnref() )
		{
		if ( ref_count-1 > 0xFFFF >> 5 )
			{
			// Here we just can't revert to the no-unref status
			// because the reference count we need to save is
			// greater than the bits we have available to store it
			// So we must leak the memory.
			mask |= mUNREF();
			}
		else
			{
			// We store off the current reference count, and when it
			// it reaches zero, we revert to propagate with no unref
			// and the old reference count.
			set_revert_count( ref_count-1 );
			ref_count = 1;
			mask |= mUNREF_REVERT();
			}
		}
	}

int GcRef::SoftDelete( )
	{
	fprintf( stderr, "\nSOFT DELETE REQUIRED\n" );
	return 0;
	}

void GcRef::PreDelete( )
	{
	fprintf( stderr, "\nPRE-DELETE REQUIRED\n" );
	}

void GcRef::ObservedGone( GcRef * )
	{
	fprintf( stderr, "\nOBSERVED GONE REQUIRED\n" );
	}

void GcRef::ObserverGone( GcRef * )
	{
	fprintf( stderr, "\nOBSERVER GONE REQUIRED\n" );
	}

void GcRef::ObserverChanged( GcRef *, GcRef * )
	{
	fprintf( stderr, "\nOBSERVER CHANGED REQUIRED\n" );
	}

GcRef::~GcRef() { }

void sos_do_unref( GcRef *object )
	{
	if ( object->doRevert( ) )
		{
		object->mask &= ~ object->mUNREF_REVERT();
		object->ref_count = object->get_revert_count( );
		}
	else
		{
		if ( object->doUnref() ) object->PreDelete( );

		if ( object->doSoftDelete( ) )
			{
			if ( object->SoftDelete( ) ) delete object;
			}
		else
			delete object;

		}
	}
