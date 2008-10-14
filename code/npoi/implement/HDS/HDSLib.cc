//# HDSLib.cc:
//# Copyright (C) 1997,1998,1999,2000,2001
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
//# $Id: HDSLib.cc,v 19.2 2004/08/25 05:49:26 gvandiep Exp $

#if defined(HAVE_HDS)

#include <npoi/HDS/HDSLib.h>
#include <npoi/HDS/HDSWrapper.h>
#include <npoi/HDS/HDSNode.h>
#include <npoi/HDS/HDSDef.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/IPosition.h>
#include <casa/BasicSL/String.h>

// The following extern "C" statement should be removed when STARLINK adds
// one to their include files.
extern "C" {
#include <f77.h>
#include <cnf.h>
F77_SUBROUTINE(hds_open)(CHARACTER(fFileName), CHARACTER(fIOMode), 
			 CHARACTER(fTopNode), INTEGER(fStatus) 
			 TRAIL(fFileName) TRAIL(fIOMode) TRAIL(fTopNode));
F77_SUBROUTINE(hds_new)(CHARACTER(fFileName), CHARACTER(fNodeName), 
			CHARACTER(fNodeType), INTEGER(fNdims),
			INTEGER_ARRAY(fDims), CHARACTER(fTopNode),
			INTEGER(fStatus) TRAIL(fFileName) TRAIL(fNodeName) 
			TRAIL(fNodeType) TRAIL(fTopNode));
F77_SUBROUTINE(hds_erase)(CHARACTER(fTopNode), 
			  INTEGER(fStatus) TRAIL(fTopNode));
F77_SUBROUTINE(hds_state)(LOGICAL(fstate), INTEGER(fStatus));
F77_SUBROUTINE(hds_show)(CHARACTER(fTypeName), 
			 INTEGER(&fStatus) TRAIL(fTypeName));
F77_SUBROUTINE(hds_stop)(INTEGER(fStatus));
F77_SUBROUTINE(hds_trace)(CHARACTER(fNode), INTEGER(fnLevels),
			  CHARACTER(fNodePath), CHARACTER(fFileName), 
			  INTEGER(fStatus) TRAIL(fNode) TRAIL(fNodePath) 
			  TRAIL(fFileName));
F77_SUBROUTINE(dat_annul)(CHARACTER(fnode), INTEGER(fStatus) TRAIL(fnode));
F77_SUBROUTINE(dat_cell)(CHARACTER(fArrNode), INTEGER(fNdims),
			 INTEGER_ARRAY(fDims), CHARACTER(fCellLoc), 
			 INTEGER(fStatus) 
			 TRAIL(fArrNode) TRAIL(fCellNode) );
F77_SUBROUTINE(dat_clone)(CHARACTER(fOldnode), CHARACTER(fNewnode),
			  INTEGER(fStatus) TRAIL(fOldNode) TRAIL(fNewNode));
F77_SUBROUTINE(dat_find)(CHARACTER(fparentLoc), CHARACTER(fcompName),
			 CHARACTER(fcompLoc), INTEGER(fStatus) 
			 TRAIL(fparentLoc) TRAIL(fcompName) TRAIL(fcompLoc));
F77_SUBROUTINE(dat_get0c)(CHARACTER(fLoc), CHARACTER(fvalue),
			  INTEGER(fStatus) TRAIL(fLoc) TRAIL(fvalue));
F77_SUBROUTINE(dat_get0d)(CHARACTER(fLoc), DOUBLE(fvalue),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_get0i)(CHARACTER(fLoc), INTEGER(fvalue),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_get0l)(CHARACTER(fLoc), LOGICAL(fvalue),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_get0r)(CHARACTER(fLoc), REAL(fvalue),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_get1c)(CHARACTER(fLoc), INTEGER(fMaxLen),
			  CHARACTER_ARRAY(fValues), INTEGER(fLen),
			  INTEGER(fStatus) TRAIL(fLoc) TRAIL(fValues));
F77_SUBROUTINE(dat_get1d)(CHARACTER(fLoc), INTEGER(fMaxLen),
			  DOUBLE_ARRAY(fValues), INTEGER(fLen),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_get1i)(CHARACTER(fLoc), INTEGER(fMaxLen),
			  INTEGER_ARRAY(fValues), INTEGER(fLen),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_get1l)(CHARACTER(fLoc), INTEGER(fMaxLen),
			  LOGICAL_ARRAY(fValues), INTEGER(fLen),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_get1r)(CHARACTER(fLoc), INTEGER(fMaxLen),
			  REAL_ARRAY(fValues), INTEGER(fLen),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_getnc)(CHARACTER(fLoc), INTEGER(fNdims),
			  INTEGER_ARRAY(fDims), CHARACTER_ARRAY(fValues), 
			  INTEGER_ARRAY(fRdims), INTEGER(fStatus) 
			  TRAIL(fLoc) TRAIL(fValues));
F77_SUBROUTINE(dat_getnd)(CHARACTER(fLoc), INTEGER(fNdims),
			  INTEGER_ARRAY(fDims), DOUBLE_ARRAY(fValues), 
			  INTEGER_ARRAY(fRdims), INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_getni)(CHARACTER(fLoc), INTEGER(fNdims),
			  INTEGER_ARRAY(fDims), INTEGER_ARRAY(fValues), 
			  INTEGER_ARRAY(fRdims), INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_getnl)(CHARACTER(fLoc), INTEGER(fNdims),
			  INTEGER_ARRAY(fDims), LOGICAL_ARRAY(fValues), 
			  INTEGER_ARRAY(fRdims), INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_getnr)(CHARACTER(fLoc), INTEGER(fNdims),
			  INTEGER_ARRAY(fDims), REAL_ARRAY(fValues), 
			  INTEGER_ARRAY(fRdims), INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_index)(CHARACTER(fLoc), INTEGER(fIndex), 
			  CHARACTER(fIndexLoc), INTEGER(fStatus)
			  TRAIL(fLoc) TRAIL(fIndexLoc));
F77_SUBROUTINE(dat_len)(CHARACTER(fLoc), INTEGER(fBytes), 
			INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_name)(CHARACTER(fLoc), CHARACTER(fName),
			 INTEGER(fStatus) TRAIL(fLoc) TRAIL(fName));
F77_SUBROUTINE(dat_ncomp)(CHARACTER(fLoc), INTEGER(fNcomp),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_new)(CHARACTER(fparentLoc), CHARACTER(fcompName), 
			CHARACTER(fcompType), INTEGER(fNdims), 
			INTEGER_ARRAY(fDims), INTEGER(fStatus) 
			TRAIL(fparentLoc) TRAIL(fcompName) TRAIL(fcompType));
F77_SUBROUTINE(dat_new0d)(CHARACTER(fparentLoc), CHARACTER(fcompName), 
			  INTEGER(fStatus) 
			  TRAIL(fparentLoc) TRAIL(fcompName));
F77_SUBROUTINE(dat_new0i)(CHARACTER(fparentLoc), CHARACTER(fcompName), 
			  INTEGER(fStatus) 
			  TRAIL(fparentLoc) TRAIL(fcompName));
F77_SUBROUTINE(dat_new0l)(CHARACTER(fparentLoc), CHARACTER(fcompName), 
			  INTEGER(fStatus) 
			  TRAIL(fparentLoc) TRAIL(fcompName));
F77_SUBROUTINE(dat_new0r)(CHARACTER(fparentLoc), CHARACTER(fcompName), 
			  INTEGER(fStatus) 
			  TRAIL(fparentLoc) TRAIL(fcompName));
F77_SUBROUTINE(dat_new0c)(CHARACTER(fparentLoc), CHARACTER(fcompName), 
			  INTEGER(fStringLen), INTEGER(fStatus) 
			  TRAIL(fparentLoc) TRAIL(fcompName));
F77_SUBROUTINE(dat_new1d)(CHARACTER(fparentLoc), CHARACTER(fcompName), 
			  INTEGER(fLen), INTEGER(fStatus) 
			  TRAIL(fparentLoc) TRAIL(fcompName));
F77_SUBROUTINE(dat_new1i)(CHARACTER(fparentLoc), CHARACTER(fcompName), 
			  INTEGER(fLen), INTEGER(fStatus) 
			  TRAIL(fparentLoc) TRAIL(fcompName));
F77_SUBROUTINE(dat_new1l)(CHARACTER(fparentLoc), CHARACTER(fcompName), 
			  INTEGER(fLen), INTEGER(fStatus) 
			  TRAIL(fparentLoc) TRAIL(fcompName));
F77_SUBROUTINE(dat_new1r)(CHARACTER(fparentLoc), CHARACTER(fcompName), 
			  INTEGER(fLen), INTEGER(fStatus) 
			  TRAIL(fparentLoc) TRAIL(fcompName));
F77_SUBROUTINE(dat_new1c)(CHARACTER(fparentLoc), CHARACTER(fcompName), 
			  INTEGER(fStringLen), INTEGER(fLen), INTEGER(fStatus) 
			  TRAIL(fparentLoc) TRAIL(fcompName));
F77_SUBROUTINE(dat_paren)(CHARACTER(fChildLoc), CHARACTER(fParentLoc),
			  INTEGER(fStatus) TRAIL(fChildLoc) TRAIL(fParentLoc));
F77_SUBROUTINE(dat_prmry)(LOGICAL(fSetGet), CHARACTER(fNode), 
			  LOGICAL(fPrimary), INTEGER(fStatus) 
			  TRAIL(fNode));
F77_SUBROUTINE(dat_put0c)(CHARACTER(fLoc), CHARACTER(fvalue), 
			  INTEGER(fStatus) TRAIL(fLoc) TRAIL(fvalue));
F77_SUBROUTINE(dat_put0d)(CHARACTER(fLoc), DOUBLE(fvalue), 
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_put0i)(CHARACTER(fLoc), INTEGER(fvalue), 
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_put0l)(CHARACTER(fLoc), LOGICAL(fvalue), 
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_put0r)(CHARACTER(fLoc), REAL(fvalue),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_put1c)(CHARACTER(fLoc), INTEGER(fLen),
			  CHARACTER_ARRAY(fValues), 
			  INTEGER(fStatus) TRAIL(fLoc) TRAIL(fValues));
F77_SUBROUTINE(dat_put1d)(CHARACTER(fLoc), INTEGER(fLen),
			  DOUBLE_ARRAY(fValues), INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_put1i)(CHARACTER(fLoc), INTEGER(fLen),
			  INTEGER_ARRAY(fValues),INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_put1l)(CHARACTER(fLoc), INTEGER(fLen),
			  LOGICAL_ARRAY(fValues),INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_put1r)(CHARACTER(fLoc), INTEGER(fLen),
			  REAL_ARRAY(fValues), INTEGER(fStatus) TRAIL(fLoc));
// F77_SUBROUTINE(dat_putnc)(CHARACTER(fLoc), INTEGER(fNDim), 
// 			  INTEGER_ARRAY(fADims), CHARACTER_ARRAY(fValues), 
// 			  INTEGER_ARRAY(fODims), 
// 			  INTEGER(fStatus) TRAIL(fLoc) TRAIL(fValues));
// F77_SUBROUTINE(dat_putnd)(CHARACTER(fLoc), INTEGER(fNDim), 
// 			  INTEGER_ARRAY(fADims), DOUBLE_ARRAY(fValues), 
// 			  INTEGER_ARRAY(fODims), INTEGER(fStatus) TRAIL(fLoc));
// F77_SUBROUTINE(dat_putni)(CHARACTER(fLoc), INTEGER(fNDim), 
// 			  INTEGER_ARRAY(fADims), INTEGER_ARRAY(fValues), 
// 			  INTEGER_ARRAY(fODims), INTEGER(fStatus) TRAIL(fLoc));
// F77_SUBROUTINE(dat_putnl)(CHARACTER(fLoc), INTEGER(fNDim), 
// 			  INTEGER_ARRAY(fADims), LOGICAL_ARRAY(fValues), 
// 			  INTEGER_ARRAY(fODims), INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_putnr)(CHARACTER(fLoc), INTEGER(fNDim), 
			  INTEGER_ARRAY(fADims), REAL_ARRAY(fValues), 
			  INTEGER_ARRAY(fODims), INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_shape)(CHARACTER(fLoc), INTEGER(fMaxDim),
			  INTEGER_ARRAY(fDims), INTEGER(fNDims),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_size)(CHARACTER(fLoc), INTEGER(fLen),
			 INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_state)(CHARACTER(fLoc), LOGICAL(fisDefined),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_struc)(CHARACTER(fLoc), LOGICAL(fisAStruct),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_there)(CHARACTER(fLoc), CHARACTER(fName),
			  LOGICAL(fExists), INTEGER(fStatus) 
			  TRAIL(fLoc) TRAIL(fName));
F77_SUBROUTINE(dat_type)(CHARACTER(fLoc), CHARACTER(fType),
			 INTEGER(fStatus) TRAIL(fLoc) TRAIL(fType));
F77_SUBROUTINE(dat_valid)(CHARACTER(fLoc), LOGICAL(fisValid),
			  INTEGER(fStatus) TRAIL(fLoc));
F77_SUBROUTINE(dat_vec)(CHARACTER(fLoc), CHARACTER(fCellLoc), 
			INTEGER(fStatus) 
			TRAIL(fLoc) TRAIL(fVecLoc) );
}


void HDSLib::hds_open(const String& fileName, HDSDef::IOMode mode, 
		      HDSNode& topNode, Int& status) {
  DECLARE_CHARACTER_DYN(fFileName);
  F77_CREATE_CHARACTER(fFileName, fileName.length());
  // The following cast(s) are because cnf_exprt (and related functions) do
  // not understand the concept of "const" arguments.
  cnf_exprt(const_cast<char*>(fileName.chars()), fFileName, fFileName_length);

  const String modeString = HDSDef::name(mode);
  DECLARE_CHARACTER_DYN(fIOMode);
  F77_CREATE_CHARACTER(fIOMode, modeString.length());
  cnf_exprt(const_cast<char*>(modeString.chars()), fIOMode, fIOMode_length);

  DECLARE_CHARACTER(fTopNode, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  F77_CALL(hds_open)(CHARACTER_ARG(fFileName), CHARACTER_ARG(fIOMode), 
		     CHARACTER_ARG(fTopNode), INTEGER_ARG(&fStatus) 
		     TRAIL_ARG(fFileName) TRAIL_ARG(fIOMode)
		     TRAIL_ARG(fTopNode));
  status = fStatus;
  cnf_impch(fTopNode, HDSDef::DAT_SZLOC, topNode.itsLoc.storage());
  F77_FREE_CHARACTER(fFileName);
  F77_FREE_CHARACTER(fIOMode);
}

void HDSLib::hds_new(const String& fileName, const String& nodeName, 
		     const String& nodeType, const IPosition& shape,
		     HDSNode& topNode, Int& status) {
  DECLARE_CHARACTER_DYN(fFileName);
  F77_CREATE_CHARACTER(fFileName, fileName.length());
  cnf_exprt(const_cast<char*>(fileName.chars()), fFileName, fFileName_length);

  DECLARE_CHARACTER_DYN(fNodeName);
  F77_CREATE_CHARACTER(fNodeName, nodeName.length());
  cnf_exprt(const_cast<char*>(nodeName.chars()), fNodeName, fNodeName_length);

  DECLARE_CHARACTER_DYN(fNodeType);
  F77_CREATE_CHARACTER(fNodeType, nodeType.length());
  cnf_exprt(const_cast<char*>(nodeType.chars()), fNodeType, fNodeType_length);

  DECLARE_INTEGER(fNdims);
  fNdims = shape.nelements();

  DECLARE_INTEGER_ARRAY(fDims, fNdims);
  for (Int i = 0; i < fNdims; i++) {
    fDims[i] = shape(i);
  }
  DECLARE_CHARACTER(fTopNode, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  F77_CALL(hds_new)(CHARACTER_ARG(fFileName), CHARACTER_ARG(fNodeName), 
   		    CHARACTER_ARG(fNodeType), INTEGER_ARG(&fNdims),
  		    INTEGER_ARRAY_ARG(fDims), CHARACTER_ARG(fTopNode),
   		    INTEGER_ARG(&fStatus) 
 		    TRAIL_ARG(fFileName) TRAIL_ARG(fNodeName)
 		    TRAIL_ARG(fNodeType) TRAIL_ARG(fTopNode));
  status = fStatus;
  cnf_impch(fTopNode, HDSDef::DAT_SZLOC, topNode.itsLoc.storage());
  F77_FREE_CHARACTER(fFileName);
  F77_FREE_CHARACTER(fNodeName);
  F77_FREE_CHARACTER(fNodeType);
}

void HDSLib::hds_new(const String& fileName, const String& nodeName, 
		     const HDSDef::Type nodeType, const IPosition& shape,
		     HDSNode& topNode, Int& status) {
  HDSLib::hds_new(fileName, nodeName, HDSDef::name(nodeType), shape, 
		  topNode, status);
}

void HDSLib::hds_erase(const HDSNode& topNode, Int& status) {

  DECLARE_CHARACTER(fTopNode, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(topNode.itsLoc.storage()), fTopNode,
	    HDSDef::DAT_SZLOC);
  //  topNode.print();
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(hds_erase)(CHARACTER_ARG(fTopNode), 
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fTopNode));
  status = fStatus;
  //  topNode.print();
}

void HDSLib::hds_show(const HDSDef::showTypes topic, Int& status) {
  String showTypeName;
  if (topic == HDSDef::DATA) {
    showTypeName = "DATA";
  } else if (topic == HDSDef::FILES) {
    showTypeName = "FILES";
  } else {
    showTypeName = "LOCATORS";
  }
  DECLARE_CHARACTER_DYN(fTypeName);
  F77_CREATE_CHARACTER(fTypeName, showTypeName.length());
  cnf_exprt(const_cast<char*>(showTypeName.chars()), fTypeName,
	    fTypeName_length);
  
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(hds_show)(CHARACTER_ARG(fTypeName), 
 		     INTEGER_ARG(&fStatus) TRAIL_ARG(fTypeName));
  status = fStatus;
  F77_FREE_CHARACTER(fTypeName);
}

void HDSLib::hds_state(HDSDef::state& state, Int& status) {
  DECLARE_LOGICAL(fstate);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  F77_CALL(hds_state)(LOGICAL_ARG(&fstate), INTEGER_ARG(&fStatus));

  status = fStatus;

  if (F77_ISTRUE(fstate)) {
    state = HDSDef::ACTIVE;
  } else {
    state = HDSDef::INACTIVE;
  }
}

void HDSLib::hds_stop(Int& status) {
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(hds_stop)(INTEGER_ARG(&fStatus));
  status = fStatus;
}

void HDSLib::hds_trace(const HDSNode& node, Int& nLevels, 
		       String& nodePath, String& fileName, Int& status) {

  DECLARE_CHARACTER(fNode, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(node.itsLoc.storage()), fNode,
	    HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fnLevels);
  fnLevels = nLevels;

  DECLARE_CHARACTER(fNodePath, 512);

  DECLARE_CHARACTER(fFileName, 256);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  F77_CALL(hds_trace)(CHARACTER_ARG(fNode), INTEGER_ARG(&fnLevels),
		      CHARACTER_ARG(fNodePath), CHARACTER_ARG(fFileName),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fNode)
		      TRAIL_ARG(fNodePath) TRAIL_ARG(fFileName));
  nLevels = fnLevels;
  {
    char tmpStr[fNodePath_length + 1];
    cnf_imprt(fNodePath, fNodePath_length, tmpStr);
    nodePath = tmpStr;
  }
  {
    char tmpStr[fFileName_length + 1];
    cnf_imprt(fFileName, fFileName_length, tmpStr);
    fileName = tmpStr;
  }
  status = fStatus;
};

void HDSLib::dat_annul(HDSNode& node, Int& status) {

  DECLARE_CHARACTER(fnode, HDSDef::DAT_SZLOC);
  cnf_expch(node.itsLoc.storage(), fnode, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  F77_CALL(dat_annul)(CHARACTER_ARG(fnode), 
  		      INTEGER_ARG(&fStatus) TRAIL_ARG(fnode));

  status = fStatus;
  cnf_impch(fnode, HDSDef::DAT_SZLOC, node.itsLoc.storage());
}

void HDSLib::dat_cell(const HDSNode& arrLoc, const IPosition& which,
		      HDSNode& cellLoc, Int& status) {
  DECLARE_CHARACTER(fArrLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(arrLoc.itsLoc.storage()), fArrLoc, 
	    HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fNdims);
  fNdims = which.nelements();

  DECLARE_INTEGER_ARRAY(fDims, fNdims);
  for (Int i = 0; i < fNdims; i++) {
    fDims[i] = which(i) + 1;
  }
  DECLARE_CHARACTER(fCellLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_cell)(CHARACTER_ARG(fArrLoc), INTEGER_ARG(&fNdims),
		     INTEGER_ARRAY_ARG(fDims), CHARACTER_ARG(fCellLoc), 
		     INTEGER_ARG(&fStatus) 
		     TRAIL_ARG(fArrLoc) TRAIL_ARG(fCellLoc) );

  status = fStatus;
  cnf_impch(fCellLoc, HDSDef::DAT_SZLOC, cellLoc.itsLoc.storage());
}

void HDSLib::dat_clone(const HDSNode& oldNode, HDSNode& newNode,
		       Int& status) {
  DECLARE_CHARACTER(fOldNode, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(oldNode.itsLoc.storage()), fOldNode,
	    HDSDef::DAT_SZLOC);

  DECLARE_CHARACTER(fNewNode, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_clone)(CHARACTER_ARG(fOldNode), CHARACTER_ARG(fNewNode), 
   		      INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fOldNode) TRAIL_ARG(fNewNode) );

  status = fStatus;
  cnf_impch(fNewNode, HDSDef::DAT_SZLOC, newNode.itsLoc.storage());
}

void HDSLib::dat_find(const HDSNode& parentLoc, const String& compName,
		      HDSNode& compLoc, Int& status) {
  HDSWrapper::dat_find(parentLoc.itsLoc.storage(), compName.chars(),
		       compLoc.itsLoc.storage(), &status);
}

void HDSLib::dat_get0c(const HDSNode& loc, String& value, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  Int len;
  HDSLib::dat_len(loc, len, status);
  DECLARE_CHARACTER_DYN(fvalue);
  F77_CREATE_CHARACTER(fvalue, len);

  F77_CALL(dat_get0c)(CHARACTER_ARG(fLoc), CHARACTER_ARG(fvalue),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc) TRAIL_ARG(fvalue));
  {
    char tmpStr[fvalue_length + 1];
    cnf_imprt(fvalue, fvalue_length, tmpStr);
    value = tmpStr;
  }
  status = fStatus;
  F77_FREE_CHARACTER(fvalue);
}

void HDSLib::dat_get0d(const HDSNode& loc, Double& value, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  DECLARE_DOUBLE(fvalue);
  F77_CALL(dat_get0d)(CHARACTER_ARG(fLoc), DOUBLE_ARG(&fvalue),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  value = fvalue;
  status = fStatus;
}

void HDSLib::dat_get0i(const HDSNode& loc, Int& value, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  DECLARE_INTEGER(fvalue);
  F77_CALL(dat_get0i)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fvalue),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  value = fvalue;
  status = fStatus;
}

void HDSLib::dat_get0l(const HDSNode& loc, Bool& value, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  DECLARE_LOGICAL(fvalue);
  F77_CALL(dat_get0l)(CHARACTER_ARG(fLoc), LOGICAL_ARG(&fvalue),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  if (F77_ISTRUE(fvalue)) {
    value = True;
  } else {
    value = False;
  }
  status = fStatus;
}

void HDSLib::dat_get0r(const HDSNode& loc, Float& value, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  DECLARE_REAL(fvalue);
  F77_CALL(dat_get0r)(CHARACTER_ARG(fLoc), REAL_ARG(&fvalue),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  value = fvalue;
  status = fStatus;
}

void HDSLib::dat_get1c(const HDSNode& loc, Vector<String>& values, 
		       Int& status) {
  IPosition shape(1);
  HDSLib::dat_shape(loc, shape, status);
  values.resize(shape);
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fMaxLen);
  fMaxLen = values.nelements();
  Int stringLen;
  HDSLib::dat_len(loc, stringLen, status);
  DECLARE_CHARACTER_ARRAY(fValues, stringLen, fMaxLen);
  DECLARE_INTEGER(fLen);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_get1c)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fMaxLen), 
 		      CHARACTER_ARRAY_ARG(fValues), INTEGER_ARG(&fLen),
  		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc) 
		      TRAIL_ARG(fValues));
  status = fStatus;
  for (Int i = 0; i < fLen; i++) {
    values(i) = String(fValues[i], cnf_lenf(fValues[i], stringLen));
  }
}

void HDSLib::dat_get1d(const HDSNode& loc, Vector<Double>& values, 
		       Int& status) {
  IPosition shape(1);
  HDSLib::dat_shape(loc, shape, status);
  values.resize(shape);
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fMaxLen);
  fMaxLen = values.nelements();
  DECLARE_INTEGER(fLen);
  DECLARE_DOUBLE_ARRAY(fValues, fMaxLen);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_get1d)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fMaxLen), 
		      DOUBLE_ARRAY_ARG(fValues), INTEGER_ARG(&fLen),
 		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  for (Int i = 0; i < fMaxLen; i++) {
    values(i) = fValues[i];
  }
  status = fStatus;
}

void HDSLib::dat_get1i(const HDSNode& loc, Vector<Int>& values, 
		       Int& status) {
  IPosition shape(1);
  HDSLib::dat_shape(loc, shape, status);
  values.resize(shape);
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fMaxLen);
  fMaxLen = values.nelements();
  DECLARE_INTEGER(fLen);
  DECLARE_INTEGER_ARRAY(fValues, fMaxLen);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_get1i)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fMaxLen), 
		      INTEGER_ARRAY_ARG(fValues), INTEGER_ARG(&fLen),
 		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  for (Int i = 0; i < fMaxLen; i++) {
    values(i) = fValues[i];
  }
  status = fStatus;
}

void HDSLib::dat_get1l(const HDSNode& loc, Vector<Bool>& values, 
		       Int& status) {
  IPosition shape(1);
  HDSLib::dat_shape(loc, shape, status);
  values.resize(shape);
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fMaxLen);
  fMaxLen = values.nelements();
  DECLARE_INTEGER(fLen);
 
  DECLARE_LOGICAL_ARRAY_DYN(fValues); fValues = 0;
  Bool isACopy;
  const Bool sameType = ((sizeof(Bool) == sizeof(F77_LOGICAL_TYPE)) && 
			       (True == F77_TRUE) && 
			       (False == F77_FALSE));
  
  if (sameType) {
    fValues = (F77_LOGICAL_TYPE *) values.getStorage(isACopy);    
  } else {
    F77_CREATE_LOGICAL_ARRAY(fValues, fMaxLen);
  }
  
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_get1l)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fMaxLen), 
		      LOGICAL_ARRAY_ARG(fValues), INTEGER_ARG(&fLen),
 		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
  if (sameType) {
    values.putStorage((Bool *&) fValues, isACopy);
  } else {
    F77_LOGICAL_TYPE * inDataPtr =  fValues;
    Bool * outDataPtr =  values.getStorage(isACopy);
    Bool * const dataEndPtr = outDataPtr + fMaxLen;
    while (outDataPtr < dataEndPtr) {
      if (F77_ISTRUE(*inDataPtr)) {
	*outDataPtr = True;
      } else {
	*outDataPtr = False;
      }
      inDataPtr++; outDataPtr++;
    }
    values.putStorage(outDataPtr, isACopy);
    F77_FREE_LOGICAL(fValues);
    fValues = 0;
  }
}

void HDSLib::dat_get1r(const HDSNode& loc, Vector<Float>& values, 
		       Int& status) {
  IPosition shape(1);
  HDSLib::dat_shape(loc, shape, status);
  values.resize(shape);
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fMaxLen);
  fMaxLen = values.nelements();
  DECLARE_INTEGER(fLen);
  // This assumes that Float and F77_REAL_TYPE are the same data type.
  Bool isACopy;
  F77_REAL_TYPE * fValues = values.getStorage(isACopy);
  
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_get1r)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fMaxLen), 
		      REAL_ARRAY_ARG(fValues), INTEGER_ARG(&fLen),
 		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
  values.putStorage(fValues, isACopy);
}

void HDSLib::dat_getnc(const HDSNode& loc, Array<String>& values, 
		       Int& status) {
  IPosition shape(values.shape()); 
  // Guess that the input Array has been initialised to the right shape. The
  // dat_shape function will resize the IPosition if it is the wrong length,
  // and the resize function (below) will adjust the Array shape if necessary.
  HDSLib::dat_shape(loc, shape, status);
  values.resize(shape);
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fNdims);
  fNdims = shape.nelements();
  DECLARE_INTEGER_ARRAY(fDims, fNdims);
  for (Int i = 0; i < fNdims; i++) {
    fDims[i] = shape(i);
  }
  Int stringLen;
  HDSLib::dat_len(loc, stringLen, status);

  Int fMaxLen = shape.product();
  DECLARE_CHARACTER_ARRAY(fValues, stringLen, fMaxLen);
  DECLARE_INTEGER_ARRAY(fRdims, fNdims);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_getnc)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fNdims),
 		      INTEGER_ARRAY_ARG(fDims), CHARACTER_ARRAY_ARG(fValues), 
 		      INTEGER_ARRAY_ARG(&fRdims), 
 		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc) TRAIL_ARG(fValues));
  status = fStatus;
  Bool isACopy;
  String * dataPtr =  values.getStorage(isACopy);
  String * const dataEndPtr = dataPtr + shape.product();
  Int j = 0;
  while (dataPtr < dataEndPtr) {
    *dataPtr = String(fValues[j], cnf_lenf(fValues[j], stringLen));
    dataPtr++; j++;
  }
  values.putStorage(dataPtr, isACopy);
}

void HDSLib::dat_getnd(const HDSNode& loc, Array<Double>& values, 
		       Int& status) {
  IPosition shape(values.shape()); 
  HDSLib::dat_shape(loc, shape, status);
  values.resize(shape);
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fNdims);
  fNdims = shape.nelements();
  DECLARE_INTEGER_ARRAY(fDims, fNdims);
  for (Int i = 0; i < fNdims; i++) {
    fDims[i] = shape(i);
  }
  // This assumes that Double and F77_DOUBLE_TYPE are the same data type. If
  // this asumption is bad then the Fortran Array would have to be allocated
  // here and then separately copied to the AIPS++ Array. What a performance
  // pig that would be.
  Bool isACopy;
  F77_DOUBLE_TYPE * fValues = values.getStorage(isACopy);

  DECLARE_INTEGER_ARRAY(fRdims, fNdims);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_getnd)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fNdims),
		      INTEGER_ARRAY_ARG(fDims), DOUBLE_ARRAY_ARG(fValues), 
		      INTEGER_ARRAY_ARG(&fRdims), 
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
  values.putStorage(fValues, isACopy);
}

void HDSLib::dat_getni(const HDSNode& loc, Array<Int>& values, 
		       Int& status) {
  IPosition shape(values.shape()); 
  HDSLib::dat_shape(loc, shape, status);
  values.resize(shape);
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fNdims);
  fNdims = shape.nelements();
  DECLARE_INTEGER_ARRAY(fDims, fNdims);
  for (Int i = 0; i < fNdims; i++) {
    fDims[i] = shape(i);
  }
  // This assumes that Int and F77_INTEGER_TYPE are the same data type.
  Bool isACopy;
  F77_INTEGER_TYPE * fValues = values.getStorage(isACopy);
  
  DECLARE_INTEGER_ARRAY(fRdims, fNdims);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_getni)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fNdims),
		      INTEGER_ARRAY_ARG(fDims), INTEGER_ARRAY_ARG(fValues), 
		      INTEGER_ARRAY_ARG(&fRdims), 
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
  values.putStorage(fValues, isACopy);
}

void HDSLib::dat_getnl(const HDSNode& loc, Array<Bool>& values, 
		       Int& status) {
  IPosition shape(values.shape()); 
  HDSLib::dat_shape(loc, shape, status);
  values.resize(shape);
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fNdims);
  fNdims = shape.nelements();
  DECLARE_INTEGER_ARRAY(fDims, fNdims);
  for (Int i = 0; i < fNdims; i++) {
    fDims[i] = shape(i);
  }

  const Bool sameType = ((sizeof(Bool) == sizeof(F77_LOGICAL_TYPE)) && 
			       (True == F77_TRUE) && 
			       (False == F77_FALSE));
  
  DECLARE_LOGICAL_ARRAY_DYN(fValues); fValues = 0;
  Bool isACopy;
  if (sameType) {
    fValues = (F77_LOGICAL_TYPE *) values.getStorage(isACopy);    
  } else {
    F77_CREATE_LOGICAL_ARRAY(fValues, shape.product());
  }
  
  DECLARE_INTEGER_ARRAY(fRdims, fNdims);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_getnl)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fNdims),
 		      INTEGER_ARRAY_ARG(fDims), LOGICAL_ARRAY_ARG(fValues), 
 		      INTEGER_ARRAY_ARG(fRdims), 
 		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
  if (sameType) {
    values.putStorage((Bool *&) fValues, isACopy);
  } else {
    F77_LOGICAL_TYPE * inDataPtr = fValues;
    Bool * outDataPtr =  values.getStorage(isACopy);
    Bool * const dataEndPtr = outDataPtr + shape.product();
    while (outDataPtr < dataEndPtr) {
      if (F77_ISTRUE(*inDataPtr)) {
	*outDataPtr = True;
      } else {
	*outDataPtr = False;
      }
      inDataPtr++; outDataPtr++;
    }
    values.putStorage(outDataPtr, isACopy);
    F77_FREE_LOGICAL(fValues);
    fValues = 0;
  }
}

void HDSLib::dat_getnr(const HDSNode& loc, Array<Float>& values, 
		       Int& status) {
  IPosition shape(values.shape()); 
  HDSLib::dat_shape(loc, shape, status);
  values.resize(shape);
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fNdims);
  fNdims = shape.nelements();
  DECLARE_INTEGER_ARRAY(fDims, fNdims);
  for (Int i = 0; i < fNdims; i++) {
    fDims[i] = shape(i);
  }
  // This assumes that Float and F77_REAL_TYPE are the same data type.
  Bool isACopy;
  F77_REAL_TYPE * fValues = values.getStorage(isACopy);

  DECLARE_INTEGER_ARRAY(fRdims, fNdims);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_getnr)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fNdims),
		      INTEGER_ARRAY_ARG(fDims), REAL_ARRAY_ARG(fValues), 
		      INTEGER_ARRAY_ARG(&fRdims), 
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
  values.putStorage(fValues, isACopy);
}

void HDSLib::dat_index(const HDSNode& loc, Int index, 
		       HDSNode& indexLoc, Int& status){
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fIndex);
  fIndex = index;
  DECLARE_CHARACTER(fIndexLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_index)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fIndex),
		      CHARACTER_ARG(fIndexLoc), INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fLoc) TRAIL_ARG(fIndexLoc));
  status = fStatus;
  cnf_impch(fIndexLoc, HDSDef::DAT_SZLOC, indexLoc.itsLoc.storage());
}

void HDSLib::dat_len(const HDSNode& loc, Int& bytes, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fBytes);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_len)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fBytes), 
		    INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
  bytes = fBytes;
}

void HDSLib::dat_name(const HDSNode& loc, String& name, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_CHARACTER(fName, HDSDef::DAT_SZNAM);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_name)(CHARACTER_ARG(fLoc), CHARACTER_ARG(fName),
		     INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc) TRAIL_ARG(fName));
  status = fStatus;
  char tmpStr[fName_length + 1];
  cnf_imprt(fName, fName_length, tmpStr);
  name = tmpStr;
}

void HDSLib::dat_ncomp(const HDSNode& loc, Int& ncomp, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fNcomp);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_ncomp)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fNcomp),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
  ncomp = fNcomp;
}

void HDSLib::dat_new(const HDSNode& parentLoc, const String& compName, 
		     const String& compType, const IPosition& shape,
		     Int& status) {

  DECLARE_CHARACTER(fparentLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(parentLoc.itsLoc.storage()), fparentLoc,
	    HDSDef::DAT_SZLOC);

  DECLARE_CHARACTER_DYN(fcompName);
  F77_CREATE_CHARACTER(fcompName, compName.length());
  cnf_exprt(const_cast<char*>(compName.chars()), fcompName, fcompName_length);

  DECLARE_CHARACTER_DYN(fcompType);
  F77_CREATE_CHARACTER(fcompType, compType.length());
  cnf_exprt(const_cast<char*>(compType.chars()), fcompType, fcompType_length);

  DECLARE_INTEGER(fNdims);
  fNdims = shape.nelements();

  DECLARE_INTEGER_ARRAY(fDims, fNdims);
  for (Int i = 0; i < fNdims; i++) {
    fDims[i] = shape(i);
  }
  DECLARE_INTEGER(fStatus);
  fStatus = status;

  F77_CALL(dat_new)(CHARACTER_ARG(fparentLoc), CHARACTER_ARG(fcompName), 
		    CHARACTER_ARG(fcompType), INTEGER_ARG(&fNdims),
		    INTEGER_ARRAY_ARG(fDims), INTEGER_ARG(&fStatus) 
		    TRAIL_ARG(fparentLoc) TRAIL_ARG(fcompName)
		    TRAIL_ARG(fcompType));
  status = fStatus;  
  F77_FREE_CHARACTER(fcompName);
  F77_FREE_CHARACTER(fcompType);
}

void HDSLib::dat_new(const HDSNode& parentLoc,
		     const String& compName, const HDSDef::Type nodeType,
		     const IPosition& shape, Int& status) {
  HDSLib::dat_new(parentLoc, compName, HDSDef::name(nodeType), shape, status);
}

void HDSLib::dat_new0d(const HDSNode& parentLoc, const String& compName, 
		       Int& status) {

  DECLARE_CHARACTER(fparentLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(parentLoc.itsLoc.storage()), fparentLoc,
	    HDSDef::DAT_SZLOC);

  DECLARE_CHARACTER_DYN(fcompName);
  F77_CREATE_CHARACTER(fcompName, compName.length());
  cnf_exprt(const_cast<char*>(compName.chars()), fcompName, fcompName_length);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  F77_CALL(dat_new0d)(CHARACTER_ARG(fparentLoc), CHARACTER_ARG(fcompName), 
		      INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fparentLoc) TRAIL_ARG(fcompName));
  status = fStatus;
  F77_FREE_CHARACTER(fcompName);
}

void HDSLib::dat_new0i(const HDSNode& parentLoc, const String& compName, 
		       Int& status) {

  DECLARE_CHARACTER(fparentLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(parentLoc.itsLoc.storage()), fparentLoc,
	    HDSDef::DAT_SZLOC);

  DECLARE_CHARACTER_DYN(fcompName);
  F77_CREATE_CHARACTER(fcompName, compName.length());
  cnf_exprt(const_cast<char*>(compName.chars()), fcompName, fcompName_length);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  F77_CALL(dat_new0i)(CHARACTER_ARG(fparentLoc), CHARACTER_ARG(fcompName), 
		      INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fparentLoc) TRAIL_ARG(fcompName));
  status = fStatus;
  F77_FREE_CHARACTER(fcompName);
}

void HDSLib::dat_new0l(const HDSNode& parentLoc, const String& compName, 
		       Int& status) {

  DECLARE_CHARACTER(fparentLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(parentLoc.itsLoc.storage()), fparentLoc,
	    HDSDef::DAT_SZLOC);

  DECLARE_CHARACTER_DYN(fcompName);
  F77_CREATE_CHARACTER(fcompName, compName.length());
  cnf_exprt(const_cast<char*>(compName.chars()), fcompName, fcompName_length);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  F77_CALL(dat_new0l)(CHARACTER_ARG(fparentLoc), CHARACTER_ARG(fcompName), 
		      INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fparentLoc) TRAIL_ARG(fcompName));
  status = fStatus;
  F77_FREE_CHARACTER(fcompName);
}

void HDSLib::dat_new0r(const HDSNode& parentLoc, const String& compName, 
		       Int& status) {

  DECLARE_CHARACTER(fparentLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(parentLoc.itsLoc.storage()), fparentLoc,
	    HDSDef::DAT_SZLOC);

  DECLARE_CHARACTER_DYN(fcompName);
  F77_CREATE_CHARACTER(fcompName, compName.length());
  cnf_exprt(const_cast<char*>(compName.chars()), fcompName, fcompName_length);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  F77_CALL(dat_new0r)(CHARACTER_ARG(fparentLoc), CHARACTER_ARG(fcompName), 
		      INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fparentLoc) TRAIL_ARG(fcompName));
  status = fStatus;
  F77_FREE_CHARACTER(fcompName);
}

void HDSLib::dat_new0c(const HDSNode& parentLoc, const String& compName, 
		       const Int& stringLength, Int& status) {

  DECLARE_CHARACTER(fparentLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(parentLoc.itsLoc.storage()), fparentLoc,
	    HDSDef::DAT_SZLOC);

  DECLARE_CHARACTER_DYN(fcompName);
  F77_CREATE_CHARACTER(fcompName, compName.length());
  cnf_exprt(const_cast<char*>(compName.chars()), fcompName, fcompName_length);

  DECLARE_INTEGER(fStringLen);
  fStringLen = stringLength;

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  F77_CALL(dat_new0c)(CHARACTER_ARG(fparentLoc), CHARACTER_ARG(fcompName), 
		      INTEGER_ARG(&fStringLen), INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fparentLoc) TRAIL_ARG(fcompName));
  status = fStatus;
  F77_FREE_CHARACTER(fcompName);
}

void HDSLib::dat_new1d(const HDSNode& parentLoc, const String& compName, 
		       const Int& length, Int& status) {
  DECLARE_CHARACTER(fparentLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(parentLoc.itsLoc.storage()), fparentLoc,
	    HDSDef::DAT_SZLOC);
  DECLARE_CHARACTER_DYN(fcompName);
  F77_CREATE_CHARACTER(fcompName, compName.length());
  cnf_exprt(const_cast<char*>(compName.chars()), fcompName, fcompName_length);
  DECLARE_INTEGER(fLen);
  fLen = length;
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_new1d)(CHARACTER_ARG(fparentLoc), CHARACTER_ARG(fcompName), 
		      INTEGER_ARG(&fLen), INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fparentLoc) TRAIL_ARG(fcompName));
  status = fStatus;
  F77_FREE_CHARACTER(fcompName);
}

void HDSLib::dat_new1i(const HDSNode& parentLoc, const String& compName, 
		       const Int& length, Int& status) {
  DECLARE_CHARACTER(fparentLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(parentLoc.itsLoc.storage()), fparentLoc,HDSDef::DAT_SZLOC);
  DECLARE_CHARACTER_DYN(fcompName);
  F77_CREATE_CHARACTER(fcompName, compName.length());
  cnf_exprt(const_cast<char*>(compName.chars()), fcompName, fcompName_length);
  DECLARE_INTEGER(fLen);
  fLen = length;
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_new1i)(CHARACTER_ARG(fparentLoc), CHARACTER_ARG(fcompName), 
		      INTEGER_ARG(&fLen), INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fparentLoc) TRAIL_ARG(fcompName));
  status = fStatus;
  F77_FREE_CHARACTER(fcompName);
}

void HDSLib::dat_new1l(const HDSNode& parentLoc, const String& compName, 
		       const Int& length, Int& status) {
  DECLARE_CHARACTER(fparentLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(parentLoc.itsLoc.storage()), fparentLoc,
	    HDSDef::DAT_SZLOC);
  DECLARE_CHARACTER_DYN(fcompName);
  F77_CREATE_CHARACTER(fcompName, compName.length());
  cnf_exprt(const_cast<char*>(compName.chars()), fcompName, fcompName_length);
  DECLARE_INTEGER(fLen);
  fLen = length;
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_new1l)(CHARACTER_ARG(fparentLoc), CHARACTER_ARG(fcompName), 
		      INTEGER_ARG(&fLen), INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fparentLoc) TRAIL_ARG(fcompName));
  status = fStatus;
  F77_FREE_CHARACTER(fcompName);
}

void HDSLib::dat_new1r(const HDSNode& parentLoc, const String& compName, 
		       const Int& length, Int& status) {
  DECLARE_CHARACTER(fparentLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(parentLoc.itsLoc.storage()), fparentLoc,
	    HDSDef::DAT_SZLOC);
  DECLARE_CHARACTER_DYN(fcompName);
  F77_CREATE_CHARACTER(fcompName, compName.length());
  cnf_exprt(const_cast<char*>(compName.chars()), fcompName, fcompName_length);
  DECLARE_INTEGER(fLen);
  fLen = length;
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_new1r)(CHARACTER_ARG(fparentLoc), CHARACTER_ARG(fcompName), 
		      INTEGER_ARG(&fLen), INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fparentLoc) TRAIL_ARG(fcompName));
  status = fStatus;
  F77_FREE_CHARACTER(fcompName);
}

void HDSLib::dat_new1c(const HDSNode& parentLoc, 
		       const String& compName, const Int& stringLength,
		       const Int& length, Int& status) {
  DECLARE_CHARACTER(fparentLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(parentLoc.itsLoc.storage()), fparentLoc,
	    HDSDef::DAT_SZLOC);
  DECLARE_CHARACTER_DYN(fcompName);
  F77_CREATE_CHARACTER(fcompName, compName.length());
  cnf_exprt(const_cast<char*>(compName.chars()), fcompName, fcompName_length);
  DECLARE_INTEGER(fStringLen);
  fStringLen = stringLength;
  DECLARE_INTEGER(fLen);
  fLen = length;
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_new1c)(CHARACTER_ARG(fparentLoc), CHARACTER_ARG(fcompName), 
		      INTEGER_ARG(&fStringLen), INTEGER_ARG(&fLen),
		      INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fparentLoc) TRAIL_ARG(fcompName));
  status = fStatus;
  F77_FREE_CHARACTER(fcompName);
}

void HDSLib::dat_paren(const HDSNode& childLoc, HDSNode& parentLoc,
		       Int& status) {
  DECLARE_CHARACTER(fChildLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(childLoc.itsLoc.storage()), fChildLoc,
	    HDSDef::DAT_SZLOC);
  DECLARE_CHARACTER(fParentLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_paren)(CHARACTER_ARG(fChildLoc),
		      CHARACTER_ARG(fParentLoc), INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fChildLoc) TRAIL_ARG(fParentLoc));
  status = fStatus;
  cnf_impch(fParentLoc, HDSDef::DAT_SZLOC, parentLoc.itsLoc.storage());
}

void HDSLib::dat_prmry(const Bool& setGet, HDSNode& node, Bool& primary,
		       Int& status){
  DECLARE_LOGICAL(fSetGet);
  if (setGet == True) {
    fSetGet = F77_TRUE;
  } else {
    fSetGet = F77_FALSE;
  }
  DECLARE_CHARACTER(fNode, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(node.itsLoc.storage()), fNode,
	    HDSDef::DAT_SZLOC);

  DECLARE_LOGICAL(fPrimary);
  if (setGet == True) {
    if (primary == True) {
      fPrimary = F77_TRUE;
    } else {
      fPrimary = F77_FALSE;
    }
  }
  DECLARE_INTEGER(fStatus);
  fStatus = status;

  F77_CALL(dat_prmry)(LOGICAL_ARG(&fSetGet), CHARACTER_ARG(fNode), 
   		      LOGICAL_ARG(&fPrimary), INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fNode));
  status = fStatus;
  if (setGet == True) {
    cnf_impch(fNode, HDSDef::DAT_SZLOC, node.itsLoc.storage());
  } else {
    if (F77_ISTRUE(fPrimary)) {
      primary = True;
    } else {
      primary = False;
    }
  }
}

void HDSLib::dat_put0c(const HDSNode& loc, 
		       const String& value, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  DECLARE_CHARACTER_DYN(fvalue);
  F77_CREATE_CHARACTER(fvalue, value.length());
  cnf_exprt(const_cast<char*>(value.chars()), fvalue, fvalue_length);

  F77_CALL(dat_put0c)(CHARACTER_ARG(fLoc), CHARACTER_ARG(fvalue), 
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc) TRAIL_ARG(fvalue));
  status = fStatus;
  F77_FREE_CHARACTER(fvalue);
}

void HDSLib::dat_put0d(const HDSNode& loc, 
		       const Double& value, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  DECLARE_DOUBLE(fvalue);
  fvalue = value;
  F77_CALL(dat_put0d)(CHARACTER_ARG(fLoc), DOUBLE_ARG(&fvalue),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
}

void HDSLib::dat_put0i(const HDSNode& loc, 
		       const Int& value, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  DECLARE_INTEGER(fvalue);
  fvalue = value;
  F77_CALL(dat_put0i)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fvalue),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
}

void HDSLib::dat_put0l(const HDSNode& loc, 
		       const Bool& value, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  DECLARE_LOGICAL(fvalue);
  if (value == True) {
    fvalue = F77_TRUE;
  } else {
    fvalue = F77_FALSE;
  }
  F77_CALL(dat_put0l)(CHARACTER_ARG(fLoc), LOGICAL_ARG(&fvalue),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
}

void HDSLib::dat_put0r(const HDSNode& loc, 
		       const Float& value, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);

  DECLARE_INTEGER(fStatus);
  fStatus = status;

  DECLARE_REAL(fvalue);
  fvalue = value;
  F77_CALL(dat_put0r)(CHARACTER_ARG(fLoc), REAL_ARG(&fvalue),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
}

void HDSLib::dat_put1c(const HDSNode& loc, const Vector<String>& values,
		       Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fLen);
  fLen = values.nelements();
  Int stringLen;
  HDSLib::dat_len(loc, stringLen, status);
  DECLARE_CHARACTER_ARRAY(fValues, stringLen, fLen);
  for (Int i = 0; i < fLen; i++) {
    cnf_exprt(const_cast<char*>(values(i).chars()), fValues[i], stringLen);
  }
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_put1c)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fLen),
 		      CHARACTER_ARRAY_ARG(fValues), INTEGER_ARG(&fStatus)
 		      TRAIL_ARG(fLoc) TRAIL_ARG(fValues));
  status = fStatus;
}

void HDSLib::dat_put1d(const HDSNode& loc, const Vector<Double>& values,
		       Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  DECLARE_INTEGER(fLen);
  fLen = values.nelements();
  DECLARE_DOUBLE_ARRAY(fValues, fLen);
  for (Int i = 0; i < fLen; i++) {
    fValues[i] = values(i);
  }
  F77_CALL(dat_put1d)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fLen),
		      DOUBLE_ARRAY_ARG(fValues), INTEGER_ARG(&fStatus)
		      TRAIL_ARG(fLoc));
  status = fStatus;
}

void HDSLib::dat_put1i(const HDSNode& loc, const Vector<Int>& values,
		       Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  DECLARE_INTEGER(fLen);
  fLen = values.nelements();
  DECLARE_INTEGER_ARRAY(fValues, fLen);
  for (Int i = 0; i < fLen; i++) {
    fValues[i] = values(i);
  }
  F77_CALL(dat_put1i)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fLen),
		      INTEGER_ARRAY_ARG(fValues), INTEGER_ARG(&fStatus)
		      TRAIL_ARG(fLoc));
  status = fStatus;
}

void HDSLib::dat_put1l(const HDSNode& loc, const Vector<Bool>& values,
		       Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  DECLARE_INTEGER(fLen);
  fLen = values.nelements();

  const Bool sameType = ((sizeof(Bool) == sizeof(F77_LOGICAL_TYPE)) && 
			       (True == F77_TRUE) && 
			       (False == F77_FALSE));
  
  DECLARE_LOGICAL_ARRAY_DYN(fValues); fValues = 0;
  Bool isACopy;
  if (sameType) {
    fValues = (F77_LOGICAL_TYPE *) values.getStorage(isACopy);    
  } else {
    F77_CREATE_LOGICAL_ARRAY(fValues, fLen);
    for (Int i = 0; i < fLen; i++) {
      if (values(i) == True) {
	fValues[i] = F77_TRUE;
      } else {
	fValues[i] = F77_FALSE;
      }
    }
  }

  F77_CALL(dat_put1l)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fLen),
		      LOGICAL_ARRAY_ARG(fValues), INTEGER_ARG(&fStatus)
		      TRAIL_ARG(fLoc));
  status = fStatus;
  if (sameType) {
    values.freeStorage((const Bool *&) fValues, isACopy);
  } else {
    F77_FREE_LOGICAL(fValues);
    fValues = 0;
  }
}

void HDSLib::dat_put1r(const HDSNode& loc, const Vector<Float>& values,
		       Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  DECLARE_INTEGER(fLen);
  fLen = values.nelements();
  DECLARE_REAL_ARRAY(fValues, fLen);
  for (Int i = 0; i < fLen; i++) {
    fValues[i] = values(i);
  }
  F77_CALL(dat_put1r)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fLen),
		      REAL_ARRAY_ARG(fValues), INTEGER_ARG(&fStatus)
		      TRAIL_ARG(fLoc));
  status = fStatus;
}

void HDSLib::dat_putnr(const HDSNode& loc, const Array<Float>& values,
		       Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  DECLARE_INTEGER(fLen);
  fLen = values.nelements();
  Bool isAcopy;
  // This assumes that Float and F77_REAL_TYPE are the same data type.
  const F77_REAL_TYPE * fValues = values.getStorage(isAcopy);
  F77_CALL(dat_put1r)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fLen),
		      REAL_ARRAY_ARG(fValues), INTEGER_ARG(&fStatus)
		      TRAIL_ARG(fLoc));
  values.freeStorage(fValues, isAcopy);
  status = fStatus;
}

// void HDSLib::dat_ref(const HDSNode& loc, String& refname, Int& status) {
//   DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
//   cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  

//   DECLARE_INTEGER(fStatus);
//   fStatus = status;
//   F77_CALL(dat_ref)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fMaxDim),
// 		    INTEGER_ARRAY_ARG(fDims), INTEGER_ARG(&fNDims),
// 		    INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
//   status = fStatus;
// }

void HDSLib::dat_shape(const HDSNode& loc, IPosition& shape,
		       Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fMaxDim);
  fMaxDim = 7;
  DECLARE_INTEGER_ARRAY(fDims, fMaxDim);
  DECLARE_INTEGER(fNDims);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_shape)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fMaxDim),
		      INTEGER_ARRAY_ARG(fDims), INTEGER_ARG(&fNDims),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  shape.resize(fNDims);
  for (Int i = 0; i < fNDims; i++) {
    shape(i) = fDims[i];
  }
  status = fStatus;
}

void HDSLib::dat_size(const HDSNode& loc, Int& length, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fLen);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_size)(CHARACTER_ARG(fLoc), INTEGER_ARG(&fLen),
		     INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  length = fLen;
  status = fStatus;
}

void HDSLib::dat_state(const HDSNode& loc, Bool& isDefined, 
		       Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_LOGICAL(fisDefined);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_state)(CHARACTER_ARG(fLoc), LOGICAL_ARG(&fisDefined),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
  if (F77_ISTRUE(fisDefined)) {
    isDefined = True;
  } else {
    isDefined = False;
  }
}

void HDSLib::dat_struc(const HDSNode& loc, Bool& isAStructure, 
		       Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_LOGICAL(fisAStruct);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_struc)(CHARACTER_ARG(fLoc), LOGICAL_ARG(&fisAStruct),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
  if (F77_ISTRUE(fisAStruct)) {
    isAStructure = True;
  } else {
    isAStructure = False;
  }
}

void HDSLib::dat_there(const HDSNode& loc, const String& name, 
		       Bool& exists, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_CHARACTER(fName, name.length());
  cnf_exprt(const_cast<char*>(name.chars()), fName, fName_length);
  DECLARE_LOGICAL(fExists);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_there)(CHARACTER_ARG(fLoc), CHARACTER_ARG(fName),
		      LOGICAL_ARG(&fExists), INTEGER_ARG(&fStatus) 
		      TRAIL_ARG(fLoc) TRAIL_ARG(fName));
  status = fStatus;
  if (F77_ISTRUE(fExists)) {
    exists = True;
  } else {
    exists = False;
  }
}

void HDSLib::dat_type(const HDSNode& loc, String& type, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_CHARACTER(fType, HDSDef::DAT_SZTYP);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_type)(CHARACTER_ARG(fLoc), CHARACTER_ARG(fType),
		     INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc) TRAIL_ARG(fType));
  status = fStatus;
  char tmpStr[fType_length + 1];
  cnf_imprt(fType, fType_length, tmpStr);
  type = tmpStr;
}

void HDSLib::dat_type(const HDSNode& loc, HDSDef::Type& type, 
		      Int& status) {
  String typeName;
  HDSLib::dat_type(loc, typeName, status);
  if (status == HDSDef::SAI_OK) {
    type = HDSDef::type(typeName);
  }
}

void HDSLib::dat_valid(const HDSNode& loc, Bool& isValid, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_LOGICAL(fisValid);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_valid)(CHARACTER_ARG(fLoc), LOGICAL_ARG(&fisValid),
		      INTEGER_ARG(&fStatus) TRAIL_ARG(fLoc));
  status = fStatus;
  if (F77_ISTRUE(fisValid)) {
    isValid = True;
  } else {
    isValid = False;
  }
}

void HDSLib::dat_vec(const HDSNode& loc, HDSNode& vecLoc, Int& status) {
  DECLARE_CHARACTER(fLoc, HDSDef::DAT_SZLOC);
  cnf_expch(const_cast<char*>(loc.itsLoc.storage()), fLoc, HDSDef::DAT_SZLOC);
  DECLARE_CHARACTER(fVecLoc, HDSDef::DAT_SZLOC);
  DECLARE_INTEGER(fStatus);
  fStatus = status;
  F77_CALL(dat_vec)(CHARACTER_ARG(fLoc), CHARACTER_ARG(fVecLoc), 
		    INTEGER_ARG(&fStatus) 
		    TRAIL_ARG(fLoc) TRAIL_ARG(fVecLoc) );
  
  status = fStatus;
  cnf_impch(fVecLoc, HDSDef::DAT_SZLOC, vecLoc.itsLoc.storage());
}

#endif 
// Local Variables: 
// compile-command: "gmake HDSLib"
// End:
