//# VOTable.cc:  this defines VOTable, which reads a VOTABLE file into a VOTable tree.
//# Copyright (C) 2003
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
//# $Id: VOTable.cc,v 19.1 2004/11/30 17:51:23 ddebonis Exp $

//# Includes
#include <stdlib.h>
#include <assert.h>
#include <complex>
#include <VOTable.h>
#include <xercesc/dom/DOM.hpp>
#include <xercesc/util/PlatformUtils.hpp>
#include <xercesc/parsers/XercesDOMParser.hpp>

#include <casa/namespace.h>
using xercesc::BaseRefVectorOf;
using xercesc::XMLPlatformUtils;
using xercesc::DOMAttr;
using xercesc::XMLException;

////////////////////////////////////////////////////////////////
// Table of known node types, their ASCII names and functions to
// create them.

// Pointer to node's 'makeNode' function.
typedef votNode * (*NodeMaker)(const votNode *parent, DOMElement *);

static votNode *dummymakeNode(const votNode *parent, DOMElement *e);

// Table of Element IDs, names, and node making functions.
static struct ElementTable {
	VOTable::ELEMENT	id;		// Node's enum
	const char		*name;		// Nodes string name.
	NodeMaker		makeNode;	// Function to create node.
	}
 elementTable[] = {
	{VOTable::UNKNOWN_ELEMENT, "UNKNOWN_ELEMENT", 0},
//	{VOTable::VOTABLE, "VOTABLE", &VOTable::makeNode},
	{VOTable::VOTABLE, "VOTABLE", &dummymakeNode},
	{VOTable::DESCRIPTION, "DESCRIPTION", votDescription::makeNode},
	{VOTable::DEFINITIONS, "DEFINITIONS", votDefinition::makeNode},
	{VOTable::INFO, "INFO", votInfo::makeNode},
	{VOTable::RESOURCE, "RESOURCE", votResource::makeNode},
	{VOTable::COOSYS, "COOSYS", votCOOSYS::makeNode},
	{VOTable::PARAM, "PARAM", votParam::makeNode},
	{VOTable::LINK, "LINK", votLink::makeNode},
	{VOTable::TABLE, "TABLE", votTable::makeNode},
	{VOTable::VALUES, "VALUES", votValues::makeNode},
	{VOTable::FIELD, "FIELD", votField::makeNode},
	{VOTable::DATA, "DATA", votData::makeNode},
	{VOTable::MIN, "MIN", votMinMaxNode::makeNode},
	{VOTable::MAX, "MAX", votMinMaxNode::makeNode},
	{VOTable::OPTION, "OPTION", votOption::makeNode},
	{VOTable::TABLEDATA, "TABLEDATA", votTableData::makeNode},
	{VOTable::BINARY, "BINARY", votBinary::makeNode},
	{VOTable::FITS, "FITS", votFITS::makeNode},
	{VOTable::TR, "TR", votTR::makeNode},
	{VOTable::TD, "TD", votTD::makeNode},
	{VOTable::STREAM, "STREAM", votStream::makeNode}
  };
static const int NUMELEMENTS = sizeof(elementTable)/(sizeof(elementTable));

// A table of all the known attributes.
static struct AttributeTable {
	VOTable::ATTRIBUTE	id;
	const char		*name;
	} attributeTable[] = {
		{VOTable::UNKNOWN_ATTRIBUTE, "UNKNOWN_ATTRIBUTE"},
		// (Note: this is why the id() func isn't ID()).
		{VOTable::ID, "ID"}, {VOTable::VERSION, "version"},
		{VOTable::NAME, "name"}, {VOTable::TYPE, "type"},
		{VOTable::VALUE, "value"}, {VOTable::UNIT, "unit"},
		{VOTable::DATATYPE, "datatype"},
		{VOTable::PRECISION, "precision"}, {VOTable::WIDTH, "width"},
		{VOTable::REF, "ref"}, {VOTable::UCD, "ucd"},
		{VOTable::ARRAYSIZE, "arraysize"},
		{VOTable::NULLATTR, "null"},
		{VOTable::INVALID, "invalid"},
		{VOTable::INCLUSIVE, "inclusive"},
		{VOTable::CONTENT_ROLE, "content-role"},
		{VOTable::CONTENT_TYPE, "content-type"},
		{VOTable::TITLE, "title"}, {VOTable::HREF, "href"},
		{VOTable::GREF, "gref"}, {VOTable::ACTION, "action"},
		{VOTable::EXTNUM, "extnum"}, {VOTable::ACTUATE, "actuate"},
		{VOTable::ENCODING, "encoding"}, {VOTable::EXPIRES, "expires"},
		{VOTable::RIGHTS, "rights"}, {VOTable::EQUINOX, "equinox"},
		{VOTable::EPOCH, "epoch"}, {VOTable::SYSTEM, "system"}
	};
static const int NUMATTRIBUTES =
	 sizeof(attributeTable)/(sizeof(attributeTable));

// And one for the PRIMITIVES.
static struct PrimitiveTable {
	VOTable::PRIMITIVE	id;
	const char		*name;
	const char		*longname;
	const char		*fitForm;
	      int		nbytes;
	} primitiveTable[] = {
	{votNode::UNKNOWN_PRIMITIVE, "Unknown Primitive", "unknown", "", 0 },
	{votNode::BOOLEAN, "boolean", "Logical", "L", 1 },
	{votNode::BIT, "bit", "Bit", "X", -1 },
	{votNode::UNSIGNEDBYTE, "unsignedByte", "Byte (0 to 255)", "B", 1 },
	{votNode::SHORT, "short", "Short Integer", "I", 2 },
	{votNode::INT, "int", "Integer", "J", 4 },
	{votNode::LONG, "long", "Long integer", "K", 8 },
	{votNode::CHAR, "char", "ASCII Character", "A", 1 },
	{votNode::UNICODECHAR, "unicodeChar", "Unicode Character", "" , 2 },
	{votNode::FLOAT, "float", "Floating point", "E", 4 },
	{votNode::DOUBLE, "double", "Double", "D", 8 },
	{votNode::FLOATCOMPLEX, "floatComplex", "Float Complex", "C", 8 },
	{votNode::DOUBLECOMPLEX, "doubleComplex", "Double Complex", "M", 16}
	};
static const int NUMPRIMITIVES =
	 sizeof(primitiveTable)/(sizeof(primitiveTable));

////////////////////////////////////////////////////////////////

// Print an XMLCh * type string.
ostream& operator<< (ostream& target, const XMLCh *s)
{
	char *p = XMLString::transcode(s);
	if(p != 0)
	{	target << p;
		delete [] p;
	}
	else
		target << "(NULL)";
	return target;
}

////////////////////////////////////////////////////////////////
////		Internal nodes
////	 (Base classes for the others)
////////////////////////////////////////////////////////////////
//bool		votNode::printReferences_ = false;
XMLCh		**votNode::elementTable_;
XMLCh		**votNode::attributeTable_;
XMLCh		**votNode::primitiveTable_;
votXMLChMap	*votNode::primitiveMap_;

votNode::votNode(const votNode *parent, DOMElement *node,
		 votNode::ELEMENT nt)
		 : node_(node), parent_(parent), nodeType_(nt)
{
	initOnce();
	// The only time parent is NULL is when this is the root (VOTable)
	// node.
	if(parent != 0)
		root_ = parent->rootNode();
	else
	if(nt == votNode::VOTABLE)
	{	// If we're in the middle of building a VOTable object,
		// 'this' is in the process of becoming the root node.
		root_ = (VOTable *)this; // Don't use dynamic_cast.
	}
	else
		root_ = 0;		// Oops.

	if(node != 0)
		children_ = node->getChildNodes();
	else
		children_ = 0;
}

// Creates a dummy node whose sole purpose is to initialize the static
// tables.
votNode::votNode() : node_(0), parent_(0), nodeType_(UNKNOWN_ELEMENT)
{
	initOnce();
}

votNode::~votNode()
{
	parent_ = 0;
	root_ = 0;
	node_ = 0;
	// I think the DOM stuff deletes most of the nodes it supplies.
	children_ = 0;

#if 0
	for(i=0; i<NUMELEMENTS; i++)
		if(elementTable_[i] != 0)
			delete elementTable_[i];
	delete [] elementTable_;
	elementTable_ = 0;

	for(i=0; i<NUMATTRIBUTES; i++)
		if(attributeTable_[i] != 0)
			delete attributeTable_[i];
	delete [] attributeTable_;
	attributeTable_ = 0;
#endif
}

// One time only Initialization.
bool	votNode::initedOnce_ = false;
static const char *MSG1 =
	 "VOTable::Attribute table length doesn't match NUMATTRIBUTES";
static const char *MSG2 =
	 "VOTable::Element table length doesn't match NUMELEMENTS";
static const char *MSG3 =
	 "VOTable::Primitive table length doesn't match NUMPRIMITIVES";

void votNode::initOnce()
{ int i;
	if(initedOnce_)
		return;
	// Make sure the enum -> string tables are consistent.
	assert((NUMATTRIBUTES==votNode::NUMATTRIBUTES)&& MSG1);
	assert((NUMELEMENTS== votNode::NUMELEMENTS)&& MSG2);
	assert((NUMPRIMITIVES== votNode::NUMPRIMITIVES)&& MSG3);

	// Do consistency check on the static tables.
	for(i=0; i< NUMATTRIBUTES; i++)
	{ votNode::ATTRIBUTE atr = (votNode::ATTRIBUTE) i;
		assert((atr == attributeTable[i].id)&& "votNode::ATTRIBUTE table mismatch");
	}

	for(i=0; i< NUMELEMENTS; i++)
	{ votNode::ELEMENT atr = (votNode::ELEMENT) i;
		assert((atr == elementTable[i].id)&& "votNode::ELEMENT table mismatch");
	}

	for(i=0; i< NUMPRIMITIVES; i++)
	{ votNode::PRIMITIVE atr = (votNode::PRIMITIVE) i;
		if(atr != primitiveTable[i].id)
#if 0
		cerr << "I " << i << " " << primitiveTable[i].id
		     << " " << primitiveTable[i].name << endl;
#endif
		assert((atr == primitiveTable[i].id)&& "votNode::PRIMITIVE table mismatch");
	}

	// Create tables to convert from, say, ELEMENT to its XMLCh string.
	elementTable_ = new (XMLCh *)[NUMELEMENTS];
	for(i=0; i<NUMELEMENTS; i++)
	{ const char *name = elementTable[i].name;
		elementTable_[i] = XMLString::transcode(name);
	}

	attributeTable_ = new (XMLCh *)[NUMATTRIBUTES];
	for(i=0; i<NUMATTRIBUTES; i++)
	{ const char *name = attributeTable[i].name;
		attributeTable_[i] = XMLString::transcode(name);
	}

	primitiveTable_ = new (XMLCh *)[NUMPRIMITIVES];
	primitiveMap_ = new votXMLChMap();

	for(i=0; i<NUMPRIMITIVES; i++)
	{ const char *name = primitiveTable[i].name;
	  XMLCh *xname = XMLString::transcode(name);
		primitiveTable_[i] = xname;
		primitiveMap_->add(xname, primitiveTable[i].id);
	}

	initedOnce_ = true;
}

const XMLCh *votNode::getAttributeName(votNode::ATTRIBUTE id)
{
	if(id >= NUMATTRIBUTES)
		id = UNKNOWN_ATTRIBUTE;
	return attributeTable_[id];
}

const XMLCh *votNode::getElementName(votNode::ELEMENT id)
{
	if(id >= NUMELEMENTS)
		id = UNKNOWN_ELEMENT;

	return elementTable_[id];
}

const XMLCh *votNode::getPrimitiveName(votNode::PRIMITIVE id)
{
	if(id >= NUMPRIMITIVES)
		id = UNKNOWN_PRIMITIVE;
	return primitiveTable_[id];
}

votNode::PRIMITIVE votNode::getPrimitiveID(const XMLCh *name)
{ votNode::PRIMITIVE id = (votNode::PRIMITIVE)primitiveMap_->item(name);

	return id;
}

votNode::PRIMITIVE votNode::getPrimitiveID(const char *name)
{
	if(name == 0)
		return votNode::UNKNOWN_PRIMITIVE; 
	XMLCh *str = XMLString::transcode(name);
	PRIMITIVE id = (PRIMITIVE)primitiveMap_->item(str);
	delete str;

	return id;
}

////////////////////////////////////////////////////////////////
//		These are used to build the list of nodes.

// Look at the node's children for the first one whose tag matches name.
DOMElement *votNode::getDOMNodeByTagName(const XMLCh *name)const
{DOMElement *element = 0;
 unsigned int nc = 0;

	// Walk through the node's children. Check each ELEMENT node's
	// tag to see if it matches name.
	if((children_ != 0) && ((nc = children_->getLength()) > 0))
	{	for(unsigned int i=0; i < nc; i++)
		{ DOMNode *node = children_->item(i);
			if(node->getNodeType() == DOMNode::ELEMENT_NODE)
//			{DOMElement *e = (DOMElement *)node;
			{DOMElement *e = dynamic_cast<DOMElement *>(node);
				if(tagsMatch(e, name))
				{	element = e;
					break;
				}
			}
		}
	}
	return element;
}

// Return the first child whose tag matches 'id'.
DOMElement *votNode::getDOMNodeByTagID(votNode::ELEMENT id)const
{ DOMElement *node = 0;

#if 0
	if(root_ != 0)
	{const XMLCh *name = root_->getElementName(id);
		 node = getDOMNodeByTagName(name);
	}
	else
		cout << "votNode::getDOMNodeByTagID root is 0\n";
#else
	const XMLCh *name = getElementName(id);
	node = getDOMNodeByTagName(name);
#endif

	return node;
}

// Return a votNode for the first child with tag 'id'.
votNode *votNode::getChildByTagID(votNode::ELEMENT id)const
{ votNode *node = 0;

#if 0
	if(root_ == 0)
		cout << "votNode::getChildByTagID root is 0\n";

	if(root_ == 0)
		return 0;

#endif

	DOMElement *e = getDOMNodeByTagID(id);
	if( e == 0)
		return 0;
	NodeMaker makeNode = elementTable[id].makeNode;
	if(makeNode == 0)	// UNKNOWN_ELEMENT.
		return 0;

	node = makeNode(this, e);
	return node;
}

void votNode::getNodesByTagID(votNode::ELEMENT id, votNodeList *nodeList)const
{ unsigned int nc = 0;

#if 0
	if(root_ == 0)
		cout << "votNode::getNodesByTagID root is 0\n";


	if(root_ == 0)
		return;

	// XML string corresponding to id.
	const XMLCh *name = root_->getElementName(id);
#else
	const XMLCh *name = getElementName(id);
#endif
	NodeMaker makeNode = elementTable[id].makeNode;
	if(makeNode == 0)	// UNKNOWN_ELEMENT.
		return;

	// Walk through the node's children. Check each ELEMENT node's
	// tag to see if it matches name. If it does, create a new
	// votNode for it and append to list.
	if((children_ != 0) && ((nc = children_->getLength()) > 0))
	{	for(unsigned int i=0; i < nc; i++)
		{ DOMNode *node = children_->item(i);
			if(node->getNodeType() == DOMNode::ELEMENT_NODE)
			{DOMElement *e = dynamic_cast<DOMElement *>(node);
				if(tagsMatch(e, name))
				{	votNode *n = makeNode(this, e);
					if(n != 0)
						nodeList->append_(n);
				}
			}
		}
	}
	return;
}
////////////////////////////////////////////////////////////////

// Return the ASCII string giving this node's type. (INFO, PARAM, etc).
const char *votNode::nodeTypeName()const
{
	return elementTable[nodeType_].name;
}


const char *votNode::getAttributeString(votNode::ATTRIBUTE id)
{
	if(id >= NUMATTRIBUTES)
		id = UNKNOWN_ATTRIBUTE;
	return attributeTable[id].name;
}

const char *votNode::getElementString(votNode::ELEMENT id)
{
	if(id >= NUMELEMENTS)
		id = UNKNOWN_ELEMENT;

	return elementTable[id].name;
}

const char *votNode::getPrimitiveString(votNode::PRIMITIVE id)
{
	if(id >= NUMPRIMITIVES)
		id = UNKNOWN_PRIMITIVE;
	return primitiveTable[id].name;
}

// Returns true if node e's tag matches 'id'.
bool votNode::nodeCheck(const votNode *parent, DOMElement *e,
			votNode::ELEMENT id)
{
	if((parent == 0) || (e == 0))
		return false;
	const XMLCh *tag = getElementName(id);
	if(tagsMatch(e, tag))
		return true;
	else
		return false;
}

// Return the node's value.
// This is not the "node's" value, but the value of the first child.
// ( Useful for things like "ELEMENT TD (#PCDATA)")
const XMLCh *votNode::getNodeValue()const
{ const XMLCh *v=0;

	if(node_ != 0)
	{ DOMNode *child = node_->getFirstChild();
		if(child != 0)
			v = child->getNodeValue();
	}
	return v;
}

// Return the node's name.
const XMLCh *votNode::getNodeName()const
{ const XMLCh *v=0;

	if(node_ != 0)
		v = node_->getNodeName();
	return v;
}

// Just prints the node name. "<NAME>"
// (This function never gets called).
void votNode::printNode(ostream &os)const
{
	os << "votNode::printNode called: ";
	printNodeBegin(os);
	os << endl;
}

// Begin printing a node.
// Prints either "<NAME>" or "<NAME".
void votNode::printNodeBegin(ostream &os, bool close)const
{
	os << "<" << elementTable[nodeType_].name;
	if(close)
		os << ">";
}

// Finish printing a node.
// Prints "/>" or "</NAME>". Then a new line.
void votNode::printNodeEnd(ostream &os, bool shortform)const
{
	if(shortform)
		os << "/>";
	else
		os << "</" << elementTable[nodeType_].name << ">";
	os << endl;
}

// Prints the node's type name.
// (Used when debugging).
void votNode::printTypeName(ostream &os, bool begin)const
{
	if(begin)
		os << "<";
	else
		os << "</";
	os << elementTable[nodeType_].name;
}

// Prints cmnt as a comment. Does not check for validity. (eg. "--" is
// an error.
void votNode::printComment(ostream &os, const char *cmnt)
{
	if(cmnt)
	{	os << "<!-- " << cmnt << " -->" << endl;
	}
}

void votNode::startComment(ostream &os)
{
	os << "\n<!-- ";
}

void votNode::endComment(ostream &os)
{
	os << " -->" << endl;
}

ostream& operator<< (ostream& os, const votNode &n)
{
	n.printNode(os);
	return os;
}

ostream& operator<< (ostream& os, const votNode *n)
{
	if(n != 0)
		n->printNode(os);
	return os;
}

////////////////////////////////////////////////////////////////
///		string to binary conversion
////////////////////////////////////////////////////////////////

void votNode::XMLChToString(const XMLCh *str, string &rtn)
{
	if(str != 0)
	{char *s = XMLString::transcode(str);
		if(s != 0)
		{	rtn = s;
			delete [] s;
		}
		else
			rtn = "";
	}
	else
		rtn = "";
}

void votNode::XMLChToBool(const XMLCh *str, bool &value)
{ string s;
	XMLChToString(str, s);

	// Check the first char
//	switch(*s.chars()) {
	switch(s[0]) {
	case 'T':
	case 't':
	case '1':
		value = true;
		break;
	case 'F':
	case 'f':
	case '0':
		value = false;
		break;
	case '?':		// 'NULL' value. What to do??
	case ' ':
		break;
	default:
		break;
	}
}

void votNode::XMLChToLong(const XMLCh *str, Long &value)
{ string s;
	XMLChToString(str, s);
//	value = strtol(s.chars(), 0, 0);
	value = strtol(s.c_str(), 0, 0);
}

void votNode::XMLChToInt(const XMLCh *str, Int &value)
{ long v;

	XMLChToLong(str, v);
	value = (int)v;
}

void votNode::XMLChToShort(const XMLCh *str, Short &value)
{ long v;

	XMLChToLong(str, v);
	value = (short)v;
}

void votNode::XMLChTouByte(const XMLCh *str, unsigned char &value)
{ long v;

	XMLChToLong(str, v);
	value = (unsigned char)v;
}

void votNode::XMLChTouLong(const XMLCh *str, uLong &value)
{ string s;
	XMLChToString(str, s);
	value = strtoul(s.c_str(), 0, 0);
}

void votNode::XMLChTouInt(const XMLCh *str, uInt &value)
{ uLong v;

	XMLChTouLong(str, v);
	value = (uInt)v;
}

void votNode::XMLChToDouble(const XMLCh *str, Double &value)
{ string s;
	XMLChToString(str, s);
	value = strtod(s.c_str(), 0);
}

void votNode::XMLChToFloat(const XMLCh *str, Float &value)
{ Double v;

	XMLChToDouble(str, v);
	value = (Float)v;
}

	// Complex //
void votNode::XMLChToComplex(const XMLCh *str, Complex &value)
{ uInt nelems;
  Float *f = XMLChToFloatArray(str, nelems);

	if(nelems == 1)
		value = f[0];
	else
	if(nelems > 1)
	{ Complex v(f[0], f[1]);
		value = v;
	}
	delete [] f;
}

void votNode::XMLChToDoubleComplex(const XMLCh *str, DComplex &value)
{ uInt nelems;
  Double *d = XMLChToDoubleArray(str, nelems);

	if(nelems == 1)
		value = d[0];
	else
	if(nelems > 1)
	{ DComplex v(d[0], d[1]);
		value = v;
	}
	delete [] d;
}

//////////////// XMLCh * to array ////////////////

Long *votNode::XMLChToLongArray(const XMLCh *value, uInt &nelems)
{ Long *bufr =0;
  BaseRefVectorOf<XMLCh> *xvec = XMLString::tokenizeString(value);

	nelems = xvec->size();
	if(nelems > 0)
	{	bufr = new Long[nelems];
		for(uInt i=0; i< nelems; i++)
			votNode::XMLChToLong(xvec->elementAt(i), bufr[i]);
	}
	delete xvec;
	return bufr;
}

bool *votNode::XMLChToBoolArray(const XMLCh *value, uInt &nelems)
{ bool *bufr =0;
  BaseRefVectorOf<XMLCh> *xvec = XMLString::tokenizeString(value);

	nelems = xvec->size();
	if(nelems > 0)
	{	bufr = new bool[nelems];
		for(uInt i=0; i< nelems; i++)
			votNode::XMLChToBool(xvec->elementAt(i), bufr[i]);
	}
	delete xvec;
	return bufr;
}

uLong *votNode::XMLChTouLongArray(const XMLCh *value, uInt &nelems)
{ uLong *bufr =0;
  BaseRefVectorOf<XMLCh> *xvec = XMLString::tokenizeString(value);

	nelems = xvec->size();
	if(nelems > 0)
	{	bufr = new uLong[nelems];
		for(uInt i=0; i< nelems; i++)
			votNode::XMLChTouLong(xvec->elementAt(i), bufr[i]);
	}
	delete xvec;
	return bufr;
}

Int *votNode::XMLChToIntArray(const XMLCh *value, uInt &nelems)
{ Int *bufr =0;
  BaseRefVectorOf<XMLCh> *xvec = XMLString::tokenizeString(value);

	nelems = xvec->size();
	if(nelems > 0)
	{	bufr = new Int[nelems];
		for(uInt i=0; i< nelems; i++)
			votNode::XMLChToInt(xvec->elementAt(i), bufr[i]);
	}
	delete xvec;
	return bufr;
}

uInt *votNode::XMLChTouIntArray(const XMLCh *value, uInt &nelems)
{ uInt *bufr =0;
  BaseRefVectorOf<XMLCh> *xvec = XMLString::tokenizeString(value);

	nelems = xvec->size();
	if(nelems > 0)
	{	bufr = new uInt[nelems];
		for(uInt i=0; i< nelems; i++)
			votNode::XMLChTouInt(xvec->elementAt(i), bufr[i]);
	}
	delete xvec;
	return bufr;
}

Short *votNode::XMLChToShortArray(const XMLCh *value, uInt &nelems)
{ Short *bufr =0;
  BaseRefVectorOf<XMLCh> *xvec = XMLString::tokenizeString(value);

	nelems = xvec->size();
	if(nelems > 0)
	{	bufr = new Short[nelems];
		for(uInt i=0; i< nelems; i++)
			votNode::XMLChToShort(xvec->elementAt(i), bufr[i]);
	}
	delete xvec;
	return bufr;
}

unsigned char *votNode::XMLChTouByteArray(const XMLCh *value, uInt &nelems)
{ unsigned char *bufr =0;
  BaseRefVectorOf<XMLCh> *xvec = XMLString::tokenizeString(value);

	nelems = xvec->size();
	if(nelems > 0)
	{	bufr = new unsigned char[nelems];
		for(uInt i=0; i< nelems; i++)
			votNode::XMLChTouByte(xvec->elementAt(i), bufr[i]);
	}
	delete xvec;
	return bufr;
}

Float *votNode::XMLChToFloatArray(const XMLCh *value, uInt &nelems)
{ Float *bufr =0;
  BaseRefVectorOf<XMLCh> *xvec = XMLString::tokenizeString(value);

	nelems = xvec->size();
	if(nelems > 0)
	{	bufr = new Float[nelems];
		for(uInt i=0; i< nelems; i++)
			votNode::XMLChToFloat(xvec->elementAt(i), bufr[i]);
	}
	delete xvec;
	return bufr;
}

Double *votNode::XMLChToDoubleArray(const XMLCh *value, uInt &nelems)
{ Double *bufr =0;
  BaseRefVectorOf<XMLCh> *xvec = XMLString::tokenizeString(value);

	nelems = xvec->size();
	if(nelems > 0)
	{	bufr = new Double[nelems];
		for(uInt i=0; i< nelems; i++)
			votNode::XMLChToDouble(xvec->elementAt(i), bufr[i]);
	}
	delete xvec;
	return bufr;
}

Complex *votNode::XMLChToComplexArray(const XMLCh *value, uInt &nelems)
{ Complex *bufr =0;
  BaseRefVectorOf<XMLCh> *xvec = XMLString::tokenizeString(value);
  uInt length, len;

	length = xvec->size();
	if(length > 0)
	{	len = length & ~1;	// Make sure its even.
	  	nelems = len/2;
		if(len != length)
			nelems += 1;	// Just a trailing real part at end.
		bufr = new Complex[nelems];

		for(uInt j=0,i=0; i< len; i += 2, j++)
		{ float re, im;
			votNode::XMLChToFloat(xvec->elementAt(i), re);
		  	votNode::XMLChToFloat(xvec->elementAt(i+1), im);
		  Complex v(re, im);
			bufr[j] = v;
		}
		if(len < length)
		{ Float re;
			votNode::XMLChToFloat(xvec->elementAt(len), re);
			bufr[nelems-1] = re;
		}
	}
	else
		nelems = 0;
	delete xvec;
	return bufr;
}

DComplex *votNode::XMLChToDoubleComplexArray(const XMLCh *value, uInt &nelems)
{ DComplex *bufr =0;
  BaseRefVectorOf<XMLCh> *xvec = XMLString::tokenizeString(value);
  uInt length, len;

	length = xvec->size();
	if(length > 0)
	{	len = length & ~1;	// Make sure its even.
	  	nelems = len/2;
		if(len != length)
			nelems += 1;	// Just a trailing real part at end.
		bufr = new DComplex[nelems];

		for(uInt j=0,i=0; i< len; i += 2, j++)
		{ Double re, im;
			votNode::XMLChToDouble(xvec->elementAt(i), re);
		  	votNode::XMLChToDouble(xvec->elementAt(i+1), im);
		  DComplex v(re, im);
			bufr[j] = v;
		}
		if(len < length)
		{ Double re;
			votNode::XMLChToDouble(xvec->elementAt(len), re);
			bufr[nelems-1] = re;
		}
	}
	else
		nelems = 0;
	delete xvec;
	return bufr;
}

////////////////////////////////////////////////////////////////

// A votNode that can have attributes.
votAttributeNode::votAttributeNode(const votNode *parent, DOMElement *node,
				   votNode::ELEMENT nt)
	: votNode(parent, node, nt), description_(0)
{
	// Pick up the description if it exists.
//	description_ = (votDescription *)getChildByTagID(votNode::DESCRIPTION);
	description_ = dynamic_cast<votDescription *>
			(getChildByTagID(votNode::DESCRIPTION));
	// If this is a VOTable node, necessary tables haven't been setup
	// yet, so let its constructor handle these.
	if(nt != votNode::VOTABLE)
	{	checkForID();
	}
}

votAttributeNode::~votAttributeNode()
{
	if(description_ != 0)
		delete(description_);
}

// If an ID attribute exists, log it.
void votAttributeNode::checkForID()
{ const XMLCh *ID = id();
	if(ID != 0)
		rootNode()->addID(ID, this);
}

const XMLCh *votAttributeNode::getAttributeByName(const XMLCh *name)const
{ const XMLCh *attr = 0;

	// Don't use node_->getAttribute() since it returns an empty
	// string.
	if(node_ != 0)
	{ DOMAttr *attrnode = node_->getAttributeNode(name);
		if(attrnode != 0)
			attr = attrnode->getValue();
	}
	return attr;
}

const XMLCh *votAttributeNode::getAttributeByID(votNode::ATTRIBUTE id)const
{const XMLCh *name;
 const XMLCh *attr=0;
#if 0
 VOTable *root = rootNode();

	if(root != 0)
	{	name = getAttributeName(id);
		attr = getAttributeByName(name);
	}
#else
	name = getAttributeName(id);
	attr = getAttributeByName(name);
#endif
	return attr;
}

const XMLCh *votAttributeNode::id()const
{
	return getAttributeByID(votNode::ID);
}

const XMLCh *votAttributeNode::name()const
{
	return getAttributeByID(votNode::NAME);
}

const XMLCh *votAttributeNode::value()const
{
	return getAttributeByID(votNode::VALUE);
}

const XMLCh *votAttributeNode::ref()const
{
	return getAttributeByID(votNode::REF);
}

void votAttributeNode::getID(string &str)const
{	XMLChToString(id(), str);
}

void votAttributeNode::getName(string &str)const
{	XMLChToString(name(), str);
}

void votAttributeNode::getValue(string &str)const
{	XMLChToString(value(), str);
}

void votAttributeNode::getRef(string &str)const
{	XMLChToString(ref(), str);
}

// Print the name, "<NAME" followed by any attributes.
// If close is true, there is nothing else to print and the string
// will be ended with "/>". Otherwise, just ">".
// Regardless of close's state, if there is a description, it will
// be printed and the initial string not closed.
void votAttributeNode::printNodeBegin(ostream &os, bool close)const
{
	if(node_ == 0)
		return;
	DOMNamedNodeMap *attrs = node_->getAttributes();
	if(attrs == 0)
		return;
	uInt na = attrs->getLength();

	votNode::printNodeBegin(os, false);
	// Print each attribute in the list rather than each attribute
	// that SHOULD be in the list.
	votAttributeNode *reference = 0;

	if(na > 0)
	{ XMLCh *ref = XMLString::transcode("ref");

		for(uInt i=0; i < na; i++)
		{ DOMNode *node = attrs->item(i);
		  const XMLCh *name = node->getNodeName();
		  const XMLCh *value = node->getNodeValue();
			os << " " << name
			   << "=\"" << value << "\"";
			if(XMLString::compareString(ref, name)==0)
			{
				reference = rootNode()->idMap()->item(value);
			}
		}
	}

	if(reference && printReferences())
	{const XMLCh *rn = reference->getNodeName();
		startComment(os);
		os << "Refers to node " << rn;
		endComment(os);
	}

	if(close && (description_ == 0))
		printNodeEnd(os, true);
	else
		os << ">";

	if(description_)
	{	os << endl;
		description_->printNode(os);
	}
}

votAttributeList *votAttributeNode::getAttributes()const
{
	return new votAttributeList((DOMElement *)node_);
}


// If the node has no children.
void votAttributeNode::printNode(ostream &os)const
{
	printNodeBegin(os, true);
}

ostream& operator<< (ostream& os, const votAttributeNode &n)
{
	n.printNode(os);
	return os;
}

ostream& operator<< (ostream& os, const votAttributeNode *n)
{
	if(n != 0)
		n->printNode(os);
	return os;
}

/////////////////////////////////////////////////////////////////////////
////			Node elements callers see.
/////////////////////////////////////////////////////////////////////////

votCOOSYS::~votCOOSYS()
{
}

const XMLCh *votCOOSYS::equinox()const
{
	return getAttributeByID(VOTable::EQUINOX);
}

const XMLCh *votCOOSYS::epoch()const
{
	return getAttributeByID(VOTable::EPOCH);
}

const XMLCh *votCOOSYS::system()const
{
	return getAttributeByID(VOTable::SYSTEM);
}


void votCOOSYS::getEquinox(string &s)const
{
	XMLChToString(equinox(), s);
}

void votCOOSYS::getEpoch(string &s)const
{
	XMLChToString(epoch(), s);
}

void votCOOSYS::getSystem(string &s)const
{
	XMLChToString(system(), s);
}

votNode *votCOOSYS::makeNode(const votNode *parent, DOMElement *node)
{ votCOOSYS *nn = 0;

	if(nodeCheck(parent, node, votNode::COOSYS))
		nn = new votCOOSYS(parent, node);

	return nn;
}

void votCOOSYS::printNode(ostream &os)const
{
	votAttributeNode::printNode(os);
}

////////////////////////////////////////////////////////////////

votStream::~votStream()
{
}

const XMLCh *votStream::type()const
{
	return getAttributeByID(VOTable::TYPE);
}

const XMLCh *votStream::href()const
{
	return getAttributeByID(VOTable::HREF);
}

const XMLCh *votStream::actuate()const
{
	return getAttributeByID(VOTable::ACTUATE);
}

const XMLCh *votStream::encoding()const
{
	return getAttributeByID(VOTable::ENCODING);
}

const XMLCh *votStream::expires()const
{
	return getAttributeByID(VOTable::EXPIRES);
}

const XMLCh *votStream::rights()const
{
	return getAttributeByID(VOTable::RIGHTS);
}

votNode *votStream::makeNode(const votNode *parent, DOMElement *node)
{ votStream *nn = 0;

	if(nodeCheck(parent, node, votNode::STREAM))
		nn = new votStream(parent, node);

	return nn;
}

void votStream::printNode(ostream &os)const
{
	printNodeBegin(os);
	printNodeEnd(os);
}
////////////////////////////////////////////////////////////////

votBinary::votBinary(const votNode *parent, DOMElement *node) :
		     votNode(parent, node, votNode::BINARY)
{
//	stream_ = (votStream *)getChildByTagID(votNode::STREAM);
	stream_ = dynamic_cast<votStream *>(getChildByTagID(votNode::STREAM));
}

votBinary::~votBinary()
{
	if(stream_ != 0)
		delete stream_;
}

votNode *votBinary::makeNode(const votNode *parent, DOMElement *node)
{ votBinary *nn = 0;

	if(nodeCheck(parent, node, votNode::BINARY))
		nn = new votBinary(parent, node);

	return nn;
}


void votBinary::printNode(ostream &os)const
{
	printNodeBegin(os);
	if(stream_)
		stream_->printNode(os);
	printNodeEnd(os);
}
////////////////////////////////////////////////////////////////

votFITS::~votFITS()
{
}

const XMLCh *votFITS::extnum()const
{
	return getAttributeByID(VOTable::EXTNUM);
}

votNode *votFITS::makeNode(const votNode *parent, DOMElement *node)
{ votFITS *nn = 0;

	if(nodeCheck(parent, node, votNode::FITS))
		nn = new votFITS(parent, node);

	return nn;
}

void votFITS::printNode(ostream &os)const
{
	printNodeBegin(os);
	printNodeEnd(os);
}
////////////////////////////////////////////////////////////////

votTD::~votTD()
{
}

votNode *votTD::makeNode(const votNode *parent, DOMElement *node)
{ votTD *nn = 0;

	if(nodeCheck(parent, node, votNode::TD))
		nn = new votTD(parent, node);

	return nn;
}

void votTD::printNode(ostream &os)const
{
	printNodeBegin(os);
	 os << node_->getFirstChild()->getNodeValue();
	printNodeEnd(os);
}
////////////////////////////////////////////////////////////////

votTR::votTR(const votNode *parent, DOMElement *node) :
	     votNode(parent, node, votNode::TR)
{
	// There should be at least one TD in the list.
	tdList_ = new votTDList();
	getNodesByTagID(votNode::TD, tdList_);
}

votTR::~votTR()
{
	if(tdList_ != 0)
		delete tdList_;
}

votNode *votTR::makeNode(const votNode *parent, DOMElement *node)
{ votTR *nn = 0;

	if(nodeCheck(parent, node, votNode::TR))
		nn = new votTR(parent, node);

	return nn;
}

void votTR::printNode(ostream &os)const
{
	printNodeBegin(os);
	 PrintList(os, tdList_);
	printNodeEnd(os);
}
////////////////////////////////////////////////////////////////

votTableData::votTableData(const votNode *parent, DOMElement *node):
			   votNode(parent, node, votNode::TABLEDATA)
{
	rowList_ = new votTRList();
	getNodesByTagID(votNode::TR, rowList_);
}

votTableData::~votTableData()
{
	if(rowList_ != 0)
		delete rowList_;
}

votNode *votTableData::makeNode(const votNode *parent, DOMElement *node)
{ votTableData *nn = 0;

	if(nodeCheck(parent, node, votNode::TABLEDATA))
		nn = new votTableData(parent, node);

	return nn;
}

void votTableData::printNode(ostream &os)const
{
	printNodeBegin(os);
	 PrintList(os, rowList_);
	printNodeEnd(os);
}
////////////////////////////////////////////////////////////////

votData::votData(const votNode *parent, DOMElement *node) :
		 votNode(parent, node, votNode::DATA)
{
//	tableData_ = (votTableData *)getChildByTagID(votNode::TABLEDATA);
	tableData_ = dynamic_cast<votTableData *>
			(getChildByTagID(votNode::TABLEDATA));
//	binary_  = (votBinary *)getChildByTagID(votNode::BINARY);
	binary_  = dynamic_cast<votBinary *>(getChildByTagID(votNode::BINARY));
//	fits_	 = (votFITS *)getChildByTagID(votNode::FITS);
	fits_	 = dynamic_cast<votFITS *>(getChildByTagID(votNode::FITS));
}

votData::~votData()
{
	if(tableData_ != 0)
		delete tableData_;
	if(binary_ != 0)
		delete binary_;
	if(fits_ != 0)
		delete fits_;
}

votNode *votData::makeNode(const votNode *parent, DOMElement *node)
{ votData *nn = 0;

	if(nodeCheck(parent, node, votNode::DATA))
		nn = new votData(parent, node);

	return nn;
}

void votData::printNode(ostream &os)const
{
	printNodeBegin(os);
	 PrintNode(os, tableData_);
	 PrintNode(os, binary_);
	 PrintNode(os, fits_);
	printNodeEnd(os);
}
////////////////////////////////////////////////////////////////

votLink::~votLink()
{
}

votNode *votLink::makeNode(const votNode *parent, DOMElement *node)
{ votLink *nn = 0;

	if(nodeCheck(parent, node, votNode::LINK))
		nn = new votLink(parent, node);

	return nn;
}

void votLink::printNode(ostream &os)const
{
	votAttributeNode::printNode(os);
}

const XMLCh *votLink::content_role()const
{	return getAttributeByID(VOTable::CONTENT_ROLE);
}

const XMLCh *votLink::content_type()const
{	return getAttributeByID(VOTable::CONTENT_TYPE);
}

const XMLCh *votLink::title()const
{	return getAttributeByID(VOTable::TITLE);
}

const XMLCh *votLink::href()const
{	return getAttributeByID(VOTable::HREF);
}

const XMLCh *votLink::gref()const
{	return getAttributeByID(VOTable::GREF);
}

const XMLCh *votLink::action()const
{	return getAttributeByID(VOTable::ACTION);
}

void votLink::getContent_role(string &s)const
{	XMLChToString(content_role(), s);
}

void votLink::getContent_type(string &s)const
{	XMLChToString(content_type(), s);
}

void votLink::getTitle(string &s)const
{	XMLChToString(title(), s);
}

void votLink::getHref(string &s)const
{	XMLChToString(href(), s);
}

void votLink::getGref(string &s)const
{	XMLChToString(gref(), s);
}

void votLink::getAction(string &s)const
{	XMLChToString(action(), s);
}


////////////////////////////////////////////////////////////////

votOption::votOption(const votNode *parent, DOMElement *node) :
		votAttributeNode(parent, node, votNode::OPTION)
{
	optionList_ = new votOptionList();
	getNodesByTagID(votNode::OPTION, optionList_);
}

votOption::~votOption()
{
	delete optionList_;
}

votNode *votOption::makeNode(const votNode *parent, DOMElement *node)
{ votOption *nn = 0;

	if(nodeCheck(parent, node, votNode::OPTION))
		nn = new votOption(parent, node);

	return nn;
}

void votOption::printNode(ostream &os)const
{
	if(optionList_ == 0)
		votAttributeNode::printNode(os);
	else
	{	printNodeBegin(os);
		 PrintList(os, optionList_);
		printNodeEnd(os);
	}
}
////////////////////////////////////////////////////////////////

votMinMaxNode::~votMinMaxNode()
{
}

votNode *votMinMaxNode::makeNode(const votNode *parent, DOMElement *node)
{ votMinMaxNode *nn = 0;

	if(nodeCheck(parent, node, votNode::MIN))
		nn = new votMinMaxNode(parent, node, votNode::MIN);
	else
	if(nodeCheck(parent, node, votNode::MAX))
		nn = new votMinMaxNode(parent, node, votNode::MAX);

	return nn;
}

void votMinMaxNode::printNode(ostream &os)const
{
	votAttributeNode::printNode(os);
}

const XMLCh *votMinMaxNode::inclusive()const
{	return getAttributeByID(VOTable::INCLUSIVE);
}

void votMinMaxNode::getValue(string &s)const
{
	XMLChToString(value(), s);
}

void votMinMaxNode::getInclusive(string &s)const
{	XMLChToString(inclusive(), s);
}

////////////////////////////////////////////////////////////////

votValues::votValues(const votNode *parent, DOMElement *node) :
		votAttributeNode(parent, node, VOTable::VALUES)
{
	min_ = dynamic_cast<votMinMaxNode*>(getChildByTagID(votNode::MIN));
	max_ = dynamic_cast<votMinMaxNode*>(getChildByTagID(votNode::MAX));
	optionList_ = new votOptionList();
	getNodesByTagID(votNode::OPTION, optionList_);
}

votValues::~votValues()
{
	if(min_ != 0)
		delete min_;
	if(max_ != 0)
		delete max_;
	if(optionList_ != 0)
		delete optionList_;
}

votNode *votValues::makeNode(const votNode *parent, DOMElement *node)
{ votValues *nn = 0;

	if(nodeCheck(parent, node, votNode::VALUES))
		nn = new votValues(parent, node);

	return nn;
}

void votValues::printNode(ostream &os)const
{
	printNodeBegin(os);
	 PrintNode(os, min_);
	 PrintNode(os, max_);
	 PrintList(os, optionList_);
	printNodeEnd(os);
}

const XMLCh *votValues::type()const
{	return getAttributeByID(VOTable::TYPE);
}

const XMLCh *votValues::null()const
{	return getAttributeByID(VOTable::NULLATTR);
}

const XMLCh *votValues::invalid()const
{	return getAttributeByID(VOTable::INVALID);
}

void votValues::getType(string &s)const
{
	XMLChToString(type(), s);
}

void votValues::getNull(string &s)const
{
	XMLChToString(null(), s);
}

void votValues::getInvalid(string &s)const
{
	XMLChToString(invalid(), s);
}

////////////////////////////////////////////////////////////////

votField::votField(const votNode *parent, DOMElement *node) :
		   votAttributeNode(parent, node, votNode::FIELD)
{
	initField();
}

votField::votField(const votNode *parent, DOMElement *node,
		   votNode::ELEMENT id): votAttributeNode(parent, node, id)
{
	initField();
}

votField::~votField()
{
	if(valuesList_ != 0)
		delete valuesList_;
	if(linkList_ != 0)
		delete linkList_;
}

void votField::initField()
{
	valuesList_ = new votValuesList();
	getNodesByTagID(votNode::VALUES, valuesList_);
	linkList_ = new votLinkList();
	getNodesByTagID(votNode::LINK, linkList_);
}

const XMLCh *votField::unit()const
{	return getAttributeByID(votNode::UNIT);
}

const XMLCh *votField::datatype()const
{	return getAttributeByID(votNode::DATATYPE);
}

const XMLCh *votField::precision()const
{	return getAttributeByID(votNode::PRECISION);
}

const XMLCh *votField::width()const
{	return getAttributeByID(votNode::WIDTH);
}

const XMLCh *votField::ucd()const
{	return getAttributeByID(votNode::UCD);
}

const XMLCh *votField::arraysize()const
{	return getAttributeByID(votNode::ARRAYSIZE);
}

const XMLCh *votField::type()const
{	return getAttributeByID(votNode::TYPE);
}

void votField::getUnit(string &s)const
{	XMLChToString(unit(), s);
}

void votField::getDatatype(string &s)const
{	XMLChToString(datatype(), s);
}

void votField::getPrecision(string &s)const
{	XMLChToString(precision(), s);
}

void votField::getWidth(string &s)const
{	XMLChToString(width(), s);
}

void votField::getUCD(string &s)const
{	XMLChToString(ucd(), s);
}

void votField::getArraySize(string &s)const
{	XMLChToString(arraysize(), s);
}

void votField::getType(string &s)const
{	XMLChToString(type(), s);
}

votNode *votField::makeNode(const votNode *parent, DOMElement *node)
{ votField *nn = 0;

	if(nodeCheck(parent, node, votNode::FIELD))
		nn = new votField(parent, node);

	return nn;
}

void votField::printNode(ostream &os)const
{
	printNodeBegin(os);
	 PrintList(os, valuesList_);
	 PrintList(os, linkList_);
	printNodeEnd(os);
}
////////////////////////////////////////////////////////////////

votTable::votTable(const votNode *parent, DOMElement *node) :
		  votAttributeNode(parent, node, votNode::TABLE)
{
	linkList_ = new votLinkList();
	getNodesByTagID(votNode::LINK, linkList_);
	fieldList_ = new votFieldList();
	getNodesByTagID(votNode::FIELD, fieldList_);
//	data_ = (votData *)getChildByTagID(votNode::DATA);
	data_ = dynamic_cast<votData *>(getChildByTagID(votNode::DATA));
}

votTable::~votTable()
{
	if(linkList_ != 0)
		delete linkList_;
	if(fieldList_ != 0)
		delete fieldList_;
	if(data_)
		delete data_;
}

votNode *votTable::makeNode(const votNode *parent, DOMElement *node)
{ votTable *nn = 0;

	if(nodeCheck(parent, node, votNode::TABLE))
		nn = new votTable(parent, node);

	return nn;
}

void votTable::printNode(ostream &os)const
{
	printNodeBegin(os);
	 PrintList(os, linkList_);
	 PrintList(os, fieldList_);
	PrintNode(os, data_);
	printNodeEnd(os);
}
////////////////////////////////////////////////////////////////

votParam::~votParam()
{
}

votNode *votParam::makeNode(const votNode *parent, DOMElement *node)
{ votParam *nn = 0;

	if(nodeCheck(parent, node, votNode::PARAM))
		nn = new votParam(parent, node);

	return nn;
}

void votParam::printNode(ostream &os)const
{
	votField::printNode(os);
}
////////////////////////////////////////////////////////////////

votInfo::~votInfo()
{
}

votNode *votInfo::makeNode(const votNode *parent, DOMElement *node)
{ votInfo *nn = 0;

	if(nodeCheck(parent, node, votNode::INFO))
		nn = new votInfo(parent, node);

	return nn;
}

void votInfo::printNode(ostream &os)const
{
	votAttributeNode::printNode(os);
}

ostream& operator<<(ostream& os, const votInfo &info)
{
	info.printNode(os);
	return os;
}

////////////////////////////////////////////////////////////////

votDefinition::votDefinition(const votNode *parent, DOMElement *node) :
	votNode(parent, node, votNode::DEFINITIONS)
{
//	coosys_ = (votCOOSYS *) getChildByTagID(votNode::COOSYS);
//	param_ =  (votParam *) getChildByTagID(votNode::PARAM);
	coosys_ = dynamic_cast<votCOOSYS *>(getChildByTagID(votNode::COOSYS));
	param_ =  dynamic_cast<votParam *>(getChildByTagID(votNode::PARAM));
}

votDefinition::~votDefinition()
{
	delete coosys_;
	delete param_;
}

votNode *votDefinition::makeNode(const votNode *parent, DOMElement *node)
{ votDefinition *nn = 0;

	if(nodeCheck(parent, node, votNode::DEFINITIONS))
		nn = new votDefinition(parent, node);

	return nn;
}

ostream& operator<<(ostream& os, const votDefinition &def)
{
	def.printNode(os);
	return os;
}

void votDefinition::printNode(ostream &os)const
{
	printNodeBegin(os);
	 PrintNode(os, coosys_);
	 PrintNode(os, param_);
	printNodeEnd(os);
}

////////////////////////////////////////////////////////////////
// A VOTABLE DESCRIPTION element has 1 child, the description text.
////////////////////////////////////////////////////////////////

votDescription::~votDescription()
{
}

const XMLCh *votDescription::description()const
{	return node_->getFirstChild()->getNodeValue();
}

void votDescription::getDescription(string &s)const
{	XMLChToString(description(), s);
}

votNode *votDescription::makeNode(const votNode *parent, DOMElement *node)
{ votDescription *nn = 0;

	if(nodeCheck(parent, node, votNode::DESCRIPTION))
		nn = new votDescription(parent, node);

	return nn;
}

void votDescription::printNode(ostream &os)const
{
	printNodeBegin(os);
	 os << description();
	printNodeEnd(os);
}
////////////////////////////////////////////////////////////////

votResource::votResource(const votNode *parent, DOMElement *resource) :
			votAttributeNode(parent, resource, votNode::RESOURCE)
{
	infoList_ = new votInfoList();
	getNodesByTagID(votNode::INFO, infoList_);
	coosysList_ = new votCOOSYSList();
	getNodesByTagID(votNode::COOSYS, coosysList_);
	paramList_ = new votParamList();
	getNodesByTagID(votNode::PARAM, paramList_);
	linkList_ = new votLinkList();
	getNodesByTagID(votNode::LINK, linkList_);
	tableList_ = new votTableList();
	getNodesByTagID(votNode::TABLE, tableList_);
	resourceList_ = new votResourceList();
	getNodesByTagID(votNode::RESOURCE, resourceList_);
}

votResource::~votResource()
{
	delete infoList_;
	delete coosysList_;
	delete paramList_;
	delete linkList_;
	delete tableList_;
	delete resourceList_;
}

votNode *votResource::makeNode(const votNode *parent, DOMElement *node)
{ votResource *nn = 0;

	if(nodeCheck(parent, node, votNode::RESOURCE))
		nn = new votResource(parent, node);

	return nn;
}

const XMLCh *votResource::type()const
{
	return getAttributeByID(VOTable::TYPE);
}

void votResource::getType(string &s)const
{	XMLChToString(type(), s);
}

////////////////////////////////////////////////////////////////
ostream& operator<<(ostream& os, const votResource &n)
{
	n.printNode(os);
	return os;
}

void votResource::printNode(ostream &os)const
{
	printNodeBegin(os);

	if(infoList_)
		infoList_->printList(os);
	if(coosysList_)
		coosysList_->printList(os);
	if(paramList_)
		paramList_->printList(os);
	if(linkList_)
		linkList_->printList(os);

	 PrintList(os, tableList_);
	 PrintList(os, resourceList_);
	printNodeEnd(os);
}

////////////////////////////////////////////////////////////////

votDocument::~votDocument()
{
}

const XMLCh *votDocument::XMLversion()const
{	return doc_.getVersion();
}

const XMLCh *votDocument::encoding()const
{	return doc_.getEncoding();
}

bool votDocument::standalone()const
{	return doc_.getStandalone();
}

void votDocument::getXMLVersion(string &v)const
{	votNode::XMLChToString(XMLversion(), v);
}

void votDocument::getEncoding(string &s)const
{	votNode::XMLChToString(encoding(), s);
}

void votDocument::getStandalone(string &s)const
{	s = standalone() ? "yes" : "no";
}

const XMLCh *votDocument::publicId()const
{
	return doc_.getDoctype()->getPublicId();
}

const XMLCh *votDocument::systemId()const
{
	return doc_.getDoctype()->getSystemId();
}

const XMLCh *votDocument::internalSubset()const
{
	return doc_.getDoctype()->getInternalSubset();
}

void votDocument::getPublicId(string &s)const
{
	votNode::XMLChToString(publicId(), s);
}

void votDocument::getSystemId(string &s)const
{
	votNode::XMLChToString(systemId(), s);
}

void votDocument::getInternalSubset(string &s)const
{
	votNode::XMLChToString(internalSubset(), s);
}

////////////////////////////////////////////////////////////////
VOTable::VOTable(DOMElement *documentElement, XercesDOMParser *parser) :
	votAttributeNode(0, documentElement, votNode::VOTABLE), parser_(parser)
{
	init();
	// Has to be done after init so can't be done in constructor
	// for votAttributeNode.
	checkForID();

	document_ = new votDocument(*parser->getDocument());

	// And then the rest.
	definitionsList_ = new votDefinitionsList();
//cout << "DEFINITIONS LIST = " << (void *) definitionsList_ << endl;

	getNodesByTagID(VOTable::DEFINITIONS, definitionsList_);
//cout << "DEFINITIONS \n";
//	PrintList(cout, definitionsList_);

	infoList_ =  new votInfoList();
	getNodesByTagID(VOTable::INFO, infoList_);

	resourceList_ = new votResourceList();
	getNodesByTagID(VOTable::RESOURCE, resourceList_);
}

VOTable::~VOTable()
{
	if(definitionsList_ != 0)
		delete definitionsList_;

	delete document_;
	if(infoList_ != 0)
		delete infoList_;
	if(resourceList_ != 0)
		delete resourceList_;
}

void VOTable::init()
{
//	parser_ = 0;	// Set by makeVOTable.
	idMap_ = new votNodeMap();
}

void VOTable::addID(const XMLCh *id, votAttributeNode *node)
{
	idMap_->add(id, node);
#if 0
	  cout << "ID is: |" << id << "| len= " <<
		XMLString::stringLen(id) << endl;
#endif
}

static votNode *dummymakeNode(const votNode *, DOMElement *)
{
	// Probably should never be called.
	cout << "dummy VOTable::makeNode called.\n";
	return 0;
}


#if 0
votNode *VOTable::makeNode(const votNode */*parent*/, DOMElement *node)
{ VOTable *nn = 0;

	// Probably should never be called.
	cout << "VOTable::makeNode called.\n";

	// Can't use nodeCheck, since tables won't be initialized.
	const char *name = elementTable[VOTable::VOTABLE].name;
	const XMLCh *tag = XMLString::transcode(name);
	delete [] name;

	if(tagsMatch(node, tag))
		nn = new VOTable(node);

	return nn;
}
#endif

VOTable *VOTable::makeVOTable(DOMDocument *doc, XercesDOMParser *parser)
{
	if(doc == 0)
		return 0;

	const char *name = elementTable[VOTable::VOTABLE].name;
	const XMLCh *tag = XMLString::transcode(name);

	VOTable *nn = 0;
	DOMDocumentType *dt = doc->getDoctype();
	if(dt == 0)
		return 0;
	const XMLCh *dtn = dt->getName();
	if(XMLString::compareString(tag, dtn) == 0)
	{ DOMElement *e = doc->getDocumentElement();
		nn = new VOTable(e, parser);
	}
	return nn;
}

static const char *tf(bool s)
{	return (s) ? "True" : "False";
}

static void pb(ostream &os, const char *str, bool val)
{
	if(str != 0)
		os << str << "\t - " << tf(val) << endl;
}

void VOTable::printParserGets(ostream &os, const XercesDOMParser *p)
{
	if(p == 0)
	{	os << "Parser is NULL.\n";
		return;
	}
	os << "DoNamespaces\t- " << tf(p->getDoNamespaces()) << endl;
	os << "DoSchema\t- " << tf(p->getDoSchema()) << endl;
	os << "DoValidation\t- " << tf(p->getDoValidation()) << endl;

 	pb(os, "ValidationSchemaFullChecking",
	   p->getValidationSchemaFullChecking());

	os << "Error Count\t - " << p->getErrorCount() << endl;
	os << "ExitOnFirstError\t - " << tf(p->getExitOnFirstFatalError())
		<< endl;

	pb(os, "ValidationConstraintFatal",
	   p->getValidationConstraintFatal());

	pb(os, "CreateEntityReferenceNodes",
	   p->getCreateEntityReferenceNodes());

	pb(os, "IncludeIgnorableWhitespace",
	   p->getIncludeIgnorableWhitespace());

	os << "ExpandEntityReferences\t- "
	   << tf(p->getExpandEntityReferences()) << endl;

	pb(os, "ExternalNoNamespaceSchemaLocation",
	   p->getExternalNoNamespaceSchemaLocation());

	os << "ExternalSchemaLocation\t - " << p->getExternalSchemaLocation()
	   << endl;

	os << "ExternalNoNamespaceSchemaLocation\t- "
	   << p->getExternalNoNamespaceSchemaLocation() << endl;

	pb(os, "LoadExternalDTD",
	   p->getLoadExternalDTD());
	pb(os, "CreateCommentNodes",
	   p->getCreateCommentNodes());
	pb(os, "CalculateSrcOfs",
	   p->getCalculateSrcOfs());
	pb(os, "StandardUriConformant",
	   p->getStandardUriConformant());

}

VOTable *VOTable::makeVOTable(const char *xmlFile)
{ VOTableParserArgs pa;
	return makeVOTable(xmlFile, pa); 
}

VOTable *VOTable::makeVOTable(const char *xmlFile,
			      const VOTableParserArgs &args)
{ XercesDOMParser *parser = 0;

	// Initialize Xerces.
	try {
		XMLPlatformUtils::Initialize();
	}
	catch (const XMLException &toCatch)
	{	cout << "Error during init:\n"
		     << toCatch.getMessage() << "\n";
		throw;
	}

	parser = new XercesDOMParser();

	try {
		args.setParserArgs(parser);
//		printParserStats(cout, parser);
		parser->parse(xmlFile);
//		printParserGets(cout, parser);
	}
	catch (const XMLException &xmlerr)
	{	cerr << "Parse error for: " << xmlFile << " \n"
		     << xmlerr.getMessage() << endl;
		throw;
	}

//	cout << "No parse error for:" << xmlFile << endl;

	try {
		DOMDocument *doc = parser->getDocument();
		VOTable *table = makeVOTable(doc, parser);
		return table;
	}
	catch (const XMLException &xmlerr)
	{	cerr << "Could not make VOTable for: " << xmlFile << endl;
		cerr << xmlerr.getMessage() << endl;
		return 0;
	}
}

const XMLCh *VOTable::version()const
{	return getAttributeByID(votNode::VERSION);
}

void VOTable::getVersion(string &s)const
{	votNode::XMLChToString(version(), s);
}

void VOTable::printNode(ostream &os)const
{
	// XML header
	os << "<?xml version=\"" << document_->XMLversion() << "\" "
	   << " encoding=\"" << document_->encoding() << "\" "
	   << "standalone=\"" << ((document_->standalone()) ? "yes" : "no")
	   << "\""
	   << "?>\n";

	printNodeBegin(os);

#if 0
	if(definitions_ != 0)
		definitions_->printNode(os);
#else
	if(definitionsList_ != 0)
		definitionsList_->printList(os);
#endif
	if(infoList_ != 0)
		infoList_->printList(os);
	if(resourceList_ != 0)
		resourceList_->printList(os);

	printNodeEnd(os);
}

////////////////////////////////////////////////////////////////
votAttributeList::votAttributeList(DOMElement *e)
{	if(e)
	{	list_ = e->getAttributes();
	}
	else
		list_ = 0;
}

votAttributeList::~votAttributeList()
{
	if(list_)
	  {//	delete list_;  // Causes core dumps!!??
		list_ = 0;
	}
}

uInt votAttributeList::numAttributes()const
{ uInt n = 0;
	if(list_)
		n = list_->getLength();

	return n;
}

// Returns the name/value pair for attribute for the index.
// Returns false if no attribute matches the index.
bool votAttributeList::getAttribute(uInt index,
				    string &name, string &value)const
{ bool found = false;

	if(list_)
	{uInt len = list_->getLength();
		if(index < len)
		{ DOMNode *node = list_->item(index);
		  const XMLCh *xmlname = node->getNodeName();
		  const XMLCh *xmlvalue = node->getNodeValue();
//		  const char *namestr = XMLString::transcode(xmlname);
//		  const char *valuestr = XMLString::transcode(xmlvalue);

			name = XMLString::transcode(xmlname);
			value = XMLString::transcode(xmlvalue);
#if 0
			cout << "Attr: " << index << " name=" << name
			     << " value=" << value << endl;
#endif
			found = true;
		}
	}
	return found;
}


////////////////////////////////////////////////////////////////

ostream& operator<<(ostream& os, const VOTable &n)
{
	n.printNode(os);
	return os;
}

ostream& operator<<(ostream& os, const votDescription &n)
{ const char *name = elementTable[votNode::RESOURCE].name;

	os << "<" << name << ">\n";
	os << n.description();

	os << "/" << name << ">/n";
	return os;
}
