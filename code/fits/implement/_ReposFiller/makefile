# $Id: makefile,v 1.2 2004/09/29 13:17:11 gvandiep Exp $

XLIBLIST := CFITSIO

# Use the generic AIPS++ class implementation makefile.
#------------------------------------------------------
include $(word 1, $(AIPSPATH))/code/install/makefile.imp

# Set up a parallel make if PARALLEL_MAKE is defined in makedefs.
ifdef PARALLEL_MAKE
  MAKE := $(PARALLEL_MAKE)
endif
