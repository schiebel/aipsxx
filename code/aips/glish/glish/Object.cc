// $Id: Object.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998 Associated Universities Inc.

#include "config.h"
#include "Glish/glish.h"
RCSID("@(#) $Id: Object.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $")
#include "Glish/Object.h"
#include "Glish/Value.h"
#include "Glish/Reporter.h"

name_list *glish_files = 0;
name_list *glish_desc = 0;

unsigned short file_name = 0;
unsigned short line_num = 0;

Str glish_errno( (const char*) "" );

const char* GlishObject::Description() const
	{
	return 0;
	}

int GlishObject::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	const char *d = Description();
	s << (d ? d : "<*unknown*>");
	return 1;
	}

Value *GlishObject::Fail( int auto_fail, const RMessage& m0,
		       const RMessage& m1, const RMessage& m2,
		       const RMessage& m3, const RMessage& m4,
		       const RMessage& m5, const RMessage& m6,
		       const RMessage& m7, const RMessage& m8,
		       const RMessage& m9, const RMessage& m10,
		       const RMessage& m11, const RMessage& m12,
		       const RMessage& m13, const RMessage& m14,
		       const RMessage& m15, const RMessage& m16
		) const
	{
	if ( file && glish_files )
		return ValCtor::error( auto_fail, (*glish_files)[file], line, m0,m1,
				       m2,m3,m4,m5,m6,m7,m8,m9,
				       m10,m11,m12,m13,m14,m15,m16 );
	else
		return ValCtor::error( auto_fail, m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,
				       m10,m11,m12,m13,m14,m15,m16 );
	}

const Str GlishObject::strFail( const RMessage& m0,
		       const RMessage& m1, const RMessage& m2,
		       const RMessage& m3, const RMessage& m4,
		       const RMessage& m5, const RMessage& m6,
		       const RMessage& m7, const RMessage& m8,
		       const RMessage& m9, const RMessage& m10,
		       const RMessage& m11, const RMessage& m12,
		       const RMessage& m13, const RMessage& m14,
		       const RMessage& m15, const RMessage& m16
		) const
	{
	return ValCtor::error_str( m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,
				   m10,m11,m12,m13,m14,m15,m16 );
	}

Value *GlishObject::Fail( const Value *v ) const
	{
	if ( v && v->Type() == TYPE_FAIL && file && glish_files )
		return ValCtor::create( v, (*glish_files)[file], line );
	else
		return Fail( RMessage(v) );
		
	}

Value *GlishObject::Fail( ) const
	{
	if ( file && glish_files )
		return error_value( 0, (*glish_files)[file], line );
	else
		return error_value( );
	}
