// $Id: make_client.cc,v 19.1 2004/07/13 22:37:01 dschieb Exp $
// Copyright (c) 1999 Associated Universities Inc.
//
// Glish "make" client - generates events for makefile actions.
//
// This client was built using the BSD make tool from NetBSD.
//

#include <stdio.h>
#include <ctype.h>
#if defined(_AIX)
#include <strings.h>
#endif
#include "Glish/glish.h"
RCSID("@(#) $Id: make_client.cc,v 19.1 2004/07/13 22:37:01 dschieb Exp $")
#include "Glish/Client.h"
#include "make_client.h"

inline int streq( const char* a, const char* b )
        {
        return ! strcmp( a, b );
        }

static Client *client = 0;

static char    *completion_event = 0;
static int skip_completion_event = 0;

static void action_handler( char *cmd, int ack ) {

    if ( ! cmd ) return;
    while ( isspace(*cmd) ) ++cmd;
    if ( ! *cmd ) return;

    if ( client ) {
        char event[1024];
	char *ep = event;
	for ( ; *cmd && ! isspace(*cmd); *ep++ = *cmd++ );
	if ( ep == event ) return;
	*ep = '\0';
	while ( isspace(*cmd) ) ++cmd;
	Value *val = *cmd ? new Value( cmd ) : new Value( glish_true );
	client->PostEvent( event, val );
	Unref( val );
	if ( ack ) {
	    GlishEvent *e = client->NextEvent();
	    if ( strcmp( e->name, "ack" ) )
	        fprintf( stderr, "error \"%s\" taken as acknowledgement\n" );
	}
    } else {
        printf( "%s\n", cmd );
    }
}

static void uptodate_handler( char *tgt ) {
    if ( client ) {
	if ( client->ReplyPending() ) {
	    Value r(glish_true);
	    client->Reply(&r);
	}
    } else
        printf ("`%s' is up to date.\n", tgt);
}


int main( int argc, char** argv ) {
    Client c( argc, argv );
    bMake_Init( argc, argv );
    client = &c;
    bMake_SetActionHandler( action_handler );
    bMake_SetUpToDateHandler( uptodate_handler );

    for ( GlishEvent* e; (e = c.NextEvent()); ) {
        Value *val = e->value;
        if ( streq( e->name, "variable" ) ) {
	    if ( val->Type() == TYPE_STRING && val->Length() > 0 ) {
	        const char *def[] = { "1" };
	        char *name = val->StringVal();
	        bMake_Define( val->StringPtr(0), val->Length(), def, 1 );
	    } else if ( val->Type() == TYPE_RECORD && val->Length() >= 2 ) {
	        Value *name = val->NthField(1);
		Value *value = val->NthField(2);
		if ( name->Type() == TYPE_STRING && name->Length() > 0 &&
		     value->Type() == TYPE_STRING && value->Length() > 0 &&
		     (name->Length() == value->Length() || value->Length() == 1) ) {
		    bMake_Define( name->StringPtr(0), name->Length(),
				  value->StringPtr(0), value->Length() );
		} else {
		    c.Error( "bad value for 'variable'" );
		    continue;
		}
	    } else { 
                c.Error( "bad value for 'variable'" );
		continue;
	    }
	} else if ( streq( e->name, "target" ) ) {
	    Value *tgt = 0;
	    Value *action = 0;
	    if ( val->Type() == TYPE_RECORD && val->Length() >= 2 &&
		 (tgt=val->NthField(1)) && tgt->Type() == TYPE_STRING && tgt->Length() > 0 &&
		 (action=val->NthField(2)) && action->Type() == TYPE_STRING && action->Length() > 0 ) {
	        Value *dep;
	        if ( val->Length() == 2 ) {
		    bMake_TargetDef( tgt->StringPtr(0), tgt->Length(),
				     action->StringPtr(0), action->Length(), 0, 0 );
		} else if ( (dep=val->NthField(3)) && dep->Type() == TYPE_STRING && dep->Length() > 0 ) {
		    bMake_TargetDef( tgt->StringPtr(0), tgt->Length(),
				     action->StringPtr(0), action->Length(),
				     dep->StringPtr(0), dep->Length() );
		} else {
		    c.Error( "bad value for 'target'" );
		    continue;
		}
	    } else {
		c.Error( "bad value for 'target'" );
	        continue;
	    }
	} else if ( streq(e->name, "suffix" ) ) {
	    Value *suf = 0;
	    Value *action = 0;
	    if ( val->Type() == TYPE_RECORD && val->Length() >= 2 &&
		 (suf=val->NthField(1)) && suf->Type() == TYPE_STRING && suf->Length() > 0 &&
		 (action=val->NthField(2)) && action->Type() == TYPE_STRING && action->Length() > 0 ) {
	        bMake_SuffixDef( suf->StringPtr(0), suf->Length(),
				 action->StringPtr(0), action->Length() );
	    } else {
		c.Error( "bad value for 'suffix'" );
	        continue;
	    }
	} else if ( streq(e->name, "make" ) ) {
            Value *tgt = 0;
	    skip_completion_event = 0;

	    if ( val->Type() == TYPE_STRING && val->Length() > 0 )
 	        bMake_SetMain( val->StringPtr(0), val->Length() );
	    if ( ! bMake_HasMain( ) )
		c.Error( "no root target specified" );
	    else {
	        bMake( );
		if ( c.ReplyPending() ) {
		    Value r(glish_false);
		    c.Reply(&r);
		}
		if ( completion_event && *completion_event && ! skip_completion_event ) {
		    Value result( glish_true );
		    c.PostEvent( completion_event, &result );
		}
	    }

	} else if ( streq(e->name, "dump" ) ) {
	    Targ_PrintGraph (2);

	} else if ( streq(e->name, "bind" ) ) {
	    if ( val->Type() == TYPE_RECORD && val->Length() == 2 ) {
		Value *event = val->NthField(1);
		Value *binding = val->NthField(2);
		if ( event->Type() == TYPE_STRING && event->Length() > 0 &&
		     binding->Type() == TYPE_STRING && binding->Length() > 0 ) {
		    if ( ! strcasecmp( event->StringPtr(0)[0], "<completion>" ) ) {
			if ( completion_event ) free_memory( completion_event );
			completion_event = strdup(binding->StringPtr(0)[0]);
		    } else {
		        c.Error( "unknown binding event type" );
		    }
		} else
		    c.Error( "bind takes one or two string arguments" );
	    } else if ( val->Type() == TYPE_STRING && val->Length() == 1 ) {
		if ( ! strcasecmp( val->StringPtr(0)[0], "<completion>" ) ) {
		    if ( completion_event ) free_memory( completion_event );
		    completion_event = 0;
		} else {
		    c.Error( "unknown binding event type" );
		}
	    } else {
		c.Error( "bind takes one or two arguments" );
	    }
	} else {
	    c.Error( "unknown event ('%s') or bad value", e->name );
	    continue;
	}

	if ( c.ReplyPending() ) {
	    Value r(glish_true);
	    c.Reply(&r);
	}
    }

    bMake_Finish( );
    return 0;
}

extern "C" void handle_fatal_error( const char * );

void handle_fatal_error( const char *buff ) {

    skip_completion_event = 1;
    if ( client ) client->Error( buff );

}
