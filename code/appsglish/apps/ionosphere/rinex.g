# rinex.g: Glish proxy for rinex DO 
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: rinex.g,v 19.2 2004/08/25 01:22:26 cvsmgr Exp $

pragma include once

include "servers.g"
include "iono_utils.g"
include "aipsrc.g"
# include "logger.g"
include "os.g"
include "sh.g"

#---------------------------------------------------------------
#
# rinex
#
#   rinex is a meta-server for all sattelite-related function
#   (RINEX, ephemeris, etc.)
#
#---------------------------------------------------------------

#---------------------------------------------------------------
# rinex() constructor
#
const rinex := function(host='', forcenewserver = F) {       
  private := [=]                                                 
  public := [=]                                               

# activate the server process
  private.agent := defaultservers.activate("ionosphere", host, forcenewserver)
  private.id := defaultservers.create(private.agent, "rinex")

# create records for available methods
  private.importRinexRec := [_method="import_rinex",_sequence=private.id._sequence]
  private.importSP3Rec := [_method="import_sp3",_sequence=private.id._sequence]
  private.importTGDRec := [_method="import_tgd",_sequence=private.id._sequence]
  private.importDCBRec := [_method="import_dcb",_sequence=private.id._sequence]
  private.splitMJDRec := [_method="split_mjd",_sequence=private.id._sequence]
  private.getDcbRec := [_method="get_dcb",_sequence=private.id._sequence]

  private.rc := drc;
# get RINEX filename templates from aipsrc
  local xf,xc
  dum := private.rc.find(xf,'gps.rinex.filename',def='@S@D0.@yo');
  dum := private.rc.find(xc,'gps.rinex.filename.compact',def='@S@D0.@yd');
  private.xfilename := xf
  private.xcompact := xc
# get TGD file location from aipsrc
  local xtgd;
  dum := private.rc.find(xtgd,'gps.rinex.tgdfile',def='/aips++/data/gps/gpstgd.dat');
  
#
# define subclasses
#

  #---------------------------------------------------------------
  #
  # rinex::rinexchunk
  #
  #   rinexchunk is a class encapsulating a chunk of RINEX data
  #   Chunks are created by the rinex class.
  #
  #---------------------------------------------------------------
  #
  const private.rinexchunk := function(ref agent,id,ref parent,stats) {
    private := [=]                                                 
    public := [=]                    
  # setup the server process
    private.agent  := ref agent
    private.id     := id
    private.parent := ref parent
  # create records for available methods
    private.tecRec    := [_method="get_tec",_sequence=private.id._sequence]
  # set up stats
    stats.rcv_pos  := dm.position('itrf',dq.quantity(stats.rcv_pos,'m'))
    stats.interval := dq.quantity(stats.interval,'s')
    stats.epoch_begin := dm.epoch('utc',dq.quantity(stats.epoch_begin,'d'))
    stats.epoch_end   := dm.epoch('utc',dq.quantity(stats.epoch_end,'d'))
    private.stats := stats
    
  #---------------------------------------------------------------
  # rinexchunk: public methods
  #---------------------------------------------------------------

  #---------------------------------------------------------------
  # get_stats()
  #   Returns record of stats for this chunk
  #
    public.get_stats := function() {                              
      wider private
      return private.stats
    }
  #---------------------------------------------------------------
  # get_rcv_pos()
  #   Returns receiver position for this chunk
  #
    public.get_rcv_pos := function() {                              
      wider private
      return private.stats.rcv_pos
    }
    
  #---------------------------------------------------------------
  # load_table() - loads the chunk from a RINEX table  
  # not implemented yet
  
  #---------------------------------------------------------------
  # get_tec()
  #   Gets TEC observations available via this chunk.
  #   (If GPS domains etc. are not yet computed, they will be computed
  #   at this point.)
  #   Returns the count of available samples. Samples are stored into 
  #   parameters:
  #      mjd    - epoch (MJD - UTC)
  #      svn    - (integer) SVN
  #      tec    - TEC value, in TECU
  #      stec   - sigma-TEC
  #      stec30 - 30 minute mean sigma-TEC
  #   
    public.get_tec := function(ref mjd,ref svn,ref tec,ref stec,ref stec30,ref domain) {                              
      wider private                                      
      count := defaultservers.run(private.agent, private.tecRec);   
      if( count > 0 ) 
      {
        val mjd := private.tecRec.mjd;
        val svn := private.tecRec.svn;
        val tec := private.tecRec.tec;
        val stec := private.tecRec.stec;
        val stec30 := private.tecRec.stec30;
        val domain := private.tecRec.domain;
      }
      return count;
    }
    
    return public
  } # end of rinexchunk() definition

  #---------------------------------------------------------------
  #
  # rinex::ephchunk
  #
  #   ephchunk is a class encapsulating a chunk of ephemeris data
  #   Chunks are created by the rinex class.
  #   (NB: move all this to rinex.public?)
  #
  #---------------------------------------------------------------
  #
  private.ephchunk := function(ref agent,id,ref parent) {
    private := [=]                                                 
    public := [=]                    
  # setup the server process
    private.agent  := ref agent
    private.id     := id
    private.parent := ref parent
  # create records for available methods
    private.getEphRec    := [_method="get_eph",_sequence=private.id._sequence]
    private.splineEphRec := [_method="spline_eph",_sequence=private.id._sequence]
    private.splineAzElRec:= [_method="spline_azel",_sequence=private.id._sequence]

  #---------------------------------------------------------------
  # ephchunk: public methods
  #---------------------------------------------------------------
  #
  # get_eph(): Gets ephemeris data for an SVN
  #            Stores the ephemeris in ex,ey,ez.
  #            Return value is a vector of ephochs.
  # 
    public.get_eph := function(ref ex,ref ey,ref ez,svn) {
      wider private
      private.getEphRec.svn := svn
      mjd := defaultservers.run(private.agent, private.getEphRec)   
      if( !is_fail(mjd) ) {
        val ex := private.getEphRec.ex
        val ey := private.getEphRec.ey
        val ez := private.getEphRec.ez
      }
      return mjd
    }
  #
  # spline_eph(): Splines epehemeris of an SVN to new time grid 'mjd'.
  #               Stores the ephemeris in ex,ey,ez.
  #               Return value is # of elements in mjd/ex/ey/ez (on success)
  #    
    public.spline_eph := function(ref ex,ref ey,ref ez,svn,mjd) {
      wider private
      private.splineEphRec.svn := svn
      private.splineEphRec.mjd := mjd
      result := defaultservers.run(private.agent, private.splineEphRec)   
      if( !is_fail(result) ) {
        val ex := private.splineEphRec.ex
        val ey := private.splineEphRec.ey
        val ez := private.splineEphRec.ez
      }
      return result
    }
  #
  # spline_azel(): Splines epehemeris of an SVN to new time grid 'mjd',
  #                Converts the to az/el as seen from position 'pos'
  #                (note: pos must be either a position measure, or
  #                an [x,y,z] vector of ITRF coordinates)
  #                Stores the result in az and el.
  #                Return value is # of elements in mjd/az/el (on success)
  #    
    public.spline_azel := function(ref az,ref el,svn,mjd,pos) {
      wider private
      if( is_measure(pos) ) { # position specified as a measure?
        if( pos.type != 'position' )      # check that it's the right measure
          fail 'spline_azel: pos must be a valid position measure, or an [x,y,z] vector'
        if( pos.refer != 'ITRF' )         # force ITRF frame
          pos := dm.measure(pos,'ITRF')
        p := dm.addxvalue(pos)            # get as [x,y,z]
        pos := [ p[1].value,p[2].value,p[3].value ]
      } else {                # else it better be an [x,y,z] vector
        if( length(pos)!=3 || !is_numeric(pos) )
          fail 'spline_azel: pos must be a valid position measure, or an [x,y,z] vector'
      }
      private.splineAzElRec.svn := svn
      private.splineAzElRec.mjd := mjd
      private.splineAzElRec.pos := pos
      result := defaultservers.run(private.agent, private.splineAzElRec)   
      if( !is_fail(result) ) {
        val az := private.splineAzElRec.az
        val el := private.splineAzElRec.el
      }
      return result
    }
  
    return public

  } # end of ephchunk() definition

  #---------------------------------------------------------------
  # rinex: public methods
  #---------------------------------------------------------------

  #---------------------------------------------------------------
  # import_rinex(filename)
  #   Creates a rinexchunk from a RINEX file
  #
  public.import_rinex := function(filename) {                              
    wider private
    wider public
    private.importRinexRec.filename := filename
    id := defaultservers.run(private.agent, private.importRinexRec)   
    if( is_fail(id) ) fail 'import_rinex() failed'
    id2 := defaultservers.add(private.agent, id)
    return private.rinexchunk(private.agent,id2,public,private.importRinexRec.stats)
  }
  
  #---------------------------------------------------------------
  # import_sp3(filename)
  #   Attaches ephemeris data from IGS-SP3 file, returns an ephemeris chunk 
  #
  public.import_sp3 := function(filename) {                              
    wider private
    wider public
    private.importSP3Rec.filename := filename
    id := defaultservers.run(private.agent, private.importSP3Rec)   
    if( is_fail(id) ) fail 'import_sp3() failed'
    id2 := defaultservers.add(private.agent, id)
    return private.ephchunk(private.agent,id2,public)
  }
  
  #---------------------------------------------------------------
  # import_tgd(filename)
  #   Attaches group delay data from a TGD file, returns a TGD record
  #
  public.import_tgd := function(filename) {                              
    wider private;
    wider public;
    private.importTGDRec.filename := filename;
    return defaultservers.run(private.agent, private.importTGDRec);
  }
  
  public.import_dcb := function(filename='') {
    wider private;
    wider public;
    private.importDCBRec.tablename := filename;
    dcbrec := defaultservers.run(private.agent, private.importDCBRec);
    if( is_fail(dcbrec) ) 
    {
      note(paste('Failed to load DCB table',filename),
  	        priority='WARN', origin='rinex');
      private.dcbs := F;
      fail 'Failed to load DCB table';
    } 
    note(paste('Loaded DCB table',filename),
          priority='NORMAL', origin='rinex');
    private.dcbs := dcbrec;
    return private.dcbs;
  }
  
# immediately try to preload DCB data (it should be in global data)
  if( is_fail( public.import_dcb() ) )
    note(spaste('Failed to preload DCB table. Please use\n',
          'rinex.import_dcb() to import a DCB table, or GPS TECs will not be available'), 
  	      priority='WARN', origin='rinex');
  
  #---------------------------------------------------------------
  # raw_dcbs()
  #   Returns all available DCB data as raw tables (i.e. in nanoseconds, not
  #   TECUs)
  #
  const public.raw_dcbs := function () {
    return private.dcbs;
  }
  
  #---------------------------------------------------------------
  # get_dcb(svn,mjd,rms,p1c1=F)
  #   Interpolates P1-P2 DCB for a given SVN and dates
  #   If rms is supplied, returns the RMS in it.
  #   If p1c1 is T, returns P1-C1 instead
  const public.get_dcb := function(svn,dates,ref rms=F,p1c1=F) {
    wider private;
    private.getDcbRec.svn  := svn-1;
    private.getDcbRec.mjd  := epochs_to_mjd(dates);
    private.getDcbRec.p1c1 := p1c1;
    private.getDcbRec.rms  := 0.0;
    res := defaultservers.run(private.agent, private.getDcbRec);
    if( is_fail(res) )
      fail;
    miss := missing();
    if( !miss[3] )
      val rms := dq.quantity(private.getDcbRec.rms,'ns');
    return dq.quantity(res,'ns');  
  }
  
  
  #---------------------------------------------------------------
  # split_mjd(mjd)
  #   Converts MJD (in days) into a record giving year, month, day,
  #   day-of-year, etc.
  #
  public.split_mjd := function(mjd) {                              
#    wider private
#    private.splitMJDRec.mjd := mjd
#    return defaultservers.run(private.agent, private.splitMJDRec)
    return dq.splitdate(dq.quantity(mjd,'d'));
#    s := split(str,':/')
#    return [ year=s[1],month=s[2],monthday=s[3],...
  }
  
  #---------------------------------------------------------------
  # expand_filename(templ,drec,site)
  #   Based on a date record (as returned by split_mjd) and a sitename,
  #   returns the expanded filename. 
  private.expand_filename := function(templ,drec,site) {
    yy := sprintf('%02d',drec.year%100)
    ddd := sprintf('%03d',drec.yearday)
    name := templ
    name =~ eval(spaste('s/@S/',site,'/g'))
    name =~ eval(spaste('s/@Y/',drec.year,'/g'))
    name =~ eval(spaste('s/@y/',yy,'/g'))
    name =~ eval(spaste('s/@D/',ddd,'/g'))
    name =~ eval(spaste('s/@m/',drec.month,'/g'))
    name =~ eval(spaste('s/@d/',drec.monthday,'/g'))
    return name
  }
  
  #----------------------------------------------------------------
  # resolve_rinex(sites,dates)
  #   Retrieves RINEX chunks for given sites and dates.
  #   Uses the fetchallrinex.pl script to first search the local paths, then
  #   the configured ftp sites.
  #   stations: an array of IGS station codes
  #   dates:    an array [or record] of date-thingies. Thingies are handled as:
  #             numeric:  MJD is assumed
  #             string:   Converted via dq.quantity(); UTC is assumed.
  #             quantity: UTC is assumed.
  #             measure:  an epoch measure. 
  # 
  public.resolve_rinex := function(stations,dates) {
    wider private
    wider public
    # resolve the dates into UTC
    mjd := epochs_to_mjd(dates);
    # now, build up string of date specifications
    datespecs := ''
    datestring := ''
    for( d in mjd ) {
      drec := public.split_mjd(d)
      datespecs := paste(datespecs,
        paste(drec.year,drec.yearday,drec.month,drec.monthday,sep=':') )
      datestring := spaste(datestring,
        dq.time(dq.quantity(d,'d'),0,"no_time ymd"),' ')
    }
    # and a string of station codes
    stations := to_lower(paste(stations))
    # log messages
    note(paste('Resolving RINEX files for stations:',stations),
	        priority='NORMAL', origin='resolve_rinex');
    note(paste('and dates:',datestring),
	        priority='NORMAL', origin='resolve_rinex');
    # setup environment for running the fetch script
    # map aipsrc entries into environment variables:
    env_map := [  RINEX_PATH='path',
                  RINEX_CACHE='cache',
                  RINEX_FILENAME='filename',
                  RINEX_FILENAME_COMPACT='filename.compact',
                  RINEX_FTPSITE='ftp.site',
                  RINEX_FTPDIR='ftp.dir',
                  RINEX_FTPDIR_COMPACT='ftp.dir.compact' ];
    cmd := '('
    for( f in field_names(env_map) ) {
      if( private.rc.find(value,spaste('gps.rinex.',env_map[f])) ) {
        cmd := spaste(cmd,'export ',to_upper(f),'=',value,';')
      }
    }
    note(paste('Starting resolver script, please wait'),
	        priority='NORMAL', origin='resolve_rinex');
    # invoke the script
    cmd := paste(cmd,'fetchallrinex.pl',stations,datespecs,')')
    mysh := sh()
    res := mysh.command(cmd)
    mysh.done()
    print cmd,res.lines,res.errlines
    # parse the script output, extract and post messages to log
    for( line in res.lines ) {
      if( line =~ s/^(NORMAL|WARN|SEVERE): (.*)$/$1$$$2/ ) {
        note(line[2],priority=line[1], origin='resolve_rinex:script');
      }
    }
    # if failure, report and exit now
    if( res.status != 0 ) {
      for( line in res.errlines )
        note(line,priority='WARN',origin='resolve_rinex:script')
      note(paste('Resolver script has failed'),
  	        priority='WARN', origin='resolve_rinex')
      fail 'resolver script has failed'
    }
    # now, go through the reported files and attempt to import them
    chunk_vec := [=]
    for( line in res.lines ) {
      if( line =~ s/^(EXISTING|GENERATED): (.*)$/$1$$$2/ ) {
        # try to import        
        chunk := public.import_rinex(line[2])
        if( is_fail(chunk) ) {
          note(paste('Invalid RINEX file',line[2],'skipping'),
	              priority='WARN', origin='resolve_rinex')
        } else {
          # delete file if it was "temporary"
          if( line[1] == 'GENERATED' ){
            note(spaste('Imported ',line[2],', removing'), 
  	            priority='NORMAL', origin='resolve_rinex');
            dos.remove(line[2])
          } else {
            note(spaste('Imported ',line[2]), 
  	            priority='NORMAL', origin='resolve_rinex');
          }
          # add chunk to return-value record
          chunk_vec[ len(chunk_vec)+1 ] := chunk
        }
      }
    }
    return chunk_vec
  } # end of resolve_rinex()
  
  
  #----------------------------------------------------------------
  # gps_week(date,ref weekday)
  # 
  # resolves an MJD (or a vector of MJDs) into a GPS week-number and
  # a weekday
  #
  public.gps_week := function(date,ref weekday) {
    mjd0 := dq.quantity('6jan1980').value   # GPS day 0
    d := floor(date-mjd0)
    val weekday :=  d%7
    return floor(d/7)
  }

  
  #----------------------------------------------------------------
  # resolve_sp3(dates)
  #   Retrieves GPS ephemeris (SP3 files) for given dates.
  #   Uses the fetchsp3.pl script to first search the local paths, then
  #   the configured ftp sites.
  #   dates:    an array [or record] of date-thingies. Thingies are handled as:
  #             numeric:  MJD is assumed
  #             string:   Converted via dq.quantity(); UTC is assumed.
  #             quantity: UTC is assumed.
  #             measure:  an epoch measure. 
  # 
  public.resolve_sp3 := function(dates) {
    wider private
    wider public
    # resolve the dates into UTC
    local gpsday
    mjd := epochs_to_mjd(dates);
    gpsweek := public.gps_week(mjd,weekday=gpsday)
    # now, build up string of date specifications
    datespecs := ''
    datestring := ''
    for( i in 1:len(mjd) ) {
      datespecs := paste(datespecs,
        paste(gpsweek[i],gpsday[i],sep=':') )
      datestring := spaste(datestring,dq.time( dq.quantity(mjd[i],'d'),0,"no_time ymd"),' ')
    }
    # log messages
    note(paste('Resolving SP3 files for dates:',datestring),
	        priority='NORMAL', origin='resolve_sp3');
    # setup environment for running the fetch script
    # map aipsrc entries into environment variables:
    env_map := [  SP3_PATH='path',
                  SP3_CACHE='cache',
                  SP3_FILENAME='filename',
                  SP3_FTPSITE='ftp.site',
                  SP3_FTPDIR='ftp.dir' ]
    cmd := '('
    for( f in field_names(env_map) ) {
      if( private.rc.find(value,spaste('gps.sp3.',env_map[f])) ) {
        cmd := spaste(cmd,'export ',to_upper(f),'=',value,';')
      }
    }
    note(paste('Starting resolver script, please wait'),
	        priority='NORMAL', origin='resolve_sp3');
    # invoke the script
    cmd := paste(cmd,'fetchsp3.pl',datespecs,')')
    mysh := sh()
    res := mysh.command(cmd)
    mysh.done()
#    print cmd,res.lines,res.errlines
    # parse the script output, extract and post messages to log
    for( line in res.lines ) {
      if( line =~ s/^(NORMAL|WARN|SEVERE): (.*)$/$1$$$2/ ) {
        note(line[2],priority=line[1], origin='resolve_sp3:script');
      }
    }
    # if failure, report and exit now
    if( res.status != 0 ) {
      for( line in res.errlines )
        note(line,priority='WARN',origin='resolve_sp3:script')
      note(paste('Resolver script has failed'),
  	        priority='WARN', origin='resolve_sp3')
      fail 'resolver script has failed';
    }
    # now, go through the reported files and attempt to import them
    chunk_vec := [=]
    for( line in res.lines ) {
      if( line =~ s/^(EXISTING|GENERATED): (.*)$/$1$$$2/ ) {
        # try to import        
        chunk := public.import_sp3(line[2])
        if( is_fail(chunk) ) {
          note(paste('Failed to import SP3 file',line[2],'skipping'),
	              priority='WARN', origin='resolve_sp3')
        } else {
          # delete file if it was "temporary"
          if( line[1] == 'GENERATED' ){
            note(spaste('Imported ',line[2],', removing'), 
  	            priority='NORMAL', origin='resolve_sp3');
            dos.remove(line[2])
          } else {
            note(spaste('Imported ',line[2]), 
  	            priority='NORMAL', origin='resolve_sp3');
          }
          # add chunk to return-value record
          chunk_vec[ len(chunk_vec)+1 ] := chunk;
        }
      }
    }
    return chunk_vec;
  } # end of resolve_sp3()
  
  #----------------------------------------------------------------
  # resolve_tec(station,dates)
  #   Resolves continous domains of TEC samples from RINEX data.
  #   Given a station ID and date(s), resolves RINEX and ephemeris data,
  #   converts to TECs, and returns record of records 'tecrec', where 
  #   every element is:
  #     svn       = integer SVN
  #     domain    = integer domain #
  #     pos       = receiver position [a position measure]
  #     mjd[]     = array of MJDs
  #     az[],el[] = arrays of azimuth, elevation
  #     tec[]     = array of TECs
  #     stec[]    = array of TEC errors
  #     stec30[]  = array of 30-minute averaged TEC errors  
  #   ]
  #
  #   dates:    an array [or record] of date-thingies. Thingies are handled as:
  #             numeric:  MJD is assumed
  #             string:   Converted via dq.quantity(); UTC is assumed.
  #             quantity: UTC is assumed.
  #             measure:  an epoch measure. 
  # 
  public.resolve_tec := function(station,dates) {
    wider private;
    wider public;
    tecrec := [=];
    nsamp := 0;
    for( date in dates ) 
    {
      # get RINEX data for this date
      rnx := public.resolve_rinex(station,date);
      if( is_fail(rnx) || !len(rnx) )
      {
        note(spaste('Unable to resolve RINEX for ',station,':',date,', skipping'), 
  	        priority='WARN', origin='resolve_tec');
        next;
      }
      station_pos := rnx[1].get_rcv_pos()
      # get SP3 data for this date
      eph := public.resolve_sp3(date);
      if( is_fail(eph) || !len(eph) )
      {
        note(spaste('Unable to resolve ephemeris for ',date,', skipping'), 
  	        priority='WARN', origin='resolve_tec');
        next;
      }
      # get TECs from RINEX chunk
      local rmjd,rsvn,rtec,rstec,rstec30;
      n := rnx[1].get_tec(rmjd,rsvn,rtec,rstec,rstec30,rdom);
      if( !n ) 
      {
        note(spaste('No TEC samples returned for ',station,':',date,', skipping'), 
  	        priority='WARN', origin='resolve_tec');
        next;
      }
      # split up into SVNs and domains
      svns := 1:max(rsvn);
      domains := 0:max(rdom);
      for( s in svns )
        for( d in domains )
        {
          # find TECs for this domain & SVN
      	  mask := (rsvn==s & rdom==d);
          if( !any(mask) )  # skip if no records
            next;
          # convert ephemeris to az, el
          local az,el;
          if( is_fail(eph[1].spline_azel(az,el,s,rmjd[mask],station_pos)) ) 
          {
            note(spaste('spline_azel failed for SVN ',s,', date',date,', skipping'), 
  	            priority='WARN', origin='resolve_tec');
            next;
          }
          # mask off negative/zero elevations
          subset := seq(len(mask))[mask];
          elmask := el>0;
          subset := subset[elmask];
          el := el[elmask];
          az := az[elmask];
          if( len(subset)<1 )
            next;
          # add record for this domain
          tecrec[len(tecrec)+1] := 
               [ svn=s,domain=d,pos=station_pos,mjd=rmjd[subset],az=az,el=el,
	               tec=rtec[subset],stec=rstec[subset],stec30=rstec30[subset] ];
          nsamp +:= len(az);
        } # next domain/SVN
    } # next date
    n := len(tecrec);
    if( !n )
      fail paste('No TECs found for',station,dates);
    note(spaste('Resolved ',nsamp,' TECs over ',n,' domains'), 
  	      priority='NORMAL', origin='resolve_tec');
    return tecrec;
  }

  return public;
} # end of rinex() definition

#
# Create a defaultserver
#

defaultrinex := rinex();
const defaultrinex := defaultrinex;
const drnx := ref defaultrinex;

#
# Start-up messages
#
if (!is_boolean(drnx)) {
  note('defaultrinex (drnx) ready', 
	 priority='NORMAL', origin='rinex');
};

# Add defaultrinex to the GUI if necessary
if( any(symbol_names(is_record)=='objrepository') &&
    has_field(objrepository, 'notice') ) {
	objrepository.notice('defaultrinex', 'rinex');
};



# testing section
# rnx:=drnx.import_rinex('test.rnx')
# eph:=drnx.import_sp3('test.orb')
# tgd:=drnx.import_tgd('jpl_tgd.dta')

# print 'rnx.get_stats(): ',rnx.get_stats()
# print 'rnx.get_tec(): ',rnx.get_tec(mjd,svn,tec,stec,stec30)
 
#chunk_vec:=drnx.resolve_rinex("wsrt","13mar1998 20jul1998");
#sp3_vec  :=drnx.resolve_sp3("13mar1998");
#tec_vec  :=drnx.resolve_tec("wsrt","20mar2000");
