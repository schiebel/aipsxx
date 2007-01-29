/* $Id: util.h,v 19.0 2003/07/16 05:16:59 aips2adm Exp $
**
*/

/*
 * Copyright (c) 1994
 *      The Regents of the University of California.  All rights reserved.
 *
 */

#include <stdio.h>
#include "sos/alloc.h"

/* Amount to add to size computations to be sure to avoid fencepost errors. */
#define SLOP 10

/* Maximum size of an encoded binary string. */
#define MAX_ENCODED_BINARY 1024


/* A buffer for holding an error message. */
extern char errmsg[512];

extern FILE *log_file;


/* Grrr, strdup() isn't portable! */
extern char *copy_string( const char *str );

/* Given two byte arrays b1 and b2, both of length n, executes b1 ^= b2. */
extern void xor_together( unsigned char *b1, unsigned char *b2, int len );

/* Returns true if byte arrays b1 and b2 (both of length n) are equal, false
 * otherwise.
 */
extern int byte_arrays_equal( unsigned char *b1, unsigned char *b2, int len );

/* Returns a heap pointer to an array of len random bytes, or nil if not
 * enough memory available.
 */
extern unsigned char *random_bytes( int len );
extern void seed_random_number_generator();
extern long random_long();

/* Reads an encoded binary representation from the given file.  The file
 * format is as an ASCII string.  Whitespace is ignored, as are newlines
 * preceded by '\' (and initial newlines).  Returns a heap pointer and length
 * (in *len_p), or nil if the file format is incorrect or exceeds
 * MAX_ENCODED_BINARY in size.
 */
extern unsigned char *read_encoded_binary( FILE *f, int *len_p );

/* Writes an encoded binary representation to the given file.  The file format
 * is as an ASCII string, suitable for reading via read_encoded_binary().
 */
extern void write_encoded_binary( FILE *f, unsigned char *b, int len );

/* Returns a pointer to a (static region) string giving the next 
 * whitespace-delimited word sent by the peer.  Returns nil on EOF
 * or an excessively large word.
 */
extern const char *get_word_from_peer( FILE *npd_in );

/* Send the entire contents of the given file (regardless of our current
 * position in it) to the given peer.
 */
extern void send_file_to_peer( FILE *file, FILE *peer );

/* Receive the entire contents of a file from a peer and copy it to
 * the given file.  Returns non-zero on success, zero on failure (with
 * a message in errmsg).
 */
extern int receive_file_from_peer( FILE *peer, FILE *file );

/* Connect to the given host/port, returning a socket in *sock_ptr.  Returns
 * non-zero on success, zero on failure (with an error message in errmsg).
 */
extern int connect_to_host( const char *host, int port, int *sock_ptr );

/* Connect the given socket to the given host/port.  Returns non-zero on
 * success, zero on failure (with an error message in errmsg).
 */
extern int connect_socket_to_host( int sock, const char *host, int port );

/*
 * Get the username and userid of the currently running process
 */
extern const char *get_our_username();
extern int get_our_userid();

/*
 * Get any username given a userid or a userid given a username.
 * Return 0 if not found. Note that behavior with get_userid("root").
 */
extern const char *get_username( int id );
extern int get_userid( const char *name );
extern int get_user_group( const char *name );
extern const char *get_user_shell( const char *name );

/*
 * Get the uid of the owner of a file. Returns 0 upon failure.
 * Note the effect of this on files owned by root.
 */
extern int get_file_owner( const char *filename );

/*
 * Check to see if the file is not a link and readable
 * by only by the owner.
 */
extern int is_regfile_protected( const char *filename );

/* Restart the log, reporting success to the given peer. */
extern int restart_log( FILE *peer );

/* Initialize the log functionality, i.e set program name etc. */
extern void init_log(const char *program_name);

/* Put an ID stamp in the log, along with the given message. */
extern void stamp_log( const char *msg );

/* Returns the name of the log file. */
extern const char *npd_log_file();

/* Returns a string description of the given errno.  (Necessary because you
 * can't portably declare sys_errlist! :-()
 */
extern const char *sys_error_desc();

#if ! defined(RCSID)
#if ! defined(NO_RCSID)
#if defined(__STDC__) || defined(__ANSI_CPP__)
#define UsE_PaStE(b) UsE__##b##_
#else
#define UsE_PaStE(b) UsE__/**/b/**/_
#endif
#if defined(__cplusplus)
#define UsE(x) inline void UsE_PaStE(x)(const char *) { UsE_PaStE(x)(x); }
#else
#define UsE(x) static void UsE_PaStE(x)(const char *d) { UsE_PaStE(x)(x); }
#endif
#define RCSID(str)				\
	static const char *rcsid_ = str;	\
	UsE(rcsid_)
#else
#define RCSID(str)
#endif
#endif
