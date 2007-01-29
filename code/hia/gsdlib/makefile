#-----------------------------------------------------------------------------
# GNU makefile for GSDLIB in AIPS++.
#
# $Id: makefile,v 19.0 2003/07/16 06:01:09 aips2adm Exp $
#-----------------------------------------------------------------------------

# AIPS++ fundamentals.
#---------------------
AIPSROOT := $(word 1, $(AIPSPATH))
AIPSARCH := $(AIPSROOT)/$(word 2, $(AIPSPATH))
include $(AIPSARCH)/makedefs


# Temporary directories.
#-----------------------
GSDTMPD  := $(ARCHTMPD)/gsdlib

FIRST := $(shell amkdir -p ug=rwx,g+s,o=rx -v $(GSDTMPD))


# GSDLIB library.
#----------------
GSDLIB := $(LIBOPTD)/libgsd.$(SFXSTAT)


# Source lists.
#--------------
GSDIMPS := $(filter %.c,$(AIPSSRCS))
ifdef AIPSRCS
   GSDIMPS += $(patsubst $(RCSDIR)/%$(comma)v,%,$(wildcard $(RCSDIR)/*/*.c,v))
   GSDIMPS += $(patsubst $(RCSDIR)/%$(comma)v,%,$(wildcard $(RCSDIR)/*/*.f,v))
else
   GSDIMPS += $(subst $(CODEDIR)/,,$(wildcard $(CODEDIR)/*/*.c))
   GSDIMPS += $(subst $(CODEDIR)/,,$(wildcard $(CODEDIR)/*/*.f))
endif


# Pattern rules.
#---------------
$(GSDLIB)(%.o) : $(CODEDIR)/%.c
	-@ echo ""
	-@ echo "$%"
	 @ cd $(GSDTMPD) && $(CC) $(GSDDEFS) -I$(CODEDIR) $(COPT) -c $<
	-@ $(TIMER)

$(GSDLIB)(%.o) : $(CODEDIR)/%.f
	-@ echo ""
	-@ echo "$%"
	 @ cd $(GSDTMPD) && $(F77) $(GSDDEFS) -I$(CODEDIR) $(COPT) -c $<
	-@ $(TIMER)


# Static and static pattern rules.
#---------------------------------
allsys : gsdlib

.cleansys ::
	-$Q $(RM) $(GSDLIB)

gsdlib : $(GSDIMPS:%.c=$(GSDLIB)(%.o)) $(GSDIMPS:%.f=$(GSDLIB)(%.o))
	-@ cd $(GSDTMPD) ; \
	   if [ "`ls *.o 2>/dev/null`" != "" ] ; then \
	      echo "" ; \
	      echo "Updating GSDLIB..." ; \
	      $(AR) $(ARFLAGS) $(GSDLIB) *.o ; \
	      $(RANLIB) $(GSDLIB) ; \
	      $(RM) $(GSDTMPD)/*.o ; \
	   fi

show_local :
	-@ echo ""
	-@ echo "Variables defined in the GSDLIB makefile"
	-@ echo "========================================"
	-@ echo ""
	-@ echo "System"
	-@ echo "------"
	-@ echo "GSDTMPD =$(GSDTMPD)"
	-@ echo "GSDLIB  =$(GSDLIB)"
	-@ echo "GSDIMPS =$(GSDIMPS)"


# Dependency list. (still to do )
#-----------------
