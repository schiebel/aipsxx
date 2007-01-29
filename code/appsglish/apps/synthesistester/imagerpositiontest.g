#-----------------------------------------------------------------------------
#
#   Copyright (C) 1992-1999,2000,2001,2002
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#-----------------------------------------------------------------------------
# $Id: imagerpositiontest.g,v 19.2 2005/07/27 16:33:18 kgolap Exp $

pragma include once

const imagerpositiontest := function(testdir='imager_position_test',clean=T) {

    include 'measures.g';
    include 'note.g';
    include 'quanta.g';
    include 'unset.g';

#### function dotests  makes the simulated data, image it, look for
#### sources in the image and compare with the simulated ones. 
#### The arguments are self explanatory except 'scalefactor' is the factor
#### you want to expand the default array size.

    const c := 3e8;

    public := [=];
    private := [=];
    private.testdir:=testdir;

    private.frequency := '22GHz';
    private.nsources := 4;
    private.dish_diameter := 25;
    private.source_spread := 1;

    private.msname := spaste(testdir, '/','simul.ms');
    private.center_position := unset;


    private.docorrupt := F;
    private.imagename:= spaste(testdir,'/','simulimage');
    private.model_imagename := spaste(private.imagename,'.orig_model');
    private.restoredimage:=spaste(private.imagename, '.restored');

    private.clean := [=];
    private.clean.algorithm := 'clark';
    private.clean.niter := 1000;
    private.clean.gain := 0.1;
    private.clean.threshold := '0Jy';
    private.clean.displayprogress := F;
    private.clean.fixed := F;
    private.clean.multiscale.scales := unset;
    
    private.mem := [=];
    private.mem.algorithm := 'entropy';
    private.mem.niter := 20;
    private.mem.sigma := '0.001Jy';
    private.mem.targetflux := '1.0Jy';
    private.mem.constrainflux := F;
    private.mem.displayprogress := F;
    private.mem.fixed := F;

    private.mfcontrol.cyclefactor := 3.0;
    private.mfcontrol.cyclespeedup := -1;
    private.mfcontrol.stoplargenegatives := 2;
    private.mfcontrol.stoppointmode := -1;
    private.mfcontrol.scaletype := 'NONE';
    private.mfcontrol.minpb := 0.1;
    private.mfcontrol.constpb := 0.4;

    private.is_single_field := T;
    private.deconv_function := 'clean';
    private.imager_too_type := 'imager';
    private.simulator := unset;
    private.simulator::user_specified := F;
    private.noise_level := '1Jy';
    private.seed := time(); 
    private.seed::user_specified := F;
    private.cltablename := spaste(testdir, '/','simu_comp.cl');
    private.cltablename::user_specified := F;
    private.imaging_tool_type := 'imager';
    private.pimager_numprocs := 1;

    private.sim_parms := [=];
    private.sim_parms.scalefactor := 1;
    private.sim_parms.nchan := 1;
    private.sim_parms.nfields := 1;
    private.sim_parms.fov := [=]; 
    private.sim_parms.fov.ra := 
        dq.quantity([value = 3.e8/private.dish_diameter/dq.convert(dq.quantity(private.frequency),
                                                'Hz').value,unit='rad']);
    private.sim_parms.fov.dec := private.sim_parms.fov.ra; 
    private.sim_parms.deltafreq := '1MHz';
    private.sim_parms.freqresolution := private.sim_parms.deltafreq;
    private.sim_parms.direction := dm.direction('J2000', '16h00m0.0', 
                                                '50d0m0.000');
    private.sim_parms.flux.min := 3;
    private.sim_parms.flux.max := 10;
    private.sim_parms.minsep := 5;
    private.sim_parms.xm := 1;
    private.sim_parms.ym := 1;
    private.sim_parms.seed := 185349251;
    private.sim_parms.seed::user_specified := F;

    private.imaging_parms := [=];
    private.imaging_parms.nx := unset;
    private.imaging_parms.ny := unset;
    private.imaging_parms.cellx := unset;
    private.imaging_parms.celly := unset;
    private.imaging_parms.stokes := 'I';
    private.imaging_parms.doshift := unset;
    private.imaging_parms.phasecenter := unset;
    private.imaging_parms.shiftx := '0arcsec';
    private.imaging_parms.shifty := '0arcsec';
    #different from imager.setimage() default
    private.imaging_parms.mode := 'channel'; 
    private.imaging_parms.nchan := unset;
    private.imaging_parms.start := 1;
    private.imaging_parms.step := 1;
    private.imaging_parms.mstart := '0km/s';
    private.imaging_parms.mstep := '0km/s';
    private.imaging_parms.spwid := 1;
    private.imaging_parms.fieldid := unset;
    private.imaging_parms.facets := unset;
    private.imaging_parms.clean_mask_type := 'all';


    private.imaging_ms_parms := [=];
    private.imaging_ms_parms.mode := 'channel';
    private.imaging_ms_parms.nchan := unset;
    private.imaging_ms_parms.start := 1;
    private.imaging_ms_parms.step := 1;
    private.imaging_ms_parms.mstart := '0km/s';
    private.imaging_ms_parms.mstep := '0km/s';
    private.imaging_ms_parms.spwid := 1;
    private.imaging_ms_parms.fieldid := unset;
    private.imaging_ms_parms.msselect := ' ';

    private.imaging_options := [=];
    private.imaging_options::user_specified := F;
    private.imaging_options.ftmachine := 'gridft';
    private.imaging_options.cache := 0; 
    private.imaging_options.tile := 16;
    private.imaging_options.gridfunction := 'SF';
    private.imaging_options.location := F;
    private.imaging_options.padding := 1.2;

    private.tolerance := 1;

    const public.setcleanparms := function(algorithm='clark',niter=1000,
                                             gain=0.1,threshold='0Jy',
                                             displayprogress=F,fixed=F) {
        wider private;
        private.clean.algorithm := algorithm;
        private.is_single_field := 
            any(['clark','hogbom','multiscale'] == algorithm);
        private.clean.niter := niter;
        private.clean.gain := gain;
        private.clean.threshold := threshold;
        private.clean.displayprogress := displayprogress;
        private.clean.fixed := fixed;
        return T;
    }

    const public.setmemparms := function(algorithm='entropy',niter=20,
                                           sigma='0.001Jy',targetflux='1.0Jy',
                                           constrainflux=F,displayprogress=F,
                                           fixed=F) {
        wider private;
        ok_algs := ['entropy','emptiness','mfentropy','mfemptiness'];
        if(!any(ok_algs == algorithm))
            fail spaste('Unknown mem algoritm ',spaste,
                        '.  Algorithm must be one of ',ok_algs);
        private.mem.algorithm := algorithm;
        private.is_single_field := 
            any(['entropy','emptiness'] == algorithm);
        private.mem.niter := niter;
        private.mem.sigma := sigma;
        private.mem.targetflux := targetflux;
        private.mem.constrainflux := constrainflux;
        private.mem.displayprogress := displayprogress;
        private.mem.fixed := fixed;
        return T;
    }

    const public.setmfcontrolparms := function(cyclefactor=3.0,
                                                 cyclespeedup=-1,
                                                 stoplargenegatives=2,
                                                 stoppointmode=-1,
                                                 scaletype='NONE',minpb=0.1,
                                                 constpb=0.4) {
        wider private;
        private.mfcontrol.cyclefactor := cyclefactor;
        private.mfcontrol.cyclespeedup := cyclespeedup;
        private.mfcontrol.stoplargenegatives := stoplargenegatives;
        private.mfcontrol.stoppointmode := stoppointmode;
        private.mfcontrol.scaletype := scaletype;
        private.mfcontrol.minpb := minpb;
        private.mfcontrol.constpb := constpb;
        return T;
    }


    const public.setdeconvolutionfunction := function(df = 'clean') {
        wider private;
        types := ['clean','mem', 'nnls'];
        if(!any(types == df)) 
           fail spaste('algorthm ',df,' not recognized. One of ',types,
                       ' must be specified');
        private.deconv_function := df;
        return T;
    }

    #@
    # set the seeds used to seed the random number generator for producing
    # the x and y positions of the simulated sources
    # @param posx the seed for the x position generator
    # @param posy the seed for the y position generator
    
    const public.setseed := function(seed) {
        wider private;
        private.seed := seed;
        private.seed::user_specified := T;
        return T;
    }

    #@ 
    # get the seeds that are used to seed the posx and posy random
    # number generators.  Unless specified by the user with setseed()
    # these values will not be set until the function which makes the
    # simulated source component list is called
    # @return vector of length two containing the posx and posy seeds

    const public.getseed := function() {
        wider private;
        return private.seed;
    }

    #@ 
    # set the componentlist table on disk to use for simulating the data
    #

    const public.setcomponentlisttable := function(cltablename) {
        wider private;
        private.cltablename := cltablename;
        private.cltablename::user_specified := T;
        return T;
    }

    #@
    # get the component list disk table name
    # @return the componentlist table name on disk
    #

    const public.getcomponentlisttable := function() {
        wider private;
        return private.cltablename;
    }
    

    #@
    # set up parameters to be used by the simulator
    #

    const public.setsimparms := function(frequency='22GHz',docorrupt=F,
                                           scalefactor=1,nchan=1,
                                           nsources=4,noiselevel = '1Jy',
                                           nfields=1,deltafreq='1MHz',
                                           freqresolution='1MHz',
                            sourcedirection=dm.direction('J2000', '16h00m0.0', 
                                                '50d0m0.000'),
                                           source_spread=1,minflux=3,
                                           maxflux=10,minsep=5,seed=185349251) 
    {
        wider private;
#        if(!is_unset(sourcedirection)) {
        if(is_measure(sourcedirection))
            private.sim_parms.direction := sourcedirection;
        else
            fail spaste('Source direction ',sourcedirection,
                        ' is not a measure');
#        }
        if(nfields > 2) {
            ok := F;
            if (any([3,5,7,11,13,17,19] == nfields)) {}
            else if(any([4,6,8,9,10,12,14,16,18,20] == nfields))
                ok := T;
            else {
                for (factor in 2:floor(sqrt(nfields))) {
                    tmp := nfields/factor;
                    if(tmp == as_integer(tmp)) {
                        ok := T;
                        break;
                    }
                }
            }
            if(!ok) fail 'nfields must be <= 2 or a non prime number';
        }                   
        private.sim_parms.nfields := nfields;
        if(nfields == 1) {
            xm := 1;
            ym := 1;
        } else if(nfields == 2) {
            xm := 2;
            ym := 1;
        } else {
            for (factor in floor(sqrt(nfields)):1) {
                if(nfields/factor == as_integer(nfields/factor)) {
                    xm := nfields/factor;
                    ym := factor;
                    break;
                }
            }
        }
        private.sim_parms.scalefactor := scalefactor;
        private.sim_parms.nchan := nchan;
        private.docorrupt := docorrupt;
        private.nsources := nsources;
        private.noise_level := noiselevel;
        private.frequency := frequency;
        private.sim_parms.deltafreq := deltafreq;
        private.sim_parms.freqresolution := freqresolution;
        private.sim_parms.xm := xm;
        private.sim_parms.ym := ym;
        freq:=dq.convert(frequency, 'Hz').value;
        if(!private.simulator::user_specified) {
            private.sim_parms.fov.ra := dq.quantity([value = xm*3.e8/freq/private.dish_diameter, 
                                                     unit='rad']);
            private.sim_parms.fov.dec := dq.quantity([value = ym*3.e8/freq/private.dish_diameter, 
                                                      unit='rad']);
        }
        private.source_spread := source_spread;
        private.sim_parms.minflux := minflux;
        private.sim_parms.maxflux := maxflux;
        private.sim_parms.minsep := minsep;
        if(seed != private.sim_parms.seed) {
            private.sim_parms_seed := seed;
            private.sim_parms_seed::user_specified := T;
        }
        
        return T;
    }

    #@
    # set the imaging tool to use, either 'imager' or 'pimager'
    # @param type the tool type  
    #
    
    const public.setimagingtooltype := function(type='imager') {
        wider private;
        ok_types := ['imager','pimager'];
        if(!any(ok_types == type)) fail spaste('Type ',type,' is not ',
                                             'recognized. It must be one of ',
                                             ok_types);
        private.imaging_tool_type := type;
        return T;
    }                          

    #@
    # essentially set the parameters that will be passed to the imaging
    # tool's setdata function

    const public.setimagingdataparms := function(mode='channel',nchan=unset,
                                                    start=1,step=1,
                                                    msselect=unset) {
        wider private;	
        if(!is_unset(mode)) private.imaging_ms_parms.mode := mode;
        if(!is_unset(nchan)) private.imaging_ms_parms.nchan := nchan;
        if(!is_unset(start)) private.imaging_ms_parms.start := start;
        if(!is_unset(step)) private.imaging_ms_parms.step := step;
#        if(!is_unset(mstart)) private.imaging_ms_parms.mstart := mstart;
#        if(!is_unset(mstep)) private.imaging_ms_parms.mstep := mstep;
#        if(!is_unset(spwid)) private.imaging_ms_parms.spwid := spwid;
#        if(!is_unset(fieldid)) private.imaging_ms_parms.fieldid := fieldid;
        if(!is_unset(msselect)) private.imaging_ms_parms.msselect := msselect;
        return T;
    }

    const public.setimagingoptions := function(ftmachine='gridft',
                                                 cache=0, tile=16,
                                                 gridfunction='SF',
                                                 location=F,
                                                 padding=1.2) {
        wider private;
        private.imaging_options::user_specified := T;
        private.imaging_options.ftmachine := ftmachine;
        private.imaging_options.cache := cache; 
        private.imaging_options.tile := tile;
        private.imaging_options.gridfunction := gridfunction;
        private.imaging_options.location := location;
        private.imaging_options.padding := padding;
        return T;
    }


    #@
    # essentially set parameters that will be passed to the setimage()
    # function of the imaging tool
    # 
    
    const public.setimagingparms := function(nx=unset, ny=unset, cellx=unset,
                                               celly=unset, stokes=unset, 
                                               doshift=unset, 
                                               phasecenter=unset, 
                                               shiftx='0arcsec',
                                               shifty='0arcsec', 
                                               mode='mfs', 
                                               nchan=unset, start=1, 
                                               step=1, facets=unset) {
        wider private;
        if(!is_unset(nx)) private.imaging_parms.nx := nx;
        if(!is_unset(ny)) private.imaging_parms.ny := ny;
        if(!is_unset(cellx)) private.imaging_parms.cellx := cellx;
        if(!is_unset(celly)) private.imaging_parms.celly := celly;
        if(!is_unset(stokes)) private.imaging_parms.stokes := stokes;
        if(!is_unset(doshift)) private.imaging_parms.doshift := doshift;
        if(!is_unset(phasecenter)) 
            private.imaging_parms.phasecenter := phasecenter;
        if(!is_unset(shiftx)) private.imaging_parms.shiftx := shiftx;
        if(!is_unset(shifty)) private.imaging_parms.shifty := shifty;
        if(!is_unset(mode)) private.imaging_parms.mode := mode;
        if(!is_unset(nchan)) private.imaging_parms.nchan := nchan;
        if(!is_unset(start)) private.imaging_parms.start := start;
        if(!is_unset(step)) private.imaging_parms.step := step;
#        if(!is_unset(mstart)) private.imaging_parms.mstart := mstart;
#        if(!is_unset(mstep)) private.imaging_parms.mstep := mstep;
#        if(!is_unset(spwid)) private.imaging_parms.spwid := spwid;
#        if(!is_unset(fieldid)) private.imaging_parms.fieldid := fieldid;
        if(!is_unset(facets)) private.imaging_parms.facets := facets;
        return T;
    }


    #@
    # set the number of processors to use for pimager runs
    # @param numprocs the number of processors to use
    #

    const public.setpimagernumprocs := function(numprocs=1) {
        wider private;
        private.pimager_numprocs := numprocs;
        return T;
    }

    const public.dotests := function() { 
        wider private, public;
        testdir := private.testdir; 
        foundcl := spaste(testdir, '/','found_comp.cl');
        if(is_unset(private.simulator)) {
            note('Setting up the simulator');
            ok := public.makedefaultsimulator(frequency=private.frequency, 
                                    arrayscale=private.sim_parms.scalefactor);
            if(is_fail(ok)) return throw(ok::message);
        } else note('User specified simulator found');
        if(private.cltablename::user_specified) 
            note(spaste('You have set the component list to be used ',
                        'explicitly. I will not create a default list.'));
        else {
            note('Making default simulated components');
            ok := public.makedefaultcl(clname=private.cltablename,
                                   frequency=private.frequency,
                                   nsources=private.nsources, epoch='J2000',
                                   fluxmin=private.sim_parms.flux.min,
                                   fluxmax=private.sim_parms.flux.max,
                                   minsep=private.sim_parms.minsep);
            if(is_fail(ok)) return throw(ok::message);
        }
        
        note('Setting the data in the ms');
        ok := public.makems(docorrupt = private.docorrupt,
                             noiselevel=private.noise_level);
        if(is_fail(ok)) return throw(ok::message);
        note('Imaging data');
        public.makeimage(private.msname,private.imagename);
        note('Fitting sources from restored image')
            public.findsource(private.nsources,private.restoredimage,foundcl);
        note('Comparing position of sources found');
        res := public.sourcecompare(foundcl, private.cltablename);
        note(res);
        if(all(res)) note(spaste('All ',len(res),' tests PASSED'));
        else note(spaste(len(res[!res]),' of ',len(res),' tests FAILED'));
        return T;
    }

    #@
    # allows user to specify the simulator tool
    # @param sim the simulator tool
    # @return T or fail
    #

    const public.setsimulator := function(sim) {
        wider private;
        if(is_unset(sim) || !has_field(sim,'type') || sim.type() != 
           'simulator')
            fail 'Tool is not a simulator tool';
        ms := sim.name();
        if(ms == '') {
            ok := sim.create(newms=private.msname,shadowlimit=0.001,
                             elevationlimit='8.0deg',autocorrwt=0.0); 
            if(is_fail(ok)) return throw (ok::message);
            if(!ok) fail spaste('Unable to create a MS for your simulator ',
                                'tool.  Did you fail to specify something ',
                                'when you set up the simulator tool?');
            note(spaste('Creating ms ',private.msname,' from user-specified ',
                        'simulator tool'));
        } else {
            note(spaste('User has created ms ',ms,'. I will use that'));
            private.msname := ms;
        }
        t := table(private.msname);
        d := t.getcol('DISH_DIAMETER');
        private.dish_diameter := sum(d)/len(d);
        private.sim_parms.fov.ra := 
            dq.quantity([value = 3.e8/private.dish_diameter/dq.convert(dq.quantity(private.frequency),
                                          'Hz').value,unit='rad']);
        private.sim_parms.fov.dec := private.sim_parms.fov.ra; 


        private.simulator := ref sim;
        private.simulator::user_specified := T;
        return T;
    }

    #@
    # set the tolerance (in beam widths for passable source comparisons
    # @param tol the tolerance in beam widths for passable comparisons
    
    const public.settolerance := function(tol=1) {
        wider private;
        private.tolerance := tol;
        return T;
    }

    #@
    # get the restoring beam (including new fields added by sourcecomp)
    # only makes since to run this after the deconvolution
    # @return the beam (a record)

    const public.getbeam := function() {
        wider private;
        return private.beam;
    }

 
    #@
    # creates a default simulator tool
    # @param frequency the frequency
    # @param the scale factor of the array (>1 longer baselines)
    #

    const public.makedefaultsimulator := function(frequency=unset, 
			 arrayscale=1) {
        include 'simulator.g';
        wider private, public;
        if(is_unset(frequency)) frequency := private.frequency;
        testdir := private.testdir; 

        # VLA antenna positions

        xx := [41.1100006,134.110001,268.309998,439.410004,644.210022,
               880.309998,1147.10999,1442.41003,1765.41003,-36.7900009,
               -121.690002,-244.789993,-401.190002,-588.48999,-804.690002,
               -1048.48999,-1318.48999,-1613.98999,-4.38999987,-11.29,
               -22.7900009,-37.6899986,-55.3899994,-75.8899994,-99.0899963,
               -124.690002,-152.690002];
        yy := [3.51999998,-39.8300018,-102.480003,-182.149994,-277.589996,
               -387.839996,-512.119995,-649.76001,-800.450012,-2.58999991,
               -59.9099998,-142.889999,-248.410004,-374.690002,-520.599976,
               -685,-867.099976,-1066.42004,77.1500015, 156.910004,287.980011,
               457.429993,660.409973,894.700012,1158.82996,1451.43005,
               1771.48999];
        zz := [0.25,-0.439999998,-1.46000004,-3.77999997,-5.9000001,
               -7.28999996,-8.48999977,-10.5,-9.56000042,0.25,-0.699999988,
               -1.79999995,-3.28999996,-4.78999996,-6.48999977,-9.17000008,
               -12.5299997,-15.3699999,1.25999999,2.42000008,4.23000002,
               6.65999985,9.5,12.7700005,16.6800003,21.2299995,26.3299999];


        xx:=arrayscale*xx;
        yy:=arrayscale*yy;
        zz:=arrayscale*zz;

        diam := 0.0* [1:27] + private.dish_diameter;
        reftime := dm.epoch('utc', 'today');
        private.simulator := simulator();
        private.simulator.settimes( integrationtime='10s', gaptime='0s', 
                                   usehourangle=T,
                       starttime='0s', stoptime='3600s');
#                       referencetime=reftime);
        private.simulator.setfield(row=1, sourcename='SIMU1', 
                                   sourcedirection=private.sim_parms.direction,
                       integrations=1, xmospointings=private.sim_parms.xm, 
                                   ymospointings=private.sim_parms.ym,
                       mosspacing=1.0);
        posvla := dm.observatory('vla'); 

        private.simulator.setconfig(telescopename='VLA', x=xx, y=yy, z=zz, 
                        dishdiameter=diam,mount='alt-az', antname='VLA',
                        coordsystem='local', referencelocation=posvla);

        private.simulator.setspwindow(row=1, spwname=as_string(frequency), 
                                      freq=frequency, 
                                      deltafreq=private.sim_parms.deltafreq,
                                      freqresolution=
                                      private.sim_parms.freqresolution,
                                      nchannels=private.sim_parms.nchan, 
                                      stokes='RR LL');
        note('Creating the measurementset');
        private.simulator.create(newms=private.msname, shadowlimit=0.001, 
                                 elevationlimit='8.0deg',
                                 autocorrwt=0.0);
        private.simulator::user_specified := F;
        return T;
    }

    #@
    # set the type of mask to use for cleaning
    # @param type all=all of the image,comps= only regions containing model
    #        components are used

    const public.setcleanmask := function (type='all') {
        wider private;
        oktypes := ['all','comps'];
        if(!any(oktypes == type))
            fail spaste('Unrecognized mask type ',type,
                        '. Type must be one of ',oktypes);
        private.imaging_parms.clean_mask_type := type;
        return T;
    }

    #@
    # creates the ms from the simulator tool
    # @param clfile the componentlist file to simulate, if unspecified uses
    #         a default
    # @param docorrupt corrupt the measurement set by adding noise?  if unset,
    #        uses private.docorrupt
    # @param noiselevel (simple) noise level to use if docorrupt is true, if
    #                   unspecified private.noise_level is used
    #

    const public.makems := function(clfile=unset, docorrupt = F,
                                    noiselevel = 0) {
        wider private;
        if(is_unset(private.simulator))
            fail spaste('You either need to set up your own simulator tool ',
                        'and pass it in using setsimulator() or just run ',
                        'dotests()');
        if(is_unset(clfile)) clfile := private.cltablename;
        note('Generating measurement set');
        ok := private.simulator.predict(complist=clfile); 
        if(is_fail(ok))
            return throw(spaste('You must create and set up a simulator tool ',
                                'properly and pass it to this tool using ',
                                'setsimulator() or just run dotests()'));

        if(docorrupt) {
            if(private.sim_parms.seed::user_specified)
                private.simulator.setseed(private.sim_parms.seed);
            private.simulator.setnoise( mode='simplenoise', 
                                       simplenoise=noiselevel);
            note('Corrupting MS');
            private.simulator.corrupt();
        }
        private.simulator.done();
        return T;
    }


    #@
    # create the default component list to be simulated
    # @param clname name of the componentlist table that will be written to 
    #               disk
    # @param frequency ref frequency
    # @param epoch the epoch
    # @param nsources number of sources to simulate
    # @param phasecenter phasecenter of the observations

    const public.makedefaultcl := function(clname='dummy.cl', 
                                             frequency=unset, 
                                             epoch='J2000', nsources=4, 
                                             phasecenter=unset,fluxmin=3,
                                             fluxmax=10,minsep=5) {
        include 'componentlist.g';
        include 'randomnumbers.g';
        include 'ms.g';
        wider private,public;
        if(is_unset(frequency)) frequency := private.frequency;

        if(is_unset(phasecenter) || !phasecenter) 
            phasecenter := private.sim_parms.direction;
        rand :=randomnumbers();

        flux:=rand.uniform(fluxmin, fluxmax, nsources); 

        # fovra and fovdec in rad
        fovra := private.sim_parms.fov.ra.value;
        fovdec := private.sim_parms.fov.dec.value;
        ss := private.source_spread;

        rand.reseed(private.seed);
        if(minsep <= 0) {
            radius := rand.uniform((-1)*ss,ss,nsources)/2;
            theta := rand.uniform(0,2*pi,nsources);
            posx := radius*cos(theta)*fovra;
            posy := radius*sin(theta)*fovdec;
        } else {
        # assume small angles for seperation check
            getpos := function() {
                radius := rand.uniform((-1)*ss,ss,1)/2;
                theta := rand.uniform(0,2*pi,1);
                posx := radius*cos(theta)*fovra;
                posy := radius*sin(theta)*fovdec;
                return [posx,posy];
            }
            for(i in 1:nsources) {
                pos := getpos();
                posx[i] := pos[1];
                posy[i] := pos[2];
                j := 1;
                resetcount := 0;
                bad_pos := T;
                while(bad_pos) {
                    dx := posx[i]*cos(posy[i]) - 
                        posx[ind(posx) != i]*cos(posy[ind(posy) != i]);
                    dy := posy[i] - posy[ind(posy) != i];
                    if(min(dx,dy) < minsep) { 
                        dist := sqrt(dx*dx+dy*dy);
                        if(min(dist)*180*3600/pi < minsep) {
                            pos := getpos(); 
                            posx[i] := pos[1];
                            posy[i] := pos[2];
                            j := 0;
                            resetcount := resetcount + 1;
                        } else bad_pos := F;
                    } else bad_pos := F;
                    if(resetcount > 10*i)
                        fail spaste('Unable to set source position ',
                                    'distribution using a minsep of ',minsep,
                                    ' arcsec.  Either decrease the number of ',
                                    ' sources, increase the field size, or ',
                                    ' decrease minsep (<',i,'.');
                }
            }    
        }

        mm := ms(private.msname);
        uvdist := mm.range('uvdist');

        maxsize := 0.2*dq.constants('c').value/dq.convert(frequency,'Hz').value/uvdist.uvdist[2];
        maxsize := dq.quantity(maxsize,'rad');
        maxsize := dq.convert(maxsize,'arcsec');
        
        majsize := rand.uniform(0,maxsize.value,nsources);
        minsize := rand.uniform(0,maxsize.value,nsources);
        tmp1 := majsize;
        tmp2 := minsize;        
        majsize[ind(minsize)[tmp2>tmp1]] := tmp2[tmp2>tmp1]; 
        minsize[ind(minsize)[tmp1<tmp2]] := tmp1[tmp1<tmp2]; 
        pa := rand.uniform(0,180,nsources);

        cp := public.getcenterposition();

        ra := posx+cp.m0.value;
        dec := posy+cp.m1.value;

        cl:=emptycomponentlist();

        for (k in 1:nsources){

            note(spaste('ra is ',ra[k],' dec is ',dec[k]));
            cl.addcomponent(flux=[flux[k], 0, 0,0] , fluxunit="Jy" ,
                            polarization="Stokes", shape="Gaussian",
                            dirframe=epoch,ra=as_string(ra[k]),raunit='rad', 
                            dec=as_string(dec[k]), decunit='rad', 
                            majoraxis=[value=majsize[k], unit="arcsec" ],
                            minoraxis=[value=minsize[k], unit="arcsec" ],
                            positionangle=[value=pa[k], unit="deg"], 
                            spectrumtype='constant',freq=frequency);
        }


        cl.rename(clname);
        cl.close();    
	private.cltablename:=clname;         
        return T;
    }

    const public.getcenterposition := function() {
        wider private;
        if(is_unset(private.center_position)) {
            t := table(spaste(private.msname,'/FIELD'));
            if(is_fail(t)) return throw;
            pos := t.getcol('PHASE_DIR');
            t.done();
            ra := pos[1,,];
            rapos := (max(ra) + min(ra))/2;
            dec := pos[2,,];
            decpos := (max(dec) + min(dec))/2;
            private.center_position := 
                dm.direction('J2000', spaste(rapos,'rad'),
                             spaste(decpos,'rad'));
        }
        return private.center_position;
    }

    #@
    # make an image from the model data using an input image as a template
    # @param template the template image (will be zeroed and then model
    #                 added)
    
    const public.makemodelimage := function(template,
                                       imagename='simulimage_orig.model', 
					factor=1) {

        include 'image.g';
        wider private;
        im := imagefromimage(imagename,template);
        if(is_fail(im)) return throw;
        s := im.shape();
        if(len(s) == 1)
            a := array(0,s[1]);
        else if(len(s) == 2)
            a := array(0,s[1],s[2]);
        else if(len(s) == 3)
            a := array(0,s[1],s[2],s[3]);
        else if(len(s) == 4)
            a := array(0,s[1],s[2],s[3],s[4]);
        else if(len(s) == 5)
            a := array(0,s[1],s[2],s[3],s[4],s[5]);
        im.putchunk(a); 
	shell(spaste('cp -r ', private.cltablename, ' mytemp.cl'))
	cllist:=componentlist('mytemp.cl')
	for (k in 1:cllist.length()){
	  myshape:=cllist.getshape(k)
	  myshape.majoraxis:=dq.mul(myshape.majoraxis, factor);
	  myshape.minoraxis:=dq.mul(myshape.minoraxis, factor);	
	  cllist.setshape(which=k, type='gaussian', 
	                  majoraxis=myshape.majoraxis, 
			  minoraxis=myshape.minoraxis,
			  positionangle=myshape.positionangle,
			  log=F);
	  myflux:=cllist.getfluxvalue(k)
	  cllist.setflux(which=k, value=myflux*factor*factor);		  				       

	}
        im.modify(cllist,subtract=F);
	cllist.done()
        im.done();
	shell('rm -rf  mytemp.cl') 
        return T;
    }

    const public.makeimage:= function(ms=unset, imagename=unset) {
        wider private,public;
        include 'image.g';
        if(is_unset(ms)) ms := private.msname;
	if(is_unset(imagename)){ 
	  imagename:=private.imagename
        }
	else{
	  private.imagename:=imagename;
	  private.restoredimage:=spaste(imagename,'.restored');
        }
	  
        if(private.sim_parms.fov.ra.value > private.sim_parms.fov.dec.value)
            fov := private.sim_parms.fov.ra;
        else
            fov := private.sim_parms.fov.dec;
#        fov := private.sim_parms.fov;
        note(spaste('Field of view=', fov));
        if(private.imaging_tool_type == 'imager') {
            note('Using imager for imaging');
            include 'imager.g';
            myimager:=imager(ms);
        } else if(private.imaging_tool_type == 'pimager') {
            note('Using pimager for imaging');
            include 'pimager.g';
            myimager := pimager(ms,numprocs=private.pimager_numprocs);
        } else fail spaste('Unknown imaging tool type ',
                           private.imaging_tool_type);



        
        if(is_unset(private.imaging_ms_parms.nchan))
            private.imaging_ms_parms.nchan := private.sim_parms.nchan;
        if(is_unset(private.imaging_ms_parms.fieldid))
            private.imaging_ms_parms.fieldid := 1:private.sim_parms.nfields;
        myimager.setdata(mode=private.imaging_ms_parms.mode,
                         nchan=private.imaging_ms_parms.nchan,
                         start=private.imaging_ms_parms.start,
                         step=private.imaging_ms_parms.step,
                         mstart=private.imaging_ms_parms.mstart,
                         mstep=private.imaging_ms_parms.mstep,
                         spwid=private.imaging_ms_parms.spwid,
                         fieldid=private.imaging_ms_parms.fieldid,
                         msselect=private.imaging_ms_parms.msselect);
        if(is_unset(private.imaging_parms.nchan)) 
            private.imaging_parms.nchan := private.sim_parms.nchan;
        if(is_unset(private.imaging_parms.doshift))
            private.imaging_parms.doshift := private.sim_parms.xm > 1 ||
                private.sim_parms.ym > 1;
        if(is_unset(private.imaging_parms.fieldid) && 
          !private.imaging_parms.doshift) 
            private.imaging_parms.fieldid := private.imaging_ms_parms.fieldid;
        if(is_unset(private.imaging_parms.phasecenter)) { 
            if(private.imaging_parms.doshift) 
                private.imaging_parms.phasecenter := 
                    public.getcenterposition();
            else private.imaging_parms.phasecenter := F;
        }

        if(is_unset(private.imaging_parms.nx) || 
           is_unset(private.imaging_parms.ny) ||
           is_unset(private.imaging_parms.cellx) ||    
           is_unset(private.imaging_parms.celly) ||
           is_unset(private.imaging_parms.facets)) {
            local cellsize, npix, nfacets;
            myimager.advise(fieldofview=fov, cell=cellsize, pixels=npix, 
                            facets=nfacets);
            if(is_unset(private.imaging_parms.nx)) {
                if(private.is_single_field){
                    private.imaging_parms.nx := 2*npix;
                }
		else{
		  private.imaging_parms.nx := npix*private.sim_parms.xm
                }
            }
            if(is_unset(private.imaging_parms.ny)) {
                if(private.is_single_field)
                    private.imaging_parms.ny := 2*npix;
                else
                    private.imaging_parms.ny := npix*private.sim_parms.ym;
            }
            if(is_unset(private.imaging_parms.cellx)) 
                private.imaging_parms.cellx := cellsize;
            if(is_unset(private.imaging_parms.celly)) 
                private.imaging_parms.celly := cellsize;
            if(is_unset(private.imaging_parms.facets)) 
                private.imaging_parms.facets := nfacets;
        }



        if(private.imaging_options::user_specified) {
            note('Setting user specified imaging options...');
            myimager.setoptions(ftmachine=private.imaging_options.ftmachine,
                                cache=private.imaging_options.cache, 
                                tile=private.imaging_options.tile,
                                gridfunction=
                                private.imaging_options.gridfunction,
                                location=private.imaging_options.location,
                                padding=private.imaging_options.padding);
        }
        myimager.setimage(nx=private.imaging_parms.nx,
                          ny=private.imaging_parms.ny, 
                          cellx=private.imaging_parms.cellx, 
                          celly=private.imaging_parms.celly, 
                          stokes=private.imaging_parms.stokes,
                          facets=private.imaging_parms.facets,
                          mode=private.imaging_parms.mode,
                          nchan=private.imaging_parms.nchan,
                          doshift=private.imaging_parms.doshift,
                          phasecenter=private.imaging_parms.phasecenter,
                          shiftx = private.imaging_parms.shiftx,
                          shifty = private.imaging_parms.shifty,
                          start =  private.imaging_parms.start,
                          step = private.imaging_parms.step
                          );

        dirtyimage:=spaste(imagename,'.dirty');
        
        if(private.sim_parms.nfields > 1)
            myimager.setvp();
        myimager.makeimage(type='corrected', image=dirtyimage);

# need this for wfclark, but comment out for now -- testing
        myimager.setmfcontrol(cyclefactor=1.5);

        mask := '';
        if(private.imaging_parms.clean_mask_type == 'comps') {
            public.makemodelimage(dirtyimage,private.model_imagename, 
	                          factor=10);
            mask := spaste(imagename,'.mask');
            res := myimager.mask(mask=mask,image=private.model_imagename,
                          threshold='1e-4Jy');
        }
        if(!private.is_single_field)
            myimager.setmfcontrol(cyclefactor=private.mfcontrol.cyclefactor,
                                  cyclespeedup=private.mfcontrol.cyclespeedup,
                                  stoplargenegatives=
                                  private.mfcontrol.stoplargenegatives,
                                  stoppointmode=
                                  private.mfcontrol.stoppointmode,
                                  scaletype=private.mfcontrol.scaletype,
                                  minpb=private.mfcontrol.minpb,
                                  constpb=private.mfcontrol.constpb);

        if(private.is_single_field) rimage := '';
        else rimage := private.restoredimage;
        if(private.deconv_function == 'clean'){
	    if(private.clean.algorithm=='multiscale' 
              ||private.clean.algorithm=='mfmultiscale' ){
 	         myimager.setscales(nscales=3) 
            }
            myimager.clean(algorithm=private.clean.algorithm,
                           niter=private.clean.niter,gain=private.clean.gain,
                           threshold=private.clean.threshold,
                           displayprogress=private.clean.displayprogress,
                           fixed=private.clean.fixed,model=imagename,
                           mask=mask,image=rimage);
        }  
        else if(private.deconv_function == 'mem') {
	  myimager.mem(algorithm=private.mem.algorithm,
		       niter=private.mem.niter,sigma=private.mem.sigma,
		       targetflux=private.mem.targetflux,
		       constrainflux=private.mem.constrainflux,image=rimage,
		       displayprogress=private.mem.displayprogress,
		       model=imagename,fixed=private.mem.fixed,mask=mask);
	}
	else if(private.deconv_function == 'nnls') {
	  include 'regionmanager.g'
	  datamask:=spaste(imagename,'.datamask');
	  myimager.regionmask(mask=datamask, region=drm.quarter());
	  fluxmask:=spaste(imagename,'.fluxmask');
	  myimager.regionmask(mask=fluxmask, region=drm.quarter());
	  myimager.nnls(model=imagename, image=rimage, 
			image=spaste(imagename,'.restored'),
			residual=spaste(imagename, '.residual'), niter=1000,
			fluxmask=mask, datamask=datamask, tolerance=1e-6)
	}
        if(private.is_single_field) {
            myimager.restore(model=imagename,image=private.restoredimage,
                             residual=spaste(imagename,'.residual'));
        }
	
        myimager.done();
        return T;
    }

    const public.getsourcebox := function() {
        include 'componentlist.g';
        include 'images.g';
        include 'quanta.g';
        wider private;
        maxra := (-1)*2*pi;
        minra := 2*pi;
        maxdec := (-1)*pi/2;
        mindec := pi/2;
        modelcl := componentlist(private.cltablename);
        for(i in 1:modelcl.length()) {
            ra := as_float(modelcl.getrefdirra(i,'rad',10));
            if(ra > maxra) maxra := ra;
            if(ra < minra) minra := ra;
            dec := as_float(modelcl.getrefdirdec(i,'rad',10));
            if(dec > maxdec) maxdec := dec;
            if(dec < mindec) mindec := dec;
        }
        minra := dq.time(dq.quantity(minra,'rad'));
        maxra := dq.time(dq.quantity(maxra,'rad'));
        mindec := dq.angle(dq.quantity(mindec,'rad'));
        maxdec := dq.angle(dq.quantity(maxdec,'rad'));
        # yes because RA increases to the *left* damn astronomers....
#        blc := spaste(maxra,' ',mindec);
#        trc := spaste(minra,' ',maxdec);
        im := image(private.imagename);
#        cs := im.coordsys();
#        worldreg := drm.wbox(blc=blc,trc=trc,pixelaxes=[1,2],csys=cs);
#        return im.boundingbox(worldreg);
        blcpix := floor(im.topixel([maxra,mindec])[1:2])-5;
        trcpix := ceil(im.topixel([minra,maxdec])[1:2])+5;
        reg := [=];
        reg.blc := blcpix;
        reg.trc := trcpix;
        return reg;
    }



    #@
    # locate the source positions in the the specified image
    #

    const public.findsource := function(numsources, imagename, clname) {
        include 'image.g';

        myim:=image(imagename);
        c_reg := [=];
        s := myim.shape();
#        print 'is singlefield ',private.is_single_field;
        if(private.is_single_field) {
            c_reg.blc[1:3] := 1;
            c_reg.trc := s[1:3];
        } else {
            note(spaste('Multifield: using a small region box to avoid ',
                        'amplified noise at the primary beam edge'));
            c_reg := public.getsourcebox();
            c_reg.blc := [c_reg.blc,1];
            c_reg.trc := [c_reg.trc,s[3]];
        }
	if(s[4] >1){
	  for (i in 1:s[4]) {
            reg := drm.box(blc=[c_reg.blc,i],trc = [c_reg.trc,i]);
            cl := myim.findsources(nmax=numsources, cutoff=0.2,region=reg);
            cl.rename(spaste(clname,'.',as_string(i)));
	    cl.done();  
	  }
	  
	}
	else{
	  cl := myim.findsources(nmax=numsources, cutoff=0.2);
	  cl.rename(spaste(clname,'.',as_string(1)));
	  cl.done();  
	}
    }

###### Compare positions between 2 component list which ideally should be very 
###### similar

    const public.sourcecompare := function(complistfound, complisttrue) {

        wider private,public;  
        # get the restoring beam
        im := image(private.restoredimage);
        nchan := im.shape()[4];
        beam := im.rb();
        bpa := dq.convert(beam.positionangle,'rad').value;
        cosbpa := cos(bpa);
        sinbpa := sin(bpa);
        bmaj := beam.major.value;
        bmin := beam.minor.value;
        beam_ra := sqrt(sinbpa*sinbpa*bmaj*bmaj + cosbpa*cosbpa*bmin*bmin); 
        beam_dec := sqrt(cosbpa*cosbpa*bmaj*bmaj + sinbpa*sinbpa*bmin*bmin); 

        private.beam := beam;
        private.beam.ra := dq.quantity(spaste(beam_ra,'arcsec'));
        private.beam.dec := dq.quantity(spaste(beam_dec,'arcsec'));

        compo_true:=componentlist(complisttrue);

        # get the image rms
        rms := public.getrms(image(private.restoredimage));


        fail_count := 0;
        pass := T;
        pass_ary := array(T,nchan,compo_true.length());
        cc := array(0,nchan,compo_true.length());
        pos_diff_ary := array(0,nchan,compo_true.length(),2);
        for (i in 1:nchan) {
            compo_found:=componentlist(spaste(complistfound,'.',as_string(i)));
            if(compo_true.length()!=compo_found.length()){
                print 'Number of found components is ',compo_found.length(),
                    '; should have been ', compo_true.length();
            }

            for (k in 1:compo_true.length()){
                dra := 100000;
                ddec := 100000;
                distmin:=100000;
                ra_true:=dq.convert( compo_true.getrefdir(k).m0, 'rad').value;
                dec_true:=dq.convert( compo_true.getrefdir(k).m1, 'rad').value;
                for(j in 1:compo_found.length()){ 
                    ra_found := dq.convert(
                                           compo_found.getrefdir(j).m0,
                                           'rad').value;
                    dec_found := dq.convert( 
                                            compo_found.getrefdir(j).m1,
                                            'rad').value;
                    dra :=  cos(dec_true)*(ra_true - ra_found);
                    ddec :=  dec_true - dec_found;
                    dist:=sqrt(dra*dra + ddec*ddec);
                    if (dist < distmin){ 
                        ddecmin := ddec;
                        dramin := dra;
                        distmin:=dist; 
                        jmin:=j;
                        cc[i,k] := jmin;
                    }
                }
                distmin_arcsec := dq.convert(distmin,'arcsec');
                ddec_arcsec := dq.convert(ddecmin,'arcsec');
                dra_arcsec := dq.convert(dramin,'arcsec');
                note(spaste('Nearest source to simulated component ', k,
                            ' is at ', 
                            distmin_arcsec, ' arcsec and is found comp ', 
                            jmin));
                note(spaste('True RA is ', 
                            dq.time([value=ra_true, unit='rad']),
                            ' Found RA is ',
                            dq.time(compo_found.getrefdir(jmin).m0)),
                     ' RA difference is ',dra_arcsec.value,' arcsec');
                pos_diff_ary[i,k,1] := dra_arcsec.value;
                note(spaste('True dec is ', 
                            dq.angle([value=dec_true, unit='rad']),
                            ' Found dec is ',
                            dq.angle(compo_found.getrefdir(jmin).m1)),
                     ' Dec difference is ',ddec_arcsec.value,' arcsec');
                pos_diff_ary[i,k,2] := ddec_arcsec.value;
                note(spaste('True flux is ', compo_true.getfluxvalue(k), 
                            compo_true.getfluxunit(k),' Found flux is ', 
                            compo_found.getfluxvalue(jmin), 
                            compo_found.getfluxunit(jmin)));
                if(abs(ddec_arcsec.value) < private.tolerance*beam_dec) {
                    note('Declination test passed');
                    pass := pass & T;
                    pass_ary[i,k] := pass_ary[i,k] && T;
                } else {
                    note('Declination test failed');
                    pass := pass & F;
                    pass_ary[i,k] := pass_ary[i,k] && F;
                }
                if(abs(dra_arcsec.value) < private.tolerance*beam_ra) {
                    note('Right ascension test passed');
                    pass := pass & T;
                    pass_ary[i,k] := pass_ary[i,k] && T;
                } else {
                    note('Right ascension test failed');
                    pass := pass & F;
                    pass_ary[i,k] := pass_ary[i,k] && F;
                }
                if(!pass) fail_count := fail_count+1;
            }
            compo_found.done();
        }
        private.corresponding_comps := cc;
        private.position_differences := pos_diff_ary;
        compo_true.done();
        return pass_ary;
    }


    const public.getcorrespondingcomps := function() {
        return private.corresponding_comps;
    }

    const public.getrms := function(im) {
        wider public;
        # image tools referenced with the $ notation must be global variables
        # due to a current bug
        global _ipt_get_rms := im;
        if(im.type() != 'image') 
            fail spaste('input is of type ',im.type(),' not image');
        # for mosaics, ignore pixels outside the primary beams
        mask := '$_ipt_get_rms < -1e-5 || $_ipt_get_rms > 1e-5';
        s := [=];
        im.stats(s,mask=mask);
        oldrms := 0;
        rms := s.rms;
        while((abs(oldrms - rms)/rms) > 0.001) {
            im.stats(s,includepix=[-3*rms,3*rms],mask=mask);
            oldrms := rms;
            rms := s.rms;
        }
        return rms;
    }

    #@
    # view the restored image
    #

    const public.view := function() {
        wider private;
        r := private.restoredimage;
        if(!dos.fileexists(r))
            fail spaste('Image ',r,' does not exist!');
        im := image(r); 
        im.view();      
        return T;
    }


### print the summary of result of the day
  const public.logresult := function(testname="", result=F, direc="", 
                                     extrainfo="") {
    success:=T
    logfile:=spaste("summary.log.", shell('date +%j'))
   if(dos.fileexists(logfile)){
     fout:=open(spaste(">> ", logfile))
   }
   else{
     fout:=open(spaste("> ", logfile))
   }
   fprintf(fout, '%s \n', "#########################################")
   fprintf(fout, 'Done with  %s \n', testname)
   for (k in 1:length(result)){
     if(!result[k]){
      fprintf(fout, '\%\%\%\%ERROR with source %i \n',  k)
      success:=F
     }
   }
   if(success){
      fprintf(fout, 'No Errors: results in %s \n', direc )
   }
   else{
      fprintf(fout, 'Check directory %s \n', direc)
   }
   fprintf(fout, '%s \n', extrainfo);
   fprintf(fout, '%s %s\n', "############", shell('date'));
   
   return logfile;  
  }

### Done function
    const public.done := function(){
        wider private, public;
        private := F;
        public  := F;
        return T;
    }

### Cleaning up 
    const public.cleanup := function(){
        include 'os.g';
        wider private;
        testdir:=private.testdir ; 
        if(dos.fileexists(testdir)) {
            note('Cleaning up directory ', testdir);
            ok := shell(paste("rm -fr ", testdir));
            if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); };
        } else note(spaste(testdir,' does not exist. No cleanup necessary'));
	ok := shell(paste("mkdir", testdir));
        if (ok::status) { throw("mkdir", testdir, "fails!") };
        return T;
    }
    if(clean) public.cleanup();


    return ref public;

}
