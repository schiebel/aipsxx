// $Id: List.h,v 19.0 2003/07/16 05:15:47 aips2adm Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,2000 Associated Universities Inc.
#ifndef glish_list_h_
#define glish_list_h_

#include <Glish/glish.h>

//
// List.h was moved to the sos library to prserve library
// dependencies. This header file remains for historical
// reasons.
//

inline void *int_to_void(int i)
	{
	void *ret = 0;
	*((int*)&ret) = i;
	return ret;
	}

inline int void_to_int(void *v)
	{
	return *(int*)&v;
	}

#include <sos/list.h>

// Popular type of list: list of strings.
glish_declare(PList,char);
typedef PList(char) name_list;
glish_declare(List,int);
typedef List(int) offset_list;

#include <Glish/Object.h>

#endif /* glish_list_h_ */
