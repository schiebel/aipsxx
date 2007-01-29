//# DOmeasures.cc:  This class gives Glish to Measures connection
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: DOmeasures.cc,v 19.6 2005/11/07 21:17:04 wyoung Exp $

//# Includes

#include <appsglish/measures/DOmeasures.h>
#include <measures/Measures.h>
#include <measures/Measures/MCEpoch.h>
#include <measures/Measures/MCPosition.h>
#include <measures/Measures/MCDirection.h>
#include <measures/Measures/MCFrequency.h>
#include <measures/Measures/MCDoppler.h>
#include <measures/Measures/MCRadialVelocity.h>
#include <measures/Measures/MCBaseline.h>
#include <measures/Measures/MCuvw.h>
#include <measures/Measures/MCEarthMagnetic.h>
#include <measures/Measures/MeasTable.h>
#include <measures/Measures/MeasComet.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/Constants.h>
#include <measures/Measures/MeasureHolder.h>
#include <casa/Quanta/QuantumHolder.h>
#include <tasking/Glish.h>
#include <casa/Logging.h>
#include <casa/Exceptions/Error.h>

#include <casa/namespace.h>
// Constructors
measures::measures() : pcomet_p(0) {;}

measures::measures(const measures &other) :
  ApplicationObject(other), pcomet_p(0) {;}

measures &measures::operator=(const measures &) {
  return *this;
}

// Destructor
measures::~measures() {
  delete pcomet_p;
}

// Frame actions
MeasFrame &measures::getFrame() {
  return frame_p;
}

// Measure actions
void measures::getMeasureType(String &out, const GlishRecord &in) {
  Bool b;
  if (in.exists("type")) {
    b = GlishArray(in.get("type")).get(out);
  } else {
    out = "none";
  };
}

Bool measures::doframe(const MeasureHolder &in) {
  if (in.isMPosition() || in.isMDirection() ||
      in.isMEpoch() || in.isMRadialVelocity()) {
    frame_p.set(in.asMeasure());
    return True;
  };
  return False;
}

Bool measures::doframe(const String &in) {
  try {
    delete pcomet_p; pcomet_p = 0;
    if (in.empty()) {
      pcomet_p = new MeasComet;
    } else {
      pcomet_p = new MeasComet(in);
    };
    if (!pcomet_p->ok()) {
      delete pcomet_p; pcomet_p = 0;
      return False;
    };
    frame_p.set(*pcomet_p);
  } catch (AipsError (x)) {
    return False;
  } 
  return True;
}

// Convert measures
Bool measures::measure(String &error, MeasureHolder &out,
		       const MeasureHolder &in, const String &outref,
		       const GlishRecord &off) {
  MeasureHolder mo;
  if (off.exists("offset")) {
    Record rec;
    GlishRecord grec (off.get("offset"));
    grec.toRecord (rec);
    if (!mo.fromRecord(error, rec)) {
      error += String("Non-measure type offset in measure conversion\n");
      return False;
    };
    mo.asMeasure().getRefPtr()->set(frame_p);
  };
  in.asMeasure().getRefPtr()->set(frame_p);
  try {
    if (in.isMEpoch()) {
      MEpoch::Ref outRef;
      MEpoch::Types tp;
      String x = outref;
      Bool raze = False;
      if (x.before(2) == "r_" || x.before(2) == "R_") {
	raze = True;
	x = x.from(2);
      };
      if (MEpoch::getType(tp, x)) {
	if (raze) outRef.setType(tp | MEpoch::RAZE);
	else outRef.setType(tp);
      } else outRef.setType(MEpoch::DEFAULT);
      outRef.set(frame_p);
      if (!mo.isEmpty()) {
	if (mo.isMEpoch()) outRef.set(mo.asMeasure());
	else {
	  error += "Non-conforming offset measure type\n";
	  return False;
	};
      };
      MEpoch::Convert mcvt(MEpoch::Convert(in.asMeasure(), outRef));
      out = MeasureHolder(mcvt());
      out.makeMV(in.nelements());
      for (uInt i=0; i<in.nelements(); i++) {
        if (!out.setMV(i, mcvt(dynamic_cast<const MVEpoch &>
                               (*in.getMV(i))).getValue())) {
	  error += "Cannot get extra measure value in DOmeasures::measures\n";
	  return False;
	};
      };
    } else if (in.isMPosition()) {
      MPosition::Ref outRef;
      MPosition::Types tp;
      if (MPosition::getType(tp, outref)) outRef.setType(tp);
      else outRef.setType(MPosition::DEFAULT);
      outRef.set(frame_p);
      if (!mo.isEmpty()) {
	if (mo.isMPosition()) outRef.set(mo.asMeasure());
	else {
	  error += "Non-conforming offset measure type\n";
	  return False;
	};
      };
      MPosition::Convert mcvt(MPosition::Convert(in.asMeasure(), outRef));
      out = MeasureHolder(mcvt());
      out.makeMV(in.nelements());
      for (uInt i=0; i<in.nelements(); i++) {
        if (!out.setMV(i, mcvt(dynamic_cast<const MVPosition &>
                               (*in.getMV(i))).getValue())) {
	  error += "Cannot get extra measure value in DOmeasures::measures\n";
	  return False;
	};
      };
    } else if (in.isMDirection()) {
      MDirection::Ref outRef;
      MDirection::Types tp;
      if (MDirection::getType(tp, outref)) outRef.setType(tp);
      else outRef.setType(MDirection::DEFAULT);
      outRef.set(frame_p);
      if (!mo.isEmpty()) {
	if (mo.isMDirection()) outRef.set(mo.asMeasure());
	else {
	  error += "Non-conforming offset measure type\n";
	  return False;
	};
      };
      MDirection::Convert mcvt(MDirection::Convert(in.asMeasure(), outRef));
      out = MeasureHolder(mcvt());
      out.makeMV(in.nelements());
      for (uInt i=0; i<in.nelements(); i++) {
	if (!out.setMV(i, mcvt(dynamic_cast<const MVDirection &>
			       (*in.getMV(i))).getValue())) {
	  error += "Cannot get extra measure value in DOmeasures::measures\n";
	  return False;
	};
      };
   } else if (in.isMFrequency()) {
      MFrequency::Ref outRef;
      MFrequency::Types tp;
      if (MFrequency::getType(tp, outref)) outRef.setType(tp);
      else outRef.setType(MFrequency::DEFAULT);
      outRef.set(frame_p);
      if (!mo.isEmpty()) {
	if (mo.isMFrequency()) outRef.set(mo.asMeasure());
	else {
	  error += "Non-conforming offset measure type\n";
	  return False;
	};
      };
      MFrequency::Convert mcvt(MFrequency::Convert(in.asMeasure(), outRef));
      out = MeasureHolder(mcvt());
      out.makeMV(in.nelements());
      for (uInt i=0; i<in.nelements(); i++) {
	if (!out.setMV(i, mcvt(dynamic_cast<const MVFrequency &>
			       (*in.getMV(i))).getValue())) {
	  error += "Cannot get extra measure value in DOmeasures::measures\n";
	  return False;
	};
      };
    } else if (in.isMDoppler()) {
      MDoppler::Ref outRef;
      MDoppler::Types tp;
      if (MDoppler::getType(tp, outref)) outRef.setType(tp);
      else outRef.setType(MDoppler::DEFAULT);
      outRef.set(frame_p);
      if (!mo.isEmpty()) {
	if (mo.isMDoppler()) outRef.set(mo.asMeasure());
	else {
	  error += "Non-conforming offset measure type\n";
	  return False;
	};
      };
      MDoppler::Convert mcvt(MDoppler::Convert(in.asMeasure(), outRef));
      out = MeasureHolder(mcvt());
      out.makeMV(in.nelements());
      for (uInt i=0; i<in.nelements(); i++) {
        if (!out.setMV(i, mcvt(dynamic_cast<const MVDoppler &>
                               (*in.getMV(i))).getValue())) {
	  error += "Cannot get extra measure value in DOmeasures::measures\n";
	  return False;
	};
      };
    } else if (in.isMRadialVelocity()) {
      MRadialVelocity::Ref outRef;
      MRadialVelocity::Types tp;
      if (MRadialVelocity::getType(tp, outref)) outRef.setType(tp);
      else outRef.setType(MRadialVelocity::DEFAULT);
      outRef.set(frame_p);
      if (!mo.isEmpty()) {
	if (mo.isMRadialVelocity()) outRef.set(mo.asMeasure());
	else {
	  error += "Non-conforming offset measure type\n";
	  return False;
	};
      };
      MRadialVelocity::Convert
	mcvt(MRadialVelocity::Convert(in.asMeasure(), outRef));
      out = MeasureHolder(mcvt());
      out.makeMV(in.nelements());
      for (uInt i=0; i<in.nelements(); i++) {
        if (!out.setMV(i, mcvt(dynamic_cast<const MVRadialVelocity &>
                               (*in.getMV(i))).getValue())) {
	  error += "Cannot get extra measure value in DOmeasures::measures\n";
	  return False;
	};
      };
    } else if (in.isMBaseline()) {
      MBaseline::Ref outRef;
      MBaseline::Types tp;
      if (MBaseline::getType(tp, outref)) outRef.setType(tp);
      else outRef.setType(MBaseline::DEFAULT);
      outRef.set(frame_p);
      if (!mo.isEmpty()) {
	if (mo.isMBaseline()) outRef.set(mo.asMeasure());
	else {
	  error += "Non-conforming offset measure type\n";
	  return False;
	};
      };
      MBaseline::Convert mcvt(MBaseline::Convert(in.asMeasure(), outRef));
      out = MeasureHolder(mcvt());
      out.makeMV(in.nelements());
      for (uInt i=0; i<in.nelements(); i++) {
        if (!out.setMV(i, mcvt(dynamic_cast<const MVBaseline &>
                               (*in.getMV(i))).getValue())) {
	  error += "Cannot get extra measure value in DOmeasures::measures\n";
	  return False;
	};
      };
    } else if (in.isMuvw()) {
      Muvw::Ref outRef;
      Muvw::Types tp;
      if (Muvw::getType(tp, outref)) outRef.setType(tp);
      else outRef.setType(Muvw::DEFAULT);
      outRef.set(frame_p);
      if (!mo.isEmpty()) {
	if (mo.isMuvw()) outRef.set(mo.asMeasure());
	else {
	  error += "Non-conforming offset measure type\n";
	  return False;
	};
      };
      Muvw::Convert mcvt(Muvw::Convert(in.asMeasure(), outRef));
      out = MeasureHolder(mcvt());
      out.makeMV(in.nelements());
      for (uInt i=0; i<in.nelements(); i++) {
        if (!out.setMV(i, mcvt(dynamic_cast<const MVuvw &>
                               (*in.getMV(i))).getValue())) {
	  error += "Cannot get extra measure value in DOmeasures::measures\n";
	  return False;
	};
      };
    } else if (in.isMEarthMagnetic()) {
      MEarthMagnetic::Ref outRef;
      MEarthMagnetic::Types tp;
      if (MEarthMagnetic::getType(tp, outref)) outRef.setType(tp);
      else outRef.setType(MEarthMagnetic::DEFAULT);
      outRef.set(frame_p);
      if (!mo.isEmpty()) {
	if (mo.isMEarthMagnetic()) outRef.set(mo.asMeasure());
	else {
	  error += "Non-conforming offset measure type\n";
	  return False;
	};
      };
      MEarthMagnetic::Convert
	mcvt(MEarthMagnetic::Convert(in.asMeasure(), outRef));
      out = MeasureHolder(mcvt());
      out.makeMV(in.nelements());
      for (uInt i=0; i<in.nelements(); i++) {
        if (!out.setMV(i, mcvt(dynamic_cast<const MVEarthMagnetic &>
                               (*in.getMV(i))).getValue())) {
	  error += "Cannot get extra measure value in DOmeasures::measures\n";
	  return False;
	};
      };
    };
    if (out.isEmpty()) {
      error += "No measure created; probably unknow measure type\n";
      return False;
    };
  } catch (AipsError (x)) {
    error += "Cannot convert due to missing frame information\n";
    return False;
  };
  return True;
}

// Make uvw from baselines
Bool measures::toUvw(String &error, MeasureHolder &out,
		     Vector<Double> &xyz, Vector<Double> &dot,
		     const MeasureHolder &in) {
  if (!in.isMBaseline()) {
    error += "Trying to convert non-baseline to uvw\n";
    return False;
  };
  try {
    in.asMeasure().getRefPtr()->set(frame_p);   // attach frame
    MBaseline::Convert mcvt(in.asMeasure(), MBaseline::J2000);
    const MVBaseline &bas2000 = mcvt().getValue();
    MVDirection dir2000;
    Double dec2000;
    if (!frame_p.getJ2000(dir2000) || !frame_p.getJ2000Lat(dec2000)) {
      error += "No direction in frame for uvw calculation\n";
      return False;
    };
    MVuvw uvw2000 = MVuvw(bas2000, dir2000);
    out = MeasureHolder(Muvw(uvw2000, Muvw::J2000));
    uInt nel = in.nelements() == 0 ? 1 : in.nelements();
    out.makeMV(in.nelements());
    Double sd = sin(dec2000);
    Double cd = cos(dec2000);
    dot.resize(3*nel);
    xyz.resize(3*nel);
    if (in.nelements() == 0) {
      xyz = uvw2000.getValue();
      dot[0] = -sd*xyz[1] + cd*xyz[2];
      dot[1] = +sd*xyz[0];
      dot[2] = -cd*xyz[0];
    };
    for (uInt i=0; i<3*in.nelements(); i+=3) {
      const MVuvw &mv = MVuvw(mcvt(dynamic_cast<const MVBaseline &>
				   (*in.getMV(i/3))).getValue(), dir2000);
      if (!out.setMV(i/3, mv)) {
	error += "Cannot get extra baseline value in DOmeasures::toUvw\n";
	return False;
      };
      for (uInt j=0; j<3; ++j) xyz[i+j] = mv.getValue()[j];
      dot[i+0] = -sd*xyz[i+1] + cd*xyz[i+2];
      dot[i+1] = +sd*xyz[i+0];
      dot[i+2] = -cd*xyz[i+0];
    };
    for (uInt j=0; j<3*nel; ++j) {
      dot[j] *= C::pi/180/240./1.002737909350795;
    };

  } catch (AipsError(x)) {
    error += "Cannot convert baseline to uvw: frame "
      "information missing";
    return False;
  };
  return True;
}

// Expand positions to baselines
Bool measures::expand(String &error, MeasureHolder &out,
		      Vector<Double> &xyz,
		      const MeasureHolder &in) {
  if (!in.isMuvw()) {
    error += "Trying to expand non-baseline type\n";
    return False;
  };
  const MVuvw &uvw2000 = in.asMuvw().getValue();
  if (in.nelements() < 2) {
    xyz.resize(3);
    xyz = uvw2000.getValue();
    out = MeasureHolder(Muvw(uvw2000, Muvw::J2000));
  } else {
    uInt nel = (in.nelements() * (in.nelements()-1))/2;
    xyz.resize(3*nel);
    uInt k=0;
    for (uInt i=0; i<in.nelements(); ++i) {
      for (uInt j=i+1; j<in.nelements(); ++j) {
	MVuvw mv = (dynamic_cast<const MVuvw &>(*in.getMV(j))).getValue();
	mv -= (dynamic_cast<const MVuvw &>(*in.getMV(i))).getValue();
	if (k == 0) {
	  out = MeasureHolder(Muvw(mv, Muvw::J2000));
	  out.makeMV(nel);
	};
	if (!out.setMV(k, mv)) {
	  error += "Cannot expand baseline value in DOmeasures::expand\n";
	  return False;
	};
	for (uInt j=0; j<3; ++j) xyz[3*k+j] = mv.getValue()[j];
	++k;
      };
    };
  };
  return True;
}

// DO name
String measures::className() const {
  return "measures";
}

// Available methods
Vector<String> measures::methods() const {
  Vector<String> tmp(22);
  tmp(0)=  "measure";			// convert measure
  tmp(1)=  "doframe";			// set a frame element
  tmp(2)=  "doptorv";
  tmp(3)=  "doptofreq";
  tmp(4)=  "todop";
  tmp(5)=  "torest";
  tmp(6)=  "obslist";			// list of observatories
  tmp(7)=  "observatory";		// observatory position
  tmp(8)=  "srclist";			// source list
  tmp(9)=  "source";			// a source
  tmp(10)= "addev";			// add ev fields
  tmp(11)= "alltyp";			// get all types
  tmp(12)= "linelist";			// spectral line list
  tmp(13)= "line";			// a spectral line
  tmp(14)= "framecomet";		// set a comet frame
  tmp(15)= "cometname";			// get the comet name
  tmp(16)= "comettopo";			// get the topocentrische position
  tmp(17)= "comettype";			// get the type of comet table
  tmp(18)= "posangle";			// get position angle of direction
  tmp(19)= "separation";		// get separation between directions
  tmp(20)= "uvw";			// calculate uvw
  tmp(21)= "expand";			// expand to baselines from positions
  return tmp;
}

// Untraced methods
Vector<String> measures::noTraceMethods() const {

  return methods();
}

// Execute methods
MethodResult measures::runMethod(uInt which,
			     ParameterSet &parameters,
			     Bool runMethod) {

  static String returnvalName = "returnval";
  static String valName  = "val";
  static String argName  = "arg";
  static String formName = "form";
  static String form2Name= "form2";

  String err;

  switch (which) {

  // define
  // measure
  case 0: {
    Parameter<MeasureHolder> val(parameters, valName,
				 ParameterSet::In);
    Parameter<String> arg(parameters, argName,
			  ParameterSet::In);
    Parameter<GlishRecord> form(parameters, formName,
				ParameterSet::In);
    Parameter<MeasureHolder> returnval(parameters, returnvalName,
				       ParameterSet::Out);
    if (runMethod) {
      returnval() = MeasureHolder(); 	// empty return value
      if (!measure(err, returnval(), val(), arg(), form())) {
	return error(err);
      };
    };
  }
  break;

  // doframe
  case 1: {
    Parameter<MeasureHolder> val(parameters, valName,
				 ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName,
			      ParameterSet::Out);
    if (runMethod) returnval() = doframe(val());
  }
  break;

  // doptorv
  case 2: {
    Parameter<MeasureHolder> val(parameters, valName,
				 ParameterSet::In);
    Parameter<String> arg(parameters, argName,
			  ParameterSet::In);
    Parameter<MeasureHolder> returnval(parameters, returnvalName,
				       ParameterSet::Out);
    if (runMethod) {
      MRadialVelocity::Ref outRef;
      MRadialVelocity tout;
      tout.giveMe(outRef, arg());
      returnval() =
	MeasureHolder(MRadialVelocity::
		      fromDoppler(val().asMDoppler(), 
				  static_cast<MRadialVelocity::Types>
				  (outRef.getType())));
      uInt nel(val().nelements());
      if (nel>0) {
	returnval().makeMV(nel);
	MDoppler::Convert mfcv(val().asMDoppler(),
			       val().asMDoppler().getRef());
	for (uInt i=0; i<nel; i++) {
	  returnval().
	    setMV(i, MRadialVelocity::
		  fromDoppler(mfcv(val().getMV(i)),
			      static_cast<MRadialVelocity::Types>
			      (outRef.getType())).getValue());
	};
      };
    };
  }
  break;

  // doptofreq
  case 3: {
    Parameter<MeasureHolder> val(parameters, valName,
				 ParameterSet::In);
    Parameter<String> arg(parameters, argName,
			  ParameterSet::In);
    Parameter<Quantity> form(parameters, formName,
			     ParameterSet::In);
    Parameter<MeasureHolder> returnval(parameters, returnvalName,
				       ParameterSet::Out);
    if (runMethod) {
      MFrequency::Ref outRef;
      MFrequency tout;
      tout.giveMe(outRef, arg());
      returnval() =
	MeasureHolder(MFrequency::
		      fromDoppler(val().asMDoppler(),
				  MVFrequency(form()),
				  static_cast<MFrequency::Types>
				  (outRef.getType())));
      uInt nel(val().nelements());
      if (nel>0) {
	returnval().makeMV(nel);
	MDoppler::Convert mfcv(val().asMDoppler(),
			       val().asMDoppler().getRef());
	for (uInt i=0; i<nel; i++) {
	  returnval().
	    setMV(i, MFrequency::
		  fromDoppler(mfcv(val().getMV(i)),
			      MVFrequency(form()),
			      static_cast<MFrequency::Types>
			      (outRef.getType())).getValue());
	};
      };
    };
  }
  break;

  // todop
  case 4: {
    Parameter<MeasureHolder> val(parameters, valName,
				 ParameterSet::In);
    Parameter<Quantity> form(parameters, formName,
			     ParameterSet::In);
    Parameter<MeasureHolder> returnval(parameters, returnvalName,
				       ParameterSet::Out);
    if (runMethod) {
      if (val().isMRadialVelocity()) {
	returnval() = MRadialVelocity::toDoppler(val().asMeasure());
	uInt nel(val().nelements());
	if (nel>0) {
	  returnval().makeMV(nel);
	  MRadialVelocity::Convert mfcv(val().asMRadialVelocity(),
					val().asMRadialVelocity().getRef());
	  for (uInt i=0; i<nel; i++) {
	    returnval().setMV(i, MRadialVelocity::
			      toDoppler(mfcv(val().getMV(i))).
			      getValue());
	  };
	};
      } else if (val().isMFrequency()) {
	returnval() = MFrequency::toDoppler(val().asMeasure(),
					    MVFrequency(form()));
	uInt nel(val().nelements());
	if (nel>0) {
	  returnval().makeMV(nel);
	  MFrequency::Convert mfcv(val().asMFrequency(),
				   val().asMFrequency().getRef());
	  for (uInt i=0; i<nel; i++) {
	    returnval().setMV(i, MFrequency::
			      toDoppler(mfcv(val().getMV(i)),
					MVFrequency(form())).
			      getValue());
	  };
	};
      } else {
	return error("todop can only convert MFrequency or MRadialVelocity");
      };
    };
  }
  break;

  // torest
  case 5: {
    Parameter<MeasureHolder> val(parameters, valName,
				 ParameterSet::In);
    Parameter<MeasureHolder> arg(parameters, argName,
				 ParameterSet::In);
    Parameter<MeasureHolder> returnval(parameters, returnvalName,
				       ParameterSet::Out);
    if (runMethod) {
      returnval() = 
	MeasureHolder(MFrequency::toRest(val().asMFrequency(),
					 arg().asMDoppler()));
      uInt nel(val().nelements());
      if (nel != arg().nelements()) {
	return error("Incorrect length of doppler or frequency in torest");
      };
      if (nel>0) {
	returnval().makeMV(nel);
	MFrequency::Convert mfcv(val().asMFrequency(),
				 val().asMFrequency().getRef());
	MDoppler::Convert mdcv(arg().asMDoppler(),
			       arg().asMDoppler().getRef());
	for (uInt i=0; i<nel; i++) {
	  returnval().setMV(i, MFrequency::
			    toRest(mfcv(val().getMV(i)),
				   mdcv(arg().getMV(i))).
			    getValue());
	};
      };
    };
  }
  break;

  // obslist
  case 6: {
    Parameter<String> returnval(parameters, returnvalName,
				ParameterSet::Out);
    if (runMethod) {
      const Vector<String> &lst = MeasTable::Observatories();
      returnval() = String();
      if (lst.nelements() > 0) {
	// Note in next one the const throw away, since join does not accept
	// const String src[]
	Bool deleteIt; 
	String *storage = const_cast<String *>(lst.getStorage(deleteIt));
	const String *cstorage = storage;
	returnval() = join(storage, lst.nelements(), String(" "));
	lst.freeStorage(cstorage, deleteIt);
      };
    };
  }
  break;

  // observatory
  case 7: {
    Parameter<String> val(parameters, valName,
			  ParameterSet::In);
    Parameter<MPosition> returnval(parameters, returnvalName,
				   ParameterSet::Out);
    if (runMethod) {
      if (!MeasTable::Observatory(returnval(), val())) {
	return error("Unknown observatory asked for\n");
      };
    };
  }
  break;

  // srclist
  case 8: {
    Parameter<String> returnval(parameters, returnvalName,
				ParameterSet::Out);
    if (runMethod) {
      const Vector<String> &lst = MeasTable::Sources();
      returnval() = String();
      if (lst.nelements() > 0) {
	// Note in next one the const throw away, since join does not accept
	// const String src[]
	Bool deleteIt; 
	String *storage = const_cast<String *>(lst.getStorage(deleteIt));
	const String *cstorage = storage;
	returnval() = join(storage, lst.nelements(), String(" "));
	lst.freeStorage(cstorage, deleteIt);
      };
    };
  }
  break;

  // source
  case 9: {
    Parameter<String> val(parameters, valName,
			  ParameterSet::In);
    Parameter<MDirection> returnval(parameters, returnvalName,
				    ParameterSet::Out);
    if (runMethod) {
      if (!MeasTable::Source(returnval(), val())) {
	return error("Unknown source asked for\n");
      };
    };
  }
  break;

  // addev
  case 10: {
    Parameter<MeasureHolder> val(parameters, valName,
				 ParameterSet::In);
    Parameter<Array<Quantum<Double> > > returnval(parameters, returnvalName,
						  ParameterSet::Out);
    if (runMethod) {
      Vector<Quantum<Double> > res =
	val().asMeasure().getData()->getXRecordValue();
      returnval().resize(IPosition());
      returnval() = res;
    };
  }
  break;

  // alltyp
  case 11: {
    Parameter<MeasureHolder> val(parameters, valName,
				 ParameterSet::In);
    Parameter<GlishRecord> returnval(parameters, returnvalName,
				     ParameterSet::Out);
    if (runMethod) {
      Int nall, nex;
      const uInt *typ;
      const String *tall = val().asMeasure().allTypes(nall, nex, typ);
      Vector<String> tcod(nall-nex);
      Vector<String> text(nex);
      for (Int i=0; i<nall; i++) {
	if (i<nall-nex) tcod(i) = tall[i];
	else text(i-nall+nex) = tall[i];
      };
      returnval() = GlishRecord();
      returnval().add(String("normal"), tcod);
      returnval().add(String("extra"), text);
    };
  }
  break;

  // linelist
  case 12: {
    Parameter<String> returnval(parameters, returnvalName,
				ParameterSet::Out);
    if (runMethod) {
      const Vector<String> &lst = MeasTable::Lines();
      returnval() = String();
      if (lst.nelements() > 0) {
	// Note in next one the const throw away, since join does not accept
	// const String src[]
	Bool deleteIt; 
	String *storage = const_cast<String *>(lst.getStorage(deleteIt));
	const String *cstorage = storage;
	returnval() = join(storage, lst.nelements(), String(" "));
	lst.freeStorage(cstorage, deleteIt);
      };
    };
  }
  break;

  // line
  case 13: {
    Parameter<String> val(parameters, valName,
			  ParameterSet::In);
    Parameter<MFrequency> returnval(parameters, returnvalName,
				    ParameterSet::Out);
    if (runMethod) {
      if (!MeasTable::Line(returnval(), val())) {
	return error("Unknown spectral line asked for\n");
      };
    };
  }
  break;

  // framecomet
  case 14: {
    Parameter<String> val(parameters, valName,
			  ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName,
			      ParameterSet::Out);
    if (runMethod) returnval() = doframe(val());
  }
  break;

  // cometname
  case 15: {
    Parameter<String> returnval(parameters, returnvalName,
				ParameterSet::Out);
    if (runMethod) {
      if (pcomet_p) returnval() = pcomet_p->getName();
      else return error("No Comet table present\n");
    };
  }
  break;

  // comettopo
  case 16: {
    Parameter<Vector<Double > > returnval(parameters, returnvalName,
					  ParameterSet::Out);
    if (runMethod) {
      if (pcomet_p && pcomet_p->getType() == MDirection::TOPO) {
	returnval() = pcomet_p->getTopo().getValue();
      } else {
	return error("No Topocentric Comet table present\n");
      };
    };
  }
  break;

  // comettype
  case 17: {
    Parameter<String> returnval(parameters, returnvalName,
				ParameterSet::Out);
    if (runMethod) {
      if (pcomet_p) {
	if (pcomet_p->getType() == MDirection::TOPO) {
	  returnval() = String("TOPO");
	} else {
	  returnval() = String("APP");
	};
      } else {
	returnval() = String("none");
      };
    };
  }
  break;

  // posangle
  case 18: {
    Parameter<MDirection> val(parameters, valName,
			      ParameterSet::In);
    Parameter<MDirection> arg(parameters, argName,
			      ParameterSet::In);
    Parameter<Quantity> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod) {
      MDirection x(val());
      MDirection y(arg());
      x.getRefPtr()->set(frame_p);
      y.getRefPtr()->set(frame_p);
      if (x.isModel()) x = MDirection::Convert(x, MDirection::DEFAULT)();
      if (y.isModel()) y = MDirection::Convert(y, MDirection::DEFAULT)();
      if (x.getRefPtr()->getType() != y.getRefPtr()->getType()) {
	y = MDirection::Convert(y, MDirection::castType
				(x.getRefPtr()->getType()))();
      };
      returnval() = x.getValue().positionAngle(y.getValue(), "deg"); 
    };
  }
  break;

  // separation
  case 19: {
    Parameter<MDirection> val(parameters, valName,
			      ParameterSet::In);
    Parameter<MDirection> arg(parameters, argName,
			      ParameterSet::In);
    Parameter<Quantity> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod) {
      MDirection x(val());
      MDirection y(arg());
      x.getRefPtr()->set(frame_p);
      y.getRefPtr()->set(frame_p);
      if (x.isModel()) x = MDirection::Convert(x, MDirection::DEFAULT)();
      if (y.isModel()) y = MDirection::Convert(y, MDirection::DEFAULT)();
      if (x.getRefPtr()->getType() != y.getRefPtr()->getType()) {
	y = MDirection::Convert(y, MDirection::castType
				(x.getRefPtr()->getType()))();
      };
      returnval() = x.getValue().separation(y.getValue(), "deg"); 
    };
  }
  break;

  // uvw
  case 20: {
    Parameter<MeasureHolder> val(parameters, valName,
				 ParameterSet::In);
    Parameter<Quantum<Vector<Double> > > arg(parameters, argName,
					     ParameterSet::Out);
    Parameter<Quantum<Vector<Double> > > form(parameters, formName,
					      ParameterSet::Out);
    Parameter<MeasureHolder> returnval(parameters, returnvalName,
				       ParameterSet::Out);
    if (runMethod) {
      returnval() = MeasureHolder();	// empty return value
      Vector<Double> res;
      Vector<Double> xres;
      if (!toUvw(err, returnval(), xres, res, val())) return error(err);
      arg() = Quantum<Vector<Double> >(res, "m/s");
      form() = Quantum<Vector<Double> >(xres, "m");
    };
  }
  break;

  // expand
  case 21: {
    Parameter<MeasureHolder> val(parameters, valName,
				 ParameterSet::In);
    Parameter<Quantum<Vector<Double> > > arg(parameters, argName,
					     ParameterSet::Out);
    Parameter<MeasureHolder> returnval(parameters, returnvalName,
				       ParameterSet::Out);
    if (runMethod) {
      returnval() = MeasureHolder();	// empty return value
      Vector<Double> xres;
      if (!expand(err, returnval(), xres, val())) return error(err);
      arg() = Quantum<Vector<Double> >(xres, "m");
    };
  }
  break;

  default: {
    return error("Unknown method");
  }
  break;

  };
  return ok();
}
