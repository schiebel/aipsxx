## $Id: Makefile,v 19.1 2004/07/13 22:37:01 dschieb Exp $
##
##
## Makefile for glish clients.
##

TAR_FILE = glish-clients.tar

BUILD_DIR=$$ARCH

SHELL = /bin/sh
SH = $(SHELL)

all:
	if test -z "$(ARCH)"; then 				\
		ARCH=`../../../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	if test -d tkpgplot/$(ARCH); then			\
		(cd tkpgplot; $(MAKE) $$FLGS all); fi;		\
	(cd $(BUILD_DIR); $(MAKE) $$FLGS all)

install:
	@echo Installing glish clients ...
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	if test -d tkpgplot/$(ARCH); then			\
		(cd tkpgplot; $(MAKE) $$FLGS install); fi;	\
	cd $(BUILD_DIR); $(MAKE) $$FLGS install

build: all


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
		ARCH=`../../../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS clean

distclean:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS distclean
