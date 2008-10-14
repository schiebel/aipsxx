//# DOionosphere.cc: 
//# Copyright (C) 2001,2002
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
//# $Id: DOionosphere.cc,v 19.6 2005/11/07 21:17:04 wyoung Exp $

#include <appsglish/ionosphere/DOionosphere.h>
#include <casa/Exceptions/Error.h>
#include <tasking/Glish.h>
#include <casa/iostream.h>
    
#include <casa/namespace.h>
// -----------------------------------------------------------------------
// ionosphere
// Default constructor and destructor
// -----------------------------------------------------------------------
ionosphere::ionosphere () 
{
  Ionosphere::debug_level=0;  
  ionoModel = new IonosphModelPIM();
  iono = new Ionosphere(ionoModel);
}

ionosphere::~ionosphere()
{
  if( ionoModel ) 
    delete ionoModel;
  if( iono ) 
    delete iono;
}

// -----------------------------------------------------------------------
// compute
// Sets up ionosphere, computes profiles, line-of-sight
// magnetic field, tecs and rotation measures.
// Inputs: slants is an (N,6) array. Column 0 is the MJD. Columns 1-3 are
// the ITRF position (meters). Columns 4, 5 are Az, El (in radians).
// Outputs: tec (N), rmi (N) and edp (N,Nalt)
// -----------------------------------------------------------------------
Array<Float> ionosphere::compute ( Vector<Double> &tec,Vector<Double> &rmi,
                                   LogicalVector  &isUniq,
                                   Array<Float>   &emf, 
                                   Array<Float>   &lon,Array<Float>  &lat,
                                   Array<Float>   &alt,Array<Float>  &rng,
                                   Array<Double>  &slants,
                                   const GlishRecord &opt )
{
// check that slants array is of correct dimensions
  if( slants.ndim() != 2 || slants.shape()(1) != 6 )
    throw("non-conforming slants array");
// setup slants block
  uInt nsl = slants.shape()(0);
  cout<<"ionosphere::compute: "<<nsl<<" slants\n";
  SlantSet sl_set(nsl);
  for( uInt i=0; i<nsl; i++ )
  {
// extract one row of slants matrix, corresponding to a slant
    Vector<Double> row( slants(IPosition(2,i,0),IPosition(2,i,5))
                          .reform(IPosition(1,6)) );
//    cerr<<row<<endl;
//    cerr<<row(IPosition(1,4),IPosition(1,5))<<endl;
//    cerr<<row(IPosition(1,1),IPosition(1,3))<<endl;
    sl_set[i].set( row(0),
        MVDirection( row(IPosition(1,4),IPosition(1,5)) ),
        MVPosition( row(IPosition(1,1),IPosition(1,3)) ) );
//        MVDirection( row(Slice(4,2)) ),
//        MVPosition( row(Slice(1,3)) ) );
  }
  iono->setTargetSlants(sl_set);
// setup options
  if( opt.description().nfields() ) 
  {
    Record optrec;
    opt.toRecord(optrec);
    iono->setModelOptions(optrec);
  }
// compute things
  Block<EDProfile> edp( iono->compute(isUniq) );
// extract results
  iono->getTecRot(tec,rmi,edp);
// convert edp, lon and lat into matrix form
  uInt nalt = edp[0].nelements();
  IPosition shape(2,nalt,nsl),colshape(1,nalt);
  Array<Float> ed( shape );
  emf.resize( shape );
  lon.resize( shape );
  lat.resize( shape );
  rng.resize( shape );
  alt.resize( shape );
  for( uInt i=0; i<nsl; i++ )
  {
    IPosition ip0(2,0,i),ip1(2,nalt-1,i);
     #define copyRow(name,src) { \
          Vector<Float> col( name(ip0,ip1).reform(colshape) ); \
          col = edp[i].src(); }
    copyRow(ed,ed);
    copyRow(emf,getLOSField);
    copyRow(lon,lon);
    copyRow(lat,lat);
    copyRow(alt,alt);
    copyRow(rng,rng);
    #undef copyRow
  }
  
  return ed;
}


    
// -----------------------------------------------------------------------
// className
// Return class name for aips++ DO system
// -----------------------------------------------------------------------
String ionosphere::className() const
{
// Return class name for aips++ DO system
// Outputs:
//    className    String    Class name
//
  return "ionosphere";
};

// -----------------------------------------------------------------------
// methods
// Return class methods names for aips++ DO system
// -----------------------------------------------------------------------
Vector <String> ionosphere::methods() const
{
  const char *method_names[] = {
        "setmodel",
        "compute",
        "debuglevel"
      };

  const uInt nm = sizeof(method_names)/sizeof(method_names[0]);
  Vector <String> method(nm);
  for( uInt i=0; i<nm; i++ )
    method(i) = method_names[i];
  return method;
};


// -----------------------------------------------------------------------
// runMethod
// Mechanism to allow execution of class methods from the 
// aips++ DO system.
// Inputs:
//    which        uInt               Selected method
//    inpRec       ParameterSet       Associated input parameters
//    runMethod    Bool               Execute method ?
// -----------------------------------------------------------------------
MethodResult ionosphere::runMethod (uInt which, ParameterSet& inpRec, 
                                    Bool runMethod)
{
  switch( which ) 
  {
    case 0: // setmodel - ignored for now, since PIM is the only one
      break;
    
    case 1: // compute - computes ED profiles for the specified slants
    {
      Parameter< Array<Double> >  slants(inpRec,"slants", ParameterSet::In);
      Parameter< GlishRecord >   opt(inpRec,"opt", ParameterSet::In);
      Parameter< Vector<Double> > tec(inpRec,"tec", ParameterSet::Out);
      Parameter< Vector<Double> > rmi(inpRec,"rmi", ParameterSet::Out);
      Parameter< Array<Float> >   lon(inpRec,"lon", ParameterSet::Out);
      Parameter< Array<Float> >   lat(inpRec,"lat", ParameterSet::Out);
      Parameter< Array<Float> >   alt(inpRec,"alt", ParameterSet::Out);
      Parameter< Array<Float> >   rng(inpRec,"rng", ParameterSet::Out);
      Parameter< Array<Float> >   emf(inpRec,"emf", ParameterSet::Out);
      Parameter< Vector<Bool> >   isuniq(inpRec,"isuniq", ParameterSet::Out);
      Parameter< Array<Float> >   edp(inpRec,"returnval", ParameterSet::Out);
      if( runMethod ) 
      {
        try 
        {
//          cout << slants();
          edp() = compute(tec(),rmi(),isuniq(),emf(),lon(),lat(),alt(),rng(),slants(),opt());
        }
        catch( AipsError err ) 
        {
          return error( err.getMesg() );
        }
      }
      break;
    }
    case 2: // debuglevel - sets the Ionosphere debug level
    {
      Parameter <Int> level(inpRec,"level", ParameterSet::In);
      if( runMethod ) 
        Ionosphere::debug_level = level();  
      break;
    }
    

//     case 2: // gettecrmi - computes TEC/RMI for specified slants
//       Parameter <Array<Double>>  edp(inpRec,"edp", ParameterSet::In);
//       Parameter <Vector<Double>> tec(inpRec,"tec", ParameterSet::Out);
//       Parameter <Vector<Double>> rmi(inpRec,"rmi", ParameterSet::Out);
//       if( runMethod ) 
//       {
//         gettecrmi(edp(),tec(),rmi());
//       }
//       break;

    default: 
      return error("No such method");

  }
  return ok();
}

