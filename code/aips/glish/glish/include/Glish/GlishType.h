/* $Id: GlishType.h,v 19.0 2003/07/16 05:15:49 aips2adm Exp $
** Copyright (c) 1993 The Regents of the University of California.
** Copyright (c) 1997,1998 Associated Universities Inc.
*/
#ifndef glishtype_h
#define glishtype_h


typedef enum {
	/* If you change the order here or add new types, be sure to
	 * update the definition of type_names[] in Value.cc. Also,
	 * update glish_typeinfo[] in ValKern.cc.
	 *
	 * If adding numeric types update the "max_numeric_type" function
	 * definition in Value.cc.
	 */
	TYPE_ERROR,
	TYPE_REF,
	TYPE_SUBVEC_REF,
	TYPE_BOOL, TYPE_BYTE, TYPE_SHORT, TYPE_INT, TYPE_FLOAT, TYPE_DOUBLE,
	TYPE_STRING,
	TYPE_AGENT,
	TYPE_FUNC,
	TYPE_RECORD,
	TYPE_COMPLEX,
	TYPE_DCOMPLEX,
	TYPE_FAIL,
	TYPE_REGEX,
	TYPE_FILE
#define NUM_GLISH_TYPES (((int) TYPE_FILE) + 1)
	} glish_type;

/* Given two types, returns the "maximum" one, that is, which of the two
 * the other should be promoted to.
 */
extern glish_type max_numeric_type( glish_type t1, glish_type t2 );

extern const char* type_names[NUM_GLISH_TYPES];

#endif /* glishtype_h */
