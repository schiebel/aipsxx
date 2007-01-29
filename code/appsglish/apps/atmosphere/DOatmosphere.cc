//# DOatmosphere.cc: Implementation of DOatmosphere.h
//# Copyright (C) 1996,1997,1998,1999,2000,2001
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#

#include <appsglish/atmosphere/DOatmosphere.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Utilities/DataType.h>
#include <tasking/Tasking/Index.h>

namespace casa { //# Begin casa namespace

//Utility methods
void toStdVec(Vector<Double> &a, std::vector<double> &s) {
  int len;
  a.shape(len);
  s.resize(len);
  for (int i=0; i < len; i++)
    s[i]=a[i];
}

Vector<Double> rtnAIPS2Vec(std::vector<double> &s) {
  int len = s.size();
  Vector<Double> r(len);
  for (int i=0; i < len; i++)
    r[i]=s[i];
  return r;
}

void toAips2Vec(std::vector<double> &s, Vector<Double> &a) {
  int len = s.size();
  a.resize(len);
  for (int i=0; i < len; i++)
    a[i]=s[i];
}

Quantum<Vector<Double> > rtnQVD(std::vector<double> &vval, const char *unit) {
  int len=vval.size();
  Vector<Double> V(len);
  for (int i=0; i< len; i++) {
    V[i]=vval[i];
  }
  return Quantum<Vector<Double> > (V,unit);
}

Quantum<Array<Double> > rtnQAD(std::vector<vector<double> > &aval,
			       const char *unit) {
  int leni = aval.size();
  int lenj = (aval[0]).size(); //aval is a matrix but must be passed
  IPosition Index(2,leni,lenj);//as an array in runMethod().
  Array<Double> A(Index);
  for (int i=0; i < leni; i++) {
    //int len2 = (aval[i]).size(); // (aval[i]).size() is constant
    for (int j=0; j < lenj; j++) {
      Index(0) = i;
      Index(1) = j;
      A(Index)=aval[i][j];
    }
  }
  return Quantum<Array<Double> > (A,unit);
}

// Constructor
atmosphere::atmosphere(const Quantity &altitude, 
		       const Quantity &temperature,
		       const Quantity &pressure,
		       const Quantity &maxAltitude,
		       const Double &humidity,
		       const Quantity &dTem_dh,
		       const Quantity &dP,
		       const Double &dPm,
		       const Quantity &h0,
		       const Int &atmType) {
  itsAtm= new Atmosphere(altitude.getValue("m"), temperature.getValue("K"),
			 pressure.getValue("Pa"), maxAltitude.getValue("m"),
			 humidity, dTem_dh.getValue("K/m"),
			 dP.getValue("Pa"), dPm, h0.getValue("m"),
			 (AtmType)atmType);
}

atmosphere::~atmosphere() {};

Quantity atmosphere::getStartupWaterContent() const {
  return( Quantity((itsAtm->getStartupWaterContent()),"m") );
}

void  atmosphere::getProfile(Quantum<Vector<Double> > &thickness,
			     Quantum<Vector<Double> > &temperature,
			     Quantum<Vector<Double> > &water,
			     Quantum<Vector<Double> > &pressure,
			     Quantum<Vector<Double> > &O3,
			     Quantum<Vector<Double> > &CO,
			     Quantum<Vector<Double> > &N2O) const {
  Profile p;
  itsAtm->getProfile( p );
  thickness=rtnQVD(p.thickness_m,"m");
  temperature=rtnQVD(p.temperature_m,"K");
  water=rtnQVD(p.water_m,"kg.m-3");
  pressure=rtnQVD(p.pressure_m,"Pa");
  O3=rtnQVD(p.O3_m,"m-3");
  CO=rtnQVD(p.CO_m,"m-3");
  N2O=rtnQVD(p.N2O_m,"m-3");
}

void atmosphere::initWindow(const Int nbands,
			    const Quantum<Vector<Double> > &fCenter,
			    const Quantum<Vector<Double> > &fWidth,
			    const Quantum<Vector<Double> > &fRes) {
  double f_Center[nbands];
  double f_Width[nbands];
  double f_Res[nbands];
  for (Int i=0; i < nbands; i++) f_Center[i] = (fCenter.getValue("Hz"))[i];
  for (Int i=0; i < nbands; i++) f_Width[i] = (fWidth.getValue("Hz"))[i];
  for (Int i=0; i < nbands; i++) f_Res[i] = (fRes.getValue("Hz"))[i];
  itsAtm->initWindow(nbands,f_Center,f_Width,f_Res);
}

Int atmosphere::getNdata(const Int iband) const {
  return( itsAtm->getNdata(iband) );
}

void atmosphere::getOpacity(Vector<Double> &dryOpacity, Quantum<Vector<Double> > &wetOpacity) const {
  Opacity opacity;
  itsAtm->getOpacity(opacity);
  toAips2Vec(opacity.dryOpacity_m, dryOpacity);
  wetOpacity = rtnQVD(opacity.wetOpacity_m, "mm-1");
}

void atmosphere::getOpacitySpec(Array<Double> &dryOpacitySpec,
				    Quantum<Array<Double> > &wetOpacitySpec) const {
  OpacitySpec o;
  itsAtm->getOpacitySpec(o);

  int leni = o.dryOpacitySpec_m.size();
  int lenj = (o.dryOpacitySpec_m[0]).size(); //dryOpacitySpec is a matrix
  IPosition Index(2,leni,lenj);
  dryOpacitySpec.resize(Index);
  for (int i=0; i < leni; i++) {
    //int len2 = (o.dryOpacitySpec_m[i]).size(); //constant
    for (int j=0; j < lenj; j++) {
      Index(0) = i;
      Index(1) = j;
      dryOpacitySpec(Index)=o.dryOpacitySpec_m[i][j];
    }
  }
  wetOpacitySpec = rtnQAD(o.wetOpacitySpec_m, "mm-1");

}

void  atmosphere::getAbsCoeff(Quantum<Vector<Double> > &kH2OLines,
			      Quantum<Vector<Double> > &kH2OCont,
			      Quantum<Vector<Double> > &kO2,
			      Quantum<Vector<Double> > &kDryCont,
			      Quantum<Vector<Double> > &kO3,
			      Quantum<Vector<Double> > &kCO,
			      Quantum<Vector<Double> > &kN2O) const {
  AbsCoeff a;
  itsAtm->getAbsCoeff(a);
  kH2OLines = rtnQVD(a.kH2OLines_m, "m-1");
  kH2OCont = rtnQVD(a.kH2OCont_m, "m-1");
  kO2 = rtnQVD(a.kO2_m, "m-1");
  kDryCont = rtnQVD(a.kDryCont_m, "m-1");
  kO3 = rtnQVD(a.kO3_m, "m-1");
  kCO = rtnQVD(a.kCO_m, "m-1");
  kN2O = rtnQVD(a.kN2O_m, "m-1");
}

void  atmosphere::getAbsCoeffDer(Quantum<Vector<Double> > &kH2OLinesDer,
				 Quantum<Vector<Double> > &kH2OContDer,
				 Quantum<Vector<Double> > &kO2Der,
				 Quantum<Vector<Double> > &kDryContDer,
				 Quantum<Vector<Double> > &kO3Der,
				 Quantum<Vector<Double> > &kCODer,
				 Quantum<Vector<Double> > &kN2ODer) const {
  AbsCoeffDer a;
  itsAtm->getAbsCoeffDer(a);
  kH2OLinesDer = rtnQVD(a.kH2OLinesDer_m, "m-1");
  kH2OContDer = rtnQVD(a.kH2OContDer_m, "m-1");
  kO2Der = rtnQVD(a.kO2Der_m, "m-1");
  kDryContDer = rtnQVD(a.kDryContDer_m, "m-1");
  kO3Der = rtnQVD(a.kO3Der_m, "m-1");
  kCODer = rtnQVD(a.kCODer_m, "m-1");
  kN2ODer = rtnQVD(a.kN2ODer_m, "m-1");
}

void atmosphere::getPhaseFactor(Quantum<Vector<Double> > &dispPhase,
				Quantum<Vector<Double> > &nonDispPhase) const {
  PhaseFactor p;
  itsAtm->getPhaseFactor(p);
  dispPhase = rtnQVD(p.dispPhase_m, "deg.m-1");
  nonDispPhase = rtnQVD(p.nonDispPhase_m, "deg.m-1");
}

void atmosphere::computeSkyBrightness(const Double &airMass,
				      const Quantity &tbgr,
				      const Quantity &precWater) {
  itsAtm->computeSkyBrightness(airMass, tbgr.getValue("K"), precWater.getValue("m"));
}

Quantum<Vector<Double> > atmosphere::getSkyBrightness(const Int iopt) {
  vector<double> s = (itsAtm->getSkyBrightness( TemperatureType(iopt) ));
  return rtnQVD( s, "K" );
}

Quantum<Array<Double> > atmosphere::getSkyBrightnessSpec(const Int iopt) {
  vector< vector<double> > rtn1;
  Array<Double> rtn2;
  rtn1 = ( itsAtm->getSkyBrightnessSpec( (TemperatureType)iopt ) );
  return rtnQAD(rtn1, "K");
}

void  atmosphere::setSkyCoupling(const float c) {
  itsAtm->setSkyCoupling(c);
}

float atmosphere::getSkyCoupling() {
  return( itsAtm->getSkyCoupling() );
}

//
// methods from ApplicationObject
String atmosphere::className() const
{
  return "atmosphere";
}

Vector <String> atmosphere::methods() const
{
  Vector <String> method(NUM_METHODS);

  method(GETSTARTUPWATERCONTENT) = "getStartupWaterContent";
  method(GETPROFILEREF) = "getProfile";
  method(INITWINDOW) = "initWindow";
  method(GETNDATA) = "getNdata";
  method(GETOPACITYREF) = "getOpacity";
  method(GETOPACITYSPECREF) = "getOpacitySpec";
  method(GETABSCOEFFREF) = "getAbsCoeff";
  method(GETABSCOEFFDERREF) = "getAbsCoeffDer";
  method(GETPHASEFACTORREF) = "getPhaseFactor";
  method(COMPUTESKYBRIGHTNESS) = "computeSkyBrightness";
  method(GETSKYBRIGHTNESS) = "getSkyBrightness";
  method(GETSKYBRIGHTNESSSPEC) = "getSkyBrightnessSpec";
  method(SETSKYCOUPLING) = "setSkyCoupling";
  method(GETSKYCOUPLING) = "getSkyCoupling";

  return method;
}

Vector <String> atmosphere::noTraceMethods() const
{
  Vector <String> method(NUM_NOTRACE_METHODS);

  method(NT_GETSTARTUPWATERCONTENT) = "getStartupWaterContent";
  method(NT_GETPROFILEREF) = "getProfile";
  method(NT_INITWINDOW) = "initWindow";
  method(NT_GETNDATA) = "getNdata";
  method(NT_GETOPACITYREF) = "getOpacity";
  method(NT_GETOPACITYSPECREF) = "getOpacitySpec";
  method(NT_GETABSCOEFFREF) = "getAbsCoeff";
  method(NT_GETABSCOEFFDERREF) = "getAbsCoeffDer";
  method(NT_GETPHASEFACTORREF) = "getPhaseFactor";
  method(NT_COMPUTESKYBRIGHTNESS) = "computeSkyBrightness";
  method(NT_GETSKYBRIGHTNESS) = "getSkyBrightness";
  method(NT_GETSKYBRIGHTNESSSPEC) = "getSkyBrightnessSpec";
  method(NT_SETSKYCOUPLING) = "setSkyCoupling";
  method(NT_GETSKYCOUPLING) = "getSkyCoupling";

  return method;
}

//----------------------------------------------------------------------------

MethodResult atmosphere::runMethod (uInt which, ParameterSet& inpRec, 
   Bool runMethod)
{
// Mechanism to allow execution of class methods from the 
// aips++ DO system.
// Inputs:
//    which        uInt               Selected method
//    inpRec       ParameterSet       Associated input parameters
//    runMethod    Bool               Execute method ?
//
  // Case method number of:
  switch (which) {
  case GETSTARTUPWATERCONTENT: {
    Parameter <Quantity> returnval(inpRec, "returnval", ParameterSet::Out);

    if (runMethod) {
       returnval() = getStartupWaterContent();
    };
  }
  break;

  case GETPROFILEREF: {
    Parameter<Quantum<Vector<Double> > > thickness(inpRec, "thickness", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > temperature(inpRec, "temperature", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > water(inpRec, "water", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > pressure(inpRec, "pressure", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > O3(inpRec, "O3", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > CO(inpRec, "CO", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > N2O(inpRec, "N2O", ParameterSet::Out);
    if ( runMethod ){
      getProfile( thickness(), temperature(), water(), pressure(), O3(),
		     CO(), N2O() );
    }    
  }         
  break;

  case INITWINDOW: {
    Parameter<Int> nbands(inpRec, "nbands", ParameterSet::In);
    Parameter<Quantum<Vector<Double> > > fCenter(inpRec, "fCenter", ParameterSet::In);
    Parameter<Quantum<Vector<Double> > > fWidth(inpRec, "fWidth", ParameterSet::In);
    Parameter<Quantum<Vector<Double> > > fRes(inpRec, "fRes", ParameterSet::In);
    if ( runMethod ){
      initWindow( nbands(), fCenter(), fWidth(), fRes() );
    }    
  }         
  break;

  case GETNDATA: {
     Parameter<Int> returnval(inpRec, "returnval", ParameterSet::Out);
     Parameter<Int> iband(inpRec, "iband", ParameterSet::In);
     if ( runMethod ){
          returnval() = getNdata( iband() );
     }    
  }         
  break;

  case GETOPACITYREF: {
    Parameter<Vector<Double> > dryOpacity(inpRec, "dryOpacity", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > wetOpacity(inpRec, "wetOpacity", ParameterSet::Out);
    if ( runMethod ){
      getOpacity( dryOpacity(), wetOpacity() );
    }    
  }         
  break;

  case GETOPACITYSPECREF: {
    Parameter<Array<Double> >  dryOpacitySpec(inpRec, "dryOpacitySpec", ParameterSet::Out);
    Parameter<Quantum<Array<Double> > > wetOpacitySpec(inpRec, "wetOpacitySpec", ParameterSet::Out);
    if ( runMethod ){
      getOpacitySpec( dryOpacitySpec(), wetOpacitySpec() );
    }    
  }         
  break;

  case GETABSCOEFFREF: {
    Parameter<Quantum<Vector<Double> > > kH2OLines(inpRec, "kH2OLines", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > kH2OCont(inpRec, "kH2OCont", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > kO2(inpRec, "kO2", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > kDryCont(inpRec, "kDryCont", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > kO3(inpRec, "kO3", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > kCO(inpRec, "kCO", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > kN2O(inpRec, "kN2O", ParameterSet::Out);
    if ( runMethod ){
      getAbsCoeff( kH2OLines(), kH2OCont(), kO2(), kDryCont(),
		      kO3(), kCO(), kN2O() );
    }    
  }         
  break;

  case GETABSCOEFFDERREF: {
    Parameter<Quantum<Vector<Double> > > kH2OLinesDer(inpRec, "kH2OLinesDer", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > kH2OContDer(inpRec, "kH2OContDer", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > kO2Der(inpRec, "kO2Der", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > kDryContDer(inpRec, "kDryContDer", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > kO3Der(inpRec, "kO3Der", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > kCODer(inpRec, "kCODer", ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > kN2ODer(inpRec, "kN2ODer", ParameterSet::Out);
    if ( runMethod ){
      getAbsCoeffDer( kH2OLinesDer(), kH2OContDer(), kO2Der(),
			 kDryContDer(), kO3Der(), kCODer(), kN2ODer() );
    }    
  }         
  break;

  case GETPHASEFACTORREF: {
     Parameter<Quantum<Vector<Double> > > dispPhase(inpRec, "dispPhase", ParameterSet::Out);
     Parameter<Quantum<Vector<Double> > > nonDispPhase(inpRec, "nonDispPhase", ParameterSet::Out);
     if ( runMethod ){
          getPhaseFactor( dispPhase(), nonDispPhase() );
     }    
  }         
  break;

  case COMPUTESKYBRIGHTNESS: {
     Parameter<Double> airMass(inpRec, "airMass", ParameterSet::In);
     Parameter<Quantity> tbgr(inpRec, "tbgr", ParameterSet::In);
     Parameter<Quantity> precWater(inpRec, "precWater", ParameterSet::In);
     if ( runMethod ){
          computeSkyBrightness( airMass(), tbgr(), precWater() );
     }    
  }         
  break;

  case GETSKYBRIGHTNESS: {
     Parameter<Int> iopt(inpRec, "iopt", ParameterSet::In);
     Parameter<Quantum<Vector<Double> > > returnval(inpRec, "returnval", ParameterSet::Out);
     if ( runMethod ){
          returnval() = getSkyBrightness( iopt() );
     }    
  }         
  break;

  case GETSKYBRIGHTNESSSPEC: {
    Parameter<Int> iopt(inpRec, "iopt", ParameterSet::In);
    Parameter<Quantum<Array<Double> > > returnval(inpRec, "returnval", ParameterSet::Out);
    if ( runMethod ){
      returnval() = getSkyBrightnessSpec( iopt() );
     }    
  }         
  break;

  case SETSKYCOUPLING: {
     Parameter<Float> c(inpRec, "c", ParameterSet::In);
     if ( runMethod ){
          setSkyCoupling( c() );
     }    
  }         
  break;

  case GETSKYCOUPLING: {
     Parameter<Float> returnval(inpRec, "returnval", ParameterSet::Out);
     if ( runMethod ){
          returnval() = getSkyCoupling();
     }    
  }         
  break;

  default: 
    return error ("No such method");
  };

  return ok();
};
MethodResult atmosphereFactory::make (ApplicationObject*& newObject,
                      const String& whichConstructor,
                      ParameterSet& inpRec,
                      Bool runConstructor) {
   // Intialization
   MethodResult retval;
   newObject = 0;

   // Case (constructor_type) of:
   if (whichConstructor == "atmosphere") {
      Parameter <Quantity> altitude (inpRec, "altitude", ParameterSet::In);
      Parameter <Quantity> temperature (inpRec, "temperature", ParameterSet::In);
      Parameter <Quantity> pressure (inpRec, "pressure", ParameterSet::In);
      Parameter <Quantity> maxAltitude (inpRec, "maxAltitude", ParameterSet::In);
      Parameter <Double> humidity (inpRec, "humidity", ParameterSet::In);
      Parameter <Quantity> dTem_dh (inpRec, "dTem_dh", ParameterSet::In);
      Parameter <Quantity> dP (inpRec, "dP", ParameterSet::In);
      Parameter <Double> dPm (inpRec, "dPm", ParameterSet::In);
      Parameter <Quantity> h0 (inpRec, "h0", ParameterSet::In);
      //      Parameter <AtmType> atmtype (inpRec, "atmtype", ParameterSet::In);
      Parameter <Int> atmtype (inpRec, "atmtype", ParameterSet::In);
      if (runConstructor) {
         newObject = new atmosphere ( altitude(), temperature(), pressure(), maxAltitude(), humidity(), dTem_dh(), dP(), dPm(), h0(), atmtype());
       }
    } else {
      retval = String ("Unknown constructor ") + whichConstructor;
    };

   if (retval.ok() && runConstructor && !newObject) {
      retval = "Memory allocation error";
    };
   return retval;
}

} //#end casa namespace
