//# ImageInterface.cc: defines the Image base class non pure virtual stuff
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2003
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
//# $Id: ImageInterface.cc,v 19.3 2004/11/30 17:50:26 ddebonis Exp $


#include <casa/aips.h>
#include <casa/Arrays/Vector.h> // Put these early to work around g++ bug
#include <casa/Arrays/Matrix.h>

#include <coordinates/Coordinates/StokesCoordinate.h>

#include <images/Images/ImageInterface.h>
#include <images/Images/LELImageCoord.h>
#include <images/Images/ImageRegion.h>
#include <lattices/Lattices/LCRegion.h>
#include <lattices/Lattices/LCBox.h>
#include <lattices/Lattices/SubLattice.h>
#include <lattices/Lattices/LatticeIterator.h>

#include <casa/Arrays/ArrayMath.h>
#include <casa/Containers/RecordInterface.h>
#include <casa/Utilities/Assert.h>
#include <casa/sstream.h>
#include <casa/Containers/Record.h>
#include <lattices/Lattices/LCBox.h>
#include <lattices/Lattices/SubLattice.h>
#include <lattices/Lattices/TiledShape.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template <class T> 
ImageInterface<T>::ImageInterface()
: regHandPtr_p (0)
{
  logSink() << LogOrigin("ImageInterface<T>",
	    "ImageInterface()",
			 WHERE) << LogIO::DEBUGGING <<
    "Creating ImageInterface" << LogIO::POST;
  regHandPtr_p = new RegionHandler();
}

template <class T> 
ImageInterface<T>::ImageInterface (const RegionHandler& regHand)
: regHandPtr_p (0)
{
  logSink() << LogOrigin("ImageInterface<T>",
	    "ImageInterface()",
			 WHERE) << LogIO::DEBUGGING <<
    "Creating ImageInterface" << LogIO::POST;
  regHandPtr_p = regHand.clone();
  regHandPtr_p->setObjectPtr (this);
}

template <class T> 
ImageInterface<T>::ImageInterface (const ImageInterface& other)
: MaskedLattice<T> (other),
  coords_p     (other.coords_p),
  log_p        (other.log_p),
  imageInfo_p  (other.imageInfo_p),
  unit_p       (other.unit_p),
  miscInfo_p   (other.miscInfo_p),
  regHandPtr_p (0)
{
  logSink() << LogOrigin("ImageInterface<T>",
	    "ImageInterface(const ImageInterface&)",
			 WHERE) << LogIO::DEBUGGING << LogIO::POST;
  regHandPtr_p = other.regHandPtr_p->clone();
  regHandPtr_p->setObjectPtr (this);
}

template <class T> 
ImageInterface<T>& ImageInterface<T>::operator= (const ImageInterface& other)
{
  if (this != &other) {
    MaskedLattice<T>::operator= (other);
    coords_p    = other.coords_p;
    log_p       = other.log_p;
    imageInfo_p = other.imageInfo_p;
    unit_p      = other.unit_p;
    miscInfo_p  = other.miscInfo_p;
    delete regHandPtr_p;
    regHandPtr_p = 0;
    regHandPtr_p = other.regHandPtr_p->clone();
    regHandPtr_p->setObjectPtr (this);
  }
  return *this;
}

template <class T> 
ImageInterface<T>::~ImageInterface()
{
  delete regHandPtr_p;
}

template<class T>
MaskedLattice<T>* ImageInterface<T>::cloneML() const
{
    return cloneII();
}


// reset coords
template <class T> 
Bool ImageInterface<T>::setCoordinateInfo(const CoordinateSystem &coords)
{
    ostringstream errmsg;
    errmsg << "Cannot set coordinate system: ";

    Bool ok = (coords.nPixelAxes() == shape().nelements());
    if (!ok) {
	errmsg << "coords.nPixelAxes() == " << coords.nPixelAxes() << 
	    ", image.ndim() == " << shape().nelements();
    } else {
	// Check that the shape is compatible with the stokes coordinates
	Int stkcrd = -1;
	while (ok && (stkcrd = coords.findCoordinate(Coordinate::STOKES, 
							  stkcrd)) >= 0) {
	    ok = True;
	    Int axis = coords.pixelAxes(stkcrd)(0);
	    const StokesCoordinate &stokes = coords.stokesCoordinate(stkcrd);
	    if (axis >= 0) {
		Int nstokes = stokes.stokes().nelements();
		Int axislength = shape()(axis);
		if (axislength > nstokes) {
		    ok = False;
		    errmsg << "Stokes axis is length " << axislength <<
			" but we only have " << nstokes << " stokes values"
			   << endl;
		}
	    }
	}
    }

    if (ok) {
	coords_p = coords;
	logSink() << LogIO::DEBUGGING << 
	    "Changing coordinate system:\n" <<
	    "        ndim = " << shape().nelements() << endl <<
	    "        axes = " << coords_p.worldAxisNames() << endl <<
	    "     ref val = " << coords_p.referenceValue() << endl <<
	    "     ref pix = " << coords_p.referencePixel() << endl <<
	    "       delta = " << coords_p.increment() << " units = " <<
	    coords_p.worldAxisUnits() << endl <<
	    "linear xfrom = " << coords_p.linearTransform() << 
	    LogIO::POST;
    } else {
	// !ok
	logSink() << LogIO::SEVERE << String(errmsg) << LogIO::POST;
    }
    return ok;
}


template <class T> 
LELCoordinates ImageInterface<T>::lelCoordinates() const
{
    return LELCoordinates (new LELImageCoord (coords_p, imageInfo_p,
					      units(), miscInfo_p));
}


template <class T>
ImageRegion ImageInterface<T>::makeMask (const String& name,
					 Bool defineAsRegion,
					 Bool setAsDefaultMask,
					 Bool initialize,
					 Bool value)
{
  ImageRegion region = regHandPtr_p->makeMask (*this, name);
  if (initialize) {
    region.asMask().set (value);
  }
  if (defineAsRegion) {
    defineRegion (name, region, RegionHandler::Masks);
    if (setAsDefaultMask) {
      setDefaultMask (name);
    }
  }
  return region;
}

template <class T>
void ImageInterface<T>::defineRegion (const String& name,
				      const ImageRegion& region,
				      RegionHandler::GroupType type,
				      Bool overwrite)
{
  regHandPtr_p->defineRegion (name, region, type, overwrite);
}
template <class T>
Bool ImageInterface<T>::hasRegion (const String& name,
				   RegionHandler::GroupType type) const
{
  return regHandPtr_p->hasRegion (name, type);
}
template <class T>
ImageRegion* ImageInterface<T>::getImageRegionPtr
                                     (const String& name,
				      RegionHandler::GroupType type,
				      Bool throwIfUnknown) const
{
  return regHandPtr_p->getRegion (name, type, throwIfUnknown);
}
template <class T>
void ImageInterface<T>::renameRegion (const String& newName,
				      const String& oldName,
				      RegionHandler::GroupType type,
				      Bool throwIfUnknown)
{
  regHandPtr_p->renameRegion (newName, oldName, type, throwIfUnknown);
}
template <class T>
void ImageInterface<T>::removeRegion (const String& name,
				      RegionHandler::GroupType type,
				      Bool throwIfUnknown)
{
  regHandPtr_p->removeRegion (name, type, throwIfUnknown);
}
template<class T> 
Vector<String> ImageInterface<T>::regionNames
                                     (RegionHandler::GroupType type) const
{
  return regHandPtr_p->regionNames (type);
}

template <class T>
void ImageInterface<T>::setDefaultMask (const String& name)
{
  regHandPtr_p->setDefaultMask (name);
}
template <class T>
String ImageInterface<T>::getDefaultMask() const
{
  return regHandPtr_p->getDefaultMask();
}

template <class T>
void ImageInterface<T>::useMask (MaskSpecifier)
{
  throw AipsError ("ImageInterface::useMask - not implemented");
}

template <class T>
ImageRegion ImageInterface<T>::getRegion (const String& regionName,
					  RegionHandler::GroupType type) const
{
  ImageRegion* regptr = getImageRegionPtr (regionName, type, True);
  ImageRegion reg(*regptr);
  delete regptr;
  return reg;
}

template<class T>
String ImageInterface<T>::makeUniqueRegionName (const String& rootName,
						uInt startNumber) const
{
  return regHandPtr_p->makeUniqueRegionName (rootName, startNumber);
}



template<class T>
Bool ImageInterface<T>::setImageInfo(const ImageInfo& info)
//
// Derived classes like PagedImage have to put this in the
// permanent table keywordSet
// 
{ 
   imageInfo_p = info;
   return True;
}    
   
template<class T>
Bool ImageInterface<T>::setMiscInfo(const RecordInterface& miscInfo)
//
// Derived classes like PagedImage have to put this in the
// permanent table keywordSet
// 
{ 
   miscInfo_p = miscInfo;
   return True;
}    
   
template<class T>
Bool ImageInterface<T>::setUnits(const Unit& unit)
//
// Derived classes like PagedImage have to put this in the
// permanent table keywordSet
// 
{ 
   unit_p = unit;
   return True;
}    

template<class T>
Bool ImageInterface<T>::toRecord(String& error, RecordInterface& outRec)
{
//
// Save the current ImageInterface object to an output state record
// 
   Vector<Int> shape=this->shape().asVector();
   outRec.define("shape", shape);
//
   CoordinateSystem coordsys = coordinates();
   Record coordinateRecord;
   coordsys.save(coordinateRecord, "coordsys");
   outRec.defineRecord("coordsys", coordinateRecord, Record::Variable);
//
   outRec.define("imagearray", this->get(), False);
//
   Record imageInfoRecord;
   String errorString;             
   imageInfo_p.toRecord(errorString, imageInfoRecord);
   outRec.defineRecord("imageinfo", imageInfoRecord, 
		       RecordInterface::Variable);
   error = "";
   return True;
}                        

template<class T>
Bool ImageInterface<T>::fromRecord(String& error, const RecordInterface& inRec)
{
//
// Restore the current ImageInterface object from an input state record
// 
//
   Vector<Int> shape;
   inRec.get("shape", shape);
   IPosition shape2(shape);
   TiledShape newShape(shape2);  
   resize(newShape);
//
   const Record& coordinateRecord(inRec.asRecord("coordsys"));
   CoordinateSystem* pCSys = CoordinateSystem::restore(coordinateRecord, "coordsys");
   setCoordinateInfo(*pCSys);
   delete pCSys;
//
   Array<T> imageArray;
   inRec.get("imagearray",imageArray);
   this->put(imageArray);
//
   Record imageInfoRecord(inRec.asRecord("imageinfo"));
   String errorString; 
   imageInfo_p.fromRecord(errorString, imageInfoRecord); 

   error = "";
   return True;
}

} //# NAMESPACE CASA - END

