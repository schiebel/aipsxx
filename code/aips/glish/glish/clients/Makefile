## $Id: Makefile,v 19.0 2003/07/16 05:14:21 aips2adm Exp $
##
##
## Makefile for glish clients.
##

TAR_FILE = glish-clients.tar

BUILD_DIR=$$ARCH

SHELL = /bin/sh
SH = $(SHELL)

all:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS all
	(cd glishtk; $(MAKE) $$FLGS)
	(cd make; $(MAKE) $$FLGS)

install:
	@echo Installing glish clients ...
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS install
	(cd glishtk; $(MAKE) $$FLGS install)
	(cd make; $(MAKE) $$FLGS install)

build: all

glishd:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS glishd

echo_client:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS echo_client

echo_mclient:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS echo_mclient

shell_client:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS shell_client

tell_glishd:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS tell_glishd

test_client:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS test_client

timer:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS timer

multiplexer:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS multiplexer

tar:
	@rm -f $(TAR_FILE).Z tar-files
	@$(MAKE) $(MFLAGS) tar-list >tar-files
	tar cf $(TAR_FILE) -I tar-files
	compress $(TAR_FILE)
	@rm -f tar-files

tar-list:
	@ls Makefile.in *.cc

rcsinfo:
	@echo glish/clients
	@rlog -L -S RCS/*,v

clean:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS clean

distclean:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS distclean
