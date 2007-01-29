#-----------------------------------------------------------------------------
# GNU makefile provided as an AIPS++ wrapper for the Glish makefiles.
#
# $Id: GNUmakefile,v 19.2 2006/08/08 04:19:42 mcalabre Exp $
#-----------------------------------------------------------------------------

# AIPS++ fundamentals.
#---------------------
AIPSROOT := $(word 1, $(AIPSPATH))
AIPSARCH := $(AIPSROOT)/$(word 2, $(AIPSPATH))
include $(AIPSARCH)/makedefs

CPP    :=
ARCH   := $(word 2, $(AIPSPATH))

ifndef GLISH_CXXFLAGS
ifeq "$(MAKEMODE)" "programmer"
GLISH_CXXFLAGS := -g
else
GLISH_CXXFLAGS := $(C++OPTLVL)
endif
endif
ifndef GLISH_CFLAGS
ifeq "$(MAKEMODE)" "programmer"
GLISH_CFLAGS := -g
else
GLISH_CFLAGS := $(COPTLVL)
endif
endif

GLISH_CONFIGFLAGS := --enable-shared --enable-os-malloc $(GLISH_CONFIGFLAGS)

ifndef GLISH_CONFIGFLAGS
ifneq "$(MAKEMODE)" "programmer"
GLISH_CONFIGFLAGS := --enable-shared --enable-os-malloc
endif
endif

##
## Mix in the TCL/Tk directories
##
ifneq "$(strip $(TCLLIBD))" ""
GLISH_TCLCONFIGFLAGS := --tcl-libraries=$(TCLLIBD)
endif
ifneq "$(strip $(TCLINCD))" ""
GLISH_TCLCONFIGFLAGS := $(GLISH_TCLCONFIGFLAGS) --tcl-includes=$(TCLINCD)
endif


MTFLE := .mktree.precious

MotifLIBD  :=
MotifLIB  :=
XTRNLIBS  := $(XLIBPATH) $(foreach XLIB,$(XLIBLIST),$($(XLIB)LIB)) $(ARCHLIBS)

ifneq "$(subst $(space),,$(PGPLOTINCD))" ""
EXTRA_CFLAGS := $(addprefix -I, $(PGPLOTINCD))
EXTRA_CXXFLAGS := $(EXTRA_CFLAGS)
endif

ifneq "$(strip $(wildcard $(addsuffix /*pgplot*, $(PGPLOTLIBD))))" ""

PGP_LINK = $(addprefix -L,$(X11LIBD) $(PGPLOTLIBD) $(F77LIBD)) $(PGPLOTLIB) $(F77LIB) $(ARCHLIBS)
space = $(empty) $(empty)
PGP_LD_SEARCH = $(subst $(space),,$(PGPLOTLIBD) $(addprefix :, $(F77LIBD)))
PGP_INCL = $(addprefix -I, $(PGPLOTINCD))

else

ifeq "$(PGPLOTLIBD)" ""
PGPLOT_WARN = "Error: No pgplot libraries specified"
else
PGPLOT_WARN = "Error: No pgplot libraries found"
endif
PGP_LINK=
PGP_LD_SEARCH=
PGP_INCL=

endif

#
# Files created by configure
#---------------------------------

CONFIG := $(ARCH)/config.status $(ARCH)/glish.options \
	npd/$(ARCH)/static/Makefile npd/$(ARCH)/shared/Makefile \
	sos/$(ARCH)/static/Makefile sos/$(ARCH)/shared/Makefile \
	regx/$(ARCH)/static/Makefile regx/$(ARCH)/shared/Makefile \
	editline/$(ARCH)/static/Makefile editline/$(ARCH)/shared/Makefile \
	glish/$(ARCH)/static/Makefile glish/$(ARCH)/shared/Makefile \
	glish/clients/$(ARCH)/Makefile glish/$(ARCH)/config.h \
	glish/$(ARCH)/config_p.h glish/clients/$(ARCH)/config.h \
	npd/$(ARCH)/config.h editline/$(ARCH)/config.h \
	sos/$(ARCH)/config.h sos/$(ARCH)/config_p.h \
	regx/$(ARCH)/config.h regx/$(ARCH)/config_p.h

# Static and static pattern rules.
#---------------------------------

ifdef EXT_GLISH_DIR

.PHONY : share lib bin allsys compilesys .cleansys

else

.PHONY : compilesys incmod install protect

share: force.rebuild
	rm -rf $@

lib: force.rebuild
	rm -rf $@

bin: force.rebuild
	rm -rf $@

$(ARCH): force.rebuild
	-@ if test -d $(ARCH); then 				\
	     rm -rf `find . -type d -name $(ARCH) -print`;	\
	   fi
	-@ mkdir $(ARCH)

$(ARCH)/last.build : $(ARCH) FORCE
	-@ touch $@

$(ARCH)/go: $(ARCH) FORCE
	-@ touch $@

allsys : share lib bin $(ARCH)/go install incmod protect $(ARCH)/last.build

install : compilesys
	-@ $(MAKE) -f Makefile ARCH=$(ARCH) install

compilesys : $(CONFIG)
	-@ $(MAKE) -f Makefile ARCH=$(ARCH)

incmod:
	-@ files=`find include -type f -name '*.h' -print`; \
	   if [ "$(files)" ]; then \
	      chmod 644 $(files);  \
	   fi

protect :
	-@ for i in `find include -type d -print`; \
	    do [ -f "$$i/$(MTFLE)" ] || touch "$$i/$(MTFLE)"; done
	-@ for i in `find . -type d -print | grep $(ARCH)`; \
	    do [ -f "$$i/$(MTFLE)" ] || touch "$$i/$(MTFLE)"; done
	-@ [ -f "bin/$(MTFLE)" ] || touch "bin/$(MTFLE)"
	-@ [ -f "lib/$(MTFLE)" ] || touch "lib/$(MTFLE)"

ifeq "$(MAKEMODE)" "programmer"
   .PHONY : compile

   all : compile incmod $(ARCH)/last.build

   compile : $(CONFIG)
	-@ $(MAKE) -f Makefile ARCH=$(ARCH)


   $(CONFIG) : configure
	-@ echo $(PGPLOT_WARN)
	-@ CXX="$(C++)";					\
	   CC="$(CC)";						\
	   ARCH="$(ARCH)";					\
	   if test -n "$(GLISH_CFLAGS)"; then			\
	       CFLAGS="$(GLISH_CFLAGS)";			\
	       export CFLAGS;					\
	   fi;							\
	   if test -n "$(GLISH_CXXFLAGS)"; then			\
	       CXXFLAGS="$(GLISH_CXXFLAGS) $(TKPGPLOT_FLAGS)";	\
	       export CXXFLAGS;					\
	   else							\
	       CXXFLAGS="$(TKPGPLOT_FLAGS)";			\
	       export CXXFLAGS;					\
	   fi;							\
	   if test ! -d $(ARCH); then mkdir $(ARCH); fi;	\
	   export CXX CC ARCH;					\
	   echo configure --key-dir=$(AIPSROOT)/keys		\
			--rc-dir=$(AIPSROOT)			\
			--script-dir=$(AIPSROOT)/$(ARCH)/libexec \
			--script-dir-tcl=$(AIPSROOT)/$(ARCH)/libexec/tcl \
			--x-includes=$(word 1, $(X11INCD))	\
			--x-libraries=$(word 1, $(X11LIBD))	\
			--tcl-includes=$(word 1, $(TCLINCD))	\
			--tcl-libraries=$(word 1, $(TCLLIBD))	\
			--pgplot-incl-flags="$(PGP_INCL)"	\
			--pgplot-link-flags="$(PGP_LINK)"	\
			--pgplot-link-search="$(PGP_LD_SEARCH)"	\
			$(GLISH_TCLCONFIGFLAGS)			\
			$(GLISH_CONFIGFLAGS);			\
	   sh configure --key-dir=$(AIPSROOT)/keys		\
			--rc-dir=$(AIPSROOT)			\
			--script-dir=$(AIPSROOT)/$(ARCH)/libexec \
			--script-dir-tcl=$(AIPSROOT)/$(ARCH)/libexec/tcl \
			--x-includes=$(word 1, $(X11INCD))	\
			--x-libraries=$(word 1, $(X11LIBD))	\
			--tcl-includes=$(word 1, $(TCLINCD))	\
			--tcl-libraries=$(word 1, $(TCLLIBD))	\
			--pgplot-incl-flags="$(PGP_INCL)"	\
			--pgplot-link-flags="$(PGP_LINK)"	\
			--pgplot-link-search="$(PGP_LD_SEARCH)"	\
			$(GLISH_TCLCONFIGFLAGS)			\
			$(GLISH_CONFIGFLAGS)			\
		2>&1 | tee "$(ARCH)/log"
	-@ for i in $(CONFIG); 					\
	    do touch "$$i"; done

else

   $(CONFIG) : configure
	-@ echo $(PGPLOT_WARN)
	-@ cd config && \
	   chmod 0755 architecture config.guess config.sub install-sh mkhier
	-@ if test -f $(ARCH)/go; then				\
	       CXX="$(C++)";					\
	       CC="$(CC)";					\
	       ARCH="$(ARCH)";					\
	       GLISHROOT=$(AIPSROOT);				\
	       if test -n "$(GLISH_CFLAGS)"; then		\
	           CFLAGS="$(GLISH_CFLAGS)";			\
	           export CFLAGS;				\
	       fi;						\
	       if test -n "$(GLISH_CXXFLAGS)"; then		\
	           CXXFLAGS="$(GLISH_CXXFLAGS) $(TKPGPLOT_FLAGS)"; \
	           export CXXFLAGS;				\
	       else						\
	           CXXFLAGS="$(TKPGPLOT_FLAGS)";		\
	           export CXXFLAGS;				\
	       fi;						\
	       if test ! -d $(ARCH); then mkdir $(ARCH); fi;	\
	       export CXX CC ARCH GLISHROOT;			\
	       echo configure --key-dir=$(AIPSROOT)/keys	\
			    --rc-dir=$(AIPSROOT)		\
			    --script-dir=$(AIPSROOT)/$(ARCH)/libexec \
			    --script-dir-tcl=$(AIPSROOT)/$(ARCH)/libexec/tcl \
			    --prefix=$(AIPSCODE)/aips/glish	\
	                    --exec-prefix=$(AIPSARCH)		\
			    --x-includes=$(word 1, $(X11INCD))	\
			    --x-libraries=$(word 1, $(X11LIBD))	\
			    --tcl-includes=$(word 1, $(TCLINCD)) \
			    --tcl-libraries=$(word 1, $(TCLLIBD)) \
			    --pgplot-incl-flags="$(PGP_INCL)"	\
			    --pgplot-link-flags="$(PGP_LINK)"	\
			    --pgplot-link-search="$(PGP_LD_SEARCH)" \
			    $(GLISH_TCLCONFIGFLAGS) 		\
			    $(GLISH_CONFIGFLAGS);		\
	       sh configure --key-dir=$(AIPSROOT)/keys		\
			    --rc-dir=$(AIPSROOT)		\
			    --script-dir=$(AIPSROOT)/$(ARCH)/libexec \
			    --script-dir-tcl=$(AIPSROOT)/$(ARCH)/libexec/tcl \
			    --prefix=$(AIPSCODE)/aips/glish	\
	                    --exec-prefix=$(AIPSARCH)		\
			    --x-includes=$(word 1, $(X11INCD))	\
			    --x-libraries=$(word 1, $(X11LIBD))	\
			    --tcl-includes=$(word 1, $(TCLINCD)) \
			    --tcl-libraries=$(word 1, $(TCLLIBD)) \
			    --pgplot-incl-flags="$(PGP_INCL)"	\
			    --pgplot-link-flags="$(PGP_LINK)"	\
			    --pgplot-link-search="$(PGP_LD_SEARCH)" \
			    $(GLISH_TCLCONFIGFLAGS) 		\
			    $(GLISH_CONFIGFLAGS) || rm -f $(ARCH)/go \
		    2>&1 | tee "$(ARCH)/log";			\
	   fi
	-@ if test -f $(ARCH)/go; then				\
	       for i in $(CONFIG); 				\
	           do touch "$$i"; done;			\
	   fi

endif


help ::
	-@ echo ""
	-@ echo "Targets defined in the top-level glish makefile"
	-@ echo "==============================================="
	-@ echo ""
	-@ echo "System"
	-@ echo "------"
	-@ echo " compilesys: compile Glish and related libraries."
	-@ echo "    install: install Glish and related libraries."
	-@ echo ""
	-@ echo "Programmer"
	-@ echo "----------"
	-@ echo "    compile: compile Glish and related libraries."

all_r:
	$(MAKE) -f Makefile all_r

install_r:
	$(MAKE) -f Makefile install_r

clean_r:
	$(MAKE) -f Makefile clean_r

build.sos:
	$(MAKE) -f Makefile build.sos

build.regx:
	$(MAKE) -f Makefile build.regx

build.editline:
	$(MAKE) -f Makefile build.editline

build.npd:
	$(MAKE) -f Makefile build.npd

build.tk:
	$(MAKE) -f Makefile build.tk

build.glish:
	$(MAKE) -f Makefile build.glish

install.sos:
	$(MAKE) -f Makefile install.sos

install.regx:
	$(MAKE) -f Makefile install.regx

install.editline:
	$(MAKE) -f Makefile install.editline

install.npd:
	$(MAKE) -f Makefile install.npd

install.tk:
	$(MAKE) -f Makefile install.tk

install.glish:
	$(MAKE) -f Makefile install.glish

clean.sos:
	$(MAKE) -f Makefile clean.sos

clean.regx:
	$(MAKE) -f Makefile clean.regx

clean.editline:
	$(MAKE) -f Makefile clean.editline

clean.npd:
	$(MAKE) -f Makefile clean.npd

clean.tk:
	$(MAKE) -f Makefile clean.tk

clean.glish:
	$(MAKE) -f Makefile clean.glish

distclean.sos:
	$(MAKE) -f Makefile distclean.sos

distclean.regx:
	$(MAKE) -f Makefile distclean.regx

distclean.editline:
	$(MAKE) -f Makefile distclean.editline

distclean.npd:
	$(MAKE) -f Makefile distclean.npd

distclean.tk:
	$(MAKE) -f Makefile distclean.tk

distclean.glish:
	$(MAKE) -f Makefile distclean.glish

build.npd_r:
	$(MAKE) -f Makefile build.npd_r

build.tk_r:
	$(MAKE) -f Makefile build.tk_r

build.npd_r_r:
	$(MAKE) -f Makefile build.npd_r_r

build.tk_r_r:
	$(MAKE) -f Makefile build.tk_r_r

install.npd_r:
	$(MAKE) -f Makefile install.npd_r

install.tk_r:
	$(MAKE) -f Makefile install.tk_r

install.npd_r_r:
	$(MAKE) -f Makefile install.npd_r_r

install.tk_r_r:
	$(MAKE) -f Makefile install.tk_r_r

clean.npd_r:
	$(MAKE) -f Makefile clean.npd_r

clean.tk_r:
	$(MAKE) -f Makefile clean.tk_r

clean.npd_r_r:
	$(MAKE) -f Makefile clean.npd_r_r

clean.tk_r_r:
	$(MAKE) -f Makefile clean.tk_r_r

distclean.npd_r:
	$(MAKE) -f Makefile distclean.npd_r

distclean.tk_r:
	$(MAKE) -f Makefile distclean.tk_r

distclean.npd_r_r:
	$(MAKE) -f Makefile distclean.npd_r_r

distclean.tk_r_r:
	$(MAKE) -f Makefile distclean.tk_r_r

##
## Dummy targets
##
install-:

clean-:

distclean-:

# Static and static pattern rules.
#---------------------------------
.cleansys :
	-@ echo "Doing cleansys in Glish for $(ARCH)"
	-$Q $(RM) -r $(ARCH) lib/$(ARCH) bin/$(ARCH)

endif
