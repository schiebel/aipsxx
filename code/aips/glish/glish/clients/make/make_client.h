#ifndef bmake_h_
#define bmake_h_

#ifdef __cplusplus
extern "C" {
#endif
	/**
	 **  initialize bmake library
	 **/
	int bMake_Init( int argc, char **argv);
	/** 
	 **  finalize bmake library
	 **/
	int bMake_Finish( );
	/**
	 **  perform make
	 **/
	int bMake( );
	/**
	 **  define a variable
	 **/
	void bMake_Define( const char **var, int var_len, const char **val, int val_len );
	/**
	 **  define a makefile target
	 **/
	void bMake_TargetDef( const char **tag, int tag_len, const char **cmd, int cmd_len, const char **depend, int depend_len);
	/**
	 **  define a suffix rule
	 **/
	void bMake_SuffixDef( const char **tag, int tag_len, const char **cmd, int cmd_len );
	/**
         **  set root targets
	 **/
	void bMake_SetMain( const char **tgt, int len );
	/**
	 **  check to see if root targets have been
	 **  established
	 **/
	int  bMake_HasMain( );
	/**  set the function which is called to
	 **  perform each make action
	 **/
	void bMake_SetActionHandler( void (*)(char*,int) );
	/**  set the function which is called
	 **  when a target is up to date
	 **/
	void bMake_SetUpToDateHandler( void (*)(char*) );

	void Targ_PrintGraph (int);
#ifdef __cplusplus
	}
#endif

#endif
