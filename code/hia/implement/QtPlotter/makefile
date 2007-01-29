# $Id: makefile,v 19.0 2003/07/16 06:00:58 aips2adm Exp $
OPT := 2
XLIBLIST:=GLISH QT QWT3
# you must reference the QT and QWT packages in your local makedefs file
# Use the generic AIPS++ class implementation makefile.
#------------------------------------------------------
include $(word 1, $(AIPSPATH))/code/install/makefile.imp

ifeq "$(MAKEMODE)" "programmer"
mocs : moc_QtPlotter.o

else

mocs : $(PCKGOPTD)/moc_QtPlotter.o $(PCKGDBGD)/moc_QtPlotter.o

endif
