### mcmem.g : glish binding for the mcmem DO
###
### Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
### Associated Universities, Inc. Washington DC, USA.
###
### This library is free software; you can redistribute it and/or modify it
### under the terms of the GNU Library General Public License as published by
### the Free Software Foundation; either version 2 of the License, or (at your
### option) any later version.
###
### This library is distributed in the hope that it will be useful, but WITHOUT
### ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
### FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
### License for more details.
###
### You should have received a copy of the GNU Library General Public License
### along with this library; if not, write to the Free Software Foundation,
### Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
###
### Correspondence concerning AIPS++ should be addressed as follows:
###        Internet email: aips2-request@nrao.edu.
###        Postal address: AIPS++ Project Office
###                        National Radio Astronomy Observatory
###                        520 Edgemont Road
###                        Charlottesville, VA 22903-2475 USA
###
###
### $Id: mcmem.g,v 19.2 2004/08/25 01:27:39 cvsmgr Exp $


if (! is_defined('mcmem_g_included')) {    
    mcmem_g_included := 'yes';

include "servers.g"  

######### DEBUG ###########
#defaultservers.suspend(T);
###########################

#################################################
########## Glish-bound Functions ################
#################################################

const _define_mcmem := function(ref agent, id) { 
    self := [=]  
    public := [=] 

    self.agent := ref agent;
    self.id := id;

    self.meminitRec := [_method="initmem",_sequence=self.id._sequence]
    
    public.initmem := function(niter,ineps,inpsf,inwt) 
    {
        wider self
        self.meminitRec.niter := niter
        self.meminitRec.ineps := ineps
        self.meminitRec.inpsf := inpsf
        self.meminitRec.inwt := inwt
        ret := defaultservers.run(self.agent, self.meminitRec)
	return ret
    }

    self.memRec := [_method="mem",_sequence=self.id._sequence]
    
    public.mem := function(inprnum,inprior,indata,ref outimage, ref outfit) 
    {
        wider self
        self.memRec.inprnum := inprnum
        self.memRec.inprior := inprior
        self.memRec.indata := indata
        ret := defaultservers.run(self.agent, self.memRec)
        val outimage := self.memRec.outimage
        val outfit := self.memRec.outfit
	return ret
    }

    self.mcmcRec := [_method="montecarloimage",_sequence=self.id._sequence]
    
    public.montecarloimage := function(instartimage,inpriorimage,nrealize,ref outmeanimage, ref outvarimage, ref outskewimage, ref outkurtimage, ref outnsamples, ref outtrack) 
    {
        wider self
        self.mcmcRec.instartimage := instartimage
        self.mcmcRec.inpriorimage := inpriorimage
        self.mcmcRec.nrealize := nrealize
        ret := defaultservers.run(self.agent, self.mcmcRec)
        val outmeanimage := self.mcmcRec.outmeanimage
        val outvarimage := self.mcmcRec.outvarimage
        val outskewimage := self.mcmcRec.outskewimage
        val outkurtimage := self.mcmcRec.outkurtimage
        val outnsamples := self.mcmcRec.outnsamples
        val outtrack := self.mcmcRec.outtrack
	return ret
    }

    self.mcdataRec := [_method="montecarlodata",_sequence=self.id._sequence]
    
    public.montecarlodata := function(nrealize,insigma,incleandata,ref outmeanimage,ref outvarimage,ref outskewimage,ref outkurtimage) 
    {
        wider self
        self.mcdataRec.nrealize := nrealize
        self.mcdataRec.insigma := insigma
        self.mcdataRec.incleandata := incleandata
        ret := defaultservers.run(self.agent, self.mcdataRec)
        val outmeanimage := self.mcdataRec.outmeanimage
        val outvarimage := self.mcdataRec.outvarimage
        val outskewimage := self.mcdataRec.outskewimage
        val outkurtimage := self.mcdataRec.outkurtimage
	return ret
    }


    public.id := function(){
        wider self;
	return self.id.objectid;
    }


    public.done := function()
    {
        wider self, public;
        ok := defaultservers.done(self.agent, public.id());
        if (ok) {
            self := F;
            val public := F;
        }
        return ok;
    }




    return public

}  # _define_image


##########################################
#### Multiple Constructors ###############
##########################################

const mcmem := function(host='', forcenewserver=F) {
    agent := defaultservers.activate("mcmem", host, forcenewserver)
    id := defaultservers.create(agent, "mcmem","mcmem");
    defaultservers.suspend(F);

    return _define_mcmem(agent,id);

} # mcmem()


const mcmemp := function(pparam=0,host='', forcenewserver=F) {
    agent := defaultservers.activate("mcmem", host, forcenewserver)
    id := defaultservers.create(agent, "mcmem","mcmem",[pparam=pparam]);
    defaultservers.suspend(F);

    return _define_mcmem(agent,id);


} # mcmemp()



}  # include guard

########################################################################
