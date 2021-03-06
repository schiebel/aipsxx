//# RecordGram.h: Grammar for record command lines
//# Copyright (C) 2000
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: RecordGram.h,v 19.8 2005/06/21 07:47:38 gvandiep Exp $

#ifndef TABLES_RECORDGRAM_H
#define TABLES_RECORDGRAM_H

//# Includes
#include <casa/BasicSL/String.h>
#include <tables/Tables/TableGram.h>
#include <tables/Tables/Table.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declarations
class TableExprNode;
class TableExprNodeSet;
class RecordInterface;
class Table;

// <summary>
// Global functions for flex/bison scanner/parser for RecordGram
// </summary>

// <use visibility=local>

// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="">
// </reviewed>

// <prerequisite>
//# Classes you should understand before using this one.
//  <li> RecordGram.l and .y  (flex and bison grammar)
// </prerequisite>

// <synopsis> 
// Global functions are needed to define the input of the flex scanner
// and to start the bison parser.
// The input is taken from a string.
// </synopsis> 

// <motivation>
// It is necessary to be able to give a record select command in ASCII.
// This can be used in a CLI or in the record browser to get a subset
// of a record or to sort a record.
// </motivation>

// <todo asof="$DATE:$">
//# A List of bugs, limitations, extensions or planned refinements.
// </todo>

// <group name=RecordGramFunctions>

// Declare the bison parser (is implemented by bison command).
int recordGramParseCommand (const String& command);

// The yyerror function for the parser.
// It throws an exception with the current token.
void RecordGramerror (char*);

// Give the current position in the string.
// This can be used when parse errors occur.
Int& recordGramPosition();

// Declare the input routine for flex/bison.
int recordGramInput (char* buf, int max_size);

// A function to remove escaped characters.
inline String recordGramRemoveEscapes (const String& in)
    { return tableGramRemoveEscapes (in); }

// A function to remove quotes from a quoted string.
inline String recordGramRemoveQuotes (const String& in)
    { return tableGramRemoveQuotes (in); }

// </group>



// <summary>
// Helper class for values in RecordGram 
// </summary>

// <use visibility=local>

// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="">
// </reviewed>

// <synopsis> 
// A record selection command is lexically analyzed via flex.
// An object of this class is used to hold a value (like a name
// or a literal) for later use in the parser code.
// </synopsis> 

class RecordGramVal
{
public:
    Int      type;          //# i=Int, f=Double, c=DComplex, s=String t=Table
    String   str;           //# string literal; table name; field name
    Int      ival;          //# integer literal
    Double   dval[2];       //# Double/DComplex literal
    Table    tab;           //# Table (from query in e.g. FROM clause)
};




// <summary>
// Select-class for flex/bison scanner/parser for RecordGram
// </summary>

// <use visibility=local>

// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="">
// </reviewed>

// <prerequisite>
//# Classes you should understand before using this one.
//  <li> RecordGram.l and .y  (flex and bison grammar)
// </prerequisite>

// <synopsis> 
// This class is needed for the the actions in the flex scanner
// and bison parser.
// This stores the information by constructing RecordGram objects
// as needed and storing them in a List.
// </synopsis> 

// <motivation>
// It is necessary to be able to give a record select command in ASCII.
// It is used by the ACSIS people.
// </motivation>

//# <todo asof="$DATE:$">
//# A List of bugs, limitations, extensions or planned refinements.
//# </todo>


class RecordGram
{
public:
    // Convert an expression string to an expression tree.
    // The expression will operate on a series of Record objects.
    // The given record is needed to know the type of the fields used in
    // the expression.
    //# The record will be put into the static variable to be used by
    //# the other functions.
    static TableExprNode parse (const RecordInterface& record,
				const String& expression);

    // Convert an expression string to an expression tree.
    // The expression will operate on the given table.
    //# The record will be put into the static variable to be used by
    //# the other functions.
    static TableExprNode parse (const Table& table,
				const String& expression);

    // Create a TableExprNode from a literal.
    static TableExprNode handleLiteral (RecordGramVal*);

    // Find the field name and create a TableExprNode from it.
    static TableExprNode handleField (const String& name);

    // Handle a function.
    static TableExprNode handleFunc (const String& name,
				     const TableExprNodeSet& arguments);

    // Set the final node pointer.
    static void setNodePtr (TableExprNode* nodePtr)
        { theirNodePtr = nodePtr; }

private:
    // Do the conversion of an expression string to an expression tree.
    static TableExprNode doParse (const String& expression);

    static const RecordInterface* theirRecPtr;
    static const Table*           theirTabPtr;
    static TableExprNode*         theirNodePtr;
};



} //# NAMESPACE CASA - END

#endif
