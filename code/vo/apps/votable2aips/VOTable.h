//# VOTable.h: this defines VOTable, which reads a VOTABLE table.
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
//#! =========================================================================
//#
//# $Id: VOTable.h,v 19.5 2004/11/30 17:51:23 ddebonis Exp $

// VOTable currently only handles inline data. No links are followed.

#ifndef VO_VOTABLE_H
#define VO_VOTABLE_H

#include <casa/iostream.h>
using namespace std;

#include <xercesc/util/XMLString.hpp>
#include <xercesc/dom/DOM.hpp>

// If an AIPS++ file, eg. casa/aips.h, has already been included, assume
// we're part of AIPS++. Otherwise, allow building w/o it.
#if defined(AIPS_AIPS_H)
#include <casa/BasicSL/Complexfwd.h>
#else
// The complex stuff is from AIPS++'s Complexfwd.h.
#include <complex>
namespace std {
  template<class T> class complex;
}

#include <casa/namespace.h>
// AIPS++ typedefs used here.
typedef int Int;
typedef float Float;
typedef unsigned char uChar;
typedef short Short; 
typedef unsigned int uInt;
typedef long Long;
typedef unsigned long uLong;
typedef double Double;
typedef std::complex<Float>  Complex;
typedef std::complex<Double> DComplex;
#endif

//#include <trial/votable/VOTableParserArgs.h>
#include <VOTableParserArgs.h>

#include <xercesc/parsers/XercesDOMParser.hpp>
#include <casa/namespace.h>
using xercesc::DOMElement;
using xercesc::DOMDocument;
using xercesc::DOMDocumentType;
using xercesc::DOMNamedNodeMap;
using xercesc::DOMNode;
using xercesc::DOMNodeList;
using xercesc::XercesDOMParser;
using xercesc::XMLString;
// using xercesc::

//# Forward Declarations
class DOMDocument;
class XercesDOMParser;
class DOMNode;
class DOMNamedNodeMap;
class DOMNodeList;

class votNode;
class VOTable;
class votDescription;
class votNodeListImpl;
class votAttributeNode;
class votNodeMapImpl;
class votXMLChMapImpl;

// Allows printing of XMLCh strings.
ostream& operator<< (ostream& target, const XMLCh *s);

// <summary>
// Reads a VOTABLE data file using the xerces parser.
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
// None.
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// Reads a VOTABLE data file and puts wrapper classes around the result
// to make it straightforward to retrive VOTABLE information.
// NOTE: Access to the class is via the static function makeVOTable. None of
// the class constructors are called directly by the programmer.
// <srcblock>
//	VOTable *tbl = VOTable::makeVOTable(<filename>);
// </srcblock>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <templating arg=T>
// None.
// </templating>
//
// <thrown>
// None.
// </thrown>
//
// <todo asof="2003/04/25">
// <li> Only inline table data are supported.
// </todo>

////////////////////////////////////////////////////////////////
// A list of votNodes.
class votNodeList {
  public:
	friend ostream& operator<<(ostream& os, const votNodeList &n);
	friend ostream& operator<<(ostream& os, const votNodeList *n);

	unsigned int getLength()const;
	void remove();	// Pop last entry.
	void printList(ostream &)const;
  protected:
	votNodeList();
	virtual ~votNodeList();
	votNode *item(unsigned int index)const;
	friend class votNode;
	virtual void append_(votNode *);
  private:
	votNodeListImpl	*list_;
};

////////////////////////////////////////////////////////////////

// key/value map for XMLCh * keys and votAttributeNode * maps.
class votNodeMap {
  public:
	votNodeMap();
	~votNodeMap();
	// Return the attribute node corresponding to the key.
	votAttributeNode *item(const XMLCh *)const;
	// Add a key/value to list.
	void add(const XMLCh *key, votAttributeNode *node);
	// Returns true if there is already an entry for key.
	bool isDefined(const XMLCh *key);
  protected:
  private:
	votNodeMapImpl *map_;
};

// Map from an XMLCh * to an int.
class votXMLChMap {
  public:
	votXMLChMap();
	~votXMLChMap();
	int item(const XMLCh *)const;
	// Add a key/value to list replacing any existing value.
	void add(const XMLCh *key, int value);
  protected:
  private:
	votXMLChMapImpl *map_;
};

// Contains a list of attributes for a DOMElement node.
class votAttributeList {
 public:
	votAttributeList(DOMElement *);
	uInt numAttributes()const;
	// Returns the name/value pair for attribute for the index.
	// Returns false if no attribute matches the index.
	bool getAttribute(uInt index, string &name, string &value)const;
	~votAttributeList();
 protected:
	friend class votAttributeNode;
 private:
	DOMNamedNodeMap	*list_;
};

////////////////////////////////////////////////////////////////

// Base class for all nodes.
class votNode {
  public:
	enum ELEMENT {UNKNOWN_ELEMENT,
		VOTABLE, DESCRIPTION, DEFINITIONS, INFO, RESOURCE,
		COOSYS, PARAM, LINK, TABLE, VALUES, FIELD, DATA, MIN, MAX,
		OPTION, TABLEDATA, BINARY, FITS, TR, TD, STREAM,
		NUMELEMENTS};

	enum ATTRIBUTE {UNKNOWN_ATTRIBUTE,
		ID, VERSION, NAME, TYPE, VALUE, UNIT, DATATYPE,
		PRECISION, WIDTH, REF, UCD, ARRAYSIZE, NULLATTR, INVALID,
		INCLUSIVE, CONTENT_ROLE, CONTENT_TYPE, TITLE, HREF,
		GREF, ACTION, EXTNUM, ACTUATE, ENCODING, EXPIRES, RIGHTS,
		EQUINOX, EPOCH, SYSTEM, NUMATTRIBUTES};

	enum PRIMITIVE {UNKNOWN_PRIMITIVE, BOOLEAN, BIT, UNSIGNEDBYTE,
		SHORT, INT, LONG, CHAR, UNICODECHAR, FLOAT, DOUBLE,
		FLOATCOMPLEX, DOUBLECOMPLEX, NUMPRIMITIVES};

	friend ostream& operator<< (ostream& os, const votNode &);
	friend ostream& operator<< (ostream& os, const votNode *);

	virtual const votNode *parent()const{return parent_;}
	virtual VOTable *rootNode()const{return root_;}
	votNode::ELEMENT nodeType()const{return nodeType_;}
	const char *nodeTypeName()const;
	// Returns true if strings a and b are the same.
	static bool XMLCmp(const XMLCh *a, XMLCh *b)
		{ return (XMLString::compareString(a, b) == 0);}

	// Returns true if the node's tag matches tag.
	static bool tagsMatch(const DOMElement *node, const XMLCh *tag)
		{  return (node == 0) ? false :
		    (XMLString::compareString(node->getTagName(), tag) == 0);
		}

	// Returns true iff parent and e are non 0, and e's tag matches's
	// id.
	static bool nodeCheck(const votNode *parent, DOMElement *e,
			      votNode::ELEMENT id);
	virtual void printNode(ostream &os)const;
	// When a node is printed and printReferences is true, a note about
	// about what node it references is also printed.
	bool printReferences()const{return printReferences_;}
	void printReferences(bool pr){printReferences_=pr;}
	// Inserts a comment into the output stream.
	static void printComment(ostream &os, const char *cmt);
	static void startComment(ostream &);
	static void endComment(ostream &);
	// Convert between XMLCh * and int values.
	static const XMLCh *getAttributeName(votNode::ATTRIBUTE);
	static const XMLCh *getElementName(votNode::ELEMENT);
	static const XMLCh *getPrimitiveName(votNode::PRIMITIVE);

	static const char *getAttributeString(votNode::ATTRIBUTE);
	static const char *getElementString(votNode::ELEMENT);
	static const char *getPrimitiveString(votNode::PRIMITIVE);

	static ATTRIBUTE getAttributeID(const XMLCh *);
	static ELEMENT getElementID(const XMLCh *);
	static PRIMITIVE getPrimitiveID(const XMLCh *);
	static PRIMITIVE getPrimitiveID(const char *);
	// Convert from XMLCh * to various primitive types. (Including
	// some not supported by VOTable).
	static void XMLChToString(const XMLCh *, string &);
	static void XMLChToBool(const XMLCh *, bool &);
	static void XMLChToLong(const XMLCh *, Long &);
	static void XMLChTouLong(const XMLCh *, uLong &);
	static void XMLChToInt(const XMLCh *, Int &);
	static void XMLChTouInt(const XMLCh *, uInt &);
	static void XMLChToShort(const XMLCh *, short &);
	static void XMLChTouByte(const XMLCh *, unsigned char &);
	static void XMLChToFloat(const XMLCh *, Float &);
	static void XMLChToDouble(const XMLCh *, Double &);
	static void XMLChToComplex(const XMLCh *, Complex &);
	static void XMLChToDoubleComplex(const XMLCh *, DComplex &);

	static bool *XMLChToBoolArray(const XMLCh *, uInt &nelems);
	static Long *XMLChToLongArray(const XMLCh *, uInt &nelems);
	static uLong *XMLChTouLongArray(const XMLCh *, uInt &nelems);
	static Int *XMLChToIntArray(const XMLCh *, uInt &nelems);
	static uInt *XMLChTouIntArray(const XMLCh *, uInt &nelems);
	static Short *XMLChToShortArray(const XMLCh *, uInt &nelems);
	static unsigned char *XMLChTouByteArray(const XMLCh *, uInt &nelems);
	static Float *XMLChToFloatArray(const XMLCh *, uInt &nelems);
	static Double *XMLChToDoubleArray(const XMLCh *, uInt &nelems);
	static Complex *XMLChToComplexArray(const XMLCh *, uInt &nelems);
	static DComplex *XMLChToDoubleComplexArray(const XMLCh *,uInt &nelems);
	votNode(); // Makes a dummy node.
  protected:
	votNode(const votNode *parent, DOMElement *node, votNode::ELEMENT);
	virtual ~votNode();
	DOMElement *node(){return node_;}
	// Return the first child of this element with the tag.
	DOMElement *getDOMNodeByTagName(const XMLCh *name)const;
	// Return the first child of this element with the ID.
	DOMElement *getDOMNodeByTagID(votNode::ELEMENT)const;
	// Look for the first child with the id and create a node for it.
	votNode *getChildByTagID(votNode::ELEMENT id)const;
	// Return a list of all nodes with the tag.
	//votNodeList *getNodesByTagID(votNode::ELEMENT)const;
	void getNodesByTagID(votNode::ELEMENT id, votNodeList *nodelist)const;
	void nodeType(votNode::ELEMENT nt){nodeType_ = nt;}
	const XMLCh *getNodeValue()const;
	const XMLCh *getNodeName()const;
	void printTypeName(ostream &os,bool begin=true)const;
	// Prints "<NAME>" or "<NAME ".
	virtual void printNodeBegin(ostream &os, bool close=true)const;
	// Prints "</NAME>" or "/>".
	void votNode::printNodeEnd(ostream &os, bool shortform=false)const;
	static void PrintList(ostream &os, votNodeList *list)
	 { if(list) list->printList(os);}
	static void PrintNode(ostream &os, votNode *node)
	 { if(node) node->printNode(os);}
  protected:
	DOMElement	*node_;
	DOMNodeList	*children_;
	bool		printReferences_;
  private:
	static void initOnce();
	const votNode	*parent_;
	VOTable		*root_;
	votNode::ELEMENT nodeType_;

	static XMLCh	**elementTable_;
	static XMLCh	**attributeTable_;
	static XMLCh	**primitiveTable_;
	static votXMLChMap	*primitiveMap_;
	static bool	initedOnce_;
};

// A node that also has attributes.
class votAttributeNode : public votNode {
 public:
	friend ostream& operator<< (ostream& os, const votAttributeNode &);
	friend ostream& operator<< (ostream& os, const votAttributeNode *);

	const XMLCh *getAttributeByName(const XMLCh *name)const;
	const XMLCh *getAttributeByID(votNode::ATTRIBUTE)const;
	votAttributeList *getAttributes()const;
  protected:
	votAttributeNode(const votNode *parent, DOMElement *node,
			 votNode::ELEMENT);
	virtual ~votAttributeNode();
	// Various attributes that nodes frequently return.
	virtual const XMLCh *id()const;
	virtual const XMLCh *name()const;
	virtual const XMLCh *value()const;
	virtual const XMLCh *ref()const;

	virtual void getID(string &)const;
	virtual void getName(string &)const;
	virtual void getValue(string &)const;
	virtual void getRef(string &)const;

	// Many nodes can have a description.
	votDescription *description()const{return description_;}
	virtual void printNodeBegin(ostream &os, bool close=false)const;
	virtual void printNode(ostream &os)const;

	// used to setup attributeNodes.
	void checkForID();
  private:
	votDescription	*description_;
};

////////////////////////////////////////////////////////////////
// More or less one class for each 'ELEMENT' in the DTD
//	(In reverse order)
////////////////////////////////////////////////////////////////

class votCOOSYS : public votAttributeNode{
  public:
	friend class votResource;
	friend class votDefinition;

	// Attributes.
	virtual const XMLCh *id()const{return votAttributeNode::id();}
	const XMLCh *equinox()const;
	const XMLCh *epoch()const;
	const XMLCh *system()const;

	virtual void getID(string &s)const {votAttributeNode::getID(s);}
	void getEquinox(string &)const;
	void getEpoch(string &)const;
	void getSystem(string &)const;

	// Children
	// (none)
	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votCOOSYS(const votNode *parent, DOMElement *node) :
		  votAttributeNode(parent, node, votNode::COOSYS) {}
	virtual ~votCOOSYS();
  private:
};

class votCOOSYSList : public votNodeList {
  public:
	votCOOSYSList() : votNodeList(){};
	virtual ~votCOOSYSList() {}
	virtual void append(votCOOSYS *node) { votNodeList::append_(node);}
	virtual votCOOSYS *item(uInt index)
		{	return
			 dynamic_cast<votCOOSYS *>(votNodeList::item(index));
		}
};

class votStream : public votAttributeNode{
  public:
	friend class votBinary;

	const XMLCh *getNodeValue()const{return votNode::getNodeValue();}
	// Attributes.
	const XMLCh *type()const;
	const XMLCh *href()const;
	const XMLCh *actuate()const;
	const XMLCh *encoding()const;
	const XMLCh *expires()const;
	const XMLCh *rights()const;

	// Children
	// (none)

	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votStream(const votNode *parent, DOMElement *node) :
	    votAttributeNode(parent, node, votNode::STREAM) {}
	virtual ~votStream();
  private:
};

class votBinary : public votNode {
  public:
	friend class votData;
	// Attributes
	// (none)
	// Children
	votStream *stream()const{return stream_;}
	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votBinary(const votNode *parent, DOMElement *node);
	virtual ~votBinary();
  private:
	votStream	*stream_;
};

class votFITS : public votAttributeNode {
  public:
	friend class votData;

	// Attributes
	const XMLCh *extnum()const;
	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votFITS(const votNode *parent, DOMElement *node) :
		votAttributeNode(parent, node, votNode::FITS) {}
	virtual ~votFITS();
  private:
};

class votTD : public votAttributeNode {
  public:
	friend class votTR;
	const XMLCh *getNodeValue()const{return votNode::getNodeValue();}
	void getString(string &v)const{ XMLChToString(getNodeValue(), v);}
	void getBool(bool &v)const{ XMLChToBool(getNodeValue(), v);}
	void getLong(Long &v)const{ XMLChToLong(getNodeValue(), v);}
	void getuLong(uLong &v)const{XMLChTouLong(getNodeValue(), v);}
	void getInt(Int &v)const{XMLChToInt(getNodeValue(), v);}
	void getuInt(uInt &v)const{XMLChTouInt(getNodeValue(), v);}
	void getShort(short &v)const{XMLChToShort(getNodeValue(), v);}
	void getuByte(unsigned char &v)const{XMLChTouByte(getNodeValue(), v);}
	void getFloat(Float &v)const{XMLChToFloat(getNodeValue(), v);}
	void getDouble(Double &v)const{XMLChToDouble(getNodeValue(), v);}
	void getComplex(Complex &v)const{XMLChToComplex(getNodeValue(), v);}
	void getDoubleComplex(DComplex &v)const
	  	{XMLChToDoubleComplex(getNodeValue(), v);}

	bool *getBoolArray(uInt &nelems)const
		{ return XMLChToBoolArray(getNodeValue(), nelems);}
	Long *getLongArray(uInt &nelems)const
		{ return XMLChToLongArray(getNodeValue(), nelems);}
	uLong *getuLongArray(uInt &nelems)const
		{return XMLChTouLongArray(getNodeValue(), nelems);}
	Int *getIntArray(uInt &nelems)const
		{return XMLChToIntArray(getNodeValue(), nelems);}
	uInt *getuIntArray(uInt &nelems)const
		{return XMLChTouIntArray(getNodeValue(), nelems);}
	Short *getShortArray(uInt &nelems)const
		{return XMLChToShortArray(getNodeValue(), nelems);}
	uChar *getuByteArray(uInt &nelems)const
		{ return XMLChTouByteArray(getNodeValue(), nelems);}
	Float *getFloatArray(uInt &nelems)const
		{return XMLChToFloatArray(getNodeValue(), nelems);}
	Double *getDoubleArray(uInt &nelems)const
		{return XMLChToDoubleArray(getNodeValue(), nelems);}
	Complex *getComplexArray(uInt &nelems)const
		{return XMLChToComplexArray(getNodeValue(), nelems);}
	DComplex *getDoubleComplexArray(uInt nelems)const
		{return XMLChToDoubleComplexArray(getNodeValue(), nelems);}

	// Attributes
	const XMLCh *ref()const{return votAttributeNode::ref();}
	// Children
	// (none)
	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votTD(const votNode *parent, DOMElement *node) :
		votAttributeNode(parent, node, votNode::TD)
	{}
	virtual ~votTD();
  private:
};

class votTDList : public votNodeList {
  public:
	votTDList() : votNodeList(){};
	virtual ~votTDList() {}
	virtual void append(votTD *node) { votNodeList::append_(node);}
	virtual votTD *item(uInt index)
		{	return dynamic_cast<votTD *>(votNodeList::item(index));
		}
};

class votTR : public votNode {
  public:
	friend class votTableData;
	// Attributes
	// (none)
	// Children
	votTDList 	*tdList()const{return tdList_;}
	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votTR(const votNode *parent, DOMElement *node);
	virtual ~votTR();
  private:
	votTDList	*tdList_;
};

class votTRList : public votNodeList {
  public:
	votTRList() : votNodeList(){};
	virtual ~votTRList() {}
	virtual void append(votTR *node) { votNodeList::append_(node);}
	virtual votTR *item(uInt index)
		{	return dynamic_cast<votTR *>(votNodeList::item(index));
		}
};

class votTableData : public votNode {
  public:
	friend class votData;
	// Attributes
	// (none)
	// Children
	votTRList	*rowList()const{return rowList_;}
	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votTableData(const votNode *parent, DOMElement *node);
	virtual ~votTableData();
  private:
	votTRList	*rowList_;
};

class votData : public votNode {
  public:
	friend class votTable;

	// Attributes
	// (none)

	// Children
	votTableData *tableData()const{return tableData_;}
	votBinary *binary()const{return binary_;}
	votFITS *fits()const{return fits_;}

	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votData(const votNode *parent, DOMElement *node);
	virtual ~votData();
  private:
	votTableData	*tableData_;
	votBinary	*binary_;
	votFITS		*fits_;
};

class votDataList : public votNodeList {
  public:
	votDataList() : votNodeList(){};
	virtual ~votDataList() {}
	virtual void append(votData *node) { votNodeList::append_(node);}
	virtual votData *item(uInt index)
		{	return dynamic_cast<votData *>(votNodeList::item(index));
		}
};

class votLink : public votAttributeNode{
  public:
	friend class votValues;

	// Attributes.
	virtual const XMLCh *id()const{return votAttributeNode::id();}
	const XMLCh *content_role()const;
	const XMLCh *content_type()const;
	const XMLCh *title()const;
	virtual const XMLCh *value()const{return votAttributeNode::value();}
	const XMLCh *href()const;
	const XMLCh *gref()const;
	const XMLCh *action()const;

	virtual void getID(string &s)const {votAttributeNode::getID(s);}
	void getContent_role(string &s)const;
	void getContent_type(string &s)const;
	void getTitle(string &s)const;
	virtual void getValue(string &s)const
			{return votAttributeNode::getValue(s);}
	void getHref(string &s)const;
	void getGref(string &s)const;
	void getAction(string &s)const;
	// Children
	// (none)

	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votLink(const votNode *parent, DOMElement *node) :
		votAttributeNode(parent, node, votNode::LINK){}
	virtual ~votLink();
  private:
};

class votLinkList : public votNodeList {
  public:
	votLinkList() : votNodeList(){};
	virtual ~votLinkList() {}
	virtual void append(votLink *node) { votNodeList::append_(node);}
	virtual votLink *item(uInt index)
		{	return dynamic_cast<votLink *>(votNodeList::item(index));
		}
};

class votOptionList;

class votOption : public votAttributeNode{
  public:
	friend class votValues;

	// Attributes
	virtual const XMLCh *name()const{return votAttributeNode::name();}
	virtual const XMLCh *value()const{return votAttributeNode::value();}

	// Children
	//votNodeList *options()const{return optionList_;}
	votOptionList *options()const{return optionList_;}

	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votOption(const votNode *parent, DOMElement *node);
	virtual ~votOption();
  private:
	votOptionList	*optionList_;
};

class votOptionList : public votNodeList {
  public:
	votOptionList() : votNodeList(){};
	virtual ~votOptionList() {}
	virtual void append(votOption *node) { votNodeList::append_(node);}
	virtual votOption *item(uInt index)
		{	return dynamic_cast<votOption *>(votNodeList::item(index));
		}
};

// Handles both MIN and MAX nodes.
class votMinMaxNode : public votAttributeNode {
  public:
	friend class votValues;

	// Attributes
	const XMLCh *value()const{return votAttributeNode::value();}
	const XMLCh *inclusive()const;

	void getValue(string &s)const;
	void getInclusive(string &s)const;
	// Children
	//  (none)

	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votMinMaxNode(const votNode *parent, DOMElement *node,
		votNode::ELEMENT nt) : votAttributeNode(parent, node, nt){ }
	virtual ~votMinMaxNode();
  private:
};

class votMinMaxNodeList : public votNodeList {
  public:
	votMinMaxNodeList() : votNodeList(){};
	virtual ~votMinMaxNodeList() {}
	virtual void append(votMinMaxNode *node) { votNodeList::append_(node);}
	virtual votMinMaxNode *item(uInt index)
		{	return
			 dynamic_cast<votMinMaxNode *>(votNodeList::item(index));
		}
};
 
class votValues : public votAttributeNode{
  public:
	friend class votParam;
	friend class votField;

	// Attributes
	virtual const XMLCh *id()const{return votAttributeNode::id();}
	const XMLCh *type()const;
	const XMLCh *null()const;
	const XMLCh *invalid()const;

	virtual void getID(string &s)const{votAttributeNode::getID(s);}
	void getType(string &s)const;
	void getNull(string &s)const;
	void getInvalid(string &s)const;

	// Children
	virtual votMinMaxNode *min()const {return min_;}
	virtual votMinMaxNode *max()const {return max_;}
	votOptionList *optionList()const {return optionList_;}

	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votValues(const votNode *parent, DOMElement *node);
	virtual ~votValues();
  private:
	votMinMaxNode	*min_;
	votMinMaxNode	*max_;
	votOptionList	*optionList_;
};

class votValuesList : public votNodeList {
  public:
	votValuesList() : votNodeList(){};
	virtual ~votValuesList() {}
	virtual void append(votValues *node) { votNodeList::append_(node);}
	virtual votValues *item(uInt index)
		{	return dynamic_cast<votValues *>(votNodeList::item(index));
		}
};

class votField : public votAttributeNode {
  public:
	friend class votTable;

	// Attributes
	virtual const XMLCh *id()const{return votAttributeNode::id();}
	const XMLCh *unit()const;
	const XMLCh *datatype()const;
	const XMLCh *precision()const;
	const XMLCh *width()const;
	virtual const XMLCh *ref()const{return votAttributeNode::ref();}
	const XMLCh *name()const{return votAttributeNode::name();}
	const XMLCh *ucd()const;
	const XMLCh *arraysize()const;
	const XMLCh *type()const;

	virtual void getID(string &s)const{votAttributeNode::getID(s);}
	virtual void getRef(string &s)const{votAttributeNode::getRef(s);}
	virtual void getName(string &s)const{votAttributeNode::getName(s);}

	void getUnit(string &s)const;
	void getDatatype(string &s)const;
	void getPrecision(string &s)const;
	void getWidth(string &s)const;
	void getUCD(string &s)const;
	void getArraySize(string &s)const;
	void getType(string &s)const;

	// Children
	virtual votDescription *description()const
			{return votAttributeNode::description();}

	votValuesList *valuesList()const {return valuesList_;}
	votLinkList *linkList()const {return linkList_;}

	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votField(const votNode *parent, DOMElement *node);
	votField(const votNode *parent, DOMElement *node, votNode::ELEMENT);
	virtual ~votField();
  private:
	void initField();
	votValuesList *valuesList_;
	votLinkList *linkList_;
};

class votFieldList : public votNodeList {
  public:
	votFieldList() : votNodeList(){};
	virtual ~votFieldList() {}
	virtual void append(votField *node) { votNodeList::append_(node);}
	virtual votField *item(uInt index)
		{	return dynamic_cast<votField *>(votNodeList::item(index));
		}
};

class votTable : public votAttributeNode {
  public:
	friend class votResource;

	// Parameters
	virtual const XMLCh *id()const{return votAttributeNode::id();}
	virtual const XMLCh *name()const{return votAttributeNode::name();}
	virtual const XMLCh *ref()const{return votAttributeNode::ref();}

	virtual void getID(string &s)const{votAttributeNode::getID(s);}
	virtual void getName(string &s)const{votAttributeNode::getName(s);}
	virtual void getRef(string &s)const{votAttributeNode::getRef(s);}

	// Children
	virtual votDescription *description()const
			{return votAttributeNode::description();}

	votLinkList *linkList()const {return linkList_;}
	votFieldList *fieldList()const {return fieldList_;}
	votData *data()const{return data_;}

	static votNode *makeNode(const votNode *parent, DOMElement *node);
	virtual void printNode(ostream &os)const;
  protected:
	votTable(const votNode *parent, DOMElement *node);
	virtual ~votTable();
  private:
	votLinkList *linkList_;
	votFieldList *fieldList_;
	votData	    *data_;
};

class votTableList : public votNodeList {
  public:
	votTableList() : votNodeList(){};
	virtual ~votTableList() {}
	virtual void append(votTable *node) { votNodeList::append_(node);}
	virtual votTable *item(uInt index)
		{	return dynamic_cast<votTable *>(votNodeList::item(index));
		}
};

// Same as Field, but with a values attribute.
class votParam : public votField {
  public:
	friend class VOTable;
	friend class votDefinition;

	const XMLCh *value()const{return votAttributeNode::value();}
	void getValue(string &v)const{return votAttributeNode::getValue(v);}
	static votNode *makeNode(const votNode *parent, DOMElement *node);
	friend ostream& operator<<(ostream& os, const votParam &);
	virtual void printNode(ostream &os)const;
  protected:
	votParam(const votNode *parent, DOMElement *node) :
		votField(parent, node, votNode::PARAM) {}
	virtual ~votParam();
  private:
};

class votParamList : public votNodeList {
  public:
	votParamList() : votNodeList(){};
	virtual ~votParamList() {}
	virtual void append(votParam *node) { votNodeList::append_(node);}
	virtual votParam *item(uInt index)
		{	return dynamic_cast<votParam *>(votNodeList::item(index));
		}
};

class votInfo : public votAttributeNode {
  public:
	friend class VOTable;
	const XMLCh *id()const {return votAttributeNode::id();}
	const XMLCh *name()const {return votAttributeNode::name();}
	const XMLCh *value()const {return votAttributeNode::value();}

	virtual void getID(string &s)const{votAttributeNode::getID(s);}
	virtual void getName(string &s)const{votAttributeNode::getName(s);}
	virtual void getValue(string &s)const{votAttributeNode::getValue(s);}

	static votNode *makeNode(const votNode *parent, DOMElement *node);
	friend ostream& operator<<(ostream& os, const votInfo &);
	virtual void printNode(ostream &os)const;
  protected:
	votInfo(const votNode *parent, DOMElement *node) :
		votAttributeNode(parent, node, votNode::INFO) {}
	virtual ~votInfo();
  private:
};

class votInfoList : public votNodeList {
  public:
	votInfoList() : votNodeList(){};
	virtual ~votInfoList() {}
	virtual void append(votInfo *node) { votNodeList::append_(node);}
	virtual votInfo *item(uInt index)
		{	return
			 dynamic_cast<votInfo *>(votNodeList::item(index));
		}
};

class votDefinition : public votNode {
  public:
	friend class VOTable;

	// Children
	votCOOSYS *coosys()const{return coosys_;}
	votParam  *param()const{return param_;}

	static votNode *makeNode(const votNode *parent, DOMElement *node);
	friend ostream& operator<<(ostream& os, const votDefinition &);
	virtual void printNode(ostream &os)const;
  protected:
	votDefinition(const votNode *parent, DOMElement *node);
	virtual ~votDefinition();
  private:
	votCOOSYS	*coosys_;
	votParam	*param_;
};

class votDefinitionsList : public votNodeList {
  public:
	votDefinitionsList() : votNodeList(){};
	virtual ~votDefinitionsList() {}
	virtual void append(votDefinition *node) { votNodeList::append_(node);}
	virtual votDefinition *item(uInt index)
		{	return
			 dynamic_cast<votDefinition *>(votNodeList::item(index));
		}
};

class votDescription : public votNode {
  public:
	friend class votAttributeNode;
	friend class VOTable;
	const XMLCh	*description()const;
	void getDescription(string &)const;

	static votNode *makeNode(const votNode *parent, DOMElement *node);
	friend ostream& operator<<(ostream& os, const votDescription &);
	virtual void printNode(ostream &os)const;
  protected:
	votDescription( const votNode *parent, DOMElement *node) :
			votNode(parent, node, votNode::DESCRIPTION){}
	virtual ~votDescription();
  private:
};

class votResourceList;

class votResource : public votAttributeNode {
public:
	friend class VOTable;
	// Attributes.
	const XMLCh *name()const{return votAttributeNode::name();}
	virtual const XMLCh *id()const{return votAttributeNode::id();}
	const XMLCh *type()const;

	virtual void getID(string &s)const{votAttributeNode::getID(s);}
	virtual void getName(string &s)const{votAttributeNode::getName(s);}
	virtual void getType(string &s)const;
	// Child nodes.
	votDescription *description()const
		{return votAttributeNode::description();}
	votInfoList *infoList()const {return infoList_;}
	votCOOSYSList *coosysList()const {return coosysList_;}
	votParamList *paramList()const {return paramList_;}
	votLinkList *linkList()const {return linkList_;}
	votTableList *tableList()const {return tableList_;}
	votResourceList *resourceList()const {return resourceList_;}

	static votNode *makeNode(const votNode *parent, DOMElement *node);
	friend ostream& operator<<(ostream& os, const votResource &);
	virtual void printNode(ostream &os)const;
protected:
	votResource(const votNode *parent, DOMElement *resource);
	virtual ~votResource();
private:
	votInfoList *infoList_;
	votCOOSYSList *coosysList_;
	votParamList *paramList_;
	votLinkList *linkList_;
	votTableList *tableList_;
	votResourceList *resourceList_;
};

class votResourceList : public votNodeList {
  public:
	votResourceList() : votNodeList(){};
	virtual ~votResourceList() {}
	virtual void append(votResource *node) { votNodeList::append_(node);}
	virtual votResource *item(uInt index)
		{	return dynamic_cast<votResource *>(votNodeList::item(index));
		}
};

// Holds the XML header rather than VOTABLE information.
class votDocument {
  public:
	votDocument(DOMDocument &doc) : doc_(doc) {}
	virtual ~votDocument();

	// Document parameters
	const XMLCh *XMLversion()const;
	const XMLCh *encoding()const;
	bool standalone()const;
	void getXMLVersion(string &s)const;
	void getEncoding(string &s)const;
	void getStandalone(string &s)const;
	const DOMDocument *document()const{return &doc_;}

	// DocumentType parameters
	const XMLCh *publicId()const;
	const XMLCh *systemId()const;
	const XMLCh *internalSubset()const;
	void getPublicId(string &s)const;
	void getSystemId(string &s)const;
	void getInternalSubset(string &s)const;
	const DOMDocumentType *documentType()const{return doc_.getDoctype();}
  private:
	DOMDocument	&doc_;
};

class VOTable : public votAttributeNode {
public:

//#! Friends
	friend class votAttributeNode;
//#! Enumerations
	typedef votNode::ELEMENT ELEMENT;
	typedef votNode::ATTRIBUTE ATTRIBUTE;
	typedef votNode::PRIMITIVE PRIMITIVE;
//#! Constructors
//#! Destructor
	virtual VOTable::~VOTable();
//#! Operators
	friend ostream& operator<<(ostream& os, const VOTable &n);

	// Parameters
	virtual const XMLCh *id()const{return votAttributeNode::id();}
	const XMLCh *version()const;
	virtual void getID(string &s)const{votAttributeNode::getID(s);}
	void getVersion(string &)const;

	votDocument *document()const{return document_;}
	// Children
	votDescription *description()const
			{return votAttributeNode::description();}
	votDefinitionsList *definitionsList()const{return definitionsList_;}
	votInfoList *infoList()const{ return infoList_;}
	votResourceList *resourceList()const{return resourceList_;}

	static VOTable *makeVOTable(DOMDocument *, XercesDOMParser *p=0);

	static VOTable *VOTable::makeVOTable(const char *xmlFile);
	static VOTable *VOTable::makeVOTable(const char *xmlFile,
					     const VOTableParserArgs &args);
	virtual void printNode(ostream &os)const;
	const votNodeMap *idMap()const{return idMap_;}
	XercesDOMParser *parser()const{return parser_;}
	// This should never be called. It is here to have something to
	// fill a spot in elementTable.
//	static votNode *makeNode(const votNode *parent, DOMElement *node);
	static void printParserGets(ostream &os, const XercesDOMParser *p);
protected:
	// Add an ID/node to the id map.
	void addID(const XMLCh *id, votAttributeNode *node);
//#! Data Members

//#! Constructors
	VOTable(DOMElement *documentElement, XercesDOMParser *parser=0);

//#! Inheritable Member Functions

private:
	void	setParser(XercesDOMParser *p){ parser_ = p;}

//#! Data Members
	votDocument		*document_;
	votDefinitionsList	*definitionsList_;
	votInfoList		*infoList_;
	votResourceList		*resourceList_;

	votNodeMap		*idMap_;	// ID->node map. (for 'ref').
	XercesDOMParser		*parser_;
//#! Constructors

	void init();
};
#endif
