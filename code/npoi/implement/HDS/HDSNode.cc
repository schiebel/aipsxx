//# HDSnode.cc:
//# Copyright (C) 1997,1999,2000,2001
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
//# $Id: HDSNode.cc,v 19.1 2004/08/25 05:49:26 gvandiep Exp $

#if defined(HAVE_HDS)
#include <npoi/HDS/HDSNode.h>
#include <npoi/HDS/HDSDef.h>
#include <npoi/HDS/HDSLib.h>
#include <casa/Exceptions/Error.h>
#include <casa/Utilities/Assert.h>
#include <casa/iostream.h>
#include <iomanip.h>

HDSNode::HDSNode()
  :itsLoc(HDSDef::DAT_SZLOC) 
{
  reset();
  AlwaysAssert(isValid() == False, AipsError);
}

HDSNode::~HDSNode() {
  annul();
}

HDSNode::HDSNode(const HDSNode& other)
  :itsLoc(HDSDef::DAT_SZLOC) 
{
  clone(other);
}

HDSNode& HDSNode::operator=(const HDSNode& other) {
  if (this != &other) {
    annul();
    clone(other);
  }
  return *this;
}

Bool HDSNode::isValid() const {
  // I can bypass calls to HDSLIB by seeing if the HDSNode is the guaranteed
  // invalid value
  {
    uInt i = 0, strlen = (HDSDef::DAT_NOLOC).length();
    while(i < strlen && 
	  itsLoc[i] == (HDSDef::DAT_NOLOC).elem(i)) {
      i++;
    }
    if (i == strlen) {
      return False;
    }
  }
  Int status = HDSDef::SAI_OK;
  HDSDef::state currentState = HDSDef::INACTIVE;
  HDSLib::hds_state(currentState, status);
  if (status != HDSDef::SAI_OK) {
    throw(AipsError(" HDSNode::isValid - Could not determine the state of the HDS system"));
  }
  if (currentState == HDSDef::INACTIVE) {
    return False;
  }
  Bool retVal;
  HDSLib::dat_valid(*this, retVal, status);
  return retVal;
}

Bool HDSNode::isPrimary() const {
  Int status = HDSDef::SAI_OK;
  Bool set = False, isPrimary;
  HDSLib::dat_prmry(set, const_cast<HDSNode&>(*this), isPrimary, status);
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSNode::isPrimary - Could not determine if the HDSNode is a primary one"));
  }
  return isPrimary;
}

void HDSNode::print() const {
  if (isValid() == False) {
    cout << "Invalid HDSNode";
  } else {
    if (isPrimary() == True) {
      cout << "Primary ";
    }
    for (uInt j = 0; j < HDSDef::DAT_SZLOC; j++) {
      cout << "|" << setbase(16) << (uShort) itsLoc[j];
    }
    cout << "|";
  }
  cout << endl;
}

void HDSNode::reset() {
  for (uInt i = 0; i < (HDSDef::DAT_NOLOC).length(); i++)
    itsLoc[i] = (HDSDef::DAT_NOLOC).elem(i);
}

void HDSNode::annul() {
  if (isValid() == True) {
    Int status = HDSDef::SAI_OK;
    HDSLib::dat_annul(*this, status);
    if (status != HDSDef::SAI_OK) {
      throw(AipsError("HDSNode::annul - Could not annul a HDSNode"));
    }
    AlwaysAssert(isValid() == False, AipsError);
  }
}

void HDSNode::clone(const HDSNode& other) {
  Int status = HDSDef::SAI_OK;
  HDSLib::dat_clone(other, *this, status);
  if (status != HDSDef::SAI_OK) {
    throw(AipsError("HDSNode::clone - Could not copy a HDSNode"));
  }
  if (other.isPrimary() == True) {
    Bool set = True, isPrimary = True;
    HDSLib::dat_prmry(set, *this, isPrimary, status);
    if (status != HDSDef::SAI_OK) {
      throw(AipsError("HDSNode::clone - Could change the HDSNode to a primary one"));
    }
  }
}
#endif
// Local Variables: 
// compile-command: "gmake HDSNode"
// End: 
