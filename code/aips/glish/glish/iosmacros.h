// $Id: iosmacros.h,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 2001 Associated Universities Inc.
//
#if !defined(iosmacros_h_)
#define iosmacros_h_

#define DEFINE_FUNCS_NO_CHARPTR(MACRO)	\
MACRO(float)			\
MACRO(double)			\
MACRO(int)			\
MACRO(long)			\
MACRO(short)			\
MACRO(char)			\
MACRO(unsigned int)		\
MACRO(unsigned long)		\
MACRO(unsigned short)		\
MACRO(unsigned char)		\
MACRO(void*)

#define DEFINE_FUNCS(MACRO)	\
DEFINE_FUNCS_NO_CHARPTR(MACRO)	\
MACRO(const char*)

#endif
