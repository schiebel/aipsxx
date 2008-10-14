/* $Id: md5.h,v 19.0 2003/07/16 05:17:01 aips2adm Exp $
**
**  MD5.H - header file for MD5C.C
*/

/* Copyright (C) 1991-2, RSA Data Security, Inc. Created 1991. All
 * rights reserved.
 * 
 * License to copy and use this software is granted provided that it
 * is identified as the "RSA Data Security, Inc. MD5 Message-Digest
 * Algorithm" in all material mentioning or referencing this software
 * or this function.
 * 
 * License is also granted to make and use derivative works provided
 * that such works are identified as "derived from the RSA Data
 * Security, Inc. MD5 Message-Digest Algorithm" in all material
 * mentioning or referencing the derived work.
 * 
 * RSA Data Security, Inc. makes no representations concerning either
 * the merchantability of this software or the suitability of this
 * software for any particular purpose. It is provided "as is"
 * without express or implied warranty of any kind.
 * These notices must be retained in any copies of any part of this
 * documentation and/or software.
 */

/* POINTER defines a generic pointer type */
typedef unsigned char *POINTER;

/* UINT2 defines a two byte word */
typedef unsigned short int UINT2;

/* UINT4 defines a four byte word */
/* This used to be "unsigned long int", but that's problematic for
 * Dec Alphas, and for our purposes it seems unlikely npd will be
 * built on a platform with 16-bit int's.
 */
typedef unsigned int UINT4;

/* MD5 context. */
typedef struct
	{
	UINT4 state[4];	/* state (ABCD) */
	UINT4 count[2];	/* number of bits, modulo 2^64 (lsb first) */
	unsigned char buffer[64];	/* input buffer */
	} MD5_CTX;

void nMD5Init(MD5_CTX *);
void nMD5Update(MD5_CTX *, unsigned char *, unsigned int);
void nMD5Final(unsigned char [16], MD5_CTX *);
