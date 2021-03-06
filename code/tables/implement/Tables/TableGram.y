/*
    TableGram.y: Parser for table commands
    Copyright (C) 1994,1995,1997,1998,1999,2001,2002,2003
    Associated Universities, Inc. Washington DC, USA.

    This library is free software; you can redistribute it and/or modify it
    under the terms of the GNU Library General Public License as published by
    the Free Software Foundation; either version 2 of the License, or (at your
    option) any later version.

    This library is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
    License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; if not, write to the Free Software Foundation,
    Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.

    Correspondence concerning AIPS++ should be addressed as follows:
           Internet email: aips2-request@nrao.edu.
           Postal address: AIPS++ Project Office
                           National Radio Astronomy Observatory
                           520 Edgemont Road
                           Charlottesville, VA 22903-2475 USA

    $Id: TableGram.y,v 19.16 2006/05/12 10:03:07 gvandiep Exp $
*/

/*
 The grammar has 1 shift/reduce conflict which is resolved in a correct way.
*/


%{
using namespace casa;
%}

%pure_parser                /* make parser re-entrant */

%token SELECT
%token UPDATE
%token UPDSET
%token INSERT
%token VALUES
%token DELETE
%token CALC
%token CREATETAB
%token FROM
%token WHERE
%token GROUPBY
%token HAVING
%token ORDERBY
%token NODUPL
%token GIVING
%token INTO
%token SORTASC
%token SORTDESC
%token LIMIT
%token OFFSET
%token DMINFO
%token ALL                  /* ALL (in SELECT ALL) or name of function */
%token <val> NAME           /* name of function, field, table, or alias */
%token <val> FLDNAME        /* name of field or table */
%token <val> TABNAME        /* table name */
%token <val> LITERAL
%token <val> STRINGLITERAL
%token <val> REGEX
%token <val> PATTERN
%token AS
%token IN
%token INCONE
%token BETWEEN
%token EXISTS
%token LIKE
%token EQREGEX
%token NEREGEX
%token LPAREN
%token RPAREN
%token COMMA
%token LBRACKET
%token RBRACKET
%token LBRACE
%token RBRACE
%token COLON
%token OPENOPEN
%token OPENCLOSED
%token CLOSEDOPEN
%token CLOSEDCLOSED
%token OPENEMPTY
%token EMPTYOPEN
%token CLOSEDEMPTY
%token EMPTYCLOSED
%type <val> literal
%type <nodename> tabname
%type <nodename> stabname
%type <node> tabalias
%type <node> tfnamen
%type <node> tfname
%type <nodeselect> selcomm
%type <node> updcomm
%type <node> inscomm
%type <node> delcomm
%type <node> calccomm
%type <node> cretabcomm
%type <nodeselect> subquery
%type <nodeselect> selrow
%type <node> selcol
%type <nodelist> tables
%type <node> whexpr
%type <node> groupby
%type <nodelist> exprlist
%type <node> having
%type <node> order
%type <node> limitoff
%type <node> given
%type <node> into
%type <node> colexpr
%type <node> colspec
%type <nodelist> columns
%type <nodelist> acolumns
%type <nodelist> nmcolumns
%type <nodelist> colspecs
%type <node> updrow
%type <nodelist> updlist
%type <node> updexpr
%type <node> insrow
%type <nodelist> insclist
%type <node> inspart
%type <nodelist> insvlist
%type <node> orexpr
%type <node> andexpr
%type <node> relexpr
%type <node> arithexpr
%type <node> inxexpr
%type <node> simexpr
%type <node> set
%type <nodelist> singlerange
%type <nodelist> subscripts
%type <nodelist> elemlist
%type <nodelist> elems
%type <node> elem
%type <node> subsrange
%type <node> colonrange
%type <node> range
%type <node> sortexpr
%type <nodelist> sortlist
%type <nodelist> dminfo
%type <nodelist> reclist
%type <node> recelem
%type <nodelist> recexpr
%type <nodelist> recvalues
%type <node> recfield
%type <node> srecfield
%type <node> rrecfield

/* This defines the precedence order of the operators (low to high) */
%left OR
%left AND
%nonassoc EQ EQASS GT GE LT LE NE
%left PLUS MINUS
%left TIMES DIVIDE MODULO
%nonassoc UNARY
%nonassoc NOT
%right POWER

/* Alas you cannot use objects in a union, so pointers have to be used.
   This is causing problems in cleaning up in case of a parse error.
   Hence a vector (in TaQLNode) is used to keep track of the nodes created.
   They are deleted at the end of the parsing.
*/
%union {
TaQLConstNode* val;
TaQLNode* node;
TaQLConstNode* nodename;
TaQLMultiNode* nodelist;
TaQLSelectNode* nodeselect;
}

%{
namespace casa { //# NAMESPACE CASA - BEGIN
Bool theFromQueryDone;           /* for flex for knowing how to handle a , */
} //# NAMESPACE CASA - END
int TableGramlex (YYSTYPE*);
%}

%%
command:   selcomm
             { TaQLNode::theirNode = *$1; }
         | updcomm
             { TaQLNode::theirNode = *$1; }
         | inscomm
             { TaQLNode::theirNode = *$1; }
         | delcomm
             { TaQLNode::theirNode = *$1; }
         | calccomm
             { TaQLNode::theirNode = *$1; }
         | cretabcomm
             { TaQLNode::theirNode = *$1; }
         ;

subquery:  LPAREN selcomm RPAREN {
               $$ = $2;
	       $$->setBrackets();
	   }
         | LBRACKET selcomm RBRACKET {
               $$ = $2;
	       $$->setBrackets();
	   }
         ;

selcomm:   SELECT selrow {
               $$ = $2;
           }
         ;

selrow:    selcol FROM tables whexpr groupby having order limitoff given {
               $$ = new TaQLSelectNode(
                    new TaQLSelectNodeRep (*$1, *$3, 0, *$4, *$5, *$6,
					   *$7, *$8, *$9));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | selcol into FROM tables whexpr groupby having order limitoff {
               $$ = new TaQLSelectNode(
		    new TaQLSelectNodeRep (*$1, *$4, 0, *$5, *$6, *$7,
					   *$8, *$9, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;

selcol:    columns {
               $$ = new TaQLNode(
                    new TaQLColumnsNodeRep (False, *$1));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | TIMES {          /* SELECT * FROM ... */
               $$ = new TaQLNode(
                    new TaQLColumnsNodeRep (False, 0));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | ALL acolumns {
               $$ = new TaQLNode(
                    new TaQLColumnsNodeRep (False, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | NODUPL columns {
               $$ = new TaQLNode(
                    new TaQLColumnsNodeRep (True, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;

updcomm:   UPDATE updrow {
               $$ = $2;
           }
         ;

updrow:    tables UPDSET updlist FROM tables whexpr order limitoff {
               $$ = new TaQLNode(
                    new TaQLUpdateNodeRep (*$1, *$3, *$5, *$6, *$7, *$8));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | tables UPDSET updlist whexpr order limitoff {
               $$ = new TaQLNode(
		    new TaQLUpdateNodeRep (*$1, *$3, 0, *$4, *$5, *$6));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;

updlist:   updlist COMMA updexpr {
               $$ = $1;
               $$->add (*$3);
           }
         | updexpr {
	       $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
               $$->add (*$1);
           }
         ;

updexpr:   NAME EQASS orexpr {
	       $$ = new TaQLNode(
                    new TaQLUpdExprNodeRep ($1->getString(), 0, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | NAME LBRACKET subscripts RBRACKET EQASS orexpr {
	       $$ = new TaQLNode(
                    new TaQLUpdExprNodeRep ($1->getString(), *$3, *$6));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;

inscomm:   INSERT insrow {
               $$ = $2;
           }
         ;

insrow:    INTO tables insclist inspart {
	       $$ = new TaQLNode(
                    new TaQLInsertNodeRep (*$2, *$3, *$4));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;

insclist:  {         /* no column-list */   
               $$ = new TaQLMultiNode();
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | LBRACKET nmcolumns RBRACKET {
               $$ = $2;
           }
         | LPAREN nmcolumns RPAREN {
               $$ = $2;
           }
         ;

inspart:   VALUES LBRACKET insvlist RBRACKET {
               $$ = $3;
           }
         | VALUES LPAREN insvlist RPAREN {
               $$ = $3;
           }
         | selcomm {
	       $1->setNoExecute();
               $$ = $1;
	   }
         ;

insvlist:  insvlist COMMA orexpr {
               $$ = $1;
	       $$->add (*$3);
           }
         | orexpr {
               $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
	       $$->setPPFix ("VALUES [", "]");
	       $$->add (*$1);
           }
         ;

delcomm:   DELETE FROM tables whexpr order limitoff {
	       $$ = new TaQLNode(
                    new TaQLDeleteNodeRep (*$3, *$4, *$5, *$6));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;

calccomm:  CALC FROM tables CALC orexpr {
	       $$ = new TaQLNode(
                    new TaQLCalcNodeRep (*$3, *$5));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | CALC orexpr {
	       $$ = new TaQLNode(
                    new TaQLCalcNodeRep (0, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;
           
cretabcomm: CREATETAB tabname colspecs dminfo {
	       $$ = new TaQLNode(
                    new TaQLCreTabNodeRep ($2->getString(), *$3, *$4));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
          | CREATETAB tabname LPAREN colspecs RPAREN dminfo {
	       $$ = new TaQLNode(
                    new TaQLCreTabNodeRep ($2->getString(), *$4, *$6));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
          | CREATETAB tabname LBRACKET colspecs RBRACKET dminfo {
	       $$ = new TaQLNode(
                    new TaQLCreTabNodeRep ($2->getString(), *$4, *$6));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;

dminfo:    {      /* no datamans */
               $$ = new TaQLMultiNode();
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | DMINFO reclist {
               $$ = $2;
           }
         ;

groupby:   {          /* no groupby */
	       $$ = new TaQLNode();
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | GROUPBY exprlist {
	       $$ = $2;
	   }
         ;

exprlist:  exprlist COMMA orexpr {
               $$ = $1;
	       $$->add (*$3);
           }
         | orexpr {
               $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
	       $$->add (*$1);
           }
         ;

having:    {          /* no having */
	       $$ = new TaQLNode();
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | HAVING orexpr {
               $$ = $2;
	   }
         ;

order:     {          /* no sort */
	       $$ = new TaQLNode();
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | ORDERBY sortlist {
	       $$ = new TaQLNode(
	            new TaQLSortNodeRep (False, TaQLSortNodeRep::Ascending, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | ORDERBY SORTASC sortlist {
	       $$ = new TaQLNode(
	            new TaQLSortNodeRep (False, TaQLSortNodeRep::Ascending, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | ORDERBY SORTDESC sortlist {
	       $$ = new TaQLNode(
	            new TaQLSortNodeRep (False, TaQLSortNodeRep::Descending, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | ORDERBY NODUPL sortlist {
	       $$ = new TaQLNode(
	            new TaQLSortNodeRep (True, TaQLSortNodeRep::Ascending, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | ORDERBY NODUPL SORTASC sortlist {
	       $$ = new TaQLNode(
	            new TaQLSortNodeRep (True, TaQLSortNodeRep::Ascending, *$4));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | ORDERBY NODUPL SORTDESC sortlist {
	       $$ = new TaQLNode(
	            new TaQLSortNodeRep (True, TaQLSortNodeRep::Descending, *$4));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | ORDERBY SORTASC NODUPL sortlist {
	       $$ = new TaQLNode(
	            new TaQLSortNodeRep (True, TaQLSortNodeRep::Ascending, *$4));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | ORDERBY SORTDESC NODUPL sortlist {
	       $$ = new TaQLNode(
	            new TaQLSortNodeRep (True, TaQLSortNodeRep::Descending, *$4));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         ;

limitoff:  {         /* no limit,offset */
	       $$ = new TaQLNode();
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | LIMIT orexpr {
	       $$ = new TaQLNode(
	            new TaQLLimitOffNodeRep (*$2, 0));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | OFFSET orexpr {
	       $$ = new TaQLNode(
	            new TaQLLimitOffNodeRep (0, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | LIMIT orexpr OFFSET orexpr {
	       $$ = new TaQLNode(
	            new TaQLLimitOffNodeRep (*$2, *$4));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | OFFSET orexpr LIMIT orexpr {
	       $$ = new TaQLNode(
	            new TaQLLimitOffNodeRep (*$4, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         ;

given:     {          /* no result */
	       $$ = new TaQLNode();
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | GIVING tabname {
	       $$ = new TaQLNode(
                    new TaQLGivingNodeRep ($2->getString(), ""));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | GIVING tabname AS NAME {
	       $$ = new TaQLNode(
                    new TaQLGivingNodeRep ($2->getString(), $4->getString()));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | GIVING AS NAME {
	       $$ = new TaQLNode(
                    new TaQLGivingNodeRep ("", $3->getString()));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | GIVING LBRACKET elems RBRACKET {
	       $$ = new TaQLNode(
                    new TaQLGivingNodeRep (*$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         ;

into:      INTO tabname {
	       $$ = new TaQLNode(
                    new TaQLGivingNodeRep ($2->getString(), ""));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | INTO tabname AS NAME {
	       $$ = new TaQLNode(
                    new TaQLGivingNodeRep ($2->getString(), $4->getString()));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | INTO AS NAME {
	       $$ = new TaQLNode(
                    new TaQLGivingNodeRep ("", $3->getString()));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         ;

columns:   {          /* no column names given (thus take all) */
               $$ = new TaQLMultiNode();
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | colexpr {
               $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
               $$->add (*$1);
	   }
         | columns COMMA colexpr {
	       $$ = $1;
               $$->add (*$3);
	   }
         ;

/* If ALL is used in column list, the first column must be a name.
   Otherwise there is an ambiguity in e.g. ALL(COL)
   It can be function ALL with argument COL
   or it can be the SELECT qualifier ALL with orexpr (COL).
*/
acolumns:  NAME {
               $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
               TaQLNode p (new TaQLKeyColNodeRep ($1->getString()));
               $$->add (new TaQLColNodeRep (p, "", ""));
	   }
         | NAME AS NAME {
               $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
               TaQLNode p (new TaQLKeyColNodeRep ($1->getString()));
               $$->add (new TaQLColNodeRep (p, $3->getString(), ""));
	   }
         | NAME AS NAME NAME {
               $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
               TaQLNode p (new TaQLKeyColNodeRep ($1->getString()));
               $$->add (new TaQLColNodeRep (p, $3->getString(), $4->getString()));
	   }
         | acolumns COMMA colexpr {
	       $$ = $1;
               $$->add (*$3);
	   }
         ;

colexpr:   orexpr {
	       $$ = new TaQLNode(
	            new TaQLColNodeRep (*$1, "", ""));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | orexpr AS NAME {
	       $$ = new TaQLNode(
	            new TaQLColNodeRep (*$1, $3->getString(), ""));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | orexpr AS NAME NAME {
	       $$ = new TaQLNode(
	            new TaQLColNodeRep (*$1, $3->getString(), $4->getString()));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;

nmcolumns: NAME {
               $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
               $$->add (new TaQLKeyColNodeRep ($1->getString()));
	   }
         | nmcolumns COMMA NAME {
	       $$ = $1;
               $$->add (new TaQLKeyColNodeRep ($3->getString()));
	   }
         ;

colspecs:  {          /* no column specifications given */
               $$ = new TaQLMultiNode();
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | colspec {
               $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
               $$->add (*$1);
	   }
         | colspecs COMMA colspec {
	       $$ = $1;
               $$->add (*$3);
	   }
         ;

colspec:   NAME NAME {
	       $$ = new TaQLNode(
		    new TaQLColSpecNodeRep($1->getString(), $2->getString(),
		                           TaQLMultiNode()));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | NAME NAME srecfield {	
               TaQLMultiNode re(False);
	       re.add (*$3);
	       $$ = new TaQLNode(
                    new TaQLColSpecNodeRep($1->getString(), $2->getString(),
		                           re));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | NAME NAME LBRACKET recexpr RBRACKET {
	       $$ = new TaQLNode(
                    new TaQLColSpecNodeRep($1->getString(), $2->getString(),
		                           *$4));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         ;

tables:    tabalias {
               $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
               $$->add (*$1);
	   }
         | tables COMMA tabalias {
	       $$ = $1;
               $$->add (*$3);
	   }
         ;

/* If NAME is given, it is purely alphanumeric, so it can be used as alias.
   This is not the case if another type of name is given, so in that case
   there is no alias.
   Hence the 2 cases have to be handled differently.
*/
tabalias:  NAME {                          /* table name is also alias */
	       $1->setIsTableName();
	       $$ = new TaQLNode(
                    new TaQLTableNodeRep(*$1, $1->getString()));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | tfname {                        /* no alias */
	       $$ = new TaQLNode(
	            new TaQLTableNodeRep(*$1, ""));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | tfnamen NAME {
	       $2->setIsTableName();
	       $$ = new TaQLNode(
	            new TaQLTableNodeRep(*$1, $2->getString()));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | tfnamen AS NAME {
	       $$ = new TaQLNode(
	            new TaQLTableNodeRep(*$1, $3->getString()));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | NAME IN tfnamen {
	       $$ = new TaQLNode(
	            new TaQLTableNodeRep(*$3, $1->getString()));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;

tfnamen:   tfname {
               $$ = $1;
           }
         | NAME {
	       $1->setIsTableName();
               $$ = $1;
           }
         ;

tfname:    subquery {
	       theFromQueryDone = True;
	       $1->setFromExecute();
               $$ = $1;
           }
         | stabname {
	       $$ = $1;
           }
         ;

stabname:  TABNAME {
	       $1->setIsTableName();
               $$ = $1;
           }
         | FLDNAME {
	       $1->setIsTableName();
               $$ = $1;
           }
         | STRINGLITERAL {
	       $1->setIsTableName();
               $$ = $1;
           }
         ;

tabname:   NAME {
	       $1->setIsTableName();
               $$ = $1;
           }
         | stabname {
               $$ = $1;
           }
         ;

whexpr:    {                   /* no selection */
	       $$ = new TaQLNode();
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | WHERE orexpr {
	       $$ = $2;
	   }
	 ;

orexpr:    andexpr {
	       $$ = $1;
           }
	 | orexpr OR andexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_OR, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         ;

andexpr:   relexpr {
	       $$ = $1;
           }
         | andexpr AND relexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_AND, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         ;

relexpr:   arithexpr {
	       $$ = $1;
           }
         | arithexpr EQ arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_EQ, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr EQASS arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_EQ, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr GT arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_GT, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr GE arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_GE, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr LT arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_LT, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr LE arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_LE, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr NE arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_NE, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr EQREGEX REGEX {
	       TaQLMultiNode re(False);
               re.add (*$3);
               TaQLNode ref (new TaQLFuncNodeRep("REGEX", re));
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_EQ, *$1, ref));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr NEREGEX REGEX {
   	       TaQLMultiNode re(False);
               re.add (*$3);
               TaQLNode ref (new TaQLFuncNodeRep("REGEX", re));
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_NE, *$1, ref));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr EQREGEX PATTERN {
   	       TaQLMultiNode re(False);
               re.add (*$3);
               TaQLNode ref (new TaQLFuncNodeRep("PATTERN", re));
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_EQ, *$1, ref));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr NEREGEX PATTERN {
   	       TaQLMultiNode re(False);
               re.add (*$3);
               TaQLNode ref (new TaQLFuncNodeRep("PATTERN", re));
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_NE, *$1, ref));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr LIKE arithexpr {
   	       TaQLMultiNode re(False);
               re.add (*$3);
               TaQLNode ref (new TaQLFuncNodeRep("SQLPATTERN", re));
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_EQ, *$1, ref));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr NOT LIKE arithexpr {
   	       TaQLMultiNode re(False);
               re.add (*$4);
               TaQLNode ref (new TaQLFuncNodeRep("SQLPATTERN", re));
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_NE, *$1, ref));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | EXISTS subquery {
	       $2->setNoExecute();
	       $$ = new TaQLNode(
	            new TaQLUnaryNodeRep (TaQLUnaryNodeRep::U_EXISTS, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
	    }
         | NOT EXISTS subquery {
	       $3->setNoExecute();
	       $$ = new TaQLNode(
	            new TaQLUnaryNodeRep (TaQLUnaryNodeRep::U_NOTEXISTS, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
            }
         | arithexpr IN arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_IN, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | arithexpr NOT IN arithexpr {
	       TaQLNode p(
                    new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_IN, *$1, *$4));
	       $$ = new TaQLNode(
                    new TaQLUnaryNodeRep (TaQLUnaryNodeRep::U_NOT, p));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | arithexpr IN singlerange {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_IN, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | arithexpr NOT IN singlerange {
	       TaQLNode p (new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_IN, *$1, *$4));
	       $$ = new TaQLNode(
                    new TaQLUnaryNodeRep (TaQLUnaryNodeRep::U_NOT, p));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | arithexpr BETWEEN arithexpr AND arithexpr {
	       TaQLMultiNode pr(False);
	       pr.add (new TaQLRangeNodeRep (True, *$3, *$5, True));
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_IN, *$1, pr));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | arithexpr NOT BETWEEN arithexpr AND arithexpr {
	       TaQLMultiNode pr(False);
	       pr.add (new TaQLRangeNodeRep (True, *$4, *$6, True));
	       TaQLNode p (new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_IN, *$1, pr));
	       $$ = new TaQLNode(
                    new TaQLUnaryNodeRep (TaQLUnaryNodeRep::U_NOT, p));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | arithexpr INCONE arithexpr {
	       TaQLMultiNode pr(False);
	       pr.add (*$1);
	       pr.add (*$3);
	       $$ = new TaQLNode(
                    new TaQLFuncNodeRep ("anyCone", pr));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | arithexpr NOT INCONE arithexpr {
	       TaQLMultiNode pr(False);
	       pr.add (*$1);
	       pr.add (*$4);
               TaQLNode p (new TaQLFuncNodeRep ("anyCone", pr));
	       $$ = new TaQLNode(
                    new TaQLUnaryNodeRep (TaQLUnaryNodeRep::U_NOT, p));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;

arithexpr: inxexpr {
	       $$= $1;
           }
         | arithexpr PLUS  arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_PLUS, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr MINUS arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_MINUS, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr TIMES  arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_TIMES, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr DIVIDE arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_DIVIDE, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr MODULO arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_MODULO, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | MINUS arithexpr %prec UNARY {
	       $$ = new TaQLNode(
	            new TaQLUnaryNodeRep (TaQLUnaryNodeRep::U_MINUS, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | PLUS  arithexpr %prec UNARY
               { $$ = $2; }
         | NOT   arithexpr {
	       $$ = new TaQLNode(
	            new TaQLUnaryNodeRep (TaQLUnaryNodeRep::U_NOT, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | arithexpr POWER arithexpr {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_POWER, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         ;

inxexpr:   simexpr {
               $$ = $1;
           }
         | simexpr LBRACKET subscripts RBRACKET {
	       $$ = new TaQLNode(
	            new TaQLBinaryNodeRep (TaQLBinaryNodeRep::B_INDEX, *$1, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         ;

simexpr:   LPAREN orexpr RPAREN
               { $$ = $2; }
         | NAME LPAREN elemlist RPAREN {
	       $$ = new TaQLNode(
                    new TaQLFuncNodeRep ($1->getString(), *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | ALL LPAREN elemlist RPAREN {
	       $$ = new TaQLNode(
                    new TaQLFuncNodeRep ("ALL", *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | NAME {
	       $$ = new TaQLNode(
                    new TaQLKeyColNodeRep ($1->getString()));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | FLDNAME {
	       $$ = new TaQLNode(
                    new TaQLKeyColNodeRep ($1->getString()));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         | literal {
	       $$ = $1;
	   }
         | set {
	       $$ = $1;
	   }
         ;

literal:   LITERAL {
	       $$ = $1;
	   }
         | STRINGLITERAL {
	       $$ = $1;
	   }
         ;

set:       LBRACKET elems RBRACKET {
               $2->setIsSetOrArray();
               $$ = $2;
           }
         | LPAREN elems RPAREN {
               $2->setIsSetOrArray();
               $$ = $2;
           }
         | subquery {
               $$ = $1;
           }
         ;

elemlist:  elems {
               $$ = $1;
	       $$->setPPFix("", "");
           }
         | {
               $$ = new TaQLMultiNode(False);       /* no elements */
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;

elems:     elems COMMA elem {
               $$ = $1;
	       $$->add (*$3);
	   }
         | elem {
	       $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
	       $$->setPPFix ("[", "]");
	       $$->add (*$1);
	   }
         ;

elem:      orexpr {
               $$ = $1;
	   }
         | range {
               $$ = $1;
           }
         ;

singlerange: range {
	       $$ = new TaQLMultiNode(True);
	       TaQLNode::theirNodesCreated.push_back ($$);
	       $$->add (*$1);
           }
         ;

range:     colonrange {
               $$ = $1;
           }
         | LT arithexpr COMMA arithexpr GT {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (False, *$2, *$4, False));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | LT arithexpr COMMA arithexpr RBRACE {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (False, *$2, *$4, True));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | LBRACE arithexpr COMMA arithexpr GT {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (True, *$2, *$4, False));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | LBRACE arithexpr COMMA arithexpr RBRACE {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (True, *$2, *$4, True));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | LBRACE COMMA arithexpr GT {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (*$3, False));
	       TaQLNode::theirNodesCreated.push_back ($$);
          }
         | LT COMMA arithexpr GT {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (*$3, False));
	       TaQLNode::theirNodesCreated.push_back ($$);
          }
         | LBRACE COMMA arithexpr RBRACE {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (*$3, True));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | LT COMMA arithexpr RBRACE {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (*$3, True));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | LT arithexpr COMMA RBRACE {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (False, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | LT arithexpr COMMA GT {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (False, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | LBRACE arithexpr COMMA RBRACE {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (True, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | LBRACE arithexpr COMMA GT {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (True, *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | arithexpr OPENOPEN arithexpr {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (False, *$1, *$3, False));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | arithexpr OPENCLOSED arithexpr {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (False, *$1, *$3, True));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | arithexpr CLOSEDOPEN arithexpr {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (True, *$1, *$3, False));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | arithexpr CLOSEDCLOSED arithexpr {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (True, *$1, *$3, True));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
	 | EMPTYOPEN arithexpr {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (*$2, False));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
	 | EMPTYCLOSED arithexpr {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (*$2, True));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
	 | arithexpr OPENEMPTY {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (False, *$1));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
	 | arithexpr CLOSEDEMPTY {
	       $$ = new TaQLNode(
                    new TaQLRangeNodeRep (True, *$1));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;

subscripts: subscripts COMMA subsrange {
               $$ = $1;
	       $$->add (*$3);
	   }
         | subscripts COMMA {
               $$ = $1;
	       $$->add (new TaQLIndexNodeRep(0, 0, 0));
	   }
         | COMMA {
	       $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
	       $$->setPPFix ("[", "]");
	       $$->add (new TaQLIndexNodeRep(0, 0, 0));
	       $$->add (new TaQLIndexNodeRep(0, 0, 0));
	   }
         | COMMA subsrange {
	       $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
	       $$->setPPFix ("[", "]");
	       $$->add (new TaQLIndexNodeRep(0, 0, 0));
	       $$->add (*$2);
	   }
         | subsrange {
	       $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
	       $$->setPPFix ("[", "]");
	       $$->add (*$1);
	   }
         ;

subsrange: arithexpr {
	       $$ = new TaQLNode(
                    new TaQLIndexNodeRep (*$1, 0, 0));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | colonrange {
               $$ = $1;
	   }
         ;

colonrange: arithexpr COLON arithexpr {
	       $$ = new TaQLNode(
                    new TaQLIndexNodeRep (*$1, *$3, 0));
	       TaQLNode::theirNodesCreated.push_back ($$);
            }
         |  arithexpr COLON arithexpr COLON arithexpr {
	       $$ = new TaQLNode(
                    new TaQLIndexNodeRep (*$1, *$3, *$5));
	       TaQLNode::theirNodesCreated.push_back ($$);
            }
         |  arithexpr COLON {
	       $$ = new TaQLNode(
                    new TaQLIndexNodeRep (*$1, 0, 0));
	       TaQLNode::theirNodesCreated.push_back ($$);
            }
         |  arithexpr COLON COLON arithexpr {
	       $$ = new TaQLNode(
                    new TaQLIndexNodeRep (*$1, 0, *$4));
	       TaQLNode::theirNodesCreated.push_back ($$);
            }
         |  COLON arithexpr {
	       $$ = new TaQLNode(
                    new TaQLIndexNodeRep (0, *$2, 0));
	       TaQLNode::theirNodesCreated.push_back ($$);
            }
         |  COLON arithexpr COLON arithexpr {
	       $$ = new TaQLNode(
                    new TaQLIndexNodeRep (0, *$2, *$4));
	       TaQLNode::theirNodesCreated.push_back ($$);
            }
         |  COLON COLON arithexpr {
	       $$ = new TaQLNode(
                    new TaQLIndexNodeRep (0, 0, *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
            }
         ;

sortlist : sortlist COMMA sortexpr {
               $$ = $1;
               $$->add (*$3);
	   }
         | sortexpr {
	       $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
               $$->add (*$1);
	   }
         ;

sortexpr : orexpr {
	       $$ = new TaQLNode(
                    new TaQLSortKeyNodeRep (TaQLSortKeyNodeRep::None, *$1));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | orexpr SORTASC {
	       $$ = new TaQLNode(
                    new TaQLSortKeyNodeRep (TaQLSortKeyNodeRep::Ascending, *$1));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         | orexpr SORTDESC {
	       $$ = new TaQLNode(
                    new TaQLSortKeyNodeRep (TaQLSortKeyNodeRep::Descending, *$1));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
         ;

reclist:  recelem {
               $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
               $$->add (*$1);
	   }
         | reclist COMMA recelem {
	       $$ = $1;
               $$->add (*$3);
	   }
         ;
           
recelem:   LBRACKET recexpr RBRACKET {
	       $$ = new TaQLNode(
                    new TaQLRecFldNodeRep ("", *$2));
	       TaQLNode::theirNodesCreated.push_back ($$);
	   }
         ;
           
recexpr:   recexpr COMMA recfield {
               $$->add (*$3);
	   }
       |   recfield {
	       $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
	       $$->setPPFix ("[", "]");
               $$->add (*$1);
	   }
       ;

recfield:  srecfield {
               $$ = $1;
           }
       |   rrecfield {
               $$ = $1;
           }
       |   NAME EQASS LBRACKET EQASS RBRACKET {
	       /* Like in glish [=] is the syntax for an empty 'record' */
	       $$ = new TaQLNode(
                    new TaQLRecFldNodeRep ($1->getString(), TaQLNode()));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
       ;

srecfield: NAME EQASS literal {
	       $$ = new TaQLNode(
                    new TaQLRecFldNodeRep ($1->getString(), *$3));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
       |   NAME EQASS LBRACKET recvalues RBRACKET {
	       $$ = new TaQLNode(
                    new TaQLRecFldNodeRep ($1->getString(), *$4));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
       ;

rrecfield: NAME EQASS LBRACKET recexpr RBRACKET {
	       $$ = new TaQLNode(
                    new TaQLRecFldNodeRep ($1->getString(), *$4));
	       TaQLNode::theirNodesCreated.push_back ($$);
           }
       ;

recvalues: recvalues COMMA literal {
               $$->add (*$3);
	   }
       |   literal {
	       $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
	       $$->setPPFix ("[", "]");
               $$->add (*$1);
	   }
       |   {      /* empty vector */
	       $$ = new TaQLMultiNode(False);
	       TaQLNode::theirNodesCreated.push_back ($$);
	       $$->setPPFix ("[", "]");
           }
       ;
%%
