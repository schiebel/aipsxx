//# TaQLNode.cc: Representation of entities in the TaQL parse tree
//# Copyright (C) 2005
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
//# $Id: TaQLNode.cc,v 19.2 2005/06/30 11:00:54 gvandiep Exp $

//# Includes
#include <tables/Tables/TaQLNode.h>
#include <tables/Tables/TaQLNodeDer.h>
#include <tables/Tables/TableGram.h>
#include <casa/IO/AipsIO.h>
#include <tables/Tables/TableError.h>

namespace casa { //# NAMESPACE CASA - BEGIN


// Initialize the static getting the result from the parser.
TaQLNode TaQLNode::theirNode;
std::vector<TaQLNode*> TaQLNode::theirNodesCreated;

TaQLNode TaQLNode::parse (const String& command)
{
  // Add a newline if not present.
  String str(command);
  if (str.length() == 0  ||  str[str.length()-1] != '\n') {
    str += '\n';
  }
  // Set mutex if multi-threading is used.
  /// itsMutex.set()     /// pseudo-code
  try {
    tableGramParseCommand (str);
  } catch (std::exception& x) {
    // Parse error, so delete all nodes and rethrow.
    clearNodesCreated();
    throw TableParseError (str + "  " + x.what());
  }
  TaQLNode node = theirNode;
  clearNodesCreated();
  return node;
}

void TaQLNode::clearNodesCreated()
{
  for (uInt i=0; i<theirNodesCreated.size(); ++i) {
    delete theirNodesCreated[i];
  }
  theirNodesCreated.resize (0);
  theirNode = TaQLNode();
  /// itsMutex.clear()    /// pseudo-code
}

void TaQLNode::save (AipsIO& aio) const
{
  aio.putstart ("TaQLNode", 1);
  saveNode (aio);
  aio.putend();
}

void TaQLNode::saveNode (AipsIO& aio) const
{
  if (itsRep) {
    aio << nodeType();
    itsRep->save (aio);
  } else {
    aio << TaQLNode_Null;
  }
}

TaQLNode TaQLNode::restore (AipsIO& aio)
{
  aio.getstart ("TaQLNode");
  TaQLNode node = restoreNode (aio);
  aio.getend();
  return node;
}

TaQLNode TaQLNode::restoreNode (AipsIO& aio)
{
  char nodeType;
  aio >> nodeType;
  switch (nodeType) {
  case TaQLNode_Null:
    return 0;
  case TaQLNode_Const:
    return TaQLConstNodeRep::restore (aio);
  case TaQLNode_Unary:
    return TaQLUnaryNodeRep::restore (aio);
  case TaQLNode_Binary:
    return TaQLBinaryNodeRep::restore (aio);
  case TaQLNode_Multi:
    return TaQLMultiNodeRep::restore (aio);
  case TaQLNode_Func:
    return TaQLFuncNodeRep::restore (aio);
  case TaQLNode_Range:
    return TaQLRangeNodeRep::restore (aio);
  case TaQLNode_Index:
    return TaQLIndexNodeRep::restore (aio);
  case TaQLNode_KeyCol:
    return TaQLKeyColNodeRep::restore (aio);
  case TaQLNode_Table:
    return TaQLTableNodeRep::restore (aio);
  case TaQLNode_Col:
    return TaQLColNodeRep::restore (aio);
  case TaQLNode_Columns:
    return TaQLColumnsNodeRep::restore (aio);
  case TaQLNode_Join:
    return TaQLJoinNodeRep::restore (aio);
  case TaQLNode_SortKey:
    return TaQLSortKeyNodeRep::restore (aio);
  case TaQLNode_Sort:
    return TaQLSortNodeRep::restore (aio);
  case TaQLNode_LimitOff:
    return TaQLLimitOffNodeRep::restore (aio);
  case TaQLNode_Giving:
    return TaQLGivingNodeRep::restore (aio);
  case TaQLNode_UpdExpr:
    return TaQLUpdExprNodeRep::restore (aio);
  case TaQLNode_Select:
    return TaQLSelectNodeRep::restore (aio);
  case TaQLNode_Update:
    return TaQLUpdateNodeRep::restore (aio);
  case TaQLNode_Insert:
    return TaQLInsertNodeRep::restore (aio);
  case TaQLNode_Delete:
    return TaQLDeleteNodeRep::restore (aio);
  case TaQLNode_Calc:
    return TaQLCalcNodeRep::restore (aio);
  case TaQLNode_CreTab:
    return TaQLCreTabNodeRep::restore (aio);
  case TaQLNode_ColSpec:
    return TaQLColSpecNodeRep::restore (aio);
  case TaQLNode_RecFld:
    return TaQLRecFldNodeRep::restore (aio);
  default:
    throw AipsError ("TaQLNode::restoreNode - unknown node type");
  }
}

TaQLMultiNode TaQLNode::restoreMultiNode (AipsIO& aio)
{
  char nodeType;
  aio >> nodeType;
  switch (nodeType) {
  case TaQLNode_Null:
    return 0;
  case TaQLNode_Multi:
    return TaQLMultiNodeRep::restore (aio);
  default:
    throw AipsError ("TaQLNode::restoreMultiNode - unknown node type");
  }
}


TaQLConstNode::TaQLConstNode (TaQLConstNodeRep* rep)
  : TaQLNode(rep),
    itsNRep(rep)
{}

void TaQLConstNode::setIsTableName()
{
  itsNRep->setIsTableName();
}

const String& TaQLConstNode::getString() const
{
  return itsNRep->getString();
}


TaQLMultiNode::TaQLMultiNode()
  : TaQLNode(0),
    itsNRep (0)
{}

TaQLMultiNode::TaQLMultiNode (Bool isSetOrArray)
  : TaQLNode(new TaQLMultiNodeRep(isSetOrArray))
{
  itsNRep = (TaQLMultiNodeRep*)(TaQLNode::itsRep);
}

TaQLMultiNode::TaQLMultiNode (TaQLMultiNodeRep* rep)
  : TaQLNode(rep),
    itsNRep (rep)
{}

void TaQLMultiNode::add (const TaQLNode& node)
{
  itsNRep->add (node);
}

void TaQLMultiNode::add (TaQLNodeRep* noderep)
{
  itsNRep->add (TaQLNode(noderep));
}

void TaQLMultiNode::setIsSetOrArray()
{
  itsNRep->setIsSetOrArray();
}

void TaQLMultiNode::setPPFix (const String& prefix, const String& postfix)
{
  itsNRep->setPPFix (prefix, postfix);
}



TaQLSelectNode::TaQLSelectNode (TaQLSelectNodeRep* rep)
  : TaQLNode(rep),
    itsNRep (rep)
{}

void TaQLSelectNode::setBrackets()
{
  itsNRep->setBrackets();
}

void TaQLSelectNode::setNoExecute()
{
  itsNRep->setNoExecute();
}

void TaQLSelectNode::setFromExecute()
{
  itsNRep->setFromExecute();
}


} //# NAMESPACE CASA - END
