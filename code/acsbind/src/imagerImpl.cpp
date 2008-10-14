#include <vltPort.h>
#include <maciContainerImpl.h>
#include <maciACSComponentDefines.h>
#include <imagerImpl.h>
#include <corba.h>
#include <casaacsdefs.h>
#include <casa/Containers/Record.h>
#include <synthesis/MeasurementEquations/RDOimager.h>

NAMESPACE_USE(baci);
 

acsimager::acsimager(PortableServer::POA_ptr poa, const ACE_CString &name) :
         ACSComponentImpl(poa, name)
{                           ACS_TRACE("::acsimager::acsimager");
}

acsimager::~acsimager(){
        ACS_TRACE("::acsimager::~acsimager");
        ACS_DEBUG("::acsimager::~acsimager", "dtor started");
        ACS_DEBUG("::acsimager::~acsimager", "dtor ended");
 }
 
   bool acsimager::advise()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.advise(rdoRec);
              }
  bool acsimager::approximatepsf()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.approximatepsf(rdoRec);
              }
  bool acsimager::boxmask()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.boxmask(rdoRec);
              }
  bool acsimager::clean(const char *clean, int niter, float gain, float threshold, bool displayprogress, const char *model, bool keepfixed, const char *complist, const CASA::StringVec &mask, const CASA::StringVec &image, const CASA::StringVec &residual, bool interactive, int npercycle, const char *masktemplate, bool async)
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                rdoRec.define("clean", clean);
                                rdoRec.define("niter", niter);
                                rdoRec.define("gain", gain);
                                rdoRec.define("threshold", threshold);
                                rdoRec.define("displayprogress", displayprogress);
                                rdoRec.define("model", model);
                                rdoRec.define("keepfixed", keepfixed);
                                rdoRec.define("complist", complist);
                                rdoRec.define("mask", casa_wrappers::fromCASAVec<casa::String, CASA::StringVec>(mask));
                                rdoRec.define("image", casa_wrappers::fromCASAVec<casa::String, CASA::StringVec>(image));
                                rdoRec.define("residual", casa_wrappers::fromCASAVec<casa::String, CASA::StringVec>(residual));
                                rdoRec.define("interactive", interactive);
                                rdoRec.define("npercycle", npercycle);
                                rdoRec.define("masktemplate", masktemplate);
                                rdoRec.define("async", async);
                                return myRdo.clean(rdoRec);
              }
  bool acsimager::clipimage()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.clipimage(rdoRec);
              }
  bool acsimager::clipvis()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.clipvis(rdoRec);
              }
  bool acsimager::close()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.close(rdoRec);
              }
  bool acsimager::correct()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.correct(rdoRec);
              }
  bool acsimager::done()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.done(rdoRec);
              }
  bool acsimager::exprmask()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.exprmask(rdoRec);
              }
  bool acsimager::feather()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.feather(rdoRec);
              }
  bool acsimager::filter()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.filter(rdoRec);
              }
  bool acsimager::fitpsf()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.fitpsf(rdoRec);
              }
  bool acsimager::ft()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.ft(rdoRec);
              }
  bool acsimager::linearmosaic()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.linearmosaic(rdoRec);
              }
  bool acsimager::make()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.make(rdoRec);
              }
  bool acsimager::makeimage(const char *type, const char *image, const char *complexiamge, bool async)
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                rdoRec.define("type", type);
                                rdoRec.define("image", image);
                                rdoRec.define("complexiamge", complexiamge);
                                rdoRec.define("async", async);
                                return myRdo.makeimage(rdoRec);
              }
  bool acsimager::modemodelfromsd()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.modemodelfromsd(rdoRec);
              }
  bool acsimager::mask()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.mask(rdoRec);
              }
  bool acsimager::mem(const char *algorithm, int niter, double sigma, double targetflux, bool constrainflux, bool displayprogress, const CASA::StringVec &model, const CASA::BoolVec &keepfixed, const char *complist, const CASA::StringVec &prior, const CASA::StringVec &mask, const CASA::StringVec &image, const CASA::StringVec &residual, bool async)
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                rdoRec.define("algorithm", algorithm);
                                rdoRec.define("niter", niter);
                                rdoRec.define("sigma", sigma);
                                rdoRec.define("targetflux", targetflux);
                                rdoRec.define("constrainflux", constrainflux);
                                rdoRec.define("displayprogress", displayprogress);
                                rdoRec.define("model", casa_wrappers::fromCASAVec<casa::String, CASA::StringVec>(model));
                                rdoRec.define("keepfixed",casa_wrappers::fromCASAVec<casa::Bool, CASA::BoolVec>(keepfixed));
                                rdoRec.define("complist", complist);
                                rdoRec.define("prior", casa_wrappers::fromCASAVec<casa::String, CASA::StringVec>(prior));
                                rdoRec.define("mask", casa_wrappers::fromCASAVec<casa::String, CASA::StringVec>(mask));
                                rdoRec.define("image", casa_wrappers::fromCASAVec<casa::String, CASA::StringVec>(image));
                                rdoRec.define("residual", casa_wrappers::fromCASAVec<casa::String, CASA::StringVec>(residual));
                                rdoRec.define("async", async);
                                return myRdo.mem(rdoRec);
              }
  bool acsimager::nnls()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.nnls(rdoRec);
              }
  bool acsimager::open(const char *thems, bool compress)
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                rdoRec.define("thems", thems);
                                rdoRec.define("compress", compress);
                                return myRdo.open(rdoRec);
              }
  bool acsimager::pixon()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.pixon(rdoRec);
              }
  bool acsimager::plotsummary()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.plotsummary(rdoRec);
              }
  bool acsimager::plotuv()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.plotuv(rdoRec);
              }
  bool acsimager::plotvis()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.plotvis(rdoRec);
              }
  bool acsimager::plotweights()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.plotweights(rdoRec);
              }
  bool acsimager::regionmask()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.regionmask(rdoRec);
              }
  bool acsimager::residual()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.residual(rdoRec);
              }
  bool acsimager::restore()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.restore(rdoRec);
              }
  bool acsimager::selfcal()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.selfcal(rdoRec);
              }
  bool acsimager::sensitivity()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.sensitivity(rdoRec);
              }
  bool acsimager::setbeam()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.setbeam(rdoRec);
              }
  bool acsimager::setjy()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.setjy(rdoRec);
              }
  bool acsimager::setmfcontrol()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.setmfcontrol(rdoRec);
              }
  bool acsimager::setdata(const char *mode, const CASA::IntVec &nchan, const CASA::IntVec &start, const CASA::IntVec &step, double mstart, double mstep, const CASA::IntVec &spwid, const CASA::IntVec &fieldid, const char *msslect, bool async)
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                rdoRec.define("mode", mode);
                                rdoRec.define("nchan", casa_wrappers::fromCASAVec<casa::Int, CASA::IntVec>(nchan));
                                rdoRec.define("start", casa_wrappers::fromCASAVec<casa::Int, CASA::IntVec>(start));
                                rdoRec.define("step", casa_wrappers::fromCASAVec<casa::Int, CASA::IntVec>(step));
                                rdoRec.define("mstart", mstart);
                                rdoRec.define("mstep", mstep);
                                rdoRec.define("spwid", casa_wrappers::fromCASAVec<casa::Int, CASA::IntVec>(spwid));
                                rdoRec.define("fieldid", casa_wrappers::fromCASAVec<casa::Int, CASA::IntVec>(fieldid));
                                rdoRec.define("msslect", msslect);
                                rdoRec.define("async", async);
                                return myRdo.setdata(rdoRec);
              }
  bool acsimager::setimage(int nx, int ny, double cellx, double celly, const char *stokes, bool doshift, const char *phasecenter, double shiftx, double shifty, const char *mode, int nchan, int start, int step, const char *mstart, const char *mstep, const CASA::IntVec &spwid, int fieldid, int facets, double distance)
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                rdoRec.define("nx", nx);
                                rdoRec.define("ny", ny);
                                rdoRec.define("cellx", cellx);
                                rdoRec.define("celly", celly);
                                rdoRec.define("stokes", stokes);
                                rdoRec.define("doshift", doshift);
                                rdoRec.define("phasecenter", phasecenter);
                                rdoRec.define("shiftx", shiftx);
                                rdoRec.define("shifty", shifty);
                                rdoRec.define("mode", mode);
                                rdoRec.define("nchan", nchan);
                                rdoRec.define("start", start);
                                rdoRec.define("step", step);
                                rdoRec.define("mstart", mstart);
                                rdoRec.define("mstep", mstep);
                                rdoRec.define("spwid", casa_wrappers::fromCASAVec<casa::Int, CASA::IntVec>(spwid));
                                rdoRec.define("fieldid", fieldid);
                                rdoRec.define("facets", facets);
                                rdoRec.define("distance", distance);
                                return myRdo.setimage(rdoRec);
              }
  bool acsimager::setoptions(const char *ftmachine, int cache, int tile, const char *gridfunction, const char *location, double padding, bool usemodelcol)
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                rdoRec.define("ftmachine", ftmachine);
                                rdoRec.define("cache", cache);
                                rdoRec.define("tile", tile);
                                rdoRec.define("gridfunction", gridfunction);
                                rdoRec.define("location", location);
                                rdoRec.define("padding", padding);
                                rdoRec.define("usemodelcol", usemodelcol);
                                return myRdo.setoptions(rdoRec);
              }
  bool acsimager::setscales()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.setscales(rdoRec);
              }
  bool acsimager::setsdoptions()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.setsdoptions(rdoRec);
              }
  bool acsimager::setvp()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.setvp(rdoRec);
              }
  bool acsimager::smooth(CASA::StringVec_out image, const CASA::StringVec &Model, bool usefit, double bmaj, double mmin, double bpa, bool normalize, bool async)
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                // rdoRec.define("image", casa_wrappers::fromCASAVec<casa::String, CASA::StringVec>(image));
                                rdoRec.define("Model", casa_wrappers::fromCASAVec<casa::String, CASA::StringVec>(Model));
                                rdoRec.define("usefit", usefit);
                                rdoRec.define("bmaj", bmaj);
                                rdoRec.define("mmin", mmin);
                                rdoRec.define("bpa", bpa);
                                rdoRec.define("normalize", normalize);
                                rdoRec.define("async", async);
                                return myRdo.smooth(rdoRec);
              }
  bool acsimager::stop()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.stop(rdoRec);
              }
  bool acsimager::summary()
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                return myRdo.summary(rdoRec);
              }
  bool acsimager::uvrange(double uvmin, double uvmax)
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                rdoRec.define("uvmin", uvmin);
                                rdoRec.define("uvmax", uvmax);
                                return myRdo.uvrange(rdoRec);
              }
  bool acsimager::weight(const char *type, const char *rmode, double noise, double robust, double fieldofview, int npixels, bool mosaic, bool async)
                             throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
                                rdoRec.define("type", type);
                                rdoRec.define("rmode", rmode);
                                rdoRec.define("noise", noise);
                                rdoRec.define("robust", robust);
                                rdoRec.define("fieldofview", fieldofview);
                                rdoRec.define("npixels", npixels);
                                rdoRec.define("mosaic", mosaic);
                                rdoRec.define("async", async);
                                return myRdo.weight(rdoRec);
              }

  
  MACI_DLL_SUPPORT_FUNCTIONS(acsimager)
  
