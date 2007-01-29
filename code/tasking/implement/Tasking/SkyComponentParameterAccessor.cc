//# SkyComponentParameterAccessor.cc:
//# Copyright (C) 1998,2000,2003
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
//# $Id: SkyComponentParameterAccessor.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/SkyComponentParameterAccessor.h>
#include <components/ComponentModels/ComponentShape.h>
#include <components/ComponentModels/ComponentType.h>
#include <components/ComponentModels/SkyComponent.h>
#include <components/ComponentModels/SpectralModel.h>
#include <tasking/Tasking/ParameterSet.h>
#include <casa/Containers/Record.h>
#include <casa/Containers/RecordFieldId.h>
#include <casa/Exceptions/Error.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <casa/Utilities/DataType.h>
#include <casa/BasicSL/String.h>

namespace casa { //# NAMESPACE CASA - BEGIN

SkyComponentParameterAccessor::
SkyComponentParameterAccessor(const String & name, 
			      ParameterSet::Direction direction,
			      GlishRecord * values)
  :ParameterAccessor<SkyComponent>(name, direction, values, new SkyComponent)
{
    // Nothing
}

SkyComponentParameterAccessor::
~SkyComponentParameterAccessor()
{
    // Nothing
}

Bool SkyComponentParameterAccessor::
fromRecord(String & error)
{
  GlishValue val = values_p->get(name());
  if (val.type() != GlishValue::RECORD) {
    error += String("\nComponent is not a record");
    return False;
  }
  GlishRecord compRec(val);
  Record record;
  compRec.toRecord(record);
  
  ComponentType::Shape compShape = ComponentType::UNKNOWN_SHAPE;
  {
    const String shapeString("shape");
    if (!record.isDefined(shapeString)) {
      compShape = ComponentType::POINT;
    } else {
      const RecordFieldId shape(shapeString);
      if (record.dataType(shape) != TpRecord) {
	error += "The 'shape' field must be a record\n";
	return False;
      }      
      const Record & shapeRec = record.asRecord(shape);
      compShape = ComponentShape::getType(error, shapeRec);
    }
    if (compShape == ComponentType::UNKNOWN_SHAPE) {
      error += String("Component has an unknown shape\n");
      error += String("Possible shapes are:\n");
      ComponentType::Shape s;
      for (uInt i = 0; i < ComponentType::NUMBER_SHAPES - 1; i++) {
	s = (ComponentType::Shape) i;
	error += ComponentType::name(s) + String("\n");
      }
      return False;
    }
  }

  ComponentType::SpectralShape compSpectrum = 
    ComponentType::UNKNOWN_SPECTRAL_SHAPE;
  {
    const String spectrumString("spectrum");
    if (!record.isDefined(spectrumString)) {
      compSpectrum = ComponentType::CONSTANT_SPECTRUM;
    } else {
      const RecordFieldId spectrum(spectrumString);
      if (record.dataType(spectrum) != TpRecord) {
	error += "The 'spectrum' field must be a record\n";
	return False;
      }      
      const Record & spectrumRec = record.asRecord(spectrum);
      compSpectrum = SpectralModel::getType(error, spectrumRec);
    }
    if (compSpectrum == ComponentType::UNKNOWN_SPECTRAL_SHAPE) {
      error += String("Component has an unknown spectral shape.\n");
      error += String("Possible spectral shapes are:\n");
      ComponentType::SpectralShape s;
      for (uInt i = 0; i < ComponentType::NUMBER_SPECTRAL_SHAPES - 1; i++) {
	s = (ComponentType::SpectralShape) i;
	error += ComponentType::name(s) + String("\n");
      }
      return False;
    }
  }
  SkyComponent newComponent(compShape, compSpectrum);
  if (!newComponent.fromRecord(error, record)) {
    error += String("\nComponent record is bad");
    return False;
  }
  (*this)() = newComponent;
  return True;
}

Bool SkyComponentParameterAccessor::
toRecord(String & error) const {
  Record rec;
  if (!(*this)().toRecord(error, rec)) return False;
  GlishRecord record;
  record.fromRecord (rec);
  values_p -> add(name(), record);
  return True;
}

// Local Variables: 
// compile-command: "gmake OPTLIB=1 SkyComponentParameterAccessor"
// End: 

} //# NAMESPACE CASA - END

