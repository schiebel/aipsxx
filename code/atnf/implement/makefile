# $Id: makefile,v 19.2 2006/08/24 02:13:15 mcalabre Exp $

# Use the generic AIPS++ class implementation makefile.
#------------------------------------------------------
include $(word 1, $(AIPSPATH))/code/install/makefile.imp

.PHONY : pks pksio

PKSSUBS := $(addprefix $(CODEDIR)/,PKSIO pks)

pks pksio : $(PKSSUBS) $(LIB)
