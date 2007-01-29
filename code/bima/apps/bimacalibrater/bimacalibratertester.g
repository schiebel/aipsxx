# bimacalibratertester: a tool for testing bimacalibrater
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

pragma include once;
include 'sysinfo.g';
include 'os.g';
include 'note.g';
include 'mirfiller.g'
include 'bimacalibrater.g';
include 'table.g';
include 'bimams.g';
include 'tablecomparer.g'

const _define_bimacalibratertester := function(verbose=1) {

    public := [=];
    private := [=];

    private.this := 'bimacalibratertester';
    private.verbose := verbose;
    private.fill := T;
    private.calibrate := T;
    private.workdir := 'bimacalibratertester_work';
    private.delwork := T;
    private.dataroot := spaste(sysinfo().root(),'/data');
    private.mirroot := spaste(private.dataroot,'/bima/dev/miriad');
    private.cal := [=];
    private.target := [=];
    private.cal.mir := spaste(private.mirroot,'/1733-130.ll');
    private.cal.ms := spaste(private.workdir,'/1733-130.ll.ms');
    private.target.mir := spaste(private.mirroot,'/sgrb2n.ll');
    private.target.ms := spaste(private.workdir,'/sgrb2n.ll.ms');
    private.target.spw := [2,6];
    private.target.winav := [];
    private.target.sbandav := 'all';

    private.caltable := [=];
    private.caltable.orig := spaste(private.workdir,'/gcal');
    private.caltable.xfer := spaste(private.workdir,'/gcal.xfer');

    private.refant := 4;
    private.inttime := 600;

    private.testroot := spaste(private.dataroot,'/bima/test');
    private.model.caltable := (spaste(private.testroot,'/gcal.xfer'));
    private.model.datatable := (spaste(private.testroot,'/sgrb2n.caldata'));

    private.details := [=];
    private.summary := [=];

    const public.setoptions := function(delworkdir=T,fill=T,calibrate=T,
                                        refant=4, inttime=600, targetspw=-1,
                                        targetwinav=-1,targetsbandav='',
                                        modelcaltable='', modeldatatable='') {
        wider private;
        private.fill := fill;
        private.delwork := delworkdir;
        if(!fill) private.calibrate := calibrate;
        else { 
            private.calibrate := T;
            if(!calibrate) note('Forcing calibrate to be T since fill is T',
                                priority='WARN', origin=this);
        }
        private.refant := refant;
        private.inttime := inttime;
        if(len(targetspw) == 0 || targetspw > 0) 
            private.target.spw := targetspw;
        if(len(targetwinav) == 0 || targetwinav > 0) 
            private.target.winav := targetwinav; 
        if(targetsbandav != '') private.target.sbandav := targetsbandav;
        if(modelcaltable != '') private.model.caltable := modelcaltable;
        if(modeldatatable != '') private.model.datatable := modeldatatable;
        return T;
    }

    const public.setcaltables := function(transfer='', original='') {
        wider private;
        if(original != '') private.caltable.orig := original;
        if(transfer != '') private.caltable.xfer := transfer;
        return T;
    }

    const public.setdata := function(mircal='', mirtarget='', mscal='',
                                     mstarget='') {
        wider private;
        if(mircal == '') private.cal.mir := mircal;
        if(mirtarget == '') private.target.mir := mirtarget;
        if(mscal == '') private.cal.ms := mscal;
        if(mstarget == '') private.target.ms := mstarget;
        return T;
    }

    const public.runtests := function(compareonly=F) { 
        wider private;
        if(!dos.fileexists(private.model.caltable))
            fail spaste(private.model.caltable,' does not exist');
        if(!dos.fileexists(private.model.datatable))
            fail spaste(private.model.datatable,' does not exist');
        ok := T;
        workdir := private.workdir;
        mircal := private.cal.mir;
        mscal := private.cal.ms;
        mirtarget := private.target.mir;
        mstarget := private.target.ms;
        this := private.this;
        if(!compareonly) {
            if(private.delwork && dos.fileexists(workdir)) dos.remove(workdir);
            if(!dos.fileexists(workdir)) dos.mkdir(workdir);
            if(private.fill) {
                if(verbose > 0) note('Fill the miriad datasets',origin=this);
                mf := mirfiller(mircal);
                if(is_fail(mf)) fail mf::message;
                mf.select('rawbima');
                mf.fill(mscal);
                mf.done();
                mf := mirfiller(mirtarget);
                if(is_fail(mf)) fail mf::message;
                mf.select('none',private.target.spw, private.target.winav,
                          private.target.sbandav);
                mf.fill(mstarget);
                mf.done();
            }
            if(private.calibrate) {
                if(verbose > 0) note('Reaverage the calibrater data',origin=this);
                bmscal := bimams(mscal);
                res := bmscal.reavg(verbosity=verbose);
                bmscal.done();
                if(is_fail(res)) fail res::message;
                if(!res) 
                    fail 'Reaveraging of calibrater dataset was not successful!';
                bc := bimacalibrater(mstarget,mscal);
                if(is_fail(bc)) fail bc::message;
                bc.setjy(fluxdensity=[1,0,0,0]);
                bc.setsolve(type='G', refant=private.refant,
                            table=private.caltable.orig, t=private.inttime);
                bc.solve();
                bc.transfer(private.caltable.xfer, private.caltable.orig);
                bc.setapply();
                bc.correct();
                bc.done();
            }
        }
        if(verbose > 0) note(spaste('Compare ',private.caltable.xfer,' to ',
                                    private.model.caltable),origin=this);
        ncc.CALTABLE := ['REF_ANT','REF_FEED','REF_RECEPTOR','REF_FREQUENCY',
                'REF_DIRECTION'];
        tc := tablecomparer(private.caltable.xfer,private.model.caltable,
                            'CALTABLE',verbose);
        if(is_fail(tc)) fail tc::message;
        tc.select(,ncc);
        res := tc.compare();
        tc.done();
        if(is_fail(res)) fail res::message;
        if(!res) ok := F;
        if(verbose > 0) {
            if(res) note('All tests on calibration table passed',
                         origin=this);
            else note('One or more tests on the calibration table failed',
                      origin=this,priority='SEVERE');
        }

        if(verbose > 0) note(spaste('Compare MODEL_DATA and CORRECTED_DATA ',
                                    'columns'));
        coc.MS := ['MODEL_DATA','CORRECTED_DATA'];
        tc := tablecomparer(mstarget,private.model.datatable,'MS',verbose);
        tc.select(coc);
        if(sysinfo().arch() == 'sun4sol_gnu') {
            prec := [=];
            prec.MS.CORRECTED_DATA := 3.3e-5;
            tc.settolerance(cols=prec);
        }
        res := tc.compare(F,checktablekeywordnames=F);
        if(verbose > 2) note('Closing tablecomparer tool');
        tc.done();
        if(is_fail(res)) fail res::message;
        if(!res) ok := F;
        if(verbose > 0) {
            if(res) note('All tests on the MS table passed',
                         origin=this);
            else note('One or more tests on the MS table failed',
                      origin=this,priority='SEVERE');
        }
        return ok;
    }

    const public.makemodeldatatable := function(intable, outtable='') {
        if(outtable == '') outtable := intable;
        else dos.copy(intable,outtable);
        t := table(outtable,readonly=F);
        a := t.colnames();
        t.removecols(a[a != 'CORRECTED_DATA' & a != 'MODEL_DATA']);
        t.done();
        return T;
    }

    const public.done := function() {
        wider public, private;
        private := F;
        val public := F;
        return T;
    }

    return ref public;
}

const bimacalibratertester := function(verbose=1) {
    _define_bimacalibratertester(verbose);
}

