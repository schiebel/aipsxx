# bimatester: test tool for BIMA data
# Copyright (C) 1999,2000,2001,2002
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
# $Id: bimatester.g,v 19.0 2003/07/16 03:35:42 aips2adm Exp $

# Include guard
pragma include once;
 
# Include files

include 'mirfiller.g';
include 'bimacalibrater.g';
include 'note.g';
include 'imager.g';
include 'sysinfo.g';
include 'tablecomparer.g';
include 'os.g';

#
# Define a bimatester instance
#
const _define_bimatester := function(verbose=1) {
#
    private := [=];
    public := [=];

    private.this := 'bimatester';
    private.caldir := 'bimacalibratertester_work';
    private.target := spaste(private.caldir,'/sgrb2n.ll.ms');
    private.imagedir := 'bimaimagertester_work';
    private.image := [=];
    private.image.dirty := spaste(private.imagedir,'/sgrb2n.spw1.dirty');
    private.image.clean := spaste(private.imagedir,'/sgrb2n.spw1.clean');
    private.image.restored := spaste(private.imagedir,'/sgrb2n.spw1.restored');
    private.image.mask := spaste(private.imagedir,'/sgrb2n.spw1.mask');

    private.datadir := spaste(sysinfo().root(),'/data/bima/test');
    private.model.dirty := spaste(private.datadir,'/sgrb2n.spw1.dirty');
    private.model.restored := spaste(private.datadir,'/sgrb2n.spw1.restored');
    private.summary := [=];

    const private.makeimage := function(image=T, clean=T) {
        wider private;
        if(!dos.fileexists(private.imagedir)) dos.mkdir(private.imagedir);
        ok := T;
        im := imager(private.target);
        im.setdata('channel',nchan=128,spwid=1);
        im.setimage(256,256,'1.5arcsec','1.5arcsec','I',mode='channel',
                    nchan=128,spwid=1);
        if(image) {
            im.weight('natural');
            res := im.makeimage('corrected',private.image.dirty);
            if(is_fail(res)) fail res::message;
            tc := tablecomparer(private.image.dirty,private.model.dirty,
                                'DIRTY',verbose);
            if(is_fail(tc)) fail tc::message;
            res := tc.compare();
            tc.done();
            if(is_fail(res)) fail res::message;
            if(!res) ok := F;
            private.summary.IMAGING := res;
            if(verbose) {
                if(res) note('Tests on dirty image passed',
                             origin=private.this);
                else note('Tests on dirty image failed', priority='SEVERE',
                          origin=private.this);
            }
        }
        if(clean) {
            if(dos.fileexists(private.image.clean)) 
                dos.remove(private.image.clean);
            if(dos.fileexists(spaste(private.image.clean,'.residual'))) 
                dos.remove(spaste(private.image.clean,'.residual'));
            if(dos.fileexists(private.image.restored)) 
                dos.remove(private.image.restored);
            im.clean(niter=100,model=private.image.clean,
                     image=private.image.restored);
            if(dos.fileexists(private.image.restored)) 
                dos.remove(private.image.restored);
            im.restore(private.image.clean,image=private.image.restored,
                       residual=spaste(private.image.clean,'.residual'));
            tc := tablecomparer(private.image.restored,private.model.restored,
                                'RESTORED',verbose);
            if(is_fail(tc)) fail tc::message;
            res := tc.compare();
            tc.done();
            private.summary.CLEANING := res;
            if(is_fail(res)) fail res::message;
            if(!res) ok := F;
            if(verbose) {
                if(res) note('Tests on restored cleaned image passed',
                             origin=private.this);
                else note('Tests on restored cleaned image failed', 
                          priority='SEVERE',
                          origin=private.this);
            }
        }
        im.done();
        return ok;
    }

    const public.runtests := function(fill=T, calibrate=T, image=T, clean=T) {
        wider private;
        arch := sysinfo().arch();
        this := private.this;
        if((image || clean) && arch != 'linux_gnu') {
            note(spaste('Because the fiducial images were made using a linux ',
                        'installation'), priority='WARN', origin=this);
            note(spaste('and because of significant differences when imaging ',
                        'on other '), origin=this, priority='WARN');
            note('OS\'s, imaging tests will not be performed', origin=this, 
                 priority='WARN');
        }
        ok := T;
        if(fill) {
            if(verbose > 0) note('Running filler tests',origin=this);
            res := mirfillertest();
            private.summary.FILLER := res;
            if(res) {
                if(verbose > 0) note('Filler tests passed',origin=this);
            } else {
                ok := F;
                note('Filler tests failed',origin=this,priority='SEVERE');
            }
        }
        if(calibrate) {
            if(verbose > 0) note('Running bimacalibrater tests',origin=this);
            res := bimacalibratertest();
            private.summary.CALIBRATION := res;
            if(res) {
                if(verbose > 0) note('Bimacalibrater tests passed',
                                     origin=this);
            } else {
                ok := F;
                note('Bimacalibrater tests failed',origin=this,
                     priority='SEVERE');
            }
        } else if((image || clean) && arch == 'linux_gnu') {
            private.target := spaste(private.imagedir,'/sgrb2n.ll.ms');
            if(!dos.fileexists(spaste(private.imagedir,'/sgrb2n.ll.ms'))) {
                if(!dos.fileexists(private.imagedir)) {
                    note(spaste('Making ', private.imagedir));
                    res := dos.mkdir(private.imagedir);
                    if(!res || is_fail(res)) 
                        fail spaste('Failed to make ',private.imagedir);
                }
                res := dos.copy(spaste(private.datadir,'/sgrb2n.caldata'),
                                spaste(private.imagedir,'/sgrb2n.ll.ms'));
                if(is_fail(res)) fail res::message;
            }
        }
        if((image || clean) && arch == 'linux_gnu') {
            if(verbose) note('Running imager tests',origin=this);
            res := private.makeimage(image,clean);
            if(is_fail(res)) fail res::message;
            if(!res) ok := F;
        }
        if(verbose > 0) {
            if(ok) note('All tests passed', origin=private.this);
            else note('One or more tests failed', origin=private.this,
                      priority='SEVERE');
        }
        return ok;
    }

    public.summary := function(verbose=T) {
        wider private;
        if(verbose) private.logit(private.summary,'BIMATESTER');
        return private.summary;
    }

    const private.logit := function(rec,label='') {
        wider private;
        label := label ~ s/^\.//;
        for(f in field_names(rec)) {
            if(is_record(rec[f]))
                private.logit(rec[f],spaste(label,'.',f));
            else {
                if(rec[f]) p := 'NORMAL';
                else p := 'SEVERE';
                note(spaste(label,'.',f,': ',rec[f]), origin=private.this,
                     priority=p);
            }
        }
    }

    const public.close := function() {
        return T;
    }

    const public.done := function() {
        wider public, private;
        private := F;
        val public := F;
        return T;
    }

    return ref public;

} # _define_bimatester()


## Constructor

const bimatester := function(verbose=1) {
    _define_bimatester(verbose);  
} 

const bimatest := function(verbose=1, summarize=T, fill=T, calibrate=T, 
                           image=T, clean=T) {
    bt := bimatester(verbose);
    if(is_fail(bt)) fail bt::message;
    res := bt.runtests(fill, calibrate, image, clean);
    if(summarize) {
        note('Summarizing...')
        bt.summary(T);
    }
    bt.done();
    return res;
}
