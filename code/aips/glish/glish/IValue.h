// $Id: IValue.h,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.
#ifndef ivalue_h
#define ivalue_h
#include "Glish/Value.h"
#include "Reflex.h"

class Agent;
class Func;
class NodeList;
class Regex;
class RegexMatch;
class File;
class ArithExpr;
class RelExpr;
class Frame;
class IValue;
class ProxyId;

extern ProxyId glish_proxyid_dummy;
extern const char *glish_charptrdummy;

glish_declare(ReflexPtr,NodeList);

#define alloc_ivalueptr( num ) (IValue**) alloc_memory( sizeof(IValue*) * (num) )
#define realloc_ivalueptr( ptr, num ) (IValue**) realloc_memory( ptr, sizeof(IValue*) * (num) )

typedef File* fileptr;
#define alloc_fileptr( num ) (fileptr*) alloc_memory( sizeof(fileptr) * (num) )
#define realloc_fileptr( ptr, num ) (fileptr*) realloc_memory( ptr, sizeof(fileptr) * (num) )

typedef Regex* regexptr;
#define alloc_regexptr( num ) (regexptr*) alloc_memory( sizeof(regexptr) * (num) )
#define realloc_regexptr( ptr, num ) (regexptr*) realloc_memory( ptr, sizeof(regexptr) * (num) )

typedef Func* funcptr;
#define alloc_funcptr( num ) (funcptr*) alloc_memory( sizeof(funcptr) * (num) )
#define realloc_funcptr( ptr, num ) (funcptr*) realloc_memory( ptr, sizeof(funcptr) * (num) )

typedef Agent* agentptr;
#define alloc_agentptr( num ) (agentptr*) alloc_memory( sizeof(agentptr) * (num) )
#define realloc_agentptr( ptr, num ) (agentptr*) realloc_memory( ptr, sizeof(agentptr) * (num) )

glish_declare(PList,IValue);
typedef PList(IValue) ivalue_list;

extern void copy_agents( void *to_, void *from_, unsigned long len );
extern void delete_agents( void *ary_, unsigned long len );

class IValue : public Value {
public:
	// Create a <fail> value
	IValue( );
	IValue( const char *message, const char *file, int lineNum, int auto_fail=1 );
	IValue( const Value *val, const char *file, int lineNum ) :
				Value( val, file, lineNum ) { }

	IValue( const Value &v ) : Value(v)
		{ if ( v.doPropagate( ) ) SetUnref( ((IValue &)v).unref ); }
	IValue( const IValue &v ) : Value(v)
		{ if ( v.doPropagate( ) ) SetUnref( ((IValue &)v).unref ); }

	IValue( glish_bool v ) : Value( v ) { }
	IValue( byte v ) : Value( v ) { }
	IValue( short v ) : Value( v ) { }
	IValue( int v ) : Value( v ) { }
	IValue( float v ) : Value( v ) { }
	IValue( double v ) : Value( v ) { }
	IValue( glish_complex v ) : Value( v ) { }
	IValue( glish_dcomplex v ) : Value( v ) { }
	IValue( const char* v ) : Value( v ) { }
	IValue( funcptr v );
	IValue( regexptr v );
	IValue( fileptr v );

	// If "storage" is set to "COPY_ARRAY", then the underlying
	// "Agent" in value will be Ref()ed. Otherwise, if 
	// "TAKE_OVER_ARRAY" it will simply be used.
	IValue( agentptr value, array_storage_type storage = COPY_ARRAY );

	IValue( recordptr v ) : Value( v ) { }
	IValue( recordptr v, Agent* agent );

	// Reference constructor.
	IValue( Value* ref_value, value_reftype val_type ) : Value( ref_value, val_type )
		{ if ( ref_value->doPropagate( ) ) SetUnref( ((IValue *)ref_value)->unref ); }

	// Subref constructor.
	IValue( Value* ref_value, int index[], int num_elements,
		value_reftype val_type, int take_index = 0 ) :
			Value( ref_value, index, num_elements,
			       val_type, take_index ) { }

	IValue( glish_bool value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY ) :
			Value( value, num_elements, storage ) { }
	IValue( byte value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY ) :
			Value( value, num_elements, storage ) { }
	IValue( short value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY ) :
			Value( value, num_elements, storage ) { }
	IValue( int value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY ) :
			Value( value, num_elements, storage ) { }
	IValue( float value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY ) :
			Value( value, num_elements, storage ) { }
	IValue( double value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY ) :
			Value( value, num_elements, storage ) { }
	IValue( glish_complex value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY ) :
			Value( value, num_elements, storage ) { }
	IValue( glish_dcomplex value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY ) :
			Value( value, num_elements, storage ) { }
	IValue( charptr value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY ) :
			Value( value, num_elements, storage ) { }
	IValue( funcptr value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY );
	IValue( regexptr value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY );
	IValue( fileptr value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY );

	IValue( glish_boolref& value_ref ) : Value( value_ref ) { }
	IValue( byteref& value_ref ) : Value( value_ref ) { }
	IValue( shortref& value_ref ) : Value( value_ref ) { }
	IValue( intref& value_ref ) : Value( value_ref ) { }
	IValue( floatref& value_ref ) : Value( value_ref ) { }
	IValue( doubleref& value_ref ) : Value( value_ref ) { }
	IValue( complexref& value_ref ) : Value( value_ref ) { }
	IValue( dcomplexref& value_ref ) : Value( value_ref ) { }
	IValue( charptrref& value_ref ) : Value( value_ref ) { }

	~IValue();

	// True if the value is a record corresponding to a agent.
	int IsAgentRecord( int inc_proxy = 0 ) const;
	const ProxyId *GetProxyId( ) const;

	// Returns the agent or function corresponding to the Value.
	Agent* AgentVal( ) const;
	funcptr FuncVal( ) const;
	regexptr RegexVal( ) const;
	fileptr FileVal( ) const;

	// Returns the entire value converted to a single string, with
	// "sep" used to separate array elements.  "max_elements" allows
	// one to specify the maximum number of elements to be printed. If
	// "max_elements" is zero, all elements will be printed, but if
	// it is greater than zero only "max_elements" will be printed.
	// If "use_attr" is true (non-zero), then the value's attributes
	// are used for determining its shape (as a n-D array).
	//
	// Returns a new string, which should be delete'd when done with.
	char* StringVal( char sep = ' ', int max_elements = 0, 
			 int use_attr = 0, int evalable = 0,
			 const char *prefix=0,
			 Str &err = glish_errno ) const;

	// The following accessors return pointers to the underlying value
	// array.  The "const" versions complain with a fatal error if the
	// value is not the given type.  The non-const versions first
	// Polymorph() the values to the given type.  If called for a
	// subref, retrieves the complete underlying value, not the
	// just selected subelements.  (See the XXXRef() functions below.)
	funcptr* FuncPtr( int modify=1 ) const;
	regexptr* RegexPtr( int modify=1 ) const;
	fileptr* FilePtr( int modify=1 ) const;
	agentptr* AgentPtr( int modify=1 ) const;

	funcptr* FuncPtr( int modify=1 );
	regexptr* RegexPtr( int modify=1 );
	fileptr* FilePtr( int modify=1 );
	agentptr* AgentPtr( int modify=1 );

	// These coercions are very limited: they essentially either
	// return the corresponding xxxPtr() (if the sizes match,
	// no "result" is prespecified, and the Value is already
	// the given type) or generate a fatal error.
	funcptr* CoerceToFuncArray( int& is_copy, int size,
			funcptr* result = 0 ) const;
	regexptr* CoerceToRegexArray( int& is_copy, int size,
			regexptr* result = 0 ) const;
	fileptr* CoerceToFileArray( int& is_copy, int size,
			fileptr* result = 0 ) const;

	// Both of the following return a newed value.
	IValue *subscript( const IValue *index, int always_preserve_fields = 0 ) const;
	IValue *operator[]( const IValue *index ) const { return subscript(index); }
	IValue *operator[]( const_value_list *index ) const;

	IValue *ApplyRegx( regexptr *rptr, int rlen, RegexMatch &match );
	IValue *ApplyRegx( regexptr *rptr, int rlen, RegexMatch &match, int *&indices, int &ilen );

	// Return a new value holding the specified subelement(s).
	IValue* ArrayRef( int* indices, int num_indices, int always_preserve_fields=0 ) const;

	// Return a new value holding a reference the specified subelement(s).
	IValue* TrueArrayRef( int* indices, int num_indices, int take_indices = 0,
			      value_reftype vtype = VAL_REF ) const;

	// Pick distinct elements from an array.
	// Returns a newed value
	IValue* Pick( const IValue* index ) const;

	// Return a reference to distinct elements from an array.
	// Returns a newed value
	IValue* PickRef( const IValue* index, int &err );

	// Assign to distinct array elements.
	void PickAssign( const IValue* index, IValue *value );

	// Return a true sub-array reference.
	// Both of the following return a newed value.
	IValue* SubRef( const IValue* index, int &err, value_reftype vtype = VAL_REF );
	IValue* SubRef( const_value_list *args_val, int &err, value_reftype vtype = VAL_REF );

	void Polymorph( glish_type new_type );

	void ByteOpCompute( const IValue* value, int lhs_len, ArithExpr* expr,
			    const char *&err = glish_charptrdummy );
	void ShortOpCompute( const IValue* value, int lhs_len, ArithExpr* expr,
			     const char *&err = glish_charptrdummy );
	void IntOpCompute( const IValue* value, int lhs_len, ArithExpr* expr,
			   const char *&err = glish_charptrdummy );
	void FloatOpCompute( const IValue* value, int lhs_len, ArithExpr* expr,
			     const char *&err = glish_charptrdummy );
	void DoubleOpCompute( const IValue* value, int lhs_len, ArithExpr* expr,
			      const char *&err = glish_charptrdummy );
	void ComplexOpCompute( const IValue* value, int lhs_len, ArithExpr* expr,
			       const char *&err = glish_charptrdummy );
	void DcomplexOpCompute( const IValue* value, int lhs_len, ArithExpr* expr,
				const char *&err = glish_charptrdummy );

	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	void MarkFail( );
	int FailMarked( ) const;

	// Get a description of a non-standard (i.e. interpreter specific) type
	char *GetNSDesc( int evalable = 0 ) const;

	// returns the number of time a cycle root (element of c) is referenced
	int PropagateCycles( NodeList *c, int prune=0 );

	// value can be part of a frame so it can't be deleted, but needs
	// to have everything possible freed...
	int SoftDelete( );

	// Called when we need to cleanup any values to be Unref()ed
	// *before* this value is actually deleted.
	void PreDelete( );

	int SetUnref( NodeList *r, int propagate_only=0 );
	void ClearUnref( );

	void TakeValue( Value* new_value, Str &err = glish_errno );

protected:

	void DeleteValue();

	// ** NOTE THIS CAN PROBABLY BE REMOVED, BUT IT IS LEFT IN FOR NOW **
	// Does the actual work of assigning a list of array elements,
	// once type-checking has been done.
	void AssignArrayElements( int* indices, int num_indices,
				Value* value, int rhs_len );
	void AssignArrayElements( Value* value );

	ReflexPtr(NodeList) unref;

	// Note: if member variables are added, Value::TakeValue()
	//       will need to be examined
	};

extern void init_ivalues();

typedef const IValue const_ivalue;
glish_declare(PList,const_ivalue);
typedef PList(const_ivalue) const_ivalue_list;
typedef PList(const_ivalue) const_args_list;

inline IValue* empty_ivalue(glish_type t = TYPE_INT) { return (IValue*) empty_value(t); }
inline IValue* empty_bool_ivalue() { return (IValue*) empty_bool_value(); }
inline IValue* error_ivalue( ) { return (IValue*) error_value(); }
inline IValue* error_ivalue( const char *message, int auto_fail = 1 )
		{ return (IValue*) error_value(message, auto_fail); }
inline IValue* error_ivalue( const char *message, const char *file, int line, int auto_fail = 1 )
		{ return (IValue*) error_value(message, file, line, auto_fail ); }
inline IValue* false_ivalue() { return new IValue( glish_false ); }
inline IValue* create_irecord() { return (IValue*) create_record(); }
inline IValue* isplit( char* source, char* split_chars = " \t\n" )
	{ return (IValue*) split(source, split_chars); }


extern IValue* bool_rel_op_compute( const IValue* lhs, const IValue* rhs,
				int lhs_len, RelExpr* expr );
extern IValue* byte_rel_op_compute( const IValue* lhs, const IValue* rhs,
				int lhs_len, RelExpr* expr );
extern IValue* short_rel_op_compute( const IValue* lhs, const IValue* rhs,
				int lhs_len, RelExpr* expr );
extern IValue* int_rel_op_compute( const IValue* lhs, const IValue* rhs,
				int lhs_len, RelExpr* expr );
extern IValue* float_rel_op_compute( const IValue* lhs, const IValue* rhs,
				int lhs_len, RelExpr* expr );
extern IValue* double_rel_op_compute( const IValue* lhs, const IValue* rhs,
				int lhs_len, RelExpr* expr );
extern IValue* complex_rel_op_compute( const IValue* lhs, const IValue* rhs,
				int lhs_len, RelExpr* expr );
extern IValue* dcomplex_rel_op_compute( const IValue* lhs, const IValue* rhs,
				int lhs_len, RelExpr* expr );
extern IValue* string_rel_op_compute( const IValue* lhs, const IValue* rhs,
				int lhs_len, RelExpr* expr );

inline IValue *copy_value( const IValue *v ) { return (IValue*) ValCtor::copy( v ); }
inline IValue *deep_copy_value( const IValue *v ) { return (IValue*) ValCtor::deep_copy( v ); }

#endif /* ivalue_h */
