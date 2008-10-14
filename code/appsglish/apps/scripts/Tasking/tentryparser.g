# tentryparser: test the parser for input and output of parameters
# Copyright (C) 1996,1997,1998,1999,2001
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
# $Id: tentryparser.g,v 19.2 2004/08/25 02:05:09 cvsmgr Exp $


pragma include once
    
include 'entryparser.g';
include 'quanta.g';
include 'measures.g';
include 'regionmanager.g';
    
tentryparser := function(allowunset=T) 
{

  global possible := [=];

  # Viable things that one might like to insert
  addtest := function (type, value, expected=T, options=unset, types=unset,
		       units=unset) {
    global possible;
    i := length(possible)+1;
    possible[i] := [=];
    possible[i].type := type;
    possible[i].value := value;
    possible[i].expected := expected;
    possible[i].options := options;
    possible[i].types := types;
    possible[i].units := units;
    return T;
  }

  global myfunction := function() {
    return T;
  }

  addtest('array', [1, 2, 3]);
  addtest('array', myfunction, F);
  addtest('array', 'arrayfoo', F);
  addtest('array', '[1, 2, 3]');
  addtest('array', '1 2 3');
  addtest('array', '1,2,5,6,7  9');
  addtest('array', '1:3');
  addtest('array', 1:1000);
  addtest('array', array(1:1000, 100, 100));
  addtest('array', 'array(1:1000, 100, 100)');
  addtest('array', 'array(1:1000, 100, 100', F);

  addtest('boolean', T);
  addtest('boolean', myfunction, F);
  addtest('boolean', '');
  addtest('boolean', 'T');
  addtest('boolean', 'TRUE');
  addtest('boolean', 'True');
  addtest('boolean', 'False');
  addtest('boolean', 'Fales'); # This should parse to a False!
  addtest('boolean', 'FALSE');

  # choice: one of many
  addtest('choice', myfunction, F, options=['fish', 'fowl', 'pancakes']);
  addtest('choice', 'fish', options=['fish', 'fowl', 'pancakes']);
  addtest('choice', 'fowl', options=['fish', 'fowl', 'pancakes']);
  addtest('choice', 'pancakes', options=['fish', 'fowl', 'pancakes']);
  addtest('choice', 'fish fowl', F, options=['fish', 'fowl', 'pancakes']);
  addtest('choice', 'salsa', F, options=['fish', 'fowl', 'pancakes']);
  addtest('choice', ['fish', 'fowl'], F, options=['fish', 'fowl', 'pancakes']);

  # check: many of many
  addtest('check', myfunction, F, options=['fish', 'fowl', 'pancakes']);
  addtest('check', 'fish', options=['fish', 'fowl', 'pancakes']);
  addtest('check', 'fowl', options=['fish', 'fowl', 'pancakes']);
  addtest('check', 'pancakes', options=['fish', 'fowl', 'pancakes']);
  addtest('check', 'fish fowl', F, options=['fish', 'fowl', 'pancakes']);
  addtest('check', 'salsa', F, options=['fish', 'fowl', 'pancakes']);
  addtest('check', ['fish', 'fowl'], options=['fish', 'fowl', 'pancakes']);

  addtest('file', 'fish');
  addtest('file', myfunction, F);
  addtest('file', ['fish', 'fowl']);
  addtest('file', sqrt(2.0), F);

  addtest('measure', dm.direction('b1950', '56.34deg', '-23.5deg'), types='direction')
  addtest('measure', myfunction, F);
  addtest('measure', 'measurefoo', F);
  addtest('measure', 'dm.direction(\'b1950\', \'56.34deg\', \'-23.5deg\')',
	  types='direction')
  addtest('measure', dm.epoch('utc', 'today'), types='epoch');
  addtest('measure', dm.epoch('utc', 'today'), F, types='direction');

  addtest('quantity', '0.7arcsec', types='angle');
  addtest('quantity', 'quantityfoo', F, types='angle');
  addtest('quantity', myfunction, F, types='angle');
  addtest('quantity', '0.7arcsec', F, types='time');
  addtest('quantity', '60Hz', T, types='freq');
  addtest('quantity', '60Hz', F, types='time');

  addtest('record', '', F);
  addtest('record', myfunction, F);
  addtest('record', 'recordfoo', F);
  addtest('record', sqrt(2.0), F);
  addtest('record', '[a=\'fish\', b=\'fowl\']')
  addtest('record', [a='fish', b='fowl'])

  addtest('region', '', F);
  addtest('region', myfunction, F);
  addtest('region', 'regionfoo', F);
  addtest('region', sqrt(2.0), F);
  myregion := drm.box();
  addtest('region', myregion);
  addtest('region', 'drm.box()')
# The following causes a segv
  addtest('region', 'drm.box(', F)
  addtest('region', 'drm.box', F)
  addtest('region', drm.box, F)

  addtest('scalar', e);
  addtest('scalar', 0.0);
  addtest('scalar', myfunction, F);
  addtest('scalar', 'scalarfoo', F);
  addtest('scalar', '1,2,5,6,7', F);
  addtest('scalar', '1:3', F);
  addtest('scalar', 1.452+8.41i);

  nfailed := 0;

  last := '';
  for (value in possible) {
    actual := F; display := F; result := F;
    if(value.type!=last) {
      last := value.type;
      print last;
    }
    if ((value.type=='choice')||(value.type=='check')) {
      result := dep[value.type](value.value, allowunset, value.options, actual, display);
    }
    else if (value.type=='measure') {
      result := dep[value.type](value.value, allowunset, actual, display, value.types);
    }
    else if (value.type=='quantity') {
      result := dep[value.type].parse(value.value, allowunset, actual, display,
 				      value.types, value.units);
    }
    else {
      result := dep[value.type](value.value, allowunset, actual, display);
    }
    
    if(result!=value.expected) {
      nfailed +:= 1;
      printf(spaste('ERROR ', value.type, ': ', as_evalstr(value.value), ' is ',
		    type_name(value.value), ', Parsed?: ', result, ' actual: ', actual,
		    ' display: ', display , '\n'));
    }
  }
  if(nfailed) {
    note(paste('tentryparser: Unexpected result in ', nfailed, ' tests'));
    return F;
  }
  else {
    note(paste('tentryparser: All tests succeeded'));
    return T;
  }
}
  
tentryparser()
