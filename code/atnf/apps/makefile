# $Id: makefile,v 19.2 2006/08/24 02:19:54 mcalabre Exp $

# Use the generic AIPS++ applications directory makefile.
#--------------------------------------------------------
include $(word 1, $(AIPSPATH))/code/install/makefile.aps

.PHONY : pks pksio

PKSIOEXES := rp2sdfits pksfits2ms pksreader pkswriter pksgridzilla
PKSEXES   := pksbandpass pksmonitor pksstats livedata

pks : pksio $(PKSEXES:%=bin/%)

pksio : $(PKSIOEXES:%=bin/%)
