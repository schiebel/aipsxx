## $Id: Makefile,v 19.0 2003/07/16 05:14:23 aips2adm Exp $
##
##
## Makefile for glish clients.
##

TAR_FILE = glish-clients.tar

STATIC_DIR=$$ARCH/static
SHARED_DIR=$$ARCH/shared

SHELL = /bin/sh
SH = $(SHELL)

all:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(SHARED_DIR); $(MAKE) $$FLGS all);			\
	(cd $(STATIC_DIR); $(MAKE) $$FLGS all)
	if test -d pgplot; then					\
		$(MAKE) build.pgplot; fi;

#		(cd pgplot; $(MAKE) $$FLGS all); fi;

install:
	@echo Installing glish clients ...
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(SHARED_DIR); $(MAKE) $$FLGS install);		\
	(cd $(STATIC_DIR); $(MAKE) $$FLGS install)
	if test -d pgplot; then					\
		$(MAKE) install.pgplot; fi;

#		(cd pgplot; $(MAKE) $$FLGS install); fi;

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
		ARCH=`../../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(SHARED_DIR); $(MAKE) $$FLGS clean);		\
	(cd $(STATIC_DIR); $(MAKE) $$FLGS clean)
	if test -d pgplot; then					\
		$(MAKE) clean.pgplot; fi;

#		(cd pgplot; $(MAKE) $$FLGS clean); fi;

distclean:
	@if test -z "$(ARCH)"; then 				\
		ARCH=`../../../config/architecture`;		\
		FLGS="$(MFLAGS) ARCH=$$ARCH";			\
	else	FLGS=""; fi;					\
	(cd $(SHARED_DIR); $(MAKE) $$FLGS distclean);		\
	(cd $(STATIC_DIR); $(MAKE) $$FLGS distclean)
	if test -d pgplot; then					\
		$(MAKE) distclean.pgplot; fi;

#		(cd pgplot; $(MAKE) $$FLGS distclean); fi;

##
## Building PGPLOT object
##
build.pgplot: 
	@if test -z "$(ARCH)"; then 				\
		FLGS="ARCH=`../../../config/architecture`";	\
	else 	FLGS=""; fi;				 	\
	$(MAKE) $$FLGS $@_r

build.pgplot_r: 
	@if test -z "$(BUILD_PGPLOT)"; then 			\
		FLGS="BUILD_PGPLOT=`tail -1 ../../../$(ARCH)/glish.options`"; \
	else 	FLGS=""; fi;					\
	$(MAKE) $$FLGS $@_r

build.pgplot_r_r: $(BUILD_PGPLOT)

BUILD_PGPLOT: 
	@cd pgplot; $(MAKE)

install.pgplot: 
	@if test -z "$(ARCH)"; then 				\
		FLGS="ARCH=`../../../config/architecture`";	\
	else 	FLGS=""; fi; 					\
	$(MAKE) $$FLGS $@_r

install.pgplot_r: 
	@if test -z "$(BUILD_PGPLOT)"; then 			\
		FLGS="BUILD_PGPLOT=`tail -1 ../../../$(ARCH)/glish.options`"; \
	else 	FLGS=""; fi;					\
	$(MAKE) $$FLGS $@_r

install.pgplot_r_r: install-$(BUILD_PGPLOT)

install-BUILD_PGPLOT:
	@cd pgplot; $(MAKE) install

clean.pgplot: 
	@if test -z "$(ARCH)"; then 				\
		FLGS="ARCH=`../../../config/architecture`";	\
	else 	FLGS=""; fi;					\
	$(MAKE) $$FLGS $@_r

clean.pgplot_r: 
	@if test -z "$(BUILD_PGPLOT)"; then 			\
		FLGS="BUILD_PGPLOT=`tail -1 ../../../$(ARCH)/glish.options`"; \
	else 	FLGS=""; fi;					\
	$(MAKE) $$FLGS $@_r

clean.pgplot_r_r: clean-$(BUILD_PGPLOT)

clean-BUILD_PGPLOT: 
	@cd pgplot; $(MAKE) clean

distclean.pgplot: 
	@if test -z "$(ARCH)"; then 				\
		FLGS="ARCH=`../../../config/architecture`";	\
	else 	FLGS=""; fi;			 		\
	$(MAKE) $$FLGS $@_r

distclean.pgplot_r: 
	@if test -z "$(BUILD_PGPLOT)"; then 			\
		FLGS="BUILD_PGPLOT=`tail -1 ../../../$(ARCH)/glish.options`"; \
	else 	FLGS=""; fi;					\
	$(MAKE) $$FLGS $@_r

distclean.pgplot_r_r: distclean-$(BUILD_PGPLOT)

distclean-BUILD_PGPLOT: 
	@cd pgplot; $(MAKE) distclean

##
## Dummy targets
##
install-:

clean-:

distclean-:

