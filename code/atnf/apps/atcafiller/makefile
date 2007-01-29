# $Id: makefile,v 19.0 2003/07/16 03:35:17 aips2adm Exp $

XLIBLIST := RPFITS F77 GLISH

# Use the generic AIPS++ application makefile.
#---------------------------------------------
include $(word 1, $(AIPSPATH))/code/install/makefile.app

# The trial FORTRAN library contains global symbols which conflict with RPFITS.
DBGLIBS  := $(filter-out %/libtrial_f.a,$(DBGLIBS))
OPTLIBS  := $(filter-out %/libtrial_f.a,$(OPTLIBS))
PGMRLIBR := $(filter-out %/libtrial_f.a,$(PGMRLIBR))
PGMRLIBS := $(filter-out %/libtrial_f.a,$(PGMRLIBS))

