#-----------------------------------------------------------------------------
# GNU makefile provided as an AIPS++ wrapper for the Glish makefiles.
#
# $Id: GNUmakefile,v 19.1 2005/06/13 21:58:11 dschieb Exp $
#-----------------------------------------------------------------------------

# AIPS++ fundamentals.
#---------------------
AIPSROOT := $(word 1, $(AIPSPATH))
AIPSARCH := $(AIPSROOT)/$(word 2, $(AIPSPATH))
include $(AIPSARCH)/makedefs

ARCH   := $(word 2, $(AIPSPATH))
COMPILE_DIR := /kochab_5/dschieb/XXX
FLAGS_ := "BUILD_DIR=$(COMPILE_DIR)/glish/clients/gtk/pgplot/$(ARCH)" "SRC=`pwd`"

all:
	$(MAKE) -f Makefile $(FLAGS)

allsys : glishsys

glishsys :
	$(MAKE) -f Makefile $(FLAGS)

install:
	$(MAKE) -f Makefile $(FLAGS) install

# Static and static pattern rules.
#---------------------------------
.cleansys :
	-$Q $(RM) -r $(ARCH)

