//# MultiWCHolder.cc: Holder of multiple WorldCanvasHolders for panelling
//# Copyright (C) 2000,2001,2002,2003
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
//# $Id: MultiWCHolder.cc,v 19.7 2005/06/15 17:56:28 cvsmgr Exp $

#include <casa/aips.h>
#include <display/Display/WorldCanvasHolder.h>
#include <display/Display/WorldCanvas.h>
#include <display/DisplayDatas/DisplayData.h>
#include <display/DisplayDatas/PrincipalAxesDD.h>
#include <display/Display/AttributeBuffer.h>
#include <display/Display/AttValTol.h>
#include <display/Display/MultiWCHolder.h>
#include <casa/BasicMath/Math.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default constructor.
MultiWCHolder::MultiWCHolder() :
  itsBLength(0), itsBIndex(0),
  itsHoldCount(0),
  itsRefreshHeld(False) {
  setBIndexName();
}

// Constructor for a single WorldCanvasHolder.
MultiWCHolder::MultiWCHolder(WorldCanvasHolder &holder) :
  itsHoldCount(0),
  itsRefreshHeld(False) {
  setBIndexName();
  addWCHolder(holder);
}

// Destructor.
MultiWCHolder::~MultiWCHolder() {
}

// Add/remove WorldCanvasHolder/s.
void MultiWCHolder::addWCHolder(WorldCanvasHolder &holder) {
  if (isAlreadyRegistered(holder)) {
    return;
  }
  ListIter<WorldCanvasHolder *> localWCHLI(itsWCHList);
  localWCHLI.toEnd();
  localWCHLI.addRight(&holder);
  for (Int i = 0; i < itsHoldCount; i++) {
    holder.worldCanvas()->hold();
  }
  installRestrictions(holder);  
  addAllDisplayDatas(holder);
}
void MultiWCHolder::removeWCHolder(WorldCanvasHolder &holder) {
  if (!isAlreadyRegistered(holder)) {
    return;
  }
  removeAllDisplayDatas(holder,True);
  ListIter<WorldCanvasHolder *> localWCHLI(itsWCHList);
  localWCHLI.toStart();
  while (!localWCHLI.atEnd()) {
    if (&holder == localWCHLI.getRight()) {
      localWCHLI.removeRight();
      return;
    } else {
      localWCHLI++;
    }
  }
}
void MultiWCHolder::removeWCHolders() {
  ListIter<WorldCanvasHolder *> localWCHLI(itsWCHList);
  localWCHLI.toStart();
  while (!localWCHLI.atEnd()) {
    localWCHLI.removeRight();
    if (!localWCHLI.atEnd()) {
      localWCHLI++;
    }
  }
}

// Add/remove DisplayData/s.
void MultiWCHolder::addDisplayData(DisplayData &displaydata) {
  if (isAlreadyRegistered(displaydata)) {
    return;
  }
  hold();
  ListIter<DisplayData *> localDDLI(itsDDList);
  localDDLI.toEnd();
  localDDLI.addRight(&displaydata);
  addToAllWorldCanvasHolders(displaydata);

  DisplayData* dd = &displaydata;	// (need pointer version below)
  if(isBlinkDD(dd)) {

    // add a 'bIndex' restriction to newly-added DD.  It can be used to
    // alternate display of the various DDs by placing a similar restriction
    // on the WCHs.  The index is its order in itsBlinkDDs (which may change,
    // if DDs before it are removed).

    Int ddsBIndex = itsBLength++;
    itsBlinkDDs.resize(itsBLength, True);
    itsBlinkDDs[ddsBIndex]=dd;
    Attribute bIndexAtt(itsBIndexName, ddsBIndex);
    dd->setRestriction(bIndexAtt);
  }

  refresh();
  release();
}


void MultiWCHolder::removeDisplayData(DisplayData &displaydata) {

  if (!isAlreadyRegistered(displaydata)) return;

  hold();
  removeFromAllWorldCanvasHolders(displaydata);
  ListIter<DisplayData *> localDDLI(itsDDList);
  localDDLI.toStart();
  DisplayData* dd = &displaydata;
  while (!localDDLI.atEnd()) {
    if (dd == localDDLI.getRight()) {

      // DD found in main list--remove it..

      localDDLI.removeRight();

      if(isBlinkDD(dd)) {

        // Remove from blink DD 'list' (Block) too.  Adjust
	// blink index restrictions as necessary.

	dd->removeRestriction(itsBIndexName);
		// No point in leaving blink restriction hanging on the dd.

	Bool found=False;
	for(Int ddBIndex=0; ddBIndex<itsBLength; ddBIndex++) {
	  DisplayData* searchDD =
	               static_cast<DisplayData*>(itsBlinkDDs[ddBIndex]);

	  if(found) {

	    // DDs past the one being removed move back in the blinkDD list.
	    // Their bIndex restriction must also be decremented.

	    Int newddBIndex=ddBIndex-1;
	    itsBlinkDDs[newddBIndex]=searchDD;
	    Attribute bIndexAtt(itsBIndexName, newddBIndex);
	    searchDD->setRestriction(bIndexAtt);  }

	  else if(dd==searchDD) {
	    // dd found in blinkDD list--it will be removed.
	    found=True;
	    if(itsBIndex>ddBIndex) itsBIndex--;  }  }
		// itsBIndex is communicated to the animator, and becomes the
		// WCH blink restriction setting.  It should be decremented
		// if it was selecting a DD past the one deleted, in order
		// to continue selecting the same DD.

	if(found) {		// (should be True).
	  itsBLength--;
	  itsBIndex = max(0, min(itsBLength-1, itsBIndex));  }  }
		// Assure itsBIndex is in proper range

      break;  }

    else localDDLI++;  }

  refresh();
  release();
}


void MultiWCHolder::removeDisplayDatas() {
  hold();
  ListIter<DisplayData *> localDDLI(itsDDList);
  localDDLI.toStart();
  while (!localDDLI.atEnd()) {
    DisplayData* dd = localDDLI.getRight();
    removeFromAllWorldCanvasHolders(*dd);
    localDDLI.removeRight();
    if(isBlinkDD(dd)) dd->removeRestriction(itsBIndexName);
  }
  itsBLength = itsBIndex = 0;
  refresh();
  release();
}


// Install/remove restriction/s.
void MultiWCHolder::setRestriction(const Attribute &restriction) {
  itsAttributes.set(restriction);
  distributeRestrictions();
}
void MultiWCHolder::setRestrictions(const AttributeBuffer &restrictions) {
  itsAttributes.set(restrictions);
  distributeRestrictions();
}
void MultiWCHolder::removeRestriction(const String &name) {
    String nm = (name=="bIndex")?  itsBIndexName : name;
    itsAttributes.remove(nm);
    ListIter<WorldCanvasHolder*> wchs(itsWCHList);
    for(; !wchs.atEnd(); wchs++) wchs.getRight()->removeRestriction(nm);
}

void MultiWCHolder::removeRestrictions() {
  itsAttributes.clear();
  distributeRestrictions();
	// dk note: line above accomplishes nothing; restrictions remain on
	// WCHs at present, i.e. this routine doesn't work.
	// (Implementation was never finished; to be fixed).
}

// Distribute restrictions linearly.
void MultiWCHolder::setLinearRestrictions(AttributeBuffer &restrictions,
					  const AttributeBuffer &increments) {
  ListIter<WorldCanvasHolder *> localWCHLI(itsWCHList);
  localWCHLI.toStart();

  AttributeBuffer rstrs=restrictions; adjustBIndexName(rstrs);
  AttributeBuffer incrs=increments;   adjustBIndexName(incrs);
	// Same buffers, except with modified name of 'bIndex' attribute.

  Int bInd;
  Bool BIExists = ( itsBLength>0 &&
		    rstrs.getValue(itsBIndexName, bInd) &&
		    bInd>=0 );
		// There are blink DDs to control, and a bIndex
		// restriction (with a reasonable value) exists.

  if(BIExists) itsBIndex=bInd;
		// Maintain internal record of animator bIndex setting.
		// When DDs are removed, its appropriate value may change,
		// and is communicated back to the animator.

  while (!localWCHLI.atEnd()) {
    localWCHLI.getRight()->setRestrictions(rstrs);
    if (!localWCHLI.atEnd()) {
      restrictions += increments;
	  // to retain (dubious) semantics of 'restrictions' return value...
      rstrs += incrs;

      if(BIExists) {

        // Do a modulo-length adjustment to blink index, so that there
	// are no empty panels.  (In my opinion, this should be done for
	// zIndex as well.  (dk)).

        rstrs.getValue(itsBIndexName, bInd);
	if(bInd<0 || bInd>=itsBLength) {
          bInd = max(0,bInd) % itsBLength;
	  restrictions.set("bIndex", bInd);
	  rstrs.set(itsBIndexName, bInd);
	}
      }

    }
    localWCHLI++;
  }
  refresh();
}

void MultiWCHolder::hold() {
  itsHoldCount++;
  ListIter<WorldCanvasHolder *> localWCHLI(itsWCHList);
  localWCHLI.toStart();
  while (!localWCHLI.atEnd()) {
    localWCHLI.getRight()->worldCanvas()->hold();
    localWCHLI++;
  }
}
void MultiWCHolder::release() {
  itsHoldCount--;
  if (itsHoldCount <= 0) {
    itsHoldCount = 0;
    if (itsRefreshHeld) {
      refresh(itsHeldReason);
    }
    itsRefreshHeld = False;
  }
  ListIter<WorldCanvasHolder *> localWCHLI(itsWCHList);
  localWCHLI.toStart();
  while (!localWCHLI.atEnd()) {
    localWCHLI.getRight()->worldCanvas()->release();
    localWCHLI++;
  }
}
void MultiWCHolder::refresh(const Display::RefreshReason &reason) {  
  if (itsHoldCount) {
    if (!itsRefreshHeld) { // store only first reason
      itsRefreshHeld = True;
      itsHeldReason = reason;
    }
  } else {    
    ListIter<WorldCanvasHolder *> localWCHLI(itsWCHList);
    localWCHLI.toStart();
    while (!localWCHLI.atEnd()) {
      localWCHLI.getRight()->refresh(reason);
      localWCHLI++;
    }
  }
}

// Do we already have this WorldCanvasHolder/DisplayData registered?
const Bool MultiWCHolder::isAlreadyRegistered(const WorldCanvasHolder 
					      &holder) {
  ListIter<WorldCanvasHolder *> localWCHLI(itsWCHList);
  localWCHLI.toStart();
  while (!localWCHLI.atEnd()) {
    if (&holder == localWCHLI.getRight()) {
      return True;
    }
    localWCHLI++;
  }
  return False;
}
const Bool MultiWCHolder::isAlreadyRegistered(const DisplayData &displaydata) {
  ListIter<DisplayData *> localDDLI(itsDDList);
  localDDLI.toStart();
  while (!localDDLI.atEnd()) {
    if (&displaydata == localDDLI.getRight()) {
      return True;
    }
    localDDLI++;
  }
  return False;
}

// Add/remove all the DisplayDatas to/from a WorldCanvasHolder.
void MultiWCHolder::addAllDisplayDatas(WorldCanvasHolder &holder) {
  ListIter<DisplayData *> localDDLI(itsDDList);
  localDDLI.toStart();
  while (!localDDLI.atEnd()) {
    holder.addDisplayData(localDDLI.getRight());
    localDDLI++;
  }
}
void MultiWCHolder::removeAllDisplayDatas(WorldCanvasHolder &holder,
					  const Bool& permanent) {
  ListIter<DisplayData *> localDDLI(itsDDList);
  localDDLI.toStart();
  while (!localDDLI.atEnd()) {
    holder.removeDisplayData(*(localDDLI.getRight()), True);
    localDDLI++;
  }
}

// Add/remove a DisplayData to/from all WorldCanvasHolders.
void MultiWCHolder::addToAllWorldCanvasHolders(DisplayData &displaydata) {
  ListIter<WorldCanvasHolder *> localWCHLI(itsWCHList);
  localWCHLI.toStart();
  while (!localWCHLI.atEnd()) {    
    localWCHLI.getRight()->addDisplayData(&displaydata);
    localWCHLI++;
  }
}
void MultiWCHolder::removeFromAllWorldCanvasHolders(DisplayData &displaydata) {
  ListIter<WorldCanvasHolder *> localWCHLI(itsWCHList);
  localWCHLI.toStart();
  while (!localWCHLI.atEnd()) {
    localWCHLI.getRight()->removeDisplayData(displaydata);
    localWCHLI++;
  }
}

// Distribute restrictions to all WorldCanvasHolders.
void MultiWCHolder::distributeRestrictions() {
  ListIter<WorldCanvasHolder *> localWCHLI(itsWCHList);
  localWCHLI.toStart();
  while (!localWCHLI.atEnd()) {
    WorldCanvasHolder *holder = localWCHLI.getRight();
    //holder->removeRestrictions();
    holder->setRestrictions(itsAttributes);
    localWCHLI++;
  }
}
// Install restrictions on a specific WorldCanvasHolder.
void MultiWCHolder::installRestrictions(WorldCanvasHolder &holder) {
  if (isAlreadyRegistered(holder)) {
    //holder.removeRestrictions();
    holder.setRestrictions(itsAttributes);
  }
}
// This will return the maximum 'nelements' (Z axis length) of all
// dds compatible with current canvas coordinates.  (Continuum image
// can be viewed along with selected channel of spectral image, e.g.).
uInt MultiWCHolder::zLength() {
  uInt length = 0;
  if (itsWCHList.len() > 0) {
    ListIter<WorldCanvasHolder*> wchs(itsWCHList);
    length = wchs.getRight()->nelements();  }
	// Returns the value of the first wch (should be the same for
	// all of them).
  return length;
}

// Determines which DDs will be restricted, which are always active.
// May need refinement later; for now, blink Raster PADDs only; do not 
// restrict other DDs.  (Contour DDs will always show, e.g.).
// (Note that GTkPanelDisplay assumes that isBlinkDD() is False for
// GTkDrawingDDs, at present).
// (12/04: This should probably be a DD method instead, so MWCH doesn't
// need to know about various DD classes...).
Bool MultiWCHolder::isBlinkDD(DisplayData *dd) {
  return  dd->classType() == Display::Raster   &&  
	   dynamic_cast<PrincipalAxesDD*>(dd) != 0;
}

// (permanently) sets itsBIndexName (below).  Called only in constructor.
void MultiWCHolder::setBIndexName() {
  ostringstream os; os<<"bIndex"<<this;
  itsBIndexName=String(os);
}

// Adjust "bIndex" Attribute's name to include ID of this MWCH.
void MultiWCHolder::adjustBIndexName(AttributeBuffer& rstrs) {
  if(!rstrs.exists("bIndex")) return;
  Attribute bIndexAtt(itsBIndexName, *(rstrs.getAttributeValue("bIndex")));
  rstrs.remove("bIndex");
  rstrs.set(bIndexAtt);
}

// Return number of blink DDs, current appropriate blink index.  Sent to
// animator (by GtkPanelDisplay, actually) when DDs are added, removed.
// The animator in turn actually orders the bIndex 'LinearRestrictions'
// to be set or removed on the WCHs.
Int MultiWCHolder::bLength() { return itsBLength; }
Int MultiWCHolder::bIndex() { return itsBIndex; }



} //# NAMESPACE CASA - END

