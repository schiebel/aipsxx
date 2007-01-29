/*============================================================================
*
*   WCSLIB 4.3 - an implementation of the FITS WCS convention.
*   Copyright (C) 1995-2005, Mark Calabretta
*
*   WCSLIB is free software; you can redistribute it and/or modify it under
*   the terms of the GNU General Public License as published by the Free
*   Software Foundation; either version 2 of the License, or (at your option)
*   any later version.
*
*   WCSLIB is distributed in the hope that it will be useful, but WITHOUT ANY
*   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
*   FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
*   details.
*
*   You should have received a copy of the GNU General Public License along
*   with WCSLIB; if not, write to the Free Software Foundation, Inc.,
*   59 Temple Place, Suite 330, Boston, MA  02111-1307, USA
*
*   Correspondence concerning WCSLIB may be directed to:
*      Internet email: mcalabre@atnf.csiro.au
*      Postal address: Dr. Mark Calabretta
*                      Australia Telescope National Facility, CSIRO
*                      PO Box 76
*                      Epping NSW 1710
*                      AUSTRALIA
*
*   Author: Mark Calabretta, Australia Telescope National Facility
*   http://www.atnf.csiro.au/~mcalabre/index.html
*   $Id: wcsutil.c,v 1.2 2005/12/05 04:06:14 mcalabre Exp $
*===========================================================================*/

#include <string.h>

#include "wcsutil.h"

/*--------------------------------------------------------------------------*/

void wcsutil_blank_fill(int n, char c[])

{
   int k;

   for (k = strlen(c); k < n; k++) {
      c[k] = ' ';
   }

   return;
}

/*--------------------------------------------------------------------------*/

void wcsutil_null_fill(int n, char c[])

{
  int j, k;

  /* Null-fill the string. */
  *(c+n-1) = '\0';
  for (j = 0; j < n; j++) {
    if (c[j] == '\0') {
      for (k = j+1; k < n; k++) {
        c[k] = '\0';
      }
      break;
    }
  }

  for (k = j-1; k > 0; k--) {
    if (c[k] != ' ') break;
    c[k] = '\0';
  }

   return;
}

/*--------------------------------------------------------------------------*/

int wcsutil_allEq(int ncoord, int nelem, const double *first)

{
   double v0;
   const double *vp;

   v0 = *first;
   for (vp = first+nelem; vp < first + ncoord*nelem; vp += nelem) {
     if (*vp != v0) return 0;
   }

   return 1;
}

/*--------------------------------------------------------------------------*/

void wcsutil_setAll(int ncoord, int nelem, double *first)

{
   double v0, *vp;

   v0 = *first;
   for (vp = first+nelem; vp < first + ncoord*nelem; vp += nelem) {
     *vp = v0;
   }
}

/*--------------------------------------------------------------------------*/

void wcsutil_setAli(int ncoord, int nelem, int *first)

{
   int v0, *vp;

   v0 = *first;
   for (vp = first+nelem; vp < first + ncoord*nelem; vp += nelem) {
     *vp = v0;
   }
}

/*--------------------------------------------------------------------------*/

void wcsutil_setBit(int ncoord, int *sel, int bits, int *stat)

{
   int *selp, *statp;

   for (selp = sel, statp = stat; selp < sel + ncoord; selp++, statp++) {
     if (*selp) *statp |= bits;
   }
}
