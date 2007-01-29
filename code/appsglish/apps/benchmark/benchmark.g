# benchmark.g: standard AIPS++ performance benchmarks
# Copyright (C) 1999,2000,2001,2002,2003
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
# $Id: benchmark.g,v 19.1 2004/08/25 01:04:03 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'imager.g';
include 'calibrater.g'
include 'ms.g';
include 'servers.g';
include 'aipsrc.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';
include 'misc.g';
include 'os.g';
include 'stopwatch.g';
include 'quanta.g';

#
# This script executes the standard AIPS++ performance
# bechmarks, as defined in the User Reference manual
# entry for the benchmark tool.
#
#
# Define a benchmark instance
#
const _define_benchmark := function(datarepos=unset, ref agent, id) {
#
    private := [=];
    public := [=];
#
#------------------------------------------------------------------------
# Private data and functions
#------------------------------------------------------------------------
#
    # Tasking parameters
    private.agent:= agent;
    private.id:= id;

    # Path of the data repository
    private.datarepos := datarepos;
    
    # Results summary record
    private.printcodes:= [=];
    
    # Encapsulate the setting up of the imaging machine
    const public.setupimager := function(msfile=unset, imsize=unset, 
					 stokes=unset,spwid=unset,
					 cellsize=unset, weight=unset, 
					 tile=unset, cache=4194304,
					 mode='mfs', doshift=F, 
					 nchan=1,start=1,step=1,chavg=1,
					 fieldid=1,facets=1)
    {				
	wider private, public;	# 
	
	# Create an imager tool
	imagingtool := imager(msfile);
	
	# Set image properties
	
	chavg:=abs(chavg);
	nchan:=abs(nchan);
	start:=abs(start);
	step:=abs(step);
	if (mode=='mfs')
	{
	    nchanafteravg := as_integer(nchan/chavg);
	    if (nchanafteravg < 1) 
		{
		    note('NChan after channel averaging < 1.  Resetting it to 1', priority='WARN');
		    nchanafteravg:=1;
		}
	    else note('NChan after channel averaging =', nchanafteravg,priority='NORMAL');
	}

	imagingtool.setimage(nx=imsize,     ny=imsize,       cellx=cellsize, celly=cellsize,
			     stokes=stokes, doshift=doshift, mode=mode,      
			     nchan=nchanafteravg,   start=start,     step=chavg,
			     spwid=spwid,   fieldid=fieldid, facets=facets);
	
	
	# Select the uv-data
	imagingtool.setdata(mode='channel', nchan=nchan, start=start, step=step, 
			    spwid=spwid,   fieldid=fieldid, msselect='', async=F);
	
	imagingtool.setoptions(tile=tile,cache=cache);
	
	# Weight using natural weighting
	imagingtool.weight(type=weight, async=F);
	
	return imagingtool;
    };
    
    const public.setupcalibrater := function(msfile=unset, start=unset, step=unset, nchan=unset, compress=unset)
    {
	wider private, public;
	
	calibtool := calibrater(msfile, compress=compress);
	note(spaste('Channel selection: ',nchan,' ',start,' ',step));
	calibtool.setdata(mode='channel', nchan=nchan, start=start, step=step);

	return calibtool;
    }

    # Create a stopwatch tool
    private.stopwatch := stopwatch();
    
    const private.subcodename := function(telescope=unset,
					  datadescriptor='',
					  compressionmode='',
					  datasize='',
					  spwid=0,
					  jones='',
					  nant=0,
					  nsolint=0,
                                          interval=0,
					  snr=0,
					  stokes='',
					  weight='',
					  imsize=0,
					  nchan=0,
					  niter=0,
                                          rowblock=0,
					  tile=-1,
					  cache=-1)
    {
	wider private, public;
	# VLA-C-U125K-SP1-I-UN-512-1K      
	subcode := '';
	if (strlen(telescope) > 0)       subcode := spaste(subcode, telescope);

	if (strlen(jones) > 0)           subcode := spaste(subcode, '-', jones); # Calibrater related
	if (nant > 0)                    subcode := spaste(subcode, '-', nant);	# Calibrater related
	if (nsolint > 0)                 subcode := spaste(subcode, '-', nsolint); # Calibrater related
	if (strlen(datadescriptor) > 0)  subcode := spaste(subcode, '-', datadescriptor);
	if (strlen(compressionmode) > 0) subcode := spaste(subcode,'-', compressionmode);
	if (strlen(datasize) > 0)        subcode := spaste(subcode, datasize);
	if (spwid > 0)                   subcode := spaste(subcode, '-', 'SP',spwid);
	if (strlen(stokes) > 0)          subcode := spaste(subcode, '-', stokes);
	if (strlen(weight) > 0) 
	    {
		if (weight == 'uniform') t:='UN'; else t:='NA';
		subcode := spaste(subcode,'-', t);
	    }
	if (imsize > 0) subcode := spaste(subcode,'-', imsize);
	if (nchan > 0)  subcode := spaste(subcode, '-', 'C',nchan);
	if (snr > 0)    subcode := spaste(subcode, '-', snr); # Calibrater related
	if (niter > 0)  subcode := spaste(subcode, '-', niter);
        if (interval > 0)                subcode := spaste(subcode, '-', interval, 'S'); # Time interval in seconds
        if (rowblock > 0) subcode := spaste(subcode, '-', rowblock, 'R'); # Row blocking
	if (tile > 0)   subcode := spaste(subcode, '-', tile);
	if (cache > 0)  {t:=cache/(1024*1024);subcode := spaste(subcode, '-', t,'M');}
	return subcode;
    }
    
    const private.msname := function(code=unset, fitsin=unset, compress=F)
    {
	# Generate the default full MS name for a given benchmark test
	#
	# Input:
	# code            string     Benchmark code (e.g. 'A2')
	# fitsin          string     Name of the UVFITS test data file
	# compress        boolean    True if data compression required
	#
	wider private, public;
	
	# Generate the full MS name
	if (compress) {
	    outname := spaste(code, '/', fitsin, '-c.ms');
	} else {
	    outname := spaste(code, '/', fitsin, '.ms');
	};
	return outname;
    };
    
    const private.modelname := function(code=unset, subcode=unset)
    {
	# Generate the default model image name for a given 
	# benchmark code and subcode
	#
	# Input:
	# code            string     Benchmark code (e.g. 'CC-SF')
	# subcode         string     Subcode (e.g. 'VLA-C-U125K-SP1-I-UN-512-1K')
	#
	wider private, public;
	
	# Generate the full model name
	outname := spaste(code, '/', subcode, '.model');
	return outname;
    };
    
    const private.restoredname := function(code=unset, subcode=unset)
    {
	# Generate the default restored image name for a given 
	# benchmark code and subcode
	#
	# Input:
	# code            string     Benchmark code (e.g. 'CC-SF')
	# subcode         string     Subcode (e.g. 'VLA-C-U125K-SP1-I-UN-512-1K')
	#
	wider private, public;
	
	# Generate the full model name
	outname := spaste(code, '/', subcode, '.restored');
	return outname;
    };
    
    const private.residualname := function(code=unset, subcode=unset)
    {
	# Generate the default residual image name for a given 
	# benchmark code and subcode
	#
	# Input:
	# code            string     Benchmark code (e.g. 'CC-SF')
	# subcode         string     Subcode (e.g. 'VLA-C-U125K-SP1-I-UN-512-1K')
	#
	wider private, public;
	
	# Generate the full model name
	outname := spaste(code, '/', subcode, '.residual');
	return outname;
    };
    
    const private.report := function(code=unset)
    {
	# Report the timing result for the current benchmark
	#
	# Input:
	# code            string     Benchmark code (e.g. 'A2')
	#
	wider private, public;
	
	# Read the stopwatch
	numstr := sprintf('%15.2f', private.stopwatch.value());
	printstr := spaste('Benchmark ', code, ': ', numstr, ' s ');
	private.printcodes[code] := printstr;
	note(printstr);
    };
    
    const private.reportall := function()
    {
	#
	# Report all benchmark results recorded
	#
	wider private, public;
	
	# Loop over results record
	for (result in private.printcodes) {
	    note(result);
	};
    };
    
    const private.loaduvfits := function(code=unset, fitsin=unset, compress=F)
    {
	# Convert a UVFITS file to an AIPS++ MeasurementSet (MS)
	#
	# Input:
	# code            string     Benchmark code (e.g. 'A2')
	# fitsin          string     Name of the UVFITS test data file
	# compress        boolean    True if data compression required
	#
	wider private, public;
	
	# Create an empty test sub-directory for this benchmark code
	ok := dos.remove(code, recursive=T, mustexist=F, follow=F);
	ok := dos.mkdir(code);
	
	# Convert the UVFITS file to an MS
	outname := private.msname(code, fitsin, compress);
	m := fitstoms(fitsfile=spaste(private.datarepos,'/',fitsin), msfile=outname);
	m.done();
	
	# Initialize the scratch columns (a one-time operation)
	imagr := imager(outname, compress);
	imagr.done();
	
	return T;
    };
    
    const private.loadalmauvfits := function(code=unset, fitsin=unset, compress=F)
    {
	# Convert an ALMA TI UVFITS file to an AIPS++ MeasurementSet (MS)
	#
	# Input:
	# code            string     Benchmark code (e.g. 'A2')
	# fitsin          string     Name of the UVFITS test data file
	# compress        boolean    True if data compression required
	#
	wider private, public;
	include 'almati2ms.g';
	
	# Create an empty test sub-directory for this benchmark code
	ok := dos.remove(code, recursive=T, mustexist=F, follow=F);
	ok := dos.mkdir(code);
	
	# Convert the UVFITS file to an MS
	outname := private.msname(code, fitsin, compress);
	m := almatifiller(msfile=outname,fitsdir='/aips++/data/alma/test',
				pattern=fitsin, append=F, compress=compress,
				obsmode="CORR", chanzero="TIME_AVG");
	
	# Initialize the scratch columns (a one-time operation)
	imagr := imager(outname, compress);
	imagr.done();
	
	return T;
    };
    
    const private.bimamsmake := function(code=unset, msin=unset, compress=F)
    {
	# BIMA data:
	# Copy aips++ measurement set (MS) from bima data repository to
	# 'code' directory (maintains uniformity with other benchmarks.
	#
	# Input:
	# code            string     Benchmark code (e.g. 'A2')
	# msin            string     Name of the BIMA aips++ ms
	#
	wider private, public;
	
	# Create an empty test sub-directory for this benchmark code
	ok := dos.remove(code, recursive=T, mustexist=F, follow=F);
	ok := dos.mkdir(code);
	
	# Copy aips++ measurement set (MS) from bima data repository 
	outname := private.msname(code, msin, F);
#	ok := dos.copy('sgrb2n.caldata',outname);
	ok := dos.copy(spaste(private.datarepos,'/sgrb2n.caldata'),outname);	
	# Initialize the scratch columns (a one-time operation)
	imagr := imager(outname, compress);
	imagr.done();
	
	return T;
    };
    
    const private.ccsfkernel := function(code=unset,      subcode=unset,  msfile=unset,
					 spwid=unset,     stokes=unset,   weight=unset,  
					 imsize=unset,    niter=unset,    cellxy=unset,  
					 mode=unset,      nchan=unset,    start=unset,   
					 step=unset,      chavg=uset,     fieldid=unset,  
					 facets=unset,    threshold=unset,tile=unset,
					 cache=unset)
    {
	# Kernel for benchmark code 'CC-SF'
	#
	# Input:
	# code            string       Benchmark code (e.g. 'CC-SF')
	# subcode         string       Benchmark subcode (e.g. 'VLA4U-I-UN-512-1k')
	# msfile          string       MS name
	# spwid           vec_integer  Selected spectral windows
	# weight          string       Gridding weight (uniform or natural)
	# stokes          string       Image polarization coordinates
	# nxy             integer      Image size in pixels
	# cellxy          quantity     Cell size (e.g. '5arcsec')
	# niter           integer      Number of CLEAN components
	#
	wider private, public;
	
	# Reset the stopwatch
	private.stopwatch.reset(quiet=T);
	private.stopwatch.start(quiet=T);
	
	# Create an imager tool
	private.imager := public.setupimager(msfile=msfile, imsize=imsize,   stokes=stokes,
					     spwid=spwid,   cellsize=cellxy, weight=weight,  
					     mode=mode,     doshift=F,       tile=tile,
					     cache=cache,   nchan=nchan,     start=start, 
					     step=step,     chavg=chavg,     fieldid=fieldid, 
					     facets=facets);
	
	# Make an empty model image
	modelname := private.modelname(code, subcode);
	
	private.imager.make(modelname);
	
	# Clark CLEAN deconvolution
	restoredname := private.restoredname(code, subcode);
	residualname := private.residualname(code, subcode);

	private.imager.clean(algorithm='clark',     niter=niter,
			     gain=0.1,              threshold=threshold, 
			     displayprogress=F,     model=modelname, 
			     fixed=F,               complist='',
			     mask='',               image=restoredname, 
			     residual=residualname, async=F);
	
	# Close imager tool
	private.imager.done();
	
	# Show stopwatch time
	private.stopwatch.stop(quiet=T);
	
	return T;
    };
    
    const private.calibkernel := function(code=unset,  subcode=unset, msfile=unset,
					  jones=unset, solint=unset,  preinteg=unset, 
					  start=unset, step=unset,    nchan=unset,
					  calibrate='', tablename='')

	
    {
	wider private, public;



	private.stopwatch.reset(quiet=T);

	# Make the calibrater tool
	private.calibrater:= public.setupcalibrater(msfile=msfile, start=start, 
						    step=step, nchan=nchan, compress=F);
	
	if (tablename=='') tablename:='calib.tab';
	caltable:=spaste(jones,tablename);
	if (calibrate!='')
	{
	    GTab := spaste(calibrate,tablename);
	    if (tableexists(GTab))
		private.calibrater.setapply(type=calibrate, table=GTab);
	    else
		fail(spaste('Calibration table ',GTab, ' not found'));
	}
	private.calibrater.setsolve(type=jones, t=solint, preavg=preinteg, 
				    phaseonly=F, refant=-1, table=caltable, append=F);

	private.stopwatch.start(quiet=T);
	private.calibrater.solve();
	private.stopwatch.stop(quiet=T);
	
	private.calibrater.done();


	return T;
    }

    private.visiterkernelRec:= [_method="visiterkernel", 
                                _sequence=private.id._sequence];
    const private.visiterkernel := function(code=unset, subcode=unset, 
                                            msfile=unset, interval=0, 
                                            rowblock=0, cache=0)
    {
	# Kernel for benchmark code 'VISITER'
	#
	# Input:
	# code            string       Benchmark code (e.g. 'VISITER')
	# subcode         string       Benchmark subcode 
        #                              (e.g. 'VLA-C-U125K-30S-R128-24M')
	# msfile          string       MS name
        # interval        double       Time interval for iteration (seconds)
        # rowblock        integer      Number of rows to block when iterating
        #                              through a time interval
	# cache           integer      Table system cache size (in bytes)
	#
	wider private, public;

        # Check the validity of the input parameters
        if (is_unset(msfile)) fail('No valid MS file name specified');

        private.visiterkernelRec.msfile := msfile;
        private.visiterkernelRec.interval := interval;
        private.visiterkernelRec.rowblock := rowblock;
        private.visiterkernelRec.cache := cache;

        return defaultservers.run(private.agent, private.visiterkernelRec);
    };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
    const public.all := function()
    {
	#
	# Run all defined benchmarks
	#
	wider private, public;
	
	# Clark Clean, single-field
	public.ccsf();
	
	# Import vis. data from FITS file (FF==FITS Filler)
	public.fuvrd();

	# Visibility data iteration
        public.visiter();
	
	# Calibrator (GJones and DJones with 100 solution intervals)
        public.calvla();

	# Single Dish benchmarks - don't do by default (yet)
	#public.sdall();

	return T;
    };
    
    const public.ccsf := function()
    {
	#
	# Run all CC-SF benchmarks (Clark Clean, single-field)
	#
	wider private, public;
	
	# VLA, 125k vis, uncompressed, continuum data
	public.ccsfvlacu125k();
	
	# VLA, 1M vis, uncompressed, continuum data
	public.ccsfvlacu1m();
	
	# BIMA, 134M vis, uncompressed, continuum data
	public.ccsfbi4nL();
	
	return T;
    };
    
    const public.fuvrd := function()
    {
	#
	# Run all FUVRD benchmarks (FITS UV Read)
	#
	wider private, public;
	
	# VLA, 125k vis, uncompressed, continuum data
	public.fuvrdvlacu125k();
	
	# VLA, 1M vis, uncompressed, continuum data
	public.fuvrdvlacu1m();
	
	# VLA, 125K vis, uncompressed, line data
	public.fuvrdvlalu125k();
	
	return T;
    };

    const public.almafuvrd := function()
    {
	#
	# Run all ALMATI filler FUVRD benchmarks (FITS UV Read)
	#
	wider private, public;
	
	# Fills IRAM data presented in ALMA TI Fits format
	public.almatifuvrd();
	
	return T;
    };

    const public.visiter := function()
    {
        #
        # Run all VISITER benchmarks (visibility data iteration)
        #
        wider private, public;

        # VLA, 125k vis, uncompressed, continuum data
        public.visitervlacu125k();

        return T;
    };

    const public.calvla := function()
    {
        #
        # Run all CALVLA benchmarks (calibrator)
        #
        wider private, public;

        # Run calibrator benchmarks for VLA (27 antennas)
        # Solve for G and D with 100 solution intervals
        public.calvlau27s10();

        return T;
    };
    
    const public.calvlau27s10 := function(datafile='calvlau27s10.fits', 
                                          myms='', jones=["G","D"],
					  nsolint=[100],
					  nchan=1, start=1, step=1,
					  tablename='')
    {
	# Run benchmark CAL-VLA-U27 (Calibrater, VLA, Uncompressed for 27 antenna)
	#
	wider private;
	
	# Benchmark kernal code
	code     := 'CAL';
	
	# Parameters frozen for this benchmark
	compressionmode := 'U';
	datadescriptor  := '';
	telescope       := 'VLA';
	nant            := 27;
	snr             := 10;
	
	# Create the uncompressed test MS for this benchmark 
	if (myms=='')
	    {
		private.loaduvfits(code, fitsin=datafile, compress=F);
		ums := private.msname(code, datafile, compress=F);
	    }
	else  ums:=myms;


	myms:=ms(ums);
	nrows:=myms.nrow();
	myms.selectinit();
	myms.selectpolarization("I");
	myms.selectchannel(nchan=1,start=1,width=1,inc=1);
	x:=myms.getdata("model_data",ifraxis=T,average=T); 
	nbaselines:=x.model_data::shape[3];
	myms.done();
	mytab:=table(ums);
	integration:=mytab.getcell("INTERVAL",1);
	mytab.done();

	private.stopwatch.reset(quiet=T);
	private.stopwatch.start(quiet=T);
	#==================================================================
	# BENCHMARK: CAL-VLA-U27-{G,D,B}-{10,100,1000}-C{1,64}-{5,10,100}
	#==================================================================
	#            ^__^ ^____^ ^______________________________________^        
	#         Kernel  Frozen        Set via the argument list
	#
	# Kernel code: Calibrater
	# Data params (frozen for this method): VLA, 27-antennas, uncompressed
	# jones:  From argument jones (default: ["G","D"])
	# nchan:  From argument nchans (default: 1)
	# start:  From argument start (default: 1)
	# step:   From argument step (default: 1)

	for(ch in nchan)
	    for (nsol in nsolint)
		for (jn in jones)
		{
		    solutioninterval := nrows*integration/(nbaselines*nsol);
		    if (solutioninterval < integration) solutioninterval := integration;
		    note('Using solution interval = ',solutioninterval,'s');
		    realnsol := as_integer(nrows*integration/(nbaselines*solutioninterval));

		    subcode := private.subcodename(telescope=telescope,
						   datadescriptor=datadescriptor,
						   compressionmode=compressionmode,
						   jones=jn,
						   nchan=ch,
						   nsolint=realnsol,
						   nant=nant,snr=snr);
		    if (jn=='D') calibrate:='G';
		    else         calibrate:='';
			
		    private.calibkernel(code=code,  subcode=subcode, msfile=ums,
					jones=jn,   solint=solutioninterval,
#					preinteg=0, start=start, step=step, nchan=ch,
					preinteg=solutioninterval, start=start, step=step, nchan=ch,
					calibrate=calibrate,tablename=tablename);
		    

		    private.report(spaste(code,'-',subcode));
		}

	return T;
    };

    const public.fuvrdvlacu125k := function(fitsin='vlac125K.fits', compress=F)
    {
	# Run benchmark FUV-RD-VLA-C-U125K (FITS Filler, VLA, Continuum, 
	# uncompressed, 125K vis dataset)
	wider private;

	# Benchmark kernal code
	code := 'FUV-RD';
	
	# Parameters frozen for this benchmark
	compressionmode := 'U';
	datadescriptor  := 'C';
	telescope       := 'VLA';
	datasize        := '125K';
	private.loaduvfits(code, fitsin=fitsin, compress=compress);
	subcode := private.subcodename(telescope=telescope,
				       datadescriptor=datadescriptor,
				       compressionmode=compressionmode,
				       datasize=datasize, 
				       spwid=-1,
				       stokes='', 
				       weight='',
				       imsize=-1,
				       nchan=1,
				       niter=-1)


	private.report(spaste(code,'-',subcode));
	return T;
    };

    const public.fuvrdvlacu1m := function(fitsin='vlac1M.fits', compress=F)
    {
	# Run benchmark FUV-RD-VLA-C-U125K (FITS Filler, VLA, Continuum, 
	# uncompressed, 125K vis dataset)
	wider private;

	# Benchmark kernal code
	code := 'FUV-RD';
	
	# Parameters frozen for this benchmark
	compressionmode := 'U';
	datadescriptor  := 'C';
	telescope       := 'VLA';
	datasize        := '1M';
	private.loaduvfits(code, fitsin=fitsin, compress=compress);
	subcode := private.subcodename(telescope=telescope,
				       datadescriptor=datadescriptor,
				       compressionmode=compressionmode,
				       datasize=datasize, 
				       spwid=-1,
				       stokes='', 
				       weight='',
				       imsize=-1,
				       nchan=1,
				       niter=-1);

	private.report(spaste(code,'-',subcode));
	return T;
    };

    const public.fuvrdvlalu125k := function(fitsin='vlal125K64Chan.fits', compress=F)
    {
	# Run benchmark FUV-RD-VLA-C-U125K (FITS Filler, VLA, Continuum, 
	# uncompressed, 125K vis dataset)
	wider private;

	# Benchmark kernal code
	code := 'FUV-RD';
	
	# Parameters frozen for this benchmark
	compressionmode := 'U';
	datadescriptor  := 'L';
	telescope       := 'VLA';
	datasize        := '125K';
	private.loaduvfits(code, fitsin=fitsin, compress=compress);
	subcode := private.subcodename(telescope=telescope,
				       datadescriptor=datadescriptor,
				       compressionmode=compressionmode,
				       datasize=datasize, 
				       spwid=-1,
				       stokes='', 
				       weight='',
				       imsize=-1,
				       nchan=64,
				       niter=-1);

	private.report(spaste(code,'-',subcode));
	return T;
    };

    const public.almatifuvrd := function(fitsin='07-feb-1997-g067-04.fits', compress=F)
    {
	# Run benchmark FUV-RD-IRAM-ALMATI-U (FITS Filler, IRAM ALMA TI, uncompressed dataset)
	wider private;

	# Benchmark kernal code
	code := 'FUV-RD';
	
	# Parameters frozen for this benchmark
	compressionmode := 'U';
	datadescriptor  := '';
	telescope       := 'IRAM-ALMATI';
	datasize        := '';
	private.loadalmauvfits(code, fitsin=fitsin, compress=compress);
	subcode := private.subcodename(telescope=telescope,
				       datadescriptor=datadescriptor,
				       compressionmode=compressionmode,
				       datasize=datasize, 
				       spwid=-1,
				       stokes='', 
				       weight='',
				       imsize=-1,
				       nchan=-1,
				       niter=-1)

	private.report(spaste(code,'-',subcode));
	return T;
    };

    const public.ccsfvlacu125k := function(datafile='vlac125K.fits', myms='',
					   imsizes=[512,1024,2048],
					   stokes=['I', 'IQUV'],
					   weight=['natural','uniform'],
					   spwid=[1], niter=1000, mode='mfs',
					   nchan=1, start=1, step=1, chavg=1,
					   fieldid=1, facets=1,
					   tile=16,cache=4194304)
    {
	# Run benchmark CC-SF-VLA-C-U125K (Clark Clean, single-field, VLA, 125k vis,
	# uncompressed, continuum data)
	#
	# Description: form a PSF & dirty map;  deconvolve with Clark CLEAN
	# mode       : single-field, continuum
	#
	wider private;
	
#	datafile:='vlac125K.fits';
	
	# Benchmark kernal code
	code     := 'CC-SF';
	
	# Parameters frozen for this benchmark
	compressionmode := 'U';
	datadescriptor  := 'C';
	telescope       := 'VLA';
	datasize        := '125k';
	
	# Create the uncompressed test MS for this benchmark 
	if (myms=='')
	    {
		private.loaduvfits(code, fitsin=datafile, compress=F);
		ums := private.msname(code, datafile, compress=F);
	    }
	else  ums:=myms;

	private.stopwatch.reset(quiet=T);
	private.stopwatch.start(quiet=T);
	#==================================================================
	# BENCHMARK: CC-SF-VLA-C-U125K-SP1-{I,IQUV}-UN-{512,1024,2048}-1000
	#==================================================================
	#            ^____^ ^_________^ ^__________________________________^        
	#            Kernel  Frozen        Set via the argument list
	#
	# Kernel code: Clark CLEAN single-field imaging and deconvolution
	# uv-data params (frozen for this method): VLA continuum, 125k uncompressed 
	#                                          visibilities
	# uv-select: one spectral window
	# stokes: From argument stokes (default: [I])
	# weight: From argument weight (default: [uniform,natrual]);
	# nxy:    From argument imsize (default:[512,1024,2048])
	# niter:  From argument niter (default: 1000)
	# cellxy: 5 arcsec (frozen for this method)
	
	for (sz in imsizes)
	    for (s in stokes)
		for(w in weight)
		    for (t in tile) # 
			for (c in cache)
			{
			    subcode := private.subcodename(telescope=telescope,
							   datadescriptor=datadescriptor,
							   compressionmode=compressionmode,
							   datasize=datasize, 
							   spwid=spwid, 
							   stokes=s, 
							   weight=w,
							   imsize=sz,
							   nchan=nchan,
							   niter=niter,
							   cache=c, tile=t);
			    private.ccsfkernel(code=code, subcode=subcode, msfile=ums, 
					       spwid=spwid, weight=w, stokes=s, imsize=sz,
					       niter=niter, cellxy='5 arcsec', mode=mode,
					       nchan=nchan, start=start,step=step, chavg=chavg,
					       fieldid=fieldid, facets=facets,threshold='0 Jy',
					       tile=t,cache=c);
			    private.report(spaste(code,'-',subcode));
			}

	return T;
    };
    
    const public.ccsfvlacu1m := function(datafile='vlac1M.fits',
					 imsizes=[512,1024,2048],
					 stokes=['I', 'IQUV'],
					 weight=['natural','uniform'],
					 spwid=[1], niter=1000, mode='mfs',
					 nchan=1, start=1, step=1,chavg=1,
					 fieldid=1, facets=1,
					 tile=16,cache=4194304)
    {
	# Run benchmark CC-SF-VLA-C-U1M (Clark Clean, single-field, VLA, 125k vis,
	# uncompressed, continuum data)
	#
	# Description: form a PSF & dirty map;  deconvolve with Clark CLEAN
	# mode       : single-field, continuum
	#
	wider private;
	
	# Benchmark kernal code
	code     := 'CC-SF';
	
	# Parameters frozen for this benchmark
	compressionmode := 'U';
	datadescriptor  := 'C';
	telescope       := 'VLA';
	datasize        := '1M';
	
	# Create the uncompressed test MS for this benchmark 
	private.loaduvfits(code, fitsin=datafile, compress=F);
	ums := private.msname(code, datafile, compress=F);
	
	private.stopwatch.reset(quiet=T);
	private.stopwatch.start(quiet=T);
	#==================================================================
	# BENCHMARK: CC-SF-VLA-C-U1M-SP1-{I,IQUV}-UN-{512,1024,2048}-1000
	#==================================================================
	#            ^____^ ^______^ ^__________________________________^        
	#            Kernel  Frozen      Set via the argument list
	#
	# Kernel code: Clark CLEAN single-field imaging and deconvolution
	# uv-data params (frozen for this method): VLA continuum, 1M uncompressed 
	#                                          visibilities
	# uv-select: one spectral window
	# stokes: From argument stokes (default: [I])
	# weight: From argument weight (default: [uniform,natrual]);
	# nxy:    From argument imsize (default:[512,1024,2048])
	# niter:  From argument niter (default: 1000)
	# cellxy: 5 arcsec (frozen for this method)
	
	for (sz in imsizes)
	    for (s in stokes)
		for(w in weight)
		    for (t in tile)
			for (c in cache)
			{
			    subcode := private.subcodename(telescope=telescope,
							   datadescriptor=datadescriptor,
							   compressionmode=compressionmode,
							   datasize=datasize, 
							   spwid=spwid, 
							   stokes=s, 
							   weight=w,
							   imsize=sz,
							   nchan=nchan,
							   niter=niter,
							   cache=c, tile=t);
			    private.ccsfkernel(code=code, subcode=subcode, msfile=ums, 
					       spwid=spwid, weight=w, stokes=s, imsize=sz,
					       niter=niter, cellxy='5 arcsec', mode=mode,
					       nchan=nchan, start=start,step=step,chavg=1,
					       fieldid=fieldid, facets=facets,threshold='0 Jy',
					       tile=t,cache=c);
			    private.report(spaste(code,'-',subcode));
			}
	
	return T;
    };
    
    const public.ccsfvlalu125k := function(datafile='vlal125K64Chan.fits',
					   imsizes=[1024],
					   stokes=['I'],
					   weight=['natural','uniform'],
					   spwid=[1], niter=1000, mode='channel',
					   nchan=64, start=1, step=1,chavg=1,
					   fieldid=1, facets=1,
					   tile=16,cache=4194304)
    {
	# Run benchmark CC-SF-VLA-C-U125K (Clark Clean, single-field, VLA, 125k vis,
	# uncompressed, continuum data)
	#
	# Description: form a PSF & dirty map;  deconvolve with Clark CLEAN
	# mode       : single-field, continuum
	#
	wider private;
	
	    
	# Benchmark kernal code
	code     := 'CC-SF';
	
	# Parameters frozen for this benchmark
	compressionmode := 'U';
	datadescriptor  := 'L';
	telescope       := 'VLA';
	datasize        := '125k';
	
	# Create the uncompressed test MS for this benchmark 
	private.loaduvfits(code, fitsin=datafile, compress=F);
	ums := private.msname(code, datafile, compress=F);
	
	private.stopwatch.reset(quiet=T);
	private.stopwatch.start(quiet=T);
	#==================================================================
	# BENCHMARK: CC-SF-VLA-C-U125K-SP1-{I,IQUV}-UN-{512,1024,2048}-1000
	#==================================================================
	#            ^____^ ^_________^ ^__________________________________^        
	#            Kernel  Frozen        Set via the argument list
	#
	# Kernel code: Clark CLEAN single-field imaging and deconvolution
	# uv-data params (frozen for this method): VLA continuum, 125k uncompressed 
	#                                          visibilities
	# uv-select: one spectral window
	# stokes: From argument stokes (default: [I])
	# weight: From argument weight (default: [uniform,natrual]);
	# nxy:    From argument imsize (default:[512,1024,2048])
	# niter:  From argument niter (default: 1000)
	# cellxy: 5 arcsec (frozen for this method)
	
	for (sz in imsizes)
	    for (s in stokes)
		for(w in weight)
		    for (t in tile)
			for (c in cache)
			{
			    subcode := private.subcodename(telescope=telescope,
							   datadescriptor=datadescriptor,
							   compressionmode=compressionmode,
							   datasize=datasize, 
							   spwid=spwid, 
							   stokes=s, 
							   weight=w,
							   imsize=sz,
							   nchan=nchan,
							   niter=niter,
							   cache=c, tile=t);
			    private.ccsfkernel(code=code, subcode=subcode, msfile=ums, 
					       spwid=spwid, weight=w, stokes=s, imsize=sz,
					       niter=niter, cellxy='5 arcsec', mode=mode,
					       nchan=nchan, start=start,step=step,chavg=1,
					       fieldid=fieldid, facets=facets,threshold='0 Jy',
					       tile=t,cache=c);
			    private.report(spaste(code,'-',subcode));
			}
	
	return T;
    };
    
    const public.ccsfbi4nL := function(	datafile='BIMADATA',
				       imsizes=[256],
				       stokes=['I'],
				       weight=['natural'],
				       spwid=[1], niter=1000, mode='channel',
				       nchan=20, start=40, step=1,chavg=1,
				       fieldid=1, facets=1,
				       tile=16,cache=4194304)
	
    {
	# Run benchmark CC-SF-BI4NL (Clark Clean, single-field, BIMA, 139M vis,
	# uncompressed, line data)
	#
	# Description: form a PSF & dirty map;  deconvolve with Clark CLEAN
	# mode       : single-field, line 
	#
	wider private;
	
	
	# Benchmark code
	code := 'CC-SF';
	
	compressionmode := 'U';
	datadescriptor  := 'C';
	telescope       := 'BIMA';
	datasize        := '139M';
	
	# Create the uncompressed test MS for this benchmark 
#	private.bimamsmake(code, msin=spaste(private.datarepos,'/',datafile), compress=F);
	private.bimamsmake(code, msin=datafile, compress=F);
	
	ums := private.msname(code, datafile);
	
	#=============================================================
	# BENCHMARK: CC-SF-BIMA4NL-SP1-I-NA-256-1k
	#=============================================================
	# code: Clark CLEAN single-field imaging and deconvolution
	# uv-data: BIMA 3mm spectral line (BIMADATA) (139M vis uncompressed)
	# uv-select: one spectral window
	# stokes: I
	# weight: uniform
	# nxy: 128 pixels
	# cellxy: 1 arcsec
	# niter: 1000
	
	for (sz in imsizes)
	    for (s in stokes)
		for(w in weight)
		    for (t in tile)
			for (c in cahce)
			{
			    subcode := private.subcodename(telescope=telescope,
							   datadescriptor=datadescriptor,
							   compressionmode=compressionmode,
							   datasize=datasize, 
							   spwid=spwid, 
							   stokes=s, 
							   weight=w,
							   imsize=sz,
							   nchan=nchan,
							   niter=niter,
							   cache=c, tile=t);
			    private.ccsfkernel(code=code, subcode=subcode, msfile=ums, 
					       spwid=spwid, weight=w, stokes=s, imsize=sz,
					       niter=niter, cellxy='1 arcsec', mode=mode,
					       nchan=nchan, start=start,step=step,chavg=1,
					       fieldid=fieldid, facets=facets,
					       threshold='0.1Jy', 
					       tile=t,cache=c);
			    private.report(spaste(code,'-',subcode));
			}
	
	return T;
    };

    const public.visitervlacu125k := function(fitsin='vlac125K.fits', 
                                              compress=F)
    {
        #
        #====================================================================
        # Run benchmark: VISITER-VLA-C-U125K
        # (Visibility iteration, VLA, 125k vis, uncompressed, continuum data)
        #====================================================================
        #
        # Description: iterate through a visibility dataset, accessing
        #              all MAIN table columns and rows
        #
        wider private, public;

        # Benchmark kernel code
        code := 'VISITER';

        # Parameters frozen for this benchmark
        compressionmode := 'U';
        datadescriptor := 'C';
        telescope := 'VLA';
        datasize := '125K';

        # Create the uncompressed test MS for this benchmark
        private.loaduvfits(code=code, fitsin=fitsin, compress=F);
        msfile := private.msname(code=code, fitsin=fitsin, compress=F);

        #====================================================================
        # BENCHMARK: VISITER-VLA-C-U125K-{interval}S-{row blocking}R-{cache}M
        #====================================================================
        # kernel code  : VISITER
        # uv-data      : VLA continuum, 125k uncompressed visibilities
        # interval     : Iteration interval (seconds) {10,30,60,600,6000,86400}
        # row blocking : No. of rows to block in sub-interval iteration
        #                {0(same time stamp),250,500,1000,2000,4000,8000}
        # cache        : Table system cache size (MB) {1,2,4,8,16,32}
        #
        # Loop over benchmark sub-code parameters
        for (interval in [10,30,60,600,6000,86400]) {
            for (rowblock in [0,250,500,1000,2000,4000,8000]) {
                for (cacheMB in [1,2,4,8,16]) {
                    # Calculate cache size in bytes
                    cache := cacheMB * 1024 * 1024;
                    # Generate benchmark sub-code name
                    subcode := private.subcodename(telescope=telescope,
                                   datadescriptor=datadescriptor,
                                   compressionmode=compressionmode,
                                   datasize=datasize, interval=interval,
                                   rowblock=rowblock, cache=cache);
                    
                    # Execute the benchmark kernel and report the result
                    private.stopwatch.reset(quiet=T);
                    private.stopwatch.start(quiet=T);
                    private.visiterkernel(code=code, subcode=subcode,
                        msfile=msfile, interval=interval, rowblock=rowblock,
                        cache=cache);
                    private.report(spaste(code,'-',subcode));
                };
            };
        };
        return T;
    };

private.getscans := function(code) {
        wider private;
        if (code=='42256') return [17,18];
        if (code=='121k') return [36,37];
        if (code=='114k') return [20,21];
        if (code=='224k') return [43,44];
        if (code=='128k') return [48,48];
        if (code=='1216k') return [22,23];
        if (code=='12125k') return [51,52];

        return F;
        };

const public.sdall := function () {
        #
        # Run all Single-Dish GBT benchmarks
        #
        wider private,public;

        br:=[=];

        # GBT, 4 IF, 2 Polarization, 256 channel data    (1.48 MB)
        br[1]:=public.sdbench('42256');
        # GBT, 1 IF, 2 Polarization, 1024 channel data   (1.97 MB)
        br[2]:=public.sdbench('121k');
        # GBT, 1 IF, 1 Polarization, 4096 channel data   (8.93 MB)
        br[3]:=public.sdbench('114k');
        # GBT, 2 IF, 2 Polarization, 4096 channel data   (2.51 MB)
        br[4]:=public.sdbench('224k');
        # GBT, 1 IF, 2 Polarization, 8192 channel data   (8.20 MB)
        br[5]:=public.sdbench('128k');
        # GBT, 1 IF, 2 Polarization, 16000 channel data  (64.2 MB)
        br[6]:=public.sdbench('1216k');
        # GBT, 1 IF, 2 Polarization, 125000 channel data (18.1 MB)
        br[7]:=public.sdbench('12125k');

        ok:=public.report(br);

        return T;

        };

const public.sdbench := function(code) {
        #
        #Description: fill, access, display, calibrate, average, baseline
        #
        wider private;

        if (!is_record(d) || !has_field(d,'done')) {
                include 'dish.g';
                global d:=dish();       #form dish tool
        };

	include 'sysinfo.g';
        aipsroot := sysinfo().root();
        datafile := spaste(aipsroot,'/data/demo/benchmark/sdbench');
        if (!dos.fileexists(datafile)) {
           ok:=dl.log(message='File not found -- check path',priority='SEVERE');
           return F;
        };
        outms:=spaste('gbt_',code);

        shell('rm -r gbt_*');

        tests:=['import','getr','plotr','calib','average','base'];

        scans:=private.getscans(code);

        private.stopwatch.reset(quiet=T);
        private.stopwatch.start(quiet=T);
        ok:=d.import(datafile,outms,,scans[1],scans[2]);
        private.stopwatch.stop(quiet=T);
        timings[1]:=private.stopwatch.value();

        private.stopwatch.reset(quiet=T);
        private.stopwatch.start(quiet=T);
        ok:=d.getr(scans[1],1,1);
        private.stopwatch.stop(quiet=T);
        timings[2]:=private.stopwatch.value();

        private.stopwatch.reset(quiet=T);
        private.stopwatch.start(quiet=T);
        ok:=d.plotr(scans[1],1,1);
        private.stopwatch.stop(quiet=T);
        timings[3]:=private.stopwatch.value();

        private.stopwatch.reset(quiet=T);
        private.stopwatch.start(quiet=T);
        ok:=d.calib(scans[1]);
        private.stopwatch.stop(quiet=T);
        timings[4]:=private.stopwatch.value();

        private.stopwatch.reset(quiet=T);
        private.stopwatch.start(quiet=T);
        ok:=d.getc(scans[1]);
        private.stopwatch.stop(quiet=T);
        timings[5]:=private.stopwatch.value();
        private.stopwatch.reset(quiet=T);
        private.stopwatch.start(quiet=T);
        ok:=d.base(order=0);
        private.stopwatch.stop(quiet=T);
        timings[6]:=private.stopwatch.value();

        results:=[=];
        results.code:=code;
        results.tests:=tests;
        results.timings:=timings;

        return results;

        };

const public.report:=function(report_rec) {
        wider private,public;
        print 'here - length of rec ',len(report_rec);
        for (i in 1:len(report_rec)) {
           for (j in 1:6) {
               message:=spaste('gbt',report_rec[i].code,': ',
                report_rec[i].tests[j],' : ',report_rec[i].timings[j]);
                dl.log(message=message,priority='NORMAL');
           }
        };

        return T;
};

    const public.done := function()
    {
	wider private, public;
	
	# Report results summary
	private.reportall();
	
	# Close the calibrater, imager and image tools
#      private.calibrater.done();
#      if (!is_boolean(private.imager)) private.imager.done();
#      if (!is_boolean(private.image)) private.image.done();
	
	private := F;
	val public := F;
	if (has_field(private, 'gui')) {
	    ok := private.gui.done(T);
	    if (is_fail(ok)) fail;
	}
	return T;
    }
    
    const public.type := function() {
	return 'benchmark';
    }
    
    const public.gui := function() 
    {
	# Null 
	return T;
    };
    
    plugins.attach('benchmark', public);
    return ref public;
    
} # _define_benchmark()

#
# Constructor
#
const benchmark := function(datarepospath = spaste(aipsrc().aipsroot(),
                                                   '/data/demo/benchmark'),
                            host='', forcenewserver=T)
{
    agent:= defaultservers.activate("benchmark", host, forcenewserver);
    id:= defaultservers.create(agent, "benchmark", "benchmark", [=]);
    return ref _define_benchmark(datarepospath, agent, id);
} 

#
# Define demonstration function: return T if successful otherwise fail
#
const benchmarkdemo:=function() {
    mybenchmark:=benchmark();
    note(paste('Demonstation of ', mybenchmark.objectName()));
    note('Not yet implemented');  
    return T;
}

#
# Define test function: return T if successful otherwise fail
#
const benchmarktest:=function() { fail 'Not yet implemented';}

# 
#------------------------------------------------------------------------
#
