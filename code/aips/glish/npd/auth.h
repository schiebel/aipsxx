/* $Id: auth.h,v 19.0 2003/07/16 05:17:01 aips2adm Exp $
**
*/

/*
 * Copyright (c) 1994
 *      The Regents of the University of California.  All rights reserved.
 *
 */

/* Create the key file for our userid in the given directory if it
 * doesn't already exist. Returns 0 on error, non-zero on success.
 */
int create_userkeyfile( const char *dir );

/* Compose a challenge for communication from the given host.  Write the
 * challenge on the given file, and return the correct answer, or nil
 * on error.
 */
extern unsigned char *compose_challenge( const char *dir, const char *host,
					 const char *user, FILE *f, int *len_p);

/* Answer a challenge for communication to a given host.  Write the
 * answer to the given file.  Returns 0 on error, non-zero on success.
 */
extern int answer_challenge( const char *dir ,const char *host, const char *user,
			     FILE *f, unsigned char *challenge, int len );
