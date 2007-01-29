# $Id: makefile,v 19.0 2003/07/16 04:34:17 aips2adm Exp $

# Use the generic AIPS++ documentation makefile.
#-----------------------------------------------

#gettingresults := -split 3 -link 1 -address 0 -info 0 -show_section_numbers
cbvol1 := -split 3 -link 1 -address 0 -info 0 -show_section_numbers
cbvol2 := -split 3 -link 1 -address 0 -info 0 -show_section_numbers
cbvol3 := -split 3 -link 1 -address 0 -info 0 -show_section_numbers
swdictaips := -split 2 -link 1 -address 0 -info 0
swdictmiriad := -split 2 -link 1 -address 0 -info 0

TIROOT := $(word 1, $(AIPSPATH))/code/doc/cookbook
EXTRA_TEXINPUTS := $(TIROOT)/cookbook.dir

include $(word 1, $(AIPSPATH))/code/install/makefile.doc
