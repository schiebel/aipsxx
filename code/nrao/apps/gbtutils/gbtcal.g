# gbtcal: GBT calibration utilities (temporary only)
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
#   $Id: gbtcal.g,v 19.2 2004/01/25 00:43:55 wyoung Exp $

pragma include once

gbtcal := function(msname) {
  
  include 'table.g';

  private := [=];

  private.msname := msname;

#
# Use imager to add the Corrected and Model data columns
#
  private.tab := table(private.msname, readonly=F, ack=F);
  if(!any(private.tab.colnames()=='CORRECTED_DATA')) {
    private.tab.close();
    private.virgin := T;
    include 'imager.g';
    im:=imager(msname);im.close();im.done();
    private.tab := table(private.msname, readonly=F, ack=F);
  }
  else {
    private.virgin := F;
  }


#
# Smooth a function using a running filter
#
  private.smooth := function(x, width=5, method='mean') {
    include 'statistics.g';
    if(width==1) return x;
    newx := array(0.0, length(x));
    for (i in 1:length(x)) {
      if(method=='median') {
	newx[i] := median(x[max(1,(i-width)):min(length(x), (i+width))]);
      }
      else {
	newx[i] := mean(x[max(1,(i-width)):min(length(x), (i+width))]);
      }
      if(i%1000==1) {
	print i, 'of ', length(x), ':', x[i], '->', newx[i];
      }
    }
    return newx;
  }
#
# Find SNR
#
  private.statistics := function(x, width=100) {
    include 'statistics.g';
    nblocks := length(x)/width;
    signal := array(0.0, nblocks);
    noise  := array(0.0, nblocks);
    for (i in 1:nblocks) {
      block:=x[(1+(i-1)*width):(min(length(x), 1+i*width))];
      signal[i] := mean(block);
      error := block - signal[i];
      noise[i] := sqrt(sum(error*error)/length(block));
      print i, signal[i], noise[i], signal[i]/noise[i];
    }
    return [snr=max(signal/noise), leastnoise=min(noise), noise=median(noise)];
  }
  public.fixtime := function(offset=1.0, force=F) {
    wider private;
    if(!private.virgin&&!force) {
      note('Not a virgin MS: use force argument to force time fix',
	   priority='WARN');
      return F;
    }
    ttab:=table(private.tab.getkeyword('POINTING'), readonly=F, ack=F);
    tt := ttab.getcol('TIME');
    tmin := min(tt);
    tt-:=offset;
    print min(tt)-tmin;
    ttab.putcol('TIME', tt);
    ttab.flush();
    ttab.close();
  }
#
# Now the calibration
#
  public.calibrate := function(width=100, method='mean', doplot=T) {
    wider private;
#
# Get data for all cal phases
#
    phases := [=];
    phases[1] := private.tab.query('NRAO_GBT_RECEIVER_ID==0&&NRAO_GBT_STATE_ID==0');
    phases[2] := private.tab.query('NRAO_GBT_RECEIVER_ID==0&&NRAO_GBT_STATE_ID==1');
    phases[3] := private.tab.query('NRAO_GBT_RECEIVER_ID==1&&NRAO_GBT_STATE_ID==0');
    phases[4] := private.tab.query('NRAO_GBT_RECEIVER_ID==1&&NRAO_GBT_STATE_ID==1');

    times := [=];
    data := [=];
    for (i in 1:4) {
      times[i]  := phases[i].getcol('TIME');
      times[i] -:= min(times[i]);
      data[i]   := phases[i].getcol('FLOAT_DATA');
    }
#
# This seems to be the one that we want
#
    cal := [=];
    cal[1] := data[2] - data[1];
    cal[2] := data[4] - data[3];
#
# Smooth
#
    scal := [=];
    scal[1] := private.smooth(cal[1], width, method);
    scal[2] := private.smooth(cal[2], width, method);
#
# Plot the smoothed cal
#
#
# Recalibrate
#
    data[1] := data[1]/scal[1];
    data[2] := data[2]/scal[1];
    data[3] := data[3]/scal[2];
    data[4] := data[4]/scal[2];
#
    if(doplot) {
      include 'pgplotter.g';
      p:=pgplotter(background='white', foreground='black');
      p.settings(nxsub=1, nysub=2);
      
      p.sci(1);
      p.plotxy(times[1], data[2]);
      p.sci(2);
      p.pt(times[1], data[4]);
      p.sci(1);
      p.lab('Time (s)', 'Flux', 'Final calibrated flux vs time');
      
      p.sci(1);
      p.plotxy(times[1], scal[1]);
      p.sci(2);
      p.pt(times[1], scal[2]);
      p.sci(1);
      p.lab('Time (s)', 'Smoothed cal', 'Smoothed calibration signal vs time');
      
      p.postscript(spaste(private.msname, '.final.ps'));
      p.done();
    }

#
# Put back into the corrected data for second phase
#
    note('Writing calibrated data to CORRECTED_DATA column', priority='WARN');
    for (i in 1:4) {
      print i, phases[i].putcol('CORRECTED_DATA', complex(data[i]));
    }
#
    note(private.msname,' : calibrated');
  }

#
# Now the calibration
#
  public.resetcal := function() {
    wider private;
#
# Get data for all cal phases
#
    print private.tab.putcol('CORRECTED_DATA', complex(private.tab.getcol('FLOAT_DATA')));
    note(private.msname,' : calibration reset');
  }

#
# Now fix up the sigmas: do this after calibration
#
  public.setsigma := function(scale=1/100.0, offset=0.0) {
    wider private;
#
# Get data for all cal phases
#
    data  := real(private.tab.getcol('CORRECTED_DATA'));
    sigma := array(offset, 1, data::shape[3]);
    sigma +:= scale * data[1,,];
    sigma::shape := [1, data::shape[3]];
    print private.tab.putcol('SIGMA', sigma);
    note(private.msname,': set sigmas');
  }
#
# Find the sigmas
#
  public.statistics := function(width=1000) {
    wider private;
#
# Get data for all cal phases
#
    phases := [=];
    phases[1] := private.tab.query('NRAO_GBT_RECEIVER_ID==0&&NRAO_GBT_STATE_ID==0');
    phases[2] := private.tab.query('NRAO_GBT_RECEIVER_ID==0&&NRAO_GBT_STATE_ID==1');
    phases[3] := private.tab.query('NRAO_GBT_RECEIVER_ID==1&&NRAO_GBT_STATE_ID==0');
    phases[4] := private.tab.query('NRAO_GBT_RECEIVER_ID==1&&NRAO_GBT_STATE_ID==1');
    data   := real(phases[2].getcol('CORRECTED_DATA'));

    return private.statistics (data, width);
  }

  public.fixpnt := function(freq=2000000000.0) {
    atab := table(private.tab.getkeyword('ANTENNA'), readonly=F, ack=F);
    ant := atab.getcol('NAME');
    ant[1:length(ant)]:='GBT';
    atab.putcol('NAME', ant);
    atab.flush();
    atab.close();
    
    otab := table(private.tab.getkeyword('OBSERVATION'), readonly=F, ack=F);
    ant := otab.getcol('TELESCOPE_NAME');
    ant[1:length(ant)]:='GBT';
    otab.putcol('TELESCOPE_NAME', ant);
    otab.flush();
    otab.close();
    
    ftab := table(private.tab.getkeyword('FEED'), readonly=F, ack=F);
    pt := ftab.getcol('POLARIZATION_TYPE');
    pt[1:length(pt)]:='Y';
    ftab.putcol('POLARIZATION_TYPE', pt);
    ftab.flush();
    ftab.close();
    
    ptab := table(private.tab.getkeyword('POLARIZATION'), readonly=F, ack=F);
    ct := ptab.getcol('CORR_TYPE');
    ct[,]:=12;
    ptab.putcol('CORR_TYPE', ct);
    ptab.flush();
    ptab.close();
    
    ftab := table(private.tab.getkeyword('SPECTRAL_WINDOW'), readonly=F, ack=F);
    f := ftab.getcol('CHAN_FREQ');
    f[,]:=freq;
    ftab.putcol('CHAN_FREQ', f);
    f := ftab.getcol('REF_FREQUENCY');
    f:=array(freq, length(f));
    ftab.putcol('REF_FREQUENCY', f);
    for (col in "RESOLUTION CHAN_WIDTH EFFECTIVE_BW") {
      r := ftab.getcol(col);
      r[r==r]:=1000000.0;
      ftab.putcol(col, r);
    }
    ftab.flush();
    ftab.close();
    
    
    note(private.msname,' has been fixed for filler errors');
  }

  public.done := function() {
    wider private;
    private.tab.flush();
    private.tab.close();
  }

  return ref public;
}

