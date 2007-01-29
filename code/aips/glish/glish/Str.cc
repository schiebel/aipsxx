// $Id: Str.cc,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1997 Associated Universities Inc.
//

#include "config.h"
#include "Glish/glish.h"
RCSID("@(#) $Id: Str.cc,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $")
#include "Glish/Str.h"
#include "system.h"

StrKernel::~StrKernel()
	{
	if ( str ) free_memory( str );
	}
