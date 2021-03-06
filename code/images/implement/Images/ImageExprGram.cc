//# ImageExprGram.cc: Grammar for image expressions
//# Copyright (C) 1998,1999,2001,2003
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
//# $Id: ImageExprGram.cc,v 19.6 2004/11/30 17:50:25 ddebonis Exp $

// ImageExprGram; grammar for image command lines

// This file includes the output files of bison and flex for
// parsing command lines operating on lattices.
// This is a preliminary version; eventually it has to be incorporated
// in the AIPS++ command language.

#include <lattices/Lattices/LatticeExprNode.h>
#include <casa/Arrays/Slice.h>
#include <casa/Containers/Block.h>
#include <images/Images/ImageExprGram.h>
#include <images/Images/ImageExprParse.h>    // routines used by bison actions
#include <casa/Exceptions/Error.h>

//# stdlib.h is needed for bison 1.28 and needs to be included here
//# (before the flex/bison files).
#include <casa/stdlib.h>
#include <ImageExprGram.ycc>                  // flex output
#include <ImageExprGram.lcc>                  // bison output




// Define the yywrap function for flex.
int ImageExprGramwrap()
{
    return 1;
}

namespace casa { //# NAMESPACE CASA - BEGIN

//# Declare a file global pointer to a char* for the input string.
static const char*  strpImageExprGram = 0;
static Int          posImageExprGram = 0;

//# Parse the command.
//# Do a yyrestart(yyin) first to make the flex scanner reentrant.
int imageExprGramParseCommand (const String& command)
{
    ImageExprGramrestart (ImageExprGramin);
    yy_start = 1;
    strpImageExprGram = command.chars();     // get pointer to command string
    posImageExprGram  = 0;                   // initialize string position
    return ImageExprGramparse();             // parse command string
}

//# Give the string position.
Int& imageExprGramPosition()
{
    return posImageExprGram;
}

//# Get the next input characters for flex.
int imageExprGramInput (char* buf, int max_size)
{
    int nr=0;
    while (*strpImageExprGram != 0) {
	if (nr >= max_size) {
	    break;                         // get max. max_size char.
	}
	buf[nr++] = *strpImageExprGram++;
    }
    return nr;
}

void ImageExprGramerror (char*)
{
    throw (AipsError ("Image Expression: Parse error at or near '" +
		      String(ImageExprGramtext) + "'"));
}

String imageExprGramRemoveEscapes (const String& in)
{
    String out;
    int leng = in.length();
    for (int i=0; i<leng; i++) {
	if (in[i] == '\\') {
	    i++;
	}
	out += in[i];
    }
    return out;
}

String imageExprGramRemoveQuotes (const String& in)
{
    //# A string is formed as "..."'...''...' etc.
    //# All ... parts will be extracted and concatenated into an output string.
    String out;
    String str = in;
    int leng = str.length();
    int pos = 0;
    while (pos < leng) {
	//# Find next occurrence of leading ' or ""
	int inx = str.index (str[pos], pos+1);
	if (inx < 0) {
	    throw (AipsError ("ImageExprParse - Ill-formed quoted string: " +
			      str));
	}
	out += str.at (pos+1, inx-pos-1);             // add substring
	pos = inx+1;
    }
    return out;
}

} //# NAMESPACE CASA - END

