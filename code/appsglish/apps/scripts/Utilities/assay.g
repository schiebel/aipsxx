# assay.g: a glish convenience script for all tests and demos
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
# $Id: assay.g,v 19.2 2004/08/25 02:07:15 cvsmgr Exp $
#

pragma include once
  
include "general.g";
include "dishtester.g";
include "utility.g";
include "synthesis.g";
include "vla.g";
include "note.g";

# Runs each function in the list and checks for a fail.
# Tracks the number of fails and reports at the end. 
# Returns the number of fails.

  const assay:=function() {
    
    self.litetests:=['display_multi_column_text_test',
		 'fftservertest',
		 'imagerlitetests',
		 'imagetest',
		 'imagefittertest',
		 'imageprofilesupporttest',
                 'coordsystest',
                 'imagepoltest',        
		 'interpolate1dtest',
                 'pgplottertest',
		 'polyfittertest',
		 'randomnumberstest',
		 'tabletest',
		 'deconvolverlongtest',
		 'guientrytest',
                 'calibratertest',
		 'mstest',
		 'dishalltest',
		 'vlafillertest'];
    
    self.betatests:=['display_multi_column_text_test',
		 'fftservertest',
		 'imagerbetatests',
		 'imagetest',
		 'imagefittertest',
		 'imageprofilesupporttest',
                 'coordsystest',
                 'imagepoltest',        
		 'interpolate1dtest',
                 'pgplottertest',
		 'polyfittertest',
		 'randomnumberstest',
		 'tabletest',
		 'deconvolverlongtest',
		 'guientrytest',
                 'calibratertest',
		 'mstest',
		 'dishalltest',
		 'vlafillertest'];
    
    self.tests:=['display_multi_column_text_test',
		 'fftservertest',
		 'imageralltests',
		 'imagetest',
		 'imagefittertest',
		 'imageprofilesupporttest',
                 'coordsystest',
                 'imagepoltest',        
		 'interpolate1dtest',
                 'pgplottertest',
		 'polyfittertest',
		 'randomnumberstest',
		 'tabletest',
		 'deconvolverlongtest',
		 'guientrytest',
                 'calibratertest',
		 'mstest',
		 'dishalltest',
		 'vlafillertest'];

    self.demos:=['display_multi_column_text_demo',
		 'fftserverdemo',
		 'imagedemo',
		 'inputsdemo',
		 'interpolate1ddemo',
                 'pgplottertest',
		 'polyfitterdemo',
		 'randomnumbersdemo',
		 'tabledemo',
		 'vlafillerdemo'];

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

# Print demos
    const public.demos:=function() {return self.demos;}

# Assay cleanup function
#       this is specific to the current (8/2/01) files since
#       any wildcards could erase user files
    const public.cleanup:=function() {
      temp:=dos.dir();
      if (any(temp=='imagercomponenttest')) shell('rm -rf imagercomponenttest');
      if (any(temp=='imagerlongtest')) shell('rm -rf imagerlongtest');;
      if (any(temp=='imagermftest')) shell('rm -rf imagermftest');
      if (any(temp=='imagerpbtest')) shell('rm -rf imagerpbtest');
      if (any(temp=='imagerselfcaltest')) shell('rm -rf imagerselfcaltest');
      if (any(temp=='imagertest')) shell('rm -rf imagertest');
      if (any(temp=='deconvolverlongtest')) shell('rm -rf deconvolverlongtest');
      if (any(temp=='3C273.psf')) shell('rm -rf 3C273.psf');
      if (any(temp=='aipsplot_1.plot')) shell('rm -rf aipsplot_*.plot');
      if (any(temp=='demo.plot.table')) shell('rm -rf demo.plot.table');
      if (any(temp=='testsolve')) shell('rm -rf testsolve');
      if (any(temp=='vla.ms')) shell('rm -rf vla.ms');
      if (any(temp=='mstest')) shell('rm -rf mstest');
      if (any(temp=='imagetest_temp')) shell('rm -rf imagertest');
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

# Assay all demos
    const public.trydemos:=function(demos=F){
      if(is_string(demos)&&strlen(demos)) {
	return public.try(demos);
      }
      else {
	return public.try(self.demos);
      }
    }
    const public.all:=function() {return trytests()+trydemos();};

    const public.type:=function() {return "assay";};
    
    return ref public;

  }
