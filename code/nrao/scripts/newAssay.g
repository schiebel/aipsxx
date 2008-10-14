# newAssay.g: a glish convenience script for all tests and demos
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
#
#-----------------------------------------------------------------------
# Test data lives in 
# /home/bernoulli5/aips2data/temp07_SP 7G for multi-spectral window test
# /home/bernoulli5/aips2data/phIII_64ant.ms 24G for ms split test
# /aips++/daily/data/demo/NGC5921.fits for continuum subtraction test
# copy temp07_SP and phIII_64ant.ms to local to execute
#------------------------------------------------------------------------

pragma include once


include 'sysinfo.g';
include 'imager.g';
include 'calibrater.g';
include 'image.g';
include 'ms.g';
include 'flagger.g';
  
include "general.g";
include "utility.g";
include "synthesis.g";
include "vla.g";
include "note.g";

include "splitTest.g";
include "opacTest.g";
include "multiSpwTest.g";
include "blinkingTest.g";
include "contsubTest.g";


# Runs each function in the list and checks for a fail.
# Tracks the number of fails and reports at the end. 
# Returns the number of fails.

const newAssay:=function() {
    
    self.litetests:=[' '];
    
    self.betatests:=[' '];

    self.tests:=['splitTest', 'opacTest', 'multiSpwTest', 'blinkingTest', 'contsubTest'];

    self.demos:=[' '];

    const self.dontfail:=function(f) {
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
    
    const public.try:=function(functionlist) {
      if(!is_string(functionlist)) fail "Need list of functions";
      if(functionlist=='') fail "Need list of functions";
      funclist:=split(functionlist);
      messages:=array('', len(funclist));
      for (i in 1:len(funclist)) {
	messages[i]:=self.dontfail(funclist[i]);
      }
      failed:='';
      numberfailed:=0;
      for (i in 1:len(funclist)) {
	if(messages[i]!='') {
	  note(paste(funclist[i], 'failed: ', messages[i]));
	  numberfailed+:=1;
	}
      }  
      return numberfailed;
    }
    
# Print tests
    const public.tests:=function() {return self.tests;}

# Assay cleanup function
#       this is specific to the current (8/2/01) files since
#       any wildcards could erase user files
    const public.cleanup:=function() {
      temp:=dos.dir();
      if (any(temp=='Cont3mm.ms')) shell('rm -rf Cont3mm.ms');

    }

# Assay all tests
    const public.trytests:=function(tests=F){
      if(is_string(tests)&&strlen(tests)) {
	if(tests == 'lite')
	   return public.try(self.litetests);
	else if(tests == 'beta')
	   return public.try(self.betatests);
	else
	   return public.try(tests);
      }
      else {
	return public.try(self.tests);
      }
    }

    const public.all:=function() {return trytests();};

    const public.type:=function() {return "newAssay";};
    
    return ref public;

  }
