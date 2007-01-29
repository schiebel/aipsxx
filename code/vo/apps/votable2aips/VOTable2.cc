//# VOTABLE2.cc:  Implements votNodeList and votNodeMap.
//# Copyright (C) 2002,2003
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
//# $Id: VOTable2.cc,v 19.3 2004/11/30 17:51:23 ddebonis Exp $

//# Includes
#include <casa/iostream.h>
// Note there is VERY little AIPS++ dependency in this file.
//#include <casa/aips.h>

#include <VOTable.h>
#include <vector>
#include <map>

using namespace std;

#include <VOTable2.h>

#include <casa/namespace.h>
//# This is the actual list. votNodeList, etc. are wrapper classes around
//# the these implementations. This keeps all references to templates in
//# this file.
//#
//# Stores and retrieves votNodes.
class votNodeListImpl {
  public:
	votNodeListImpl();
	~votNodeListImpl();
	votNode *item(unsigned int index)const;
	unsigned int getLength()const;
	void append(votNode *);
	void remove();
  protected:
  private:
	vector<votNode *>	*list_;
};

votNodeListImpl::votNodeListImpl()
{
	list_ = new vector<votNode *>;
}

votNodeListImpl::~votNodeListImpl()
{
	delete list_;
}

votNode *votNodeListImpl::item(unsigned int index)const
{
	return (*list_)[index];
}

unsigned int votNodeListImpl::getLength()const
{
	return list_->size();
}

void votNodeListImpl::append(votNode *node)
{
	list_->push_back(node);
}

void votNodeListImpl::remove()
{
	list_->pop_back();
}

////////////////////////////////////////////////////////////////

votNodeList::votNodeList()
{
	list_ = new votNodeListImpl();
}

votNodeList::~votNodeList()
{
	delete list_;
}

votNode *votNodeList::item(unsigned int index)const
{
  if(list_->getLength() > index)
    return list_->item(index);
  else
    return 0;
}

unsigned int votNodeList::getLength()const
{
  return list_->getLength();
}

void votNodeList::append_(votNode *node)
{
	list_->append(node);
}

void votNodeList::remove()
{
	list_->remove();
}

void votNodeList::printList(ostream &os)const
{
	for(uInt i=0; i<getLength(); i++)
		item(i)->printNode(os);
}

////////////////////////////////////////////////////////////////

ostream& operator<<(ostream& os, const votNodeList &n)
{
	n.printList(os);
	return os;
}

ostream& operator<<(ostream& os, const votNodeList *n)
{
	n->printList(os);
	return os;
}

//////////////////////////////////////////////////////////////////////////


typedef map<const XMLCh *, votAttributeNode *, XMLChComp> NodeKeyMap;

// Internal implementation of an XMLch/votAttributeNode map.
class votNodeMapImpl {
  public:
	votNodeMapImpl();
	~votNodeMapImpl();
	// Return the node corresponding to key or NULL.
	votAttributeNode *item(const XMLCh *key)const;
	// Add a key/value to list replacing any existing value.
	void add(const XMLCh *key, votAttributeNode *node);

	// Returns true if the map already contains an entry for key.
	bool votNodeMapImpl::isDefined(const XMLCh *key)const;
  protected:
  private:
	mutable NodeKeyMap	map_;
};

votNodeMapImpl::votNodeMapImpl(): map_()
{
}

votNodeMapImpl::~votNodeMapImpl()
{
}

// Return a pointer to the node for key or 0 if no match.
// Does not create a new item if not match was found.
votAttributeNode *votNodeMapImpl::item(const XMLCh *key)const
{ votAttributeNode *node = 0;

	const NodeKeyMap::iterator it = map_.find(key);
	if(it != map_.end())
	{	node = it->second;
	}

	return node;
}

bool votNodeMapImpl::isDefined(const XMLCh *key)const
{
	const NodeKeyMap::iterator i = map_.find(key);
	bool rtn = (i != map_.end());
	return rtn;;
}

// Add a key/value to list. Replaces any existing value.
void votNodeMapImpl::add(const XMLCh *key, votAttributeNode *node)
{

	if((key != 0) && (node != 0))
		map_[key] = node;
}

////////////////////////////////////////////////////////////////
votNodeMap::votNodeMap()
{
	map_ = new votNodeMapImpl();
}

votNodeMap::~votNodeMap()
{
	delete map_;
}

votAttributeNode *votNodeMap::item(const XMLCh *key)const
{
	return map_->item(key);
}

// Add a key/value to list replacing any existing value.
void votNodeMap::add(const XMLCh *key, votAttributeNode *node)
{
	map_->add(key, node);
}

////////////////////////////////////////////////////////////////
typedef map<const XMLCh *,int, XMLChComp> ChIntMap;

// XMLCh/integer map.
class votXMLChMapImpl {
  public:
	votXMLChMapImpl();
	~votXMLChMapImpl();
	int item(const XMLCh *)const;
	// Add a key/value to list.
	void add(const XMLCh *key, int);
	bool isDefined(XMLCh *key) const;
  protected:
  private:
	mutable ChIntMap map_;
};

votXMLChMapImpl::votXMLChMapImpl()
{
}

votXMLChMapImpl::~votXMLChMapImpl()
{
}

// Returns the integer corresponding to the key or 0 if none.
// Does not create a new item if not match was found.
int votXMLChMapImpl::item(const XMLCh *key)const
{ int value = 0;

	ChIntMap::iterator it = map_.find(key);
	if(it != map_.end())
		value = it->second;

	return value;
}

// Add a key/value to map.
void votXMLChMapImpl::add(const XMLCh *key, int value)
{
	map_[key] = value;
}

////////////////////////////////////////////////////////////////
votXMLChMap::votXMLChMap()
{
	map_ = new votXMLChMapImpl();
}

votXMLChMap::~votXMLChMap()
{
	delete map_;
}

int votXMLChMap::item(const XMLCh *key)const
{
	return map_->item(key);
}

// Add a key/value to list.
void votXMLChMap::add(const XMLCh *key, int value)
{
	map_->add(key, value);
}
