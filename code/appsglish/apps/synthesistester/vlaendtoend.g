# vlaendtoend: Test end to end processing of VLA data
#
#   Copyright (C) 1998,1999,2000,2001,2003
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: vlaendtoend.g,v 19.4 2006/04/17 00:57:59 tcornwel Exp $

pragma include once;

vlaendtoend := function() {

  global dowait;
  dowait := T;

  stime := time();

#
# Fill from a disk file containing a VLA export file
#
  include 'vlafiller.g';
  include 'sysinfo.g';
  include 'os.g';

  testdir := 'vlaendtoend';

  note('Cleaning up directory ', testdir);
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); }

  ok := shell(paste("mkdir", testdir));
  if (ok::status) { throw("mkdir", testdir, "fails!") }

  infile := 'dstst.vla';
  if(!dos.fileexists(infile)) {
    infile := spaste(sysinfo().root(), '/data/nrao/VLA/vlafiller_test/dstst.vla');
    if(!dos.fileexists(infile)) {
      return throw ('Cannot file input VLA export file dstst.vla');
    }
  }

  include 'measures.g';
  ok:=vlafillerfromdisk(filename=infile,
			msname=spaste(testdir, "/orion.ms") ,
			overwrite=F,
			project="DSTST" ,
			bandname="X",
			verbose=F,
			async=F);
#
# Do the obvious flagging: autocorrelations, quack, known bad antennas
#
  include 'flagger.g';
  myflagger:=flagger(msfile=spaste(testdir, "/orion.ms") );
  ok:=myflagger.auto();
  ok:=myflagger.quack(scaninterval="5.1s" , delta="10s", trial=F);
  ok:=myflagger.setantennas(ants=21);
  ok:=myflagger.settimerange(starttime="21-SEP-2000/11:15:48" ,
			     endtime=  "21-SEP-2000/13:38:18");
  ok:=myflagger.flag(trial=F);
  ok:=myflagger.reset();
  ok:=myflagger.setantennas(ants=6);
  ok:=myflagger.flag(trial=F);
  ok:=myflagger.reset();
  ok:=myflagger.setids(fieldid=7, spectralwindowid=2);
  ok:=myflagger.setantennas(ants=12);
  ok:=myflagger.flag(trial=F);
  ok:=myflagger.reset();

  myflagger.done();
#
# Set the fluxes for the flux and phase calibraters
#
  include 'imager.g';
  myimager:=imager(filename=spaste(testdir, "/orion.ms") );
  ok:=myimager.setjy(fieldid=1, spwid=-1, fluxdensity=-1.0);
  ok:=myimager.setjy(fieldid=2, spwid=-1, fluxdensity=-1.0);
  myimager.done();
#
# Solve for the gains and apply
#
  include 'calibrater.g';
  mycalibrater:=calibrater(filename=spaste(testdir, "/orion.ms") );
  ok:=mycalibrater.setdata(msselect='FIELD_ID in [1,2]');
  ok:=mycalibrater.setsolve(type="G" , t=300, 
			    table=spaste(testdir, "/orion.gcal"));
  ok:=mycalibrater.solve();
  ok:=mycalibrater.fluxscale(tablein=spaste(testdir, "/orion.gcal"),
			     tableout=spaste(testdir, "/orion.ref.gcal"),
			     reference='0518+165',
			     transfer='0539-057');
  ok:=mycalibrater.setdata(msselect='');
  ok:=mycalibrater.setapply(type="G" ,
			    table=spaste(testdir, "/orion.ref.gcal") ,
			    select="FIELD_NAME=='0539-057'" );
  ok:=mycalibrater.correct();
  mycalibrater.done();
#
# Flag outrageously large points
#
  include 'flagger.g';
  myflagger:=flagger(msfile=spaste(testdir, "/orion.ms") );
  ok:=myflagger.filter(column="CORRECTED_DATA" ,
		       operation="range" ,
		       comparison="Amplitude" ,
		       range='1e-6Jy 1e2Jy',
		       trial=F);
  myflagger.done();
#
# Make an MEM mosaic image
#
  include 'imager.g';
  myimager:=imager(filename=spaste(testdir, "/orion.ms") );
  ok:=myimager.setimage(nx=600,
			ny=600,
			cellx="2arcsec",
			celly="2arcsec",
			stokes="I" ,
			doshift=T,
			phasecenter=dm.direction('B1950', '05:32:50', '-05.25.00.000'),
			spwid=[1, 2]);
  ok:=myimager.setdata(spwid=[1, 2] ,
		       fieldid=[3, 4, 5, 6, 7, 8, 9, 10, 11] ,
		       msselect='');
  ok:=myimager.weight(type="briggs" , robust=-1);
  ok:=myimager.setvp(dovp=T, dosquint=F);
  include 'regionmanager.g';
  ok:=myimager.regionmask(mask=spaste(testdir, "/orion.mask"),
			  region=drm.box([215,215], [385, 385]));
  ok:=myimager.setmfcontrol(scaletype='SAULT', constpb=0.5);
  ok:=myimager.mem(algorithm="mfentropy" ,
		   niter=60,
		   sigma="4mJy",
		   displayprogress=T,
		   model=spaste(testdir, "/orion.mem") ,
		   mask=spaste(testdir, "/orion.mask") ,
		   image=spaste(testdir, "/orion.mem.restored") ,
		   residual=spaste(testdir, "/orion.mem.residual") );
  myimager.done();

  include 'image.g';
  myimage:=image(spaste(testdir, "/orion.mem.restored"));
  myimage.statistics();
  myimage.view();

  note('Completed VLA end-to-end processing in ', time()-stime, ' seconds');

  return T;
}
