//# TblAsXYDD.cc:  Display Data for xy displays of data from a table
//# Copyright (C) 2000,2001
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
//# $Id: TblAsXYDD.cc,v 19.4 2005/06/15 18:00:46 cvsmgr Exp $

#include <casa/aips.h>
#include <casa/Utilities/Regex.h> 
#include <casa/Exceptions/Error.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/ColumnDesc.h>
#include <tables/Tables/TableParse.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Containers/Record.h>
#include <display/Display/Attribute.h>
#include <casa/Utilities/DataType.h>
#include <tables/Tables/ScalarColumn.h>
#include <tables/Tables/ArrayColumn.h>
#include <coordinates/Coordinates/LinearCoordinate.h>
#include <display/DisplayDatas/TblAsXYDD.h>
#include <display/DisplayDatas/TblAsXYDM.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// constructors
// given an already constructed table
TblAsXYDD::TblAsXYDD(Table *table):
  // NEED TO CLONE/COPY THE TABLE AND PUT THE CLONE IN ITSTABLE 
  // SO THAT NO ONE ELSE CAN REMOVE THE TABLE ON US
  itsTable(table),
  itsQueryTable(0),
  itsXColumnName(0),
  itsYColumnName(0),
  itsMColumnName(0),
  itsMColumnSet(0)
{
  // get the names of the columns from the table
  getTableColumnNames();
  // construct the parameter set for axis (column) selection
  constructParameters();
  // install the default option values
  installDefaultOptions();
  // setup the coordinate system
  getCoordinateSystem();
  ActiveCaching2dDD::setCoordinateSystem( itsCoord, itsLinblc, itsLintrc);
}

// given a string which gives the full pathname and filename of a table 
// on disk
TblAsXYDD::TblAsXYDD(const String tablename):
  itsTable(0),
  itsQueryTable(0),
  itsXColumnName(0),
  itsYColumnName(0),
  itsMColumnName(0),
  itsMColumnSet(0)
{
  // open the table file - throw and error if there is a problem
  itsTable = new Table(tablename);
  if (!itsTable) {
    throw(AipsError("Cannot open named table"));
  }
  // get the names of the columns from the table
  getTableColumnNames();
  // construct the parameter set for axis (column) selection
  constructParameters();
  // install the default option values
  installDefaultOptions();
  // setup the coordinate system
  getCoordinateSystem();
  ActiveCaching2dDD::setCoordinateSystem( itsCoord, itsLinblc, itsLintrc);
}

//destuctor
TblAsXYDD::~TblAsXYDD() {
  destructParameters();
  if (itsQueryTable) {
    itsQueryTable->markForDelete();
    delete itsQueryTable;
  }
  if (itsTable) {
    delete itsTable;
  }
} 

const Unit TblAsXYDD::dataUnit() {
  String value = "_";
  return value;
}

// get the units of the columns being displayed
const Unit TblAsXYDD::dataUnit(const String column) {
  static Regex rxUnit("^[uU][nN][iI][tT]$");
  String value;
  if (getColumnKeyword(value, column, rxUnit)) {
  } else {
    value = "_";
  }
  return value;
}                                  

// set the default options for the display data
void TblAsXYDD::setDefaultOptions() {
  ActiveCaching2dDD::setDefaultOptions();
  installDefaultOptions();
  getCoordinateSystem();
  setCoordinateSystem();
}

// set a record                                           
Bool TblAsXYDD::setOptions(Record &rec, Record &recOut) {
  Bool ret = ActiveCaching2dDD::setOptions(rec,recOut);
  Bool localchange = False, coordchange = False, error;

  if (readOptionRecord(itsOptQueryString, itsOptQueryStringUnset,
                       error, rec, "querystring")) {

    arrangeQueryTable();
    localchange = True;
  }
 
  // set the DParmeter values which have information on 
  // the axis (columns) used
  coordchange = (itsXColumnName->fromRecord(rec) || coordchange);
  coordchange = (itsYColumnName->fromRecord(rec) || coordchange);
  coordchange = (itsMColumnName->fromRecord(rec) || coordchange);
  coordchange = (itsMColumnSet->fromRecord(rec)  || coordchange);
  
  // if the axis (columns of table) are changed then we need to
  // update the coordinate system
  if (coordchange) {
    getCoordinateSystem();
    setCoordinateSystem();
  }
  
  return (ret || localchange || coordchange);                      
}

Record TblAsXYDD::getOptions() {
  Record rec = ActiveCaching2dDD::getOptions();
 
  Record querystring;
  querystring.define("dlformat", "querystring");
  querystring.define("listname", "\"WHERE\" query");
  querystring.define("ptype", "string");
  querystring.defineRecord("default", unset());
  if (itsOptQueryStringUnset) {
    querystring.defineRecord("value", unset());
  } else {
    querystring.define("value", itsOptQueryString);
  }
  querystring.define("allowunset", True);
  rec.defineRecord("querystring", querystring);
 
  // get DParameter values which have information on the axis (columns) used
  itsXColumnName->toRecord(rec);
  itsYColumnName->toRecord(rec);
  itsMColumnName->toRecord(rec);
  itsMColumnSet->toRecord(rec);

  return rec;
}
  

              
CachingDisplayMethod *TblAsXYDD::newDisplayMethod(
           WorldCanvas *worldCanvas,
	   AttributeBuffer *wchAttributes,
	   AttributeBuffer *ddAttributes,
	   CachingDisplayData *dd){
    return new TblAsXYDM(worldCanvas,wchAttributes,ddAttributes,dd);
}
                   
//get the current options of the DD in a Attribute Buffer
AttributeBuffer TblAsXYDD::optionsAsAttributes() {
  AttributeBuffer buffer = ActiveCaching2dDD::optionsAsAttributes();
 
  buffer.set("querystringunset", itsOptQueryStringUnset);
  buffer.set("querystring", itsOptQueryString);
  
  //now add DParmeter values
  buffer.set(itsXColumnName->name(), itsXColumnName->value());
  buffer.set(itsYColumnName->name(), itsYColumnName->value());
  buffer.set(itsMColumnName->name(), itsMColumnName->value());
  buffer.set(itsMColumnSet->name(),  itsMColumnSet->value() );
  
  return buffer;
}

// obtain a pointer to the table to be displayed
Table *TblAsXYDD::table() {
  if (itsQueryTable) {
    return itsQueryTable;
  } else {
    return itsTable;
  }
}

void TblAsXYDD::cleanup() {
}

// (Required) default constructor
TblAsXYDD::TblAsXYDD() :
  ActiveCaching2dDD() {
}

// (Required) copy constructor
TblAsXYDD::TblAsXYDD(const TblAsXYDD &) {
}

// (Required) copy assignment
void TblAsXYDD::operator=(const TblAsXYDD &) {
}

void TblAsXYDD::installDefaultOptions() {

  // setup values for query options
  itsOptQueryString = "";
  itsOptQueryStringUnset = True;
  arrangeQueryTable();

}

Bool TblAsXYDD::arrangeQueryTable() {
  // remove old version of query table and make ready for new entries
  if (itsQueryTable) {
    itsQueryTable->markForDelete();
    delete itsQueryTable;
  }
  itsQueryTable = 0;

  // now add to new query table if requested
  if (!itsOptQueryStringUnset) {
    String selectStr = "SELECT ";
    String fromStr = "FROM " + String(itsTable->tableName()) + String(" ");
    String whereStr = "WHERE " + itsOptQueryString;
    itsQueryTable = new Table(tableCommand(selectStr + fromStr + whereStr));
    if (itsQueryTable) {
      return True;
    }
  }
  // query table was not set
  return False;
}                           

void TblAsXYDD::getCoordinateSystem(){
  // NEED TO IMPELMENT Movie axis once changed from ActiveCaching2dDD to
  // ActiveCachingDD for n-dimensions


  // linear extent of coordinates 
  Vector<Double> linblc(2), lintrc(2), extrema;
  extrema = columnStatistics(itsXColumnName->value());
  linblc(0)=extrema(0);
  lintrc(0)=extrema(1)-1.0;
  extrema = columnStatistics(itsYColumnName->value());
  linblc(1)=extrema(0);
  lintrc(1)=extrema(1)-1.0;
  
  // coordinate axis names
  Vector<String> names(2);
  names(0) = itsXColumnName->value();
  names(1) = itsYColumnName->value();

  // coordinate axis units
  Vector<String> units(2);
  Unit temp = dataUnit(itsXColumnName->value());
  units(0) = temp.getName();
  if (itsYColumnName->value() == "<row>") {  // row is not a table column
    units(1) = "_";
  } else {
    Unit temp2 = dataUnit(itsYColumnName->value());
    units(1)= temp2.getName();
  }

  Matrix<Double> pc(2,2);
  pc = 0.0;
  pc(0, 0) = pc(1, 1) = 1.0;

  // reference values for mapping for mapping coordinates
  Vector<double> refVal = linblc;

  // coordinate increments
  Vector<double> inc(2);
  inc = 1.0;

  // reference pixel for mapping coordinates
  Vector<double> refPix = linblc;

  LinearCoordinate lc(names, units, refVal, inc, pc, refPix);
  itsCoord.addCoordinate(lc);
  itsLinblc = linblc;
  itsLintrc = lintrc;

}

void TblAsXYDD::setCoordinateSystem(){
 ActiveCaching2dDD::setCoordinateSystem( itsCoord, itsLinblc, itsLintrc);
}

String TblAsXYDD::showValue(const Vector<Double> &world) {

  // NEED TO IMPLEMENT
  // no examples of this function exist in any other DD but it should be
  // easy to implement?
  String temp="";
  return temp;
}

// get all of the table column names
void TblAsXYDD::getTableColumnNames() {

  // make sure there is a table to be read
  if (!table()) {
    throw(AipsError("could not obtain table in TblAsXYDD"));
  }

  // determine the column names
  itsColumnNames = table()->tableDesc().columnNames();

  // check to make sure there are at least two column names
  if (itsColumnNames.nelements() < 2) {
    throw(AipsError("too few columns for TblAsXYDD to plot table"));
  }

}

// get all of the table columnNames with a certain data type 
Vector<String> TblAsXYDD::getColumnNamesOfType() {

  uInt n = 0;

  // get all the table column names available
  // we must do this since a table query may be active
  getTableColumnNames();
  Vector<String> cnames = itsColumnNames;

  // get a description of the columns
  TableDesc tdesc(table()->tableDesc());

  // now keep only columns of specified data types
  Vector<String> retval (cnames.shape());
  for (uInt i = 0; i < cnames.nelements(); i++ ) {
    // columns with scalars suitable for y axis - scalar columns
    if (tdesc.columnDesc(cnames(i)).trueDataType() == TpShort ||
	tdesc.columnDesc(cnames(i)).trueDataType() == TpShort ||
	tdesc.columnDesc(cnames(i)).trueDataType() == TpUShort ||
	tdesc.columnDesc(cnames(i)).trueDataType() == TpInt ||
	tdesc.columnDesc(cnames(i)).trueDataType() == TpUInt ||
	tdesc.columnDesc(cnames(i)).trueDataType() == TpFloat ||
	tdesc.columnDesc(cnames(i)).trueDataType() == TpDouble ||
	tdesc.columnDesc(cnames(i)).trueDataType() == TpComplex ||
	tdesc.columnDesc(cnames(i)).trueDataType() == TpDComplex ) {
      retval(n++) = cnames(i);
    }
  }

  // now resize the selected column names vector
  retval.resize(n, True);

  return retval;
}


// construct the parameters list
void TblAsXYDD::constructParameters() {


  // get a list of column names with numerical data in non-arrays
  Vector<String> xstring = getColumnNamesOfType();

  // if no columns are returned then throw exception
  if (xstring.nelements() < 1) {
    throw(AipsError("no valid columns found in table for a xy plot"));
  }

  // get a list of column names with numerical data in non-arrays
  // ystring can have zero elements since we can plot against "row number"
  Vector<String> ystring = xstring;

  // increase the size of the x column string and add the "none" option
  xstring.resize(xstring.nelements() + 1, True);
  xstring(xstring.nelements() - 1) = "<none>";

  // increase the size of the y column string and add the "rows" option
  ystring.resize(ystring.nelements() + 1, True);
  ystring(ystring.nelements() - 1) = "<row>";

  // now set up the X column choice parameters
  // we want the x axis to contain the vector data - this will
  // allow "time, etc." to go on the y axis (for now) to obtain
  // the types of plots people are used to having 
  // select first valid table column as default
  itsXColumnName = 
    new DParameterChoice("xcolumn", "X Axis Column", 
			 "Selects table column to be plotted along the x axis" 
			 ,xstring, xstring(0), xstring(0),
			 "Label_properties");

  // now set up the Y column choice parameters
  // currently restricted to non-array table columns
  // select row number as default
  itsYColumnName = 
    new DParameterChoice("ycolumn", "Y Axis Column", 
			 "Selects table column or `row number' for y axis", 
			 ystring, ystring(ystring.nelements() - 1),
			 ystring(ystring.nelements() - 1),
			 "Label_properties");

  // now set up the Movie column choice parameters
  // currently restricted to non-array table columns
  // select row number as default
  itsMColumnName = 
    new DParameterChoice("mcolumn", "Movie Axis Column", 
			 "Selects table column or `row number' for movie axis" 
			 ,ystring, ystring(ystring.nelements() - 1),
			 ystring(ystring.nelements() - 1),
			 "Label_properties");
  
  //now set up the Movie column selected choice parameters
  // default is off
  xstring.resize(2);
  xstring(0)="Off";
  xstring(1)="On";
  itsMColumnSet = 
    new DParameterChoice("mcolumnset", "Movie On/Off", 
			 "Selects table column or `row number' for movie axis"
			 , xstring, xstring(0), xstring(0),
			 "Label_properties");
}

// destruct the parameters list
void TblAsXYDD::destructParameters() {
  if (itsXColumnName) {
    delete itsXColumnName;
  }
  if (itsYColumnName) {
    delete itsYColumnName;
  }
  if (itsMColumnName) {
    delete itsMColumnName;
  }
  if (itsMColumnSet) {
    delete itsMColumnSet;
  }
}

// this is a wrapper to read a table column
//
// for now we will assume that the table does not have information 
// which tells how the "row" maps to world coordinates and we will
// just use the number of rows for the world coordinate
//
// we will also assume that the column is made up of a scalar value
// or a one dimensional array  -  we will need to extend this to 
// n-dimensional arrays in the future
//
// we need to add support for complex values
//
Vector<double> TblAsXYDD::columnStatistics(const String& columnName) {

  Vector<double> extrema(2);  // first value is minima second is maxima

  // for now the min is allows zero - until we can determine if a 
  // table measures exists to tell us the world coordinate values
  extrema = 0.;

  // if column not selected then return
  if (columnName == "<none>") {
    return extrema;
  }

  // if column is selected as a row
  if (columnName == "<row>") {
    extrema(1) = table()->nrow();
    return extrema;
  }

  // get the table column data type
  TableDesc tdesc(table()->tableDesc());
  DataType type=tdesc.columnDesc(columnName).trueDataType();

  //
  // scalar column cases
  //
  if (type == TpDouble) {
    // array to contain data from column in columns data type
    Vector<double> typedata;
    // read the scalar column into an array
    ROScalarColumn<double> dataCol(*table(),columnName);
    dataCol.getColumn(typedata,True);
    // minima and maxima of data are world coordinate min and max
    minMax(extrema(0),extrema(1),typedata);
  }
  if (type == TpFloat) {
    Vector<float> typedata;
    ROScalarColumn<float> dataCol(*table(),columnName);
    dataCol.getColumn(typedata,True);
    Array<double> data;
    data.resize(typedata.shape());
    convertArray(data,typedata);
    // minima and maxima of data are world coordinate min and max
    minMax(extrema(0),extrema(1),data);
  }
  if (type == TpShort) {
    Vector<short> typedata;
    ROScalarColumn<short> dataCol(*table(),columnName);
    dataCol.getColumn(typedata,True);
    Array<double> data;
    data.resize(typedata.shape());
    convertArray(data,typedata);
    // minima and maxima of data are world coordinate min and max
    minMax(extrema(0),extrema(1),data);
  }
  if (type == TpUShort) {
    Vector<uShort> typedata;
    ROScalarColumn<uShort> dataCol(*table(),columnName);
    dataCol.getColumn(typedata,True);
    Array<double> data;
    data.resize(typedata.shape());
    convertArray(data,typedata);
    // minima and maxima of data are world coordinate min and max
    minMax(extrema(0),extrema(1),data);
  }
  if (type == TpInt) {
    Vector<int> typedata;
    ROScalarColumn<int> dataCol(*table(),columnName);
    dataCol.getColumn(typedata,True);
    Array<double> data;
    data.resize(typedata.shape());
    convertArray(data,typedata);
    // minima and maxima of data are world coordinate min and max
    minMax(extrema(0),extrema(1),data);
  }
  if (type == TpUInt) {
    Vector<uInt> typedata;
    ROScalarColumn<uInt> dataCol(*table(),columnName);
    dataCol.getColumn(typedata,True);
    Array<double> data;
    data.resize(typedata.shape());
    // have to change template file
    convertArray(data,typedata);
    // minima and maxima of data are world coordinate min and max
    minMax(extrema(0),extrema(1),data);
  }


  return extrema;
}

} //# NAMESPACE CASA - END

