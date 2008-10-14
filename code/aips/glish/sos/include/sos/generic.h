/* ======================================================================
** sos/generic.h
**
** $Id: generic.h,v 19.0 2003/07/16 05:17:41 aips2adm Exp $
**
** Copyright (c) 1997 Associated Universities Inc.
**
** ======================================================================
*/
#ifndef generic_h_
#define generic_h_

#if defined(__STDC__) || defined(__ANSI_CPP__) || defined(__hpux)

#define sos_name2(x, y)         name2_sos(x, y)
#define name2_sos(x, y)         x##y
#define sos_name3(x, y, z)      name3_sos(x, y, z)
#define name3_sos(x, y, z)      x##y##z
#define sos_name4(w, x, y, z)   name4_sos(w, x, y, z)
#define name4_sos(w, x, y, z)   w##x##y##z

#else

#define sos_name2(x, y)         x/**/y
#define sos_name3(x, y, z)      x/**/y/**/z
#define sos_name4(w, x, y, z)   w/**/x/**/y/**/z

#endif

#define sos_declare(x, y)       sos_name2(x, declare)(y)
#define sos_implement(x, y)     sos_name2(x, implement)(y)
#define sos_declare2(x, y, z)   sos_name2(x, declare2)(y, z)
#define sos_implement2(x, y, z) sos_name2(x, implement2)(y, z)

#endif
