// $Id: IValCtorKern.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 2004 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: IValCtorKern.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $")
#include "input.h"
#include "IValue.h"
#include "IValCtorKern.h"
#include "Glish/Reporter.h"
#include "Sequencer.h"
#include "ValCtorKernDefs.h"

#if USE_EDITLINE
extern "C" {
	void nb_readline_cleanup();
	void finalize_readline_history( );
}
#endif

extern int allwarn;

class StringReporter : public Reporter {
    public:
	StringReporter( OStream* reporter_stream ) :
		Reporter( reporter_stream ) { loggable = 0; }
	void Epilog();
	void Prolog();
	};

void StringReporter::Epilog() { }
void StringReporter::Prolog() { }

static StringReporter *srpt = 0;
static unsigned int error_count = 0;

inline void init_string_reporter( )
	{ if ( ! srpt ) srpt = new StringReporter( new SOStream ); }
inline void finalize_string_reporter( )
	{ if ( ! srpt ) srpt = new StringReporter( new SOStream ); }
inline StringReporter *string_reporter( ) { return srpt; }

DEFINE_CREATE_VALUE(IValCtorKern,IValue);

Value *IValCtorKern::copy( const Value *value )
	{
	if ( value->IsRef() )
		return copy_value( (const IValue*) value->RefPtr() );

	IValue *copy = 0;
	switch( value->Type() )
		{
		case TYPE_BOOL:
		case TYPE_BYTE:
		case TYPE_SHORT:
		case TYPE_INT:
		case TYPE_FLOAT:
		case TYPE_DOUBLE:
		case TYPE_COMPLEX:
		case TYPE_DCOMPLEX:
		case TYPE_STRING:
		case TYPE_AGENT:
		case TYPE_FUNC:
		case TYPE_REGEX:
		case TYPE_FILE:
		case TYPE_FAIL:
			copy = new IValue( *value );
			break;
		case TYPE_RECORD:
			if ( value->IsAgentRecord() )
				{
				copy = new IValue( (Value*) value, VAL_REF );
				copy->CopyAttributes( value );
				}
			else
				copy = new IValue( *value );
			break;

		case TYPE_SUBVEC_REF:
			switch ( value->VecRefPtr()->Type() )
				{

#define COPY_REF(tag,accessor)						\
	case tag:							\
		copy = new IValue( value->accessor ); 			\
		copy->CopyAttributes( value );				\
		break;

				COPY_REF(TYPE_BOOL,BoolRef())
				COPY_REF(TYPE_BYTE,ByteRef())
				COPY_REF(TYPE_SHORT,ShortRef())
				COPY_REF(TYPE_INT,IntRef())
				COPY_REF(TYPE_FLOAT,FloatRef())
				COPY_REF(TYPE_DOUBLE,DoubleRef())
				COPY_REF(TYPE_COMPLEX,ComplexRef())
				COPY_REF(TYPE_DCOMPLEX,DcomplexRef())
				COPY_REF(TYPE_STRING,StringRef())

				default:
					glish_fatal->Report( "bad type in copy_value(IValue*) [",
						       value->VecRefPtr()->Type(), "]" );
				}
			break;

		default:
			glish_fatal->Report( "bad type in copy_value(IValue*) [", value->Type(), "]" );
		}

	return copy;
	}

Value *IValCtorKern::deep_copy( const Value *value ) { return copy_value( value ); }


Value *IValCtorKern::error( int auto_fail, const RMessage& m0,
			      const RMessage& m1, const RMessage& m2,
			      const RMessage& m3, const RMessage& m4,
			      const RMessage& m5, const RMessage& m6,
			      const RMessage& m7, const RMessage& m8,
			      const RMessage& m9, const RMessage& m10,
			      const RMessage& m11, const RMessage& m12,
			      const RMessage& m13, const RMessage& m14,
			      const RMessage& m15, const RMessage& m16 )
	{
	init_string_reporter( );
	srpt->Stream().reset();
	srpt->report( ioOpt(ioOpt::NO_NEWLINE(), 3 ), m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16);
	IValue *ret = error_ivalue( ((SOStream&)srpt->Stream()).str(), auto_fail );
	if ( allwarn )
		{
		glish_error->Stream() << "E[" << ++error_count << "]: ";
		ret->Describe( glish_error->Stream() );
		glish_error->Stream() << endl;
		}
	return ret;
	}

Value *IValCtorKern::error( int auto_fail, const char *file, int line,
			      const RMessage& m0,
			      const RMessage& m1, const RMessage& m2,
			      const RMessage& m3, const RMessage& m4,
			      const RMessage& m5, const RMessage& m6,
			      const RMessage& m7, const RMessage& m8,
			      const RMessage& m9, const RMessage& m10,
			      const RMessage& m11, const RMessage& m12,
			      const RMessage& m13, const RMessage& m14,
			      const RMessage& m15, const RMessage& m16
			    )
	{
	init_string_reporter( );
	string_reporter( )->Stream().reset();
	string_reporter( )->report( ioOpt( ioOpt::NO_NEWLINE(), 3 ), m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16);
	IValue *ret = error_ivalue( ((SOStream&)string_reporter( )->Stream()).str(), file, line, auto_fail );
	if ( allwarn )
		{
		glish_error->Stream() << "E[" << ++error_count << "]: ";
		ret->Describe( glish_error->Stream() );
		glish_error->Stream() << endl;
		}
	return ret;
	}

const Str IValCtorKern::error_str( const RMessage& m0,
				     const RMessage& m1, const RMessage& m2,
				     const RMessage& m3, const RMessage& m4,
				     const RMessage& m5, const RMessage& m6,
				     const RMessage& m7, const RMessage& m8,
				     const RMessage& m9, const RMessage& m10,
				     const RMessage& m11, const RMessage& m12,
				     const RMessage& m13, const RMessage& m14,
				     const RMessage& m15, const RMessage& m16 )
	{
	init_string_reporter( );
	string_reporter( )->Stream().reset();
	string_reporter( )->report( ioOpt(ioOpt::NO_NEWLINE(), 3 ), m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16);
	if ( allwarn )
		glish_error->Stream() << "E[" << ++error_count << "]: " <<
		  ((SOStream&)string_reporter( )->Stream()).str() << endl;
	return Str( (const char *) ((SOStream&)string_reporter( )->Stream()).str() );
	}


void IValCtorKern::report( const RMessage& m0,
			     const RMessage& m1, const RMessage& m2,
			     const RMessage& m3, const RMessage& m4,
			     const RMessage& m5, const RMessage& m6,
			     const RMessage& m7, const RMessage& m8,
			     const RMessage& m9, const RMessage& m10,
			     const RMessage& m11, const RMessage& m12,
			     const RMessage& m13, const RMessage& m14,
			     const RMessage& m15, const RMessage& m16 )
	{
	init_string_reporter( );
	string_reporter( )->Stream().reset();
	string_reporter( )->report( ioOpt(ioOpt::NO_NEWLINE(), 3 ), m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16);
	IValue *ret = error_ivalue( ((SOStream&)string_reporter( )->Stream()).str() );
	if ( allwarn )
		{
		glish_error->Stream() << "E[" << ++error_count << "]: ";
		ret->Describe( glish_error->Stream() );
		glish_error->Stream() << endl;
		}
	Sequencer::SetErrorResult( ret );
	}

void IValCtorKern::report( const char *file, int line,
			    const RMessage& m0,
			    const RMessage& m1, const RMessage& m2,
			    const RMessage& m3, const RMessage& m4,
			    const RMessage& m5, const RMessage& m6,
			    const RMessage& m7, const RMessage& m8,
			    const RMessage& m9, const RMessage& m10,
			    const RMessage& m11, const RMessage& m12,
			    const RMessage& m13, const RMessage& m14,
			    const RMessage& m15, const RMessage& m16 )
	{
	init_string_reporter( );
	string_reporter( )->Stream().reset();
	string_reporter( )->report( ioOpt(ioOpt::NO_NEWLINE(), 3 ), m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16);
	IValue *ret = error_ivalue( ((SOStream&)string_reporter( )->Stream()).str(), file, line );
	if ( allwarn )
		{
		glish_error->Stream() << "E[" << ++error_count << "]: ";
		ret->Describe( glish_error->Stream() );
		glish_error->Stream() << endl;
		}
	Sequencer::SetErrorResult( ret );
	}

int IValCtorKern::print_precision( )
	{
	return Sequencer::CurSeq()->System().PrintPrecision();
	}

int IValCtorKern::print_limit( )
	{
	return Sequencer::CurSeq()->System().PrintLimit();
	}

int IValCtorKern::silent( )
	{
	return 0;
	}
int IValCtorKern::collecting_garbage( )
	{
	return 0;
	}
void IValCtorKern::log( const char *s )
	{
	if ( Sequencer::CurSeq()->System().OLog() )
		Sequencer::CurSeq()->System().DoOLog( s );
	}

int IValCtorKern::do_log( )
	{
	return Sequencer::CurSeq()->System().OLog();
	}

void IValCtorKern::show_stack( OStream &st )
	{
	Sequencer::CurSeq()->DescribeFrames( st );
	st << endl;
	}

int IValCtorKern::write_agent( sos_out &sos, Value *val_, sos_header &head, const ProxyId &proxy_id )
	{
	if ( val_->Type() != TYPE_AGENT )
		return 0;

	IValue *val = (IValue*) val_;
	Agent *agent = val->AgentVal();
	if ( ! agent || ! agent->IsProxy() )
		{
// 		glish_warn->Report( "non-proxy agent" );
		return 0;
		}

	ProxyTask *pxy = (ProxyTask*) agent;
	if ( pxy->Id().interp() != proxy_id.interp() ||
	     pxy->Id().task() != proxy_id.task() )
		{
		glish_warn->Report( "attempt to pass proxy agent to client which did not create it" );
		return 0;
		}

	sos.put( (int*) pxy->Id().array(), ProxyId::len(), head, sos_sink::COPY );
	return 1;
	}

void IValCtorKern::cleanup( )
	{
#if USE_EDITLINE
	nb_readline_cleanup();
	finalize_readline_history( );
#endif
	set_term_unchar_mode();
	Sequencer::CurSeq()->AbortOccurred();
	}

