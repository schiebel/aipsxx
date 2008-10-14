#-----------------------------------------------------------------------------
# atpl_oo.g: Provides class inheritance for the ATCA pipeline
#-----------------------------------------------------------------------------
# Copyright (C) 1996-2004
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id:
#-----------------------------------------------------------------------------
#

const INHERIT := function(child, parent){
  for(field in field_names(parent)){
    if(type_name(parent[field]) == 'function'){
      child[field] := parent[field]
    }
  }

  return T
}

const INTERNAL := function(parent){
  return parent.__ITS();
}

#klass := subsequence(){
#  its := [=]
#  const self.__ITS := function(){ return ref its; }
#}

#klass2 := subsequence(){
# 
#  par := klass()
#  INHERIT(self, par)
#  its := INTERNAL(par)
#}
