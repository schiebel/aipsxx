%{
/* $Id: scan.l,v 19.14 2005/10/19 14:44:07 dschieb Exp $
** Copyright (c) 1993 The Regents of the University of California.
** Copyright (c) 1997 Associated Universities Inc.
*/

#include "system.h"
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <errno.h>
#if HAVE_OSFCN_H
#include <osfcn.h>
#endif

#include "Expr.h"
#include "BuiltIn.h"
#include "Glish/Reporter.h"
#include "Glish/List.h"
#include "Sequencer.h"
#include "Regex.h"
#include "input.h"
#include "y.tab.h"
#include "system.h"

#if ! defined(PURE_PARSER)
extern YYSTYPE yylval;
#define YYLVAL(x) yylval.x
#define YY_DECL int yy_flex ( )
#else
#define YYLVAL(x) yylval->x
#define YY_DECL int yy_flex YY_PROTO(( YYSTYPE *yylval ))
#endif

extern Sequencer* current_sequencer;
#ifdef GGC
extern int glish_do_gc_register;
extern void glish_gc_register( IValue * );
#define DO_GC_REGISTER						\
	if ( glish_do_gc_register )				\
		glish_gc_register( v );
#else
#define DO_GC_REGISTER
#endif

// Whether the last token might be the end of a statement.
#define SET_STATEMENT_CAN_END					\
	if ( paren_count == 0 ) statement_can_end = 1
static int statement_can_end = 0;
static int paren_count = 0;
static List(int) *paren_count_stack = 0;

static int literal_ids = 0;
#define LITERAL_SECTION (literal_ids & 1)
#define set_LITERAL_SECTION literal_ids |= 1
#define clear_LITERAL_SECTION literal_ids &= ~1
#define LITERAL_CURRENT (literal_ids & 1<<1)
#define set_LITERAL_CURRENT literal_ids |= 1<<1
#define clear_LITERAL_CURRENT literal_ids &= ~(1<<1)
static List(int) *literal_ids_stack = 0;
#define TEST_LITERALS LITERAL_SECTION && LITERAL_CURRENT

extern int first_line;

//Transition Variables
static int request_cnt = 0;
static int send_cnt = 0;

// When we convert a newline to a ';' we don't bump the line count just
// yet, as that'll result in the line count being one too high for the
// statement that ends with that ';'.  So instead we set this flag and
// subsequently bump the line count on the next call.
int bump_line_num = 0;

// A class for holding information on an input file: where we are in
// it (i.e., its flex buffer), its name, and the current line number.
// InputFileInfo objects are created without any parameters; they glean
// all the pertinent information from the globals present in input.h.
// To restore the globals to the state they had when the object was
// created, simply delete it.
class InputFileInfo {
public:
	InputFileInfo( FILE*, YY_BUFFER_STATE );
	~InputFileInfo();

protected:
	YY_BUFFER_STATE buf;
	char* filename;
	unsigned short line;
	int save_first_line;
	int save_bump_line_num;
	int save_statement_can_end;
	int save_paren_count;
	int save_literal_ids;
	FILE *file;
	YY_BUFFER_STATE newbuf;
	};

// List of input buffers associated with included files.
glish_declare(PList,InputFileInfo);
PList(InputFileInfo) file_list;

static int scanner_read( YY_CHAR buf[], int max_size );
static void new_file();

//
// This handles intermediate storage of literals. Each time
// it is called it returns a pointer to the beginning of the
// literal. 'clear_literal()' resets the buffer.
//
static char *literal( const char *s = 0, int clear = 0 );
#define clear_literal() literal(0,1)

#undef YY_INPUT
#define YY_INPUT(buf,result,max_size)	\
	result = scanner_read( buf, max_size );

#define RETURN_CONSTANT(value)					\
	{							\
	SET_STATEMENT_CAN_END;					\
	IValue *v = new IValue( value );			\
	DO_GC_REGISTER						\
	YYLVAL(expr) = new ConstExpr( v );			\
	return TOK_CONSTANT;					\
	}

#define RETURN_LAST_EVENT(type)					\
	{							\
	SET_STATEMENT_CAN_END;					\
	YYLVAL(event_type) = type;				\
	return TOK_LAST_EVENT;					\
	}

#define RETURN_LAST_REGEX(type)					\
	{							\
	SET_STATEMENT_CAN_END;					\
	YYLVAL(regex_type) = type;				\
	return TOK_LAST_REGEX;					\
	}

#define RETURN_COMPOUND(type)					\
	{							\
	YYLVAL(ival) = type;					\
	return TOK_ASSIGN;					\
	}

#define RETURN_APPLYRX(type)					\
	{							\
	YYLVAL(ival) = type;					\
	return TOK_APPLYRX;					\
	}

#define RETURN_KEYWORD(TOKEN,EXTRA)				\
	{							\
	if ( TEST_LITERALS )					\
		{						\
		YYLVAL(id) = string_dup((const char*) yytext );\
		return TOK_ID;					\
		}						\
	else							\
		{						\
		EXTRA						\
		return TOKEN;					\
		}						\
	}

#define PRAGMA_SHARED(type)					\
	{							\
	current_sequencer->MultiClientScript( Client::type );	\
	++line_num;						\
	BEGIN(INITIAL);						\
	break;							\
	}

#define PRAGMA_ONCE						\
	{							\
	current_sequencer->IncludeOnce( );			\
	++line_num;						\
	BEGIN(INITIAL);						\
	break;							\
	}

#undef YY_BREAK
// The following makes actions by default fall through to the next
// action.  We are careful then that every action ends in a "return"
// or a break.  The reason for bother with this is so that picky
// compilers don't complain about the zillions of actions that
// terminate with a "return" followed by a "break".
#define YY_BREAK

#define yywrap() 1
%}

%x QUOTE RECORD_FIELD SCAN_EVENT_NAME UNKNOWN_PRAGMA ATTR ATTR_QUOTE REGEX NO_REGEX END_REGEX

	static int is_double_quote = 0;
	int glish_regex_matched = 0;
	static char *match_regex_portion = 0;
	static char regex_delimit = '\0';
	static char regex_start = '\0';
	static unsigned int regex_flags = 0;


ID	[A-Za-z_][A-Za-z0-9_]*
WS	[ \t]+
OWS	[ \t]*
D	[0-9]
RXSTART	[!/#@%^&|~`;]
RXCONT	[^\n\r\\!/#@%^&|~`;]

FLOAT	(({D}*"."?{D}+)|({D}+"."?{D}*))([eE][-+]?{D}+)?

%%
	// Whether to return a ';' token if a newline is seen.
	int newline_is_semi = statement_can_end;

	if ( bump_line_num )
		++line_num;

	bump_line_num = 0;
	statement_can_end = 0;


[!:;|&+*/%^-]	return yytext[0];

[,]		{
		set_LITERAL_CURRENT;
		return yytext[0];
		}

[=]		{
		clear_LITERAL_CURRENT;
		return yytext[0];
		}

[[]		{
		literal_ids_stack->append(literal_ids);
		clear_LITERAL_SECTION;
		clear_LITERAL_CURRENT;
		return yytext[0];
		}

[\]]		{
		literal_ids = literal_ids_stack->remove_nth(literal_ids_stack->length()-1);
		SET_STATEMENT_CAN_END;
		return yytext[0];
		}

[(]		{
		++paren_count;
		literal_ids_stack->append(literal_ids);
		clear_LITERAL_SECTION;
		clear_LITERAL_CURRENT;
		return yytext[0];
		}

[)]		{
		literal_ids = literal_ids_stack->remove_nth(literal_ids_stack->length()-1);
		if ( --paren_count < 0 ) paren_count = 0;
		SET_STATEMENT_CAN_END;
		return yytext[0];
		}

[{]		{
		paren_count_stack->append(paren_count);
		paren_count = 0;
		literal_ids_stack->append(literal_ids);
		clear_LITERAL_SECTION;
		clear_LITERAL_CURRENT;
		return yytext[0];
		}

[}]		{
		paren_count = paren_count_stack->remove_nth(paren_count_stack->length()-1);
		literal_ids = literal_ids_stack->remove_nth(literal_ids_stack->length()-1);
		if ( newline_is_semi )
			{
			unput( '}' );
			return ';';
			}
		else
			return '}';
		}

"++"|"--"	{
		glish_error->Report( yytext, " is not a valid Glish operator" );
		paren_count = 0;
		return TOK_FLEX_ERROR;
		}

"."		BEGIN(RECORD_FIELD); return yytext[0];
"->"		BEGIN(SCAN_EVENT_NAME); return TOK_ARROW;
"::"		BEGIN(ATTR); return TOK_ATTR;

"..."		return TOK_ELLIPSIS;

"=="		return TOK_EQ;
"!="		return TOK_NE;
"<="		return TOK_LE;
">="		return TOK_GE;
"<"		return TOK_LT;
">"		return TOK_GT;

"&&"		return TOK_AND_AND;
"||"		return TOK_OR_OR;

":="		RETURN_COMPOUND(0);

"+:="		RETURN_COMPOUND(yytext[0]);
"-:="		RETURN_COMPOUND(yytext[0]);
"*:="		RETURN_COMPOUND(yytext[0]);
"/:="		RETURN_COMPOUND(yytext[0]);
"%:="		RETURN_COMPOUND(yytext[0]);
"^:="		RETURN_COMPOUND(yytext[0]);

"&:="		RETURN_COMPOUND(yytext[0]);
"|:="		RETURN_COMPOUND(yytext[0]);

"&&:="		RETURN_COMPOUND(TOK_AND_AND);
"||:="		RETURN_COMPOUND(TOK_OR_OR);

"~:="		RETURN_COMPOUND(yytext[0]);
"=~"		RETURN_APPLYRX(yytext[0]);
"!~"		RETURN_APPLYRX(yytext[0]);
"~"		RETURN_APPLYRX(0);

activate	RETURN_KEYWORD( TOK_ACTIVATE, SET_STATEMENT_CAN_END; YYLVAL(ival) = 1; );
await		RETURN_KEYWORD( TOK_AWAIT, );
break		RETURN_KEYWORD( TOK_BREAK, statement_can_end = 1; );
const		return TOK_CONST;
deactivate	RETURN_KEYWORD( TOK_ACTIVATE, SET_STATEMENT_CAN_END; YYLVAL(ival) = 0; );
do		RETURN_KEYWORD( TOK_DO, );
else		RETURN_KEYWORD( TOK_ELSE, );
except		RETURN_KEYWORD( TOK_EXCEPT, );
exit		RETURN_KEYWORD( TOK_EXIT, statement_can_end = 1; );
for		RETURN_KEYWORD( TOK_FOR, );
func(tion)?	RETURN_KEYWORD( TOK_FUNCTION, );
if		RETURN_KEYWORD( TOK_IF, );
in		RETURN_KEYWORD( TOK_IN, );
link		RETURN_KEYWORD( TOK_LINK, );
local		RETURN_KEYWORD( TOK_LOCAL, );
global		RETURN_KEYWORD( TOK_GLOBAL, );
wider		RETURN_KEYWORD( TOK_WIDER, );
next|continue	RETURN_KEYWORD( TOK_NEXT, statement_can_end = 1; );
only		RETURN_KEYWORD( TOK_ONLY, );
print		RETURN_KEYWORD( TOK_PRINT, );
fail		RETURN_KEYWORD( TOK_FAIL, statement_can_end = 1; );
ref		RETURN_KEYWORD( TOK_REF, );
return		RETURN_KEYWORD( TOK_RETURN, statement_can_end = 1; );
subseq(uence)?	RETURN_KEYWORD( TOK_SUBSEQUENCE, );
to		RETURN_KEYWORD( TOK_TO, );
unlink		RETURN_KEYWORD( TOK_UNLINK, );
val		RETURN_KEYWORD( TOK_VAL, );
whenever	RETURN_KEYWORD( TOK_WHENEVER, );
while		RETURN_KEYWORD( TOK_WHILE, );
include		RETURN_KEYWORD( TOK_INCLUDE, );

"$agent"	RETURN_LAST_EVENT( EVENT_AGENT )
"$name"		RETURN_LAST_EVENT( EVENT_NAME )
"$value"	RETURN_LAST_EVENT( EVENT_VALUE )
"$m"		RETURN_LAST_REGEX( REGEX_MATCH )

F		RETURN_CONSTANT( glish_false )
T		RETURN_CONSTANT( glish_true )

pragma{WS}shared{WS}user{OWS};?{OWS}\r?\n	PRAGMA_SHARED(USER)
pragma{WS}shared{WS}group{OWS};?{OWS}\r?\n	PRAGMA_SHARED(GROUP)
pragma{WS}shared{WS}world{OWS};?{OWS}\r?\n	PRAGMA_SHARED(WORLD)
pragma{WS}include{WS}once{OWS};?{OWS}\r?\n	PRAGMA_ONCE
pragma		BEGIN(UNKNOWN_PRAGMA); break;

<INITIAL,NO_REGEX>{ID} {
		SET_STATEMENT_CAN_END;
		YYLVAL(id) = string_dup((const char*) yytext );
		BEGIN(INITIAL);
		return TOK_ID;
		}

<RECORD_FIELD,ATTR,SCAN_EVENT_NAME>{ID}	{
		// We use a separate start condition for these names so
		// that they can include reserved words.

		BEGIN(INITIAL);
		SET_STATEMENT_CAN_END;
		YYLVAL(id) = string_dup((const char*) yytext );
		return TOK_ID;
		}

<SCAN_EVENT_NAME>[*\[]	BEGIN(INITIAL); return yytext[0];

{D}+		{
		long longv = strtol((const char*) yytext, 0, 10 );
		if ( errno == ERANGE )
			RETURN_CONSTANT( strtod((const char*) yytext, 0 ) )
		else
			RETURN_CONSTANT( (int) longv )
		}

{FLOAT}		RETURN_CONSTANT( strtod((const char*) yytext, 0) )

{FLOAT}i	RETURN_CONSTANT( atodcpx((const char*) yytext) )

["']		{
		clear_literal();
		is_double_quote = yytext[0] == '"';
		BEGIN(QUOTE);
		break;
		}

[ms]{RXSTART}	{
		clear_literal();
		regex_start = yytext[0];
		regex_delimit = yytext[1];
		match_regex_portion = 0;
		BEGIN(REGEX);
		break;
		}
		
<REGEX>{RXCONT}+			literal((const char*) yytext ); break;
<QUOTE,ATTR_QUOTE>[^'"\r\n\\]+		literal((const char*) yytext ); break;
<QUOTE,REGEX,ATTR_QUOTE>"\\n"		literal( "\n" ); break;
<QUOTE,REGEX,ATTR_QUOTE>"\\t"		literal( "\t" ); break;
<QUOTE,REGEX,ATTR_QUOTE>"\\r"		literal( "\r" ); break;
<QUOTE,REGEX,ATTR_QUOTE>"\\f"		literal( "\f" ); break;
<QUOTE,REGEX,ATTR_QUOTE>"\\v"		literal( "\v" ); break;
<QUOTE,REGEX,ATTR_QUOTE>"\\e"		{ char escape[2] = { '\x01b', '\0' };
					  literal( escape ); break; }
<QUOTE,REGEX,ATTR_QUOTE>"\\a"		literal( "\a" ); break;
<QUOTE,REGEX,ATTR_QUOTE>"\\"\r?\n{OWS}	++line_num; break;
<QUOTE,ATTR_QUOTE>"\\".			literal((const char*) &yytext[1] ); break;
<REGEX>"\\".				literal((const char*) yytext ); break;


<ATTR>"["	{
		BEGIN(INITIAL);
		return yytext[0];
		}

<ATTR>["']	{
		clear_literal();
		is_double_quote = yytext[0] == '"';
		BEGIN(ATTR_QUOTE);
		break;
		}

<QUOTE>\"	|
<QUOTE>\'	{
		if ( (is_double_quote && yytext[0] == '\'') ||
		     (! is_double_quote && yytext[0] == '"') )
			literal((const char*) &yytext[0]);

		else
			{
			BEGIN(INITIAL);

			if ( is_double_quote )
				{
				SET_STATEMENT_CAN_END;
				IValue *v = isplit( literal());
#ifdef GGC
				if ( glish_do_gc_register )
					glish_gc_register( v );
#endif
				YYLVAL(expr) = new ConstExpr( v );
				return TOK_CONSTANT;
				}

			else
				RETURN_CONSTANT( literal() )
			}

		break;
		}

<ATTR_QUOTE>\"	|
<ATTR_QUOTE>\'	{
		if ( (is_double_quote && yytext[0] == '\'') ||
		     (! is_double_quote && yytext[0] == '"') )
			literal((const char *) &yytext[0]);

		else
			{
			BEGIN(INITIAL);
			SET_STATEMENT_CAN_END;
			YYLVAL(id) = string_dup( literal() );
			return TOK_ID;
			}

		break;
		}

<REGEX>{RXSTART} {
		if ( yytext[0] != regex_delimit )
			{
			literal((const char*) yytext);
			break;
			}
		else if ( regex_start == 'm' || match_regex_portion )
			{
			regex_flags = 0;
			BEGIN(END_REGEX);
			break;
			}
		else
			{
			match_regex_portion = string_dup(literal());
			clear_literal();
			break;
			}
		}

<END_REGEX>[gi] {
		regex_flags |= yytext[0] == 'g' ?  Regex::GLOBAL() : yytext[0] == 'i' ? Regex::FOLD() : 0;
		break;
		}

<END_REGEX>\r?\n |
<END_REGEX>. {
		SET_STATEMENT_CAN_END;
		unput(yytext[0]);
		IValue *v = 0;
		Regex *r = regex_start == 'm' ? new Regex( string_dup(literal()), regex_delimit, regex_flags ) :
				new Regex(match_regex_portion, regex_delimit, regex_flags, string_dup(literal()));
		if ( ! r->Error() )
			v = new IValue( r );
		else
			{
			v = (IValue*) ValCtor::error(r->Error());
			delete r;
			}
		DO_GC_REGISTER
		YYLVAL(expr) = new ConstExpr( v );
		glish_regex_matched = 1;
		BEGIN(INITIAL);
		return TOK_REGEX;
		}

<REGEX>\r?\n	{
		unput('\n');
		char *bad = literal();
		int len = strlen(bad)-1;
		for ( int i = len; i >= 0; --i )
			{
			unput(bad[i]);
			}
		unput( regex_delimit );
		if ( match_regex_portion )
			{
			len = strlen(match_regex_portion)-1;
			for ( int i = len; i >= 0; --i )
				unput(match_regex_portion[i]);
			free_memory(match_regex_portion);
			match_regex_portion = 0;
			unput( regex_delimit );
			}
		unput( regex_start );
		BEGIN(NO_REGEX);
		break;
		}


<QUOTE,ATTR_QUOTE>\r?\n	{
		glish_error->Report( "unmatched quote (",
				is_double_quote ? "\"" : "'", ")" );
		++line_num;
		BEGIN(INITIAL);
		paren_count = 0;
		return TOK_FLEX_ERROR;
		}


<INITIAL,RECORD_FIELD,SCAN_EVENT_NAME,ATTR>#.*			break; // comment
<INITIAL,RECORD_FIELD,SCAN_EVENT_NAME,UNKNOWN_PRAGMA,ATTR>{WS}	break; // eat whitespace

<UNKNOWN_PRAGMA>.*	{
		static Dict(int) unknown_pragma;
		if ( ! unknown_pragma.Lookup((const char*) yytext) )
			{
			unknown_pragma.Insert(string_dup((const char*) yytext),1);
			glish_warn->Report( "unknown pragma found:", yytext );
			}
		BEGIN(INITIAL);
		break;
		}

<INITIAL,RECORD_FIELD,SCAN_EVENT_NAME,ATTR>\\\r?\n	{
		++line_num;
		break;
		}

<ATTR>\r?\n	{
		// Treat this case as ending the newline, so that
		// "foo := bar::" works as expected.
		BEGIN(INITIAL);
		bump_line_num = 1;
		return ';';
		}

<ATTR>.		{ // Allow "bar:::=" to work.
		unput( yytext[0] );
		SET_STATEMENT_CAN_END;
		BEGIN(INITIAL);
		break;
		}

<*>\r?\n	{
		if ( newline_is_semi )
			{
			bump_line_num = 1;
			return ';';
			}

		++line_num;
		break;
		}

<*>.		{
		glish_error->Report( "unrecognized character '", yytext, "'" );
		SET_STATEMENT_CAN_END;
		BEGIN(INITIAL);
		paren_count = 0;
		return TOK_FLEX_ERROR;
		}

<<EOF>>		{
		if ( newline_is_semi )
			return ';';

		int nesting = file_list.length();
		if ( nesting > 0 )
			{
			// Pop back to previous file.
			delete file_list.remove_nth( nesting - 1 );
			break;
			}

		else
			yyterminate();
		}
%%

InputFileInfo::InputFileInfo( FILE *f, YY_BUFFER_STATE s )
	{
	buf = YY_CURRENT_BUFFER;
	line = line_num;
	save_first_line = first_line;
	save_bump_line_num = bump_line_num;
	save_statement_can_end = statement_can_end;
	save_paren_count = paren_count;
	file = f;
	newbuf = s;
	}

InputFileInfo::~InputFileInfo()
	{
	yy_switch_to_buffer( buf );
	line_num = line;
	first_line = save_first_line;
	bump_line_num = save_bump_line_num;
	statement_can_end = save_statement_can_end;
	paren_count = save_paren_count;
	if ( newbuf ) yy_delete_buffer( newbuf );
	if ( file ) fclose( file );
	}


// If non-null, we're scanning an array of strings, with our present
// position given by input_offset.
static const char** input_strings;
static const char* save_string = 0;
static int input_offset;

void scan_strings( const char** strings )
	{
	input_strings = strings;
	input_offset = 0;
	}

int scanner_read( YY_CHAR yybuf[], int max_size )
	{
        char *buf = (char*) yybuf;
	if ( input_strings )
		{
		const char* s = input_strings[input_offset];
		if ( ! s )
			{ // All done.
			input_strings = 0;
			return 0;
			}

		char* bufptr = buf;
		while ( max_size > 0 && s )
			{
			int len = strlen( s );
			if ( len >= max_size )
				{
				// Uh-oh, we've hit a line which is bigger
				// than max_size, we've got to chunk it up.
				if ( buf == bufptr )
					{
					memcpy( buf, s, max_size );
					if ( ! save_string ) save_string = s;
					input_strings[input_offset] = &s[max_size];
					bufptr += max_size;
					}
				// Okay, we've read enough.
				return bufptr - buf;
				}

			strcpy( bufptr, s );
			bufptr[len] = '\n';
			++len;	// add in the newline
			bufptr += len;
			max_size -= len;

			// We were fed a string longer than max_size, and so we
			// had to chunk it up, now we're fixing things back
			if ( save_string )
				{
				input_strings[input_offset] = save_string;
				save_string = 0;
				}
			// Move on to the next string.
			s = input_strings[++input_offset];
			}

		return bufptr - buf;
		}

	if ( interactive( ) && yyin == stdin )
		{
		const char* prompt = first_line ? "- " : "+ ";
		if ( Sequencer::CurSeq()->System().ILog() )
			{
			int len = interactive_read( yyin, prompt, buf, max_size );
			Sequencer::CurSeq()->System().DoILog(buf,len);
			return len;
			}
		else
			return interactive_read( yyin, prompt, buf, max_size );
		}
	else
		return read( fileno( yyin ), buf, max_size );
	}

void restart_yylex( FILE* input_file )
	{
	static int first_call = 1;

	if ( yyin && yyin != stdin )
		fclose( yyin );

	yyin = input_file;

	new_file();

	if ( first_call )
		first_call = 0;
	else
		yyrestart( yyin );
	}

static int put_back_token = NULL_TOK;
int
#if ! defined(PURE_PARSER)
yylex ( )
#else
yylex ( YYSTYPE *yylval )
#endif
	{
	if ( put_back_token == NULL_TOK )
		return 
#if ! defined(PURE_PARSER)
			yy_flex ( );
#else
			yy_flex ( yylval );
#endif
	else
		{
		int cur_token = put_back_token;
		put_back_token = NULL_TOK;
		return cur_token;
		}
	}

void putback_token( int tok )
	{
	put_back_token = tok;
	}

void new_file()
	{
	line_num = 1;
	first_line = 1;
	bump_line_num = 0;
	statement_can_end = 0;
	paren_count = 0;
	}

char *literal( const char *new_str, int clear )
	{
	static unsigned int len = 512;
	static unsigned int curlen = 0;
	static char *string = alloc_char( len );

	if ( clear )
		curlen = 0;

	if ( ! new_str )
		{
		string[curlen] = '\0';
		return string;
		}

	int newlen = strlen(new_str);

	if ( curlen + newlen + 1 > len )
		{
		while ( curlen + newlen + 1 > len )
			len *= 2;
		string = realloc_char( string, len );
		}

	memcpy( &string[curlen], new_str, newlen + 1 );
	curlen += newlen;
	return string;
	}

struct flex_buf GC_FREE_CLASS {
	flex_buf( YY_BUFFER_STATE buf_, int putback_ ) : buf(buf_), putback(putback_) { }
	YY_BUFFER_STATE buf;
	int putback;
};

void *current_flex_buffer()
	{
	return new flex_buf(YY_CURRENT_BUFFER, put_back_token);
	}

void *new_flex_buffer( FILE *fptr )
	{
	return new flex_buf(yy_create_buffer(fptr, YY_BUF_SIZE), NULL_TOK);
	}

void set_flex_buffer(void *new_buf)
	{
	flex_buf *buf = (flex_buf*) new_buf;
	yy_switch_to_buffer(buf->buf);
	put_back_token = buf->putback;
	}

void delete_flex_buffer(void *old_buf)
	{
	flex_buf *buf = (flex_buf*) old_buf;
	yy_delete_buffer(buf->buf);
	delete buf;
	}

int begin_literal_ids( int lookahead )
	{
	int clear_lookahead = 0;
	if ( lookahead != NULL_TOK &&
	     lookahead > START_KEYWORDS &&
	     lookahead < END_KEYWORDS )
		{
		YYLVAL(id) = string_dup((const char*) yytext );
		putback_token(TOK_ID);
		clear_lookahead = 1;
		}
	set_LITERAL_SECTION;
	set_LITERAL_CURRENT;
	return clear_lookahead;
	}

void end_literal_ids()
	{
	clear_LITERAL_SECTION;
	clear_LITERAL_CURRENT;
	}

void init_scanner( )
	{
	paren_count_stack = new List(int);
	literal_ids_stack = new List(int);
	}

void set_statement_can_end( )
	{
	SET_STATEMENT_CAN_END;
	}

void clear_statement_can_end( )
	{
	statement_can_end = 0;
	}

void scanner_reset( )
	{
	BEGIN(INITIAL);
	paren_count = 0;
	}
