# $Id: makefile,v 19.0 2003/07/16 06:00:54 aips2adm Exp $
OPT := 2
XLIBLIST:=GLISH QT
# you must reference the Qt package in your local makedefs file
# Use the generic AIPS++ class implementation makefile.
#------------------------------------------------------
include $(word 1, $(AIPSPATH))/code/install/makefile.imp


ifeq "$(MAKEMODE)" "programmer"
mocs : moc_QtGlishEvent.o

else

mocs : $(PCKGOPTD)/moc_QtGlishEvent.o $(PCKGDBGD)/moc_QtGlishEvent.o

endif
