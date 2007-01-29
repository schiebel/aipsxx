// $Id: IValCtorKern.h,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 2004 Associated Universities Inc.
#ifndef ivalctorkern_h
#define ivalctorkern_h

#include "Glish/ValCtorKern.h"
class IValue;

class IValCtorKern : public ValCtorKern {

    public:

        Value *create( );
	Value *create( const char *message, const char *file, int line, int auto_fail );
	Value *create( const Value *v, const char *file, int line );
	Value *create( const Value &value );
	Value *create( glish_bool value );
	Value *create( byte value );
	Value *create( short value );
	Value *create( int value );
	Value *create( float value );
	Value *create( double value );
	Value *create( glish_complex value );
	Value *create( glish_dcomplex value );
	Value *create( const char* value );
	Value *create( recordptr value );
	Value *create( Value* ref_value, value_reftype val_type );
	Value *create( Value* ref_value, int index[], int num_elements, value_reftype val_type, int take_index );
	Value *create( glish_bool value[], int num_elements, array_storage_type storage );
	Value *create( byte value[], int num_elements, array_storage_type storage );
	Value *create( short value[], int num_elements, array_storage_type storage );
	Value *create( int value[], int num_elements, array_storage_type storage );
	Value *create( float value[], int num_elements, array_storage_type storage );
	Value *create( double value[], int num_elements, array_storage_type storage );
	Value *create( glish_complex value[], int num_elements, array_storage_type storage );
	Value *create( glish_dcomplex value[], int num_elements, array_storage_type storage );
	Value *create( charptr value[], int num_elements, array_storage_type storage );
	Value *create( glish_boolref& value_ref );
	Value *create( byteref& value_ref );
	Value *create( shortref& value_ref );
	Value *create( intref& value_ref );
	Value *create( floatref& value_ref );
	Value *create( doubleref& value_ref );
	Value *create( complexref& value_ref );
	Value *create( dcomplexref& value_ref );
	Value *create( charptrref& value_ref );

	Value *copy( const Value *val );
	Value *deep_copy( const Value *val );

	Value *error( int auto_fail, const RMessage &a,
		      const RMessage &b = EndMessage, const RMessage &c = EndMessage,
		      const RMessage &d = EndMessage, const RMessage &e = EndMessage,
		      const RMessage &f = EndMessage, const RMessage &g = EndMessage,
		      const RMessage &h = EndMessage, const RMessage &i = EndMessage,
		      const RMessage &j = EndMessage, const RMessage &k = EndMessage,
		      const RMessage &l = EndMessage, const RMessage &m = EndMessage,
		      const RMessage &n = EndMessage, const RMessage &o = EndMessage,
		      const RMessage &p = EndMessage, const RMessage &q = EndMessage );

	Value *error( int auto_fail, const char *file, int line,
		      const RMessage &a, const RMessage &b = EndMessage,
		      const RMessage &c = EndMessage, const RMessage &d = EndMessage,
		      const RMessage &e = EndMessage, const RMessage &f = EndMessage,
		      const RMessage &g = EndMessage, const RMessage &h = EndMessage,
		      const RMessage &i = EndMessage, const RMessage &j = EndMessage,
		      const RMessage &k = EndMessage, const RMessage &l = EndMessage,
		      const RMessage &m = EndMessage, const RMessage &n = EndMessage,
		      const RMessage &o = EndMessage, const RMessage &p = EndMessage,
		      const RMessage &q = EndMessage );

	const Str error_str( const RMessage &a, const RMessage &b = EndMessage,
			     const RMessage &c = EndMessage, const RMessage &d = EndMessage,
			     const RMessage &e = EndMessage, const RMessage &f = EndMessage,
			     const RMessage &g = EndMessage, const RMessage &h = EndMessage,
			     const RMessage &i = EndMessage, const RMessage &j = EndMessage,
			     const RMessage &k = EndMessage, const RMessage &l = EndMessage,
			     const RMessage &m = EndMessage, const RMessage &n = EndMessage,
			     const RMessage &o = EndMessage, const RMessage &p = EndMessage,
			     const RMessage &q = EndMessage );

	void report( const RMessage &a, const RMessage &b = EndMessage,
		     const RMessage &c = EndMessage, const RMessage &d = EndMessage,
		     const RMessage &e = EndMessage, const RMessage &f = EndMessage,
		     const RMessage &g = EndMessage, const RMessage &h = EndMessage,
		     const RMessage &i = EndMessage, const RMessage &j = EndMessage,
		     const RMessage &k = EndMessage, const RMessage &l = EndMessage,
		     const RMessage &m = EndMessage, const RMessage &n = EndMessage,
		     const RMessage &o = EndMessage, const RMessage &p = EndMessage,
		     const RMessage &q = EndMessage );

	void report( const char *file, int line,
		     const RMessage &a, const RMessage &b = EndMessage,
		     const RMessage &c = EndMessage, const RMessage &d = EndMessage,
		     const RMessage &e = EndMessage, const RMessage &f = EndMessage,
		     const RMessage &g = EndMessage, const RMessage &h = EndMessage,
		     const RMessage &i = EndMessage, const RMessage &j = EndMessage,
		     const RMessage &k = EndMessage, const RMessage &l = EndMessage,
		     const RMessage &m = EndMessage, const RMessage &n = EndMessage,
		     const RMessage &o = EndMessage, const RMessage &p = EndMessage,
		     const RMessage &q = EndMessage );

	int print_precision( );
	int print_limit( );
	int silent( );
	int collecting_garbage( );
	void log( const char *s );
	int do_log( );
	void show_stack( OStream &st );
	int write_agent( sos_out &sos, Value *val, sos_header &head, const ProxyId &id );
	void cleanup( );

};

#endif
