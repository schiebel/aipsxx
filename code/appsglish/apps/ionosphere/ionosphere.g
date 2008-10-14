# ionosphere.g: Glish proxy for ionosphere DO 
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001
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
#   $Id: ionosphere.g,v 19.2 2004/08/25 01:22:11 cvsmgr Exp $

pragma include once

include "servers.g"
include "iono_utils.g"

#
# constructor
#
const ionosphere := function(host='', forcenewserver = F) {       
  private := [=]                                                 
  public := [=]                                               

# define some ionosphere-related units
  dq.define('TECU','1e+16/(m.m)');
  dq.define('RMU','1deg.GHz.GHz');
  global iono_kpd;
  const iono_kpd := dq.quantity(1.344536,"GHz/TECU");

# activate the server process
  private.agent := defaultservers.activate("ionosphere", host, forcenewserver)
  private.id := defaultservers.create(private.agent, "ionosphere")     

  private.fixed_vals := [=]

#----------------------------------------------------------------------------
# methodrec(methodname,[param,value,][param2,value2,][...])
#   creates record for calling a DO method
  const private.methodrec := function (method,...)
  {
    wider private;
    rec := [ _method=method,_sequence=private.id._sequence ];
    if( num_args(...)>=2 )
      for( i in 1:(num_args(...)/2) )
        rec[nth_arg(i,...)] := nth_arg(i+1,...);
    return rec;
  }
#----------------------------------------------------------------------------
# runmethod(methodname,[param,value,][param2,value2,][...])
#   directly runs method with given parameters
  const private.runmethod := function (method,...)
  {
    wider private;
    return defaultservers.run(private.agent,private.methodrec(method,...));   
  }
  

#----------------------------------------------------------------------------
# debuglevel(level)
#   sets the debug level (default is 0 for none)
  const public.debuglevel := function (level=0)
  {
    wider private;
    return private.runmethod('debuglevel','level',level);   
  }

#----------------------------------------------------------------------------
# slant(ep,pos,dir)
#   This function puts together a slant record suitable for 
#   ionosphere.compute().
#
# ep  specifies the epoch, either as an epoch measure, or a time quantity, 
#     (MJD UTC assumed), or a string quantity, or a numeric MJD.
# pos is a position measure, an observatory name, a numeric vector of lon,lat 
#     (in degrees) and (optionally) altitude (in meters), or a string vector 
#     (suitable for dm.position).
# dir is a direction measure, or a vector of [az,el] -- numerics (in degrees),
#     or string for dm.direction
#
  const public.slant := function(ep=F,pos=F,dir=F) {
    # resolve position
#    print ep,pos,dir;
    mjd := epoch_to_mjd(ep);
    pos := resolve_position(pos,refer='ITRF');
    dir := resolve_direction(dir);
    if( dir.refer != 'AZEL' ) {
      dm.doframe(dm.epoch('utc',dq.quantity(mjd,'d')));
      dm.doframe(pos);
      dir := dm.measure( dir,'azel' );
    }
#    print mjd,pos,dir;
    slrec := [ mjd = mjd,
               pos = pos,
               dir = dir ];
    slrec::id := 'slant';
    return slrec;
  }  
  
#
# define the compute() function
# compute(slrec,...)
#   Inputs: slrec - a vector of "slant" records (from ionosphere.slant())
#           fix   - an optional record to fix specific parameters (rather
#                   then letting them be looked up in tables). Recognized
#                   fields are bz, ap and f107.   
#   Outputs: tec - vector quantity of TECs (TECU=10^16*m^2)
#            rmi - vector quantity of RMIs (RMU=deg*GHz^2)
#            emf - [Nalt,Nsl] quantity of Bpar EMF component
#            lat - vector quantity of latitudes (deg)
#            lon - vector quantity of longtitudes (deg)
#            alt - vector quantity of altitudes (km)
#            rng - vector quantity of ranges (km)
#            pos - vector of position measures (along slant)
#            return value - [Nalt,Nsl] array of EDPs
#
  const public.compute := function(slrec,ref tec=F,ref rmi=F,ref emf=F,ref lon=F,ref lat=F,ref alt=F,ref rng=F,ref edp=F,opt=F,ref isuniq=F) { 
    wider private;
# see which information the caller wants returned
    m := missing()
    want := [ tec=!m[2],rmi=!m[3],emf=!m[4],lon=!m[5],lat=!m[6],
              alt=!m[7],rng=!m[8],edp=!m[9],isuniq=!m[10] ];
# check for valid slants    
    if( !is_record(slrec) )
      fail 'slant() objects expected';
    if( slrec::id == 'slant' )  # only one slant? convert into "vector"
      slrec := [ dum=slrec ];
# stuff the slants record into an (N,6) array suitable for the agent
    nsl := len( slrec )
    sl := array( 0.0,nsl,6 )
    for( i in 1:nsl ) {
      if( !is_record(slrec[i]) || slrec[i]::id != 'slant' )
        fail 'slant() objects expected';
# stuff numbers into the sl matrix
      sl[i,1] := slrec[i].mjd;
      pos := dm.addxvalue(slrec[i].pos);
      sl[i,2:4] := [pos[1].value,pos[2].value,pos[3].value];
      sl[i,5:6] := [slrec[i].dir.m0.value,slrec[i].dir.m1.value];
    }
    mrec := private.methodrec('compute');
    mrec['slants'] := sl;
    for( f in "tec rmi lon lat alt rng emf isuniq" ) 
      mrec[f] := 0.0;
    if( !is_record(opt) )
      opt := [=];
    mrec['opt'] := opt;
    
    ed := defaultservers.run(private.agent, mrec)   
    if( is_fail(ed) )
      fail;
  
    if( want.edp ) val edp := dq.quantity(ed,'TECU');
    if( want.tec ) val tec := dq.quantity(mrec.tec,'TECU');
    if( want.rmi ) val rmi := dq.quantity(mrec.rmi,'RMU' );
    if( want.lon ) val lon := dq.quantity(mrec.lon,'deg' );
    if( want.lat ) val lat := dq.quantity(mrec.lat,'deg' );
    if( want.alt ) val alt := dq.quantity(mrec.alt,'km' );
    if( want.rng ) val rng := dq.quantity(mrec.rng,'km' );
    if( want.emf ) val emf := dq.quantity(mrec.emf,'G' );
    if( want.emf ) val emf := dq.quantity(mrec.emf,'G' );
    if( want.isuniq ) val isuniq := mrec.isuniq;
    
    return T;
  }
  
#----------------------------------------------------------------------------
# get_fr(rmi,freq,units)
#
# This function computes the FR at a given frequency.
#
# rmi    is either a string/quantity, or a numeric ('RMU' units assumed)
# freq   is either a string/quantity, or a numeric (GHz addumed)
# units  specifies the output units. Default is canonical units ("rad").
#
  const public.get_fr := function(rmi,freq,units=F) {
    if( is_numeric(rmi) )
      rmi := dq.quantity(rmi,'RMU');
    if( is_numeric(freq) )
      freq := dq.quantity(freq,'GHz');
    fr:=dq.div(rmi,dq.mul(freq,freq));
    if( is_string(units) )
      return dq.convert(fr,units);
    return dq.canon(fr);
  }

# get_phdel(tec,freq,units)
#
# This function computes the phase delay at a given frequency.
#
# tec    is either a string/quantity, or a numeric ('TECU' units assumed)
# freq   is either a string/quantity, or a numeric (GHz addumed)
# units  specifies the output units. Default is cycles, and the return value
#        is a numeric (no units!). If you want the phase delay in units of time,
#        specify a time unit.  If you want the phase delay in degrees or radians,
#        specify an angle unit.
#
  const public.get_phdel := function(tec,freq,units=F) {
    if( is_numeric(tec) )
      tec := dq.quantity(tec,'TECU');
    if( is_numeric(freq) )
      freq := dq.quantity(freq,'GHz');
    # resolve output units to canonicals
    if( is_boolean(units) )
     canon_units := '';
    else {
      canon_units := dq.canon(units).unit;
      if( canon_units == '' )
        fail paste('unknown output unit:',units);
    }
    # compute phase delay in cycles
    pd := dq.mul(iono_kpd,dq.div(tec,freq));
    # if time units requested, then divide by frequency again
    if( canon_units == 's' )
      return dq.convert(dq.div(pd,freq),units);
    # if angle requested, multiply by 2pi and convert
    if( canon_units == 'rad' )  # should we convert to angle?
    {
      pd.value := pd.value * 2 * dq.constants('pi').value;
      pd.unit := 'rad';
      return dq.convert(pd,units);
    }
    return dq.canon(pd).value;
  }
  
  # track_fr
  #   Tracks a source from _location_ (pos. measure or observatory)
  #   and at given _direction_ (measure), over a period starting from
  #   _ep0_ (MJD/string/epoch measure), and a duration of _dur_ (numeric
  #   hours or string/time quantity). Recomputes the ionosphere every 
  #   _spacing_ (numeric hours or string/time quantity).
  #   _freq_ is frequency for which FR is computed.
  #   _opt_ is a record of PIM options. Several runs with different
  #       options may be requested by using a record of records.
  #   _alt0_ is an altitude at which Bpar will be returned
  #   Returns a record of:
  #     mjd:     [N]        Sampled MJDs
  #     hours:   [N]        Sampled U.T. hours
  #     fr:      [N,M]      Faraday rotations (degrees)
  #     tec:     [N,M]      TECs (in TECUs)
  #     az/el/ha:[N]        azimuths/elevations/hour angles (degrees)
  #     edp:     [Np,N,M]   ionospheric profiles
  #     alt:     [Np,N,M]   sampling altitudes of each profile
  #     bpar:    [Np,N,M]   corresponding Bpar components
  #     bpar0:   [N,M]      Bpar component at the _alt0_ altitude
  #   Here, N is the number of sampled times, M is the number of runs
  #   (as specified by _opt_), and Np is the number of vertical sampling points
  #
  const public.track_fr := function(location,direction,ep0,
                                    dur=24,spacing=.5,alt0=350,
                                    freq='1GHz',opt=F) 
  {
    wider public;
  # resolve location
    location := resolve_position(location);
    if( is_fail(location) )
      fail 'Bad location';
  # resolve direction
    direction := resolve_direction(direction);
    if( is_fail(direction) )
      fail 'Bad direction';
    local desc := paste(dm.dirshow(location),'->',dm.dirshow(direction),ep0);  
  # resolve ep0
    local mjd1 := epoch_to_mjd(ep0);
    if( is_fail(mjd1) )
      fail 'Bad starting epoch';
  # resolve duration
    dur := time_to_hours(dur);
    spacing := time_to_hours(spacing);
    if( is_fail(dur) || is_fail(spacing) )
      fail 'Bad duration or spacing';
  # build array of MJDs and hours
    nmjd := as_integer(dur/spacing); # sample every 1/2 hour
    hours := (0:(nmjd-1))*spacing;
    mjds := mjd1 + hours/24.0;
    hours +:= dq.splitdate(dq.quantity(mjd1,'d')).hour;
  # figure out how many option sets were specified
    local options := [opt=F];
    if( is_record(opt) ) 
    {
      if( is_record(opt[1]) )  # several option sets specified
        options := opt;
      else
        options[1] := opt;
    }
    local nopt := len(options);
    if( nopt>1 )
      desc := spaste(desc,', ',nopt,' runs');
    note(paste('Tracking FR for',desc),origin='ionosphere');
  # build record of slants    
    bpar := el := az := ha := array(0.,nmjd);
    slants := [=];
    for( i in 1:nmjd )
    {
      slants[i] := public.slant(mjds[i],location,direction);
      dd := dm.getvalue(slants[i].dir);
      az[i] := dq.convert(dd[1],'deg').value;
      el[i] := dq.convert(dd[2],'deg').value;
      dd := dm.getvalue(dm.measure(slants[i].dir,'hadec'));
      ha[i] := dq.convert(dd[1],'deg').value;
    }
  # compute everything
    tec := fr := array(0.,nmjd,nopt);
    for( i in 1:nopt )
    {
      print 'Computing slants for options: ',options[i];
      public.compute(slants,tecq,rmi,alt=alt,emf=emf,edp=edp,opt=options[i]);
      fr[,i] := public.get_fr(rmi,freq,'deg').value;
      tec[,i] := tecq.value;
      # get Bpar at altitude
      if( i==1 )
      {
        wh := where(alt.value[,1]>=alt0);
        if( len(wh) )
          bpar := emf.value[wh[1],];
        nalt := alt.value::shape[1];
        edps := alts := emfs := array(0.,nalt,nmjd,nopt);
      }
      edps[,,i] := edp.value;
      emfs[,,i] := emf.value;
      alts[,,i] := alt.value;
    }
  # return record of results
    return [ fr=fr,tec=tec,az=az,el=el,ha=ha,
             edp=edps,emf=emfs,alt=alts,
             bpar0=bpar,mjd=mjds,hours=hours ];
  }

  return public;
} # end of ionosphere constructor


#
# Create a defaultserver
#

defaultionosphere := ionosphere()
const defaultionosphere := defaultionosphere
const diono := ref defaultionosphere

#
# Start-up messages
#
if (!is_boolean(diono)) {
  note('defaultionosphere (diono) ready', 
	 priority='NORMAL', origin='ionosphere');
};

# Add defaultionosphere to the GUI if necessary
if( any(symbol_names(is_record)=='objrepository') &&
    has_field(objrepository, 'notice') ) {
	objrepository.notice('defaultionosphere', 'ionosphere');
};

# global ip := iono_plot(F,640,480);
# fr := read_value('fr.glsav');
# # ip.azel(fr.hours,fr.az,fr.el,elci=2,tlab='Azimuth/Elevation');
# 
# const test2 := function ()
# {
#   global fr:=diono.track_fr('WSRT',dm.direction('b1950','6h40m','40deg'),'1jan2000');
#   write_value(fr,'fr.glsav');
# }
# const test := function ()
# {
# #  global fr:=diono.track_fr('WSRT',dm.direction('b1950','6h40m','40deg'),'1jan2000');
#   
#   ip.pg->subp(1,3);
#   ip.azel(fr.hours,fr.az,fr.el,azls=1,tlab='Azimuth/Elevation');
#   ip.frtec(fr.hours,fr.fr,fr.tec);
#   ip.bparalt(fr.hours,fr.bpar,fr.alt);
# }
# 
# # test
# # rec:=[=];
# # rec[1]:=diono.slant('22jul1988','wsrt',"0deg 30deg");
# # rec[2]:=diono.slant('22jul1988','wsrt',"0deg 60deg");
# # print rec;
# # diono.compute(rec,tec=tec1,rmi=rmi1,emf=emf,alt=alt,edp=edp1,fix=[bz=1]);
