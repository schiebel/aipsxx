## $Id: Makefile,v 19.0 2003/07/16 05:14:31 aips2adm Exp $
##

ROOT = ../../../../..

BUILD_DIR=$$ARCH

SHELL = /bin/sh
SH = $(SHELL)

all:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`$(ROOT)/config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(BUILD_DIR); $(MAKE) $$FLGS all)

install:
	@echo Installing tkpgplot ...
	@if test -z "$(ARCH)"; then 				\
		ARCH=`$(ROOT)/config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else 	FLGS=""; fi;					\
	(cd $(BUILD_DIR); $(MAKE) $$FLGS install)

build: all

app:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`$(ROOT)/config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS app

libtkpgdrv.a:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`$(ROOT)/config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS libtkpgdrv.a

clean:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`$(ROOT)/config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS clean

distclean: clean
	@if test -z "$(ARCH)"; then 				\
		ARCH=`$(ROOT)/config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	cd $(BUILD_DIR); $(MAKE) $$FLGS distclean
