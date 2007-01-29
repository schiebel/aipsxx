# $Id: makefile,v 19.2 2005/06/15 18:07:56 cvsmgr Exp $

# Use the generic AIPS++ class implementation makefile.
#------------------------------------------------------
include $(word 1, $(AIPSPATH))/code/install/makefile.imp

# Set up a parallel make if PARALLEL_MAKE is defined in makedefs
ifdef PARALLEL_MAKE
  MAKE := $(PARALLEL_MAKE)
endif
