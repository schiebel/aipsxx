# bimams.g: a helper tool for BIMA measurement sets
#
#   Copyright (C) 1998,1999,2000,2002
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

pragma include once;

include 'ms.g';
include 'note.g';
include 'os.g';
include 'quanta.g';

const _define_bimams := function(mstool) {

    private := [=];
    private.mstool := mstool;
    private.table := [=];
    private.table.main := unset;
    private.table.dd := unset;
    private.table.doppler := unset;
    private.table.field := unset;
    private.table.polar := unset;
    private.table.source := unset;
    private.table.spw := unset;
    private.table.syscal := unset;
    private.spw := [=];
    private.spw.cw := [=];
    private.spw.cw.indices := [=];
    private.spw.cw.indices.ordered := unset;
    private.spw.cw.reffreq := unset;
    private.spw.cw.startfreq := unset;
    private.spw.cw.endfreq := unset;
    private.spw.cw.chanwidths := unset;
    private.spw.chans := [=];
    private.spw.chans.start := unset;
    private.spw.chans.nchan := unset;
    private.spw.chans.nchan := unset;
    const private.sba := 'SIDEBAND-AVG';
    const private.mcd := 'MULTI-CHANNEL-DATA';
    const private.mca := 'MULTI-CHANNEL-AVG';


    public := [=];

    ######################### private functions ######################
    

    ###################### public functions #######################

    # get a vector of the channel widths for the the specified window type
    # type type of window 's' sideband-avg, 'c' multi-channel-data, 'a'
    #        multi-channel-avg
    # @return a vector of channel widths in the order they appear in the
    # SPECTRAL_WINDOW table, the length of this vector is equal to the number
    # of windows given by the type
    
    const public.chanwidths := function(type='c') {
	wider private;
        # this needs to be fixed up a bit but it works for now
        if(type == 'c') {
            if(is_unset(private.spw.cw.chanwidths)) 
                private.spw.cw.chanwidths := 
                    public.get_values('CHAN_WIDTH',1,type);

            return private.spw.cw.chanwidths;
        }
        else 
            return public.get_values('CHAN_WIDTH',1,type);
    }

    ##
    # the the channel widths for the spectral windows referred to by the
    # specified 1-based data description ids
    # @param the 1-based data description ids to get the chan widths for
    # @return the channel widths associated witht the specified data 
    #         description ids

    const public.chanwidthsddids := function(ddids) {
        wider public;
        spwids := public.ddids_spw(ddids);
        cw := public.chanwidths();
        return cw[spwids];
    }

    # get the data description ID (the 1-based row) from the DATA_DESCRIPTION
    # table
    # @param the 1-based spectral window ID
    # @param stokes the stokes parameter, not used of polid is given 
    # @param polid the 1-based polariztion id from the POLARIZATION table,
    #        if not given stokes is used, if given overrides stokes
    # @return the 1-based data description id, -1 if not found

    const public.ddid := function(spwid,stokes='YY',polid=unset) {
        wider public;
        if(!is_unset(polid)) {
            if(!is_integer(polid) || polid <= 0)
                return throw('polid must be an integer > 0');
        } else if(is_string(stokes))
            polid := public.polarids(stokes);
        else if(is_unset(stokes))
            return throw('Either polid or stokes must be specified');
        else return throw('stokes must be a string');
        t := public.ddtable();
        cpolid := t.getcol('POLARIZATION_ID');
        cspwid := t.getcol('SPECTRAL_WINDOW_ID');
        # values in cpolid and cspwid are zero based
        for(i in ind(cpolid)) {
            if((cpolid[i]+1) == polid && (cspwid[i]+1) == spwid)
                return i;
        }
        return -1;
    }

    ##
    # get a vector of 1-based data description ids based on a vector of
    # spectral window ids and a vector of polarization ids.  The spectral
    # window and polarization ids vectors are or-ed within themselves and then
    # and-ed with each other
    # @param spwids vector of 1-based spectral window ids
    #               if unset all spectral windows are used
    # @param polids vector of 1-based polarization ids, 
    #        if unset all polarizations are used

    const public.ddids := function(spwids = unset, polids = unset) {
        wider public;
        t := public.ddtable();
        if(is_fail(t)) fail;
        if(is_unset(spwids) && is_unset(polids))
            return 1:t.nrows();
        if(is_unset(spwids)) spwids := seq(public.nspw());
        if(is_unset(polids)) polids := seq(public.npol());
        cpolid := t.getcol('POLARIZATION_ID');
        cspwid := t.getcol('SPECTRAL_WINDOW_ID');
        # values in cpolid and cspwid are zero based
        ids := [];
        for(i in ind(cpolid)) {
            if(any(polids == cpolid[i]+1) && any(spwids == cspwid[i]+1))
                ids[len(ids)+1] := i;
        }
        return ids;
    }

    ##
    # get a list of 1-based spectral window ids associated with the
    # specified 1-based list of data description ids
    # @param ddids the 1-based list of data desc ids 
    # @return a 1-based list of spectral window ids

    const public.ddids_spw := function(ddids) {
        wider public;
        ddt := public.ddtable();
        if(is_fail(ddt)) fail;
        zballspwids := ddt.getcol('SPECTRAL_WINDOW_ID');
        obspwids := zballspwids[ddids] + 1;
        return obspwids;
    }


    # get the DATA_DESCRIPTION table associated with the ms
    # @return the DATA_DESCRIPTION table as a table tool

    const public.ddtable := function() {
	wider private,public;
	if(is_unset(private.table.dd)) {
	    t := public.subtable('DATA_DESCRIPTION');
	    if(is_fail(t)) {
		note('Error creating DATA_DESCRIPTION table from ms.',
		     priority='SEVERE',origin='bimams');
		return throw(t::message);
	    }
            private.table.dd := t;
	}
	return private.table.dd;
    }

    # done with this tool

    const public.done := function() {
        wider private,public;
        public.ms().done();
        note('Closing tables....',origin='bimams');
        for(f in field_names(private.table)) {
            if(is_table(private.table[f])) 
                private.table[f].done();
        }
        private := F;
        val public := F;
        return T;
    }


    # get the doppler table associated with the ms
    # @return the doppler table
    
    const public.doptable := function() {
	wider private,public;
	if(is_unset(private.table.doppler)) {
	    t := public.subtable('DOPPLER');
	    if(is_fail(t)) {
		note('Error creating doppler table from ms.',
		     priority='SEVERE', origin='bimams');
		return throw(t::message);
	    }
            private.table.doppler := t;
	}
	return private.table.doppler;
    }

    # get a vector of the start frequencies for the multichannel data
    # @return a vector of start frequencies in the order they appear in the
    # SPECTRAL_WINDOW table
    
    const public.endfreqs := function() {
	wider private;
	if(is_unset(private.spw.cw.endfreq)) {
	    private.spw.cw.endfreq := public.get_values('CHAN_FREQ',-1);
	}
	return private.spw.cw.endfreq;
    }

    # get a vector of the (1-based) field ids associated with the specified
    # source name
    # @param sname the source name for which the field ids are required
    # @return a vector of 1-based field ids associated with the specified  
    #         source

    const public.fieldids := function(sname) {
        wider public;
        s := public.sourcetable();
        f := public.fieldtable();
        snames := s.getcol('NAME');
        zsids := ind(snames)[snames==sname] - 1;
        fsids := f.getcol('SOURCE_ID');
        zfids := [];
        for(i in 1:len(fsids)) {
            if(any(zsids == fsids[i]))
                zfids := [zfids,i-1];
        }
        return zfids+1;
    }

    # get the FIELD subtable
    # @return the FIELD subtable as a table tool or fail

    const public.fieldtable := function() {
	wider private,public;
	if(is_unset(private.table.field)) {
	    t := public.subtable('FIELD');
	    if(is_fail(t)) {
		note('Error creating FIELD table from ms.',
		     priority='SEVERE', origin='bimams');
		return throw(t::message);
	    }
            private.table.field := t;
	}
	return private.table.field;
    }                          


        

    # get a vector of values for the specified column in the SPECTRAL_WINDOW
    # table
    # @param cn the column name
    # @param j optional index used if contents of the cell is a vector
    #        if so, the value at the specified index is used
    #        if j < 0, then the index used is the absolute value of
    #        j from the end of the vector, e.g. j=-1 means get the last
    #        value in the vector
    # @param type type of window 's' sideband-avg, 'c' multi-channel-data, 'a'
    #        multi-channel-avg
    # @return a vector of values for the specified column

    const public.get_values := function(cn, j=1, type='c') {
	wider public;
	inds := public.spwids(type);
	r := [];
	t := public.spwtable();
	for(i in 1:len(inds)) {
	    v := t.getcell(cn,inds[i]);
	    if(len(v) == 1) r := [r,v];
	    else {
		if(j == 0) j := 1;
		if(j > 0) r := [r,v[j]];
		else r := r := [r,v[len(v) + j + 1]];
	    }
	}
	return r;
    }

    # calculate the total time in this measurement set
    # @param gaptime the minimum gap between scans in seconds, if < 0
    #        2 times the maximim interval (single integration) is used
    
    const public.totalintegration := function(gaptime=-1) {
        wider public;
        t := public.maintable();
        time1 := t.getcol('TIME');
        time2 := [time1[2:len(time1)],time1[len(time1)]];
        diff := time2-time1;
        if(gaptime < 0) gaptime := 2*max(t.getcol('INTERVAL'));
        return dq.quantity(sum(diff[diff < gaptime]),'s');
    }

    # get the main table as a table tool
    
    const public.maintable := function() {
        wider private;
	if(is_unset(private.table.main)) {
            t := table(private.mstool.name(), readonly=T);
            if(is_fail(t)) 
                return throw('Error creating table from measurement set tool.');
            private.table.main := t;
        }
	return private.table.main;
    }



    # given (1-based) data description ids which refer to multichannel
    # data windows, return the 1-based data description ids which refer
    # to the corresponding multi-channel averages. For multichannel windows
    # which do not have corresponding mulitchannel averages, -1 is returned
    # at the corresponding vector position.
    # @param mcd vector of 1-based data description ids which refer to 
    #            multichannel data windows, if unset, all are used
    # @param assoc the associated ids to get 'a' = multichannel averages, 
    #              's' = sideband averages
    # @return the 1-based data description ids which refer to the 
    #         corresponding multi-channel averages

    public.assoc_spw_ddids := function(mcd,assoc='a',debug=F) {
        wider public;
        if(assoc == 'a') type := private.mca;
        else if(assoc == 's') type := private.sba;
        else return throw('assoc must be either "a" or "s"',
                          origin='bimams.spw_assoc_ddids');
        ddt := public.ddtable();
        if(is_fail(ddt)) fail;
        spwt := public.spwtable();
        if(is_fail(spwt) || is_unset(spwt)) fail;
        if(is_unset(mcd) || len(mcd) <= 0) return throw('mcd must be set');
        tmp := ddt.selectrows(mcd);
        spwids := unique(tmp.getcol('SPECTRAL_WINDOW_ID')) + 1;
        tmp := spwt.selectrows(spwids);
        if(!all(tmp.getcol('FREQ_GROUP_NAME') == private.mcd))
            return throw(spaste('At least one of the windows you ',
                                'specified is not a MULTI-CHANNEL-DATA ',
                                'window'));
        ddsubt := ddt.selectrows(mcd);
        polar := ddsubt.getcol('POLARIZATION_ID');
        targetspwids := ddsubt.getcol('SPECTRAL_WINDOW_ID') + 1;
        spwsubt := spwt.selectrows(targetspwids);
        mca := [];
        if(assoc == 's') {
            lsbid := public.spwid('l','s') - 1;
            usbid := public.spwid('u','s') - 1;
            ns := spwsubt.getcol('NET_SIDEBAND');
            mca[ind(ns)] := -1;
            mca[ns == -1] := lsbid;
            mca[ns == 1] := usbid;
        } else {
            zbassoc := spwsubt.getcol('ASSOC_SPW_ID');
            if(is_fail(zbassoc)) 
                return throw(spaste('This failure likely means that your ',
                                    'dataset contains a different number\n',
                                    'of channel data windows than channel ',
                                    'average windows.  Currently you must\n',
                                    'the same number of channel average ',
                                    'windows as channel data windows or you\n',
                                    'must have 0 channel average windows\n',
                                    zbassoc::message));
            obassoc := zbassoc + 1;
            if(debug) {
                note(spaste('zbassoc ',zbassoc), origin='bimams');
                note(spaste('zbassoc::shape ', zbassoc::shape), 
                     origin='bimams');
            }
            for(i in 1:obassoc::shape[2]) {
                test := spwt.selectrows(obassoc[,i]).getcol('FREQ_GROUP_NAME');
                tmpmca := zbassoc[,i][test==type]; 
                lng := len(tmpmca);
                if(lng == 0) tmpmca := -1;
                else if(lng > 1) 
                    return throw(spaste('Dataset irregularity. Spectral ',
                                        'window number ',targetspwids[i],
                                        ' has ',lng,' ',type,' associations. ',
                                        'I can deal with it if it only has ',
                                        'one.'));
                mca[i] := tmpmca;
                if(debug)
                    note(spaste('i ',i,' mca ',mca[i]), 
                         origin='bimams');
            }
        }
        if(debug)
            note(spaste('mca is ',mca), origin='bimams');
        # we have the associated window ids (zero based) so now we need to
        # get the corresponding data description ids
        allspws := ddt.getcol('SPECTRAL_WINDOW_ID');
        allpols := ddt.getcol('POLARIZATION_ID');
        ids[ind(mca)] := -1;
        umca := unique(mca);
        for(i in ind(umca)) {
            if(umca[i] < 0) ids[mca == umca[i]] := umca[i];
            else {
                for(j in 1:len(allpols)) {
                    if(umca[i] == allspws[j] && polar[i] == allpols[j]) {
                        ids[mca == umca[i]] := j;
                        break;
                    }
                }
            }
        }
        return ids;
    }

    # get the measurement set associated with this tool
    # @return the measurement set associated with this tool

    const public.ms := function() {
	wider private;
	return private.mstool;
    }

    # name a spectral window by adding an entry in the name column of the
    # SPECTRAL_WINDOW table
    # @param sb the sideband the window is in "u" or "l"
    # @param type type of window "s" sideband-avg, "c" multi-channel-data, "a"
    #        multi-channel-avg
    # @param mcn integer the number of the multichannel window. Not used when
    #        type='s'.
    # @param name the name that the window will be known by
    # @return T or F if naming was successful

    const public.namespw := function(sb, type, mcn=1, name) {
        wider public;
        id := public.spwid(sb, type, mcn);
        if(is_fail(id)) return throw(id::message);
        return public.namespwid(id,name);
    }


    # name a spectral window by specifying its row number in the 
    # SPECTRAL_WINDOW table
    # @param id the row number of the spectral window to name
    # @param name the name to give the window
    # @return T or fail

    const public.namespwid := function(spwid,name) {
        names := public.spwnames();
	for(i in 1:len(names)) {
            if(name == names[i] && i != spwid && name != 'none') {
                s := "There is already a column in the SPECTRAL_WINDOWS";
                s := paste(s,"table named",name);
                note(s,priority='SEVERE', origin='bimams');
                return throw(s);
            }
        }
        t := public.spwtable(F);
        if(!t.putcell("NAME",spwid,name))
            return throw("putcell() failed.  Unable to name the specified window");
        return T;
    }

    # get a vector of the number of channels for the multichannel data windows
    # @return a vector of the number of channels for the multichannel data 
    # windows in the order they appear in the SPECTRAL_WINDOWS table
    
    const public.nchans := function() {
	wider private;
	wider public;
	if(is_unset(private.spw.chans.nchan)) 
	    private.spw.chans.nchan := public.get_values('NUM_CHAN');
	return private.spw.chans.nchan;
    }

    ##
    # get the number of rows in the polarization table
    # @return the number of polarizations in this ms or fail

    const public.npol := function() {
	wider public;
	t := public.polartable();
	if(is_fail(t)) return throw(t::message);
	return t.nrows();
    }

    # get the number of rows in the spectral window table 
    # (includes averages, etc.)
    # @return the number of spectral windows in this ms or fail

    const public.nspw := function() {
	wider public;
	t := public.spwtable();
	if(is_fail(t)) return throw(t::message);
	return t.nrows();
    }

    # get the POLARIZATION table associated with the ms
    # @return the POLARIZATION table as a table tool or fail

    const public.polartable := function() {
	wider private,public;
	if(is_unset(private.table.polar)) {
	    t := public.subtable('POLARIZATION');
	    if(is_fail(t)) {
		note('Error creating DATA_DESCRIPTION table from ms.',
		     priority='SEVERE', origin='bimams');
		return throw(t::message);
	    }
            private.table.polar := t;
	}
	return private.table.polar;
    }                          

    # get the 1-based polarization ids
    # @param stokes the stokes parameter
    # @return the 1-based polarization ids matching the stokes parameter as
    #         a vector

    const public.polarids := function(stokes) {
	wider public;
        t := public.polartable();
        stid := public.stokesid(stokes);
        ids := t.getcol('CORR_TYPE');
        x := [];
        for(i in ind(ids)) {
            if(stid == ids[i])
                x := [x,i];
        }
        return x;
    }

    ##
    # calculate the sideband and window averages (should always be done after
    # data have been flagged
    # @param verbosity the verbosity level, higher numbers mean more verbose
    #        output of informational messages <=0 no informational messages
    # @param out the output ms, if unset, the new averages are written to the
    #        input ms
    # @param dosort sort the data when doing subqueries, if F, will speed up
    #        execution, but should only be set to F if you are sure you data
    #        are already sorted in time-baseline order 
    # @param reset should all average data be recomputed? By default (reset=T),
    #        all averages recomputed regardless of the value of the existing 
    #        flags, otherwise (reset=F), only averages with F flags are 
    #        recomputed (i.e. averages flagged bad are left untouched).
    # @return T or fail
    # @todo add edge and blanf parameters as in miriad's uvwide to allow
    #       user to exclude edge channels from being used when computing
    #       averages (note, blankf = 0.033 by default in uvwide which is
    #       one reason why default uvwide averages differ from reavg averages)

    const public.reavg := function(out = '', dosort = T, reset = T, 
                                   verbosity = 1) {
        wider private,public;

        # copy the dataset to a new dataset and compute the averages for
        # the new dataset in place
        docopy_and_reavg := function() {
            if(verbosity >= 1)
                note(spaste('Copying the original measurement set to '
                            ,out), origin='bimams');
            ok := tablecopy(public.ms().name(),out);
            if(is_fail(ok)) fail;
            if(!ok) return F;
            if(verbosity >= 1)
                note('Creating new bimams tool for the new ms', 
                     origin='bimams');
            bms := bimams(out);
            if(is_fail(bms)) fail;
            # do the reaveraging on the new dataset
            retval := bms.reavg(unset,dosort,reset,verbosity);
            bms.done();
            return retval;
        }

        if(out != '') return docopy_and_reavg();

        if(verbosity >= 1)
            note(spaste('Beginning reaveraging. For large datasets this ',
                        'may take several minutes. The performance issue ',
                        'is being investigated.'), origin='bimams');
        public.spwtable();
        spwavg := 0;
        # in table queries can only use variables of global scope
	global junk_zb_mcd;
	global junk_zb_mca;
        global junk_sba;
        if(dosort) 
            sort := 'TIME, DATA_DESC_ID, ANTENNA1, ANTENNA2';
        else sort := unset;
        collist := 'TIME, ANTENNA1, ANTENNA2, DATA, FLAG';
        t := table(public.ms().name(), readonly = F);
        # for processing, make a subtable containing only multichannel
        # data; don't use the averages for iterating
        zb_mcd := public.ddids(public.spwids('c')) - 1;
        zb_mca := public.assoc_spw_ddids(zb_mcd+1,'a') - 1;
        if(is_fail(zb_mca)) fail;
        # loop thru the data description ids
        testcols := ['TIME','ANTENNA1','ANTENNA2'];
        npoints := [=];
        new_mca := [=];
        sba_count := 0;
        sba_avg := [];
        sband_ddids := [];
        sba_subt := [=];
        sba_col['TIME'] := [=];
        sba_col['ANTENNA1'] := [=];
        sba_col['ANTENNA2'] := [=];
        mcd_col['TIME'] := [=];
        mcd_col['ANTENNA1'] := [=];
        mcd_col['ANTENNA2'] := [=];
        mca_data := [=];
        mca_flags := [=];

        sba_data := [=];
        sba_flags := [=];
        for(i in ind(zb_mcd)) {
            if(verbosity > 0)
                note('Performing sanity checks for multichannel data window ',
                     zb_mcd[i] + 1,' and its associated windows',
                     origin='bimams');
            rec_num := as_string(i);
            if(verbosity >= 2)
                note(spaste('Working on data description id ',
                            zb_mcd[i] + 1), origin='bimams');
            junk_zb_mcd := zb_mcd[i];
            q1 := spaste('DATA_DESC_ID == $junk_zb_mcd');
            mcd_subt[rec_num] := t.query(q1,sortlist=sort,columns=collist);
            if(is_fail(mcd_subt[rec_num])) {
                note(spaste('Failed to construct subtable for ',
                            'data description id ',zb_mcd[i]),
                     priority = 'SEVERE', origin='bimams');
                next;
            }
            for(col in testcols)
                mcd_col[col][i] := mcd_subt[rec_num].getcol(col);
            if(zb_mca[i] >= 0) {
                junk_zb_mca := zb_mca[i];
                q2 := spaste('DATA_DESC_ID == $junk_zb_mca');
                mca_subt[rec_num] := t.query(q2,sortlist=sort,columns=collist);
                if(is_fail(mca_subt[rec_num])) 
                    fail spaste('Failed to construct subtable for ',
                                'data description id ',zb_mca[i]);
                # check and make sure the data in the two subtables are
                # consistent
                for(col in testcols) {
                    if(mcd_col[col][i] != mca_subt[rec_num].getcol(col)) {
                        fail spaste(col,' column mismatch for data ',
                                    'description ids ',zb_mcd[i] + 1,' and ',
                                    zb_mca[i] + 1);
                    }           
                }                
                if(!reset) {
                    mca_data[i] := mca_subt[rec_num].getcol('DATA');
                    mca_flags[i] := mca_subt[rec_num].getcol('FLAG');
                }
            }
            assoc_sba[i] := as_string(public.assoc_spw_ddids(zb_mcd[i] + 1,'s')
                                   - 1);
            if(is_fail(assoc_sba[i])) 
                return throw(spaste('Unable to find sideband average ',
                                    'associated with (one based) window ',
                                    zb_mcd[i] + 1,'\n',assoc_sba[i]::message));
            if(verbosity > 1) 
                note(spaste('ASSOCIATED SIDEBAND FOR WINDOW ',zb_mcd[i] + 1,
                            ' is ',assoc_sba[i]));
            if(!has_field(sba_subt,assoc_sba[i])) {
                junk_sba := as_integer(assoc_sba[i]);
                q2 := spaste('DATA_DESC_ID == $junk_sba');
                sba_subt[assoc_sba[i]] := 
                    t.query(q2,sortlist=sort,columns=collist);
                if(is_fail(sba_subt[assoc_sba[i]])) {
                    fail spaste('Failed to construct sidbeband average ',
                                'subtable for data description id ',
                                as_integer(assoc_sba[i]) + 1,'\n',
                                sba_subt[assoc_sba[i]]::message);
                }
                if(verbosity > 1) 
                    note('New sideband ',as_integer(assoc_sba[i]) + 1,
                         ' found',origin='bimams');
                sba_col['TIME'][assoc_sba[i]] := 
                    sba_subt[assoc_sba[i]].getcol('TIME');
                sba_col['ANTENNA1'][assoc_sba[i]] := 
                    sba_subt[assoc_sba[i]].getcol('ANTENNA1');
                sba_col['ANTENNA2'][assoc_sba[i]] := 
                    sba_subt[assoc_sba[i]].getcol('ANTENNA2');
                if(!reset) {
                    sba_data[assoc_sba[i]] := 
                        sba_subt[assoc_sba[i]].getcol('DATA');
                    sba_flags[assoc_sba[i]] := 
                        sba_subt[assoc_sba[i]].getcol('FLAG');
                }
            }
            for(col in testcols) {
                if(mcd_col[col][i] != sba_col[col][assoc_sba[i]]) 
                        fail spaste(col,' column mismatch for data ',
                                    'description ids ',zb_mcd[i] + 1,' and ',
                                    as_integer(assoc_sba[i]) + 1); 
            }
        }

        # now that all the checks have passed, the new averages can be 
        # calculated and written
        
        mca_avg := [=];

        sba_w_sum := [=];
        sba_w := [=];
        mcd_data := mcd_subt['1'].getcol('DATA');
        npol := mcd_data::shape[1];
        ndata := mcd_data::shape[3];
        for(f in field_names(sba_subt)) {
            sba_w_sum[f] := array(0,npol,1,ndata);
            sba_w[f] := array(0,npol,1,ndata);
        }
        for(i in ind(zb_mcd)) {
            rec_num := as_string(i);
            if(verbosity > 1)
                note(spaste('Determining averages associated with channel ',
                            'data window ',zb_mcd[i] + 1),origin='bimams');
            mcd_data := mcd_subt[rec_num].getcol('DATA');
            nchan := mcd_data::shape[2];
            npoints[i] := array(0,npol,ndata);
            new_mca[i] := array(0,npol,1,ndata);
            mca_avg[i] := array(0,npol,1,ndata);
            cw := public.chanwidthsddids(zb_mcd[i] + 1);
            mcd_flags := mcd_subt[rec_num].getcol('FLAG');
            # reset the avg array
            for(j in 1:npol) {
                for(k in 1:ndata) {
                    gooddata := mcd_data[j,,k][!mcd_flags[j,,k]];
                    # save npoints for later use in sideband averaging
                    npoints[i][j,k] := len(gooddata); 
                    # store new multichannel averages in new_mca array for
                    # use later
                    if(npoints[i][j,k] > 0) {
                        new_mca[i][j,1,k] := sum(gooddata)/npoints[i][j,k];
                        weight := sqrt(cw*npoints[i][j,k]);
                        sba_w_sum[assoc_sba[i]][j,1,k] +:= 
                            weight*new_mca[i][j,1,k];
                        sba_w[assoc_sba[i]][j,1,k] +:= weight;
                    }
                    # if we need to actually write the new channel averages
                    # stuff those in avg
#                    if(zb_mca[i] >= 0) {
#                        if(reset || !mca_flags[i][j,1,k]) 
#                            mca_avg[i][j,1,k] := new_mca[i][j,k];
#                        else mca_avg[i][j,1,k] := mca_data[i][j,1,k];
#                    }
                }
            }
            if(zb_mca[i] >= 0) {
                mca_avg[i] := new_mca[i];
                if(!reset) {
                    if(verbosity > 2) 
                        note('Not changing flagged multichannel average values');
                    mca_avg[i][mca_flags[i]] := mca_data[i][mca_flags[i]];
                }
            }
            mcd_subt[rec_num].done();
        }
        sba_avg := [=];
        for(f in field_names(sba_subt)) {
            if(verbosity > 0)
                note(spaste('Determining sideband average for data ',
                            'description id ',as_integer(f)+1),
                     origin='bimams');
            # save away for later comparisons
            sba_avg[f] := sba_w_sum[f]/sba_w[f];
            if(!reset) {
                if(verbosity > 2) 
                    note('Not changing flagged sideband average values');
                sba_avg[f][sba_flags[f]] := sba_data[f][sba_flags[f]]; 
            }
        }

        for(i in ind(zb_mca)) {
            if(zb_mca[i] >= 0) {
                rec_num := as_string(i);
                if(verbosity > 0) 
                    note(spaste('Writing multichannel averages to data desc ',
                                'id ',zb_mca[i]+1), origin='bimams');
                ok := mca_subt[rec_num].putcol('DATA',mca_avg[i]);     
                if(is_fail(ok)) 
                    note(spaste('Failed to write multichannel average for ',
                                'data desc id ',zb_mca[i]+1,': ',ok::message),
                         priority='SEVERE', origin='bimams');
                mca_subt[rec_num].done();
            }
        }
        # do the sibeband averages
        for(f in field_names(sba_subt)) {
            if(verbosity > 0)
                note(spaste('Writing sideband average for data ',
                            'description id ',as_integer(f) + 1),
                     origin='bimams');
            sba_subt[f].putcol('DATA',sba_avg[f]);
            sba_subt[f].done();
        }
        t.done();
        if(verbosity >= 1)
            note('reavg() has finished', origin='bimams');
        return T;
    }


    # get a vector of reference frequencies for the multichannel data
    # @return a vector of reffreqs in the order they appear in the
    # SPECTRAL_WINDOW table
    
    const public.reffreqs := function() {
	wider private, public;
	if(is_unset(private.spw.cw.reffreq)) {
	    private.spw.cw.reffreq := public.get_values('REF_FREQUENCY');
	}
	return private.spw.cw.reffreq;
    }

    ##
    # get a list of net_sideband values associated with the given 1-based 
    # spectral window ids

    const public.sb := function(spwids) {
        wider public;
        return public.spwtable().getcol('NET_SIDEBAND')[spwids];
    }


    # get a vector of source names from the SOURCE table
    
    const public.sourcenames := function() {
        wider public;
        s := public.sourcetable();
        return s.getcol('NAME');
    }

    # get the SOURCE subtable
    # @return the SOURCE subtable as a table tool or fail

    const public.sourcetable := function() {
	wider private,public;
	if(is_unset(private.table.source)) {
	    t := public.subtable('SOURCE');
	    if(is_fail(t)) {
		note('Error creating SOURCE table from ms.',
		     priority='SEVERE', origin='bimams');
		return throw(t::message);
	    }
            private.table.source := t;
	}
	return private.table.source;
    }                          

    ##
    # get a 1-based list of data description ids associated with the
    # specified spwids
    # @return a two-d array of ddids.  The first index represents the
    #         index of the input spwids array. The second index is for
    #         the polarization (with n polarizations, there will
    #         n ddids associated with a given spectral window id)

    const public.spw_ddids := function(spwids) {
        wider public;
        spwids := spwids - 1;
        ddt := public.ddtable();
        allspwids := ddt.getcol('SPECTRAL_WINDOW_ID');
        upols := unique(ddt.getcol('POLARIZATION_ID'));
        ddids[1:len(spwids)*len(upols)] := -1;
        ddids::shape := [len(spwids),len(upols)];
        for(i in ind(spwids)) {
            ddids[i,] := ind(allspwids)[allspwids == spwids[i]];
        }
        return ddids;
    }


    # get the 1-based spectral window id (the row number of the specified
    # entry in the spectral_windows table) of the specified window.  
    # @param sb which sideband? "u" or "l"
    # @param type type of window "s" sideband-avg, "c" multi-channel-data, "a"
    #        multi-channel-avg
    # @param mcn integer the position of this type of window
    #        miriad dataset (relies on bimafiller writing windows in the
    #        order they appear in the miriad dataset).  Not used when
    #        type='s'.
    # @return int the spectral window id or -1 if the window was not found

    const public.spwid := function(sb,type,mcn = 1) {
	wider public,private;
	if(sb =~ m/^u/i) ns := 1;
	else if(sb =~ m/^l/i) ns := -1;
	else {
	    note('sb must either be "l" or "u"',priority='SEVERE', 
                 origin='bimams');
	    return throw('Unrecognized sideband label');
	}
	if(type =~ m/^s/i) fgn := private.sba;
	else if(type =~ m/^c/i) fgn := private.mcd;
	else if(type =~ m/^a/i) fgn := private.mca;
	else {
	    note('type must either be "a", "c", or "s"',priority='SEVERE', 
                 origin='bimams');
	    return throw('Unrecognized frequency group label');
	}
	if(fgn == private.sba) mcn := 0;
	else if(mcn <= 0) {
	    note('You must specify a multichannel window number',
		 priority='SEVERE', origin='bimams');
	    return throw('Mulitchannel window number was not specified');
	}
	spwt := public.spwtable();
	if(is_fail(spwt)) return throw(spwt::message);
	n := 1;
	found := F;
	for(i in 1:spwt.nrows()) {
	    tns := spwt.getcell('NET_SIDEBAND',i);
	    tfgn := spwt.getcell('FREQ_GROUP_NAME',i);
	    if(tfgn == fgn && tns == ns) {
		if(tfgn == private.sba) {
		    found := T;
		    break;
		} else {
		    if(n == mcn) {
			found := T;
			break;
		    }
		    else n := n+1;
		}
	    }
	}
	if(found) return i;
	else return -1;
    }

    # get a vector of spectral window ids 
    # @param type type of window 's' sideband-avg, 'c' multi-channel-data, 'a'
    #        multi-channel-avg, 'A' all types
    # @param sb which sideband? "u", "l", or "b" (both)
    # @return a vector of ids

    const public.spwids := function(type, sb='b') {
        wider private;
	if(type =~ m/^s/i) fgn := private.sba;
	else if(type =~ m/^c/i) fgn := private.mcd;
	else if(type =~ m/^a/) fgn := private.mca;
        else if(type =~ m/^A/) fgn := 'all';
	else {
	    note('type must either be "A", "a", "c", or "s"',
                 priority='SEVERE', origin='bimams');
	    return throw('Unrecognized frequency group label');
	}
	ns := 0;
	if(sb =~ m/^u/i) ns := 1;
	else if(sb =~ m/^l/i) ns := -1;
	t := public.spwtable();
	if(is_fail(t)) fail;
	vec := [];
	for(i in 1:t.nrows()) {
            if(fgn != 'all')
                tfgn := t.getcell("FREQ_GROUP_NAME",i);
	    tns := 0;
	    if(ns != 0) tns := t.getcell("NET_SIDEBAND",i);
	    if((fgn == 'all' || tfgn == fgn) && tns == ns) vec := [vec,i];
	}
	return vec;
    }

    # get the spectral window id by specifying the name of the window
    # @param names vector of names of the spectral windows
    # @return vector of ints the spectral window id(s) or -1 if the 
    # window was not found

    const public.spwidsbyname := function(names) {
        spwnames := public.spwnames();
        for(j in 1:len(names)) {
            ids[j] := -1;
            for(i in 1:len(spwnames)) {
                if(names[j] == spwnames[i]) {
                    ids[j] := i;
                    break;
                }
            }
        }
        return ids;
    }

    # get a vector of spectral window names
    # @param type return a vector containing only the names of these types
    #        of windows. 'a' all windows, 'c' channel-data windows only
    # @return a vector of the spectral window names

    const public.spwnames := function(type='all') {
        t := public.spwtable();
        names := t.getcol('NAME');
        if(type == 'all') return names;
        else if (type == 'c') return names[public.spwids('c')];
        else if (type == 'a') return names[public.spwids('a')];
        else if (type == 's') return names[public.spwids('s')];
        else return throw (spaste('Unrecognized type ',type,'. Only \'all\', \'a\', \'c\', and \'s\' are currently recognized.'));
    }

    # get a vector of the start frequencies for the multichannel data
    # @return a vector of start frequencies in the order they appear in the
    # SPECTRAL_WINDOW table
    
    const public.startfreqs := function() {
	wider private;
	if(is_unset(private.spw.cw.startfreq)) {
	    private.spw.cw.startfreq := public.get_values('CHAN_FREQ',1);
	}
	return private.spw.cw.startfreq;
    }

    # get the stokes id given the stokes parameter, id's from 
    # aips/implement/Measures/Stokes.h
    # @param the stokes parameter
    # @return the stokes id or -1 if not a recognized stokes parameter

    const public.stokesid := function(stokes) {
        if(!is_string(stokes))
            return throw('stokes must be a string');
        if(stokes == 'I') return 1; 
        if(stokes == 'Q') return 2;
        if(stokes == 'U') return 3;
        if(stokes == 'V') return 4;
        if(stokes == 'RR') return 5;
        if(stokes == 'RL') return 6;
        if(stokes == 'LR') return 7;
        if(stokes == 'LL') return 8;
        if(stokes == 'XX') return 9;
        if(stokes == 'XY') return 10;
        if(stokes == 'YX') return 11;
        if(stokes == 'YY') return 12;
        if(stokes == 'RX') return 13;
        if(stokes == 'RY') return 14;
        if(stokes == 'LX') return 15;
        if(stokes == 'LY') return 16;
        if(stokes == 'XR') return 17;
        if(stokes == 'XL') return 18;
        if(stokes == 'YR') return 19;
        if(stokes == 'YL') return 20;
        return -1;
    }

    # get the specified subtable of the ms
    # @param tname the table name
    # @param readonly open table for reading only?
    # @return the subtable as a table tool or fail

    const public.subtable := function(tname,readonly=T) {
	wider private;
	if(is_unset(private.table.main)) {
	    t := public.maintable();
	    if(is_fail(t)) return throw(t::message);
	}
	t := table(private.table.main.getkeyword(tname),readonly=readonly);
	if(is_fail(t)) return throw(spaste('Subtable ',tname,' not found. ',
                                           t::message));
	return t;
    }

    # produce a summary of the ms
    # @param type the type of summary, unset defaults to ms.summary()
    #        other recognized values are 'spec' which produces a miriad like
    #        listing of the multi-channel data spectral windows
    # @return T

    const public.summary := function(type=unset) {
	wider public;
	if(is_unset(type)) {
	    m := public.ms();
	    if(is_fail(m)) return throw(m::message);
	    m.summary();
	} else if (type == 'spec') {
	    t := public.spwtable();
	    nrows := 7;
            number := public.spwids('c');
	    n := len(number);
	    ncols := 1 + n + as_integer((n-1)/6);
	    ent := array('',nrows,ncols);
	    i := 1;
	    j := 1;
            names := public.spwnames('c');
#	    startch := public.startchans();
	    nchan := public.nchans();
	    startfreq := public.startfreqs()/1e9;
	    endfreq := public.endfreqs()/1e9;
	    chanwidth := public.chanwidths()/1e9;
	    while( i <= ncols) {
		if ((i-1) % 7 == 0) { 
		    ent[1,i] := 'window row num.  :';
		    ent[2,i] := 'window name      :';
#		    ent[3,i] := 'starting channel :';
		    ent[3,i] := 'number of chans. :';
		    ent[4,i] := 'start frequency  :';
		    ent[5,i] := 'end frequency    :';
		    ent[6,i] := 'channel width    :';
		    ent[7,i] := 'window width     :';
		    i := i+1;
		} else {
		    maxi := i+5;
		    if (maxi > ncols) maxi := ncols;
		    maxj := j+5;
		    if (maxj > len(number)) maxj := len(number);
		    ent[1,i:maxi] := sprintf('%10i',number[j:maxj]);
		    ent[2,i:maxi] := sprintf('%10s',names[j:maxj]);
#		    ent[3,i:maxi] := sprintf('%10i',startch[j:maxj]);
		    ent[3,i:maxi] := sprintf('%10i',nchan[j:maxj]);
		    ent[4,i:maxi] := sprintf('%10.5f',startfreq[j:maxj]);
		    ent[5,i:maxi] := sprintf('%10.5f',endfreq[j:maxj]);
		    ent[6,i:maxi] := sprintf('%10.5f',chanwidth[j:maxj]);
		    ent[7,i:maxi] := sprintf('%10.5f',
                                             chanwidth[j:maxj]*nchan[j:maxj]);
		    j := maxj+1;
		    i := maxi+1;
		}
	    }
	    out := 'The order of the windows below may not be the same as the';
	    out := spaste(out,'\norder of the windows in the original ');
            out := spaste(out,'MIRIAD dataset.\n\n');
	    maxk := as_integer((ncols-1)/7)+1;
	    for(k in 1:maxk) {
		startcol := 7*(k-1)+1;
		for(i in 1:nrows) {
		    s := '';
		    for(j in startcol:(startcol+6)) {
			if(j <= ent::shape[2]) {
			    t := ent[i,j];
			    s := spaste(s,t);
			}
		    }
		    out := spaste(out,s,'\n');
		}
		if(k != maxk) out := spaste(out,'\n');
	    }
	}
	note(out);
    }

    # get the spectral window table associated with the ms
    # @param readonly open the table for reading only
    # @return the spectral window table or fail

    const public.spwtable := function(readonly=T) {
        wider private,public;
	if(is_unset(private.table.spw)) {
	    t := public.subtable('SPECTRAL_WINDOW',readonly);
	    if(is_fail(t)) {
		note('Error creating spectral window table from ms.',
		     priority='SEVERE', origin='bimams');
		return throw(t::message);
            }
            private.table.spw := t;
        } else if((private.table.spw.iswritable() && readonly) || 
                  (!private.table.spw.iswritable() && !readonly)) {
            private.table.spw.done();
            private.table.spw := unset;
            public.spwtable(readonly);
        }
	return private.table.spw;
    }
	
    # get the syscal table associated with the ms
    # @param readonly open the table for reading only
    # @return the syscal table or fail

    const public.syscaltable := function(readonly=T) {
        wider private;
	if(is_unset(private.table.syscal)) {
	    t := public.subtable('SYSCAL',readonly);
	    if(is_fail(t)) {
		note('Error creating spectral window table from ms.',
		     priority='SEVERE', origin='bimams');
		return throw(t::message);
            }
            private.table.syscal := t;
        } else if((private.table.syscal.iswritable() && readonly) || 
                  (!private.table.syscal.iswritable() && !readonly)) {
            private.table.syscal.done();
            private.table.syscal := unset;
            public.syscal(readonly);
        }
	return private.table.syscal;
    }

    # get the timerange (as a record of quantities containing fields 
    # max and min) in the ms

    const public.timerange := function() {
        wider public;
        t := public.maintable();
        if(is_fail(t)) fail;
        times := t.getcol('TIME');
        unit := t.getcolkeywords('TIME').QuantumUnits;
        mint := dq.quantity(min(times),unit);
        maxt := dq.quantity(max(times),unit);
        r := [=];
        r.max := maxt;
        r.min := mint;
        return r;
    }

    # returns 'bimams', the tool type
    # @return 'bimams'

    const public.type := function() {
        return 'bimams';
    }

    # create a visplot tool using the ms associated with this tool
    # @return T

    const public.visplot := function() {
        wider public;
        include 'visplot.g';
        ok := visplot(public.ms().name());
        if (is_fail(ok)) return throw (ok::message);
        return ok;
    }

    return ref public;
}
##
# @constructor
# @param msname the name of a measurement
# set on disk that should be attached to this tool
# @return a reference to the public record

const bimams := function(msname) {

#    if(has_field(msname,'type') && msname.type() != 'ms')
#	mstool := msname;
#    else {
	mstool := ms(msname);
	if(is_fail(mstool)) return throw(mstool::message);
#    }
	    
    return ref _define_bimams(mstool);
};				 
