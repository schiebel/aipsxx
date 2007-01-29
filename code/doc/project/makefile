# $Id: makefile,v 19.0 2003/07/16 04:06:30 aips2adm Exp $

beta := -split +0
releasenotes := -split +0
releasenotes09 := -split +0
releasenotes11 := -split +0
releasenotes12 := -split +0
releasenotes13 := -split +0
releasenotes14 := -split +0
releasenotes15 := -split +0
1997q1 := -split 0
1997q2 := -split 0
1997q3 := -split 0
1997q4 := -split 0
1998q1 := -split 0
1998q2 := -split 0
1998q3 := -split 0
1998q4 := -split 0
1999q1 := -split 0
1999q2 := -split 0
1999q3 := -split 0
dev13report := -split 0
dev14report := -split 0
dev15report := -split 0
dev16report := -split 0
decisionlog := -split 0

# This is a special
$(word 1, $(AIPSPATH))/readme.html : toplevel_readme.thtml
	sed -e "s/VERSIONID/`avers | awk -F. '{print \"Version\", \$$1/10, \"Build\", \$$2}'`/" $< > $@

# Use the generic AIPS++ documentation makefile
#----------------------------------------------
include $(word 1, $(AIPSPATH))/code/install/makefile.doc

