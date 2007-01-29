# $Id: makefile,v 19.3 2006/08/24 02:09:49 mcalabre Exp $

# Use the generic AIPS++ package makefile.
#-----------------------------------------
include $(word 1, $(AIPSPATH))/code/install/makefile.pkg

.PHONY : pks pksio

pks :
	 @ $(MAKE) -C $(MAKEIMPD) pks
	 @ $(MAKE) -C $(MAKEAPSD) pks

pksio :
	 @ $(MAKE) -C $(MAKEIMPD) pksio
	 @ $(MAKE) -C $(MAKEAPSD) pksio
