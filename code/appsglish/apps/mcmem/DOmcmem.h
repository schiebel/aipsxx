//# DOmcmem.h: defines classes for mcmem DO.
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
//#
//# $Id: DOmcmem.h,v 19.7 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_DOMCMEM_H
#define APPSGLISH_DOMCMEM_H
#include <stdio.h>
#include <string>
#include <iostream>
#include <fstream>
#include <math.h>

#include <casa/aips.h>

#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/MatrixMath.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Matrix.h>

#include <scimath/Mathematics/Convolver.h>
#include <casa/BasicMath/Random.h>

#include <tasking/Tasking.h>

#include <datatransform.h>

#include <casa/namespace.h>

using std::string;

template<class T> class mcmem : public ApplicationObject 
{
	public:
		mcmem();
		mcmem(Int pparam);
		~mcmem();
		
		Int initmem(Int niter,T ineps,Array<T> &inpsf, 
			    Array<T> &inwt);

	
		Int mem(Int inprnum, Array<T> &inprior,
			Array<T> &indata,
			Array<T> &outimage, T &outfit);

		Int montecarloimage(Array<T> &instartimage,
				    Array<T> &inpriorimage, 
				    Int nrealize, 
				    Array<T> &outmeanimage, 
				    Array<T> &outvarimage, 
				    Array<T> &outskewimage, 
				    Array<T> &outkurtimage, 
				    Int &outnsamples, 
				    Array<T> &outtrack);
		
		Int montecarlodata(Int nrealize,T insigma,
				   Array<T> &incleandata,
				   Array<T> &outmeanimage,
				   Array<T> &outvarimage, 
				   Array<T> &outskewimage, 
				   Array<T> &outkurtimage);


		Int next();
        	Int cal_chisq(Array<T> &array);
		Int cal_grad_chisq(Array<T> &array);
		Int cal_entropy_flux(Array<T> &array);
		Int grad_eval();
		Int change_alpha();
		T calculate_step();
		T gradient_dot_step();
		Array<T> take_step(Array<T> in1,Array<T> in2,
				   T w1, T w2);
		Int update_alpha();


		Int cal_logp(Array<T> &array);
		Int trial();
		Int propose_trial();
		Int accept_trial();


		virtual String className() const;               
   		virtual Vector<String> methods() const;                        
    		virtual MethodResult runMethod(uInt which,
			            ParameterSet &parameters,
                                    Bool runMethod);

		
	private:
		
		MLCG gen;
		Uniform run;
		Normal nrm;
		Timer tmr,tms;
	
		T ttm;
		
		datatransform<T> trans;
		
		IPosition inpshape,shape,iter,memit;
		IPosition hh,t0,t1,t2;
		Int niters,dim;
		T epsilon;

		Array<T> psf,prior,data,image,wt,wwt;
		
		//Matrix<T> inversehessian;
		Array<T> ihdiag;
		Array<T> trialimage,memimage;
		
		Array<T> fit,gradient,track;
		
		Array<T> gradchisq,gdg,step,temp,ihess;
		
		T adscale;
		
		Int N,ENT;
		Int flag;
		T chisq, tchisq, flux, tflux, qpsf ;
		T alpha, nrmgrd, entropy, length;
		T tol, std;

		T logp,logpimage,logpdata,logpcurrent,logptrial;
	
};


#endif
