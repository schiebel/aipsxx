# synthesistester.g: a glish script for a suite of automated tests of
# synthesis code 
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA



pragma include once 
include 'imagerpositiontest.g';
include "vlaendtoend.g";

const synthesistester:=function() {

     self.tests:=['vlaendtoend', 'vlaplusgbt']


  const self.try:=function(f) {
      if(!is_defined(f)) return 'argument must be defined';
      if(!is_string(f)) return 'argument must be a string';
      if(!is_function(eval(f))) return paste(f, 'is not a function');
      result:=eval(spaste(f,'()'));
      if(is_fail(result)) {
        print f, 'fails: ', result::message;
        return result::message;
      }
      return '';
    } 

   public.runtests:=function(functionlist=self.tests){
      return_val := T ;
     if(!is_string(functionlist)) fail "Need list of functions";  
     funclist:=split(functionlist);        
      for (i in 1:len(funclist)) {
        if (self.try(funclist[i]) != '') {
                    return_val := F;
        }
      } 
   return return_val
  }

   public.vlaendtoend:=function(){

    if (self.try('vlaendtoend') == ''){
      return T;
    }
    else{
      return F;
    }

   }

   public.vlaplusgbt:=function(){

     if (self.try('vlaplusgbt') == ''){
       return T;
     }
     else{
       return F;
     }

   }

return ref public;

}
