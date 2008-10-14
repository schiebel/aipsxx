# imagerdemo.g: Demonstration of imager
#
#   Copyright (C) 1999
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
#   $Id: imagerdemo.g,v 19.1 2004/08/25 01:20:25 cvsmgr Exp $
#

include 'imager.g';
include 'demonstration.g';
include 'catalog.g';

const imagerdemo := function(size=256, cleanniter=1000, cleangain=0.1, cell='0.7arcsec',
			     doshift=T, doplot=F, dodisplay=T, cache=1024*1024) {
  
  global dowait:=T;
  
  ddemo.title('Demonstration of AIPS++ Synthesis Imaging');

  ddemo.caption('This demonstration illustrates the use of the AIPS++ synthesis module for basic self-calibration and imaging of an example VLA dataset, in this case observations of the source 3C273 taken at 8 GHz.');
  
  # Variables that define the demonstration
  testdir := 'imagerdemo';
  if(doshift) testdir:=spaste(testdir,'-shifted');
  
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); }
  
  # Make the directory
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw("rm fails!") }
  ok := shell(paste("mkdir", testdir));
  if (ok::status) { throw("mkdir", testdir, "fails!") }
  
  # Make the data
  ddemo.caption('The first step in the reduction process is to create an AIPS++ uv-data file by reading an external FITS file.', 'This is performed using the fitstoms \'constructor\' of the MeasurementSet tool ms. Note the use of a progress meter to display the time expected to complete the filling.');
  
  msfile:=spaste(testdir, '/','3C273XC1.ms');
  imagermaketestms(msfile);
  
  ddemo.caption('Next, create and initialize an imager tool, which has associated functions to perform basic imaging tasks.',
		'Functions include advise, setimage, setdata, image, weight, filter, uvrange, restore, clean, nnls, fitpsf, smooth, plotuv, plotvis, plotweights, sensitivity, and more.');
  animagerdemo := imager(msfile);
  if (is_fail(animagerdemo)) throw(animagerdemo::message);
  
  mcore:=dm.direction('b1950', '12h26m33.248000', '02d19m43.290000');
  if(doshift) {
    ddemo.caption('Set the image parameters, including the cell size and phase-center direction.',
		  ' To demonstrate the capabilities of the coordinate handling in AIPS++, this image will be in galactic coordinates.');
    ok:=animagerdemo.setimage(nx=size,ny=size,cellx=cell,celly=cell,
			      stokes='IV',phasecenter=mcore,doshift=T);
  }
  else {
    ddemo.caption('Set the image parameters, including the cell size and phase-center direction. This image will be in (RA,DEC) coordinates.');
    ok:=animagerdemo.setimage(nx=size,ny=size,cellx=cell,celly=cell,
			      stokes='IV',doshift=F);
  }
  if(is_fail(ok)) throw(ok::status);
  
# Set the cache size
  ok:=animagerdemo.setoptions(cache=cache);
  if(is_fail(ok)) throw(ok::status);
  
  ddemo.caption('Set the uv-data selection parameters, including the selected pointing centers, spectral-window identifiers and spectral channel range.');
  
# Set up the data selection parameters
  ok:=animagerdemo.setdata(mode='all', nchan=1, start=1, step=1, fieldid=1, spwid=1);
  if(is_fail(ok)) throw(ok::status);
  
  ddemo.caption('Print a summary of the uv-data file and the internal state of the imager tool to the logger.');
  
  
# Get a summary of the state of the object
  ok:=animagerdemo.summary();
  if(is_fail(ok)) throw(ok::status);
  
  ddemo.caption('Now, apply Briggs weighting to the uv-data.',
		'Briggs weighting provides a controllable compromise between the sensitivity of natural weighting and the resolution of uniform weighting');
# Weight the data
  ok:=animagerdemo.weight(type='briggs');
  if(is_fail(ok)) throw(ok::status);
  
  ddemo.caption('Apply a taper in the uv-plane, corresponding to an image plane Gaussian filter of 2 arcsec by 2 arcsec.');
  
  ok:=animagerdemo.filter(type="gaussian", bmaj="2arcsec", bmin="2arcsec");
  if(is_fail(ok)) throw(ok::status);
  
  ddemo.caption('Now, fit the major and minor axes of the main lobe of the point spread function defining the synthesized beam properties.');
  
  ok:=animagerdemo.fitpsf('', bmaj=bmaj, bmin=bmin, bpa=bpa);
  if(is_fail(ok)) throw(ok::status);
  
  note('## Fitted beam: ', bmaj, bmin, bpa);
  
  ddemo.caption('Transform the uv-data to create a dirty image.',
		'The transform is performed by convolutional gridding onto a regular grid, followed by a Fast Fourier transform, and image plane correction for the convolutional gridding function');
  
# Make a dirty image
  ok:=animagerdemo.image(type='observed', image=spaste(testdir, '/', '3C273XC1.dirty'));
  if(is_fail(ok)) throw(ok::status);

  ddemo.caption('Create an offset image box mask of size (90x85) pixels, near the center of the image, and covering the expected region of emission in the image plane.');
  
# Generate a box mask
  ok:=animagerdemo.make(image=spaste(testdir, '/', '3C273XC1.mask'));
  if(is_fail(ok)) throw(ok::status);
  ok:=animagerdemo.boxmask(spaste(testdir, '/', '3C273XC1.mask'),
			   blc=[95+size/2-128,65+size/2-128,1,1],
			   trc=[185+size/2-128,150+size/2-128,2,1]);
  if(is_fail(ok)) throw(ok::status);
  
  ddemo.caption('Deconvolve the dirty image using the Hogbom CLEAN algorithm.',
		'Other algorithms available are Clark CLEAN, Multi-Scale CLEAN, Non-Negative Least Squares, Maximum Entropy. The CLEAN algorithms can be run for multiple fields and for wide fields of view');
  
# Hogbom Clean
  ok:=animagerdemo.clean(algorithm='hogbom',
			 model=spaste(testdir, '/', '3C273XC1.clean'), 
			 mask=spaste(testdir, '/', '3C273XC1.mask'),
			 niter=cleanniter, gain=cleangain,
			 image=spaste(testdir, '/', '3C273XC1.restored'));
  
  if(is_fail(ok)) throw(ok::status);
  
# Restore
  ok:=animagerdemo.restore(model=spaste(testdir, '/', '3C273XC1.clean'), 
			   image=spaste(testdir, '/', '3C273XC1.restored'));
  
  if(is_fail(ok)) throw(ok::status);
  
  if(dodisplay) {
    ddemo.caption('Use the AIPS++ Display Library viewer tool to display the final image',
		  'The viewer has many capabilities for controlling the appearance and hardcopy characteristics of images.');
    dc.view(spaste(testdir, '/', '3C273XC1.restored'));
  }

# Smooth the restored image
  ddemo.caption('Smooth the restored image to make another mask.',
		'There are many methods for making masks for deconvolution.');
  ok:=animagerdemo.smooth(model=spaste(testdir, '/', '3C273XC1.restored'),
			  image=spaste(testdir, '/', '3C273XC1.restored.smoothed'),
			  bmaj="5arcsec", bmin="5arcsec");
  if(is_fail(ok)) throw(ok::status);
  
# Make a thresholded mask
  ddemo.caption('Create a mask in the image plane, defined by all points above 50 mJy/beam.');
  
  ok:=animagerdemo.mask(image=spaste(testdir, '/', '3C273XC1.restored.smoothed'),
			mask=spaste(testdir, '/', '3C273XC1.thresholdmask'),
			threshold='0.05Jy');
  if(is_fail(ok)) throw(ok::status);
  
  ddemo.caption('Use the imager tool to transform the current model i.e. the CLEAN image',
		'In addition to image-based models, discrete component models can be used');
  
  ok:=animagerdemo.ft(model=spaste(testdir,'/','3C273XC1.clean'));
  if(is_fail(ok)) throw(ok::status);

  animagerdemo.done();

# Construct a calibrater object, and self-calibrate
  ddemo.caption('Create a calibrater tool, acting on the same dataset.', 'Calibrater is used for solving for, and applying calibration information.');
  
  ci:= calibrater(spaste(testdir,'/','3C273XC1.ms'));

  ddemo.caption('Solve for the complex electronic gains, and for the phase of the atmospheric correction, over intervals of 300s and 30s respectively. Apply the solutions to the data.',
		'Other effects, such as bandpass calibration and polarization leakage, are addressed using the same tool. Note also that the rms fit before and after solution is reported.');
  
  ci.setsolve("G",300.0,F,spaste(testdir,'/','gcal_out'),F);
  ci.setsolve("T",30.0,T,spaste(testdir,'/','tcal_out'),F);
  ci.solve();
  ci.correct();
  ci.close();
  
  animagerdemo := imager(msfile);
  if (is_fail(animagerdemo)) throw(animagerdemo::message);
  
  mcore:=dm.direction('b1950', '12h26m33.248000', '02d19m43.290000');
  if(doshift) {
    ok:=animagerdemo.setimage(nx=size,ny=size,cellx=cell,celly=cell,
			      stokes='IV',phasecenter=mcore,doshift=T);
  }
  else {
    ok:=animagerdemo.setimage(nx=size,ny=size,cellx=cell,celly=cell,
			      stokes='IV',doshift=F);
  }
  if(is_fail(ok)) throw(ok::status);
  
# Set the cache size
  ok:=animagerdemo.setoptions(cache=cache);
  if(is_fail(ok)) throw(ok::status);
  
  ddemo.caption('Set the uv-data selection parameters, including the selected pointing centers, spectral-window identifiers and spectral channel range.');
  
# Set up the data selection parameters
  ok:=animagerdemo.setdata(mode='all', nchan=1, start=1, step=1, fieldid=1, spwid=1);
  if(is_fail(ok)) throw(ok::status);
  
# Plot visibilities
  if (doplot) {
    ddemo.caption('Plot the self-calibrated visibility data.',
		  'AIPS++ uses the Caltech PGPLOT library for plotting. Thus the familar PGPLOT commands are available from both C++ and Glish. In addition, the pgplotter tool, shown here, allows interactive editing of the plot commands.' );
    ok:=animagerdemo.plotvis();
    if(is_fail(ok)) throw(ok::status);
    
  }
  
  ddemo.caption('Deconvolve the self-calibrated data using the Hogbom CLEAN algorithm and the refined threshold mask.');
# Clean with thresholded mask
  ok:=animagerdemo.clean(algorithm='hogbom',
			 model=spaste(testdir, '/', '3C273XC1.clean.masked'), 
			 mask=spaste(testdir, '/', '3C273XC1.thresholdmask'),
			 niter=cleanniter, gain=cleangain,
			 image=spaste(testdir, '/', '3C273XC1.masked.restored'));
  if(is_fail(ok)) throw(ok::status);
  
# Restore
  ok:=animagerdemo.restore(model=spaste(testdir, '/', '3C273XC1.clean.masked'), 
			   image=spaste(testdir, '/', '3C273XC1.masked.restored'));
  
  if(is_fail(ok)) throw(ok::status);
  
  if(dodisplay) {
    dc.view(spaste(testdir, '/', '3C273XC1.masked.restored'));
  }

  ddemo.caption('Finally we close the imager tool.');
  
  ok := animagerdemo.close(); 
  if (!ok) {
    throw('Unexpected close error (1)')
      }
  ok := animagerdemo.done(); 
  if (!ok) {
    throw('Unexpected done error (1)');
  }
  ddemo.caption('That\'s all!');
  
  return T;
}


