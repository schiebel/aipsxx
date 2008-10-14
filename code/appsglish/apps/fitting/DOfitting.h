//# DOfitting.h: This class gives Glish to Fitting connection
//# Copyright (C) 1999,2000,2002,2004
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: DOfitting.h,v 19.7 2004/11/30 17:50:07 ddebonis Exp $

#ifndef APPSGLISH_DOFITTING_H
#define APPSGLISH_DOFITTING_H

//# Includes

#include <casa/aips.h>
#include <tasking/Tasking.h>

#include <casa/namespace.h>
//# Forward declarations
namespace casa { //# NAMESPACE CASA - BEGIN
class String;
//class LSQaips;

template<class T> class GenericL2Fit;
//template<class T> class Array;
template<class T> class Vector;
} //# NAMESPACE CASA - END

// <summary> This class gives Glish to Fitting connection</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto module=Tasking>Tasking</linkto>
//   <li> <linkto module=Fitting>Fitting</linkto>
// </prerequisite>

// <etymology>
// Distributed Object and fitting
// </etymology>

// <synopsis>
// The class makes the connection between the
// <linkto module=Fitting>Fitting</linkto> module and the Glish
// distributed object system. It provides a series of Glish callable
// methods. See Aips++ Note 197 for details. <br>
// Operations supported
// are all the fitting methods supported in the Fitting module
// </synopsis>

// <example>
// For an example of the class use, see the <src>fitting.g</src> application.
// </example>

// <motivation>
// To provide a direct user interface between the user and 
// <linkto module=Fitting>Fitting</linkto> related calculations.
// </motivation>

// <todo asof="2004/08/30">
//  <li> Nothing I know of
// </todo>

class fitting : public ApplicationObject {

public:
  //# Standard constructors/destructors

  fitting();
  fitting(const fitting &other);
  fitting &operator=(const fitting &other);
  ~fitting();

  // Required Tasking methods
  // <group>
  virtual String className() const;
  virtual Vector<String> methods() const;
  virtual MethodResult runMethod(uInt which,
				 ParameterSet &parameters,
				 Bool runMethod);
  // </group>

  // Stop tracing
  virtual Vector<String> noTraceMethods() const;

private:
  // Class to aid in distributing different fitters
  class FitType {
  public:
    //# Constructors
    // Default constructor: no method known
    FitType();
    // Destructor
    ~FitType();
    //# Method
    // Set a fitter pointer (real or complex)
    // <group>
    void setFitter   (GenericL2Fit<Double> *ptr);
    void setFitterCX (GenericL2Fit<DComplex> *ptr);
    // </group>
    // Get a fitter pointer (real or complex)
    // <group>
    GenericL2Fit<Double>   *const &getFitter() const;
    GenericL2Fit<DComplex> *const &getFitterCX() const;
    // </group>
    // Set the status
    void setStatus(Int n, Int typ, Double colfac, Double lmfac);
    // Get the number of terms in condition equation
    Int getNceq() const { return nceq_p;} ;
    // Get the number of unknowns
    Int getN() const { return n_p;} ;
    // Get the number of real unknowns
    Int getNreal() const { return nreal_p;} ;
    // Get the type
    Int getType() const { return typ_p;} ;
    // Get the collinearity factor
    Double getColfac() const { return colfac_p;} ;
    // Get the Levenberg-Marquardt factor
    Double getLMfac() const { return lmfac_p;} ;
    // Set solution done or not
    void setSolved(Bool solved);
    // Solution done?
    Bool getSolved() const { return soldone_p;} ;
  private:
    // Copy constructor: not implemented
    FitType(const FitType &other); 
    // Assignment: not implemented
    FitType &operator=(const FitType &other);
    //# Data
    // Pointer to a Fitting Machine: real or complex
    // <group>
    casa::GenericL2Fit<Double> *fitter_p;
    casa::GenericL2Fit<DComplex> *fitterCX_p;
    // </group>
    // Number of unknowns
    Int n_p;
    // Number of terms in condition equation
    Int nceq_p;
    // Number of real unknowns
    Int nreal_p;
    // Type
    Int typ_p;
    // Collinearity factor
    Double colfac_p;
    // Levenberg-Marquardt factor
    Double lmfac_p;
    // Solution done?
    Bool soldone_p;
    // System's rank deficiency
    uInt nr_p;
  };
  //# Member functions
  //# Data
  // Number of FitType obkects present
  uInt nFitter_p;
  // List of FitTypes
  FitType **list_p;
};


#endif
