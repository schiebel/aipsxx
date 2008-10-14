# $Id: makefile,v 19.8 2005/11/09 04:13:46 mcalabre Exp $

BINEXECS := cubecat gridzilla

XLIBLIST := GLISH RPFITS CFITSIO WCSLIB LAPACK F77
XLIBLIST_shared := GLISH RPFITS CFITSIO WCSLIB LAPACK F77

LINKAPP := atnf tasking ms measures tables scimath casa

# Use the generic AIPS++ application makefile.
#---------------------------------------------
include $(word 1, $(AIPSPATH))/code/install/makefile.app
