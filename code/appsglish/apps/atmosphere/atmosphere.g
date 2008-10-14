# atmosphere.g: Glish proxy for atmosphere DO 
# give users access to atmosphere calculations in glish
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


pragma include once

include "servers.g";
include "table.g";
include "quanta.g";
include "misc.g";

#defaultservers.suspend(T)
#defaultservers.trace(T)

##############################################################################
# Private function used by constructor
#
const _define_atmosphere := function(altitude, temperature, pressure, maxAltitude, humidity, dTem_dh, dP, dPm, h0, atmtype, ref agent, id) {

   self:= [=];
   public:= [=];

   self.agent:= ref agent;
   self.id:= id;
   self.altitude:= altitude;
   self.temperature:= temperature;
   self.pressure:= pressure;
   self.maxAltitude:= maxAltitude;
   self.humidity:= humidity;
   self.dTem_dh:= dTem_dh;
   self.dP:= dP;
   self.h0:= h0;
   self.atmtype:= atmtype;
#-----------------------------------------------------------------------------

# Method: getStartupWaterContent()
#
   self.getStartupWaterContentRec:= [_method = "getStartupWaterContent", _sequence = self.id._sequence];
   public.getStartupWaterContent:= function () {
#
      wider self;
      return defaultservers.run (self.agent, self.getStartupWaterContentRec);
    }
#-----------------------------------------------------------------------------

# Method: getProfile()
#
   self.getProfileRec:= [_method = "getProfile", _sequence = self.id._sequence];
##   public.getProfile:= function (  ref thickness=unset, ref temperature=unset, ref water=unset, ref pressure=unset, ref O3=unset, ref CO=unset, ref N2O=unset ) {
     public.getProfile:= function ( ref thickness , ref temperature, ref water, ref pressure, ref O3, ref CO, ref N2O ) {
#
      wider self;
      
      self.getProfileRec.thickness:= thickness;
      self.getProfileRec.temperature:= temperature;
      self.getProfileRec.water:= water;
      self.getProfileRec.pressure:= pressure;
      self.getProfileRec.O3:= O3;
      self.getProfileRec.CO:= CO;
      self.getProfileRec.N2O:= N2O;
##
      returnval := defaultservers.run (self.agent, self.getProfileRec);
##
      val thickness := dq.quantity(self.getProfileRec.thickness);
      val temperature := dq.quantity(self.getProfileRec.temperature);
      val water := dq.quantity(self.getProfileRec.water);
      val pressure := self.getProfileRec.pressure;
      val O3 := self.getProfileRec.O3;
      val CO := self.getProfileRec.CO;
      val N2O := self.getProfileRec.N2O;
      return returnval;
    }
#-----------------------------------------------------------------------------------------------------------

# Method: initWindow()
#
   self.initWindowRec:= [_method = "initWindow", _sequence = self.id._sequence];
   public.initWindow:= function ( nbands=1, fCenter='88.e9Hz', fWidth='5.0e8Hz', fRes='1.25e8Hz' ) {
#
      wider self;
      
      self.initWindowRec.nbands:= nbands;
      self.initWindowRec.fCenter:= fCenter;
      self.initWindowRec.fWidth:= fWidth;
      self.initWindowRec.fRes:= fRes;
      
      return defaultservers.run (self.agent, self.initWindowRec);
    }
#-----------------------------------------------------------------------------------------------------------
#
# Method: getNdata()
#
   self.getNdataRec:= [_method = "getNdata", _sequence = self.id._sequence];
   public.getNdata:= function ( iband=1 ) {
#
      wider self;
      
      self.getNdataRec.iband:= iband; #identifier of band
      return defaultservers.run (self.agent, self.getNdataRec);
    }
#
#-----------------------------------------------------------------------------
#
# Method: getOpacity()
#
   self.getOpacityRec:= [_method = "getOpacity", _sequence = self.id._sequence];
   public.getOpacity:= function ( ref dryOpacity, ref wetOpacity ) {
#
      wider self;
      self.getOpacityRec.dryOpacity := dms.tovector(dryOpacity,'double'); 
      self.getOpacityRec.wetOpacity := dq.quantity(wetOpacity); 
      #note('About to call run()', priority='WARN', origin='atmosphere.getOpacity');
##
      returnval:= defaultservers.run (self.agent, self.getOpacityRec);
##
      val dryOpacity := self.getOpacityRec.dryOpacity;  
      val wetOpacity := self.getOpacityRec.wetOpacity;  
      
      return returnval;
    }

#-----------------------------------------------------------------------------

# Method: getOpacitySpec()
#
   self.getOpacitySpecRec:= [_method = "getOpacitySpec", _sequence = self.id._sequence];
   public.getOpacitySpec:= function ( ref dryOpacitySpec, ref wetOpacitySpec ) {
#
      wider self;
      self.getOpacitySpecRec.dryOpacitySpec := dryOpacitySpec;
      self.getOpacitySpecRec.wetOpacitySpec := dq.quantity(wetOpacitySpec);
##
      returnval := defaultservers.run (self.agent, self.getOpacitySpecRec);
##
      val dryOpacitySpec := self.getOpacitySpecRec.dryOpacitySpec;
      val wetOpacitySpec := self.getOpacitySpecRec.wetOpacitySpec;
      return returnval;
    }

#-----------------------------------------------------------------------------

# Method: getAbsCoeff()
#
   self.getAbsCoeffRec:= [_method = "getAbsCoeff", _sequence = self.id._sequence];
   public.getAbsCoeff:= function ( ref kH2OLines, ref kH2OCont, ref kO2, ref kDryCont, ref kO3, ref kCO, ref kN2O ) {
#
      wider self;
      self.getAbsCoeffRec.kH2OLines:= kH2OLines;
      self.getAbsCoeffRec.kH2OCont:= kH2OCont;
      self.getAbsCoeffRec.kO2:= kO2;
      self.getAbsCoeffRec.kDryCont:= kDryCont;
      self.getAbsCoeffRec.kO3:= kO3;
      self.getAbsCoeffRec.kCO:= kCO;
      self.getAbsCoeffRec.kN2O:= kN2O;
      returnval := defaultservers.run (self.agent, self.getAbsCoeffRec);
##
      val kH2OLines := self.getAbsCoeffRec.kH2OLines;
      val kH2OCont := self.getAbsCoeffRec.kH2OCont;
      val kO2 := self.getAbsCoeffRec.kO2;
      val kDryCont := self.getAbsCoeffRec.kDryCont;
      val kO3 := self.getAbsCoeffRec.kO3;
      val kCO := self.getAbsCoeffRec.kCO;
      val kN2O := self.getAbsCoeffRec.kN2O;
      return returnval;
    }

#-----------------------------------------------------------------------------

# Method: getAbsCoeffDer()
#
   self.getAbsCoeffDerRec:= [_method = "getAbsCoeffDer", _sequence = self.id._sequence];
   public.getAbsCoeffDer:= function ( ref kH2OLinesDer, ref kH2OContDer, ref kO2Der, ref kDryContDer, ref kO3Der, ref kCODer, ref kN2ODer ) {
#
      wider self;
      self.getAbsCoeffDerRec.kH2OLinesDer:= kH2OLinesDer;
      self.getAbsCoeffDerRec.kH2OContDer:= kH2OContDer;
      self.getAbsCoeffDerRec.kO2Der:= kO2Der;
      self.getAbsCoeffDerRec.kDryContDer:= kDryContDer;
      self.getAbsCoeffDerRec.kO3Der:= kO3Der;
      self.getAbsCoeffDerRec.kCODer:= kCODer;
      self.getAbsCoeffDerRec.kN2ODer:= kN2ODer;
      returnval := defaultservers.run (self.agent, self.getAbsCoeffDerRec);
## 
      val kH2OLinesDer := self.getAbsCoeffDerRec.kH2OLinesDer;
      val kH2OContDer := self.getAbsCoeffDerRec.kH2OContDer;
      val kO2Der := self.getAbsCoeffDerRec.kO2Der;
      val kDryContDer:= self.getAbsCoeffDerRec.kDryContDer;
      val kO3Der := self.getAbsCoeffDerRec.kO3Der;
      val kCODer := self.getAbsCoeffDerRec.kCODer;
      val kN2ODer := self.getAbsCoeffDerRec.kN2ODer;
      return returnval;
    }
#-----------------------------------------------------------------------------

# Method: getPhaseFactor()
#
   self.getPhaseFactorRec:= [_method = "getPhaseFactor", _sequence = self.id._sequence];
   public.getPhaseFactor:= function ( ref dispPhase, ref nonDispPhase ) {
#
      wider self;
      self.getPhaseFactorRec.dispPhase:= dispPhase;
      self.getPhaseFactorRec.nonDispPhase:= nonDispPhase;
      returnval := defaultservers.run (self.agent, self.getPhaseFactorRec);
##
      val dispPhase := self.getPhaseFactorRec.dispPhase;
      val nonDispPhase := self.getPhaseFactorRec.nonDispPhase;
      return returnval;
    }
#--------------------------------------------------------------------------------------------------

# Method: computeSkyBrightness()
#
   self.computeSkyBrightnessRec:= [_method = "computeSkyBrightness", _sequence = self.id._sequence];
   public.computeSkyBrightness:= function ( airMass=1.51, tbgr='2.73K', precWater='4.05e-3m' ) {
#
      wider self;
      
      self.computeSkyBrightnessRec.airMass:= airMass;
      self.computeSkyBrightnessRec.tbgr:= tbgr;
      self.computeSkyBrightnessRec.precWater:= precWater;
      
      return defaultservers.run (self.agent, self.computeSkyBrightnessRec);
    }
#--------------------------------------------------------------------------------------------------

# Method: getSkyBrightness()
#
   self.getSkyBrightnessRec:= [_method = "getSkyBrightness", _sequence = self.id._sequence];
   public.getSkyBrightness:= function ( iopt=1) {
#
      wider self;
      
      self.getSkyBrightnessRec.iopt:= iopt;
      return defaultservers.run (self.agent, self.getSkyBrightnessRec);
    }
#-----------------------------------------------------------------------------

# Method: getSkyBrightnessSpec()
#
   self.getSkyBrightnessSpecRec:= [_method = "getSkyBrightnessSpec", _sequence = self.id._sequence];
   public.getSkyBrightnessSpec:= function ( iopt=1 ) {
#
      wider self;
      
      self.getSkyBrightnessSpecRec.iopt:= iopt;
      return defaultservers.run (self.agent, self.getSkyBrightnessSpecRec);
    }
##
#-----------------------------------------------------------------------------

# Method: setSkyCoupling()
#
   self.setSkyCouplingRec:= [_method = "setSkyCoupling", _sequence = self.id._sequence];
   public.setSkyCoupling:= function ( c=1.0 ) {
#
      wider self;
      
      self.setSkyCouplingRec.c:= c;
      return defaultservers.run (self.agent, self.setSkyCouplingRec);
    }
#-----------------------------------------------------------------------------

# Method: getSkyCoupling()
#
   self.getSkyCouplingRec:= [_method = "getSkyCoupling", _sequence = self.id._sequence];
   public.getSkyCoupling:= function () {
#
      wider self;
      return defaultservers.run (self.agent, self.getSkyCouplingRec);
    }
#
#-----------------------------------------------------------------------------
# Method: type
#
    public.type := function() {
	return 'atmosphere';
    };

#-----------------------------------------------------------------------------
# Method: id
#
    public.id := function() {
       wider self;
       return self.id.objectid;
    };

#-----------------------------------------------------------------------------
# Method: done
#
    public.done := function() {
       wider self, public;
       ok := defaultservers.done(self.agent, public.id());
       if (ok) {
           self := F;
           val public := F;
       }
       return ok;
    };


   return public;

} #_define_atmosphere()
#
##############################################################################
# Constructor: create a new server for each invocation
#
   const atmosphere:= function (altitude='2550.0m', temperature='270.32K', 
                                pressure='73585Pa', maxAltitude='45000m',
                                humidity=20, dTem_dh='-0.0056K/m', dP='500Pa',
                                dPm=1.25, h0='2000m', atmtype=2, host = '',
                                forcenewserver = T) {
      agent:= defaultservers.activate ("atmosphere", host, forcenewserver);
      id:= defaultservers.create (agent, "atmosphere", "atmosphere", 
         [altitude = altitude, temperature = temperature, pressure = pressure,
          maxAltitude = maxAltitude, humidity = humidity, dTem_dh = dTem_dh,
          dP = dP, dPm =dPm, h0 = h0, atmtype = atmtype ]);
      return _define_atmosphere (altitude, temperature, pressure, maxAltitude, humidity, dTem_dh, dP, dPm, h0, atmtype, agent, id);
    };

##############################################################################