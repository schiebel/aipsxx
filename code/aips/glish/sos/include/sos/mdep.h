//======================================================================
// sos/mdep.h
//
// $Id: mdep.h,v 19.2 2005/09/02 04:43:43 tcornwel Exp $
//
// Copyright (c) 1997 Associated Universities Inc.
//
//======================================================================
#ifndef sos_mdep_h
#define sos_mdep_h
#include "sos/sos.h"

//======================= PADDING BYTE INFORMATION =======================
/*
  These numbers tell you what broad architecture type you are using; 
  one of these is chosen at compile time to indicate how to pad data
  what sizes data primitives are and what floating point representations
  are used. The choice is made by testing for the standard #defines.

  Adding a new machine may be simple if the correct architecture is 
  already here. Two defined blocks must be added below: one tests for
  the machine type and defines SOS_ARC; in this block you also note if
  shared memory and/or file mapping is available on the system by
  defining SHMEM and/or MEMMAP. In the second block you define
  some of the more generic primitives - for instance whether an int
  is two or four bytes. Byte ordering is picked up automatically.

  If the architecture is not yet available, several things must be done
  before the above stuff can be entered:

  1. NARCS (number of architecture types) increases.
  2. A new architecture is defined as SOS_SUN3ARC, SOS_SPARC etc have
     been below.
  3. A new series of entries need to be made in the static array sos_arcs,
     which appears in the globals file sos_glob.c. An array of
     SOS_NTYPES integers represent the byte boundary of each primitive
     type as defined in this file (SOS_WORD, SOS_LONG etc) and named in
     sos_glob.c. Also, the most restrictive boundary (eg 1 for Vax, 2 for
     680x0, 8 for sparc risc) is put in the sos_arcs array in sos_glob.c.
  4. System-dependant header differences can be ironed out in the file
     sosgen.h
  5. Proceed as above when the architecture was already in place.

  Be careful - in some cases differences happen on the same machine - eg
  VMS and ultrix vaxen - and even with different compilers.

  If you need to add a new primitive type, increase the value of NTYPES
  defined in this file and add entries to the type_name array ,
  the sos_sizes array and the sos_arcs array (sos_glob.c) for
  ALL CURRENT ARCHITECTURES. Add the define for the new type, and
  recompile everything. (Ouch!)

****************************************************************************/

#define SOS_SUN3ARC   0
#define SOS_SPARC     1
#define SOS_VAXARC    2
#define SOS_ALPHAARC  3
#define SOS_HCUBESARC 4

#define  SOS_NARCS  5

//======================================================================
// Defining base architectures and various support styles
//======================================================================
#if defined(mv147) || defined(__mv147__) || defined(VXWORKS)
#define SOS_ARC SOS_SUN3ARC
#endif

//======================================================================
#if defined(__ultrix__)
#define SOS_SHMEM 1
#define SOS_ARC SOS_HCUBESARC
#endif

//======================================================================
#if defined(__ia64__) || defined(__ia64__)
#define SOS_SHMEM 1
#define SOS_ARC SOS_HCUBESARC
#define SOS_BIGADDR 1
#endif

//======================================================================
#if defined(__x86_64__) || defined(__x86_64__)
#define SOS_SHMEM 1
#define SOS_ARC SOS_HCUBESARC
#define SOS_BIGADDR 1
#endif

//======================================================================
#if defined(__i486__) || defined(__i386__)
#define SOS_SHMEM 1
#define SOS_ARC SOS_HCUBESARC
#endif

//======================================================================
#if defined(mips) || defined(__mips__)
#if !defined(sgi) && !defined(__sgi__)
#define MIPS_SWAPPED
#endif 
#if(_MIPS_SZLONG==64)
#define SOS_BIGADDR 1
#endif
#define SOS_SHMEM 1
#define SOS_MEMMAP 1
#define SOS_ARC SOS_SPARC
#endif 

//======================================================================
#if defined(__alpha__)
#define SOS_BIGADDR 1
#define SOS_SHMEM 1
#define SOS_MEMMAP 1
#define SOS_ARC SOS_ALPHAARC
#endif 

//======================================================================
#if defined(apple) || defined(__APPLE_CC__)
#define SOS_SHMEM 1
#define SOS_MEMMAP 1
#define SOS_ARC SOS_SPARC
#endif 

//======================================================================
#if defined(sparc) || defined(__sparc__)
#define SOS_SHMEM 1
#define SOS_MEMMAP 1
#define SOS_ARC SOS_SPARC
#endif 

//======================================================================
#if defined(sun3) || defined(__sun3__)
#define SOS_SHMEM 1
#define SOS_MEMMAP 1
#define SOS_ARC SOS_SUN3ARC
#endif

//======================================================================
#if defined(mac) || defined(__mac__)
#define SOS_ARC SOS_SUN3ARC
#endif

//======================================================================
#if defined(_AIX)
#define SOS_SHMEM 1
#define SOS_ARC SOS_SPARC
#endif

//======================================================================
#if defined(masscomp) || defined(__masscomp__)
#define SOS_SHMEM 1
#define SOS_ARC SOS_SUN3ARC 
#endif 

//======================================================================
#if defined(vax) || defined(__vax__)
#define SOS_ARC SOS_VAXARC
#endif

//======================================================================
#ifdef atari
#define SOS_ARC SOS_SUN3ARC 
#endif 

//======================================================================
#if defined(_AMIGA)
#define SOS_ARC SOS_SUN3ARC
#endif
 
//======================================================================
#if defined(hp9000s800) || defined(__hp9000s800__)
#define SOS_SHMEM 1
#define SOS_ARC SOS_SPARC
#endif

//======================================================================
#if defined(hp9000s300) || defined(__hp9000s300__)
#define SOS_SHMEM 1
#define SOS_ARC SOS_SUN3ARC
#endif

//======================================================================
#if defined(NeXT) || defined(__NeXT__)
#define SOS_ARC SOS_SUN3ARC
#endif

//======================================================================
#ifdef __DGUX__
#define SOS_SHMEM 1
#define SOS_ARC SOS_SPARC
#endif

//======================================================================
#define SOS_SIGNED   0
#define SOS_UNSIGNED 1

//======================================================================
// element type codes
//======================================================================
typedef unsigned char sos_code;
#define SOS_RECORD               (sos_code) 0x00
#define SOS_PADB                 (sos_code) 0x01
#define SOS_BYTE                 (sos_code) 0x02
#define SOS_UNS_BYTE             (sos_code) 0x03
#define SOS_WORD                 (sos_code) 0x04
#define SOS_UNS_WORD             (sos_code) 0x05
#define SOS_LONG                 (sos_code) 0x06
#define SOS_UNS_LONG             (sos_code) 0x07
#define SOS_IFLOAT               (sos_code) 0x08
#define SOS_IDOUBLE              (sos_code) 0x09
#define SOS_VFLOAT               (sos_code) 0x0a
#define SOS_DVDOUBLE             (sos_code) 0x0b
#define SOS_GVDOUBLE             (sos_code) 0x0c
#define SOS_STRING               (sos_code) 0x0d
#define SOS_DIRECTORY_STRUCTURE  (sos_code) 0x0e
#define SOS_ICOMPLEX             (sos_code) 0x0f
#define SOS_IDOUBLE_COMPLEX      (sos_code) 0x10
#define SOS_VCOMPLEX             (sos_code) 0x11
#define SOS_DVDOUBLE_COMPLEX     (sos_code) 0x12
#define SOS_GVDOUBLE_COMPLEX     (sos_code) 0x13
#define SOS_LOGICAL_1            (sos_code) 0x14
#define SOS_LOGICAL_2            (sos_code) 0x15
#define SOS_LOGICAL_4            (sos_code) 0x16
#define SOS_POINTER              (sos_code) 0x17
#define SOS_TIME                 (sos_code) 0x18
#define SOS_SOS                  (sos_code) 0x19
#define SOS_FSTRING              (sos_code) 0x1a
#define SOS_SIZE_MODIFIER        (sos_code) 0x1b
#define SOS_GLISH_VALUE          (sos_code) 0x1c
#define SOS_UNIX_TIME            (sos_code) 0x1d
#define SOS_BITFIELD             (sos_code) 0x1e
#define SOS_INTERNAL_POINTER     (sos_code) 0x1f
#define SOS_DOUBLE_LONG          (sos_code) 0x20
#define SOS_END_BITFIELDS        (sos_code) 0x21
#define SOS_CHAR_BITFIELD        (sos_code) 0x22
#define SOS_SHORT_BITFIELD       (sos_code) 0x23
#define SOS_LONG_BITFIELD        (sos_code) 0x24
#define SOS_DOUBLE_LONG_BITFIELD (sos_code) 0x25
#define SOS_UNS_DOUBLE_LONG      (sos_code) 0x26
// SOS_UNKNOWN is always last
#define SOS_UNKNOWN              (sos_code) 0x27
#define SOS_NTYPES               SOS_UNKNOWN

#define SOS_LAST_BITFIELD        (sos_code) 0x80
#define SOS_BITFIELD_NMASK       (sos_code) 0x7f

//======================================================================
// Defining specific variable types for various architectures, and FP reps
//======================================================================
#if defined(hpux) || defined(__hpux__) \
 || defined(NeXT) || defined(__NeXT__) \
 || defined(sun) || defined(__sun__) || defined (__alpha__) \
 || defined(_AMIGA) || defined(THINK_C) \
 || defined(mac) || defined(__mac__) \
 || defined(__DGUX__) \
 || defined(mv147) || defined(__mv147__) || defined(VXWORKS) \
 || defined(__i486__) || defined(__i386__) || defined(__ia64__) || defined(__x86_64__) \
 || defined(mips) || defined(__mips__) \
 || defined(masscomp) || defined(__masscomp__) || defined(_AIX) \
 || defined(__APPLE_CC__)
#define SOS_IEEEFP
#define SOS_FLOAT SOS_IFLOAT
#define SOS_DOUBLE SOS_IDOUBLE
#define SOS_COMPLEX SOS_ICOMPLEX
#define SOS_DOUBLE_COMPLEX SOS_IDOUBLE_COMPLEX
#define SOS_CHAR SOS_BYTE
#define SOS_INT SOS_LONG
#define SOS_SHORT SOS_WORD
#define SOS_UNS_CHAR SOS_UNS_BYTE
#define SOS_UNS_INT SOS_UNS_LONG
#define SOS_UNS_SHORT SOS_UNS_WORD
#endif

//======================================================================
#ifdef MSDOS
#define SOS_IEEEFP
#define SOS_FLOAT SOS_IFLOAT
#define SOS_DOUBLE SOS_IDOUBLE
#define SOS_COMPLEX SOS_COMPLEX
#define SOS_DOUBLE_COMPLEX SOS_IDOUBLE_COMPLEX
#define SOS_CHAR SOS_BYTE
#define SOS_INT SOS_WORD
#define SOS_SHORT SOS_WORD
#define SOS_UNS_CHAR SOS_UNS_BYTE
#define SOS_UNS_INT SOS_UNS_WORD
#define SOS_UNS_SHORT SOS_UNS_WORD
#endif

//======================================================================
#if defined(vms) || defined(__ultrix__)
#define SOS_VAXFP
#define SOS_CHAR SOS_BYTE
#define SOS_INT SOS_LONG
#define SOS_SHORT SOS_WORD
#define SOS_UNS_CHAR SOS_UNS_BYTE
#define SOS_UNS_INT SOS_UNS_LONG
#define SOS_UNS_SHORT SOS_UNS_WORD
#define SOS_FLOAT SOS_VFLOAT
#define SOS_DOUBLE SOS_DVDOUBLE
#define SOS_COMPLEX SOS_VCOMPLEX
#define SOS_DOUBLE_COMPLEX SOS_DVDOUBLE_COMPLEX
#endif
     
//======================================================================
#ifdef atari
#define SOS_VAXFP
#define SOS_CHAR SOS_BYTE
#define SOS_INT SOS_WORD
#define SOS_SHORT SOS_WORD
#define SOS_UNS_CHAR SOS_UNS_BYTE
#define SOS_UNS_INT SOS_UNS_WORD
#define SOS_UNS_SHORT SOS_UNS_WORD
#define SOS_FLOAT SOS_VFLOAT
#define SOS_DOUBLE SOS_DVDOUBLE
#define SOS_COMPLEX SOS_VCOMPLEX
#define SOS_DOUBLE_COMPLEX SOS_DVDOUBLE_COMPLEX
#endif


//======================================================================
// magic number to identify SOS messages and to catch byte swapping.
#define SOS_MAGIC 0x963cc369

//======================================================================
#if !defined(SOS_BIGADDR)
#define SOS_BIGADDR 0
#endif

#endif
