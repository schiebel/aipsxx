//# ExprNodeRep.h: Abstract base class for a node in a table column expression tree
//# Copyright (C) 1994,1995,1996,1997,1998,2000,2001,2003
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
//# $Id: ExprNodeRep.h,v 19.10 2005/07/04 06:10:55 gvandiep Exp $

#ifndef TABLES_EXPRNODEREP_H
#define TABLES_EXPRNODEREP_H

//# Includes
#include <casa/aips.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableExprId.h>
#include <tables/Tables/ExprRange.h>
#include <casa/BasicSL/Complex.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Utilities/DataType.h>
#include <casa/Utilities/Regex.h>
#include <casa/iosfwd.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declarations
class TableExprNode;
class TableExprNodeColumn;
template<class T> class Block;


// <summary>
// Abstract base class for a node in a table column expression tree
// </summary>

// <use visibility=local>

// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="">
// </reviewed>

// <prerequisite>
//# Classes you should understand before using this one.
//   <li> <linkto class=TableExprNode>TableExprNode</linkto>
// </prerequisite>

// <etymology>
// TableExprNodeRep is the (abstract) REPresentation of a node in a table
// expression tree.
// </etymology>

// <synopsis> 
// TableExprNodeRep is the base class for all nodes in a table
// expression tree. It is used by the handle class TableExprNode.
// <p>
// The objects of this class are reference-counted to make it possible
// that the same object is reused.
// </synopsis> 

// <motivation>
// TableExprNodeRep and its derivations store a table select expression
// before actually evaluating it. It is also possible that the classes
// are used by the table expression parser defined in TableParse and
// TableGram.
// <br>
// For each operator a special derived class is implemented.
// Another approach could have been to store the operator as
// a flag and switch on that. However, that causes extra overhead
// and the C++ virtual function mechanism is designed for
// these purposes.
// </motivation>

// <todo asof="$DATE:$">
//# A List of bugs, limitations, extensions or planned refinements.
//   <li> add selection by comparing with a set of values
// </todo>


class TableExprNodeRep
{
public:
    // Define the data types of a node.
    enum NodeDataType {
	NTBool,
	NTDouble,
	NTComplex,
	NTString,
	NTRegex,
	NTDate,
	NTNumeric,             //# NTDouble or NTComplex
	NTAny                  //# Any data type
    };

    // Define the value types.
    enum ValueType {
	VTScalar,
	VTArray,
	VTRecord,
	VTSetElem,
	VTSet,
	VTIndex
    };

    // Define the operator types.
    // LE and LT are handled as GE and GT with swapped operands.
    enum OperType {OtPlus, OtMinus, OtTimes, OtDivide, OtModulo,
		   OtEQ, OtGE, OtGT, OtNE, OtIN,
		   OtAND, OtOR, OtNOT, OtMIN,
		   OtColumn, OtField, OtLiteral, OtFunc, OtSlice, OtUndef,
	           OtRownr, OtRandom
    };

    // Define the value types of the 2 arguments when arrays are involved.
    enum ArgType {
	NoArr, ArrArr, ArrSca, ScaArr
    };

    // Define (sub-)expression type
    enum ExprType {
	// A constant subexpression which can be evaluated immediately.
	Constant,
	// A variable (i.e. row dependent) subexpression which
	// has to be evaluated for each table row.
	Variable
	// An expensive constant subexpression which should only be
	// evaluated when needed (e.g. a subquery).
//	Lazy
    };

    // Construct a node.
    TableExprNodeRep (NodeDataType, ValueType, OperType, ArgType, ExprType,
		      Int ndim, const IPosition& shape,
		      const Table& table);

    // This constructor is called from the derived TableExprNodeRep.
    TableExprNodeRep (NodeDataType, ValueType, OperType, const Table&);

    // Copy constructor.
    TableExprNodeRep (const TableExprNodeRep&);

    // The destructor deletes all the underlying TableExprNode objects.
    virtual ~TableExprNodeRep();

    // Link to this object, i.e. increase its reference count.
    TableExprNodeRep* link();

    // Unlink from the given object.
    // If its reference count is zero, delete it.
    static void unlink (TableExprNodeRep*);

    // Get a scalar value for this node in the given row.
    // The appropriate functions are implemented in the derived classes and
    // will usually invoke the get in their children and apply the
    // operator on the resulting values.
    // <group>
    virtual Bool getBool         (const TableExprId& id);
    virtual Double getDouble     (const TableExprId& id);
    virtual DComplex getDComplex (const TableExprId& id);
    virtual String getString     (const TableExprId& id);
    virtual Regex getRegex       (const TableExprId& id);
    virtual MVTime getDate       (const TableExprId& id);
    // </group>

    // Get an array value for this node in the given row.
    // The appropriate functions are implemented in the derived classes and
    // will usually invoke the get in their children and apply the
    // operator on the resulting values.
    // <group>
    virtual Array<Bool> getArrayBool         (const TableExprId& id);
    virtual Array<Double> getArrayDouble     (const TableExprId& id);
    virtual Array<DComplex> getArrayDComplex (const TableExprId& id);
    virtual Array<String> getArrayString     (const TableExprId& id);
    virtual Array<MVTime> getArrayDate       (const TableExprId& id);
    // </group>

    // Does a value occur in an array or set?
    // The default implementation tests if it is in an array.
    // <group>
    virtual Bool hasBool     (const TableExprId& id, Bool value);
    virtual Bool hasDouble   (const TableExprId& id, Double value);
    virtual Bool hasDComplex (const TableExprId& id, const DComplex& value);
    virtual Bool hasString   (const TableExprId& id, const String& value);
    virtual Bool hasDate     (const TableExprId& id, const MVTime& value);
    virtual Array<Bool> hasArrayBool     (const TableExprId& id,
					  const Array<Bool>& value);
    virtual Array<Bool> hasArrayDouble   (const TableExprId& id,
					  const Array<Double>& value);
    virtual Array<Bool> hasArrayDComplex (const TableExprId& id,
					  const Array<DComplex>& value);
    virtual Array<Bool> hasArrayString   (const TableExprId& id,
					  const Array<String>& value);
    virtual Array<Bool> hasArrayDate     (const TableExprId& id,
					  const Array<MVTime>& value);
    // </group>

    // Get the number of rows in the table associated with this expression.
    // One is returned if the expression is a constant.
    // Zero is returned if no table is associated with it.
    uInt nrow() const;

    // Get the data type of the column.
    // It returns True when it could set the data type (which it can
    // if the expression is a scalar column or a constant array column pixel).
    // Otherwise it returns False.
    virtual Bool getColumnDataType (DataType&) const;

    // Get the value of the expression evaluated for the entire column.
    // The data of function called should match the data type as
    // returned by function <src>getColumnDataType</src>.
    // <group>
    virtual Array<Bool>     getColumnBool();
    virtual Array<uChar>    getColumnuChar();
    virtual Array<Short>    getColumnShort();
    virtual Array<uShort>   getColumnuShort();
    virtual Array<Int>      getColumnInt();
    virtual Array<uInt>     getColumnuInt();
    virtual Array<Float>    getColumnFloat();
    virtual Array<Double>   getColumnDouble();
    virtual Array<Complex>  getColumnComplex();
    virtual Array<DComplex> getColumnDComplex();
    virtual Array<String>   getColumnString();
    // </group>

    // Convert the tree to a number of range vectors which at least
    // select the same things.
    // This function is very useful to convert the expression to
    // some intervals covering the select expression. This can
    // be used to do a rough fast selection via an index and do the
    // the slower final selection on that much smaller subset.
    // The function can only convert direct comparisons of columns
    // with constants (via ==, !=, >, >=, < or <=) and their combinations
    // using && or ||.
    virtual void ranges (Block<TableExprRange>&);

    // Get the data type of the derived TableExprNode object.
    // This is the data type of the resulting value. E.g. a compare
    // of 2 numeric values results in a Bool, thus the data type
    // of, say, TableExprNodeEQ<T> is always Bool.
    // Function getInternalDT gives the internal data type, thus in
    // the example above the data type of T.
    NodeDataType dataType() const;

    // Get the value type.
    ValueType valueType() const;

    // Set the value type.
    void setValueType (ValueType vtype);

    // Get the operator type.
    OperType operType() const;

    // Get the expression type.
    ExprType exprType() const;

    // Is the exprerssion a constant?
    Bool isConstant() const;

    // Get the fixed dimensionality (same for all rows).
    Int ndim() const;

    // Get the fixed shape (same for all rows).
    const IPosition& shape() const;

    // Get the shape for the given row.
    // It returns the fixed shape if defined, otherwise getShape(id).
    const IPosition& shape (const TableExprId& id);

    // Is the value in the given row defined?
    // The default implementation returns True.
    virtual Bool isDefined (const TableExprId& id);

    // Show the expression tree.
    virtual void show (ostream&, uInt indent) const;

    // Get table. This gets the Table object to which a
    // TableExprNode belongs. A TableExprNode belongs to the Table to
    // which the column(s) used in an expression belong. Note that
    // all columns in an expression have to belong to the same table.
    // <group>
    Table& table();
    const Table& table() const;
    // </group>

    // Replace the Table pointer in this node and all its children.
    virtual void replaceTablePtr (const Table&);

    // Create a range object from a column and an interval.
    static void createRange (Block<TableExprRange>&,
			     TableExprNodeColumn*, Double start, Double end);

    // Create a empty range object.
    static void createRange (Block<TableExprRange>&);

protected:
    uInt              count_p;       //# Reference count
    Table             table_p;       //# Table from which node is "derived"
    NodeDataType      dtype_p;       //# data type of the operation
    ValueType         vtype_p;       //# value type of the result
    OperType          optype_p;      //# operator type
    ArgType           argtype_p;     //# argument types
    ExprType          exprtype_p;    //# Constant or Variable
    Int               ndim_p;        //# Fixed dimensionality of node values
                                     //# -1 = variable dimensionality
    IPosition         shape_p;       //# Fixed shape of node values

    // Get the shape for the given row.
    virtual const IPosition& getShape (const TableExprId& id);

    // Get pointer to REPresentation object.
    // This is used by derived classes.
    static TableExprNodeRep* getRep (TableExprNode&);

    // When one of the children is a constant, convert its data type
    // to that of the other operand. This avoids that conversions are
    // done for each get.
    // The default implementation does nothing.
    virtual void convertConstChild();

    // Check if this node uses the same table pointer.
    // Fill the Table object if it is still null.
    // <group>
    void checkTablePtr (const TableExprNodeRep* node);
    static void checkTablePtr (Table& table,
			       const TableExprNodeRep* node);
    // </group>

    // Set expression type to Variable if node is Variable.
    // <group>
    void fillExprType (const TableExprNodeRep* node);
    static void fillExprType (ExprType&, const TableExprNodeRep* node);
    // </group>

    // When the node is constant, it is evaluated and replaced by
    // the appropriate TableExprNodeConst object.
    // If not constant, it calls the virtual ConvertConstChild function
    // which can convert a constant child when appropriate.
    static TableExprNodeRep* convertNode (TableExprNodeRep* thisNode,
					  Bool convertConstType);

private:
    // A copy of a TableExprNodeRep cannot be made.
    TableExprNodeRep& operator= (const TableExprNodeRep&);
};




// <summary>
// Abstract base class for a node having 0, 1, or 2 child nodes.
// </summary>

// <use visibility=local>

// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="">
// </reviewed>

// <prerequisite>
//# Classes you should understand before using this one.
//   <li> <linkto class=TableExprNodeRep>TableExprNodeRep</linkto>
// </prerequisite>

// <etymology>
// TableExprNodeBinary is a node in the table expression tree
// representing a binary node (i.e. having 2 operands).
// </etymology>

// <synopsis> 
// TableExprNodeBinary is the abstract base class for all nodes in a table
// expression tree using up to 2 operands.
// It is used as the base class for the node classes representing
// operator +, -, etc..
// </synopsis> 

// <motivation>
// This class contains the common functionality for the classes
// representing a binary (or unary) operator.
// </motivation>

//# <todo asof="$DATE:$">
//# A List of bugs, limitations, extensions or planned refinements.
//#   <li> to be filled in
//# </todo>


class TableExprNodeBinary : public TableExprNodeRep
{
public:
    // Constructor
    TableExprNodeBinary (NodeDataType, ValueType, OperType, const Table&);
    TableExprNodeBinary (NodeDataType, const TableExprNodeRep&, OperType);

    // Destructor
    virtual ~TableExprNodeBinary();
    
    // Show the expression tree.
    virtual void show (ostream&, uInt indent) const;

    // Check the data types and get the common one.
    static NodeDataType getDT (NodeDataType leftDtype,
			       NodeDataType rightDype,
			       OperType operType);

    // Check the data and value types and get the common one.
    static TableExprNodeRep getTypes (const TableExprNodeRep& left,
				      const TableExprNodeRep& right,
				      OperType operType);

    // Link the children to the node and convert the children
    // to constants if needed and possible. Also convert the node to
    // constant if possible.
    static TableExprNodeRep* fillNode (TableExprNodeBinary* thisNode,
				       TableExprNodeRep* left,
				       TableExprNodeRep* right,
				       Bool convertConstType);

    // When one of the children is a constant, convert its data type
    // to that of the other operand. This avoids that conversions are
    // done for each get.
    void convertConstChild();

    // Replace the Table in this node and all its children.
    virtual void replaceTablePtr (const Table&);

  // Get the child nodes.
  // <group>
  const TableExprNodeRep* getLeftChild() const
    { return lnode_p; }
  const TableExprNodeRep* getRightChild() const
    { return rnode_p; }
  // </group>

protected:
    TableExprNodeRep* lnode_p;     //# left operand
    TableExprNodeRep* rnode_p;     //# right operand
};




// <summary>
// Abstract base class for a node having multiple child nodes.
// </summary>

// <use visibility=local>

// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="">
// </reviewed>

// <prerequisite>
//# Classes you should understand before using this one.
//   <li> <linkto class=TableExprNodeRep>TableExprNodeRep</linkto>
// </prerequisite>

// <etymology>
// TableExprNodeMulti is a node in the table expression tree
// which can have MULTIple child nodes.
// </etymology>

// <synopsis> 
// TableExprNodeMulti is the abstract base class for all nodes in a table
// expression tree using multiple operands.
// It is used as the base class for the node classes representing
// functions, sets, indices, etc..
// </synopsis> 

// <motivation>
// This class contains the common functionality for the classes
// representing a node with multiple operands.
// </motivation>

//# <todo asof="$DATE:$">
//# A List of bugs, limitations, extensions or planned refinements.
//#   <li> to be filled in
//# </todo>


class TableExprNodeMulti : public TableExprNodeRep
{
public:
    // Constructor
    TableExprNodeMulti (NodeDataType, ValueType, OperType,
			const TableExprNodeRep& source);

    // Destructor
    virtual ~TableExprNodeMulti();

    // Show the expression tree.
    virtual void show (ostream&, uInt indent) const;

    // Check number of arguments
    // low <= number_of_args <= high
    // It throws an exception if wrong number of arguments.
    static uInt checkNumOfArg (uInt low, uInt high,
			       const PtrBlock<TableExprNodeRep*>& nodes);
    
    // Replace the Table pointer in this node and all its children.
    virtual void replaceTablePtr (const Table&);

    // Get the child nodes.
    const PtrBlock<TableExprNodeRep*>& getChildren() const
      { return operands_p; }

protected:
    PtrBlock<TableExprNodeRep*> operands_p;


    // Check datatype of nodes and return output type.
    // It also sets the expected data type of the operands (from dtIn).
    static NodeDataType checkDT (Block<Int>& dtypeOper,
				 NodeDataType dtIn, NodeDataType dtOut,
				 const PtrBlock<TableExprNodeRep*>& nodes);
};



//# Get the data type of the node.
inline TableExprNodeRep::NodeDataType TableExprNodeRep::dataType() const
    { return dtype_p; }

//# Get the value type of the node.
inline TableExprNodeRep::ValueType TableExprNodeRep::valueType() const
    { return vtype_p; }

//# Get the value type of the node.
inline void TableExprNodeRep::setValueType (TableExprNodeRep::ValueType vtype)
    { vtype_p = vtype; }

//# Get the operator type of the node.
inline TableExprNodeRep::OperType TableExprNodeRep::operType() const
    { return optype_p; }

//# Get the expression type of the node.
inline TableExprNodeRep::ExprType TableExprNodeRep::exprType() const
    { return exprtype_p; }

//# Is the expression a constant?
inline Bool TableExprNodeRep::isConstant() const
    { return  (exprtype_p == Constant); }

//# Get the fixed dimensionality of the node.
inline Int TableExprNodeRep::ndim() const
    { return ndim_p; }

//# Get the fixed shape of the node.
inline const IPosition& TableExprNodeRep::shape() const
    { return shape_p; }

//# Get the table from which the node is derived.
inline Table& TableExprNodeRep::table()
    { return table_p; }
inline const Table& TableExprNodeRep::table() const
    { return table_p; }

inline void TableExprNodeRep::checkTablePtr (const TableExprNodeRep* node)
    { checkTablePtr (table_p, node); }
inline void TableExprNodeRep::fillExprType (const TableExprNodeRep* node)
    { fillExprType (exprtype_p, node); }

//# Link to the node.
inline TableExprNodeRep* TableExprNodeRep::link()
{
    count_p++;
    return this;
}


} //# NAMESPACE CASA - END

#endif
