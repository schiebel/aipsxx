## $Id: Makefile,v 19.0 2003/07/16 05:17:52 aips2adm Exp $
##
##
##  Makefile for sds C libraries.
##

TAR_FILE = sos.tar

BUILD_DIR=$$ARCH

SHELL = /bin/sh
SH = $(SHELL)

all:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(BUILD_DIR)/static; $(MAKE) $$FLGS);		\
	(cd $(BUILD_DIR)/shared; $(MAKE) $$FLGS)

install:
	@echo Installing sos ...
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(BUILD_DIR)/static; $(MAKE) $$FLGS install);	\
	(cd $(BUILD_DIR)/shared; $(MAKE) $$FLGS install)

build: all

libsos.a:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS libsos.a

tar:
	@rm -f $(TAR_FILE).Z tar-files
	@$(MAKE) $(MFLAGS) tar-list >tar-files
	tar cf $(TAR_FILE) -I tar-files
	compress $(TAR_FILE)
	@rm -f tar-files

tar-list:
	@echo sds >&2
	@ls Makefile.in *.c include/Sds/*.h Doc/*

rcsinfo:
	@echo sos
	@rlog -L RCS/*,v | sed -n -e 's/Working file://p' -e 's/locked by//p'
	@echo sds/include/Sds
	@cd include/Sds;rlog -L RCS/*,v | sed -n -e 's/Working file://p' -e 's/locked by//p'

clean:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS clean

distclean:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS distclean
