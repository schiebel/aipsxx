# $Id: makefile,v 19.2 2004/10/17 15:46:32 bgarwood Exp $

# prerequisites (as of 16 aug 95)
#
# the entire checked-in contents of code/trial/implement/FITS:
#   BinTable.cc          FITSMultiTable.h     GBTBackendTable.cc
#   BinTable.h           FITSTable.cc         GBTBackendTable.h
#   CopyRecord.cc        FITSTable.h          GBTPositionTable.cc
#   CopyRecord.h         FITSTimedTable.cc    GBTPositionTable.h
#   FITSMultiTable.cc    FITSTimedTable.h
#

# Use the generic AIPS++ application makefile.
#---------------------------------------------
LINKAPP := nrao tasking fits tables casa
XLIBLIST := CFITSIO GLISH 

include $(word 1, $(AIPSPATH))/code/install/makefile.app

