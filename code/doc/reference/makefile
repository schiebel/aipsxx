# $Id: makefile,v 19.0 2003/07/16 04:19:17 aips2adm Exp $

# Declare LaTeX documents to be converted to HTML by setting latex2html flags.
Admin   := -split +2
System   := -split +2
HowTos   := -split +2
Coding   := -split +3
Glish    := -split +2
online   := -split 0 -no_navigation -info 0

TIROOT := $(word 1, $(AIPSPATH))/code/doc
EXTRA_TEXINPUTS := $(TIROOT)/memos/111.dir:$(TIROOT)/notes/156.dir:$(TIROOT)/notes/167.dir:$(TIROOT)/notes/170.dir:$(TIROOT)/notes/195.dir:$(TIROOT)/notes/196.dir

# Use the generic AIPS++ documentation makefile
#----------------------------------------------
include $(word 1, $(AIPSPATH))/code/install/makefile.doc
