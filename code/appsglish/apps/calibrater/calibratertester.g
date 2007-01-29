# calibratertester: test tool for calibrater
# Copyright (C) 1999,2000,2002
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
# $Id: calibratertester.g,v 19.2 2004/08/25 01:05:04 cvsmgr Exp $

# Include guard
pragma include once
 
# Include files

include 'imager.g';
include 'calibrater.g';
include 'ms.g';
include 'statistics.g';
include 'sysinfo.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';
include 'misc.g';


#
# Define a calibratertester instance
#
const _define_calibratertester := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private data and functions
#------------------------------------------------------------------------
#
   # Flags indicating which tests have run successfully
   private.results := [=];

   const private.maketestms := function (fitsfile, msname, dirname) 
   {
   # Make the test MS from the specified FITS file in the
   # requested directory. The directory is deleted and
   # re-created before each test run.

      # Clean up the directory
      if(dos.fileexists(dirname)){
         note ('Cleaning up test directory ', dirname);
         ok := dos.remove (dirname, mustexist=F)
         if (ok::status) {
            return throw ('Cleanup of ', dirname, ' failed');
         };
      }

      # Re-make the directory
      ok := shell (paste ("mkdir", dirname));
      if (ok::status) {
         return throw ('Could not create test directory ', dirname);
      };

      # Fill the data from the specified FITS file
      if (!dms.fileexists (fitsfile)) {
         return throw (paste ('FITS file', fitsfile, 'not found'));
      } else {
         fullmsname := spaste (dirname, '/', msname);
         mstest := fitstoms (msfile=fullmsname, fitsfile=fitsfile, readonly=F);
         if (is_fail(mstest)) return throw (mstest::message);
         mstest.done();
      };
      return T;
   };

   const private.setmodel := function (fullmsname, iquv) 
   {
   # Set a point source model of a specified flux density
   #
      # Create a local imager tool
      imagr := imager (fullmsname);
      if (is_fail(imagr)) return throw (imagr::message);
      # Set the default source model
      ok := imagr.setjy (fluxdensity=iquv);
      if (is_fail(ok)) return throw (ok::message);
      imagr.done();
      return T;
   };

   const private.defaultmodel := function (fullmsname) 
   {
   # Set the default unit point source model
   #
      return private.setmodel (fullmsname, iquv=-1);
   };

   const private.comparecal := function (testtype, testsubtype, caltable, 
      ref stats)
   {
   # Compare derived with expected solutions
   #
      # Initialization
      val stats := [=];

      # Get caldesc:
      caldesctab:=table(spaste(caltable,'/CAL_DESC'));
      spwlist:=caldesctab.getcol('SPECTRAL_WINDOW_ID')+1;
      caldesctab.done();

      # Open the calibration table
      caltab := table (caltable);
      if (is_fail(caltab)) return throw (caltab::message);

      caltabiter:=tableiterator(caltab,"CAL_DESC_ID");
      caltabiter.reset();



      ndiff := 0;
      while (caltabiter.next()) {

	thiscal:=caltabiter.table();

	thiscaldesc:=thiscal.getcell("CAL_DESC_ID",1)+1;

	thisspw:=spwlist[thiscaldesc];

	# Read the calibration solutions
	times := thiscal.getcol ('TIME');
	ant := thiscal.getcol ('ANTENNA1');
	gain := thiscal.getcol ('GAIN');
	mask := thiscal.getcol ('SOLUTION_OK');
	if (len(times) == 0) return throw ('Invalid calibration table');


	# Compute the expected solutions
	gainref := private.gainref (testtype, testsubtype, times, thisspw, ant);
	if (is_fail(gainref)) return throw (gainref::message);


	# Accumulate statistics
	npol := max (gain::shape[1], gain::shape[2]);
	tuniq := unique (times);
	nuniq := len (tuniq);
	for (t in 1:nuniq) {
	  tmask := (times == tuniq[t]);
	  for (ipol in 1:npol) {
	    gainsub := gain[ipol,ipol,1,1,tmask][mask[1,1,tmask]];
	    gainrefsub := gainref[ipol,ipol,1,1,tmask][mask[1,1,tmask]];
	    nsub := len (gainsub);
	    i := 1;
	    while (i < nsub) {
	      j := i + 1;
	      while (j <= nsub) {
		diff[ndiff+1] := gainsub[j] * conj (gainsub[i]) - 
		  gainrefsub[j] * conj (gainrefsub[i]);
		ndiff := ndiff + 1;
		j := j + 1;
	      };
	      i := i + 1;
	    };
	  };
	};
	
      };
      caltabiter.done();
      caltab.done();

      val stats.mean := mean (diff);
      val stats.rms := variance (diff);
      val stats.snr := abs (stats.mean) / abs (stats.rms);

      return T;
   };      

   const private.compareuv := function (testtype, testsubtype, fullmsname, 
      ref stats)
   {
   # Compare derived with expected solutions
   #
      # Initialization
      val stats := [=];

      # Open the MS
      mstab := table (fullmsname);
      if (is_fail(mstab)) return throw (mstab::message);

      # Read the corrected data
      corrected := mstab.getcol ('CORRECTED_DATA');
      if (len(corrected) == 0) return throw ('Invalid MS');

      # Compute statistics wrt expected corrected data
      uvref := private.uvref (testtype, testsubtype, corrected);
      if (is_fail(uvref)) return throw (uvref::message);

      diff := corrected - uvref;

      # Accumulate statistics
      npol := corrected::shape[1];
      polmask := array (F, npol);
      polmask[1] := T;
      polmask[npol] := T;

      diff := diff[polmask,,];

      val stats.mean := mean (diff);
      val stats.rms := variance (diff);
      val stats.snr := 1.0 / abs (stats.rms);

      return T;
   };      

   const private.uvref := function (testtype, testsubtype, corrected)
   {
   # Compute the expected corrected uv data
   #
      # Case test_type of:
      #
      # G.1CH2SP4P3S; continuum, 2 spw, 4 polzn, 3 sources, unpolarized
      #
      if (testsubtype == 'G.1CH2SP4P3S') {
         # Compute the expected uv data
         uvref := corrected;
         nslot := corrected::shape[3];
         for (t in 1:nslot) {
            uvref[,1,t] := [1.0, 0.0, 0.0, 1.0];
         };
         return uvref;
      #
      # G.1CH2SP4P3SB; continuum, 2 spw, 4 polzn, 3 sources,
      #                polarized (I=1, Q=0.6, U=0.5, V=0)
      #
      } else if (testsubtype == 'G.1CH2SP4P3SB') {
         # Compute the expected uv data
         uvref := corrected;
         nslot := corrected::shape[3];
         i:= 1;
         q:= 0.6;
         u:= 0.5;
         v:= 0.0;
         for (t in 1:nslot) {
            uvref[,1,t] := [1.0, 0.0, 0.0, 1.0];
         };
         return uvref;
      #
      # OTHER:
      } else {
         return throw ('Unrecognized test type');
      };
   };

   const private.gainref := function (testtype, testsubtype, time, spw, ant)
   {
   # Compute the expected gain solutions
   #
      # Case test_type of:
      #
      # G.1CH2SP4P3S; continuum, 2 spw, 4 polzn, 3 sources, unpolarized, or
      # G.1CH2SP4P3SB; as preceding, but i=1,q=0.6,u=0.5,v=0
      #
      if (testsubtype == 'G.1CH2SP4P3S' || testsubtype == 'G.1CH2SP4P3SB') {
         # Set the known calibration errors for these tests
         err := [=];
         for (i in 1:4) {
            rec1 := [order=[0,0], range=[0,0], scale=[0,0], offset=[0,0]];
            rec := [amp=rec1, phase=rec1];
            err[i] := [R=rec, L=rec];
         };

         # Antenna 1         
         err[1].R.amp := [order=[0, 1], range=[1.0, 1.0], scale=[0.15, 0.12],
            offset=[1.0, 1.0]];
         err[1].R.phase := [order=[2, 4], range=[1.0, 1.0], scale=[10.0, 76.0],
            offset=[0.0, 0.0]];
         err[1].L.amp := [order=[1, 7], range=[1.0, 1.0], scale=[0.05, 0.08],
            offset=[1.0, 1.0]];
         err[1].L.phase := [order=[3, 5], range=[1.0, 1.0], 
            scale=[-40.0, -34.0], offset=[0.0, 0.0]];

         # Antenna 2
         err[2].R.amp := [order=[5, 2], range=[1.0, 1.0], scale=[0.08, 0.04],
            offset=[1.0, 1.0]];
         err[2].R.phase := [order=[4, 0], range=[1.0, 1.0], scale=[60.0, 60.0],
            offset=[0.0, 0.0]];
         err[2].L.amp := [order=[2, 8], range=[1.0, 1.0], scale=[0.10, 0.16],
            offset=[1.0, 1.0]];
         err[2].L.phase := [order=[1, 6], range=[1.0, 1.0], 
            scale=[20.0, 65.0], offset=[0.0, 0.0]];

         # Antenna 3
         err[3].R.amp := [order=[8, 4], range=[1.0, 1.0], scale=[0.03, 0.11],
            offset=[1.0, 1.0]];
         err[3].R.phase := [order=[10, 2], range=[0.5, 1.0], 
            scale=[30.0, 83.0], offset=[0.0, 0.0]];
         err[3].L.amp := [order=[2, 6], range=[1.0, 1.0], scale=[0.05, 0.10],
            offset=[1.0, 1.0]];
         err[3].L.phase := [order=[8, 2], range=[0.2, 1.0], 
            scale=[25.0, -5.0], offset=[0.0, 0.0]];

         # Antenna 4
         err[4].R.amp := [order=[0, 5], range=[1.0, 1.0], scale=[0.2, 0.06],
            offset=[1.0, 1.0]];
         err[4].R.phase := [order=[4, 1], range=[0.2, 1.0], 
            scale=[60.0, -50.0], offset=[0.0, 0.0]];
         err[4].L.amp := [order=[0, 2], range=[1.0, 1.0], scale=[0.0, 0.17],
            offset=[1.0, 1.0]];
         err[4].L.phase := [order=[1, 4], range=[1.0, 1.0], 
            scale=[20.0, 40.0], offset=[0.0, 0.0]];

         # Compute the expected gain solutions
	 gainref :=array (1+0i, 2, 2, 1,1, len(time));
	 for (t in 1:len(time)) {
	   mjd := time[t] / 86400.0;
	   fracday := mjd - floor (mjd);
	   ipol := 1;
	   for (pol in ['R','L']) {
	     gainref[ipol,ipol,1,1,t] := 
	       private.chebyerror (err[ant[t]+1][pol], spw, fracday);
	     ipol := ipol + 1;
	   };
	 };
         return gainref;
      } else {
         return throw ('Unrecognized test type');
      };
   };

   const private.chebyerror := function (errparms, spw, fracday)
   {
   # Compute an error in Chebyshev form
   #
      result := [=];
      for (type in ['amp','phase']) {
         order := errparms[type].order[spw];
         a := 0.0;
         b := errparms[type].range[spw];
         xn := floor (fracday / b);
         x := fracday - xn * b;
         cheby := private.chebyshev (a, b, x, order);
         scale := errparms[type].scale[spw];
         offset := errparms[type].offset[spw];
         result[type] := cheby[order+1] * scale + offset;
      };
      # Construct phasor
      phsrad := result.phase / 180.0 * pi;
      re := result.amp * cos (phsrad);
      im := result.amp * sin (phsrad);
      return complex (re, im);
   };

   const private.chebyshev := function (a, b, x, n)
   {
   # Evalute a Chebyshev polynomial
   #
      # Transform to range [a,b]
      xab := (2 * x - a -b) / (b - a);
      xab2 := 2.0 * xab;
      result := array (0, n+1);
      result[1] := 1.0;
      # n=0
      if (n==0) return result;
      result[2] := xab;
      # n=1
      if (n==1) return result;
      # n>1
      for (i in 2:n) {
         result[i+1] := xab2 * result[i] - result[i-1];
      };
      return result;
   };

   const private.printstats := function (testtype, testsubtype, stats, passed)
   {
   # Print the test statistics
   #
      title := '';
      if (testsubtype == 'G.1CH2SP4P3S') {
         title := 
            'G Jones; continuum, 2 spw, (RR,LL,RL,LR), 3 sources, unpolarized';
      } else if (testsubtype == 'G.1CH2SP4P3SB') {
         title := 
            'G Jones; continuum, 2 spw, (RR,LL,RL,LR), 3 sources, polarized';
      };

      hdr := spaste (rep('-',65));
      note (hdr);
      note (spaste('Test type: ', testtype));
      note (spaste('Sub-type : ',title));
      if (passed) {
         result := 'PASSED';
      } else {
         result := 'FAILED';
      };
      note (spaste('Status: ', result));
      note (sprintf('Mean deviation: %15.6e', abs(stats.mean)));
      note (sprintf('RMS deviation : %15.6e', abs(stats.rms)));
      note (sprintf('SNR           : %15.6f', stats.snr));
      note (hdr);
      return T;
   };
      
#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.testsolve := function (testsubtype=unset)
   {
   # Test the calibrater.solve() method
   #
      wider private;

      # Case test_type of:
      #
      # G.1CH2SP4P3S; continuum, 2 spw, 4 polzn, 3 sources, unpolarized
      if (testsubtype == 'G.1CH2SP4P3S') {

         # Create the test MS
         testname := 'G1CH2SP4P3S';
         aipsroot := sysinfo().root();
         fitsfile := spaste (aipsroot, '/data/demo/calibrater/',
            testname, '.fits');
         msname := spaste (testname, '.ms');
         dirname := 'testsolve';
         ok := private.maketestms (fitsfile, msname, dirname);
         if (is_fail(ok)) return throw (ok::message);

         # Set the default source model
         fullmsname := spaste (dirname, '/', msname);
         ok := private.defaultmodel (fullmsname);
         if (is_fail(ok)) return throw (ok::message);

         # Create a local calibrater tool
         cal := calibrater (fullmsname);
         if (is_fail(cal)) return throw (cal::message);

         # Set solution parameters
         caltabname := spaste (dirname, '/', testname, '.gcal');
         ok := cal.setsolve (type='G', t=10.0, phaseonly=F, table=caltabname,
            append=F);
         if (is_fail(ok)) return throw (ok::message);

         # Solve
         ok := cal.solve();
         if (is_fail(ok)) return throw (ok::message);

         # Close the calibrater tool
         cal.done();

         # Compare derived and expected solutions
         stats := F
         ok := private.comparecal('testsolve', testsubtype, caltabname, stats);
         if (is_fail(ok)) return throw (ok::message);

         # Decide if test passed and report results
         passed := (stats.snr > 10.0);
         private.printstats ('testsolve', testsubtype, stats, passed);

         # Update test flags
         private.results.testsolve := [test=testsubtype, status=passed];
         return passed;
      #
      # G.1CH2SP4P3SB; continuum, 2 spw, 4 polzn, 3 sources, polarized
      #
      } else if (testsubtype == 'G.1CH2SP4P3SB') {

         # Create the test MS
         testname := 'G1CH2SP4P3SB';
         aipsroot := sysinfo().root();
         fitsfile := spaste (aipsroot, '/data/demo/calibrater/',
            testname, '.fits');
         msname := spaste (testname, '.ms');
         dirname := 'testsolve';
         ok := private.maketestms (fitsfile, msname, dirname);
         if (is_fail(ok)) return throw (ok::message);

         # Set a point source model with [i=1,q=0.6,u=0.5,v=0]
         fullmsname := spaste (dirname, '/', msname);
         ok := private.setmodel (fullmsname, [1.0, 0.6, 0.5, 0.0]);
         if (is_fail(ok)) return throw (ok::message);

         # Create a local calibrater tool
         cal := calibrater (fullmsname);
         if (is_fail(cal)) return throw (cal::message);

         # Set solution parameters
         caltabname := spaste (dirname, '/', testname, '.gcal');
         ok := cal.setsolve (type='G', t=10.0, phaseonly=F, table=caltabname,
            append=F);
         if (is_fail(ok)) return throw (ok::message);

         # Solve
         ok := cal.solve();
         if (is_fail(ok)) return throw (ok::message);

         # Close the calibrater tool
         cal.done();

         # Compare derived and expected solutions
         stats := F
         ok := private.comparecal('testsolve', testsubtype, caltabname, stats);
         if (is_fail(ok)) return throw (ok::message);

         # Decide if test passed and report results
         passed := (stats.snr > 10.0);
         private.printstats ('testsolve', testsubtype, stats, passed);

         # Update test flags
         private.results.testsolve := [test=testsubtype, status=passed];
         return passed;
      #
      # UNSET:
      } else if (is_unset(testsubtype)) {
         return throw ('No calibrater test type specified');
      #
      # OTHER:
      } else {
         return throw ('Invalid calibrater test type');
      };
   };

   const public.testcorrect := function (testsubtype=unset)
   {
   # Test the calibrater.correct() method
   #
      wider private, public;

      # Case test_type of:
      #
      # G.1CH2SP4P3S; continuum, 2 spw, (RR,LL,RL,LR),3 sources,unpolarized, or
      # G.1CH2SP4P3SB; as preceding, but polarized (i=1,q=0.6,u=0.5,v=0)
      if (testsubtype == 'G.1CH2SP4P3S' || testsubtype == 'G.1CH2SP4P3SB') {
         
         # Check if testsolve has run
         if (!has_field (private.results, 'testsolve') ||
            private.results.testsolve.test != testsubtype ||
            !private.results.testsolve.status) {
            ok := public.testsolve (testsubtype=testsubtype);
            if (is_fail(ok)) return throw (ok::message);
         };

         testname := testsubtype ~ s/\.//;
         msname := spaste (testname, '.ms');
         dirname := 'testsolve';

         # Create a local calibrater tool
         fullmsname := spaste (dirname, '/', msname);
         cal := calibrater (fullmsname);
         if (is_fail(cal)) return throw (cal::message);
         
         # Apply the derived calibration solutions
         caltabname := spaste (dirname, '/', testname, '.gcal');
         ok := cal.setapply (type='G', t=0.0, table=caltabname);
         if (is_fail(ok)) return throw (ok::message);

         ok := cal.correct();
         if (is_fail(ok)) return throw (ok::message);

         # Compute statistics on the corrected data
         stats := F
         private.compareuv ('testcorrect', testsubtype, fullmsname, stats);

         # Decide if test passed and report results
         passed := (stats.snr > 10.0);
         private.printstats ('testcorrect', testsubtype, stats, passed);

         return passed;
   
      #
      # UNSET:
      } else if (is_unset(testsubtype)) {
         return throw ('No calibrater test type specified');
      #
      # OTHER:
      } else {
         return throw ('Invalid calibrater test type');
      };
   };  
         




   const public.done := function()
   {
      wider private, public;

      private := F;
      val public := F;
      if (has_field(private, 'gui')) {
         ok := private.gui.done(T);
         if (is_fail(ok)) fail;
      }
      return T;
   }

   const public.type := function() {
      return 'calibratertester';
   }

   const public.gui := function() 
   {
   # Null 
      return T;
   };

   plugins.attach('calibratertester', public);
   return ref public;

} # _define_calibratertester()

#
# Constructor
#
const calibratertester := function() {
#   
   return ref _define_calibratertester();
} 

# 
#------------------------------------------------------------------------
#








