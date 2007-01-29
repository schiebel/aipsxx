# imagepol.g: Binding to Glish for image polarimetry (imagepol)
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
#   $Id: imagepol.g,v 19.2 2004/08/25 00:58:27 cvsmgr Exp $
#

pragma include once

include 'servers.g'
include 'image.g'
include 'plugins.g'
include 'substitute.g'
include 'misc.g'
include 'serverexists.g'


const imagepoltest := function(which=unset)
{
    eval('include \'imagepolservertest.g\'');
    return imagepolservertest(which=which);
}


const is_imagepol := function (thing)
{
   if (!is_record(thing)) return F;
   if (!has_field(thing, 'type')) return F;
   if (!is_function(thing.type)) return F;
   if (!(thing.type() == 'imagepol')) return F;
   return T;   
}          


# Users aren't to use this.
const _define_imagepol := function (ref agent, id)
{
    if (!serverexists('dms', 'misc', dms)) {
       return throw('The misc server "dms" is not running',
                     origin='imagepol.g');
    }
#
    private := [=]
    private.agent := ref agent;
    private.id := id;
#
# Make this closure an agent so it can emit events.  This
# code should be consolidated within servers.g
#
    public := [=]
    public := defaultservers.init_object(private)
    x := create_agent();
    for (i in field_names(x)) {
       public[i] := x[i];
    }

### Private methods

###
   const private.activateImage := function (id)
   {
      id2 := defaultservers.add(private.agent, id);
      return _define_image(agent, id2)
   }



### Public methods

###
    private.complexlinpolRec := [_method="complexlinpol", _sequence=private.id._sequence]
    const public.complexlinpol := function(outfile)
    {
        wider private; 
        private.complexlinpolRec.outfile := as_string(outfile);
#
        return defaultservers.run(private.agent, private.complexlinpolRec, F);
    }
    const public.clp := public.complexlinpol;

###
    private.complexfraclinpolRec := [_method="complexfraclinpol", _sequence=private.id._sequence]
    const public.complexfraclinpol := function(outfile)
    {
        wider private; 
        private.complexfraclinpolRec.outfile := as_string(outfile);
#
        return defaultservers.run(private.agent, private.complexfraclinpolRec, F);
    }
    const public.cflp := public.complexfraclinpol;

###
    private.depolratioRec := [_method="depolratio", _sequence=private.id._sequence]
    const public.depolratio := function (infile, debias=F, clip=10.0, sigma=unset, outfile=unset)
    {
        wider private; 
#
        if (is_image(infile)) {                                     # Image tool
           rec := infile.id();
           infile2 := spaste('\'ObjectID=', as_string(rec), '\'');
        } else if (is_string(infile)) {                             # String with embedded Image tool
           local rec;
           infile2 := substitute(infile, 'image', idrec=rec);
           if (is_fail(infile2)) fail;
        }
        private.depolratioRec.infile := infile2;
#
        private.depolratioRec.debias := debias;
        private.depolratioRec.clip := clip;
        private.depolratioRec.sigma := sigma;
        if (is_unset(sigma)) private.depolratioRec.sigma := -1;
#
        if (is_unset(outfile)) outfile := '';
        private.depolratioRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.depolratioRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }
    const public.dr := public.depolratio;

###
    const public.done := function()
    {
        wider private, public;
        ok := defaultservers.done(private.agent, public.id());
        if (is_fail(ok)) fail;
        val private := F;
        val public := F;
        return ok;
    }

###
    private.fourierrotationmeasureRec := [_method="fourierrotationmeasure", _sequence=private.id._sequence]
    const public.fourierrotationmeasure := function(complex=unset, amp=unset, 
                                                    pa=unset, real=unset, 
                                                    imag=unset, zerolag0=F)
    {
        wider private;
#
        private.fourierrotationmeasureRec.complex := complex;
        if (is_unset(complex)) private.fourierrotationmeasureRec.complex := '';
#
        private.fourierrotationmeasureRec.amp := amp;
        if (is_unset(amp)) private.fourierrotationmeasureRec.amp := '';
#
        private.fourierrotationmeasureRec.pa := pa;
        if (is_unset(pa)) private.fourierrotationmeasureRec.pa := '';
#
        private.fourierrotationmeasureRec.real := real;
        if (is_unset(real)) private.fourierrotationmeasureRec.real := '';
#
        private.fourierrotationmeasureRec.imag := imag;
        if (is_unset(imag)) private.fourierrotationmeasureRec.imag := '';
#
        private.fourierrotationmeasureRec.zerolag0 := zerolag0;
#
        return defaultservers.run(private.agent, private.fourierrotationmeasureRec, F);
    }
    const public.frm := public.fourierrotationmeasure;

###
    private.fraclinpolRec := [_method="fraclinpol", _sequence=private.id._sequence]
    const public.fraclinpol := function(debias=F, clip=10.0, sigma=unset, outfile=unset)
    {
        wider private; 
        private.fraclinpolRec.debias := debias;
        private.fraclinpolRec.clip := clip;
        private.fraclinpolRec.sigma := sigma;
        if (is_unset(sigma)) private.fraclinpolRec.sigma := -1;
#
        if (is_unset(outfile)) outfile := '';
        private.fraclinpolRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.fraclinpolRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }
    const public.flp := public.fraclinpol;

###
    private.fractotpolRec := [_method="fractotpol", _sequence=private.id._sequence]
    const public.fractotpol := function(debias=F, clip=10.0, sigma=unset, outfile=unset)
    {
        wider private; 
        private.fractotpolRec.debias := debias;
        private.fractotpolRec.clip := clip;
        private.fractotpolRec.sigma := sigma;
        if (is_unset(sigma)) private.fractotpolRec.sigma := -1;
#
        if (is_unset(outfile)) outfile := '';
        private.fractotpolRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.fractotpolRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }
    const public.ftp := public.fractotpol;


###
    const public.id := function()
    {
        wider private;
        if (!has_field(private.id, 'objectid')) {
#
# Add an objectid if necessary. This can happen if the object
# is the result of a method instead of a constructor, 
#
            id := private.id;
            id.objectid := [sequence=id._sequence,pid=id._pid,time=id._time,
                            host=id._host];
            private.id := id;
    
        }
        return private.id.objectid;
    }
 
###
    private.linpolintRec := [_method="linpolint", _sequence=private.id._sequence]
    const public.linpolint := function(debias=F, clip=10.0, sigma=unset, outfile=unset)
    {
        wider private; 
        private.linpolintRec.debias := debias;
        private.linpolintRec.clip := clip;
        private.linpolintRec.sigma := sigma;
        if (is_unset(sigma)) private.linpolintRec.sigma := -1;
#
        if (is_unset(outfile)) outfile := '';
        private.linpolintRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.linpolintRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }
    const public.lpi := public.linpolint;


###
    private.linpolposangRec := [_method="linpolposang", _sequence=private.id._sequence]
    const public.linpolposang := function(outfile=unset)
    {
        wider private;
#
        if (is_unset(outfile)) outfile := '';
        private.linpolposangRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.linpolposangRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }
    const public.lppa := public.linpolposang;

###
    private.makecomplexRec := [_method="makecomplex", _sequence=private.id._sequence]
    const public.makecomplex := function(outfile, real=unset, imag=unset, 
                                         amp=unset, phase=unset)
    {

       wider private;
#
       ok1 := !is_unset(real) && !is_unset(imag);
       ok2 := !is_unset(amp) && !is_unset(phase);
       if (ok1 && ok2) {
          s := spaste ('You should just specify real and imaginary,\n',
                       'or amplitude and phase.  Not all four of them');
          return throw (s, origin='imagepol.makecomplex');
       }
#
       private.makecomplexRec.real := '';
       if (!is_unset(real)) private.makecomplexRec.real := as_string(real);
       private.makecomplexRec.imag := '';
       if (!is_unset(imag)) private.makecomplexRec.imag := as_string(imag);
       private.makecomplexRec.amp  := '';
       if (!is_unset(amp)) private.makecomplexRec.amp := as_string(amp);
       private.makecomplexRec.phase := '';
       if (!is_unset(phase)) private.makecomplexRec.phase := as_string(phase);
       private.makecomplexRec.complex := as_string(outfile);
#
       return defaultservers.run(private.agent, private.makecomplexRec, F);
    }

###
    const public.pol := function(which, debias=F, clip=10.0, sigma=unset, outfile=unset)
#
# Long names are for toolmanager
#
    {
        s := to_upper(which);
        if (s=='LPI' || s=='LINEARLYPOLARIZEDINTENSITY') {
           return public.linpolint(debias=debias, clip=clip, sigma=sigma, outfile=outfile);
        } else if (s=='TPI' || s=='TOTALPOLARIZEDINTENSITY') {
           return public.totpolint(debias=debias, clip=clip, sigma=sigma, outfile=outfile);
        } else if (s=='LPPA' || s=='LINEARLYPOLARIZEDPOSITIONANGLE') {
           return public.linpolposang(outfile=outfile);
        } else if (s=='FLP' || s=='FRACTIONALLINEARPOLARIZATION') {
           return public.fraclinpol(debias=debias, clip=clip, sigma=sigma, outfile=outfile);
        } else if (s=='FTP' || s=='FRACTIONALTOTALPOLARIZATION') {
           return public.fractotpol(debias=debias, clip=clip, sigma=sigma, outfile=outfile);
        } else {
           msg := spaste('Code "', which, '" is unrecognized');
           return throw (msg, origin='imagepol.pol');
        }
    }

###
    private.rotationmeasureRec := [_method="rotationmeasure", _sequence=private.id._sequence]
    const public.rotationmeasure := function(rm=unset, rmerr=unset, pa0=unset,
                                             pa0err=unset, nturns=unset, 
                                             chisq=unset, sigma=unset, 
                                             rmfg=0, rmmax=unset, maxpaerr=unset,
                                             plotter=unset, nx=5, ny=5)
    {
        wider private;
#
        private.rotationmeasureRec.rm := rm;
        if (is_unset(rm)) private.rotationmeasureRec.rm := '';
#
        private.rotationmeasureRec.rmerr := rmerr;
        if (is_unset(rmerr)) private.rotationmeasureRec.rmerr:= '';
#
        private.rotationmeasureRec.pa0 := pa0;
        if (is_unset(pa0)) private.rotationmeasureRec.pa0 := '';
#
        private.rotationmeasureRec.pa0err := pa0err;
        if (is_unset(pa0err)) private.rotationmeasureRec.pa0err:= '';
#
        private.rotationmeasureRec.nturns := nturns;
        if (is_unset(nturns)) private.rotationmeasureRec.nturns := '';
#
        private.rotationmeasureRec.chisq := chisq;
        if (is_unset(chisq)) private.rotationmeasureRec.chisq := '';
#
        private.rotationmeasureRec.sigma := sigma;
        if (is_unset(sigma)) private.rotationmeasureRec.sigma := -1;
#
        private.rotationmeasureRec.rmfg := rmfg;
        if (is_unset(rmfg)) private.rotationmeasureRec.rmfg := 0.0;
#
        private.rotationmeasureRec.rmmax := rmmax;
        if (is_unset(rmmax)) private.rotationmeasureRec.rmmax := 0.0;
#
        private.rotationmeasureRec.maxpaerr := maxpaerr;
        if (is_unset(maxpaerr)) private.rotationmeasureRec.maxpaerr := 1e30;
#
# If it proves to not be able to find the frequency axis, can make this
# a user given argument
#
        private.rotationmeasureRec.axis := -1;
#
        private.rotationmeasureRec.plotter := plotter;
        if (is_unset(plotter)) private.rotationmeasureRec.plotter := '';
        private.rotationmeasureRec.nx := nx;
        private.rotationmeasureRec.ny := ny;
#
        return defaultservers.run(private.agent, private.rotationmeasureRec, F);
    }
    const public.rm := public.rotationmeasure;

###
    private.sigmaRec := [_method="sigma", _sequence=private.id._sequence]
    const public.sigma := function (clip=10.0)
    {
        wider private;
        private.sigmaRec.clip := clip;
        return defaultservers.run(private.agent, private.sigmaRec, F);
    }

###
    private.sigmadepolratioRec := [_method="sigmadepolratio", _sequence=private.id._sequence]
    const public.sigmadepolratio := function (infile, debias=F, clip=10.0, sigma=unset, outfile=unset)
    {
        wider private; 
#
        if (is_image(infile)) {                                     # Image tool
           rec := infile.id();
           infile2 := spaste('\'ObjectID=', as_string(rec), '\'');
        } else if (is_string(infile)) {                             # String with embedded Image tool
           local rec;
           infile2 := substitute(infile, 'image', idrec=rec);
           if (is_fail(infile2)) fail;
        }
        private.sigmadepolratioRec.infile := infile2;
#
        private.sigmadepolratioRec.debias := debias;
        private.sigmadepolratioRec.clip := clip;
        private.sigmadepolratioRec.sigma := sigma;
        if (is_unset(sigma)) private.sigmadepolratioRec.sigma := -1;
#
        if (is_unset(outfile)) outfile := '';
        private.sigmadepolratioRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.sigmadepolratioRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }
    const public.sdr := public.sigmadepolratio;

###
    private.sigmafraclinpolRec := [_method="sigmafraclinpol", _sequence=private.id._sequence]
    const public.sigmafraclinpol := function (clip=10.0, sigma=unset, outfile=unset)
    {
        wider private;
#
        private.sigmafraclinpolRec.clip := clip;
        private.sigmafraclinpolRec.sigma := sigma;
        if (is_unset(sigma)) private.sigmafraclinpolRec.sigma := -1.0;
#
        if (is_unset(outfile)) outfile := '';
        private.sigmafraclinpolRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.sigmafraclinpolRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }
    const public.sflp := public.sigmafraclinpol;

###
    private.sigmafractotpolRec := [_method="sigmafractotpol", _sequence=private.id._sequence]
    const public.sigmafractotpol := function (clip=10.0, sigma=unset, outfile=unset)
    {
        wider private;
        private.sigmafractotpolRec.clip := clip;
        private.sigmafractotpolRec.sigma := sigma;
        if (is_unset(sigma)) private.sigmafractotpolRec.sigma := -1.0;
#
        if (is_unset(outfile)) outfile := '';
        private.sigmafractotpolRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.sigmafractotpolRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }
    const public.sftp := public.sigmafractotpol;
    
###
    private.sigmalinpolintRec := [_method="sigmalinpolint", _sequence=private.id._sequence]
    const public.sigmalinpolint := function (clip=10.0, sigma=unset)
    {
        wider private;
        private.sigmalinpolintRec.clip := clip;
        private.sigmalinpolintRec.sigma := sigma;
        if (is_unset(sigma)) private.sigmalinpolintRec.sigma := -1.0;
        return defaultservers.run(private.agent, private.sigmalinpolintRec, F);
    }
    const public.slpi := public.sigmalinpolint;

###
    private.sigmalinpolposangRec := [_method="sigmalinpolposang", _sequence=private.id._sequence]
    const public.sigmalinpolposang := function (clip=10.0, sigma=unset, outfile=unset)
    {
        wider private;
        private.sigmalinpolposangRec.clip := clip;
        private.sigmalinpolposangRec.sigma := sigma;
        if (is_unset(sigma)) private.sigmalinpolposangRec.sigma := -1.0;
#
        if (is_unset(outfile)) outfile := '';
        private.sigmalinpolposangRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.sigmalinpolposangRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }
    const public.slppa := public.sigmalinpolposang;

###
    private.sigmastokesRec := [_method="sigmastokes", _sequence=private.id._sequence]
    const public.sigmastokes := function (which, clip=10.0)
    {
        s := to_upper(which);
        if (s=='I') {
           return public.sigmastokesi(clip);
        } else if (s=='Q') {
           return public.sigmastokesq(clip);
        } else if (s=='U') {
           return public.sigmastokesu(clip);
        } else if (s=='V') {
           return public.sigmastokesv(clip);
        } else {
           msg := spaste('Stokes "', which, '" is unrecognized');
           return throw (msg, origin='imagepol.sigmastokes');
        }
    }
    const public.ss := public.sigmastokes;


###
    private.sigmastokesiRec := [_method="sigmastokesi", _sequence=private.id._sequence]
    const public.sigmastokesi := function (clip=10.0)
    {
        wider private;
        private.sigmastokesiRec.clip := clip;
        return defaultservers.run(private.agent, private.sigmastokesiRec, F);
    }
    const public.ssi := public.sigmastokesi;

###
    private.sigmastokesqRec := [_method="sigmastokesq", _sequence=private.id._sequence]
    const public.sigmastokesq := function (clip=10.0)
    {
        wider private;
        private.sigmastokesqRec.clip := clip;
        return defaultservers.run(private.agent, private.sigmastokesqRec, F);
    }
    const public.ssq := public.sigmastokesq;

###
    private.sigmastokesuRec := [_method="sigmastokesu", _sequence=private.id._sequence]
    const public.sigmastokesu := function (clip=10.0)
    {
        wider private;
        private.sigmastokesuRec.clip := clip;
        return defaultservers.run(private.agent, private.sigmastokesuRec, F);
    }
    const public.ssu := public.sigmastokesu;

###
    private.sigmastokesvRec := [_method="sigmastokesv", _sequence=private.id._sequence]
    const public.sigmastokesv := function (clip=10.0)
    {
        wider private;
        private.sigmastokesvRec.clip := clip;
        return defaultservers.run(private.agent, private.sigmastokesvRec, F);
    }
    const public.ssv := public.sigmastokesv;

###
    private.sigmatotpolintRec := [_method="sigmatotpolint", _sequence=private.id._sequence]
    const public.sigmatotpolint := function (clip=10.0, sigma=unset)
    {
        wider private;
        private.sigmatotpolintRec.clip := clip;
        private.sigmatotpolintRec.sigma := sigma;
        if (is_unset(sigma)) private.sigmatotpolintRec.sigma := -1.0;
        return defaultservers.run(private.agent, private.sigmatotpolintRec, F);
    }
    const public.stpi := public.sigmatotpolint;

###
    private.stokesiRec := [_method="stokesi", _sequence=private.id._sequence]
    const public.stokesi := function(outfile=unset)
    {
        wider private;
#
        if (is_unset(outfile)) outfile := '';
        private.stokesiRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.stokesiRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }


###
    private.stokesqRec := [_method="stokesq", _sequence=private.id._sequence]
    const public.stokesq := function(outfile=unset)
    {
        wider private;
#
        if (is_unset(outfile)) outfile := '';
        private.stokesqRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.stokesqRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }

###
    private.stokesuRec := [_method="stokesu", _sequence=private.id._sequence]
    const public.stokesu := function(outfile=unset)
    {
        wider private;
#
        if (is_unset(outfile)) outfile := '';
        private.stokesuRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.stokesuRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }

###
    private.stokesvRec := [_method="stokesv", _sequence=private.id._sequence]
    const public.stokesv := function(outfile=unset)
    {
        wider private;
#
        if (is_unset(outfile)) outfile := '';
        private.stokesvRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.stokesvRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }

###
    const public.stokes := function(which, outfile=unset)
    {
        s := to_upper(which);
        if (s=='I') {
           return public.stokesi(outfile);
        } else if (s=='Q') {
           return public.stokesq(outfile);
        } else if (s=='U') {
           return public.stokesu(outfile);
        } else if (s=='V') {
           return public.stokesv(outfile);
        } else {
           msg := spaste('Stokes "', which, '" is unrecognized');
           return throw (msg, origin='imagepol.stokes');
        }
    }

###
    private.summaryRec := [_method="summary", _sequence=private.id._sequence]
    const public.summary := function()
    {
       id := defaultservers.run(private.agent, private.summaryRec, F);
       if (is_fail(id)) fail;
       return id;
    }
###
    private.totpolintRec := [_method="totpolint", _sequence=private.id._sequence]
    const public.totpolint := function(debias=F, clip=10.0, sigma=unset, outfile=unset)
    {
        wider private;
#
        private.totpolintRec.debias := debias;
        private.totpolintRec.clip := clip;
        private.totpolintRec.sigma := sigma;
        if (is_unset(sigma)) private.totpolintRec.sigma := -1;
#
        if (is_unset(outfile)) outfile := '';
        private.totpolintRec.outfile := as_string(outfile);
#
        id := defaultservers.run(private.agent, private.totpolintRec, F);
        if (is_fail(id)) fail;
        return private.activateImage(id);
    }
    const public.tpi := public.totpolint;


###
    const public.type := function ()
    {
       return 'imagepol';
    }

###
    plugins.attach('imagepol', public);
    return ref public;
} # _define_imagepol()



###  Constructors

const imagepol := function(infile, host='', forcenewserver=F)
#
# infile can be image tool, file name, or '$im' where im is 
# and image tool.
#
{
   agent := defaultservers.activate(server='app_image', host=host, 
                                    forcenewserver=forcenewserver, async=F,
                                    terminateonempty=F);
#
   infile2 := '';
   if (is_image(infile)) {
#
# This will let us get at the underlying "image" object
#
      rec := infile.id();
      infile2 := spaste('\'ObjectID=', as_string(rec), '\'');
   } else if (is_string(infile)) {
#
# This means '$im' will work as well as just the file name
# (no substitution in that case)
#
      local rec;
      infile2 := substitute(infile, 'image', idrec=rec);
      if (is_fail(infile2)) fail;
   }
#
   id := defaultservers.create(id=agent, type='imagepol',
                               creator='imagepol',
                               invokerecord=[infile=infile2]);
   if (is_fail(id)) fail;
   ok := ref _define_imagepol(agent, id);
   return ok;
} 


###
const imagepoltestimage := function (outfile, rm=unset, pa0=0.0, sigma=0.01, 
                                     nx=32, ny=32, nf=32, f0=1.4e9, bw=128.0e6, 
                                     host='', forcenewserver=F)
{
   agent := defaultservers.activate(server='app_image', host=host, 
                                    forcenewserver=forcenewserver, async=F,
                                    terminateonempty=F);
#
   if (strlen(outfile)==0) {
      return throw ('You must give an outfile', origin='imagepoltestimage');
   }
#
   rec := [=];
   rec.outfile := outfile;
#
   if (is_unset(rm)) {
      rec.rm := [0.0];
      rec.defaultrm := T;
   } else {
      rec.rm := dms.tovector(rm, 'float');
      if (is_fail(rec.rm)) fail;
      rec.defaultrm := F;
   }
#
   rec.nx := as_integer(nx);
   rec.ny := as_integer(ny);
   rec.nf := as_integer(nf);
   rec.f0 := as_float(f0);
   rec.bw := as_float(bw);
   rec.pa0 := as_float(pa0);
   rec.sigma := as_float(sigma);
#
   id := defaultservers.create(id=agent, type='imagepol', 
                               creator='imagepoltestimage', invokerecord=rec);
   if (is_fail(id)) fail;
   ok := ref _define_imagepol(agent, id);
   return ok;
} 

