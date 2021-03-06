/*
    TableGram.l: Lexical analyzer for table commands
    Copyright (C) 1994,1995,1996,1997,1998,2001,2003
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

    $Id: TableGram.l,v 19.14 2006/05/16 09:08:13 gvandiep Exp $
*/

%{
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) result=tableGramInput(buf,max_size)

#undef YY_DECL
#define YY_DECL int TableGramlex (YYSTYPE* lvalp)
%}

/* states */
%s EXPRstate
%s GIVINGstate
%s FROMstate
%s REGEXstate

/* The order in the following list is important, since, for example,
   the word "giving" must be recognized as GIVING and not as NAME.
   Similarly, an alphanumeric string must be recognized as NAME
   and not as NAMETAB or NAMEFLD.
   Complex values can be given as:   FLOATi
          where i is the letter i (in lowercase only).
   In a NAME the backslash can be used to escape special characters like -.
   In that way a name like DATE-OBS can be given as DATE\-OBS.
*/
WHITE1    [ \t\n]
WHITE     {WHITE1}*
DIGIT     [0-9]
INT       {DIGIT}+
EXP       [DdEe][+-]?{INT}
FLOAT     {INT}{EXP}|{INT}"."{DIGIT}*({EXP})?|{DIGIT}*"."{INT}({EXP})?
FLINT     {FLOAT}|{INT}
COMPLEX   {FLINT}"i"
TRUE      T
FALSE     F

MONTH     ("-"{INT}?"-")|("-"?[A-Za-z]+"-"?)
DATEH     {INT}{MONTH}{INT}
DATES     {INT}"/"{INT}?"/"{INT}
DATE      {DATEH}|{DATES}
DTIMEHM   {INT}[hH]({INT}?([mM]({FLINT})?)?)?
DTIMEC    {INT}":"({INT}?(":"({FLINT})?)?)?
DTIME     {DTIMEHM}|{DTIMEC}
DATETIME  {DATE}([-/]{DTIME})?
TIMESL    "/"{DTIME}

TIMEU     {FLINT}[a-zA-Z]+
POSDM     {INT}[dD]({INT}?([mM]({FLINT})?)?)?
POSD      {INT}"."{INT}?"."{FLINT}?
TIME      {DTIMEHM}|{TIMEU}|{POSDM}|{POSD}
/*
     positions with colons cannot be allowed, because they interfere
     with the interval syntax (and a starting slash is rather ambiguous).
TIME      {DTIMEHM}|{TIMESL}|{TIMEU}|{POSDM}|{POSD}
*/

QSTRING   \"[^\"\n]*\"
ASTRING   \'[^\'\n]*\'
UQSTRING   \"[^\"\n]*\n
UASTRING   \'[^\'\n]*\n
STRING    ({QSTRING}|{ASTRING})+
USTRING   ({UQSTRING}|{UASTRING})+
UNION     [Uu][Nn][Ii][Oo][Nn]
INTERSECT [Ii][Nn][Tt][Ee][Rr][Ss][Ee][Cc][Tt]
EXCEPT    ([Ee][Xx][Cc][Ee][Pp][Tt])|([Mm][Ii][Nn][Uu][Ss])
SELECT    [Ss][Ee][Ll][Ee][Cc][Tt]
UPDATE    [Uu][Pp][Dd][Aa][Tt][Ee]
INSERT    [Ii][Nn][Ss][Ee][Rr][Tt]
DELETE    [Dd][Ee][Ll][Ee][Tt][Ee]
CALC      [Cc][Aa][Ll][Cc]
CREATETAB [Cc][Rr][Ee][Aa][Tt][Ee]{WHITE}[Tt][Aa][Bb][Ll][Ee]
DMINFO    [Dd][Mm][Ii][Nn][Ff][Oo]
SET       [Ss][Ee][Tt]
VALUES    [Vv][Aa][Ll][Uu][Ee][Ss]
FROM      [Ff][Rr][Oo][Mm]
WHERE     [Ww][Hh][Ee][Rr][Ee]
ORDERBY   [Oo][Rr][Dd][Ee][Rr]{WHITE}[Bb][Yy]{WHITE1}
NODUPL1   [Nn][Oo][Dd][Uu][Pp][Ll][Ii][Cc][Aa][Tt][Ee][Ss] 
DISTINCT  [Dd][Ii][Ss][Tt][Ii][Nn][Cc][Tt]
UNIQUE    [Uu][Nn][Ii][Qq][Uu][Ee]
NODUPL    {NODUPL1}|{DISTINCT}|{UNIQUE}
GIVING1   [Gg][Ii][Vv][Ii][Nn][Gg]
SAVETO    [Ss][Aa][Vv][Ee]{WHITE}[Tt][Oo]{WHITE1}
GIVING    {GIVING1}|{SAVETO}
INTO      [Ii][Nn][Tt][Oo]
GROUPBY   [Gg][Rr][Oo][Uu][Pp]{WHITE}[Bb][Yy]{WHITE1}
HAVING    [Hh][Aa][Vv][Ii][Nn][Gg]
ASC       [Aa][Ss][Cc]
DESC      [Dd][Ee][Ss][Cc]
LIMIT     [Ll][Ii][Mm][Ii][Tt]
OFFSET    [Oo][Ff][Ff][Ss][Ee][Tt]
BETWEEN   [Bb][Ee][Tt][Ww][Ee][Ee][Nn]
EXISTS    [Ee][Xx][Ii][Ss][Tt][Ss]
LIKE      [Ll][Ii][Kk][Ee]
IN        [Ii][Nn]
INCONE    [Ii][Nn]{WHITE}[Cc][Oo][Nn][Ee]{WHITE1}
AS        [Aa][Ss]
AND       [Aa][Nn][Dd]
OR        [Oo][Rr]
NOT       [Nn][Oo][Tt]
ALL       [Aa][Ll][Ll]
NAME      \\?[A-Za-z_]([A-Za-z_0-9]|(\\.))*
NAMEFLD   {NAME}?"."?{NAME}?("::")?{NAME}("."{NAME})*
TEMPTAB   [$]{INT}
NAMETAB   ([A-Za-z0-9_./+\-~$]|(\\.))+
REGEX1    m"/"[^/]+"/"
REGEX2    m%[^%]+%
REGEX3    m#[^#]+#
REGEX     {REGEX1}|{REGEX2}|{REGEX3}
PATT1     p\/[^/]+\/
PATT2     p%[^%]+%
PATT3     p#[^#]+#
PATT      {PATT1}|{PATT2}|{PATT3}

%%
 /* The command to be analyzed is:
        SELECT column-list FROM table-list WHERE expression
                          ORDER BY column-list GIVING table
    The WHERE, ORDER BY, and GIVING parts are optional.
    Elements in a list are separated by commas.
    A table-name can be only a table file name or a table file name
    followed by whitespace and an alphanumeric name. That 2nd name
    serves as a shorthand for possible later use in the field name.
    A table name can be given in the FROM part and in the giving PART.
    These are indicated by the FROM/GIVINGstate, because a table name
    can contain special characters like -. In the FROMstate a table name
    can also be $nnn indicating a temporary table.
    In a subquery care must be taken that the state is switched back to
    EXPRstate, because a FROM can be the last part in a subquery and
    because a set can be specified in the GIVING part.
    This is done by setting the state when parentheses or square brackets
    are found. ( and [ indicate the beginning of a set(subquery).
    ) and ] indicate the end of subquery.
 */
{UNION}  {
            tableGramPosition() += yyleng;
            throw (TableInvExpr ("UNION is not supported yet"));
	  }
{INTERSECT}  {
            tableGramPosition() += yyleng;
            throw (TableInvExpr ("INTERSECT is not supported yet"));
	  }
{EXCEPT}  {
            tableGramPosition() += yyleng;
            throw (TableInvExpr ("EXCEPT/MINUS is not supported yet"));
	  }
{SELECT}  {
            tableGramPosition() += yyleng;
	    BEGIN(EXPRstate);
	    return SELECT;
	  }
{UPDATE}  {
            tableGramPosition() += yyleng;
	    BEGIN(FROMstate);
	    return UPDATE;
	  }
{SET}  {
            tableGramPosition() += yyleng;
	    BEGIN(EXPRstate);
	    return UPDSET;
	  }
{INSERT}  {
            tableGramPosition() += yyleng;
	    BEGIN(FROMstate);
	    return INSERT;
	  }
{VALUES}  {
            tableGramPosition() += yyleng;
	    BEGIN(EXPRstate);
	    return VALUES;
          }
{DELETE}  {
            tableGramPosition() += yyleng;
	    return DELETE;
	  }
{CALC}  {
            tableGramPosition() += yyleng;
	    BEGIN(EXPRstate);
	    return CALC;
	  }
{CREATETAB} {
            tableGramPosition() += yyleng;
	    return CREATETAB;
	  }
{DMINFO}  {
            tableGramPosition() += yyleng;
	    return DMINFO;
	  }
{FROM}    {
            tableGramPosition() += yyleng;
	    BEGIN(FROMstate);
	    return FROM;
	  }
{WHERE}   {
            tableGramPosition() += yyleng;
	    BEGIN(EXPRstate);
            theFromQueryDone = False;
	    return WHERE;
	  }
{ORDERBY} {
            tableGramPosition() += yyleng;
	    BEGIN(EXPRstate);
	    return ORDERBY;
          }
{NODUPL}  {
            tableGramPosition() += yyleng;
	    return NODUPL;
          }
{DESC}    {
            tableGramPosition() += yyleng;
	    return SORTDESC;
          }
{ASC}     {
            tableGramPosition() += yyleng;
	    return SORTASC;
          }
{GIVING}  {
            tableGramPosition() += yyleng;
	    BEGIN(GIVINGstate);
	    return GIVING;
          }
{INTO}    {
            tableGramPosition() += yyleng;
	    return INTO;
          }
{LIMIT}   {
            tableGramPosition() += yyleng;
	    BEGIN(EXPRstate);
	    return LIMIT;
          }
{OFFSET}  {
            tableGramPosition() += yyleng;
	    BEGIN(EXPRstate);
	    return OFFSET;
          }
{GROUPBY} {
            tableGramPosition() += yyleng;
            throw (TableInvExpr ("GROUPBY is not supported yet"));
          }
{HAVING}  {
            tableGramPosition() += yyleng;
            throw (TableInvExpr ("HAVING is not supported yet"));
          }

{AS}      {
            tableGramPosition() += yyleng;
            return AS;
          }
{IN}      {
            tableGramPosition() += yyleng;
            return IN;
          }
{INCONE}  {
            tableGramPosition() += yyleng;
            return INCONE;
          }
"["       {
            tableGramPosition() += yyleng;
            BEGIN(EXPRstate);
            return LBRACKET;
          }
"("       {
            tableGramPosition() += yyleng;
            BEGIN(EXPRstate);
            return LPAREN;
          }
"]"       {
            tableGramPosition() += yyleng;
            BEGIN(EXPRstate);
            return RBRACKET;
          }
")"       {
            tableGramPosition() += yyleng;
            BEGIN(EXPRstate);
            return RPAREN;
          }

"<:<"     { tableGramPosition() += yyleng; return OPENOPEN; }
"<:="     { tableGramPosition() += yyleng; return OPENCLOSED; }
"=:<"     { tableGramPosition() += yyleng; return CLOSEDOPEN; }
"=:="     { tableGramPosition() += yyleng; return CLOSEDCLOSED; }
"<:"      { tableGramPosition() += yyleng; return OPENEMPTY; }
":<"      { tableGramPosition() += yyleng; return EMPTYOPEN; }
"=:"      { tableGramPosition() += yyleng; return CLOSEDEMPTY; }
":="      { tableGramPosition() += yyleng; return EMPTYCLOSED; }
":"       { tableGramPosition() += yyleng; return COLON; }
"=="      { tableGramPosition() += yyleng; return EQ; }
"="       { tableGramPosition() += yyleng; return EQASS; }
"!="      { tableGramPosition() += yyleng; return NE; }
"<>"      { tableGramPosition() += yyleng; return NE; }
">="      { tableGramPosition() += yyleng; return GE; }
">"       { tableGramPosition() += yyleng; return GT; }
"<="      { tableGramPosition() += yyleng; return LE; }
"<"       { tableGramPosition() += yyleng; return LT; }
{BETWEEN} { tableGramPosition() += yyleng; return BETWEEN; }
{EXISTS}  { tableGramPosition() += yyleng; return EXISTS; }
{LIKE}    { tableGramPosition() += yyleng; return LIKE; }
"&&"      { tableGramPosition() += yyleng; return AND; }
{AND}     { tableGramPosition() += yyleng; return AND; }
"||"      { tableGramPosition() += yyleng; return OR; }
{OR}      { tableGramPosition() += yyleng; return OR; }
"!"       { tableGramPosition() += yyleng; return NOT; }
{NOT}     { tableGramPosition() += yyleng; return NOT; }
"^"       { tableGramPosition() += yyleng; return POWER; }
"*"       { tableGramPosition() += yyleng; return TIMES; }
"/"       { tableGramPosition() += yyleng; return DIVIDE; }
"%"       { tableGramPosition() += yyleng; return MODULO; }
"+"       { tableGramPosition() += yyleng; return PLUS; }
"-"       { tableGramPosition() += yyleng; return MINUS; }
"{"       { tableGramPosition() += yyleng; return LBRACE; }
"}"       { tableGramPosition() += yyleng; return RBRACE; }
","       {
            tableGramPosition() += yyleng;
            if (theFromQueryDone) {
              BEGIN(FROMstate);
              theFromQueryDone=False;
            }
            return COMMA;
          }


 /* Literals */
{COMPLEX} {
            tableGramPosition() += yyleng;
            double v;
	    sscanf (TableGramtext, "%lf%*c", &v);
            lvalp->val = new TaQLConstNode(
                new TaQLConstNodeRep (DComplex(0, v)));
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
	    return LITERAL;
	  }
{FLOAT}   {
            tableGramPosition() += yyleng;
	    double v = atof(TableGramtext);
            lvalp->val = new TaQLConstNode(
                new TaQLConstNodeRep (v));
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
	    return LITERAL;
	  }
{INT}     {
            tableGramPosition() += yyleng;
            int ival = atoi(TableGramtext);
            double dval = atof(TableGramtext);
            if (ival < dval-0.1  ||  ival > dval+0.1) {
                lvalp->val = new TaQLConstNode(new TaQLConstNodeRep (dval));
            } else {
                lvalp->val = new TaQLConstNode(new TaQLConstNodeRep (ival));
            }
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
            return LITERAL;
	  }
{TRUE}    {
            tableGramPosition() += yyleng;
            lvalp->val = new TaQLConstNode(new TaQLConstNodeRep (True));
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
	    return LITERAL;
	  }
{FALSE}   {
            tableGramPosition() += yyleng;
            lvalp->val = new TaQLConstNode(new TaQLConstNodeRep (False));
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
	    return LITERAL;
	  }
{STRING}  {
            tableGramPosition() += yyleng;
            lvalp->val = new TaQLConstNode(
                new TaQLConstNodeRep (tableGramRemoveQuotes (TableGramtext)));
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
	    return STRINGLITERAL;
	  }
{DATETIME} {
            tableGramPosition() += yyleng;
            lvalp->val = new TaQLConstNode(
                new TaQLConstNodeRep (tableGramParseDateTime (TableGramtext)));
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
	    return LITERAL;
	  }
<EXPRstate>{TIME} {
            tableGramPosition() += yyleng;
            lvalp->val = new TaQLConstNode(
                new TaQLConstNodeRep (tableGramParseTime (TableGramtext)));
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
	    return LITERAL;
	  }

 /* regular expression and pattern handling */
<EXPRstate>"~" {
            tableGramPosition() += yyleng;
            BEGIN(REGEXstate);
            return EQREGEX;
          }
<EXPRstate>"!~" {
            tableGramPosition() += yyleng;
            BEGIN(REGEXstate);
            return NEREGEX;
          }
<REGEXstate>{REGEX} {
            tableGramPosition() += yyleng;
            lvalp->val = new TaQLConstNode(
                new TaQLConstNodeRep (String(TableGramtext+2,yyleng-3)));
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
            BEGIN(EXPRstate);
	    return REGEX;
	  }
<REGEXstate>{PATT} {
            tableGramPosition() += yyleng;
            lvalp->val = new TaQLConstNode(
                new TaQLConstNodeRep (String(TableGramtext+2,yyleng-3)));
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
            BEGIN(EXPRstate);
	    return PATTERN;
	  }

 /* In the FROM clause a shorthand (for a table) can be given.
    In the WHERE and ORDERBY clause a function name can be given.
    Note that this rule could also be done by NAMEFLD. However, in the
    future :: and . will be operators instead of parts of the name.
    ALL is a special name, because it can also be used instead of DISTINCT
    in the SELECT clause (note that ALL is also a function name).
 */
{ALL}     {
            tableGramPosition() += yyleng;
	    return ALL;
	  }
{NAME}    {
            tableGramPosition() += yyleng;
            lvalp->val = new TaQLConstNode(
                new TaQLConstNodeRep (tableGramRemoveEscapes (TableGramtext)));
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
	    return NAME;
	  }
 /* Field names can be used in the SELECT, FROM, WHERE, and ORDERBY clause */
{NAMEFLD} {
            tableGramPosition() += yyleng;
            lvalp->val = new TaQLConstNode(
                new TaQLConstNodeRep (tableGramRemoveEscapes (TableGramtext)));
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
	    return FLDNAME;
	  }

 /* A temporary table number can be given in the FROM clause */
<FROMstate>{TEMPTAB} {
            tableGramPosition() += yyleng;
            int ival = atoi(TableGramtext+1);
            lvalp->val = new TaQLConstNode(new TaQLConstNodeRep (ival));
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
	    return TABNAME;
	  }

 /* A table file name can be given in the UPDATE, FROM or GIVING clause */
<FROMstate,GIVINGstate>{NAMETAB} {
            tableGramPosition() += yyleng;
            lvalp->val = new TaQLConstNode(
                new TaQLConstNodeRep (tableGramRemoveEscapes (TableGramtext)));
            TaQLNode::theirNodesCreated.push_back (lvalp->val);
	    return TABNAME;
	  }

 /* Whitespace is skipped */
{WHITE}   { tableGramPosition() += yyleng; }

 /* An unterminated string is an error */
{USTRING} { throw (TableInvExpr ("Unterminated string")); }

 /* terminate on EOF */
<<EOF>>   { yyterminate(); }

 /* Any other character is invalid */
.         { return YYERRCODE; }

%%
