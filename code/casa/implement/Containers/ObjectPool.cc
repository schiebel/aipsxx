//# ObjectPool.cc: A parameterized stack of re-usable objects
//# Copyright (C) 2001
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
//# $Id: ObjectPool.cc,v 19.3 2004/11/30 17:50:15 ddebonis Exp $

//# Includes
#include <casa/Containers/ObjectPool.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Constructors
template <class T, class Key>
ObjectPool<T, Key>::ObjectPool() :
  defKey_p(), defStack_p(new PoolStack<T, Key>),
  cacheKey_p(), cacheStack_p(0),
  map_p(defStack_p) {}

template <class T, class Key>
ObjectPool<T, Key>::~ObjectPool() {
  delete defStack_p;
  for (uInt i=0; i<map_p.ndefined(); i++) {
    delete map_p.getVal(i);
    map_p.getVal(i) = 0;
  };
}

template <class T, class Key>
PoolStack<T, Key> &ObjectPool<T, Key>::getStack(const Key key) {
  if (key == cacheKey_p && cacheStack_p) return *cacheStack_p;
  else if (key == defKey_p) return *defStack_p;
  PoolStack<T, Key> **v0;
  if (!(v0 = map_p.isDefined(key))) {
    v0 = &(map_p.define(key, new PoolStack<T, Key>(key)));
  };
  cacheKey_p = key;
  cacheStack_p = *v0;
  return **v0;
}

template <class T, class Key>
void ObjectPool<T, Key>::release(T *obj, const Key key) {
  if (key == cacheKey_p && cacheStack_p) cacheStack_p->release(obj);
  else if (key == defKey_p) defStack_p->release(obj);
  else {
    PoolStack<T, Key> **v0;
    if ((v0 = map_p.isDefined(key))) (*v0)->release(obj);
  };
}

template <class T, class Key>
void ObjectPool<T, Key>::clearStacks() {
  for (uInt i=0; i<map_p.ndefined(); i++) clearStack(map_p.getKey(i));
}

template <class T, class Key>
void ObjectPool<T, Key>::clearStack(const Key key) {
  PoolStack<T, Key> **v0;
  if ((v0 = map_p.isDefined(key))) (*v0)->clear();
}

template <class T, class Key>
void ObjectPool<T, Key>::clear() {
  clearStacks();
  for (uInt i=0; i<map_p.ndefined(); i++) {
    if (map_p.getVal(i)->nelements() == 0) {
      delete map_p.getVal(i);
      map_p.getVal(i) = 0;
      map_p.remove(map_p.getKey(i));
    };
  };
}

} //# NAMESPACE CASA - END

