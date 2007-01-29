# dishtester: dishtester tool
# Copyright (C) 2002,2003
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
# $Id: dishopstester.g,v 19.1 2004/08/25 01:10:44 cvsmgr Exp $

# include guard
pragma include once;

# this is designed to be used by dishtester.  All sanity checks
# should happen since they are not done here.

# the dish and sditerator arguments are NOT destroyed here.

dishopstester := function(adish, ansditerator, ansdrecord, testdir,
			  checkresult) 
{
    public:=[=];
    private:=[=];

    include 'note.g';

    private.adish := adish;
    private.ansditerator := ansditerator;
    private.ansdrecord := ansdrecord;
    private.testdir := testdir;
    private.tests := [=];
    private.checkresult := checkresult;

    # this must be called before any of the private tests are run
    private.clearAndInitialize := function() {
	wider private;
	# clear the dish, add a copy of ansditerator to it and make that the 
	# current ws.
	note('Restoring test dish to the default state');
	ok := private.adish.restorestate(T);
	if (is_fail(ok)) return public.done(ok::);

	# make a new sditerator from this one - so that we have a copy we
	# can muck with - when dish is reset, cleared, this is done'ed.
	thissdit := sditerator(private.ansditerator.name());
	if (!is_sditerator(thissdit)) 
	    throw('dish ops tester: Could not create a copy of the test sditerator');

	ok := private.adish.rm().add('opstestit','sdit used in ops tests', thissdit, 'SDITERATOR');
	if (is_fail(ok) || !is_string(ok)) {
	    throw('dish ops tester: Could not select sditerator for testing');
	}
	# select this as filein
	private.adish.filein(ok);
	return T;
    }

    private.addAndSelect := function(ansdrecord, name, comment) {
	wider private;
	addok := private.adish.rm().add(name, comment,
					private.ansdrecord,'SDRECORD');
 	private.adish.rm().select('end');
	return addok;
    }
	    	
    private.tests.debugcheck := function () {
	wider private;
	# check for presence of any debug fields at top level of dish
	if (any("debug" == field_names(private.adish))) {
	    note('dish contains a debug field - not a fatal flaw but it should be removed.',
		 priority='WARN');
	}
	# Check for debug fields in the ops
	for (op in private.adish.ops()) {
	    if (any("debug" == field_names(op))) {
		note('dish.ops().',op.opfuncname(),
		     ' function contains a debug field - not a fatal flaw but it should be removed.',
		     priority='WARN');
	    }
	}
	    
	return T;
    }

    # operation tests

    private.tests.average := function() {
	note('dish.ops().average');
	avgop := private.adish.ops().average;
	ok := avgop.opfuncname() == 'average';
	ok := ok && avgop.opmenuname() == 'Averaging';
	# should be the default state
	s := avgop.getstate();
	ok := ok && !is_fail(s) &&
	    (s.selection == T && s.alignment == "NONE" &&
	     s.restshift == F && s.weighting == "NONE");
	
	# turn selection off
	# average after a selection is part of the selection test.
	ok := ok && avgop.doselection(F);
	# turn restshift ON
	ok := ok && avgop.dorestshift(T);
	# verify its on in the state
	ok := ok && avgop.getstate().restshift == T;
	# reset to the default state saved above
	ok := ok && avgop.setstate(s);
	# verify that restshift selection is off
	ok := ok && avgop.getstate().restshift == F;
	# set the various alignments (NONE last since its already set
	# at none now)
	if (ok) {
	    validAlignments := "VELOCITY XAXIS NONE";
	    for (a in validAlignments) {
		ok := ok && avgop.setalignment(a);
		ok := ok && avgop.getstate().alignment == a;
	    }
	    # try a bogus one
	    ok := ok && !avgop.setalignment("junk");
	    # alignment should still be NONE
	    ok := ok && avgop.getstate().alignment == "NONE";
	}
	# set the various weightings (NONE last here)
	if (ok) {
	    validWeights := "RMS TSYS WEIGHT NONE";
	    for (a in validWeights) {
		ok := ok && avgop.setweighting(a);
		ok := ok && avgop.getstate().weighting == a;
	    }
	    # try a bogus one
	    ok := ok && !avgop.setweighting("junk");
	    # weighting should still be NONE
	    ok := ok && avgop.getstate().weighting == "NONE";
	}
	# apply
	ok := ok && avgop.apply();
	# daver - with a few scans
	ok := ok && !is_fail(avgop.daver([1:20]));
	# averagews - using the ws available here
	ok := ok && !is_fail(avgop.averagews(private.ansditerator));
	return ok;
    }

    private.tests.baseline := function() {
	wider private;
	note('dish.ops().baseline');
	baseop := private.adish.ops().baseline;
	ok := baseop.opfuncname() == 'baseline';
	ok := ok && baseop.opmenuname() == 'Baselines';
	# set to the default state
	s := baseop.setstate([=]);
	# should be the default state
	s := baseop.getstate();
	# limited test of default state
	ok := ok && !is_fail(s) &&
	    (s.type == "polynomial" && s.recalculate == T &&
	     s.action == "show");
	if (ok) {
	    validActions := "subtract show";
	    for (a in validActions) {
		ok := ok && baseop.setaction(a);
		ok := ok && baseop.getaction() == a &&
		    baseop.getstate().action == a;
	    }
	    # try a bogus one
	    ok := !baseop.setaction('junk');
	    # action should still be show
	    ok := ok && baseop.getaction() == "show";
	}
	ok := ok && baseop.recalculate(F);
	ok := ok && baseop.getstate().recalculate == F;
	# reset to defaut using default state above
	ok := ok && baseop.setstate(s);
	# verify with a simple test
	ok := ok && baseop.getstate().recalculate == T;
	ok := ok && baseop.setamplitude(10);
	ok := ok && baseop.getstate().ampSine == 10;
	ok := ok && baseop.setcriteria(0.005);
	ok := ok && baseop.getstate().criteriaSine == 0.005;
	ok := ok && baseop.setmaxiter(20);
	ok := ok && baseop.getstate().maxIterSine == 20;
	ok := ok && baseop.setorder(2);
	ok := ok && baseop.getstate().order == 2;
	ok := ok && baseop.setperiod(2);
	ok := ok && baseop.getstate().perSine == 2;
	ok := ok && baseop.setrange('[10:20][50:100]');
	ok := ok && baseop.getstate().rangeString == '[10:20] [50:100]';
	if (ok) {
	    validTypes := "sinusoid polynomial";
	    for (a in validTypes) {
		ok := ok && baseop.settype(a);
		ok := ok && baseop.getstate().type == a;
	    }
	    # try a bogus one
	    ok := !baseop.settype('junk');
	    # type should still be polynomial
	    ok := ok && baseop.getstate().type == "polynomial";
	}
	ok := ok && baseop.setx0(5);
	ok := ok && baseop.getstate().x0Sine == 5;
	# reset to default
	ok := ok && baseop.setstate([=]);
	
	# add private.ansdrecord into the results manager
	addok := private.addAndSelect(private.ansdrecord,'dishbasetest','Used in baseline tests');
	if (is_fail(addok)) throw('Unable to insert a test SDRecord for dish baseline test');
	
	# apply - this tests polynomial as well
	ok := ok && baseop.apply();
	# dbase
	ok := ok && baseop.dbase(private.ansdrecord);
	# switch to sinusoid type
	ok := ok && baseop.settype('sinusoid');
	# apply - this tests sinusoidal
	ok := ok && baseop.apply();
	return ok;
    }
	
    private.tests.calculator := function() {
	wider private;
	note('dish.ops().calculator');
	calcop := private.adish.ops().calculator;
	ok := calcop.opfuncname() == 'calculator';
	ok := ok && calcop.opmenuname() == 'Calculator';
	# set to default state
	ok := ok && calcop.setstate([=]);
	# verify default state
	s := calcop.getstate();
	ok := ok && len(s.rec) == 0 && len(s.name) == 0 && 
	    len(s.descriptions) == 0 && s.stackcntr == 0 && s.lbcntr == 0;
	# add private.ansdrecord into the results manager
	addok := private.addAndSelect(private.ansdrecord,'dishcalctest','Used in calculator tests');
	if (is_fail(addok)) throw('Unable to insert a test SDRecord for dish calculator test');

	# copy it to the CB
	private.adish.rm().copy();
	# and from there to the calculator GUI via paste
	ok := ok && calcop.paste();
	# and reset to the default using s from above
	ok := ok && calcop.setstate(s);
	# verify default state
	s := calcop.getstate();
	ok := ok && len(s.rec) == 0 && len(s.name) == 0 && 
	    len(s.descriptions) == 0 && s.stackcntr == 0 && s.lbcntr == 0;
	return ok;
    }

    private.tests.function := function() {
	wider private;
	note('dish.ops().function');
	funcop := private.adish.ops().function;
	ok := funcop.opfuncname() == 'function';
	ok := ok && funcop.opmenuname() == 'Function';
	# set to default state
	ok := ok && funcop.setstate([=]);
	# verify default state
	s := funcop.getstate();
	ok := ok && strlen(s.fn) == 0 && strlen(s.history) == 0 && 
	    s.selection == 0;

	# add private.ansdrecord into the results manager
	addok := private.addAndSelect(private.ansdrecord,'dishfunctest','Used in function tests');
	if (is_fail(addok)) throw('Unable to insert a test SDRecord for dish function test');
	
	ok := ok && funcop.setfn('ARR*ARR');
	ok := ok && (funcop.getfn() == 'ARR*ARR');
	ok := ok && funcop.apply();
	
	# and reset to the default using s from above
	ok := ok && funcop.setstate(s);
	# verify default state
	ok := ok && strlen(s.fn) == 0 && strlen(s.history) == 0 && 
	    s.selection == 0;
	return ok;
    }

    private.tests.regrid := function() {
	wider private;
	note('dish.ops().regrid');
	regop := private.adish.ops().regrid;
	ok := regop.opfuncname() == 'regrid';
	ok := ok && regop.opmenuname() == 'Regrid';
	# set to default state
	ok := ok && regop.setstate([=]);
	# verify default state
	s := regop.getstate();
	ok := ok && (s.type == 0) && (strlen(s.boxwidth) == 0) &&
	    (strlen(s.gwidth) == 0) && (s.gunits == 1) &&
		(s.decimate == F) && (strlen(s.gridfac) == 0);
	ok := ok && regop.setboxwidth(3);
	ok := ok && as_integer(regop.getstate().boxwidth) == 3;
	ok := ok && regop.setdecimate(T);
	ok := ok && regop.getstate().decimate == T;
	ok := ok && regop.setgausswidth(4, 'Native Units');
	ok := ok && as_integer(regop.getstate().gwidth) == 4;
	ok := ok && regop.getstate().gunits == 2;
	ok := ok && regop.setgridfac(0.5);
	ok := ok && as_double(regop.getstate().gridfac) == 0.5;
	if (ok) {
	    validTypes := "HANNING BOXCAR GAUSSIAN SPLINEINT FTINT";
	    typeCodes := [0:4];
	    for (i in 1:len(validTypes)) {
		ok := ok && regop.settype(validTypes[i]);
		ok := ok && regop.getstate().type == typeCodes[i];
	    }
	    # try a bogus one - settype currently returns T no matter what
	    regop.settype('junk');
	    # type should still be last one set
	    ok := ok && regop.getstate().type == 4;
	}
	# reset to default using s saved above
	ok := ok && regop.setstate(s);
	# verify default state
	s := regop.getstate();
	ok := ok && (s.type == 0) && (strlen(s.boxwidth) == 0) &&
	    (strlen(s.gwidth) == 0) && (s.gunits == 1) &&
		(s.decimate == F) && (strlen(s.gridfac) == 0);

	# add private.ansdrecord into the results manager
	addok := private.addAndSelect(private.ansdrecord,'dishregridest','Used in regrid tests');
	if (is_fail(addok)) throw('Unable to insert a test SDRecord for dish regrid test');

	ok := ok && regop.apply();
	return ok;
    }

    private.tests.save := function() {
	wider private;
	note('dish.ops().save');
	saveop := private.adish.ops().save;
	ok := saveop.opfuncname() == 'save';
	ok := ok && saveop.opmenuname() == 'Save to table';
	## setstate currently bypasses setting the wsname - and since there's
	## nothing else to the state, don't test it here.
	# set to default state
	# ok := ok && saveop.setstate([=]);
	# verify default state - just one field
	# ok := ok && strlen(saveop.getstate().wsname) == 0;

	# add private.ansdrecord into the results manager
	addok := private.addAndSelect(private.ansdrecord,'dishsvtest','Used in save tests');
	if (is_fail(addok)) throw('Unable to insert a test SDRecord for dish save test');

	# create a new empty ws
	# first, remove any old one if it exists
	junkwsname := spaste(private.testdir,'dishsavetest');
	note('Removing ',junkwsname);
	ok := dos.remove(junkwsname,mustexist=F);
	if (is_fail(ok)) {throw('Removal of ',junkwsname,'fails!');}
	
	private.adish.open(junkwsname,new=T,filein=F);
	private.adish.fileout(private.adish.rm().getnames(private.adish.rm().size()));

	ok := ok && saveop.apply();

	s := saveop.getstate();
	wsname := s.wsname;
	## don't test setstate/getstate further here just yet
	# reset to default state
	# ok := ok && saveop.setstate([=]);
	# verify default state - just one field
	# s := saveop.getstate();
	# ok := ok && strlen(s.wsname) == 0;

	# set the ws name
	ok := ok && saveop.setws(wsname);
	# and verify
	ok := ok && saveop.getstate().wsname == wsname;

	# verify that setting it to garbage returns F
	print 'Expect one \'ERROR\' line.';
	ok := ok && !saveop.setws('complete garbage');

	# and reset to the default using s from above
	# ok := ok && saveop.setstate(s);
	# verify default state
	# ok := ok && strlen(saveop.getstate().wsname) == 0;
	return ok;
    }


    private.tests.select := function () {
	wider private;
	note('dish.ops().select');
	selop := private.adish.ops().select;
	ok := selop.opfuncname() == 'select';
	ok := ok && selop.opmenuname() == 'Selection';
	
	# try setting some criteria
	crit := [=];
	crit.header := [=];
	crit.header.source_name := 'firstz';
	# setcriteria doesn't yet set anything that be queried.  It is
	# used when select(fromgui=F) is done.
	ok := ok && selop.setcriteria(crit);
	if (ok) {
	    sws := selop.apply(fromgui=F,returnws=T);
	    ok := unique(sws.getheadervector('source_name').source_name) == 'firstz';
	}
	# set the combobox values by getting the state, changing the entry field
	# and setting the state
	s := selop.getstate();
	if (ok) {
	    if (has_field(s,'source_name') &&
		has_field(s.source_name,'cb') &&
		has_field(s.source_name.cb,'entry')) {
		s.source_name.cb.entry := 'secondz';
		# turn all off - just to be safe
		for (rec in s) {
		    if (has_field(rec,'enabled')) {
			rec.enabled := F;
		    }
		}
		# and turn this one on
		s.source_name.enabled := T;
		# setstate returns F always
		selop.setstate(s);
		
		# verify the state changes above:
		s := selop.getstate();
		ok := s.source_name.cb.entry == 'secondz';
		if (ok) {
		    for (rec in field_names(s)) {
			if (has_field(s[rec],'enabled')) {
			    if (rec == 'source_name') {
				ok := ok && s[rec].enabled == T;
			    } else {
				ok := ok && s[rec].enabled == F;
			    }
			}
		    }
		}
	    } else {
		ok := F;
	    }
	}

	ok := ok && selop.apply();
	# should be last entry in rm
	lastws := private.adish.rm().getvalues(adish.rm().size());
	ok := ok && is_sditerator(lastws);
	ok := ok && unique(lastws.getheadervector('source_name').source_name) == 'secondz';
	
	# updatecomboboxes, setPendingCWS, newworkingset not tested yet
	# current working set should be same as ws
	ok := ok && private.ansditerator.length() == selop.cws().length();
	return ok;
    }


    private.tests.smooth := function() {
	wider private;
	note('dish.ops().smooth');
	smoothop := private.adish.ops().smooth;
	ok := smoothop.opfuncname() == 'smooth';
	ok := ok && smoothop.opmenuname() == 'Smooth';
	# set to default state
	ok := ok && smoothop.setstate([=]);
	# verify default state
	s := smoothop.getstate();
	ok := ok && (s.type == 0) && (strlen(s.boxwidth) == 0) &&
	    (strlen(s.gwidth) == 0) && (s.gunits == 1) &&
		(s.decimate == F);
	ok := ok && smoothop.setboxwidth(3);
	ok := ok && as_integer(smoothop.getstate().boxwidth) == 3;
	ok := ok && smoothop.setdecimate(T);
	ok := ok && smoothop.getstate().decimate == T;
	ok := ok && smoothop.setgausswidth(4, 2);
	ok := ok && as_integer(smoothop.getstate().gwidth) == 4;
	ok := ok && smoothop.getstate().gunits == 2;
	if (ok) {
	    validTypes := "HANNING BOXCAR GAUSSIAN";
	    typeCodes := [0:4];
	    for (i in 1:len(validTypes)) {
		ok := ok && smoothop.settype(validTypes[i]);
		ok := ok && smoothop.getstate().type == typeCodes[i];
	    }
	    # try a bogus one - settype currently returns T no matter what
	    smoothop.settype('junk');
	    # type should still be last one set
	    ok := ok && smoothop.getstate().type == 2;
	}
	# reset to default using s saved above
	ok := ok && smoothop.setstate(s);
	# verify default state
	s := smoothop.getstate();
	ok := ok && (s.type == 0) && (strlen(s.boxwidth) == 0) &&
	    (strlen(s.gwidth) == 0) && (s.gunits == 1) &&
		(s.decimate == F);

	# add private.ansdrecord into the results manager
	addok := private.addAndSelect(private.ansdrecord,'dishsmoothtest','Used in smooth tests');
	if (is_fail(addok)) throw('Unable to insert a test SDRecord for dish smooth test');

	ok := ok && smoothop.apply();
	return ok;
    }


    private.tests.statistics := function() {
	wider private;
	note('dish.ops().statistics');
	statop := private.adish.ops().statistics;
	ok := statop.opfuncname() == 'statistics';
	ok := ok && statop.opmenuname() == 'Statistics';
	# set to default state
	ok := ok && statop.setstate([=]);
	# verify default state - all fields are empty strings
	s := statop.getstate();
	for (field in s) {
	    ok := ok && is_string(field) && strlen(field) == 0;
	}
	
	if (ok) {
	    # add private.ansdrecord into the results manager
	    addok := private.addAndSelect(private.ansdrecord,'dishstattest','Used in statistics tests');
	    if (is_fail(addok)) 
		throw('Unable to get a test SDRecord for dish statistics test');
	    res := statop.apply();
	    
	    if (is_record(res)) {
		# one field for each pol - test each field
		for (field in res) {
		    if (is_record(field)) {
			# just check that each field is numeric
			for (polfield in field) {
			    ok := ok && is_numeric(polfield);
			}
		    } else {
			ok := F;
		    }
		}
	    } else {
		ok := F;
	    }
	}

	if (ok) {
	    # dstats, same as above - except not needed in rm
	    res := statop.dstats(private.ansdrecord);
	    
	    if (is_record(res)) {
		# one field for each pol - test each field
		for (field in res) {
		    if (is_record(field)) {
			# just check that each field is numeric
			for (polfield in field) {
			    ok := ok && is_numeric(polfield);
			}
		    } else {
			ok := F;
		    }
		}
	    } else {
		ok := F;
	    }
	}

	if (ok) {
	    rstring := '[1:10] [20:50] [40:55]';
	    rmat := statop.rangeStringToMatrix(rstring);
	    ok := ok && is_numeric(rmat) && has_field(rmat::,'shape');
	    ok := ok && all(rmat::shape == [2,3]);
	    ok := ok && all(rmat[1,] == [1,20,40]) &&
		all(rmat[2,] == [10,50,55]);
	}
	ok := ok && statop.setranges('[109:110]');
	ok := ok && statop.getstate().start == '109' && 
	    statop.getstate().stop == '110'; 
	return ok;
    }

    private.tests.write := function() {
	note('dish.ops().write');
	writeop := private.adish.ops().write;
	ok := writeop.opfuncname() == 'write';
	ok := ok && writeop.opmenuname() == 'Write to File';
	# set to default state
	ok := ok && writeop.setstate([=]);
	# verify default state - just one field
	s := writeop.getstate();
	ok := ok && strlen(s.ofname) == 0;
	addok := private.addAndSelect(private.ansdrecord,'dishwritetest','Used in write tests');
	if (is_fail(addok)) throw('Unable to get a test SDRecord for dish write test');
	ok := ok && writeop.apply();
	
	# ensure that a previous use of this test has been removed
	ofname := spaste(private.testdir,'oftest');
	ok := ok && dos.remove(ofname,mustexist=F);
	
	# set the ws name
	ok := ok && writeop.setof(ofname);
	# and verify
	ok := ok && writeop.getstate().ofname == ofname;
	
	ok := ok && writeop.apply();
	
	ok := ok && writeop.tofile(ofname, private.ansdrecord);
	
	# and reset to the default using s from above
	ok := ok && writeop.setstate(s);
	# verify default state
	ok := ok && strlen(writeop.getstate().ofname) == 0;
	return ok;
    }

    const public.testnames := function() {
	wider private;
	return field_names(private.tests);
    }

    const public.test := function(whichtests=unset) {
	wider private, public;
	if (is_unset(whichtests)) whichtests := public.testnames();
	private.clearAndInitialize();
	ntest := 0;
	nfailures := 0;
	results := [=];
	for (atest in whichtests) {
	    ntest +:= 1;
	    ok := F;
	    if (has_field(private.tests,atest)) {
		ok := private.tests[atest]();
	    }
	    if (!private.checkresult(ok,ntest,atest,results)) nfailures +:= 1;
	}

	for (result in results) {
	    note(result);
	}

	return (nfailures == 0);
    }

    const public.done := function() {
	wider private, public;
	val private := F;
	val public := F;
	return T;
    }

    const public.debug := function() {
	wider private;
	return ref private;
    }

    return ref public;
}
