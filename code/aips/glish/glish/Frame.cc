// $Id: Frame.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.

#include "config.h"
#include "Glish/glish.h"
RCSID("@(#) $Id: Frame.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $")
#include "IValue.h"
#include "Frame.h"
#include "Glish/Reporter.h"
#include "system.h"
#include "Func.h"

const char *Frame::Description() const
	{
	return "<frame>";
	}

Frame::Frame( int frame_size, IValue* param_info, parameter_list *formal_params, scope_type s )
	{
	roots = 0;
	scope = s;
	size = frame_size;
	missing = param_info ? param_info : empty_ivalue();
	formals = formal_params;
	if ( formals ) Ref( formals );
	parameters = 0;
	values = alloc_ivalueptr( size );

	for ( int i = 0; i < size; ++i )
		values[i] = 0;
	}


Frame::~Frame() { clear(); }

void Frame::clear()
	{
	Unref( missing );
	missing = 0;
	Unref( formals );
	formals = 0;
	Unref( parameters );
	parameters = 0;

	for ( int i = 0; i < size; ++i )
		{
		IValue *val = values[i];
		if ( val )
			{
			val->ClearSoftDel( );
			Unref( val );
			}
		}

	free_memory( values );
	values = 0;
	size = 0;
	}


IValue*& Frame::FrameElement( int offset )
	{
	if ( offset < 0 || offset >= size )
		glish_fatal->Report( "bad offset in Frame::FrameElement" );

	return values[offset];
	}

const IValue *Frame::Parameters( ) const
	{
	if ( parameters ) return parameters;
	if ( ! formals || size < formals->length() ) return 0;

	recordptr rec = create_record_dict( );
	loop_over_list( *formals, i )
		{
		if ( (*formals)[i]->IsEllipsis( ) )
			{
			rec->Insert( string_dup( "..." ), values[i] ? copy_value(values[i]) : new IValue( glish_false ) );
			}
		else
			{
			const char * formal_name = (*formals)[i]->Name( );
			rec->Insert( string_dup( formal_name ), values[i] ? copy_value(values[i]) : new IValue( glish_false ) );
			}
		}

	((Frame*)this)->parameters = new IValue( rec );
	return parameters;
	}
