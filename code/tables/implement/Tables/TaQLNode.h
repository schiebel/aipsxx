//# TaQLNode.h: Envelope class for a node in the raw TaQL parse tree
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
//# $Id: TaQLNode.h,v 19.2 2005/07/04 06:10:55 gvandiep Exp $

#ifndef TABLES_TAQLNODE_H
#define TABLES_TAQLNODE_H

//# Includes
#include <tables/Tables/TaQLNodeRep.h>
#include <vector>
#include <iostream>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declaration.
class AipsIO;
class TaQLNodeVisitor;
class TaQLMultiNode;
class TaQLConstNodeRep;
class TaQLMultiNodeRep;
class TaQLSelectNodeRep;

// <summary>
// Envelope class for a node in the raw TaQL parse tree.
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="" tests="tTaQLNode">
// </reviewed>

// <prerequisite>
//# Classes you should understand before using this one.
//   <li> <linkto group=TableGram.h#TableGramFunctions>TableGram</linkto>
//   <li> Note 199 describing <a href="../../../notes/199/199.html">TaQL</a>
// </prerequisite>

// <synopsis>
// The result of parsing a TaQL command is stored in TaQLNode objects.
// Each part of the command can have its own specialized
// <linkto class=TaQLNodeRep>TaQLNodeRep</linkto> object, which forms
// the letter in the TaQLNode envelope.
// <br>The actual scanning/parsing of the command is done using flex/bison
// as defined in the TableGram files.
// </synopsis> 

// <motivation>
// The letter-envelope idiom (counted pointer) makes if much easier
// to keep track of memory, especially in the case of exceptions.
// </motivation>

class TaQLNode
{
public:
  // Default constructor.
  TaQLNode()
    : itsRep(0) {}

  // Construct for given letter. It takes over the pointer.
  TaQLNode (TaQLNodeRep* rep)
    { itsRep = TaQLNodeRep::link (rep); }

  // Copy constructor (reference semantics).
  TaQLNode (const TaQLNode& that)
    { itsRep = TaQLNodeRep::link (that.itsRep); }

  // Assignment (reference semantics).
  TaQLNode& operator= (const TaQLNode& that)
    { if (this != &that) {
        TaQLNodeRep::unlink (itsRep);
	itsRep = TaQLNodeRep::link (that.itsRep);
      }
    return *this;
    }

  // Destructor deletes the letter if no more references.
  ~TaQLNode()
    { TaQLNodeRep::unlink (itsRep); }

  // Parse a TaQL command and return the result.
  // An exception is thrown in case of parse errors.
  static TaQLNode parse (const String& command);

  // Does the envelope contain a letter?
  Bool isValid() const
    { return itsRep; }

  // Return the type of letter.
  char nodeType() const
    { return itsRep->nodeType(); }

  // Get read access to the letter.
  const TaQLNodeRep* getRep() const
    { return itsRep; }

  // 
  TaQLNodeResult visit (TaQLNodeVisitor& visitor) const
    { return (itsRep  ?  itsRep->visit (visitor) : TaQLNodeResult()); }

  // Print the node (recursively) in the given stream.
  void show (std::ostream& os) const
    { if (itsRep) itsRep->show (os); }

  // Save and restore the entire tree.
  // <group>
  void save (AipsIO& aio) const;
  static TaQLNode restore (AipsIO& aio);
  // </group>

protected:
  TaQLNodeRep* itsRep;
private:
  static void clearNodesCreated();
public:
  // Helper functions for save/restore of tree.
  // <group>
  void saveNode (AipsIO& aio) const;
  static TaQLNode restoreNode (AipsIO& aio);
  static TaQLMultiNode restoreMultiNode (AipsIO& aio);
  // </group>

  // The object getting the final tree.
  static TaQLNode theirNode;
  // A list of objects created by the parser and deleted at the end.
  static std::vector<TaQLNode*> theirNodesCreated;
};


// <summary>
// Envelope class for a node containing a constant value.
// </summary>
// <use visibility=local>
// <reviewed reviewer="" date="" tests="tTaQLNode">
// </reviewed>
// <synopsis>
// This is a specialization of the envelope class
// <linkto class=TaQLNode>TaQLNode</linkto> for a node containing
// a constant value.
// </synopsis> 
class TaQLConstNode: public TaQLNode
{
public:
  explicit TaQLConstNode (TaQLConstNodeRep* rep);
  void setIsTableName();
  const String& getString() const;
private:
  TaQLConstNodeRep* itsNRep;
};


// <summary>
// Envelope class for a node containing a select command.
// </summary>
// <use visibility=local>
// <reviewed reviewer="" date="" tests="tTaQLNode">
// </reviewed>
// <synopsis>
// This is a specialization of the envelope class
// <linkto class=TaQLNode>TaQLNode</linkto> for a node containing
// a select command.
// </synopsis> 
class TaQLMultiNode: public TaQLNode
{
public:
  TaQLMultiNode();
  explicit TaQLMultiNode (Bool isSetOrArray);
  TaQLMultiNode (TaQLMultiNodeRep* rep);
  void add (const TaQLNode& node);
  void add (TaQLNodeRep* noderep);
  void setIsSetOrArray();
  void setPPFix (const String& prefix, const String& postfix);
  const TaQLMultiNodeRep* getMultiRep() const
    { return itsNRep; }
private:
  TaQLMultiNodeRep* itsNRep;
};


// <summary>
// Envelope class for a node containing a list of nodes.
// </summary>
// <use visibility=local>
// <reviewed reviewer="" date="" tests="tTaQLNode">
// </reviewed>
// <synopsis>
// This is a specialization of the envelope class
// <linkto class=TaQLNode>TaQLNode</linkto> for a node containing
// a list of nodes.
// </synopsis> 
class TaQLSelectNode: public TaQLNode
{
public:
  TaQLSelectNode (TaQLSelectNodeRep* rep);
  void setBrackets();
  void setNoExecute();
  void setFromExecute();
private:
  TaQLSelectNodeRep* itsNRep;
};


} //# NAMESPACE CASA - END

#endif
