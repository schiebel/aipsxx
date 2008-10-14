//# X11PCCaching.cc: implementation of X11PixelCanvas caching mechanism
//# Copyright (C) 1993,1994,1995,1996,1998,1999,2000,2001,2002
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
// $Id: X11PCCaching.cc,v 19.4 2005/06/15 17:56:36 cvsmgr Exp $

#include <display/Display/X11PixelCanvas.h>
#include <casa/Exceptions/Error.h>
#include <casa/IO/AipsIO.h>
#include <casa/Utilities/Assert.h>
#include <casa/Logging/LogIO.h>
#include <casa/iostream.h>
#include <display/Display/X11PCDLDisplayList.h>

namespace casa { //# NAMESPACE CASA - BEGIN

uInt X11PixelCanvas::pickListID() {
  Bool found = False;
  uInt id = 0;
  uInt size = displayList_.nelements();
  
  // select an id that isn't occupied
  for (uInt i = 0; (i < size) && !found; i++) {
    if (!displayList_[i]) { 
      id = i; 
      found = True;
    }
  }

  if (!found) {
    // resize the blocks
    displayList_.resize(2*size);
    listCount_.resize(2*size);
    for (uInt j = size; j < 2 * size; j++) {
      displayList_[j] = 0;
      listCount_[j] = 0;
    }
    id = size;
  }

  return id;
}

// begin caching display commands - return list ID
uInt X11PixelCanvas::newList() {
  if (drawMode() == Display::Compile) {
    throw(AipsError("Cannot nest newList()"));
  }
  
  // turn on compile flag
  setDrawMode(Display::Compile);

  // pick a new list id
  currentList_ = pickListID();

  // create a new list - initialize with 16 slots for display list lists
  displayList_[currentList_] =
    new PtrBlock<X11PCDisplayListObject *>(16, (X11PCDisplayListObject*)0);  

  // return the id
  return currentList_;
}

// end caching display commands
void X11PixelCanvas::endList() {
  if (drawMode() != Display::Compile) {
    throw(AipsError("endList() found without newList()"));
  }

  // compactDisplayList is buggy, and causes pure virtual function
  // calls, segmentation faults etc.  Switch this optimisation off
  // for the time being, and readdress it at a later date.  This
  // display list optimisation is probably not buying a lot in 
  // efficiency anyway.  I'm sure the bug will have something to
  // do with accidental deletion or PtrBlock resizing.
#if 0
  compactDisplayList(displayList_[currentList_], currentDLCount_);
  listCount_[currentList_] = displayList_[currentList_]->nelements();
#else
  listCount_[currentList_] = currentDLCount_;
#endif

  setDrawMode(Display::Draw);
  currentDLCount_ = 0;
}

void X11PixelCanvas::translateAllLists(Int xt, Int yt) {
  for (uInt i = 0; i < displayList_.nelements(); i++) {
    if (displayList_[i] != 0) {
      translateList(i, xt, yt);
    }
  }
}

void X11PixelCanvas::translateList(uInt list, Int xt, Int yt) {
  if (!validList(list)) {
    throw(AipsError("X11PixelCanvas::translateList() - invalid list"));
  }
  PtrBlock<X11PCDisplayListObject *> *l = displayList_[list];
  for (uInt i = 0; i < listCount_[list]; i++) {
    X11PCDisplayListObject *o = (*l)[i];
    if (o) {
      o->translate(xt, yt);
    }
  }
}

// recall cached display commands
void X11PixelCanvas::drawList(uInt list) {
  if (!validList(list)) {
    throw(AipsError("X11PixelCanvas::drawList() - invalid list"));
  }

  if (drawMode() == Display::Draw) {
    // draw the list if we are in draw mode
    PtrBlock<X11PCDisplayListObject *> *l = displayList_[list];
    for (uInt i = 0; i < listCount_[list]; i++) {
      X11PCDisplayListObject *o = (*l)[i];
      if (o) {
	if (drawToPixmap()) {
	  o->draw(display_, pixmap_, gc_, xTranslation(), yTranslation());
	}
	if (drawToWindow()) {
	  o->draw(display_, drawWindow_, gc_, xTranslation(), yTranslation());
	}
      }
    }
  } else {
    // compile mode - create an object that represents the list
    appendToDisplayList(new X11PCDLDisplayList(this, list));
  }
}

// remove list from cache
void X11PixelCanvas::deleteList(uInt list) {
  if (!validList(list)) {
    throw(AipsError("X11PixelCanvas::deleteList() - invalid list"));
  }
  for (uInt i = 0; i < displayList_[list]->nelements(); i++) {
    delete (*displayList_[list])[i];
    (*displayList_[list])[i] = 0;
  }
  delete displayList_[list];
  displayList_[list] = 0;
  listCount_[list] = 0;
}

// flush all lists from the cache
void X11PixelCanvas::deleteLists() {
  for (uInt i = 0; i < displayList_.nelements(); i++) {
    if (displayList_[i] != 0) {
      deleteList(i);
    }
  }
}

// return True if the list exists
Bool X11PixelCanvas::validList(uInt list) {
  if (list >= displayList_.nelements()) {
    return False;
  } else {
    return (displayList_[list] != 0);
  }
}

void X11PixelCanvas::appendToDisplayList(X11PCDisplayListObject *obj) {
  if (drawMode() != Display::Compile) {
    throw(AipsError("appendToDisplayList() called while not in compile mode"));
  }

  PtrBlock<X11PCDisplayListObject *> *l = displayList_[currentList_];
  if (!l) {
    throw(AipsError("appendToDisplayList() called for invalid current list"));
  }

  if (currentDLCount_ == l->nelements()) {
    l->resize(2*l->nelements());
    for (uInt i = currentDLCount_; i < l->nelements(); i++) {
      (*l)[i] = 0;
    }
  }

  (*l)[currentDLCount_] = obj;
  currentDLCount_++;
}

} //# NAMESPACE CASA - END

