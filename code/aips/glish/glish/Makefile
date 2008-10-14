## $Id: Makefile,v 19.12 2004/11/03 20:38:58 cvsmgr Exp $
## Copyright (c) 1993 The Regents of the University of California.
## Copyright (c) 1997 Associated Universities Inc.
##
## Note: Glish requires flex version 2.4.6 or greater.  Flex is available
## from ftp.ee.lbl.gov.

TAR_FILE = glish.tar

BUILD_DIR=$$ARCH

SHELL = /bin/sh
SH = $(SHELL)

all:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(BUILD_DIR)/static; $(MAKE) $$FLGS);		\
	(cd $(BUILD_DIR)/shared; $(MAKE) $$FLGS);		\
	(cd clients; $(MAKE) $$FLGS)

install:
	@echo Installing glish ...
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else 	FLGS=""; fi;					\
	(cd $(BUILD_DIR)/static; $(MAKE) $$FLGS install);	\
	(cd $(BUILD_DIR)/shared; $(MAKE) $$FLGS install);	\
	(cd clients; $(MAKE) $$FLGS install)

build: all

glish:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(BUILD_DIR)/static; $(MAKE) $$FLGS);		\
	(cd $(BUILD_DIR)/shared; $(MAKE) $$FLGS)

libglish.a:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS libglish.a

libinterp.a:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS libinterp.a

tar:
	@rm -f $(TAR_FILE).Z tar-files
	@$(MAKE) $(MFLAGS) tar-list >tar-files
	tar cf $(TAR_FILE) -I tar-files
	compress $(TAR_FILE)
	@rm tar-files

tar-list:
	@echo glish >&2
	@ls Makefile.in Makefile config.h.in \
		COPYING glish.init mkinit.sh *.c *.cc *.h *.l *.y \
		*.sed doc/*.ps demos/*.g demos/*.cc demos/*.c \
		demos/README* include/Glish/*.h | grep -v '^config.h$$'
	@cd clients; $(MAKE) $(MFLAGS) tar-list | sed 's,^,clients/,'

rcsinfo:
	@echo glish
	@rlog -L -S RCS/*,v
	@echo glish/include/Glish
	@cd include/Glish; rlog -L -S RCS/*,v
	@cd clients; $(MAKE) $(MFLAGS) rcsinfo

clean:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(BUILD_DIR); $(MAKE) $$FLGS clean);		\
	(cd clients; $(MAKE) $(MFLAGS) clean)

distclean: clean
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../config/architecture`;			\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(BUILD_DIR); $(MAKE) $$FLGS distclean);		\
	(cd clients; $(MAKE) $(MFLAGS) distclean)
