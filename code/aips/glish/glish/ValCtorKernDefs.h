#ifndef valctorkerndefs_h
#define valctorkerndefs_h

#define DEFINE_CREATE_VALUE(CLASS, TYPE)					\
Value *CLASS::create( )								\
	{ return new TYPE( ); }							\
Value *CLASS::create( const char *message, const char *file, int line, int auto_fail ) \
	{ return new TYPE( message, file, line, auto_fail ); }			\
Value *CLASS::create( const Value *v, const char *file, int line )		\
	{ return new TYPE( v, file, line ); }					\
Value *CLASS::create( const Value &value )					\
	{ return new TYPE( value ); }						\
Value *CLASS::create( glish_bool value )					\
	{ return new TYPE( value ); }						\
Value *CLASS::create( byte value )						\
	{ return new TYPE( value ); }						\
Value *CLASS::create( short value )						\
	{ return new TYPE( value ); }						\
Value *CLASS::create( int value )						\
	{ return new TYPE( value ); }						\
Value *CLASS::create( float value )						\
	{ return new TYPE( value ); }						\
Value *CLASS::create( double value )						\
	{ return new TYPE( value ); }						\
Value *CLASS::create( glish_complex value )					\
	{ return new TYPE( value ); }						\
Value *CLASS::create( glish_dcomplex value )					\
	{ return new TYPE( value ); }						\
Value *CLASS::create( const char* value )					\
	{ return new TYPE( value ); }						\
Value *CLASS::create( recordptr value )						\
	{ return new TYPE( value ); }						\
Value *CLASS::create( Value* ref_value, value_reftype val_type ) 		\
	{ return new TYPE( ref_value, val_type ); }				\
Value *CLASS::create( Value* ref_value, int index[], int num_elements, value_reftype val_type, int take_index ) \
	{ return new TYPE( ref_value, index, num_elements, val_type, take_index ); }\
Value *CLASS::create( glish_bool value[], int num_elements,			\
	array_storage_type storage )						\
		{ return new TYPE( value, num_elements, storage ); }		\
Value *CLASS::create( byte value[], int num_elements,				\
	array_storage_type storage )						\
		{ return new TYPE( value, num_elements, storage ); }		\
Value *CLASS::create( short value[], int num_elements,				\
	array_storage_type storage )						\
		{ return new TYPE( value, num_elements, storage ); }		\
Value *CLASS::create( int value[], int num_elements,				\
	array_storage_type storage )						\
		{ return new TYPE( value, num_elements, storage ); }		\
Value *CLASS::create( float value[], int num_elements,				\
	array_storage_type storage )						\
		{ return new TYPE( value, num_elements, storage ); }		\
Value *CLASS::create( double value[], int num_elements,				\
	array_storage_type storage )						\
		{ return new TYPE( value, num_elements, storage ); }		\
Value *CLASS::create( glish_complex value[], int num_elements,			\
	array_storage_type storage )						\
		{ return new TYPE( value, num_elements, storage ); }		\
Value *CLASS::create( glish_dcomplex value[], int num_elements,			\
	array_storage_type storage )						\
		{ return new TYPE( value, num_elements, storage ); }		\
Value *CLASS::create( charptr value[], int num_elements,			\
	array_storage_type storage )						\
		{ return new TYPE( value, num_elements, storage ); }		\
Value *CLASS::create( glish_boolref& value_ref )				\
	{ return new TYPE( value_ref ); }					\
Value *CLASS::create( byteref& value_ref )					\
	{ return new TYPE( value_ref ); }					\
Value *CLASS::create( shortref& value_ref )					\
	{ return new TYPE( value_ref ); }					\
Value *CLASS::create( intref& value_ref )					\
	{ return new TYPE( value_ref ); }					\
Value *CLASS::create( floatref& value_ref )					\
	{ return new TYPE( value_ref ); }					\
Value *CLASS::create( doubleref& value_ref )					\
	{ return new TYPE( value_ref ); }					\
Value *CLASS::create( complexref& value_ref )					\
	{ return new TYPE( value_ref ); }					\
Value *CLASS::create( dcomplexref& value_ref )					\
	{ return new TYPE( value_ref ); }					\
Value *CLASS::create( charptrref& value_ref )					\
	{ return new TYPE( value_ref ); }

#endif
