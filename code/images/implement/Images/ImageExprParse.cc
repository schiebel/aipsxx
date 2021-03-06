//# ImageExprParse.cc: Classes to hold results from image expression parser
//# Copyright (C) 1998,1999,2000,2001,2002,2003
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
//# $Id: ImageExprParse.cc,v 19.7 2005/03/16 15:02:18 gvandiep Exp $

#include <images/Images/ImageExprParse.h>
#include <images/Images/ImageExprGram.h>
#include <images/Images/PagedImage.h>
#include <images/Images/ImageOpener.h>
#include <images/Images/ImageRegion.h>
#include <images/Images/RegionHandlerTable.h>
#include <lattices/Lattices/LatticeExprNode.h>
#include <lattices/Lattices/PagedArray.h>
#include <lattices/Lattices/ArrayLattice.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/ColumnDesc.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Slice.h>
#include <casa/Arrays/ArrayUtil.h>
#include <casa/BasicSL/Constants.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>


namespace casa { //# NAMESPACE CASA - BEGIN

//# Define pointer blocks holding temporary lattices and regions.
static const Block<LatticeExprNode>* theTempLattices;
static const PtrBlock<const ImageRegion*>* theTempRegions;

//# Define a block holding allocated nodes.
//# They will be deleted when the expression is parsed.
//# In that way they are also deleted in case of exceptions.
static Block<void*> theNodes;
static Block<Bool>  theNodesType;
static uInt theNrNodes;

//# Hold the last table used to lookup unqualified region names.
static Table theLastTable;


//# Initialize static members.
LatticeExprNode ImageExprParse::theirNode;


ImageExprParse::ImageExprParse (Bool value)
: itsType (TpBool),
  itsBval (value)
{}

ImageExprParse::ImageExprParse (Int value)
: itsType (TpInt),
  itsIval (value)
{}

ImageExprParse::ImageExprParse (Float value)
: itsType (TpFloat),
  itsFval (value)
{}

ImageExprParse::ImageExprParse (Double value)
: itsType (TpDouble),
  itsDval (value)
{}

ImageExprParse::ImageExprParse (const Complex& value)
: itsType (TpComplex),
  itsCval (value)
{}

ImageExprParse::ImageExprParse (const DComplex& value)
: itsType  (TpDComplex),
  itsDCval (value)
{}

ImageExprParse::ImageExprParse (const Char* value)
: itsType (TpString),
  itsSval (String(value))
{}

ImageExprParse::ImageExprParse (const String& value)
: itsType (TpString),
  itsSval (value)
{}

Table& ImageExprParse::getRegionTable (void*, Bool)
{
  return theLastTable;
}

void ImageExprParse::addNode (LatticeExprNode* node)
{
    if (theNrNodes >= theNodes.nelements()) {
        theNodes.resize (theNrNodes + 32);
        theNodesType.resize (theNrNodes + 32);
    }
    theNodes[theNrNodes] = node;
    theNodesType[theNrNodes] = True;
    theNrNodes++;
}
void ImageExprParse::addNode (ImageExprParse* node)
{
    if (theNrNodes >= theNodes.nelements()) {
        theNodes.resize (theNrNodes + 32);
        theNodesType.resize (theNrNodes + 32);
    }
    theNodes[theNrNodes] = node;
    theNodesType[theNrNodes] = False;
    theNrNodes++;
}
void ImageExprParse::deleteNodes()
{
    for (uInt i=0; i<theNrNodes; i++) {
        if (theNodesType[i]) {
	    delete (LatticeExprNode*)(theNodes[i]);
	} else {
	    delete (ImageExprParse*)(theNodes[i]);
	}
    }
    theNrNodes = 0;
}

LatticeExprNode ImageExprParse::command (const String& str)
{
    Block<LatticeExprNode> dummyLat;
    PtrBlock<const ImageRegion*> dummyReg;
    return command (str, dummyLat, dummyReg);
}
LatticeExprNode ImageExprParse::command
                           (const String& str,
			    const Block<LatticeExprNode>& tempLattices,
			    const PtrBlock<const ImageRegion*>& tempRegions)
{
    theTempLattices = &tempLattices;
    theTempRegions  = &tempRegions;
    theNrNodes = 0;
    theLastTable = Table();
    theirNode = LatticeExprNode();
    String message;
    String command = str + '\n';
    Bool error = False;
    try {
	// Parse and execute the command.
	if (imageExprGramParseCommand(command) != 0) {
	    throw (AipsError("Parse error in image expression " + str));
	}
    } catch (AipsError x) {
	message = x.getMesg();
	error = True;
    } 
    //# Save the resulting expression and clear the common node object.
    LatticeExprNode node = theirNode;
    theirNode = LatticeExprNode();
    deleteNodes();
    theLastTable = Table();
    //# If an exception was thrown; throw it again with the message.
    //# Get rid of the constructed node.
    if (error) {
        node = LatticeExprNode();
	throw (AipsError(message + '\n' + "Scanned so far: " +
	                 command.before(imageExprGramPosition())));
    }
    return node;
}


LatticeExprNode ImageExprParse::makeFuncNode() const
{
    AlwaysAssert (itsType == TpString, AipsError);
    if (itsSval == "pi") {
	return LatticeExprNode (C::pi);
    } else if (itsSval == "e") {
	return LatticeExprNode (C::e);
    } else {
	throw (AipsError ("0-argument function " + itsSval + " is unknown"));
    }
    return LatticeExprNode();
}

LatticeExprNode ImageExprParse::makeFuncNode (const LatticeExprNode& arg1) const
{
    AlwaysAssert (itsType == TpString, AipsError);
    if (itsSval == "sin") {
	return sin(arg1);
    } else if (itsSval == "sinh") {
	return sinh(arg1);
    } else if (itsSval == "asin") {
	return asin(arg1);
    } else if (itsSval == "cos") {
	return cos(arg1);
    } else if (itsSval == "cosh") {
	return cosh(arg1);
    } else if (itsSval == "acos") {
	return acos(arg1);
    } else if (itsSval == "tan") {
	return tan(arg1);
    } else if (itsSval == "tanh") {
	return tanh(arg1);
    } else if (itsSval == "atan") {
	return atan(arg1);
    } else if (itsSval == "exp") {
	return exp(arg1);
    } else if (itsSval == "log") {
	return log(arg1);
    } else if (itsSval == "log10") {
	return log10(arg1);
    } else if (itsSval == "sqrt") {
	return sqrt(arg1);
    } else if (itsSval == "ceil") {
	return ceil(arg1);
    } else if (itsSval == "floor") {
	return floor(arg1);
    } else if (itsSval == "round") {
	return round(arg1);
    } else if (itsSval == "sign") {
	return sign(arg1);
    } else if (itsSval == "conj") {
	return conj(arg1);
    } else if (itsSval == "abs"  ||  itsSval == "amplitude") {
	return abs(arg1);
    } else if (itsSval == "arg"  ||  itsSval == "phase") {
	return arg(arg1);
    } else if (itsSval == "real") {
	return real(arg1);
    } else if (itsSval == "imag") {
	return imag(arg1);
    } else if (itsSval == "min") {
	return min(arg1);
    } else if (itsSval == "max") {
	return max(arg1);
    } else if (itsSval == "median") {
	return median(arg1);
    } else if (itsSval == "mean") {
	return mean(arg1);
    } else if (itsSval == "variance") {
	return variance(arg1);
    } else if (itsSval == "stddev") {
	return stddev(arg1);
    } else if (itsSval == "avdev") {
	return avdev(arg1);
    } else if (itsSval == "sum") {
	return sum(arg1);
    } else if (itsSval == "replace") {
	return replace(arg1, 0);
    } else if (itsSval == "ndim") {
	return ndim(arg1);
    } else if (itsSval == "nelements"  ||  itsSval == "count") {
	return nelements(arg1);
    } else if (itsSval == "any") {
	return any(arg1);
    } else if (itsSval == "all") {
	return all(arg1);
    } else if (itsSval == "ntrue") {
	return ntrue(arg1);
    } else if (itsSval == "nfalse") {
	return nfalse(arg1);
    } else if (itsSval == "isnan") {
	return isNaN(arg1);
    } else if (itsSval == "mask") {
	return mask(arg1);
    } else if (itsSval == "value") {
	return value(arg1);
    } else if (itsSval == "float") {
	return toFloat(arg1);
    } else if (itsSval == "double") {
	return toDouble(arg1);
    } else if (itsSval == "complex") {
	return toComplex(arg1);
    } else if (itsSval == "dcomplex") {
	return toDComplex(arg1);
    } else if (itsSval == "bool"  ||  itsSval == "boolean") {
	return toBool(arg1);
    } else {
	throw (AipsError ("1-argument function " + itsSval + " is unknown"));
    }
    return LatticeExprNode();
}

LatticeExprNode ImageExprParse::makeFuncNode (const LatticeExprNode& arg1,
					      const LatticeExprNode& arg2) const
{
    AlwaysAssert (itsType == TpString, AipsError);
    if (itsSval == "atan2") {
	return atan2(arg1, arg2);
    } else if (itsSval == "pow") {
	return pow(arg1, arg2);
    } else if (itsSval == "fmod") {
	return fmod(arg1, arg2);
    } else if (itsSval == "min") {
	return min(arg1, arg2);
    } else if (itsSval == "max") {
	return max(arg1, arg2);
    } else if (itsSval == "complex") {
	return formComplex(arg1, arg2);
    } else if (itsSval == "length") {
	return length(arg1, arg2);
    } else if (itsSval == "amp") {
	return amp(arg1, arg2);
    } else if (itsSval == "pa") {
	return pa(arg1, arg2);
    } else if (itsSval == "spectralindex") {
	return spectralindex(arg1, arg2);
    } else if (itsSval == "fractile") {
	return fractile(arg1, arg2);
    } else if (itsSval == "fractilerange") {
	return fractileRange(arg1, arg2);
    } else if (itsSval == "replace") {
	return replace(arg1, arg2);
    } else if (itsSval == "rebin") {
	return rebin(arg1, makeBinning(arg2));
    } else {
	throw (AipsError ("2-argument function " + itsSval + " is unknown"));
    }
    return LatticeExprNode();
}

LatticeExprNode ImageExprParse::makeFuncNode (const LatticeExprNode& arg1,
					      const LatticeExprNode& arg2,
					      const LatticeExprNode& arg3) const
{
    AlwaysAssert (itsType == TpString, AipsError);
    if (itsSval == "iif") {
	return iif(arg1, arg2, arg3);
    } else if (itsSval == "fractilerange") {
	return fractileRange(arg1, arg2, arg3);
    } else {
	throw (AipsError ("3-argument function " + itsSval + " is unknown"));
    }
    return LatticeExprNode();
}


LatticeExprNode ImageExprParse::makeLiteralNode() const
{
    switch (itsType) {
    case TpBool:
	return LatticeExprNode (itsBval);
    case TpInt:
	return LatticeExprNode (itsIval);
    case TpFloat:
	return LatticeExprNode (itsFval);
    case TpDouble:
	return LatticeExprNode (itsDval);
    case TpComplex:
	return LatticeExprNode (itsCval);
    case TpDComplex:
	return LatticeExprNode (itsDCval);
    default:
	throw (AipsError ("ImageExprParse: unknown data type for literal"));
    }
    return LatticeExprNode();
}

LatticeExprNode ImageExprParse::makeValueList
                              (const Block<LatticeExprNode>& values)
{
  // First determine the resulting data type (which is the 'highest' one).
  // It also checks if no mix of e.g. bool and numeric is used.
  DataType dtype = values[0].dataType();
  for (uInt i=0; i<values.nelements(); i++) {
    if (! values[i].isScalar()) {
      throw AipsError ("ImageExprParse: value in value list is not a scalar");
    }
    dtype = LatticeExprNode::resultDataType (dtype, values[i].dataType());
  }
  switch (dtype) {
  case TpBool:
    {
      Vector<Bool> vals(values.nelements());
      for (uInt i=0; i<vals.nelements(); i++) {
	vals[i] = values[i].getBool();
      }
      return LatticeExprNode (ArrayLattice<Bool>(vals));
    }
  case TpFloat:
    {
      Vector<Float> vals(values.nelements());
      for (uInt i=0; i<vals.nelements(); i++) {
	vals[i] = values[i].getFloat();
      }
      return LatticeExprNode (ArrayLattice<Float>(vals));
    }
  case TpDouble:
    {
      Vector<Double> vals(values.nelements());
      for (uInt i=0; i<vals.nelements(); i++) {
	vals[i] = values[i].getDouble();
      }
      return LatticeExprNode (ArrayLattice<Double>(vals));
    }
  case TpComplex:
    {
      Vector<Complex> vals(values.nelements());
      for (uInt i=0; i<vals.nelements(); i++) {
	vals[i] = values[i].getComplex();
      }
      return LatticeExprNode (ArrayLattice<Complex>(vals));
    }
  case TpDComplex:
    {
      Vector<DComplex> vals(values.nelements());
      for (uInt i=0; i<vals.nelements(); i++) {
	vals[i] = values[i].getDComplex();
      }
      return LatticeExprNode (ArrayLattice<DComplex>(vals));
    }
  default:
    throw (AipsError ("ImageExprParse: unknown data type for value list"));
  }
}

IPosition ImageExprParse::makeBinning (const LatticeExprNode& values)
{
  Vector<Double> vals;
  if (values.dataType() != TpFloat  &&  values.dataType() != TpDouble) {
    throw (AipsError ("ImageExprParse: invalid data type for rebin factors"));
  }
  if (values.isScalar()) {
    vals.resize (1);
    vals[0] = values.getDouble();
  } else {
    if (values.dataType() == TpFloat) {
      Vector<Float> val (values.getArrayFloat());
      vals.resize (val.nelements());
      for (uInt i=0; i<val.nelements(); i++) {
	vals[i] = val[i];
      }
    } else {
      vals = values.getArrayDouble();
    }
  }
  IPosition binning(vals.nelements());
  for (uInt i=0; i<binning.nelements(); i++) {
    if (vals[i] <= 0) {
      throw AipsError("ImageExprParse: "
		      "binning factor has to be a positive value");
    }
    binning[i] = Int(0.5 + vals[i]);
  }
  return binning;
}

Slice* ImageExprParse::makeSlice (const ImageExprParse& start)
{
  if (start.itsType != TpInt) {
    throw AipsError("ImageExprParse: s:e:i has to consist of integer values");
  }
  return new Slice(start.itsIval-1);
}

Slice* ImageExprParse::makeSlice (const ImageExprParse& start,
				  const ImageExprParse& end)
{
  if (start.itsType!=TpInt || end.itsType!=TpInt) {
    throw AipsError("ImageExprParse: s:e:i has to consist of integer values");
  }
  if (start.itsIval > start.itsIval) {
    throw AipsError("ImageExprParse: in s:e:i s must be <= e");
  }
  return new Slice(start.itsIval-1, end.itsIval-start.itsIval+1);
}

Slice* ImageExprParse::makeSlice (const ImageExprParse& start,
				  const ImageExprParse& end,
				  const ImageExprParse& incr)
{
  if (start.itsType!=TpInt || end.itsType!=TpInt || incr.itsType!=TpInt) {
    throw AipsError("ImageExprParse: s:e:i has to consist of integer values");
  }
  if (start.itsIval > start.itsIval) {
    throw AipsError("ImageExprParse: in s:e:i s must be <= e");
  }
  return new Slice(start.itsIval-1, end.itsIval-start.itsIval+1, incr.itsIval);
}

LatticeExprNode ImageExprParse::makeIndexinNode (const LatticeExprNode& axis,
						 const vector<Slice>& slices)
{
  // Determine maximum end value.
  Int maxEnd = 0;
  for (uInt i=0; i<slices.size(); i++) {
    if (slices[i].end() > maxEnd) {
      maxEnd = slices[i].end();
    }
  }
  // Create a vector of that length and initialize to False.
  // Set the vector to True for all ranges.
  Vector<Bool> flags(maxEnd+1, False);
  for (uInt i=0; i<slices.size(); i++) {
    const Slice& slice = slices[i];
    for (Int j=slice.start(); j<=slice.end(); j+=slice.inc()) {
      flags[j] = True;
    }
  }
  // Create the node.
  return indexin (axis, ArrayLattice<Bool>(flags));
}

LatticeExprNode ImageExprParse::makeLRNode() const
{
    // When the name is numeric, we have a temporary lattice number.
    // Find it in the block of temporary lattices.
    if (itsType == TpInt) {
        Int latnr = itsIval-1;
	if (latnr < 0  ||  latnr >= Int(theTempLattices->nelements())) {
	    throw (AipsError ("ImageExprParse: invalid temporary image "
			      "number given"));
	}
	return ((*theTempLattices)[latnr]);
    }
    // A true name has been given.
    // Split it using : as separator (:: is full separator).
    // Test if it is a region.
    Vector<String> names = stringToVector (itsSval, ':');
    if (names.nelements() != 1) {
	if ((names.nelements() == 2  &&  names(1).empty())
	||  (names.nelements() == 3  &&  !names(1).empty()
         &&  names(2).empty())
	|| names.nelements() > 3) {
	    throw (AipsError ("ImageExprParse: '" + itsSval +
			      "' is an invalid lattice, image, "
			      "or region name"));
	}
    }
    // If 1 element is given, try if it is a lattice or image.
    // If that does not succeed, it'll be tried later as a region.
    if (names.nelements() == 1) {
	LatticeExprNode node;
	if (tryLatticeNode (node, names(0))) {
	    return node;
	}
    }
    // If 2 elements given, it should be an image with a mask name.
    if (names.nelements() == 2) {
	return makeImageNode (names(0), names(1));
    }
    // One or three elements have been given.
    // If the first one is empty, a table must have been used already.
    if (names.nelements() == 1) {
	if (theLastTable.isNull()) {
	    throw (AipsError ("ImageExprParse: '" + itsSval +
			      "' is an unknown lattice or image "
			      "or it is an unqualified region"));
	}
    } else if (names(0).empty()) {
	if (theLastTable.isNull()) {
	    throw (AipsError ("ImageExprParse: unqualified region '" + itsSval +
			      "' is used before any table is used"));
	}
    } else {
	// The first name is given; see if it is a readable table.
	if (! Table::isReadable (names(0))) {
	    throw (AipsError ("ImageExprParse: the table used in region name'"
			      + itsSval + "' is unknown"));
	}
	Table table (names(0));
	theLastTable = table;
    }
    // Now try to find the region in the table.
    ImageRegion* regPtr;
    RegionHandlerTable regHand(getRegionTable, 0);
    if (names.nelements() == 1) {
	regPtr = regHand.getRegion (names(0), RegionHandler::Any, False);
	if (regPtr == 0) {
	    throw (AipsError ("ImageExprParse: '" + itsSval +
			      "' is an unknown lattice, image, or region"));
	}
    } else {
	regPtr = regHand.getRegion (names(2), RegionHandler::Any, False);
	if (regPtr == 0) {
	    throw (AipsError ("ImageExprParse: region '" + itsSval +
			      " is an unknown region"));
	}
    }
    LatticeExprNode node (*regPtr);
    delete regPtr;
    return node;
}

Bool ImageExprParse::tryLatticeNode (LatticeExprNode& node,
				     const String& name) const
{
    if (!Table::isReadable(name)) {

// If it's not an aips++ table, try other image types

	LatticeBase* lattPtr = ImageOpener::openImage (name);
	if (lattPtr == 0) {
	   return False;
	}
	ImageInterface<Float>* img = dynamic_cast<ImageInterface<Float>*>(lattPtr);
	if (img == 0) {
	   return False;
	}
	node = LatticeExprNode (*img);
	delete img;
	return True;
    }

// Continue and see if its a PagedArray (aips++ image)

    Bool isImage = True;
    Table table(name);
    String type = table.tableInfo().type();
    if (type == TableInfo::type(TableInfo::PAGEDARRAY)) {
        isImage = False;
    } else if (type != TableInfo::type(TableInfo::PAGEDIMAGE)) {
        return False;
    }
    if (table.nrow() != 1) {
	throw (AipsError ("ImageExprParse can only handle Lattices/"
			  "Images with 1 row"));
    }
    DataType dtype = TpOther;
    String colName;
    ColumnDesc cdesc = table.tableDesc()[0];
    if (cdesc.isArray()) {
	dtype = cdesc.dataType();
	colName = cdesc.name();
    }
    if (isImage) {
	switch (dtype) {
	case TpFloat:
	    node = LatticeExprNode (PagedImage<Float> (table));
	    break;
///	case TpDouble:
///	    node = LatticeExprNode (PagedImage<Double> (table));
///	    break;
	case TpComplex:
	    node = LatticeExprNode (PagedImage<Complex> (table));
	    break;
///	case TpDComplex:
///	    node = LatticeExprNode (PagedImage<DComplex> (table));
///	    break;
	default:
	    throw (AipsError ("ImageExprParse: " + name + " is a PagedImage "
			      "with an unsupported data type"));
	}
    } else {
	switch (dtype) {
	case TpBool:
	    node = LatticeExprNode (PagedArray<Bool> (table, colName, 0));
	    break;
	case TpFloat:
	    node = LatticeExprNode (PagedArray<Float> (table, colName, 0));
	    break;
	case TpDouble:
	    node = LatticeExprNode (PagedArray<Double> (table, colName, 0));
	    break;
	case TpComplex:
	    node = LatticeExprNode (PagedArray<Complex> (table, colName, 0));
	    break;
	case TpDComplex:
	    node = LatticeExprNode (PagedArray<DComplex> (table, colName, 0));
	    break;
	default:
	    throw (AipsError ("ImageExprParse: " + name + " is a PagedArray "
			      "with an unsupported data type"));
	}
    }
    // This is now the last table used (for finding unqualified regions).
    theLastTable = table;
    return True;
}

LatticeExprNode ImageExprParse::makeImageNode (const String& name,
					       const String& mask) const
{
    // Look if we need a mask for the image.
    // By default we do need one.
    MaskSpecifier spec(True);
    if (! mask.empty()) {
        String maskName = mask;
	maskName.upcase();
        if (maskName == "NOMASK") {
	    spec = MaskSpecifier(False);
	} else {
  	    spec = MaskSpecifier(mask);
	}
    }
    LatticeExprNode node;
    if (! Table::isReadable(name)) {
	LatticeBase* lattPtr = ImageOpener::openImage (name, spec);
	ImageInterface<Float>* img = 0;
	if (lattPtr != 0) {
	    img = dynamic_cast<ImageInterface<Float>*>(lattPtr);
	}
	if (img == 0) {
	    throw AipsError ("ImageExprParse: " + name +
			     " has an unknown image type");
	}
	node = LatticeExprNode (*img);
	delete img;
	return node;
    }
    Table table(name);
    String type = table.tableInfo().type();
    if (type != TableInfo::type(TableInfo::PAGEDIMAGE)) {
	throw (AipsError ("ImageExprParse: " + name + " is not a PagedImage"));
    }
    if (table.nrow() != 1) {
	throw (AipsError ("ImageExprParse can only handle Lattices/"
			  "Images with 1 row"));
    }
    DataType dtype = TpOther;
    ColumnDesc cdesc = table.tableDesc()[0];
    if (cdesc.isArray()) {
	dtype = cdesc.dataType();
    }
    // Create the node from the lattice (and optional mask).
    switch (dtype) {
    case TpFloat:
    {
	node = LatticeExprNode (PagedImage<Float> (table, spec));
	break;
    }
/// case TpDouble:
/// {
///	node = LatticeExprNode (PagedImage<Double> (table, spec));
///	break;
/// }
    case TpComplex:
    {
	node = LatticeExprNode (PagedImage<Complex> (table, spec));
	break;
    }
/// case TpDComplex:
/// {
///	node = LatticeExprNode (PagedImage<DComplex> (table, spec));
///	break;
/// }
    default:
	throw (AipsError ("ImageExprParse: " + name + " is a PagedImage "
			  "with an unsupported data type"));
    }
    // This is now the last table used (for finding unqualified regions).
    theLastTable = table;
    return node;
}

LatticeExprNode ImageExprParse::makeLitLRNode() const
{
    // The following outcommented code makes it possible to specify
    // a constant without ().
    // E.g.            image.file * pi
    // instead of      image.file * pi()
    // However, it forbids the use of pi, e, etc. as a lattice name and
    // may make things unclear. Therefore it is not supported (yet?).
///    if (itsSval == "pi") {
///	return LatticeExprNode (C::pi);
///    } else if (itsSval == "e") {
///	return LatticeExprNode (C::e);
///    }
    // It is a the name of a constant, so it must be a lattice name.
    return makeLRNode();
}

LatticeExprNode ImageExprParse::makeRegionNode() const
{
    // The name should be numeric.
    // Find it in the block of temporary lattices.
    AlwaysAssert (itsType == TpInt, AipsError);
    Int regnr = itsIval-1;
    if (regnr < 0  ||  regnr >= Int(theTempRegions->nelements())) {
	throw (AipsError ("ImageExprParse: invalid temporary region "
			  "number given"));
    }
    return *((*theTempRegions)[regnr]);
}


} //# NAMESPACE CASA - END

