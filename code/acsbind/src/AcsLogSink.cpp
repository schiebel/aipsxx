#include <AcsLogSink.h>
#include <iostream.h>
#include <casa/aips.h>
#include <logging.h>
#include <stdlib.h>
#include <casa/Logging/LogFilter.h>
using namespace casa;

String AcsLogSink::localId( ) {
    return String("AcsLogSink");
}

String AcsLogSink::id( ) const {
    return String("AcsLogSink");
}

AcsLogSink::AcsLogSink( ) { }

AcsLogSink::AcsLogSink(const LogFilter &filter) : LogSinkInterface(filter) { }

AcsLogSink::AcsLogSink(const AcsLogSink &other) : LogSinkInterface(other) { }

AcsLogSink &AcsLogSink::operator=(const AcsLogSink &other)
{
    if (this != &other) {
        LogSinkInterface &This = *this;
	This = other;
    }
    return *this;
}

AcsLogSink::~AcsLogSink() { }

static ACE_Log_Priority translate_priority( LogMessage::Priority priority ) {
  switch ( priority ) {
  case LogMessage::NORMAL: return LM_INFO;
  case LogMessage::WARN: return LM_WARNING;
  case LogMessage::SEVERE: return LM_ERROR;
  default: return LM_DEBUG;
  }
  return LM_DEBUG;
}

static char *xml_clean_string( const char *str ) {
    unsigned long subst = 0;
    unsigned char proceed = 0;

    //
    // Clip leading white space at the start
    //
    while ( isspace(*str) ) ++str;

    //
    // Do we need to munge?
    //
    unsigned char space_count = 0;
    for ( const char *ptr = str; *ptr; ++ptr ) {

	//
	// Track of how many character expansions are required
	//
	if ( *ptr == '<' || *ptr == '>' || *ptr == '&' ||
	     *ptr == '\'' || *ptr == '"' )
	    ++subst;

	//
	// Track of how many subsitutions (or subtractions) are required
	//
	if ( *ptr == '\n' || *ptr == '\r' || *ptr == '\f' ||
	     *ptr == '\b' || *ptr == '\033' || *ptr == '\t' )
	    proceed = 1;

	if ( *ptr == ' ' )
	    ++space_count;
	else
	    space_count = 0;

	if ( space_count > 1 )
	    proceed = 1;
    }

    //
    // If no munging, return a copy
    //
    if ( ! subst && ! proceed )
	return strdup( str );

    //
    // Munging necessary, so allocate a buffer
    //
    char *ret = (char*) malloc(sizeof(char) * (strlen(str) + subst * 6 + 1));
    *ret = '\0';

    //
    // And then munge...
    //
    char *rptr = ret;
    space_count = 0;
    for ( const char *ptr = str; *ptr; ++ptr ) {
	switch ( *ptr ) {
	case '<':
	  *rptr++ = '&';
	  *rptr++ = 'l';
	  *rptr++ = 't';
	  *rptr++ = ';';
	  space_count = 0;
	  break;
	case '>':
	  *rptr++ = '&';
	  *rptr++ = 'g';
	  *rptr++ = 't';
	  *rptr++ = ';';
	  space_count = 0;
	  break;
	case '&':
	  *rptr++ = '&';
	  *rptr++ = 'a';
	  *rptr++ = 'm';
	  *rptr++ = 'p';
	  *rptr++ = ';';
	  space_count = 0;
	  break;
	case '\'':
	  *rptr++ = '&';
	  *rptr++ = 'a';
	  *rptr++ = 'p';
	  *rptr++ = 'o';
	  *rptr++ = 's';
	  *rptr++ = ';';
	  space_count = 0;
	  break;
	case '"':
	  *rptr++ = '&';
	  *rptr++ = 'q';
	  *rptr++ = 'u';
	  *rptr++ = 'o';
	  *rptr++ = 't';
	  *rptr++ = ';';
	  space_count = 0;
	  break;
	case '\n':
	  if ( ! space_count ) *rptr++ = ' ';
	  ++space_count;
	  break;
	case '\r':
	case '\f':
	case '\b':
	case '\033':			// escape
	  break;
	case '\t':
	  if ( ! space_count ) *rptr++ = ' ';
	  ++space_count;
	  break;
	case ' ':
	  if ( ! space_count ) *rptr++ = ' ';
	  ++space_count;
	  break;
	default:
	  space_count = 0;
	  *rptr++ = *ptr;
	}
    }
    *rptr = '\0';

    return ret;
}

Bool AcsLogSink::postLocally(const LogMessage &msg) 
{
    Bool doPost = filter().pass(msg);
    if (doPost) {
	LogOrigin origin = msg.origin( );
	LoggingProxy::Flags(LM_SOURCE_INFO | LM_RUNTIME_CONTEXT);
	char routine_buf[1024];

	if ( origin.isUnset( ) )
	    sprintf( routine_buf, "CASA Message (which has no specified routine)" );
	else {
	    routine_buf[0] = '\0';
	    if ( origin.fileName() != "" )
		sprintf( routine_buf, "[%s,%u]: ", origin.fileName().chars(), origin.line() );
	    if ( origin.functionName() != "" )
		strcat( routine_buf, origin.functionName().chars() );
	    else if ( origin.className() != "" )
		strcat( routine_buf, origin.className().chars() );
	}

	char *routine = xml_clean_string( routine_buf );
	char *message = xml_clean_string( msg.message().chars() );
	LoggingProxy::Routine(routine);
	ACE_ERROR((translate_priority(msg.priority()), "%s", message));
	free( message );
	free( routine );
    }

    return doPost;
}

void AcsLogSink::flush()
{
    cerr.flush();
}
