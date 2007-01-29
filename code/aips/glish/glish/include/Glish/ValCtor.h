// $Id: ValCtor.h,v 19.1 2004/07/13 22:37:01 dschieb Exp $
// Copyright (c) 2004 Associated Universities Inc.
#ifndef valctor_h
#define valctor_h

#include "Glish/ValCtorKern.h"
#include "Glish/Value.h"

class ValCtor {

    public:

	static Value *create( )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( ); }
	static Value *create( const char *message, const char *file, int line, int auto_fail=1 )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( message, file, line, auto_fail ); }
	static Value *create( const Value *v, const char *file, int line )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( v, file, line ); }
	static Value *create( const Value &value )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value ); }
	static Value *create( glish_bool value )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value ); }
	static Value *create( byte value )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value ); }
	static Value *create( short value )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value ); }
	static Value *create( int value )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value ); }
	static Value *create( float value )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value ); }
	static Value *create( double value )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value ); }
	static Value *create( glish_complex value )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value ); }
	static Value *create( glish_dcomplex value )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value ); }
	static Value *create( const char* value )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value ); }
	static Value *create( recordptr value )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value ); }
	static Value *create( Value* ref_value, value_reftype val_type )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( ref_value, val_type ); }
	static Value *create( Value* ref_value, int index[], int num_elements, value_reftype val_type, int take_index=0 )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( ref_value, index, num_elements, val_type, take_index ); }
	static Value *create( glish_bool value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value, num_elements, storage ); }
	static Value *create( byte value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value, num_elements, storage ); }
	static Value *create( short value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value, num_elements, storage ); }
	static Value *create( int value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value, num_elements, storage ); }
	static Value *create( float value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value, num_elements, storage ); }
	static Value *create( double value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value, num_elements, storage ); }
	static Value *create( glish_complex value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value, num_elements, storage ); }
	static Value *create( glish_dcomplex value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value, num_elements, storage ); }
	static Value *create( charptr value[], int num_elements,
		array_storage_type storage = TAKE_OVER_ARRAY )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value, num_elements, storage ); }
	static Value *create( glish_boolref& value_ref )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value_ref ); }
	static Value *create( byteref& value_ref )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value_ref ); }
	static Value *create( shortref& value_ref )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value_ref ); }
	static Value *create( intref& value_ref )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value_ref ); }
	static Value *create( floatref& value_ref )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value_ref ); }
	static Value *create( doubleref& value_ref )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value_ref ); }
	static Value *create( complexref& value_ref )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value_ref ); }
	static Value *create( dcomplexref& value_ref )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value_ref ); }
	static Value *create( charptrref& value_ref )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->create( value_ref ); }

	static Value *copy( const Value *val ) 
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->copy( val ); }
	static Value *deep_copy( const Value *val )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->deep_copy( val ); }

	static void report( const RMessage &a, const RMessage &b = EndMessage,
			    const RMessage &c = EndMessage, const RMessage &d = EndMessage,
			    const RMessage &e = EndMessage, const RMessage &f = EndMessage,
			    const RMessage &g = EndMessage, const RMessage &h = EndMessage,
			    const RMessage &i = EndMessage, const RMessage &j = EndMessage,
			    const RMessage &k = EndMessage, const RMessage &l = EndMessage,
			    const RMessage &m = EndMessage, const RMessage &n = EndMessage,
			    const RMessage &o = EndMessage, const RMessage &p = EndMessage,
			    const RMessage &q = EndMessage )
		{ (kernel ? kernel : (kernel = new ValCtorKern( )))->
		    report( a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q ); }

	static void report( const char *file, int line,
			    const RMessage &a, const RMessage &b = EndMessage,
			    const RMessage &c = EndMessage, const RMessage &d = EndMessage,
			    const RMessage &e = EndMessage, const RMessage &f = EndMessage,
			    const RMessage &g = EndMessage, const RMessage &h = EndMessage,
			    const RMessage &i = EndMessage, const RMessage &j = EndMessage,
			    const RMessage &k = EndMessage, const RMessage &l = EndMessage,
			    const RMessage &m = EndMessage, const RMessage &n = EndMessage,
			    const RMessage &o = EndMessage, const RMessage &p = EndMessage,
			    const RMessage &q = EndMessage )
		{ (kernel ? kernel : (kernel = new ValCtorKern( )))->
		    report( file,line,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q ); }

	static Value *error( int auto_fail, const RMessage &a,
			     const RMessage &b = EndMessage, const RMessage &c = EndMessage,
			     const RMessage &d = EndMessage, const RMessage &e = EndMessage,
			     const RMessage &f = EndMessage, const RMessage &g = EndMessage,
			     const RMessage &h = EndMessage, const RMessage &i = EndMessage,
			     const RMessage &j = EndMessage, const RMessage &k = EndMessage,
			     const RMessage &l = EndMessage, const RMessage &m = EndMessage,
			     const RMessage &n = EndMessage, const RMessage &o = EndMessage,
			     const RMessage &p = EndMessage, const RMessage &q = EndMessage )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->
		    error( auto_fail,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q ); }

	static Value *error( const RMessage &a, const RMessage &b = EndMessage,
			     const RMessage &c = EndMessage, const RMessage &d = EndMessage,
			     const RMessage &e = EndMessage, const RMessage &f = EndMessage,
			     const RMessage &g = EndMessage, const RMessage &h = EndMessage,
			     const RMessage &i = EndMessage, const RMessage &j = EndMessage,
			     const RMessage &k = EndMessage, const RMessage &l = EndMessage,
			     const RMessage &m = EndMessage, const RMessage &n = EndMessage,
			     const RMessage &o = EndMessage, const RMessage &p = EndMessage,
			     const RMessage &q = EndMessage )
		{ return error( 1, a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q ); }

	static Value *error( int auto_fail, const char *file, int line,
			     const RMessage &a, const RMessage &b = EndMessage,
			     const RMessage &c = EndMessage, const RMessage &d = EndMessage,
			     const RMessage &e = EndMessage, const RMessage &f = EndMessage,
			     const RMessage &g = EndMessage, const RMessage &h = EndMessage,
			     const RMessage &i = EndMessage, const RMessage &j = EndMessage,
			     const RMessage &k = EndMessage, const RMessage &l = EndMessage,
			     const RMessage &m = EndMessage, const RMessage &n = EndMessage,
			     const RMessage &o = EndMessage, const RMessage &p = EndMessage,
			     const RMessage &q = EndMessage )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->
		    error( auto_fail,file,line,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q ); }

	static Value *error( const char *file, int line,
			     const RMessage &a, const RMessage &b = EndMessage,
			     const RMessage &c = EndMessage, const RMessage &d = EndMessage,
			     const RMessage &e = EndMessage, const RMessage &f = EndMessage,
			     const RMessage &g = EndMessage, const RMessage &h = EndMessage,
			     const RMessage &i = EndMessage, const RMessage &j = EndMessage,
			     const RMessage &k = EndMessage, const RMessage &l = EndMessage,
			     const RMessage &m = EndMessage, const RMessage &n = EndMessage,
			     const RMessage &o = EndMessage, const RMessage &p = EndMessage,
			     const RMessage &q = EndMessage )
		{ return error( 1, file, line, a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q ); }

	static const Str error_str( const RMessage &a, const RMessage &b = EndMessage,
			     const RMessage &c = EndMessage, const RMessage &d = EndMessage,
			     const RMessage &e = EndMessage, const RMessage &f = EndMessage,
			     const RMessage &g = EndMessage, const RMessage &h = EndMessage,
			     const RMessage &i = EndMessage, const RMessage &j = EndMessage,
			     const RMessage &k = EndMessage, const RMessage &l = EndMessage,
			     const RMessage &m = EndMessage, const RMessage &n = EndMessage,
			     const RMessage &o = EndMessage, const RMessage &p = EndMessage,
			     const RMessage &q = EndMessage )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->
		    error_str( a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q ); }

	static int print_precision( )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->print_precision( ); }
	static int print_limit( )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->print_limit( ); }
	static int silent( )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->silent( ); }
	static int collecting_garbage( )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->collecting_garbage( ); }
	static void collecting_garbage( int state )
		{ (kernel ? kernel : (kernel = new ValCtorKern( )))->collecting_garbage( state ); }
	static void log( const char *s )
		{ (kernel ? kernel : (kernel = new ValCtorKern( )))->log( s ); }
	static int do_log( )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->do_log( ); }
	static void show_stack( OStream &st )
		{ (kernel ? kernel : (kernel = new ValCtorKern( )))->show_stack( st ); }
	static int write_agent( sos_out &sos, Value *val, sos_header &head, const ProxyId &id )
		{ return (kernel ? kernel : (kernel = new ValCtorKern( )))->write_agent( sos, val, head, id ); }

	static void cleanup( )
		{ if ( kernel ) kernel->cleanup( ); }

	static void init( ValCtorKern *k ) { if ( kernel ) delete kernel; kernel = k; }

    private:

	static ValCtorKern *kernel;

};

inline Value *copy_value( const Value *v ) { return ValCtor::copy( v ); }
inline Value *deep_copy_value( const Value *v ) { return ValCtor::deep_copy( v ); }

#endif
