//# AipsrcVString.cc: Specialisation for AipsrcVector<String>
//# Copyright (C) 1995,1996,1997,1998,2000,2001,2002,2003
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
//# $Id: AipsrcVString.cc,v 19.5 2004/11/30 17:50:19 ddebonis Exp $

//# Includes

#include <casa/System/AipsrcVector.h>
#include <casa/Utilities/Regex.h>
#include <casa/Utilities/Assert.h>
#include <casa/Arrays/Vector.h>
#include <casa/sstream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Data
AipsrcVector<String> AipsrcVector<String>::myp_p;

//# Constructor
AipsrcVector<String>::AipsrcVector() : 
  tlst(0), ntlst(0) {}

//# Destructor
AipsrcVector<String>::~AipsrcVector() {}

Bool AipsrcVector<String>::find(Vector<String> &value,
					    const String &keyword) {
  String res;
  Bool x = Aipsrc::find(res, keyword, 0);
  if (x) {
    const Regex ws("[ 	]+");
    res.gsub(ws, " ");
    Int m = res.freq(" ") +1;
    String *nres = new String[m];
    m = split(res, nres, m, " ");
    value = Vector<String>(m);
    for (Int i=0; i<m; i++) {
      value(i) = nres[i];
    };
    delete [] nres;
  };
  return x;
}

Bool AipsrcVector<String>::find(Vector<String> &value,
					    const String &keyword, 
					    const Vector<String> &deflt) {
  return (find(value, keyword) ? True : (value = deflt, False));
}

uInt AipsrcVector<String>::registerRC(const String &keyword,
						  const Vector<String> 
						  &deflt) {
  uInt n = Aipsrc::registerRC(keyword, myp_p.ntlst);
  myp_p.tlst.resize(n);
  find ((myp_p.tlst)[n-1], keyword, deflt);
  return n;
}

const Vector<String> &AipsrcVector<String>::get(uInt keyword) {
  AlwaysAssert(keyword > 0 && keyword <= myp_p.tlst.nelements(), AipsError);
  return (myp_p.tlst)[keyword-1];
}

void AipsrcVector<String>::set(uInt keyword,
					   const Vector<String> &deflt) {
  AlwaysAssert(keyword > 0 && keyword <= myp_p.tlst.nelements(), AipsError);
  (myp_p.tlst)[keyword-1].resize(deflt.nelements());
  (myp_p.tlst)[keyword-1] = deflt;
}

void AipsrcVector<String>::save(uInt keyword) {
  AlwaysAssert(keyword > 0 && keyword <= myp_p.tlst.nelements(), AipsError);
  ostringstream oss;
  Int n = ((myp_p.tlst)[keyword-1]).nelements();
  for (Int i=0; i<n; i++) oss << " " << ((myp_p.tlst)[keyword-1])(i);
  Aipsrc::save((myp_p.ntlst)[keyword-1], String(oss));
}

} //# NAMESPACE CASA - END

