## $Id: Makefile,v 19.0 2003/07/16 05:17:15 aips2adm Exp $
##
##
##  Makefile for gcmem C libraries.
##

TAR_FILE = gcmem.tar

BUILD_DIR=$$ARCH

SHELL = /bin/sh
SH = $(SHELL)

all:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(BUILD_DIR); $(MAKE) $$FLGS)

install:
	@echo Installing gcmem ...
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(BUILD_DIR); $(MAKE) $$FLGS install)

build: all

libgcmem.a:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS libgcmem.a

tar:
	@rm -f $(TAR_FILE).Z tar-files
	@$(MAKE) $(MFLAGS) tar-list >tar-files
	tar cf $(TAR_FILE) -I tar-files
	compress $(TAR_FILE)
	@rm -f tar-files

tar-list:
	@echo gcmem >&2
	@ls Makefile.in *.c include/gcmem/*.h Doc/*

rcsinfo:
	@echo gcmem
	@rlog -L RCS/*,v | sed -n -e 's/Working file://p' -e 's/locked by//p'
	@echo gcmem/include/gcmem
	@cd include/gcmem;rlog -L RCS/*,v | sed -n -e 's/Working file://p' -e 's/locked by//p'

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
