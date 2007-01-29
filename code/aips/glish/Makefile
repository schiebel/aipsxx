## $Id: Makefile,v 19.2 2004/07/13 22:37:00 dschieb Exp $
##

CWD=.
SHELL = /bin/sh
SH = $(SHELL)

all: include
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;		 		\
	$(MAKE) $$FLGS $@_r

install: include
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi; 				\
	$(MAKE) $$FLGS $@_r

clean:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi; 				\
	$(MAKE) $$FLGS $@_r

distclean:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS="";			fi; 	\
	$(MAKE) $$FLGS $@_r

include:
	if test ! -d "include"; then			\
	     mkdir include;				\
	fi
	cd include;							\
	if test ! -h sos; then ln -s ../sos/include/sos sos; fi;	\
	if test ! -h Npd; then ln -s ../npd/include/Npd Npd; fi;	\
	if test ! -h regx; then ln -s ../regx/include/regx regx; fi

all_r: 
	@echo "Building Glish for $(ARCH)"
	@$(MAKE) build.npd
	@$(MAKE) build.sos
	@$(MAKE) build.regx
	@$(MAKE) build.editline
	@$(MAKE) build.glish

install_r: 
	@echo "Installing Glish for $(ARCH)"
	@$(MAKE) install.sos
	@$(MAKE) install.regx
	@$(MAKE) install.editline
	@$(MAKE) install.npd
	@$(MAKE) install.glish

clean_r:
	@echo "Cleaning Glish for $(ARCH)"
	@$(MAKE) clean.sos
	@$(MAKE) clean.regx
	@$(MAKE) clean.editline
	@$(MAKE) clean.npd
	@$(MAKE) clean.glish

distclean_r:
	@echo "Removing Everything for $(ARCH)"
	@$(MAKE) distclean.sos
	@$(MAKE) distclean.regx
	@$(MAKE) distclean.editline
	@$(MAKE) distclean.npd
	@$(MAKE) distclean.glish
	@rm -rf $(ARCH)

##
## Building SOS
##
build.sos:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS="";  fi;			 	\
	cd sos; $(MAKE) $$FLGS

install.sos:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd sos; $(MAKE) $$FLGS install

clean.sos:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd sos; $(MAKE) $$FLGS clean

distclean.sos:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd sos; $(MAKE) $$FLGS distclean
##
## Building REGX
##
build.regx:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS="";  fi;			 	\
	cd regx; $(MAKE) $$FLGS

install.regx:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd regx; $(MAKE) $$FLGS install

clean.regx:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd regx; $(MAKE) $$FLGS clean

distclean.regx:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd regx; $(MAKE) $$FLGS distclean

##
## Building Editline
##
build.editline:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd editline; $(MAKE) $$FLGS

install.editline:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd editline; $(MAKE) $$FLGS install

clean.editline:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd editline; $(MAKE) $$FLGS clean

distclean.editline:
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd editline; $(MAKE) $$FLGS distclean

##
## Building Glish
##
build.glish: 
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd glish; $(MAKE) $$FLGS

install.glish: 
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd glish; $(MAKE) $$FLGS install

clean.glish: 
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd glish; $(MAKE) $$FLGS clean

distclean.glish: 
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	cd glish; $(MAKE) $$FLGS distclean

##
## Building NPD
##
build.npd: 
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	$(MAKE) $$FLGS $@_r

build.npd_r: 
	@if test -z "$(BUILD_NPD)"; then 		\
		FLGS="BUILD_NPD=`head -1 $(CWD)/$(ARCH)/glish.options`"; \
	else 	FLGS=""; fi;				\
	$(MAKE) $$FLGS $@_r

build.npd_r_r: $(BUILD_NPD)

BUILD_NPD: 
	@cd npd; $(MAKE)

install.npd: 
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi; 				\
	$(MAKE) $$FLGS $@_r

install.npd_r: 
	@if test -z "$(BUILD_NPD)"; then 		\
		FLGS="BUILD_NPD=`head -1 $(CWD)/$(ARCH)/glish.options`"; \
	else 	FLGS=""; fi;				\
	$(MAKE) $$FLGS $@_r

install.npd_r_r: install-$(BUILD_NPD)

install-BUILD_NPD:
	@cd npd; $(MAKE) install

clean.npd: 
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;				\
	$(MAKE) $$FLGS $@_r

clean.npd_r: 
	@if test -z "$(BUILD_NPD)"; then 		\
		FLGS="BUILD_NPD=`head -1 $(CWD)/$(ARCH)/glish.options`"; \
	else 	FLGS=""; fi;				\
	$(MAKE) $$FLGS $@_r

clean.npd_r_r: clean-$(BUILD_NPD)

clean-BUILD_NPD: 
	@cd npd; $(MAKE) clean

distclean.npd: 
	@if test -z "$(ARCH)"; then 			\
		FLGS="ARCH=`config/architecture`";	\
	else 	FLGS=""; fi;			 	\
	$(MAKE) $$FLGS $@_r

distclean.npd_r: 
	@if test -z "$(BUILD_NPD)"; then 		\
		FLGS="BUILD_NPD=`head -1 $(CWD)/$(ARCH)/glish.options`"; \
	else 	FLGS=""; fi;				\
	$(MAKE) $$FLGS $@_r

distclean.npd_r_r: distclean-$(BUILD_NPD)

distclean-BUILD_NPD: 
	@cd npd; $(MAKE) distclean

##
## Dummy targets
##
install-:

clean-:

distclean-:

