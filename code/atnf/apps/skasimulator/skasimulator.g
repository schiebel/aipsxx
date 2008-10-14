# Simulation of AIPS++ measurement set using a C++ server
#

# Copyright (C) 1999,2000
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: skasimulator.g,v 1.4 2005/09/19 04:19:10 mvoronko Exp $

# include guard
if (!is_defined('skasimulator_g_included')) {
    skasimulator_g_included:='yes';

    include 'servers.g'
    include 'quanta.g'
    include 'measures.g'

    const skasimulator:=function(host='',forcenewserver=F) {
          self:=[=];
	  public:=[=];

	  self.agent:=defaultservers.activate("skasimulator",host,forcenewserver);
	  self.id:=defaultservers.create(self.agent,"SKASimulator");
	  self.setLayoutRec:=[_method="setlayout",_sequence=self.id._sequence];

	  # set the layout of interferometer. X,Y,Z are global coordinates of each antenna
	  # diam is a vector with diameters
	  const public.setlayout:=function(x,y,z,diam)
	  {
	      wider self;

	      self.setLayoutRec.x:=x;
	      self.setLayoutRec.y:=y;
	      self.setLayoutRec.z:=z;
	      self.setLayoutRec.diam:=diam;

              return defaultservers.run(self.agent,self.setLayoutRec);
          }

	  self.setSkyModelRec:=[_method="setskymodel",_sequence=self.id._sequence];

	  # set sky model to what is defined by the component list stored in the AIPS++
	  # table with the name passed in the complist parameter
	  const public.setskymodel:=function(complist)
	  {
	     wider self;
	     
	     self.setSkyModelRec.componentlist:=complist;

	     return defaultservers.run(self.agent,self.setSkyModelRec);
	  }

	  self.setCorParamsRec:=[_method="setcorparams",
	                         _sequence=self.id._sequence];
	  # set correlator parameters (averaging time, gap, number of spectral
	  # channels, channel bandwidth)
	  const public.setcorparams:=function(nchannels=1,
	            chbandw=dq.quantity(1,'Hz'),coravg=dq.quantity(10,'s'),
		    corgap=dq.quantity(5,'s'))
          {
	     wider self;
	     self.setCorParamsRec.nchannels:=nchannels;
	     self.setCorParamsRec.chbandw:=chbandw;
	     self.setCorParamsRec.coravg:=coravg;
	     self.setCorParamsRec.corgap:=corgap;

	     return defaultservers.run(self.agent,self.setCorParamsRec);
	  }

	  self.setSidTimesRec:=[_method="setsidtimes",
	                        _sequence=self.id._sequence];

          # set observation times using sidereal time and utcday (epoch)
	  # utcday is used only to get something reasonable in the 
	  # measurement set and can be a dummy value
	  const public.setsidtimes:=function(sidstart=dq.quantity(0,'s'),
	             sidstop=dq.quantity(15,'s'), 
		     utcday=dm.epoch('utc','20Dec2004'))
	  {
	     wider self;
	     self.setSidTimesRec.sidstart:=sidstart;
	     self.setSidTimesRec.sidstop:=sidstop;
	     self.setSidTimesRec.utcday:=utcday;

	     return defaultservers.run(self.agent,self.setSidTimesRec);
	  }

	  self.setTimesRec:=[_method="settimes",
	                     _sequence=self.id._sequence];

          # set observation times using fully specified epoch
	  const public.settimes:=function(start=dm.epoch('utc','53359.d'),
	                        stop=dm.epoch('utc','53359.0002d'))
	  {
	     wider self;
	     self.setTimesRec.start:=start;
	     self.setTimesRec.stop:=stop;

	     return defaultservers.run(self.agent,self.setTimesRec);
	  }

	  
	  self.simulateRec:=[_method="simulate",
	                     _sequence=self.id._sequence];

          # simulate a dataset
	  # fname - name of the disk file
	  # freq  - frequency of the first channel
	  # phasecntr - phase centre
	  const public.simulate:=function(fname, freq, phasecntr =
	          dm.direction('J2000','0h0m0','-50d0m0'))
         {
	     wider self;
	     self.simulateRec.fname:=fname;
	     self.simulateRec.freq:=freq;
	     self.simulateRec.phasecntr:=phasecntr;

	     return defaultservers.run(self.agent,self.simulateRec);
	 }

	  self.setoptionsRec:=[_method="setoptions",
	                     _sequence=self.id._sequence];
          
	  # set options describing what is to be simulated
	  # dosky  - if T, a skymodel will be used to simulate the sky
	  # dobandsmear - if T, bandwidth smearing will be simulated
	  # dotasmear   - if T, time average smearing will be simulated
	  # dorfi       - if T, an RFI model will be simulated
	  # donoise     - if T, noise will be simulated
	  # dovp        - if T, a voltage pattern will be simulated
	  # dodelay     - if T, a residual delay will be simulated
	  #                     (the retarded baseline effect)
	  const public.setoptions:=function(dosky=T, dobandsmear=T,
	            dotasmear=T, dorfi=F, donoise=F, dovp=F, dodelay=F)
	  {
	     wider self;
	     self.setoptionsRec.dosky:=dosky;
	     self.setoptionsRec.dobandsmear:=dobandsmear;
	     self.setoptionsRec.dotasmear:=dotasmear;
	     self.setoptionsRec.dorfi:=dorfi;
	     self.setoptionsRec.donoise:=donoise;
	     self.setoptionsRec.dovp:=dovp;
	     self.setoptionsRec.dodelay:=dodelay;
             
	     return defaultservers.run(self.agent,self.setoptionsRec);
	  }

	  self.setdelaymodelRec:=[_method="setdelaymodel",
			     _sequence=self.id._sequence];

	  # set parameters of the residual delay model (retarded baseline
	  # effect)
	  # Possible values of the input string:
	  #    "all"  simulate all effects currently in the code
	  #    "gravdelayonly" simulate gravitational delay only
	  #    "orbitalonly"  simulate the delay due to the orbital motion
	  #    "diurnalonly"  simulate the delay due to the diurnal rotation
	  #    "orbitalanddiurnal" simulate the delay due to the orbital and
	  #                        diurnal motions
	  const public.setdelaymodel:=function(mode="all")
	  {
	    wider self;
	    self.setdelaymodelRec.mdl:=mode;
	    return defaultservers.run(self.agent,self.setdelaymodelRec);
	  }

	  self.setrfimodelRec:=[_method="setrfimodel",
	                     _sequence=self.id._sequence];
          
	  # set parameters of the RFI model (moving source of the spherical
	  #                                  wave)
	  # flux - RFI flux density at the reference position Rc
	  # Rc   - reference position (use dm.position to define)
	  # Rr   - position of interferor
	  # Rrdot - velocity of interferor specified as an increment of
	  #         its position per a given time unit
	  #         (stationary source is default)
	  # timeunit - any unit of time to specify interferor's velocity
	  #            (second is default)
	  const public.setrfimodel:=function(flux,Rc,Rr,
	              Rrdot=dm.position('ITRF','0m','0m','0m'),
		      timeunit='s')
          {
	     wider self;
	     self.setrfimodelRec.flux:=flux;
	     self.setrfimodelRec.Rc:=Rc;
	     self.setrfimodelRec.Rr:=Rr;
	     self.setrfimodelRec.Rrdot:=Rrdot;
	     self.setrfimodelRec.timeunit:=timeunit;
             
	     return defaultservers.run(self.agent,self.setrfimodelRec);
	  }

	  self.setaddgaussnoiseRec:=[_method="setaddgaussnoise",
	                     _sequence=self.id._sequence];
          
	  # set Additive Gaussian Noise as a noise model
	  # variance is the square root from dispersion. If mean is 0, it
	  #          is the same as rms
	  # mean     is the expectation value (default is 0Jy)
	  const public.setaddgaussnoise:=function(variance,
				 mean=dq.quantity(0.,'Jy'))
	  {
	     wider self;
	     self.setaddgaussnoiseRec.variance:=variance;
	     self.setaddgaussnoiseRec.mean:=mean;

	     return defaultservers.run(self.agent,self.setaddgaussnoiseRec);
	  }

          
	  self.getstatusRec:=[_method="getstatus",
	                     _sequence=self.id._sequence];
          
	  # set Additive Gaussian Noise as a noise model
	  # return a record with the current status of the simulator
	  # The fields of this record are as follows:
	  # layoutset     - T if layout is set, F otherwise
	  # dotasmear     - T if time average smearing will be simulated
	  # dobandsmear   - T if bandwidth smearing will be simulated
	  # nchannels     - Number of spectral channels
	  # chbandw       - Channel Bandwidth (Quantity)
	  # avgtime       - Average Time (Quantity)
	  # dosky         - T if sky model will be simulation
	  #    if T additional fields exist
	  #    skymodelset - T if sky model is set, F otherwise
	  #    nsources    - number of sources in the model
	  # dorfi          - T is an rfi has to be simulated
          #    if T an additional field exists
	  #    rfimodelset - T if rfi model is set, F otherwise
	  # donoise        - T if a noise has to be simulated
	  #    if T an additional field exists
	  #    noisemodelset
	  # in the case of error return F. If bequiet=T, nothing is
	  # printed to the log
	  const public.getstatus:=function(bequiet=F)
	  {
	     wider self;
	     self.getstatusRec.bequiet:=bequiet;
             res:=defaultservers.run(self.agent,self.getstatusRec);
	     if (!res) return F;
	     return self.getstatusRec.status;
	  }

	  self.simresidualdelaysRec:=[_method="simresidualdelays",
	                     _sequence=self.id._sequence];
          
	  # test function (not necessary for the rest of the simulator to work)
	  # simulates the set of differencial delays across the field of view
	  # offsets - array of offsets (in radians) for which the delays are
	  #           calculated
	  # ant1    - the first antenna number (in the current layout)
	  # ant2    - the second antenna number (in the curent layout)
	  # phasecntr - direction to the phase centre
	  # freq    - frequency object
	  const public.simresidualdelays:=function(offsetsx, offsetsy,
	         ant1,ant2,phasecntr,freq=dm.frequency('REST',
		                 dq.quantity(1.4,'GHz')))
	  {
	     wider self;
	     self.simresidualdelaysRec.offsetsx:=offsetsx;
	     self.simresidualdelaysRec.offsetsy:=offsetsy;
	     self.simresidualdelaysRec.ant1:=ant1-1;
	     self.simresidualdelaysRec.ant2:=ant2-1;
	     self.simresidualdelaysRec.phasecntr:=phasecntr;
	     self.simresidualdelaysRec.freq:=freq;
	     res:=defaultservers.run(self.agent,self.simresidualdelaysRec);
	     if (!res) return F;
	     return self.simresidualdelaysRec.delays;
	  }

	  const public.done:=function()
	  {
	      wider self,public;
	      ok:=defaultservers.done(self.agent,self.id.objectid);
	      if (ok) {
	          self:=F;
	          val public:=F;
              }
              return ok;
          }
          return public;
    } #constructor

} #include guard
