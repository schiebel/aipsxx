# $Id: makefile,v 19.3 2004/10/17 16:05:59 bgarwood Exp $

# prerequisites:
#   trial/implement/FITS:
#     BinTable.cc    CopyRecord.h       FITSTable.cc       FITSTimedTable.h
#     BinTable.h     FITSMultiTable.cc  FITSTable.h        GBTBackendTable.cc
#     CopyRecord.cc  FITSMultiTable.h   FITSTimedTable.cc  GBTBackendTable.h


LINKAPP := nrao fits tables casa
XLIBLIST := CFITSIO

# Use the generic AIPS++ application makefile.
#---------------------------------------------

include $(word 1, $(AIPSPATH))/code/install/makefile.app

