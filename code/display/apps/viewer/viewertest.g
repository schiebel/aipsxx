# viewertest.g: test script for viewer.g
# Copyright (C) 1996,1997,1998,1999,2000,2001
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
# $Id: viewertest.g,v 19.1 2005/06/15 18:10:59 cvsmgr Exp $

include 'viewer.g'
include 'note.g'

pragma include once

const viewerdemo := function() {

    # make a test array
    larr := viewermaketestarray(100);
    
    # make a viewer & displaypanel
    lv := viewer();
    ldp := lv.newdisplaypanel();

    # hold the lot
    lv.hold();
    
    # make raster and contour displaydatas
    ldd1 := lv.loaddata(larr, 'raster');
    ldd2 := lv.loaddata(larr, 'contour');

    # add them to the displaypanel
    ldp.register(ldd1);
    ldp.register(ldd2);

    # release the lot
    lv.release();
}

viewertest := function(whichtest=unset) {
    global dowait;
    olddowait := dowait;
    dowait := T;
    its := [=];
    its.tests := [=];

    const its.info := function(...) { 
	note(...,origin='viewertest()');
    }

    const its.stop := function(...) { 
	note(paste(...) ,priority='SEVERE', origin='viewertest()');
        global dowait;
        dowait := olddowait;
        return F;
    }

    const its.is_true := function(v) {
	return (is_boolean(v) && v);
    }
    
    const is_thing := function(thing, v) {
	return (is_record(v) && has_field(v, 'type') &&
		is_function(v.type) && (v.type() == thing));
    }
    
    const its.is_viewer := function(v) {
	return is_thing('viewer', v);
    }

    const its.is_displaypanel := function(v) {
	return is_thing('viewerdisplaypanel', v);
    }

    const its.is_displaydata := function(v) {
	return is_thing('viewerdisplaydata', v);
    }

    # test1 - check existence and validity of viewer
    const its.tests.test1 := function() {
	its.info('Test 1 - check existence and validity of viewer');
	if (!is_defined('viewer') || !is_function(viewer)) {
	    return its.stop('viewer closure is not defined');
	}
	if (!is_defined('dv') || !is_defined('defaultviewer')) {
	    return its.stop('defaultviewer (dv) not defined');
	}
	if (!its.is_viewer(dv)) {
	    return its.stop('type inconsistency for defaultviewer');
	}
	# now assume viewer is valid, so call all functions without
	# prior checks on existence etc.
	if (dv.dying()) {
	    return its.stop('defaultviewer is prematurely dying');
	}
	tmp := dv.done();
	if (its.is_true(tmp)) {
	    return its.stop('defaultviewer.done succeeded incorrectly');
	}
	tmp := dv.hold();
	if (!its.is_true(tmp)) {
	    return its.stop('defaultviewer.hold failed');
	}
	tmp := dv.release();
	if (!its.is_true(tmp)) {
	    return its.stop('defaultviewer.release failed');
	}
	tmp := dv.disable();
	if (!its.is_true(tmp)) {
	    return its.stop('defaultviewer.disable failed');
	}
	tmp := dv.enable();
	if (!its.is_true(tmp)) {
	    return its.stop('defaultviewer.enable failed');
	}

	lv := viewer();
	if (!has_field(lv, 'type') || !is_function(lv.type) ||
	    (lv.type() != 'viewer')) {
	    return its.stop('type inconsistency for local viewer');
	}
	tmp := lv.done();
	if (!its.is_true(tmp)) {
	    return its.stop('local viewer done failed');
	}

	return T;
    }
	
    # test2 - check ability to construct displaypanels
    const its.tests.test2 := function() {
	its.info('Test 2 - check ability to construct displaypanels');
	# now make some displaypanels
	tmp := dv.newdisplaypanel();
	if (!its.is_displaypanel(tmp)) {
	    return its.stop('default displaypanel creation failed');
	}
	tmp.done();
	tmp := dv.newdisplaypanel(newcmap=T);
	if (!its.is_displaypanel(tmp)) {
	    return its.stop('newcmap=T displaypanel creation failed');
	}
	tmp.done();
	tmp := dv.newdisplaypanel(maptype='rgb');
	if (!its.is_displaypanel(tmp)) {
	    return its.stop('maptype=rgb displaypanel creation failed');
	}
	tmp.done();
	tmp := dv.newdisplaypanel(maptype='hsv');
	if (!its.is_displaypanel(tmp)) {
	    return its.stop('maptype=hsv displaypanel creation failed');
	}
	tmp.done();
	tmp := dv.newdisplaypanel(mincolors='3000000');
	if (!is_fail(tmp)) {
	    return its.stop('mincolors=3000000 displaypanel creation ',
			    'succeeded');
	}
	f := ddlws.frame(newcmap=T);
	tmp := dv.newdisplaypanel(f, width=600, height=600, hasgui=F);
	if (!its.is_displaypanel(tmp)) {
	    return its.stop('width,height displaypanel creation failed');
	}
	tmp.done();
	val f := 0; # (need val because s/seq shares f with global scope)
	return T;
    }

    # test 3 - check ability to construct displaydatas
    const its.tests.test3 := function() {
	its.info('Test 3 - check ability to construct displaydatas');
	arr := viewermaketestarray(size=50);
	img := viewermaketestimage('zzztimg');
	if (!is_image(img)) {
	    return its.stop('viewermaketestimage failed');
	}
	sky := vieweropentestskycatalog();
	if (!is_table(sky)) {
	    return its.stop('vieweropentestskycatalog failed');
	}
	# now make some displaydatas
	tmp := dv.loaddata(arr, 'raster');
	if (!its.is_displaydata(tmp)) {
	    return its.stop('failed to create raster displaydata of array');
	}
	tmp.done();
	tmp := dv.loaddata(arr, 'contour');
	if (!its.is_displaydata(tmp)) {
	    return its.stop('failed to create contour displaydata of array');
	}
	tmp.done();
	tmp := dv.loaddata(img.name(), 'raster');
	if (!its.is_displaydata(tmp)) {
	    return its.stop('failed to create raster displaydata of image');
	}
	tmp.done();
	tmp := dv.loaddata(img.name(), 'contour');
	if (!its.is_displaydata(tmp)) {
	    return its.stop('failed to create contour displaydata of image');
	}
	tmp.done();
	tmp := dv.loaddata(sky.name(), 'skycatalog');
	if (!its.is_displaydata(tmp)) {
	    return its.stop('failed to create sky catalog displaydata');
	}
	tmp.done();
	
	sky.done();
	img.delete(done=T);
	arr := 0;
	
	return T;
    }
    
    # test 4 - check raster of image displaydatas
    const its.tests.test4 := function() {
	its.info('Test 4 - check raster of image displaydatas');
	img := viewermaketestimage('zzztimg');
	if (!is_image(img)) {
	    return its.stop('viewermaketestimage failed');
	}
	# now make the displaydata
	mdd := dv.loaddata(img.name(), 'raster');
	if (!its.is_displaydata(mdd)) {
	    return its.stop('failed to create raster of image displaydata');
	}
	# try setting options to what they already are (!)
	tmp := mdd.setoptions(mdd.getoptions());
	if (!its.is_true(tmp)) {
	    return its.stop('inconsistency with set/getoptions functions');
	}
	# make a displaypanel
	mdp := dv.newdisplaypanel();
	if (!its.is_displaypanel(mdp)) {
	    return its.stop('failed to create a default displaypanel');
	}
	# register the displaydata
	tmp := mdp.register(mdd);
	if (!its.is_true(tmp)) {
	    return its.stop('registration of displaydata failed');
	}
	# try all colormaps
	cmn := dv.colormapmanager().colormapnames();
	for (i in cmn) {
	    tmp := mdd.setoptions([colormap=i]);
	    if (!its.is_true(tmp)) {
		return its.stop('change to colormap ', i, ' failed');
	    }
	}
	# try invalid colormap
	tmp := mdd.setoptions([colormap=unset]);
	if (!its.is_true(tmp)) {
	    return its.stop('setoptions returned a value other than T');
	}
	# zoom a bit
	for (i in 1:5) {
	    tmp := mdp.zoom(1.4);
	    if (!its.is_true(tmp)) {
		return its.stop('zoom failed');
	    }
	}
	# switch to bilinear, ramp up power
	tmp := mdd.setoptions([resample='bilinear', cycles=2.0]);
	if (!its.is_true(tmp)) {
	    return its.stop('setoptions returned a value other than T');
	}

	tmp := mdd.done();
	if (!its.is_true(tmp)) {
	    return its.stop('displaydata.done failed');
	}
	tmp := mdp.done();
	if (!its.is_true(tmp)) {
	    return its.stop('displaypanel.done failed');
	}
	tmp := img.delete(done=T);
	if (!its.is_true(tmp)) {
	    return its.stop('deletion of temporary image failed');
	}
	return T;
    }

    

    # run the tests
    note (spaste('These tests include forced errors.  If the logger \n',
		 'GUI is active you should expect to see Red Boxes Of \n',
		 'Death (RBsOD) with many errors.  If the test finally \n',
		 'returns T, then it has succeeded.'),
	  priority='WARN', origin='viewertest.g');
    fn := field_names(its.tests);
    const ntests := length(fn);
    if (is_unset(whichtest)) {
	whichtest := [1:ntests];
    }
    if (length(whichtest)==1) {
	whichtest := [whichtest];
    }
    
    for (i in (fn[whichtest])) {
	msg := spaste('Viewertest failed ', i);
	if (has_field(its.tests, i)) {
	    if (!its.tests[i]()) {
		return throw(msg, origin='imageservertest.g');
	    }
	}
    }
    
    dowait := olddowait;
    return T;
}
