//======================================================================
// types.cc
//
// $Id: types.cc,v 19.0 2003/07/16 05:17:49 aips2adm Exp $
//
// Copyright (c) 1997,2002 Associated Universities Inc.
//
//======================================================================
#include "sos/sos.h"
RCSID("@(#) $Id: types.cc,v 19.0 2003/07/16 05:17:49 aips2adm Exp $")
#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "sos/mdep.h"

#if !defined(VXWORKS)
#include <sys/time.h>
#endif
#include <sys/types.h>
#include <unistd.h>

#if defined(__SUN5)
#else
#if defined(__linux__)
#include <fpu_control.h>
#include <linux/limits.h>
#else
#if defined(VXWORKS)
#include <types/vxParams.h>
#else
#include <sys/param.h>
#endif
#endif
#endif

#if !defined(VXWORKS)
#if !defined(__MSDOS__) 
#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif
#include <memory.h>
#else
#include <alloc.h>
#include <mem.h>
#endif
#endif

//======================================================================
// The sizes of all the primitive types on the current architecture, in bytes 
//======================================================================
char sos_type_sizes[SOS_NTYPES] =  {
  (char) 0,                      // struct
  (char) sizeof(char),           // pad - unused
  (char) sizeof(char),           // byte
  (char) sizeof(char),           // unsigned byte
  (char) sizeof(short),          // word
  (char) sizeof(short),          // unsigned word
#if (SOS_BIGADDR == 1)           // 8-byte address and long
  (char) sizeof(int),            // 4-byte integer
  (char) sizeof(int),            // unsigned 4-byte integer
#else
  (char) sizeof(long),           // 4-byte integer
  (char) sizeof(long),           // unsigned 4-byte integer
#endif
  (char) sizeof(float),          // float
  (char) sizeof(double),         // double
  (char) sizeof(float),          // vax float
  (char) sizeof(double),         // vax D-double
  (char) sizeof(double),         // vax G-double
  (char) 1,                      // C string - zero terminated
//(char) sizeof(struct direc),   // direc structure
  (char) 0,                      // direc structure
  (char) 2*sizeof(float),        // complex
  (char) 2*sizeof(double),       // double complex
  (char) 2*sizeof(float),        // vax complex
  (char) 2*sizeof(double),       // vax D-double complex
  (char) 2*sizeof(double),       // vax G-double complex
  (char) sizeof(char),           // logical byte
  (char) sizeof(short),          // logical word
#if (SOS_BIGADDR == 1)           // 8-byte address and long
  (char) sizeof(int),            // logical 4-byte
#else                           
  (char) sizeof(long),           // logical 4-byte
#endif
  (char) sizeof(char*),          // pointer
  (char) 2*sizeof(long),         // time (eg sybase time )
  (char) 0,                      // Sos
  (char) 1,                      // fixed length string, no terminator
#if (SOS_BIGADDR == 1)           // 8-byte address and long
  (char) sizeof(int),            // size modifier
#else                           
  (char) sizeof(long),           // size modifier
#endif
  (char) sizeof(void*),          // Glish value
#if (SOS_BIGADDR == 1)           // 8-byte address and long
  (char) sizeof(int),            // Unix time is an int
#else                           
  (char) sizeof(long),           // Unix time is a long
#endif
  (char) 0,                      // bitfield
#if (SOS_BIGADDR == 1)           // 8-byte address and long
  (char) sizeof(long),           // internal pointer is a long
  (char) sizeof(long),           // 8-byte integer   is a long
#else                           
  (char) sizeof(int),            // internal pointer is an int
  (char) 2*sizeof(long),         // 8-byte integer   is two long
#endif
  (char) 0,                      // End bitfield
  (char) sizeof(char),           // byte bitfield
  (char) sizeof(short),          // word bitfield
#if (SOS_BIGADDR == 1)           // 8-byte address and long
  (char) sizeof(int),            // 4-byte bitfield
  (char) sizeof(long),           // 8-byte bitfield
  (char) sizeof(long),           // 8-byte unsigned long
#else                           
  (char) sizeof(long),           // 4-byte bitfield
  (char) 2*sizeof(long),         // 8-byte bitfield
  (char) 2*sizeof(long),         // 8-byte unsigned long
#endif
};

//======================================================================
// ...and the corresponding names
//======================================================================
char *sos_type_names[SOS_NTYPES + 1] = {
  "Structure",              
  "Pad", 
  "Byte", 
  "Uns Byte",
  "Word",
  "Uns Word",
  "Long32",
  "Uns Long32",
  "Float",
  "Double",
  "Vax Float",
  "Vax D-Double",
  "Vax G-Double",
  "C-String",
  "Direc",
  "Complex",
  "Complex Double",
  "Vax Complex",
  "Vax Complex D-Double",
  "Vax Complex G-Double",
  "Logical Byte",
  "Logical Word",
  "Logical Long32",
  "Pointer",
  "Time",
  "Sos",
  "F-String",
  "Size Modifier",
  "Glish Value",
  "Unix Time",
  "Bitfield",
  "Internal Pointer",
  "Long64",
  "End Bitfield",
  "Char Bitfield",
  "Short Bitfield",
  "Long32 Bitfield",
  "Long64 Bitfield",
  "UnsLong64",
  "Unknown Type"
};

char *sos_ctype_names[SOS_NTYPES + 1] = {
  "struct",              
  "char", 
  "char", 
  "unsigned char",
  "short",
  "unsigned short",
  "long",
  "unsigned long",
  "float",
  "double",
  "Vax Float",
  "Vax D-Double",
  "Vax G-Double",
  "char",
  "struct direc {",
  "Complex",
  "Complex Double",
  "Vax Complex",
  "Vax Complex D-Double",
  "Vax Complex G-Double",
  "char",
  "short",
  "long",
  "void *",
  "long",
  "Sos",
  "char",
  "Size Modifier",
  "Glish Value",
  "long",
  "Bitfield",
  "Internal Pointer",
  "Long64",
  "End Bitfield",
  "Char Bitfield",
  "Short Bitfield",
  "Long32 Bitfield",
  "Long64 Bitfield",
  "long long",
  "Unknown Type"
};

char  sos_byte_boundary[SOS_NARCS] = { 2,8,1,8,4};

//======================================================================
// The following gives alignment for different SOS_XXX
// Note that there is a special code for SOS_BITFIELD whose alignment
// is only there to pad the array correctly - its alignment depends
// on where it is in its integer or short or whatever. SOS_BITFIELD
// types modify whatever integer type they follow. Here their 
// alignment is marked '0'.
//======================================================================
char  sos_type_alignment[SOS_NARCS][SOS_NTYPES] =  {
  {2, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, /* 680x0 */
   1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 1,
   1, 2, 2, 2, 0, 2, 2, 0, 1, 2, 2, 2, 2},
  {8, 1, 1, 1, 2, 2, 4, 4, 4, 8, 4, 8, 8, /* SUN, HP MIPS RISC */
   1, 4, 4, 8, 4, 8, 8, 1, 2, 4, 4, 4, 1,
   1, 4, 4, 4, 0, 4, 4, 0, 1, 2, 4, 4, 4},
  {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, /* VAX VMS */
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1},
  {8, 1, 1, 1, 2, 2, 4, 4, 4, 8, 4, 8, 8, /* Alpha.8byte long,addr */
   1, 8, 4, 8, 4, 8, 8, 1, 2, 4, 8, 4, 1,
   1, 4, 8, 4, 0, 8, 8, 0, 1, 2, 4, 8, 8},
  {4, 1, 1, 1, 2, 2, 4, 4, 4, 4, 4, 4, 4, /* ultrix, hypercube */
   1, 4, 4, 4, 4, 4, 4, 1, 2, 4, 4, 4, 1,
   1, 4, 4, 4, 0, 4, 4, 0, 1, 2, 4, 4, 4}
};

