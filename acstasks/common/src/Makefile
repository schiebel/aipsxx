#*******************************************************************************
# E.S.O. - ACS project
#
# "@(#) $Id: Makefile,v 1.1 2005/04/02 01:44:07 ddebonis Exp $"
#
# Makefile of ........
#
# who       when      what
# --------  --------  ----------------------------------------------
# bjeram  2004-09-17  created
#

#*******************************************************************************
# This Makefile follows VLT Standards (see Makefile(5) for more).
#*******************************************************************************
# REMARKS
#    None
#------------------------------------------------------------------------

#
# user definable C-compilation flags
USER_CFLAGS = -g -Wno-deprecated


#
# additional include and library search paths
#

AIPSROOT := $(word 1, $(AIPSPATH))
AIPSARCH := $(word 2, $(AIPSPATH))

ifndef AIPSRPMROOT

## We are NOT using AIPS++ RPMs
##
AIPSLIB  = $(AIPSROOT)/$(AIPSARCH)/lib
VERSION  = $(AIPSROOT)/$(AIPSARCH)/lib/version.o
AIPSINC  = $(AIPSROOT)/code/include
WCSINC   = $(AIPSROOT)/code/casa

else

## We ARE using AIPS++ RPMs
##
AIPSLIB  = $(AIPSRPMROOT)/lib
VERSION  = $(AIPSRPMROOT)/lib/aips++/lib/version.o
AIPSINC  = $(AIPSRPMROOT)/include/aips++
WCSINC   = $(AIPSRPMROOT)/include/aips++

endif

USER_INC =

USER_LIB =      -Xlinker -rpath -Xlinker $(AIPSLIB) \
                -Xlinker --allow-multiple-definition \
                -L$(AIPSLIB) -L/usr/local/lib \
                -lACE \
                -lTAO \
                -lTAO_DsLogAdmin \
                -lTAO_CosNaming \
                -lTAO_IORTable \
                -lTAO_PortableServer \
                -lTAO_Svc_Utils \
                -lTAO_CosTrading \
                -lTAO_DynamicAny \
                -lTAO_IFR_Client \
                -lacsutil \
                -lcdb \
                -llogging \
                -lbaci \
                -lmaci \
                -lmaciClient \
                -lacsnc \
                -lxerces-c \
                $(VERSION)

#
# additional include and library search paths
#USER_INC = 
#USER_LIB = 

#
# MODULE CODE DESCRIPTION:
# ------------------------
# As a general rule:  public file are "cleaned" and "installed"  
#                     local (_L) are not "installed".

#
# C programs (public and local)
# -----------------------------
EXECUTABLES     = 
EXECUTABLES_L   = 

common_CFLAGS =-DAIPS_LINUX -fexceptions -I$(AIPSINC)

# should be :
#testComponent_OBJECTS   = 
# testComponent_LIBS = task execComponentTestImpl
# but acsMakefile has bug	


xxxxx_OBJECTS   =	
xxxxx_LDFLAGS   =
xxxxx_LIBS      =

#
# special compilation flags for single c sources
#yyyyy_CFLAGS   = 

#
# Includes (.h) files (public only)
# ---------------------------------
INCLUDES        =

#
# Libraries (public and local)
# ----------------------------
LIBRARIES       = psetConverter
LIBRARIES_L     = 

#
# <brief description of lllll library>

#
psetConverter_CFLAGS =-DAIPS_LINUX -fexceptions -I$(AIPSINC)
psetConverter_OBJECTS = psetConverter
psetConverter_LIBS = ACSErrTypeCommon baci

# Scripts (public and local)
# ----------------------------
SCRIPTS         =
SCRIPTS_L       =

#
# TCL scripts (public and local)
# ------------------------------
TCL_SCRIPTS     =
TCL_SCRIPTS_L   =

#
# Python stuff (public and local)
# ----------------------------
PY_SCRIPTS         =
PY_SCRIPTS_L       =

PY_MODULES         =
PY_MODULES_L       =

PY_PACKAGES        =
PY_PACKAGES_L      =
pppppp_MODULES	   =

#
# <brief description of tttttt tcl-script>
tttttt_OBJECTS  =
tttttt_TCLSH    = 
tttttt_LIBS     = 

#
# TCL libraries (public and local)
# ------------------------------
TCL_LIBRARIES   =
TCL_LIBRARIES_L =

#
# <brief description of tttlll library>
tttlll_OBJECTS  = 

#
# Configuration Database Files
# ----------------------------
CDB_SCHEMAS = 

# 
# IDL Files and flags
# 
IDL_FILES = 
IDL_TAO_FLAGS =
USER_IDL =
#
# Jarfiles and their directories
#
JARFILES= 
jjj_DIRS=
jjj_EXTRAS= 
#
# java sources in Jarfile on/off
DEBUG= 
#
# ACS XmlIdl generation on/off
#
XML_IDL= 
#
# Java Component Helper Classes generation on/off
#
COMPONENT_HELPERS=
#
# Java Entity Classes generation on/off
#
XSDBIND=
#
# Schema Config files for the above
#
XSDBIND_INCLUDE=
# man pages to be done
# --------------------
MANSECTIONS =
MAN1 =
MAN3 =
MAN5 =
MAN7 =
MAN8 =

#
# local man pages
# ---------------
MANl =

#
# ASCII file to be converted into Framemaker-MIF
# --------------------
ASCII_TO_MIF = 

#
# other files to be installed
#----------------------------
INSTALL_FILES =

#
# list of all possible C-sources (used to create automatic dependencies)
# ------------------------------
CSOURCENAMES = \
	$(foreach exe, $(EXECUTABLES) $(EXECUTABLES_L), $($(exe)_OBJECTS)) \
	$(foreach rtos, $(RTAI_MODULES) , $($(rtos)_OBJECTS)) \
	$(foreach lib, $(LIBRARIES) $(LIBRARIES_L), $($(lib)_OBJECTS))

#
#>>>>> END OF standard rules

#
# INCLUDE STANDARDS
# -----------------
ifdef ACSROOT
    MAKEDIR  = $(shell if [ -f $(INTROOT)/include/acsMakefile ];  then \
                     echo $(INTROOT)/include; \
	           else \
	             echo $(ACSROOT)/include; \
		   fi;)
    include $(MAKEDIR)/acsMakefile
else
    MAKEDIR  = $(shell if [ -f $(INTROOT)/include/vltMakefile ];  then \
                     echo $(INTROOT)/include; \
	           else \
	             echo $(VLTROOT)/include; \
		   fi;)
    include $(MAKEDIR)/vltMakefile
endif

#
# TARGETS
# -------
all:	do_all
	@echo " . . . 'all' done" 

clean : clean_all 
	@echo " . . . clean done"

clean_dist : clean_all clean_dist_all 
	@echo " . . . clean_dist done"

man   : do_man 
	@echo " . . . man page(s) done"

install : install_all
	@echo " . . . installation done"


#___oOo___
