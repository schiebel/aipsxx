# $Id: makefile,v 19.1 2006/06/14 14:24:46 dschieb Exp $

# Use the generic AIPS++ class implementation makefile.
#------------------------------------------------------
XLIBLIST := PGPLOT Motif X11 WCSLIB QT4
include $(word 1, $(AIPSPATH))/code/install/makefile.imp

# Set up a parallel make if PARALLEL_MAKE is defined in makedefs
ifdef PARALLEL_MAKE
  MAKE := $(PARALLEL_MAKE)
endif
