## $Id: Makefile,v 19.0 2003/07/16 05:15:43 aips2adm Exp $
##
##
## Makefile for make client.
##

TAR_FILE = glish-clients.tar

STATIC_DIR=$$ARCH

SHELL = /bin/sh
SH = $(SHELL)

all:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(STATIC_DIR); $(MAKE) $$FLGS all);

install:
	@echo Installing glish clients ...
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(STATIC_DIR); $(MAKE) $$FLGS install);

build: all


tar:
	@rm -f $(TAR_FILE).Z tar-files
	@$(MAKE) $(MFLAGS) tar-list >tar-files
	tar cf $(TAR_FILE) -I tar-files
	compress $(TAR_FILE)
	@rm -f tar-files

tar-list:
	@ls Makefile.in *.cc *.c *.h

rcsinfo:
	@echo glish/clients
	@rlog -L -S RCS/*,v

clean:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(STATIC_DIR); $(MAKE) $$FLGS clean);

distclean:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(STATIC_DIR); $(MAKE) $$FLGS distclean);
