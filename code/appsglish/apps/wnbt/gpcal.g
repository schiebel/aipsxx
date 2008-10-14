# gpcal.g: Try a (Miriad version) gpcal
# Copyright (C) 2000
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
# $Id: gpcal.g,v 19.2 2004/08/25 01:57:01 cvsmgr Exp $
#
pragma include once;

include 'quanta.g';
include 'note.g';
include 'imager.g';
include 'flagger.g';
include 'tables.g';
include 'calibrater.g';
#
##defaultservers.trace(T)
##defaultservers.suspend(T)
#
# This is a test for the ATCA gpcal type procedure.
# It is at the moment written to also compare the data with miriad,
# and hence the input MS is limited to a special one, called
# data.ms. It is available, a.o. places at:
# tarzan:/home/tarzan3/wbrouw/aips++/data/data.ms
#
# In the same directory the miriad output of the gain/bandpass is
# available as well as mf3.log
# Also the component model for the primary calibrator (m1934.cl)
# The arguments of the function gpcal() (after inclusion of gpcal.g):
#
#	name	what			default
#	----	----			-------
#	mms	MS			/home/tarzan3/wbrouw/aips++/
#					data/data.ms
#	mmdl	complist		/home/tarzan3/wbrouw/aips++/
#					data/m1934.cl
#	doreset	reset CORR_DATA		T
#	dofl	flag 5+5 channels	T
#	domdl	make MODEL_DATA		T
#	dogb	make gain+bandpass	T
#	dogb2	redo with applied	T
#
# The 'do' ones are present to suppress some steps, since they will
# not change anything.
# The steps are:
# - reset (in imager) the CORRECTED_DATA column
# - flag (directly in MS) the first and last 5 channels
# - make the MODEL_DATA based on the component list
# - get bandpass and gain
# - apply the bandpass and gain, and calculate it again
#
# Output is in log, and shows the results (the amplitude of the gains
# -- there could be a small difference with miriad: I take the
# abs(gain), while I am not sure about miriad, and also I think
# miriad flags one or two data points.
#
# The solution does not look too different. However, running it again,
# with setapply() of the previous step's results, will just give the
# same again, whether I do a 'correct()' or not after the setapply().
# I tried if in the same calibrater with .solve(); setapply();
# correct(); and also in a separate calibrater (as now). No difference
#
# There arew some more comments in the following text to explain why
# some things are done the way they are done
#
#
# The next are the data used (should be arguments in a function)
#
# 
# Do it
gpcal := function(mms='~/aips++/data/data.ms',
		  mmdl='~/aips++/data/m1934.cl',
		  doreset=T,
		  dofl=T,
		  domdl=T,
		  dogb=T,
		  dogb2=T) {
  global system;
#
# Actual stuff
#
  tmst := dq.unit('today');
  if (doreset) {
    note(paste('Working gpcal on', mms, 'at', dq.time(tmst, 8, 'ymd')));
###########################################################################
# First reset the calibrated data in measurement set
# This must be done in imager, calibrater does not accept no corrections
  note(paste('Resetting CORRECTED_DATA column'));
# Create imager
    mim := imager(mms);
#
# Clear corrected data column
    mim.correct(T, '10s');
#
# done
    mim.done(); 
    tm := dq.unit('today');
    note(paste('done at', dq.time(tm, 8, 'ymd'), 
	       '(', dq.time(dq.sub(tm, tmst), 8), ')'));
  };
###########################################################################
# Select data is necessary for ATNF calibration. Band selection does not
# seem to work (I tried select channel 23 start 5)
# Hence flagging of these channels
# Flagging is slow, and can be suppressed. 
# Flagging now bypassed, since selection did not seem to do
# what I wanted. So I replaced it by a manual set of the flags
  if (dofl && F) {
    note(paste('Flagging channels 1-5 and 29-33'));
# Flag data
    fl := flagger(mms);
    fl.setchan([1:5, 29:33]);
# Next one should not be, but ...
    fl.setpol([1:4]);
    fl.setantennas([1:6]);
    fl.setfeeds([1:2]);
# the next one is necessary to get any flagging done
    fl.setids(fieldid=[1,2], spectralwindowid=[1,2], arrayid=1);
    fl.filter(column='CORRECTED_DATA',
	      operation='range', comparison='Amplitude',
	      range = ['0Jy', '1e6Jy']);
    fl.done();
    tm := dq.unit('today');
    note(paste('done at', dq.time(tm, 8, 'ymd'), 
	       '(', dq.time(dq.sub(tm, tmst), 8), ')'));
  } else if (dofl) {
    note(paste('Manually flagging channels 1-5 and 29-33'));
# Flag data
    fl := table(mms, readonly=F);
    local ch := array(F, 4, 33);
    ch[,[1:5,29:33]] := T;
    for (i in 1:fl.nrows()) fl.putcell('FLAG', i, ch);
    fl.done();
    tm := dq.unit('today');
    note(paste('done at', dq.time(tm, 8, 'ymd'), 
	       '(', dq.time(dq.sub(tm, tmst), 8), ')'));
  };
###########################################################################
# Set the model data in the MS
  if (domdl) {
    note(paste('Setting MODEL_DATA'));
# Create imager
    mim := imager(mms);
#
# Set model data column for the primary calibrater at one frequency
    mim.setdata(mode='channel', nchan=23, start=6, spwid=1, fieldid=1)
    mim.setdata(spwid=1, fieldid=1);
    mim.ft(complst=mmdl, incremental=F);
#
# done
    mim.done(); 
    tm := dq.unit('today');
    note(paste('done at', dq.time(tm, 8, 'ymd'), 
	       '(', dq.time(dq.sub(tm, tmst), 8), ')'));
  };
###########################################################################
# Get the gain and bandpass corrections for the primary calibrator
  if (dogb) {
    note(paste('Getting gain and bandpass corrections'));
# Create calibrater
    mcl := calibrater(mms);
# select data to use (Note that the channels have no effect)
    mcl.setdata(mode='channel', nchan=23, start=6,
		msselect='FIELD_ID==1 && SPECTRAL_WINDOW_ID==1');
# select the gain and bandpass solvers and solve
    mcl.setsolve(type='G', t=300, table='gcal_1');
    mcl.setsolve(type='B', t=30000, table='bcal_1');
    mcl.solve();
# I tried to do apply here, but did not work
    mcl.done();
# Note that the result has all ones in the flagged channels. This is in my
# view better than all 0 as in the case of miriad.
    tm := dq.unit('today');
    note(paste('done at', dq.time(tm, 8, 'ymd'), 
	       '(', dq.time(dq.sub(tm, tmst), 8), ')'));
  };
###########################################################################
# Get the result (amplitude)
  g := array(0,2,6,3);
  tg := table('gcal_1');
  for (i in 1:3) {
    for (j in 1:2) {
      for (k in 1:6) {
	g[j,k,i]:=abs(tg.getcell('GAIN',(i-1)*6+k))[j,j,1];
      };
    };
  };
  tg.done();
# miriad
  g2:=[0.996,1.008,0.992,0.996,0.992,0.989,1.007,1,0.994,0.992,
      1.003,1,0.996,1.008,0.993,0.997,0.992,0.989,1.008,0.999,
      0.995,0.992,1.003,1,0.996,1.008,0.993,0.998,0.991,0.99,
      1.007,0.997,0.995,0.993,1.002,0.999];
  g2::shape := [2,6,3];
  system.print.precision := 3;
  note('Gain:');
  note (g);
# show gain/miriad
  note('gain/miriad: ');
  note(paste(g2/g));
  gb := array(0,2,6,33);
  tb := table('bcal_1');
  for (i in 1:33) {
    for (j in 1:2) {
      for (k in 1:6) {
	gb[j,k,i]:=abs(tb.getcell('GAIN',k))[j,j,1,i];
      };
    };
  };
  tb.done();
  gb2 := 
    [0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.83935,0.88175,0.94821,0.87647,0.84874,0.91846,
    0.81066,0.88212,0.89659,0.87579,0.88783,0.88437,
    0.84751,0.91834,0.96213,0.91581,0.94856,0.93142,
    0.89925,0.89917,0.90439,0.89939,0.91808,0.92599,
    0.87222,0.94020,0.98812,0.93821,0.94929,0.94900,
    0.92689,0.92665,0.93058,0.91701,0.94939,0.95189,
    0.90466,0.96423,1.01433,0.95850,0.93951,0.95627,
    0.95292,0.94602,0.96687,0.94209,0.97363,0.97238,
    0.92422,0.98591,1.02474,0.96809,0.97985,0.96419,
    1.00108,0.96316,0.98586,0.97085,0.98644,0.98481,
    0.94404,1.00368,1.03271,0.96863,0.99793,0.96812,
    0.99923,0.97155,0.99532,0.99196,1.00652,0.99099,
    0.94147,1.01120,1.01446,0.96891,1.08685,0.96245,
    1.05257,0.97086,0.97186,0.99774,1.00426,0.99448,
    0.95337,1.00825,1.01230,0.97221,1.08228,0.96102,
    1.03663,0.97349,0.96221,0.98925,1.00726,0.99381,
    0.95958,1.00662,1.00065,0.98329,1.07949,0.95490,
    1.06083,0.96972,0.94773,0.98250,0.98464,0.99258,
    0.98238,1.00649,0.99904,0.99502,1.01366,0.96862,
    1.03664,0.98067,0.95496,0.98374,0.97247,0.98964,
    1.00742,1.01748,0.99504,1.01148,0.97339,0.98103,
    1.02230,0.99315,0.97225,0.99725,0.97164,0.99476,
    1.02498,1.02940,0.99234,1.02573,0.99016,1.00661,
    1.04583,1.02552,0.98700,1.01210,0.98205,1.00300,
    1.05035,1.03752,1.00508,1.03549,0.98164,1.01843,
    1.03067,1.05006,1.01025,1.02380,1.00971,1.01350,
    1.06159,1.03771,1.00712,1.03613,1.00656,1.01653,
    1.03644,1.05514,1.02071,1.02505,1.02423,1.01716,
    1.07101,1.03298,1.00866,1.02862,0.99752,1.02167,
    1.01425,1.05131,1.02994,1.01812,1.03215,1.01593,
    1.07215,1.03647,0.99848,1.02465,0.99543,1.02622,
    1.01234,1.03549,1.03486,1.01832,1.02881,1.02112,
    1.08016,1.04022,0.99341,1.02302,0.97705,1.05469,
    0.99828,1.04027,1.04432,1.01990,1.03569,1.02866,
    1.08546,1.04264,0.99353,1.03146,0.98640,1.06488,
    1.00282,1.03597,1.04591,1.02727,1.04416,1.04069,
    1.08385,1.03365,0.99688,1.03792,1.01278,1.07539,
    1.01040,1.04647,1.05086,1.03354,1.04689,1.04474,
    1.07892,1.02018,1.00273,1.04606,1.02745,1.06637,
    1.00642,1.04387,1.06598,1.04557,1.04443,1.04467,
    1.06503,1.00231,1.00239,1.05081,1.04081,1.05507,
    1.01655,1.04131,1.07195,1.05952,1.03401,1.03894,
    1.05297,0.97581,1.00585,1.04517,1.01740,1.04487,
    0.99364,1.04429,1.07026,1.06926,1.02724,1.02638,
    1.02589,0.94656,0.99837,1.03451,1.03765,1.00945,
    0.99916,1.02433,1.04928,1.07138,1.01002,1.01324,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,
    0.00000,0.00000,0.00000,0.00000,0.00000,0.00000];
  gb2::shape := [2,6,33];
  note('bandpass numbers');
  note(paste(gb));
  note('miriad/bandpass numbers');
  note(paste(gb2/gb));
###########################################################################
# Get the gain and bandpass corrections again for the primary calibrator
  if (dogb2) {
    note(paste('Getting gain and bandpass corrections as test'));
# Create imager
    mcl := calibrater(mms);
# select data to use (Note that the channels have no effect)
    mcl.setdata(mode='channel', nchan=23, start=6,
		msselect='FIELD_ID==1 && SPECTRAL_WINDOW_ID==1');
# apply the old one (note we cannot select the spectral window)
    note('Applying calibration');
    mcl.setapply(table='gcal_1', select='FIELD_ID==1');
    mcl.setapply(table='bcal_1', select='FIELD_ID==1');
    mcl.correct();
    mcl.done();
    note('Redoing solve gain/bandpass');
# Create calibrater
    mcl := calibrater(mms);
# select data to use (Note that the channels have no effect)
    mcl.setdata(mode='channel', nchan=23, start=6,
		msselect='FIELD_ID==1 && SPECTRAL_WINDOW_ID==1');
# select the gain and bandpass solvers and solve again
    mcl.setsolve(type='G', t=300, table='gcal_2');
    mcl.setsolve(type='B', t=30000, table='bcal_2');
    mcl.solve();
    mcl.done();
    tm := dq.unit('today');
    note(paste('done at', dq.time(tm, 8, 'ymd'), 
	       '(', dq.time(dq.sub(tm, tmst), 8), ')'));
  };
  g := array(0,2,6,3);
  tg := table('gcal_2');
  for (i in 1:3) {
    for (j in 1:2) {
      for (k in 1:6) {
	g[j,k,i]:=abs(tg.getcell('GAIN',(i-1)*6+k))[j,j,1];
      };
    };
  };
  tg.done();
  note('Test gain solver: ');
  note(paste(g));
  gb := array(0,2,6,33);
  tb := table('bcal_2');
  for (i in 1:33) {
    for (j in 1:2) {
      for (k in 1:6) {
	gb[j,k,i]:=abs(tb.getcell('GAIN',k))[j,j,1,i];
      };
    };
  };
  tb.done()
  note('Test band pass solver: ');
  note(paste(gb));
###########################################################################
# Ready
  tm := dq.unit('today');
  note(paste('ready', dq.time(tm, 8, 'ymd'), 
	     '(', dq.time(dq.sub(tm, tmst), 8), ')'));
}










