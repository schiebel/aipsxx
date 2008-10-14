# $Id: makefile,v 19.6 2005/06/27 06:13:48 gvandiep Exp $

AIPSROOT := $(word 1, $(AIPSPATH))
AIPSARCH := $(AIPSROOT)/$(word 2, $(AIPSPATH))
GLISHARCH := $(AIPSROOT)/code/aips/glish/$(word 2, $(AIPSPATH))


# XmPGPLOT includes PGPLOT
# WCSLIB has to be first, ATNF for example has wcs in /usr/local/lib
XLIBLIST := CFITSIO WCSLIB XmPGPLOT MIRLIB GLISH Motif TCL X11 XPM GLISHLO LAPACK F77
XLIBLIST_override := $(XLIBLIST)

# AIPS++ fundamentals.
#---------------------
include $(AIPSARCH)/makedefs

# Get glish loadable object definitions.
ifdef EXT_GLISH_DIR
    -include $(EXT_GLISH_DIR)/lib/glish/lib/glishtk.mak
else
    -include $(GLISHARCH)/glishtk.mak
endif

GLISHLIB  := -lglishtk -lglish -ledit -lsos -lnpd
MKSO := $(GLISH_MK_OBJ)
LDSOPTS := 
LDDBG :=
LDOPT :=

THISAPP := gDisplay.$(SFXSHAR)

# The name of this application.
#------------------------------
ifndef THISAPP
THISAPP  := $(word 3,$(subst /,$(space),$(CODESUBD)))
endif
PCKGAPP  := $(PACKAGE)_$(subst .$(SFXSHAR),,$(THISAPP))

# Hook to allow compilation of this application to be skipped.
ifeq "$(suffix $(THISAPP))" ".$(SFXSHAR)"
TGT := lib
else
TGT := bin
endif

# Get architecture-specific, application-specific definitions.
-include $(INSTARCH)/$(PCKGAPP).defs

CPPSTD += -DAIPS_NO_TEMPLATE_SRC
CPPOPT += -DAIPS_NO_TEMPLATE_SRC
CPPDBG += -DAIPS_NO_TEMPLATE_SRC


# Temporary directories.
#-----------------------
TMPPCKGD := $(ARCHTMPD)/$(PACKAGE)
PCKGDBGD := $(TMPPCKGD)/dbg
PCKGOPTD := $(TMPPCKGD)/opt

FIRST := $(shell amkdir -p ug=rwx,g+s,o=rx -v $(PCKGDBGD) $(PCKGOPTD) $(PCKGDBGD)/tmplinst $(PCKGOPTD)/tmplinst)

# Source lists.
#--------------
AIPSIMPS := $(filter-out $(subst .$(SFXSHAR),,$(THISAPP)).cc,$(filter %.cc,$(AIPSSRCS)))
PGMRIMPS := $(filter-out $(subst .$(SFXSHAR),,$(THISAPP)).cc,$(sort $(AIPSIMPS) $(wildcard *.cc)))

# Glish scripts.
LIBEXECS := $(filter %.g %.gp, $(AIPSSRCS))

# Glish script icons.
LIBICONS := $(filter %.xbm, $(AIPSSRCS))

# Programmer path to include files for this application.
PRGAPINC := -I. -I$(CODEDIR)


# Do-it-yourself template instantiation.
#---------------------------------------
AIPSINST :=
PGMRINST :=
ifeq "$(TEMPLATES)" "diy"
   ifneq "$(findstring templates,$(AIPSSRCS))" ""
      AIPSINST := $(CODEDIR)/tmplinst
   endif

   ifeq "$(MAKEMODE)" "programmer"
      ifeq "$(notdir $(CODESUBD))" "tmplinst"
         PGMRIMPS := $(wildcard *.cc)
         ifeq "$(wildcard ../MyTemplatesOnly)" ""
            PGMRIMPS := $(sort $(PGMRIMPS) \
                           $(notdir $(wildcard $(CODEDIR)/*.cc)))
         endif
         PRGAPINC := -I.. -I$(dir $(CODEDIR))
      else
         ifneq "$(wildcard templates)" ""
            PGMRINST := inst
         else
            ifneq "$(findstring templates,$(AIPSSRCS))" ""
               ifeq "$(wildcard MyTemplatesOnly)" ""
                  PGMRINST := inst
               endif
            endif
         endif
      endif
   endif
endif


# Libraries.
#-----------
# Parse the link lists and library control variables.
DBGLIBS  := $(foreach PCKG,$(LINK$(PACKAGE)), \
               $(subst $(LIBDBGD)/lib$(PCKG).defeat, \
                  $(LIBOPTD)/lib$(PCKG).$(word 2,$(LIB$(PCKG))), \
                  $(subst $(LIBDBGD)/lib$(PCKG)_c.defeat, \
                     $(LIBOPTD)/lib$(PCKG)_c.$(word 4,$(LIB$(PCKG))), \
                     $(subst $(LIBDBGD)/lib$(PCKG)_f.defeat, \
                        $(LIBOPTD)/lib$(PCKG)_f.$(word 6,$(LIB$(PCKG))), \
                           $(LIBDBGD)/lib$(PCKG).$(word 1,$(LIB$(PCKG))) \
                           $(LIBDBGD)/lib$(PCKG)_c.$(word 3,$(LIB$(PCKG))) \
                           $(LIBDBGD)/lib$(PCKG)_f.$(word 5,$(LIB$(PCKG)))))))
DBGLIBS  := $(strip \
               $(subst .static,.$(SFXSTAT), \
                  $(subst .shatic,.$(SFXSTAT), \
                     $(subst .shared,.$(SFXSHAR), \
                        $(filter-out %.defeat,$(DBGLIBS))))))

OPTLIBS  := $(foreach PCKG,$(LINK$(PACKAGE)), \
               $(subst $(LIBOPTD)/lib$(PCKG).defeat, \
                  $(LIBDBGD)/lib$(PCKG).$(word 1,$(LIB$(PCKG))), \
                  $(subst $(LIBOPTD)/lib$(PCKG)_c.defeat, \
                     $(LIBDBGD)/lib$(PCKG)_c.$(word 3,$(LIB$(PCKG))), \
                     $(subst $(LIBOPTD)/lib$(PCKG)_f.defeat, \
                        $(LIBDBGD)/lib$(PCKG)_f.$(word 5,$(LIB$(PCKG))), \
                           $(LIBOPTD)/lib$(PCKG).$(word 2,$(LIB$(PCKG))) \
                           $(LIBOPTD)/lib$(PCKG)_c.$(word 4,$(LIB$(PCKG))) \
                           $(LIBOPTD)/lib$(PCKG)_f.$(word 6,$(LIB$(PCKG)))))))
OPTLIBS  := $(strip \
               $(subst .static,.$(SFXSTAT), \
                  $(subst .shatic,.$(SFXSTAT), \
                     $(subst .shared,.$(SFXSHAR), \
                        $(filter-out %.defeat,$(OPTLIBS))))))

ifeq "$(MAKEMODE)" "programmer"
   # Programmer libraries.
   #----------------------
   ifndef OPTLIB
      OPTLIB := $(OPT)
   endif

   ifdef PGMRLIBD
      ifndef OPTLIB
         PGMRLIBR := $(foreach PCKG,$(LINK$(PACKAGE)), \
            $(wildcard $(PGMRLIBD)/lib$(PCKG).$(SFXSTAT)) \
            $(wildcard $(PGMRLIBD)/lib$(PCKG)_c.$(SFXSTAT)) \
            $(wildcard $(PGMRLIBD)/lib$(PCKG)_f.$(SFXSTAT)) \
            $(subst $(LIBDBGD)/lib$(PCKG).defeat, \
               $(LIBOPTD)/lib$(PCKG).$(word 2,$(LIB$(PCKG))), \
               $(subst $(LIBDBGD)/lib$(PCKG)_c.defeat, \
                  $(LIBOPTD)/lib$(PCKG)_c.$(word 4,$(LIB$(PCKG))), \
                  $(subst $(LIBDBGD)/lib$(PCKG)_f.defeat, \
                     $(LIBOPTD)/lib$(PCKG)_f.$(word 6,$(LIB$(PCKG))), \
                        $(LIBDBGD)/lib$(PCKG).$(word 1,$(LIB$(PCKG))) \
                        $(LIBDBGD)/lib$(PCKG)_c.$(word 3,$(LIB$(PCKG))) \
                        $(LIBDBGD)/lib$(PCKG)_f.$(word 5,$(LIB$(PCKG)))))))
      else
         PGMRLIBR := $(foreach PCKG,$(LINK$(PACKAGE)), \
            $(wildcard $(PGMRLIBD)/lib$(PCKG).$(SFXSTAT)) \
            $(wildcard $(PGMRLIBD)/lib$(PCKG)_c.$(SFXSTAT)) \
            $(wildcard $(PGMRLIBD)/lib$(PCKG)_f.$(SFXSTAT)) \
            $(subst $(LIBOPTD)/lib$(PCKG).defeat, \
               $(LIBDBGD)/lib$(PCKG).$(word 1,$(LIB$(PCKG))), \
               $(subst $(LIBOPTD)/lib$(PCKG)_c.defeat, \
                  $(LIBDBGD)/lib$(PCKG)_c.$(word 3,$(LIB$(PCKG))), \
                  $(subst $(LIBOPTD)/lib$(PCKG)_f.defeat, \
                     $(LIBDBGD)/lib$(PCKG)_f.$(word 5,$(LIB$(PCKG))), \
                        $(LIBOPTD)/lib$(PCKG).$(word 2,$(LIB$(PCKG))) \
                        $(LIBOPTD)/lib$(PCKG)_c.$(word 4,$(LIB$(PCKG))) \
                        $(LIBOPTD)/lib$(PCKG)_f.$(word 6,$(LIB$(PCKG)))))))
      endif
   else
      ifndef OPTLIB
         PGMRLIBR := $(foreach PCKG,$(LINK$(PACKAGE)), \
            $(wildcard $(PGMRCODE)/$(PCKG)/implement/lib$(PCKG).$(SFXSTAT)) \
            $(wildcard $(PGMRCODE)/$(PCKG)/C/lib$(PCKG)_c.$(SFXSTAT))       \
            $(wildcard $(PGMRCODE)/$(PCKG)/fortran/lib$(PCKG)_f.$(SFXSTAT)) \
            $(subst $(LIBDBGD)/lib$(PCKG).defeat, \
               $(LIBOPTD)/lib$(PCKG).$(word 2,$(LIB$(PCKG))), \
               $(subst $(LIBDBGD)/lib$(PCKG)_c.defeat, \
                  $(LIBOPTD)/lib$(PCKG)_c.$(word 4,$(LIB$(PCKG))), \
                  $(subst $(LIBDBGD)/lib$(PCKG)_f.defeat, \
                     $(LIBOPTD)/lib$(PCKG)_f.$(word 6,$(LIB$(PCKG))), \
                        $(LIBDBGD)/lib$(PCKG).$(word 1,$(LIB$(PCKG))) \
                        $(LIBDBGD)/lib$(PCKG)_c.$(word 3,$(LIB$(PCKG))) \
                        $(LIBDBGD)/lib$(PCKG)_f.$(word 5,$(LIB$(PCKG)))))))
      else
         PGMRLIBR := $(foreach PCKG,$(LINK$(PACKAGE)), \
            $(wildcard $(PGMRCODE)/$(PCKG)/implement/lib$(PCKG).$(SFXSTAT)) \
            $(wildcard $(PGMRCODE)/$(PCKG)/C/lib$(PCKG)_c.$(SFXSTAT))       \
            $(wildcard $(PGMRCODE)/$(PCKG)/fortran/lib$(PCKG)_f.$(SFXSTAT)) \
            $(subst $(LIBOPTD)/lib$(PCKG).defeat, \
               $(LIBDBGD)/lib$(PCKG).$(word 1,$(LIB$(PCKG))), \
               $(subst $(LIBOPTD)/lib$(PCKG)_c.defeat, \
                  $(LIBDBGD)/lib$(PCKG)_c.$(word 3,$(LIB$(PCKG))), \
                  $(subst $(LIBOPTD)/lib$(PCKG)_f.defeat, \
                     $(LIBDBGD)/lib$(PCKG)_f.$(word 5,$(LIB$(PCKG))), \
                        $(LIBOPTD)/lib$(PCKG).$(word 2,$(LIB$(PCKG))) \
                        $(LIBOPTD)/lib$(PCKG)_c.$(word 4,$(LIB$(PCKG))) \
                        $(LIBOPTD)/lib$(PCKG)_f.$(word 6,$(LIB$(PCKG)))))))
      endif
   endif

   PGMRLIBR := $(strip \
                  $(subst .static,.$(SFXSTAT), \
                     $(subst .shatic,.$(SFXSTAT), \
                        $(subst .shared,.$(SFXSTAT), \
                           $(filter-out %.defeat,$(PGMRLIBR))))))

   # Programmer applications library.
   ifdef PGMRLIBD
      PRGAPLIB := $(PGMRLIBD)/lib$(PCKGAPP).$(SFXSTAT)
   else
      ifeq "$(notdir $(CODESUBD))" "tmplinst"
         PRGAPLIB := ../lib$(PCKGAPP).$(SFXSTAT)
      else
         PRGAPLIB := lib$(PCKGAPP).$(SFXSTAT)
      endif
   endif

   ifneq "$(PGMRIMPS)$(PGMRINST)" ""
      PGMRLIBR := $(PRGAPLIB) $(PGMRLIBR) $(PRGAPLIB) $(PGMRLIBR)
   endif

   ifndef OPTLIB
      PGMRLIBS := \
         $(firstword $(wildcard $(LIBDBGD)/version.o $(LIBOPTD)/version.o)) \
         $(PGMRLIBR) $(XTRNLIBS) $(EXTRA_PGMRLIBS)
   else
      PGMRLIBS := \
         $(firstword $(wildcard $(LIBOPTD)/version.o $(LIBDBGD)/version.o)) \
         $(PGMRLIBR) $(XTRNLIBS) $(EXTRA_PGMRLIBS)
   endif


   # Programmer dependency lists.
   #-----------------------------
   ifndef PGMRAUXD
      override PGMRAUXD := .
   endif

   ifeq "$(notdir $(CODESUBD))" "tmplinst"
      PGMRLIST := $(PGMRAUXD)/$(PCKGAPP)-tmplinst.list
      PGMRTIME := $(PGMRAUXD)/$(PCKGAPP)-tmplinst.time
   else
      PGMRLIST := $(PGMRAUXD)/$(PCKGAPP).list
      PGMRTIME := $(PGMRAUXD)/$(PCKGAPP).time
   endif


   # Programmer lock files.
   #-----------------------
   PGMRLOCK := $(PGMRAUXD)/$(PCKGAPP).lock


   # Programmer paths.
   #------------------
   ifndef PGMRLIBD
      override PGMRLIBD := .
   endif

   ifndef PGMRBIND
      override PGMRBIND := .
   endif
   include $(AIPSROOT)/code/install/makefile.help
endif


##========================================================================
## Pattern rules.
##========================================================================

## -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
## debug objects from code directory
## -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
$(PCKGDBGD)/%.o : $(PCKGDBGD)/%.lock ;

$(PCKGDBGD)/%.lock : $(PCKGDBGD)/%.LOCK $(PCKGDBGD)/%.lcc $(PCKGDBGD)/%.ycc
	-@ echo ""
	-@ echo "$(basename $(@F)) (dbg)"
	 @ cd $(PCKGDBGD) && $(C++) $(CPPDBG) $(AIPSINCL) -I. $(C++DBG) -c $(@F:%.lock=$(CODEDIR)/%.cc)
	-@ $(TIMER)
	-@ $(RM) $@ $<

$(PCKGDBGD)/%.LOCK : $(CODEDIR)/%.cc
	-@ echo "$(JOBIDENT)" > $(@:.LOCK=.lock)

$(PCKGDBGD)/%.lcc : $(CODEDIR)/%.l
	-@ echo ""
	$(FLEX) -t -P$(<F:.l=) $< > $@

$(PCKGDBGD)/%.lcc : ;

$(PCKGDBGD)/%.ycc : $(CODEDIR)/%.y
	-@ echo ""
	$(BISON) -p $(<F:.y=) -o $@ $<

$(PCKGDBGD)/%.ycc : ;

## -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
## optimized objects from code directory
## -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
$(PCKGOPTD)/%.o : $(PCKGOPTD)/%.lock ;

$(PCKGOPTD)/%.lock : $(PCKGOPTD)/%.LOCK $(PCKGOPTD)/%.lcc $(PCKGOPTD)/%.ycc
	-@ echo ""
	-@ echo "$(basename $(@F)) (opt)"
	 @ cd $(PCKGOPTD) && $(C++) $(CPPOPT) $(AIPSINCL) -I. $(C++OPT) -c $(addprefix $(CODEDIR)/,$(patsubst %.lock,%.cc,$(subst $(PCKGOPTD)/,,$@)))
	-@ $(TIMER)
	-@ $(RM) $@ $<

$(PCKGOPTD)/%.LOCK : $(CODEDIR)/%.cc
	-@ echo "$(JOBIDENT)" > $(@:.LOCK=.lock)

$(PCKGOPTD)/%.lcc : $(CODEDIR)/%.l
	-@ echo ""
	$(FLEX) -t -P$(<F:.l=) $< > $@

$(PCKGOPTD)/%.lcc : ;

$(PCKGOPTD)/%.ycc : $(CODEDIR)/%.y
	-@ echo ""
	$(BISON) -p $(<F:.y=) -o $@ $<

$(PCKGOPTD)/%.ycc : ;

## -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
## rules for creating binaries
## -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
$(BINDBGD)/% : $(CODEDIR)/%.cc $(AIPSINST) \
    $(addprefix $(CODEDIR)/,$(AIPSIMPS)) $(DBGLIBS)
	-@ echo ""
	-@ $(TIMER)
	-@ echo "Remaking $@ (dbg) because of $(?F)"
	 @ cd $(PCKGDBGD) && \
	   $(C++) $(CPPDBG) -I$(CODEDIR) $(AIPSINCL) $(C++DBG) $(LDDBG) -o $@ $< $(AIPSINST:%=%/*.cc) $(addprefix $(CODEDIR)/,$(AIPSIMPS)) $(firstword $(wildcard $(LIBDBGD)/version.o $(LIBOPTD)/version.o)) $(patsubst $(LIBDBGD)/lib%.$(SFXSHAR), -l%, $(DBGLIBS)) $(MODULIBS) $(XTRNLIBS)
	-@ $(TIMER)
	-@ $(RM) $(patsubst %.cc,$(PCKGDBGD)/%.o,$(<F) $(AIPSIMPS))
	-@ chmod 775 $@

$(BINOPTD)/% : $(CODEDIR)/%.cc $(AIPSINST) \
    $(addprefix $(CODEDIR)/,$(AIPSIMPS)) $(OPTLIBS)
	-@ echo ""
	-@ $(TIMER)
	-@ echo "Remaking $@ (opt) because of $(?F)"
	 @ cd $(PCKGOPTD) && \
	   $(C++) $(CPPOPT) -I$(CODEDIR) $(AIPSINCL) $(C++OPT) $(LDOPT) -o $@ $< $(AIPSINST:%=%/*.cc) $(addprefix $(CODEDIR)/,$(AIPSIMPS)) $(firstword $(wildcard $(LIBOPTD)/version.o $(LIBDBGD)/version.o)) $(patsubst $(LIBOPTD)/lib%.$(SFXSHAR), -l%, $(OPTLIBS)) $(MODULIBS) $(XTRNLIBS)
	-@ $(TIMER)
	-@ $(RM) $(patsubst %.cc,$(PCKGOPTD)/%.o,$(<F) $(AIPSIMPS))
	-@ chmod 775 $@

## -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
## rules for creating loadable objects
## -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
$(LIBDBGD)/%.$(SFXSHAR) : $(PCKGDBGD)/%.o \
    $(addprefix $(PCKGDBGD)/tmplinst/,$(patsubst %.cc, %.o, $(notdir $(wildcard $(AIPSINST)/*.cc)))) \
    $(addprefix $(PCKGDBGD)/,$(patsubst %.cc, %.o, $(AIPSIMPS))) $(DBGLIBS)
	-@ echo ""
	-@ $(TIMER)
	-@ echo "Remaking $@ (opt) because of $(?F)"
	   cd $(PCKGDBGD) && \
	   $(MKSO) $(LDSOPTS) $@ $< $(LDDBG) $(GLISH_LD_RPATH) $(PGMRLIBS) $(patsubst %.cc, %.o, $(notdir $(wildcard $(AIPSINST)/*.cc))) $(patsubst %.cc, %.o,$(AIPSIMPS)) $(firstword $(wildcard $(LIBDBGD)/version.o $(LIBOPTD)/version.o)) $(patsubst $(LIBDBGD)/lib%.$(SFXSHAR), -l%, $(DBGLIBS)) $(MODULIBS) $(XTRNLIBS) 2>&1 | head -100
	-@ $(TIMER)
	-@ $(RM) $(addprefix $(PCKGDBGD)/, $(<F) $(patsubst %.cc,%.o,$(AIPSIMPS) $(notdir $(wildcard $(AIPSINST)/*.cc))))
	-@ chmod 775 $@

$(LIBOPTD)/%.$(SFXSHAR) : $(PCKGOPTD)/%.o \
    $(addprefix $(PCKGOPTD)/tmplinst/,$(patsubst %.cc, %.o, $(notdir $(wildcard $(AIPSINST)/*.cc)))) \
    $(addprefix $(PCKGOPTD)/,$(patsubst %.cc, %.o, $(AIPSIMPS))) $(OPTLIBS)
	-@ echo ""
	-@ $(TIMER)
	-@ echo "Remaking $@ (opt) because of $(?F)"
	   cd $(PCKGOPTD) && \
	   $(MKSO) $(LDSOPTS) $@ $< $(LDOPT) $(GLISH_LD_RPATH) $(PGMRLIBS) $(patsubst %.cc, %.o, $(notdir $(wildcard $(AIPSINST)/*.cc))) $(patsubst %.cc, %.o,$(AIPSIMPS)) $(firstword $(wildcard $(LIBOPTD)/version.o $(LIBDBGD)/version.o)) $(patsubst $(LIBOPTD)/lib%.$(SFXSHAR), -l%, $(OPTLIBS)) $(MODULIBS) $(XTRNLIBS) 2>&1 | head -100
	-@ $(TIMER)
	-@ $(RM) $(addprefix $(PCKGOPTD)/, $(<F) $(patsubst %.cc,%.o,$(AIPSIMPS) $(notdir $(wildcard $(AIPSINST)/*.cc))))
	-@ chmod 775 $@

## -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
## misc rules
## -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
$(LIBEXECD)/% : $(CODEDIR)/%
	@ $(RM) $@
	  sed -e 's#__SFXSHAR#$(SFXSHAR)#g' $< > $@
	@ chmod 664 $@

$(LIBICOND)/% : $(CODEDIR)/%
	@ $(RM) $@
	  cp $< $@
	@ chmod 664 $@

# Programmer-oriented pattern rules.
ifeq "$(MAKEMODE)" "programmer"
   vpath %.cc $(CODEDIR)
   vpath templates $(CODEDIR)

   # Paths assumed by the programmer dependency lists.
   vpath %.h  $(PGMRCODE)/include:$(CODEINCD):$(THISDIR):$(CODEDIR)
   vpath %.cc $(PGMRCODE)/include:$(CODEINCD):$(THISDIR):$(CODEDIR)

   mylib(%.o) : $(PRGAPLIB)(%.o)
	@ if [ -f "$(PGMRLIBD)/$%" ] ; then \
	     cd $(PGMRLIBD) ; \
	     $(CXXAR) $(CXXARFLAGS) $(PRGAPLIB) $% ; \
	     $(RM) $% ; \
	     $(RANLIB) $(PRGAPLIB) ; \
	  fi

   $(PRGAPLIB)(%.o) : %.cc $(PGMRTIME)(%)
	-@ echo ""
	-@ $(RM) $(PGMRLIBD)/$%
	   $(C++) $(CPPFLAGS) $(PRGAPINC) $(PGMRINCL) -c $(C++FLAGS) -o $(PGMRLIBD)/$% $<

   $(PGMRBIND)/% : $(PGMRBIND)/%.o $(PGMRLIBR)
	-@ echo ""
	-@ $(RM) $@
	   $(C++) $(PRGAPINC) $(PGMRINCL) $(C++FLAGS) $(LDFLAGS) -o $@ $< $(PGMRLIBS)

   $(PGMRBIND)/%.o : %.cc $(PGMRTIME)(%)
	-@ echo ""
	-@ $(RM) $@
	   $(C++) $(CPPFLAGS) $(PRGAPINC) $(PGMRINCL) -c $(C++FLAGS) -o $@ $<

   $(PGMRBIND)/%.i : %.cc $(PGMRTIME)(%)
	-@ echo ""
	-@ $(RM) $@
	   $(CPP) $(CPPFLAGS) $(PRGAPINC) $(PGMRINCL) $< > $@

   $(PGMRLIBD)/%.$(SFXSHAR) : $(PGMRLIBD)/%.o $(PGMRLIBR)
	-@ echo ""
	-@ $(RM) $@
	   $(MKSO) $(LDSOPTS) $@ $< $(LDFLAGS) $(GLISH_LD_RPATH) $(PGMRLIBS) 2>&1 | head -100

   $(PGMRLIBD)/%.o : %.cc $(PGMRTIME)(%)
	-@ echo ""
	-@ $(RM) $@
	   $(C++) $(CPPFLAGS) $(PRGAPINC) $(PGMRINCL) -c $(C++FLAGS) -o $@ $<

   $(PGMRLIBD)/%.i : %.cc $(PGMRTIME)(%)
	-@ echo ""
	-@ $(RM) $@
	   $(CPP) $(CPPFLAGS) $(PRGAPINC) $(PGMRINCL) $< > $@

   %.d : %.cc $(PGMRTIME)(%)
	-@ echo ""
	-@ echo "Programmer dependencies for $<:"
	-@ sed -n -e '\#^$$(PGMRTIME)($*)#s#.* : #   #p' $(PGMRLIST)

   $(PGMRTIME)(%) : %.cc
	-@ echo ""
	-@ echo "Updating dependencies for $<"
	 @ for i in 10 9 8 7 6 5 4 3 2 1 ; do \
	      [ ! -f "$(PGMRLOCK)" ] && break ; \
	      echo "    waiting for lock file ($$i)..." ; \
	      sleep 5 ; \
	   done
	-@ touch $(PGMRLIST)
	 @ trap "$(RM) $(PGMRLOCK) $(PGMRLIST).$(PID)" 1 2 3 15 ; \
	      TARGET='$$(PGMRTIME)($*) : ' ; \
	      sed -n -e "\#^$$TARGET#!p" $(PGMRLIST) > $(PGMRLOCK) ; \
	      $(CPP) $(CPPFLAGS) $(PRGAPINC) $(PGMRINCL) $< | \
	      sed -n \
	          -e '\%^# *[0-9][0-9]* ".*"%!d' \
	          -e 's%.*"./\(.*\)".*%'"$$TARGET"'$$(THISDIR)/\1%p' \
	          -e 's%.*"\([^</].*\)".*%'"$$TARGET"'$$(THISDIR)/\1%p' \
	          -e 's%.*"$(CODEDIR)/\(.*\)".*%'"$$TARGET"'\1%p' \
	          -e 's%.*"$(PGMRCODE)/\(include/.*\)".*%'"$$TARGET"'$$(PGMRCODE)/\1%p' \
	          -e 's%.*"$(CODEINCD)/\(.*\)".*%'"$$TARGET"'\1%p' | \
	      sort -u | sort -m - $(PGMRLOCK) > $(PGMRLIST).$(PID)
	 @ if [ -f "$(PGMRLOCK)" ] ; then \
	      mv -f $(PGMRLIST).$(PID) $(PGMRLIST) ; \
	      $(RM) $(PGMRLOCK) ; \
	      trap "$(RM) $(PGMRAUXD)/$*" 1 2 3 15 ; \
	      cat /dev/null > $(PGMRAUXD)/$* ; \
	      $(AR) r $(PGMRTIME) $(PGMRAUXD)/$* ; \
	      $(RM) $(PGMRAUXD)/$* ; \
	   fi

   ifneq "$(PGMRBIND)" "."
      %   : $(PGMRBIND)/%   ;
      %.o : $(PGMRBIND)/%.o ;
      %.i : $(PGMRBIND)/%.i ;
   endif

   %.h : ;
   $(THISDIR)/%.cc : ;
endif

# Defeat builtin pattern rules.
%.i : %.cc
%.o : %.cc
%   : %.cc


# Static and static pattern rules.
#---------------------------------
.PRECIOUS : $(DBGLIBS) $(OPTLIBS) $(LIBDBGD)/version.o $(LIBOPTD)/version.o

.PHONY : bin bindbg exorcise instsys

allsys : $(TGT)

.cleancode ::
	-$Q cd $(CODEDIR) && $(RM) *.i *.o *.cdb *.cyi
	-$Q $(RM) -r $(CODEDIR)/tmplinst


ifeq "$(TGT)" "bin"
bin    : $(PCKGOPTD) $(BINOPTD)/$(THISAPP) $(LIBEXECS) $(LIBICONS) ;
bindbg : $(PCKGDBGD) $(BINDBGD)/$(THISAPP) ;
else
bin    : lib ;
bindbg : libdbg ;
endif

lib    : $(PCKGOPTD) $(LIBOPTD)/$(THISAPP) $(LIBEXECS) $(LIBICONS) ;
libdbg : $(PCKGDBGD) $(LIBDBGD)/$(THISAPP) ;

instsys : $(CODEDIR)/tmplinst ;

$(CODEDIR)/tmplinst : $(CODEDIR)/templates
	-@ echo ""
	 @ amkdir -p ug=rwx,g+s,o=rx -v $@
	-@ echo ""
	 @ cd $@ && mkinst -q $<

# Scripts.
$(LIBEXECS) : % : $(LIBEXECD)/% ;

# Script icons.
$(LIBICONS) : % : $(LIBICOND)/% ;

# Programmer-oriented static and static pattern rules.
ifeq "$(MAKEMODE)" "programmer"
   .PRECIOUS : $(PGMRBIND)/% $(PGMRBIND)/%.o $(PGMRBIND)/%.i
   .PRECIOUS : $(PGMRLIBD)/% $(PGMRLIBD)/%.o $(PGMRLIBD)/%.i

   .PHONY : %.d inst mylib

ifeq "$(TGT)" "bin"
   all : $(PGMRBIND)/$(THISAPP)
else
   all : $(PGMRLIBD)/$(THISAPP)
endif

   .clean ::
	- cd $(PGMRAUXD) && $(RM) *~ *% $(PCKGAPP).lock
	- cd $(PGMRLIBD) && $(RM) *.i *.o *.cdb *.cyi a.out core
	- cd $(PGMRBIND) && $(RM) *.i *.o *.cdb *.cyi a.out core

   .cleaner ::
	- $(RM) $(PGMRAUXD)/$(PCKGAPP)*.*
	- $(RM) $(PRGAPLIB)
	- $(RM) -r tmplinst
	- $(RM) $(PGMRBIND)/$(THISAPP)
	- $(RM) $(PGMRLIBD)/$(THISAPP)

   depend : $(THISAPP:%=$(PGMRTIME)(%)) $(PGMRIMPS:%.cc=$(PGMRTIME)(%));

   exorcise :
	-@ if [ -f "$(PGMRLIST)" ] ; then \
	      grep "(THISDIR)" $(PGMRLIST) | \
	      awk '{print $$3}' | \
	      sort -u | \
	      while read RHS ; do \
	         DFILE=`echo $$RHS | sed -e 's#\$$(THISDIR)#$(THISDIR)#'` ; \
	         if [ ! -f "$$DFILE" ] ; then \
	            grep "$$RHS" $(PGMRLIST) | \
	            awk '{print $$1}' | \
	            sort -u | \
	            while read LHS ; do \
	               TARGET=`echo $$LHS | sed -e '{s/.*(//;s/)$$//;}'` ; \
	               echo "Deleting dependencies for $$TARGET because of" ; \
	               echo "   $$DFILE" ; \
	               grep -v "^$$LHS : " $(PGMRLIST) > $(PGMRLIST).$(PID) ; \
	               mv $(PGMRLIST).$(PID) $(PGMRLIST) ; \
	               $(AR) d $(PGMRTIME) $$TARGET ; \
	               echo "Deleting $$TARGET.o from" ; \
	               echo "   $(PRGAPLIB)" ; \
	               $(AR) d $(PRGAPLIB) $$TARGET.o ; \
	            done ; \
	         fi ; \
	      done ; \
	   fi
	-@ if [ -f "$(PGMRLIST)" ] ; then \
	      grep PGMRCODE $(PGMRLIST) | \
	      awk '{print $$3}' | \
	      sort -u | \
	      while read RHS ; do \
	         DFILE=`echo $$RHS | sed -e 's#\$$(PGMRCODE)#$(PGMRCODE)#'` ; \
	         if [ ! -f "$$DFILE" ] ; then \
	            grep "$$RHS" $(PGMRLIST) | \
	            awk '{print $$1}' | \
	            sort -u | \
	            while read LHS ; do \
	               TARGET=`echo $$LHS | sed -e '{s/.*(//;s/)$$//;}'` ; \
	               echo "Deleting dependencies for $$TARGET because of" ; \
	               echo "   $$DFILE" ; \
	               grep -v "^$$LHS : " $(PGMRLIST) > $(PGMRLIST).$(PID) ; \
	               mv $(PGMRLIST).$(PID) $(PGMRLIST) ; \
	               $(AR) d $(PGMRTIME) $$TARGET ; \
	            done ; \
	         fi ; \
	      done ; \
	   fi
	-@ if [ ! -s "$(PGMRLIST)" ] ; then \
	      $(RM) $(PGMRLIST) $(PGMRTIME) ; \
	   fi
	-@ if [ -d tmplinst ] ; then \
	      if [ -f templates ] ; then \
	         (cd tmplinst && mkinst -q ../templates) ; \
	      else \
	         (cd tmplinst && mkinst -q - < /dev/null) ; \
	      fi ; \
	      $(MAKE) -f $(THISDIR)/makefile -C tmplinst $@ ; \
	   fi

   mylib : $(PRGAPLIB) ;

   $(PRGAPLIB) : $(PGMRINST) $(PGMRIMPS:%.cc=$(PRGAPLIB)(%.o)) update_mylib ;

   inst : tmplinst FORCE
	-@ if [ -f MyTemplatesOnly ] ; then \
	      echo "" ; \
	      echo "WARNING: Ignoring system template instantiation files." ; \
	   fi
	 @ $(MAKE) -f $(THISDIR)/makefile -C $< mylib

   tmplinst : templates
	-@ echo ""
	 @ amkdir -p ug=rwx,g+s,o=rx -v $@
	-@ echo ""
	 @ case "$<" in \
	   templates) \
	      cd $@ && mkinst -q ../$< ; \
	      ;; \
	   *) \
	      cd $@ && mkinst -q - < /dev/null ; \
              ;; \
	   esac

   update_mylib :
	@ cd $(PGMRLIBD) ; \
	  PGMROBJS="$(PGMRIMPS:%.cc=%.o)" ; \
	  [ "$$PGMROBJS" != "" ] && PGMROBJS=`ls $$PGMROBJS 2>/dev/null` ; \
	  if [ "$$PGMROBJS" != "" ] ; then \
	     $(CXXAR) $(CXXARFLAGS) $(PRGAPLIB) $$PGMROBJS ; \
	     $(RM) $$PGMROBJS ; \
	     $(RANLIB) $(PRGAPLIB) ; \
	  fi
endif

show_local :
	-@ echo ""
	-@ echo "Variables defined in the applications makefile"
	-@ echo "=============================================="
	-@ echo ""
	-@ echo "System"
	-@ echo "------"
	-@ echo "THISAPP =$(THISAPP)"
	-@ echo "PCKGAPP =$(PCKGAPP)"
	-@ echo ""
	-@ echo "PCKGOPTD=$(PCKGOPTD)"
	-@ echo "PCKGDBGD=$(PCKGDBGD)"
	-@ echo ""
	-@ echo "AIPSIMPS=$(AIPSIMPS)"
	-@ echo "LIBEXECS=$(LIBEXECS)"
	-@ echo "LIBICONS=$(LIBICONS)"
	-@ echo ""
	-@ echo "AIPSINST=$(AIPSINST)"
	-@ echo ""
	-@ echo "DBGLIBS =$(DBGLIBS)"
	-@ echo "OPTLIBS =$(OPTLIBS)"
	-@ echo ""
	-@ echo "MODULIBS=$(MODULIBS)"
	-@ echo ""
	-@ echo "TGT=$(TGT)"
	-@ echo ""
	-@ echo "Programmer"
	-@ echo "----------"
	-@ echo "PGMRINST=$(PGMRINST)"
	-@ echo "PGMRIMPS=$(PGMRIMPS)"
	-@ echo "PRGAPINC=$(PRGAPINC)"
	-@ echo ""
	-@ echo "PGMRLIBR=$(PGMRLIBR)"
	-@ echo "PGMRLIBS=$(PGMRLIBS)"
	-@ echo ""
	-@ echo "PRGAPLIB=$(PRGAPLIB)"
	-@ echo ""
	-@ echo "PGMRLIST=$(PGMRLIST)"
	-@ echo "PGMRTIME=$(PGMRTIME)"
	-@ echo "PGMRLOCK=$(PGMRLOCK)"

help ::
	-@ echo ""
	-@ echo "Targets defined in the applications makefile"
	-@ echo "============================================"
	-@ echo ""
	-@ echo "System"
	-@ echo "------"
	-@ echo "        bin: compile this application."
	-@ echo "     bindbg: compile this application in debug mode."
	-@ echo "    instsys: generate diy template instantiation files."
	-@ echo ""
	-@ echo "Programmer"
	-@ echo "----------"
	-@ echo "        %.o: produce an object file."
	-@ echo "        %.i: preprocess a .cc file."
	-@ echo "        %.d: list dependencies for an application."
	-@ echo "     depend: determine dependencies for \$$(THISAPP)."
	-@ echo "   exorcise: dispell vexatious spirits."
	-@ echo " \$$(THISAPP): compile this application."
	-@ echo "       inst: generate and instantiate diy templates."
	-@ echo "   tmplinst: generate diy template instantiation files."
	-@ echo "      mylib: instantiate diy templates."
	-@ echo "update_mylib: insert all object modules into a private"
	-@ echo "             library and ranlib it (if necessary)."

# Programmer dependency list.
ifeq "$(MAKEMODE)" "programmer"
   -include $(PGMRLIST)
endif

