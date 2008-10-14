# $Id: makefile,v 19.3 2004/09/28 06:35:26 mmarquar Exp $
XLIBLIST := MIRLIB GLISH PGPLOT WCSLIB CFITSIO LAPACK F77 IDL Motif XPM X11 MPI

# Use the generic AIPS++ application makefile.
#---------------------------------------------
include $(word 1, $(AIPSPATH))/code/install/makefile.app

# Add MPI and IDL to the standard shared library list defined in makedefs.
XLIBLIST_shared += MPI

XLIBLIST_shared += IDL
