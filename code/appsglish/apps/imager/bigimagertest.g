# bigimagertest.g: Validate processing of large images
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#
pragma include once;

include 'misc.g'
include 'sysinfo.g'
include 'logger.g'
include 'table.g'
include 'getrc.g'

const bigimagertest := function(size=1024, nchan=1, imagertask='imager',
				numthreads=1, cache=16777216, forcenew=F,
				cleanniter=5000)
{
# Private functions.
#------------------------------------------------------------------------
    self := [=];

    # Private function to define informational note.
    const self.info := function(...) { 
        defaultlogger.note(spaste(...), origin='bigimagertest()'); 
    }

    # Private function to define error note.
    const self.error := function(...) {
        throw(spaste(...), origin='bigimagertest()');
    }

    # Private function to clean up directory.
    const self.cleanup := function() {
    	self.info('## Cleaning up directory ', output_dir);
	mysh := sh();
	if (dms.fileexists(output_dir, '-d')) {
	    for (output_image in all_output_images) {
		ok := mysh.command(spaste('rm -fr ', output_image));
		if (ok.status) self.error('Removal of ', output_image, 
					  'fails!');
	    }
	} else {
	    ok := mysh.command(spaste('mkdir ', output_dir));
	    if (ok.status) {
		self.error('mkdir ', output_dir, 'fails!');
		fail;
	    }
	}
	mysh.done();
    }

    # Private function to make the test images.
    const self.makeimages := function() {
	wider self;

	# Processing parameters, these should not be changed without
	# regenerating the standard images.
	tile := 16;
	padding := 1.2;
	fieldid := 1;
	spwid := 1;
	stokes := 'I';
	mode := 'channel';
	bchan := 1;
	step := 1;
	cleangain := 0.1;
	cleanthreshold := '1mJy';
	algorithm := 'clark';
	cellsize := '1.5arcsec';
	shiftx := '-600arcsec';
	shifty := '-1140arcsec';

	# Input MS and UVFITS file names.
	m33ms_file := 'M33_8ch.ms';
	m33ms := spaste(output_dir, '/', m33ms_file);
	m33uvfits_file := 'M33_8CH.UVFITS';
	m33uvfits := spaste(archive_dir, '/', m33uvfits_file);

	# If archive directory is writable (i.e., script is being run
	# by aips2mgr) the MeasurementSet in the archive will be used,
	# otherwise we will use the one in the output directory.
	include 'ms.g';
	if (dms.fileexists(archive_dir, '-w')) {
	    m33ms := spaste(archive_dir, '/', m33ms_file);
	}

	# If the input MeasurementSet does not exist, recreate it from
	# UVFITS file in the archive.
	if (!tableexists(m33ms)) {
	    self.info('## Input MeasurementSet does not exist, recreating it from UVFITS file ', 
		      m33uvfits);
	    newms := fitstoms(m33ms, m33uvfits);
	    if (is_fail(newms)) {
		self.error(newms::message);
		newms.close(); newms.done();
		fail;
	    }
	    newms.close(); newms.done();
	}

	# Start timing.
	self.info('## Start timing');
	start_time := time();
	self.info('## Running bigimagertest using ', size, ' by ', size, 
		  ' pixels by ', nchan, ' channel(s)');
	
	# Create imager object from MeasurementSet.
	self.info('## Creating imager object from MeasurementSet ', m33ms);
	if (imagertask == 'pimager') {
	    include 'pimager.g';
	    global abigimagertest := pimager(filename=m33ms, 
					     numprocs=numthreads);
	} else {
	    include 'imager.g';
	    global abigimagertest := imager(filename=m33ms);
	}
	if (is_fail(abigimagertest)) {
	    self.error(abigimagertest::message);
	    fail;
	}

	# Set up the image parameters.
	self.info('## Set up the image parameters');
	ok := abigimagertest.setimage(nx=size, ny=size, cellx=cellsize,
				      celly=cellsize, stokes=stokes,
				      mode=mode, nchan=nchan, 
				      start=bchan, step=step, shiftx=shiftx,  
				      shifty=shifty);
	if (is_fail(ok)) {self.error(ok::status); fail;}

	# Turn on primary beam (a.k.a. voltage pattern [vp]) correction.
	self.info('## Turn on primary beam correction');
	ok := abigimagertest.setvp(dovp=T);
	if (is_fail(ok)) {self.error(ok::message); fail;}

	# Set up cache size.
	self.info('## Set up the cache size to be ', cache, ' pixels');
	ok := abigimagertest.setoptions(cache=cache, padding=padding, 
					tile=tile);
	if(is_fail(ok)) {self.error(ok::message); fail;}

	# Set up the data selection parameters.
	self.info('## Set up the data selection parameters');
	ok := abigimagertest.setdata(mode=mode, nchan=nchan, start=bchan,
				     step=step, fieldid=fieldid, spwid=spwid);
	if(is_fail(ok)) {self.error(ok::message); fail;}

	# Get a summary of the state of the object.
	self.info('## Get a summary of the state of the object');
	ok := abigimagertest.summary();
	if(is_fail(ok)) {self.error(ok::message); fail;}

	# Make an empty model (clean) image.
	self.info('## Make an empty model (clean) image');
	ok := abigimagertest.make(image=clean);
	if(is_fail(ok)) {self.error(ok::message); fail;}

	# Weight the data.
	self.info('## Weight the data');
	ok := abigimagertest.weight(type='briggs', rmode='norm', robust=0.5);
	if(is_fail(ok)) {self.error(ok::message); fail;}

	# Calculate the psf.
	self.info('## Calculate the psf');
	ok := abigimagertest.image(type='psf', image=psf);
	if(is_fail(ok)) {self.error(ok::message); fail;}

	# Fit the psf.
	self.info('## Fit the psf');
	bmaj:=F; bmin:=F; bpa:=F;
	ok := abigimagertest.fitpsf(psf, bmaj=bmaj, bmin=bmin, bpa=bpa,
				    async=F); 
	if(is_fail(ok)) {self.error(ok::message); fail;}
	self.info('## Using beam: ', bmaj, ', ', bmin, ', ', bpa);

	self.info ('## Starting deconvolution (', algorithm, ')');
	ok := abigimagertest.clean(algorithm=algorithm, niter=cleanniter,
				   gain=cleangain, threshold=cleanthreshold,
				   model=clean, image=restored,
				   residual=residual, async=F);
	if (is_fail(ok)) {self.error(ok::message); fail;}

	# End timing and print elapsed time.
	end_time := time();
	elapse_time := as_integer(end_time-start_time);
	self.info('## Finished bigimagertest in run time = ', elapse_time, 
		  ' seconds, using ', size, ' by ', size, ' pixels by ', 
		  nchan, ' channel(s)');

	# Close the imager object.
	self.info('## Close the imager object');
	abigimagertest.close(); abigimagertest.done();
    } # self.makeimages()

# Public functions
#------------------------------------------------------------------------
    public := [=];

    # Public function to compare a test image with the standard image in the
    # archive.
    const public.compare := function(comp_image=restored_file, logresult=F)
    {
	# Define information note function.
	const self.info := function(...) { 
	    defaultlogger.note(spaste(...), origin='bigimagertest.compare()'); 
	}
	# Define error note function.
	const self.error := function(...) {
	    throw(spaste(...), origin='bigimagertest.compare()');
	}

	# Check to make sure the shape is in the allowed range (i.e., the
	# image can be compared to existing standard images in archive).
	if (!can_compare) {
	    self.error('Image shape is not valid for comparison');
	    fail;
	}

	# Use image tool to make a difference image between the test and
	# standard images.
	include 'image.g';
	global test_image := image(spaste(output_dir, '/', comp_image));
	if (is_fail(test_image)) {self.error(test_image::message); fail;}
	global std_image := image(spaste(archive_dir, '/', comp_image));
	if (is_fail(std_image)) {self.error(std_image::message); fail;}

	# One last check to insure that the images have the same shape.
	if (test_image.shape() != std_image.shape()) {
	    std_image.close(); std_image.done(); 
	    test_image.close(); test_image.done();
	    self.error('Test and comparison images are not the same shape!');
	    fail;
	}

	# Make the difference image.
	diff_image := imagecalc('diff_image', '$std_image-$test_image');
	if (is_fail(diff_image)) {self.error(diff_image::message); fail;}

	# Obtain the statistics for the difference image; max_diff is the
	# maximum of the absolute value of the minimum and maximum difference.
	ok := diff_image.statistics(statsout=diffstats);
	if (is_fail(ok)) {self.error(ok::message); fail;}
	max_diff := max(abs(diffstats.min), abs(diffstats.max));

	# Close image objects and remove temporary difference image.
	std_image.close(); std_image.done(); 
	test_image.close(); test_image.done();
	diff_image.close(); diff_image.done();
	mysh := sh();
	ok := mysh.command(spaste('rm -fr diff_image'));
	if (ok.status) self.error('Removal of difference image fails!');

	# If results are being logged, write in comment line in aipsrc file.
	if (logresult) {
	    # Prepare to write output on comparison into aipsrc file.  If the
	    # $AIPSARCH/aipsrc file is writable (i.e., script is being run
	    # by aips2mgr), output will go there, otherwise it will go into
	    # the aipsrc file in the current directory.
	    arcfile := spaste(sysinfo().root(), '/', sysinfo().arch(), '/', 
			      sysinfo().site(), '/aipsrc');
	    if (!dms.fileexists(arcfile, '-w')) {
		arcfile := 'aipsrc';
		if (!dms.fileexists(arcfile)) {
		    ok := mysh.command(spaste('touch ', arcfile));
		    if (ok.status) self.error('Cannot create output aipsrc in current working directory.');
		}
	    }

	    date := dq.time(dq.quantity('today'),form="dmy");
	    ok := mysh.command(spaste('echo \"# Result of bigimagertest (', outname, ') on ', date, '\" | cat >> ', arcfile));
	    if (ok.status) self.error('Problem writing to output aipsrc file.');
	}

	# Write note into log on status of comparison.  Return Bool showing
	# success or failure.
	if (max_diff) {
	    self.info('## Comparison test FAILED!  Maximum difference is ', 
		      max_diff);
	    if (logresult) {
		ok :=mysh.command(spaste('echo \"system.parallel.bigimagertest.result: false\" | cat >> ', arcfile));
	    }
	    mysh.done();
	    return F;
	} else {
	    self.info('## Comparison test succeeded!');
	    if (logresult) {
		ok := mysh.command(spaste('echo \"system.parallel.bigimagertest.result: true\" | cat >> ', arcfile));
	    }
	    mysh.done();
	    return T;
	}
    } # bigimagertest.compare()

    # Check that size and nchans are within allowed ranges.
    global can_compare := T;
    allowed_sizes := [1024, 2048, 4096, 8192];
    if (!sum(size == allowed_sizes)) {
	can_compare := F;
	self.error('Size ', size, ' not within allowed range ', allowed_sizes);
    }
    allowed_nchans := [1, 2, 4, 8];
    if (!sum(nchan == allowed_nchans)) {
	can_compare := F;
	self.error('Number of channels ', nchan, ' not within allowed range ',
		   allowed_nchans);
    }

    # Define archive and output directories.  If the
    # system.parallel.bigimagertest.dir record is defined in the aipsrc
    # file use it, otherwise use $AIPSROOT/bigdata.
    global archive_dir;
    ok := getrc.find(archive_dir, "system.parallel.bigimagertest.dir");
    if(!ok) {
	archive_dir := spaste(sysinfo().root(), '/bigdata');
    }
    global output_dir := 'bigimagertest';

    # Set up file names based on image size and nchan.
    global outname := spaste('M33_', size, 'x', size, 'x', nchan);
    global psf_file := spaste(outname, '.psf');
    global psf := spaste(output_dir, '/', psf_file);
    global clean_file := spaste(outname, '.clean');
    global clean := spaste(output_dir, '/', clean_file);
    global residual_file := spaste(outname, '.residual');
    global residual := spaste(output_dir, '/', residual_file);
    global restored_file := spaste(outname, '.restored');
    global restored := spaste(output_dir, '/', restored_file);

    # Make a list of all necessary images.
    global all_output_images := [psf, clean, residual, restored];
    all_images_complete := F;

    # If user did not forcenew=T, check to see if all necessary images exist
    # in output directory.  This would be the case if the files were created
    # at one time and compared later.
    if (!forcenew) {
	all_images_complete := T;
	for (output_image in all_output_images) {
	    if (!tableexists(output_image)) all_images_complete := F;
	}
    }

    # If all images exist and forcenew=F, then do nothing, otherwise remove
    # what files do exist and recreate them.
    if (all_images_complete) {
	self.info('## All images exist in ', output_dir, 
		  ' directory, none will be created');
    } else {
	self.cleanup();
	ok := self.makeimages();
	if (is_fail(ok)) {self.error('Creation of new images fails!'); fail;}
    }
    
    return ref public;
} # bigimagertest
