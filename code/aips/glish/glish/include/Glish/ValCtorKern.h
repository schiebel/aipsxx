// $Id: ValCtorKern.h,v 19.1 2004/07/13 22:37:01 dschieb Exp $
// Copyright (c) 2004 Associated Universities Inc.
#ifndef valctorkern_h
#define valctorkern_h

#include "Glish/glish.h"

struct glish_complex;
struct glish_dcomplex;

class Value;
class sos_out;
class sos_header;
class ProxyId;

#include "Glish/ValKern.h"

class ValCtorKern {

    public:

  ValCtorKern( ) : collecting_garbage_(0) { }

        virtual Value *create( );
	virtual Value *create( const char *message, const char *file, int line, int auto_fail );
	virtual Value *create( const Value *v, const char *file, int line );
	virtual Value *create( const Value &value );
	virtual Value *create( glish_bool value );
	virtual Value *create( byte value );
	virtual Value *create( short value );
	virtual Value *create( int value );
	virtual Value *create( float value );
	virtual Value *create( double value );
	virtual Value *create( glish_complex value );
	virtual Value *create( glish_dcomplex value );
	virtual Value *create( const char* value );
	virtual Value *create( recordptr value );
	virtual Value *create( Value* ref_value, value_reftype val_type );
	virtual Value *create( Value* ref_value, int index[], int num_elements, value_reftype val_type, int take_index );
	virtual Value *create( glish_bool value[], int num_elements, array_storage_type storage );
	virtual Value *create( byte value[], int num_elements, array_storage_type storage );
	virtual Value *create( short value[], int num_elements, array_storage_type storage );
	virtual Value *create( int value[], int num_elements, array_storage_type storage );
	virtual Value *create( float value[], int num_elements, array_storage_type storage );
	virtual Value *create( double value[], int num_elements, array_storage_type storage );
	virtual Value *create( glish_complex value[], int num_elements, array_storage_type storage );
	virtual Value *create( glish_dcomplex value[], int num_elements, array_storage_type storage );
	virtual Value *create( charptr value[], int num_elements, array_storage_type storage );
	virtual Value *create( glish_boolref& value_ref );
	virtual Value *create( byteref& value_ref );
	virtual Value *create( shortref& value_ref );
	virtual Value *create( intref& value_ref );
	virtual Value *create( floatref& value_ref );
	virtual Value *create( doubleref& value_ref );
	virtual Value *create( complexref& value_ref );
	virtual Value *create( dcomplexref& value_ref );
	virtual Value *create( charptrref& value_ref );

	virtual Value *copy( const Value *val );
	virtual Value *deep_copy( const Value *val );

	virtual Value *error( int auto_fail, const RMessage &a,
			      const RMessage &b = EndMessage, const RMessage &c = EndMessage,
			      const RMessage &d = EndMessage, const RMessage &e = EndMessage,
			      const RMessage &f = EndMessage, const RMessage &g = EndMessage,
			      const RMessage &h = EndMessage, const RMessage &i = EndMessage,
			      const RMessage &j = EndMessage, const RMessage &k = EndMessage,
			      const RMessage &l = EndMessage, const RMessage &m = EndMessage,
			      const RMessage &n = EndMessage, const RMessage &o = EndMessage,
			      const RMessage &p = EndMessage, const RMessage &q = EndMessage );

	virtual Value *error( int auto_fail, const char *file, int line,
			      const RMessage &a, const RMessage &b = EndMessage,
			      const RMessage &c = EndMessage, const RMessage &d = EndMessage,
			      const RMessage &e = EndMessage, const RMessage &f = EndMessage,
			      const RMessage &g = EndMessage, const RMessage &h = EndMessage,
			      const RMessage &i = EndMessage, const RMessage &j = EndMessage,
			      const RMessage &k = EndMessage, const RMessage &l = EndMessage,
			      const RMessage &m = EndMessage, const RMessage &n = EndMessage,
			      const RMessage &o = EndMessage, const RMessage &p = EndMessage,
			      const RMessage &q = EndMessage );

	virtual const Str error_str( const RMessage &a, const RMessage &b = EndMessage,
				     const RMessage &c = EndMessage, const RMessage &d = EndMessage,
				     const RMessage &e = EndMessage, const RMessage &f = EndMessage,
				     const RMessage &g = EndMessage, const RMessage &h = EndMessage,
				     const RMessage &i = EndMessage, const RMessage &j = EndMessage,
				     const RMessage &k = EndMessage, const RMessage &l = EndMessage,
				     const RMessage &m = EndMessage, const RMessage &n = EndMessage,
				     const RMessage &o = EndMessage, const RMessage &p = EndMessage,
				     const RMessage &q = EndMessage );

	virtual void report( const RMessage &a, const RMessage &b = EndMessage,
			     const RMessage &c = EndMessage, const RMessage &d = EndMessage,
			     const RMessage &e = EndMessage, const RMessage &f = EndMessage,
			     const RMessage &g = EndMessage, const RMessage &h = EndMessage,
			     const RMessage &i = EndMessage, const RMessage &j = EndMessage,
			     const RMessage &k = EndMessage, const RMessage &l = EndMessage,
			     const RMessage &m = EndMessage, const RMessage &n = EndMessage,
			     const RMessage &o = EndMessage, const RMessage &p = EndMessage,
			     const RMessage &q = EndMessage );

	virtual void report( const char *file, int line,
			     const RMessage &a, const RMessage &b = EndMessage,
			     const RMessage &c = EndMessage, const RMessage &d = EndMessage,
			     const RMessage &e = EndMessage, const RMessage &f = EndMessage,
			     const RMessage &g = EndMessage, const RMessage &h = EndMessage,
			     const RMessage &i = EndMessage, const RMessage &j = EndMessage,
			     const RMessage &k = EndMessage, const RMessage &l = EndMessage,
			     const RMessage &m = EndMessage, const RMessage &n = EndMessage,
			     const RMessage &o = EndMessage, const RMessage &p = EndMessage,
			     const RMessage &q = EndMessage );

	virtual int print_precision( );
	virtual int print_limit( );
	virtual int silent( );
	virtual int collecting_garbage( );
	virtual void collecting_garbage( int );
	virtual void log( const char *s );
	virtual int do_log( );
	virtual void show_stack( OStream &st );
	virtual int write_agent( sos_out &sos, Value *val, sos_header &head, const ProxyId &id );

	virtual void cleanup( );

  protected:

	int collecting_garbage_;

};

#endif
