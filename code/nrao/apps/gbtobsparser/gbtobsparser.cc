#include <casa/stdio.h>
#include "Glish/Client.h"

#include <casa/namespace.h>
extern "C" int GBTObsParseparse( );
extern void clear_parser( );
extern Value *parser_result( );
extern Value *collect_ids( );

Client *client;

int post_end_result = 0;

int main( int argc, char **argv )
	{

	client = new Client( argc, argv );

	clear_parser();
	while ( 1 )
		{
		if ( ! GBTObsParseparse() )
			{
			Value *result = parser_result( );
			if ( result && result->Length() > 0 )
				{
				Value *ids = collect_ids( );
				if ( ids ) result->SetField( "id", ids );
				client->PostEvent("result", result);
				clear_parser();
				}
			}

		else if ( post_end_result )
			{
			recordptr rec = create_record_dict();
			rec->Insert( strdup("type"), new Value( "end" ) );

			Value *result = 0;
			Value *ids = collect_ids( );
			if ( ids )
				{
				rec->Insert( strdup("id"), ids );
				result = new Value( create_record_dict() );
				Value *v = new Value(rec);
				result->SetField( result->NewFieldName(0), v );
				Unref(v);
				}
			else
				result = new Value( rec );

			client->PostEvent("result", result);
			Unref(result);
			clear_parser();
			}
		}

	delete client;
	}
