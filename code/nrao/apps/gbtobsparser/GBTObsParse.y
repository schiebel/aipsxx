/* $Id: GBTObsParse.y,v 19.0 2003/07/16 03:44:29 aips2adm Exp $
** Copyright (c) 1998,2000 Associated Universities Inc.
*/

%token TOK_ALIAS TOK_BLOCK TOK_END TOK_HEADER TOK_QUERY
%token TOK_REPEAT TOK_ID TOK_SEX TOK_STR TOK_LABEL
%token TOK_NUM TOK_ALNUM TOK_YYERROR TOK_NL TOK_STAR
%token TOK_LEXER_ERROR

%right '='

%{
#include <stdio.h>
#include <unistd.h>
#include "Glish/Client.h"
#include "GBTObsSymtab.h"
int doing_block = 0;
%}

%type <var> var block_head
%type <vex> assignvar
%type <str> TOK_SEX TOK_NUM TOK_ALNUM value value_element TOK_STR TOK_LABEL
%type <vlst> assignvalue value_list
%type <id>  TOK_ID
%type <ilst> index index_list

%union	{
	Var *var;
	char *str;
	obs_identifier id;
	obs_varexpr vex;
	char_list *vlst;
	int_list *ilst;
	}

%{
extern "C" {
	int GBTObsParseparse();
	void GBTObsParseerror( char msg[] );
}

#if ! defined(PURE_PARSER)
extern int GBTObsParselex();
#else
extern int GBTObsParselex( YYSTYPE * );
#endif

extern recordptr clear_cval( );
extern void clear_scanner( );
extern void clear_parser( );
extern Value *parser_result( );
static void post_error( );
static void set_param( Value *, const char *, const char *, Value *v=0 );
static char *defcat = 0;

static int undef_ok = 0;
int skip_syntax_error = 0;

typedef List(int) int_list;
extern void append_id( int );
extern Value *collect_ids( );

int_list id_list;

extern SymbolTable symbol_table;

/**
*** This value will be used to accumulate
*** the result for one or more lines.
***
***    parse_value is what really gets retuned
***
***    cval is the current value being constructed
**/
static Value *parse_value = 0;
static Value *cval = 0;

/**
*** this is used for *both* REPEAT and BLOCK blocks
**/
static value_list block_stack;

static var_list cur_line;
static var_list cur_header;

extern Client *client;

extern int post_end_result;

%}

%%

all:		obs
			{ YYACCEPT; }
	|	TOK_LEXER_ERROR
			{ YYABORT; }
	|
			{ YYABORT; }
	;

obs:		statement
	|	repeat
	|	block
	|	TOK_NL
	|	error TOK_NL
			{
			yyerrok;
			yyclearin;
			clear_scanner( );
			}
	;

statement:	TOK_NL
			{ }
	|	alias TOK_NL
	|	header TOK_NL
	|	assign TOK_NL
	|	query TOK_NL
	|	line TOK_NL
			{
			Value *val = cval;
			if ( doing_block )
				{
				val = new Value( create_record_dict() );
				cval->SetField(cval->NewFieldName(0),val);
				}
			if ( cur_line.length() == 1 )
				{
				const char *C = cur_line[0]->category();
				const char *N = cur_line[0]->name();
				if ( N && ! strcmp( C, "block" ) )
					{
					val->SetField( "type", "block" );
					val->SetField( "name", N );
					}
				else if ( N && ! strcmp( C, "procnames" ) )
					{
					val->SetField( "type", "procnames" );
					val->SetField( "name", N );
					}
				// Need if to trap one column tables
				else if ( cur_header.length() != 1 )
					{
					clear_cval( );
					cval->SetField( "type", "syntax error" );
					cval->SetField( "category", C );
					if ( N ) cval->SetField( "name", N );
					post_error( );
					}
				}

			// Need if to handle one column tables
			if ( cur_line.length() != 1 || cur_header.length() == 1 )
				{
				if ( cur_header.length() <= 0 )
					{
					clear_cval( );
					cval->SetField( "type", "line with no previous header" );
					post_error( );
					}
				else if ( cur_line.length() <= 0 )
					{
					clear_cval( );
					cval->SetField( "type", "bad line (zero length)" );
					post_error( );
					}
				else if ( cur_line.length() != cur_header.length() )
					{
					clear_cval( );
					cval->SetField( "type", "bad line (header mismatch)" );
					post_error( );
					}
				else
					{
					val->SetField( "type", "tableline" );
					Value *elem = new Value(create_record_dict());
					val->SetField( "elem", elem ); Unref(elem);
					for ( int i=0; i < cur_line.length(); ++i )
						if ( cur_line[i]->name() )
							{
							if ( ! strcmp(cur_line[i]->category(), "procnames") )
								{
								Value *v = new Value(create_record_dict());
								v->SetField( "type", new Value("procnames") );
								v->SetField( "name", new Value(cur_line[i]->name()) );
								elem->SetField( v->NewFieldName(0), v );
								}
							else
								{
								Value *v = new Value(create_record_dict());
								v->SetField( "type", new Value("param") );
								v->SetField( "category", new Value(cur_line[i]->category()) );
								v->SetField( "name", new Value(cur_line[i]->name()) );
								set_param( elem, cur_header[i]->category(), cur_header[i]->name(), v );
								}
							}
						else
							set_param( elem, cur_header[i]->category(), cur_header[i]->name(),
								   new Value(cur_line[i]->category()) );
					}
				}

			cur_line.clear();
			}
	;

statement_list: statement_list statement
	|
	;

repeat:		repeat_head statement_list TOK_END TOK_NL
			{
			doing_block=0;
			int len = block_stack.length();
			if ( len <= 0 )
				{
				clear_cval( );
				charptr *s = (charptr*) alloc_memory( sizeof(charptr) * 2 );
				s[0] = strdup("stack underflow");
				s[1] = strdup("repeat");
				cval->SetField( "type", s, 2 );
				post_error( );
				}
			else
				/***********************************/
				/*** stop collecting statements  ***/
				/***********************************/
				cval = block_stack.remove_nth( len - 1 );
			}
	;

repeat_head:	TOK_REPEAT TOK_NUM TOK_NL
			{
			/***********************************/
			/*** start collecting statements ***/
			/***********************************/
			cval->SetField( "type", "repeat" );
			cval->SetField( "count", $2 );
			Value *ncval = new Value(create_record_dict());
			cval->SetField( "lines", ncval ); Unref(ncval);
			block_stack.append(cval);
			cval = ncval;
			}
		
	;

block:		block_head statement_list TOK_END TOK_NL
			{
			doing_block=0;
			int len = block_stack.length();
			if ( len <= 0 )
				{
				clear_cval( );
				charptr *s = (charptr*) alloc_memory( sizeof(charptr) * 2 );
				s[0] = strdup("stack underflow");
				s[1] = strdup("block");
				cval->SetField( "type", s, 2 );
				post_error( );
				}
			else
				{
				/***********************************/
				/*** stop collecting statements  ***/
				/***********************************/
				cval = block_stack.remove_nth( len - 1 );
				if ( ! symbol_table.find("block","block") )
					symbol_table.add( new Var( strdup("block"), strdup("block") ) );
				}
			}
	;

block_head:	TOK_BLOCK TOK_LABEL TOK_NL
			{
			/***********************************/
			/*** register block id           ***/
			/***********************************/
			$$ = new Var( strdup("block"), $2 );
			symbol_table.add( $$ );
			/***********************************/
			/*** start collecting statements ***/
			/***********************************/
			cval->SetField( "type", "blockdef" );
			cval->SetField( "name", $2 );
			Value *ncval = new Value(create_record_dict());
			cval->SetField( "lines", ncval ); Unref(ncval);
			block_stack.append(cval);
			cval = ncval;
			}
	;

alias:		TOK_ALIAS TOK_LABEL {undef_ok = 1;} var
			{
			undef_ok = 0;
			if ( symbol_table.alias( $2 ) )
				symbol_table.alias( $2, $4 );
			else if ( symbol_table.find( $2 ) )
				{
				clear_cval( );
				cval->SetField( "type", "alias matches other" );
				post_error( );
				}
			else
				symbol_table.alias( $2, $4 );
			}
	;

header:		header_head var_list
			{
			Value *val = cval;
			if ( doing_block )
				{
				val = new Value( create_record_dict() );
				cval->SetField(cval->NewFieldName(0),val);
				}
			defcat = 0;
			val->SetField( "type", "header" );
			Value *elem = new Value(create_record_dict());
			val->SetField( "elem", elem ); Unref( elem );
			for ( int i=0; i < cur_header.length(); ++i )
				set_param( elem, cur_header[i]->category(), cur_header[i]->name() );
			}
	;

header_head:	TOK_HEADER
			{
			cur_header.clear();
			defcat = "proc";
			}
	;

var_list:	var_list var
			{
			cur_header.append($2);
			}
	|	var
			{
			cur_header.append($1);
			}
	;

index_list:	index_list ',' TOK_NUM
			{
			$1->append( atoi($3) );
			}
	|	TOK_NUM
			{
			$$ = new int_list;
			$$->append( atoi($1) );
			}
	;


index:		index_list
	|	TOK_NUM ':' TOK_NUM
			{
			int start = atoi($1);
			int end = atoi($3);

			$$ = new int_list;
			if ( start <= end )
				for ( ; start <= end; ++start ) $$->append( start );
			else
				for ( ; start >= end; --start ) $$->append( start );
			}
	;

var:		TOK_ID
			{
			if ( ! ($$ = symbol_table.find( $1.cat, $1.nme )) )
				{
				if ( undef_ok )
					$$ = new Var( $1.cat );
				else
					{
					handle_var_error( );
					YYERROR;
					}
				}
			}
	;

assignvar:	TOK_ID
			{
			if ( ! ($$.var = symbol_table.find( $1.cat, $1.nme )) )
				{
				if ( undef_ok )
					$$.var = new Var( $1.cat );
				else
					{
					handle_var_error( );
					YYERROR;
					}
				}
			$$.index = 0;
			}
	|	TOK_ID '[' index ']'
			{
			if ( ! ($$.var = symbol_table.find( $1.cat, $1.nme )) )
				{
				handle_var_error( );
				YYERROR;
				}
			$$.index = $3;
			}
	;

assign:		assignvar '='
			{
			Value *val = cval;
			if ( doing_block )
				{
				val = new Value( create_record_dict() );
				cval->SetField(cval->NewFieldName(0),val);
				}
			val->SetField( "type", "param" );
			val->SetField( "category", $1.var->category() );
			val->SetField( "name", $1.var->name() );
			val->SetField( "value", glish_false );
			val->SetField( "index", glish_false );
			}
	|	assignvar '=' assignvalue
			{
			Value *val = cval;
			if ( doing_block )
				{
				val = new Value( create_record_dict() );
				cval->SetField(cval->NewFieldName(0),val);
				}
			val->SetField( "type", "param" );
			val->SetField( "category", $1.var->category() );
			val->SetField( "name", $1.var->name() );

			int len = 0;
			if ( $3 && (len = $3->length()) > 0 )
				{
				charptr *vec = (charptr*) alloc_memory( len * sizeof(charptr) );
				for ( int i=0; i < len; ++i )
					vec[i] = (*$3)[i];
				val->SetField( "value", new Value( vec, len ) );
				}
			else
				val->SetField( "value", empty_value( TYPE_STRING ) );
			delete $3;

			if ( $1.index && (len = $1.index->length()) > 0 )
				{
				int *vec = (int*) alloc_memory( $1.index->length() * sizeof(int) );
				for ( int i=0; i < len; ++i )
					vec[i] = (*$1.index)[i];
				val->SetField( "index", new Value( vec, len ) );
				}
			else
				val->SetField( "index", glish_false );
			delete $1.index;
			}
	;

value_element:	TOK_SEX
	|	TOK_NUM
	|	TOK_ALNUM
	|	TOK_STR
	;

value_list:	value_list ',' value_element
			{
			$1->append( $3 );
			}
	|	value_element
			{
			$$ = new char_list;
			$$->append($1);
			}
	;

value:		value_element
	;

assignvalue:	value_element
		{
		$$ = new char_list;
		$$->append($1);
		}
	|	'[' value_list ']'
		{
		$$ = $2;
		}
	;

query:		TOK_QUERY TOK_STR var
			{
			Value *val = cval;
			if ( doing_block )
				{
				val = new Value( create_record_dict() );
				cval->SetField(cval->NewFieldName(0),val);
				}
			val->SetField( "type", "query" );
			((char*)$2)[strlen($2)-1] = '\0';
			val->SetField( "prompt", $2 + 1 );
			val->SetField( "category", $3->category() );
			val->SetField( "name", $3->name() );
			}
	|	TOK_QUERY TOK_STR
			{
			Value *val = cval;
			if ( doing_block )
				{
				val = new Value( create_record_dict() );
				cval->SetField(cval->NewFieldName(0),val);
				}
			val->SetField( "type", "query" );
			((char*)$2)[strlen($2)-1] = '\0';
			val->SetField( "prompt", $2 + 1 );
			}
	;

line:		line item
	|	item
	;

item:		TOK_STAR
			{
			cur_line.append(new Var("*NULL*"));
			}
	|	value
			{
			cur_line.append(new Var($1));
			}
	|	var
			{
			cur_line.append($1);
			}
	;

%%

extern "C"
void GBTObsParseerror( char msg[] )
	{
	if ( ! skip_syntax_error )
		{
		post_end_result = 0;
		clear_cval( );
		cval->SetField( "type", "syntax error" );
		post_error( );
		}
	skip_syntax_error = 0;
	}

static void post_error( )
	{
	doing_block = 0;
	Value *ids = collect_ids();
	parse_value->SetField( "id", ids ? ids : empty_value( ) );
	client->PostEvent( "error", parse_value );
	clear_parser( );
	}

recordptr clear_cval( )
	{
	Unref( parse_value );
	recordptr rec = create_record_dict();
	cval = parse_value = new Value( rec );
	return rec;
	}

void clear_parser( )
	{
	clear_cval( );
/*                                                    */
/* Look into what should/should not be deleted here!! */
/*                                                    */
/* 	for ( int x=0; x < cur_line.length(); ++x )   */
/* 		delete cur_line[x];                   */
/*                                                    */
	cur_line.clear();
	id_list.clear();
	clear_scanner();
	}

void append_id( int id )
	{
	id_list.append(id);
	}

Value *collect_ids( )
	{
	int len = id_list.length();
	if ( len <= 0 ) return 0;

	int *ids = (int*) alloc_memory( sizeof(int) * len );
	for ( int i=0; i < len; ++i ) ids[i] = id_list[i];
	return new Value( ids, len );
	}

Value *parser_result( )
	{
	return parse_value;
	}

void set_param( Value *val, const char *cat, const char *name, Value *theval )
	{
	recordptr rec = create_record_dict();
	rec->Insert( strdup("type"), new Value("param") );
	rec->Insert( strdup("category"), new Value(cat) );
	rec->Insert( strdup("name"), new Value(name) );
	if ( theval )
		{
		rec->Insert( strdup("value"), theval );
		rec->Insert( strdup("index"), new Value( glish_false ) );
		}
	Value *v = new Value( rec );
	val->SetField( val->NewFieldName(0), v );
	Unref(v);
	}

void handle_var_error( )
	{
	const char *c, *p;
	symbol_table.last( c, p );

	clear_cval( );
	switch ( symbol_table.getResult( ) ) {
	    case SymbolTable::NMATCH_CAT:
		cval->SetField( "type", "unknown category" );
		if ( c ) cval->SetField( "category", c );
		break;
	    case SymbolTable::NMATCH_NAME:
		cval->SetField( "type", "unknown parameter" );
		if ( c ) cval->SetField( "category", c );
		if ( p ) cval->SetField( "parameter", p );
		break;
	    case SymbolTable::MDOTS_CAT:
		{
		charptr *type = (charptr*) alloc_memory( sizeof(charptr) * 2 );
		type[0] = strdup("alias resolution");
		type[1] = strdup("multiple dots (category)");
		cval->SetField( "type", type, 2 );
		if ( c ) cval->SetField( "category", c );
		}
		break;
	    case SymbolTable::MDOTS_NAME:
		{
		charptr *type = (charptr*) alloc_memory( sizeof(charptr) * 2 );
		type[0] = strdup("alias resolution");
		type[1] = strdup("multiple dots (parameter)");
		cval->SetField( "type", type, 2 );
		if ( c ) cval->SetField( "category", c );
		if ( p ) cval->SetField( "parameter", p );
		}
		break;
	    case SymbolTable::NDOTS:
		{
		charptr *type = (charptr*) alloc_memory( sizeof(charptr) * 2 );
		type[0] = strdup("alias resolution");
		type[1] = strdup("no dots (doesn't resolve to <CATEGORY>.<PARAMETER>)");
		cval->SetField( "type", type, 2 );
		if ( c ) cval->SetField( "category", c );
		}
		break;
	    case SymbolTable::MMATCH:
		{
		cval->SetField( "type", "multiple matches" );
		if ( c ) cval->SetField( "category", c );
		if ( p ) cval->SetField( "parameter", p );
		int len;
		char **matches = symbol_table.getStrings(len);
		if ( matches )
			cval->SetField( "matches", (charptr*) matches, len );
		}
		break;
	    default:
		cval->SetField( "type", "symbol lookup failure" );
		if ( c ) cval->SetField( "category", c );
		if ( p ) cval->SetField( "parameter", p );
	}

	post_error( );
	}

void parser_begin_block()
	{
	doing_block = 1;
	}
