/* $Id: parse.y,v 19.13 2004/11/03 20:39:00 cvsmgr Exp $
** Copyright (c) 1993 The Regents of the University of California.
** Copyright (c) 1997,1998 Associated Universities Inc.
*/

%token START_KEYWORDS
%token TOK_ACTIVATE TOK_AWAIT TOK_BREAK TOK_DO TOK_ELSE TOK_EXCEPT TOK_EXIT
%token TOK_FAIL TOK_FOR TOK_FUNCTION TOK_GLOBAL TOK_IF TOK_IN TOK_INCLUDE
%token TOK_LINK TOK_LOCAL TOK_NEXT TOK_ONLY TOK_PRINT TOK_RETURN
%token TOK_SUBSEQUENCE TOK_TO TOK_UNLINK TOK_WHENEVER TOK_WHILE TOK_WIDER
%token TOK_REF TOK_VAL
%token END_KEYWORDS
%token TOK_CONST
%token TOK_CONSTANT TOK_ID TOK_REGEX
%token TOK_ELLIPSIS TOK_APPLYRX TOK_ATTR 
%token TOK_LAST_EVENT TOK_LAST_REGEX
%token TOK_FLEX_ERROR NULL_TOK

%left ','
%right TOK_ASSIGN
%left TOK_OR_OR
%left TOK_AND_AND
%left '|'
%left '&'
%nonassoc TOK_LT TOK_GT TOK_LE TOK_GE TOK_EQ TOK_NE
%left '+' '-'
%left '*' '/' '%'
%left ':'
%right '^'
%right '!'
%left TOK_APPLYRX
%left '.' '[' ']' '(' ')' TOK_ARROW TOK_ATTR TOK_REQUEST

%type <ival> TOK_ACTIVATE TOK_ASSIGN TOK_APPLYRX
%type <id> TOK_ID opt_id
%type <event_type> TOK_LAST_EVENT
%type <regex_type> TOK_LAST_REGEX
%type <expr> TOK_CONSTANT expression var function formal_param_default TOK_REGEX
%type <expr> scoped_expr opt_scoped_expr stand_alone_expr scoped_lhs_var
%type <expr> function_head block_head subscript
%type <expr> func_attributes
%type <exprlist> subscript_list
%type <event> event
%type <stmt> statement_list statement func_body block
%type <stmt> local_list local_item global_list global_item wider_list wider_item
%type <stmt> whenever whenever_head
%type <ev_list> event_list
%type <param_list> formal_param_list formal_params
%type <param_list> actual_param_list actual_params
%type <param_list> opt_actual_param_list opt_actual_params
%type <param_list> array_record_ctor_list array_record_params
%type <param> formal_param actual_param opt_actual_param
%type <param> array_record_param
%type <val_type> value_type formal_param_class


%{
#if defined(_AIX) && defined(YYBISON)
/* Must occur before the first line of C++ code - barf! */
/* Actually only required when using bison. */
#pragma alloca
#endif

#include "config.h"
#include <string.h>
#include <stdlib.h>
#include <setjmp.h>

#include "BinOpExpr.h"
#include "Event.h"
#include "Stmt.h"
#include "Func.h"
#include "Glish/Reporter.h"
#include "Pager.h"
#include "Sequencer.h"
#include "Task.h"
#include "input.h"
#include "system.h"
%}

%union	{
	char* id;
	last_event_type event_type;
	last_regex_type regex_type;
	Expr* expr;
	expr_list* exprlist;
	EventDesignator* event;
	Stmt* stmt;
	event_dsg_list* ev_list;
	PDict(Expr)* record;
	parameter_list* param_list;
	Parameter* param;
	value_reftype val_type;
	int ival;
	}

%{
extern "C" {
	int yyparse();
	void yyerror( char msg[] );
}

/* returns non-zero if look-ahead should be cleared */
extern int begin_literal_ids( int );
extern void end_literal_ids();

expr_list *glish_current_subsequence = 0;
/* reset glish state after an error */
static void error_reset( );

#if ! defined(PURE_PARSER)
extern int yylex();
#else
extern int yylex( YYSTYPE * );
#endif

/* Used for recovery after a ^C */
extern jmp_buf glish_top_jmpbuf;
extern int glish_top_jmpbuf_set;

Sequencer* current_sequencer = 0;
static IValue *parse_error = 0;

/* Communication of status between glish_parser() and yyparse() */
static int status;
static int scope_depth = 0;
static Stmt *cur_stmt = null_stmt;
static evalOpt *eval_options;

static int *lookahead = 0;
static int empty_token = 0;

int first_line = 1;
extern int glish_regex_matched;
extern void putback_token( int );
Expr* compound_assignment( Expr* lhs, int tok_type, Expr* rhs );
%}

%%


glish:
		{first_line = 0;} statement
			{
			first_line = 1;
			glish_regex_matched = 0;
			if ( interactive( ) )
				status = 0;

			if ( ! lookahead )
				{
				lookahead = & ( yyclearin );
				empty_token = *lookahead;
				}

			cur_stmt = $2;

			if ( *lookahead != empty_token )
				putback_token( *lookahead );

			YYACCEPT;
			}

	|	error
			{
			first_line = 1;
			status = 1;
			if ( interactive( ) )
				{
				// Try to throw away the rest of the line.
				set_statement_can_end( );
				first_line = 1;
				YYACCEPT;
				}
			else
				{
				YYABORT;
				}
			}
	|
			{
			first_line = 1;
			YYABORT;
			}

	;


statement_list:
		statement_list statement
			{ $$ = merge_stmts( $1, $2 ); }
	|
			{ $$ = null_stmt; }
	;


scoped_expr:
		expression
			{ $$ = $$->BuildFrameInfo( SCOPE_UNKNOWN ); }
	;

opt_scoped_expr:
		scoped_expr
	|
			{ $$ = 0; }
	;

stand_alone_expr:
		scoped_expr
			{ $$->StandAlone( ); }
	;


scoped_lhs_var:
		var
			{ $$ = $$->BuildFrameInfo( SCOPE_LHS ); }
	;

statement:
		block

	|	TOK_LOCAL local_list ';'
			{ $$ = $2; }

	|	TOK_GLOBAL global_list ';'
			{ $$ = $2; }

	|	TOK_WIDER wider_list ';'
			{ $$ = $2; }

	|	whenever

	|	TOK_LINK event_list TOK_TO event_list ';'
			{ $$ = new LinkStmt( $2, $4, current_sequencer ); }

	|	TOK_UNLINK event_list TOK_TO event_list ';'
			{ $$ = new UnLinkStmt( $2, $4, current_sequencer ); }

	|	TOK_AWAIT event_list ';'
			{
			$$ = new AwaitStmt( $2, 0, 0, current_sequencer );
			}
	|	TOK_AWAIT TOK_ONLY event_list ';'
			{
			$$ = new AwaitStmt( $3, 1, 0, current_sequencer );
			}
	|	TOK_AWAIT TOK_ONLY event_list TOK_EXCEPT event_list ';'
			{
			$$ = new AwaitStmt( $3, 1, $5, current_sequencer );
			}

	|	TOK_ACTIVATE ';'
			{ $$ = new ActivateStmt( $1, 0, current_sequencer ); }

	|	TOK_ACTIVATE scoped_expr ';'
			{ $$ = new ActivateStmt( $1, $2, current_sequencer ); }

	|	TOK_IF '(' scoped_expr ')' cont statement
			{ $$ = new IfStmt( $3, $6, 0 ); }
	|	TOK_IF '(' scoped_expr ')' cont statement TOK_ELSE statement
			{ $$ = new IfStmt( $3, $6, $8 ); }

	|	TOK_FOR '(' scoped_lhs_var TOK_IN scoped_expr ')' cont statement
			{
			$$ = new ForStmt( $3, $5, $8 );
			}

	|	TOK_WHILE '(' scoped_expr ')' cont statement
			{ $$ = new WhileStmt( $3, $6 ); }

	|	TOK_NEXT ';'
			{ $$ = new LoopStmt; }

	|	TOK_BREAK ';'
			{ $$ = new BreakStmt; }

	|	TOK_RETURN ';'
			{ $$ = new ReturnStmt( 0 ); }

	|	TOK_RETURN scoped_expr ';'
			{ $$ = new ReturnStmt( $2 ); }

	|	TOK_EXIT ';'
			{ $$ = new ExitStmt( 0, current_sequencer ); }

	|	TOK_EXIT scoped_expr ';'
			{ $$ = new ExitStmt( $2, current_sequencer ); }

	|	TOK_PRINT actual_param_list ';'
			{ $$ = new PrintStmt( $2 ); }

	|	TOK_FAIL opt_scoped_expr ';'
			{ $$ = new FailStmt( $2 ); }

	|	stand_alone_expr ';'
			{ $$ = new ExprStmt( $1 ); }

	|	';'
			{ $$ = null_stmt; }
	;

whenever: whenever_head TOK_DO statement
			{
			((WheneverStmtCtor*) $1)->SetStmt($3);
			$$ = $1;
			}
	;

whenever_head: TOK_WHENEVER event_list
			{
		        $$ = new WheneverStmtCtor( $2, current_sequencer );
			}
	;

expression:
		'(' expression ')'
			{ $$ = $2; }

	|	expression TOK_ASSIGN expression
			{ $$ = compound_assignment( $1, $2, $3 ); }

	|	expression TOK_OR_OR expression
			{ $$ = new OrExpr( $1, $3 ); }
	|	expression TOK_AND_AND expression
			{ $$ = new AndExpr( $1, $3 ); }

	|	expression '|' expression
			{ $$ = new LogOrExpr( $1, $3 ); }
	|	expression '&' expression
			{ $$ = new LogAndExpr( $1, $3 ); }

	|	expression TOK_LT expression
			{ $$ = new LT_Expr( $1, $3 ); }
	|	expression TOK_GT expression
			{ $$ = new GT_Expr( $1, $3 ); }
	|	expression TOK_LE expression
			{ $$ = new LE_Expr( $1, $3 ); }
	|	expression TOK_GE expression
			{ $$ = new GE_Expr( $1, $3 ); }
	|	expression TOK_EQ expression
			{ $$ = new EQ_Expr( $1, $3 ); }
	|	expression TOK_NE expression
			{ $$ = new NE_Expr( $1, $3 ); }

	|	TOK_LT expression TOK_GT
			{
			Expr* id = current_sequencer->LookupID( string_dup("_"), LOCAL_SCOPE, 1, 0, 0 );
			Ref(id);
			$$ = compound_assignment( id, 0, new GenerateExpr($2) );
			}

	|	expression '+' expression
			{ $$ = new AddExpr( $1, $3 ); }
	|	expression '-' expression
			{ $$ = new SubtractExpr( $1, $3 ); }
	|	expression '*' expression
			{ $$ = new MultiplyExpr( $1, $3 ); }
	|	expression '/' expression
			{ $$ = new DivideExpr( $1, $3 ); }
	|	expression '%' expression
			{ $$ = new ModuloExpr( $1, $3 ); }
	|	expression '^' expression
			{ $$ = new PowerExpr( $1, $3 ); }

	|	expression TOK_APPLYRX expression
			{
			if ( $2 == '!' )
				$$ = new NotExpr( new ApplyRegExpr( $1, $3, current_sequencer, $2 ) );
			else
				$$ = new ApplyRegExpr( $1, $3, current_sequencer, $2 );
			}

	|	TOK_APPLYRX expression
			{
			Expr* id = current_sequencer->LookupID( string_dup("_"), ANY_SCOPE, 0, 0 );
			if ( ! id ) id = current_sequencer->InstallID( string_dup("_"), LOCAL_SCOPE, 0 );
			Ref(id);

			if ( $1 == '!' )
				$$ = new NotExpr( new ApplyRegExpr( id, $2, current_sequencer, $1 ) );
			else
				$$ = new ApplyRegExpr( id, $2, current_sequencer, $1 );
			}

	|	'-' expression			%prec '^'
			{ $$ = new NegExpr( $2 ); }
	|	'+' expression			%prec '^'
			{ $$ = $2; }
	|	'!' expression
			{ $$ = new NotExpr( $2 ); }

	|	expression '[' subscript_list ']'
			{ $$ = new ArrayRefExpr( $1, $3 ); }

	|	expression '.' TOK_ID
			{ $$ = new RecordRefExpr( $1, $3 ); }

	|	expression TOK_ATTR
			{ $$ = new AttributeRefExpr( $1 ); }

	|	expression TOK_ATTR '[' expression ']'
			{ $$ = new AttributeRefExpr( $1, $4 ); }

	|	expression TOK_ATTR TOK_ID
			{ $$ = new AttributeRefExpr( $1, $3 ); }

	|	'[' '=' ']'
			{ $$ = new ConstructExpr( 0 ); }

	|	'[' begin_literal_ids array_record_ctor_list end_literal_ids ']'
			{ $$ = new ConstructExpr( $3 ); }

	|	expression ':' expression	%prec '^'
			{ $$ = new RangeExpr( $1, $3 ); }

	|	expression '(' opt_actual_param_list ')'
			{ $$ = new CallExpr( $1, $3, current_sequencer ); }

	|	value_type expression		%prec '!'
			{ $$ = new RefExpr( $2, $1 ); }

	|	event '(' actual_param_list ')'
			{
			$$ = new SendEventExpr( $1, $3 );
			}

	|	TOK_LAST_EVENT
			{ $$ = new LastEventExpr( current_sequencer, $1 ); }

	|	TOK_LAST_REGEX
			{ $$ = new LastRegexExpr( current_sequencer, $1 ); }

	|	TOK_INCLUDE expression		%prec '!'
			{ $$ = new IncludeExpr( $2, current_sequencer ); }

	|	function

	|	var

	|	TOK_CONSTANT

	|	TOK_REGEX

	|	TOK_FLEX_ERROR
			{
			error_reset();
			YYERROR;
			}
	;


local_list:	local_list ',' local_item
			{ $$ = merge_stmts( $1, $3 ); }
	|	local_item
	;

local_item:	TOK_ID TOK_ASSIGN scoped_expr
			{
			Expr* id = current_sequencer->LookupID( $1, LOCAL_SCOPE, 1, 0, 0 );

			Ref(id);
			$$ = new ExprStmt( compound_assignment( id, $2, $3 ) );

			if ( $2 != 0 )
				glish_warn->Report( "compound assignment in", $$ );
			}
	|	TOK_ID
			{
			(void) current_sequencer->LookupID( $1, LOCAL_SCOPE, 1, 0, 0, 1 );
			$$ = null_stmt;
			}
	;


global_list:	global_list ',' global_item
			{ $$ = merge_stmts( $1, $3 ); }
	|	global_item
	;

global_item:	TOK_ID TOK_ASSIGN scoped_expr
			{
			Expr* id =
				current_sequencer->LookupID( $1, GLOBAL_SCOPE, 1, 0 );

			Ref(id);
			$$ = new ExprStmt( compound_assignment( id, $2, $3 ) );

			if ( $2 != 0 )
				glish_warn->Report( "compound assignment in", $$ );
			}
	|	TOK_ID
			{
			(void) current_sequencer->LookupID( $1, GLOBAL_SCOPE, 1, 0, 1, 1 );
			$$ = null_stmt;
			}
	;


wider_list:	wider_list ',' wider_item
			{ $$ = merge_stmts( $1, $3 ); }
	|	wider_item
	;

wider_item:	TOK_ID TOK_ASSIGN scoped_expr
			{
			Expr* id =
				current_sequencer->LookupID( string_dup($1), ANY_SCOPE, 0, 0 );

			if ( ! id )
				{
				glish_warn->Report( "\"",$1,"\" ", "not found in 'wider', non-global scope; defaults to 'local'");
				id = current_sequencer->InstallID( $1, LOCAL_SCOPE, 0 );
				}
			else
				free_memory( $1 );

			Ref(id);
			$$ = new ExprStmt( compound_assignment( id, $2, $3 ) );

			if ( $2 != 0 )
				glish_warn->Report( "compound assignment in", $$ );
			}
	|	TOK_ID
			{
			Expr* id =
				current_sequencer->LookupID( string_dup($1), ANY_SCOPE, 0, 0 );

			if ( ! id )
				{
				glish_warn->Report( "\"",$1,"\" ", "not found in 'wider', non-global scope; defaults to 'local'");
				id = current_sequencer->InstallID( $1, LOCAL_SCOPE, 0 );
				}
			else
				free_memory( $1 );

			$$ = null_stmt;
			}
	;


block:		block_head statement_list '}'
			{
			int frame_size = current_sequencer->PopScope();

			$$ = new StmtBlock( frame_size, $2, current_sequencer );
			}
	;

block_head:	'{'
			{
			current_sequencer->PushScope();
			$$ = 0;
			}
	;

function:	function_head opt_id '(' formal_param_list ')' cont func_attributes cont func_body
		no_cont
			{
			IValue *attributes = $7 ? $7->CopyEval(*eval_options) : 0;
			Unref($7);

			back_offsets_type *back_refs = 0;
			int frame_size = current_sequencer->PopScope( &back_refs );
			IValue *err = 0;

			UserFunc* ufunc = new UserFunc( $4, $9, frame_size, back_refs,
							current_sequencer, $1, err,
							attributes);

			if ( ! err )
				{
				$$ = new FuncExpr( ufunc, attributes );

				if ( $2 )
					{
					if ( current_sequencer->GetScopeType() == GLOBAL_SCOPE )
						{ 
						// Create global reference to function.
						Expr* func =
							current_sequencer->LookupID(
							$2, LOCAL_SCOPE );

						IValue* ref = new IValue( ufunc );
						if ( attributes ) ref->AssignAttributes(copy_value(attributes));
						/* keep ufunc from being deleted with $$ */
						Ref(ufunc);

						if ( err = func->Assign( *eval_options, ref ) )
							{
							Unref( $$ );
							$$ = new ConstExpr( err );
							}
						}
					else
						{
						Expr *lhs = 
							current_sequencer->LookupID( $2, LOCAL_SCOPE);
						Ref(lhs);
						$$ = compound_assignment( lhs, 0, $$ );
						}
					}
				}
			else
				{
				$$ = new ValExpr( err );
				Ref(err);
				Unref( ufunc );
				}

			int tmplen;
			if ( $1 && (tmplen = glish_current_subsequence->length()) )
				glish_current_subsequence->remove_nth(tmplen-1);
			}
	;

function_head:	TOK_FUNCTION
			{
			current_sequencer->PushScope( FUNC_SCOPE );
			$$ = 0;
			}

	|	TOK_SUBSEQUENCE
			{
			current_sequencer->PushScope( FUNC_SCOPE );
			$$ = current_sequencer->InstallID( string_dup( "self" ), LOCAL_SCOPE );
			glish_current_subsequence->append($$);
			Ref($$);
			}
	;


func_attributes: ':' '[' { current_sequencer->StashScope(); } array_record_ctor_list ']'
			{
			$$ = new ConstructExpr( $4 );
			current_sequencer->RestoreScope();
			}
	|
			{ $$ = 0; }
	;

formal_param_list:
		formal_params
	|
			{ $$ = new parameter_list; }
	;

formal_params:	formal_params ',' formal_param
			{ $1->append( $3 ); }

	|	formal_param
			{
			$$ = new parameter_list;
			$$->append( $1 );
			}
	;

formal_param:	formal_param_class TOK_ID formal_param_default
			{
			Expr* id = current_sequencer->LookupID( string_dup($2), LOCAL_SCOPE, 0, 0 );
			if ( id )
				{
				yyerror("multiple parameters with same name");
				YYERROR;
				}

			Expr* param = current_sequencer->InstallID( $2, LOCAL_SCOPE );
			Ref(param);
			$$ = new FormalParameter( (const char *) $2, $1, param, 0, $3 );
			}

	|	TOK_ELLIPSIS formal_param_default
			{
			Expr* ellipsis = current_sequencer->LookupID(string_dup("..."), LOCAL_SCOPE, 1, 0 );

			Ref(ellipsis);
			$$ = new FormalParameter( VAL_CONST, ellipsis, 1, $2 );
			}
	;

formal_param_class:
		value_type
	|
			{ $$ = VAL_VAL; }
	;

formal_param_default:
		'=' scoped_expr
			{ $$ = $2; }
	|
			{ $$ = 0; }
	;

actual_param_list:
		actual_params
	|
			{ $$ = new parameter_list; }
	;

actual_params:	actual_params ',' actual_param
			{ $1->append( $3 ); }

	|	actual_param
			{
			$$ = new parameter_list;
			$$->append( $1 );
			}
	;

actual_param:	scoped_expr
			{ $$ = new ActualParameter( VAL_VAL, $1 ); }

	|	TOK_ID '=' scoped_expr
			{
			Ref( $3 );
			$$ = new ActualParameter( $1, VAL_VAL, $3, 0, $3 );
			}

	|	TOK_ELLIPSIS
			{
			Expr* ellipsis =
				current_sequencer->LookupID(
					string_dup( "..." ), LOCAL_SCOPE, 0 );

			if ( ! ellipsis )
				{
				glish_error->Report( "\"...\" not available" );
				IValue *v = error_ivalue();
				$$ = new ActualParameter( VAL_VAL,
					new ConstExpr( v ) );
				}

			else
				{
				Ref(ellipsis);
				$$ = new ActualParameter( VAL_VAL, ellipsis, 1 );
				}
			}
	;

array_record_ctor_list:
		array_record_params
	|
			{ $$ = new parameter_list; }
	;

array_record_params:	array_record_params ',' array_record_param
			{ $1->append( $3 ); }

	|	array_record_param
			{
			$$ = new parameter_list;
			$$->append( $1 );
			}
	;

array_record_param:	scoped_expr
			{ $$ = new ActualParameter( VAL_VAL, $1 ); }

	|	TOK_CONST TOK_ID '=' scoped_expr
			{
			Ref( $4 );
			$$ = new ActualParameter( $2, VAL_CONST, $4, 0, $4 );
			}

	|	TOK_ID '=' scoped_expr
			{
			Ref( $3 );
			$$ = new ActualParameter( $1, VAL_VAL, $3, 0, $3 );
			}

	|	TOK_ELLIPSIS
			{
			Expr* ellipsis =
				current_sequencer->LookupID(
					string_dup( "..." ), LOCAL_SCOPE, 0 );

			if ( ! ellipsis )
				{
				glish_error->Report( "\"...\" not available" ); 
				IValue *v = error_ivalue();
				$$ = new ActualParameter( VAL_VAL,
					new ConstExpr( v ) );
				}

			else
				{
				Ref(ellipsis);
				$$ = new ActualParameter( VAL_VAL, ellipsis, 1 );
				}
			}
	;

opt_actual_param_list:
		opt_actual_params
	|
			{ $$ = new parameter_list; }
	;

opt_actual_params:	opt_actual_params ',' opt_actual_param
			{ $1->append( $3 ); }
	|	opt_actual_params ','
			{
			$1->append( new ActualParameter() );
			}

	|	','
			{ // Something like "foo(,)" - two missing parameters.
			$$ = new parameter_list;
			$$->append( new ActualParameter() );
			$$->append( new ActualParameter() );
       			}

	|	',' opt_actual_param
			{
			$$ = new parameter_list;
			$$->append( new ActualParameter() );
			$$->append( $2 );
       			}

	|	opt_actual_param
			{
			$$ = new parameter_list;
			$$->append( $1 );
       			}
	;

opt_actual_param:	scoped_expr
			{ $$ = new ActualParameter( VAL_VAL, $1 ); }

	|	TOK_ID '=' scoped_expr
			{
			Ref( $3 );
			$$ = new ActualParameter( $1, VAL_VAL, $3, 0, $3 );
			}

	|	TOK_ELLIPSIS
			{
			Expr* ellipsis =
				current_sequencer->LookupID(
					string_dup( "..." ), LOCAL_SCOPE, 0 );

			if ( ! ellipsis )
				{
				glish_error->Report( "\"...\" not available" ); 
				IValue *v = error_ivalue();
				$$ = new ActualParameter( VAL_VAL,
					new ConstExpr( v ) );
				}

			else
				{
				Ref(ellipsis);
				$$ = new ActualParameter( VAL_VAL, ellipsis, 1 );
				}
			}
	;


subscript_list: subscript_list ',' subscript
			{ $1->append( $3 ); }
	|	subscript_list ','
			{ $1->append( 0 ); }
	|	','
			{
			$$ = new expr_list;
			$$->append( 0 );
			$$->append( 0 );
			}
	|	',' subscript
			{
			$$ = new expr_list;
			$$->append( 0 );
			$$->append( $2 );
			}
	|	subscript
			{
			$$ = new expr_list;
			$$->append( $1 );
			}
	;


subscript:	scoped_expr
	;


func_body:	'{' statement_list '}'
			{ $$ = $2; }

	|	expression			%prec ','
			{ $$ = new ExprStmt( $1->BuildFrameInfo( SCOPE_UNKNOWN ) ); }
	;


var:		TOK_ID
			{
			$$ = current_sequencer->LookupID( string_dup($1), LOCAL_SCOPE, 0 );

			if ( ! $$ )
				$$ = CreateVarExpr( $1, current_sequencer );
			else
				free_memory( $1 );

			Ref($$);
			}
	;

opt_id:		TOK_ID
	|
			{ $$ = 0; }
	;


event_list:	event_list ',' event
			{ $$->append( $3 ); }
	|	event
			{
			$$ = new event_dsg_list;
			$$->append( $1 );
			}
	;

event:	expression TOK_ARROW '[' expression ']'
			{
			$1 = $1->BuildFrameInfo( SCOPE_UNKNOWN );	/* necessary? */
			$4 = $4->BuildFrameInfo( SCOPE_UNKNOWN );	/* necessary? */
			$$ = new EventDesignator( $1, $4 );
			}
	|	expression TOK_ARROW TOK_ID
			{
			$1 = $1->BuildFrameInfo( SCOPE_UNKNOWN );	/* necessary? */
			$$ = new EventDesignator( $1, $3 );
			}
	|	expression TOK_ARROW '*' no_cont
			{
			$1 = $1->BuildFrameInfo( SCOPE_UNKNOWN );	/* necessary? */
			$$ = new EventDesignator( $1, (Expr*) 0 );
			}
	;


value_type:	TOK_REF
			{ $$ = VAL_REF; }
	|	TOK_CONST
			{ $$ = VAL_CONST; }
	|	TOK_VAL
			{ $$ = VAL_VAL; }
	;


cont:			{ clear_statement_can_end( ); }
	;

no_cont:		{ set_statement_can_end( ); }
	;

begin_literal_ids:
			{
			if ( begin_literal_ids( *lookahead == empty_token ? NULL_TOK : *lookahead ) )
				{
				yyclearin;
				}
			}
	;

end_literal_ids:
			{
			end_literal_ids();
			}
	;

%%

void error_reset( )
	{
	extern void scanner_reset( );
	scanner_reset( );

	current_sequencer->ClearWhenevers();

	if ( interactive( ) )
		while ( current_sequencer->ScopeDepth() > scope_depth )
			current_sequencer->PopScope();

	if ( in_evaluation( ) ) scan_strings( 0 );
	}

extern "C"
void yyerror( char msg[] )
	{
	if ( ! status && ! in_evaluation( ) )
		{
		if ( glish_regex_matched )
			{
			parse_error = (IValue*) ValCtor::error( msg, " at or near '", yytext,
					"'; a regular expression\n",
					"was matched in this statement, perhaps it is a mistaken arithmetic expression?" );
			glish_error->Report( msg, " at or near '", yytext, "'; a regular expression\n",
				       "was matched in this statement, perhaps it is a mistaken arithmetic expression?" );
			}
		else
			{
			parse_error = (IValue*) ValCtor::error( msg, " at or near '", yytext, "'" );
			glish_error->Report( msg, " at or near '", yytext, "'" );
			}
		}

	error_reset( );
	}


void clear_error()
	{
	status = 0;
	}

IValue *glish_parser( evalOpt &opt, Stmt *&stmt )
	{
	cur_stmt = stmt = null_stmt;
	eval_options = &opt;

	glish_error->SetCount(0);
	status = 0;

	if ( interactive( ) )
		scope_depth = current_sequencer->ScopeDepth();

	while ( ! yyparse() )
		{
		if ( ! interactive( ) )
			stmt = merge_stmts( stmt, cur_stmt );

		else
			{
			if ( status ) continue;
			Stmt *loc_stmt = cur_stmt;
			cur_stmt = null_stmt;

			IValue *val = 0;
			if ( setjmp(glish_top_jmpbuf) == 0 )
				{
				glish_top_jmpbuf_set = 1;
				opt.set(evalOpt::VALUE_NEEDED);
				val = loc_stmt->Exec( opt );
				if ( ! opt.Next() )
					glish_warn->Report("control flow (loop/break/return) ignored" );
				}

			glish_top_jmpbuf_set = 0;

			if ( current_sequencer->ErrorResult() && current_sequencer->ErrorResult()->Type() == TYPE_FAIL &&
			     ! current_sequencer->ErrorResult()->FailMarked() )
				{
				if ( Sequencer::CurSeq()->System().OLog() )
					Sequencer::CurSeq()->System().DoOLog(current_sequencer->ErrorResult());

				pager->Report( current_sequencer->ErrorResult() );
				current_sequencer->ClearErrorResult();
				}
			else if ( val )
				{
				pager->Report( val );
				Unref( val );
				}

			NodeUnref(loc_stmt);
			first_line = 1;
			scope_depth = current_sequencer->ScopeDepth();
			}
		}

	if ( ! status ) return 0;
	status = 0;
	IValue *tmp = parse_error;
	parse_error = 0;
	return tmp ? tmp : error_ivalue( "parse error" );
	}

Expr* compound_assignment( Expr* lhs, int tok_type, Expr* rhs )
	{
	switch ( tok_type )
		{
		case 0:	// ordinary :=
			return new AssignExpr( lhs, rhs );

#define CMPD(token, expr)						\
	case token:							\
		Ref(lhs);						\
		return new AssignExpr( lhs, new expr( lhs, rhs ) );

		CMPD('+', AddExpr);
		CMPD('-', SubtractExpr);
		CMPD('*', MultiplyExpr);
		CMPD('/', DivideExpr);
		CMPD('%', ModuloExpr);
		CMPD('^', PowerExpr);

		case '~':
			Ref(lhs);
			return new AssignExpr( lhs, new ApplyRegExpr( lhs, rhs, current_sequencer ) );

		CMPD('|', LogOrExpr);
		CMPD('&', LogAndExpr);

		CMPD(TOK_OR_OR, OrExpr);
		CMPD(TOK_AND_AND, AndExpr);

		default:
			glish_fatal->Report( "unknown compound assignment type =",
					     tok_type );
			return 0;
		}
	}

