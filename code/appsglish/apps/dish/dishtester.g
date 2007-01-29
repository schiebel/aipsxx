# dishtester: dishtester tool
# Copyright (C) 2002
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
# $Id: dishtester.g,v 19.1 2004/08/25 01:11:50 cvsmgr Exp $

# include guard
pragma include once;

include 'unset.g';
 

# this is a closure that is should be used to test dish and
# related tools (dishplotter, iards, dcr tool, dish imaging, etc)

const dishtester := function(adish=unset, testdir='dishtester/')
{
    public:=[=];
    private:=[=];

    include 'dish.g';
    include 'os.g';
    include 'note.g';
    include 'sditerator.g';
    include 'dishdemodata.g';

    include 'dishopstester.g';

    private.adish := unset;
    private.testdir := testdir;
    private.sditerators := [=];
    private.sdrecords := [=];
    private.deletePrivateDish := F;
    private.testers := [=];

    if (!have_gui()) {
	throw('dish tests require a GUI');
    }
    
    # cleans up.  If failattributes is set, then this returns
    # a fail.  That feature is intended to be used during
    # construction, so that cleanup happens even when something
    # bad happens.
    const public.done := function(failattributes=unset) {
	wider private, public;
	# done all of the sub-testers
	for (subtest in private.testers) {
	    ok := subtest.done();
	}

	if (private.deletePrivateDish) ok := private.adish.done();
	if (len(private.sditerators)) {
	    for (it in private.sditerators) {
		if (is_sditerator(it)) ok := it.done();
	    }
	}

	# and remove the testdir and contents
	# ok := dos.remove(private.testdir,mustexist=F);
	# if (is_fail(ok) || !ok) note('Problems removing ', testdir, priority='SEVERE');
	val private := F;
	val public := F;
	if (!is_unset(failattributes)) {
	    failmsg := '';
	    if (is_string(failattributes)) {
		failmsg := failattributes;
	    } else {
		if (is_record(failattributes) && 
		    has_field(failattributes,'message')) 
		failmsg := failattributes.message;
	    }
	    fail(failmsg);
	}
	return T;
    }

    # put the test directory into its place
    note('Cleaning up dishtester directory : ',private.testdir);
    ok := dos.remove(private.testdir,mustexist=F);
    if (is_fail(ok)) {
	note(spaste('Cleanup of ',private.testdir,' fails!'),priority='WARN');
	note('This may cause problems for dish tests.', priority='WARN');
    }
    
    # Make the directory
    if (!dos.fileexists(testdir) || dos.filetype(testdir) != 'Directory') {
	ok := dos.mkdir(testdir);
	if (is_fail(ok)) {
	    return public.done(spaste('Creation of ',private.testdir,' fails!'));
	}
    }
    
    # Make the data
    ok:=dishdemodata(myoutdir=private.testdir);
    if (is_fail(ok)) return public.done(ok::);

    # open an iterator and a get a sample sdrecord
    it := sditerator(spaste(private.testdir,'dishdemo2'));
    if (is_fail(it)) return public.done(it::);

    private.sditerators.dd2 := it;

    r := it.get();
    if (is_fail(r)) return public.done(r::);

    private.sdrecords.r := r;

    if (is_unset(adish) ||
	!is_record(adish) || !has_field(adish,'type') || !adish.type('dish')) {
	private.adish := dish();
	private.deletePrivateDish := T;
    } else {
	private.adish := adish;
	# ask about losing contents of this dish
	if (choice('Testing using this dish will clear its current contents, is that OK?',
		   "Yes Cancel",
		   "plain dismiss", 2) != "Yes") {
	    return F;
	}	    
    }

    # clear the contents
    # restore adish to its default state
    note('Restoring test dish to the default state');
    ok := private.adish.restorestate(T);
    if (is_fail(ok)) return public.done(ok::);

    # check function - to be used by sub-system checkers
    public.checkresult  := function(ok,ntest,nametest,ref results) {
	# return F if there was a failure
	result := F;
	if (is_fail(ok)) {
	    # some fails don't produce a message
	    message := '';
	    if (has_field(ok::,message)) message := ok::message;
	    results[ntest] := paste("Test",ntest," on ", nametest, 
				    "failed",message);
	} else if (is_boolean(ok)) {
	    if (ok) {
		result := T;
		results[ntest] := paste("Test",ntest," on ",nametest,
					"succeeded");
	    } else {
		results[ntest] := paste("Test",ntest," on ",nametest,
					"failed ");
	    }
	} else {
	    results[ntest] := paste("test",ntest," on ",nametest,
				    "returned", ok);
	}
	return result;
    }

    # okay, start adding in the sub-tests
    private.testers.ops := dishopstester(private.adish, 
					 private.sditerators.dd2,
					 private.sdrecords.r,
					 private.testdir,
					 public.checkresult);
    
    const public.testnames := function() {
	wider private;
	return field_names(private.testers);
    }

    const public.subtest := function(whichtest) {
	wider private, public;
	tester := public.subtester(whichtest);
	result := F;
	if (is_record(tester) && has_field(tester,'test')) {
	    result := tester.test();
	} else {
	    throw(spaste('Unavailable dishtester subtest : ',whichtest));
	}
	return result;
    }
    
    const public.subtester := function(whichtest) {
	result := F;
	if (has_field(private.testers, whichtest) &&
	    is_record(private.testers[whichtest])) {
	    result := private.testers[whichtest];
	}
	return result;
    }

    const public.test := function(whichtests=unset) {
	wider private, public;
	# Start the timing here
	note('## Start timing');
	stime:=time();
	if (is_unset(whichtests)) whichtests := public.testnames();
	results := [=];
	ntest := 0;
	nfailures := 0;
	for (atest in whichtests) {
	    ntest +:= 1;
	    ok := F;
	    ok := public.subtest(atest);
	    if (!public.checkresult(ok,ntest,atest,results)) nfailures +:= 1;
	}
	for (result in results) {
	    note(result);
	}

	etime:=time();
	note('## dishtester.test()');
	note('## Finished in run time = ',(etime-stime),' seconds');

	return (nfailures == 0);
    }

    const public.type := function() {return "dishtester";};

    const public.debug := function() {
	wider private;
	return ref private;
    }

    # Return a reference to the public interface
    return ref public;  
}


const dishalltest := function() {
    include 'dish.g';
    mytester := dishtester();
    ok := mytester.test();
    mytester.done();
    return ok;
}
