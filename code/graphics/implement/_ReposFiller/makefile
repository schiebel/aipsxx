# $Id: makefile,v 1.2 2004/08/25 05:51:28 gvandiep Exp $

# Use the generic AIPS++ class implementation makefile.
#------------------------------------------------------
XLIBLIST := PGPLOT Motif X11
include $(word 1, $(AIPSPATH))/code/install/makefile.imp

# Set up a parallel make if PARALLEL_MAKE is defined in makedefs
ifdef PARALLEL_MAKE
  MAKE := $(PARALLEL_MAKE)
endif
