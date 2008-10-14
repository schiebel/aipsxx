/* $Id: npd.c,v 19.0 2003/07/16 05:17:02 aips2adm Exp $
**
**  npd - network probe daemon
*/

/*
 * Copyright (c) 1994
 *      The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that: (1) source code distributions
 * retain the above copyright notice and this paragraph in its entirety, (2)
 * distributions including binary code include the above copyright notice and
 * this paragraph in its entirety in the documentation or other materials
 * provided with the distribution, and (3) all advertising materials mentioning
 * features or use of this software display the following acknowledgement:
 * ``This product includes software developed by the University of California,
 * Lawrence Berkeley Laboratory and its contributors.'' Neither the name of
 * the University nor the names of its contributors may be used to endorse
 * or promote products derived from this software without specific prior
 * written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

#include "config.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <memory.h>
#include <signal.h>
#include <time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#include <syslog.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#include "util.h"
RCSID("@(#) $Id: npd.c,v 19.0 2003/07/16 05:17:02 aips2adm Exp $")
#include "auth.h"
#include "version.h"

/* Version of Network Probe Protocol. */
#define NPP_VERSION 1
static char *keys_dir = 0;

void set_key_directory( const char *kd )
	{
	if ( keys_dir ) free_memory( keys_dir );
	keys_dir = (kd ? string_dup(kd) : 0);
	}

const char *get_key_directory( )
	{
	return (keys_dir ? keys_dir : KEYS_DIR);
	}

int create_keyfile()
	{
	static char buf[1024];
	char *s = 0, *ptr = buf;
	if ( ! create_userkeyfile( keys_dir ? keys_dir : KEYS_DIR ) )
		{
		if ( s = getenv("AIPSPATH") )
			{
			while ( *s && *s != ' ' )
				*ptr++ = *s++;
			if ( *s )
				{
				*ptr++ = '/'; *ptr++ = 'k';
				*ptr++ = 'e'; *ptr++ = 'y';
				*ptr++ = 's'; *ptr++ = '\0';
				return create_userkeyfile( buf );
				}
			else
				return 0;
			}
		else
			return 0;
		}
	else
		return 1;
	}

/* Authenticate ourselves to the given peer.  Returns non-zero on success,
 * zero on failure.
 */
static int authenticate_to_peer( FILE *read_, FILE *write_, const char *local_host,
			  const char *remote_host )
	{
	const char *s;
	int version;
	unsigned char *challenge;
	int challenge_len;
	const char *our_username;

	if ( ! create_keyfile() )
		{
		fprintf( stderr, "couldn't create key file" );
		return 0;
		}

	if ( ! (our_username = get_our_username()) )
		{
		fprintf( stderr, "couldn't get our username" );
		return 0;
		}

	fprintf( write_, "hello %s %s %d\n", local_host, our_username, NPP_VERSION );
	fflush( write_ );

	if ( ! (s = get_word_from_peer( read_ )) )
		{
		fprintf( stderr, "peer %s blew us off", remote_host );
		return 0;
		}

	/* Disgusting hack for SunOS systems! */
	if ( ! strcmp( s, "ld.so:" ) )
		{ /* Eat up something like:
	ld.so: warning: /usr/lib/libc.so.1.8 has older revision than expected 9
		   */
		int i;
		for ( i = 0; i < 8; ++i )
			if ( ! (s = get_word_from_peer( read_ )) )
				{
				fprintf( stderr, "peer %s protocol error, hello expected, problem eating ld.so chud\n", remote_host );
				return 0;
				}

		if ( ! (s = get_word_from_peer( read_ )) )
			{
			fprintf( stderr, "peer %s blew us off", remote_host );
			return 0;
			}
		}

	if ( strcmp( s, "hello" ) )
		{ /* Send error message to stderr */
		fprintf( stderr,
			"peer %s protocol error, hello expected, got:\n%s ",
			remote_host, s );
		while ( (s = get_word_from_peer( read_ )) )
			fprintf( stderr, "%s ", s );
		fprintf( stderr, "\n" );
		return 0;
		}

	if ( ! (s = get_word_from_peer( read_ )) ||
	     (version = atoi( s )) <= 0 )
		{
		fprintf( stderr, "peer %s protocol error, bad version: got \"%s\"",
			 remote_host, s ? s : "<EOF>" );
		return 0;
		}

	if ( ! (s = get_word_from_peer( read_ )) ||
	     strcmp( s, "challenge" ) )
		{
		fprintf( stderr, "peer %s protocol error, hello expected, got \"%s\"",
			 remote_host, s ? s : "<EOF>" );
		return 0;
		}

	if ( ! (challenge = read_encoded_binary( read_, &challenge_len )) )
		{
		fprintf( stderr, "bad challenge from peer %s - %s", remote_host, errmsg );
		return 0;
		}

	fprintf( write_, "answer " );
	if ( ! answer_challenge( (keys_dir ? keys_dir : KEYS_DIR), local_host,
				 our_username, write_, challenge, challenge_len ) )
		{
		fprintf( stderr, "answering peer %s's challenge failed - %s",
			 remote_host, errmsg );
		return 0;
		}

	free_memory( challenge );
	fflush( write_ );

	if ( ! (s = get_word_from_peer( read_ )) ||
	     strcmp( s, "accepted" ) )
		{
		fprintf( stderr, "answer not accepted by peer %s", remote_host );
		return 0;
		}

	return 1;
	}

/* Returns true if the peer successfully authenticates itself, false
 * otherwise.
 */
static char **authenticate_peer( FILE *npd_in, FILE *npd_out, struct sockaddr_in *sin )
	{
	unsigned char *answer, *peer_answer;
	static char peer_hostname[256];
	static char peer_username[9];
	static char *OK[3] = { 0, 0, 0 };
	long peer_addr;
	u_long ip_addr;
	int answer_len, peer_answer_len;
	int version;
	struct hostent *h;
	const char *s;
	int uid;
	int i;

	/* return peer information if properly authenticated */
	if ( ! OK[0] )
		{
		OK[0] = peer_username;
		OK[1] = peer_hostname;
		OK[2] = 0;
		}

	/* First, figure out who we're talking to. */
	peer_addr = sin->sin_addr.s_addr;
	if ( ! (h = gethostbyaddr( (char *) &peer_addr,
					sizeof peer_addr, AF_INET )) )
		{
		syslog( LOG_ERR, "could not get peer 0x%X's address", peer_addr );
		return 0;
		}

	ip_addr = ntohl( sin->sin_addr.s_addr );

	syslog( LOG_INFO, "npd peer connection from %s (%d.%d.%d.%d.%d)", h->h_name,
		(ip_addr >> 24) & 0xff, (ip_addr >> 16) & 0xff,
		(ip_addr >> 8) & 0xff, (ip_addr >> 0) & 0xff,
		sin->sin_port );

	/* Search the list of addresses associated with this host to see
	 * if we're being spoofed.
	 */
	for ( i = 0; h->h_addr_list[i]; ++i )
		if ( memcmp( (char *) &peer_addr, (char *) h->h_addr_list[i],
				h->h_length ) == 0 )
			break;

	if ( ! h->h_addr_list[i] )
		{
		syslog( LOG_ERR, "peer appears to be spoofing" );
		return 0;
		}

	s = get_word_from_peer( npd_in );
	if ( ! s || strcmp( s, "hello" ) )
		{
		syslog( LOG_ERR, "peer protocol error, hello expected, got \"%s\"",
			s ? s : "<EOF>" );
		return 0;
		}
	if ( ! (s = get_word_from_peer( npd_in )) )
		{
		syslog( LOG_ERR, "peer protocol error, hostname expected, got \"%s\"",
			s ? s : "<EOF>" );
		return 0;
		}
	if ( strlen( s ) >= sizeof peer_hostname )
		{
		syslog( LOG_ERR, "ridiculously long hostname: \"%s\"", s );
		return 0;
		}
	strcpy( peer_hostname, s );

	if ( ! (s = get_word_from_peer( npd_in )) )
		{
		syslog( LOG_ERR, "peer protocol error, username expected, got \"%s\"",
			s ? s : "<EOF>" );
		return 0;
		}
	if ( strlen( s ) >= sizeof peer_username )
		{
		syslog( LOG_ERR, "ridiculously long username: \"%s\"", s );
		return 0;
		}
	strcpy( peer_username, s );

	/* Verify the peer's alleged host name. */
	if ( ! (h = gethostbyname( peer_hostname )) )
		{
		syslog( LOG_ERR, "can't lookup peer's alleged name: %s", peer_hostname );
		return 0;
		}

	/* Again, search address list to see if we're being spoofed. */
	for ( i = 0; h->h_addr_list[i]; ++i )
		if ( memcmp( (char *) &peer_addr, (char *) h->h_addr_list[i],
				h->h_length ) == 0 )
			break;

	if ( ! h->h_addr_list[i] )
		{
		syslog( LOG_ERR, "peer appears to be spoofing" );
		return 0;
		}

	/* Verify the peer's alleged user name. */
	if ( ! (uid = get_userid( peer_username )) )
		{
		syslog( LOG_ERR, "peer sent bogus user name" );
		return 0;
		}

	/* Prevent access for users who don't have a shell */
	if ( ! get_user_shell( peer_username ) )
		{
		syslog( LOG_ERR, "peer sent bogus user name" );
		return 0;
		}

	if ( ! (s = get_word_from_peer( npd_in )) || (version = atoi( s )) < 1 )
		{
		syslog( LOG_ERR, "peer protocol error, version expected, got \"%s\"",
			s ? s : "<EOF>" );
		return 0;
		}

	fprintf( npd_out, "hello %d challenge\n", NPP_VERSION );
	answer = compose_challenge( (keys_dir ? keys_dir : KEYS_DIR), peer_hostname,
				    peer_username, npd_out, &answer_len );
	if ( ! answer )
		{
		syslog( LOG_ERR, "couldn't compose challenge - %s", errmsg );
		return 0;
		}
	fflush( npd_out );

	if ( ! (s = get_word_from_peer( npd_in )) || strcmp( s, "answer" ) )
		{
		syslog( LOG_ERR, "peer protocol error, answer expected, got \"%s\"",
			s ? s : "<EOF>" );
		return 0;
		}

	if ( ! (peer_answer = read_encoded_binary( npd_in, &peer_answer_len )) )
		{
		syslog( LOG_ERR, "peer protocol error, couldn't get answer - %s", errmsg );
		return 0;
		}

	if ( peer_answer_len != answer_len )
		{
		syslog( LOG_ERR, "peer challenge answer wrong length, %d != %d",
			peer_answer_len, answer_len );
		return 0;
		}

	if ( ! byte_arrays_equal( peer_answer, answer, answer_len ) )
		{
		syslog( LOG_ERR, "peer answer incorrect" );
		return 0;
		}

	fprintf( npd_out, "accepted\n" );
	fflush( npd_out );

	syslog( LOG_INFO, "peer %s authenticated", peer_hostname );

	return OK;
	}

char **authenticate_client(int sock)
	{
	FILE *in, *out;
	struct sockaddr_in sin;
	int len = sizeof( sin );
	char **result = 0;

	if (! (in = fdopen(dup(sock),"r")))
		{
		syslog( LOG_ERR, "could not create FILE* (in)" );
		return 0;
		}
			    
	if (! (out = fdopen(dup(sock),"w")))
		{
		fclose(in);
		syslog( LOG_ERR, "could not create FILE* (out)" );
		return 0;
		}

	if ( getpeername( sock, (struct sockaddr*) &sin, &len ) < 0 )
		{
		fclose(in);
		fclose(out);
		syslog( LOG_ERR, "could not get peer information (fd: 0x%X)", sock );
		return 0;
		}

	result = authenticate_peer(in, out, &sin);
	fclose(in);
	fclose(out);
	return result;
	}

int authenticate_to_server(int sock)
	{
	FILE *in, *out;
	struct sockaddr_in sin;
	int len = sizeof( sin );
	long addr;
	struct hostent *h;
	char local_host[256];
	char remote_host[256];
	int result = 0;

	if (! (in = fdopen(dup(sock),"r")))
		{
		fprintf( stderr, "could not create FILE* (in)" );
		return 0;
		}
			    
	if (! (out = fdopen(dup(sock),"w")))
		{
		fclose(in);
		fprintf( stderr, "could not create FILE* (out)" );
		return 0;
		}

	if ( getsockname( sock, (struct sockaddr*) &sin, &len ) < 0 )
		{
		fclose(in);
		fclose(out);
		fprintf( stderr, "could not get host information (0x%X)", sock );
		return 0;
		}

	addr = sin.sin_addr.s_addr;
	if ( ! (h = gethostbyaddr( (char *) &addr,
					sizeof addr, AF_INET )) )
		{
		fclose(in);
		fclose(out);
		fprintf( stderr, "could not get our information 0x%X's address", addr );
		return 0;
		}

	if ( strlen(h->h_name) > sizeof(local_host) )
		{
		fclose(in);
		fclose(out);
		fprintf( stderr, "ridiculously long hostname: \"%s\"", h->h_name );
		return 0;
		}

	strcpy(local_host,h->h_name);

	if ( getpeername( sock, (struct sockaddr*) &sin, &len ) < 0 )
		{
		fclose(in);
		fclose(out);
		fprintf( stderr, "could not get peer information (fd: 0x%X)", sock );
		return 0;
		}

	addr = sin.sin_addr.s_addr;
	if ( ! (h = gethostbyaddr( (char *) &addr,
					sizeof addr, AF_INET )) )
		{
		fclose(in);
		fclose(out);
		fprintf( stderr, "could not get our information 0x%X's address", addr );
		return 0;
		}

	if ( strlen(h->h_name) > sizeof(remote_host) )
		{
		fclose(in);
		fclose(out);
		fprintf( stderr, "ridiculously long hostname: \"%s\"", h->h_name );
		return 0;
		}

	strcpy(remote_host,h->h_name);

	result = authenticate_to_peer(in, out, local_host, remote_host);

	fclose(in);
	fclose(out);
	return result;
	}
