//# AppUtil.cc: Implementation of AppUtil.h
//# Copyright (C) 1996,1997,1998,2000,2001,2003
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
//# $Id: 
//----------------------------------------------------------------------------

#include <tasking/Tasking/AppUtil.h>
#include <casa/Utilities/Assert.h>
#include <casa/Utilities/DataType.h>
#include <casa/Arrays/Slice.h>
#include <casa/BasicMath/Math.h>
#include <casa/Logging/LogIO.h>
#include <casa/iostream.h>
#include <casa/iomanip.h>
#include <casa/sstream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//----------------------------------------------------------------------------

AppUtil::AppUtil() : itsMeta(0)
{
// Default constructor
// Output to private data:
//    itsMeta      Record*            Meta information
//
};

//----------------------------------------------------------------------------

AppUtil::~AppUtil()
{
// Default destructor
//
  // Delete pointers if they already exist
  if (itsMeta) {
    delete itsMeta;
  };
};

//----------------------------------------------------------------------------

AppUtil::AppUtil (const AppUtil& other) : itsMeta(0)
{
// Copy constructor
// Inputs:
//    other        AppUtil&           Input AppUtil object
// Output to private data: 
//    itsMeta      Record*            Tasking meta-information
//
  if (itsMeta) {
    *itsMeta = (*(other.itsMeta));
  } else {
    itsMeta = new Record (*(other.itsMeta));
  };
};

//----------------------------------------------------------------------------

AppUtil& AppUtil::operator= (const AppUtil& other)
{
// Assignment operator
// Inputs:
//    other        AppUtil            Input AppUtil object
// Output to private data:
//    itsMeta      Record*            Tasking meta-information
//
  if (itsMeta && this != &other) {
    *itsMeta = *(other.itsMeta);
  };
  return *this;
};

//----------------------------------------------------------------------------

AppUtil::AppUtil (const GlishRecord& meta) : itsMeta(0)
{
// Constructor taking meta information as input
// Inputs:
//    meta         GlishRecord        Input meta information
// Output to private data:
//    itsMeta      Record*            Meta information
//
   // Copy meta information
   Record rec;
   meta.toRecord (rec);
   itsMeta = new Record (rec);
   AlwaysAssert (itsMeta, AipsError);
};

//----------------------------------------------------------------------------

Vector <String> AppUtil::tabulate (const String& line, const Int& colWidth) 
  const
{
// Sub-divide a string for display in a multi-line column
// Inputs:
//    line         String             Input string
//    colWidth     Int                Column width
// Outputs:
//    AppUtil      Vector<String>     Subdivided string
//
  // Initialization
  String stmp = line;
  Int lim = stmp.length() - 1;
  Int jout = 0;
  Int start = 0;
  Int end = min (colWidth - 1, lim);
  Int last = -1;
  Vector <String> retval(1);
  Bool null = True;
   
  // Loop over each character in the string
  Int indx, uselim;
  for (indx = 0; indx <= lim; indx++) {

    // Mark position of last blank character
    if (stmp.at(indx,1) == " ") {
      last = indx;
    } else {
      null = False;
    };

    // End of current column width ?
    if (indx >= end) {
      if (last > 0 && indx != lim) {
        uselim = last;
      } else {
        uselim = end;
      };
      if (!null) {
	if (jout > 0) retval.resize(jout+1, True);
        retval(jout++) = stmp.at(start, uselim-start+1);
      };
      start = uselim + 1;
      end = start + colWidth - 1;
      if (end > lim) end = lim;
      last = -1;
      null = True;
    };
  };
  return retval;
};

//----------------------------------------------------------------------------

inline void AppUtil::fillBuf (Char* buffer, const Int& nlen) const
{
// Blank fill a character buffer
// Input:
//    nlen         Int                Buffer length
// Input/output:
//    buffer       Char*              Buffer
//
  // Initialize buffer
  Int i;
  for (i = 0; i < nlen; i++) buffer[i] = ' ';
};

//----------------------------------------------------------------------------

Vector<String> AppUtil::format (const String& method, 
   const GlishRecord& parms, const Int& width, const Int& gap) const
{
// Format the parameter values for display as character strings
// Inputs:
//    method       String             Method name
//    parms        GlishRecord        Parameter names and values
//    width        Int                Window width (chars)
//    gap          Int                Desired gap between columns (chars)
// Outputs:
//    AppUtil      Vector<String>     Formatted parameter values
//
  // Convert GlishRecord to standard Record
  Record rec;
  parms.toRecord (rec);

  // No. of fields in parameter record
  Int nfield = rec.nfields();

   // Find longest input parameter name
  Int i, l; 
  Int wparm = 0;
  for (i = 0; i < nfield; i++) {
     l = rec.name(i).length();
     if (l > wparm) {
        wparm = l;
     };
  };
   
  // Compute column widths
  Int wcol = (width - (wparm + 2 * gap)) / 2;
  Int tabval = wparm + gap;
  Int tabhelp = tabval + wcol + gap;

  // Define local variables
  Char* streamBuf = new Char[1024];
  AlwaysAssert (streamBuf, AipsError);

  ostringstream oss;
  Float fval;
  Double dval;
  Bool bval;
  Int field, j, nval, k, newsiz, nout, nv, nh, ival;
  Int jout = 0;
  DataType fieldType;
  GlishValue x;
  Vector <String> returnval(1), varType(2);
  Vector <String>* valstr;
  Vector <String>* helpstr;
  String str, fieldName;
  Record tmpRec;

   // Loop over the fields in the parameter record
  for (field = 0; field < nfield; field++) {

    // Get type and dimension of field
    fieldType = rec.dataType(field);
    nval = parms.get(field).nelements();
    fieldName = rec.name(field);
      
    // Loop over each element in the field
    oss.seekp(0);
    // fillBuf (streamBuf, 1024);
    for (j = 0; j < nval; j++) {

    // Select on data type
      switch (fieldType) {
        case TpString:
          str = rec.asString(field);
          oss << "\"" << str << "\"";
          break;

        case TpArrayString:
          str = rec.asArrayString(field)(IPosition(1,j));
          oss << "\"" << str << "\"";
          break;
    
        case TpInt:
          ival = rec.asInt(field);
          oss << ival;
          break;

        case TpFloat:
          fval = rec.asFloat(field);
          oss << fval;
          break;

        case TpDouble:
          dval = rec.asDouble(field);
          oss << dval;
          break;

        case TpBool:
          bval = rec.asBool(field);
          if (bval) {
	    oss << 'T';
	  } else {
            oss << 'F';
	  };
          break;

      default:
	AlwaysAssert (False, AipsError);
      };
      if (j != (nval-1)) oss << ",";
    };

    // Tabulate in each column
    str = String (oss.str());
    valstr = new Vector <String> (tabulate (str, wcol));
    AlwaysAssert (valstr, AipsError);

    // Locate help string in the meta-information record
    str = "";
    varType(0) = "data";
    varType(1) = "prereq";
    if (itsMeta->isDefined(method)) {
      // Search both [.data] and [.prereq]
      for (j = 0; j < 2; j++) {
	tmpRec = itsMeta->asRecord(method);
	if (tmpRec.isDefined(varType(j))) {
	  tmpRec = tmpRec.asRecord(varType(j));
	  if (tmpRec.isDefined(fieldName)) {
	    tmpRec = tmpRec.asRecord(fieldName);
	    if (tmpRec.isDefined("help")) {
	      tmpRec = tmpRec.asRecord("help");
	      if (tmpRec.isDefined("text")) 
		str = tmpRec.asString("text");
	    };
	  };
	};
      };
    };		

    helpstr = new Vector <String> (tabulate (str, wcol));
    AlwaysAssert (helpstr, AipsError);    

    // Expand returnval if necessary
    nv = valstr->shape()(0);
    nh = helpstr->shape()(0);
    nout = max (nv, nh);
    newsiz = returnval.shape()(0) + nout;
    returnval.resize(newsiz, True);

    // Add new lines to returnval
    for (k = 0; k < nout; k++) {

      // Re-use stream buffer
      oss.seekp(0);
      // fillBuf (streamBuf, width);
      oss.setf(ios::left);

      if (k == 0) oss << setw (wparm) << fieldName;
      if (k < nv) {
	oss.seekp(tabval);
	oss << setw (wcol) << (*valstr)(k);
      };
      if (k < nh) {
	oss.seekp(tabhelp);
	oss << setw (wcol) << (*helpstr)(k);
      };
      returnval(jout++) = (String (streamBuf)).at(0, width);
    };

    // Delete pointers
    delete (valstr);
    delete (helpstr);
  };

  delete (streamBuf);
  return returnval;
};

//----------------------------------------------------------------------------

String AppUtil::readcmd() const
{
// Read a command string from stdin
// Output:
//    readcmd        String           Input command string
//
  // Use cin/cout for now
  String returnval = ""; 
  Char nextChar;
  cout.put('>');
  Int next = cin.get();

  while (next != '\n') {
    nextChar = char (next);
    returnval += nextChar;
    next = cin.get();
  };

  return returnval;
};

//----------------------------------------------------------------------------

void AppUtil::pushCmd (Vector <String>& cmdStack, const String& newCmd) const
{
// Add a new command to a command list
// Input:
//    newCmd        String             New command
// Input/output:
//    cmdStack      Vector<String>     Command list
//
  Int ndim = cmdStack.shape()(0);
  cmdStack(ndim-1) = newCmd;
  cmdStack.resize(ndim+1, True);
};

//----------------------------------------------------------------------------

inline Bool AppUtil::validVarNameChar (const Char& inchar) const
{
// Return true if input character can form part of a Glish variable name
// Input:
//    inchar              Char               Input character
// Output:
//    validVarNameChar    Bool               True if valid Glish var. char
//
  return ((inchar >= '0' && inchar <= '9') ||
	  (inchar >= 'A' && inchar <= 'Z') ||
	  (inchar >= 'a' && inchar <= 'z') ||
	  (inchar == '_'));
};

//----------------------------------------------------------------------------

Vector <String> AppUtil::parse (const GlishRecord& parms, const String& cmd)
  const
{
// Parse an input command string, and convert to standard Glish
// Inputs:
//    parms          GlishRecord      Record containing current parameters
//    cmd            String           Input command string
// Output:
//    parse          Vector<String>   Encoded Glish commands
//
  // Divide command string into sub-commands (separated by semi-colons);
  Int nlen = cmd.length();
  Vector <String> returnval(1);
  Vector <String> subCmd(1);
  subCmd(0) = "";
  Int jsub = 0;
  Int pos, nextPos;
  Bool strSearch = False;
  Char termChar, currChar;
  termChar='\0';

  // Loop through command string, avoiding semi-colons in
  // character string expressions.
  for (pos = 0; pos < nlen; pos++) {
    currChar = cmd.elem(pos);
    if ((currChar == '\"' || currChar == '\'') && !strSearch) {
      strSearch = True;
      termChar = currChar;
      subCmd(jsub) += currChar;
    } else if (strSearch && currChar == termChar) {
      strSearch = False;
      subCmd(jsub) += currChar;
    } else if (currChar == ' ' && !strSearch) {
      nextPos = min (pos+1, nlen-1);
      if (subCmd(jsub).length() != 0 && cmd.elem(nextPos) != ' ') 
	subCmd(jsub) += currChar;
    } else if (currChar == ';' && !strSearch) {
      subCmd.resize(jsub+2, True);
      subCmd(++jsub) = "";
    } else {
      subCmd(jsub) += currChar;
    };
  };

  // Compute number of sub-commands found
  Int nsub;
  if (subCmd(jsub).length() == 0) {
    nsub = jsub;
  } else {
    nsub = jsub + 1;
  };

  // Process each sub-command separately
  Int jstr, nsplit, field, nlenSub, tmp, j, nfreq, nparen, lastAssign;
  Int prec, succ, offset;
  Char chPrec, chSucc;
  String tmpStr[2], lowerCase, tmpOut;
  Vector <String> tmpVec(2);
  Vector <Int> startPos(64), endPos(64);
  Int nPos = 0;
  Int nfield = parms.description().nfields();
  Bool matchStart, matchEnd, parenSearch, equality, assignm, found, 
    closeArray, skipChar;

  for (jsub = 0; jsub < nsub; jsub++) {
    nlenSub = subCmd(jsub).length();

    // Match command keywords (eg. tget, tput etc.). Examine first
    // two words of the sub-command to identify type.
    nsplit = split (subCmd(jsub), tmpStr, 2, ' ');
    for (jstr = 0; jstr < 2; jstr++) {
      tmpVec(jstr) = tmpStr[jstr];
    };
    lowerCase = downcase (tmpVec(0));

    // Deal with each command keyword separately
    // Command TGET:
    if (lowerCase == "tget") {
      pushCmd (returnval, lowerCase);

      // Extract method name
      if (nsplit > 1) {
	pushCmd (returnval, tmpVec(1));
      } else {
	pushCmd (returnval, "APP-ERROR");
      };

    // Command TPUT:
    } else if (lowerCase == "tput") {
      pushCmd (returnval, lowerCase);

      // Extract method name
      if (nsplit > 1) {
	pushCmd (returnval, tmpVec(1));
      } else {
	pushCmd (returnval, "APP-ERROR");
      };

    // Command INP:
    } else if (lowerCase == "inp") {
      pushCmd (returnval, lowerCase);

    // Command GO:
    } else if (lowerCase == "go") {
      pushCmd (returnval, lowerCase);

    // Command QUIT:
    } else if (lowerCase == "quit") {
      pushCmd (returnval, lowerCase);

    // Null command; ignore
    } else if (lowerCase == ' ') {

    // Else assume that it is a parameter-setting command
    } else {

      // Find positions of all parameter names in the sub-command string
      for (field = 0; field < nfield; field++) {
	nfreq = subCmd(jsub).freq(parms.name(field));
	tmp = 0;
	for (j = 0; j < nfreq; j++) {
	  // Check that this is an isolated parameter name
          pos = subCmd(jsub).index(parms.name(field), tmp++);
          offset = pos + parms.name(field).length() - 1;
	  prec = max (0, pos-1);
	  succ = min (nlenSub-1, offset+1);
	  chPrec = subCmd(jsub).elem(prec);
	  chSucc = subCmd(jsub).elem(succ);
	  if ((pos == 0 || !validVarNameChar (chPrec)) &&
	      (offset == (nlenSub-1) || !validVarNameChar (chSucc))) {
	    startPos(nPos) = pos;
	    endPos(nPos++) = offset;
	  };
	};
      };

      // Loop through each character in the sub-command string,
      // translating to standard Glish as required.
      strSearch = False;
      tmpOut = "";
      nparen = 0;
      lastAssign = -1;
      closeArray = False;
      parenSearch = False;

      for (pos = 0; pos < nlenSub; pos++) {
	currChar = subCmd(jsub).elem(pos);
	skipChar = False;

	// Check for match to start or end of any input parameter
	matchStart = False; 
	matchEnd = False;
	for (j = 0; j < nPos; j++) {
	  if (pos == startPos(j)) matchStart = True;
	  if (pos == (endPos(j)+1)) matchEnd = True;
	};

	// Do not search for reserved tokens within character expressions
	if ((currChar == '\"' || currChar == '\'') && !strSearch) {
	  strSearch = True;
	  termChar = currChar;
	} else if (strSearch && currChar == termChar) {
	  strSearch = False;

        // Start of input parameter
	} else if (matchStart && !strSearch) {
	  // Insert underscore
	  tmpOut += "_";

        // Open parenthesis (
	} else if (currChar == '(' && !strSearch) {
	  // Check for () indexing and convert to []
	  if (matchEnd && !parenSearch) {
	    tmpOut += '[';
	    skipChar = True;
	    parenSearch = True;
	    nparen = 1;
	  } else if (parenSearch) {
	    nparen = nparen + 1;
	  };

        // Close parenthesis )
	} else if (currChar == ')' && !strSearch) {
	  nparen = nparen - 1;
	  if (nparen == 0) {
	    parenSearch = False;
	    tmpOut += ']';
	    skipChar = True;
	  };

        // Equal symbol =
	} else if (currChar == '=' && !strSearch) {
	  // Check for assignment (:=) or equality (==)
	  assignm = False;
	  equality = False;
	  if (pos > 0) {
	    if (subCmd(jsub).elem(pos-1) == ':') assignm = True;
	    if (subCmd(jsub).elem(pos-1) == '=') equality = True;
	  };
	  if (pos < (nlenSub-1)) 
	    if (subCmd(jsub).elem(pos+1) == '=') equality = True;

	  // Add colon if not assignment or equality
	  if (!assignm && !equality) {
	    tmpOut += ':';
	    assignm = True;
	  };

	  // If assignment, then add space in case it is array assignment
	  if (assignm) {
	    tmpOut += currChar;
	    tmpOut += ' ';
	    lastAssign = tmpOut.length() - 1;
	    skipChar = True;
	  };

        // Array separator comma
	} else if (currChar == ',' && !strSearch) {
	  // Has bracket [ already been used ?
	  if (lastAssign >= 0) {
	    j = lastAssign;
	    found = False;
	    while (j < (Int) (tmpOut.length()) && !found) 
	      if (tmpOut.elem(j++) != ' ') found = True;
	    if (found && tmpOut.elem(j-1) != '[') {
	      tmpOut[lastAssign] = '[';
	      closeArray = True;
	    };
	  };

        // No special character; copy directly to output
	};
	if (!skipChar) tmpOut += currChar;
      };

      // Add closing bracket ], if array assignment
      if (closeArray) tmpOut += ']';

      // Add command to command list; ignore null commands
      if (tmpOut.length() != 0) {
	pushCmd (returnval, "setparm");
	pushCmd (returnval, tmpOut);
      };
    };
  };
  return returnval(Slice(0,returnval.shape()(0)-1));
};

//----------------------------------------------------------------------------





} //# NAMESPACE CASA - END

