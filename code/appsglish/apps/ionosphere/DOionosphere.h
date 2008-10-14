#ifndef APPSGLISH_DOIONOSPHERE_H
#define APPSGLISH_DOIONOSPHERE_H

#include <casa/aips.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Tasking.h>                                          
#include <ionosphere/Ionosphere/Ionosphere.h>
#include <ionosphere/Ionosphere/IonosphModelPIM.h>

    
#include <casa/namespace.h>
// <summary>
// Implements the ionosphere DO
// </summary>
class ionosphere : public ApplicationObject                         
{
public:

  ionosphere();
  ~ionosphere();

  virtual String className() const;                              
  virtual Vector<String> methods() const;                        
  virtual MethodResult runMethod(uInt which,                     
                                ParameterSet &parameters,
                                Bool runMethod);
  
private:
  // Sets up Ionosphere object, computes for specified slants,
  // returns array (matrix) of EDPs, as well as TECs and rotation
  // measures
  Array<Float> compute ( Vector<Double> &tec,Vector<Double> &rmi, 
                        LogicalVector  &isUniq,
                        Array<Float>  &emf,
                        Array<Float>  &lon,Array<Float>  &lat,
                        Array<Float>  &alt,Array<Float>  &rng,
                        Array<Double> &slants,
                        const GlishRecord &fix );

    

  Ionosphere      *iono;
  IonosphModelPIM *ionoModel;
};


#endif
