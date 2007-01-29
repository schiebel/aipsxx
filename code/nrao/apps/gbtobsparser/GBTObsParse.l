%{
/* $Id: GBTObsParse.l,v 19.0 2003/07/16 03:44:30 aips2adm Exp $
** Copyright (c) 1998,2000 Associated Universities Inc.
*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include "Glish/Client.h"
#include "GBTObsSymtab.h"

SymbolTable symbol_table;

extern void parser_begin_block();

extern Client *client;

static int scanner_read( char buf[], int max_size );
static char *clean_string( const char * ); 
static char *unquote_string( const char * ); 
extern void clear_scanner( );
extern void append_id( int );
extern int_list id_list;
extern int skip_syntax_error;
static int current_id = 0;

extern int post_end_result;

#define RETURN_LABEL(STATE)			\
	{					\
	BEGIN(STATE);				\
	YYLVAL(str) = clean_string(yytext);	\
	return TOK_LABEL;			\
	}

#define RETURN_STRING(tok)			\
	{					\
	YYLVAL(str) = strdup( yytext );		\
	return tok;				\
	}

#define RETURN_UNQUOTE_STRING(tok)		\
	{					\
	YYLVAL(str) = unquote_string( yytext );	\
	return tok;				\
	}

#define RETURN(tok)				\
	{					\
	return tok;				\
	}

#if ! defined(PURE_PARSER)
extern YYSTYPE yylval;
#define YYLVAL(x) yylval.x
#define YY_DECL int GBTObsParselex ( )
#else
#define YYLVAL(x) yylval->x
#define YY_DECL int GBTObsParselex YY_PROTO(( YYSTYPE *yylval ))
#endif

#undef YY_INPUT
#define YY_INPUT(buf,result,max_size)	\
	result = scanner_read( buf, max_size );

#undef YY_BREAK
// The following makes actions by default fall through to the next
// action.  We are careful then that every action ends in a "return"
// or a break.  The reason for bother with this is so that picky
// compilers don't complain about the zillions of actions that
// terminate with a "return" followed by a "break".
#define YY_BREAK
#define GBTObsParsewrap() 1

%}

%x HEADER COMMENT VALUE BLOCK BLOCKHEAD ALIAS ALIASHEAD

ID	[A-Za-z_][A-Za-z0-9_]*
ALNUM	[A-Za-z0-9_+-]+
D	[0-9]
SEXC	[-+]?{D}?{D}?{D}:{D}?{D}:({D}?{D}|({D}?{D})?"."{D}*)
SEXH	[-+]?{D}?{D}?{D}"h"{D}?{D}"m"({D}?{D}|({D}?{D})?"."{D}*)"s"?
STR	\"[^\"\n]*\"
FLOAT	[-+]?(({D}*"."?{D}+)|({D}+"."?{D}*))([eE][-+]?{D}+)?
WS	[ \t]+

%%

<INITIAL,BLOCK>alias			BEGIN(ALIASHEAD); RETURN(TOK_ALIAS);
<INITIAL>block				BEGIN(BLOCKHEAD); parser_begin_block(); RETURN(TOK_BLOCK);
<INITIAL,BLOCK>end			BEGIN(INITIAL);	RETURN(TOK_END);
<INITIAL,BLOCK>header			BEGIN(HEADER); RETURN(TOK_HEADER);
<INITIAL,BLOCK>query			RETURN(TOK_QUERY);
<INITIAL>repeat				BEGIN(BLOCK); parser_begin_block(); RETURN(TOK_REPEAT);

<BLOCKHEAD>{ID}				RETURN_LABEL(BLOCK);
<ALIASHEAD>{ID}				RETURN_LABEL(ALIAS);

<INITIAL,BLOCK,HEADER>{ID}[ \t]*[.][ \t]*{ID}	{
					char *cat = clean_string(strtok( yytext, " \t." ));
					char *nme = clean_string(strtok( NULL, " \t." ));
					if ( symbol_table.find( cat, nme ) )
						{
						YYLVAL(id.cat) = cat;
						YYLVAL(id.nme) = nme;
						return TOK_ID;
						}
					else
						{
						handle_var_error( );
						skip_syntax_error = 1;
						RETURN(TOK_YYERROR);
						}
					}

<ALIAS>{ID}[ \t]*[.][ \t]*{ID}		{
					char *cat = clean_string(strtok( yytext, " \t." ));
					char *nme = clean_string(strtok( NULL, " \t." ));
					YYLVAL(id.cat) = cat;
					YYLVAL(id.nme) = nme;
					return TOK_ID;
					}

<ALIAS>{ID}				{
					YYLVAL(id.cat) = clean_string(yytext);
					YYLVAL(id.nme) = 0;
					return TOK_ID;
					}

<INITIAL,BLOCK,HEADER>{ID}		{
					char *id = clean_string( yytext );
					if ( symbol_table.find( id ) )
						{
						YYLVAL(id.cat) = id;
						YYLVAL(id.nme) = 0;
						return TOK_ID;
						}
					else
						{
						free_memory( id );
						RETURN_STRING(TOK_ALNUM);
						}
					}

<INITIAL,BLOCK,VALUE>{SEXC}|{SEXH}	RETURN_STRING(TOK_SEX);

<INITIAL,BLOCK,VALUE>{STR}		RETURN_UNQUOTE_STRING(TOK_STR);

<INITIAL,BLOCK,VALUE>{FLOAT}		RETURN_STRING(TOK_NUM);

<INITIAL,BLOCK,VALUE>{ALNUM}		RETURN_STRING(TOK_ALNUM);

<INITIAL,BLOCK,VALUE>[:\]\[,]		RETURN(yytext[0]);

<INITIAL,BLOCK,HEADER>[=]		BEGIN(VALUE); RETURN(yytext[0]);

<INITIAL,BLOCKHEAD,BLOCK,VALUE,HEADER,ALIASHEAD,ALIAS>\\\n|{WS}	break;

<INITIAL,BLOCK,VALUE,HEADER,ALIAS>\n	BEGIN(INITIAL); RETURN(TOK_NL);

<INITIAL,BLOCK,VALUE,HEADER>\*		RETURN(TOK_STAR);

<INITIAL,BLOCK,VALUE,HEADER>#		BEGIN(COMMENT); break;

<COMMENT>\n				BEGIN(INITIAL); return(TOK_NL);

<COMMENT>.				break;

<INITIAL,BLOCK,VALUE,HEADER>.		RETURN(TOK_LEXER_ERROR)

%%

static char *input_string = 0;
static char *orig_string = 0;

void clear_scanner( )
	{
	input_string = 0;
	free_memory(orig_string);
	orig_string = 0;
	BEGIN(INITIAL);
	}

/****************************************/
/*** This will wait for glish events. ***/
/****************************************/
int scanner_read( char buf[], int max_size )
	{

	while ( ! input_string )
		{
		GlishEvent* e = client->NextEvent();
		if ( ! e ) exit(0);

		register const char *N = e->Name();
		if ( N[0] == 'l' && ! strcmp( N, "line" ) )
			{
			const Value *val = e->Val();
			if ( val->Type() == TYPE_RECORD )
				{
				const Value *v = 0;
				if ( (v = val->HasRecordElement( "line" )) )
					{
					orig_string = input_string = v->StringVal();
					if ( (v = val->HasRecordElement( "id" )) && v->IsNumeric() )
						append_id( current_id = v->IntVal( ) );
					else
						append_id( ++current_id );
					}
				else
					{
					client->Error( "no 'line' field in record" );
					continue;
					}
				}
			else
				{
				orig_string = input_string = val->StringVal();
				append_id( ++current_id );
				}
			}

		else if ( N[0] == 'i' && ! strcmp( N, "init") )
			{
			if ( e->Val()->Type() != TYPE_RECORD )
				{
				client->Error( "bad 'init' value" );
				continue;
				}

			recordptr rec = e->Val()->RecordPtr();
			IterCookie* c = rec->InitForIteration();
			Value* val;
			const char* key;
			int did_proc_proc = 0;
			while ( (val = rec->NextEntry( key, c )) )
				{
				if ( val->Type() != TYPE_RECORD ) continue;

				recordptr irec = val->RecordPtr();
				IterCookie* i = rec->InitForIteration();
				Value* ival;
				const Value* name;
				const char* ikey;
				char *clean_key = clean_string(key);
				for ( int cnt=0; (ival = irec->NextEntry( ikey, i )); ++cnt )
					{
					if ( ival->Type() != TYPE_RECORD ||
					     ! (name = ival->HasRecordElement("name")) ||
					     name->Length() <= 0 ||
					     name->Type() != TYPE_STRING ) continue;
					symbol_table.add( new Var( cnt ? strdup(clean_key) : clean_key,
								   clean_string(name->StringPtr(0)[0]) ));
					}

				if ( ! did_proc_proc && key[0] == 'p' && ! strcmp(key, "proc") )
					{
					symbol_table.add( new Var( strdup("proc"), strdup("proc") ) );
					symbol_table.add( new Var( strdup("proc"), strdup("procedure") ) );
					++did_proc_proc;
					}
				}
			}

		else if ( N[0] == 'e' && ! strcmp( N, "end") )
			{
			post_end_result = 1;
			return YY_NULL;
			}

		else if ( N[0] == 'd' && ! strcmp( N, "dump") )
			symbol_table.dump( );

		else
			client->Unrecognized( );
		}

	if ( input_string )
		{
		int len = strlen( input_string );

		if ( len >= max_size )
			{
			// Uh-oh, we've hit a line which is bigger
			// than max_size, we've got to chunk it up.
			memcpy( buf, input_string, max_size );
			input_string = &input_string[max_size];
			return max_size;
			}

		strcpy( buf, input_string );
		buf[len] = '\n';
		clear_scanner( );
		return len+1;
		}

	return YY_NULL;
	}

static char *clean_string( const char *old )
	{
	if ( ! old ) return 0;

	char *buf = (char *) alloc_memory( strlen(old)+1 );
	char *rptr = buf;
	for ( ; *old; ++old )
		if ( *old != '_' )
			*rptr++ = (char) tolower(*old);
	*rptr = '\0';
	return buf;
	}

static char *unquote_string( const char *old )
	{
	if ( ! old ) return 0;

	if ( *old == '\"' ) ++old;

	int len = strlen(old);
	char *buf = (char *) alloc_memory( strlen(old)+1 );
	memcpy( buf, old, len+1 );
	if ( buf[len-1] == '\"' ) buf[len-1] = '\0';
	return buf;
	}
