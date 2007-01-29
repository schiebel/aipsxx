//# DOmcmem.cc : implements the mcmem DO
//#
//# mcmem class to compute MEM solutions + monte carlo methods 
//#
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
//# $Id: DOmcmem.cc,v 19.8 2006/01/17 11:25:58 gvandiep Exp $


#include <DOmcmem.h>
#include <casa/BasicMath/Math.h>
//#define DBG 

#include <casa/namespace.h>


/* Default Constructor */
template<class T> mcmem<T>::mcmem():
		run((RNG*)NULL,(Double)0.0,(Double)1.0),
		nrm((RNG*)NULL,(Double)0.0,(Double)1.0),
		trans()
{
#ifdef DBG
	cout << "begin !" << endl;
#endif
	
}

/* constructor to be used later with diff input params */
template<class T> mcmem<T>::mcmem(Int pparam):
		run((RNG*)NULL,(Double)0.0,(Double)1.0),
		nrm((RNG*)NULL,(Double)0.0,(Double)1.0),
		trans()
{
#ifdef DBG
	cout << "begin with " << pparam << " !" << endl;
#endif
	
}

/* Destructor */
template<class T> mcmem<T>::~mcmem()
{
#ifdef DBG
	cout << "done !" << endl;
#endif
}

/* Tasking + Glish binding... */
template<class T> String mcmem<T>::className() const
{
	return("mcmem");
}


/* Tasking + Glish binding... */
template<class T> Vector<String> mcmem<T>::methods() const
{
	Vector<String> methodlist(4);
	methodlist[0] = "initmem";
	methodlist[1] = "mem";
	methodlist[2] = "montecarloimage";
	methodlist[3] = "montecarlodata";
	
	return methodlist;
}
 


/* Tasking + Glish binding... */
template<class T> MethodResult mcmem<T>::runMethod(uInt which,
                                                   ParameterSet &parameters,
                                                   Bool runMethod)
{
    	static String niterName = "niter";                                  
    	static String inepsName = "ineps";                                  
	static String inpsfName = "inpsf";                                  
    	static String inprnumName = "inprnum";                                  
    	static String inpriorName = "inprior";                                  
    	static String indataName = "indata";                                  
    	static String inwtName = "inwt";                                  
    	static String outimageName = "outimage";                                  
    	static String outfitName = "outfit";                                  
    	
    	static String instartimageName = "instartimage";            
    	static String inpriorimageName = "inpriorimage";            
    	static String nrealizeName = "nrealize";                                  
    	static String outmeanimageName = "outmeanimage";            
    	static String outvarimageName = "outvarimage";            
    	static String outskewimageName = "outskewimage";            
    	static String outkurtimageName = "outkurtimage";            
    	static String outnsamplesName = "outnsamples";            
    	static String outtrackName = "outtrack";            
	
	static String insigmaName = "insigma";
	static String incleandataName = "incleandata";
	
	static String returnvalName = "returnval";                  
                                                               
    	switch (which) 
    	{
		case 0:
			{
			    Parameter<Int> niter(parameters,niterName, 
			                         ParameterSet::In); 
			    Parameter<T> ineps(parameters,inepsName, 
			                        ParameterSet::In); 
			    Parameter<Array<T> > inpsf(parameters,inpsfName, 
			                                ParameterSet::In); 
			    Parameter<Array<T> > inwt(parameters,inwtName, 
			                               ParameterSet::In); 
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = initmem(niter(),ineps(),
						    inpsf(),inwt()); 
			    break;         
			}
    
		case 1:
			{
			    Parameter<Int> inprnum(parameters,inprnumName, 
			                                  ParameterSet::In); 
			    Parameter<Array<T> > inprior(parameters,inpriorName, 
			                                  ParameterSet::In); 
			    Parameter<Array<T> > indata(parameters,indataName, 
			                                 ParameterSet::In); 
			    Parameter<Array<T> > outimage(parameters, outimageName,
					                   ParameterSet::Out);
			    Parameter<T> outfit(parameters, outfitName,
					         ParameterSet::Out);
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = mem(inprnum(),inprior(),indata(),outimage(),outfit()); 
			    break;                                            
			}
		case 2:
			{
			    Parameter<Array<T> > instartimage(parameters,
					                       instartimageName,
					                       ParameterSet::In);
			    Parameter<Array<T> > inpriorimage(parameters,
					                       inpriorimageName,
					                       ParameterSet::In);
			    Parameter<Int> nrealize(parameters,nrealizeName, 
			                            ParameterSet::In); 
			    Parameter<Array<T> > outmeanimage(parameters,
					                       outmeanimageName,
					                       ParameterSet::Out);
			    Parameter<Array<T> > outvarimage(parameters,
					                       outvarimageName,
					                       ParameterSet::Out);
			    Parameter<Array<T> > outskewimage(parameters,
					                       outskewimageName,
					                       ParameterSet::Out);
			    Parameter<Array<T> > outkurtimage(parameters,
					                       outkurtimageName,
					                       ParameterSet::Out);
			    Parameter<Int> outnsamples(parameters,
					            outnsamplesName,
					            ParameterSet::Out);
			    Parameter<Array<T> > outtrack(parameters,
					                 outtrackName,
					                 ParameterSet::Out);
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = montecarloimage(instartimage(),
						    inpriorimage(),nrealize(),
						    outmeanimage(),outvarimage(),
						    outskewimage(),outkurtimage(),
						    outnsamples(),outtrack()); 
			    break;                                            
			}
    
		case 3:
			{
			    Parameter<Int> nrealize(parameters,nrealizeName, 
			                            ParameterSet::In); 
			    Parameter<T> insigma(parameters,insigmaName, 
			                         ParameterSet::In); 
			    
			    Parameter<Array<T> > incleandata(parameters,
					                 incleandataName, 
			                                 ParameterSet::In); 
			    
			    Parameter<Array<T> > outmeanimage(parameters,
					                 outmeanimageName,
					                   ParameterSet::Out);
			    Parameter<Array<T> > outvarimage(parameters,
					                       outvarimageName,
					                       ParameterSet::Out);
			    Parameter<Array<T> > outskewimage(parameters,
					                       outskewimageName,
					                       ParameterSet::Out);
			    Parameter<Array<T> > outkurtimage(parameters,
					                       outkurtimageName,
					                       ParameterSet::Out);
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = montecarlodata(nrealize(),
						    insigma(),incleandata(),
						    outmeanimage(),outvarimage(),
						    outskewimage(),outkurtimage()); 
			    break;                                            
			}
		default:                                             
        	return error("Unknown method");               
	}  
	
	return ok();     
	
}

/*************************************************************************/

/* Calculate chisq */
template<class T> Int mcmem<T>::cal_chisq(Array<T> &array)
{
	//tms.mark();
	trans.image_to_data(array,temp);
	//ttm += (T)tms.real();
	
	temp -= data;
	chisq = sum(wt*temp*temp);
	return 0;
}

/* Calculate chisq and gradient of chisq */
template<class T> Int mcmem<T>::cal_grad_chisq(Array<T> &array)
{
	//tms.mark();
	trans.image_to_data(array,temp);
	//ttm += (T)tms.real();
	
	temp -= data;
	chisq = sum(wt*temp*temp);
	temp = (T)2*wt*temp;
	
	/* This convolution is because Chisq is in the image domain */
	//tms.mark();
	trans.data_to_image(temp,gradchisq);
	//ttm += (T)tms.real();
	return 0;
}

/* Calculate entropy and flux */
/* **************************************************
 * Penalty Functions : ENT
 * ENT = 0 : Entropy : -Ilog(I/M) + I-M
 * ENT = 1 : Emptiness : -log(cosh((I-M)/sigma))
 * ENT = 2 : Positivity : log(I)
 * ENT = 3 : Emptiness + Positivity 
 * **************************************************/
template<class T> Int mcmem<T>::cal_entropy_flux(Array<T> &array)
{
	temp = 1.0;
	flux = sum(array);
	switch(ENT)
	{
		case 0:
			entropy = sum(array*(temp-log(array/prior)) - prior);
			break;
		case 1:
			if(isInf(sum(log(cosh(array-prior)*wwt))))
				entropy = (T)(-1.0) * sum(abs(array-prior)*wwt);
			else
				entropy = (T)(-1.0) * sum(log(cosh((array-prior)*wwt)));
			break;
		case 2:
			entropy = sum(log(array + (T)0.000001));
			break;
		case 3:
			if(isInf(sum(log(cosh(array-prior)*wwt))))
				entropy = (T)(-1.0) * sum(abs(array-prior)*wwt);
			else
				entropy = (T)(-1.0) * sum(log(cosh((array-prior)*wwt)));
			entropy = entropy + sum(log(array + (T)0.000001));
			break;
	}
	
	return 0;
}

/* Evaluate gradient of J, the Hessian, and the step */
template<class T> Int mcmem<T>::grad_eval()
{
	step = 0;gdg = 0.0;
	ihess = 0.0;
	
	flux = 0.0;
	flux = sum(image);

	/* temp : gradient of J=H-alpha.chisq = grad J
	 * ihess : approximate inverse Hessian = grad grad J
	 * step : grad grad J * grad J
	 */
	
	switch(ENT)
	{
		case 0:
			temp = (T)(-1.0) * log(image/prior);
			ihess = (image/(alpha*qpsf*wt*image + (T)1.0));
			step = (ihess) * (temp - alpha*gradchisq);
			break;
		case 1:
			temp = (T)(-1.0) * wwt * tanh((image-prior)*wwt);
			ihess = (T)1.0/((pow(tanh((image-prior)*wwt),(T)2.0) + (T)1.0)*wwt*wwt + alpha*qpsf);
			step = ihess * (temp - alpha*gradchisq);
			break;
		case 2:
			temp = (T)(1.0)/image;
			ihess = (image*image)/(alpha*qpsf*image*image + (T)1.0);
			step = ihess * (temp - alpha*gradchisq);
			break;
		case 3:
			temp = (T)(-1.0) * wwt * tanh((image-prior)*wwt);
			temp += (T)(1.0)/image;
			ihess = (T)1.0/((pow(tanh((image-prior)*wwt),(T)2.0) + (T)1.0)*wwt*wwt + alpha*qpsf + (T)1.0/((image+(T)1e-5)*(image+(T)1e-5)));
			
			step = ihess * (temp - alpha*gradchisq);
			break;
	}

	/* Compute Second Derivatives to later estimate Alpha
	 * alpha = || grad H || / || grad Chisq ||
	 */
	
	hh[0]=0;hh[1]=0;gdg(hh) = sum(temp*ihess*temp);
	hh[0]=0;hh[1]=1;gdg(hh) = sum(temp*ihess*gradchisq);
	hh[0]=1;hh[1]=1;gdg(hh) = sum(gradchisq*ihess*gradchisq);


	t0[0]=0;t0[1]=2;t1[0]=0;t1[1]=0;t2[0]=0;t2[1]=1;
	gdg(t0) = gdg(t1) - alpha * gdg(t2);
	
	t0[0]=1;t0[1]=2;t1[0]=0;t1[1]=1;t2[0]=1;t2[1]=1;
	gdg(t0) = gdg(t1) - alpha * gdg(t2);
	
	t0[0]=2;t0[1]=2;t1[0]=0;t1[1]=0;t2[0]=1;t2[1]=1;
	hh[0]=0;hh[1]=1;
	gdg(t0) = gdg(t1) + alpha * alpha * gdg(t2) - 2 * alpha * gdg(hh);

	length = gdg(t1) + alpha * alpha * gdg(t2);

	return 0;
}

/* Change alpha */
template<class T> Int mcmem<T>::change_alpha()
{

	grad_eval();
	
	if(alpha == 0.0) length = flux;
	
	t0[0]=2;t0[1]=2;
	nrmgrd = gdg(t0)/length;
	
	if(alpha == 0.0) nrmgrd = 0.0;

	if(nrmgrd <= tol) update_alpha();
	else
	{
		t0[0]=0;t0[1]=1; t1[0]=1;t1[1]=1;
		alpha = max(0.0,gdg(t0)/gdg(t1));
#ifdef DBG
		cout << gdg(t0) << "/" << gdg(t1) << endl;
		cout << " change ";
#endif
	}


#ifdef DBG
	cout << "alpha : " << alpha << endl;
#endif
	
	return 0;
}

/* Calculate the Step to be taken */
template<class T> T mcmem<T>::calculate_step()
{
	/* Step gets calculated in grad_eval() */
	grad_eval(); 
	
	/* Monitor the length of the step and control it */
	t0[0]=2; t0[1]=2;
	T grad_dot_step_val = gdg(t0);

	if(length <= 0.0) length = flux;
	nrmgrd = gdg(t0)/length;
	
	return(grad_dot_step_val);
}

/* Evaluate gradient-dot-step */
template<class T> T mcmem<T>::gradient_dot_step()
{
	switch(ENT)
	{
		case 0:
			return( -1* sum(step * (log(image/prior) + alpha*gradchisq)));
		case 1:
			return( -1* sum(step * ( wwt*tanh((image-prior)*wwt) + alpha*gradchisq)));
		case 2:
			return( sum(step * ( (T)1.0/image - alpha*gradchisq)));
			
		case 3:
			return( -1* sum(step * ( wwt*tanh((image-prior)*wwt) + alpha*gradchisq - (T)1.0/image )));
		default:
			return(0.0);
	}
}

/* Take the step from in1 to in1+in2 with weights w1 and w2*/
template<class T> Array<T> mcmem<T>::take_step(Array<T> in1,Array<T> in2, T w1, T w2)
{
	return max((in1*w1 + in2*w2),(T)0.1*in1 + (T)1e-8);
}

/* Update alpha - calculate and add delta alpha */
template<class T> Int mcmem<T>::update_alpha()
{
	t0[0]=1;t0[1]=2; t1[0]=1; t1[1]=1;
	T a = gdg(t0)/gdg(t1);
	t0[0]=2; T b = a*a - (gdg(t0) - tol*length)/gdg(t1);

	T damax,damin;
	
	if(b>0.0)
	{
		b = sqrt(b);
		damax = a+b;
		damin = a-b;
	}
	else
	{
		damax = 0.0;
		damin = 0.0;
	}

	t0[0]=1;
	T dalpha = (chisq - tchisq + gdg(t0))/gdg(t1);
	dalpha = max(damin,min(damax,dalpha));
#ifdef DBG	
	cout << " alpha + dalpha : " << alpha << " + " << dalpha << endl;
#endif
	alpha = max(0.0,alpha + dalpha);
#ifdef DBG	
	cout << " update ";
#endif
	return 0;
}

/* One MEM iteration */
template<class T> Int mcmem<T>::next()
{


	if(flag==0) /* first iteration */
	{
		/*Initialize alpha */
		alpha = 0;
		flux = 0;

		cal_grad_chisq(image);
		change_alpha();
	
		flag=1;
	}
	else
	{
		/* Calculate the grad of chisq */
		cal_grad_chisq(image);
	}
	
	/* Calculate the step */
	T pzero = calculate_step();

	
	/* Limit Step to less than the tolerance */
	T scale = 1.0;
	T scalem = 1.0;

	if(nrmgrd > 0.0) scalem = tol/nrmgrd;
	scale = min(1.0,scalem);
	
	/* Take the step - first guess */
	image = take_step(image,step,1.0,scale);

	/*** Calculate the corrective step, from the current image and take it ***/
	
	/* Calculate the grad of chisq */
	cal_grad_chisq(image);
	
	/* Calculate gradient-dot-step */
	T pone = gradient_dot_step();
	
	/* Calculate optimum step (to correct the first guess step) */
	T eps = 1.0;
	if(pzero != pone) eps = pzero/(pzero-pone);
	if(scale != 0.0) eps = min(eps, scalem/scale);
	if(eps <= 0.0) eps = 1.0;

	/* If needed, take the optimum step and calculate grad chisq */
	if(abs(eps - 1.0) > tol)
	{
		image = take_step(image,step,1.0,scale*(eps-1.0));
		cal_grad_chisq(image);
	}

	/* re-adjust the estimate of the hessian diagonal ( area under PSF )*/
	qpsf = (1.0/max(0.5,min(2.0,eps)) + 1.0)/2.0;

	/* Calculate entropy and flux change alpha */
	cal_entropy_flux(image);
	change_alpha();

	return 0;
}

/* Initialize data members for MEM  - Glish bound */
template<class T> Int mcmem<T>::initmem(Int niter,T ineps,Array<T> &inpsf, Array<T> &inwt)
{
	/* Input data from Glish */
	inpshape = inpsf.shape();
	shape = IPosition(1,0);

	/* Initialize a 'transform' time counter */
	ttm = 0.0;

	/* Dimension of input array 1D or 2D */
	dim = inpshape.nelements();

	wwt.resize(shape); wwt=0.0;
#ifdef DBG	
	cout << "Dimension of input arrays : " << dim << endl;
	cout << "inpshape : " << inpshape << endl;
#endif	
	if(dim==2)
	{
		/* Convert from incoming 2D to 1D */
		shape[0] = inpshape[0]*inpshape[1];
		psf = inpsf.reform(shape);
		wt = inwt.reform(shape);
		
	}
	else
	{
		shape = inpshape;
		psf = inpsf;
		wt = inwt;
	}
	
#ifdef DBG	
	cout << "Input psf shape : " << psf.shape() << endl;
#endif	

	/* Used in the MCMC inverse hessian diagonal approximation */
	wwt = sqrt((T)1.0/wt);
	

	/* Initialize everything needed for MEM */
	
	niters = niter;
	epsilon = ineps;

	iter = IPosition(1,0);
	memit = IPosition(1,0);
	hh = IPosition(2);
	t0 = IPosition(2);
	t1 = IPosition(2);
	t2 = IPosition(2);
	
	/* Initialize the 'transform' object with the PSF and data dimension */
	trans.set_psf(psf,dim);

	/* Target Chisq : Normalized Chisq : total number of elements */
	chisq = shape[0];
	tchisq = chisq;

	/* limit on magnitude of the step length */
	tol = 0.1;
	/* Estimate of the area under the PSF : '1' for a normalized psf */
	qpsf = 1.0;

	nrmgrd = 0.0; alpha = 0.0; entropy = 0.0; length = 0.0;

	/* Current image at any stage */
	image.resize(shape); image = 0.0;
		
	/* MEM output vectors - not required for computation */
	fit.resize(IPosition(1,niters)); fit = 0.0;
	gradient.resize(IPosition(1,niters)); gradient = 0.0;
	
	/* Initialize all other workspace arrays */
	gradchisq.resize(shape); gradchisq = 0.0;
	step.resize(shape); step = 0.0;
	gdg.resize(IPosition(2,3,3)); gdg=0.0;
	
	logp = 0.0; logpimage = 0.0; logpdata = 0.0; logpcurrent = 0.0;
	
	flag = 0;
	temp.resize(shape); temp=0.0;
	ihess.resize(shape); ihess=0.0;
	trialimage.resize(shape); trialimage=0.0;

	return 0;
}


/* MEM - Glish bound*/
template<class T> Int mcmem<T>::mem(Int inprnum, Array<T> &inprior,Array<T> &indata, Array<T> &outimage, T &outfit)
{

	/* Set the choice of penalty function */
	ENT = inprnum;

	if(ENT != 0 && ENT != 1 && ENT !=2 && ENT !=3) 
	{
		cout << "Invalid Prior ID : " << ENT << " ...Setting to Entropy." << endl;
		ENT=0;
	}
	
	/* Transfer input arrays to data members */
	if(indata.ndim()==2)
	{
		shape[0] = inpshape[0]*inpshape[1];

		data = indata.reform(shape);
		prior = inprior.reform(shape);
	
	}
	else
	{
		data = indata;
		prior = inprior;
	}
	

	//tms.mark();
		
	/* Total Flux */
	flux = sum(prior);
	tflux = flux;

	/* MEM begins from the default image (called 'prior' here) */
	image = prior;

	qpsf = 1.0;
	nrmgrd = 0.0; alpha = 0.0; entropy = 0.0; length = 0.0;

	fit = 0.0; gradient = 0.0; gradchisq = 0.0; step = 0.0;
	gdg=0.0;
	
	flag = 0;
	temp=0.0;

	/* MEM iterations */
	
	for(memit[0]=0;memit[0]<niters;memit[0]++)
	{
		
		wwt = sqrt(wt) * (T)1.0/sqrt( chisq / (T)shape[0]);
		
		next();
		
#ifdef DBG
		cout << "Sigma estimate : mean of 1/wwt : " << mean((T)1.0/wwt) << endl;
#endif
		
		fit(memit) = sqrt(chisq/tchisq);
		gradient(memit) = nrmgrd;
	
#ifdef DBG
		cout << "Chisq/TChisq : " << chisq << "/" << tchisq ;
		cout << "  --  Fit[" << memit[0] << "] : " << fit(memit) ;
		cout << "  --  Gradient : " << gradient(memit) << endl;
		//getchar();
#endif
		
		if(abs(fit(memit)-1.0) < epsilon && gradient(memit)<epsilon)
			break;

	}// memit

	memit[0]--;
	cout << " MEM Stopping at iteration : " << memit << endl;
	
	/* Log Probability of the Mode : should be maximum */
	cal_logp(image);
	
	/* Mode (MEM) image is written to data member 'memimage' - used in MCMC */
	memimage = image;
	
	flag = 0;

	/* Output Image to Glish */
	if(indata.ndim()==2)
		outimage = image.reform(inpshape);
	else
		outimage = image;
	
	outfit = sqrt(chisq/tchisq);
	
	return 0;
}

/**************** MCMC begins here ! *******************/


/* Calculate Bayesian probabilities */
template<class T> Int mcmem<T>::cal_logp(Array<T> &array)
{

	cal_entropy_flux(array); 
	cal_chisq(array); 

	if(alpha > 0.0)	logpimage = entropy/alpha;
	else logpimage = 0.0;

	logpdata = -0.5 * chisq;
	logp = logpimage + logpdata;

	return 0;
}


/* Propose a trial image */
template<class T> Int mcmem<T>::propose_trial()
{
	trialimage = 0.0;
		
	for(iter[0]=0;iter[0]<shape[0];iter[0]++)
		trialimage(iter) = nrm();
	
	trialimage = trialimage * ihdiag * adscale * (T)5.0/sqrt((T)shape[0]);
	
	trialimage = image + trialimage;
	
	if(ENT==0 || ENT==2 || ENT==3)
	{
		/* Prevent the Step from going negative */
		//temp = image * (T)0.1 + (T)1e-8;
		temp = (T)1e-8;
		trialimage = max(trialimage,temp);
	}
	
	return 0;
}

/* Check for trialimage acceptance */
template<class T> Int mcmem<T>::accept_trial()
{
	T p = min(1.0,exp(logptrial - logpcurrent));
	T pa = run();
	return(pa<p);
}

/* One Step in the Markov chain */
template<class T> Int mcmem<T>::trial()
{
	propose_trial();
	
	cal_logp(image);
	logpcurrent = logp;
	
	cal_logp(trialimage); 
	logptrial = logp;
	
	return(accept_trial());
}


/* montecarloimage - Glish bound */
template<class T> Int mcmem<T>::montecarloimage(Array<T> &instartimage,Array<T> &inpriorimage, Int nrealize, Array<T> &outmeanimage,Array<T> &outvarimage, Array<T> &outskewimage, Array<T> &outkurtimage, Int &outnsamples, Array<T> &outtrack)
{

	Array<T> startimage;

	/* startimage : MCMC iterations start with this image */
	/* prior : The default image used in entropy calculation */
	
	if(dim==2)
	{
		startimage = instartimage.reform(shape);
		prior = inpriorimage.reform(shape);
	}
	else
	{
		startimage = instartimage;
		prior = inpriorimage;
	}

	/* Initialize random number generators */
	run.generator(&gen);
	run.low(0.0);run.high(1.0);
	
	std = 1.0;
	nrm.generator(&gen);
	nrm.mean(0.0);nrm.variance(std*std);
	
	Int nsamples = 0;

	Array<T> meanimage,varimage,skewimage,kurtimage;
	
	meanimage.resize(shape); meanimage = 0.0;
	varimage.resize(shape); varimage = 0.0;
	skewimage.resize(shape); skewimage = 0.0;
	kurtimage.resize(shape); kurtimage = 0.0;
	temp = 0.0;

	track.resize(IPosition(1,nrealize)); track = 0.0;
	ihdiag.resize(shape);ihdiag=0.0;

	/* timer start */
	tmr.mark();
	
	/* Compute a diagonal approximation to the sqrt(inverse hessian diagonal)
	 *  - an approximation to the diag of the Chlesky decomposition */
	
	switch(ENT)
	{
		case 0:
			ihdiag = sqrt(alpha*memimage/(alpha*memimage*wt*qpsf*qpsf + (T)1.0));
			break;
		case 1:
			ihdiag = sqrt((T)1.0/((pow(tanh((memimage-prior)*wwt),(T)2.0) + (T)1.0)*wwt*wwt + alpha*qpsf));
			break;
		case 2:
			ihdiag = sqrt((memimage*memimage)/(alpha*qpsf*memimage*memimage + (T)1.0));
			break;
		case 3:
			ihdiag = sqrt((T)1.0/((pow(tanh((memimage-prior)*wwt),(T)2.0) + (T)1.0)*wwt*wwt + alpha*qpsf + (T)1.0/((memimage+(T)1e-5)*(memimage+(T)1e-5))));
			break;
	}

	/* Scale ihdiag by the memimage : approximate the effect of the
	 * diag and first off diag of the Cholesky Decomp of the
	 * inversehessian */
	
	ihdiag = ihdiag * memimage / (T)2.0;
	
#ifdef DBG
	cout << "Max of ihdiag : " << max(ihdiag) << endl;
#endif

	
/********************************************************************
 * Code for Hessian Calculation, Hessian Inversion,
 * and Cholesky Decomposition of the Covariance Matrix
 * supplied at the end of this file. Can be included here is needed
 ********************************************************************/

	/* adaptive trial step scale initialized to 1 */
	adscale = 1.0;


	IPosition it(1),cit(2),tt1(1),tt2(1);
	
	Int tmpnsamples=0,meannsamples=0;
	T accrat=1.0,rat=1.0, prat = 0.23;

	/* burn-in is 40% of the total number of iterations */
	Int burnin = (int)((T)0.4*(T)nrealize);

#ifdef DBG
	cout << "Burn-in : " << burnin << endl;
#endif

	/* Initialize the image */
	image = startimage;
	cal_logp(image); 
	logpcurrent = logp;
#ifdef DBG
	cout << "LogP initial : " << logpcurrent << endl;
#endif

	T memp,maxp,minp;
	memp = exp(logpcurrent);
	maxp = 0; minp = 100.0;
	
	nsamples = 0;
	trialimage = 0.0;
	
	gen.reseed(getpid(),getppid());
	
	/* MCMC iterations */
	
	for(it[0]=0;it[0]<nrealize;it[0]++)
	{

		if(trial())
		{
			image = trialimage;
			cal_logp(image);
			logpcurrent = logp;

			if(maxp < exp(logp)) maxp = exp(logp);
			if(minp > exp(logp)) minp = exp(logp);

			nsamples++;
			
			if(it[0] > burnin)
			{
				meannsamples++;
				meanimage = meanimage + image;
				varimage = varimage + pow((image - memimage),(T)2.0);
				skewimage = skewimage + pow((image - memimage),(T)3.0);
				kurtimage = kurtimage + pow((image - memimage),(T)4.0);
			}
		
		}// if trial() 
		
		/* Track the centre pixel */
		track(it) = image(IPosition(1,(inpshape[0]/2 - 1)*inpshape[1]+(inpshape[1]/2)+0));

		
		if(it[0]==burnin+99) 
		{
			tmpnsamples=0;
#ifdef DBG
			cout << "Burnin done !" << endl;
#endif
		}

		/* Adaptively adjust the step scale
		 * to keep the acceptance ratio between 0.15 and 0.25 */
		
		if(it[0]>=100 && it[0]%100 == 0)
		{

			if(it[0]>=burnin+100)
			{
				accrat = (T)(meannsamples-tmpnsamples)/(T)100.0;
				tmpnsamples = meannsamples;
			}
			else
			{
				accrat = (T)(nsamples-tmpnsamples)/(T)100.0;
				tmpnsamples = nsamples;
			}
			
			rat = (T)1.0 + abs((accrat-prat)/prat);

			if(accrat > 0.25) 
			{
				adscale *= rat ;
#ifdef DBG
				cout << " rat " << nsamples << "/" << it[0];
				cout << "  : " << accrat;
				cout << "    adscale up " << adscale << endl;;
#endif
			}
			
			if(accrat < 0.15)
			{
				adscale /= rat;
#ifdef DBG
				cout << " rat " << nsamples << "/" << it[0];
				cout << "  : " << accrat;
				cout << "    adscale down " << adscale << endl;;
#endif
			}
		}//adscale
	}//for nrealize

	if(nsamples > 0)
	{
		meanimage = meanimage/(T)(meannsamples);
		varimage = varimage/(T)(meannsamples);
		skewimage = skewimage/(T)(meannsamples);
		kurtimage = kurtimage/(T)(meannsamples);

		skewimage = skewimage/pow(varimage,(T)1.5);
		kurtimage = kurtimage/(varimage*varimage) - (T)3.0;
		
	}
	else 
	{
		cout << " No samples ! " << endl;
	}

	/* timer stop */
#ifdef DBG	
	cout << " Elapsed time - montecarloimage : " << tmr.real() << endl;
	
	cout << " Number of MC samples : " << nrealize << endl;
	cout << " Number of MCMC samples accepted : " << nsamples << endl;
	cout << " nrealize - burnin : " << nrealize-burnin << endl;
	cout << " mean nsamples : " << meannsamples << endl;

	cout << "Probability of MEM image : " << memp << endl;
	cout << "Max probability from trials : " << maxp << endl;
	cout << "Min probability from trials : " << minp << endl;
#endif
	if(dim==2)
	{
		outmeanimage = meanimage.reform(inpshape);
		outvarimage = varimage.reform(inpshape);
		outskewimage = skewimage.reform(inpshape);
		outkurtimage = kurtimage.reform(inpshape);
	}
	else
	{
		outmeanimage = meanimage;
		outvarimage = varimage;
		outskewimage = skewimage;
		outkurtimage = kurtimage;
	}
		
	outtrack = track;
	outnsamples = nsamples;
#ifdef DBG
	cout << "outnsamples : " << outnsamples << endl;
#endif
	
	return 0;
}

/* montecarlodata - Glish bound */
template<class T> Int mcmem<T>::montecarlodata(Int nrealize,T insigma, Array<T> &incleandata, Array<T> &outmeanimage,Array<T> &outvarimage, Array<T> &outskewimage, Array<T> &outkurtimage)
{
	Int nsamples = 0;
	
	Array<T> cleandata; 

	/* Input cleandata to be able to generate different data realizations
	 * without having to use glish */
	
	if(dim==2)
		cleandata = incleandata.reform(shape);
	else
		cleandata = incleandata;

	nrm.generator(&gen);
	nrm.mean(0.0); nrm.variance(insigma*insigma);
	
	Array<T> andata(shape); andata = 0.0;
	Array<T> animage(shape); animage = 0.0;
	Array<T> initimage;
	initimage = image;
	
	T realsigma,fit;
	realsigma = insigma;

	Array<T> meanimage,diff;
	meanimage.resize(shape); meanimage = 0.0;
	temp = 0.0;

	Array<T> varimage,skewimage,kurtimage;
	
	varimage.resize(shape); varimage = 0.0;
	skewimage.resize(shape); skewimage = 0.0;
	kurtimage.resize(shape); kurtimage = 0.0;

	
	/* timer start */
#ifdef DBG
	tmr.mark();
#endif
	
	for(iter[0]=0;iter[0]<shape[0];iter[0]++)
		wt(iter) = (T)1.0/(insigma*insigma);
	
	
	IPosition it(1),cit(2),tt1(1),tt2(1);

	gen.reseed(2,3);
	
	nsamples = 0;
	image = memimage;
	cal_logp(image); 
	logpcurrent = logp;
#ifdef DBG	
	cout << "LogP initial : " << logpcurrent << endl;
#endif
	
	trialimage = 0.0;
	meanimage = 0.0;

	for(it[0]=0;it[0]<nrealize;it[0]++)
	{	
		/* new noise realization */
		for(iter[0]=0;iter[0]<shape[0];iter[0]++)
			andata(iter) = cleandata(iter) + nrm();
	
		/* run mem */
		mem(ENT,prior,andata,animage,fit);
		
		if( abs(fit - (T)1.0) < epsilon)
		{
			nsamples++;
			//tms.mark();
			trans.image_to_data(animage,temp);
			//ttm += (T)tms.real();
			meanimage = meanimage + animage;
			varimage = varimage + pow((animage - memimage),(T)2.0);
			skewimage = skewimage + pow((animage - memimage),(T)3.0);
			kurtimage = kurtimage + pow((animage - memimage),(T)4.0);
			
		}
	}
	
	if(nsamples > 0)
	{
		meanimage = meanimage/(T)(nsamples);
			varimage = varimage/(T)(nsamples);
			skewimage = skewimage/(T)(nsamples);
			kurtimage = kurtimage/(T)(nsamples);

			skewimage = skewimage/pow(varimage,(T)1.5);
			kurtimage = kurtimage/(varimage*varimage) - (T)3.0;
#ifdef DBG
		cout << "Number of samples : " << nsamples << endl;
#endif
	}
	else 
	{
		cout << " No samples ! " << endl;
	}
	

        /* timer end */
#ifdef DBG
	cout << "Time elapsed - montecarlodata : " << tmr.real() << endl;
	
	cout << " nrealize : " << nrealize << endl;
	cout << " nsamples : " << nsamples << endl;
#endif

	if(dim==2)
	{
		outmeanimage = meanimage.reform(inpshape);
		outvarimage = varimage.reform(inpshape);
		outskewimage = skewimage.reform(inpshape);
		outkurtimage = kurtimage.reform(inpshape);
		
	}
	else
	{
		outmeanimage = meanimage;
	}
	

	return 0;
}

/**************************************************************************/

/****************************************************************
 * Additional Code for Hessian Computation for the Entropy Prior
 * Hessian Inversion
 * Cholesky Decomposition
 * **************************************************************/

#if 0
/************** Calculate the true Hessian and Invert it !! *********/

	IPosition hshape(2),he(2),ps(1);
	hshape[0]=shape[0]; hshape[1]=shape[0];
	Matrix<T> hessian(hshape,(T)0.0);

	
if(dim==2)
{
	tms.mark();


	T p0=0.0,p1=0.0;
	
	cout << "Allocated memory for hessian" << endl;
	
	for(int i=0;i<inpshape[0];i++)
	for(int j=0;j<inpshape[1];j++)
	{
		he[0] = i*inpshape[1] + j;

		for(int x=0;x<inpshape[0];x++)
		for(int y=0;y<inpshape[1];y++)
		{
			he[1] = x*inpshape[1] + y;
		

			hessian(he) = 0.0;
			
			for(int p=0;p<inpshape[0];p++)
			for(int q=0;q<inpshape[1];q++)
			{
				p0=0.0;
				p1=0.0;
				if(i<p+inpshape[0]/2 && i>=p-inpshape[0]/2 && j<q+inpshape[1]/2 && j>=q-shape[1]/2-1)
				{
					ps[0]=(inpshape[0]/2+i-p)*inpshape[1] + inpshape[1]/2+j-q;
					p0=psf(ps);
				}
				if(x<p+inpshape[0]/2 && x>=p-inpshape[0]/2 && y<q+inpshape[1]/2 && y>=q-shape[1]/2-1)
				{
					ps[0]=(inpshape[0]/2+x-p)*inpshape[1] + inpshape[1]/2+y-q;
					p1=psf(ps);
				}
				ps[0]=inpshape[0]*p + q;
				hessian(he) += 2 * wt(ps) * p0*p1;
			}//for pq
			
		}//for xy
	
	}//for ij


	for(int i=0;i<shape[0];i++)
	{
		he[0]=i;he[1]=i;
		ps[0]=i;
		hessian(he) += (T)1.0/(alpha*image(ps));
	}

	
	cout << "AALPHA : " << alpha << endl;
	
	cout << "calculated hessian - now inverting it " << endl;
	inversehessian = invert(hessian);
	cout <<" inverted Hessian" << endl;

	//ofstream ofile("outhess.m");
	//ofile << hessian << endl;

	/* store the diagonal in ihdiag */
	for(int i=0;i<shape[0];i++)
	{
		he[0]=i;he[1]=i;
		ps[0]=i;
		ihdiag(ps) = inversehessian(he);
	}

	
/* In-place Cholesky Decomp of inversehessian (ihess) */
/* Algorithm from Numerical Recipes */
/* lower triangular part of ihess gets replaced. Diag goes into ihdiag
 * ihdiag is copied onto ihess diag and upper triangular part of
 * ihess is set to zero. ihess is then the cholesky decomp */

	Float smm=0.0;
	IPosition it1(2),it2(2),it3(2),ccit(1);
	
	for(int i=0;i<hshape[0];i++)
	for(int j=i;j<hshape[1];j++)
	{
		it1[0]=i; it1[1]=j;
		smm = inversehessian(it1);
		for(int k=i-1;k>=0;k--)
		{
			it2[0]=i ; it2[1]=k ;
			it3[0]=j ; it3[1]=k ;
			smm -= inversehessian(it2)*inversehessian(it3);
		}
		if(i==j)
		{
			if(smm <= 0.0) 
			{ 
			cout << "Ouch !  : " << i << " " << j << endl;
			return(-1);
			}
			ccit[0]=i;
			ihdiag(ccit) = sqrt(smm);
		}
		else 
		{
			it2[0]=j; it2[1]=i;
			ccit[0]=i;
			inversehessian(it2) = smm/ihdiag(ccit);
		}
	}
	
	for(int i=0;i<shape[0];i++)
	{
		he[0]=i;he[1]=i;
		ps[0]=i;
		inversehessian(he) = ihdiag(ps);
	}
	
	for(he[0]=0;he[0]<hshape[0]-1;he[0]++)
	for(he[1]=he[0]+1;he[1]<hshape[1];he[1]++)
		inversehessian(he)=0.0;


	//ofstream ofil2("ihdiag.m");
	//ofil2 << ihdiag << endl;
		
	cout << " Max of cholesky decomp matrix : " << max(inversehessian) << endl;

	

/** chol decomp done **/
	
	cout << "Time taken to invert + Cholesky: " << (T)tms.real() << endl;
//return 0;
}
#endif

template class mcmem<Float>;
#include <datatransform.cc>
template class datatransform<Float>;
