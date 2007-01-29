from _pyimager import Imager
from pyquanta import quanta
from pymeasures import measures, is_measure

class imager(Imager):
    def __init__(self, msname=None, compress=False):
	self.dq = quanta()
	self.dm = measures()
	Imager.__init__(self, msname, compress)
    
    def weight(self, type="uniform", rmode="none", noise='0.0Jy',
	       robust=0.0, fieldofview="0rad", npixels=0):

	return Imager.weight(self, type, rmode, self.dq.quantity(noise), robust,
			     self.dq.quantity(fieldofview), npixels)

    def makeimage(self, type="observed", image=""):
	return Imager.makeimage(self, type, image)

    def setimage(self, nx=128, ny=128,
		 cellx='1arcsec', celly='1arcsec',
		 stokes='I',
		 doshift=False, 
		 phasecenter=None,
		 shiftx='0arcsec', shifty='0arcsec',
		 mode='mfs', nchan=1,
		 start=0, step=1,
		 mstart='0km/s',
		 mstep='0km/s',
		 spwid=0, fieldid=0,
		 facets=1, distance='0m',
		 pastep=5.0, pblimit=5e-2):
	if phasecenter is None:
	    phasecenter = self.dm.direction('b1950', '0deg', '90deg')	  
	if not is_measure(mstart):
	    mstart = self.dm.radialvelocity("LSRK", mstart)
	if not is_measure(mstep):
	    mstep = self.dm.radialvelocity("LSRK", mstep)
	return Imager.setimage(self, nx, ny, 
			       self.dq.quantity(cellx),
			       self.dq.quantity(celly),
			       stokes, doshift,
			       phasecenter,
			       self.dq.quantity(shiftx),
			       self.dq.quantity(shifty),
			       mode, nchan, start, step,
			       mstart,
			       mstep,
			       spwid, fieldid, facets, 
			       self.dq.quantity(distance),
			       pastep, pblimit)
    def setdata(self, msname='', mode='none',
		nchan=1, start=0, step=1,
		spwid=0, fieldid=0, 
		msselect = ' '):
	return Imager.setdata(self, mode, nchan, start, step,
			      spwid, fieldid, msselect, msname)

    def setoptions(self, ftmachine='ft',
		   cache=0, tile=16,
		   gridfunction='SF',
		   location=None,
		   padding=1.0,
		   usemodelcol=True,
		   wprojplanes=1,
		   pointingtable='',dopointing=True,dopbcorr=True,
		   cfcache=''):
	if location is None:
	    location = self.dm.position('wgs84', '0m', '0m', '0m')	    
	return Imager.setoptions(self, ftmachine, cache, tile, gridfunction,
				 location, padding, usemodelcol,
				 wprojplanes, pointingtable,
				 dopointing, dopbcorr, cfcache)

    def filter(self, type="gaussian", bmaj='0rad', bmin='0rad',
	       bpa='0deg'):
	return Imager.filter(self, type, self.dq.quantity(bmaj),
			     self.dq.quantity(bmin), self.dq.quantity(bpa))
    def setmfcontrol(self, cyclefactor=1.5, cyclespeedup=-1.0,
		     stoplargenegatives=2, stoppointmode=-1, minpb=0.1,
		     scaletype='NONE', constpb=0.3, fluxscale=''):
#	if isinstance(fluxscale, str):
#	    fluxscale = (fluxscale,)
	return Imager.setmfcontrol(self, cyclefactor, cyclespeedup, 
				   stoplargenegatives, stoppointmode,
				   scaletype, minpb, constpb, fluxscale)

    def setscales(self, scalemethod='nscales', nscales=5, 
		  uservector=[0.0,3.0,10.0]):
	Imager.setscales(self,scalemethod, nscales, uservector)
    
    def clean(self, algorithm='clark', niter=1000, gain=0.1,
	      threshold='0Jy',
	      displayprogress=True, 
	      model='', fixed=False, complist='',
	      mask='', image='', residual=''):

	if model != '' and  image == '':
            for k in range(len(model)):
		image[k] = '%s.restored' % model[k]            
	if image is None: image = ''
	if model != '' and residual=='':
	     for k in range(len(model)):
		 image[k] = '%s.residual' % model[k]
	return Imager.clean(self, algorithm, niter, gain,
			    self.dq.quantity(threshold), displayprogress,
			    model, fixed, complist, mask, image, residual)
