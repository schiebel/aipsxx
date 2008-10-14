//# DOatoms.cc:  This class gives Glish to Quantity connection
//# Copyright (C) 1998,2000,2001,2002,2003
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
//# $Id: DOatoms.cc,v 19.2 2004/08/25 05:48:55 gvandiep Exp $

//# Includes

#include <atnf/Atoms/DOatoms.h>
#include <tasking/Glish.h>
#include <casa/Logging.h>
#include <casa/Exceptions/Error.h>
#include <casa/BasicSL/String.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Arrays/Vector.h>
#include <casa/Quanta/QuantumHolder.h>
#include <rpc/rpc.h>
#include <casa/Containers/RecordInterface.h>
#include <casa/Containers/Record.h>

// Constructors
atoms::atoms() : cl_p(0) {;}

atoms::atoms(const atoms &other) : ApplicationObject(other) {;}

atoms &atoms::operator=(const atoms &other) {
  if (False && !&other) {}; // stop warning 
  return *this;
}

// Destructor
atoms::~atoms() {;}

// Double from hyper
Double atoms::toDouble(const servoRPC_AbsTime &in) const {
#ifdef _PSOS_
  return (in.h0 + in.h1*65536.0*65536.0);
#else
  return Double(in);
#endif
}

Double atoms::toDouble(const servoRPC_RelTime &in) const {
#ifdef _PSOS_
  return (in.h0 + in.h1*65536.0*65536.0);
#else
  return Double(in);
#endif
}

// Connect
Bool atoms::connect(const String &server) {
  if (!cl_p) {
    cl_p = clnt_create(server.chars(), SERVO_RPC__PROG, SERVO_RPC__VER, "tcp");
  };
  return (cl_p);
};

// DO name
String atoms::className() const {
  return "atoms";
}

// Make from pair
Bool atoms::get(GlishRecord &out, String &err, const servoRPC_Pair &in,
		const String &un) {
  static Vector<Double> pp(2);
  static Quantum<Vector<Double> > xx;
  static QuantumHolder x;
  Record myRec;
  pp(0) = in.c1;
  pp(1) = in.c2;
  xx = Quantum<Vector<Double> >(pp, un);
  x = QuantumHolder(xx);
  if (!x.toRecord(err, myRec)) return False;
  out.fromRecord(myRec);
  return True;
}

// Make from data value
Bool atoms::get(GlishRecord &out, String &err,
		const servoRPC_GetNamedValueOut *in,
		const String nam) {
  if (in->value.value_len > 0) {
    switch (in->value.value_val[0].type) {
    case servoRPC_DTbool: {
      Vector<Bool> x(in->value.value_len);
      for (uInt i=0; i<in->value.value_len; i++) {
	x(i) = in->value.value_val[i].servoRPC_DataValue_u.DATbool;
      };
      out.add(nam, x);
    };
    break;
    case servoRPC_DTint: {
      Vector<Int> x(in->value.value_len);
      for (uInt i=0; i<in->value.value_len; i++) {
	x(i) = in->value.value_val[i].servoRPC_DataValue_u.DATint;
      };
      out.add(nam, x);
    };
    break;
    case servoRPC_DTdouble: {
      Vector<Double> x(in->value.value_len);
      for (uInt i=0; i<in->value.value_len; i++) {
	x(i) = in->value.value_val[i].servoRPC_DataValue_u.DATdouble;
      };
      out.add(nam, x);
    };
    break;
    case servoRPC_DTrelTime:
    case servoRPC_DTabsTime: {
      GlishRecord x;
      if (!get(x, err,
	       in->value.value_val[0].servoRPC_DataValue_u.DATabsTime)) {
	return False;
      };
      out.add(nam, x);
    };
    break;
    case servoRPC_DTpair: {
      GlishRecord x;
      if (!get(x, err,
	       in->value.value_val[0].servoRPC_DataValue_u.DATpair,
	       String("rad"))) return False;
      out.add(nam, x);
    };
    break;
    case servoRPC_DTstring: {
      String x(in->value.value_val[0].servoRPC_DataValue_u.DATstring);
      out.add(nam, x);
    };
    break;
    case servoRPC_DTangle: {
      Vector<Double> x(in->value.value_len);
      for (uInt i=0; i<in->value.value_len; i++) {
	x(i) = in->value.value_val[i].servoRPC_DataValue_u.DATdouble;
      };
      Quantum<Vector<Double> > xx(x, "rad");
      QuantumHolder y(xx);
      GlishRecord detail;
      Record myRec;
      if (!y.toRecord(err, myRec)) return False;
      detail.fromRecord(myRec);
      out.add(nam, detail);
    };
    break;
    case servoRPC_DTtime: {
      Vector<Double> x(in->value.value_len);
      for (uInt i=0; i<in->value.value_len; i++) {
	x(i) = in->value.value_val[i].servoRPC_DataValue_u.DATdouble;
      };
      Quantum<Vector<Double> > xx(x, "rad");
      QuantumHolder y(xx);
      GlishRecord detail;
      Record myRec;
      if (!y.toRecord(err, myRec)) return False;
      detail.fromRecord(myRec);
      out.add(nam, detail);
    };
    break;
    default:
      err = "Illegal data type";
      return False;
    };	
  };

  return True;
}

// Make from Abs time
Bool atoms::get(GlishRecord &out, String &err, const servoRPC_AbsTime &in) {
  static Quantum<Double> xx;
  static QuantumHolder x;
  xx = Quantum<Double>(toDouble(in), "us");
  x = QuantumHolder(xx);
  Record myRec;
  if (!x.toRecord(err, myRec)) return False;
  out.fromRecord(myRec);
  return True;
}

// Get state
Bool atoms::get(GlishRecord &out, String &err, const servoRPC_State &in) {
  static const String nam[N_servoRPC_State] = {
    "UNKNOWN", "UNKNOWN", "STOWED", "STOWING",
    "UNSTOWING", "STOWERROR", "PARKED", "PARKING",
    "STOPPING", "IDLE", "GOTO", "SLEWING",
    "TRACKING", "INLIMITS", "DRIVEERROR", "RESETTING"
  };
  if (uInt(in) >= N_servoRPC_State) {
    err = "Illegal state";
    return False;
  };
  out.add(String("state"), nam[in]);
  return True;
}

// Available methods
Vector<String> atoms::methods() const {
  Vector<String> tmp(22);
  tmp(0) = "connect";			// connect ACC
  tmp(1) = "disconnect";	       	// disconnect ACC
  tmp(2) = "getpos";			// get pos from GetInfo
  tmp(3) = "getshort";			// get short info (first only)
  tmp(4) = "getinfo";			// get all info
  tmp(5) = "getname";			// get specified names
  tmp(6) = "getsnames";			// get short info name list
  tmp(7) = "testconnect";		// test connection
  tmp(8) = "readsinfo";			// read the short info buffer
  tmp(9) = "pow";			// raise to power
  tmp(10)= "totime";			// convert angle to time
  tmp(11)= "toangle";			// convert time to angle
  tmp(12)= "constants";			// get a constant
  tmp(13)= "qfunc1";			// one argument quantity function
  tmp(14)= "qfunc2";			// two argument quantity function
  tmp(15)= "qvfunc1";			// one argument q<vector> function
  tmp(16)= "unitv";			// unit(vector)
  tmp(17)= "qvvfunc2";			// two argument q<vector> function
  tmp(18)= "quant";			// quant
  tmp(19)= "dopcv";			// doppler value conversion
  tmp(20)= "frqcv";                     // freq converter
  tmp(21)= "tfreq";                     // table freq formatter

  return tmp;
}

// Untraced methods
Vector<String> atoms::noTraceMethods() const {
  return methods();
}

// Execute methods
MethodResult atoms::runMethod(uInt which,
			      ParameterSet &parameters,
			      Bool runMethod) {

  static String returnvalName = "returnval";
  static String valName  = "val";
  static String argName  = "arg";
  static String formName = "form";
  static String form2Name= "form2";

  switch (which) {

  // Connect
  case 0: {
    Parameter<String> arg(parameters, argName,
			  ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName,
			      ParameterSet::Out);
    if (runMethod) {
      returnval() = atoms::connect(arg());
    };
  }
  break;

  // Disconnect
  case 1: {
    Parameter<Bool> returnval(parameters, returnvalName,
			      ParameterSet::Out);
    if (runMethod) {
      if (cl_p) clnt_destroy(cl_p);
      cl_p = 0;
      returnval() = True;
    };
  }
  break;

  // getpos
  case 2: {
    Parameter<Vector<Double> > returnval(parameters, returnvalName,
					 ParameterSet::Out);
    if (runMethod) {
      servoRPC_GetInfoOut *out;
      if (!cl_p) return error("No connection established");
      out = servo_rpc__get_info_1(0, cl_p);
      if (!out) return error("Cannot do the GetInfo");
      returnval().resize(2);
      returnval()(0) = out->pos.pos_val[0].c1;
      returnval()(1) = out->pos.pos_val[0].c2;
    };
  }
  break;

  // getshort
  case 3: {
    Parameter<GlishRecord> returnval(parameters, returnvalName,
				     ParameterSet::Out);
    if (runMethod) {
      if (!cl_p) return error("No connection established");
      GlishRecord tmp;
      servoRPC_GetShortInfoNamesOut *nout;
      servoRPC_GetShortInfoIn in;
      nout = servo_rpc__get_shortinfo_names_1(&in, cl_p);
      if (!nout) return error("Cannot do GetShortInfoNames");
      servoRPC_GetShortInfoOut *out;
      out = servo_rpc__get_shortinfo_1(&in, cl_p);
      if (!out) return error("Cannot do GetShortInfo");
      tmp.add(String("name"), String(nout->names.names_val[0].name));
      switch (nout->names.names_val[0].type) {
      case servoRPC_DTbool:
	tmp.add(String("value"),
		Bool(out->points.points_val[0].info.info_val[0].
		     value.value_val[0].servoRPC_DataValue_u.DATbool));
	break;
      case servoRPC_DTdouble:
	tmp.add(String("value"),
		Double(out->points.points_val[0].info.info_val[0].
		       value.value_val[0].servoRPC_DataValue_u.DATdouble));
	break;
      default:
	tmp.add(String("value"),
		Int(out->points.points_val[0].info.info_val[0].
		    value.value_val[0].servoRPC_DataValue_u.DATint));
	break;
      } // switch
      returnval() = tmp;
    };
  }
  break;

  // getinfo
  case 4: {
    Parameter<GlishRecord > returnval(parameters, returnvalName,
				      ParameterSet::Out);
    if (runMethod) {
      if (!cl_p) return error("No connection established");
      servoRPC_GetInfoOut *out;
      out = servo_rpc__get_info_1(0, cl_p);
      if (!out) return error("Cannot do the GetInfo");
      GlishRecord tmp;
      GlishRecord detail;
      String err;
      if (!get(detail, err, out->timeStamp)) return error(err);
      tmp.add(String("stamp"), detail);
      tmp.add(String("status"), Int(out->status));
      if (!get(tmp, err, out->state)) return error(err);
      tmp.add(String("rebooted"), Bool(out->rebooted));
      tmp.add(String("interpol"), Int(out->interpScheme));
      if (!get(detail, err, out->pos.pos_val[0],
	       String("rad"))) return error(err);
      tmp.add(String("pos"), detail);
      if (!get(detail, err, out->reqPos,
	       String("rad"))) return error(err);
      tmp.add(String("reqpos"), detail);
      if (!get(detail, err, out->rate.rate_val[0],
	       String("rad/s"))) return error(err);
      tmp.add(String("rate"), detail);
      if (!get(detail, err, out->reqRate,
	       String("rad/s"))) return error(err);
      tmp.add(String("reqrate"), detail);
      if (!get(detail, err, out->target,
	       String("rad"))) return error(err);
      tmp.add(String("target"), detail);
      if (!get(detail, err, out->estTime)) return error(err);
      tmp.add(String("esttime"), detail);
      tmp.add(String("remopblocked"), Bool(out->remOpBlocked));

      returnval() = tmp;
    };
  }
  break;

  // getname  
  case 5: {
    Parameter<Vector<String> > arg(parameters, argName,
				   ParameterSet::In);
    Parameter<GlishRecord> returnval(parameters, returnvalName,
				     ParameterSet::Out);
    if (runMethod) {
      if (!cl_p) return error("No connection established");
      GlishRecord tmp;
      String err;
      servoRPC_GetNamedValueOut *out;
      servoRPC_GetNamedValueIn in;
      for (uInt i=0; i<arg().nelements(); i++) {
	in.name.name = (char *)(arg()(i).chars());
	out = servo_rpc__get_namedvalue_1(&in, cl_p);
	if (!out) return error("Cannot do the GetNamedValue");
	if (out->status != servoRPC_ok)
	  return error(String("Illegal name") + arg()(i));
	String nam(out->name.name);
	nam.downcase();
	if (!get(tmp, err, out, nam)) return error(err);
      };
      returnval() = tmp;
    };
  }
  break;

  // getsnames
  case 6: {
    Parameter<Vector<String> > returnval(parameters, returnvalName,
					 ParameterSet::Out);
    if (runMethod) {
      returnval().resize(0);
      servoRPC_GetShortInfoIn in;
      servoRPC_GetShortInfoNamesOut *out;
      out = servo_rpc__get_shortinfo_names_1(&in, cl_p);
      returnval().resize(out->names.names_len);
      for (uInt i=0; i<out->names.names_len; i++) {
	returnval()(i) = String(out->names.names_val[i].name);
      };
    };
  }
  break;

  // testconnect
  case 7: {
    Parameter<Bool> returnval(parameters, returnvalName,
			      ParameterSet::Out);
    if (runMethod) {
      returnval() = (cl_p);
    };
  }
  break;

  // readsinfo
  case 8: {
    Parameter<Vector<Int> > arg(parameters, argName,
				ParameterSet::In);
    Parameter<GlishRecord> returnval(parameters, returnvalName,
				     ParameterSet::Out);
    if (runMethod) {
      String err;
      servoRPC_GetShortInfoIn in;
      servoRPC_GetShortInfoOut *out;
      out = servo_rpc__get_shortinfo_1(&in, cl_p);
      GlishRecord tmp;
      Char nam[6] = "a0000";
      for (uInt i=0; i<out->points.points_len; i++) {
	GlishRecord detail;
	GlishRecord det;
	if (!get(detail, err, out->points.points_val[i].timeStamp)) {
	  return error(err);
	};
	detail.add(String("stamp"),
		   toDouble(out->points.points_val[i].timeStamp));
	detail.add(String("state"),
		   out->points.points_val[i].info.info_val[arg()(0)].
		   value.value_val[0].servoRPC_DataValue_u.DATint);
	detail.add(String("posaz"),
		   out->points.points_val[i].info.info_val[arg()(1)].
		   value.value_val[0].servoRPC_DataValue_u.DATpair.c1);
	detail.add(String("posel"),
		   out->points.points_val[i].info.info_val[arg()(1)].
		   value.value_val[0].servoRPC_DataValue_u.DATpair.c2);
	detail.add(String("rposaz"),
		   out->points.points_val[i].info.info_val[arg()(2)].
		   value.value_val[0].servoRPC_DataValue_u.DATpair.c1);
	detail.add(String("rposel"),
		   out->points.points_val[i].info.info_val[arg()(2)].
		   value.value_val[0].servoRPC_DataValue_u.DATpair.c2);
	tmp.add(String(nam), detail);
	for (uInt j=4; j>0; j--) {
	  if (++(nam[j]) > '9') nam[j] = '0';
	  else break;
	};
      };
      returnval() = tmp;
    };
  }
  break;

  default: {
    return error("Unknown method");
  }

  };
  return ok();
}
