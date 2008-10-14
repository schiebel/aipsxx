# mirfiller: a tool for filling MIRIAD uv data
# Copyright (C) 2000,2001,2002
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
# $Id: mirfiller.g,v 19.0 2003/07/16 03:35:48 aips2adm Exp $

# include guard
pragma include once
 
# Include whatever files are necessary. aips.g will nearly always
# be required.

include "servers.g";
include "unset.g";
include "quanta.g";

const _mirfiller_defpass := 
    [rawbima=[splwin='all',  winav='none', sbandav='all',  desc='raw BIMA' ],
     calbima=[splwin='all',  winav='none', sbandav='none',
                  desc='calibrated BIMA' ],
         all=[splwin='all',  winav='all',  sbandav='all',  desc='generic'  ],
        none=[splwin='none', winav='none', sbandav='none', desc='specialized']];

const _define_mirfiller := function(ref serverid, toolid, 
                                    mirfile, preview=T, defpass='default',
				    quiet=F, goodsyst=T) 
{
    public:=[=];
    private:=[=];

    private.serverid := ref serverid;
    private.toolid := toolid;
    private.mirfile := mirfile;
    private.defpass := defpass;

#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------

# End of private function
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------

    private.fillRec := [_method='fill', _sequence=private.toolid._sequence];

    # fill the output MS according to the current selections and options
    # @param msfile  the output measurement set name
    const public.fill := function(msfile, verbose=F, async=F) {
        wider private;
        wider public;
        local defverb := T;

        if (verbose) {
            defverb := private.getoptions();
            defverb := defverb.verbose;
            if (! defverb) public.setoptions(verbose=T);
        }

	private.fillRec.msfile := msfile;
	ok := defaultservers.run(private.serverid, private.fillRec);

        if (! defverb) public.setoptions(verbose=F);

	return ok;
    }

    private.selectRec := [_method='selectspectra', _sequence=private.toolid._sequence];

    # select data from the input Miriad dataset.  Correllation data 
    # stored in a MIRIAD dataset are stored in spectral windows and so-called
    # wideband channels.  The latter is used to store wideband averages.  
    # BIMA data contains an average for each window and one for each entire
    # sideband.  This function allows one to restrict which data will be 
    # copied into the output measurement set.
    # @param defpass    a string indicating the default window passing
    #                   mode to use.  This mode affects the which kinds of 
    #                   windows get passed when they are not explicitly 
    #                   specified by the other parameters.  See general 
    #                   description above for more details.  Allowed values:
    #                     'default'   use the mode that was set (or assumed) 
    #                                 at construction (see constructor 
    #                                 description for more information);
    #                     'rawbima'   use a default appropriate for 
    #                                 uncalibrated BIMA data:  pass all 
    #                                 spectral line windows and both side 
    #                                 band averages but no window averages;
    #                     'calbima'   use a default appropriate for calibrated 
    #                                 data: pass all spectral line windows 
    #                                 but no wideband averages;
    #                     'all'       pass all windows and wideband channels 
    #                                 by default;
    #                     'none'      pass no windows or wideband channels by 
    #                                 default, require that they be specified 
    #                                 explicitly with select().
    # @param splwin     a list of one-based spectral window indicies to 
    #                   load.  The default selection, controlled by the 
    #                   defpass parameter, applies if an empty vector is 
    #                   supplied.
    # @param winav      a list of one-based spectral window indices indicating
    #                   which window averages to load.  An index of 1 means 
    #                   load the average of the first spectral window.  
    #                   The default selection, controlled by the 
    #                   defpass parameter, applies if an empty vector is 
    #                   supplied.
    # @param sbandav    a string indicating which sideband averages to
    #                   load.  Allowed values:
    #                     'default'   allow the defpass parameter to control 
    #                                 sideband average selection;
    #                     'lsb'       the lower sideband;
    #                     'usb'       the upper sideband;
    #                     'all'       both sidebands;
    #                     'none'      neither sideband.
    const public.select := function(defpass="default", 
                                    splwin=[], winav=[], sbandav="default") 
    {
        wider private;
        wider public;
        global _mirfiller_defpass;
        local info;

        # interpret defpass: match the user value against supported values
        if (defpass == 'default') defpass := private.defpass;
        if (! has_field(_mirfiller_defpass, defpass)) {
            if (private.defpass == defpass) private.defpass := 'all';
            note(spaste('defpass parameter value "', defpass, 
                        '" not recognized; setting defpass="', 
                        private.defpass, '"'),
                 origin='mirfiller', priority='WARN');
            defpass := private.defpass;
        }

        # interpret an unset value the same as an empty vector
        if (is_unset(splwin)) splwin := [];
        if (is_unset(winav)) winav := [];
        if (is_unset(sbandav)) sbandav := 'default';

        # if user did not specify a given selection, assume the default
        #   selection given by defpass
        local defsel := _mirfiller_defpass[defpass];
        if (length(splwin) == 0) splwin := defsel.splwin;
        if (length(winav) == 0) winav := defsel.winav;
        if (sbandav == 'default') sbandav := defsel.sbandav;

        # convert named selections to the appropriate selection indices
        public.summary(info, verbose=F, preview=F);
	spw := splwin;
        if (is_string(spw)) {
            if (spw == "all")
                spw := 1:info.nspect;
            else if (spw == "none") 
                spw := [];
            else 
                fail paste('mirfiller.select(): unrecognized splwin alias:',
                           spw);
        }
	private.selectRec.windows := spw;

	wdav := winav;
        if (is_string(wdav)) {
            if (wdav == "all" && info.nwide > 2) 
                wdav := 1:(info.nwide-2);
            else if (wdav == "all" || wdav == "none") 
                wdav := [];
            else 
                fail paste('mirfiller.select(): unrecognized winav alias:',
                           wdav);
        }

	sbav := sbandav;
        if (is_string(sbav)) {
            if (sbav == "all") 
                sbav := 1:2;
            else if (sbav == "none") 
                sbav := [];
            else if (sbav == "lsb")
                sbav := [1];
            else if (sbav == "usb")
                sbav := [2];
            else 
                fail paste('mirfiller.select(): unrecognized sbandav value:',
                           sbav);
        }
        if (length(sbav) > 0) {
            private.selectRec.widechans := [sbav[sbav>0 && sbav<3], 
                                            wdav[wdav > 0] + 2];
        } else {
            private.selectRec.widechans := [wdav[wdav > 0] + 2];
        }

	ok := defaultservers.run(private.serverid, private.selectRec);
	return ok;
    }

    private.getoptionsRec := [_method='getoptions', 
			      _sequence=private.toolid._sequence];

    const private.getoptions := function() {
	wider private;

	private.getoptionsRec.options := [=];
        ok := defaultservers.run(private.serverid, private.getoptionsRec);
	if (is_fail(ok)) return ok;
	return private.getoptionsRec.options;
    }

    # return the current state of the filler options.  See setoptions()
    # for list of supported options.
    # @return record   holding the options.  
    const public.getoptions := function() {
	wider private;

	opts := private.getoptions();
	useropts := field_names(private.getoptionsRec.options);
	useropts := opts[useropts[useropts!='histbl']];
	useropts.scanlim := dq.quantity(useropts.scanlim/60, 'min');
	useropts.obslim := dq.quantity(useropts.obslim/3600, 'h');
	useropts.updmodelint := dq.quantity(useropts.updmodelint/3600, 'h');
	return useropts;
    }
    
    private.setoptionsRec := [_method='setoptions', 
			      _sequence=private.toolid._sequence,
			      options=[=] ];

    # set the filler options.  If reset=T, then all options will be set
    # to their default value before being updated to the values provided;
    # otherwise, this will update those options explicitly passed to this
    # function.  
    # @param scanlim  the scan time jump limit, in minutes.  If the jump in
    #                 time between two consecutive Miriad records is greater 
    #                 than this limit the scan number that gets written out
    #                 for that record will be incremented.  A change in source
    #                 will always increment the scan number unless scanlim is
    #                 negative; in this case, all records are forced to have
    #                 the same scan number.  The default is 5 minutes.
    # @param obslim   the observation ID time jump limit, in hours.  The 
    #                 observation ID is meant to delimit two tracks that might
    #                 appear in the same file.  If the jump in time 
    #                 between two consecutive Miriad records is greater than 
    #                 this limit the scan number that gets written out for 
    #                 that record will be incremented.  The ID will always be
    #                 incremented if there is a change in telescope or array
    #                 configuration unless obslim is negative, in which case,
    #                 all records will be forced to have the same observation
    #                 ID.  The default is four hours.
    # @param tilesize the tiling size to use (in channels?) for storing data
    #                 in the MS using the TiledStorageManager.  If the value 
    #                 is <= 0, the standard (non-tiled) storage manager will
    #                 be used.  The default is 32.
	# @param updmodelint the interval in hours after which the model should
	#                    be updated.  If the observation spans a time
	#					 greater than this interval then the model will be
	#					 updated.  Default is 8 hours.
    # @param verbose  if true, send extra messages to the logger
    # @param reset    Reset all the options to their defaults before updating
    #                 their values.  
    const public.setoptions := function(scanlim=unset, obslim=unset, 
                                        tilesize=unset, # nosplit=unset, 
                                        verbose=unset, wideconv=unset, 
                                        joinpol=unset, tsyswt=unset,
                                        planetfit=unset, movfield=unset, 
										updmodelint=unset,
                                        compress=unset, reset=F)
    {
	wider public, private;
	private.setoptionsRec.options := [=];

        if (reset) {
	    private.setoptionsRec.options := private.defopts;
	    ok := defaultservers.run(private.serverid, private.setoptionsRec);
	    if (is_fail(ok)) return ok;
        } else {
	    private.setoptionsRec.options := private.getoptions();
	}

	if (! is_unset(tilesize)) 
	    private.setoptionsRec.options.tilesize := tilesize;
# 	if (! is_unset(nosplit))  
#	    private.setoptionsRec.options.nosplit  := nosplit;
	if (! is_unset(scanlim))  {
		scanlim := dq.convert(scanlim, 's').value;
	    private.setoptionsRec.options.scanlim  := scanlim;
	}
	if (! is_unset(obslim))   {
		obslim := dq.convert(obslim, 's').value;
	    private.setoptionsRec.options.obslim   := obslim;
	}
	if (! is_unset(verbose))   
	    private.setoptionsRec.options.verbose  := verbose;
	if (! is_unset(wideconv))   
	    private.setoptionsRec.options.wideconv := wideconv;
	if (! is_unset(joinpol))   
	    private.setoptionsRec.options.joinpol := joinpol;
	if (! is_unset(tsyswt))   
	    private.setoptionsRec.options.tsyswt := tsyswt;
	if (! is_unset(planetfit))   
	    private.setoptionsRec.options.planetfit := planetfit;
	if (! is_unset(updmodelint)) {
		updmodelint := dq.convert(updmodelint, 's').value;
		private.setoptionsRec.options.updmodelint := updmodelint;
	}
	if (! is_unset(movfield))   
	    private.setoptionsRec.options.movfield := movfield;
	if (! is_unset(compress))   
	    private.setoptionsRec.options.compress  := compress;

	ok := defaultservers.run(private.serverid, private.setoptionsRec);
	return ok;
    }

    private.summaryRec := [_method='summary', 
                           _sequence=private.toolid._sequence];

    # send a summary of the contents of the input dataset to the logger.
    # This will implicitly cause the dataset to be scanned in its entirety to 
    # extract the necessary information, if it has not already been read once
    # already.  Selected information about the dataset can be returned by
    # providing a header record: the following fields will be copied into 
    # the record
    #   nwide      the maximum number of wide-band channels
    #   nspect     the maximum number of spectral line windows
    #   nchan      the maximum (total) number of channels
    #   narray     the number of array configurations found
    #   npol       the number of polarizations found
    #   nrec       the total number of visibility records found
    #   cormode    the correlator mode of the first correlator setup
    #   telescope  the name of the telescope.  This will equal "multiple"
    #                if data from multiple telescopes are detected; "unknown"
    #                is returned if the telescope name is not encoded.
    # @param header   if provided, dataset info will be loaded into this 
    #                      record
    # @param verbose  if true (the default), detailed information regarding 
    #                      contents will be sent to the logger.
    # @param preview  if true (the default), the entire file will be read
    #                      to extract information.  Set this to false to 
    #                      defeat this behavior (e.g. for very large files).
    #                      In this case, only the first record of the file 
    #                      will be read; thus, some information may be 
    #                      inaccurate if the dataset is a concatonation of 
    #                      several original datasets.
    const public.summary := function(ref header=[=], verbose=T, preview=T) {
	wider private;

	private.summaryRec.verbose := verbose;
	private.summaryRec.preview := preview;
        ok := defaultservers.run(private.serverid, private.summaryRec);
	if (is_fail(ok)) return ok;
	val header := private.summaryRec.header;

        header.systok := T;
        if ((has_field(header, 'badnsyst') && header.badnsyst > 0) ||
            (has_field(header, 'badwsyst') && header.badwsyst > 0))
            header.systok := F;

        return T;
    }

    # return the tool type
    const public.type := function() { return 'mirfiller'; }

    # shut down this tool.  This function will close the input file.
    const public.done:=function() { 
	wider private, public;
        ok := defaultservers.done(private.serverid, private.toolid.objectid);
        if (is_fail(ok)) fail;
	val private := F;
	val public := F;
	return T;
    }

    # set the default options
    private.defopts := private.getoptions();

    # guess at flavor of input dataset for setting defpass
    info := [=];
    if (preview) {
        public.summary(info, verbose=!quiet);
    } else {
        note(paste('Input dataset previewing turned off;', 
                   'abbreviated summary will be given'),
             origin='mirfiller', priority='NORMAL');
        public.summary(info, preview=F, verbose=!quiet);
    }
    if (private.defpass == 'default') {
        if (all(info.telescope=='BIMA')) {
            if (info.cormode*2 == info.nspect &&
                info.nwide == info.nspect+2 && 
                (! has_field(info, 'narray') || info.narray == 1)) 
            {
                private.defpass := 'rawbima';
            }
            else {
                private.defpass := 'calbima';
            }
            public.setoptions(wideconv='bima');
        }
        else {
            private.defpass := 'all';
        }
        note(spaste('Input looks like a ', 
                    _mirfiller_defpass[private.defpass].desc, 
                    ' dataset; setting default defpass="', 
                    private.defpass, '"'),
             origin='mirfiller', priority='NORMAL');
    } else {
        if (all(info.telescope=='BIMA')) {
            public.setoptions(wideconv='bima');
#           private.defpass := defpass;
	}
    }
    public.select(private.defpass);

    # Check and report on possible problems with system temperatures
    if (! info.systok) {
        if (has_field(info, 'nrec') && info.nrec > 0) {   # previewed
            if (info.badnsyst > 0) 
                note('Found ', info.badnsyst, ' out of ', info.nrec, 
                     ' records containing uninterpretable narrowband system ',
                     'temperatures', priority='WARN', origin='mirfiller');
            if (info.badwsyst > 0) 
                note('Found ', info.badwsyst, ' out of ', info.nrec, 
                     ' records containing uninterpretable wideband system ',
                     'temperatures', priority='WARN', origin='mirfiller');
        }
        else {
            if (info.badnsyst > 0) 
                note('Uninterpretable narrowband system temperatures found',
                     priority='WARN', origin=mirfiller);
            if (info.badwsyst > 0) 
                note('Uninterpretable wideband system temperatures found',
                     priority='WARN', origin=mirfiller);
        }
        if (goodsyst) {
            public.setoptions(tsyswt=F);
            note('System temperature weighting disabled', priority='WARN',
                 origin='mirfiller');
            if (! quiet) 
                note('Use \'setoptions(tsyswt=T)\' to re-enable system ',
                     'temperature weigthing', 
                     priority='WARN', origin='mirfiller');
        }
    }

#    public.private := ref private;          # for debugging
  
    # Return a reference to the public interface
    return ref public;
}

#**
# create a mirfiller tool
# @param mirfile  the MIRIAD dataset filename
# @param preview  pre-scan the dataset and log a description of the contents.
#                 Setting this to F may be useful for very large input files.
# @param defpass  a string indicating the default window passing
#                 mode to use.  This mode affects the which kinds of 
#                 windows get passed when they are not explicitly 
#                 specified by the other parameters.  See general 
#                 description above for more details.  Allowed values:
#                   'default'   use the mode that was set (or assumed) 
#                               at construction (see constructor 
#                               description for more information);
#                   'rawbima'   use a default appropriate for 
#                               uncalibrated BIMA data:  pass all 
#                               spectral line windows and both side 
#                               band averages but no window averages;
#                   'calbima'   use a default appropriate for calibrated 
#                               data: pass all spectral line windows 
#                               but no wideband averages;
#                   'all'       pass all windows and wideband channels 
#                               by default;
#                   'none'      pass no windows or wideband channels by 
#                               default, require that they be specified 
#                               explicitly with select().
# @param quiet    If true, the dataset summary will not be written to the 
#                 logger.  This is intended for use by scripts that want to 
#                 control message output.
# @param host     the remote host to run the server on
# @param forcenewserver  if true, force the creation of a new server,
#                 even if a server currently already running.
##
const mirfiller := function(mirfile, preview=T, defpass='default', quiet=F,
                            host=unset, forcenewserver=F, goodsyst=T) 
{
  include 'servers.g';
  if (is_unset(host)) {
    host := '';
  }
#  defaultservers.suspend(T)
  serverid := defaultservers.activate('mirfiller', host, forcenewserver);
#  defaultservers.suspend(F)
  if(is_fail(serverid)) fail;
  
  toolid := defaultservers.create(serverid, 'mirfiller', 'mirfiller', 
				  [mirfile=mirfile]);
  if(is_fail(toolid)) fail;
  
  return _define_mirfiller(serverid, toolid, mirfile, preview, defpass, quiet,
                           goodsyst);
} 

#**
# this rewrites fail messages generated by caught exceptions into a 
# nicer form. 
##
const _fail_message := function(failmsg) {
    if (failmsg ~ m/^Caught an exception/) 
        failmsg =~ s/^.*exception=//;
    return failmsg;
}

#**
# fill data from a Miriad dataset.  This global function provides a one-step
# method for filling Miriad data in the most typical circumstances.  
# @param msfile  the output measurement set name
# @param mirfile  the MIRIAD dataset filename
# @param defpass  a string indicating the which windows to pass.  See the 
#                 mirfiller tool description for more details.  Allowed values:
#                   'default'   guess at the appropriate window selection 
#                               based on its contents.
#                   'rawbima'   use a default appropriate for 
#                               uncalibrated BIMA data:  pass all 
#                               spectral line windows and both side 
#                               band averages but no window averages;
#                   'calbima'   use a default appropriate for calibrated 
#                               data: pass all spectral line windows 
#                               but no wideband averages;
#                   'all'       pass all windows and wideband channels.
#                               by default;
# @param verbose  if true, send lots of messages to the logger.  A summary of
#                 the input miriad dataset will be printed, and filling will
#                 be done in verbose mode.
# @param goodsyst if true (default), require that all system temperatures to 
#                   be good to enable system temperature weighting; if any
#                   system temperatures are bad, system temperatures weighting
#                   is disabled.  If false, system temperatures weighting will
#                   always be enabled; records with bad system temperatures 
#                   will be given zero weight.  
# @param host     the remote host to run the server on
# @param forcenewserver  if true, force the creation of a new server,
#                 even if a server currently already running.
##
const miriadtoms := function(msfile, mirfile, defpass='default', verbose=F,
			     goodsyst=T, host=unset, forcenewserver=F) 
{
    if (defpass != 'default' && defpass != 'rawbima' && defpass != 'calbima' &&
	defpass != 'all') 
    {
	fail spaste("fillmiriad: defpass=", defpass, " value unsupported");
    }
    local filler := mirfiller(mirfile, defpass=defpass, quiet=!verbose,
                              goodsyst=goodsyst);
    if (is_fail(filler)) 
        return throw('Unable to convert ', mirfile, ': ', 
                     _fail_message(filler::message), origin='miriadtoms');
        
    local ok := filler.fill(msfile, verbose=verbose);
    if (is_fail(ok)) {
        note('Trouble converting ', mirfile, ': ', 
             _fail_message(ok::message), origin='miriadtoms',
             priority='SEVERE');
	ok := F;
    }
    filler.done();
    return ok;
}

# Define test function: return T if successful otherwise fail
const mirfillertest := function(ref summary=[=], ref details=[=], logsummary=F,
                                verbose=1, fill=T, mirdata='',modeldata='') { 
    include 'mirfillertester.g'; 
    mft := mirfillertester(verbose, mirdata, modeldata);
    ok := mft.runtests(fill);
    note(ok);
    if(is_fail(ok)) fail ok::message;
    summary := mft.summary(logsummary);
    details := mft.details();
    mft.done();
    return ok;
}

