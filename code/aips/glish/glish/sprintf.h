// $Id: sprintf.h,v 19.12 2004/11/03 20:39:00 cvsmgr Exp $
// Copyright (c) 1998 Associated Universities Inc.
#ifndef printf_h
#define printf_h
#include <stdio.h>
#include "IValue.h"

int gsprintf( char **&out, char *format, const_args_list *args, const char *&error=glish_charptrdummy, int arg_off=1 );

#endif
