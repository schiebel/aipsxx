# bimacalibrater.g: A tool for calibration of bima data
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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

include 'bimams.g';
include 'bimacalfluxtable.g';
include 'calibrater.g';
include 'imager.g';
include 'itemcontainer.g';
include 'table.g';

#@
# not to be called directly by users
# @param cals array of calibrater ms names
# @param targets array of target (ie what the calibration will be applied to)
#        ms names 

const _define_bimacalibrater := function(targets,targetnames,phcals,phcalnames,
                                         pbcals,pbcalnames,fcals,fcalnames) {

    private := [=];
    public := [=];

    # these are used to describe the current state of the tool
    # (ie what has been done so far). The current state is held in 
    # private.state

    const private.CONSTRUCTED := 0;
    const private.SETJY := 10;
    const private.SETDATA := 20;
    const private.SETSOLVE := 30;
    const private.SOLVE := 40;
    const private.FIT := 50;
    const private.TRANSFER := 60;
    const private.SETAPPLY := 70;
    const private.CORRECT := 80;

    private.targetnames := targetnames;
    private.phcalnames := phcalnames;
    private.fcalnames := fcalnames;
    private.pbcalnames := pbcalnames;
    private.targets := targets;
    private.phcals := phcals;
    private.fcals := fcals;
    private.pbcals := pbcals;
    private.calibraters := [=];
    private.bimamss := [=];
    private.table := [=];
    private.table.cal := unset;
    private.table.xfer := unset;
    private.reservednames := ['all','targets','phcals','fcals','pbcals'];
    private.state := private.CONSTRUCTED;

    if(len(targets) != len(targetnames))
        fail(spaste('The length of the targets and targetnames arrays must ',
                    'be identical'));
    if(len(phcals) != len(phcalnames))
        fail(spaste('The length of the phcals and phcalnames arrays must be ',
             'identical'));
    if(len(pbcals) != len(pbcalnames))
        fail(spaste('The length of the pbcals and pbcalnames arrays must be ',
             'identical'));
    if(len(fcals) != len(fcalnames))
        fail(spaste('The length of the fcals and fcalnames arrays must be ',
             'identical'));


    const private.setsources := function(role,mss,names) {
        wider private;
        if(len(names) != len(mss)) 
            fail 'The mss and names vectors must be of the same length';
        for(i in (1:len(names))) {
            if(has_field(private.calibraters,names[i])) {
                private.calibraters[names[i]]::roles := 
                    [private.calibraters[names[i]]::roles,role];
            } else {
                if(any(private.reservednames == names[i]))
                    fail spaste(names[i] ,' is a reserved name. Please ',
                                'choose another nickname');
                    bm := bimams(mss[i]);
                    if(is_fail(bm)) 
                        fail spaste('Failed to create bimams tool for ',
                                    mss[i]);
                    private.bimamss[names[i]] := bm;
                    private.calibraters[names[i]] := unset;
                    private.calibraters[names[i]]::msname := mss[i];
                    private.calibraters[names[i]]::roles := role;
                }
        }
        return T;
    }

    #@
    # get (and create if necessary) a calibrater tool for the specified source
    # @param source the name of the source for which to get the calibrater tool
    # @param selectwb if 1 set initial data selection to wide band data only,
    #        if 0, set no selection, if 2 let function decide, it will select
    #        wideband data only for fcals and phcals, all data for other
    #

    const private.calibrater := function(source,selectwb = 2) {
        wider private;
        if(is_unset(private.calibraters[source])) {
            note(spaste('Creating calibrater tool for ',
                        private.calibraters[source]::msname),
                 origin='bimacalibrater');
            # get the widebnad windows before creating the calibrater tool
            # to avoid table sync problems
            if(selectwb == 0) dowbselection := F;
            else if(selectwb == 1) dowbselection := T;
            else if(selectwb == 2) {
                if(any(private.calibraters[source]::roles == 'targets') || 
                   any(private.calibraters[source]::roles == 'bpcals'))
                    dowbselection := F;
                else dowbselection := T;
            }
            wbs := unset;
            if(dowbselection) {
                wbs := private.bimamss[source].ddids(
                                       private.bimamss[source].spwids('s'));
            }
            c := calibrater(private.calibraters[source]::msname);
            # need to pass along the attriubtes explicitly
            c:: := private.calibraters[source]::;
            if(is_fail(c)) fail;
            private.calibraters[source] := c;
            if(!is_unset(wbs) && len(wbs) > 0) {
                # queries must be made using 0 based values
                bc_wbs := wbs - 1;
                q := spaste('DATA_DESC_ID IN ',
                            private.vec2string(bc_wbs));
                private.calibraters[source].setdata(msselect=q);
                note(spaste('Setting initial data selection to use ',
                            'wideband data only, (zero based) ',
                            'DATA_DESC_IDs ',
                            bc_wbs,'.'),origin='bimacalibrater');
                note('Can be overridden by running setdata()',
                     origin='bimacalibrater');
            } else if (is_unset(wbs))
                note(spaste('No initial data selection performed'),
                     origin='bimacalibrater');
            else
                note(spaste('No sidbeband averages found, no initial ',
                            'data selection performed'),
                     origin='bimacalibrater');
        }
        return ref private.calibraters[source];
    }

    #@
    # get the source names for the specified role(s) or source nickname(s)
    # @param sources the roles or source nickname(s) for which to get the 
    # source nicknames
    #

    const public.getsourcenames := function(sources='all') {
        wider private;
        sources := unique(sources);
        new_sources := [];
        allnames := [];
        if(!is_unset(private.targetnames))
            allnames := [allnames,private.targetnames];
        if(!is_unset(private.phcalnames))
            allnames := [allnames,private.phcalnames];
        if(!is_unset(private.pbcalnames))
            allnames := [allnames,private.pbcalnames];
        if(!is_unset(private.fcalnames))
            allnames := [allnames,private.fcalnames];

        if(any(sources == 'all')) return allnames;
        else 
            for (i in 1:len(sources)) {
                if(sources[i] == 'phcals') {
                    if(!is_unset(private.phcalnames))
                        new_sources := [new_sources,private.phcalnames];
                } else if(sources[i] == 'targets') {
                    if(!is_unset(private.targetnames)) 
                        new_sources := [new_sources,private.targetnames];
                } else if(sources[i] == 'fcals') {
                    if(!is_unset(private.fcalnames)) 
                        new_sources := [new_sources,private.fcalnames];
                } else if(sources[i] == 'pbcals') {
                    if(!is_unset(private.pbcalnames)) 
                        new_sources := [new_sources,private.pbcalnames];
                } else if(!any(allnames == sources[i])) 
                    fail(spaste(sources[i],' is not a valid source nick name ',
                                'nor role! ',
                                'Allowed roles are ',private.reservednames));
                else
                    new_sources := [new_sources,sources[i]];
            }
        return unique(new_sources);
    }

    #@
    # set the model for the specified sources
    # @param sources list of the sources to manipulate ('phcals' all phase 
    #        cals, 'targets' all targets, 'all' all sources, or a list of
    #        source names used when constructing this tool
    # @param fieldid the field id passed to setjy 
    # @param spwid the spwid passed to setjy
    # @param fluxdensity the flux density passed to setjy, if < 0, 
    #        lookup the source's flux in 
    #        $aipsroot/data/bima/calibration/mmCalsFluxes.tbl using nearest
    #        in time algorithm.  If source isn't there, set unpolarized 
    #        fluxdensity to 1 Jy.
    #

    const public.setjy := function(sources='phcals',fieldid=-1, spwid=-1, 
                                   fluxdensity=-1) {
        wider public,private;
        sources := public.getsourcenames(sources);
        if(is_fail(sources)) fail;
        for(s in sources) {
            if(fluxdensity < 0) {
                sname := private.bimamss[s].sourcenames();
                if(len(sname) > 1) {
                    note(spaste(s,' is a multisource dataset. setjy ',
                                'cannot handle these when looking up source ',
                                'flux densities. Setting flux density to 1 Jy')
                         ,origin='bimacalibrater.setjy', priority='SEVERE');
                    public.setjy(s,fieldid,spwid,1);
                }
                tra := private.bimamss[s].timerange();
                span := dq.quantity(tra.max.value-tra.min.value,tra.max.unit);
                span := dq.convert(span,'s');
                if(span.value > 86400*10) 
                    note(spaste('The time range in measurement set ', 
                                private.bimammss[s].ms().name(),' spans more ',
                                'than 10 days. Be aware that using a single ',
                                'flux density value for such a large time ',
                                'range may not be a good thing to do'),
                         ,origin='bimacalibrater.setjy', priority='WARN');
                fieldid := private.bimamss[s].fieldids(sname)-1;
                bcft := bimacalfluxtable();
                nt := dq.quantity((tra.max.value + tra.min.value)/2,
                                  tra.max.unit);
                flux := bcft.nearestflux(sname,nt);
                note(spaste('Using ',flux.flux,' Jy at ',flux.freq,' GHz ',
                            'measured on ',
                            dq.time(dq.quantity(flux.obsdate,'d'),form='ymd')),
                     origin='bimacalibrater.setjy',priority='NORMAL');
                fluxdensity := flux.flux;
            }
            im := imager(private.calibraters[s]::msname);
            if(is_fail(im)) fail;
            ok := im.setjy(fieldid,spwid,fluxdensity);
            if(is_fail(ok)) fail;
            im.done();
        }
        private.state := private.SETJY;
        return T;
    }

    #@
    # wrapper around calibrater.setdata()
    # the specified sourcenames will be used to determine the appropriate 
    # field ids which will be ANDed with with anything specified in the 
    # msselect string

    const public.setdata := function(sources='phcals',mode='none',nchan=1,
                                     start=1,step=1,mstart='0km/s',
                                     mstep='0km/s', uvrange=0,sourcenames=' ',
                                     msselect=' ') {
        wider public,private;
        sources := public.getsourcenames(sources);
        if(is_fail(sources)) return throw(sources::message);
        final_res := T;
        for(s in sources) {
            c := private.calibrater(s,0);
            if(is_fail(c)) return throw(c::message);
            if(sourcenames != ' ') {
                st := table(spaste(c::msname,'/SOURCE'));
                if(is_fail(st)) return throw(st::message);
                slist := st.getcol('NAME');
                for(sn in sourcenames) {
                    if(!any(slist == sn)) fail spaste('Source ',sn,' does ',
                                                      'not exist in the ',
                                                      c::msname,' SOURCE ',
                                                      'subtable!');
                }
                s_ids := st.getcol('SOURCE_ID');
                st.done();
                ft := table(spaste(c::msname,'/FIELD'));
                if(is_fail(ft)) return throw(ft::message);
                ft_sids := ft.getcol('SOURCE_ID');
                fids := [];
                for (i in s_ids) {
                    # one based here
                    fids := [fids,ind(ft_sids)[ft_sids==i]];
                }
                ft.done();
                # the field ids are zero based in the ms
                fids := fids - 1;
                fid_part := spaste('FIELD_ID IN ',fids);
                if(msselect == ' ') msselect := fid_part;
                else msselect := spaste(msselect,' && ',fid_part);
            }
            if(msselect != ' ')
                note(spaste('selection is ',msselect),origin='bimacalibrater');
            ok := c.setdata(mode,nchan,start,step,mstart,mstep,uvrange,
                            msselect=msselect);
            if(is_fail(ok)) 
                fail spaste('Running of setdata on ', c::msname,
                            ' failed.\nThe message was',ok::message);
            final_res := final_res && ok;
        }
        if(final_res) private.state := private.SETDATA;
        return final_res;
    }

    #@
    # wrapper around calibrater.setsolve()

    const public.setsolve := function(sources='phcals',type=' ',t=60,
                                      preavg=60,phaseonly=F,refant=-1,
                                      table='',append=F) {
        wider public,private;
        sources := public.getsourcenames(sources);
        if(is_fail(sources)) return throw(sources::message);
        if(is_unset(table) || table == '') {
            tmp := spaste(tr('[A-Z]','[a-z]',type),'cal');
	    table := tmp;
	    i := 1;
            while(dos.fileexists(table)) {
	        i := i+1;
                table := spaste(tmp,'.',i);
            }
        }
        final_res := T;
        for(s in sources) {
            c := private.calibrater(s);
            if(is_fail(c)) return throw(c::message);
            ok := c.setsolve(type,t,preavg,phaseonly,refant,table,append);
            if(is_fail(ok)) return throw(ok::message);
            final_res := final_res && ok;
        }
        private.table.cal := table;
        if(final_res) private.state := private.SETSOLVE;
        return final_res;
    }

    #@ wrapper around calibrater.solve()
    #

    const public.solve := function(sources='phcals') {
        wider public,private;
        sources := public.getsourcenames(sources);
        if(is_fail(sources)) return throw(sources::message);
        final_res := T;
        for(s in sources) {
            c := private.calibrater(s);
            if(is_fail(c)) return throw(c::message);
            ok := c.solve();
            if(is_fail(ok)) fail spaste('calibrater.solve() on ',c::msname,
                                        'failed.\nThe message was ',
                                        ok::message);
            final_res := final_res && ok;
        }
        # write spw info as a keyword into the calibration table
        if(final_res) {
            s := sources[1];
            msname := private.calibraters[s]::msname;
            spwt := table(spaste(msname,'/SPECTRAL_WINDOW'));
            if(is_fail(spwt))
                note(spaste('Failed to open spectral window table of ',
                            msname), priority='WARN',origin='bimacalibrater');
            else {
                spwinfo := [=];
                spwinfo.NET_SIDEBAND := spwt.getcol('NET_SIDEBAND');
                spwinfo.FREQ_GROUP_NAME := spwt.getcol('FREQ_GROUP_NAME');
                spwt.done();
                calt := table(private.table.cal,readonly=F);
                
                ok := calt.putkeyword('SPW_INFO',spwinfo);
                if(!ok) note(spaste('Put of spectral window info into ',
                                    private.table.cal,' failed'),
                             priority='WARN',origin='bimacalibrater');
                calt.done();
            }
        }
        if(final_res) private.state := private.SOLVE;
        return final_res;
    }                           

    #@
    # convert an array of numbers to a string that can be used by msslect
    # parameter in setdata
    
    private.vec2string := function (invec) {
        if(len(invec) == 1) return as_string(invec);
        pos := 1;
        out := '[';
        for(i in invec) {
            if(pos < len(invec)) out := spaste(out,as_string(i),',');
            else out := spaste(out,i);
            pos +:= 1;
        }
        out := spaste(out,']');
        return out;
    }

    #@
    # fit the calibration solutions using gainpolyfitter
    # @param table the calibration table
    #
    
    public.fit := function(table = '') {
        wider private;
        if(is_unset(table || table == '') ) {
            if(is_unset(private.table.cal))
                fail ('You must specify a calibration table or run setsolve');
            else
                table := private.table.cal;
        }
        include 'gainpolyfitter.g';
        g := gainpolyfitter();
        x := g.gui(table);
        note('The GUI will run asynchronously. Be sure you have completed'
             ,origin='bimacalibrater');
        note('all fitting and have saved the results before moving on to the'
             ,origin='bimacalibrater');
        note('next step.',origin='bimacalibrater');
        private.state := private.FIT;
        return T;
    }

    #@ transfer the solutions to another table of the correct dimensionality
    # so they can be applied to the targets
    # @param intable if not specified will use the table specified when
    #        setsolve was run, if unspecified, the table written by
    #        .solve() will be used
    # @param intable the table to get the solutions from
    # @param the table to which to transfer and write the solutions
    # @param spwmap array of ints describing how the input windows should
    #        be mapped to the output windows.  If not specified, the function
    #        tries to guess the mapping, and should currently be accurate 
    #        if the input contains lower and upper sideband averages only
    #        The array is 1-based, negative values are not allowed and
    #        values of 0 have the special effect that the gains for those
    #        windows are set to 0 (no transfer is done).
    # @param calibratees array of labels (strings) for the sources to which
    #        the transferred solutions will be applied
    # @param forcecopy force the table to be copied even if no copy is 
    #        necessary

    const public.transfer := function(outtable='',intable='',spwmap = unset,
                                      calibratees='targets',forcecopy=T) {
        wider private,public;
        guess_spw_map := is_unset(spwmap) || len(spwmap) == 0;
#	note(guess_spw_map);
        sources := public.getsourcenames(calibratees);
        if(is_fail(sources)) fail;
        if(is_unset(intable) || intable == '') {
            if(is_unset(private.table.cal)) 
                fail(spaste('You must specify a value for intable (or run ',
                            'setsolve())'));
            else intable := private.table.cal;
        }
        if(is_unset(outtable) || outtable == '') 
            outtable := spaste(intable,'.xfer');
        c_caldesc := spaste(intable,'/CAL_DESC');
        c_caldesc_t := table(c_caldesc);
        if(is_fail(c_caldesc_t))
            fail(spaste('Unable to open ',c_caldesc,'. Did you run solve()?'));
        c_spwids := c_caldesc_t.getcell('SPECTRAL_WINDOW_ID',1) + 1;
        c_caldesc_t.done();
#        note(spaste('c_spwids ', c_spwids));
        for(s in sources) {
            bm := private.bimamss[s];
            nspw := bm.nspw();
            note(spaste(nspw,' spectral windows found in ',s,' dataset')
                 ,origin='bimacalibrater');
            if(guess_spw_map) {
                if(len(c_spwids) == 1) {
                    note('Only one spectral window in the input calibration ',
                         'table.  I will assume that it\'s solutions are ',
                         'valid for all windows in the datasets to be ',
                         'calibrated',priority='WARN',origin='bimacalibrater');
                    spwmap := array(1,nspw);
                } else {
                    c_table := table(intable);
                    spw_info := c_table.getkeyword('SPW_INFO');
                    c_table.done();
                    if(is_fail(spw_info)) {
                        if(len(c_spwids) == 2 ) {
                            note(spaste('Failed to find SPW_INFO keyword in ',
                                        intable), priority='WARN',
                                 origin='bimacalibrater');
                            note(spaste('But found two spectral windows. ',
                                        'Assuming the first is the'),
                                 priority='WARN'
                                 ,origin='bimacalibrater');
                            note('LSB and the second is the USB',
                                 priority='WARN'
                                 ,origin='bimacalibrater');
                            ns := [-1,1];   
                            ind_ns := ind(ns);
                        } else
                            fail(spaste('If you don\'t specify spwmap or ',
                                        'run bimacalibrater.solve() to ',
                                        'create the input table, I can only ',
                                        'make educated guesses about an ',
                                        'input calibration table with 1 or 2 ',
                                        'spectral windows'));
                    } else {        
                        fg := spw_info.FREQ_GROUP_NAME;
                        ns := spw_info.NET_SIDEBAND;
                        ind_ns := ind(ns)[fg == 'SIDEBAND-AVG'];
                        ns := ns[fg == 'SIDEBAND-AVG'];
                        if(any(ns != [-1,1]) && any(ns != [1,-1]))
                            fail(spaste('net sidebands from ',intable,' are ',
                                        ns,'. I don\'t know how to deal ',
                                        'with this configuration'));
                        else {
                            note(spaste('Found USB and LSB windows in ',
                                        intable),origin='bimacalibrater');
                            note(spaste('The NET_SIDEBAND values are ',ns)
                                 ,origin='bimacalibrater');
                        }
                    }
                    spwmap := array(0,nspw);
                    sbs := bm.sb(1:nspw);
                    for(i in ind(sbs)) {
                        for(j in ind(ns)) {
                            if(sbs[i] == ns[j]) {
                                spwmap[i] := ind_ns[j];
                                break;
                            }
                        }
                    }
                    note(spaste('Sideband codes are ',sbs),
                         origin='bimacalibrater');
                }
            } else {          
                if(nspw != len(spwmap)) {
                    fail(spaste('Number of windows in dataset to be ',
                                'calibrated is ',nspw,'. Number of elements ',
                                'spw_map input is ',len(spwmap),'. These ',
                                'two values must be the same'));
                }
            }
            if(guess_spw_map)
                note(spaste('My best guess for spwmap is ',spwmap)
                     ,origin='bimacalibrater');
            else 
                note(spaste('User specified spwmap is ',spwmap)
                     ,origin='bimacalibrater');
#            note('c_spwids ',c_spwids,' spwmap ',spwmap);
            if(len(c_spwids) == len(spwmap) && all(c_spwids == spwmap) 
               && !forcecopy ) {
                note(spaste('No copy necessary. You can correct the ',s,
                            ' dataset using ',intable),
                     origin='bimacalibrater');
                private.table.xfer := intable;
                next;
            }
            note('Copying ',intable,' to ',outtable,origin='bimacalibrater');
            tablecopy(intable,outtable);
            cd := table(spaste(outtable,'/CAL_DESC'),readonly=F);
            if(is_fail(cd)) fail(spaste('Error opening ',outtable,'/CAL_DESC ',
                                        'for writing'));
            ok := cd.putcol('NUM_SPW',nspw);

            if(!ok) fail('Couldn\'t put the NUM_SPW value');
            ok := cd.removecols('SPECTRAL_WINDOW_ID');
            if(!ok) fail('Couldn\'t remove the SPECTRAL_WINDOW_ID column');
            desc := tablecreatearraycoldesc('SPECTRAL_WINDOW_ID',[1:nspw],
                                            shape=nspw,
                                            comment=spaste('Created by ',
                                                 'bimacalibrater.transfer()'));
            ok := cd.addcols(desc);
            if(!ok) fail('Failed to add column SPECTRAL_WINDOW_ID');
            ok := cd.putcell('SPECTRAL_WINDOW_ID',1,[1:nspw]);
            if(!ok) fail('Failed to putcell in SPECTRAL_WINDOW_ID');
            cd.done();
            main := table(outtable,readonly=F);
            gain := main.getcol('GAIN');
            gs := gain::shape[1:3];
            gs[3] := nspw;
            gdesc := tablecreatearraycoldesc('GAIN',as_complex(0),shape=gs,
                              comment='Created by bimacalibrater.transfer()');
            ngain := array(gain[1],gs[1],gs[2],gs[3],gain::shape[4]);
            sok := main.getcol('SOLUTION_OK');
            ss := nspw;
            sdesc := tablecreatearraycoldesc('SOLUTION_OK',T,shape=ss,
                              comment='Created by bimacalibrater.transfer()');
            nsok := array(sok[1],ss,sok::shape[2]);
            fit := main.getcol('FIT');
            fs := nspw;

            fdesc := tablecreatearraycoldesc('FIT',as_float(0),shape=fs,
                               comment='Created by bimacalibrater.transfer()');
            nfit := array(fit[2],fs,fit::shape[2]);

            fw := main.getcol('FIT_WEIGHT');
            ws := nspw;
            wdesc := tablecreatearraycoldesc('FIT_WEIGHT',as_float(0),
                                             shape=nspw,
                               comment='Created by bimacalibrater.transfer()');
            nfw := array(fw[1],nspw,fw::shape[2]);

            ngain[,,seq(nspw)[spwmap>0],] := gain[,,spwmap[spwmap>0],];
            nsok[seq(nspw)[spwmap>0],] := sok[spwmap[spwmap>0],];
            nfit[seq(nspw)[spwmap>0],] := fit[spwmap[spwmap>0],];
            nfw[seq(nspw)[spwmap>0],] := fw[spwmap[spwmap>0],];
            
            # set stuff to 0 if 0 specified by user in spwmap

            ngain[,,seq(nspw)[spwmap==0],] := 0;
            nsok[seq(nspw)[spwmap==0],] := T;
            # is 1 ok for defaults for FIT and FIT_WEIGHT? question for 
            # Athol
            nfit[seq(nspw)[spwmap==0],] := 1;
            nfw[seq(nspw)[spwmap==0],] := 1;

            ok := main.removecols(['GAIN','SOLUTION_OK','FIT','FIT_WEIGHT']);
            if(!ok) fail('Failed to remove columns from main table');

            desc := tablecreatedesc(gdesc,sdesc,fdesc,wdesc);
            ok := main.addcols(desc);
            if(!ok) fail('Failed to add column descriptors');

            ok := main.putcol('GAIN',ngain);
            if(!ok) fail('Failed to put GAIN values');
            ok := main.putcol('SOLUTION_OK',nsok);
            if(!ok) fail('Failed to put SOLUTION_OK values');
            ok := main.putcol('FIT',nfit);
            if(!ok)fail('Failed to put FIT values');
            ok := main.putcol('FIT_WEIGHT',nfw);
            if(!ok) fail('Failed to put FIT_WEIGHT values');
            main.done();
            private.table.xfer := outtable;
        }                
        private.state := private.TRANSFER;
        return T;
    }

    const public.setapply := function (sources = 'targets',type='G',t=0,
                                       table=unset,select=' ') {
        wider private,public;
        sources := public.getsourcenames(sources);
        if(is_fail(sources)) fail;
        if(is_unset(table)) {
            if(is_unset(private.table.xfer)) {
                if(is_unset(private.table.cal)) 
                    fail(spaste('You must specify a value for intable (or ',
                                'run solve() and/or transfer())'));
                else table := private.table.cal;
            } else table := private.table.xfer;
        }
        final_res := T;
        for(s in sources) {
            c := private.calibrater(s);
            if(is_fail(c)) fail;
            ok := c.setapply(type=type,t=t,table=table,select=select);
            if(is_fail(ok)) fail;
            final_res := final_res && ok;
        }
        if(final_res) private.state := private.SETAPPLY;
        return final_res;
    }
        
    const public.correct := function (sources = 'targets') {
        wider private,public;
        sources := public.getsourcenames(sources);
        if(is_fail(sources)) fail;
        final_res := T;
        for(s in sources) {
            c := private.calibrater(s);
            if(is_fail(c)) fail;
            ok := c.correct()
            if(is_fail(ok)) fail;
            final_res := final_res && ok;
        }
        if(final_res) private.state := private.CORRECT;
        return final_res;
    }

    const public.type := function() {
        return 'bimacalibrater';
    }

    const public.done := function() {
        wider private, public;
        for (s in field_names(private.calibraters)) {
            if(!is_unset(private.calibraters[s]))
                private.calibraters[s].done();
        }
        for (s in field_names(private.bimamss)) {
            if(!is_unset(private.calibraters[s]))
                private.bimamss[s].done();
        }
        private := F;
        val public := F;
        return T;
    }

    #@
    # add specified targets to the targets list
    # @param mss an array of target measurement sets
    # @param names an array of target nicknames (defaults to ms names if 
    #        unspecified)
    #

    const public.addtargets := function(mss,names=unset) {
        wider private;
        if(is_unset(names)) names := mss;
        ok := private.setsources('targets',mss,names);
        if(is_fail(ok)) fail;
        return ok;
    }

    #@ 
    # close the specified calibrater tools
    # @param sources close the tools of the MSs corresponding to these 
    # sources (or roles)  

    const public.close := function(sources) {
        wider public;
        sources := public.getsourcenames(sources);
        if(is_fail(sources)) return throw(sources::message);
        for(s in sources) {
            c := ref private.calibraters[s];
            if(!is_unset(c) && has_field(c,'type') && 
               c.type() == 'calibrater') {
                note(spaste('Closing calibrater tool for ',c::msname),
                     origin='bimacalibrater');
                c.close();
            }
        }
        return T;
    }

    #@
    # just wraps calibrater.plotcal() 
  
    const public.plotcal := function(sources = 'phcals', plottype = 'AMP',
                                     tablename = '', antennas = [], 
                                     fields = [], polarization = 1, 
                                     spwids = [], timeslot = 1, multiplot = F,
                                     nx=1, ny=1,psfile='') {
        wider public;
        if(tablename == '') tablename := private.table.cal;
        note(tablename);
        sources := public.getsourcenames(sources);
        if(is_fail(sources)) fail;
        final_res := T;
        for(s in sources) {
            c := private.calibrater(s);
            ok := c.plotcal(plottype,tablename,antennas,fields,polarization,
                            spwids,timeslot,multiplot,nx,ny,psfile);
            final_res := final_res && ok;
        }
        return final_res;
    }

    if(!is_unset(targets)) {
        ok := private.setsources('targets',targets,targetnames);
        if(is_fail(ok)) return throw (spaste('Failure setting up targets ',
                                            ok::message));
    }

    if(!is_unset(phcals)) {
        ok := private.setsources('phcals',phcals,phcalnames);
        if(is_fail(ok)) return throw (spaste('Failure setting up phase ',
                                            'calibrators ',ok::message));
    }

    if(!is_unset(pbcals)) {
        ok := private.setsources('pbcals',pbcals,pbcalnames);
        if(is_fail(ok)) return throw (spaste('Failure setting up phase ',
                                            'calibrators ',ok::message));
    }

    if(!is_unset(fcals)) {
        ok := private.setsources('fcals',fcals,fcalnames);
        if(is_fail(ok)) return throw (spaste('Failure setting up flux ',
                                            'calibrators ',ok::message));
    }

    #@
    # print of summary of this tool

    const public.summary := function() {
	wider private;
        note(spaste('targets:     ',private.targets),origin='bimacalibrater');
        note(spaste('targetnames: ',private.targetnames),
             origin='bimacalibrater');
        note(spaste('phcals :     ',private.phcals),origin='bimacalibrater');
        note(spaste('phcalnames:  ',private.phcalnames),
             origin='bimacalibrater');
        note(spaste('pbcals :     ',private.pbcals),origin='bimacalibrater');
        note(spaste('pbcalnames:  ',private.pbcalnames),
             origin='bimacalibrater');
        note(spaste('fcals :      ',private.fcals),origin='bimacalibrater');
        note(spaste('fcalnames:   ',private.fcalnames),
             origin='bimacalibrater');
	note(spaste('cal table:   ',private.table.cal),
             origin='bimacalibrater');
	note(spaste('xfer table:  ',private.table.xfer),
             origin='bimacalibrater');
        return T;
    }
    return ref public;
}

#@
# constructor users should call
# @param phcals array of phase calibrator ms names
# @param targets array of target ms names
#

const bimacalibrater := function(targets=[' '],phcals=[' '],pbcals=[' '],
                                 fcals=[' '],targetnames=unset,
                                 phcalnames=unset,pbcalnames=unset,
                                 fcalnames=unset
                                 ) {
    
    if(targets == [' ']) targets := unset;
    if(phcals == [' ']) phcals := unset;
    if(pbcals == [' ']) pbcals := unset;
    if(fcals == [' ']) fcals := unset;
    if(is_unset(targets) && is_unset(phcals) && is_unset(pbcals) 
       && is_unset(fcals))
        fail spaste('At least one of targets, phcals, pbcals, or fcals must ',
                    'be specified.');
    if(is_unset(targetnames)) targetnames := targets;
    if(is_unset(phcalnames)) phcalnames := phcals;
    if(is_unset(pbcalnames)) pbcalnames := pbcals;
    if(is_unset(fcalnames)) fcalnames := fcals;
    return _define_bimacalibrater(targets,targetnames,phcals,phcalnames,pbcals,
                                  pbcalnames,fcals,fcalnames);
}

const bimacalibratertest := function(verbose=1, modelcaltable='', 
                                     modeldatatable='') {
    include 'bimacalibratertester.g';
    bct := bimacalibratertester(verbose);
    bct.setoptions(modelcaltable=modelcaltable, modeldatatable=modeldatatable);
    return bct.runtests();
}
