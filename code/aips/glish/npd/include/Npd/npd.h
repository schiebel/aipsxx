/* $Id: npd.h,v 19.0 2003/07/16 05:16:56 aips2adm Exp $
**
**  npd  --  network probe daemon
**
*/

/*
 * Copyright (c) 1994
 *      The Regents of the University of California.  All rights reserved.
 *
 */

#ifndef npd_h
#define npd_h

#ifdef __cplusplus
extern "C" {
#endif

	char **authenticate_client( int sock );
	int authenticate_to_server( int sock );
	int get_userid( const char *name );
	int get_user_group( const char *name );
	const char *get_group_name( int gid );

	void set_key_directory( const char * );
	const char *get_key_directory( );

	/* Returns 0 upon failure */
	int create_keyfile();
	void init_log(const char *program_name);

	long random_long();

#ifdef __cplusplus
	}
#endif

#endif
