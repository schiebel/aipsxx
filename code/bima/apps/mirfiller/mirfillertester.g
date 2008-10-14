# mirfillertester: a tool for testing mirfiller
# Copyright (C) 2000,2001,2002
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

# Test mirfiller by filling a miriad dataset from the data repository and
# compare the results to a model MS in the repository filled previously
# with a possibliy older version mirfiller

pragma include once;
include 'sysinfo.g';
include 'os.g';
include 'note.g';
include 'mirfiller.g';
include 'table.g';
include 'tablecomparer.g';

const _define_mirfillertester := function(verbose=1, mirdata='', 
                                          modeldata='') {

    public := [=];
    private := [=];
    private.summary := [=];
    private.details := [=];

    private.this := 'mirfillertester';
    private.verbose := verbose;
    private.mirdata := mirdata;
    private.modeldata := modeldata;
    private.details.test := [=];
    private.details.model := [=];
    private.details.diff := [=];

    const private.logit := function(rec,label='',failedonly=F) {
        wider private;
        label := label ~ s/^\.//;
        for(f in field_names(rec)) {
            if(is_record(rec[f])) 
                private.logit(rec[f],spaste(label,'.',f));
            else if(failedonly || !rec[f])
                note(spaste(label,'.',f,': ',rec[f]),origin=private.this);
        }
    }


    const public.runtests := function(fill=T) {
        wider private;
        devdir := spaste(sysinfo().root(),'/data/bima/dev');
        
        if(private.mirdata == '') 
            private.mirdata := spaste(devdir,'/miriad/sgrb2n.small.ll');
        if(private.modeldata == '') 
            private.modeldata := spaste(devdir,'/ms/sgrb2n.ll.small.ms');
        
        testdir := 'mirfillertester.work';
        filleddata := spaste(testdir,'/sgrb2n.test.ms');
        if(fill) {
            if(dos.fileexists(testdir)) {
                dos.remove(testdir);
            }
            dos.mkdir(testdir);
            if(verbose > 0) {
                note(spaste('Begin filling ',mirdata,' to ',filleddata),
                     origin=private.this);
            }
            mf := mirfiller(private.mirdata);
            mf.select('all');
            mf.fill(filleddata);
            mf.done();
        }
        ok := T;
        bb.HISTORY := 'TIME';
        tc := tablecomparer(filleddata,private.modeldata,'MAIN',
                            private.verbose);
        if(is_fail(tc)) fail tc::message;
        if(sysinfo().arch() == 'sun4sol_gnu') {
            tol := [=];
            tol.MAIN.WEIGHT := 1.2e-7;
            tol.MAIN.SIGMA := 4e-6;
            tol.FIELD.DELAY_DIR := 2.3e-16;
            tol.FIELD.PHASE_DIR := 2.3e-16;
            tol.FIELD.REFERENCE_DIR := 2.3e-16;
            tol.SPECTRAL_WINDOW.CHAN_FREQ := 1.6e-5;
            tc.settolerance(cols=tol);
        }
        tc.select(,bb);
        res := tc.compare();
        private.summary := tc.summary();
        private.details := tc.details();
        tc.done();
        if(is_fail(res)) fail(res::message);
        ok := ok && res;
        if(private.verbose > 0) {
            if(ok) note('All tests passed',origin=private.this);
            else note ('One or more tests failed',priority='SEVERE',
                       origin=private.this);
        }
        return ok;
    }

    public.summary := function(verbose=T, failedonly=F) {
        wider private;
        if(verbose) private.logit(private.summary,,failedonly);
        return private.summary;
    }

    public.details := function() {
        wider private;
        return private.details;
    }

    const public.done := function() {
        wider public, private;
        private := F;
        val public := F;
        return T;
    }


    return ref public;
}




const mirfillertester := function(verbose=1, mirdata='', modeldata='')
{
    _define_mirfillertester(verbose, mirdata, modeldata);
}
