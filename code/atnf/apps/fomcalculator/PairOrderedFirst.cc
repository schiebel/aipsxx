///////////////////////////////////////////////////////////////////////////////
// 
// PairOrderedFirst
//              a template similar to std::pair<T1,T2> with the comparison
//              operators defined for the first field
//              The T1 type should allow comparison
//
//              The main application of this template is to sort the data
//              on the basis of T1 and preserve T2
//

//# Copyright (C) 1999,2000
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: PairOrderedFirst.cc,v 1.2 2005/08/12 01:40:58 mvoronko Exp $


#ifndef __PAIRORDEREDFIRST_HPP
#define __PAIRORDEREDFIRST_HPP

template<class T1, class T2>
struct PairOrderedFirst 
{
  T1 first;
  T2 second;
  // returns true if first<in.first
  bool operator<(const PairOrderedFirst<T1,T2> &in) const {
       return first<in.first;
  }
  // returns true if first>in.first
  bool operator>(const PairOrderedFirst<T1,T2> &in) const {
       return first>in.first;
  }
  // returns true if first==in.first
  bool operator==(const PairOrderedFirst<T1,T2> &in) const {
       return first==in.first;
  }
  // returns true if first!=in.first
  bool operator!=(const PairOrderedFirst<T1,T2> &in) const {
       return first!=in.first;
  }  
};

#endif // #ifndef __PAIRORDEREDFIRST_HPP
