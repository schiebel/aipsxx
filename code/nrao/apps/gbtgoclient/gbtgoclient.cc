//# gbtgoclient.cc : this is the shared communications hub for GO and IARDS
//# Copyright (C) 2002,2003
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: gbtgoclient.cc,v 19.2 2004/11/30 17:50:40 ddebonis Exp $

//# Includes
#include <stdio.h>
#include <casa/stdlib.h>
#include <casa/iostream.h>
#include <casa/string.h>
#include <casa/math.h>
#include <ctype.h>
#include "Glish/Client.h"

#include <casa/namespace.h>
int main( int argc, char** argv) {
    Client GOaips2( argc, argv, Client::WORLD);

    for ( GlishEvent* e; ( e = GOaips2.NextEvent() ); ) {
	fprintf(stderr,"\t\t=> %s\n",e->Name());
	if ( strcmp( "PING", e->Name() ) ) {
	    source_list &sources = GOaips2.EventSources();
	    loop_over_list( sources, i ) {
	        fprintf(stderr,"\t\t\t id=%s  name=%s\n",sources[i]->Context().id(),
			sources[i]->Context().name());
		if ( sources[i]->Context() != GOaips2.LastContext() ) {
		    GOaips2.PostEvent( e, sources[i]->Context() );
		    fprintf(stderr,"\t\t\t\t Event Posted\n");
		}
	    }
	} else {
	    if ( GOaips2.ReplyPending( ) ) {
		GOaips2.PostEvent( "*PING-reply*", "alive", EventContext(GOaips2.LastContext()) );
	    } else {
		GOaips2.PostEvent( "PINGreply", "alive", EventContext(GOaips2.LastContext()) );
	    }

	}
    }

    fprintf(stderr,"\ngo_aips2_g exiting\n\n");
    return 0;
}
