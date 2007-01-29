// $Id: Reflex.h,v 19.12 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 2000 Associated Universities Inc.
#ifndef reflex_h
#define reflex_h
#include "Glish/Object.h"
#include "sos/generic.h"
#include "sos/list.h"
#include <stdio.h>

class ReflexObj;

class ReflexPtrBase {
    public:
	ReflexPtrBase( ReflexObj *p=0 );
	ReflexPtrBase( ReflexPtrBase &p );
	virtual ~ReflexPtrBase( );
	virtual void ObjGone( );
	int isNull( ) const { return obj == 0; }
	static void new_key( ) { ++current_key_; }
	static unsigned int current_key( ) { return current_key_; }
    protected:
	static unsigned int current_key_;
	ReflexPtrBase &operator=( ReflexObj *o );
	ReflexPtrBase &operator=( ReflexPtrBase &p );
	ReflexObj *obj;
	unsigned int key_;
};

glish_declare(PList,ReflexPtrBase);
typedef PList(ReflexPtrBase) reflexptr_list;

// Objects which can be pointed to by ReflexPtrBases
class ReflexObj : public GlishObject {
    public:
	ReflexObj( ) { }
	virtual ~ReflexObj( );
	// called when a pointer disappears
	void PointerGone( ReflexPtrBase* );
	void AddPointer( ReflexPtrBase* );
	virtual int isList( ) const;
    protected:
	reflexptr_list ptrs;
};

#define ReflexPtr(type)		sos_name2(type,ReflexPtr)

#define ReflexPtrdeclare(type)						\
class ReflexPtr(type) : ReflexPtrBase {					\
    public:								\
	ReflexPtr(type)( type *p=0 ) : ReflexPtrBase(p) { }		\
	ReflexPtr(type)( ReflexPtr(type) &p ) : ReflexPtrBase(p) { }	\
	ReflexPtr(type) &operator=( ReflexPtr(type) &p )		\
		{ return (ReflexPtr(type)&) ReflexPtrBase::operator=(p); } \
	ReflexPtr(type) &operator=( type *p )				\
		{ return (ReflexPtr(type)&) ReflexPtrBase::operator=(p); } \
	operator type *( ) { return (type*) obj; }			\
	operator const type *( ) const { return (type*) obj; }		\
	type &operator*( ) { return *((type*)obj); }			\
	type *operator->( ) { return (type*)obj; }			\
	int isNull( ) const { return ReflexPtrBase::isNull( ); }	\
	type *ptr( ) { return (type*) obj; }				\
	const type *ptr( ) const { return (type*) obj; }		\
	unsigned int key( ) const { return key_; }			\
	void unref( ) { if (obj) {obj->PointerGone( this ); Unref(obj);} obj=0; } \
};

class CycleNode : public ReflexObj { };

glish_declare(ReflexPtr,CycleNode);

struct node_list : BaseList
	{
	node_list(FINAL fh=0) : BaseList(0,fh) {}
	node_list(int sz, FINAL fh=0) : BaseList(sz,fh) {}
	node_list(node_list &l) : BaseList((BaseList&)l) {}

	void operator=(node_list& l)
		{ BaseList::operator=((BaseList&)l); }
	void insert(ReflexPtr(CycleNode) *a)	{ BaseList::insert(ent(a)); }
	void append(ReflexPtr(CycleNode) *a)	{ BaseList::append(ent(a)); }
	ReflexPtr(CycleNode) *remove(CycleNode *a);
	void insert_nth(int n, ReflexPtr(CycleNode)* a)	
				{ BaseList::insert_nth(n,ent(a)); }
	ReflexPtr(CycleNode) *remove_nth(int n)	{ return (ReflexPtr(CycleNode)*)(BaseList::remove_nth(n)); }
	ReflexPtr(CycleNode) *get()		{ return (ReflexPtr(CycleNode)*)BaseList::get(); }
	ReflexPtr(CycleNode) *operator[](int i) const
		{ return (ReflexPtr(CycleNode)*)(BaseList::operator[](i)); }
/* 	ReflexPtr(CycleNode) *replace( CycleNode *Old, ReflexPtr(CycleNode) *New); */
	ReflexPtr(CycleNode) *replace(int i, ReflexPtr(CycleNode)* new_type)
		{ return (ReflexPtr(CycleNode)*)BaseList::replace(i,ent(new_type)); }
	ReflexPtr(CycleNode) *is_member(const CycleNode *e);
	FINAL set_finalize_handler(FINAL fh=0)
		{ return BaseList::set_finalize_handler(fh); }
	};

glish_declare(PList,node_list);
typedef PList(node_list) cyclenodelist_list;

class NodeList : public CycleNode {
    public:
	void prune(CycleNode *r);
	ReflexPtr(CycleNode) *is_member(const CycleNode *e)
		{ return list.is_member( e ); }
	void append( NodeList * );
	void append( CycleNode * );
	int length( ) const { return list.length( ); }
	FINAL set_finalize_handler(FINAL fh=0)
		{ pruned.set_finalize_handler(fh); return list.set_finalize_handler(fh); }
	// value can be part of a frame so it can't be deleted, but needs to have
	// everything possible freed...
	int SoftDelete( );

	int isList( ) const;

	~NodeList( );

    protected:
	node_list pruned;
	node_list list;
};

#endif
