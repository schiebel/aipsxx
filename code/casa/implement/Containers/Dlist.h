//# Dlist.h: Doubly linked list
//# Copyright (C) 1993,1994,1995,1999,2000
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
//# $Id: Dlist.h,v 19.6 2005/06/18 21:19:14 ddebonis Exp $

#ifndef CASA_DLIST_H
#define CASA_DLIST_H

#include <casa/Containers/List.h>
#include <casa/Containers/Dlink.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template<class t> class DlistIter;


// <summary><b>Deprecated</b> use <linkto class=List>List</linkto> instead</summary>
// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>
// <h2>Deprecated use <linkto class=List><src>List</src></linkto> instead.</h2>
//
template<class t> class Dlist : public List<t> { 
  public:
    Dlist();

  enum {DlistVersion = 2};
};



// <summary><b>Deprecated</b> use 
// <linkto class=ConstListIter>ConstListIter</linkto>
// </summary>
// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>
// <h2>Deprecated use <linkto class=ConstListIter><src>ConstListIter</src></linkto> instead.</h2>
//
template<class t> class ConstDlistIter : virtual public ConstListIter<t> {
private:

  ConstListIter<t> &operator=(const List<t> &);
  ConstListIter<t> &operator=(const List<t> *);
  ConstListIter<t> &operator=(const ConstListIter<t> &);
  ConstListIter<t> &operator=(const ConstListIter<t> *);

public:

  ConstDlistIter(const Dlist<t> *st);
  ConstDlistIter(const Dlist<t> &st);

  virtual ConstDlistIter<t> &operator=(const Dlist<t> &other);
  virtual ConstDlistIter<t> &operator=(const Dlist<t> *other);

  ConstDlistIter(const ConstDlistIter<t> &other);
  ConstDlistIter(const ConstDlistIter<t> *other);

  virtual ConstDlistIter<t> &operator=(const ConstDlistIter<t> &other);
  virtual ConstDlistIter<t> &operator=(const ConstDlistIter<t> *other);

  ConstDlistIter();

  enum {ConstDlistIterVersion = 2};

};


// <summary><b>Deprecated</b> use <linkto class=ListIter>ListIter</linkto> instead</summary>
// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>
// <h2>Deprecated use <linkto class=ListIter><src>ListIter</src></linkto> instead.</h2>
//
template<class t> class DlistIter : public ListIter<t>, public ConstDlistIter<t> {
private:

  ConstListIter<t> &operator=(const List<t> &);
  ConstListIter<t> &operator=(const List<t> *);
  ConstListIter<t> &operator=(const ConstListIter<t> &);
  ConstListIter<t> &operator=(const ConstListIter<t> *);

  ListIter<t> &operator=(List<t> &);
  ListIter<t> &operator=(List<t> *);
  ListIter<t> &operator=(const ListIter<t> &);
  ListIter<t> &operator=(const ListIter<t> *);

  ConstDlistIter<t> &operator=(const Dlist<t> &);
  ConstDlistIter<t> &operator=(const Dlist<t> *);
  ConstDlistIter<t> &operator=(const ConstDlistIter<t> &);
  ConstDlistIter<t> &operator=(const ConstDlistIter<t> *);

public:

  DlistIter(Dlist<t> *st,Bool OWN = False);
  DlistIter(Dlist<t> &st);

  DlistIter<t> &operator=(Dlist<t> &other) {
    ListIter<t>::operator=((List<t> &) other);
    return *this;
  }

  DlistIter<t> &operator=(Dlist<t> *other) {
    ListIter<t>::operator=((List<t> *)other);
    return *this;
  }

  DlistIter(const DlistIter<t> &other);
  DlistIter(const DlistIter<t> *other);

  DlistIter<t> &operator=(const DlistIter<t> &other) {
    ListIter<t>::operator=((const ListIter<t> &)other);
    return *this;
  }

  DlistIter<t> &operator=(const DlistIter<t> *other) {
    ListIter<t>::operator=((const ListIter<t> *)other);
    return *this;
  }

  DlistIter();

  enum {DlistIterVersion = 2};

};

} //# NAMESPACE CASA - END

#ifndef AIPS_NO_TEMPLATE_SRC
#include <casa/Containers/Dlist.cc>
#endif //# AIPS_NO_TEMPLATE_SRC
#endif
