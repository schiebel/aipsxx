#-----------------------------------------------------------------------------
# GNU makefile provided as an AIPS++ wrapper for the Glish makefiles.
#
# $Id: GNUmakefile,v 19.1 2005/06/13 21:58:07 dschieb Exp $
#-----------------------------------------------------------------------------

# AIPS++ fundamentals.
#---------------------
AIPSROOT := $(word 1, $(AIPSPATH))
AIPSARCH := $(AIPSROOT)/$(word 2, $(AIPSPATH))
include $(AIPSARCH)/makedefs

ARCH   := $(word 2, $(AIPSPATH))
COMPILE_DIR := /kochab_5/dschieb/XXX
FLAGS_ := "BUILD_DIR=$(COMPILE_DIR)/glish/clients/gtk/$(ARCH)" "SRC=`pwd`"

all:
	$(MAKE) -f Makefile $(FLAGS)

allsys : glishsys

glishsys :
	$(MAKE) -f Makefile $(FLAGS)

install:
	$(MAKE) -f Makefile $(FLAGS) install


build.pgplot:
	$(MAKE) -f Makefile build.pgplot

install.pgplot:
	$(MAKE) -f Makefile install.pgplot

clean.pgplot:
	$(MAKE) -f Makefile clean.pgplot

distclean.pgplot:
	$(MAKE) -f Makefile distclean.pgplot

build.pgplot_r:
	$(MAKE) -f Makefile build.pgplot_r

build.pgplot_r_r:
	$(MAKE) -f Makefile build.pgplot_r_r

install.pgplot_r:
	$(MAKE) -f Makefile install.pgplot_r

install.pgplot_r_r:
	$(MAKE) -f Makefile install.pgplot_r_r

clean.pgplot_r:
	$(MAKE) -f Makefile clean.pgplot_r

clean.pgplot_r_r:
	$(MAKE) -f Makefile clean.pgplot_r_r

distclean.pgplot_r:
	$(MAKE) -f Makefile distclean.pgplot_r

distclean.pgplot_r_r:
	$(MAKE) -f Makefile distclean.pgplot_r_r

##
## Dummy targets
##
install-:

clean-:

distclean-:

# Static and static pattern rules.
#---------------------------------
.cleansys :
	-$Q $(RM) -r $(ARCH)

