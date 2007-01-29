//# DOhdsfile.cc:
//# Copyright (C) 1998,1999,2000,2001,2002
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
//# $Id: DOhdsfile.cc,v 19.2 2004/08/25 05:49:26 gvandiep Exp $

#if defined(HAVE_HDS)

#include <npoi/HDS/DOhdsfile.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterSet.h>
#include <casa/Arrays/Vector.h>
#include <casa/Containers/Block.h>
#include <casa/Exceptions/Error.h>
#include <casa/Arrays/IPosition.h>
#include <tasking/Tasking/Index.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Regex.h>
#include <casa/Utilities/Assert.h>
#include <casa/Logging/LogIO.h>
#include <casa/Logging/LogOrigin.h>
#include <casa/stdio.h>
#include <casa/iostream.h>

hdsfile::hdsfile(const String& filename, const Bool& readonly)
  :itsFile(filename, readonly)
{
  //  DebugAssert(DOok(), AipsError);
}

hdsfile::~hdsfile() {
}

Vector<String> hdsfile::ls() {
  Vector<String> retVal = itsFile.ls();
  for (uInt i = 0; i < retVal.nelements(); i++) {
    retVal(i).downcase();
  }
  return retVal;
}

void hdsfile::cd(const String& newNode) {
  Block<String> nodeNames(0);
  Block<IPosition> nodeElements(0);
  if (parseNodeString(nodeNames, nodeElements, newNode) == False) {
    throw(AipsError("hdsfile::cd - " 
		    "cannot parse the following node string: " + newNode));
  }
  // This function should also strip of the leading element if it is the
  // top name.
  for (uInt n = 0; n < nodeNames.nelements(); n++) {
    if (nodeElements[n].nelements() == 0) {
      if (itsFile.exists(nodeNames[n])) {
	itsFile.cd(nodeNames[n]);
      } else {
	LogIO logErr(LogOrigin("hdsfile", "cd(const String&)"));
	logErr << "Cannot find node " << nodeNames[n] << endl
	       << "...Aborting cd at this point."
	       << LogIO::EXCEPTION;
      }
    } else {
      if (itsFile.exists(nodeNames[n], nodeElements[n])) {
	itsFile.cd(nodeNames[n], nodeElements[n]);
      } else {
	LogIO logErr(LogOrigin("hdsfile", "cd(const String&)"));
	logErr << "Cannot find node " 
	       << nodeNames[n] << "(" << nodeElements[n]+1 << ")" << endl
	       << "...Aborting cd at this point."
	       << LogIO::EXCEPTION;
      }
    }
  }
}

void hdsfile::cdup() {
  // Should check if we are at the top
  return itsFile.cdUp();
}

void hdsfile::cdtop() {
  return itsFile.cdTop();
}

String hdsfile::name() {
  String retVal = itsFile.name();
  retVal.downcase();
  return retVal;
}

String hdsfile::fullname() {
  String retVal = itsFile.fullname();
  retVal.downcase();
  return retVal;
}

String hdsfile::type() {
  String retVal = itsFile.type();
  retVal.downcase();
  return retVal;
}

Vector<Index> hdsfile::shape() {
  const IPosition& shape = itsFile.shape();
  Vector<Index> retVal;
  Index::convertIPosition(retVal, shape, False);
  return retVal;
}

Array<Double> hdsfile::get() {
  Array<Double> retVal;
  itsFile.get(retVal);
  return retVal;
}

Array<String> hdsfile::getstring() {
  Array<String> retVal;
  itsFile.get(retVal);
  return retVal;
}

String hdsfile::className() const {
  return String("hdsfile");
}

Vector<String> hdsfile::methods() const {
  Vector<String> method(10);
  method(0) = "ls";
  method(1) = "cd";
  method(2) = "cdup";
  method(3) = "cdtop";
  method(4) = "name";
  method(5) = "fullname";
  method(6) = "type";
  method(7) = "shape";
  method(8) = "get";
  method(9) = "getstring";
  return method;
}

MethodResult hdsfile::runMethod(uInt which,
				ParameterSet& parameters, 
				Bool runMethod) {
  static const String returnvalName = "returnval";
  static const String nodeName = "node";

  switch (which) {
  case 0: { // ls()
    Parameter<Vector<String> > returnval(parameters, returnvalName, 
					 ParameterSet::Out);
    if (runMethod) {
      returnval() = ls();
    }
  }
  break;
  case 1: { // cd(node)
    const Parameter<String> node(parameters, nodeName, ParameterSet::In);
    if (runMethod) {
      cd(node());
    }
  }
  break;
  case 2: { // cdup()
    if (runMethod) {
      cdup();
    }
  }
  break;
  case 3: { // cdtop()
    if (runMethod) {
      cdtop();
    }
  }
  break;
  case 4: { // name()
    Parameter<String> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = name();
    }
  }
  break;
  case 5: { // fullname()
    Parameter<String> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = fullname();
    }
  }
  break;
  case 6: { // type()
    Parameter<String> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = type();
    }
  }
  break;
  case 7: { // shape()
    Parameter<Vector<Index> > returnval(parameters, returnvalName, 
					ParameterSet::Out);
    if (runMethod) {
      returnval().resize(0); // THIS WORKAROUND IS INCLUDED
			     // BECAUSE THE RETURNVAL VECTOR
			     // MAY NOT BE THE RIGHT SIZE!
      returnval() = shape();
    }
  }
  break;
  case 8: { // get()
    Parameter<Array<Double> > returnval(parameters, 
					returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval().resize(IPosition(1,0));
      returnval() = get();
    }
  }
  break;
  case 9: { // getstring()
    Parameter<Array<String> > returnval(parameters, 
					returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval().resize(IPosition(1,0));
      returnval() = getstring();
    }
  }
  break;
  default:
    return error("Unknown method");
  }
  return ok();
}

Vector<String> hdsfile::noTraceMethods() const {
  Vector<String> method(10);
  method(0) = "ls";
  method(1) = "cd";
  method(2) = "cdup";
  method(3) = "cdtop";
  method(4) = "name";
  method(5) = "fullname";
  method(6) = "type";
  method(7) = "shape";
  method(8) = "get";
  method(9) = "getstring";
  return method;
}

Bool hdsfile::parseNodeString(Block<String>& nodeNames,
			      Block<IPosition>& nodeElements,
			      String allNodes) {
  const Int stringLength = allNodes.length();
  Int startIndex = 0;
  Int pathLength;
  String thisNode, elementString;
  uInt n = 0;
  const Regex indexExpr("\\([0-9]+.*\\)");// eg., "(...)"
  while (startIndex < stringLength) {
    pathLength = allNodes.index('.', startIndex);
    if (pathLength < 0) pathLength = stringLength;
    pathLength -= startIndex;
    if (pathLength > 0) {
      nodeNames.resize(n+1);
      nodeElements.resize(n+1);
      thisNode = allNodes.at(startIndex, pathLength);
      nodeNames[n] = thisNode.before(indexExpr);
      if (nodeNames[n].length() != thisNode.length()) {
	elementString = thisNode.at(Regex("\\([0-9]+\\)"));
	if (elementString.length() > 0) {
	  uInt cell;
	  if (sscanf(elementString.chars(), "(%u)", &cell) != 1) return False;
	  nodeElements[n] = IPosition(1, cell-1);
	} else {
	  elementString = thisNode.at(Regex("\\([0-9]+,[0-9]+\\)"));
	  if (elementString.length() > 0) {
	    uInt cellx, celly;
	    if (sscanf(elementString.chars(), "(%u,%u)", &cellx, &celly) 
		!= 2) return False;
	    nodeElements[n] = IPosition(2, cellx-1, celly-1);
	  } else {
	    elementString = thisNode.at(Regex("\\([0-9]+,[0-9]+,[0-9]+\\)"));
	    if (elementString.length() > 0) {
	      uInt cellx, celly, cellz;
	      if (sscanf(elementString.chars(), "(%u,%u,%u)", 
			 &cellx, &celly, &cellz) != 3) return False;
	      const IPosition sh = itsFile.shape();
	      nodeElements[n] = IPosition(3, cellx-1, celly-1, cellz-1);
	    } else {
	      elementString = 
		thisNode.at(Regex("\\([0-9]+,[0-9]+,[0-9]+,[0-9]+\\)"));
	      if (elementString.length() > 0) {
		uInt cellx, celly, cellz, cellA;
		if (sscanf(elementString.chars(), "(%u,%u,%u,%u)", 
			   &cellx, &celly, &cellz, &cellA) != 4) return False;
		const IPosition sh = itsFile.shape();
		nodeElements[n] = IPosition(4, cellx-1, celly-1, 
					    cellz-1, cellA-1);
	      }
	    }
	  }
	}
      }
      n++;
    }
    startIndex += (pathLength + 1);
  }
  return True;
}
#endif
// Local Variables: 
// compile-command: "gmake DOhdsfile"
// End: 
