//======================================================================
// sos/types.h
//
// $Id: types.h,v 19.0 2003/07/16 05:17:39 aips2adm Exp $
//
// Copyright (c) 1997 Associated Universities Inc.
//
//======================================================================
#ifndef sos_types_h
#define sos_types_h
#include "sos/mdep.h"

extern char sos_type_sizes[SOS_NTYPES];
extern char *sos_type_names[SOS_NTYPES + 1];
extern char *sos_ctype_names[SOS_NTYPES + 1];
extern char sos_byte_boundary[SOS_NARCS];
extern char sos_type_alignment[SOS_NARCS][SOS_NTYPES];

inline char *sos_typename(sos_code code)
	{
	return code > SOS_NTYPES ? sos_type_names[SOS_NTYPES] : sos_type_names[code];
	}

inline char *sos_c_typename(sos_code code)
	{
	return code > SOS_NTYPES ? sos_ctype_names[SOS_NTYPES] : sos_ctype_names[code];
	}

inline char sos_size(sos_code code)
	{
	return code > SOS_NTYPES ? (char)0 : sos_type_sizes[code];
	}

inline char sos_align(sos_code code, int arc = SOS_ARC )
	{
	return arc < 0 || arc > SOS_NARCS || code > SOS_NTYPES ?
		(char)0 : sos_type_alignment[arc][code];
	}

inline char *sos_alignS( int arc = SOS_ARC )
	{
	return sos_type_alignment[arc];
	}

inline char sos_boundary(int arc = SOS_ARC )
	{
	return sos_byte_boundary[arc];
	}


#endif
